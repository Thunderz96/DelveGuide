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

**Consequence, now observed.** A completed Labyrinth step logged exactly the predicted row:

```
[DelveGuide] Logged: The Labyrinth of Kindo'Jan  [?]  [Vault: 305 ilvl]
```

```lua
["history"][1] = {
    ["char"]      = "Thunderclapz",
    ["name"]      = "The Labyrinth of Kindo'Jan",
    ["resetKey"]  = 1788271200,
    ["date"]      = "2026-09-05 02:32",
    ["tier"]      = "?",
    ["vaultIlvl"] = 305,
    ["realm"]     = "Fyrakk",
}
```

**Worse than predicted.** The plan expected `variant=nil`. In the stored row the `variant`
key is **absent entirely**, and `tier` is also lost (`"?"`), because
`C_DelvesUI.GetActiveDelveTier()` returns zeros here (§3) and the tracker scrape does not
recognise the Labyrinth. Only `name` and `vaultIlvl` (305) survived. The `[?]` in chat — no outdoor variant text resolves for widget set 2316. This
is the §2 data-loss path as an artifact rather than an inference. The delve name and vault
ilvl were captured correctly; only the variant was lost.

### ~~The discriminator: flags bit 7~~ — RETRACTED, use instanceID

An earlier reading of this document proposed scenario flags bit 7 (delve 18 / labyrinth 146)
as the Labyrinth discriminator. **That is wrong and must not be built on.**

Observed at 02:32 on 2026-09-05, inside Kindo'jan, after killing the step-1 boss
(`ENCOUNTER_START,3648,"King of Souls",208,1,3043`), `C_Scenario.GetInfo()` returned:

| | before boss | after boss |
|---|---|---|
| name `[1]` | "Soul King" | **"Delves"** |
| flags `[4]` | 146 | **18** |
| scenarioID `[13]` | 3580 | **3342** |
| numStages | 2 | 1 |

The combat log proves this was **not** a zone change: exactly one `ZONE_CHANGE` and one
`MAP_CHANGE` for the whole session (both at 02:17 into instance 3043), and every creature
GUID in the log carries instance 3043. The scenario swapped underneath a stationary player.

So flags, scenarioID, numStages and the scenario name all describe the **current scenario
phase**, not the run type. A Labyrinth sampled at the wrong moment is indistinguishable
from a Delve on every one of them. Any gate gets the answer right on entry and wrong later.

**Use instanceID instead.** It is stable for the whole run and verified from three
independent sources: `GetInstanceInfo()` returned 3043, every combat-log creature GUID
embeds 3043, and `ZONE_CHANGE,3043` fired once on entry and never again.

```lua
local _,_,_,_,_,_,_, instanceID = GetInstanceInfo()
local isLabyrinth = DelveGuideData.labyrinthInstances[instanceID]
```

This costs an allowlist that grows with each new Labyrinth, which is the tradeoff for
correctness. Capture the instanceID of Labyrinth B when it appears.

⚠️ Still unverified: whether instanceID is stable across tiers and bountiful state. Prior
research says instance maps are fixed per delve, and nothing here contradicts that, but it
has not been tested for Labyrinths.

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
| **Vault credit rule** | — | **Every 3 chambers (3 / 6 / 9), any tier** — confirmed by Nick 2026-09-06. The Kindo'jan kill at T8+ is a *separate* reward (Heroic Soul Fragment); an earlier reading of this doc conflated the two |

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
| 3 | scenario readable at `SCENARIO_COMPLETED` | **answered for Labyrinth chambers (2026-09-06):** `GetInfo()` still returns name + scenarioID; `GetStepInfo()` and criteria are already torn down. Capture the ID at completion; anything step-level earlier |
| 4 | `C_DelvesUI.GetActiveDelveTier()` returns a tier | **no** — empty struct in both. **But the tier IS available as data elsewhere:** see §3.1 |
| 5 | Labyrinth scenario type / scenario ID / instance ID | **answered** — 8 / 3580 / 3043 |

### §5 item 4 correction — the tracker scrape cannot be retired

