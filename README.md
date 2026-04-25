# DelveGuide

> **The definitive in-game reference for Midnight Delves.**
> Rankings, curios, loot, nemesis guides, roster tracking, an in-run HUD, and more — all in one addon.

---

## 📖 Overview

DelveGuide is a World of Warcraft addon built for players who want to get the most out of Midnight's Delve system. Whether you're farming vault slots across multiple alts, hunting Bountiful Delves, optimizing your curio loadout, or preparing to face Nullaeus — DelveGuide has you covered.

---

## ✨ Features

### 🗺️ Delves Tab

- Full list of all Delves with **S–F variant rankings**
- Live indicators for **active Nemesis** and **Bountiful** status
- Interactive flag badges (**[Best]**, **[Bug]**, **[Mt]**, **[Nemesis]**, **[Bountiful]**, **[TODAY]**) with hover tooltips
- Highlights your current best routes and known bugs/quirks
- **Share to Chat** — send today's active variants to Party or Guild with one click
- **"What are Delves?"** tooltip (hover the **?** icon) for new players
- **World Map Tooltips** — hover active Delves on the map to see their Speed Grade and Variant. Tier 8+ delves are flagged as Voidcore-eligible.

### 🎯 In-Run HUD

- Auto-appears when you **enter a Delve**, hides when you leave
- Shows: **Delve name · Active variant + grade · Tier · Curio recommendation · Nemesis warning · Bountiful status · Remaining lives · Completion timer**
- **Live Timer** — tracks your run duration in real time
- **Draggable**, **lockable**, and **resizable** — remembers its position between sessions
- Toggle manually with `/dg hud` (works as a preview outside Delves)

### 🏆 Victory Screen

- Animated toast on **Delve completion** with fade in/hold/fade out
- Displays **completion time**, weekly delve count, and Great Vault ilvl unlocked
- Custom victory fanfare audio
- Draggable and toggleable via Settings

### ✅ Pre-Entry Checklist

- Triggers automatically when you **target a Delve entrance**
- Verifies: Coffer Key Shards · Restored Coffer Keys · Bountiful Delve token · Beacon of Hope · **Voidforge weekly progress**
- Catches you before you waste a Bountiful run with missing keys or unfilled Voidforge shards

### 📦 Compact Widget

- Persistent floating widget showing: **Shard count · Restored Coffer Keys · Voidforge progress · Active high-value variants**
- **Bountiful-Only filter** — `[B]` button in the header hides every non-bountiful variant (gold = ON, grey = OFF). Mirrored by `/dg bountiful` and the Settings tab.
- **Share button** — send displayed variants to Party or Guild (respects the bountiful filter)
- Configurable tier filter (show/hide S/A/B/C/D/F ranks)
- **Independent font scale** — `/dg widgetfont` keeps the widget compact even when the main UI font is bumped up
- Draggable and lockable, with optional click-to-open and auto-hide

### 🧙 Voidforge Integration *(Patch 12.0.5)*

Patch 12.0.5 *"Lingering Shadows"* added the Voidforge upgrade system. DelveGuide surfaces it across the existing UI:

- **Widget:** "Cores / Forge" line shows current Nebulous Voidcore count and Elementary Voidcore Shard progress toward the weekly *Building The Voidforge* quest
- **Pre-entry Checklist:** "Voidforge weekly" row flags whether you still owe shards before your next Bountiful Delve
- **History Tab:** Per-week summary now reports how many of that week's runs were Tier 8+ and therefore Voidcore-eligible
- **World Map Tooltip:** Active-delve tooltips include a "T8+: drops Nebulous Voidcore" reminder
- **Loot Tab:** Voidforge Currencies section explains Nebulous / Elementary Shard / Ascendant Voidcores

### 📊 DataBroker Feed

- Native **LibDataBroker** support for info bar addons (Titan Panel, ElvUI, Bazooka)
- Displays your **top active variant**, rank, shard count, and vault progress

### 💀 Nullaeus Tab

Dedicated guide for the **Season 1 Nemesis**:

- Location & coordinates · Unlock requirements (Tier 7 → `?`, Tier 10 → `??`)
- **Beacon of Hope** workflow — earn the weekly bounty without entering Torment's Rise
- All 4 core mechanics: *Emptiness of the Void, Devouring Essence, Dread Portal, Umbral Rage*
- Phase transitions at **75% · 50% · 25%**
- Recommended setup, ilvl guidance, 8 strategic tips
- Full reward list — including the region-limited **Fabled Vanquisher** title

### 👥 Roster Tab

Track all your **level 80+ alts** in one view:

- Weekly Delves completed · Vault slots filled · Coffer Key Shards · Restored Coffer Keys · Item level
- Characters register **automatically** on login
- Per-character remove button with confirmation

### 🧪 Curios Tab

Spec-by-spec curio recommendations for every class and specialization.

### 🤝 Companion Tab

Live status panel for **Valeera Sanguinar**:

- **XP / level bar** — works anywhere, not just inside delves. Reads from her friendship reputation faction so you can check progress between runs.
- **Role detection** (DPS / Healer / Tank) and **live curio loadout scan** when the Blizzard Companion panel is open
- Spec-aware curio recommendations with mismatch warnings when your equipped curios don't match the rec
- Auto-discovery scans for the companion faction on first render and caches the ID per-character (`/dg companionscan` to re-scan, `/dg companionfaction <id>` to pin manually)

### 🎁 Loot Tab

Delve loot reference organized by tier — know what drops before you go in. Includes the new Voidforge Currencies section.

### 📜 History Tab

- Run log grouped by **weekly reset** — timestamps, character names, variant details
- **Completion times** displayed per run
- Per-week count of **Tier 8+ runs** (Voidcore-eligible)

### 🔮 Future Tab

Roadmap for upcoming features and planned data additions, kept in-game so you can see what's on the way without leaving WoW.

### ⚙️ Settings

- Toggle: minimap button · compact widget · widget click-to-open · widget auto-hide · **bountiful-only filter** · pre-entry checklist · in-run HUD · victory screen · changelog popup · map tooltips
- Widget tier filter (S/A/B/C/D/F)
- **Main font scale** (0.6–2.0) with live preview
- **Widget font scale** (0.6–2.0) — independent from the main scale
- All settings are **saved per-account** via `SavedVariables`

---

## ⌨️ Slash Commands

| Command | Description |
| --- | --- |
| `/dg` | Open / close DelveGuide |
| `/dg scan` | Rescan active Delve variants |
| `/dg map` | Open the world map |
| `/dg hud` | Toggle the in-run HUD |
| `/dg widget` | Toggle the compact widget |
| `/dg resetwidget` | Reset widget position to center |
| `/dg bountiful` | Toggle the widget's bountiful-only filter |
| `/dg check` | Show the pre-entry checklist |
| `/dg minimap` | Toggle the minimap button |
| `/dg roster` | Open the Roster tab |
| `/dg companionscan` | Re-scan for the companion reputation faction |
| `/dg companionfaction <id>` | Manually pin the companion faction ID |
| `/dg share [channel]` | Share active variants to chat (party/guild/say/raid) |
| `/dg tier <1-11>` | Manually set the current Delve tier in the HUD |
| `/dg font <0.6-2.0>` | Main UI font scale |
| `/dg widgetfont <0.6-2.0>` | Widget-only font scale (independent from main) |
| `/dg help` | Show all available commands |

> Debug commands available for bug reports and localization fixes: `dump`, `chatdump`, `huddump`, `tierdebug`, `checkdebug`, `specinfo`, `findplaza`.

---

## 📋 Requirements

- **No dependencies required** — works out of the box
- Compatible with **World of Warcraft: Midnight** (Interface 120000, 120001, 120005 — through Patch 12.0.5)
- TomTom is **optionally supported** for waypoint pins

---

## 🗓️ Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

---

## 👤 Author

**Thunderz** — [GitHub](https://github.com/Thunderz96/DelveGuide) · [CurseForge](https://www.curseforge.com/wow/addons/delveguide)

*Feedback, bug reports, and feature requests welcome via GitHub Issues or CurseForge comments.*
