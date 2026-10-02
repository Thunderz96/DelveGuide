# DelveGuide

## [2.0.0] - 2026-09-TBD

Built for **Patch 12.1.5 (Midnight)**; runs on 12.1.0 as well.

### Labyrinths
- **DelveGuide recognises the Labyrinth of Kindo'jan.** Inside one, the game reports the same scenario type and difficulty a delve does, so every test the addon ran said "delve": it started a delve timer and wrote a delve-shaped run with no variant and no tier for each chamber cleared. Outdoors, the Labyrinth arrived through the delve POI API and showed up as an unknown-variant row. Neither happens now.
- **An in-run HUD for Labyrinths** -- which Labyrinth, the current chamber, tier, objective progress, lives, chambers cleared and the vault credit they are worth, and time since you entered.
- **A run summary when you leave**: a chat line and the Victory toast with the chambers cleared, the vault credits they earned, the tier and the time.
- **Labyrinth runs are logged in History** as their own kind of run, and their vault credit counts toward the weekly tallies on the Roster, the History tab and the Victory screen. **Every 3 chambers cleared is one vault credit, at any tier** -- the credit one delve gives, so a nine-chamber run is worth three delves. This was checked against the Great Vault's own counter on the PTR. The row and each chamber time carry the tier.
- **A Labyrinth tab.** This week's runs per character; your renown with the Labyrinth of Kindo'jan; your progress up the tier ladder (the eleven "3 chambers on Tier N" achievements) with lifetime chambers cleared and Kindo'jan kills; the chambers you have seen, named by their objective, with your own median times; the rewards -- mount, titles, toys -- each marked earned, collected or not yet from your own account; and the few tips we can stand behind. `/dg labyrinth` or `/dg lab` opens it.
- **Chambers are named by their objective.** From PTR build 69848 every chamber reports the same scenario name, "The Labyrinth of Kindo'jan", so the addon now catches each chamber's step title while it runs (by the time a chamber completes, the step is gone).
- **Run submissions carry chamber times.** `/dg submit` adds a Labyrinth section (chamber, tier, seconds) once you have timed a chamber. A code from a client that has never been inside a Labyrinth is unchanged.
- This is Labyrinth **support**, not a Labyrinth guide: there are no route or chamber tips yet.

### Added
- **The pre-entry checklist now opens by itself.** It never fired automatically before 2.0.0: it watched your target, and a delve entrance is a game object, not something you can target -- so the only way to see it was `/dg check`. It now opens with the entrance dialog, sits just above the tier picker, can be dragged, remembers where you put it, and closes with ESC or when the dialog does.
- **Keybindings** for the window, the HUD and the compact widget, under ESC > Key Bindings > AddOns.
- **An addon compartment entry**, with a *Show in the addon compartment* toggle in Settings, and an ESC > Options > AddOns entry that opens the guide.
- **A "Rotates in Xh Ym" countdown** to the daily variant rotation, on the Delves tab header and the compact widget.
- **A native map waypoint.** Clicking a delve now sets Blizzard's own waypoint arrow; TomTom stays optional rather than being the only way to get a pin on screen.
- **The Victory screen compares the run to your personal best** for that delve and variant, and to the community median. The same line is printed to chat, so it survives the toast fading or being turned off.
- **A "How grades work" tooltip** on the Delves rankings header: the grades are measured Tier 8+ clear times, not a difficulty rating.
- **A Cosmetics group on the Loot tab** -- mounts, pets, toys and transmog from the delve vendors, checked against their actual stock in game.
- **Settings gains an About block** with the version and copyable GitHub / CurseForge / rankings-form links, and a *Show Debug tab* toggle.
- **`/dg selftest`** prints one pass/fail block you can paste into a bug report, and **`/dg export`** now captures far more for the same purpose. Selftest earned its keep immediately: it caught the Loot tab break below on its first run against 12.1.5.
- **`/dg findpoi <text>`** searches the map for a delve POI by name. It replaces `/dg findplaza`, which only ever matched one English word; `findplaza` is kept as a shorthand.
- **`/dg quest`** now works as an alias of `/dg journey` and `/dg quests`.
- **Delve glove enhancements** (new in 12.1.5) are listed on the Loot tab: the four of them, what each does, the item-level-334 cap, and where they come from (Labyrinth renown). The pre-entry checklist shows a green line when one is on your gloves and otherwise says nothing.
- **Viperwind Idol** joins the Curios tab, and every curio's new **Rank 5** is recognised on the Companion tab in any language (curios are matched by the spell ID of each rank).
- **Ascendant Venomstones are counted** on the Voidforge tab and in your alts' stockpile. Drops start the week of Oct 20.

