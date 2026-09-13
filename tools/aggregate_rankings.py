#!/usr/bin/env python3
"""
DelveGuide -- community variant ranking aggregator.

Reads a CSV export of the Google Form responses, pulls the DelveGuide
submission codes players paste in, averages clear times per delve/variant
across everyone, and prints a ranked table (fastest first, per delve) plus a
regenerated DelveGuideData.delves block -- the COMPLETE block, rebuilt from the
published one so every curated field (zone, mountable, hasBug, isBestRoute)
comes back untouched. --write puts it into the data file in place.

Submission code produced by /dg submit (format version DG1):
    DG1;delve~variant~avgTier~avgSec~count;delve~variant~...

Usage:
    python aggregate_rankings.py responses.csv
    python aggregate_rankings.py responses.csv --min-runs 5 --min-tier 8
    python aggregate_rankings.py responses.csv --min-tier 8 --write

Notes:
  * --min-runs drops thinly-sampled variants (default 3 total runs).
  * --min-tier ignores a submitter's variant if their avg tier is below it
    (times balloon at low tiers -- comparing at T8+ is cleaner once data exists).
  * Suggested S-F letters are GLOBAL -- relative to the MEDIAN variant across
    ALL delves (see SUGGEST for why not the fastest). Tweak
    the SUGGEST thresholds to taste; treat them as a starting point, not gospel.
"""

import os
import re
import csv
import sys
import argparse
import statistics
from collections import defaultdict

# Ratio to the MEDIAN variant -> suggested letter; anything slower = F.
# S therefore means "clears in roughly 4/5 the time of a typical variant".
#
# This used to be a ratio to the single FASTEST variant, which made the whole
# table hostage to one sample. Measured across two consecutive data pulls
# (73 -> 84 responses): the fastest variant moved 51s while the median moved 17s,
# and 15 variants gained a grade purely because the yardstick got longer. Anchoring
# to the median gives an identical grade distribution with half the churn
# (18 -> 9 changes between those same two pulls).
#
# Absolute bands ("S = under 12 minutes") would be perfectly stable but need
# retuning every season as gear inflates -- exactly how the Voidforge item-level
# thresholds ended up dead at 680/700/720. A median anchor rescales itself.
SUGGEST = [(0.82, "S"), (0.93, "A"), (1.08, "B"), (1.19, "C"), (1.37, "D")]

# Letters worst-to-best is the reverse of this; index 0 = S ... index 5 = F.
LETTERS = [letter for _ratio, letter in SUGGEST] + ["F"]

# The published data file sits one level up from tools/. Resolved from __file__,
# NOT from the working directory: a CWD-relative default meant that running the
# script from anywhere but the repo root silently found no published grades and
# turned hysteresis off without saying so.
DEFAULT_PUBLISHED = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, "DelveGuide_Data.lua"))


def split_sections(code):
    """Split a DG1 code into (runs, missing).

    A code may carry any number of trailing "|NAME;" sections after the run
    data -- |MISSING; (unidentified variants) and, since 2.0.0, |LAB;
    (Labyrinth chamber timings, which this tool does not rank). Sections are
    peeled off generically so a section added by a newer client never eats the
    last run segment: splitting on "|MISSING;" alone left "count|LAB" as the
    fifth field of the final run and silently dropped that run.
    """
    code = code.strip()
    if not code.startswith("DG1;"):
        return "", ""
    body = code[4:]
    runs, _, tail = body.partition("|")
    sections = {}
    for seg in tail.split("|"):
        name, _, rest = seg.partition(";")
        sections.setdefault(name.strip().upper(), rest)
    return runs, sections.get("MISSING", "")


def parse_code(code):
    """Yield (delve, variant, avg_tier, avg_sec, count) from one DG1 code."""
    runs, _ = split_sections(code)
    for seg in runs.split(";"):
        parts = seg.strip().split("~")
        if len(parts) != 5:
            continue
        delve, variant = parts[0].strip(), parts[1].strip()
        try:
            avg_tier, avg_sec, count = int(parts[2]), int(parts[3]), int(parts[4])
        except ValueError:
            continue
        if delve and variant and avg_sec > 0 and count > 0:
            yield delve, variant, avg_tier, avg_sec, count


