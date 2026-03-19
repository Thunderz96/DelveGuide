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
    
    y = y + UI.CreateHeader(cf, y, "DEBUG -- Variant Detection Results") + 4
    y = y + UI.CreateRow(cf, y, "|cFFFFFF00/dg scan refreshes results  |  /dg chatdump prints all data to chat|r") + 8

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