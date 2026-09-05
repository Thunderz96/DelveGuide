# PTR findings — Midnight 12.1.5, build 69594

**Captured:** 2026-09-05, Thunderclapz-Fyrakk (XPTR), DelveGuide 1.11.0, interface 120105.
**Method:** `/dg export` snapshots pulled from SavedVariables on disk, plus `/dump` in chat.
Raw snapshots are in `DelveGuideDB.ptrExports` — timestamps `02:01:12` (outdoors),
`02:03:23` (Collegiate Calamity), `02:10:14` (Kindo'jan).

This document records what the running game returned. It supersedes assumptions in
`DelveGuide_2.0_Plan.md` §5 where the two disagree, and flags where a finding rests on a
single sample.

---

## 1. Headline: Labyrinths are scenario type 8, same as Delves

The `scenarioType == 8` gate in `DelveGuide.lua:1882` **fires inside a Labyrinth**.
`diffID` and `diffName` are identical too. Every cheap, locale-free signal the addon
currently uses says "this is a delve".

| Field | Collegiate Calamity | Kindo'jan | Same? |
|---|---|---|---|
| scenario type `[10]` | 8 | 8 | yes |
| `diffID` | 208 | 208 | yes |
| `diffName` | "Delves" | "Delves" | yes |
| **scenario flags `[4]`** | **18** | **146** | **no** |
| scenarioID `[13]` | 3193 | 3580 | no |
| instanceID | 2933 | 3043 | no |
| numStages | 3 | 2 | no |

**Consequence today:** a completed Labyrinth run logs a history row with `variant=nil`,
because no outdoor variant text resolves for widget set 2316. This is the §2 data-loss
path, now observed rather than inferred. It was not triggered during capture only because
the export was taken before completing the run.

### The discriminator: flags bit 7

```
delve      18 = 0b0_0010010
labyrinth 146 = 0b1_0010010
                 ^ bit 7 (128) set only on the Labyrinth
```

146 - 18 = 128 exactly. Proposed gate:

```lua
local flags = select(4, C_Scenario.GetInfo())
local isLabyrinth = flags and bit.band(flags, 128) ~= 0
```

⚠️ **One sample each.** Before Stage 2 builds on this, confirm against a second delve and,
once it exists, Labyrinth B. If bit 7 does not hold, fall back to `instanceID` /
`scenarioID` allowlists, which are verified below.

---

## 2. Verified IDs

Confirmed in a running 12.1.5 client, not read from data files.

| Thing | ID | Notes |
|---|---|---|
| Kindo'jan instanceID | **3043** | answers 2.0 plan §5 item 5 |
| Kindo'jan scenarioID | **3580** | scenario name "Soul King" |
| Kindo'jan widgetSetID | **2316** | stable across all 3 outdoor maps |
| Kindo'jan poiID | 9035 (maps 2437, 2395), 9037 (map 2537) | varies by map — key on the set |
| Kindo'jan instance mapID | 2647 | parent 2437 |
| Collegiate Calamity instanceID | 2933 | matches prior research |
| Collegiate Calamity scenarioID | 3193 | scenario name "Delves" |
| Item: Kindo'jan | 285875 | Vault credit + Heroic Soul Fragment, Tier 8+, 1/week/char |
| Item: Heroic Soul Fragment | 285807 | Hero 2/6; 3 combine into a random Hero 2/6 piece |
| Spell: Labyrinth Chambers | 1314915 | 9 chambers; rewards every 3; min 3 unlocks next tier |

**Kindo'jan appears outdoors through the delve POI API.** `C_AreaPoiInfo.GetDelvesForMap`
returns it on maps 2437, 2395 and 2537. Its atlas is `overworld-active-64x64`, not
`delves-regular` like all twelve rotational delves — the only outdoor signal that
distinguishes it. This corroborates the plan's §2 conclusion that the "do NOT key anything
on poiID" comment in `DelveGuide_Data.lua:106-109` is wrong: the *set* is stable, the
poiID is stable per (delve, map, bountiful state).

---

## 3. Answers to 2.0 plan §5

| # | Question | Answer |
|---|---|---|
| 1 | scenarioID stable across tiers / bountiful | **not yet tested** — needs 2 tiers + 1 bountiful |
| 2 | Nemesis lair scenarioID (expect 3395) | **not yet tested** |
| 3 | scenario readable at `SCENARIO_COMPLETED` | **not yet tested** |
| 4 | `C_DelvesUI.GetActiveDelveTier()` returns a tier | **assumption was wrong** — see below |
| 5 | Labyrinth scenario type / scenario ID / instance ID | **answered** — 8 / 3580 / 3043 |

### §5 item 4 correction

The plan assumed this "returns a tier number". It returns a **table**, and inside the
Labyrinth every field is empty despite the run visibly being Tier 11:

```
{ tier=0, unlocked=false, suggestedILvl=0, difficultyID=0,
  modifierUIWidgetSetID=0, overrideTooltipSpellID=0,
  queueAsLFG=false, tierDescription="", rewards={} }
```

So the objective-tracker scrape **cannot** be retired for Labyrinths. Whether it works in a
regular delve is untested — that single command is the cheapest open item.

---

## 4. Bugs and risks found

**4.1 Case mismatch in the delve name.** The POI returns `The Labyrinth of Kindo'jan`
(lowercase j); the zone and instance name return `The Labyrinth of Kindo'Jan` (capital J).
Any exact string comparison between POI name and zone name fails silently. More evidence
for ID-based identity.

**4.2 Widget set 2316 yields no usable variant text.** Outdoors, Kindo'jan is quarantined
as `[Missing Translation] Unknown Variant Text`. Nothing was written to
`DelveGuideDB.missingTranslations`, which per `DelveGuide.lua:333` means `safeText` was
`nil` — the widget returned no single-line string under 120 chars, not a string lacking a
translation. A text-matching path meets the new content type and gets nothing at all.

**4.3 Scenario naming inverts between the two types.**

| | `scenario[1]` | step name |
|---|---|---|
| Delve | "Delves" (generic) | "Collegiate Calamity" (the delve) |
| Labyrinth | "Soul King" (proper noun) | "Soul Survivor" |

Code that treats `scenario[1]` as a category will read a proper noun inside a Labyrinth.

**4.4 `numStages` does not track chambers.** It reported 2 while the Labyrinth advertises
9 chambers. Chamber progress needs its own source — see 5.1, `subzone` is a candidate.

**4.5 `mapName` is an unlocalized internal string:** `12_15_Labyrinth_A`. Do not display
it. The `_A` suffix implies further Labyrinths, which is worth accounting for in the data
model rather than hardcoding one.

---

## 5. Content notes (from in-game tooltips)

### 5.1 Layout — chambers are named sub-areas

The in-game map names its regions after Zul'Aman's bosses: **Akil'zon's Roost**,
**Nalorakk's Den**, **Halazzi's Lair**, **The Cave Towers**, and **Chamber of Rites**.
The Labyrinth is built on Zul'Aman geography rather than delve geometry.

`GetSubZoneText()` returned **"Chamber of Rites"** in the 02:10:14 snapshot, matching the
map label. So subzone tracks which chamber the player is standing in, and is the most
promising source for chamber progress given `numStages` does not carry it (4.4).

Two caveats before relying on it: subzone strings are **localized**, so this reintroduces
exactly the text-matching problem ID-based identity exists to remove; and it reports
*location*, not *completion* — standing in a chamber is not clearing it. Treat it as a
position signal, and find a separate completion source.

Access is gated through Akil'zon's Roost (see below), so the sub-areas are ordered rather
than free-roam.


- Tier 11 exists. "Fabled Let Me Solo Him: Kindo'jan" requires Tier 11, solo, before the
  first weekly reset — **first week only**, so it is time-boxed content.
- Kindo'jan must be beaten in a Tier 8+ Labyrinth for Vault credit + a Heroic Soul
  Fragment, once per week per character.
- Access gate: clear all nine chambers, then gain entry via Akil'zon's Roost. Once proven,
  Kindo'jan's chamber can be entered at will.
- Heavy Trunk Crest rewards are doubled inside Labyrinths.
- Companion is Valeera, as in Delves — the Companion tab shape carries over
  (`companionID = 12` resolved normally inside both).

---

## 6. Open items, cheapest first

1. `/dump C_DelvesUI.GetActiveDelveTier()` inside a **regular delve** — decides whether the
   tracker scrape can go for Delves at least.
2. `/dump C_Scenario.GetInfo()` in a **second delve** — confirms flags 18 is not a
   coincidence of Collegiate Calamity.
3. Same in a **bountiful** delve and at a **second tier** — plan §5 item 1.
4. Same in a **Nemesis lair** — plan §5 item 2, expect scenarioID 3395.
5. Whether scenario info survives to `SCENARIO_COMPLETED` — plan §5 item 3.
6. Re-check widget set 2316's texts once Blizzard populates PTR localization.

---

## Appendix: environment

The PTR client hard-crashes on login with **Plater** enabled — `ERROR #110` in
`PlayerConditions_C.cpp:765`. `Plater_Auras.lua:279` brute-force scans spell IDs
255001-257501; ID 255616 resolves to PlayerCondition 53723 -> Aura 257321, absent from
build 69594's DBC, and the client asserts. Not a DelveGuide issue. Plater is moved to
`_xptr_\Interface\AddOns_Disabled`. Any addon doing range spell-ID scans is suspect on a
fresh PTR build.
