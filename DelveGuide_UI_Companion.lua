-- ============================================================
-- DelveGuide_UI_Companion.lua
-- ============================================================
local UI = DelveGuide.UI

local function GetSpecRec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    local specID = select(1, GetSpecializationInfo(idx))
    if not specID then return nil end
    return DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID], specID
end

-- Auto-discovery for Valeera's reputation/renown track. Caches the hit in
-- SavedVariables so we only scan once per character. "major" = C_MajorFactions
-- (renown track); "rep" = regular reputation bar.
local function FindCompanionFactionID()
    if DelveGuideDB and DelveGuideDB.companionFactionID then
        return DelveGuideDB.companionFactionID, DelveGuideDB.companionFactionType
    end

    local function nameMatches(n)
        if not n then return false end
        return n:find("Valeera") or n:find("Sanguinar")
    end

    -- Friendship factions (Valeera / Brann-style companion tracks) match first,
    -- since the underlying reputation API would also match but returns the
    -- wrong (1-8 reaction) level.
    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        for id = 2600, 3100 do
            local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, id)
            if ok and d and d.friendshipFactionID and d.friendshipFactionID > 0 and nameMatches(d.name) then
                if DelveGuideDB then
                    DelveGuideDB.companionFactionID = id
                    DelveGuideDB.companionFactionType = "friendship"
                end
                return id, "friendship"
            end
        end
    end

    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        for id = 2600, 3100 do
            local ok, d = pcall(C_MajorFactions.GetMajorFactionData, id)
            if ok and d and nameMatches(d.name) then
                if DelveGuideDB then
                    DelveGuideDB.companionFactionID = id
                    DelveGuideDB.companionFactionType = "major"
                end
                return id, "major"
            end
        end
    end

    if C_Reputation and C_Reputation.GetFactionDataByID then
        for id = 2600, 3100 do
            local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
            if ok and d and nameMatches(d.name) then
                if DelveGuideDB then
                    DelveGuideDB.companionFactionID = id
                    DelveGuideDB.companionFactionType = "rep"
                end
                return id, "rep"
            end
        end
    end
    return nil, nil
end

-- Renown can live in three different APIs depending on the faction type:
--   major      -- C_MajorFactions (e.g. Dornogal renown)
--   friendship -- C_GossipInfo.GetFriendshipReputation (Brann, Valeera style,
--                 80-level XP track with a rankInfo.currentLevel)
--   rep        -- plain reputation (Hated..Exalted, 1-8 reaction)
-- Companion tracks (Valeera Sanguinar = faction 2744) are friendship-style,
-- so QueryFriendship must be tried FIRST -- the plain reputation API also
-- returns data for these factions, but reports reaction=8 (Exalted) instead
-- of the real 80-level rank.

local function QueryFriendship(id)
    if not (C_GossipInfo and C_GossipInfo.GetFriendshipReputation) then return nil end
    local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, id)
    if not (ok and d and d.friendshipFactionID and d.friendshipFactionID > 0) then return nil end

    local floor   = d.reactionThreshold or 0
    local ceil    = d.nextThreshold or (floor + 1)
    local cur     = (d.standing or floor) - floor
    local max     = math.max(1, ceil - floor)

    -- Level extraction: companion-style friendships (e.g. Valeera 2744) don't
    -- populate d.rankInfo.currentLevel. The rank number lives in d.reaction
    -- as a localised string like "Level 38", with d.text mirroring it
    -- ("Valeera Sanguinar reached Level 38."). Try the structured field first
    -- for forward compatibility, then pattern-match the strings.
    local level = 0
    if d.rankInfo and d.rankInfo.currentLevel then
        level = d.rankInfo.currentLevel
    elseif type(d.reaction) == "string" then
        level = tonumber(d.reaction:match("(%d+)")) or 0
    end
    if level == 0 and type(d.text) == "string" then
        level = tonumber(d.text:match("(%d+)")) or 0
    end

    return {
        level     = level,
        current   = cur,
        max       = max,
        name      = (d.name and d.name ~= "") and d.name or nil,
        factionID = id,
        ftype     = "friendship",
    }
end

