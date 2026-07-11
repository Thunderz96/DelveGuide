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
    -- Placeholder scaffold -- fill in from PTR testing before
    -- the 12.1 release. Search "TBD" to find every blank.
    -- ========================================================
    y = y + UI.CreateHeader(cf, y, "Venomfall Deeps  --  Season 2 Nemesis  |cFF888888(PTR preview - details TBD)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Azta'rec. Season 2's Nemesis delve, tied to the Zul'jan / Ula'tek storyline. Mechanics and rewards below are placeholders until confirmed on the 12.1 PTR.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Location|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  The Serpent's Tail  -  The Coiled Isle|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  /way #2512 51.2 30.3|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Unlock Requirements|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  TBD  |cFF888888(Season 1 pattern: Tier 7 clear for Tier ?, Tier 10 clear for Tier ??, with 1+ life remaining)|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Boss Mechanics  --  Azta'rec|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  TBD  |cFF888888(catalogue on PTR -- expect a venom/serpent kit)|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Recommended Setup|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  TBD  |cFF888888(companion spec, curios -- also verify arena profession nodes for Mandate builds)|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Rewards|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  TBD  |cFF888888(expect the S1 pattern: cosmetic + title + mount, incl. a time-limited first-clear reward -- flag that one early!)|r") + 8

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

    y = y + UI.CreateRow(cf, y, "|cFF00FF88Still obtainable |cFF888888(pending 12.1 PTR confirmation)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Nullaeus Domaneye (cosmetic helm)  -  Arcanovoid Construct (mount, solo Tier ??)  -  Dominating Victory (toy)  -  \"the Ominous\" title (Tier ??)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFFF4444No longer obtainable|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Fabled Vanquisher of Nullaeus (first 4,000, ended during Season 1)  -  seasonal Hero Dawncrest bonuses|r") + 2

    cf:SetHeight(y + 20)
end
