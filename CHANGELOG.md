# Changelog

## [1.7.17] - 2026-04-25

### Added
- **Voidforge Tab:** New top-level tab (between Loot and Nullaeus) that consolidates the Patch 12.0.5 upgrade loop. Four sections:
  - **This Week** -- live Nebulous Voidcore count, "Building the Voidforge" progress bar, Ascendant Voidcore count.
  - **Where to Earn** -- one-line reference for each currency source.
  - **Upgrade Priority** -- scans all 16 gear slots and recommends weapons & trinkets first (largest stat-per-ilvl gain), then armor by lowest ilvl. Empty slots float to the top. Each row is hoverable for the item tooltip and shift-click chat-links the item.
  - **Alt Stockpile** -- rolls up cores/shards/ascendant counts plus weekly-quest status across every cached character on the account, with totals.
- **Quests Tab (Delver's Call):** New top-level tab that tracks the 10 per-delve "Delver's Call" quests across characters. Designed for the alt-leveling "world tour" workflow -- run every delve once, bank the quests, then turn them all in close to max level for a big XP push (turning in at the cap itself wastes the XP). Auto-detects state via `C_QuestLog`:
  - `Available` (not picked up) / `In Progress` (in log, objectives pending) / `Banked` (objectives done, ready to turn in -- the gold-highlighted sweet spot) / `Turned In` (completed).
  - All 10 quest IDs catalogued from wowhead.com (Atal'Aman 93409, Collegiate Calamity 93384, Parhelion Plaza 93386, Shadowguard Point 93428, Sunkiller Sanctum 93427, The Darkway 93385, The Grudge Pit 93421, The Gulf of Memory 93416, The Shadow Enclave 93372, Twilight Crypts 93410).
  - Per-character + alt-rollup view at the bottom of the tab.
  - Manual checkbox fallback (with cycle button) in case Blizzard adds future quests we haven't catalogued yet.
- **`/dg voidforge`** (alias `/dg forge`) -- jumps to the Voidforge tab.
- **`/dg quests`** -- jumps to the Quests tab.
- **`/dg questscan`** -- scans the player's quest log and prints any Delver's Call-style quests with their IDs, so future quests can be added to the data table.
- **Voidforge Data on Roster Snapshot:** `PLAYER_ENTERING_WORLD` now captures `voidforge = {cores, shards, ascendant, questDone}` per character so the Voidforge tab's Alt Stockpile rollup works without each alt being currently logged in.

## [1.7.16] - 2026-04-24

### Fixed
- **CurseForge Build Pipeline:** v1.7.15 failed to publish because the BigWigsMods packager tried to fetch lib externals from URLs that no longer resolve (Stanzilla/LibStub returns 404; CurseForge retired their public git mirrors at `repos.curseforge.com/wow/...`). Removed the `externals:` block from `.pkgmeta` entirely -- the four libraries (LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0) are already committed under `Libs/` and ship as-is. No functional changes versus 1.7.15.

## [1.7.15] - 2026-04-24

### Added
- **Settings Toggle for Bountiful-Only Filter:** The bountiful filter introduced in 1.7.14 now has a matching checkbox in the Settings tab's Compact Widget section. Toggling it there stays in sync with the widget's `[B]` button and the `/dg bountiful` slash command -- all three control the same `widgetBountifulOnly` flag.

## [1.7.14] - 2026-04-24

### Added
- **Bountiful-Only Filter on Widget:** New `[B]` toggle button in the widget header (left of the share/lock icons) -- click to hide every non-bountiful variant, click again to restore the full list. Gold `[B]` = filter ON, dim grey = OFF. The Share button respects the filter too, so right-click-to-guild only sends today's bountiful delves when the toggle is active. State persists per-character.
- **`/dg bountiful`** -- slash-command toggle for the same filter, in case the widget is hidden or you've muscle-memory'd the keyboard.

## [1.7.13] - 2026-04-24

### Fixed
- **Companion Level Parses From `d.reaction` String:** For Valeera's friendship faction (2744), `C_GossipInfo.GetFriendshipReputation` does not populate the structured `rankInfo.currentLevel` field -- the actual rank number is embedded in `d.reaction` as a localised string like `"Level 38"` (with `d.text` mirroring it: `"Valeera Sanguinar reached Level 38."`). The Companion tab now pattern-matches digits out of `d.reaction` first, then `d.text` as a fallback, so the header correctly shows `Level 38` instead of `Level 0`. The structured `rankInfo.currentLevel` path is kept first for forward compatibility in case Blizzard populates it in a later patch.

## [1.7.12] - 2026-04-24

### Fixed
- **Companion XP Now Reads Correct Friendship Rank:** Valeera's track is a friendship-style reputation (80-level XP rank, same shape as Brann's TWW system), not a plain reputation. The plain `C_Reputation.GetFactionDataByID` API *also* returns data for these factions but only exposes the 1-8 reaction (Honored / Exalted), which is why the Companion tab was showing "Level 8" instead of the real rank. The renown query now probes `C_GossipInfo.GetFriendshipReputation` first, which returns `rankInfo.currentLevel` (the real 80-level rank) plus the in-level XP progress.
- **Auto-Discovery Covers Friendships:** The one-time ID scan now checks `C_GossipInfo.GetFriendshipReputation` in the 2600-3100 range before falling through to Major Factions and regular reputations.

## [1.7.11] - 2026-04-24

### Fixed
- **Companion XP Lookup:** The renown lookup now probes both the Major Faction and regular Reputation APIs regardless of how the faction ID was cached, so a manually-pinned ID works whichever table it actually lives in. Previously, `/dg companionfaction <id>` hardcoded the type to "major" and silently returned nil if the faction was actually a regular reputation (which is where Valeera Sanguinar -- faction 2744 -- actually lives).
- **Cache Self-Correction:** When the type probe has to fall through to the other API, the corrected type is written back to the cache so subsequent renders skip the wrong query.

## [1.7.10] - 2026-04-23

### Added
- **Companion XP via Reputation:** The Companion tab now reads Valeera's XP/level from her reputation/renown faction, so the progress bar works anywhere -- not just inside an active delve. Previously, `C_DelvesUI.GetCompanionInfo` only populated XP data while inside an instance; outside delves the bar was empty. Auto-discovery scans for the companion faction on first render and caches the ID per-character.
- **`/dg companionscan`** -- clears the cached companion faction so the next Companion tab open re-scans (useful if Blizzard renames the faction or you roll a new character).
- **`/dg companionfaction <id>`** -- manually pin a faction ID when auto-discovery can't find it.

## [1.7.9] - 2026-04-23

### Added
- **Voidforge Integration (Patch 12.0.5):** First pass on the new Lingering Shadows Void systems. Surfaces across the existing UI:
  - **Widget:** New "Cores / Forge" line below Keys showing current Nebulous Voidcore count (vs weekly cap) and Elementary Voidcore Shard progress toward the weekly "Building The Voidforge" quest (X/3).
  - **Pre-entry Checklist:** New "Voidforge weekly" row flags whether you still owe shards before your next Bountiful Delve.
  - **History tab:** Per-week summary now reports how many of that week's runs were Tier 8+ and therefore Voidcore-eligible.
  - **World Map Tooltip:** Active-delve tooltips now include a "T8+: drops Nebulous Voidcore" reminder.
  - **Loot tab:** New Voidforge Currencies section explains Nebulous / Elementary Shard / Ascendant Voidcores and where they drop.
- **New module:** `DelveGuide_Voidforge.lua` centralizes currency/quest polling so every surface shares the same status.

### Notes
- Currency-backed features (widget line, checklist shard count) stay hidden until Voidforge currency IDs are populated in `DelveGuide_Voidforge.lua` -- the rest of the integration (tooltip reminder, loot section, history eligibility count) works immediately.

## [1.7.8] - 2026-04-23

### Added
- **Separate Widget Font Scale:** The compact widget now has its own independent font scale, decoupled from the main UI font. Set via new `/dg widgetfont <0.6-2.0>` command or the Settings tab's new "Widget Font Scale" section (A-/A+/Reset buttons). The main `/dg font` command no longer affects the widget, so you can keep a large main UI without bloating the floating widget.

## [1.7.7] - 2026-04-23

### Fixed
- **Compact Widget 8-Line Cap:** Widget now displays up to 10 active delve variants (previously capped at 8, hiding entries when 9-10 were active).
- **Font Scale Ignored by Widget:** `/dg font <0.6-2.0>` command and Settings tab A-/A+/Reset buttons now resize the compact widget's font and width. Previously only the main UI and HUD respected `fontScale`; the widget was hardcoded at 11pt/12pt regardless of the setting.

## [1.7.6] - 2026-04-21

### Changed
- **Patch 12.0.5 Compatibility:** Added interface version `120005` to the TOC so the addon is no longer flagged as "Out of Date" on the latest client. No logic changes.

## [1.7.5] - 2026-04-17

### Fixed
- **Parhelion Plaza Detection:** Scanner now queries mapID 2424 (the actual Isle of Quel'Danas uiMapID in Midnight). Previously it only scanned 2444, which does not expose the Parhelion Plaza POI -- so the delve never appeared in the "Active Today" section even when its variant was in rotation.
- **Parhelion Plaza Widget Set:** Registered widget set ID 1799 -> "Parhelion Plaza" so non-EN clients can resolve the localized delve name.
- **Torment's Rise Spurious "Missing Translation":** The Nullaeus Nemesis delve has no rotational variant, but was being logged as `[Missing Translation] Unknown Variant Text` in the Debug tab and inflating the active-variant count. Now correctly recognized as a Nemesis delve. Stale entries from previous versions are auto-purged from SavedVariables on load.

### Changed
- **Scan Dedup:** POIs exposed on multiple map IDs (e.g. Collegiate Calamity on 2393 and 2395) are now processed once instead of twice, halving scan work and removing duplicate rows from the Debug tab.

### Added
- **`/dg findplaza` Command:** Brute-force scans map IDs 2200-2700 to locate the Parhelion Plaza POI, for future rediscovery if Blizzard changes its map.

## [1.7.4] - 2026-04-12

### Added
- **Variant in Run History:** Completed delve runs now capture and display the story variant name (e.g., "Ogre Powered") in the History tab and chat log.
- **Traditional Chinese (zhTW):** 4 new variant translations -- Loosed Loa (alt), Holding the Line, March of the Arcane Brigade, Bombing Run.

### Fixed
- **HUD Font Scaling:** HUD overlay font size now respects the `fontScale` setting instead of being hardcoded at 11pt.
- **Spanish (esES) Trapped! Translation:** Corrected from "¡Atrapado!" to "¡Atrapados!" to match in-game text.
- **Parhelion Plaza esES Labels:** Properly labeled the 3 Parhelion Plaza Spanish variant translations.

### Changed
- **Darkway & Parhelion Plaza Widget Support:** Added TODO placeholders for widget set IDs needed for non-EN daily window detection (EN clients already supported).

## [1.7.3] - 2026-04-01

### Added
- **Spanish (esES/esMX) Full Coverage:** Expanded from 9 to 30/30 variant translations -- complete!
- **`/dg resetwidget` Command:** Resets the compact widget position to center if lost off-screen.

### Fixed
- **Widget Off-Screen Detection:** Widget now checks saved coordinates against screen bounds on load and auto-resets if off-screen.

## [1.7.2] - 2026-03-30

### Added
- **Traditional Chinese (zhTW):** 3 Darkway variant translations + alternate Mirror Shine translation for in-game vs achievement name mismatch.

### Fixed
- **Unicode Rendering:** Replaced em dashes, checkmarks, and other unicode characters that showed as squares in WoW's default font.
- **The Darkway Coordinates:** Updated Silvermoon City map pin to verified in-game location (39.30, 31.78).

### Changed
- **Future Tab Cleanup:** Removed stale entries for already-live system changes and past releases.

## [1.7.1] - 2026-03-28

### Fixed
- **Widget Position Reset:** Users upgrading from pre-1.7.0 may have their compact widget position reset to center. Simply drag it to your preferred location -- it will save correctly going forward.
- **DataBroker (LDB) Text:** Vault display now matches the main tracker format.

## [1.7.0] - 2026-03-27

### Added
- **Italian (itIT) Expansion:** Added 9 more Italian variant translations (26 of 30 now covered).
- **`/dg huddump` Command:** Dumps localized HUD data (zone, instance, scenario criteria) for locale debugging.

### Fixed
- **HUD Locale Support:** Variant, grade, tier, lives, nemesis, and bountiful now display correctly on non-English clients.
- **Great Vault Tracker:** Updated for Midnight API changes -- was showing `Delves: 0 (Vault 0/8)`.
- **Restored Coffer Key:** Now reads from currency system (Blizzard moved it from items to currency in Midnight).
- **World Quest Counter:** Deduplicated quests that appear on multiple overlapping zone maps.
- **Vault Reward ilvl:** Was displaying tier number instead of actual vault reward item level.
- **Widget Position:** Compact widget now correctly saves and restores position across reloads.

### Changed
- **Keys Tracker:** Shows green **(Capped)** when weekly shard cap is reached instead of reverting to 0/600.
- **Vault Progress:** Now shows completions toward max threshold (e.g. `8/8`) instead of slots unlocked.

## [1.6.2] - 2026-03-25

### Added
- **Spanish (esES/esMX) Support:** Added 9 variant translations for Spanish clients — new language!
- **Italian (itIT) Expansion:** Added 9 new Italian variant translations (17 of 30 now covered).

### Changed
- **Active Variants Sorted:** The "Active Today" section in the Delves tab now sorts by rank (S first, F last).

## [1.6.1] - 2026-03-25

### Changed
- **Silent Translation Logging:** Missing translation notifications no longer spam chat during POI scanning. A single one-time message prints on login if untranslated variants exist on your client.
- Missing translations are still silently logged to SavedVariables and viewable in the Debug tab.

## [1.6.0] - 2026-03-24

### Added
- **Share to Chat:** Share today's active variants to Party (left-click) or Guild (right-click) from the Delves tab and compact widget.
- **Completion Timer:** Live timer on the HUD during delve runs, saved to run history on completion.
- **Victory Screen Timer:** Your completion time now displays on the victory popup.
- **DataBroker Text Feed:** Info bar addons (Titan Panel, ElvUI, Bazooka) now show your top active variant and rank.
- **"What are Delves?" Tooltip:** Hover the ? icon in the Delves tab for a quick overview of Midnight Delve mechanics — aimed at new players.

### Changed
- **Interactive Flag Tooltips:** Delve flags ([Best], [Bug], [Mt], [Nemesis], [Bountiful], [TODAY]) are now individual buttons with hover tooltips explaining each tag.
- **Translation Logging:** Missing translations are now automatically logged to SavedVariables with locale, delve name, and first-seen date. Check the Debug tab to review and clear.

### Fixed
- **Restored Coffer Key ID:** Corrected the item ID used in roster character cache from 225091 to 3028.

## [1.5.1] - 2026-03-23

### Hotfix
- **Tooltip Hotfix:** Fixed a Lua error ("table index is secret") that could occur when hovering over protected game elements (like players or unit frames) with the new map tooltips enabled.

## [1.5.0] - 2026-03-23

### Added
- **World Map Tooltip Injections:** Hovering over an active Delve on the World Map will now seamlessly display the DelveGuide Speed Grade and active variant right inside the tooltip!
- **Map Tooltip Toggle:** Added a kill-switch in the Settings tab so users can disable map tooltips if they prefer a minimalist map.

### Fixed
- **Minimap Toggle Bug:** Fixed an issue where the minimap button wouldn't immediately hide/show when clicked in the Settings tab.
- **Blizzard Typo Handling:** Added a background fix for a typo Blizzard made in the English game client ("Captured Widlife") that was causing missing translation warnings.
- **Localization Expansion:** Fully verified and integrated the latest German (deDE) and Korean (koKR) variant translations.

## [1.4.5] - 2026-03-21

### Added
- **Traditional Chinese (zhTW) Support:** Added full variant translation support for the Traditional Chinese client.

### Fixed
- **Localization Fallback Overhaul:** Fixed an issue where a single missing translation would cause the addon to display all 24 variants at once. The addon now safely quarantines unknown variants with a "[Missing Translation]" tag, keeping your UI clean while identifying exactly which string needs to be reported.

## [1.4.4] - 2026-03-21

### Fixed
- **Localization Hotfix:** Fixed a critical Lua syntax error that was preventing the localization dictionaries from loading properly. The addon will now correctly translate Delve variants on all non-English clients (krKR, deDE, frFR, etc.) and gracefully fall back to showing all variants if a translation is missing.

## [1.4.3] - 2026-03-21

### Added
- **New Feature: Victory Screen!** A sleek, animated "Run Completed" toast will now drop down from the top of your screen whenever you finish a Delve.
- The Victory Screen displays your exact weekly Delves completed and your newly unlocked Great Vault item level.
- **Custom Audio:** Added a custom Final Fantasy-style Victory Fanfare that plays when you complete a run.
- **New Settings:** You can now enable/disable the Victory Screen, toggle the sound effect, and unlock the frame to drag it anywhere on your screen.
- Added a "Test / Move Popup" button in the Settings tab so you can configure your layout without having to actually run a Delve.

### Fixed
- **Great Vault Tracking Overhaul:** Bypassed a major flaw in Blizzard's `C_WeeklyRewards` API where open-world activities (like World Bosses) were falsely incrementing the Delve counter. DelveGuide now calculates your Great Vault progress purely from your internal run history for 100% accuracy.

## [1.4.2] - 2026-03-21
### Added

- Companion tab — track Valeera/Brann level, role, and XP progress via a visual progress bar
- Live Curio scanning — compares currently equipped curios against S-Tier spec recommendations and shows dynamic warnings
- Smart Tier auto-detection for the In-Run HUD (API checking + Objective Tracker scraping)
- Automated Great Vault tracking — auto-detected tiers are now directly logged to your History tab
- Korean (koKR) variant translation support
- Graceful fallbacks for missing translations — shows all possible variants if the localized name isn't recognized by the dictionary

### Changed

- Main window and In-Run HUD are now fully resizable with bottom-right grip handles
- Debug tab overhauled into a System Health Dashboard (shows database size, live API status, and troubleshooting commands)
- Refactored Pre-Entry Checklist and Compact Widget into separate modules (`DelveGuide_Checklist.lua` and `DelveGuide_Widget.lua`)
- Moved all localization translation dictionaries to `DelveGuide_Data.lua`
- Variant text scanning logic now uses robust substring matching instead of strict punctuation parsing

### Fixed

- Bypassed C_DelvesUI API restrictions to correctly read Companion data even when standing outside of a delve instance
- Fixed a scope bug causing the LibDBIcon minimap toggle to fail
- Cleaned up unused legacy variables and dead code to optimize memory usage


## [1.3.0] - 2026-03-16

### Added

- In-Run HUD (`DelveGuide_HUD.lua`) — auto-shows when inside a known Delve, hides on exit
- HUD displays: delve name, active variant + grade, tier, recommended curios, nemesis warning, bountiful status, remaining lives
- HUD is draggable; position persists across sessions
- HUD lock button (padlock icon) — prevents accidental repositioning; state saved across sessions
- `/dg hud` to manually toggle the HUD (works as preview outside Delves too)
- `/dg tier [1-11]` — manually set delve tier; persists across runs so you only need to set it once per farming session
- Tier row shows a grayed-out `/dg tier [1-11]` hint until the player sets it
- Tier set via `/dg tier` is saved to run history and used for Great Vault ilvl tracking

### Fixed

- Removed Unicode characters (⚠ ★ ✓) that rendered as squares in WoW's default font; replaced with ASCII equivalents

## [1.2.2] - 2026-03-16

### Added

- History: each run now shows which character completed the delve
- History: "Clear History" button with confirmation dialog

## [1.2.1] - 2026-03-16

### Fixed

- Opening the world map no longer triggers `ADDON_ACTION_BLOCKED` (SetPassThroughButtons taint)
- Waypoint clicks now set the pin silently — press M to open your map and navigate

## [1.2.0] - 2026-03-15

### Added

- Roster tab — track all level-80+ alts' weekly delves, shards, ilvl, and vault slots
- Roster: per-character remove button (x) with confirmation dialog
- "What's New" popup on version update — shows once per version, re-openable from Settings
- "View Changelog" button in Settings tab

### Fixed

- Targeting a delve entrance no longer triggers a taint error (secret string compare)

## [1.1.0] - 2026-03-14

### Added

- Settings tab: UI-configurable minimap button, compact widget, tier filter, font scale
- Compact floating widget: shows active delve variants with rank, tier filter, lock button
- Widget lock button with padlock texture (prevents accidental repositioning)
- Widget tier filter: toggle S/A/B/C/D/F ranks shown in widget (Settings tab)
- Clickable delve names in widget and main Delves tab — opens map and sets waypoint
- Item tooltips on Loot tab (hover to preview with correct bonus ID)
- Weekly reset timer in main window header bar
- Great Vault tracker: shows delve count and slot progress in header and Delves tab
- Coffer key shard currency tracker in header bar
- History tab now groups runs by WoW week with vault slot summary per week
- /dg help command listing all slash commands

### Fixed

- OpenWorldMap taint (ADDON_ACTION_BLOCKED) — deferred via C_Timer.After(0)

## [1.0.4] - 2026-03-14

### Fixed

- Minimap button: assign btn upvalue before drag callbacks (nil crash fix)
- Minimap button: exact NightPulse drag math and background texture

## [1.0.2] - 2026-03-14

### Fixed

- Restored DelveGuide.lua after file corruption
- Minimap button updated to left-drag pattern (consistent with NightPulse/MidnightCheck)
- Fixed angle calculation in minimap drag handler

## [1.0.1] - 2026-03-13

### Changed

- Minimap button: switched from right-drag to left-drag (RegisterForDrag pattern, consistent with MidnightCheck)
- Fixed angle calculation using button effective scale instead of UIParent scale

## [1.0.0] - 2026-03-01

### Added

- Initial release
- Delve listings, curio DB, loot tables, completion history
- Active variant scanner (C_AreaPoiInfo)
- Minimap button with saved angle
- Font scale setting (/dg font)
