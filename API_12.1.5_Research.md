# 12.1.5 API surface research — build 69594

**Produced 2026-09-05** by a research pass over Blizzard's UI source, for `PLAN_2.0.0.md` §8.
Cross-checks every namespaced API DelveGuide calls against the 12.1.5 PTR, and looks for any
Labyrinth-specific API surface.

## Sources

| Source | Branch / build | Reliability |
|---|---|---|
| `github.com/Gethe/wow-ui-source` | `ptr` @ `a89e9d0` (12.1.5 / 69594); `live` @ `8ea15b6` (12.1.0 / 69587) | Primary. Every claim re-verified via `raw.githubusercontent.com` (literal bytes or a clean 404) or the Commits API — GitHub directory listings passed through a summariser hallucinated twice during this pass (a non-existent `ScenarioDocumentation.lua`; a fabricated "removed in 11.0.0") and were not trusted alone |
| `warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes` | raw wikitext; auto-generated 12.1.0→12.1.5 diff of the generated-docs tree (TOC 120105, build 69594, Aug 28 2026) | Most authoritative single source found |
| `townlong-yak.com/framexml/69594` | file index only | diff pages are JS-rendered, unreadable |
| WoWhead PTR faction page (via search) | — | **Low confidence**, not source-verified; used for one cross-reference only |

## Headline

1. **No other documented removal affects the addon.** The entire 12.1.0→12.1.5 Global API
   diff lists exactly one removal: `C_TableUtil.FindIndexedMismatch`. DelveGuide does not
   use it.
2. **The `C_Scenario.GetNumCriteria` / `GetCriteriaInfo` removal is invisible to Blizzard's
   tooling.** `C_Scenario` (Mists-era) has never had a file in
   `Blizzard_APIDocumentationGenerated` — zero commits in the repo's history touch such a
   path — so the generated diff cannot show its members disappearing. No `Deprecated_*.lua`
   shim references it either, and no `Deprecated_12_1_5.lua` exists yet. **The in-game PTR
   test (both return `nil` on 69594) is the only evidence anywhere; nothing contradicts it.**
3. **`C_ScenarioInfo.GetCriteriaInfo`'s field list is byte-identical on `live` and `ptr`**
   (`description, criteriaType, completed, quantity, totalQuantity, flags, assetID,
   criteriaID, duration, elapsed, failed, isWeightedProgress, isFormatted, quantityString`).
   The fallback in `DelveGuide.lua:427-432` targets a stable API.
4. **`C_DelvesUI` is entirely unchanged** — the same 40 functions, same order, same
   signatures on both branches. `GetActiveDelveTier`, `GetCompanionInfoForActivePlayer`,
   `GetRoleNodeForCompanion`, `GetRoleSubtreeForCompanion`, `HasActiveLair` all present.
5. **`GetActiveDelveTier`'s doc string, unedited in 12.1.5:** *"Returns the entrance tier
   information for the active Delve (via party data). Assumes only Delves use this type for
   now."* The source-level explanation for the all-zero struct observed in both content types.
6. **`TieredEntranceType` has five values on both branches:** `Invalid=0, Delve=1, Sites=2,
   WorldTier=3, Lairs=4`. **No Labyrinth entry.** Labyrinths are not a first-class
   tiered-entrance type in the documented API on 69594 — either not routed through
   `C_DelvesUI` at all, or reusing `Delve=1`.
7. **No `C_LabyrinthInfo` namespace**, and no function or table containing "Labyrinth",
   "Chamber" or "WalkIn" anywhere in the generated docs on the `ptr` branch.
8. `ScenarioInformation.flags` / `.type` and `ScenarioCriteriaInfo.criteriaType` / `.assetID`
   are documented only as raw `number`, with no enum. The empirical `criteriaType 0 → creature
   ID, 165 → encounter ID` mapping (Findings §5.6) is neither corroborated nor contradicted
   by source; it is simply undocumented.
9. **Faction cross-reference (WoWhead, not source-verified):** factionID **2836** =
   "The Labyrinth of Kindo'jan". Note: the in-game sweep of 2200-3400 *did* call
   `GetFactionDataByID(2836)` and kept nothing, because it filtered on a non-empty name. So
   the ID may exist in DB2 with no client-side name — consistent with Findings §5.10. `/dg
   export` now records the raw return for 2836 without the name filter.
10. The wiki's 12.1.5 "deprecated shims finally deleted" list includes the globals
    `GetItemCount` and `GetDetailedItemLevelInfo`. DelveGuide already calls the `C_Item.*`
    forms exclusively. Unaffected.

## Per-API status

Scope: every `.lua` in the addon, excluding the `/dg export` block (`DelveGuide.lua` from
`elseif msg=="export"` to the `ptrExports` insert).

**Status key.** *Confirmed* = member verified present in the ptr-branch generated docs.
*Presumptive OK* = absent from the diff's removed list, not individually opened. *Undocumented*
= no generated-docs file on either branch (the `C_Scenario` blind spot). *N/A* = export block
or comments only.