The plan assumed this "returns a tier number". It returns a **table**, and every field is
empty in both content types:

```
{ tier=0, unlocked=false, suggestedILvl=0, difficultyID=0,
  modifierUIWidgetSetID=0, overrideTooltipSpellID=0,
  queueAsLFG=false, tierDescription="", rewards={} }
```

Verified inside **Atal'Aman, a regular Delve, at tier 8** — while the addon's own tracker
scrape correctly reported `tierNum = 8` in the same snapshot. So this is not a Labyrinth
quirk: the API is empty for Delves too.

**The whole-frame-tree walk was the wrong fix for the right idea.** `GetActiveDelveTier` is
empty, but the tier is exposed as data by a different API — §3.1 below — so the scrape can
be retired after all, once that source is confirmed at a second tier and in a Labyrinth.

### §3.1 The tier source: the delve header widget (2026-09-06)

The scenario step's widget set (12th return of `C_Scenario.GetStepInfo`, **842** in every
delve and Labyrinth snapshot) holds a **`ScenarioHeaderDelves` widget, type 29**. Its
visualization info via `C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo`
carries, verified in Twilight Crypts at Tier 8 across three snapshots:

```
tierText = "8"   headerText = "Twilight Crypts"   frameTextureKit = "delves-scenario"
tierTooltipSpellID = 1260965   currencies = {...}   spells = {...}   rewardInfo = {...}
```

`tierText` is the tier exactly as the objective tracker renders it — the very text the
frame-tree scrape has been reading off FontStrings since 12.0. Read as data it is one API
call. `DelveGuide.ReadDelveHeaderWidget` does so and the HUD uses it as Method 0 with every
older method still behind it.

**Confirmed 2026-09-06 at Tier 8 and Tier 9 in delves (Twilight Crypts) and Tier 11 in the
Labyrinth** — the conditions set for retiring the scrape are met. Methods 1–3 stay behind
Method 0 for 2.0.0 and only run if the widget read fails; remove them in 2.1 if no misses are
reported.

**Lives live in the same widget.** `currencies[1]`: `text = "3"`, `tooltip =
"|Hspell:458103|h|nTotal deaths: 0"`, `iconFileID = 6013778`. Matched on the spell link or
icon, never wording, so it holds on every locale. `DelveGuide.ReadDelveLives` returns lives and
deaths; `ReadLivesText` uses it first. The criteria scan that never found lives is now a
fallback only (`hud-victory#7` / `#17` closed).

Other fields seen: `headerText` is the *chamber* name inside a Labyrinth ("Voices in the
Halls") and the delve name in a delve; `spells[]` holds the header's spell icons (1318775,
462940 on 69594); `rewardInfo` has earned/unearned tooltips (spells 463212/463213);
`tierTooltipSpellID` differs by tier (1260965 at 8, 1260975 at 11).

Related: the addon's tier detection works in Delves (`tierNum = 8`) but returns nil in
Labyrinths (5.8), so the scrape is Delve-shaped and does not generalise.

## 4. Bugs and risks found

**4.1 Case mismatch in the delve name.** The POI returns `The Labyrinth of Kindo'jan`
(lowercase j); the zone and instance name return `The Labyrinth of Kindo'Jan` (capital J).
Any exact string comparison between POI name and zone name fails silently. More evidence
for ID-based identity. Observed live: `/dg huddump` reports
`localizedToEnglish[The Labyrinth of Kindo'Jan] = nil`.

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

**4.6 BREAKING: scenario criteria moved namespace.** `C_Scenario.GetNumCriteria` and
`C_Scenario.GetCriteriaInfo` are **removed** in 12.1.5. Criteria now live on
`C_ScenarioInfo.GetCriteriaInfo`, which returns the same field names
(`description`, `quantity`, `totalQuantity`, `quantityString`) — only the namespace moved.

This is not Labyrinth-specific; it affects Delves equally, and it is the most shippable
finding here. Six call sites were affected, all inside `pcall`, so the removal produced
**no Lua error and no BugSack entry** — the HUD silently stopped showing lives and
objectives:

| File | Lines | Symptom |
|---|---|---|
| `DelveGuide_HUD.lua` | 456, 458 | lives counter falls back to `--` |
| `DelveGuide_HUD.lua` | 549, 551 | `SCENARIO_CRITERIA_UPDATE` refresh does nothing |
| `DelveGuide.lua` | 1385, 1388 | `/dg huddump` reports 0 criteria |

Fixed via `DelveGuide.GetCriteriaCount()` / `DelveGuide.GetCriteria(i)`, which prefer the
new namespace and keep the old as fallback so one build serves 12.1.0 and 12.1.5. The count
comes from the 3rd return of `C_Scenario.GetStepInfo()`, which survives. Verified in-game
on 69594 inside Kindo'jan: `count: 1`, `crit[1] desc=[Defeat Hexbound Defenders] qty=5 total=6`.

**Surviving `C_Scenario` functions** (confirmed on 69594): `GetInfo`, `GetStepInfo`,
`IsInScenario`.

**4.7 A second removal: the global `GetItemInfoInstant`.** Found 2026-09-06 by `/dg selftest`
on its first PTR run: the Loot tab errored on every render (`UI_Loot.lua:20: attempt to call
a nil value`). 12.1.5 deleted the deprecated global shims; the addon had migrated
`GetItemCount` and `GetDetailedItemLevelInfo` to `C_Item` but not this one, and the API
research (`API_12.1.5_Research.md`) swept only `C_*` calls plus a fixed list of globals, so
it was invisible there too. Fixed with `C_Item.GetItemInfoInstant` (identical returns) and
the global kept as a 12.1.0 fallback. A sweep of every other deprecated global the 12.x line
has been deleting found no further bare uses. **Lesson:** rendering every tab under `pcall`
catches what static sweeps miss; the selftest earned its place on day one.

