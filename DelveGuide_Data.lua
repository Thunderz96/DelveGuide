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
    { name="Porcelain Blade Tip",        id=251801, description="Chance on hit to apply a crit % debuff (2ppm)",                         curiotype="Combat",  ranking="A" },
    { name="Holy Bounding Hand Grenade", id=251802, description="On hit damage proc that stuns; can chain proc, low damage (3ppm)",       curiotype="Combat",  ranking="B" },
    { name="Nether Entropic Kris",       id=251803, description="Chance on hit spreading DOT (1ppm), spread on death with 100ms cd",      curiotype="Combat",  ranking="B" },
    { name="Mantle of Stars",            id=251804, description="Pseudo cheat death (90 second cd)",                                      curiotype="Combat",  ranking="C" },
    { name="Sanctum's Edict",            id=251805, description="Tanking curio - underwhelming performance",                              curiotype="Combat",  ranking="F" },
    { name="Mandate of Sacred Death",    id=251806, description="Valeera gathering grants stacking on-hit %max hp proc; low % execute",   curiotype="Utility", ranking="S" },
    { name="Overflowing Voidspire",      id=251807, description="Throughput buff after being in combat for 35 seconds (35s cd)",          curiotype="Utility", ranking="A" },
    { name="Ebon Crown of Subjugation",  id=251808, description="Stacking primary stat buff for opening mislaid curiosities, 12 stacks",  curiotype="Utility", ranking="A" },
    { name="Time Lost Edict",            id=251809, description="Summons a zone that increases haste, CDR, and speed (30s cd)",           curiotype="Utility", ranking="B" },
    { name="Motionless Nulltide",        id=251810, description="Grants speed and haste after standing still",                            curiotype="Utility", ranking="C" },
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
    -- ── Labyrinths (Patch 12.1.5 — Autumn 2026) ──────────────
    { category="Labyrinths (12.1.5)", note="Mega-delve content: longer, multi-wing layouts scaled to delve difficulty" },
    { category="Labyrinths (12.1.5)", note="Designed for solo or small group (2-3 player) play" },
    { category="Labyrinths (12.1.5)", note="Expected to use the Coffer Key / shard currency system" },
    { category="Labyrinths (12.1.5)", note="No lockout confirmed — likely repeatable like standard delves" },
    { category="Labyrinths (12.1.5)", note="Difficulty tier structure and Great Vault tracking TBD" },
    { category="Labyrinths (12.1.5)", note="Unique curio interactions distinct from standard delves (unconfirmed)" },
}

-- ============================================================
-- ============================================================
-- SECTION 6: DELVE TIER REWARDS
-- coffer  = Bountiful Coffer base drop ilvl
-- vault   = Great Vault reward ilvl for completing this tier
-- ============================================================
DelveGuideData.tierRewards = {
    [1]  = { coffer=220, vault=233 },
    [2]  = { coffer=224, vault=237 },
    [3]  = { coffer=227, vault=240 },
    [4]  = { coffer=230, vault=243 },
    [5]  = { coffer=233, vault=246 },
    [6]  = { coffer=237, vault=253 },
    [7]  = { coffer=246, vault=256 },
    [8]  = { coffer=250, vault=259 },
    [9]  = { coffer=250, vault=259 },
    [10] = { coffer=250, vault=259 },
    [11] = { coffer=250, vault=259 },
}

