local UI = DelveGuide.UI

-- ============================================================
-- NEMESIS TAB
-- One tab slot, refreshed each season: the current season's
-- Nemesis delve gets the full guide treatment, the previous one
-- drops to a compact legacy section (TWW precedent: the old
-- Nemesis delve stays enterable, but seasonal rewards retire).
-- Full Season 1 Nullaeus guide lives in git history:
-- DelveGuide_UI_Nullaeus.lua (v1.7.x).
-- ============================================================

DelveGuide.RenderNemesis = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    -- ========================================================
    -- SEASON 2: VENOMFALL DEEPS (12.1 "Curse of Ula'tek")
    -- Content compiled from Season 2 launch guides (2026-08-11).
    -- Confirm mechanics/rewards through play; refine in 1.8.x.
    -- ========================================================
    y = y + UI.CreateHeader(cf, y, "Venomfall Deeps  --  Season 2 Nemesis") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCCAzta'rec, tied to the Ula'tek storyline. A venom-and-memory fight: survive the poison, interrupt the big cast, and remember the safe zones.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Location|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  The Serpent's Tail  -  The Coiled Isle|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  /way #2512 51.2 30.3|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Unlock Requirements|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Tier ?:|r  clear any Tier 7 Delve with 1+ life remaining") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Tier ??:|r clear any Tier 10 Delve with 1+ life remaining  |cFF888888(opens with Season 2, Aug 18)|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Boss Mechanics  --  Azta'rec|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Sermon of Ula'tek |cFF888888(signature):|r|cFFCCCCCC splits the arena into four sections and flashes the safe zones, then repeats them with no visual guide -- memorise the pattern. Tier ?? extends it to five.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Soul Extinction:|r interruptible -- top interrupt priority; huge damage if it lands.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Noxious Bile:|r frontal poison cone that drops lingering ground pools -- don't point it at yourself.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Void Toxin:|r stacking magic DoT that also cuts your damage -- dispel it.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Venom Storm:|r slow poison waves cross the arena -- keep moving.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Serpent's Strike:|r heavy physical melee hit.") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  Three intermissions; Tier ?? adds an Echo of Azta'rec that copies his abilities.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Recommended Setup|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Healer Valeera is the safe pick -- her sustain covers the melee/poison pressure and she helps dispel Void Toxin. DPS Valeera only if you self-heal and dispel well.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  Save your interrupt for Soul Extinction. Curios that rely on profession nodes may be dead here (as in the S1 arena) -- swap to Overflowing Voidspire / Ebon Crown if so.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Rewards|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Apophic Soul Crusher |cFF888888(mount -- solo Tier ?? kill)|r|cFFCCCCCC  -  Apophic Patagia |cFF888888(back)|r|cFFCCCCCC  -  Corrosive Victory |cFF888888(toy)|r|cFFCCCCCC  -  \"the Poisonous\" title |cFF888888(Tier ??)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF8844  Time-limited:|r |cFFCCCCCCFabled Vanquisher of Azta'rec|r |cFF888888-- opening-season solo challenge (Fabled Let Me Solo Him). Grab it early; the S1 version ended mid-season.|r") + 8

    -- ========================================================
    -- LEGACY: NULLAEUS (Season 1)
    -- CONFIRMED still enterable on 12.1 PTR build 68629
    -- (instanceID 2966, interior map 2507, scenarioID 3289).
    -- Which rewards survive is a Season-2-flip question -- check
    -- at S2 launch, then correct the two reward lines below.
    -- NOTE: C_DelvesUI.HasActiveLair() returns false even while
    -- standing inside the lair (it's seasonal state, NOT an
    -- in-lair check) -- detect Nemesis delves by instanceID.
    -- ========================================================
    y = y + 8
    y = y + UI.CreateHeader(cf, y, "Legacy: Nullaeus  --  Season 1 Nemesis") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Domanaar, Hand of the Harbinger. No longer seasonally relevant, but Torment's Rise stays open for collectors (as with Zekvir's Lair and Demolition Dome in TWW).|r") + 6

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Location:|r |cFFCCCCCCTorment's Rise - Voidstorm   |cFF888888/way #2405 61.17 71.37|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Unlock:|r |cFFCCCCCCTier ? = any Tier 7 delve clear / Tier ?? = any Tier 10 clear, with 1+ life remaining|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Skip:|r |cFFCCCCCCBeacon of Hope (5,000 Undercoins, Naleidea Rivergleam at Delver's HQ) - use in any delve past the checkpoint, burn to 50%|r") + 6

    y = y + UI.CreateRow(cf, y, "|cFF00FF88Still obtainable |cFF888888(Season 1 rewards; some may retire under Season 2 -- check before grinding)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Nullaeus Domaneye (cosmetic helm)  -  Arcanovoid Construct (mount, solo Tier ??)  -  Dominating Victory (toy)  -  \"the Ominous\" title (Tier ??)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFFF4444No longer obtainable|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Fabled Vanquisher of Nullaeus (first 4,000, ended during Season 1)  -  seasonal Hero Dawncrest bonuses|r") + 2

    cf:SetHeight(y + 20)
end
