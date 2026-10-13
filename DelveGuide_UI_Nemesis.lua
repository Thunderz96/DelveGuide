local UI = DelveGuide.UI
local L = DelveGuide.L

-- ============================================================
-- NEMESIS TAB
-- One tab slot, refreshed each season: the current season's
-- Nemesis delve gets the full guide treatment, the previous one
-- drops to a compact legacy section (TWW precedent: the old
-- Nemesis delve stays enterable, but seasonal rewards retire).
-- Full Season 1 Nullaeus guide lives in git history:
-- DelveGuide_UI_Nullaeus.lua (v1.7.x).
-- ============================================================

local function Entrance(name)
    for _, e in ipairs(DelveGuideData.nemesisEntrances or {}) do
        if e.name == name then return e end
    end
end

-- Clickable entrance line: same interaction as the Delves tab's name button
-- (click = open map + set waypoint), built from the pooled button so nothing
-- is created per render. The /way text is formatted from the pin, so the
-- coordinate shown and the coordinate you get sent to cannot disagree.
local function CreateEntranceRow(parent, y, pin)
    if not pin then return 0 end
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    local btn = UI.AcquireButton()
    btn:SetSize(parent:GetWidth() - 16, rH)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y)

    local fs = UI.AcquireFontString("OVERLAY")
    fs:SetFont(ROW_FONT, rSize)
    fs:SetPoint("LEFT", btn, "LEFT", 0, 0)
    fs:SetWidth(btn:GetWidth()); fs:SetJustifyH("LEFT")
    fs:SetText(string.format("|cFF888888  /way #%d %g %g|r  |cFF00FF88" .. L["(click)"] .. "|r",
        pin.mapID, pin.x * 100, pin.y * 100))

    btn.pin = pin
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cFFFFD700" .. self.pin.name .. "|r")
        GameTooltip:AddLine("|cFFCCCCCC" .. (self.pin.zone or "") .. "|r")
        GameTooltip:AddLine("|cFF00FF88" .. L["Click to open map & set waypoint"] .. "|r")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", function(self) UI.SetDelveWaypoint(self.pin) end)

    return rH
end

