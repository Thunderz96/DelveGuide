#!/usr/bin/env python3
"""Validate DelveGuide localeVariants: every VALUE must be a canonical
variant name that exists in DelveGuideData.delves, otherwise the localized
client resolves to a name nothing matches (delve silently never shows active).

Also checks for duplicate locale keys and for substring collisions between
canonical English names and locale keys. Exits non-zero if anything fails.
"""
import re, sys, os

# Resolve the data file next to this script's repo root, not the CWD, so the
# validator works from anywhere (and checks the checkout, not an installed copy).
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, "DelveGuide_Data.lua")
path = os.path.normpath(path)
src = open(path, encoding="utf-8").read()

failures = 0

# --- canonical variant names from the delves table ---
delves_block = src.split("DelveGuideData.delves = {", 1)[1]
delves_block = delves_block.split("\n}", 1)[0]
canon = set(re.findall(r'variant="([^"]+)"', delves_block))

# --- localeVariants mappings ---
loc_block = src.split("DelveGuideData.localeVariants = {", 1)[1]
loc_block = loc_block.split("\n}", 1)[0]
pairs = re.findall(r'\["([^"]+)"\]\s*=\s*"([^"]+)"', loc_block)

print(f"canonical variants in delves: {len(canon)}")
print(f"localeVariants mappings:      {len(pairs)}\n")

bad = [(k, v) for k, v in pairs if v not in canon]
if bad:
    failures += len(bad)
    print(f"!! {len(bad)} mapping(s) point to a NON-canonical name (these silently fail):")
    for k, v in bad:
        # closest canonical match for context
        near = [c for c in canon if c.lower().replace("d ", " ") == v.lower().replace("d ", " ")]
        hint = f"   -> did you mean: {near[0]!r}" if near else ""
        print(f"   [{k!r}] = {v!r}{hint}")
else:
    print("All localeVariants values resolve to canonical variant names.")

# --- duplicate locale keys ---
# Lua keeps the LAST assignment silently, so a repeated key means one of the two
# translations in the file is dead and nobody gets told.
seen, dupes = {}, []
for k, v in pairs:
    if k in seen:
        dupes.append((k, seen[k], v))
    seen[k] = v
if dupes:
    failures += len(dupes)
    print(f"\n!! {len(dupes)} duplicate locale key(s) -- Lua keeps only the last:")
    for k, first, last in dupes:
        print(f"   [{k!r}]: {first!r} then {last!r}")
else:
    print("\nNo duplicate locale keys.")

# --- substring collisions ---
# The scanner substring-matches canonical English names against widget text
# FIRST, and only falls back to locale keys if nothing matched. So if a
# canonical name is contained in a locale key, that locale's widget text hits
# the English loop and resolves to the WRONG variant before the locale entry is
# ever consulted.
collisions = [(c, k, v) for k, v in pairs for c in canon if c != v and c in k]
if collisions:
    failures += len(collisions)
    print(f"\n!! {len(collisions)} substring collision(s) -- English name hides inside a locale key:")
    for c, k, v in collisions:
        print(f"   canonical {c!r} is inside locale key {k!r} (which means {v!r})")
else:
    print("No canonical variant name is a substring of a locale key for another variant.")

# --- also flag canonical variants with no localization at all ---
covered = {v for _, v in pairs}
missing = sorted(canon - covered)
print(f"\ncanonical variants with NO locale mapping ({len(missing)}):")
for m in missing:
    print(f"   {m}")

sys.exit(1 if failures else 0)