-- SECTION 7: SPEC CURIO RECOMMENDATIONS
-- ------------------------------------------------------------
-- Keys are WoW specIDs returned by GetSpecializationInfo().
-- combat / utility = name string matching DelveGuideData.curios entries.
-- companion = recommended Valeera role for that spec.
-- Source: NotebookLM community research (Midnight 12.0.1, March 2026).
-- Update this table after major balance patches.
--
-- NOTE: Sanctum's Edict is rated F in the curio table as a tanking curio,
-- but community data recommends it for some physical DPS specs as a stat
-- stick. The F rating reflects its tanking value; consider revising.
--
-- NEMESIS WARNING: Mandate of Sacred Death procs require profession nodes.
-- Nullaeus (Season 1 Nemesis) arena has NO nodes — swap Mandate specs to
-- Overflowing Voidspire or Ebon Crown of Subjugation for that fight.
--
-- ============================================================
DelveGuideData.specCurioRecs = {
    -- ── Tanks ─────────────────────────────────────────────────
    [250] = { spec="Blood Death Knight",    role="Tank",   companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="High self-sustain but sluggish damage. Sanctum's Edict provides the raw damage boost needed for high-HP elite packs." },
    [73]  = { spec="Protection Warrior",    role="Tank",   companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="Lacks passive self-healing — Healer Valeera mandatory. Ebon Crown scales Shield Block and Ignore Pain values." },
    [66]  = { spec="Protection Paladin",    role="Tank",   companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="Highly competitive damage output. Blade Tip synergizes with Grand Crusader crit resets. Swap Mandate for Nemesis (no nodes)." },
    [104] = { spec="Guardian Druid",        role="Tank",   companion="Damage Dealer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="12.0.1 buffed Maul and Raze, rewarding aggressive stat-scaling. May need Healer Valeera in magic-heavy delves." },
    [268] = { spec="Brewmaster Monk",       role="Tank",   companion="Healer",
              combat="Porcelain Blade Tip",       utility="Ebon Crown of Subjugation",
              notes="Stagger can overwhelm without external healing. Blade Tip crit buffs boost Celestial Fortune procs for self-heals." },
    [581] = { spec="Vengeance Demon Hunter",role="Tank",   companion="Damage Dealer",
              combat="Porcelain Blade Tip",       utility="Mandate of Sacred Death",
              notes="High mobility + 12.0.1 Soul Cleave/Spirit Bomb buffs. Can chain-pull between nodes to abuse Mandate procs. Swap for Nemesis." },
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
              notes="Mandate needed for damage scaling so bosses die before mana exhausts — a common Tier 11 failure point. Swap for Nemesis." },
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
              notes="12.0.1 Psychic Link buffs make them elite AoE clearers. High DoT frequency triggers both curios flawlessly. Swap Mandate for Nemesis." },
    [259] = { spec="Assassination Rogue",   role="DPS",    companion="Healer",
              combat="Sanctum's Edict",          utility="Ebon Crown of Subjugation",
              notes="12.0.1 physical buffs reinforce Ebon Crown as best raw stat amplifier for Bleed damage." },
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
        version = "1.6.2",
        date    = "2026-03-25",
        entries = {
            "Localization: Added Spanish (esES/esMX) variant translations — new language!",
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
            "New Feature: Share to Chat — share today's active variants to Party (left-click) or Guild (right-click) from the Delves tab and compact widget.",
            "New Feature: Completion Timer — live timer on the HUD during delve runs, saved to run history on completion.",
            "New Feature: Victory Screen now displays your completion time.",
            "New Feature: DataBroker text feed — info bar addons (Titan Panel, ElvUI, Bazooka) now show your top active variant and rank.",
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
            "Smart Tier Auto-Detection: The In-Run HUD now automatically detects your Delve tier—no more /dg tier commands!",
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
            "Variant matching uses locale-independent widget set IDs — no English text matching required",
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
            "New command: /dg chatdump — prints full scan results to chat for easy copy-paste sharing",
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
            "New tab: Nullaeus — dedicated Season 1 Nemesis guide",
            "Covers location, unlock requirements, all mechanics (Umbral Rage, Oblivion Shell), phase transitions, recommended setup, tips, and rewards",
            "Includes Beacon of Hope workflow for earning the weekly Bounty without entering Torment's Rise",
        },
    },
    {
        version = "1.3.3",
        date    = "2026-03-17",
        entries = {
            "Tracking Restored Coffer Keys (item 3028) — shown in compact widget, checklist, roster, and Delves tab",
            "Checklist: coffer key check now passes if you have a Restored Coffer Key, even without 100 shards",
            "Roster: restored key count shown next to shard total as +(N)r",
        },
    },
    {
        version = "1.3.2",
        date    = "2026-03-17",
        entries = {
            "Fixed: HUD showing in Zul'Aman overworld (seamless sub-zone name bleeding into detection)",
            "Detection now requires C_Scenario.IsInScenario() — zone name alone is no longer sufficient",
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
            "In-Run HUD — auto-shows when inside a Delve, hides on exit",
            "HUD shows: delve name, active variant + grade, tier, curio rec, nemesis warning, bountiful status",
            "HUD is draggable and remembers its position",
            "/dg hud — toggle the HUD manually (also works as a preview outside of Delves)",
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
            "Waypoint click now sets the pin silently — press M to open your map and navigate",
        },
    },
    {
        version = "1.2.0",
        date    = "2026-03-15",
        entries = {
            "Roster tab — track all level-80+ alts' weekly delves, shards, ilvl, and vault slots",
            "Roster: per-character remove button with confirmation dialog",
            "Fixed: targeting a delve entrance no longer triggers a taint error",
        },
    },
    {
        version = "1.1.0",
        date    = "2026-03-14",
        entries = {
            "Settings tab — minimap, compact widget, tier filter, font scale",
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
            "Initial release — delve rankings, curio DB, loot tables, run history",
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
    [1800] = "Sunkiller Sanctum",
    [1801] = "Shadowguard Point",
    [1802] = "Atal'Aman",
    [1803] = "The Gulf of Memory",
    [1804] = "The Shadow Enclave",
    [1805] = "Twilight Crypts",
}


-- Localized variant name → English variant name.
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

    -- Español (esES / esMX)
    ["Resplandor invasivo"]              = "Invasive Glow",             -- Collegiate Calamity
    ["Concentradores bajo presión"]      = "Focusers Under Pressure",   -- The Darkway
    ["Recompensa de una traición"]       = "Traitor's Due",             -- The Shadow Enclave
    ["Aguafiestas"]                      = "Party Crasher",             -- Twilight Crypts
    ["Aniquilación de tótems"]           = "Totem Annihilation",        -- Atal'Aman
    ["El núcleo del problema"]           = "Core of the Problem",       -- Sunkiller Sanctum
    ["Acecho putrefacto despiadado"]     = "Dastardly Rotstalk",        -- The Grudge Pit
    ["Descenso de los haranir"]          = "Descent of the Haranir",    -- The Gulf of Memory
    ["Maná robado"]                      = "Stolen Mana",              -- Shadowguard Point

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
    ["鏡子發光"] = "Mirror Shine",          	-- The Shadow Enclave
    ["派對破壞者"] = "Party Crasher",           -- Twilight Crypts
    ["受困！"] = "Trapped!", -- Twilight Crypts
    ["失控羅亞"] = "Loosed Loa", -- Twilight Crypts
}