#!/usr/bin/env python3
"""Validate DelveGuide localeVariants: every VALUE must be a canonical
variant name that exists in DelveGuideData.delves, otherwise the localized
client resolves to a name nothing matches (delve silently never shows active).
"""
import re, sys

path = r"C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\DelveGuide\DelveGuide_Data.lua"
src = open(path, encoding="utf-8").read()

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
    print(f"!! {len(bad)} mapping(s) point to a NON-canonical name (these silently fail):")
    for k, v in bad:
        # closest canonical match for context
        near = [c for c in canon if c.lower().replace("d ", " ") == v.lower().replace("d ", " ")]
        hint = f"   -> did you mean: {near[0]!r}" if near else ""
        print(f"   [{k!r}] = {v!r}{hint}")
else:
    print("All localeVariants values resolve to canonical variant names.")

# --- also flag canonical variants with no localization at all ---
covered = {v for _, v in pairs}
missing = sorted(canon - covered)
print(f"\ncanonical variants with NO locale mapping ({len(missing)}):")
for m in missing:
    print(f"   {m}")
