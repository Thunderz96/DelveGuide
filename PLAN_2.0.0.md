# DelveGuide 2.0.0 — integration plan

**Written 2026-09-05** on branch `ptr-12.1.5`, after the first PTR session against build 69594.

This reconciles three documents into one release:

| Input | What it is | Where |
|---|---|---|
| **Review Plan** | 14-reviewer static analysis of 1.11.0 against 12.1.0: 215 verified findings, phases 0–5 | `~/Downloads/DelveGuide_Review_Plan.md` |
| **2.0 Sequencing Plan** | Nick's scope decision (Labyrinths + Venomstone) and the argument for pooling + ID identity as prerequisites | scratchpad `DelveGuide_2.0_Plan.md` (session 37f2989e) |
| **PTR Findings** | What the running 12.1.5 client actually returned | `PTR_12.1.5_Findings.md` (this branch) |

Both source docs should move into `docs/` in the repo so this file's references stop
pointing at a Downloads folder and an ephemeral scratchpad. That is Nick's call — the Review
Plan is 120 KB and the repo is public.

---

## 1. What changed since the sequencing plan was written

The sequencing plan's thesis holds: pooling and ID-based identity stop being cleanup and
become prerequisites the moment Labyrinths are in scope. The PTR session changed **how much
Labyrinth work is possible in 2.0.0** and **what the ID work can and cannot key on**.

Three facts drive every change below.

**The content is placeholder.** A chamber scenario is literally named `[PH] Soul Jars`; two
distinct Blizzard bugs left every run unfinishable; the map name is `12_15_Labyrinth_A`.
IDs, names and mechanics may all move before launch. A Labyrinth *guide* cannot be written
against this build. A Labyrinth *guard* can and must be.

**Labyrinths look like Delves on every cheap signal.** Scenario type 8, `diffID` 208,
`diffName` "Delves", and scenario `flags` 18 in the hub — identical to a real Delve. Every
detection test the addon runs today says "delve", so the HUD starts a run timer and a
completed chamber logs a delve-shaped history row with `variant` absent and `tier = "?"`.
Observed, not inferred (Findings §1). The only stable discriminator is **instanceID**
(3043, constant across tiers 11, 1 and 8).

**One assumed API win is gone.** `C_DelvesUI.GetActiveDelveTier()` returns an all-zero
struct in Delves *and* Labyrinths (Findings §3). The every-two-seconds tracker scrape the
Review Plan hoped to retire (Phase 3.3) stays.

And one thing the static review could not see: **12.1.5 removed `C_Scenario.GetNumCriteria`
and `GetCriteriaInfo`** (Findings §4.6). Six `pcall`-wrapped call sites failed silently — no
error, no BugSack entry — and the HUD would have quietly stopped showing lives on patch day.
Fixed on this branch and verified in-game in both content types.

---

## 2. Corrections to the Review Plan, item by item

Everything not listed here proceeds exactly as the Review Plan wrote it.

