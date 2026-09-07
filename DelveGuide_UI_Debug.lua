-- ============================================================
-- DelveGuide_UI_Debug.lua
-- ============================================================
local UI = DelveGuide.UI

-- Shared with the scanner. This file used to keep its own copy, which was
-- never updated for Season 2 -- so The Coiled Isle (2512/2537) never appeared
-- in the scan-status list even though the scanner was checking it.
local ALL_ZONE_MAP_IDS = DelveGuideData.zoneMapIDs
local ZONE_NAMES       = DelveGuideData.zoneNames

DelveGuide.RenderDebug = function()
    local cf = UI.NewContentFrame()
    local y = 10
    
    y = y + UI.CreateHeader(cf, y, "DEBUG  --  System Health & Diagnostics") + 4

    -- 1. Commands Section
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Troubleshooting Commands|r") + 4
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg scan|r  -  Force refresh map POI detection")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg chatdump|r  -  Print POI data to chat (for localization reports)")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg specinfo|r  -  Print detected spec ID and curio recommendations")
    y = y + UI.CreateRow(cf, y, "  |cFFFFFF00/dg checkdebug|r  -  Print raw Valeera role/aura data to chat")
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
        -- A map with 0 POIs is NOT an error: overview maps carry none, and a
        -- delve only registers on one map even when several overlap (the
        -- scanner dedupes by POI id). Only a total of 0 across every map means
        -- something is actually broken, so don't paint individual zeroes red.
        local grandTotal = 0
        for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
            local found = 0
            for _, r in ipairs(rawScanResults) do
                if r.mapID == mapID then
                    if r.name ~= "" and not r.name:find("returned") then found = found + 1 end
                end
            end
            grandTotal = grandTotal + found
            local col = found > 0 and "|cFF44FF44" or "|cFF777777"
            local label = ZONE_NAMES[mapID] or ("mapID " .. mapID)
            local note  = found == 0 and "  |cFF666666(none registered here)|r" or ""
            y = y + UI.CreateRow(cf, y, string.format("  %smapID %-6d  %-20s  %d POI(s)|r%s", col, mapID, label, found, note))
        end
        local totalCol = grandTotal > 0 and "|cFF44FF44" or "|cFFFF4444"
        y = y + UI.CreateRow(cf, y, string.format("  %sTotal delve POIs found: %d|r", totalCol, grandTotal))
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
        local clearBtn = UI.AcquirePanelButton()
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

-- ============================================================
-- DEBUG SLASH COMMANDS
--
-- Appended to the table DelveGuide.lua builds. The .toc loads that file
-- first, so the table exists by the time this runs; dispatch happens at
-- runtime, long after both files are in. Every body here was moved verbatim
-- out of the old if/elseif chain -- these are diagnostics printed into chat,
-- and they belong next to the Debug tab that documents them rather than in
-- the middle of the main file.
-- ============================================================

-- Substring search over the delve POIs of a range of map IDs. This started
-- life as /dg findplaza, which matched the English literal "Parhelion" and so
-- found nothing at all on a non-English client -- the one situation where a
-- "why is this delve missing from Active Today" hunt is most likely to be
-- needed. Taking the text as an argument fixes that and costs nothing.
--
-- The needle arrives already lowercased by the dispatcher and the POI name is
-- lowercased here, so the match is case-insensitive; non-ASCII bytes pass
-- through unchanged on both sides, so a pasted localized name still matches.
local function FindPOI(needle)
    if needle == "" then
        print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg findpoi <text>|r  -- e.g. |cFFFFFF00/dg findpoi parhelion|r")
        return
    end
    print(string.format("|cFF00BFFF[DelveGuide]|r Scanning map IDs 2200-2700 for POIs matching [%s]...", needle))
    local found = 0
    for mapID = 2200, 2700 do
        local ok, poiIDs = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
        if ok and poiIDs and #poiIDs > 0 then
            for _, poiID in ipairs(poiIDs) do
                local okInfo, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
                if okInfo and info and info.name and string.find(info.name:lower(), needle, 1, true) then
                    print(string.format("|cFF44FF44FOUND: mapID=%d poiID=%d name=[%s] set=%s|r",
                        mapID, poiID, info.name, tostring(info.tooltipWidgetSet or 0)))
                    found = found + 1
                end
            end
        end
    end
    print(string.format("|cFF00BFFF[DelveGuide]|r Scan complete. Found %d matching POI(s).", found))
    if found == 0 then
        print("|cFFFF4444No match in 2200-2700. The POI may be exposed only while its delve is in rotation, or live on an unusual map ID.|r")
    end
