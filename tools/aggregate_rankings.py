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
  * Suggested S-F letters are GLOBAL -- relative to the fastest variant across
    ALL delves, matching the addon's "S = fastest, F = slowest" scale. Tweak
    the SUGGEST thresholds to taste; treat them as a starting point, not gospel.
"""

import re
import csv
import argparse
from collections import defaultdict

# ratio to the GLOBAL fastest variant -> suggested letter; anything slower = F
SUGGEST = [(1.10, "S"), (1.25, "A"), (1.45, "B"), (1.60, "C"), (1.85, "D")]


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
    args = ap.parse_args()

    # weighted accumulation per (delve, variant)
    tot_sec = defaultdict(float)   # sum of avg_sec * count
    tot_runs = defaultdict(int)    # sum of count
    tot_tier = defaultdict(float)  # sum of avg_tier * count

    unidentified = defaultdict(lambda: {"count": 0, "locales": set()})

    salvaged = []
    submissions = 0
    for code in find_codes(args.csv, salvaged):
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

    rows = []
    for key, runs in tot_runs.items():
        if runs < args.min_runs:
            continue
        delve, variant = key
        rows.append({
            "delve": delve, "variant": variant, "runs": runs,
            "avg_sec": tot_sec[key] / runs,
            "avg_tier": round(tot_tier[key] / runs),
        })

    by_delve = defaultdict(list)
    for r in rows:
        by_delve[r["delve"]].append(r)

    print(f"\nParsed {submissions} submissions -> {len(rows)} variants "
          f"(filters: >={args.min_runs} runs, avg tier >={args.min_tier})")
    if salvaged:
        print(f"\n!! {len(salvaged)} submission(s) had no DG1; prefix (partial paste). "
              f"Salvaged what was parseable:")
        for frag in salvaged:
            print(f"   ...{frag}")
    print()

    global_fastest = min((r["avg_sec"] for r in rows), default=1)

    lua = []
    for delve in sorted(by_delve):
        variants = sorted(by_delve[delve], key=lambda r: r["avg_sec"])
        print(f"== {delve} ==")
        for r in variants:
            letter = suggest_letter(r["avg_sec"], global_fastest)
            print(f"  [{letter}]  {mmss(r['avg_sec']):>8}  {r['variant']:<34}"
                  f"({r['runs']} runs, ~T{r['avg_tier']})")
            lua.append(
                f'    {{ name="{delve}", zone="?", variant="{r["variant"]}", '
                f'ranking="{letter}", mountable=false, hasBug=false, isBestRoute=false }},'
                f'  -- {mmss(r["avg_sec"])}, {r["runs"]} runs'
            )
        print()

    print("---- Lua snippet (fill in zone / flags, then merge into DelveGuideData.delves) ----")
    print("\n".join(lua))
    report_unidentified()


if __name__ == "__main__":
    main()