| Review item | Status after PTR | Evidence |
|---|---|---|
| **Phase 3.3** — `GetActiveDelveTier` as Method 0, retire the scrape | **DROP.** Protocol row 16 failed: empty struct at tier 8 in Atal'Aman while the scrape correctly read 8 | Findings §3 |
| **Phase 3.1** — scenarioID as locale-free run identity | **Keep for Delves, gated; exclude Labyrinths explicitly.** Rows 13 and 14 are still unrun for Delves. Inside a Labyrinth scenarioID keys *chamber content*, re-rolled per run — a per-run fact, not an identity | Findings §5.7; §5 below |
| **Phase 1.10 / H5** — companion faction by ID (2744) | **Corroborated.** Faction 2744 present in the 12.1.5 sweep; `companionID = 12` resolved inside both content types. Proceed | Findings §5 |
| **Phase 0.10** — soften the "do NOT key on poiID" comment | **Corroborated, and now urgent for a different reason** — see A3 below. widgetSetID is stable across three maps; poiID varies per map | Findings §2 |
| **Phase 4 item 6** — `/dg selftest` | **~60% already built** as the `/dg export` expansion: API presence probe, criteria dump, both scenario structs, the tier struct, taxi, factions. Selftest = export + render-every-tab `xpcall` + data invariants + the objective-tracker widget dump | this branch, commits 4552f33…d8948bd |
| **Phase 5 `hud-victory#7`** — lives are probably a header widget | **Still blocked on data,** and the Labyrinth cannot answer it (single objective, no lives criterion). Needs one Tier 4+ Delve export mid-run | §5 G3 |
| **Phase 5 `hud-victory#17`** — extract `ReadLivesText()` | **Pull forward into Track A.** Both duplicate sites were just edited for the namespace fix; extracting now is a few lines while the code is warm | `DelveGuide_HUD.lua:456`, `:549` |
| **Phase 4 item 4** — reload-safe run record | **Add a Labyrinth clause.** `SCENARIO_COMPLETED` fires per chamber, so the record must know it is inside a multi-scenario run or it dedupes wrongly | Findings §1, §5.2a |
| **§7.4** — "no locale-free variant ID outdoors" | **Confirmed, and worse for Labyrinths:** widget set 2316 yields no usable text at all, so the outdoor scan quarantines Kindo'jan as `[Missing Translation] Unknown Variant Text` | Findings §4.2 |
| **§7.4** — datamined delve instance IDs (2933…) | **Corroborated:** Collegiate Calamity returned 2933 live | Findings §2 |
| **§7.4 speculative** — non-text widget fields as an outdoor variant key | **Unchanged, still worth the experiment.** The export now records `widgetTexts`; add `widgetTag`/`textureKit`/`orderIndex` in the same place | — |
| **2.0 Plan Stage 0 item 3** — prune the Future tab | **Now has specific corrections.** `Data.lua:384` says "progress saved between sessions" — the path resets every run (taxi nodes unlock, but the run restarts at Chamber of Rites). "Small group" unverified (solo only observed). Hero-track gear confirmed (Heroic Soul Fragment, Hero 2/6); "housing & vendor currency" unverified (Corrosive Coin exists, purpose unknown) | Findings §5.1, §5.2, §5.10 |
| **2.0 Plan §2** — "scenarioID is an exact (delve, variant) key" | **Holds for Delves only, pending rows 13/14.** Explicitly false for Labyrinths | Findings §5.7 |

---

## 3. New work the review could not see — Track A

These exist because the review was static analysis against 12.1.0. They are **time-bound by
Blizzard's patch date**, which nothing else in 2.0.0 is.

| # | Item | Status | Effort | Test |
|---|---|---|---|---|
| A1 | Criteria namespace fix: `DelveGuide.GetCriteriaCount()` / `GetCriteria(i)` with both paths, so one build serves 12.1.0 and 12.1.5 | **Done, verified** (`41e5336`) | — | `/dg huddump` in a Delve and a Labyrinth: `count 1+`, `crit[]` lines — both passed |
| A2 | **Labyrinth guard.** ✅ **Done** (see commit log) — `DelveGuideData.labyrinthInstances = { [3043] = "The Labyrinth of Kindo'jan" }`. When `select(8, GetInstanceInfo())` is in it: the HUD does not start a delve run timer and shows a neutral Labyrinth state; `SCENARIO_COMPLETED` does **not** write a delve-shaped history row. Runs are cheap to detect and expensive to un-log | **New** | S | Enter Kindo'jan, clear one chamber: no `Logged:` line, no history row, HUD not showing a delve tier |
| A3 | **Filter Labyrinth POIs out of the rotational scan.** ✅ **Done** — `C_AreaPoiInfo.GetDelvesForMap` returns Kindo'jan on maps 2437, 2395, 2537 (set 2316, atlas `overworld-active-64x64`). Without a filter the Delves tab and widget show a quarantined junk row **on live patch day**. Exclude by `labyrinthWidgetSets = { [2316] = true }`; optionally also by atlas not starting `delves-`. The set allowlist is the existing idiom (`widgetSetDelves`) and is precise; the atlas check catches an uncatalogued Labyrinth B generically but its safety depends on bountiful delves also using a `delves-*` atlas, which is **not yet verified** | **New** | S | `/dg scan` in Eversong: 12 delves, 12 variants, no `[Missing Translation]` line |
| A4 | `.toc` Interface 120105 | **Done** (`e2f3800`) | — | verified `select(4, GetBuildInfo())` |
| A5 | Extract `ReadLivesText()` (`hud-victory#17`) — both duplicates were just touched | ✅ **Done** | S | lives row unchanged in a Tier 4+ Delve |
| A6 | **Retail check** (G4 below): does live 12.1.0 still have `C_Scenario.GetNumCriteria`? Decides whether A1 is pre-patch prep or a live hotfix | **Unrun** | one command | — |

**Track A can and should ship before 12.1.5 goes live**, independent of the rest of 2.0.0.
A1 is safe on 12.1.0 today by construction. If 2.0.0 is not ready by patch day, Track A
goes out alone as 1.12.0 and 2.0.0 follows. Nothing else in this document is on Blizzard's
clock.

---