### Fixed
- **A `/reload` in the middle of a run no longer loses the run.** The timer used to restart from zero, which fed a fabricated fast time into the community median. The run start is now stored as wall clock and resumed, and the variant is carried through the reload, so a reloaded run still reaches the rankings.
- **Runs completed near the weekly reset could land in the previous week** and go missing from the Roster's weekly count, the Victory tally and the History grouping. One second of clock jitter was enough. Older runs are snapped back onto the reset grid too, so History no longer shows the same week twice.
- **Test runs from `/dg testrun` counted as a second character** on the Roster and in History.
- **The Loot tab errored on every render on 12.1.5** -- the game function it used to read item data was deleted in the patch. (Also shipped to 12.1.0 players in 1.11.2.)
- **Opening the map no longer taints it.** Clicking a delve used to open and re-point the world map from addon code, after which map pins could be blocked in combat and the waypoint's shift-click failed. The map now opens through Blizzard's own call, and only when nothing restricts it (combat, an encounter, a keystone, a PvP match). (Also in 1.11.2.)
- **Tier and lives in the HUD now come from the delve's own header widget** rather than from reading the objective tracker's text. That works in every language, and inside a Labyrinth. Lives were never an objective at all, which is why they had always been unreliable.
- **The Companion tab reads Valeera's live role and curios from the game's own data**, not from the text on Blizzard's panel. It now works on any language and with that panel closed; before, the role stayed "Unknown" and no curio was ever detected on a translated client.
- **Unknown commands print the help instead of opening or closing the window**, so a typo no longer looks as though it worked. `/dg tier` with no number prints its usage, and the tab commands open the window rather than toggling it shut.
- **The widget's tier filter no longer leaks delves back in** as unranked `[?]` rows; with every rank unticked the widget is empty and says why.
- **Voidforge no longer lists an empty off-hand as your top upgrade** when you are wielding a two-hander or a ranged weapon.
- **Sharing to party or guild when you are in neither** prints a friendly line instead of a red error, and a full rotation goes out as packed lines rather than a dozen separate messages.
- **The checklist's rows stay on one line**, with their tips on hover, so the flute row can no longer spill over the dismiss checkbox. Clicking the X now only closes the checklist; it used to suppress it for the rest of the session.
- **Refreshing a tab keeps your scroll position** -- a POI update or a font change no longer yanks the list back to the top.
- **Nebulous Voidcores were described as dropping from Tier 8+ delves.** They do not drop from delves at all. A Voidcore is a **bonus-roll token**, spent after a boss or a completed run to roll for additional loot. The Great Vault awards them, and from the week of Oct 6 Orin Straylight trades one more a week for gold, Voidlight Marl or Veteran crests. A roll is accepted after a Bountiful Delve at any tier; Tier 8+ is only where end-of-run loot reaches the maximum pool, which is what makes spending one there worth it. (Also in 1.11.2.)
- **Ascendant Venomstones upgrade weapons, trinkets and necks only.** The Voidforge upgrade priority is now those five slots, and the comparison against armour is gone.
- **Packaging:** the LICENSE ships with the addon, and the library folder's casing matches disk, so a build cannot lose its libraries on a case-sensitive builder.

### Changed
- **Community rankings** are the 2026-10-01 pass -- 115 submissions across 42 graded variants -- the same data 1.11.2 carries. Twelve contributors from the September and October form exports are credited in Settings.
- **One grade palette everywhere**, in the tier-list convention players already know -- S salmon through F green. The Delves tab, Curios, the HUD, the compact widget and Settings all agree; S no longer reads like a D or an F on one screen and not another.
- **The Debug tab is hidden by default.** Tick *Show Debug tab* in Settings to bring it back. The debug slash commands always run, so following a bug-report instruction never needs the tab.
- **Season 1 Nemesis rewards are marked as no longer obtainable**, and both Nemesis entrance coordinates were re-read in game.
- **The Future tab looks ahead again.** Its pre-launch Labyrinth notes are gone -- they were written before the PTR, some had since been contradicted, and the Labyrinth tab covers what is known. In their place: what Blizzard announced at BlizzCon for Eclipse (Patch 12.2) and Season 3 -- a new Nemesis, Astalor Bloodsworn, more delve variations, and a higher level cap and new curios for Valeera.

### Localization
- **Every string a player sees now goes through a translation table**, so DelveGuide can be translated without a code change: copy `Locales/TEMPLATE.lua`, translate the right-hand side of each line, add the file to the TOC and open a pull request. About 720 phrases are in the template.
- **There are no translations yet** -- every phrase falls back to its English text, so nothing changes for English players. Delve and variant names were already localized separately in the data file and are unaffected.
- **First Russian (ruRU) variant names: 12**, one for each delve, taking `localeVariants` from 187 keys to 199. They came from the `MISSING` section of one player's `/dg submit` report, and each is a direct translation of a variant of the delve it was reported on. The other 32 arrive the same way: a Russian client that runs `/dg submit` sends every name the addon could not identify.
- CurseForge's translation platform is not available to this project, which is why translations are repository files contributed by pull request.

### Under the hood
- **Tab rendering no longer leaks frames.** Every tab now draws from reusable widget pools instead of building and orphaning a fresh frame tree each time, which is what made frames-per-second drift down as you switched tabs and resized the window over a session. 65 per-render creation sites became zero.
- **A broken tab can no longer take the window down with it.** Each tab render is contained; a failure paints one row saying so, and is still reported to your error display.
- **Saved data has a version number and numbered migrations**, so one-off cleanups run once rather than on every login.
- **The slash commands are one table and `/dg help` is generated from it**, so a command cannot exist undocumented or stay documented after it is removed.
- **Every release now has to pass a Lua 5.1 parse and lint check** before it can be built.
- **Nothing reads the objective tracker's text any more.** The last scrape of it (a tier fallback walked once a second) is gone; the header widget is confirmed at Tiers 8 and 9 and in a Tier 11 Labyrinth.
- **Current APIs instead of Blizzard's deprecation shims** for the spec, chat and system-message calls (`C_SpecializationInfo`, `C_ChatInfo`, `ChatFrameUtil`), so the addon does not depend on the shims staying loaded.