def parse_missing(code):
    """Yield (delve, locale, text) for variants a client could not identify."""
    _, missing = split_sections(code)
    for seg in missing.split(";"):
        parts = seg.strip().split("~")
        if len(parts) != 3:
            continue
        delve, locale, text = (p.strip() for p in parts)
        if text:
            yield delve, locale, text


# A run segment looks like: delve~variant~tier~seconds~count
RUN_SEG = re.compile(r"[^~;|]+~[^~;|]+~\d+~\d+~\d+")


def find_codes(csv_path, salvaged=None, handle_col=2):
    """Yield (code, handle) for every DG1 code found in any cell of the CSV.

    Cells are scanned in any order so a reshuffled form still parses, but the
    HANDLE is pinned to a column (the same one screen_handles.py uses): guessing
    it by shape pulls in free-text feedback. The handle is what identifies a
    resubmission, so a wrong column silently un-deduplicates the data.

    Also salvages codes whose "DG1;" prefix was lost -- players sometimes paste a
    partial selection, and silently dropping the whole submission hides real data
    loss. Salvaged cells are recorded in `salvaged` so it gets reported.
    """
    with open(csv_path, newline="", encoding="utf-8-sig") as fh:
        for row in csv.reader(fh):
            handle = row[handle_col].strip() if len(row) > handle_col else ""
            if "DG1;" in handle or RUN_SEG.search(handle):
                handle = ""   # columns shifted; that is a code, not a name
            for cell in row:
                if not cell:
                    continue
                if "DG1;" in cell:
                    yield cell[cell.index("DG1;"):], handle
                elif RUN_SEG.search(cell):
                    if salvaged is not None:
                        salvaged.append(cell.strip()[:70])
                    yield "DG1;" + cell.strip(), handle


def suggest_letter(sec, fastest):
    ratio = sec / fastest if fastest else 999
    for threshold, letter in SUGGEST:
        if ratio <= threshold:
            return letter
    return "F"


def mmss(seconds):
    seconds = int(seconds)
    return f"{seconds // 60}m {seconds % 60:02d}s"


# ---------------------------------------------------------------------------
# Round-tripping the DelveGuideData.delves block.
#
# The emitter used to print rows with zone="?" and every curated flag hard-wired
# to false, so its output could never be pasted -- mountable, hasBug and
# isBestRoute are hand-researched and would have been wiped. Every refresh was
# therefore applied by hand, one row at a time, which is exactly how a flag goes
# missing. So: read the existing block, change ONLY ranking / medianSec /
# players, and re-emit the whole thing. Rows we have no fresh data for are
# copied out byte-for-byte, comments and all.
# ---------------------------------------------------------------------------

BLOCK_OPEN = "DelveGuideData.delves = {"

# A row is a single-line table constructor. `.*?` never crosses a line here
# because the block is split into lines first.
ROW_RE = re.compile(r'^(?P<indent>\s*)\{(?P<fields>.*?)\},(?P<rest>.*)$')


def row_key(fields):
    """(delve, variant) for a row's field text, or None if it is not a delve row."""
    name = re.search(r'name="([^"]*)"', fields)
    variant = re.search(r'variant="([^"]*)"', fields)
    if name and variant:
        return name.group(1), variant.group(1)
    return None


def _set_number(fields, key, value):
    """Set key=<int> in a row's field text, appending it if it is not there yet."""
    pat = re.compile(r"\b" + key + r"=\d+")
    if pat.search(fields):
        return pat.sub(f"{key}={value}", fields, count=1)
    return fields.rstrip() + f", {key}={value} "


def rewrite_row(line, ranking, median_sec, players, hold=None):
    """Update one row's grade/median/players, preserving every other field."""
    m = ROW_RE.match(line)
    fields = re.sub(r'ranking="[^"]*"', f'ranking="{ranking}"', m.group("fields"), count=1)
    fields = _set_number(fields, "medianSec", int(median_sec))
    fields = _set_number(fields, "players", players)
    tag = f" -- HELD (would be {hold})" if hold else ""
    return f'{m.group("indent")}{{{fields}}},  -- {mmss(median_sec)}, {players} players{tag}'


