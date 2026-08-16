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
    -- Content compiled from Season 2 guides (wowhead/icy-veins/method),
    -- last refreshed 2026-08-16. Confirm mechanics/rewards through play.
    -- ========================================================
    y = y + UI.CreateHeader(cf, y, "Venomfall Deeps  --  Season 2 Nemesis") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCCAzta'rec, tied to the Ula'tek storyline. A venom-and-memory fight: survive the poison in the main phase, then nail the Simon-Says quadrant game in each intermission.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Location|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Venomfall Deeps  -  northern Coiled Isle|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  /way #2512 51.2 31.0|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Unlock Requirements|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Tier ?:|r  clear any Tier 7 Delve with 1+ life remaining") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Tier ??:|r clear any Tier 10 Delve with 1+ life remaining") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Intro Questline|r  |cFF888888(optional -- toy reward)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Valeera offers a short chain at the Delver's HQ (lvl 90): Slithering Spoils -> Fangs for the Memories. Not needed to fight Azta'rec, but it grants the Corrosive Victory toy once you beat him on any difficulty.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Main Phase|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Soul Extinction:|r interruptible cast, ~2M damage -- kick it (Valeera will, if you don't).") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Void Toxin:|r magic DoT that also cuts your damage by 40% -- dispel it.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Noxious Bile:|r frontal poison cone -- dodge it; it leaves ground puddles.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Venom Storm:|r summons waves across the arena -- keep moving.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Serpent's Strike:|r tank-only tankbuster (fairly mild physical hit).") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  He auto-attacks hard and outruns you, so kiting doesn't work -- surviving is the real test for non-tanks. A tank spec has it easiest (only the mild tankbuster).|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Intermissions  --  Memory Game (90% / 60% / 30%)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  He goes immune and blasts 3 of the 4 quadrants (one is safe). Sermon of Ula'tek telegraphs the pattern; Echo of Ula'tek then repeats it with NO telegraph -- memorise the safe-spot order, then re-run it.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  Tier ??: the sequence grows each intermission (5 -> 6 -> 7 safe spots), and an Echo of Azta'rec add spawns using his main-phase kit -- kill it before the game ends.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Recommended Setup|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Valeera:|r Healer for Tank & DPS specs; DPS Valeera for Healer specs.") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Aim for roughly 290 item level for the '?' difficulty.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  Between you and Valeera, cover the Soul Extinction interrupt and the Void Toxin dispel every time.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Rewards|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Mistcrests |cFF888888(uncapped, every kill):|r|cFFCCCCCC ? drops 30 Hero; ?? drops 30 more Hero + Myth.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Apophic Soul Crusher |cFF888888(flying mount -- solo ?? kill)|r|cFFCCCCCC  -  Apophic Patagia |cFF888888(back -- any difficulty)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  \"the Poisonous\" title |cFF888888(?? kill)|r|cFFCCCCCC  -  Corrosive Victory |cFF888888(toy -- from the intro questline)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF8844  Time-limited:|r |cFFCCCCCCFabled Vanquisher of Azta'rec|r |cFF888888title -- defeat ?? solo in the first week of Season 2.|r") + 8

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