| API | Non-export call sites | Status |
|---|---|---|
| `C_Scenario.GetNumCriteria` | DelveGuide.lua:422 (fallback only) | **Removed** — in-game evidence only |
| `C_Scenario.GetCriteriaInfo` | DelveGuide.lua:431 (fallback only) | **Removed** — in-game evidence only |
| `C_Scenario.GetStepInfo` | DelveGuide.lua:424; HUD.lua:262 | Undocumented; verified working in-game |
| `C_Scenario.GetInfo` | DelveGuide.lua:2122, 2147; HUD.lua:254 | Undocumented; verified working in-game |
| `C_Scenario.IsInScenario` | DelveGuide.lua:1567; HUD.lua:15, 36, 55 | Undocumented; verified working in-game |
| `C_ScenarioInfo.GetCriteriaInfo` | DelveGuide.lua:429 | **Confirmed**, identical both branches |
| `C_DelvesUI.GetCompanionInfoForActivePlayer` | Checklist:86; DelveGuide:1596; UI_Debug:40; UI_Companion:188 | **Confirmed** |
| `C_DelvesUI.GetRoleNodeForCompanion` | DelveGuide.lua:1600 | **Confirmed** (`companionID → nodeID`) |
| `C_DelvesUI.GetRoleSubtreeForCompanion` | DelveGuide.lua:1601 | **Confirmed** |
| `C_DelvesUI.HasActiveLair` | UI_Nemesis.lua:76 (comment) | **Confirmed** present |
| `C_DelvesUI.GetCompanionInfo` | UI_Companion.lua:193, 205 | **Undocumented on both branches**; already existence-guarded; not a 12.1.5 change |
| `C_UIWidgetManager.GetAllWidgetsBySetID` / `GetTextWithStateWidgetVisualizationInfo` / `GetIconAndTextWidgetVisualizationInfo` | DelveGuide.lua:163-171 | Presumptive OK |
| `C_AreaPoiInfo.GetDelvesForMap` / `GetAreaPOIInfo` | DelveGuide.lua:210, 223 … | Presumptive OK |
| `C_UnitAuras.GetPlayerAuraBySpellID` | DelveGuide.lua:446 | Presumptive OK |
| `C_UnitAuras.GetAuraDataByIndex` | DelveGuide.lua:1618 (`/dg checkdebug`) | Presumptive OK, not individually checked |
| `C_Item.GetItemCount` | Checklist:24; DelveGuide:452, 645; UI_Delves:105; Voidforge:72 | **OK** — the global form was removed; addon already on `C_Item` |
| `C_Item.GetDetailedItemLevelInfo` | DelveGuide:599, 1544; Voidforge:128 | **OK** — same |
| `C_CurrencyInfo.GetCurrencyInfo` | 13 sites | Presumptive OK |
| `C_DateAndTime.GetSecondsUntilWeeklyReset` | 6 sites | Presumptive OK |
| `C_QuestLog.*` (8 functions) | DelveGuide:459, 959-961; Quests:58-132 | Presumptive OK |
| `C_Map.SetUserWaypoint` | DelveGuide.lua:520 | Presumptive OK |
| `C_WeeklyRewards.*` (3) | DelveGuide:583-597, 1549 | Presumptive OK |
| `C_TaskQuest.GetQuestsOnMap` | DelveGuide.lua:956 | Presumptive OK |
| `C_Traits.GetActiveConfigID` | DelveGuide.lua:1611 (`/dg checkdebug`) | Presumptive OK, not individually checked |
| `C_Timer.After` / `NewTicker` | 8 sites | Presumptive OK (`C_Timer` only gained `NewTimedSignalMap`) |
| `C_GossipInfo.GetFriendshipReputation` | UI_Companion:30, 82 | Presumptive OK |
| `C_MajorFactions.GetMajorFactionData` | UI_Companion:43, 117 | Presumptive OK |
| `C_Reputation.GetFactionDataByID` | UI_Companion:56, 133 | Presumptive OK |
| `C_Reputation.GetNumFactions` / `GetFactionDataByIndex` / `ExpandFactionHeader` / `GetWatchedFactionData`, `C_MajorFactions.GetMajorFactionIDs`, `C_TaxiMap.*`, taxi globals, `GetBuildInfo`, `GetSubZoneText` | export block only | N/A |
| `GetInstanceInfo`, `GetRealZoneText`, `UnitName`, `GetSpecialization(Info)` | many | Presumptive OK (globals, not in any removed list) |
| `GetAchievementCriteriaInfo`, `UnitGUID` | — | Not called by the addon |

A separate risk noted in passing, not an API removal: `DelveGuide_Checklist.lua:200` already
records that `UnitName("target")` can return a Secret Value on this build. That is the
existing secret-values class of issue, unchanged by this research.

## Deprecated shim files opened

`Blizzard_Deprecated/Mainline/Deprecated_12_1_0.lua`, `Deprecated_12_0_5.lua`,
`Deprecated_12_0_7.lua`, `Deprecated_12_0_1.lua`, `Blizzard_Deprecated/Shared/Deprecated_12_1_0.lua`.
None reference `C_Scenario` or `C_ScenarioInfo`. No `Deprecated_12_1_5.lua` exists yet on
`ptr`. Nothing in them touches DelveGuide (`GetDyeColorForItem`, `C_Housing.IsInsideOwnHouse`,
`GetInspectSpecialization` — all unused).

## Could not determine

- Per-function confirmation for every "Presumptive OK" row. Confidence rests on the aggregate
  diff showing near-zero API churn this patch, not on opening each namespace's doc file.
- Full raw text of `Blizzard_DelvesDifficultyPicker.lua` (only a summary was obtained); whether
  it special-cases Labyrinths internally is unknown. The only Delves-prefixed AddOn folders on
  `ptr` are `Blizzard_DelvesCompanionConfiguration`, `Blizzard_DelvesDifficultyPicker`,
  `Blizzard_DelvesToast`.
- Whether `C_DelvesUI.GetCompanionInfo` exists at runtime — undocumented on both branches,
  already guarded, not a regression.
- GitHub code search needed authentication (401), so repo-wide grep for "Labyrinth" was not
  possible; findings come from directory listings and targeted raw fetches.
