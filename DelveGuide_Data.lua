-- ============================================================
-- DelveGuide_Data.lua
-- ============================================================
DelveGuideData = {}

-- ============================================================
-- SECTION 1: DELVE RANKINGS
-- ============================================================
DelveGuideData.delves = {
    -- ── Atal'Aman ─────────────────────────────────────────
    { name="Atal'Aman",             zone="Zul'Aman",    variant="Totem Annihilation",          ranking="C", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Atal'Aman",             zone="Zul'Aman",    variant="Toadly Unbecoming",            ranking="B", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Atal'Aman",             zone="Zul'Aman",    variant="Ritual Interrupted",           ranking="F", mountable=true,  hasBug=false, isBestRoute=false },
    -- ── Collegiate Calamity ───────────────────────────────
    { name="Collegiate Calamity",   zone="Quel'Thalas", variant="Faculty of Fear",              ranking="D", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Collegiate Calamity",   zone="Quel'Thalas", variant="Academy Under Siege",          ranking="D", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Collegiate Calamity",   zone="Quel'Thalas", variant="Invasive Glow",                ranking="B", mountable=true,  hasBug=false, isBestRoute=true  },
    -- ── Parhelion Plaza ───────────────────────────────────
    { name="Parhelion Plaza",       zone="Quel'Danas",  variant="Holding the Line",             ranking="B", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Parhelion Plaza",       zone="Quel'Danas",  variant="Bombing Run",                  ranking="F", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Parhelion Plaza",       zone="Quel'Danas",  variant="March of the Arcane Brigade",  ranking="F", mountable=true,  hasBug=false, isBestRoute=false },
    -- ── Shadowguard Point ─────────────────────────────────
    { name="Shadowguard Point",     zone="Voidstorm",   variant="Calamitous",                   ranking="C", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Shadowguard Point",     zone="Voidstorm",   variant="Capture Wildlife",             ranking="F", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Shadowguard Point",     zone="Voidstorm",   variant="Stolen Mana",                  ranking="D", mountable=true,  hasBug=false, isBestRoute=false },
    -- ── Sunkiller Sanctum ─────────────────────────────────
    { name="Sunkiller Sanctum",     zone="Voidstorm",   variant="Not What I Expected",          ranking="D", mountable=false, hasBug=false, isBestRoute=false },
    { name="Sunkiller Sanctum",     zone="Voidstorm",   variant="The Gravitational Effect",     ranking="C", mountable=false, hasBug=true,  isBestRoute=false },
    { name="Sunkiller Sanctum",     zone="Voidstorm",   variant="Core of the Problem",          ranking="B", mountable=false, hasBug=false, isBestRoute=false },
    -- ── The Darkway ───────────────────────────────────────
    { name="The Darkway",           zone="Quel'Thalas", variant="Focusers Under Pressure",      ranking="B", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Darkway",           zone="Quel'Thalas", variant="Leyline Technician",           ranking="F", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Darkway",           zone="Quel'Thalas", variant="Ogre Powered",                 ranking="S", mountable=false, hasBug=false, isBestRoute=true  },
    -- ── The Grudge Pit ────────────────────────────────────
    { name="The Grudge Pit",        zone="Harandar",    variant="Dastardly Rotstalk",           ranking="D", mountable=true,  hasBug=false, isBestRoute=false },
    { name="The Grudge Pit",        zone="Harandar",    variant="Lightbloom Invasion",          ranking="F", mountable=true,  hasBug=false, isBestRoute=false },
    { name="The Grudge Pit",        zone="Harandar",    variant="Arena Champion",               ranking="C", mountable=true,  hasBug=false, isBestRoute=false },
    -- ── The Gulf of Memory ────────────────────────────────
    { name="The Gulf of Memory",    zone="Harandar",    variant="Descent of the Haranir",       ranking="C", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Gulf of Memory",    zone="Harandar",    variant="Alnmoth Munchies",             ranking="B", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Gulf of Memory",    zone="Harandar",    variant="Sporasaur Special",            ranking="A", mountable=false, hasBug=true,  isBestRoute=true  },
    -- ── The Shadow Enclave ────────────────────────────────
    { name="The Shadow Enclave",    zone="Quel'Thalas", variant="Traitor's Due",                ranking="C", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Shadow Enclave",    zone="Quel'Thalas", variant="Shadowy Supplies",             ranking="F", mountable=false, hasBug=true,  isBestRoute=false },
    { name="The Shadow Enclave",    zone="Quel'Thalas", variant="Mirror Shine",                 ranking="D", mountable=false, hasBug=false, isBestRoute=false },
    -- Note: Torment's Rise (Voidstorm, mapID 2405) is the Nemesis delve for Nullaeus, not a rotational delve.
    -- ── Twilight Crypts ───────────────────────────────────
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Party Crasher",               ranking="B", mountable=false, hasBug=true,  isBestRoute=false },
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Trapped!",                    ranking="D", mountable=false, hasBug=true,  isBestRoute=false },
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Loosed Loa",                  ranking="F", mountable=false, hasBug=true,  isBestRoute=false },

    -- ============================================================
    -- SEASON 2 (12.1 "Curse of Ula'tek")
    -- Two new delves on The Coiled Isle plus venom/serpent variants
    -- added to the existing pools (S1 variants still rotate too).
    -- Variant names confirmed live via /dg export (Aug 2026). ranking="?"
    -- until routes are speed-tested -- "?" rows sort last, and the
    -- Delves-tab fallback still surfaces any active variant not listed
    -- here yet (e.g. Sunkiller Sanctum / The Gulf of Memory S2 variants,
    -- not seen active as of this build).
    -- (Venomfall Deeps is the S2 Nemesis delve -> Nemesis tab, not a row.)
    -- ── The Coiled Isle -- new delves ─────────────────────
    { name="The Ring of Glory",   zone="The Coiled Isle", variant="Game Day",                      ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Ring of Glory",   zone="The Coiled Isle", variant="Open Night",                    ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    { name="Gnarldor Isle",       zone="The Coiled Isle", variant="Speaking Their Language",       ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    { name="Gnarldor Isle",       zone="The Coiled Isle", variant="Olds and Ends",                 ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    -- ── S2 variants on existing delves ────────────────────
    { name="Atal'Aman",           zone="Zul'Aman",    variant="Venomous Vapors",               ranking="?", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Collegiate Calamity", zone="Quel'Thalas", variant="An Elementary Antidote",        ranking="?", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Parhelion Plaza",     zone="Quel'Danas",  variant="Caustic Crush",                 ranking="?", mountable=true,  hasBug=false, isBestRoute=false },
    { name="Shadowguard Point",   zone="Voidstorm",   variant="Basalisk Blitz",                ranking="?", mountable=true,  hasBug=false, isBestRoute=false },
    { name="The Darkway",         zone="Quel'Thalas", variant="Eggsplosive Growth",            ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    { name="The Grudge Pit",      zone="Harandar",    variant="Fungal Pharmacon",              ranking="?", mountable=true,  hasBug=false, isBestRoute=false },
    { name="The Shadow Enclave",  zone="Quel'Thalas", variant="Infiltrate and Ameliorate",     ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    { name="Twilight Crypts",     zone="Zul'Aman",    variant="Why Did it Have to Be Snakes?", ranking="?", mountable=false, hasBug=false, isBestRoute=false },
    -- Reference IDs -- Coiled Isle uiMapID 2512 / overview 2537 (live, build 69299).
    -- Ring of Glory: POI 8764, widgetSet 2047.  Gnarldor Isle: POI 8761, widgetSet 2044.
    -- Venomfall Deeps (S2 Nemesis): instanceID 3079 (PTR; verify inside) -- /way #2512 51.2 30.3.
    -- Torment's Rise (S1 Nemesis, legacy, still enterable): instanceID 2966 (PTR; verify inside).
    -- ============================================================
}


-- ============================================================
-- SECTION 1b: DELVER'S CALL QUESTS  --  "World Tour" alt-leveling chain
-- ------------------------------------------------------------
-- One Delver's Call quest per rotational delve. The intended workflow:
--   1. While leveling an alt, run each delve once to pick up the quest
--      (do NOT turn it in -- the XP scales with your level at turn-in).
--   2. Bank all 10 quests in your log.
--   3. Once you're a few levels short of cap, turn them in to power
--      through those last levels. Hitting cap before turn-in wastes the
--      XP, so don't hold them too long.
--
-- questID = nil means we haven't catalogued that quest yet. Run
-- /dg questscan with the quest in your log to print its ID, then
-- paste it here. The Quests tab works fine without IDs (manual
-- checkbox fallback), but auto-detection is much nicer once filled.
-- ============================================================
DelveGuideData.delversCall = {
    -- All 10 quest IDs catalogued from wowhead.com (April 2026).
    { delve = "Atal'Aman",           questID = 93409 },
    { delve = "Collegiate Calamity", questID = 93384 },
    { delve = "Parhelion Plaza",     questID = 93386 },
    { delve = "Shadowguard Point",   questID = 93428 },
    { delve = "Sunkiller Sanctum",   questID = 93427 },
    { delve = "The Darkway",         questID = 93385 },
    { delve = "The Grudge Pit",      questID = 93421 },
    { delve = "The Gulf of Memory",  questID = 93416 },
    { delve = "The Shadow Enclave",  questID = 93372 },
    { delve = "Twilight Crypts",     questID = 93410 },
    -- Season 2 (12.1): new delves likely add Delver's Call quests.
    -- NOT available on PTR build 68629 (2026-07-11) -- likely gated
    -- until Season 2 opens. RECHECK AT S2 LAUNCH (~Aug 2026) with
    -- /dg questscan, then uncomment:
    -- { delve = "The Ring of Glory",  questID = nil },
    -- { delve = "Gnarldor Isle",      questID = nil },
}


-- ============================================================
-- SECTION 1c: DELVER'S JOURNEY  --  Season 2 rank progression
-- ------------------------------------------------------------
-- The seasonal renown-style track that levels as you run delves; each
-- rank unlocks rewards / vendors / QoL. Static reference for now (the
-- player's current rank isn't detected). Ranks 1-10 confirmed for S2.
-- ============================================================
DelveGuideData.delversJourney = {
    { rank=1,  unlock="Curiosity boons & first decor", note="Temporary character buffs from Mislaid Curiosities and Heavy Trunks, plus the first housing decor purchase." },
    { rank=2,  unlock="Corrosive Reticule",            note="Unlocks the Corrosive Reticule purchase." },
    { rank=3,  unlock="Shrine of Abundance",           note="Bountiful Delves gain a chance to contain a Shrine of Abundance. The Effigy of Dundun toy becomes purchasable." },
    { rank=4,  unlock="Gilded Stashes appear",         note="Tier 11 Gilded Stashes begin carrying Hero and Myth Mistcrests -- the first rank that changes your upgrade-currency income rather than cosmetics." },
    { rank=5,  unlock="Zah'ran & first mount",         note="Extra Curiosity boons, the Zah'ran gear vendor at the end of Tier 6+ Delves, and the Corroded Soul Crusher purchase." },
    { rank=6,  unlock="Two Restored Coffer Keys",      note="Naleidea Rivergleam hands over two Restored Coffer Keys, plus decor and gravestone options." },
    { rank=7,  unlock="Delve teleports",               note="The Delve-O-Bot 7001 Midnight Software Update Chip adds Midnight Delves to the bot's teleport destinations." },
    { rank=8,  unlock="Champion Warbound gear",        note="Champion Warbound gear can appear in Tier 9+ Delves. The Ula'tek Ritual Stone decor unlocks." },
    { rank=9,  unlock="Hero gear currency",            note="Tier 11 Bountiful Coffers can provide Hero gear or Untainted Mana-Crystals, which Zah'ran accepts for Hero-track items." },
    { rank=10, unlock="Snake Eater",                   note="The Snake Eater title, and increased Coffer Key Shards from every source." },
}


-- ============================================================
-- SECTION 2: DELVE MAP PINS
-- ------------------------------------------------------------
-- mapID = WoW uiMapID for the zone
-- x, y  = 0.0–1.0 fractions (in-game /way coords divided by 100)
--
-- Zone mapIDs:
--   2393 = Silvermoon City     (Collegiate Calamity, The Darkway)
--   2437 = Zul'Aman            (Atal'Aman, Twilight Crypts)
--   2395 = Eversong Woods      (The Shadow Enclave)
--   2424 = Isle of Quel'Danas  (Parhelion Plaza)
--   2413 = Harandar            (The Grudge Pit, The Gulf of Memory)
--   2405 = Voidstorm           (Shadowguard Point, Sunkiller Sanctum)
--
-- Coordinates verified from in-game map data (March 2026).
-- ============================================================
DelveGuideData.mapPins = {
    -- ── Silvermoon City (2393) ────────────────────────────
    { name="Collegiate Calamity", mapID=2393, x=0.3989, y=0.5359 },  -- verified in-game
    { name="The Darkway",         mapID=2393, x=0.3930, y=0.3178 },  -- verified in-game

    -- ── Zul'Aman (2437) ───────────────────────────────────
    { name="Atal'Aman",           mapID=2437, x=0.2426, y=0.5288 },  -- verified in-game
    { name="Twilight Crypts",     mapID=2437, x=0.2592, y=0.8417 },  -- verified in-game

    -- ── Eversong Woods (2395) ─────────────────────────────
    { name="The Shadow Enclave",  mapID=2395, x=0.4549, y=0.8638 },  -- verified in-game

    -- ── Isle of Quel'Danas (2424) ─────────────────────────
    { name="Parhelion Plaza",     mapID=2424, x=0.4850, y=0.5200 },  -- coords still estimate; verify in-game

    -- ── Harandar (2413) ───────────────────────────────────
    { name="The Grudge Pit",      mapID=2413, x=0.7051, y=0.6535 },  -- verified in-game
    { name="The Gulf of Memory",  mapID=2413, x=0.3666, y=0.4953 },  -- verified in-game

    -- ── Voidstorm (2405) ──────────────────────────────────
    { name="Shadowguard Point",   mapID=2405, x=0.3705, y=0.4880 },  -- verified in-game
    { name="Sunkiller Sanctum",   mapID=2405, x=0.5524, y=0.4741 },  -- verified in-game

    -- ── The Coiled Isle (2512) -- 12.1 Season 2 ───────────
    { name="Gnarldor Isle",       mapID=2512, x=0.5787, y=0.7859 },  -- from /dg export at entrance (PTR build 68629); verify precise spot
    { name="The Ring of Glory",   mapID=2512, x=0.7126, y=0.5654 },  -- from /dg export at entrance (PTR build 68629); verify precise spot
    -- Venomfall Deeps (S2 Nemesis) entrance: The Serpent's Tail, /way #2512 51.2 30.3 --
    -- intentionally not pinned here (Nemesis delves aren't rotational; location lives in the Nemesis tab)
}


-- ============================================================
-- SECTION 3: CURIOS
-- ============================================================
-- Season 2 (12.1) curio set. Season 1's curios were retired at the season
-- flip. Confirmed via wowhead / in-game (Aug 2026). ranking "?" until the
-- meta settles; id = wowhead spell ID (reference only -- curios match by name).
DelveGuideData.curios = {
    -- ── Combat ──
    { name="Corrosive Bilespear",        id=1295761, description="At <50% HP: Horrify nearby enemies 6s; you gain +5% primary & +50% leech/avoid/speed for 20s (2 min cd). A strong, safe all-purpose pick.", curiotype="Combat",  ranking="?" },
    { name="Ouroboric Curse",            id=1248856, description="At <50% HP: Horrify nearby enemies 6s; you gain +20% primary & +50% leech/avoid/speed for 20s (2 min cd).",                                          curiotype="Combat",  ranking="?" },
    { name="Essence Trap",               id=1295975, description="In combat Valeera may drop a trap; enemies within 3 yds are slowed 20% (5s), then it detonates for moderate Nature damage and a 1s stun.",           curiotype="Combat",  ranking="?" },
    -- ── Utility ──
    { name="Soul-Cracking Dreamcatcher", id=1296121, description="When a party member interrupts or CCs an Elite, that enemy takes +10% damage for 30s, stacking up to 2.",                                            curiotype="Utility", ranking="?" },
    { name="Dundun's Favor",             id=1296018, description="In combat a Mislaid Spirit may appear; walking over a Mislaid Curiosity/Spirit fires 3 Volatile Sprites at random enemies. Curiosity contents auto-loot.", curiotype="Utility", ranking="?" },
    { name="Venom Infusion",             id=1305686, description="On entering combat the party is Poisoned: 1% current HP/min as Nature, but +1% move & +1% haste per 5% HP missing (reversed for the first 6s).",       curiotype="Utility", ranking="?" },
}

-- ============================================================
-- SECTION 3b: POISONS  (new 12.1 choice node -- independent of Valeera's role)
-- ------------------------------------------------------------
-- base=true are available from the start; base=false unlock via quests.
-- No source crowns a "best" one, so `use` is an effect-based hint, not a meta.
-- ============================================================
DelveGuideData.poisons = {
    { name="Bloodcrypt Toxin",               base=true,  effect="Enemies hit deal -10% damage & -10% Haste (20s).",                                  use="Survivability -- solo, progression, high tiers." },
    { name="Poison of the Forgotten Master", base=true,  effect="+5% damage, stacking every 3s up to 5.",                                            use="Speed-farming tiers you already clear." },
    { name="Soulthirst Venom",               base=true,  effect="+10% Leech / Avoidance / Speed.",                                                   use="Niche stat-stick." },
    { name="Frostheart Venom",               base=false, effect="Enemies hit: -30% movement and -20% melee/ranged/cast speed (10s).",               use="Strong control/defense vs melee & caster packs." },
    { name="Phantasmal Spore Toxin",         base=false, effect="Enemies hit are interrupted and feared for 1s.",                                    use="Interrupt-heavy or caster-dense pulls." },
    { name="Bursting Toad Toxin",            base=false, effect="Enemies hit occasionally burst: Nature damage every 1s for 8s to enemies within 8 yds.", use="Extra AoE for trash-heavy runs." },
}

-- ============================================================
-- SECTION 4: NOTABLE LOOT
-- ============================================================
DelveGuideData.loot = {
    { name="Withered Saptor's Paw",        id=251782, slot="Trinket", notes="Crits grant Agility / main stat" },
    { name="Desecrated Chalice",           id=251790, slot="Trinket", notes="Tank: on-damage versatility + damage" },
    { name="Ever-Collapsing Void Fissure", id=251786, slot="Trinket", notes="On-use ramping haste" },
    { name="Glorious Crusader's Keepsake", id=251792, slot="Trinket", notes="RNG incarnate idol" },
    { name="Holy Retributor's Order",      id=251791, slot="Trinket", notes="On-hit damage + heal" },
    { name="Lost Idol of the Hash'ey",     id=251783, slot="Trinket", notes="On-hit summons a companion" },
    { name="Sealed Chaos Urn",             id=251787, slot="Trinket", notes="On-use all-stat buff" },
    { name="Sylvan Wakrapuku",             id=251784, slot="Trinket", notes="On-hit physical proc" },
    { name="Void-Reaper's Libram",         id=251785, slot="Trinket", notes="Damage proc + crit buff" },
    { name="Ultradon Cuirass",             id=264694, slot="Trinket", notes="Tank on-use absorb" },
    { name="Gift of Light",                id=251788, slot="Trinket", notes="Healer: on-hit ally stat buff" },
    { name="Cosmic Bell",                  id=264701, slot="Trinket", notes="Healer on-use" },
    { name="Consecrated Chalice",          id=251789, slot="Trinket", notes="Healer on-use absorb" },
    { name="Lightgrasp Worldroot",         id=251935, slot="Weapon",  notes="Staff with a delve-only banish ability" },
    { name="Radiant Foil",                 id=251885, slot="Weapon",  notes="2-set 1h sword with on-hit proc" },
    { name="Abyss Sabre",                  id=251884, slot="Weapon",  notes="2-set 1h sword with on-hit proc" },
}


-- ============================================================
-- SECTION 5: FUTURE / PATCH NOTES
-- ============================================================
DelveGuideData.future = {
    -- ── Later in Season 2 (12.1) ────────────────────────────
    { category="Later in Season 2", note="Ascendant Venomstones arrive later this season -- the gear-upgrade material. 10 upgrade one weapon/trinket/neck; a Tier 11 Bountiful Delve is a guaranteed source." },
    -- ── Labyrinths (Patch 12.1.5 -- ~Autumn 2026) ───────────
    { category="Labyrinths (Patch 12.1.5)", note="Confirmed for 12.1.5 (~autumn 2026): a larger, mega-dungeon-inspired Delve variant -- pitched as the difficulty ceiling for players who skip raiding." },
    { category="Labyrinths (Patch 12.1.5)", note="Multi-boss, playable solo or in a small group, with progress saved between sessions (not a simple repeatable delve)." },
    { category="Labyrinths (Patch 12.1.5)", note="Different reward structure than Delves: Hero-track gear at mid-to-high difficulty, plus a separate currency track for housing & seasonal vendors." },
    { category="Labyrinths (Patch 12.1.5)", note="Exact difficulty tiers, lockouts, and Great Vault interaction are still on the PTR -- details may change." },
    -- ── Also in Patch 12.1.5 ────────────────────────────────
    { category="Also in 12.1.5", note="A new raid arrives alongside Labyrinths." },
}

-- ============================================================
-- ============================================================
-- SECTION 6: DELVE TIER REWARDS
-- coffer  = Bountiful Coffer base drop ilvl
-- vault   = Great Vault reward ilvl for completing this tier
-- ============================================================
-- Season 2 (12.1) item levels. coffer = end-of-run / Bountiful Coffer reward;
-- vault = Great Vault delve slot. Without a Restored Coffer Key, end-of-run
-- caps at Tier 3 (272). Tiers 9-11 don't raise the standard reward past T8+.
-- Source: community delve rewards guides (Aug 2026) -- verify against your drops.
DelveGuideData.tierRewards = {
    [1]  = { coffer=266, vault=279 },
    [2]  = { coffer=269, vault=282 },
    [3]  = { coffer=272, vault=285 },
    [4]  = { coffer=276, vault=289 },
    [5]  = { coffer=279, vault=292 },
    [6]  = { coffer=282, vault=298 },
    [7]  = { coffer=292, vault=302 },
    [8]  = { coffer=295, vault=305 },
    [9]  = { coffer=295, vault=305 },
    [10] = { coffer=295, vault=305 },
    [11] = { coffer=295, vault=305 },
}

-- SECTION 7: SPEC CURIO RECOMMENDATIONS
-- ------------------------------------------------------------
-- Keys are WoW specIDs returned by GetSpecializationInfo().
-- combat / utility = name string matching DelveGuideData.curios entries.
-- companion = recommended Valeera role for that spec.
-- Only `role`/`companion` (recommended Valeera role) are still used by the UI.
-- The `combat`/`utility`/`notes` fields point at RETIRED Season 1 curios and
-- are no longer displayed -- kept only until per-spec S2 recommendations exist.
-- The live Season 2 curio set is in DelveGuideData.curios; the meta isn't
-- settled, so the Curios tab lists effects and defers on per-spec picks.
--
-- NOTE: Sanctum's Edict is rated F in the curio table as a tanking curio,
-- but community data recommends it for some physical DPS specs as a stat
-- stick. The F rating reflects its tanking value; consider revising.
--
-- NEMESIS WARNING: Mandate of Sacred Death procs require profession nodes.
-- The seasonal Nemesis arena may lack them (Nullaeus's did; verify Venomfall
-- Deeps) — swap Mandate specs to Overflowing Voidspire or Ebon Crown there.
--
-- ============================================================
DelveGuideData.specCurioRecs = {
    -- ── Tanks ─────────────────────────────────────────────────
    [250] = { spec="Blood Death Knight",    role="Tank",   companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="High self-sustain but sluggish damage. Sanctum's Edict provides the raw damage boost needed for high-HP elite packs." },
    [73]  = { spec="Protection Warrior",    role="Tank",   companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Lacks passive self-healing - Healer Valeera mandatory. Ebon Crown scales Shield Block and Ignore Pain values." },
    [66]  = { spec="Protection Paladin",    role="Tank",   companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Highly competitive damage output. Blade Tip synergizes with Grand Crusader crit resets. Swap Mandate for Nemesis (no nodes)." },
    [104] = { spec="Guardian Druid",        role="Tank",   companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Recent Maul and Raze buffs reward aggressive stat-scaling. May need Healer Valeera in magic-heavy delves." },
    [268] = { spec="Brewmaster Monk",       role="Tank",   companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Stagger can overwhelm without external healing. Blade Tip crit buffs boost Celestial Fortune procs for self-heals." },
    [581] = { spec="Vengeance Demon Hunter",role="Tank",   companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="High mobility plus strong Soul Cleave/Spirit Bomb output. Can chain-pull between nodes to abuse Mandate procs. Swap for Nemesis." },
    -- ── Healers ───────────────────────────────────────────────
    [65]  = { spec="Holy Paladin",          role="Healer", companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Aligns with Holy damage profile, enabling massive throughput windows during Avenging Wrath. Swap Mandate for Nemesis." },
    [257] = { spec="Holy Priest",           role="Healer", companion="Healer",
              combat="Mantle of Stars",           utility="Time Lost Edict",
              notes="Lacks damage-to-healing conversion. Mantle survives long Smite casting windows; Time Lost Edict aids positioning." },
    [256] = { spec="Discipline Priest",     role="Healer", companion="Healer",
              combat="Mantle of Stars",           utility="Ebon Crown of Subjugation",
              notes="Ebon Crown provides consistent Intellect scaling for both Atonement damage and healing output." },
    [105] = { spec="Restoration Druid",     role="Healer", companion="Healer",
              combat="Mantle of Stars",           utility="Time Lost Edict",
              notes="HoT-and-Rot kiting strategy. Time Lost Edict essential for repositioning while contributing Sunfire/Moonfire damage." },
    [264] = { spec="Restoration Shaman",    role="Healer", companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Acid Rain and Lava Burst procs consistently trigger Mandate's Holy damage. Swap Mandate for Nemesis." },
    [270] = { spec="Mistweaver Monk",       role="Healer", companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Mandate needed for damage scaling so bosses die before mana exhausts - a common Tier 11 failure point. Swap for Nemesis." },
    [1468]= { spec="Preservation Evoker",   role="Healer", companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="High-frequency Living Flame and Azure Strike ticks consistently trigger Mandate procs. Swap Mandate for Nemesis." },
    -- ── DPS ───────────────────────────────────────────────────
    [70]  = { spec="Retribution Paladin",   role="DPS",    companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="High Holy damage output heavily bolstered by Mandate's max-HP procs. Swap Mandate for Nemesis." },
    [71]  = { spec="Arms Warrior",          role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Standard physical scaling. Ebon Crown boosts primary stat for raw physical output." },
    [72]  = { spec="Fury Warrior",          role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Susceptible to burst without Enraged Regeneration. Ebon Crown scales both damage and passive regeneration." },
    [251] = { spec="Frost Death Knight",    role="DPS",    companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Reliable stat scaling boosts consistent physical and frost damage output." },
    [252] = { spec="Unholy Death Knight",   role="DPS",    companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Reliable stat scaling for minion and plague damage stability." },
    [102] = { spec="Balance Druid",         role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Crit synergy pairs well with Blade Tip for Starsurge/Starfall scaling." },
    [103] = { spec="Feral Druid",           role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Physical bleed outputs scale best with the Agility influx from Ebon Crown." },
    [262] = { spec="Elemental Shaman",      role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Extreme crit-based kit synergy. Blade Tip scales exponentially with gear. Swap Mandate for Nemesis." },
    [263] = { spec="Enhancement Shaman",    role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Physical/magic hybrid benefits from primary stat padding via Ebon Crown." },
    [258] = { spec="Shadow Priest",         role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Psychic Link makes them elite AoE clearers. High DoT frequency triggers both curios flawlessly. Swap Mandate for Nemesis." },
    [259] = { spec="Assassination Rogue",   role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Physical scaling reinforces Ebon Crown as the best raw stat amplifier for Bleed damage." },
    [260] = { spec="Outlaw Rogue",          role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="High APM physical spec relies on flat stat padding for consistency." },
    [261] = { spec="Subtlety Rogue",        role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Stat and crit setup for burst stealth windows." },
    [253] = { spec="Beast Mastery Hunter",  role="DPS",    companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Pet multi-hit triggers Mandate more frequently than almost any other spec. Swap Mandate for Nemesis." },
    [254] = { spec="Marksmanship Hunter",   role="DPS",    companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Ranged burst relies on high crit values. Swap Mandate for Nemesis." },
    [255] = { spec="Survival Hunter",       role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Steady stat increases for pet/melee hybrid consistency." },
    [265] = { spec="Affliction Warlock",    role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Steady DoT damage scales reliably with constant primary stat buffs." },
    [266] = { spec="Demonology Warlock",    role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Pets hold aggro allowing flexibility. Ebon Crown strongly buffs demon throughput." },
    [267] = { spec="Destruction Warlock",   role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Crit scaling drastically increases Chaos Bolt burst output." },
    [62]  = { spec="Arcane Mage",           role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Primary stat scaling from Ebon Crown deletes priority targets during Touch of the Magi." },
    [63]  = { spec="Fire Mage",             role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Total reliance on crit synergies makes Blade Tip optimal. Swap Mandate for Nemesis." },
    [64]  = { spec="Frost Mage",            role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Shattering procs with Valeera holding aggro. Swap to Mantle of Stars if kiting is impossible (e.g., Shadow Enclave). Swap Mandate for Nemesis." },
    [269] = { spec="Windwalker Monk",       role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Raw stats over random procs keeps alternating attacks fluid." },
    [577] = { spec="Havoc Demon Hunter",    role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="High baseline crit synergies make Blade Tip outstanding. Swap Mandate for Nemesis." },
    [1480]= { spec="Devourer Demon Hunter", role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Apex Rank 1 ensures Collapsing Star always crits, making Blade Tip mandatory. Swap Mandate for Nemesis." },
    [1467]= { spec="Devastation Evoker",    role="DPS",    companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Glass cannon setup. Crit amplifier scales immensely with Eternity Surge and Deep Breath." },
    [1473]= { spec="Augmentation Evoker",   role="DPS",    companion="Healer",
              combat="Mantle of Stars",           utility="Ebon Crown of Subjugation",
              notes="Dependent on keeping self and Valeera alive. Mantle prevents one-shots; Ebon Crown boosts supportive damage." },
}

-- ============================================================
-- GRADE COLORS
-- ============================================================
DelveGuideData.gradeColors = {
    S = "|cFFFF8000",
    A = "|cFF00FF00",
    B = "|cFF00BFFF",
    C = "|cFFFFFF00",
    D = "|cFFFF6600",
    F = "|cFFFF0000",
}
-- ============================================================
-- SECTION 8: CHANGELOG
-- ============================================================
DelveGuideData.changelog = {
    {
        version = "1.8.2",
        date    = "2026-08-16",
        entries = {
            "Help rank the delves! DelveGuide already times your runs -- now /dg submit copies your clear times to paste into the community ranking form. The more players pitch in, the faster the new [?] variants get real rankings.",
            "New 'Your Fastest Variants' panel on the History tab: your average clear time per variant, fastest first.",
        }
    },
    {
        version = "1.8.1",
        date    = "2026-08-16",
        entries = {
            "Fixed: the new Coiled Isle delves (The Ring of Glory, Gnarldor Isle) and the new venom variants now show up in Active Today and the widget -- they were being detected but not displayed. Rankings show as [?] until routes are tested.",
            "The Delves tab now surfaces any active delve even when its exact variant isn't catalogued yet, so daily rotations of new variants won't vanish from Active Today.",
            "Loot: delve reward item levels updated to Season 2 -- end-of-run up to 295 at Tier 8+, and the Great Vault delve slot up to 305 (Hero).",
            "Curios tab refreshed for Season 2: Season 1's curios are gone and were replaced by the confirmed S2 set (Corrosive Bilespear, Ouroboric Curse, Essence Trap, Soul-Cracking Dreamcatcher, Dundun's Favor, Venom Infusion). Per-spec picks that pointed at retired curios were removed; a strong general pick (Corrosive Bilespear) is surfaced instead.",
            "Poisons: all six 12.1 poisons (3 base + 3 quest-unlocked) are now listed on the Curios and Companion tabs, with what each does and a rule-of-thumb pick.",
            "Future tab: cleared out stale entries and refreshed it with confirmed upcoming content -- Ascendant Venomstones later this season, and Labyrinths (the mega-delve) confirmed for patch 12.1.5.",
            "The Quests tab is now the Journey tab: it lists the Season 2 Delver's Journey rank unlocks (ranks 1-10) on top of the Delver's Call quest tracker. Open with /dg journey.",
            "Fixed the Trovehunter's Bounty status on the Delves tab -- it was checking old item/buff IDs and never lit up. It now shows Active (buff up), In Bags (item held), Done this week (weekly done), or None.",
            "Nemesis tab: the Azta'rec guide is expanded and corrected from the live guide -- clearer main-phase abilities, the intermission memory game (Sermon -> Echo), the intro questline for the Corrosive Victory toy, and exact rewards per difficulty.",
            "Season 2 currencies: Nebulous Voidcore is now tracked as the bonus-roll token. The new gear-upgrade material -- Ascendant Venomstone (10 per upgrade, guaranteed from Tier 11 Bountiful Delves) -- is flagged in the Voidforge and Loot tabs and lights up once it goes live later this season.",
            "Retired the old Patch 12.0.5 Voidforge upgrade loop (Elementary Shards / the 'Building the Voidforge' weekly quest).",
        }
    },
    {
        version = "1.8.0",
        date    = "2026-08-11",
        entries = {
            "Patch 12.1 / Season 2 ready! The Coiled Isle and its two new delves -- The Ring of Glory and Gnarldor Isle -- are fully integrated: map pins, Active Today detection, compact widget, and variant tracking.",
            "New Nemesis tab (replaces the Nullaeus tab): dedicated guide for Season 2's Nemesis delve, Venomfall Deeps, and its boss Azta'rec -- location (The Serpent's Tail, /way #2512 51.2 30.3), unlock requirements, mechanics, and rewards.",
            "Nullaeus isn't gone! Torment's Rise remains enterable as legacy content. The Nemesis tab keeps a compact Season 1 section: location, unlock, the Beacon of Hope skip, and exactly which rewards are still collectible vs. retired.",
            "Season 2 story variants added -- and good news: Season 1 variants (and all existing rankings) remain in rotation. Season 2 adds new venom/serpent variants on top of the existing pools rather than replacing them.",
            "Rankings for the new delves and new variants will be refined over the first weeks of Season 2 as routes get tested -- keep an eye on 1.8.x updates.",
            "Delver's Call: quests for The Ring of Glory and Gnarldor Isle will be auto-detected as soon as they're catalogued at Season 2 launch.",
            "New command: /dg export -- snapshots your current zone/delve/quest state to SavedVariables. Handy for bug reports: run it where something looks wrong and attach the file.",
            "Launch schedule: the new delves, Nemesis, and venom variants are live now (Aug 11). Bountiful Delves, Coffer Keys, and the seasonal Great Vault unlock with Season 2 on Aug 18 -- so the bountiful filter and key checklist stay quiet that first week. That's expected, not a bug.",
        }
    },
    {
        version = "1.7.17",
        date    = "2026-04-25",
        entries = {
            "New Voidforge tab: weekly Cores/Shards/Ascendant state, where-to-earn reference, slot upgrade priority (weapons & trinkets first, then armor by lowest ilvl), and alt stockpile rollup.",
            "New Quests tab (Delver's Call): tracks all 10 per-delve quests with 4 auto-detected states -- Available / In Progress / Banked (gold-highlighted sweet spot) / Turned In. Hold quests until close to max level for a big XP push.",
            "All 10 Delver's Call quest IDs catalogued from wowhead.com -- the tab is fully auto-detect on day one.",
            "Slash commands: /dg voidforge (alias /dg forge), /dg quests, /dg questscan (lists Delver's Call quests in your log + IDs).",
            "Roster snapshot now captures Voidforge state per character so the Alt Stockpile works without each alt being logged in right now.",
        }
    },
    {
        version = "1.7.16",
        date    = "2026-04-24",
        entries = {
            "CI Hotfix: Removed dead lib externals from .pkgmeta -- libraries now ship from the committed Libs/ folder. v1.7.15 failed to publish on CurseForge; this republishes the same code under a new tag. No functional changes.",
        }
    },
    {
        version = "1.7.15",
        date    = "2026-04-24",
        entries = {
            "Settings: Added 'Show only bountiful delves' checkbox to the Compact Widget section -- syncs with the [B] button and /dg bountiful.",
        }
    },
    {
        version = "1.7.14",
        date    = "2026-04-24",
        entries = {
            "New Feature: Bountiful-Only filter on the widget. Click the new [B] button in the widget header to hide all non-bountiful variants (gold = ON, grey = OFF).",
            "New Command: /dg bountiful -- toggles the same filter from chat.",
            "Improvement: Share button now respects the bountiful filter -- only broadcasts bountiful delves when the toggle is ON.",
        }
    },
    {
        version = "1.7.13",
        date    = "2026-04-24",
        entries = {
            "Fix: Companion tab now correctly displays Valeera's level (e.g. 38) by parsing the rank number out of the friendship 'Level X' string.",
        }
    },
    {
        version = "1.7.12",
        date    = "2026-04-24",
        entries = {
            "Fix: Companion XP now reads the correct friendship rank (80-level XP track) instead of the 1-8 reaction. The tab was showing 'Level 8' for Exalted reputations -- now shows the real rank.",
            "Improvement: Faction auto-discovery scans friendship factions before falling through to Major Factions and regular reputations.",
        }
    },
    {
        version = "1.7.11",
        date    = "2026-04-24",
        entries = {
            "Fix: /dg companionfaction <id> no longer hardcodes Major Faction type -- the renown lookup auto-detects whether the ID is a Major Faction or regular reputation.",
            "Improvement: Cached faction type self-corrects when the wrong API was guessed.",
        }
    },
    {
        version = "1.7.10",
        date    = "2026-04-23",
        entries = {
            "New Feature: Companion XP via Reputation -- the Companion tab now reads Valeera's XP/level from her reputation faction, so the progress bar works outside of delves too.",
            "New Command: /dg companionscan -- clears the cached companion faction so it re-scans on next open.",
            "New Command: /dg companionfaction <id> -- manually pin a faction ID if auto-discovery can't find it.",
        }
    },
    {
        version = "1.7.9",
        date    = "2026-04-23",
        entries = {
            "New Feature: Voidforge integration (Patch 12.0.5)! Surfaces across the widget, pre-entry checklist, history tab, world map tooltip, and loot tab.",
            "Widget: New 'Cores / Forge' line shows Nebulous Voidcore count and weekly shard progress.",
            "Checklist: New 'Voidforge weekly' row flags if you still owe shards before your next Bountiful Delve.",
            "History: Per-week summary now reports how many T8+ runs were Voidcore-eligible.",
            "Map: Active-delve tooltips now flag T8+ as Voidcore-eligible.",
            "Loot: New Voidforge Currencies section explains Nebulous / Elementary Shard / Ascendant Voidcores.",
        }
    },
    {
        version = "1.7.8",
        date    = "2026-04-23",
        entries = {
            "New Feature: Separate Widget Font Scale -- the compact widget now has its own independent font scale, decoupled from the main UI font.",
            "New Command: /dg widgetfont <0.6-2.0> -- adjusts only the widget font size.",
            "Settings: Added Widget Font Scale section with A-/A+/Reset buttons.",
        }
    },
    {
        version = "1.7.7",
        date    = "2026-04-23",
        entries = {
            "Fix: Compact widget now displays up to 10 active variants (previously capped at 8).",
            "Fix: /dg font command and Settings A-/A+/Reset buttons now resize the compact widget too.",
        }
    },
    {
        version = "1.7.6",
        date    = "2026-04-21",
        entries = {
            "Patch 12.0.5 Compatibility: Added interface version 120005 so the addon is no longer flagged as 'Out of Date' on the latest client.",
        }
    },
    {
        version = "1.7.5",
        date    = "2026-04-17",
        entries = {
            "Fix: Parhelion Plaza now detects correctly -- scanner queries mapID 2424 (the actual Isle of Quel'Danas uiMapID).",
            "Fix: Registered widget set ID 1799 for Parhelion Plaza so non-EN clients can resolve the localized delve name.",
            "Fix: Torment's Rise no longer logged as a missing translation -- correctly recognized as a Nemesis delve. Stale entries auto-purged on load.",
            "Improvement: POI scan dedup -- delves exposed on multiple map IDs are processed once instead of twice.",
            "New Command: /dg findplaza -- brute-force scans map IDs 2200-2700 to locate Parhelion Plaza POI for future map changes.",
        }
    },
    {
        version = "1.7.4",
        date    = "2026-04-12",
        entries = {
            "New Feature: Story variant captured in run history (e.g. 'Ogre Powered' displayed in the History tab and chat log).",
            "Localization: Traditional Chinese (zhTW) -- 4 new variant translations.",
            "Fix: HUD overlay font size now respects the fontScale setting.",
            "Fix: Spanish 'Trapped!' corrected to '¡Atrapados!'.",
            "Fix: Parhelion Plaza esES variants properly labeled.",
        }
    },
    {
        version = "1.7.3",
        date    = "2026-04-01",
        entries = {
            "Localization: Spanish (esES/esMX) now at full 30/30 variant coverage!",
            "New Command: /dg resetwidget -- resets widget position to center if lost off-screen.",
            "Fix: Widget now auto-detects off-screen position on load and resets to center.",
        }
    },
    {
        version = "1.7.2",
        date    = "2026-03-30",
        entries = {
            "Localization: Added 3 Traditional Chinese (zhTW) Darkway variants + alternate Mirror Shine translation.",
            "Fix: Replaced unicode characters (em dashes, checkmarks) that rendered as squares in WoW's default font.",
            "Data: Updated The Darkway coordinates in Silvermoon City to verified in-game location.",
            "Data: Cleaned up stale Future tab entries (removed already-live system changes and past releases).",
        }
    },
    {
        version = "1.7.1",
        date    = "2026-03-28",
        entries = {
            "Hotfix: Compact widget position reset for users upgrading from pre-1.7.0. You may need to reposition your widget once.",
            "Bug Fix: DataBroker (LDB) vault text now matches the main tracker format.",
        }
    },
    {
        version = "1.7.0",
        date    = "2026-03-27",
        entries = {
            "Localization: Expanded Italian (itIT) coverage from 17 to 26 variants.",
            "Bug Fix: HUD now works on non-English clients (variant, grade, tier, lives, nemesis, bountiful).",
            "Bug Fix: Great Vault tracker updated for Midnight API changes (was showing 0/8).",
            "Bug Fix: Restored Coffer Key now reads from currency system instead of item system.",
            "Bug Fix: World Quest counter now deduplicates quests across overlapping zones.",
            "Bug Fix: Vault row now shows actual reward ilvl instead of tier number.",
            "Bug Fix: Compact widget position now saves correctly across reloads.",
            "Improvement: Keys tracker shows (Capped) when weekly shard cap is reached.",
            "Improvement: Vault progress shows completions toward max threshold (e.g. 8/8).",
            "New Command: /dg huddump -- dumps localized HUD data for debugging.",
        }
    },
    {
        version = "1.6.2",
        date    = "2026-03-25",
        entries = {
            "Localization: Added Spanish (esES/esMX) variant translations - new language!",
            "Localization: Expanded Italian (itIT) coverage from 8 to 17 variants.",
            "Improvement: Active variants in the Delves tab are now sorted by rank (S first, F last).",
        }
    },
    {
        version = "1.6.1",
        date    = "2026-03-25",
        entries = {
            "Improvement: Missing translation notifications are now silent. A single one-time flag prints on login if untranslated variants exist on your client.",
            "Removed per-variant chat spam that fired during POI scanning on non-English clients.",
        }
    },
    {
        version = "1.6.0",
        date    = "2026-03-24",
        entries = {
            "New Feature: Share to Chat - share today's active variants to Party (left-click) or Guild (right-click) from the Delves tab and compact widget.",
            "New Feature: Completion Timer - live timer on the HUD during delve runs, saved to run history on completion.",
            "New Feature: Victory Screen now displays your completion time.",
            "New Feature: DataBroker text feed - info bar addons (Titan Panel, ElvUI, Bazooka) now show your top active variant and rank.",
            "Improvement: Delve flags ([Best], [Bug], [Mt], [Nemesis], [Bountiful], [TODAY]) are now interactive buttons with hover tooltips explaining each tag.",
            "Improvement: Added a 'What are Delves?' tooltip for new players (hover the ? in the Delves tab).",
            "Improvement: Missing translations are now automatically logged to SavedVariables with locale, delve name, and first-seen date. Check the Debug tab to review.",
            "Bug Fix: Restored Coffer Key item ID corrected in roster character cache.",
        }
    },
    {
        version = "1.5.1",
        date    = "2026-03-24",
        entries = {
            "Hotfix: Resolved a Lua error that triggered when hovering over protected UI elements with map tooltips enabled."
        }
    },
    {
        version = "1.5.0",
        date    = "2026-03-23",
        entries = {
            "Milestone: Thank you all so much for 25,000+ downloads! Your feedback and chat dumps make this addon possible.",
            "New Feature: Hover over active delves on the World Map to instantly see their Speed Grade and Variant!",
            "Settings: Added a toggle to enable/disable the new World Map tooltips.",
            "Bug Fix: The minimap toggle button in the settings menu now works flawlessly.",
            "Localization: Massive updates to German and Korean tracking, and added a workaround for a Blizzard spelling typo."
        }
    },
    {
        version = "1.4.7",
        date    = "2026-03-21",
        entries = {
            "Hotfix to fix Blizzard Spelling Error l0l",
            "Shadowguard Point Story Variant Captured Widlife"
        }
    },
    {
        version = "1.4.6",
        date    = "2026-03-21",
        entries = {
            "Minor localization additions to koKR client"
        }
    },   
    {
        version = "1.4.5",
        date    = "2026-03-21",
        entries = {
            "Localization Upgrade: Unknown variants are now safely quarantined with a [Missing Translation] tag instead of breaking the UI.",
            "Traditional Chinese (zhTW) Support: Added full variant translations for the zhTW client."
        }
    },    
    {
        version = "1.4.4",
        date    = "2026-03-21",
        entries = {
            "Hotfix: Fixed a Lua bug preventing localization dictionaries from loading on non-English clients."
        }
    },
    {
        version = "1.4.3",
        date    = "2026-03-21",
        entries = {
            "New Feature: Animated Victory Screen on Delve completion!",
            "Custom Audio: Plays a satisfying victory fanfare when you finish a run.",
            "UI Customization: You can now unlock, drag, and reposition the Victory popup via the Settings tab.",
            "Vault Tracking Fix: Bypassed a Blizzard API bug where World Bosses were counting as Delve completions. Vault tracking is now 100% accurate."
        }
    },
    {
        version = "1.4.2",
        date    = "2026-03-21",
        entries = {
            "New Companion Tab: Track Valeera/Brann's level, role, and XP progress.",
            "Live Curio Scanning: Compares your currently equipped curios against S-Tier spec recommendations and shows dynamic warnings.",
            "Smart Tier Auto-Detection: The In-Run HUD now automatically detects your Delve tier - no more /dg tier commands!",
            "Automated Vault Tracking: Auto-detected tiers are now seamlessly logged to your History tab.",
            "Resizable Windows: Both the Main Window and the In-Run HUD can now be dragged and resized.",
            "Korean (koKR) Support: Added full variant translation support for the Korean client.",
            "Localization Upgrade: Added graceful fallbacks to show all possible variants if a translated name isn't found.",
            "System Health Dashboard: Overhauled the Debug tab to show live API status, database size, and troubleshooting commands.",
            "Under the hood: Modularized the Pre-Entry Checklist and Compact Widget for better performance."
        }
    },
    {
        version = "1.4.0",
        date    = "2026-03-19",
        entries = {
            "Massive architecture refactor: extracted all 9 UI tabs into separate modules for better performance and maintainability.",
            "Added native LibDataBroker (LDB) support for the minimap button (supports Titan Panel, ElvUI, Bazooka, etc.).",
            "Added native TomTom support for all delve and nemesis waypoints.",
            "Loot Tab: Added native WoW item icons to all trinket and weapon rows.",
            "Roster Tab: Added class/spec icons to the character list.",
            "Roster Tab: Added interactive hover tooltips showing exact delve runs and highest Great Vault item level unlocked.",
        },
    },
    {
        version = "1.3.8",
        date    = "2026-03-18",
        entries = {
            "Fixed: variant detection and all badges now work on all non-English clients (KR, TW, CN, DE, FR, RU, etc.)",
            "Variant matching uses locale-independent widget set IDs - no English text matching required",
            "HUD now correctly detects you are inside a Delve on non-English clients",
            "Zone names normalized to English internally so TODAY and Bountiful badges work globally",
        },
    },
    {
        version = "1.3.7",
        date    = "2026-03-18",
        entries = {
            "Debug tab: now shows per-map-ID scan status even when results are empty",
            "Debug tab: clear messaging when map IDs return no POIs (helps diagnose non-English client issues)",
            "New command: /dg chatdump - prints full scan results to chat for easy copy-paste sharing",
        },
    },
    {
        version = "1.3.6",
        date    = "2026-03-17",
        entries = {
            "Bountiful detection now uses atlas name (reliable, no map hover required)",
            "Delves tab: active bountiful delves show a gold [Bountiful] badge",
            "Compact widget: bountiful variants marked with gold [B]",
            "Debug tab: atlasName now shown per POI to aid future detection work",
        },
    },
    {
        version = "1.3.5",
        date    = "2026-03-17",
        entries = {
            "Settings: added toggle to disable the What's New changelog popup on login",
            "Changelog popup can still be opened manually via the View Changelog button in Settings",
        },
    },
    {
        version = "1.3.4",
        date    = "2026-03-17",
        entries = {
            "New tab: Nullaeus - dedicated Season 1 Nemesis guide",
            "Covers location, unlock requirements, all mechanics (Umbral Rage, Oblivion Shell), phase transitions, recommended setup, tips, and rewards",
            "Includes Beacon of Hope workflow for earning the weekly Bounty without entering Torment's Rise",
        },
    },
    {
        version = "1.3.3",
        date    = "2026-03-17",
        entries = {
            "Tracking Restored Coffer Keys (item 3028) - shown in compact widget, checklist, roster, and Delves tab",
            "Checklist: coffer key check now passes if you have a Restored Coffer Key, even without 100 shards",
            "Roster: restored key count shown next to shard total as +(N)r",
        },
    },
    {
        version = "1.3.2",
        date    = "2026-03-17",
        entries = {
            "Fixed: HUD showing in Zul'Aman overworld (seamless sub-zone name bleeding into detection)",
            "Detection now requires C_Scenario.IsInScenario() - zone name alone is no longer sufficient",
        },
    },
    {
        version = "1.3.1",
        date    = "2026-03-16",
        entries = {
            "Fixed: HUD now closes on delve completion (SCENARIO_COMPLETED + ZONE_CHANGED events)",
            "Settings: added HUD enable/disable toggle",
        },
    },
    {
        version = "1.3.0",
        date    = "2026-03-16",
        entries = {
            "In-Run HUD - auto-shows when inside a Delve, hides on exit",
            "HUD shows: delve name, active variant + grade, tier, curio rec, nemesis warning, bountiful status",
            "HUD is draggable and remembers its position",
            "/dg hud - toggle the HUD manually (also works as a preview outside of Delves)",
        },
    },
    {
        version = "1.2.2",
        date    = "2026-03-16",
        entries = {
            "History: each run now shows which character completed it",
            "History: added Clear History button with confirmation",
        },
    },
    {
        version = "1.2.1",
        date    = "2026-03-16",
        entries = {
            "Fixed: opening world map no longer triggers ADDON_ACTION_BLOCKED (SetPassThroughButtons taint)",
            "Waypoint click now sets the pin silently - press M to open your map and navigate",
        },
    },
    {
        version = "1.2.0",
        date    = "2026-03-15",
        entries = {
            "Roster tab - track all level-80+ alts' weekly delves, shards, ilvl, and vault slots",
            "Roster: per-character remove button with confirmation dialog",
            "Fixed: targeting a delve entrance no longer triggers a taint error",
        },
    },
    {
        version = "1.1.0",
        date    = "2026-03-14",
        entries = {
            "Settings tab - minimap, compact widget, tier filter, font scale",
            "Compact floating widget with tier filter and lock button",
            "Clickable delve names open the map and set a waypoint",
            "Loot tab item tooltips on hover",
            "Weekly reset timer and Great Vault tracker in the header",
            "Coffer Key shard tracker in the header bar",
            "/dg help command listing all slash commands",
        },
    },
    {
        version = "1.0.0",
        date    = "2026-03-01",
        entries = {
            "Initial release - delve rankings, curio DB, loot tables, run history",
            "Active variant scanner, minimap button, font scale setting",
        },
    },
}

-- ============================================================================
-- LOCALIZATION DICTIONARIES
-- ============================================================================

-- Widget set ID → English DELVE name (not variant name).
DelveGuideData.widgetSetDelves = {
    [1611] = "Collegiate Calamity",
    [1738] = "The Grudge Pit",
    [1799] = "Parhelion Plaza",
    [1800] = "Sunkiller Sanctum",
    [1801] = "Shadowguard Point",
    [1802] = "Atal'Aman",
    [1803] = "The Gulf of Memory",
    [1804] = "The Shadow Enclave",
    [1805] = "Twilight Crypts",
    [1806] = "The Darkway",
    -- Note: Torment's Rise (set=0) is the Nullaeus Nemesis delve, not a rotational delve.
}


-- Localized variant name → English variant name.
-- TRANSLATION GAPS (as of 1.7.5):
--   koKR, itIT — Parhelion Plaza: Holding the Line, Bombing Run, March of the Arcane Brigade
--   Need verified text from a koKR/itIT client while those variants are active.
--   Submit via /dg chatdump when they hit rotation.
DelveGuideData.localeVariants = {
    -- English Typos (Blizzard mistakes)
    ["Captured Widlife"] = "Capture Wildlife",     -- Shadowguard Point typo
    ["Captured Wildlife"] = "Capture Wildlife",    -- Just in case they fix the 'L' but keep 'Captured'
    -- Korean (koKR)
    ["하라니르의 후예"] = "Descent of the Haranir",      -- The Gulf of Memory
    ["침입하는 불빛"]   = "Invasive Glow",               -- Collegiate Calamity 
    ["배신자의 대가"]   = "Traitor's Due",               -- The Shadow Enclave 
    ["연회 훼방꾼"]     = "Party Crasher",               -- Twilight Crypts 
    ["토템 말살"]       = "Totem Annihilation",          -- Atal'Aman 
    ["문제의 중심"]     = "Core of the Problem",         -- Sunkiller Sanctum 
    ["악랄한 부식줄기"] = "Dastardly Rotstalk",          -- The Grudge Pit 
    ["도둑맞은 마나"]   = "Stolen Mana",                 -- Shadowguard Point 

    -- Korean (koKR) - Batch 2
    ["포위당한 학술원"]   = "Academy Under Siege",       -- Collegiate Calamity
    ["어둠의 보급품"]     = "Shadowy Supplies",          -- The Shadow Enclave
    ["함정이다!"]         = "Trapped!",                  -- Twilight Crypts
    ["의식 방해"]         = "Ritual Interrupted",        -- Atal'Aman
    ["중력 효과"]         = "The Gravitational Effect",  -- Sunkiller Sanctum
    ["투기장의 용사"]     = "Arena Champion",            -- The Grudge Pit
    ["알른나방 간식"]     = "Alnmoth Munchies",          -- The Gulf of Memory
    ["재앙을 부르는 자"]   = "Calamitous",                -- Shadowguard Point

    -- German (deDE)
        -- Verified via /dg chatdump
    ["Belagerte Akademie"]       = "Academy Under Siege",       
    ["Schattenhafte Vorräte"]    = "Shadowy Supplies",          
    ["Gefangen!"]                = "Trapped!",                  
    ["Ritual unterbrochen"]      = "Ritual Interrupted",        
    ["Der Gravitationseffekt"]   = "The Gravitational Effect",  
    ["Arenachampion"]            = "Arena Champion",            
    ["Heißhunger der Alnmotten"] = "Alnmoth Munchies",          
    ["Verhängnisvoll"]           = "Calamitous",                
    ["Invasives Leuchten"]       = "Invasive Glow",           
    ["Schuld eines Verräters"]   = "Traitor's Due",           
    ["Ungeladene Gäste"]         = "Party Crasher",           
    ["Totemvernichtung"]         = "Totem Annihilation",      
    ["Der Kern des Problems"]    = "Core of the Problem",     
    ["Durchtriebener Faulstrunk"]= "Dastardly Rotstalk",      
    ["Abstieg der Haranir"]      = "Descent of the Haranir",  
    ["Gestohlenes Mana"]         = "Stolen Mana",   

        -- Unverified 
    ["Krötal unwürdig"]              = "Toadly Unbecoming",
    ["Fakultät der Furcht"]          = "Faculty of Fear",
    ["Die Stellung halten"]          = "Holding the Line",
    ["Bomberangriff"]                = "Bombing Run",
    ["Marsch der arkanen Brigade"]   = "March of the Arcane Brigade",
    ["Gefangene Tiere"]              = "Capture Wildlife",
    ["Nicht, was ich erwartet hatte"]= "Not What I Expected",
    ["Fokussierer unter Druck"]      = "Focusers Under Pressure",
    ["Leylinientechniker"]           = "Leyline Technician",
    ["Ogerbetrieben"]                = "Ogre Powered",
    ["Lichtblüteninvasion"]          = "Lightbloom Invasion",
    ["Sporasaurus Spezial"]          = "Sporasaur Special",
    ["Spiegelglanz"]                 = "Mirror Shine",
    ["Gelöste Loa"]                  = "Loosed Loa",

    -- Italiano (itIT)
    ["L'Assedio dell'Accademia"] = "Academy Under Siege",       -- Collegiate Calamity
    ["Bagliore Invasivo"]        = "Invasive Glow",             -- Collegiate Calamity
    ["Scorte Tenebrose"]         = "Shadowy Supplies",          -- The Shadow Enclave
    ["Il Prezzo del Traditore"]  = "Traitor's Due",             -- The Shadow Enclave
    ["In Trappola!"]             = "Trapped!",                  -- Twilight Crypts
    ["Imbucati"]                 = "Party Crasher",             -- Twilight Crypts
    ["Rituale Interrotto"]       = "Ritual Interrupted",        -- Atal'Aman
    ["Annientamento dei Totem"]  = "Totem Annihilation",        -- Atal'Aman
    ["Effetto Gravitazionale"]   = "The Gravitational Effect",  -- Sunkiller Sanctum
    ["Il nucleo del problema"]   = "Core of the Problem",       -- Sunkiller Sanctum
    ["Campione dell'arena"]      = "Arena Champion",            -- The Grudge Pit
    ["Micostelo Ignobile"]       = "Dastardly Rotstalk",        -- The Grudge Pit
    ["Delizie per Falenaln"]     = "Alnmoth Munchies",          -- The Gulf of Memory
    ["Discesa degli Haranir"]    = "Descent of the Haranir",    -- The Gulf of Memory
    ["Calamità"]                 = "Calamitous",                -- Shadowguard Point
    ["Mana rubato"]              = "Stolen Mana",              -- Shadowguard Point
    ["Concentrazione Sotto Pressione"] = "Focusers Under Pressure", -- The Darkway
    ["Facoltà della Paura"]           = "Faculty of Fear",         -- Collegiate Calamity
    ["Potenza da Ogre"]               = "Ogre Powered",            -- The Darkway
    ["Splendore dello Specchio"]      = "Mirror Shine",            -- The Shadow Enclave
    ["Loa Scatenato"]                 = "Loosed Loa",              -- Twilight Crypts
    ["Rospamente Sconveniente"]       = "Toadly Unbecoming",       -- Atal'Aman
    ["Non come mi aspettavo"]         = "Not What I Expected",     -- Sunkiller Sanctum
    ["Invasione della Fioritura di Luce"] = "Lightbloom Invasion", -- The Grudge Pit
    ["Specialità da Sporasauri"]      = "Sporasaur Special",       -- The Gulf of Memory
    ["Fauna catturata"]               = "Capture Wildlife",        -- Shadowguard Point

    -- Español (esES / esMX)
    ["Resplandor invasivo"]              = "Invasive Glow",             -- Collegiate Calamity
    ["Facultad del miedo"]               = "Faculty of Fear",           -- Collegiate Calamity
    ["Academia asediada"]                = "Academy Under Siege",       -- Collegiate Calamity
    ["Concentradores bajo presión"]      = "Focusers Under Pressure",   -- The Darkway
    ["Energía de ogro"]                  = "Ogre Powered",              -- The Darkway
    ["Técnico de líneas Ley"]            = "Leyline Technician",        -- The Darkway
    ["Recompensa de una traición"]       = "Traitor's Due",             -- The Shadow Enclave
    ["Brillo de espejo"]                 = "Mirror Shine",              -- The Shadow Enclave
    ["Suministros sombríos"]             = "Shadowy Supplies",          -- The Shadow Enclave
    ["Aguafiestas"]                      = "Party Crasher",             -- Twilight Crypts
    ["Loa a la fuga"]                    = "Loosed Loa",                -- Twilight Crypts
    ["¡Atrapados!"]                      = "Trapped!",                  -- Twilight Crypts
    ["Aniquilación de tótems"]           = "Totem Annihilation",        -- Atal'Aman
    ["Sapos impropios"]                  = "Toadly Unbecoming",         -- Atal'Aman
    ["Ritual interrumpido"]              = "Ritual Interrupted",        -- Atal'Aman
    ["El núcleo del problema"]           = "Core of the Problem",       -- Sunkiller Sanctum
    ["No es lo que esperaba"]            = "Not What I Expected",       -- Sunkiller Sanctum
    ["El efecto gravitatorio"]           = "The Gravitational Effect",  -- Sunkiller Sanctum
    ["Acecho putrefacto despiadado"]     = "Dastardly Rotstalk",        -- The Grudge Pit
    ["Invasión de flor de Luz"]          = "Lightbloom Invasion",       -- The Grudge Pit
    ["Campeón de la arena"]              = "Arena Champion",            -- The Grudge Pit
    ["Descenso de los haranir"]          = "Descent of the Haranir",    -- The Gulf of Memory
    ["Especial de esporasaurio"]         = "Sporasaur Special",         -- The Gulf of Memory
    ["Bocaditos para polillas de Aln"]   = "Alnmoth Munchies",          -- The Gulf of Memory
    ["Maná robado"]                      = "Stolen Mana",               -- Shadowguard Point
    ["Fauna cautiva"]                    = "Captured Wildlife",          -- Shadowguard Point
    ["Calamitoso"]                       = "Calamitous",                 -- Shadowguard Point
    ["Defender el frente"]               = "Holding the Line",           -- Parhelion Plaza
    ["Bombardeo"]                        = "Bombing Run",                -- Parhelion Plaza
    ["La marcha de la brigada Arcana"]   = "March of the Arcane Brigade", -- Parhelion Plaza

    -- Traditional Chinese (zhTW)

    ["圖騰滅絕"] = "Totem Annihilation", 	-- Atal'Aman
    ["蟾蜍災難"] = "Toadly Unbecoming", 	-- Atal'Aman
    ["儀式中斷"] = "Ritual Interrupted", 	-- Atal'Aman
    ["恐懼教授"] = "Faculty of Fear", 		-- Collegiate Calamity
    ["被圍攻的學院"] = "Academy Under Siege", -- Collegiate Calamity
    ["入侵之光"] = "Invasive Glow", 		-- Collegiate Calamity
    ["災厄"] = "Calamitous", 				-- Shadowguard Point
    ["被捕獲的野生動物"] = "Capture Wildlife", -- Shadowguard Point
    ["遭竊的法力"] = "Stolen Mana", 			-- Shadowguard Point
    ["非我所望"] = "Not What I Expected",  		-- Sunkiller Sanctum
    ["重力效應"] = "The Gravitational Effect",  -- Sunkiller Sanctum
    ["麻煩的核心"] = "Core of the Problem",  	-- Sunkiller Sanctum
    ["殘虐腐柄"] = "Dastardly Rotstalk", 		-- The Grudge Pit
    ["光綻入侵"] = "Lightbloom Invasion", 		-- The Grudge Pit
    ["競技場勇士"] = "Arena Champion", 		    -- The Grudge Pit
    ["哈拉尼爾進入地底"] = "Descent of the Haranir", -- The Gulf of Memory
    ["艾恩蛾點心"] = "Alnmoth Munchies", 		-- The Gulf of Memory
    ["孢龍快遞"] = "Sporasaur Special", 		-- The Gulf of Memory
    ["叛徒的死期"] = "Traitor's Due",          	-- The Shadow Enclave
    ["暗影補給品"] = "Shadowy Supplies",        -- The Shadow Enclave
    ["鏡子發光"] = "Mirror Shine",              -- The Shadow Enclave (achievement name)
    ["鏡光閃閃"] = "Mirror Shine",              -- The Shadow Enclave (in-game variant name)
    ["派對破壞者"] = "Party Crasher",           -- Twilight Crypts
    ["受困！"] = "Trapped!",                    -- Twilight Crypts
    ["失控羅亞"] = "Loosed Loa",                -- Twilight Crypts
    ["地脈技師"] = "Leyline Technician",        -- The Darkway
    ["高壓聚焦器"] = "Focusers Under Pressure", -- The Darkway
    ["強化巨魔"] = "Ogre Powered",              -- The Darkway
    ["獲釋的羅亞"] = "Loosed Loa",              -- Twilight Crypts (alt translation)
    ["堅守陣線"] = "Holding the Line",           -- Parhelion Plaza
    ["秘法兵團行軍"] = "March of the Arcane Brigade", -- Parhelion Plaza
    ["轟炸任務"] = "Bombing Run",                -- Parhelion Plaza
}