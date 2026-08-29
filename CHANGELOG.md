# Changelog

## [1.10.1] - 2026-08-29

### Fixed
- **The Delves tab's Weekly Items row tracked a retired item.** The ID `253342` (Season 1's *Beacon of Hope*) was hardcoded in `DelveGuide_UI_Delves.lua`, so once 12.1 replaced it the row counted something nobody could obtain and read `None` for every player. Now `275910` (*Scalebound Herald's Flute*), and **the ID lives in `DelveGuideData.nemesisItem`** -- the same centralisation the trove IDs got, for the same reason: this is the second time Blizzard has swapped it between seasons.
- **The pre-entry checklist never appeared on non-English clients.** It matched `UnitName("target")` -- localized -- against English delve names. Now resolves through `localizedToEnglish` first. Same bug family as the run-logging and Nemesis-detection failures fixed in 1.9.0.
- **Nemesis tab, Season 1 section carried three wrong facts** about Beacon of Hope: it called the item a "Skip" (it summons), placed the vendor at "Delver's HQ" (Silvermoon City), and described a "burn to 50%" effect that appears in no tooltip and has no traceable source. Corrected, and noted as the same item as Season 2's flute one season earlier.

### Added
- **Flute reminder on the pre-entry checklist.** Requested by a submitter who kept forgetting to use it at the summoning stone. Shows when you are carrying one, and leans on the trove state the addon already tracks -- if this week's Trovehunter's Bounty is unclaimed the tip says so, since that is when using it actually matters.
  - A first cut gated this on targeting a Nemesis delve. That was backwards: research showed the flute is used in **any** delve to summon the Nemesis *to you*, so gating it there would have hidden the reminder everywhere it is useful.
- **Nemesis tab: "Summon Him Anywhere" section** with the verbatim tooltip, the 1-hour cooldown, the guaranteed Trovehunter's Bounty map, and all three sources (Mislaid Curiosities, 5,000 Undercoin from Naleidea Rivergleam in Silvermoon City, weekly *A Nightmarish Task* prey quest).
- `DelveGuideData.nemesisDelves` -- single source of truth for Nemesis delve names, read by both the scanner and the checklist. It was previously a local list in `DelveGuide.lua`, so the checklist had no idea those delves existed and never fired at them.

## [1.10.0] - 2026-08-29

### Added
- **Community block on the History tab**, between *Your Fastest Variants* and the weekly vault summary. Shows contributor count, total timed runs, variants ranked, the most-run and fastest/slowest variants, and the fastest-to-slowest spread -- the last of which is the single number that says what the rankings are worth (currently **10m 17s** a run).
- **You vs the Community** -- your average against the community median, per variant.
  - Both sides use the **Tier 8+ filter**. The first cut compared `GetVariantRunStats` (every tier) against a T8+ median, which on real data produced *"Totem Annihilation, 71% faster"* where every run had been Tier 2. It would have told every player they were a speedrunner. Variants with no T8+ runs of yours are omitted rather than compared dishonestly.
  - Run counts are shown per row, so a one-run comparison reads as one run.

### Changed
- `DelveGuideData.delves` entries carry `medianSec` and `players` as real fields rather than trailing comments -- that is what makes any client-side comparison possible.
- `rankingStats` gains `runs`, `mostRun`, `mostRunRuns`, `fastest`, `fastestSec`, `slowest`, `slowestSec`. Regenerate these with the rankings or the tab will contradict the table.

### Known issue (pre-existing, not introduced here)
- **`NewContentFrame` leaks a frame on every render.** WoW frames cannot be destroyed; `Hide()` + `SetParent(nil)` orphans them for the session, and `CreateRow` allocates a fresh FontString per row. There are 26 re-render call sites, and window resize triggers one on mouse-up -- which is why FPS degrades as you resize repeatedly. This also rules out any live-filtering UI until it is fixed: a filter that re-renders per keystroke leaks a frame and ~70 font strings per character. Fixing it needs frame/font-string pooling in `NewContentFrame`, `CreateRow` and `CreateHeader`.

## [1.9.3] - 2026-08-28

### Fixed
- **The Bountiful coffer blurb was still being filed as a missing translation.** 1.9.1 added a picker that takes the last single-line widget text, but kept `safeText or widgetTexts[1]` as a fallback -- so when the widget carried *only* the blurb, it fell straight back to it. The purge deleted the junk at login and the next scan put it back; the two fought each other and the table refilled indefinitely. Now a record is written **only** when a variant-looking line (single-line, ≤120 chars) is actually found. A blurb is not a missing translation, and recording nothing beats recording noise.

### Localization
- **Zero canonical variants are now without a locale mapping** (was 5). 14 deDE mappings added -- the first batch harvested automatically from `/dg submit`'s MISSING section rather than a hand-filed report, which only became possible once 1.9.1 made that section transmit at all.
- The five that had no mapping in **any** language are all covered: *Adopt-a-thon*, *An Elementary Antidote*, *Caustic Crush*, *Eggsplosive Growth*, *Speaking Their Language*.
- Collision-checked against all 214 keys: no new substring collisions.

### Rankings
- Refreshed from **87 submissions** (105 responses, 15 resubmissions dropped) covering **36 variants**, up from 33. **12 grades moved** -- down from 23 last release, which is the median anchor doing its job.
- Newly graded: *Eggsplosive Growth* (A), *Adopt-a-thon* (B), *Speaking Their Language* (D). **Both Coiled Isle delves are now fully ranked.**
- Contributor credits 45 → 48. Jemhadar submitted under three spellings (`/handle Jemhadar`, `/handle jemhadar-Saurfang-EU`, `Jemhadar-SaurfangEU`) and is credited once.

### Notes
- **4 of the 5 thin grades flagged in 1.9.2 moved**, as predicted -- Caustic Crush, Dastardly Rotstalk, Traitor's Due and March of the Arcane Brigade. *Calamitous* also swung B→D. Measured cause is **sample size, not spread**: the swinging variants sit at 7-11 players while stable ones like *Ogre Powered* (26) and *Invasive Glow* (25) hold, and their time ranges are comparable (~20-30 min either way). A higher player floor would not have prevented these -- all had ≥6 players. Worth considering a confidence marker for thinly-sampled grades rather than raising the floor further.

## [1.9.2] - 2026-08-26

### Rankings
- Refreshed from **80 submissions** (94 responses, 11 resubmissions dropped) covering **33 variants**, up from 30. **23 grades moved** -- 17 up, 3 down, 3 newly graded.
- Cumulative across two data pulls since v1.9.0 shipped its rankings, not one week's drift. Decomposed: the anchor change alone accounts for **2** of the 23; data 84 → 94 accounts for 4 under the new anchor (6 under the old).
- Best-sampled movers are the trustworthy ones: *Ogre Powered* C→B (62 runs / 23 players), *Academy Under Siege* B→A (34r/18p), *Faculty of Fear* D→B (31r/14p). **The Darkway moved three variants up at once**, all well-sampled -- a delve-wide shift rather than noise.
- Downgrades are all well-sampled: *Mirror Shine* B→C (19r/16p), *Stolen Mana* B→C (10r/9p), *Totem Annihilation* B→C (7r/6p).
- Newly graded: *March of the Arcane Brigade* (B), *An Elementary Antidote* (D), *Minchi's Osseous Adventure* (F). **Gnarldor Isle has a ranked variant again** -- it had shown 0/3 since the player floor went to 4, which was the flagged cost of that change.
- **Five sit at or near the 4-player floor** and are the most likely to move next pull: Caustic Crush (6p), Lightbloom Invasion (4p), Dastardly Rotstalk (6p), Traitor's Due (6p), March of the Arcane Brigade (4p).
- Contributor credits 36 → 45. Two submissions arrived as `/handle Jemhadar` and `/handle jemhadar-Saurfang-EU` -- same person, having typed the field label along with the value; credited once as *Jemhadar*. `screen_handles.py` gained a rule for command- and label-prefixed handles, which it had missed at 16 characters.

### Changed
- **Grades now anchor to the median variant rather than the fastest** (shipped as tooling in 1.9.1, first applied here). See `tools/RANKING.md`.

## [1.9.1] - 2026-08-24

### Fixed
- **10 more esMX variant mappings** ([#5](https://github.com/Thunderz96/DelveGuide/issues/5), Kajunnas, dumped on v1.9.0). Six are esMX wording that differs from esES -- *Asedio a la academia* (Academy Under Siege), *Tecnicatura en líneas ley* (Leyline Technician), *Loa liberado* (Loosed Loa), *Marcha de la Brigada Arcana*, *No era lo que esperaba* (Not What I Expected), *Fauna capturada* (Capture Wildlife). Four had no Spanish mapping at all: *Infiltrar y aliviar*, *Fármaco fúngico*, *Antigüedades varias*, *Día de partido*.
- Canonical variants with no locale mapping: **9 → 5** (Adopt-a-thon, An Elementary Antidote, Caustic Crush, Eggsplosive Growth, Speaking Their Language).
- Two entries in the same dump (*Aniquilación de tótems*, *Especial de esporasaurio*) already resolved and were not re-added. Collision-checked against all 200 keys before merging: no new substring collisions.

### Fixed
- **`/dg submit` could produce a code far too large to paste.** `missingTranslations` is keyed by the recorded text, and before v1.9.0 that text was `widgetTexts[1]` -- on a Bountiful delve, the multi-line coffer blurb, which embeds a live countdown ("Tiempo restante: 9 h 17 min") and a shard count. Both change constantly, so **every scan minted a new key** and the table grew without bound. One reporter's code came out **116,701 characters** over what the form accepts. Three fixes: the load-time purge now drops any entry that is multi-line or over 80 characters (a real variant line is neither, so blurb junk could never match a variant name and be cleared by the existing rules); a hard cap of 40 entries regardless of cause; and the built code is capped at 8000 characters, trimming MISSING entries first since run data is the point of the submission.
- **The MISSING section was only ever attached when the player had no runs at all.** `BuildSubmissionCode` returned `"DG1;" .. parts` whenever there was run data, silently discarding unidentified variants for every real submitter -- which is why not one of 66 submissions carried a MISSING entry despite the feature shipping in 1.8.4. Now always attached, within the length budget.
  - These two compound: a non-English player had no runs (the v1.9.0 bug), so their code was the `DG1;|MISSING;` branch -- i.e. pure accumulated blurb garbage and nothing else.

### Added
- **ESC now closes the main window and the changelog window.** `UISpecialFrames` had never been wired up, so neither responded to ESC -- a convention essentially every WoW addon follows. Requested by a submitter. Both frames already carried global names, which is what `UISpecialFrames` needs.
- **Copy Form Link button** on the `/dg submit` window. The URL was plain dialog text with no way to get it out of the game short of retyping it. Requested by a submitter.
- `tools/screen_handles.py` -- screens contributor handles before they ship. They are free text from a public form written verbatim into a Lua string literal, so the risk is not only taste: a `"` or `\` breaks the file for every user, and `|cFFFF0000` lets a submitter colour or hide text on the Settings tab. Flags Lua-breaking characters, WoW markup, control/invisible characters, URLs, over-long handles, impersonation (Blizzard/GM/author/addon) and profanity/slurs, matched against a leetspeak- and spacing-normalised form so `ButtH0le` and `B U T T H O L E` both trip. It flags rather than decides. All 36 shipping handles screened clean.

### Changed (tooling only -- no shipped grades yet)
- **Grades now anchor to the median variant, not the fastest.** A ratio to the single fastest variant made the whole table hostage to one sample. Across two consecutive pulls (73 → 84 responses) the fastest moved **51s** while the median moved **17s**, and 15 variants gained a grade purely because the yardstick got longer. Re-anchoring gives an **identical grade distribution** (S:4 A:6 B:12 C:8 D:2 F:1 either way) with **half the churn** -- 18 → 9 changes across those same two pulls. Bands recalibrated to 0.82/0.93/1.08/1.19/1.37× the median. Aggregator-only; the rankings refresh itself is deliberately held back so it lands once, against a dataset that includes the non-English players v1.9.0 unblocked.

### Confirmed
- **v1.9.0's run-logging fix verified on esMX by the reporter** -- history now saves correctly on non-English clients.

## [1.9.0] - 2026-08-23

All four reported from the esMX client by Kajunnas ([#5](https://github.com/Thunderz96/DelveGuide/issues/5), [#6](https://github.com/Thunderz96/DelveGuide/issues/6), [#7](https://github.com/Thunderz96/DelveGuide/issues/7)). Three of the four are English-only logic that was never extended to the localized path.

### Fixed
- **Non-English clients never logged a single delve run.** `SCENARIO_COMPLETED` decided "was that a delve?" with `scenarioName == "Delves"` plus a match against English delve names. `C_Scenario.GetInfo()` returns a **localized** string, so both tests failed on any non-English client and the handler returned before reaching the one write to `DelveGuideDB.history`. **Confirmed in game on esMX (2026-08-23):** the run timer ran, the HUD showed delve/variant/tier/bountiful correctly, and the completed run was still never saved.
  - Consequence: non-English players had no history and could never `/dg submit`, so **every ranking shipped to date was built on English clients only**. The bug also hides its own victims — with nothing logged they cannot appear in the response data at all, which is why 66 submissions contained zero non-English locales.
  - Root cause captured from a live `/dg export` on esMX inside Gnarldor Isle: `C_Scenario.GetInfo()` returned `{ "Abismos", 2, 4, 18, false, false, false, 0, 0, 8, "UNKNOWN", nil, 3414 }`. The name is **"Abismos"**, not "Delves".
  - That same snapshot exposed `scenarioType == 8` (10th return) — a plain number, identical in every language — which is now the primary test and works on a fresh install's first delve with nothing learned. The gate then runs four more, only the last language-bound: the zone resolving to a catalogued delve via `localizedToEnglish`, a run timer already being started, the localized scenario name learned from a previous confirmed delve, and finally the original English check. On any confirmed delve the client's own word for "Delves" is learned into SavedVariables, so uncatalogued and Nemesis delves log too — no translation table, and it works in locales nobody has tested.
  - `IsInDelveScenario` in the HUD carried the same English-only fallback and is fixed the same way, so timing now covers Nemesis and uncatalogued delves on every locale.
- **The Season 2 Nemesis delve leaked into the rotational delve list on non-English clients.** `NEMESIS_DELVES` is keyed by English name and was checked against the localized `delveName` and an `engZoneName` that also stays localized (Nemesis delves have no `widgetSetDelves` entry, since their widget set is 0). On esMX, Venomfall Deeps ("Sima del Tósigo") failed both and appeared as a 13th delve with "Unknown Variant Text". Now detected by `widgetSetID == 0` plus empty widget text, and the check was moved **above** the `activeDelves` insertion so it actually suppresses the row -- sitting below it, the first attempt only stopped the missing-translation record and the delve still rendered, as "New variant" instead of "Unknown Variant Text" (which looked fixed but was not). Both the Delves tab and the compact widget fall back to iterating `activeDelves`, so anything in there is drawn as a delve of the day — the locale-independent signature both Nemesis delves share, and one that will cover future ones without a name. English clients only escaped by luck, `delveName` already being English there.
- **Bountiful delves poisoned the missing-translation reports.** On a Bountiful delve the widget prepends a multi-line coffer blurb, so `widgetTexts[1]` is the blurb and the variant is `widgetTexts[2]`. The recorder took `[1]`, filing "Este abismo contiene un cofre..." as the missing translation. Now takes the last single-line entry, correct in both layouts.
- **The widget never opened the world map.** Both the widget and the Delves tab advertise *"Click to open map & set waypoint"*, but `SetDelveWaypoint` only ever set a waypoint — nothing in the addon opened the map except `/dg map`. The tooltip had been wrong for every user on every locale since it was written. It now opens the map and focuses the delve's zone. ([#6](https://github.com/Thunderz96/DelveGuide/issues/6))
- **Repeated clicks on the same delve did nothing.** `TomTom:AddWaypoint` de-duplicates: called on coordinates that already hold a waypoint it returns the existing one *without* re-announcing it or re-pointing the arrow. Our chat line printed, TomTom stayed silent, and the click looked dead. We now track the UID we set, remove it first, and pass `crazy = true` so the arrow re-points every time. ([#6](https://github.com/Thunderz96/DelveGuide/issues/6))
- **Widget `[B]` filter reported "No bountiful delves today" when bountiful delves were active.** Not a bountiful-detection problem — `atlasName:find("bountiful")` is locale-independent and works. The widget only iterated `DelveGuideData.delves` gated on `activeVariants[d.variant]`, so a delve whose **variant** could not be matched never entered the loop at all, taking its bountiful flag with it. The Delves tab has had a delve-level fallback for exactly this since 1.8.1; the widget never got it, which is precisely why the reporter saw the Delves tab working while the widget did not. Now added. Affects any client with an uncatalogued variant, not only non-English ones — esMX just hits it constantly with 9 variants still unmapped. ([#7](https://github.com/Thunderz96/DelveGuide/issues/7))
- **Stale "missing translation" records were never purged on non-English clients.** The `ADDON_LOADED` purge cleared a record only when its stored text contained a known **English** variant name — but a missing translation is by definition *not* English, so localized records could never match and survived forever, keeping variants listed long after they were mapped. Reported on esMX ([#5](https://github.com/Thunderz96/DelveGuide/issues/5)): *Destello invasor* and *Potenciamiento ogro* resolved correctly on v1.8.8 while still being listed as untranslated. Verified by replaying both strings through the shipped v1.8.8 tables — each resolves to the correct variant, so this was the *reporting* being wrong, not the detection. Affected records clear on next login with no user action.
- **Retired Season 1 curio advice was still shipping.** All six curios referenced by `specCurioRecs` — *Mandate of Sacred Death*, *Porcelain Blade Tip*, *Sanctum's Edict*, *Ebon Crown of Subjugation*, *Mantle of Stars*, *Time Lost Edict* — were removed in 12.1, and all 27 spec entries referenced at least one. The 12.1 curio rework changed the UI to render only `rec.companion` but left the data in place, so the stale names still leaked through the Delves tab's `[Nemesis]` tooltip ("Swap Mandate of Sacred Death") and `/dg specinfo`. `combat`/`utility`/`notes` stripped from all 40 entries; the table is now just the Valeera companion pick, which is the only field the UI reads and is still correct. Per-spec curio picks stay out until the Season 2 meta settles — the S2 curios are all ranked `?` for that reason.
  - This also removes a latent error: with those fields gone, `/dg specinfo` would have thrown, since `string.format("%s", nil)` errors in WoW's Lua.
- **Voidforge "Equipped average" disagreed with the character sheet.** It averaged the filled slots (total / 15), but `GetAverageItemLevel()` counts a two-hander twice -- once into the empty off-hand -- and divides by 16. On a Marksmanship Hunter with a 321 bow that showed **300** against the sheet's **301.69**, which reads as a bug rather than a different metric. Now uses Blizzard's own equipped value, with the slot average kept as a fallback.
- **Voidforge item-level colouring was dead.** `ColorIlvl` banded at 680/700/720 — The War Within numbers — while Midnight Season 2 runs 266-305, so every value fell through to the white fallback. Bands now derive from `DelveGuideData.tierRewards` (T4 / T8 / T11 vault) so they rescale with the season instead of going stale again.
- **Delves tab fallback showed "New variant" instead of the real variant name on non-English clients.** `rawScanResults` is keyed by the localized delve name while `activeDelves` is keyed by the English one, so the lookup always missed. Both call sites now map across via `localizedToEnglish`.

## [1.8.8] - 2026-08-22

### Changed
- **Grades now use the median clear time, not the mean.** Clear time has a hard floor but no ceiling -- an AFK, a wipe chain or a disconnect produces a 45m+ "run" that no amount of good data cancels out. *Academy Under Siege* was the clearest casualty: eight of ten players clear it in 8-15 minutes, but a single submitter at **49m09s x2** pulled the mean to 20m13s and would have shipped it as **F**. **18 of 33 variants changed grade depending purely on the statistic used.**
  - Dropping outliers instead was tested at 1.5x/2x/2.5x/3x median and by IQR fence, and is *worse*: **20 of 33 variants changed grade depending only on where the cutoff sat**, and trimming at 1.5x promoted *Calamitous* -- the slowest variant in the game -- to **S**. It also cannot work in principle, since `/dg submit` transmits each player's own average, so trimming never sees the bad run inside someone's 4-run average.
- **One vote per player, not per run.** Run-weighting let one player with 14 runs outvote 14 players with one run each -- and those 14 runs are not independent samples (same character, gear, route), so they carry far less information than the count implies. Measured before the change: *Invasive Glow* had 15 players and 41 runs, but one player held 14 of them and their average **was** the grade. `--weight runs` restores the old behaviour.
- **Minimum raised from 3 players to 4.** This caps any single player at 25% of a grade, and removes thin-sample grades: at 3 players *Olds and Ends* was scoring **S** -- the best variant in the game -- on three people's word.
- **Variants below the floor now read `?` instead of keeping a stale estimate.** A gap invites data; a wrong grade quietly misleads. *Olds and Ends*, *Shadowy Supplies* and *March of the Arcane Brigade* revert to `?`.

### Rankings
- Refreshed from **66 submissions** (73 responses, 6 resubmissions dropped, 1 blank) covering **30 variants**.
- vs live v1.8.7: **23 of 44 entries unchanged**, 13 improved, 3 dropped, 2 newly graded (*Game Day* B, *Caustic Crush* F), 3 lost their grade. Ten moves of one grade, five of two.
- The skew toward improvement is the outlier problem unwinding -- under the mean, slow outliers only ever pushed grades down.
- The "fastest in the game" reference moved from *Olds and Ends* (3 players) to **The Gravitational Effect** (7 players, 10m52s). Every grade is a ratio to that reference, so it now rests on firmer ground.
- Contributor credits updated to 36.

### Fixed
- **Variant matching now prefers the longest match, in both the English and localized paths.** Some localized names contain another as a substring: esMX *"Bombardeo basilisco"* (**Basalisk Blitz**, Shadowguard Point) contains esES *"Bombardeo"* (**Bombing Run**, Parhelion Plaza). Both loops previously took first/last match over `pairs()`, whose order Lua does not define — so the collision resolved to the wrong variant **non-deterministically**, silently logging bad runs that then fed the community rankings. A superstring always has more bytes than its substring, so comparing name length is exact. Reported via [#5](https://github.com/Thunderz96/DelveGuide/issues/5).
- **10 esMX variant mappings added** (GitHub [#5](https://github.com/Thunderz96/DelveGuide/issues/5), thanks Kajunnas). esMX wording differs from esES for five existing variants (*Destello invasor*, *Potenciamiento ogro*, *Brillo espejado*, *Última defensa*, *Invasión de floraluz*), and five Season 2 variants had no Spanish mapping at all (*Why Did it Have to Be Snakes?*, *Venomous Vapors*, *Basalisk Blitz*, *Minchi's Osseous Adventure*, *Open Night*). Canonical variants with no locale mapping: 14 → 9.

### Added
- `tools/RANKING.md` -- the full ranking spec. It is the authority; the data-file header is a summary.
- Aggregator gained `--stat median|mean` and `--weight players|runs` to reproduce any prior method.

### Notes
- 14 variants remain ungraded. **Gnarldor Isle has none of its three graded** -- that is the biggest gap.
- This is the last data pass carrying the pre-v1.8.7 tier bug, which discarded 34% of submitted runs as tier 0. Coverage should improve markedly next pass.

## [1.8.7] - 2026-08-22

### Fixed
- **Runs were being logged with no elapsed time.** Both the main addon and the HUD hooked `SCENARIO_COMPLETED`, and the HUD cleared `runStartTime` without ever using it -- so whenever it won the (unordered) race, the completion handler found no start time and saved the run without a duration. The timer had run correctly the whole way; the value was destroyed a moment before it was read. Affected players could not submit anything via `/dg submit`. **Found and diagnosed by Zaph0n.**
- **Delve tier was not detected when the in-run HUD was disabled.** Tier detection sat behind the `hudEnabled` early-return, so switching the overlay off meant runs logged without a tier -- and tier-0 runs are filtered out of the community rankings entirely. Detection now runs before the display gate.

### Added
- The addon version is shown in the main window title and at the top of `/dg help`.

## [1.8.6] - 2026-08-21

### Rankings
- Updated from **60 player submissions** -- 7 variants shifted a grade. **Gnarldor Isle / Olds and Ends** takes the first Season 2 ranking (**A**), now that Season 2 runs are reporting real tiers.
- A variant now requires times from at least **three different players** before it is graded -- previously a single player with enough runs could set a ranking alone. Repeat submissions from the same player are also no longer double-counted.
- Contributor credits updated to 31.
- **Still unranked:** the two Coiled Isle delves and the Season 2 venom variants (13 in total). Tier 8+ clears of those are what `/dg submit` needs to grade them.

## [1.8.5] - 2026-08-19

### Rankings
- Updated from **54 player submissions** -- 10 variants shifted a grade. Contributor credits updated to 27.

### Added
- `/dg resethud` -- recentres the in-run HUD, matching the existing `/dg resetwidget`.

## [1.8.4] - 2026-08-18

### Rankings
- Refreshed from **47 player submissions** -- 9 variants changed grade. *The Gravitational Effect* (Sunkiller Sanctum) is the fastest measured variant at ~10m38s. `[Best]` flags now mark each delve's fastest well-tested variant.
- Two new Coiled Isle variants added: **Adopt-a-thon** and **Minchi's Osseous Adventure**.

### Fixed
- **Great Vault item levels** now show what you'll actually receive, on both the Delves tab and the Roster.
- **History is tracked per character** -- your alts no longer pool into one shared vault count. Slots correctly unlock at 2/4/8 delves.
- **Curio and poison descriptions corrected.** Several were wrong -- notably *Corrosive Bilespear* (a damage proc, not the below-50% curse) and *Poison of the Forgotten Master*, which loses all its stacks when you take damage.
- **Delve tier detection** no longer shows the previous run's tier, and the in-run HUD and timer start reliably.
- **Trovehunter's Bounty** shows its real state on the pre-entry checklist again.
- The compact widget fits all 12 delves, and Bountiful runs are tagged in History.
- Fixes for non-English clients, including a variant that never displayed on Spanish clients.

### Added
- `/dg submit` now also reports variants your client doesn't recognise -- that's how new and non-English variants get discovered. Thank you to everyone contributing; your handles are on the Settings tab.

## [1.8.3] - 2026-08-17

### Changed
- **Delve rankings are now community-timed.** The first data pass from `/dg submit` is in: **36 submissions** covering **28 variants**, ranked by average Tier 8+ clear time instead of hand-estimation. Several rankings moved a long way -- highlights:
  - **The Gravitational Effect** (Sunkiller Sanctum) is the fastest variant measured overall at ~11:09 -- was rated C.
  - **Bombing Run** (Parhelion Plaza) C -> A, **Trapped!** and **Loosed Loa** (Twilight Crypts) both -> A, **Ritual Interrupted** (Atal'Aman) -> A. All four were previously rated D/F.
  - **Ogre Powered** (The Darkway) S -> B and **Sporasaur Special** (Gulf of Memory) A -> D -- the old speed-meta picks didn't hold up against the stopwatch.
  - **Calamitous** (Shadowguard Point) C -> F at ~31:49, the slowest measured variant.
- **`[Best]` flags rebuilt from the data** -- each delve now flags its fastest variant where the sample is solid (7+ runs), instead of the previous hand-picked routes.
- Variants with no submitted times keep their old estimate and are marked as such in the data file. The two new Coiled Isle delves stay `[?]` until Season 2 runs come in.

### Added
- **Contributor credits in-game:** the Settings tab now has a **Community Rankings** section showing the submission stats, a **Contribute Your Times** button, and the handles of every player whose data built the current rankings.
- The Delves tab notes that rankings are community-sourced and points to `/dg submit`.

## [1.8.2] - 2026-08-16

### Added
- **Community variant rankings -- help rank the delves!** DelveGuide already times your runs; now you can pool that data into crowd-sourced variant rankings:
  - **`/dg submit`** (alias `/dg rank`) -- copies a compact code of your per-variant clear times, pre-selected and ready to paste into the submission form.
  - **"Your Fastest Variants"** panel on the History tab -- your average clear time per variant, fastest first (this is exactly the data `/dg submit` shares).
  - A one-time **"Call to Arms"** popup on login invites players to contribute. Shows once, and respects the "show changelog popup" setting.

## [1.8.1] - 2026-08-16

### Added
- **Season 2 curio set:** replaced the retired Season 1 curios with the confirmed S2 set -- Corrosive Bilespear, Ouroboric Curse, Essence Trap (Combat) and Soul-Cracking Dreamcatcher, Dundun's Favor, Venom Infusion (Utility), each with its effect. Ranked `[?]` until the meta settles; the Companion tab's live scan recognises them when equipped.
- **Poisons reference** (Curios + Companion tabs) -- patch 12.1 made poison its own choice node, independent of role. Lists all six poisons (3 base + 3 quest-unlocked) with effects and a rule-of-thumb pick, since no source crowns a "best" one yet.
- **Delver's Journey reference:** the Quests tab is now the **Journey** tab -- it leads with the full Season 2 Delver's Journey rank unlocks (ranks 1-10, what each grants) above the existing Delver's Call quest tracker. Open with `/dg journey` (or `/dg quests`).

### Fixed
- **New delves now show in "Active Today":** The Coiled Isle delves (The Ring of Glory, Gnarldor Isle) and the new venom variants on existing delves are now registered, so they appear in the Delves tab and compact widget instead of being silently dropped. Rankings show as `[?]` until routes are speed-tested.
- **Delves tab no longer drops uncatalogued variants:** any delve the scanner flags active now surfaces even if its exact variant isn't in the data yet -- so daily rotations of not-yet-ranked Season 2 variants stay visible.
- **Delve reward item levels updated to Season 2:** end-of-run 266->295 (Tier 1->8+) and Great Vault 279->305 (Hero at Tier 8+); fixed two "?" tooltips still quoting the old 259.
- Corrected the Ring of Glory delve POI reference (8763 -> 8764) from live data.
- **Trovehunter's Bounty status fixed & expanded:** it was checking stale item/buff IDs and always read "None." Now uses the Season 2 item (274374) and buff (1293799), and adds a **"Done this week"** state via the *Purging the Vaults* weekly (quest 95520) -- so the row reads Active / In Bags / Done this week / None correctly.

### Changed
- **Season 2 currency rework:** Nebulous Voidcore is now tracked as the **bonus-roll** currency (ID 3418, replacing the Season 1 3513). The gear-upgrade material is now **Ascendant Venomstone** -- arriving later this season; 10 per upgrade, with a Tier 11 Bountiful Delve as a guaranteed source. The Voidforge tab, compact widget, Loot tab, and alt stockpile were reworked to match.
- **Curios tab reworked for Season 2:** dropped the per-spec Combat/Utility picks, the "General Loadout" presets, and the Nemesis warning -- all of which pointed at retired S1 curios. The tab now lists the live S2 curios + poisons and surfaces a strong general pick (Corrosive Bilespear). The Companion tab's loadout section was updated to match (shows equipped curios as info instead of comparing against gone S1 recs).
- **Future tab cleaned up:** removed stale entries (old Delver's Journey milestones, the past Parhelion Plaza release, pre-launch "not returning" notes) and refreshed the Labyrinths (12.1.5) section with confirmed details; added an Ascendant Venomstone heads-up.
- **Nemesis tab (Azta'rec) expanded** from the live guide: split into Main Phase / Intermissions, corrected mechanics (Void Toxin -40% damage; the Sermon -> Echo memory recall; ?? 5/6/7 safe-spot sequences; tank-only Serpent's Strike), and added the intro questline (Corrosive Victory toy) plus precise per-kill Mistcrest drops and per-achievement reward conditions.

### Removed
- Retired the Patch 12.0.5 upgrade loop (Elementary Voidcore Shards, the "Building the Voidforge" weekly quest, and Ascendant Voidcore), including its pre-entry checklist row.

## [1.8.0] - 2026-08-11

### Added
- **Patch 12.1 / Season 2 support:** Interface 120100, plus full integration of **The Coiled Isle** (uiMapID 2512, overview 2537) and its two new rotational delves:
  - **The Ring of Glory** (POI 8763, widgetSet 2047) -- map pin at 71.3, 56.5.
  - **Gnarldor Isle** (POI 8761, widgetSet 2044) -- map pin at 57.9, 78.6. First confirmed story variant: *Speaking Their Language*.
  - Both feed Active Today, the compact widget, variant detection, and map pins like any other delve.
- **Nemesis Tab** (replaces the Nullaeus tab): the tab slot is now seasonal -- the current season's Nemesis delve gets the full guide, the previous one drops to a compact legacy section.
  - **Venomfall Deeps** (Season 2 Nemesis, boss **Azta'rec**): location (The Serpent's Tail, `/way #2512 51.2 30.3`), unlock tiers, the six core abilities (including the *Sermon of Ula'tek* Simon-Says memory mechanic), companion advice, and the full reward list -- Apophic Soul Crusher (mount), Apophic Patagia (back), *Corrosive Victory* (toy), the *the Poisonous* title, and the time-limited *Fabled Vanquisher of Azta'rec*. Detected by instanceID 3079 (Nemesis delves have no world-map delve POI, and `C_DelvesUI.HasActiveLair()` reflects seasonal state -- it returns false even while standing inside a lair).
  - **Nullaeus legacy section:** Torment's Rise remains enterable in 12.1 (confirmed on PTR, instanceID 2966). Compact reference: location, unlock, Beacon of Hope skip, and which rewards are still obtainable vs. retired. The full Season 1 guide lives in git history (`DelveGuide_UI_Nullaeus.lua`, v1.7.x).
- **Season 2 story variants** on existing delves (all venom/serpent themed): Venomous Vapors (Atal'Aman), An Elementary Antidote (Collegiate Calamity), Caustic Crush (Parhelion Plaza), Basalisk Blitz (Shadowguard Point), Eggsplosive Growth (The Darkway), Fungal Pharmacon (The Grudge Pit), Infiltrate and Ameliorate (The Shadow Enclave), Why Did it Have to Be Snakes? (Twilight Crypts). Season 2 **adds** to the existing variant pools -- Season 1 variants and rankings remain valid and in rotation.
- **`/dg export`** -- snapshots zone/instance/scenario/map/delve-POI/quest state into SavedVariables (`DelveGuideDB.ptrExports`); attach it to bug reports. **`/dg exportclear`** wipes the snapshots.

### Changed
- Curios tab Nemesis warning updated for the Venomfall Deeps arena (profession-node availability).
- Debug aura dump (`/dg` valeera debug) is now safe against 12.1 secret aura values (`tostring` instead of `%d` formatting).

### Notes
- **Launch schedule:** patch 12.1 goes live **Aug 11**, but Season 2 proper starts **Aug 18**. The new delves, the Nemesis, and the venom variants are playable now; **Bountiful Delves, Coffer Keys, and the seasonal Great Vault unlock Aug 18** (higher Nemesis `??` difficulty too). During that first week the bountiful filter and pre-entry key checklist are intentionally quiet -- that's expected, not a bug.
- Nemesis mechanics/rewards are compiled from Season 2 launch guides and will be fine-tuned as routes are tested.
- Delver's Call quest IDs for the two new delves are gated behind the Season 2 flip and will land in a 1.8.x update, along with refined S-F rankings for the new delves/variants.

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
