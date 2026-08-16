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
  * Suggested S-F letters are relative to the FASTEST variant of the same
    delve -- tweak the SUGGEST thresholds to taste; treat them as a starting
    point, not gospel.
"""

import csv
import argparse
from collections import defaultdict

# ratio-to-fastest (within a delve) -> suggested letter; anything slower = F
SUGGEST = [(1.05, "S"), (1.15, "A"), (1.30, "B"), (1.50, "C"), (1.80, "D")]


def parse_code(code):
    """Yield (delve, variant, avg_tier, avg_sec, count) from one DG1 code."""
    code = code.strip()
    if not code.startswith("DG1;"):
        return
    for seg in code[4:].split(";"):
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


def find_codes(csv_path):
    """Yield every DG1 code found in any cell of the CSV (robust to column order)."""
    with open(csv_path, newline="", encoding="utf-8-sig") as fh:
        for row in csv.reader(fh):
            for cell in row:
                if cell and "DG1;" in cell:
                    yield cell[cell.index("DG1;"):]


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

    submissions = 0
    for code in find_codes(args.csv):
        submissions += 1
        for delve, variant, avg_tier, avg_sec, count in parse_code(code):
            if avg_tier < args.min_tier:
                continue
            key = (delve, variant)
            tot_sec[key] += avg_sec * count
            tot_runs[key] += count
            tot_tier[key] += avg_tier * count

    if not tot_runs:
        print(f"No DelveGuide (DG1) submission codes found in {args.csv}.")
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
          f"(filters: >={args.min_runs} runs, avg tier >={args.min_tier})\n")

    lua = []
    for delve in sorted(by_delve):
        variants = sorted(by_delve[delve], key=lambda r: r["avg_sec"])
        fastest = variants[0]["avg_sec"]
        print(f"== {delve} ==")
        for r in variants:
            letter = suggest_letter(r["avg_sec"], fastest)
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


if __name__ == "__main__":
    main()
