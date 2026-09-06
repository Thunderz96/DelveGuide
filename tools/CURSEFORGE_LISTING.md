# CurseForge listing — paste source for 2.0.0

The live listing is still Season 1 text ("preparing to face Nullaeus", a Nullaeus tab
section, Beacon of Hope, Interface 120001) and mentions none of: the Victory screen, the
Voidforge tab, the Companion tab, the DataBroker feed, the History community block, Share to
Chat, `/dg submit`. This file is the replacement, built from README.md after Phase 0 corrected
it. Paste the **Description** block into the CurseForge project description; the two short
blocks after it are for the gallery captions and the comment thread.

Before pasting at release: replace `«N»` / `«V»` with the figures in
`DelveGuideData.rankingStats` (99 / 39 at the time of writing — the corrected aggregator
produces 97 if its four grade moves are published) and confirm the Interface line.

---

## Description

**DelveGuide — the in-game reference for Midnight Delves, with rankings measured from real runs.**

Every other delve addon tells you what a variant *is*. DelveGuide tells you how *fast* it is:
the S–F grades come from **«N» players' timed runs across «V» variants**, submitted with one
command and reduced to a median per variant. Not guesswork, not the author's opinion —
measured, and refreshed every release.

**Display-only, by design.** DelveGuide reads Blizzard's delve UI and never writes to it — no
companion-loadout changes, no protected-frame hooks, no taint. Your Great Vault credit,
scenario objectives and companion configuration are untouched.

**Patch 12.1.5 ready.** Recognises the Labyrinth of Kindo'jan and keeps it out of your delve
history and rankings — a Labyrinth is not a delve, even though it grants delve vault credit.
Fuller Labyrinth support lands as the content stabilises.

### What you get

**Delves tab** — every delve with its variant grade, live **Bountiful** and **Nemesis** flags,
best-route and known-bug badges, a "how grades work" tooltip, and a *rotates in Xh Ym*
countdown. Click a row for a native waypoint arrow (TomTom optional).

**In-run HUD** — appears on entry, hides on exit: delve, variant + grade, tier, curio
recommendation, lives, and a live timer that survives a `/reload`.

**Victory screen** — completion time, weekly delve count, vault ilvl unlocked, and how you did
against your personal best and the community median.

**Pre-entry checklist** — target a delve entrance and it checks your Coffer Key, Trovehunter's
Bounty state, Valeera's role, and whether your Herald's Flute will still earn this week's map.

**Compact widget** — shards, restored keys, Voidforge progress and today's high-value
variants in a small always-on panel, with a bountiful-only filter and one-click **Share to
Chat**.

**Voidforge tab** — Nebulous Voidcores and Ascendant Venomstones: what you have, where they
come from, what to upgrade first, and your alts' stockpile.

**Companion tab** — Valeera's level and XP anywhere (not just inside a delve), role detection,
and a live curio-loadout check against the recommendation for your spec.

**History tab** — every run grouped by weekly reset with time, tier, variant and vault ilvl,
your per-variant medians, and how they compare to the community's.

**Roster tab** — all your level-80 alts: weekly delves, vault slots, keys, item level.

**Nemesis tab** — the season's Nemesis delve in full (Venomfall Deeps / Azta'rec), with the
previous season kept as a compact legacy reference.

**Also:** Loot tab by tier · Curios tab by spec · world-map tooltips with grade and variant ·
LibDataBroker feed for Titan/ElvUI/Bazooka · keybindings · addon compartment entry · ESC >
Options signpost · in-game changelog.

### Help rank the delves

DelveGuide times every run. Type `/dg submit`, paste the code into the form it links, and
your times join the pool. Only clear times are sent — no character or account data.
Contributors are credited on the Settings tab.

### Requirements

No dependencies. Interface 120105 (12.1.5), also loads on 12.1.0. TomTom optional.

`/dg` opens the window · `/dg help` lists every command.

---

## Gallery captions (target: 8 images; there are 5 today, the leading rival has 16)

Add at least: the **HUD mid-run** (timer + lives visible), the **Voidforge tab**, the **History
tab with the community comparison block**, and the **Victory toast with the comparison row**.

1. Delves tab — grades, flags, today's variants, rotation countdown
2. In-run HUD — variant, grade, tier, lives, live timer
3. Victory screen — time vs personal best and community median
4. Pre-entry checklist at a delve entrance
5. Compact widget with bountiful-only filter
6. Voidforge tab — currencies and upgrade priority
7. History tab — weekly runs and community comparison
8. Companion tab — Valeera's XP and loadout check

---

## Comment for the thread where "not actively playing retail" sits at the top

> Short update: DelveGuide is in active development for 12.1.5 — 2.0.0 is being tested on the
> PTR now. The rankings have never depended on my own playtime: they're built from the runs
> you all submit with `/dg submit`, medianed per variant, and refreshed each release. If you
> want a variant graded that isn't yet, that command is how it gets there. Thanks to everyone
> who has sent times in.