**Chamber progress source.** Criteria give quantified, locale-free progress (5/6), which is
a better source than the subzone approach in 5.1 — it measures completion rather than
position and needs no string matching. Chambers are sequentially gated (the door to
Halazzi's Lair stays shut until the current step completes), so criteria and chamber order
line up.

**4.5 `mapName` is an unlocalized internal string:** `12_15_Labyrinth_A`. Do not display
it. The `_A` suffix implies further Labyrinths, which is worth accounting for in the data
model rather than hardcoding one.

---

**4.8 The Pre-Entry Checklist has never fired automatically.** Raised by Nick 2026-09-06.
Its trigger compared `UnitName("target")` to delve names, but a delve entrance is a game
object, not a targetable unit, so the event never carried a delve name. Every appearance of
the checklist -- and every review measurement of its rows -- came through `/dg check`. The
README's "triggers automatically when you target a Delve entrance" described a path that
cannot happen. Fixed: it now opens with the entrance dialog
(`PLAYER_INTERACTION_MANAGER_FRAME_SHOW`, matched by
the interaction type seen). **The type is 79 on 69594** — recorded at a delve entrance and at
the Labyrinth's — and `Enum.PlayerInteractionType` has no `DelvesDifficultyPicker` member
there, so the enum is searched for a Delve-named key and 79 is the fallback. The literal 3 the
code assumed since 12.0 is the trainer type. ⚠️ The popup itself is still unverified; the
first build that could fire it is the one after this note.

**4.9 Delve glove enhancements (Wowhead datamine, 2026-09-06).** Four permanent bonuses
that apply "while inside delve content" -- all delves, not only Labyrinths -- restricted to
gloves of item level 334 or below (which excludes the 344 raid gloves; Wowhead suspects an
oversight). Names, enchant IDs and acquisition are unknown; the article says so. Scaffolded
as a checklist row keyed on the gloves' enchant ID, with the table empty until an export
taken with one applied supplies the ID. The row speaks only when definite.

## 5. Content notes (from in-game tooltips)

### 5.1 A Labyrinth run is choose-your-path, push-your-luck

Corrects an earlier reading of this document that called the chambers "sequentially gated".
They are gated, but the **order is the player's choice**, and the run is a bank-or-continue
loop rather than a fixed clear.

Between chambers the scenario step is **"Choose Your Path"**, described by Blizzard as:

> Select the next chamber you wish to challenge in the Labyrinth, or speak to Kinduru if
> you wish to end your run.

And entering the next chamber prompts:

> Continue into the Reliquary? ... Continue your run to gather more rewards, at the risk of
> increased challenge.

So difficulty and rewards escalate per chamber, and the player can stop and bank at any
point via the NPC Kinduru. **This does not fit the addon's delve model** — one variant, one
tier, run to completion. A Labyrinth run is a variable-length chain of chosen chambers with
an explicit bail-out, so run history, timing and "rankings" all need a different shape here.
Do not try to force it into the existing history row.

### 5.2 Progression is a taxi network — verified

The instance has its own flight map (`taxiMapID = 2671`, internal name
`12_15_Labyrinth_Taxi`). `C_TaxiMap.GetAllTaxiNodes(GetTaxiMapID())` returns the node table;
`GetTaxiMapID` is a **global**, not a member of `C_TaxiMap`.

Node `state` is confirmed by cross-checking the classic `TaxiNodeGetType` strings:

| state | classic type | meaning |
|---|---|---|
| 0 | `CURRENT` | where the player is |
| 1 | `REACHABLE` | unlocked, can fly there now |
| 2 | `DISTANT` | not yet unlocked |

**Progress = counting nodes that have left state 2.** Numeric node IDs, a property of the
instance rather than the current scenario phase, so it survives the scenario swap in §1.

**The 9-chamber count is resolved.** 11 nodes were returned, but names are not unique:

| Node ID | Name | state |
|---|---|---|
| 3300 | Chamber of Rites | 0 CURRENT |
| 3301 | Entrance to The Reliquary | 1 REACHABLE |
| 3305 | Entrance to Halazzi's Lair | 2 |
| 3307 | Entrance to The Central Chamber | 2 |
| 3309 | Entrance to The Catacombs | 2 |
| 3311 | Entrance to The Central Chamber | 2 |
| 3312 | Entrance to The Cave Towers | 2 |
| 3314 | Entrance to Jan'alai's Refuge | 2 |
| 3316 | Entrance to Akil'zon's Roost | 2 |
| 3318 | Entrance to Nalorakk's Den | 2 |
| 3329 | Entrance to The Catacombs | 2 |

"The Central Chamber" appears twice (3307, 3311) at **different** coordinates — two
entrances to one chamber. "The Catacombs" appears twice (3309, 3329) at **identical**
coordinates — a genuine duplicate node. Deduplicating gives exactly **9 destinations**,
matching the advertised nine chambers.

⚠️ Node names are therefore **not unique keys**, and they are localized. Key on node ID, and
curate an ID -> chamber mapping rather than counting names.

### 5.1b The outdoor variant-key experiment: closed, negative

The review (§7.4, speculative) proposed that `widgetTag` / `textureKit` / `orderIndex` on
a delve's widget set might carry a locale-free variant key. `/dg selftest` on 2026-09-06
printed those fields for all twelve rotational delves plus the Labyrinth: **`widgetTag` is
the empty string and `textureKit` is `nil` on every one**; `orderIndex` only distinguishes
the two widgets a bountiful set carries (coffer blurb, variant). There is nothing to compare
across days. The honest limit stands: outdoors, the variant reaches the client only as text.

### 5.1c The hub is a scenario step with its own criteria

Seen live 2026-09-06 in the D6 HUD: between chambers the hub reports step **"Choose Your
Path"** with two count-type criteria, **"Speak to Kinduru 0/1"** and **"Path chosen 0/1"**.
So the hub is not criteria-free; anything that treats "no criteria" as "in the hub" is
wrong. The generic scenario name ("Delves") remains the hub's only cheap signature.

### 5.2a Chambers are separate scenarios, and the content is unfinished

Each chamber runs its own scenario. Three observed inside instance 3043:

| scenarioID | name | flags | context |
|---|---|---|---|
| 3580 | "Soul King" | 146 | step-1 chamber |
| 3342 | "Delves" | 18 | the "Choose Your Path" hub |
| 3345 | **"[PH] Soul Jars"** | 146 | a later chamber |

`[PH]` is Blizzard's own placeholder marker — this content is visibly mid-development, so
**names and IDs may still move before launch.** Re-verify everything here against a later
build rather than treating it as final.

Note flags 146 appears in chambers and 18 in the hub, so bit 7 tracks *chamber vs hub*, not
Labyrinth vs Delve. Consistent with the §1 retraction.

The chamber-entry prompt art is themed rather than per-chamber: "Halazzi's Lair" reuses the
identical portrait and body text as "The Reliquary" ("ominous chants of dark rituals"),
while "The Central Chamber" has its own goblin-shredder art. More placeholder reuse.

**Criteria come in two shapes.** The step-1 chamber used a count (`qty=5, total=6,
qtyStr="5"`); the "[PH] Soul Jars" chamber uses a percentage (`qty=0, total=100,
qtyStr="0%", cflags=32`). Any HUD progress display must handle both.

### 5.3 New reputation

12.1.5 adds a faction named **"The Labyrinth of Kindo'jan"** (note the lowercase `j`, as on
the POI, not the capitalised `Kindo'Jan` used by the zone — see 4.1). Nick wants this
tracked in the addon.

The factionID is **still not captured**. The first attempt returned only 9 factions and
missed it: `C_Reputation.GetNumFactions()` enumerates only rows that are currently
*visible*, so collapsed headers hide most of the list. `/dg export` now expands every header
before scanning (which leaves the Reputation pane expanded as a side effect). Tracking itself is Stage 3 feature work, not a 12.1.5 compatibility fix.

### 5.4 Encounter IDs — boss chambers only

| Encounter | ID | Notes |
|---|---|---|
| King of Souls | **3648** | `ENCOUNTER_START,3648,"King of Souls",208,1,3043`, ended success=1 |
| Drill Sergeant | **3622** | success=1, 82s (Case B) |
| The Undead Trollbunal | **3632** | success=true, captured by D3 with no combat log (Case C) |

⚠️ **Corrects an earlier claim in this document.** `ENCOUNTER_START`/`END` are *not* a
general per-chamber completion signal. Over a 34-minute run (02:17-02:51) covering several
chambers, exactly one encounter pair fired — the King of Souls boss. The objective chamber
"Disrupt the Vilebranch" produced none at all despite 44 mob kills.

So chambers come in at least two kinds:

| Chamber kind | Completion signal | Example |
|---|---|---|
| Boss | `ENCOUNTER_START` / `ENCOUNTER_END` + criteria | King of Souls (3648) |
| Objective | criteria only (percentage) | "Disrupt the Vilebranch" (`0%`, total 100) |

Any completion tracking must read criteria; encounter events are a bonus on boss chambers,
not the primary source.

### 5.5 Confirmed bug: kills not credited to scenario criteria

Reproduced twice on 2026-09-05 in instance 3043, with **two distinct failure modes**.

**Case A — no encounter fired.** Scenario 3582 stage 2, criteria 116103
("Defeat the King of Souls", total 1).

| Time | Event | Source |
|---|---|---|
| 02:51:08 | combat begins with King of Souls (creature 269822) | combat log |
| 02:51:21.775 | `UNIT_DIED` King of Souls, health `0/285089` | combat log |
| 02:53:30 | criterion still `qty=0, total=1` | export #15 |

No `ENCOUNTER_START`/`END` for this kill at all — the only pair that session was an earlier
02:32 kill of the same boss.

**Case B — encounter fired and succeeded, criterion still stuck.** Scenario 3548
"Graverobbers" stage 2, step "Drill or be Drilled", criteria 117895 ("Drill Sergeant slain",
ctype 165, assetID 3622, total 1).

| Time | Event | Source |
|---|---|---|
| 03:04:30.384 | `ENCOUNTER_START,3622,"Drill Sergeant",208,1,3043` | combat log |
| 03:05:52.673 | `ENCOUNTER_END,3622,...,1,82271` — **success=1**, 82s fight | combat log |
| 03:20:32 | criterion `qty=0, total=1, completed=false` | export |
| 03:24:08 | criterion **unchanged**, 18 minutes after the kill | export |

Case B is the more damning of the two: the encounter system reported a clean success and the
criterion tracking it never moved. So criteria updating is failing **independently** of
encounter events, not as a downstream consequence of them.

⚠️ Hypothesis, untested: in Case B the criterion belongs to **stage 2** while the encounter
completed during stage 1, leaving a stage-2 objective that requires killing a boss which is
already dead and does not respawn. The player killed "Thundering Hexmask" 13 times while
stuck, consistent with trash respawning in a chamber that cannot be completed.

**Case C — the mechanism, to the second (2026-09-06, no combat log; captured by D3).**
Scenario 3605 "Raging Spirits" stage 1 ("Quell the Enraged Spirits", a percentage criterion).

| Time | Event | Source |
|---|---|---|
| 09:39:06 | `ENCOUNTER_END 3632 "The Undead Trollbunal" success=true` | D3 encounter entry |
| 09:39:06 | `SCENARIO_COMPLETED` for 3605 | D3 chamber entry |
| 09:42:08 | scenario **3606** "Raging Spirits", step "Judgement Day", criterion "Undead Trollbunal slain" **0/1** | export |

The boss died in the same second stage 1 completed, and the follow-on scenario whose only
criterion is his death began *after* he was dead. Same shape as Case B (Drill Sergeant's
encounter ended during stage 1; stage 2's "slain" criterion never moved), now with the
race visible. Report wording: *the chamber boss can be killed during stage 1's completion
window; the stage-2 "boss slain" criterion is created after `ENCOUNTER_END` and is never
satisfied.*

All three cases leave the run unfinishable without abandoning it. Consistent with the
placeholder state in 5.2a.

### 5.6 criteria.assetID meaning depends on criteriaType

| ctype | assetID refers to | Example |
|---|---|---|
| 0 | **creature ID** | "Defeat the King of Souls." assetID 269822 = `Creature-...-269822-...` |
| 0 | creature ID | "Defeat Hexbound Defenders" assetID 262929 = Hexbound Defender |
| 165 | **encounter ID** | "Drill Sergeant slain" assetID 3622 = `ENCOUNTER_START,3622,"Drill Sergeant"` |
| 92 | **unresolved** — not the encounter (3632) | "Undead Trollbunal slain" assetID 106706; no combat log that run, so creature ID unconfirmed |

Both are locale-free and identify the objective's target without the combat log, but they are
**not interchangeable** — read `criteriaType` before interpreting `assetID`.

### 5.7 RESOLVED: chamber content is randomised per run

Each run rolls different content onto the same chamber nodes. The starting node, Chamber of
Rites, hosted two entirely different scenarios on consecutive runs:

| Run | Tier | scenarioID | name | objective |
|---|---|---|---|---|
| 1 | 11 | 3580 | "Soul King" | Defeat Hexbound Defenders -> King of Souls |
| 2 | 8 | 3615 | "Labyrinth" | "Collect Stolen Artifacts" |

Same subzone, different scenario, different objective *type* (boss kill vs collection). A
third, 3582 "Soul King", appeared at Central Chamber in run 1 — the same content as 3580 at
a different node.

**So scenarioID keys chamber CONTENT, and content is rolled per run.** It is neither
per-node nor per-tier, which retires both readings offered earlier in this document.
Progression resets to Chamber of Rites each run — confirmed by observation, and not a
consequence of abandoning the previous run.

**Consequences for the 2.0 plan.** The plan's §2 treats scenarioID as an exact
`(delve, variant)` key. For Delves that may still hold. For Labyrinths, scenarioID is closer
to "which chamber content did this run roll", which is a *per-run* fact, not a stable
content identity. A Labyrinth run is a randomised sequence, so run-to-run comparison and
anything ranking-shaped needs a different model than the Delve one.

⚠️ Untested: whether the same content ID reappears across runs (i.e. whether 3580 is drawn
from a fixed pool that will recur), and whether the pool differs by tier.

### 5.8 ~~The addon cannot detect tier in a Labyrinth~~ — REVERSED 2026-09-06

The header widget (§3.1) carried `tierText = "11"` inside Kindo'jan. `GetActiveDelveTier`
and the frame-tree scrape both read nothing there, but the widget does. The HUD's Labyrinth
view and the run record now use it. The original finding, kept for the record:


`snap.tierNum`, `tierManual` and `tierAuto` are all **nil** in every Labyrinth snapshot, so
`DelveGuide.currentDelveTierNum` is never populated. This is the internal cause of the
`tier = "?"` in the logged history row (§1), and it is consistent with
`C_DelvesUI.GetActiveDelveTier()` returning zeros (§3). Neither the API nor the tracker
scrape recognises Labyrinth tiers, even though the objective tracker visibly displays one.

### 5.9 Scenario flags observed so far

| flags | binary | context |
|---|---|---|
| 18 | `0_0010010` | "Choose Your Path" hub |
| 144 | `1_0010000` | chamber (3615, collection objective) |
| 146 | `1_0010010` | chamber (3580/3582/3345, boss and percentage objectives) |

A regular Delve (Atal'Aman, scenario 3117) also reports **flags 18** — identical to the
Labyrinth hub. So bit 7 distinguishes chamber from hub, but a Delve and a Labyrinth hub are
indistinguishable on flags, confirming the §1 retraction from the other direction. Bit 1 (2) varies between chambers
for reasons not yet established.

### 5.10 Warband reputations are invisible to GetNumFactions

Looting inside a Labyrinth awards:

```
Your Warband's reputation with Delves: Season 2 increased by 100.
Your Warband's reputation with The Labyrinth of Kindo'jan increased by 80.
You receive currency: [Corrosive Coin] x100
```

**Neither faction appears in `C_Reputation.GetNumFactions()`**, even with every header
expanded (25 rows captured; under Midnight only `Amani Tribe` 2696 and `Valeera Sanguinar`
2744), and neither is in `C_MajorFactions`.

This is **not specific to the new content** — `Delves: Season 2` is a faction the addon
already depends on, and it is equally invisible. Any code that enumerates reputations to
find a Delve faction is looking at an incomplete list.

`C_Reputation.GetFactionDataByID(id)` answers for factions the enumeration omits, so
`/dg export` now sweeps IDs 2400-2900 and keeps everything that returns a name. Once the
IDs are known, query them directly and never enumerate.

**Conclusion: the reputation is not implemented client-side yet.** Confirmed in-game — it
cannot be tracked in the reputation UI. It awards rep via chat messages but has no queryable
entry anywhere:

| Approach | Result |
|---|---|
| `C_Reputation.GetNumFactions()` enumeration, all headers expanded | absent (25 rows) |
| `C_Reputation.GetFactionDataByID` sweep, 2200-3400 | absent (151 factions, none above 2838) |
| `C_MajorFactions` | absent |
| `C_Reputation.GetWatchedFactionData()` | unavailable — cannot be tracked in the UI |

So this is **blocked on Blizzard**, not on finding the right API. Consistent with the
placeholder state in 5.2a.

`Delves: Season 2` is equally invisible to the enumeration. **Correction (2026-09-05, next
day):** an earlier version of this section said this affected shipped code. It does not.
Every `GetNumFactions` / `GetFactionDataByIndex` call in the addon lives inside the
`/dg export` debug block; shipped paths use `GetFactionDataByID`, `GetFriendshipReputation`
and `GetMajorFactionData`, all ID-based, and the addon does not track the Delves: Season 2
faction at all. The constraint is real for any *future* reputation feature — enumerate
nothing, query by ID — but nothing live is broken by it.

Re-test on a later build. `/dg export` captures the enumeration, an ID sweep, major factions
and the watched faction, so a single export will show the moment it lands.

**New currency: "Corrosive Coin"**, awarded 100 at a time from Labyrinth looting. ID not yet
captured; the addon makes 13 `C_CurrencyInfo.GetCurrencyInfo` calls, so this likely wants
adding to the currency model once the ID is known.

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
