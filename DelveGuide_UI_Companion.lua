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

-- Shared with the Nemesis tab so the two screens cannot disagree about which
-- Valeera role a spec wants. (The Curios tab still keeps its own copy.)
UI.GetSpecRec = GetSpecRec

-- Auto-discovery for Valeera's reputation/renown track. Caches the hit in
-- SavedVariables so we only scan once per character. "major" = C_MajorFactions
-- (renown track); "rep" = regular reputation bar.
--
-- The name sweep below used to be the ONLY filter, which made this tab
-- English-only: ruRU/zhCN/zhTW/koKR transliterate "Valeera Sanguinar", so
-- nothing ever matched and the renown line never appeared. It was also the
-- expensive path -- three sweeps of 501 pcall'd calls, 1,503 per render -- and
-- a miss was never written anywhere, so every render re-ran the whole thing.
-- Resolution order is now: Blizzard's own resolver, then the known constant,
-- then the sweep as a last resort, with misses cached for the session.
local sweepMissed = false   -- session-only: a /reload retries in case the
                            -- companion track has been unlocked since.

local function CacheFaction(id, ftype)
    if DelveGuideDB then
        DelveGuideDB.companionFactionID = id
        DelveGuideDB.companionFactionType = ftype
    end
    return id, ftype
end