local function QueryMajor(id)
    if not (C_MajorFactions and C_MajorFactions.GetMajorFactionData) then return nil end
    local ok, d = pcall(C_MajorFactions.GetMajorFactionData, id)
    if ok and d and d.name and d.name ~= "" then
        return {
            level     = d.renownLevel or 0,
            current   = d.renownReputationEarned or 0,
            max       = (d.renownLevelThreshold and d.renownLevelThreshold > 0)
                         and d.renownLevelThreshold or 1,
            name      = d.name,
            factionID = id,
            ftype     = "major",
        }
    end
end

local function QueryRep(id)
    if not (C_Reputation and C_Reputation.GetFactionDataByID) then return nil end
    local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
    if ok and d and d.name and d.name ~= "" then
        local floor = d.currentReactionThreshold or 0
        local ceil  = d.nextReactionThreshold or (floor + 1)
        local cur   = (d.currentStanding or floor) - floor
        local max   = math.max(1, ceil - floor)
        return {
            level     = d.reaction or 0,
            current   = cur,
            max       = max,
            name      = d.name,
            factionID = id,
            ftype     = "rep",
        }
    end
end

local function GetCompanionRenown()
    local id, ftype = FindCompanionFactionID()
    if not id then return nil end

    -- Try friendship FIRST -- it returns nil for non-friendship factions, so
    -- it's a harmless probe, but it's the only API that exposes the 80-level
    -- companion XP track for Valeera.
    local result = QueryFriendship(id)
    if not result then
        if ftype == "rep" then
            result = QueryRep(id) or QueryMajor(id)
        else
            result = QueryMajor(id) or QueryRep(id)
        end
    end

    if result and DelveGuideDB and result.ftype ~= ftype then
        DelveGuideDB.companionFactionType = result.ftype
    end
    return result
end

DelveGuide.RenderCompanion = function()
    local cf = UI.NewContentFrame()
    local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, "Companion  --  XP, Role & Live Curio Loadout") + 8

    -- 1. Fetch initial API Data
    local compID = nil
    local compName = "Companion"
    local compLevel, compXP, compMaxXP = 0, 0, 1
    local roleStr = "Unknown"

    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            compID = C_DelvesUI.GetCompanionInfoForActivePlayer()
        end
        if compID and compID > 0 then
            compName = (compID == 11) and "Valeera Sanguinar" or "Companion"
            if C_DelvesUI.GetCompanionInfo then
                local info = C_DelvesUI.GetCompanionInfo(compID)
                if info then
                    compLevel = info.level or 0
                    compXP = info.experience or 0
                    compMaxXP = info.maxExperience or 1
                end
            end
        end
    end)

    -- Prefer faction/renown data when available -- works outside of delves,
    -- unlike C_DelvesUI.GetCompanionInfo which is only populated in-instance.
    local renown = GetCompanionRenown()
    if renown then
        compLevel  = renown.level
        compXP     = renown.current
        compMaxXP  = renown.max
        if renown.name and renown.name ~= "" then compName = renown.name end
        if not compID or compID == 0 then compID = 11 end
    end

