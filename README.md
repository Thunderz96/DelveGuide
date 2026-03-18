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
- Highlights your current best routes and known bugs/quirks

### 🎯 In-Run HUD

- Auto-appears when you **enter a Delve**, hides when you leave
- Shows: **Delve name · Active variant + grade · Tier · Curio recommendation · Nemesis warning · Bountiful status · Remaining lives**
- **Draggable** and **lockable** — remembers its position between sessions
- Toggle manually with `/dg hud` (works as a preview outside Delves)

### ✅ Pre-Entry Checklist

- Triggers automatically when you **target a Delve entrance**
- Verifies: Coffer Key Shards · Restored Coffer Keys · Bountiful Delve token · Beacon of Hope
- Catches you before you waste a Bountiful run with missing keys

### 📦 Compact Widget

- Persistent floating widget showing: **Shard count · Restored Coffer Keys · Active high-value variants**
- Configurable tier filter (show/hide S/A/B/C/D/F ranks)
- Draggable and lockable, with optional click-to-open for the main window

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

Session log of completed Delves — timestamps, character names, and variant details.

### ⚙️ Settings

- Toggle: minimap button · compact widget · pre-entry checklist · in-run HUD · changelog popup
- Adjust font scale (0.6–2.0) with live preview
- All settings are **saved per-account** via `SavedVariables`

---

## ⌨️ Slash Commands

| Command | Description |
| --- | --- |
| `/dg` | Open / close DelveGuide |
| `/dg hud` | Toggle the in-run HUD |
| `/dg widget` | Toggle the compact widget |
| `/dg check` | Toggle the pre-entry checklist |
| `/dg minimap` | Toggle the minimap button |
| `/dg tier [1-11]` | Set your current Delve tier in the HUD |
| `/dg scan` | Rescan active Delve variants |
| `/dg font [0.6-2.0]` | Adjust text scale |
| `/dg reset` | Reset the main window position |

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
