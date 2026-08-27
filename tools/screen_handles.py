#!/usr/bin/env python3
"""
DelveGuide -- contributor handle screening.

Handles are free text typed by strangers into a public Google Form, and they get
written verbatim into DelveGuideData.contributors and shipped to every user. Two
separate risks:

  1. STRUCTURAL -- the handle lands inside a Lua string literal. A double quote or
     backslash breaks the file for everyone; WoW colour escapes (|cFFFF0000) let a
     submitter style or hide text on the Settings tab.
  2. CONTENT -- profanity, slurs, impersonation, advertising.

This script FLAGS; it never decides. Read the output and choose. An unflagged
handle is not "approved", it just did not trip a rule -- always eyeball the NEW
list, because no word list catches everything.

Usage:
    python tools/screen_handles.py tools/responses.csv
    python tools/screen_handles.py tools/responses.csv --new-only
"""

import re
import csv
import sys
import argparse
import unicodedata

# Characters that break or abuse the Lua string literal they are pasted into.
LUA_BREAKING = {chr(34), chr(92), chr(10), chr(13), chr(91), chr(93), chr(123), chr(125), chr(124)}

# Impersonating the author, the addon, or Blizzard staff.
IMPERSONATION = ["blizzard", "blizz", "gamemaster", "game master", "gmteam",
                 "delveguide", "thunderz", "admin", "moderator", "official", "support"]

# Obvious content flags. Deliberately short -- this is a tripwire, not a filter.
# Matched against a leetspeak-normalised, punctuation-stripped form.
PROFANITY = ["fuck", "shit", "cunt", "bitch", "bastard", "dick", "cock", "penis",
             "vagina", "butthole", "asshole", "anus", "rectum", "scrotum", "testicle",
             "nigger", "nigga", "faggot", "fagot", "retard", "tranny", "kike", "spic",
             "chink", "wetback", "rape", "rapist", "nazi", "hitler", "kkk",
             "porn", "pornhub", "onlyfans", "sex", "cum", "jizz", "wank", "boner",
             "titties", "boobs", "nutsack", "ballsack", "queef", "smegma"]

# Known-good handles that would otherwise trip a rule forever. Keep this tiny --
# a screener that always prints a flag gets ignored, which is the real failure.
ALLOWLIST = {"thunderz"}   # the author's own handle, trips IMPERSONATION

LEET = str.maketrans({"0": "o", "1": "i", "3": "e", "4": "a", "5": "s",
                      "7": "t", "8": "b", "@": "a", "$": "s", "!": "i"})


def normalise(name):
    """Fold to a comparable form: lowercase, de-accent, de-leet, strip non-letters."""
    n = unicodedata.normalize("NFKD", name)
    n = "".join(c for c in n if not unicodedata.combining(c))
    n = n.lower().translate(LEET)
    return re.sub(r"[^a-z]", "", n)


def screen(name):
    """Return a list of reasons this handle deserves a human look."""
    flags = []
    if normalise(name) in ALLOWLIST:
        return flags
    hit = LUA_BREAKING & set(name)
    if hit:
        flags.append("BREAKS LUA: " + " ".join(repr(c) for c in sorted(hit)))
    if re.search(r"\|c[0-9a-fA-F]{8}|\|cn[\w_]+:|\|r|\|T|\|A|\|H", name):
        flags.append("WOW MARKUP -- can colour/hide text on the Settings tab")
    if any(unicodedata.category(c) in ("Cc", "Cf") for c in name):
        flags.append("CONTROL/INVISIBLE CHARACTER")
    if re.search(r"https?://|www\.|\.com|\.net|discord\.gg", name, re.I):
        flags.append("URL / ADVERTISING")
    if len(name) > 24:
        flags.append(f"UNUSUALLY LONG ({len(name)} chars)")
    # Someone typing a command instead of a name. Two submissions arrived as
    # "/handle Jemhadar" and "/handle jemhadar-Saurfang-EU" -- the intended handle
    # is obviously "Jemhadar", and shipping the literal string would look broken.
    # Usually means the form's wording was read as a command prompt.
    if name.lstrip().startswith("/"):
        flags.append("LOOKS LIKE A COMMAND -- probably meant just the name after it")
    if re.match(r"^\s*(handle|name|nick|user|my name is|im|i am)[\s:=-]+", name, re.I):
        flags.append("PREFIXED WITH A LABEL -- probably meant just the value after it")

    flat = normalise(name)
    for w in PROFANITY:
        if w in flat:
            flags.append(f"PROFANITY/SLUR: matched {w!r}")
            break
    for w in IMPERSONATION:
        if w.replace(" ", "") in flat:
            flags.append(f"IMPERSONATION: matched {w!r}")
            break
    return flags


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv", help="CSV export of the Google Form responses")
    ap.add_argument("--data", default="DelveGuide_Data.lua",
                    help="data file, to tell already-credited handles from new ones")
    ap.add_argument("--new-only", action="store_true",
                    help="only show handles not already credited")
    ap.add_argument("--col", type=int, default=2,
                    help="0-based CSV column holding the handle (default 2). The form is "
                         "Timestamp / DG1 code / handle / spare / feedback. Guessing the "
                         "column by shape pulls in free-text feedback, so it is pinned.")
    args = ap.parse_args()

    seen, handles = set(), []
    for row in list(csv.reader(open(args.csv, encoding="utf-8-sig")))[1:]:
        if len(row) <= args.col:
            continue
        c = row[args.col].strip()
        if c and c.lower() not in seen:
            seen.add(c.lower())
            handles.append(c)

    try:
        src = open(args.data, encoding="utf-8").read()
        block = re.search(r"^DelveGuideData\.contributors = \{(.*?)^\}", src, re.S | re.M).group(1)
        credited = {n.lower() for n in re.findall(r'"([^"]+)"', block)}
    except Exception:
        credited = set()

    new = [h for h in handles if h.lower() not in credited]
    pool = new if args.new_only else handles

    print(f"{len(handles)} handle(s) in {args.csv}  --  {len(new)} not yet credited\n")

    flagged = [(h, f) for h in pool if (f := screen(h))]
    if flagged:
        print("=== FLAGGED -- read these before shipping ===")
        for h, f in flagged:
            tag = "NEW" if h.lower() not in credited else "already shipping"
            print(f"  {h!r}  [{tag}]")
            for x in f:
                print(f"      - {x}")
        print()
    else:
        print("=== nothing tripped a rule ===\n")

    if new:
        print("=== NEW handles -- eyeball this list, the word list is not exhaustive ===")
        for i in range(0, len(new), 5):
            print("   " + "  ".join(f"{x:<22}" for x in new[i:i + 5]))
    print(f"\nExit: {'REVIEW NEEDED' if flagged else 'no automatic flags'}")
    return 1 if flagged else 0


if __name__ == "__main__":
    sys.exit(main())
