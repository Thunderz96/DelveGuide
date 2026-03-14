# Changelog

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
