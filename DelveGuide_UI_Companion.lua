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

DelveGuide.RenderCompanion = function()
    local cf = UI.NewContentFrame()
    local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, "Companion  —  XP, Role & Live Curio Loadout") + 8

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
    y = y + UI.CreateRow(cf, y, "|cFF00BFFF" .. compName .. "|r  —  Level |cFFFFD700" .. compLevel .. "|r  —  Role: |cFF00FF44" .. roleStr .. "|r") + 6

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
        xpText:SetText("|cFF888888XP Data requires entering a delve|r")
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