## 4. The shape of 2.0.0

Five tracks. Track A is ordered first by the calendar; B and C are ordered by the Review
Plan's own dependencies; D and E are reorderable.

### Track B — Review Plan Phases 0, 1a, 1b (unchanged)

Docs and metadata (0.1–0.12), the aggregator (1.1–1.6, before the next rankings refresh),
and the user-visible bug batch (1.7–1.17). One evening without the game, one Python session,
one Delve session. Nothing here touched by the PTR except the Future-tab corrections folded
into 0.x and the H5 corroboration.

### Track C — Foundation (2.0 Plan Stage 1 = Review Phases 2 + 3.1/3.2/3.5)

| Item | Note |
|---|---|
| 2.1a–f hygiene | as written. 2.1d (`EvaluateDelveState` early-out) is unaffected by Labyrinths since `inDelveInstance` will be false there after A2 |
| 2.2–2.4 pooling | as written. This is the L item and the one where an **Opus review agent** earns its keep before merge — 27 re-render sites, 114 creation sites |
| 2.6 schema + migrations | as written; add a migration that re-tags any history row with `name` in `labyrinthInstances` values and no `variant` as `suspect = "labyrinth"` rather than deleting it |
| 2.7 error containment, 2.8 HUD gating | as written |
| 3.5 CI gate on **Lua 5.1 / LuaJIT** | as written; the local `luac` is 5.4.6 and passed every change on this branch, which is exactly the blind spot |
| 3.1 scenarioID identity — **Delves only** | gated on G1 and G2. Design addition: `GetDelveByScenarioID` must return nil for any scenarioID observed inside a `labyrinthInstances` instance, so a chamber scenario can never resolve to a delve |
| 3.2 learn `scenarioID -> variant` | as written; same Labyrinth exclusion |
| ~~3.3 tier API~~ | **dropped** — keep the probe in `/dg export` so a later build populating the struct is noticed |
| 3.4, 3.6–3.10 | as written, independent |

### Track D — Labyrinths: aware now, guided shell now, content as it stabilises

**Decision (Nick, 2026-09-05):** both aware and guided are wanted. Labyrinths are not Delves
and are not treated as equals — but they grant delve vault credit and broadly the same
rewards, so the addon should help where it can: easiest rooms, tips, progression. Much is
unknown; the structure ships in 2.0.0 and the content fills in as the PTR matures.

**The structural insight that makes this tractable.** Chamber content is drawn from a pool
and re-rolled per run, and each content has its own scenarioID when instantiated ("Soul King"
appeared at two nodes; Chamber of Rites hosted two different contents on two runs). So a
chamber's *content* recurs across runs and is the rankable unit — exactly as a variant is
for a Delve. "Easiest rooms" is the existing community-timing pipeline (`/dg submit` ->
aggregator -> grade letters) pointed at chamber content instead of variants.

| # | Item | Effort | Ships in 2.0.0 as |
|---|---|---|---|
| D1 | **Detection** by `labyrinthInstances` allowlist (3043 verified across tiers 11/1/8) | S | code |
| D2 | **Labyrinth run record** — its own shape, not a delve row: `{ instanceID, name, date, resetKey, char, realm, tierNum (nil until readable), vaultIlvl, chambersCleared, chambers = {...}, completed, elapsed }`. Written on leaving the instance or on the final completion, **not** per chamber. **Counts toward the Roster's weekly vault tally** — a T8+ Labyrinth is a delve vault slot. `vaultIlvl` via the existing `GetWeeklyVaultData` fallback, which read 305 correctly last night | M | code |
| D3 | **Chamber observation log** per `SCENARIO_COMPLETED` inside a Labyrinth: `{ scenarioID, scenarioName, stepTitle, criteria, encounterIDs, subzone, taxiNodeID, elapsed }`, bounded. Feeds D2's `chambers[]` and is the raw material for chamber timings | M | code |
| D4 | **Labyrinth tab shell**, built pooled from day one — a *new* tab is where the pooling pattern (Track C 2.2–2.4) gets established rather than retrofitted. Sections: this week's status (cleared / vault credit), chamber list keyed on content with grade + median time (empty until data), tips per chamber (empty until written), progression (taxi nodes unlocked, from D3). Every content row carries `source` and `verifiedBuild` so `[PH]`-era entries are visibly provisional | M–L | code, mostly empty |
| D5 | **Chamber timings in `/dg submit`** — a `|LAB;` section carrying `(contentScenarioID, chamberName, elapsed, tier)` per cleared chamber, aggregated alongside variants | M | code |
| D6 | **HUD Labyrinth state**: chamber name + objective progress (both criteria shapes: count and percentage) instead of a delve tier it cannot read | S | code |
| D7 | Future tab corrections from evidence | S | content |
| D8 | Chamber tips, easiest-room guidance, reputation and Corrosive Coin tracking | — | **content, added as PTR builds stabilise**; blocked today on `[PH]` names, unimplemented faction, unknown currency ID |

