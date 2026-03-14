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
    -- ── Twilight Crypts ───────────────────────────────────
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Party Crasher",               ranking="B", mountable=false, hasBug=true,  isBestRoute=false },
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Trapped!",                    ranking="D", mountable=false, hasBug=true,  isBestRoute=false },
    { name="Twilight Crypts",       zone="Zul'Aman",    variant="Loosed Loa",                  ranking="F", mountable=false, hasBug=true,  isBestRoute=false },
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
--   2444 = Isle of Quel'Danas  (Parhelion Plaza)
--   2413 = Harandar            (The Grudge Pit, The Gulf of Memory)
--   2405 = Voidstorm           (Shadowguard Point, Sunkiller Sanctum)
--
-- Coordinates verified from in-game map data (March 2026).
-- ============================================================
DelveGuideData.mapPins = {
    -- ── Silvermoon City (2393) ────────────────────────────
    { name="Collegiate Calamity", mapID=2393, x=0.3989, y=0.5359 },  -- verified in-game
    { name="The Darkway",         mapID=2393, x=0.5400, y=0.1800 },  -- north docks, boat (estimate)

    -- ── Zul'Aman (2437) ───────────────────────────────────
    { name="Atal'Aman",           mapID=2437, x=0.2426, y=0.5288 },  -- verified in-game
    { name="Twilight Crypts",     mapID=2437, x=0.2592, y=0.8417 },  -- verified in-game

    -- ── Eversong Woods (2395) ─────────────────────────────
    { name="The Shadow Enclave",  mapID=2395, x=0.4549, y=0.8638 },  -- verified in-game

    -- ── Isle of Quel'Danas (2444) ─────────────────────────
    { name="Parhelion Plaza",     mapID=2444, x=0.4850, y=0.5200 },  -- west of Sunwell (estimate)

    -- ── Harandar (2413) ───────────────────────────────────
    { name="The Grudge Pit",      mapID=2413, x=0.7051, y=0.6535 },  -- verified in-game
    { name="The Gulf of Memory",  mapID=2413, x=0.3666, y=0.4953 },  -- verified in-game

    -- ── Voidstorm (2405) ──────────────────────────────────
    { name="Shadowguard Point",   mapID=2405, x=0.3705, y=0.4880 },  -- verified in-game
    { name="Sunkiller Sanctum",   mapID=2405, x=0.5524, y=0.4741 },  -- verified in-game
}


-- ============================================================
-- SECTION 3: CURIOS
-- ============================================================
DelveGuideData.curios = {
    { name="Porcelain Blade Tip",        description="Chance on hit to apply a crit % debuff (2ppm)",                         curiotype="Combat",  ranking="A" },
    { name="Holy Bounding Hand Grenade", description="On hit damage proc that stuns; can chain proc, low damage (3ppm)",       curiotype="Combat",  ranking="B" },
    { name="Nether Entropic Kris",       description="Chance on hit spreading DOT (1ppm), spread on death with 100ms cd",      curiotype="Combat",  ranking="B" },
    { name="Mantle of Stars",            description="Pseudo cheat death (90 second cd)",                                      curiotype="Combat",  ranking="C" },
    { name="Sanctum's Edict",            description="Tanking curio - underwhelming performance",                              curiotype="Combat",  ranking="F" },
    { name="Mandate of Sacred Death",    description="Valeera gathering grants stacking on-hit %max hp proc; low % execute",   curiotype="Utility", ranking="S" },
    { name="Overflowing Voidspire",      description="Throughput buff after being in combat for 35 seconds (35s cd)",          curiotype="Utility", ranking="A" },
    { name="Ebon Crown of Subjugation",  description="Stacking primary stat buff for opening mislaid curiosities, 12 stacks",  curiotype="Utility", ranking="A" },
    { name="Time Lost Edict",            description="Summons a zone that increases haste, CDR, and speed (30s cd)",           curiotype="Utility", ranking="B" },
    { name="Motionless Nulltide",        description="Grants speed and haste after standing still",                            curiotype="Utility", ranking="C" },
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
    { category="Delver's Journey",  note="Myth Crests from delves become available at lv. 4 Delver's Journey" },
    { category="Delver's Journey",  note="Flickergate equivalent unlocks at lv. 3 Delver's Journey" },
    { category="Delver's Journey",  note="T11 Bountiful Delves can drop hero gear at lv. 9 Delver's Journey" },
    { category="Delver's Journey",  note="Mislaid Curiosities grant stacking buffs when opened (R1 Journey)" },
    { category="Delver's Journey",  note="Trinket vendor sells random gear, unlocked at lv. 5 Delver's Journey" },
    { category="Delver's Journey",  note="Trinket vendor sells hero gear at lv. 8 Delver's Journey" },
    { category="System Change",     note="Nemesis packs are now marked on the map and minimap" },
    { category="System Change",     note="Mislaid Curiosities now have a blue glow" },
    { category="System Change",     note="4 Gilded Stashes per week (up from 3), each has 5 items (down from 7)" },
    { category="System Change",     note="Coffer key shards are now a currency with a weekly cap of 600 (6 keys)" },
    { category="System Change",     note="Puzzles replaced with delve-specific interactables that grant buffs" },
    { category="System Change",     note="Delve Tiers 4+ unlock at level 90 / max level" },
    { category="System Change",     note="Delve Tiers 4-7 can give Adventurer gear" },
    { category="Returning Content", note="Weekly turn-in quest for Delver's Journey is returning in Midnight" },
    { category="Returning Content", note="Cracked Keystone quest returning, awards 15 Hero and Myth crests" },
    { category="Not Returning",     note="Radiant Echoes are NOT returning in Midnight" },
    { category="Not Returning",     note="There is no Ethereal Challenge Room equivalent in Midnight" },
    { category="Release",           note="The Darkway releases week of March 17 (Season 1 launch)" },
    { category="Release",           note="Parhelion Plaza releases week of March 31 (March on Quel'Danas raid)" },
    { category="Preseason Note",    note="During preseason, crests from delves are capped at Adventurer" },
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
