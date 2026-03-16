# Changelog

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