local function FindCompanionFactionID()
    if DelveGuideDB and DelveGuideDB.companionFactionID then
        return DelveGuideDB.companionFactionID, DelveGuideDB.companionFactionType
    end

    -- 1. Blizzard's own resolver -- Blizzard_DelvesCompanionConfiguration.lua
    --    maps the active companion to its faction exactly this way. Locale
    --    independent, and one call instead of 1,503.
    if C_DelvesUI and C_DelvesUI.GetFactionForCompanion and C_DelvesUI.GetCompanionInfoForActivePlayer then
        local ok, id = pcall(function()
            return C_DelvesUI.GetFactionForCompanion(C_DelvesUI.GetCompanionInfoForActivePlayer())
        end)
        if ok and type(id) == "number" and id > 0 then
            return CacheFaction(id, "friendship")
        end
    end

    -- 2. The known constant (Valeera Sanguinar = 2744, confirmed in the 12.1.5
    --    faction sweep). Probed rather than trusted blind, so a season that
    --    moves the companion falls through instead of reporting a dead track.
    local constID = DelveGuideData and DelveGuideData.companionFactionID
    if constID and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, constID)
        if ok and d and d.friendshipFactionID and d.friendshipFactionID > 0 then
            return CacheFaction(constID, "friendship")
        end
    end

    -- 3. Last resort: the English-only name sweep. Only reached when both the
    --    API and the constant fail, and only once per session.
    if sweepMissed then return nil, nil end

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
                return CacheFaction(id, "friendship")
            end
        end
    end

    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        for id = 2600, 3100 do
            local ok, d = pcall(C_MajorFactions.GetMajorFactionData, id)
            if ok and d and nameMatches(d.name) then
                return CacheFaction(id, "major")
            end
        end
    end

    if C_Reputation and C_Reputation.GetFactionDataByID then
        for id = 2600, 3100 do
            local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
            if ok and d and nameMatches(d.name) then
                return CacheFaction(id, "rep")
            end
        end
    end

    sweepMissed = true
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
        
        -- The scrape walks Blizzard's own frame tree, which we don't control: a
        -- forbidden or unexpected child throws, and that error used to abort this
        -- render with the tab half-drawn. Contain it -- whatever the walk read
        -- before it threw is kept, and the rest of the tab still draws from the
        -- API/renown values gathered above.
        local ok, err
        if blizzFrame.CompanionConfigInfo then
            ok, err = pcall(ScrapeUI, blizzFrame.CompanionConfigInfo)
        else
            ok, err = pcall(ScrapeUI, blizzFrame)
        end
        if not ok then DelveGuide.lastScrapeError = err end
    end
    -- 3. Draw Header
    y = y + UI.CreateRow(cf, y, "|cFF00BFFF" .. compName .. "|r  -  Level |cFFFFD700" .. compLevel .. "|r  -  Role: |cFF00FF44" .. roleStr .. "|r") + 6

    -- 4. Draw XP Progress Bar
    local barW = UI.WINDOW_W - 32; local barH = 20
    local xpBg = UI.AcquireTexture("BACKGROUND")
    xpBg:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    xpBg:SetSize(barW, barH); xpBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local xpFill = UI.AcquireTexture("ARTWORK")
    xpFill:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    local fillPct = math.min(1, math.max(0, compXP / compMaxXP))
    xpFill:SetSize(math.max(1, barW * fillPct), barH)
    xpFill:SetColorTexture(0.5, 0.2, 0.9, 0.8)

    local xpBorder = UI.AcquireBackdropFrame()
    xpBorder:SetPoint("TOPLEFT", cf, "TOPLEFT", 6, -(y - 2))
    xpBorder:SetSize(barW + 4, barH + 4)
    xpBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    xpBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local xpText = UI.AcquireFontString("OVERLAY")
    xpText:SetFont(ROW_FONT, rSize)
    xpText:SetPoint("CENTER", xpBg, "CENTER", 0, 0)
    
    if compMaxXP > 1 then
        xpText:SetText(string.format("%d / %d XP  (%.1f%%)", compXP, compMaxXP, fillPct * 100))
    else
        xpText:SetText("|cFF888888XP Data unavailable  -  try /dg companionscan|r")
    end
    y = y + barH + 20

    -- 5. Curio loadout: recommended Valeera role (still valid) plus whatever the
    -- live scan detects equipped. Per-spec S2 curio picks are pending (S1's are
    -- gone), so equipped curios show as info; the Curios tab is the full S2
    -- curio + poison reference.
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Curio Loadout --|r") + 4

    local rec, specID = GetSpecRec()
    if rec then
        y = y + UI.CreateRow(cf, y, "Your Spec: |cFFFFFFFF" .. rec.spec .. "|r  --  Recommended Valeera role: |cFF00CFFF" .. (rec.companion or "--") .. "|r") + 6
    end

    if liveCombat or liveUtility then
        y = y + UI.CreateRow(cf, y, "|cFF00FF88Equipped now:|r  Combat: |cFFFFD700" .. (liveCombat or "--") .. "|r   Utility: |cFFFFD700" .. (liveUtility or "--") .. "|r")
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888Open Blizzard's Companion panel, then reopen this tab to scan your equipped curios.|r")
    end
    y = y + UI.CreateRow(cf, y, "|cFF888888Full Season 2 curio & poison list: the Curios tab.|r") + 4

    -- 6. Poisons (new 12.1 choice node in Valeera's supplies menu -- independent
    -- of her role). Rendered from DelveGuideData.poisons (same as the Curios tab).
    y = y + 8
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Poisons  (new in 12.1) --|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Pick one in Valeera's supplies menu -- independent of her role now.|r") + 6
    for _, p in ipairs(DelveGuideData.poisons or {}) do
        local tag = p.base and "|cFF00FF88[Base] |r" or "|cFFFFD700[Quest]|r"
        y = y + UI.CreateRow(cf, y, string.format("%s |cFFAA66CC%s|r  |cFFCCCCCC%s|r  |cFF888888%s|r", tag, p.name, p.effect, p.use)) + 2
    end
    y = y + UI.CreateRow(cf, y, "|cFF00FF88Rule of thumb:|r |cFFCCCCCCBloodcrypt Toxin is the safe default; Frostheart Venom for defense once unlocked. Forgotten Master loses all stacks when you take damage -- only worth it if you're rarely getting hit.|r") + 4

    cf:SetHeight(y + 20)
end