**What is known well enough to build against now:** instanceID; the per-chamber scenario
structure; two criteria shapes; taxi node IDs as progression; encounter events on boss
chambers; that completion grants vault credit. **What is not:** any chamber's final name or
ID, tier readability, the faction, the currency, group play. D1–D7 depend only on the first
list. D8 depends on the second and waits.

**Rewrite risk, stated plainly:** chamber content IDs observed on 69594 may change. D4's
content rows are keyed on them, so a later build may orphan early entries. `verifiedBuild`
on each row makes that visible rather than silent, and the log (D3) re-collects for free.

### Track E — Features (Review Phase 4)

As written, with two notes. Item 6 (`/dg selftest`) starts from the export code rather than
from zero. Item 4 (reload-safe run record) gains the per-chamber clause from §2.

Recommended for 2.0.0: items 1 (listing), 2 (waypoint), 3 (parity release), 4 (run record),
5 (Victory toast), 6 (selftest). Items 7–10 and Phase 5 go to 2.1 unless a Delve session
frees up. That is a scope recommendation, not a decision — see §7.

---

## 5. Verification gates — one command each

Every unproven assumption that gates code, with the single cheapest capture that settles it.

| # | Gate | Gates | Command | Pass |
|---|---|---|---|---|
| G1 | scenarioID invariant across tier and bountiful for **one Delve** (protocol row 13) | 3.1, 3.2 | `/dg export` in the same delve at two tiers + once bountiful, read `scenarioInfo.scenarioID` off disk | identical all three times. **If it moves, 3.1's design is wrong** |
| G2 | scenarioID readable inside the `SCENARIO_COMPLETED` handler (row 14) | 3.1 capture design | one debug `print(select(13, C_Scenario.GetInfo()))` at `DelveGuide.lua:2122`, complete a delve | a number prints. If nil, capture on entry and cache |
| G3 | lives criterion shape in a Tier 4+ Delve mid-run | `hud-victory#7`, A5 | `/dg export` inside a T4+ delve after the first pull, read `criteria[]` | a criterion whose `desc`/`qtyStr` matches the lives regex — or none, which means it *is* a widget |
| G4 | live 12.1.0 still has the old criteria API | **A1's urgency** | — | **✅ answered 2026-09-05: `nil function` on retail.** Live 1.11.0's lives counter is silently broken today. A1 ships as hotfix **1.11.1** from `main` (cherry-picked `41e5336` + `e2f3800`), ahead of 2.0.0 |
| G5 | Nemesis lair scenarioID (row 13 tail; expect 3395) | 3.1 | `/dg export` inside Venomfall Deeps | 3395 |
| G6 | bountiful delve POI atlas name | A3's atlas option | `/dg export` on a day with a bountiful delve up, read `delvePOIs[].atlas` | starts with `delves-` |
| G7 | instanceID stable across Labyrinth tiers | A2 | — | **✅ verified** — 3043 at tiers 11, 1, 8 |
| G8 | `GetActiveDelveTier` populated in a Delve (row 16) | 3.3 | — | **✅ answered: no** — 3.3 dropped |

G4 is a single line typed into the retail client and it decides whether Track A is a
release or a hotfix. It should be the first thing done.

---

## 6. Recommendation

**Track A is now two releases.** G4 came back `nil function` on retail, so A1 + A4 ship
immediately as **1.11.1** from `main` — the lives counter has been silently dead on live
12.1.0. A2, A3 and A5 are Labyrinth-facing and stay on Blizzard's calendar for 12.1.5; they
ship with 2.0.0 or as 1.12.0 if patch day arrives first.

**Then Track B in the Review Plan's order**, because the aggregator miscount is live and the
Phase 0 docs are the paste source for the CurseForge listing.

**Then Track C**, with 3.1 held until G1 and G2 are run in one Delve session. Pooling
(2.2–2.4) is the L item and the place to spend an Opus review pass.

**Track D stays minimal** until a non-placeholder PTR build. D2 costs one evening and makes
the next build's session self-documenting.

**Track E items 1–6 in 2.0.0, 7–10 in 2.1.** The listing refresh (E1) is the highest-scored
item in the whole review and needs no code; it should not wait on anything.