end

-- Every entry below is debug = true; the loop stamps it once rather than
-- having it repeated ten times. The loop variable is `cmd`, not `c`, because
-- one of the handlers uses `c` as a local for a colour code.
for _, cmd in ipairs({
    {
        name = "dump",
        desc = "Dump every raw POI field for the first delves found",
        handler = function()
            print("|cFF00BFFF[DelveGuide]|r === RAW POI FIELD DUMP ===")
            local found=0
            for _,mapID in ipairs(ALL_ZONE_MAP_IDS) do
                local poiIDs=C_AreaPoiInfo.GetDelvesForMap(mapID)
                if poiIDs and #poiIDs>0 then
                    local info=C_AreaPoiInfo.GetAreaPOIInfo(mapID,poiIDs[1])
                    print(string.format("|cFFFFD700mapID=%-6d  poiID=%d|r",mapID,poiIDs[1]))
                    if info then
                        for k,v in pairs(info) do
                            local vs=tostring(v); local c=(vs=="" or vs=="false" or vs=="0") and "|cFF888888" or "|cFF44FF44"
                            print(string.format("  |cFFCCCCCC%-22s|r = %s%s|r",tostring(k),c,vs))
                        end; found=found+1
                    else print("  |cFFFF4444(nil)|r") end
                    if found>=2 then break end
                end
            end
            if found==0 then print("|cFFFF4444No delves found.|r") end
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "chatdump",
        desc = "Print POI data to chat (for localization reports)",
        handler = function()
            -- Same binding RenderDebug uses above: the scanner rebuilds this
            -- table on every scan and re-publishes it, and it is absent until
            -- the first scan runs -- which is exactly the "no scan data" case
            -- reported below.
            local rawScanResults = DelveGuide.rawScanResults or {}
            print("|cFF00BFFF[DelveGuide]|r === LOCALIZATION DUMP (share this output) ===")
            print("Version: "..DelveGuide.ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
            if #rawScanResults==0 then
                print("|cFFFF4444No scan data. Run /dg scan first.|r")
                print("Checked map IDs: "..table.concat(ALL_ZONE_MAP_IDS,", "))
            else
                for _,r in ipairs(rawScanResults) do
                    print(string.format("mapID=%s  poiID=%s  name=[%s]  atlas=[%s]  set=%s",
                        tostring(r.mapID),tostring(r.poiID),tostring(r.name),tostring(r.atlasName),tostring(r.widgetSetID)))
                    if r.widgetTexts and #r.widgetTexts>0 then
                        for i,t in ipairs(r.widgetTexts) do
                            print(string.format("  text[%d]=[%s]",i,t))
                        end
                    else
                        print("  (no widget texts)")
                    end
                end
            end
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "huddump",
        desc = "Print zone/instance/scenario state the HUD reads",
        handler = function()
            print("|cFF00BFFF[DelveGuide]|r === HUD DEBUG DUMP (share this output) ===")
            print("Version: "..DelveGuide.ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
            -- Zone info
            local zone = ""; pcall(function() zone = GetRealZoneText() or "" end)
            print("GetRealZoneText: ["..zone.."]")
            -- Instance info
            pcall(function()
                local name, instType, diffID, diffName = GetInstanceInfo()
                print(string.format("GetInstanceInfo: name=[%s]  type=[%s]  diffID=[%s]  diffName=[%s]",
                    tostring(name), tostring(instType), tostring(diffID), tostring(diffName)))
            end)
            -- Scenario info
            pcall(function()
                if C_Scenario and C_Scenario.GetInfo then
                    local scenName = C_Scenario.GetInfo()
                    print("C_Scenario.GetInfo: ["..tostring(scenName).."]")
                end
                if C_Scenario and C_Scenario.GetStepInfo then
                    local stepName = C_Scenario.GetStepInfo()
                    print("C_Scenario.GetStepInfo: ["..tostring(stepName).."]")
                end
                local inScenario = C_Scenario.IsInScenario and C_Scenario.IsInScenario()
                print("IsInScenario: "..tostring(inScenario))
            end)
            -- Scenario criteria (lives detection)
            pcall(function()
                local numCrit = DelveGuide.GetCriteriaCount()
                print("Scenario criteria count: "..tostring(numCrit))
                for i = 1, (numCrit or 0) do
                    local crit = DelveGuide.GetCriteria(i)
                    if crit then
                        print(string.format("  crit[%d] desc=[%s]  qtyStr=[%s]  qty=%s  total=%s",
                            i, tostring(crit.description), tostring(crit.quantityString),
                            tostring(crit.quantity), tostring(crit.totalQuantity)))
                    end
                end
            end)
            -- Localized → English mapping
            local l10n = DelveGuide.localizedToEnglish or {}
            local mapped = l10n[zone]
            print("localizedToEnglish["..zone.."] = "..tostring(mapped))
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "tierdebug",
        desc = "Print tier state and the objective-tracker text",
        handler = function()
            print("|cFF00BFFF[DelveGuide]|r === Tier State ===")
            local function fmt(v) return v == nil and "|cFF555555nil|r" or ("|cFFFFFFFF"..tostring(v).."|r") end
            print("  manual (/dg tier):  " .. fmt(DelveGuide.manualDelveTier))
            print("  auto (detected):    " .. fmt(DelveGuide.autoDelveTier)
                  .. "   |cFF888888via " .. tostring(DelveGuide.autoDetectMethod or "none") .. "|r")
            print("  --> effective num:  " .. fmt(DelveGuide.currentDelveTierNum))
            print("  --> effective str:  " .. fmt(DelveGuide.currentDelveTier))
            local inScen = false; pcall(function() inScen = C_Scenario.IsInScenario() end)
            local zone = ""; pcall(function() zone = GetRealZoneText() or "" end)
            print(string.format("  inScenario: %s   zone: |cFFCCCCCC%s|r   runTimer: %s",
                tostring(inScen), zone, DelveGuide.runStartTime and "running" or "|cFF555555stopped|r"))
            print("|cFF00BFFF[DelveGuide]|r === Objective Tracker Dump ===")
            local tracker = _G["ObjectiveTrackerFrame"] or _G["ScenarioObjectiveTracker"]
            if tracker then
                local function PrintText(frame, depth)
                    if not frame or frame:IsForbidden() then return end
                    for _, r in ipairs({frame:GetRegions()}) do
                        if r:GetObjectType() == "FontString" and r:IsShown() then
                            local txt = r:GetText()
                            if txt and txt ~= "" then
                                local cleanTxt = DelveGuide.StripEscapes(txt)
                                print("  ["..depth.."] " .. cleanTxt)
                            end
                        end
                    end
                    for _, child in ipairs({frame:GetChildren()}) do
                        PrintText(child, depth + 1)
                    end
                end
                PrintText(tracker, 0)
            else
                print("  |cFFFF4444No tracker found on screen!|r")
            end
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "checkdebug",
        desc = "Print raw Valeera role/aura data to chat",
        handler = function()
            print("|cFF00BFFF[DelveGuide]|r === Valeera Role Debug ===")
            local id = C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer and C_DelvesUI.GetCompanionInfoForActivePlayer()
            print("  companionID: " .. tostring(id))
            if id and id > 0 then
                for roleType, roleName in pairs({[0]="DPS",[1]="Heal",[2]="Tank"}) do
                    -- GetRoleNodeForCompanion takes the companion ID alone (one role
                    -- node per companion); the old (roleType, id) call looked up
                    -- companion 0, 1 and 2 instead.
                    local node    = C_DelvesUI.GetRoleNodeForCompanion    and C_DelvesUI.GetRoleNodeForCompanion(id)
                    local subtree = C_DelvesUI.GetRoleSubtreeForCompanion and C_DelvesUI.GetRoleSubtreeForCompanion(roleType, id)
                    print(string.format("  %s: node=%s  subtree=%s", roleName, tostring(node), tostring(subtree)))
                end
            end
            local f = DelvesCompanionConfigurationFrame
            if f then
                print("  frame.selectedRole: " .. tostring(f.selectedRole))
                if f.RoleDropdown then print("  RoleDropdown.selectedValue: " .. tostring(f.RoleDropdown.selectedValue)) end
            end
            -- Check active trait configs
            if C_Traits and C_Traits.GetActiveConfigID then
                print("  activeConfigID: " .. tostring(C_Traits.GetActiveConfigID()))
            end
            print("|cFF00BFFF[DelveGuide]|r === End ===")
            -- Also scan auras
            local i = 1
            while true do
                local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                if not aura then break end
                -- tostring() keeps this safe if aura fields come back as secret values (12.1+)
                print(string.format("  aura[%d] spellID=%s  %s", i, tostring(aura.spellId), tostring(aura.name)))
                i = i + 1
            end
        end,
    },
    {
        name = "specinfo",
        desc = "Print detected spec ID and curio recommendations",
        handler = function()
            local idx = GetSpecialization and GetSpecialization()
            if not idx then print("|cFF00BFFF[DelveGuide]|r GetSpecialization() returned nil"); return end
            local specID, specName = GetSpecializationInfo(idx)
            print(string.format("|cFF00BFFF[DelveGuide]|r specIndex=%d  specID=%d  specName=%s", idx, specID or -1, specName or "nil"))
            local rec = DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID]
            if rec then
                -- combat/utility were Season 1 curios and are gone from the table.
                -- Printing them with %s would also error outright, since string.format
                -- rejects nil for %s.
                print(string.format("|cFF00BFFF[DelveGuide]|r Rec found: %s (%s)  Valeera=%s",
                    tostring(rec.spec or "?"), tostring(rec.role or "?"), tostring(rec.companion or "?")))
            else
                print("|cFF00BFFF[DelveGuide]|r No rec entry for specID "..tostring(specID))
            end
        end,
    },
    {
        name = "currencydebug",
        desc = "Dump every field of the delve currencies",
        handler = function()
            -- Dump every field of the delve currencies so season-scoped vs lifetime
            -- totals can be told apart (the in-game tooltip shows both).
            print("|cFF00BFFF[DelveGuide]|r === Currency Fields ===")
            -- 3513 is the ID the addon used for the Voidcore before 3418 was
            -- confirmed; kept so the two can be told apart in the output.
            local ids = { DelveGuide.Voidforge.NEBULOUS_CURRENCY_ID, 3513,
                          DelveGuideData.cofferKeys.SHARD_CURRENCY_ID, DelveGuideData.cofferKeys.RESTORED_CURRENCY_ID }
            for _, id in ipairs(ids) do
                local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
                if ok and info then
                    local bits = {}
                    for _, f in ipairs({"name","quantity","totalEarned","maxQuantity","maxWeeklyQuantity",
                                        "quantityEarnedThisWeek","useTotalEarnedForMaxQty","isAccountWide",
                                        "isAccountTransferable","discovered"}) do
                        if info[f] ~= nil then table.insert(bits, f.."="..tostring(info[f])) end
                    end
                    print(string.format("  |cFFFFD700%d|r  %s", id, table.concat(bits, "  ")))
                else
                    print(string.format("  |cFF888888%d  (no data)|r", id))
                end
            end
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "vaultdebug",
        desc = "Dump the real Great Vault activity data",
        handler = function()
            -- Dumps the real Great Vault activity data so the reward item levels can
            -- be read from Blizzard rather than a hardcoded per-tier table.
            print("|cFF00BFFF[DelveGuide]|r === Great Vault Activities ===")
            local ok, acts = pcall(C_WeeklyRewards.GetActivities)
            if not ok or type(acts) ~= "table" then
                print("  |cFFFF4444GetActivities failed|r")
            else
                for _, a in ipairs(acts) do
                    local bits = {}
                    for _, f in ipairs({"id","type","index","level","threshold","progress","claimID"}) do
                        if a[f] ~= nil then table.insert(bits, f.."="..tostring(a[f])) end
                    end
                    print("  " .. table.concat(bits, "  "))
                    -- Reward item level, if the API will give it to us directly.
                    pcall(function()
                        local links = C_WeeklyRewards.GetExampleRewardItemHyperlinks and C_WeeklyRewards.GetExampleRewardItemHyperlinks(a.id)
                        if links then
                            local ilvl = C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(links)
                            print("      reward: " .. tostring(links) .. "   ilvl=" .. tostring(ilvl))
                        end
                    end)
                    pcall(function()
                        if a.id and C_WeeklyRewards.GetActivityEncounterInfo then
                            local enc = C_WeeklyRewards.GetActivityEncounterInfo(a.type, a.index)
                            if enc then for _, e in ipairs(enc) do
                                print("      encounter: bestDifficulty=" .. tostring(e.bestDifficulty) .. " name=" .. tostring(e.encounterName))
                            end end
                        end
                    end)
                end
            end
            print("|cFF00BFFF[DelveGuide]|r === END ===")
        end,
    },
    {
        name = "findpoi",
        usage = "<text>",
        desc = "Search map IDs 2200-2700 for a POI whose name contains <text>",
        handler = function(arg)
            FindPOI(arg)
        end,
    },
    {
        name = "findplaza",
        desc = "Shorthand for /dg findpoi parhelion (kept for muscle memory)",
        handler = function()
            FindPOI("parhelion")
        end,
    },
}) do
    cmd.debug = true
    table.insert(DelveGuide.commands, cmd)
end
