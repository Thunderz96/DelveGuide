# Changelog

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