def render_delves_block(src, fresh):
    """Rebuild the delves block inside `src` from `fresh`.

    `fresh` maps (delve, variant) -> {"ranking", "median_sec", "players", "hold"}.
    Returns (new_src, block_text, changed, untouched, added) where `changed` is a
    list of (key, old_line, new_line). Raises ValueError if the block is missing.
    """
    nl = "\r\n" if "\r\n" in src else "\n"
    lines = src.split(nl)
    try:
        start = next(i for i, l in enumerate(lines) if l.startswith(BLOCK_OPEN))
        end = next(i for i in range(start + 1, len(lines)) if lines[i].rstrip() == "}")
    except StopIteration:
        raise ValueError(f"no {BLOCK_OPEN!r} ... '}}' block found")

    out, changed, untouched, seen = [], [], [], set()
    for line in lines[start + 1:end]:
        m = ROW_RE.match(line)
        key = row_key(m.group("fields")) if m else None
        if key is None:            # comment, blank line, anything not a row
            out.append(line)
            continue
        if key not in fresh:       # no fresh data -- never rewrite, never drop
            out.append(line)
            untouched.append(key)
            continue
        seen.add(key)
        f = fresh[key]
        new = rewrite_row(line, f["ranking"], f["median_sec"], f["players"], f.get("hold"))
        out.append(new)
        if new != line:
            changed.append((key, line, new))

    added = [k for k in fresh if k not in seen]
    if added:
        out.append("    -- NEW -- graded this pass but not in the table yet."
                   " Set zone and the curated flags.")
        for key in added:
            f = fresh[key]
            out.append(rewrite_row(
                f'    {{ name="{key[0]}", zone="?", variant="{key[1]}", ranking="?",'
                f' mountable=false, hasBug=false, isBestRoute=false }},',
                f["ranking"], f["median_sec"], f["players"], f.get("hold")))

    block = nl.join([lines[start]] + out + [lines[end]])
    new_src = nl.join(lines[:start] + [lines[start]] + out + lines[end:])
    return new_src, block, changed, untouched, added


