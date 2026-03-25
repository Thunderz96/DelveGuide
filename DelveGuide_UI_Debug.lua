-- ============================================================
-- DelveGuide_UI_Debug.lua
-- ============================================================
local UI = DelveGuide.UI

local ALL_ZONE_MAP_IDS = { 2393, 2437, 2395, 2444, 2413, 2405 }
local ZONE_NAMES = {
    [2393] = "Silvermoon City",   [2437] = "Zul'Aman",
    [2395] = "Eversong Woods",    [2444] = "Isle of Quel'Danas",
    [2413] = "Harandar",          [2405] = "Voidstorm",
}

DelveGuide.RenderDebug = function()
    local cf = UI.NewContentFrame()
    local y = 10
    
    y = y + UI.CreateHeader(cf, y, "DEBUG  —  System Health & Diagnostics") + 4
    
    -- 1. Commands Section
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Troubleshooting Commands|r") + 4
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg scan|r  —  Force refresh map POI detection")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg chatdump|r  —  Print POI data to chat (for localization reports)")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg specinfo|r  —  Print detected spec ID and curio recommendations")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg checkdebug|r  —  Print raw Valeera role/aura data to chat")
    y = y + 8

    -- 2. Database & State Section
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Database & Environment|r") + 4
    local rCount, hCount = 0, 0
    if DelveGuideDB then
        if DelveGuideDB.roster then for _ in pairs(DelveGuideDB.roster) do rCount = rCount + 1 end end
        if DelveGuideDB.history then hCount = #DelveGuideDB.history end
    end
    y = y + UI.CreateRow(cf, y, string.format("  |cFFCCCCCCSavedVariables:|r  %d characters in Roster  |  %d runs in History", rCount, hCount))
    
    local inDelve = DelveGuide.inDelveInstance and "|cFF00FF44True|r" or "|cFFFF4444False|r"
    y = y + UI.CreateRow(cf, y, "  |cFFCCCCCCIn Delve Instance (Internal Flag):|r  " .. inDelve)
    
    local compID = "nil"
    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            local id = C_DelvesUI.GetCompanionInfoForActivePlayer()
            if id then compID = tostring(id) end
        end
    end)
    y = y + UI.CreateRow(cf, y, "  |cFFCCCCCCCompanion API Active ID:|r  |cFF00CFFF" .. compID .. "|r  |cFF888888(If 0/nil outside a delve, UI Scraping is active)|r")
    y = y + 12

    -- 3. Variant Detection Summary
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Map ID Scan Status --|r") + 4
    
    local rawScanResults = DelveGuide.rawScanResults or {}
    local activeVariants = DelveGuide.activeVariants or {}
    
    if #rawScanResults == 0 then
        y = y + UI.CreateRow(cf, y, "|cFFFF4444No results at all -- /dg scan has not been run, or all map IDs returned empty.|r")
        y = y + UI.CreateRow(cf, y, "|cFFAAAAAA  Checked map IDs: " .. table.concat(ALL_ZONE_MAP_IDS, ", ") .. "|r")
    else
        for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
            local found, total = 0, 0
            for _, r in ipairs(rawScanResults) do
                if r.mapID == mapID then
                    total = total + 1
                    if r.name ~= "" and not r.name:find("returned") then found = found + 1 end
                end
            end
            local col = found > 0 and "|cFF44FF44" or "|cFFFF4444"
            local label = ZONE_NAMES[mapID] or ("mapID " .. mapID)
            y = y + UI.CreateRow(cf, y, string.format("  %smapID %-6d  %-20s  %d POI(s)|r", col, mapID, label, found))
        end
    end

    y = y + 8

    -- 3b. Missing Translations Log
    local missing = DelveGuideDB and DelveGuideDB.missingTranslations or {}
    local missingCount = 0
    for _ in pairs(missing) do missingCount = missingCount + 1 end
    if missingCount > 0 then
        y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Missing Translations (" .. missingCount .. ") --|r") + 4
        y = y + UI.CreateRow(cf, y, "|cFFAAAAAA  These variants were detected but have no entry in localeVariants.|r")
        y = y + UI.CreateRow(cf, y, "|cFFAAAAAA  Run /dg chatdump and share the output on CurseForge to help!|r") + 4
        for _, entry in pairs(missing) do
            y = y + UI.CreateRow(cf, y, string.format("  |cFFFF8844[%s]|r  |cFFCCCCCC%s|r  |cFF888888(delve: %s, first seen: %s)|r",
                entry.locale or "?", entry.text or "?", entry.delve or "?", entry.firstSeen or "?"))
        end
        y = y + 4
        local clearBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
        clearBtn:SetSize(160, 20)
        clearBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
        clearBtn:SetText("Clear Missing Log")
        clearBtn:SetScript("OnClick", function()
            DelveGuideDB.missingTranslations = {}
            DelveGuideDB.missingNotified = nil
            UI.RefreshCurrentTab()
        end)
        y = y + 28
    else
        y = y + UI.CreateRow(cf, y, "|cFF44FF44No missing translations detected.|r") + 4
    end

    -- 4. Raw Per-Delve Data Dump
    if #rawScanResults > 0 then
        local vc = 0
        for _ in pairs(activeVariants) do vc = vc + 1 end
        local vcColor = vc > 0 and "|cFF44FF44" or "|cFFFF4444"
        
        y = y + UI.CreateRow(cf, y, string.format("%s%d variant(s) matched today:|r", vcColor, vc))
        if vc == 0 then
            y = y + UI.CreateRow(cf, y, "|cFFFF4444  No variants matched. On non-English clients, widget text will be localized.|r")
            y = y + UI.CreateRow(cf, y, "|cFFAAAAAA  Use /dg chatdump and share output to help add localization support.|r")
        else
            for v in pairs(activeVariants) do 
                y = y + UI.CreateRow(cf, y, "|cFF44FF44  + " .. v .. "|r") 
            end
        end

        y = y + 8
        y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Raw Per-Delve Data --|r")
        
        for _, r in ipairs(rawScanResults) do
            y = y + 4
            local isErr = r.name == "" or r.name:find("returned")
            local nColor = isErr and "|cFFFF4444" or "|cFFFFD700"
            local vColor = (r.variantName == "(not found)" or r.variantName == "(nil)") and "|cFFFF4444" or "|cFF44FF44"
            
            y = y + UI.CreateRow(cf, y, string.format("%s%-26s|r  set=%-6s  -> %s%s|r", nColor, r.name, r.widgetSetID, vColor, r.variantName))
            y = y + UI.CreateRow(cf, y, string.format("   |cFF666666atlas:|r |cFFAAAAAA%s|r", r.atlasName ~= "" and r.atlasName or "(none)"))
            
            if r.widgetTexts and #r.widgetTexts > 0 then
                for _, t in ipairs(r.widgetTexts) do 
                    y = y + UI.CreateRow(cf, y, "   |cFF888888> " .. t .. "|r") 
                end
            else
                y = y + UI.CreateRow(cf, y, "   |cFF555555(no widget texts)|r")
            end
        end
    end
    cf:SetHeight(y + 20)
end