On the sequencing plan's §6 naming question: unchanged. Middle option — keep the name, add
"Delves and Labyrinths" to the TOC Notes. One line, no identity cost.

---

## 7. Decisions that are Nick's, not mine

1. **Is 2.0.0 one release or a train?** Partly decided by G4: A1 goes out as 1.11.1 now
   regardless. The open half is whether A2/A3 (Labyrinth guard + POI filter) wait for 2.0.0
   or ship as 1.12.0 if 12.1.5 lands first.
2. ~~**Track D scope.**~~ **Decided:** aware + guided shell in 2.0.0, content as builds
   stabilise. See Track D.
3. **Track E cut line.** Items 1–6 vs all ten.
4. **Move the two source documents into `docs/`.** Keeps the plan's references stable; puts a
   120 KB internal review in a public repo.
5. **A3's filter** — set allowlist only (precise, misses Labyrinth B until catalogued) or
   allowlist + atlas check (generic, depends on G6).

---

## 8. 12.1.5 API surface research — done

Full report: `API_12.1.5_Research.md`. What it changes here:

- **Track A is complete as listed.** No other documented removal in 12.1.5 touches the addon;
  the whole patch removed exactly one Global API (`C_TableUtil.FindIndexedMismatch`, unused).
  `C_DelvesUI` is byte-identical between 12.1.0 and 12.1.5.
- **The criteria removal is invisible to Blizzard's tooling** — `C_Scenario` has never had a
  generated-docs file, so no diff can show it. The in-game test is the only evidence. That is
  a reason to run G4 on retail rather than a reason to doubt A1.
- **Phase 3.3's drop is source-grounded, not just observed.** `GetActiveDelveTier`'s own doc
  string still reads *"Assumes only Delves use this type for now,"* and `TieredEntranceType`
  has no Labyrinth value. Labyrinths are not a first-class tiered-entrance type on 69594.
- **Track D's deferral is source-grounded too.** No `C_LabyrinthInfo`, no Labyrinth-named
  function anywhere in the generated docs. There is no API to build a guide against yet.
- **Faction lead:** WoWhead lists factionID **2836** for the Kindo'jan reputation. The sweep
  already called that ID and kept nothing (name filter), so `/dg export` now records its raw
  return. If it comes back as a table with an empty name, Findings §5.10's "exists but not
  client-side" reading is confirmed and the ID can be pre-seeded in `DelveGuideData`.

Confidence limit carried over from the report: most "unchanged" verdicts rest on the
aggregate 12.1.0→12.1.5 diff, not per-function inspection of every namespace's doc file.

---

## 9. Progress log

| Date | Done | Notes |
|---|---|---|
| 2026-09-05 | **1.11.1** staged on `main` (untagged) | criteria API hotfix for live |
| 2026-09-05 | **A1, A2, A3, A4, A5** | Track A complete; A2/A3 await PTR check |
| 2026-09-05 | **E2** native waypoint, **E5** Victory comparison row, **D3** Labyrinth observation log | E5 hides its row below tier 8 or with no median |
| 2026-09-05 | **Phase 0** merged (branch `phase0`, 9 commits) | review's "~15 missing changelog versions" was 3; 0.12 found no fifth Atal'Aman variant; `.pkgmeta` `manual-changelog` decision still Nick's |
| 2026-09-05 | **E4** reload-safe run record, dedupe guard, per-player median; **D2 scaffold** (gated on `finalEncounterID`, unknown on `[PH]`) | Labyrinth rows count toward the weekly vault tally via `history` |
| 2026-09-05 | **Phase 1a** merged (branch `phase1a`, 8 commits, 23 tests) | ⚠️ 4 grade moves NOT applied — Nick's call; below-floor rows kept verbatim (agent's non-destructive reading of RANKING.md step 5) — Nick's call |
| 2026-09-05 | **E6** `/dg selftest`; export gains tracker-widget dump + POI widget metadata | Debug-tab Settings gate waits for `e3-parity` to merge |
| 2026-09-05 | **E1** listing text at `tools/CURSEFORGE_LISTING.md` | Nick pastes; 4 screenshots still needed (HUD, Voidforge, History, Victory); fill «N»/«V» from `rankingStats` |
| 2026-09-05 | **D6** Labyrinth HUD view | chamber / step / objective (both criteria shapes) / cleared / time; tier shown as not readable |
| 2026-09-05 | **E3** merged (branch `e3-parity`, 6 commits) | grades tooltip, ESC>Options signpost, 3 keybinds, compartment, rotation countdown, About block; ⚠️ glance at widget countdown fit at font scale 0.6 |