def main():
    # The data file and the unidentified-variant reports both carry non-ASCII
    # (box-drawing rules in the comments, localized variant names), and a
    # Windows console defaults to cp1252 -- printing either would raise
    # UnicodeEncodeError and lose the whole run.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    ap = argparse.ArgumentParser()
    ap.add_argument("csv", help="CSV export of the Google Form responses")
    ap.add_argument("--min-runs", type=int, default=3)
    ap.add_argument("--min-tier", type=int, default=0)
    ap.add_argument("--handle-col", type=int, default=2, metavar="N",
                    help="0-based CSV column holding the contributor handle (default 2, "
                         "matching screen_handles.py). Resubmissions are detected by handle, "
                         "so pointing this at the wrong column silently stops deduplicating.")
    ap.add_argument("--min-submitters", type=int, default=4,
                    help="require this many DIFFERENT players before grading a variant. "
                         "Also caps any one player's influence at 1/N of the grade.")
    ap.add_argument("--hysteresis", type=int, default=30, metavar="SECONDS",
                    help="do not move a PUBLISHED grade unless the new time clears the band "
                         "boundary by this many seconds (default 30; 0 disables). The grade "
                         "distribution is squeezed into ~9 minutes with 5 band edges in it, so "
                         "edges land ~1.5min apart while normal data movement is tens of "
                         "seconds -- without this, variants sitting seconds from an edge flip "
                         "letter almost every refresh regardless of sample size.")
    ap.add_argument("--published", default=DEFAULT_PUBLISHED, metavar="LUA",
                    help="data file read for the currently published grades, which hysteresis "
                         "is measured against. Ignored if --hysteresis 0. Defaults to the copy "
                         "next to the script, so it works from any directory.")
    ap.add_argument("--write", action="store_true",
                    help="write the regenerated delves block back into --published, replacing "
                         "exactly that block and leaving the rest of the file (and its line "
                         "endings) byte-for-byte. Without it the block goes to stdout.")
    ap.add_argument("--weight", choices=("players", "runs"), default="players",
                    help="'players' (default) counts each submitter ONCE regardless of how "
                         "many times they ran it -- no single player can hold more than "
                         "1/min-submitters of a grade. 'runs' weights by run count, which "
                         "let one player with 14 runs outvote 14 players with one each.")
    ap.add_argument("--stat", choices=("median", "mean"), default="median",
                    help="central-tendency estimator. Clear time has a hard floor but no "
                         "ceiling (an AFK/wipe/disconnect run can be 45m+), so the sample is "
                         "right-skewed and a single bad run drags the mean several minutes. "
                         "The median ignores that. 'mean' reproduces pre-1.8.8 grades.")
    args = ap.parse_args()

    # weighted accumulation per (delve, variant)
    tot_sec = defaultdict(float)   # sum of avg_sec * count
    tot_runs = defaultdict(int)    # sum of count
    tot_tier = defaultdict(float)  # sum of avg_tier * count
    submitters = defaultdict(set)  # distinct submissions contributing to each variant
    samples = defaultdict(list)    # per-variant (avg_sec, count) from each submitter

    unidentified = defaultdict(lambda: {"count": 0, "locales": set()})

    salvaged = []
    all_codes = list(find_codes(args.csv, salvaged, args.handle_col))

    # Drop superseded resubmissions. Each /dg submit code is a COMPLETE snapshot
    # of that player's history (GetVariantRunStats walks all of it), not an
    # increment -- so a player who submits again would otherwise have every run
    # counted twice, inflating run totals and the >=7-run confidence threshold.
    #
    # Deduplicate on IDENTITY (the handle), not on the data. Keeping only the
    # last code per non-empty handle is exact. The old rule -- "a later code
    # repeating >=70% of an earlier one's EXACT entries supersedes it" -- keyed
    # on avg_sec, which is a per-player average that MOVES every time that
    # player re-runs a variant. Once someone had re-run more than ~30% of their
    # variants the two codes no longer overlapped enough, both survived, and one
    # human counted as two players -- which is exactly what the "no one holds
    # more than 1/N of a grade" guarantee in RANKING.md forbids. It also cut the
    # other way, superseding people who had submitted only once but happened to
    # share a variant set with someone else.
    #
    # Dropping avg_sec from the key instead was tested and is far worse: players
    # legitimately run the same variants, so (delve, variant) overlap alone
    # collapsed 100 of 106 codes into each other.
    #
    # The overlap heuristic survives as the ONLY thing available for blank
    # handles (roughly 40% of submissions -- the field is optional), where there
    # is no identity to key on.
    def entries(code):
        out = set()
        for d, v, t, s, c in parse_code(code):
            out.add((d, v, s))
        return out

    superseded = set()
    by_handle = {}
    for i, (_code, handle) in enumerate(all_codes):
        key = handle.casefold()
        if not key:
            continue
        if key in by_handle:
            superseded.add(by_handle[key])   # keep the LAST code per handle
        by_handle[key] = i
    dropped_by_handle = len(superseded)

    anon = [i for i, (_c, h) in enumerate(all_codes) if not h.casefold()]
    ent = {i: entries(all_codes[i][0]) for i in anon}
    for pos, i in enumerate(anon):
        if not ent[i]:
            continue
        for j in anon[pos + 1:]:
            if ent[j] and len(ent[i] & ent[j]) / len(ent[i]) >= 0.70:
                superseded.add(i)
                break
    dropped_anon = len(superseded) - dropped_by_handle
    codes = [c for i, (c, _h) in enumerate(all_codes) if i not in superseded]

    submissions = 0
    for code in codes:
        submissions += 1
        for delve, locale, text in parse_missing(code):
            rec = unidentified[(delve, text)]
            rec["count"] += 1
            rec["locales"].add(locale)
        for delve, variant, avg_tier, avg_sec, count in parse_code(code):
            if avg_tier < args.min_tier:
                continue
            key = (delve, variant)
            tot_sec[key] += avg_sec * count
            tot_runs[key] += count
            tot_tier[key] += avg_tier * count
            samples[key].append((avg_sec, count))
            submitters[key].add(submissions)  # submission index = one player

    def report_unidentified():
        if not unidentified:
            return
        print(f"\n=== UNIDENTIFIED VARIANTS reported by {len(unidentified)} distinct text(s) ===")
        print("These were seen in game but aren't in DelveGuideData.delves. English")
        print("entries are new variants to catalogue; non-English ones are localized")
        print("text for localeVariants.\n")
        for (delve, text), rec in sorted(unidentified.items(), key=lambda kv: -kv[1]["count"]):
            locs = ",".join(sorted(rec["locales"]))
            print(f'   {delve:<22} [{locs}]  "{text}"   (reported by {rec["count"]})')

    if not tot_runs:
        print(f"No ranked run data found in {args.csv}.")
        report_unidentified()
        return

    rows, thin = [], []
    for key, runs in tot_runs.items():
        if runs < args.min_runs:
            continue
        if len(submitters[key]) < args.min_submitters:
            thin.append((key, runs, len(submitters[key])))
            continue
        delve, variant = key
        mean_sec = tot_sec[key] / runs
        # One player, one vote (default). Weighting by run count let a single
        # player with 14 runs outvote 14 players with one run each -- and their
        # runs are not 14 independent samples anyway (same character, gear and
        # route), so they carry far less information than the count implies.
        if args.weight == "runs":
            pool = [sec for sec, cnt in samples[key] for _ in range(cnt)]
        else:
            pool = [sec for sec, _cnt in samples[key]]
        median_sec = statistics.median(pool)
        rows.append({
            "delve": delve, "variant": variant, "runs": runs,
            "avg_sec": median_sec if args.stat == "median" else mean_sec,
            "mean_sec": mean_sec, "median_sec": median_sec,
            "avg_tier": round(tot_tier[key] / runs),
            "submitters": len(submitters[key]),
        })

    by_delve = defaultdict(list)
    for r in rows:
        by_delve[r["delve"]].append(r)

    print(f"\nParsed {submissions} submissions -> {len(rows)} variants "
          f"(filters: >={args.min_runs} runs, >={args.min_submitters} players, "
          f"tier >={args.min_tier}, stat={args.stat}, weight={args.weight})")
    if superseded:
        print(f"   ({len(superseded)} earlier resubmission(s) dropped -- each code is a full "
              f"history snapshot, so counting both would double a player's runs)")
        print(f"    {dropped_by_handle} by handle (exact), {dropped_anon} by entry overlap "
              f"(blank handles only -- best effort)")
    if salvaged:
        print(f"\n!! {len(salvaged)} submission(s) had no DG1; prefix (partial paste). "
              f"Salvaged what was parseable:")
        for frag in salvaged:
            print(f"   ...{frag}")
    print()

    import statistics as _st
    global_fastest = _st.median(sorted(r["avg_sec"] for r in rows)) if rows else 1

    # The published data file, read once: it is both the hysteresis baseline and
    # the source of the curated flags the emitter has to round-trip. newline=""
    # so the file's own line endings survive a --write.
    pub_path = os.path.abspath(args.published)
    try:
        with open(pub_path, encoding="utf-8", newline="") as fh:
            pub_src = fh.read()
    except FileNotFoundError:
        pub_src = None

    published = {}
    if args.hysteresis > 0:
        if pub_src is not None:
            # `.` excludes newlines without DOTALL, so this stays on one Lua line.
            # Keyed on (delve, variant), never on the variant alone: variant
            # names are unique within a delve but NOT across the table, and a
            # collision would hand one delve's published grade to another
            # delve's row -- an invisible wrong hold, in the one code path
            # whose whole job is to keep a grade from moving.
            for m in re.finditer(
                    r'name="([^"]+)".*?variant="([^"]+)".*?ranking="([SABCDF])"', pub_src):
                published[(m.group(1), m.group(2))] = m.group(3)
            print(f"Hysteresis ACTIVE (+/-{args.hysteresis}s): {len(published)} published "
                  f"grade(s) read from {pub_path}")
            print()
        else:
            # Never swallow this. Without the published grades every letter is
            # recomputed from scratch, so variants parked near a band edge flip
            # -- which is the exact churn --hysteresis exists to stop.
            print("!! HYSTERESIS IS OFF -- no published data file at:")
            print(f"     {pub_path}")
            print("   Grades below are recomputed from scratch and boundary-noise flips")
            print("   are NOT suppressed. Pass --published <path>, or --hysteresis 0 to")
            print("   mean it.")
            print()

    band_edges = sorted(global_fastest * ratio for ratio, _ in SUGGEST)

    def settle(sec, fresh, key):
        """Keep the published letter when the new time has not clearly cleared the
        boundary. `key` is (delve, variant). Returns (letter, held_note_or_None)."""
        old = published.get(key)
        if not old or old == fresh:
            return fresh, None
        # Hysteresis is for boundary NOISE. A variant whose time collapsed past
        # two or more band edges has genuinely moved, and holding it there would
        # be self-perpetuating: the held letter is what gets published, and the
        # next run reads that back as its baseline, so the variant never catches
        # up with its own data. Cap a hold at a single band.
        if abs(LETTERS.index(old) - LETTERS.index(fresh)) > 1:
            return fresh, None
        gap = min(abs(sec - e) for e in band_edges)
        if gap < args.hysteresis:
            return old, f"held {old} (would be {fresh}, only {int(gap)}s past the line)"
        return fresh, None

    graded, held_notes = {}, []
    for delve in sorted(by_delve):
        variants = sorted(by_delve[delve], key=lambda r: r["avg_sec"])
        print(f"== {delve} ==")
        for r in variants:
            fresh = suggest_letter(r["avg_sec"], global_fastest)
            letter, held = settle(r["avg_sec"], fresh, (delve, r["variant"]))
            if held:
                held_notes.append((delve, r["variant"], held))
            skew = r["mean_sec"] - r["median_sec"]
            note = f"   [mean {mmss(r['mean_sec'])}]" if abs(skew) >= 60 else ""
            print(f"  [{letter}]  {mmss(r['avg_sec']):>8}  {r['variant']:<34}"
                  f"({r['runs']} runs / {r['submitters']} players, ~T{r['avg_tier']}){note}")
            # A held row carries the letter it WOULD have had, so the suppression
            # is visible in the data file itself and not only in this run's log.
            graded[(delve, r["variant"])] = {
                "ranking": letter,
                "median_sec": int(r["avg_sec"]),
                "players": r["submitters"],
                "hold": fresh if held else None,
            }
        print()

    if held_notes:
        print(f"== {len(held_notes)} grade(s) HELD by hysteresis (--hysteresis {args.hysteresis}) ==")
        print("   These sit close enough to a band edge that the change is boundary noise,")
        print("   not a real shift. Re-run with --hysteresis 0 to see them move.")
        for d, v, note in sorted(held_notes):
            print(f"   {d:<22} {v:<32} {note}")
        print()

    if thin:
        print(f"~~ {len(thin)} variant(s) withheld -- enough runs but fewer than "
              f"{args.min_submitters} different players (one grinder shouldn't set a grade):")
        for (d, v), runs, subs in sorted(thin):
            print(f"   {d:<22} {v:<32} {runs} runs from {subs} player(s)")
        print()

    if pub_src is None:
        print(f"!! Cannot emit the delves block: no data file at {pub_path}.")
        print("   The block is regenerated FROM the published one so the curated flags")
        print("   (zone, mountable, hasBug, isBestRoute) survive. Point --published at it.")
        report_unidentified()
        return

    try:
        new_src, block, changed, untouched, added = render_delves_block(pub_src, graded)
    except ValueError as err:
        print(f"!! Cannot emit the delves block: {err} in {pub_path}.")
        report_unidentified()
        return

    print(f"---- DelveGuideData.delves ({len(changed)} row(s) changed, "
          f"{len(untouched)} left alone for lack of fresh data, {len(added)} new) ----")
    for (d, v), _old, _new in changed:
        print(f"   changed: {d} / {v}")
    for d, v in sorted(untouched):
        print(f"   no data this pass, row kept as published: {d} / {v}")
    print()

    if args.write:
        if new_src == pub_src:
            print(f"No change -- {pub_path} already matches this data pass.")
        else:
            with open(pub_path, "w", encoding="utf-8", newline="") as fh:
                fh.write(new_src)
            print(f"Wrote the delves block into {pub_path} "
                  f"({len(changed)} row(s) changed, {len(added)} added).")
            print("   Everything outside the block, and the file's line endings, are untouched.")
            print("   Diff it before committing.")
    else:
        print(block)
        print()
        print("(re-run with --write to put this back into the data file in place)")

    report_unidentified()


if __name__ == "__main__":
    main()