-- 2. UI SCRAPING! (Bypasses API restrictions outside of Delves)
    local liveCombat, liveUtility
    local foundRole = false -- Flag to prevent overwriting the role

    local function ScrapeUI(frame)
        if not frame or frame:IsForbidden() then return end
        
        local fName = frame:GetName() or ""
        if fName:find("ScrollBox") or fName:find("DropDownList") then return end
        
        -- Scan all text on the frame
        for _, r in ipairs({frame:GetRegions()}) do
            if r:GetObjectType() == "FontString" and r:IsShown() then
                local txt = r:GetText()
                if txt and txt ~= "" then
                    local cleanTxt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                    
                    -- Detect Role (Lock in the FIRST match)
                    if not foundRole and (cleanTxt == "Healer" or cleanTxt == "DPS" or cleanTxt == "Damage Dealer" or cleanTxt == "Tank") then
                        roleStr = cleanTxt
                        foundRole = true
                    end
                    
                    -- Detect Level (Lock in the FIRST match)
                    local num = tonumber(cleanTxt)
                    if num and num > 0 and num < 100 then
                        if compLevel == 0 then compLevel = num end
                    end
                    
                    -- Detect Curios (Lock in the FIRST match for each type)
                    if DelveGuideData and DelveGuideData.curios then
                        for _, c in ipairs(DelveGuideData.curios) do
                            if cleanTxt == c.name then
                                if c.curiotype == "Combat" and not liveCombat then 
                                    liveCombat = c.name 
                                end
                                if c.curiotype == "Utility" and not liveUtility then 
                                    liveUtility = c.name 
                                end
                            end
                        end
                    end
                end
            end
        end
        -- Recurse through allowed child frames
        for _, child in ipairs({frame:GetChildren()}) do
            ScrapeUI(child)
        end
    end

    -- Trigger the scrape if the Blizzard UI is open
    local blizzFrame = _G["DelvesCompanionConfigurationFrame"]
    if blizzFrame and blizzFrame:IsShown() then
        if not compID or compID == 0 then compID = 11; compName = "Valeera Sanguinar" end
        
        if blizzFrame.CompanionConfigInfo then
            ScrapeUI(blizzFrame.CompanionConfigInfo)
        else
            ScrapeUI(blizzFrame)
        end
    end
    -- 3. Draw Header
    y = y + UI.CreateRow(cf, y, "|cFF00BFFF" .. compName .. "|r  -  Level |cFFFFD700" .. compLevel .. "|r  -  Role: |cFF00FF44" .. roleStr .. "|r") + 6

    -- 4. Draw XP Progress Bar
    local barW = UI.WINDOW_W - 32; local barH = 20
    local xpBg = cf:CreateTexture(nil, "BACKGROUND")
    xpBg:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    xpBg:SetSize(barW, barH); xpBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local xpFill = cf:CreateTexture(nil, "ARTWORK")
    xpFill:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    local fillPct = math.min(1, math.max(0, compXP / compMaxXP))
    xpFill:SetSize(math.max(1, barW * fillPct), barH)
    xpFill:SetColorTexture(0.5, 0.2, 0.9, 0.8)

    local xpBorder = CreateFrame("Frame", nil, cf, "BackdropTemplate")
    xpBorder:SetPoint("TOPLEFT", cf, "TOPLEFT", 6, -(y - 2))
    xpBorder:SetSize(barW + 4, barH + 4)
    xpBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    xpBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local xpText = cf:CreateFontString(nil, "OVERLAY")
    xpText:SetFont(ROW_FONT, rSize)
    xpText:SetPoint("CENTER", xpBg, "CENTER", 0, 0)
    
    if compMaxXP > 1 then
        xpText:SetText(string.format("%d / %d XP  (%.1f%%)", compXP, compMaxXP, fillPct * 100))
    else
        xpText:SetText("|cFF888888XP Data unavailable  -  try /dg companionscan|r")
    end
    y = y + barH + 20

    -- 5. Live Curio Warnings
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Live Curio Loadout --|r") + 4

    local rec, specID = GetSpecRec()
    if not rec then
        y = y + UI.CreateRow(cf, y, "|cFF888888Could not detect player spec for curio recommendations.|r")
    else
        y = y + UI.CreateRow(cf, y, "Your Spec: |cFFFFFFFF" .. rec.spec .. "|r  |cFF888888(specID " .. specID .. ")|r") + 6

        y = y + UI.CreateRow(cf, y, "|cFF00FF88Recommended Loadout:|r")
        y = y + UI.CreateRow(cf, y, "  Combat:  |cFFFFD700" .. rec.combat .. "|r")
        y = y + UI.CreateRow(cf, y, "  Utility: |cFFFFD700" .. rec.utility .. "|r")
        y = y + 8

        y = y + UI.CreateRow(cf, y, "|cFFFF4444Live Equipment Check:|r")
        
        if liveCombat or liveUtility then
            -- We found data! Run the comparisons.
            local cMatch = (liveCombat == rec.combat)
            local uMatch = (liveUtility == rec.utility)
            
            if cMatch and uMatch then
                y = y + UI.CreateRow(cf, y, "|cFF00FF44 Perfect! You have the recommended curios equipped.|r")
            else
                if not cMatch and liveCombat then
                    y = y + UI.CreateRow(cf, y, "|cFFFF4444[!] Warning:|r You have |cFFFF8800[" .. liveCombat .. "]|r equipped. Recommended: [" .. rec.combat .. "].")
                end
                if not uMatch and liveUtility then
                    y = y + UI.CreateRow(cf, y, "|cFFFF4444[!] Warning:|r You have |cFFFF8800[" .. liveUtility .. "]|r equipped. Recommended: [" .. rec.utility .. "].")
                end
            end
        else
            -- We didn't find data because the window is closed
            y = y + UI.CreateRow(cf, y, "|cFF888888Open the Companion panel and click this tab again to scan active curios.|r")
        end
    end

    cf:SetHeight(y + 20)
end