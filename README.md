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
- **World Map Tooltips** — hover active Delves on the map to see their Speed Grade and Variant

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
- Verifies: Coffer Key Shards · Restored Coffer Keys · Bountiful Delve token · Beacon of Hope
- Catches you before you waste a Bountiful run with missing keys

### 📦 Compact Widget

- Persistent floating widget showing: **Shard count · Restored Coffer Keys · Active high-value variants**
- **Share button** — send displayed variants to Party or Guild
- Configurable tier filter (show/hide S/A/B/C/D/F ranks)
- Draggable and lockable, with optional click-to-open and auto-hide

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

### 🎁 Loot Tab

Delve loot reference organized by tier — know what drops before you go in.

### 📜 History Tab

- Run log grouped by **weekly reset** — timestamps, character names, variant details
- **Completion times** displayed per run

### ⚙️ Settings

- Toggle: minimap button · compact widget · pre-entry checklist · in-run HUD · victory screen · changelog popup · map tooltips
- Adjust font scale (0.6–2.0) with live preview
- Widget auto-hide and click-to-open options
- All settings are **saved per-account** via `SavedVariables`

---

## ⌨️ Slash Commands

| Command | Description |
| --- | --- |
| `/dg` | Open / close DelveGuide |
| `/dg scan` | Rescan active Delve variants |
| `/dg hud` | Toggle the in-run HUD |
| `/dg widget` | Toggle the compact widget |
| `/dg check` | Toggle the pre-entry checklist |
| `/dg minimap` | Toggle the minimap button |
| `/dg share [channel]` | Share active variants to chat (party/guild/say/raid) |
| `/dg tier [1-11]` | Set your current Delve tier in the HUD |
| `/dg font [0.6-2.0]` | Adjust text scale |
| `/dg chatdump` | Print full scan results to chat (for localization reports) |
| `/dg specinfo` | Show your detected spec ID (debug) |
| `/dg help` | Show all available commands |

---

## 📋 Requirements

- **No dependencies required** — works out of the box
- Compatible with **World of Warcraft: Midnight** (Interface 120001)
- TomTom is **optionally supported** for waypoint pins

---

## 🗓️ Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

---

## 👤 Author

**Thunderz** — [GitHub](https://github.com/Thunderz96/DelveGuide) · [CurseForge](https://www.curseforge.com/wow/addons/delveguide)

*Feedback, bug reports, and feature requests welcome via GitHub Issues or CurseForge comments.*
