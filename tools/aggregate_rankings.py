#!/usr/bin/env python3
"""
DelveGuide -- community variant ranking aggregator.

Reads a CSV export of the Google Form responses, pulls the DelveGuide
submission codes players paste in, averages clear times per delve/variant
across everyone, and prints a ranked table (fastest first, per delve) plus a
Lua-ready snippet you can merge into DelveGuideData.delves.

Submission code produced by /dg submit (format version DG1):
    DG1;delve~variant~avgTier~avgSec~count;delve~variant~...

Usage:
    python aggregate_rankings.py responses.csv
    python aggregate_rankings.py responses.csv --min-runs 5 --min-tier 8

Notes:
  * --min-runs drops thinly-sampled variants (default 3 total runs).
  * --min-tier ignores a submitter's variant if their avg tier is below it
    (times balloon at low tiers -- comparing at T8+ is cleaner once data exists).
  * Suggested S-F letters are GLOBAL -- relative to the MEDIAN variant across
    ALL delves (see SUGGEST for why not the fastest). Tweak
    the SUGGEST thresholds to taste; treat them as a starting point, not gospel.
"""

import re
import csv
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


def split_sections(code):
    """DG1 codes may carry a trailing |MISSING; section of unidentified variants."""
    code = code.strip()
    if not code.startswith("DG1;"):
        return "", ""
    body = code[4:]
    if "|MISSING;" in body:
        runs, missing = body.split("|MISSING;", 1)
        return runs, missing
    return body, ""


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


def find_codes(csv_path, salvaged=None):
    """Yield every DG1 code found in any cell of the CSV (robust to column order).

    Also salvages codes whose "DG1;" prefix was lost -- players sometimes paste a
    partial selection, and silently dropping the whole submission hides real data
    loss. Salvaged cells are recorded in `salvaged` so it gets reported.
    """
    with open(csv_path, newline="", encoding="utf-8-sig") as fh:
        for row in csv.reader(fh):
            for cell in row:
                if not cell:
                    continue
                if "DG1;" in cell:
                    yield cell[cell.index("DG1;"):]
                elif RUN_SEG.search(cell):
                    if salvaged is not None:
                        salvaged.append(cell.strip()[:70])
                    yield "DG1;" + cell.strip()


def suggest_letter(sec, fastest):
    ratio = sec / fastest if fastest else 999
    for threshold, letter in SUGGEST:
        if ratio <= threshold:
            return letter
    return "F"


def mmss(seconds):
    seconds = int(seconds)
    return f"{seconds // 60}m {seconds % 60:02d}s"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv", help="CSV export of the Google Form responses")
    ap.add_argument("--min-runs", type=int, default=3)
    ap.add_argument("--min-tier", type=int, default=0)
    ap.add_argument("--min-submitters", type=int, default=4,
                    help="require this many DIFFERENT players before grading a variant. "
                         "Also caps any one player's influence at 1/N of the grade.")
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
    all_codes = list(find_codes(args.csv, salvaged))

    # Drop superseded resubmissions. Each /dg submit code is a COMPLETE snapshot
    # of that player's history (GetVariantRunStats walks all of it), not an
    # increment -- so a player who submits again would otherwise have every run
    # counted twice, inflating run totals and the >=7-run confidence threshold.
    # A later code that repeats >=70% of an earlier one's exact entries is
    # treated as that player resubmitting.
    def entries(code):
        out = set()
        for d, v, t, s, c in parse_code(code):
            out.add((d, v, s))
        return out

    ent = [entries(c) for c in all_codes]
    superseded = set()
    for i in range(len(all_codes)):
        if not ent[i]:
            continue
        for j in range(i + 1, len(all_codes)):
            if ent[j] and len(ent[i] & ent[j]) / len(ent[i]) >= 0.70:
                superseded.add(i)
                break
    codes = [c for i, c in enumerate(all_codes) if i not in superseded]

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
    if salvaged:
        print(f"\n!! {len(salvaged)} submission(s) had no DG1; prefix (partial paste). "
              f"Salvaged what was parseable:")
        for frag in salvaged:
            print(f"   ...{frag}")
    print()

    import statistics as _st
    global_fastest = _st.median(sorted(r["avg_sec"] for r in rows)) if rows else 1

    lua = []
    for delve in sorted(by_delve):
        variants = sorted(by_delve[delve], key=lambda r: r["avg_sec"])
        print(f"== {delve} ==")
        for r in variants:
            letter = suggest_letter(r["avg_sec"], global_fastest)
            skew = r["mean_sec"] - r["median_sec"]
            note = f"   [mean {mmss(r['mean_sec'])}]" if abs(skew) >= 60 else ""
            print(f"  [{letter}]  {mmss(r['avg_sec']):>8}  {r['variant']:<34}"
                  f"({r['runs']} runs / {r['submitters']} players, ~T{r['avg_tier']}){note}")
            lua.append(
                f'    {{ name="{delve}", zone="?", variant="{r["variant"]}", '
                f'ranking="{letter}", mountable=false, hasBug=false, isBestRoute=false }},'
                f'  -- {mmss(r["avg_sec"])}, {r["runs"]} runs'
            )
        print()

    if thin:
        print(f"~~ {len(thin)} variant(s) withheld -- enough runs but fewer than "
              f"{args.min_submitters} different players (one grinder shouldn't set a grade):")
        for (d, v), runs, subs in sorted(thin):
            print(f"   {d:<22} {v:<32} {runs} runs from {subs} player(s)")
        print()

    print("---- Lua snippet (fill in zone / flags, then merge into DelveGuideData.delves) ----")
    print("\n".join(lua))
    report_unidentified()


if __name__ == "__main__":
    main()
