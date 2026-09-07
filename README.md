# DelveGuide

> **The definitive in-game reference for Midnight Delves.**
> Rankings, curios, loot, nemesis guides, roster tracking, an in-run HUD, and more — all in one addon.

---

## 📖 Overview

DelveGuide is a World of Warcraft addon built for players who want to get the most out of Midnight's Delve system. Whether you're farming vault slots across multiple alts, hunting Bountiful Delves, optimizing your curio loadout, or preparing to face the Season 2 Nemesis Azta'rec — DelveGuide has you covered.

> 🆕 **Patch 12.1 "Curse of Ula'tek" / Season 2 ready** — The Coiled Isle, the new **Ring of Glory** and **Gnarldor Isle** delves, venom variants on existing delves, and a full **Venomfall Deeps** (Azta'rec) Nemesis guide. *(Bountiful Delves, Coffer Keys, and the seasonal Great Vault unlock with Season 2 on Aug 18.)*

---

## ✨ Features

### 🗺️ Delves Tab

- Full list of all Delves with **S–F variant rankings**
- Live indicators for **active Nemesis** and **Bountiful** status
- Interactive flag badges (**[Best]**, **[Bug]**, **[Mt]**, **[Nemesis]**, **[Bountiful]**, **[TODAY]**) with hover tooltips
- Highlights your current best routes and known bugs/quirks
- **Share to Chat** — send today's active variants to Party or Guild with one click
- **"What are Delves?"** tooltip (hover the **?** icon) for new players
- **World Map Tooltips** — hover active Delves on the map to see their Speed Grade and Variant. Tier 8+ delves are flagged as max-ilvl loot, worth a Voidcore bonus roll.

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
- Verifies: **Coffer Key** (shard count + Restored Coffer Keys) · **Trovehunter's Bounty** (active / in bags but not activated / already used this week) · **Valeera** and her selected role
- Also flags a **Scalebound Herald's Flute** in your bags, and tells you whether using it will still earn this week's Bounty map
- Catches you before you waste a Bountiful run with no key, or enter with your Bounty still sitting unactivated in your bags

### 📦 Compact Widget

- Persistent floating widget showing: **Shard count · Restored Coffer Keys · Voidforge progress · Active high-value variants**
- **Bountiful-Only filter** — `[B]` button in the header hides every non-bountiful variant (gold = ON, grey = OFF). Mirrored by `/dg bountiful` and the Settings tab.
- **Share button** — send displayed variants to Party or Guild (respects the bountiful filter)
- Configurable tier filter (show/hide S/A/B/C/D/F ranks)
- **Independent font scale** — `/dg widgetfont` keeps the widget compact even when the main UI font is bumped up
- Draggable and lockable, with optional click-to-open and auto-hide

### 🧙 Voidforge — Bonus Rolls & Gear Upgrades

The Voidforge tab tracks Season 2's two delve reward currencies:

- **Nebulous Voidcore** — the bonus-roll token. After a raid boss, Mythic+ dungeon, Bountiful Delve or Nightmare Prey Hunt, spend one to roll for additional loot; one item per difficulty level until your spec's pool is exhausted. For now only the Great Vault awards them; a weekly purchase is expected around 12.1.5.
- **Ascendant Venomstone** — the gear-upgrade material *(arriving later this season)*. 10 upgrade one weapon or trinket, the only slots they apply to; a Tier 11 Bountiful Delve guarantees one (~1-2).

Plus an **upgrade priority** scan of the four Venomstone slots (weapons and trinkets, lowest ilvl first) and an **alt stockpile** rollup across your cached characters.

### 📊 DataBroker Feed

- Native **LibDataBroker** support for info bar addons (Titan Panel, ElvUI, Bazooka)
- Displays your **top active variant**, rank, shard count, and vault progress

### 💀 Nemesis Tab

A **seasonal** guide slot — the current season's Nemesis delve gets the full write-up, and the previous one drops to a compact legacy section for collectors.

**Season 2 — Venomfall Deeps (Azta'rec):**
- Location & coordinates · Unlock tiers (Tier 7 → `?`, Tier 10 → `??`; higher difficulty opens Aug 18)
- All 6 core abilities, led by the *Sermon of Ula'tek* Simon-Says memory mechanic
- Companion (Healer Valeera) plus curio and interrupt advice
- Full reward list — **Apophic Soul Crusher** mount, **Apophic Patagia** back, *Corrosive Victory* toy, "*the Poisonous*" title, and the **time-limited** *Fabled Vanquisher of Azta'rec*

**Legacy — Nullaeus (Season 1):** Torment's Rise stays enterable; a compact reference for what's still collectible vs. retired.

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
- Per-week count of **Tier 8+ runs** (max-ilvl loot)

### 🔮 Future Tab

Roadmap for upcoming features and planned data additions, kept in-game so you can see what's on the way without leaving WoW.

### ⚙️ Settings

- Toggle: minimap button · compact widget · widget click-to-open · widget auto-hide · **bountiful-only filter** · pre-entry checklist · in-run HUD · victory screen · changelog popup · map tooltips
- Widget tier filter (S/A/B/C/D/F)
- **Main font scale** (0.6–2.0) with live preview
- **Widget font scale** (0.6–2.0) — independent from the main scale
- All settings are **saved per-account** via `SavedVariables`

---

## 🚫 What DelveGuide does not do

- It does **not** show treasure or curiosity locations inside a Delve — there are no in-Delve maps, routes, or object pins.
- It tells you which Delve to run and what to bring; once you're inside, you're on your own.

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
| `/dg submit` | Copy your run times to submit for the community rankings |
| `/dg tier <1-11>` | Manually set the current Delve tier in the HUD |
| `/dg font <0.6-2.0>` | Main UI font scale |
| `/dg widgetfont <0.6-2.0>` | Widget-only font scale (independent from main) |
| `/dg help` | Show all available commands |

> Debug commands available for bug reports and localization fixes: `dump`, `chatdump`, `huddump`, `tierdebug`, `checkdebug`, `specinfo`, `currencydebug`, `vaultdebug`, `selftest`, `findpoi <text>`. They always run; tick **Show Debug tab** in Settings to have `/dg help` list them too.

---

## 🏆 Help rank the delves

The S–F rankings aren't guesswork — they're built from players' own timed runs, and yours can go in too.

1. Run some Delves. DelveGuide times every run automatically.
2. Type `/dg submit`. It hands you a code, pre-selected — just press Ctrl+C.
3. Paste the code into the form: **<https://forms.gle/BwrGBZkRmbQdwufN8>**

Only clear times are included — no character or account data. Submitted times are pooled, reduced to a median per variant, and shipped back as the rankings you see in-game. Contributors are credited on the Settings tab.

---

## 🌍 Translating

Every string a player sees goes through a lookup table, so DelveGuide can show your language without a code change. Copy `Locales/TEMPLATE.lua` to `Locales/<locale>.lua` (for example `Locales/deDE.lua`), set the locale on its first code line, translate the right-hand side of each line, delete the lines you did not translate (they fall back to English), add the file to `DelveGuide.toc` directly after `DelveGuide_Locale.lua`, and open a pull request. Keep `%s` / `%d` placeholders in the same order. Delve, variant and item names are game data and are not in the template; those live in the locale tables inside `DelveGuide_Data.lua`.

## 📋 Requirements

- **No dependencies required** — works out of the box
- Compatible with **World of Warcraft: Midnight** — current through **Patch 12.1 "Curse of Ula'tek" / Season 2** (Interface 120100; also loads on 120000 / 120001 / 120005)
- TomTom is **optionally supported** for waypoint pins

---

## 🗓️ Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

---

## 👤 Author

**Thunderz** — [GitHub](https://github.com/Thunderz96/DelveGuide) · [CurseForge](https://www.curseforge.com/wow/addons/delveguide)

*Feedback, bug reports, and feature requests welcome via GitHub Issues or CurseForge comments.*