DelveGuide.RenderNemesis = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    -- ========================================================
    -- SEASON 2: VENOMFALL DEEPS (12.1 "Curse of Ula'tek")
    -- Content compiled from Season 2 guides (wowhead/icy-veins/method),
    -- last refreshed 2026-08-16. Confirm mechanics/rewards through play.
    -- ========================================================
    y = y + UI.CreateHeader(cf, y, L["Venomfall Deeps  --  Season 2 Nemesis"]) + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC" .. L["Azta'rec, tied to the Ula'tek storyline. A venom-and-memory fight: survive the poison in the main phase, then nail the Simon-Says quadrant game in each intermission."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Location"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Venomfall Deeps  -  northern Coiled Isle"] .. "|r") + 2
    y = y + CreateEntranceRow(cf, y, Entrance("Venomfall Deeps")) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Unlock Requirements"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Tier ?:"] .. "|r  " .. L["clear any Tier 7 Delve with 1+ life remaining"]) + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Tier ??:"] .. "|r " .. L["clear any Tier 10 Delve with 1+ life remaining"]) + 2
    -- Tooltip verbatim: "Play the Scalebound Herald's Flute, luring the Nemesis to
    -- its location. Only usable after activating an Abandoned Restoration Stone
    -- inside of a Delve. (1 Hour Cooldown)" -- i.e. it SUMMONS him into whatever
    -- delve you are already in. It is not an access item for Venomfall Deeps.
    y = y + 4
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Summon Him Anywhere"] .. "|r  |cFF888888" .. L["(Scalebound Herald's Flute)"] .. "|r") + 4
    -- The emphasised "any" is passed in as the %s, so the colour switch and the
    -- switch back never reach L and a translation can move the word.
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. string.format(L["You do not have to run Venomfall Deeps. The flute lures Azta'rec to you in %s delve, at the mid-delve respawn point."], "|cFFFFD700any|r|cFFCCCCCC") .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  \"" .. L["Play the Scalebound Herald's Flute, luring the Nemesis to its location. Only usable after activating an Abandoned Restoration Stone inside of a Delve. (1 Hour Cooldown)"] .. "\"|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF00FF88  " .. L["Guarantees a Trovehunter's Bounty map"] .. "|r |cFFCCCCCC" .. L["if you have not looted one this week."] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Where to get it: drops from Mislaid Curiosities in delves  -  5,000 Undercoin from Naleidea Rivergleam in Silvermoon City  -  weekly reward from the prey quest \"A Nightmarish Task\"."] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["DelveGuide shows how many you are carrying on the Delves tab, and reminds you on the pre-entry checklist."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Intro Questline"] .. "|r  |cFF888888" .. L["(optional -- toy reward)"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Valeera offers a short chain at the Delver's HQ (lvl 90): Slithering Spoils -> Fangs for the Memories. Not needed to fight Azta'rec, but it grants the Corrosive Victory toy once you beat him on any difficulty."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Main Phase"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Soul Extinction:"] .. "|r " .. L["interruptible cast, ~2M damage -- kick it (Valeera will, if you don't)."]) + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Void Toxin:"] .. "|r " .. L["magic DoT that also cuts your damage by 40% -- dispel it."]) + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Noxious Bile:"] .. "|r " .. L["frontal poison cone -- dodge it; it leaves ground puddles."]) + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Venom Storm:"] .. "|r " .. L["summons waves across the arena -- keep moving."]) + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Serpent's Strike:"] .. "|r " .. L["tank-only tankbuster (fairly mild physical hit)."]) + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["He auto-attacks hard and outruns you, so kiting doesn't work -- surviving is the real test for non-tanks. A tank spec has it easiest (only the mild tankbuster)."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Intermissions  --  Memory Game (90% / 60% / 30%)"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["He goes immune and blasts 3 of the 4 quadrants (one is safe). Sermon of Ula'tek telegraphs the pattern; Echo of Ula'tek then repeats it with NO telegraph -- memorise the safe-spot order, then re-run it."] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Tier ??: the sequence grows each intermission (5 -> 6 -> 7 safe spots), and an Echo of Azta'rec add spawns using his main-phase kit -- kill it before the game ends."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Recommended Setup"] .. "|r") + 4
    -- Same DelveGuideData.specCurioRecs lookup the Companion and Curios tabs
    -- use. This line used to be a hand-written generalisation, which meant the
    -- Nemesis tab could recommend a different Valeera role than the Companion
    -- tab for the same spec.
    local rec = UI.GetSpecRec and UI.GetSpecRec()
    if rec then
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Valeera:"] .. "|r " .. L["run her as"] .. " |cFF00CFFF" .. (rec.companion or "--") .. "|r |cFF888888" .. string.format(L["for your spec (%s)."], rec.spec) .. "|r") + 2
    else
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Valeera:"] .. "|r " .. L["Healer for Tank & DPS specs; DPS Valeera for Healer specs."]) + 2
    end
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Aim for roughly 290 item level for the '?' difficulty."] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Between you and Valeera, cover the Soul Extinction interrupt and the Void Toxin dispel every time."] .. "|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Rewards"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Mistcrests"] .. " |cFF888888" .. L["(uncapped, every kill):"] .. "|r|cFFCCCCCC " .. L["? drops 30 Hero; ?? drops 30 more Hero + Myth."] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Apophic Soul Crusher"] .. " |cFF888888" .. L["(flying mount -- solo ?? kill)"] .. "|r|cFFCCCCCC  -  " .. L["Apophic Patagia"] .. " |cFF888888" .. L["(back -- any difficulty)"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["\"the Poisonous\" title"] .. " |cFF888888" .. L["(?? kill)"] .. "|r|cFFCCCCCC  -  " .. L["Corrosive Victory"] .. " |cFF888888" .. L["(toy -- from the intro questline)"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF8844  " .. L["Time-limited:"] .. "|r |cFFCCCCCC" .. L["Fabled Vanquisher of Azta'rec"] .. "|r |cFF888888" .. L["title -- defeat ?? solo in the first week of Season 2."] .. "|r") + 8

    -- ========================================================
    -- LEGACY: NULLAEUS (Season 1)
    -- CONFIRMED still enterable on 12.1 PTR build 68629
    -- (instanceID 2966, interior map 2507, scenarioID 3289).
    -- Season 2 launched 2026-08-18. Reward status below last
    -- checked against public guides on 2026-09-06: the mount,
    -- helm and title are all reported as Season 1 only, so they
    -- moved to the retired list. Sources agreeing on that:
    --   conquestcapped.com/guides/wow/arcanovoid-construct/
    --     ("Availability: Season 1 only")
    --   method.gg/guides/nullaeus-nemesis-delve-guide-torments-rise
    -- Not yet confirmed in game -- if a Season 2 kill still awards
    -- any of them, move that line back up.
    -- NOTE: C_DelvesUI.HasActiveLair() returns false even while
    -- standing inside the lair (it's seasonal state, NOT an
    -- in-lair check) -- detect Nemesis delves by instanceID.
    -- ========================================================
    y = y + 8
    y = y + UI.CreateHeader(cf, y, L["Legacy: Nullaeus  --  Season 1 Nemesis"]) + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Domanaar, Hand of the Harbinger. No longer seasonally relevant, but Torment's Rise stays open for collectors (as with Zekvir's Lair and Demolition Dome in TWW)."] .. "|r") + 6

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Location:"] .. "|r |cFFCCCCCC" .. L["Torment's Rise - Voidstorm"] .. "|r") + 2
    y = y + CreateEntranceRow(cf, y, Entrance("Torment's Rise")) + 2
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Unlock:"] .. "|r |cFFCCCCCC" .. L["Tier ? = any Tier 7 delve clear / Tier ?? = any Tier 10 clear, with 1+ life remaining"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Summon:"] .. "|r |cFFCCCCCC" .. L["Beacon of Hope - the same item as Season 2's flute, one season earlier: place it after the Restoration Stone in any delve to lure Nullaeus to you (1 hour cooldown)."] .. " |cFFFF8844" .. L["No longer obtainable."] .. "|r") + 6

    -- The dates ride in as arguments: a re-verification pass then edits the date
    -- only, and every existing translation of the caption still applies.
    y = y + UI.CreateRow(cf, y, "|cFF00FF88" .. L["Still obtainable"] .. "|r  |cFF888888" .. string.format(L["(last verified %s)"], "2026-09-06") .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Dominating Victory (toy)  -  a Season 1 questline reward, not tied to a seasonal achievement."] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFFF4444" .. L["No longer obtainable"] .. "|r  |cFF888888" .. string.format(L["(Season 1 only; Season 2 started %s -- last verified %s)"], "2026-08-18", "2026-09-06") .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Arcanovoid Construct (mount, solo Tier ??)  -  Nullaeus Domaneye (cosmetic helm)  -  \"the Ominous\" title (Tier ??)"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Fabled Vanquisher of Nullaeus (first 4,000, ended during Season 1)  -  seasonal Hero Dawncrest bonuses"] .. "|r") + 2

    cf:SetHeight(y + 20)
end
