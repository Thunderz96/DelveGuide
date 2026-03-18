-- ============================================================
-- DelveGuide.lua  --  Main addon logic
-- ============================================================
DelveGuide = {}

local ADDON_NAME       = "DelveGuide"
local ADDON_VERSION    = "1.3.7"
local WINDOW_W         = 700
local WINDOW_H         = 500
local TAB_HEIGHT       = 28
local BASE_HEADER_SIZE = 14
local BASE_ROW_SIZE    = 11
local BASE_ROW_HEIGHT  = 18

local TABS = {
    { label = "Delves",   key = "delves"   },
    { label = "Curios",   key = "curios"   },
    { label = "Loot",     key = "loot"     },
    { label = "Nullaeus", key = "nullaeus" },
    { label = "History",  key = "history"  },
    { label = "Future",   key = "future"   },
    { label = "Roster",   key = "roster"   },
    { label = "Settings", key = "settings" },
    { label = "Debug",    key = "debug"    },
}

local CHANGELOG = {
    {
        version = "1.3.7",
        date    = "2026-03-18",
        entries = {
            "Debug tab: now shows per-map-ID scan status even when results are empty",
            "Debug tab: clear messaging when map IDs return no POIs (helps diagnose non-English client issues)",
            "New command: /dg chatdump — prints full scan results to chat for easy copy-paste sharing",
        },
    },
    {
        version = "1.3.6",
        date    = "2026-03-17",
        entries = {
            "Bountiful detection now uses atlas name (reliable, no map hover required)",
            "Delves tab: active bountiful delves show a gold [Bountiful] badge",
            "Compact widget: bountiful variants marked with gold [B]",
            "Debug tab: atlasName now shown per POI to aid future detection work",
        },
    },
    {
        version = "1.3.5",
        date    = "2026-03-17",
        entries = {
            "Settings: added toggle to disable the What's New changelog popup on login",
            "Changelog popup can still be opened manually via the View Changelog button in Settings",
        },
    },
    {
        version = "1.3.4",
        date    = "2026-03-17",
        entries = {
            "New tab: Nullaeus — dedicated Season 1 Nemesis guide",
            "Covers location, unlock requirements, all mechanics (Umbral Rage, Oblivion Shell), phase transitions, recommended setup, tips, and rewards",
            "Includes Beacon of Hope workflow for earning the weekly Bounty without entering Torment's Rise",
        },
    },
    {
        version = "1.3.3",
        date    = "2026-03-17",
        entries = {
            "Tracking Restored Coffer Keys (item 3028) — shown in compact widget, checklist, roster, and Delves tab",
            "Checklist: coffer key check now passes if you have a Restored Coffer Key, even without 100 shards",
            "Roster: restored key count shown next to shard total as +(N)r",
        },
    },
    {
        version = "1.3.2",
        date    = "2026-03-17",
        entries = {
            "Fixed: HUD showing in Zul'Aman overworld (seamless sub-zone name bleeding into detection)",
            "Detection now requires C_Scenario.IsInScenario() — zone name alone is no longer sufficient",
        },
    },
    {
        version = "1.3.1",
        date    = "2026-03-16",
        entries = {
            "Fixed: HUD now closes on delve completion (SCENARIO_COMPLETED + ZONE_CHANGED events)",
            "Settings: added HUD enable/disable toggle",
        },
    },
    {
        version = "1.3.0",
        date    = "2026-03-16",
        entries = {
            "In-Run HUD — auto-shows when inside a Delve, hides on exit",
            "HUD shows: delve name, active variant + grade, tier, curio rec, nemesis warning, bountiful status",
            "HUD is draggable and remembers its position",
            "/dg hud — toggle the HUD manually (also works as a preview outside of Delves)",
        },
    },
    {
        version = "1.2.2",
        date    = "2026-03-16",
        entries = {
            "History: each run now shows which character completed it",
            "History: added Clear History button with confirmation",
        },
    },
    {
        version = "1.2.1",
        date    = "2026-03-16",
        entries = {
            "Fixed: opening world map no longer triggers ADDON_ACTION_BLOCKED (SetPassThroughButtons taint)",
            "Waypoint click now sets the pin silently — press M to open your map and navigate",
        },
    },
    {
        version = "1.2.0",
        date    = "2026-03-15",
        entries = {
            "Roster tab — track all level-80+ alts' weekly delves, shards, ilvl, and vault slots",
            "Roster: per-character remove button with confirmation dialog",
            "Fixed: targeting a delve entrance no longer triggers a taint error",
        },
    },
    {
        version = "1.1.0",
        date    = "2026-03-14",
        entries = {
            "Settings tab — minimap, compact widget, tier filter, font scale",
            "Compact floating widget with tier filter and lock button",
            "Clickable delve names open the map and set a waypoint",
            "Loot tab item tooltips on hover",
            "Weekly reset timer and Great Vault tracker in the header",
            "Coffer Key shard tracker in the header bar",
            "/dg help command listing all slash commands",
        },
    },
    {
        version = "1.0.0",
        date    = "2026-03-01",
        entries = {
            "Initial release — delve rankings, curio DB, loot tables, run history",
            "Active variant scanner, minimap button, font scale setting",
        },
    },
}

local ALL_ZONE_MAP_IDS = { 2393, 2437, 2395, 2444, 2413, 2405 }

local ZONE_NAMES = {
    [2393] = "Silvermoon City",
    [2437] = "Zul'Aman",
    [2395] = "Eversong Woods",
    [2444] = "Isle of Quel'Danas",
    [2413] = "Harandar",
    [2405] = "Voidstorm",
}

local function InitSavedVars()
    if not DelveGuideDB then
        DelveGuideDB = { minimapAngle=225, windowX=nil, windowY=nil, fontScale=1.0, history={}, minimapHidden=false, widgetHidden=false, widgetX=nil, widgetY=nil, widgetClickOpens=false }
    end
    if not DelveGuideDB.fontScale then DelveGuideDB.fontScale = 1.0 end
    if not DelveGuideDB.history then DelveGuideDB.history = {} end
    if DelveGuideDB.minimapHidden == nil then DelveGuideDB.minimapHidden = false end
    if DelveGuideDB.widgetHidden == nil then DelveGuideDB.widgetHidden = false end
    if DelveGuideDB.widgetClickOpens == nil then DelveGuideDB.widgetClickOpens = false end
    if not DelveGuideDB.widgetTiers then DelveGuideDB.widgetTiers = {S=true,A=true,B=true,C=true,D=true,F=true} end
    if DelveGuideDB.widgetLocked == nil then DelveGuideDB.widgetLocked = false end
    if DelveGuideDB.hudLocked == nil then DelveGuideDB.hudLocked = false end
    if DelveGuideDB.hudEnabled == nil then DelveGuideDB.hudEnabled = true end
    if DelveGuideDB.checklistEnabled == nil then DelveGuideDB.checklistEnabled = true end
    if DelveGuideDB.showChangelog == nil then DelveGuideDB.showChangelog = true end
    -- checklistDismissed is session-only; reset on every load
    DelveGuideDB.checklistDismissed = false
    if not DelveGuideDB.roster then DelveGuideDB.roster = {} end
    -- lastSeenVersion drives the "what's new" popup (nil = never shown)
    if DelveGuideDB.lastSeenVersion == nil then DelveGuideDB.lastSeenVersion = nil end
end

local activeDelves, activeVariants, rawScanResults = {}, {}, {}
local minimapBtn, currentAngle, compactWidget, UpdateCompactWidget, RefreshCurrentTab

local function ReadVariantFromWidgetSet(setID)
    if not setID or setID == 0 then return {} end
    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID)
    if not widgets then return {} end
    local texts = {}
    for _, w in ipairs(widgets) do
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo
                     and C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(w.widgetID)
        if info and info.text and info.text ~= "" then table.insert(texts, info.text) end
        info = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo
               and C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(w.widgetID)
        if info and info.text and info.text ~= "" then table.insert(texts, info.text) end
    end
    return texts
end

local function ScanActiveVariants()
    activeDelves, activeVariants, rawScanResults = {}, {}, {}
    DelveGuide.activeDelves   = activeDelves
    DelveGuide.activeVariants = activeVariants
    local knownVariants = {}
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do knownVariants[d.variant] = true end
    end
    for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
        local poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
        if poiIDs == nil then
            table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A",name="(GetDelvesForMap returned nil)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
        elseif #poiIDs == 0 then
            table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A",name="(GetDelvesForMap returned empty — map IDs may not match this region)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
        else
            for _, poiID in ipairs(poiIDs) do
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info then
                    local delveName=info.name or ""; local widgetSetID=info.tooltipWidgetSet or 0
                    local widgetTexts=ReadVariantFromWidgetSet(widgetSetID)
                    local atlasName = info.atlasName or ""
                    local variantName,isBountiful,hasNemesis=nil,false,false
                    if atlasName:find("bountiful",1,true) then isBountiful=true end
                    for _, t in ipairs(widgetTexts) do
                        local clean=t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")
                        if string.find(clean,"Nemesis",1,true) then hasNemesis=true end
                        for kVariant in pairs(knownVariants) do
                            if string.find(clean,kVariant,1,true) then variantName=kVariant end
                        end
                    end
                    if delveName~="" then activeDelves[delveName]={bountiful=isBountiful,nemesis=hasNemesis} end
                    table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID=poiID,name=delveName,widgetSetID=tostring(widgetSetID),
                        atlasName=atlasName,widgetTexts=widgetTexts,variantName=variantName or "(not found)"})
                    if variantName and variantName~="" then activeVariants[variantName]=true end
                else
                    table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID=poiID,name="(GetAreaPOIInfo returned nil)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
                end
            end
        end
    end
end

local function IsVariantActive(v) return activeVariants[v]==true end

-- Expose live scan data so DelveGuide_HUD.lua can read it
DelveGuide = DelveGuide or {}

local HEADER_FONT_FILE,ROW_FONT_FILE=nil,nil
local function EnsureFontFiles()
    if not HEADER_FONT_FILE then
        HEADER_FONT_FILE=GameFontNormalLarge:GetFont() or "Fonts\\FRIZQT__.TTF"
        ROW_FONT_FILE=GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    end
end
local function GetScaledSizes()
    local s=DelveGuideDB and DelveGuideDB.fontScale or 1.0
    return math.floor(BASE_HEADER_SIZE*s+0.5),math.floor(BASE_ROW_SIZE*s+0.5),math.floor(BASE_ROW_HEIGHT*s+0.5)
end

local function GradeColor(g) return (DelveGuideData.gradeColors[g] or "|cFFFFFFFF")..g.."|r" end
local zoneColors={["Zul'Aman"]="|cFFFF8C00",["Quel'Thalas"]="|cFF00CED1",["Voidstorm"]="|cFFBF5FFF",["Harandar"]="|cFF7FFF00",["Quel'Danas"]="|cFFFF69B4"}
local function ZoneColor(z) return (zoneColors[z] or "|cFFCCCCCC")..z.."|r" end
local typeColors={Combat="|cFFFF4444",Utility="|cFF44AAFF"}
local RANK_COLORS={S="|cFF00FF44",A="|cFF66FF44",B="|cFFAAFF44",C="|cFFFFFF44",D="|cFFFF8844",F="|cFFFF4444"}
local function TypeColor(t) return (typeColors[t] or "|cFFFFFFFF")..t.."|r" end

local function SetDelveWaypoint(pin)
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin.mapID,pin.x,pin.y))
    -- Do NOT call OpenWorldMap() — even deferred it triggers SetPassThroughButtons()
    -- on WaypointLocationDataProvider pins inside a secure frame chain, causing taint.
    -- User can press M to open the map and see the waypoint.
    print("|cFF00BFFF[DelveGuide]|r Waypoint set: |cFFFFD700"..pin.name.."|r |cFF888888(press M to open map)|r")
end
local function FindPinByName(name)
    for _,p in ipairs(DelveGuideData.mapPins) do if p.name==name then return p end end
end

local scrollFrame,currentContent=nil,nil
local function NewContentFrame()
    if currentContent then currentContent:Hide(); currentContent:SetParent(nil) end
    local cf=CreateFrame("Frame",nil,scrollFrame)
    local w=scrollFrame:GetWidth(); if not w or w==0 then w=WINDOW_W-32 end
    cf:SetWidth(w); cf:SetHeight(2000); scrollFrame:SetScrollChild(cf); currentContent=cf; return cf
end

local function CreateHeader(parent,y,text)
    EnsureFontFiles(); local hSize=GetScaledSizes()
    local fs=parent:CreateFontString(nil,"OVERLAY"); fs:SetFont(HEADER_FONT_FILE,hSize,"OUTLINE")
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-y); fs:SetWidth(parent:GetWidth()-16)
    fs:SetJustifyH("LEFT"); fs:SetTextColor(1,0.82,0,1); fs:SetText(text); return hSize+6
end

local function CreateRow(parent,y,text)
    EnsureFontFiles(); local _,rSize,rH=GetScaledSizes()
    local fs=parent:CreateFontString(nil,"OVERLAY"); fs:SetFont(ROW_FONT_FILE,rSize)
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-y); fs:SetWidth(parent:GetWidth()-16)
    fs:SetJustifyH("LEFT"); fs:SetText(text); return rH
end

local function CreateDelveRow(parent,y,d)
    EnsureFontFiles(); local _,rSize,rH=GetScaledSizes(); local rowW=WINDOW_W-52
    local active=IsVariantActive(d.variant)
    if active then
        local fill=parent:CreateTexture(nil,"BACKGROUND"); fill:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        fill:SetSize(rowW-4,rH+2); fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        fill:SetGradient("HORIZONTAL",CreateColor(0,0.7,0.15,0.35),CreateColor(0,0.7,0.15,0))
        local bar=parent:CreateTexture(nil,"ARTWORK"); bar:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        bar:SetSize(3,rH+2); bar:SetColorTexture(0,1,0.2,1)
    end
    local gradeFS=parent:CreateFontString(nil,"OVERLAY"); gradeFS:SetFont(ROW_FONT_FILE,rSize)
    gradeFS:SetPoint("TOPLEFT",parent,"TOPLEFT",10,-y); gradeFS:SetWidth(46); gradeFS:SetJustifyH("LEFT")
    gradeFS:SetText(string.format("[%s]",GradeColor(d.ranking)))
    local pin=FindPinByName(d.name)
    local nameBtn=CreateFrame("Button",nil,parent); nameBtn:SetSize(160,rH)
    nameBtn:SetPoint("TOPLEFT",parent,"TOPLEFT",56,-y+1)
    local nameFS=nameBtn:CreateFontString(nil,"OVERLAY"); nameFS:SetFont(ROW_FONT_FILE,rSize)
    nameFS:SetAllPoints(nameBtn); nameFS:SetJustifyH("LEFT")
    if pin then
        nameFS:SetText("|cFF00CFFF"..d.name.."|r")
        nameBtn:SetScript("OnEnter",function(self)
            nameFS:SetText("|cFFFFFFFF"..d.name.."|r")
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine("|cFFFFD700"..d.name.."|r")
            GameTooltip:AddLine("|cFFCCCCCC"..d.zone.."|r"); GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF88Click to open map & set waypoint|r"); GameTooltip:Show()
        end)
        nameBtn:SetScript("OnLeave",function() nameFS:SetText("|cFF00CFFF"..d.name.."|r") GameTooltip:Hide() end)
        nameBtn:SetScript("OnClick",function() SetDelveWaypoint(pin) end)
    else nameFS:SetText(d.name) end
    local variantText=active and "|cFF44FF44"..d.variant.."|r" or d.variant
    local flags=""
    if d.isBestRoute then flags=flags.."|cFF00FF00[Best]|r " end
    if d.hasBug then flags=flags.."|cFFFF4444[Bug]|r " end
    if d.mountable then flags=flags.."|cFFFFD700[Mt]|r " end
    local delveStatus=activeDelves[d.name]
    local isBountiful=type(delveStatus)=="table" and delveStatus.bountiful
    if type(delveStatus)=="table" and delveStatus.nemesis then flags=flags.."|cFFFF4444[Nemesis]|r " end
    local infoFS=parent:CreateFontString(nil,"OVERLAY"); infoFS:SetFont(ROW_FONT_FILE,rSize)
    infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y)
    infoFS:SetWidth(isBountiful and (rowW-420) or (rowW-310)); infoFS:SetJustifyH("LEFT")
    infoFS:SetText(ZoneColor(d.zone).."  "..variantText.."  "..flags)
    if isBountiful then
        local bountyFS=parent:CreateFontString(nil,"OVERLAY"); bountyFS:SetFont(ROW_FONT_FILE,rSize)
        bountyFS:SetPoint("TOPLEFT",parent,"TOPLEFT",rowW-190,-y); bountyFS:SetJustifyH("LEFT")
        bountyFS:SetText("|cFFFFD700[Bountiful]|r")
    end
    if active then
        local todayFS=parent:CreateFontString(nil,"OVERLAY"); todayFS:SetFont(ROW_FONT_FILE,rSize)
        todayFS:SetPoint("TOPLEFT",parent,"TOPLEFT",rowW-80,-y); todayFS:SetJustifyH("LEFT")
        todayFS:SetText("|cFF00FF44* TODAY|r")
    end
    return rH
end

local function FormatResetTime(secs)
    if not secs or secs <= 0 then return "|cFFFF4444Now|r" end
    local d = math.floor(secs / 86400)
    local h = math.floor((secs % 86400) / 3600)
    local m = math.floor((secs % 3600) / 60)
    if d > 0 then return string.format("%dd %dh", d, h)
    elseif h > 0 then return string.format("%dh %dm", h, m)
    else return string.format("|cFFFF4444%dm|r", m) end
end

local function GetWeeklyVaultData()
    local delveCount, slots, acts = 0, 0, {}
    if Enum and Enum.WeeklyRewardItemTierType and Enum.WeeklyRewardItemTierType.World then
        local ok, data = pcall(C_WeeklyRewards.GetActivities, Enum.WeeklyRewardItemTierType.World)
        if ok and type(data) == "table" then
            for _, a in ipairs(data) do
                if a.progress > delveCount then delveCount = a.progress end
                if a.progress >= a.threshold then slots = slots + 1 end
                table.insert(acts, a)
            end
        end
    end
    return delveCount, slots, acts
end

-- Snapshot the current character's state into SavedVariables.
-- Called ONCE on PLAYER_ENTERING_WORLD — no polling, no OnUpdate.
-- Only caches characters level 80+ (current expansion).
local function CacheCurrentChar()
    if (UnitLevel("player") or 0) < 80 then return end

    local name  = UnitName("player") or "Unknown"
    local realm = GetRealmName()     or "Unknown"
    local charKey = name .. "-" .. realm

    local specName = "?"
    pcall(function()
        local idx = GetSpecialization()
        if idx then
            local _, sName = GetSpecializationInfo(idx)
            if sName then specName = sName end
        end
    end)

    local ilvl = 0
    pcall(function()
        local _, overall = GetAverageItemLevel()
        ilvl = math.floor(overall or 0)
    end)

    -- Coffer Key shards (currency 3310 — confirmed in RunChecklistScan)
    local shards = 0
    pcall(function()
        local info = C_CurrencyInfo.GetCurrencyInfo(3310)
        if info then shards = info.quantity or 0 end
    end)

    -- Trovehunter's Bounty in bags (item 265714)
    local bounty = C_Item.GetItemCount(265714, true) or 0

    -- Restored Coffer Keys in bags (item 3028)
    local restoredKeys = C_Item.GetItemCount(3028, true) or 0

    -- Weekly delves from history, matched against current reset window
    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    local resetKey = secsUntilReset and (math.floor((time() + secsUntilReset - 604800) / 3600) * 3600) or nil
    local delveCount = 0
    if resetKey and DelveGuideDB.history then
        for _, h in ipairs(DelveGuideDB.history) do
            if h.resetKey == resetKey then delveCount = delveCount + 1 end
        end
    end

    -- Vault slots — reuse existing helper
    local _, vaultSlots = GetWeeklyVaultData()

    DelveGuideDB.roster[charKey] = {
        name       = name,
        realm      = realm,
        specName   = specName,
        ilvl       = ilvl,
        shards       = shards,
        restoredKeys = restoredKeys,
        bounty       = bounty,
        delveCount = delveCount,
        vaultSlots = vaultSlots,
        lastSeen   = date("%Y-%m-%d"),
        resetKey   = resetKey,
    }
end

local function RenderDelves()
    local cf=NewContentFrame(); local y=10
    local vc=0; for _ in pairs(activeVariants) do vc=vc+1 end
    local troveCount=C_Item.GetItemCount(265714,true) or 0
    local hasTroveAura=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(1254631)
    local troveText=hasTroveAura and "|cFF00FF44Active|r" or (troveCount>0 and "|cFFFFFF00In Bags|r" or "|cFFFF4444None|r")
    local beaconCount=C_Item.GetItemCount(253342,true) or 0
    local beaconText=beaconCount>0 and "|cFF00FF44"..beaconCount.." in Bags|r" or "|cFFFF4444None|r"
    local restoredKeyCount=C_Item.GetItemCount(3028,true) or 0
    local restoredKeyText=restoredKeyCount>0 and "|cFF00FF44"..restoredKeyCount.." in Bags|r" or "|cFF888888None|r"
    local activeData,inactiveData={},{}
    for _,d in ipairs(DelveGuideData.delves) do
        if IsVariantActive(d.variant) then table.insert(activeData,d) else table.insert(inactiveData,d) end
    end
    local note=vc>0 and "  |cFF44FF44("..vc.." active today)|r" or "  |cFFAAAAAA(use /dg scan)|r"
    y=y+CreateHeader(cf,y,"Delve Rankings -- S=Fastest | F=Slowest"..note)+4
    y=y+CreateRow(cf,y,string.format("|cFF3088FFWeekly Items:|r  Trovehunter's Bounty: %s   |   Beacon of Hope: %s   |   Restored Coffer Key: %s",troveText,beaconText,restoredKeyText))
    local delveCount,_,vaultActs=GetWeeklyVaultData()
    if #vaultActs>0 then
        local parts={}
        for _,a in ipairs(vaultActs) do
            local done=a.progress>=a.threshold
            local ilvlText=a.level and a.level>0 and ("|cFFFFD700"..a.level.." ilvl|r") or "|cFF888888?|r"
            if done then
                table.insert(parts,string.format("|cFF00FF44✓ Slot %d|r (%s)",a.index or #parts+1,ilvlText))
            else
                table.insert(parts,string.format("|cFF888888Slot %d:|r %d/%d needed",a.index or #parts+1,a.progress,a.threshold))
            end
        end
        y=y+CreateRow(cf,y,string.format("|cFF3088FFGreat Vault:|r  %d delve(s) this week  —  %s",delveCount,table.concat(parts,"  |  ")))
    end
    y=y+8
    y=y+CreateRow(cf,y,"|cFFAAAAAA"..string.format("%-6s  %-22s  %-14s  %s","Rank","Delve","Zone","Variant / Flags").."|r")
    y=y+CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+2
    if vc>0 then
        y=y+4; y=y+CreateRow(cf,y,"|cFF00FF44-- * ACTIVE TODAY --|r")
        for _,d in ipairs(activeData) do y=y+CreateDelveRow(cf,y,d) end
        y=y+12; y=y+CreateRow(cf,y,"|cFF888888-- ALL VARIANTS (INACTIVE) --|r")
    end
    local lastZone=""
    for _,d in ipairs(inactiveData) do
        if d.zone~=lastZone then y=y+4; y=y+CreateRow(cf,y,"|cFF666666-- "..d.zone.." --|r"); lastZone=d.zone end
        y=y+CreateDelveRow(cf,y,d)
    end
    cf:SetHeight(y+20)
end

local function GetSpecRec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    local specID = select(1, GetSpecializationInfo(idx))
    if not specID then return nil end
    return DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID], specID
end

local function RenderCurios()
    local cf=NewContentFrame(); local y=10
    EnsureFontFiles(); local _,_,rH=GetScaledSizes()

    -- ── Spec recommendation block ──────────────────────────────
    local rec, specID = GetSpecRec()
    y=y+CreateHeader(cf,y,"Curios Rankings  --  S=Best  |  F=Worst")+4

    if rec then
        -- Highlight row background
        local hi=cf:CreateTexture(nil,"BACKGROUND"); hi:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
        hi:SetSize(WINDOW_W-52,rH*3+14); hi:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        hi:SetGradient("HORIZONTAL",CreateColor(0,0.4,1,0.18),CreateColor(0,0.4,1,0))
        local bar=cf:CreateTexture(nil,"ARTWORK"); bar:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
        bar:SetSize(3,rH*3+14); bar:SetColorTexture(0,0.6,1,1)
        y=y+CreateRow(cf,y,string.format("|cFF00BFFFYour Spec:|r |cFFFFFFFF%s|r  |cFF888888(specID %d)|r", rec.spec, specID))
        y=y+CreateRow(cf,y,string.format("|cFF00FF88Recommended:|r  Combat: |cFFFFD700%s|r   Utility: |cFFFFD700%s|r   Valeera: |cFF00CFFF%s|r", rec.combat, rec.utility, rec.companion))
        if rec.notes then
            y=y+CreateRow(cf,y,"|cFF888888"..rec.notes.."|r")
        end
        y=y+6
        y=y+CreateRow(cf,y,"|cFFFF8844[Nemesis Warning]|r Mandate of Sacred Death procs require profession nodes. Nullaeus arena has none — swap to Overflowing Voidspire or Ebon Crown.")
        y=y+8
    else
        y=y+CreateRow(cf,y,"|cFF888888No spec data available — enter the world to detect your specialization.|r")
        y=y+8
    end

    -- ── General loadout reference ──────────────────────────────
    y=y+CreateRow(cf,y,"|cFFFFD700-- General Loadout Reference --|r")
    y=y+CreateRow(cf,y,"|cFF00FF00Safe / Progression:|r  Sanctum's Edict (Combat)  +  Ebon Crown of Subjugation (Utility)")
    y=y+CreateRow(cf,y,"|cFFFF4444Speed / Farming:|r    Porcelain Blade Tip (Combat)  +  Mandate of Sacred Death (Utility)")
    y=y+CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+4

    -- ── Full curio table with spec badges ─────────────────────
    local specCombat  = rec and rec.combat  or nil
    local specUtility = rec and rec.utility or nil
    for _,ctype in ipairs({"Combat","Utility"}) do
        local specPick = ctype=="Combat" and specCombat or specUtility
        y=y+4; y=y+CreateRow(cf,y,TypeColor(ctype).." Curios")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-4s  %-32s  %s","Rank","Name","Effect").."|r")
        for _,c in ipairs(DelveGuideData.curios) do
            if c.curiotype==ctype then
                local badge = (c.name==specPick) and "|cFF00FF88[Your Spec] |r" or ""
                -- Highlight the recommended row
                if c.name==specPick then
                    local fw=cf:CreateTexture(nil,"BACKGROUND"); fw:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
                    fw:SetSize(WINDOW_W-52,rH+2); fw:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                    fw:SetGradient("HORIZONTAL",CreateColor(0,1,0.3,0.15),CreateColor(0,1,0.3,0))
                end
                y=y+CreateRow(cf,y,string.format("%s[%s]  %-32s  %s",badge,GradeColor(c.ranking),c.name,c.description))
            end
        end; y=y+8
    end
    cf:SetHeight(y+20)
end

local function CreateLootRow(parent, y, item)
    EnsureFontFiles(); local _, rSize, rH = GetScaledSizes()
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(220, rH); btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y+1)
    local nameFS = btn:CreateFontString(nil, "OVERLAY")
    nameFS:SetFont(ROW_FONT_FILE, rSize); nameFS:SetAllPoints(btn); nameFS:SetJustifyH("LEFT")
    if item.id then
        nameFS:SetText("|cFF00BFFF"..item.name.."|r")
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(string.format("item:%d::::::::::::1:13648", item.id))
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        nameFS:SetText(item.name)
    end
    local notesFS = parent:CreateFontString(nil, "OVERLAY")
    notesFS:SetFont(ROW_FONT_FILE, rSize)
    notesFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 236, -y)
    notesFS:SetWidth(parent:GetWidth() - 244); notesFS:SetJustifyH("LEFT"); notesFS:SetText(item.notes)
    return rH
end

local function RenderLoot()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Notable Loot  --  Trinkets & Weapons from Midnight Delves")+4
    y=y+CreateRow(cf,y,"|cFF888888Hover an item name to preview its tooltip.|r")+4
    for _,slot in ipairs({"Trinket","Weapon"}) do
        y=y+4; y=y+CreateRow(cf,y,"|cFFFFD700"..slot.."s|r")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-36s  %s","Item Name","Effect / Notes").."|r")
        for _,item in ipairs(DelveGuideData.loot) do
            if item.slot==slot then y=y+CreateLootRow(cf,y,item) end
        end; y=y+8
    end
    y=y+8; y=y+CreateRow(cf,y,"|cFFFFD700-- Midnight Delve iLvl Scaling --|r")
    y=y+CreateRow(cf,y,"|cFF888888Tier  Recommended  Bountiful Drop  Great Vault|r")
    local tiers={{1,170,220,233},{2,187,224,237},{3,200,227,240},{4,213,230,243},{5,222,233,246},
                 {6,229,237,253},{7,235,246,256},{8,244,250,259},{9,250,250,259},{10,257,250,259},{11,265,250,259}}
    for _,d in ipairs(tiers) do
        y=y+CreateRow(cf,y,string.format(" %-5d %-12d |cFF00FF00%-14d|r |cFF00BFFF%d|r",d[1],d[2],d[3],d[4]))
    end; cf:SetHeight(y+20)
end

local function RenderNullaeus()
    local cf = NewContentFrame(); local y = 10
    EnsureFontFiles()

    -- ── Header ────────────────────────────────────────────────
    y = y + CreateHeader(cf, y, "Nullaeus  —  Season 1 Nemesis  |cFF888888(Tier ? / Tier ??)|r") + 4
    y = y + CreateRow(cf, y,
        "|cFF888888Domanaar, Hand of the Harbinger. The '?' and '??' tier names are intentional — " ..
        "Blizzard masked the difficulty labels. Torment's Rise unlocked March 17 with Season 1.|r") + 8

    -- ── Location ──────────────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Location|r") + 4
    y = y + CreateRow(cf, y, "|cFFCCCCCC  Torment's Rise  —  Voidstorm|r") + 2
    y = y + CreateRow(cf, y, "|cFF888888  /way #2405 61.17 71.37  (between Nexus-Point Xenas and Obscurion Citadel)|r") + 8

    -- ── Unlock Requirements ───────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Unlock Requirements|r") + 4
    y = y + CreateRow(cf, y, "|cFFFF8800  Tier ?   |r|cFFCCCCCC Complete any Tier 7 delve with at least 1 life remaining|r") + 2
    y = y + CreateRow(cf, y, "|cFFFF4444  Tier ??  |r|cFFCCCCCC Complete any Tier 10 delve with at least 1 life remaining|r") + 8

    -- ── Beacon of Hope Shortcut ───────────────────────────────
    y = y + CreateRow(cf, y, "|cFF00FF88Beacon of Hope  —  Skip Torment's Rise entirely|r") + 4
    y = y + CreateRow(cf, y,
        "|cFFCCCCCC  Purchase from |cFFFFD700Naleidea Rivergleam|r|cFFCCCCCC at Delver's HQ, Silvermoon — |cFFFFD7005,000 Undercoins|r") + 2
    y = y + CreateRow(cf, y,
        "|cFFCCCCCC  Use inside any standard delve |cFFFFD700after the checkpoint|r|cFFCCCCCC. " ..
        "Nullaeus spawns — burn him to |cFF00FF8850% HP|r|cFFCCCCCC, loot the gold pile. Done.|r") + 2
    y = y + CreateRow(cf, y,
        "|cFFFF8800  Tip: |r|cFFCCCCCC Use on Tier 8+ for best loot scaling. Cooldown: 1 hour. Weekly Bounty: once per week.|r") + 8

    -- ── Boss Mechanics ────────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Boss Mechanics|r") + 4

    local mechanics = {
        { name="Emptiness of the Void", color="|cFFFF4444", desc=
            "AoE Shadow damage, ~20s cooldown. |cFFFF4444Interrupt every single cast.|r No exceptions." },
        { name="Devouring Essence",     color="|cFFFF8800", desc=
            "2.5s cast (Spell 1256358). Applies Shadow DoT every 2s for 18s. Interrupt or dispel via Valeera (Healer). " ..
            "Each tick it lands builds |cFFFF4444Umbral Rage|r stacks." },
        { name="Dread Portal",          color="|cFFBF5FFF", desc=
            "Opens a portal: spawns add wave + applies |cFFFF4444Oblivion Shell|r (boss takes zero damage until all " ..
            "adds are dead). Immediately AoE the adds — do not tunnel Nullaeus." },
        { name="Umbral Rage",           color="|cFFFF4444", desc=
            "+10% damage per stack. |cFFFF4444Never decays|r during the fight. Stacks from lingering adds and unimpeded " ..
            "Devouring Essence ticks. This is the mechanic that kills groups — it compounds." },
    }
    for _, m in ipairs(mechanics) do
        y = y + CreateRow(cf, y, m.color .. "  " .. m.name .. "|r") + 2
        y = y + CreateRow(cf, y, "|cFF888888  " .. m.desc .. "|r") + 4
    end

    -- ── Phase Transitions ─────────────────────────────────────
    y = y + 4
    y = y + CreateRow(cf, y, "|cFFFFD700Phase Transitions  |cFF888888(Tier ? reference)|r") + 4
    local phases = {
        { hp="75%", event="2x Razorshell Ravagers spawn + first Void Orb activates (persistent arena goop)" },
        { hp="50%", event="7x Spitting Ticks spawn + Gravity Well activates" },
        { hp="25%", event="|cFFFF4444Enslaved Voidcaster|r appears — high HP, spams Shadow Bolt (~55k/hit)" },
    }
    for _, p in ipairs(phases) do
        y = y + CreateRow(cf, y,
            string.format("|cFF00BFFF  %-5s|r  |cFFCCCCCC%s|r", p.hp, p.event)) + 2
    end
    y = y + 8

    -- ── Recommended Setup ─────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Recommended Setup|r") + 4
    y = y + CreateRow(cf, y, "|cFF44AAFF  Companion:     |r|cFFCCCCCCValeera Sanguinar — |cFF00FF88Healer spec|r|cFFCCCCCC (dispels Devouring Essence, sustains melee)|r") + 2
    y = y + CreateRow(cf, y, "|cFF44AAFF  Combat Curio:  |r|cFFCCCCCCPorcelain Blade Tip (burst DPS aligned with add-phase windows)|r") + 2
    y = y + CreateRow(cf, y, "|cFF44AAFF  Utility Curio: |r|cFFCCCCCCOverflowing Voidspire (activates ~25s in, dual damage + healing value)|r") + 2
    y = y + CreateRow(cf, y, "|cFF44AAFF  Valeera level: |r|cFFCCCCCC20+ for curio slots to be meaningful|r") + 8

    -- ── Recommended ilvl ──────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Recommended Item Level|r") + 4
    y = y + CreateRow(cf, y, "|cFF00FF88  Tier ?   |r|cFFCCCCCC~255 ilvl  (fresh Midnight launch gear is sufficient)|r") + 2
    y = y + CreateRow(cf, y, "|cFFFF8800  Tier ??  |r|cFFCCCCCC272–278 ilvl  (Hero track target; 285+ Mythic gear = clean clear)|r") + 2
    y = y + CreateRow(cf, y, "|cFF888888  Note: clean interrupt discipline compensates for roughly 10–15 ilvl of deficit.|r") + 8

    -- ── Tips ──────────────────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Tips & Strategy|r") + 4
    local tips = {
        "|cFFFF4444Interrupt Emptiness of the Void every cast.|r  This is non-negotiable.",
        "When Dread Portal fires, |cFFFFD700immediately AoE the adds.|r  Oblivion Shell makes the boss unkillable — " ..
            "faster add clears = fewer Umbral Rage stacks.",
        "Treat Umbral Rage as a |cFFFF4444compounding timer,|r not a soft enrage. Two missed interrupts early " ..
            "will make the last phase unsurvivable.",
        "The 25% Voidcaster hits hard — save a |cFF44AAFF defensive cooldown|r for that phase.",
        "Tank specs have an inherent advantage due to white swing mitigation. Good first-clear option.",
        "Install |cFFFFD700Deadly Boss Mods|r — Nullaeus's ability timing is consistent enough that audio " ..
            "alerts let you pre-position interrupts rather than reacting to cast bars.",
        "For the Beacon of Hope workflow: you only need 50% — once the gold pile spawns, |cFF00FF88you can stop fighting.|r",
        "Save your Beacon of Hope for a |cFFFF8800Tier 8+|r delve run. The Hidden Trove loot scales with delve tier.",
    }
    for _, tip in ipairs(tips) do
        y = y + CreateRow(cf, y, "|cFF888888  • |r" .. tip) + 3
    end
    y = y + 8

    -- ── Rewards ───────────────────────────────────────────────
    y = y + CreateRow(cf, y, "|cFFFFD700Rewards|r") + 4
    local rewards = {
        { label="Nullaeus Domaneye",           detail="Cosmetic helm + 30 Hero Dawncrests (outside seasonal cap)  — any difficulty kill" },
        { label="\"the Ominous\" title",       detail="+ 30 more Hero Dawncrests — requires Tier ?? kill" },
        { label="Arcanovoid Construct",        detail="Flying mount — solo Tier ?? clear" },
        { label="Fabled Vanquisher of Nullaeus", detail="|cFFFF4444Region-limited to first 4,000 players|r — solo Tier ?? title, time-sensitive" },
        { label="Dominating Victory (toy)",    detail="From the introductory questline: A Missing Member > Nulling Nullaeus" },
    }
    for _, r in ipairs(rewards) do
        y = y + CreateRow(cf, y,
            "|cFFFFD700  " .. r.label .. "  |r|cFF888888" .. r.detail .. "|r") + 2
    end

    cf:SetHeight(y + 20)
end

local function RenderFuture()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Future / Upcoming Content & Patch Notes")+4
    local seen,cats={},{}
    for _,f in ipairs(DelveGuideData.future) do
        if not seen[f.category] then seen[f.category]=true; table.insert(cats,f.category) end
    end
    for _,cat in ipairs(cats) do
        y=y+4; y=y+CreateRow(cf,y,"|cFF00FF88"..cat.."|r")
        for _,f in ipairs(DelveGuideData.future) do
            if f.category==cat then y=y+CreateRow(cf,y,"|cFFCCCCCC* |r"..f.note)+2 end
        end; y=y+8
    end; cf:SetHeight(y+20)
end

local function MakeSettingCheckbox(parent, y, labelText, getValue, onToggle)
    EnsureFontFiles(); local _, rSize = GetScaledSizes()
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -y)
    cb:SetChecked(getValue())
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ROW_FONT_FILE, rSize)
    lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    lbl:SetText(labelText)
    cb:SetScript("OnClick", function(self) onToggle(self:GetChecked()) end)
    return 30
end

-- ---- What's New popup ----
local changelogFrame

local function ShowChangelogPopup()
    if not changelogFrame then
        local BACKDROP = {
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left=4, right=4, top=4, bottom=4 },
        }
        local f = CreateFrame("Frame", "DelveGuideChangelogFrame", UIParent, "BackdropTemplate")
        f:SetSize(440, 460)
        f:SetBackdrop(BACKDROP)
        f:SetBackdropColor(0, 0, 0, 0.95)
        f:SetBackdropBorderColor(0.1, 0.5, 1, 1)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop",  f.StopMovingOrSizing)
        f:SetPoint("CENTER")

        -- Title bar
        local bar = f:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
        bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
        bar:SetHeight(28); bar:SetColorTexture(0.05, 0.25, 0.55, 0.95)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)
        title:SetText("|cFF3399FFDelveGuide|r  —  What's New")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Scroll area
        local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",  12,  -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 44)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(scrollFrame:GetWidth() or 380)
        scrollFrame:SetScrollChild(content)

        -- Populate content
        local ROW_FONT  = "Fonts\\FRIZQT__.TTF"
        local cy = 0
        local isFirst = true

        for _, block in ipairs(CHANGELOG) do
            -- Version header
            local verLabel = content:CreateFontString(nil, "OVERLAY")
            verLabel:SetFont(ROW_FONT, isFirst and 13 or 11)
            verLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -cy)
            verLabel:SetWidth(content:GetWidth())
            if isFirst then
                verLabel:SetText("|cFF3399FFv" .. block.version .. "|r  |cFF888888— " .. block.date .. "|r")
            else
                verLabel:SetText("|cFF666666v" .. block.version .. "  — " .. block.date .. "|r")
            end
            cy = cy + (isFirst and 20 or 17)

            -- Entries
            for _, entry in ipairs(block.entries) do
                local bullet = content:CreateFontString(nil, "OVERLAY")
                bullet:SetFont(ROW_FONT, isFirst and 11 or 10)
                bullet:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -cy)
                bullet:SetWidth(content:GetWidth() - 10)
                bullet:SetJustifyH("LEFT")
                if isFirst then
                    bullet:SetText("|cFFCCCCCC• " .. entry .. "|r")
                else
                    bullet:SetText("|cFF555555• " .. entry .. "|r")
                end
                bullet:SetWordWrap(true)
                cy = cy + bullet:GetStringHeight() + 4
            end

            cy = cy + (isFirst and 12 or 8)
            isFirst = false
        end

        content:SetHeight(math.max(cy, 10))

        -- "Got it!" button
        local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        okBtn:SetSize(100, 26); okBtn:SetText("Got it!")
        okBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
        okBtn:SetScript("OnClick", function() f:Hide() end)

        changelogFrame = f
    end

    changelogFrame:Show()
end

local function RenderSettings()
    local cf = NewContentFrame(); local y = 10
    EnsureFontFiles(); local _, rSize, rH = GetScaledSizes()

    y = y + CreateHeader(cf, y, "Settings") + 8

    -- Minimap
    y = y + CreateRow(cf, y, "|cFFFFD700Minimap|r") + 6
    y = y + MakeSettingCheckbox(cf, y,
        "Show minimap button  |cFF888888(or: /dg minimap)|r",
        function() return not DelveGuideDB.minimapHidden end,
        function(checked)
            DelveGuideDB.minimapHidden = not checked
            if minimapBtn then
                if DelveGuideDB.minimapHidden then minimapBtn:Hide() else minimapBtn:Show() end
            end
        end) + 8

    -- Compact Widget
    y = y + CreateRow(cf, y, "|cFFFFD700Compact Widget|r") + 6
    y = y + MakeSettingCheckbox(cf, y,
        "Show compact floating widget  |cFF888888(or: /dg widget)|r",
        function() return not DelveGuideDB.widgetHidden end,
        function(checked)
            DelveGuideDB.widgetHidden = not checked
            if compactWidget then
                if DelveGuideDB.widgetHidden then compactWidget:Hide() else compactWidget:Show() end
            end
        end)
    y = y + MakeSettingCheckbox(cf, y,
        "Click widget to open/close main window",
        function() return DelveGuideDB.widgetClickOpens end,
        function(checked) DelveGuideDB.widgetClickOpens = checked end)
    -- Tier filter
    y = y + 4
    y = y + CreateRow(cf, y, "|cFFAAAAAAAAWidget tier filter — show active variants at these rankings:|r") + 6
    EnsureFontFiles()
    local allRanks = {"S","A","B","C","D","F"}
    for i, rank in ipairs(allRanks) do
        local cb = CreateFrame("CheckButton", nil, cf, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", cf, "TOPLEFT", 10 + (i-1)*80, -y)
        cb:SetChecked(DelveGuideDB.widgetTiers[rank])
        local lbl = cf:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ROW_FONT_FILE, 11)
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText((RANK_COLORS[rank] or "|cFFFFFFFF")..rank.."|r")
        local r = rank
        cb:SetScript("OnClick", function(self)
            DelveGuideDB.widgetTiers[r] = self:GetChecked()
            UpdateCompactWidget()
        end)
    end
    y = y + 30 + 8

    -- Pre-Entry Checklist
    y = y + CreateRow(cf, y, "|cFFFFD700Pre-Entry Checklist|r") + 6
    y = y + MakeSettingCheckbox(cf, y,
        "Show checklist when targeting a delve entrance  |cFF888888(or: /dg check)|r",
        function() return DelveGuideDB.checklistEnabled end,
        function(checked) DelveGuideDB.checklistEnabled = checked end) + 8

    -- In-Run HUD
    y = y + CreateRow(cf, y, "|cFFFFD700In-Run HUD|r") + 6
    y = y + MakeSettingCheckbox(cf, y,
        "Auto-show HUD when inside a Delve  |cFF888888(or: /dg hud)|r",
        function() return DelveGuideDB.hudEnabled end,
        function(checked)
            DelveGuideDB.hudEnabled = checked
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
        end) + 8

    -- Font Scale
    y = y + CreateRow(cf, y, "|cFFFFD700Font Scale|r") + 6
    local fsDesc = cf:CreateFontString(nil, "OVERLAY")
    fsDesc:SetFont(ROW_FONT_FILE, rSize)
    fsDesc:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 – 2.0)", DelveGuideDB.fontScale))
    y = y + rH + 4

    local function MakeFontScaleBtn(label, xOff, delta)
        local b = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
        b:SetSize(36, 22); b:SetText(label)
        b:SetPoint("TOPLEFT", cf, "TOPLEFT", xOff, -y)
        b:SetScript("OnClick", function()
            DelveGuideDB.fontScale = math.max(0.6, math.min(2.0, DelveGuideDB.fontScale + delta))
            fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 – 2.0)", DelveGuideDB.fontScale))
            RefreshCurrentTab()
        end)
    end
    MakeFontScaleBtn("A-", 10, -0.1)
    MakeFontScaleBtn("A+", 52, 0.1)
    local resetBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 22); resetBtn:SetText("Reset")
    resetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 94, -y)
    resetBtn:SetScript("OnClick", function()
        DelveGuideDB.fontScale = 1.0
        fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 – 2.0)", DelveGuideDB.fontScale))
        RefreshCurrentTab()
    end)
    y = y + 30 + 16

    -- Changelog
    y = y + CreateRow(cf, y, "|cFFFFD700Changelog|r") + 6
    y = y + MakeSettingCheckbox(cf, y,
        "Show What's New popup on version update",
        function() return DelveGuideDB.showChangelog end,
        function(checked) DelveGuideDB.showChangelog = checked end) + 4
    local clBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    clBtn:SetSize(160, 26); clBtn:SetText("View Changelog")
    clBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    clBtn:SetScript("OnClick", ShowChangelogPopup)
    y = y + 34

    cf:SetHeight(y + 20)
end

local function RenderDebug()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"DEBUG -- Variant Detection Results")+4
    y=y+CreateRow(cf,y,"|cFFFFFF00/dg scan refreshes results  |  /dg chatdump prints all data to chat|r")+8

    -- Map ID status summary (always shown, even if scan returned nothing useful)
    y=y+CreateRow(cf,y,"|cFFFFD700-- Map ID Scan Status --|r")+4
    local mapSeen={}
    for _,r in ipairs(rawScanResults) do
        if r.mapID and r.mapID~="" and not mapSeen[r.mapID] then
            mapSeen[r.mapID]=true
        end
    end
    if #rawScanResults==0 then
        y=y+CreateRow(cf,y,"|cFFFF4444No results at all -- /dg scan has not been run, or all map IDs returned empty.|r")
        y=y+CreateRow(cf,y,"|cFFAAAAAA  Checked map IDs: "..table.concat(ALL_ZONE_MAP_IDS,", ").."|r")
    else
        for _,mapID in ipairs(ALL_ZONE_MAP_IDS) do
            local found,total=0,0
            for _,r in ipairs(rawScanResults) do
                if r.mapID==mapID then
                    total=total+1
                    if r.name~="" and not r.name:find("returned") then found=found+1 end
                end
            end
            local col=found>0 and "|cFF44FF44" or "|cFFFF4444"
            local label=ZONE_NAMES[mapID] or ("mapID "..mapID)
            y=y+CreateRow(cf,y,string.format("  %smapID %-6d  %-20s  %d POI(s)|r",col,mapID,label,found))
        end
    end

    y=y+8
    if #rawScanResults>0 then
        local vc=0; for _ in pairs(activeVariants) do vc=vc+1 end
        local vcColor=vc>0 and "|cFF44FF44" or "|cFFFF4444"
        y=y+CreateRow(cf,y,string.format("%s%d variant(s) matched today:|r",vcColor,vc))
        if vc==0 then
            y=y+CreateRow(cf,y,"|cFFFF4444  No variants matched. On non-English clients, widget text will be localized.|r")
            y=y+CreateRow(cf,y,"|cFFAAAAAA  Use /dg chatdump and share output to help add localization support.|r")
        else
            for v in pairs(activeVariants) do y=y+CreateRow(cf,y,"|cFF44FF44  + "..v.."|r") end
        end

        y=y+8; y=y+CreateRow(cf,y,"|cFFFFD700-- Raw Per-Delve Data --|r")
        for _,r in ipairs(rawScanResults) do
            y=y+4
            local isErr=r.name=="" or r.name:find("returned")
            local nColor=isErr and "|cFFFF4444" or "|cFFFFD700"
            local vColor=(r.variantName=="(not found)" or r.variantName=="(nil)") and "|cFFFF4444" or "|cFF44FF44"
            y=y+CreateRow(cf,y,string.format("%s%-26s|r  set=%-6s  -> %s%s|r",nColor,r.name,r.widgetSetID,vColor,r.variantName))
            y=y+CreateRow(cf,y,string.format("   |cFF666666atlas:|r |cFFAAAAAA%s|r",r.atlasName~="" and r.atlasName or "(none)"))
            if r.widgetTexts and #r.widgetTexts>0 then
                for _,t in ipairs(r.widgetTexts) do y=y+CreateRow(cf,y,"   |cFF888888> "..t.."|r") end
            else
                y=y+CreateRow(cf,y,"   |cFF555555(no widget texts)|r")
            end
        end
    end
    cf:SetHeight(y+20)
end

local function RenderRoster()
    local cf = NewContentFrame(); local y = 10
    EnsureFontFiles(); local _, rSize, rH = GetScaledSizes()

    y = y + CreateHeader(cf, y, "Roster  —  All Characters  |cFF888888(updates on login)|r") + 4

    local currentName  = UnitName("player") or "?"
    local currentRealm = GetRealmName()     or "?"
    local currentKey   = currentName .. "-" .. currentRealm

    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    local currentResetKey = secsUntilReset and (math.floor((time() + secsUntilReset - 604800) / 3600) * 3600) or nil

    local roster = DelveGuideDB.roster or {}

    -- Column x positions (pixel offsets from left of content frame)
    local COL = { name=8, spec=160, ilvl=278, shards=322, bounty=385, delves=438, vault=480, seen=522, del=626 }

    -- Header row
    local function MakeHeaderCol(x, w, text)
        local fs = cf:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ROW_FONT_FILE, rSize)
        fs:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y)
        fs:SetWidth(w); fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.67, 0.67, 0.67, 1)
        fs:SetText(text)
    end
    MakeHeaderCol(COL.name,   148, "Character")
    MakeHeaderCol(COL.spec,   114, "Spec")
    MakeHeaderCol(COL.ilvl,    60, "iLvl")
    MakeHeaderCol(COL.shards,  60, "Shards")
    MakeHeaderCol(COL.bounty,  50, "Bounty")
    MakeHeaderCol(COL.delves,  40, "Delves")
    MakeHeaderCol(COL.vault,   40, "Vault")
    MakeHeaderCol(COL.seen,   100, "Last Seen")
    y = y + rH

    local sep = cf:CreateTexture(nil, "OVERLAY")
    sep:SetPoint("TOPLEFT", cf, "TOPLEFT", 4, -y)
    sep:SetSize(WINDOW_W - 60, 1); sep:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    y = y + 6

    -- Sort: current char first, then alphabetical
    local keys = {}
    for k in pairs(roster) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        if a == currentKey then return true end
        if b == currentKey then return false end
        return a < b
    end)

    if #keys == 0 then
        y = y + CreateRow(cf, y, "|cFF888888No characters cached yet — log in on each alt to populate their row.|r")
    else
        for _, k in ipairs(keys) do
            local c         = roster[k]
            local isCurrent = (k == currentKey)
            local isStale   = currentResetKey and c.resetKey and (c.resetKey ~= currentResetKey)
            local alpha     = isStale and 0.45 or 1.0

            -- Row highlight for current char
            if isCurrent then
                local fill = cf:CreateTexture(nil, "BACKGROUND")
                fill:SetPoint("TOPLEFT", cf, "TOPLEFT", 2, -(y - 1))
                fill:SetSize(WINDOW_W - 56, rH + 2)
                fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                fill:SetGradient("HORIZONTAL", CreateColor(0, 0.4, 1, 0.18), CreateColor(0, 0.4, 1, 0))
                local bar = cf:CreateTexture(nil, "ARTWORK")
                bar:SetPoint("TOPLEFT", cf, "TOPLEFT", 2, -(y - 1))
                bar:SetSize(3, rH + 2); bar:SetColorTexture(0, 0.6, 1, 1)
            end

            local function MakeCol(x, w, text, justify)
                local fs = cf:CreateFontString(nil, "OVERLAY")
                fs:SetFont(ROW_FONT_FILE, rSize)
                fs:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y)
                fs:SetWidth(w); fs:SetJustifyH(justify or "LEFT")
                fs:SetAlpha(alpha); fs:SetText(text)
            end

            local nameText = isCurrent
                and ("|cFF00CFFF" .. c.name .. "|r  |cFF888888" .. c.realm .. "|r")
                or (c.name .. "  |cFF666666" .. c.realm .. "|r")

            local rk = c.restoredKeys or 0
            local shardsReady = (c.shards or 0) >= 100 or rk > 0
            local shardsText = shardsReady
                and ("|cFF00FF44" .. (c.shards or 0) .. "|r")
                or  tostring(c.shards or 0)
            if rk > 0 then
                shardsText = shardsText .. " |cFFFFD700(+" .. rk .. "r)|r"
            end

            local bountyText = (c.bounty or 0) > 0
                and ("|cFF00FF44" .. (c.bounty or 0) .. "|r")
                or  "|cFF666666--|r"

            local vaultText = (c.vaultSlots or 0) > 0
                and ("|cFF00FF44" .. (c.vaultSlots or 0) .. "|r")
                or  "|cFF888888—|r"

            local staleTag = isStale and " |cFF888888[prev week]|r" or ""

            MakeCol(COL.name,   148, nameText)
            MakeCol(COL.spec,   114, c.specName or "?")
            MakeCol(COL.ilvl,    38, c.ilvl and c.ilvl > 0 and tostring(c.ilvl) or "|cFF888888?|r", "RIGHT")
            MakeCol(COL.shards,  60, shardsText)
            MakeCol(COL.bounty,  45, bountyText)
            MakeCol(COL.delves,  38, tostring(c.delveCount or 0), "RIGHT")
            MakeCol(COL.vault,   38, vaultText, "RIGHT")
            MakeCol(COL.seen,   100, "|cFF888888" .. (c.lastSeen or "?") .. "|r" .. staleTag)

            -- Delete button — only for non-current characters
            if not isCurrent then
                local capK = k
                local capName = c.name
                local delBtn = CreateFrame("Button", nil, cf)
                delBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", COL.del, -y)
                delBtn:SetSize(18, rH)
                local delLabel = delBtn:CreateFontString(nil, "OVERLAY")
                delLabel:SetFont(ROW_FONT_FILE, rSize)
                delLabel:SetPoint("CENTER"); delLabel:SetText("|cFFFF4444x|r")
                delBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Remove " .. capName .. " from roster", 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                delBtn:SetScript("OnClick", function()
                    local dialog = StaticPopup_Show("DELVEGUIDE_CONFIRM_REMOVE_CHAR", capName)
                    if dialog then dialog.data = capK end
                end)
            end

            y = y + rH + 2
        end
    end

    y = y + 12
    y = y + CreateRow(cf, y, "|cFF555555Log in on each alt to cache their data. Greyed rows = previous week.|r")
    cf:SetHeight(y + 20)
end

local function RenderHistory()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Delve Run History  —  Weekly Great Vault Summary")+4

    -- Clear History button
    local clearBtn=CreateFrame("Button",nil,cf,"UIPanelButtonTemplate")
    clearBtn:SetSize(110,22); clearBtn:SetPoint("TOPRIGHT",cf,"TOPRIGHT",-10,-8)
    clearBtn:SetText("Clear History")
    clearBtn:SetScript("OnClick",function() StaticPopup_Show("DELVEGUIDE_CONFIRM_CLEAR_HISTORY") end)

    if not DelveGuideDB.history or #DelveGuideDB.history==0 then
        y=y+CreateRow(cf,y,"|cFF888888No runs recorded yet. Go complete a Delve!|r")
    else
        -- Group runs by WoW week (resetKey), legacy entries keyed as 0
        local weeks,weekOrder={},{}
        for _,run in ipairs(DelveGuideDB.history) do
            local key=run.resetKey or 0
            if not weeks[key] then weeks[key]={}; table.insert(weekOrder,key) end
            table.insert(weeks[key],run)
        end
        table.sort(weekOrder,function(a,b)
            if a==0 then return false end; if b==0 then return true end; return a>b
        end)
        for _,key in ipairs(weekOrder) do
            local runs=weeks[key]; local count=#runs
            local weekLabel=key==0 and "|cFF888888Earlier / Legacy Runs|r"
                or ("|cFFFFD700Week of "..date("%b %d, %Y",key).."|r")
            local vaultText
            if count>=8 then vaultText="|cFF00FF44All 3 vault slots unlocked ✓|r"
            elseif count>=4 then vaultText=string.format("|cFFFFFF002/3 vault slots|r  |cFF888888(%d more for 3rd)|r",8-count)
            elseif count>=1 then vaultText=string.format("|cFFFF88441/3 vault slots|r  |cFF888888(%d more for 2nd)|r",4-count)
            else vaultText="|cFFFF4444No vault slots|r" end
            y=y+8
            y=y+CreateRow(cf,y,weekLabel.."  |cFF888888"..count.." run(s)|r  —  "..vaultText)
            y=y+CreateRow(cf,y,"|cFF555555"..string.rep("-",80).."|r")+2
            for _,run in ipairs(runs) do
                local tierStr=run.tier and ("  |cFF888888["..run.tier.."]|r") or ""
                local vaultStr=run.vaultIlvl and ("  |cFFFFD700★ "..run.vaultIlvl.." ilvl|r") or ""
                local charStr=run.char and ("|cFF00FF88"..run.char.."|r  ") or ""
                y=y+CreateRow(cf,y,string.format("  |cFFCCCCCC%-18s|r  %s|cFF00BFFF%s|r",run.date,charStr,run.name)..tierStr..vaultStr)
            end
        end
    end; cf:SetHeight(y+20)
end

local tabRenderers={delves=RenderDelves,curios=RenderCurios,loot=RenderLoot,nullaeus=RenderNullaeus,history=RenderHistory,future=RenderFuture,roster=RenderRoster,settings=RenderSettings,debug=RenderDebug}
local mainFrame,tabButtons,currentTabKey=nil,{},nil

local function SwitchTab(key)
    currentTabKey=key
    for _,td in ipairs(TABS) do
        local btn=tabButtons[td.key]
        if td.key==key then btn.Text:SetTextColor(1,0.82,0,1); btn.Underline:Show()
        else btn.Text:SetTextColor(0.5,0.5,0.5,1); btn.Underline:Hide() end
    end
    local r=tabRenderers[key]; if r then r(); scrollFrame:SetVerticalScroll(0) end
end

RefreshCurrentTab = function() if currentTabKey then SwitchTab(currentTabKey) end end

-- ============================================================
-- PRE-ENTRY CHECKLIST
-- ============================================================
local checklistFrame

local function RunChecklistScan()
    local results = {}

    -- 1. Coffer Key shards (100 shards = 1 key) or Restored Coffer Key (item 3028)
    local keyInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards = keyInfo and keyInfo.quantity or 0
    local restoredKeys = C_Item.GetItemCount(3028, true) or 0
    local hasKey = shards >= 100 or restoredKeys > 0
    local keyLabel
    if restoredKeys > 0 then
        keyLabel = string.format("Coffer Key  |cFF00FF44(%d restored key%s + %d/600 shards)|r",
            restoredKeys, restoredKeys > 1 and "s" or "", shards)
    else
        keyLabel = string.format("Coffer Key  |cFF888888(%d/600 shards)|r", shards)
    end
    table.insert(results, {
        label = keyLabel,
        ok    = hasKey,
        tip   = not hasKey and "You need 100 shards (1 key) or a Restored Coffer Key to open a Bountiful Coffer." or nil,
    })

    -- 2. Trovehunter's Bounty active as an aura
    local hasBountyAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
        and C_UnitAuras.GetPlayerAuraBySpellID(1254631) ~= nil
    -- 3. Trovehunter's Bounty in bags (fallback check)
    local bountyCount = C_Item.GetItemCount(265714, true) or 0
    if hasBountyAura then
        table.insert(results, { label="Trovehunter's Bounty  |cFF00FF44(Active)|r", ok=true })
    elseif bountyCount > 0 then
        table.insert(results, {
            label = string.format("Trovehunter's Bounty  |cFFFFD700(%d in bags — not active)|r", bountyCount),
            ok    = false,
            tip   = "Right-click the item to activate it before entering.",
        })
    else
        table.insert(results, {
            label = "Trovehunter's Bounty  |cFFFF4444(None)|r",
            ok    = false,
            tip   = "Pick one up from the Delver's Journey rewards or the vendor.",
        })
    end

    -- 4. Valeera companion — C_DelvesUI.GetCompanionInfoForActivePlayer() returns
    -- the companionID (11 = Valeera). Role detection requires the config frame to
    -- have been opened this session; if not, we show "check manually".
    local valerraOk, valerraLabel = false, "|cFFFF4444Not detected|r"
    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            local companionID = C_DelvesUI.GetCompanionInfoForActivePlayer()
            if companionID and companionID > 0 then
                local roleNames = { [0]="DPS", [1]="Healer", [2]="Tank" }
                local role = DelvesCompanionConfigurationFrame
                    and DelvesCompanionConfigurationFrame.selectedRole
                local roleStr = role and roleNames[role] or "check role"
                valerraOk    = true
                valerraLabel = "|cFF00FF44Present|r  |cFF888888(" .. roleStr .. ")|r"
            end
        end
    end)
    table.insert(results, {
        label = "Valeera  " .. valerraLabel,
        ok    = valerraOk,
        tip   = not valerraOk and "Open the companion panel to configure Valeera." or nil,
    })

    return results
end

local function ShowChecklist(force)
    if not force then
        if not DelveGuideDB.checklistEnabled then return end
        if DelveGuideDB.checklistDismissed then return end
    end

    -- Build frame lazily
    if not checklistFrame then
        local f = CreateFrame("Frame", "DelveGuideChecklist", UIParent, "BackdropTemplate")
        f:SetSize(340, 160)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=false, tileSize=16, edgeSize=14,
            insets={left=4,right=4,top=4,bottom=4}
        })
        f:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
        f:SetBackdropBorderColor(1, 0.7, 0, 0.9)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
        title:SetText("|cFFFFD700[DelveGuide]|r  Pre-Entry Checklist")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        closeBtn:SetScript("OnClick", function()
            DelveGuideDB.checklistDismissed = true
            f:Hide()
        end)

        -- Row pool (4 rows max)
        f.rows = {}
        for i = 1, 4 do
            local row = f:CreateFontString(nil, "OVERLAY")
            row:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 11)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(24 + (i-1)*22))
            row:SetWidth(316)
            row:SetJustifyH("LEFT")
            f.rows[i] = row
        end

        -- "Don't show again this session" checkbox
        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
        cb:SetChecked(false)
        cb:SetScript("OnClick", function(self)
            DelveGuideDB.checklistDismissed = self:GetChecked()
        end)
        local cblbl = f:CreateFontString(nil, "OVERLAY")
        cblbl:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 10)
        cblbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cblbl:SetText("|cFF888888Don't show again this session|r")

        checklistFrame = f
    end

    -- Populate rows
    local results = RunChecklistScan()
    local frameH = 44 + #results * 22
    checklistFrame:SetHeight(frameH)

    for i, row in ipairs(checklistFrame.rows) do
        local r = results[i]
        if r then
            local icon
            if r.ok == true then
                icon = "|cFF00FF44✔|r "
            elseif r.ok == false then
                icon = "|cFFFF4444✘|r "
            else
                icon = "|cFFFF8844?|r "  -- unknown
            end
            local text = icon .. r.label
            if r.tip then text = text .. "  |cFF888888" .. r.tip .. "|r" end
            row:SetText(text)
            row:Show()
        else
            row:Hide()
        end
    end

    checklistFrame:Show()
end

local function OnTargetChanged()
    if not DelveGuideDB.checklistEnabled then return end
    if DelveGuideDB.checklistDismissed then return end
    -- UnitName("target") returns a secret string in Midnight 12.0 —
    -- wrap the comparison in pcall to avoid ADDON_ACTION_BLOCKED taint.
    local matched = false
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            local ok, result = pcall(function()
                local targetName = UnitName("target")
                return targetName and targetName == d.name
            end)
            if ok and result then matched = true; break end
        end
    end
    if matched then ShowChecklist(false) end
end

local function CreateMainWindow()
    local f=CreateFrame("Frame","DelveGuideFrame",UIParent,"BackdropTemplate")
    f:SetSize(WINDOW_W,WINDOW_H); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",f.StartMoving)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); DelveGuideDB.windowX=self:GetLeft(); DelveGuideDB.windowY=self:GetTop() end)
    if DelveGuideDB.windowX then f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",DelveGuideDB.windowX,DelveGuideDB.windowY)
    else f:SetPoint("CENTER") end
    f:SetFrameStrata("HIGH"); f:Hide()
    f:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=false,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(0.08,0.08,0.08,0.92); f:SetBackdropBorderColor(0.2,0.2,0.2,1)
    local closeBtn=CreateFrame("Button",nil,f,"UIPanelCloseButton"); closeBtn:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
    f.TitleText=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    f.TitleText:SetPoint("TOPLEFT",f,"TOPLEFT",16,-12); f.TitleText:SetText("|cFF00BFFFDelveGuide|r -- Midnight Reference")
    f.TrackerText=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.TrackerText:SetPoint("TOPRIGHT",f,"TOPRIGHT",-40,-14)
    f.UpdateTracker=function()
        local keysInfo=C_CurrencyInfo.GetCurrencyInfo(3310); local shards=keysInfo and keysInfo.quantity or 0
        local delveCount,vaultSlots=GetWeeklyVaultData()
        local wqCount=0
        for _,z in ipairs({2393,2437,2395,2444,2413,2405,2424}) do
            local quests=C_TaskQuest.GetQuestsOnMap(z)
            if quests then for _,q in ipairs(quests) do
                if C_QuestLog.IsWorldQuest(q.questID) and not C_QuestLog.IsQuestFlaggedCompleted(q.questID) then
                    local curs=C_QuestLog.GetQuestRewardCurrencies(q.questID)
                    if curs then for _,c in ipairs(curs) do if c.currencyID==3310 then wqCount=wqCount+1 end end end
                end
            end end
        end
        local resetSecs=C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
        local resetText=resetSecs and FormatResetTime(resetSecs) or "|cFF888888?|r"
        f.TrackerText:SetText(string.format(
            "|cFFFFD700Keys:|r %d/600  |  |cFF00BFFFDelves:|r %d  |cFF888888(Vault %d/8)|r  |  |cFF00FF88WQs:|r %d  |  |cFFAAAA00Reset:|r %s",
            shards,delveCount,vaultSlots,wqCount,resetText))
    end
    f:HookScript("OnShow",f.UpdateTracker)
    local tabW=(WINDOW_W-32)/#TABS
    for i,td in ipairs(TABS) do
        local btn=CreateFrame("Button","DelveGuideTab_"..td.key,f); btn:SetSize(tabW-4,TAB_HEIGHT)
        btn:SetPoint("TOPLEFT",f,"TOPLEFT",16+(i-1)*tabW,-36)
        btn.Text=btn:CreateFontString(nil,"OVERLAY","GameFontNormal"); btn.Text:SetPoint("CENTER"); btn.Text:SetText(td.label)
        btn.Underline=btn:CreateTexture(nil,"ARTWORK"); btn.Underline:SetColorTexture(1,0.82,0,1)
        btn.Underline:SetPoint("BOTTOM",btn,"BOTTOM",0,2); btn.Underline:SetSize(btn.Text:GetStringWidth()+16,2); btn.Underline:Hide()
        local k=td.key; btn:SetScript("OnClick",function() SwitchTab(k) end); tabButtons[k]=btn
    end
    local sf=CreateFrame("ScrollFrame","DelveGuideScrollFrame",f,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",f,"TOPLEFT",16,-(36+TAB_HEIGHT+10)); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,8)
    scrollFrame=sf; mainFrame=f; SwitchTab(TABS[1].key)
end

function DelveGuide.Toggle()
    if not mainFrame then CreateMainWindow() end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end

-- Compact floating widget
local RANK_ORDER  = {S=1,A=2,B=3,C=4,D=5,F=6}
local W_HEADER_H  = 28   -- title row + divider
local W_LINE_H    = 18   -- height per variant line
local W_PAD       = 10   -- bottom padding
local W_MAX_LINES = 8

UpdateCompactWidget = function()
    if not compactWidget or not compactWidget:IsShown() then return end
    -- Build filtered+sorted list of active variants
    local tiers = DelveGuideDB.widgetTiers or {}
    local entries = {}
    if DelveGuideData and DelveGuideData.delves then
        local seen = {}
        for _, d in ipairs(DelveGuideData.delves) do
            if activeVariants[d.variant] and not seen[d.variant] and tiers[d.ranking] then
                seen[d.variant] = true
                table.insert(entries, {variant=d.variant, ranking=d.ranking, delve=d.name})
            end
        end
    end
    table.sort(entries, function(a,b)
        return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99)
    end)
    -- Update variant line pool
    local n = math.min(#entries, W_MAX_LINES)
    if n == 0 then
        compactWidget.varLines[1].label:SetText("|cFF888888No active variants|r")
        compactWidget.varLines[1].pin = nil
        compactWidget.varLines[1]:ClearAllPoints()
        compactWidget.varLines[1]:SetPoint("TOPLEFT", compactWidget, "TOPLEFT", 8, -(W_HEADER_H+4))
        compactWidget.varLines[1]:Show()
        n = 1
        for i = 2, W_MAX_LINES do compactWidget.varLines[i]:Hide() end
    else
        for i = 1, W_MAX_LINES do
            local line = compactWidget.varLines[i]
            local e = entries[i]
            if e then
                local rc = RANK_COLORS[e.ranking] or "|cFFFFFFFF"
                local pin = FindPinByName(e.delve)
                local nameText = pin and ("|cFF00CFFF"..e.variant.."|r") or e.variant
                local ds = activeDelves[e.delve]
                local bountyTag = (type(ds)=="table" and ds.bountiful) and "  |cFFFFD700[B]|r" or ""
                line.label:SetText(rc.."["..e.ranking.."]|r  "..nameText..bountyTag)
                line.pin = pin
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", compactWidget, "TOPLEFT", 8, -(W_HEADER_H+4+(i-1)*W_LINE_H))
                line:Show()
            else line:Hide() end
        end
    end
    -- Reposition keys line and resize frame
    local keysY = -(W_HEADER_H + 4 + n*W_LINE_H + 6)
    compactWidget.keysLine:ClearAllPoints()
    compactWidget.keysLine:SetPoint("TOPLEFT", compactWidget, "TOPLEFT", 8, keysY)
    compactWidget:SetHeight(W_HEADER_H + 4 + n*W_LINE_H + 6 + W_LINE_H + W_PAD)
    local keysInfo   = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards     = keysInfo and keysInfo.quantity or 0
    local restored   = C_Item.GetItemCount(3028, true) or 0
    local keysStr    = string.format("|cFFFFD700Keys:|r %d/600 shards", shards)
    if restored > 0 then
        keysStr = keysStr .. string.format("  |cFF00FF44+%d restored|r", restored)
    end
    compactWidget.keysLine:SetText(keysStr)
end

local function CreateCompactWidget()
    local f = CreateFrame("Frame", "DelveGuideCompactWidget", UIParent, "BackdropTemplate")
    f:SetSize(220, 80)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if DelveGuideDB.widgetLocked then return end
        self.dragging = true; self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        DelveGuideDB.widgetX = self:GetLeft(); DelveGuideDB.widgetY = self:GetTop()
        C_Timer.After(0.05, function() self.dragging = false end)
    end)
    f:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" and not self.dragging and DelveGuideDB.widgetClickOpens then
            DelveGuide.Toggle()
        end
    end)
    if DelveGuideDB.widgetX then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DelveGuideDB.widgetX, DelveGuideDB.widgetY)
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, 250) end
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=false,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.88)
    f:SetBackdropBorderColor(0.15, 0.5, 1, 0.8)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cFF00BFFFDelveGuide|r"); GameTooltip:AddLine("Drag to reposition.", 0.7, 0.7, 0.7)
        if DelveGuideDB.widgetClickOpens then GameTooltip:AddLine("Click to open/close.", 1, 1, 1) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Title
    local titleFS = f:CreateFontString(nil, "OVERLAY")
    titleFS:SetFont(GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    titleFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -9); titleFS:SetText("|cFF00BFFFDelveGuide|r")
    -- Lock button
    local lockBtn = CreateFrame("Button", nil, f)
    lockBtn:SetSize(14, 14); lockBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -7, -7)
    lockBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local function RefreshLock()
        if DelveGuideDB.widgetLocked then
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Locked-Up")
        else
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Unlocked-Up")
        end
    end
    lockBtn:SetScript("OnClick", function()
        DelveGuideDB.widgetLocked = not DelveGuideDB.widgetLocked
        RefreshLock()
    end)
    lockBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(DelveGuideDB.widgetLocked and "|cFFFF4444Locked|r — click to unlock" or "|cFF44FF44Unlocked|r — click to lock")
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    RefreshLock()
    -- Divider
    local div = f:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(0.15, 0.5, 1, 0.35); div:SetSize(204, 1)
    div:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
    -- Variant line pool
    local sf = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    f.varLines = {}
    for i = 1, W_MAX_LINES do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(204, W_LINE_H)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(sf, 11); fs:SetAllPoints(); fs:SetJustifyH("LEFT")
        btn.label = fs
        btn:SetScript("OnClick", function(self)
            if self.pin then SetDelveWaypoint(self.pin) end
        end)
        btn:SetScript("OnEnter", function(self)
            if self.pin then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("|cFFFFD700"..self.pin.name.."|r")
                GameTooltip:AddLine("Click to open map & set waypoint", 0, 1, 0.5)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:Hide()
        f.varLines[i] = btn
    end
    -- Keys line (always visible)
    f.keysLine = f:CreateFontString(nil, "OVERLAY")
    f.keysLine:SetFont(sf, 11); f.keysLine:SetWidth(204); f.keysLine:SetJustifyH("LEFT")
    f.keysLine:SetText("|cFFFFD700Keys:|r --")
    if DelveGuideDB.widgetHidden then f:Hide() end
    compactWidget = f
    UpdateCompactWidget()
end

-- Minimap button — mirrors NightPulse's MinimapButton.lua exactly.

local function UpdateMinimapPos(angle)
    local radius = (Minimap:GetWidth() / 2) + 10
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius,
        math.sin(angle) * radius)
end

local function SaveMinimapAngle()
    if DelveGuideDB then
        DelveGuideDB.minimapAngle = math.deg(currentAngle)
    end
end

local function CreateMinimapButton()
    local btn = CreateFrame("Button", "DelveGuideMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Background circle (same as NightPulse)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("CENTER")

    -- Icon — map icon for DelveGuide
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map09")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    -- Tracking border ring (same offset as NightPulse — TOPLEFT with no extra offset)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    -- Assign to upvalue NOW so UpdateMinimapPos and drag callbacks can reference it
    minimapBtn = btn

    -- Restore saved angle, default to 45 degrees
    local savedDeg = (DelveGuideDB and DelveGuideDB.minimapAngle) or 45
    currentAngle = math.rad(savedDeg)
    UpdateMinimapPos(currentAngle)

    -- Hide if the user previously disabled it
    if DelveGuideDB and DelveGuideDB.minimapHidden then
        btn:Hide()
    end

    -- Drag to reposition — exact same math as NightPulse
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local xpos, ypos = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            xpos = xpos / scale - Minimap:GetLeft() - Minimap:GetWidth()  / 2
            ypos = ypos / scale - Minimap:GetBottom() - Minimap:GetHeight() / 2
            currentAngle = math.atan2(ypos, xpos)
            UpdateMinimapPos(currentAngle)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
        SaveMinimapAngle()
    end)

    btn:SetScript("OnClick", function() DelveGuide.Toggle() end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF00BFFFDelveGuide|r")
        GameTooltip:AddLine("Left-Click to open/close.", 1, 1, 1)
        GameTooltip:AddLine("Drag to reposition.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

SLASH_DELVEGUIDE1="/delveguide"; SLASH_DELVEGUIDE2="/dg"
SlashCmdList["DELVEGUIDE"]=function(msg)
    msg=strtrim(msg:lower())
    if msg=="hide" then if mainFrame then mainFrame:Hide() end
    elseif msg=="show" then if not mainFrame then CreateMainWindow() end; mainFrame:Show()
    elseif msg=="map" then ToggleWorldMap()
    elseif msg=="scan" then
        ScanActiveVariants(); RefreshCurrentTab()
        local vc,dc=0,0
        for _ in pairs(activeVariants) do vc=vc+1 end
        for _ in pairs(activeDelves) do dc=dc+1 end
        print(string.format("|cFF00BFFF[DelveGuide]|r Scan: |cFF44FF44%d|r delves, |cFF44FF44%d|r variants.",dc,vc))
        if vc>0 then
            local list={}; for v in pairs(activeVariants) do table.insert(list,v) end
            print("|cFF00BFFF[DelveGuide]|r Active variants: "..table.concat(list,", "))
        end
    elseif msg=="chatdump" then
        print("|cFF00BFFF[DelveGuide]|r === LOCALIZATION DUMP (share this output) ===")
        print("Version: "..ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
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
    elseif msg=="dump" then
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
    elseif msg=="roster" then
        DelveGuide.Toggle(); SwitchTab("roster")
    elseif msg=="check" then
        ShowChecklist(true)
    elseif msg=="checkdebug" then
        print("|cFF00BFFF[DelveGuide]|r === Valeera Role Debug ===")
        local id = C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer and C_DelvesUI.GetCompanionInfoForActivePlayer()
        print("  companionID: " .. tostring(id))
        if id and id > 0 then
            for roleType, roleName in pairs({[0]="DPS",[1]="Heal",[2]="Tank"}) do
                local node    = C_DelvesUI.GetRoleNodeForCompanion    and C_DelvesUI.GetRoleNodeForCompanion(roleType, id)
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
            print(string.format("  aura[%d] spellID=%d  %s", i, aura.spellId or 0, aura.name or "?"))
            i = i + 1
        end
    elseif msg=="specinfo" then
        local idx = GetSpecialization and GetSpecialization()
        if not idx then print("|cFF00BFFF[DelveGuide]|r GetSpecialization() returned nil"); return end
        local specID, specName = GetSpecializationInfo(idx)
        print(string.format("|cFF00BFFF[DelveGuide]|r specIndex=%d  specID=%d  specName=%s", idx, specID or -1, specName or "nil"))
        local rec = DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID]
        if rec then
            print(string.format("|cFF00BFFF[DelveGuide]|r Rec found: Combat=%s  Utility=%s", rec.combat, rec.utility))
        else
            print("|cFF00BFFF[DelveGuide]|r No rec entry for specID "..tostring(specID))
        end
    elseif msg=="testrun" then
        -- DEV ONLY: simulate a delve completion for the first delve in the DB
        local testName = DelveGuideData and DelveGuideData.delves and DelveGuideData.delves[1] and DelveGuideData.delves[1].name or "Test Delve"
        local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
        local resetKey = secsUntilReset and (math.floor((time()+secsUntilReset-604800)/3600)*3600) or nil
        local testChar="Unknown"; pcall(function() testChar=UnitName("player") or "Unknown" end)
        table.insert(DelveGuideDB.history,1,{name=testName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier="Tier 8",vaultIlvl=610,char=testChar})
        print("|cFF00BFFF[DelveGuide]|r TEST: Injected fake run — |cFF00FF44"..testName.."|r")
        if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
    elseif msg=="help" then
        print("|cFF00BFFF[DelveGuide]|r Commands:")
        print("  |cFFFFFF00/dg|r             — Toggle window")
        print("  |cFFFFFF00/dg scan|r        — Rescan active delve variants")
        print("  |cFFFFFF00/dg minimap|r     — Toggle minimap button")
        print("  |cFFFFFF00/dg hud|r         — Toggle in-run HUD overlay")
        print("  |cFFFFFF00/dg widget|r      — Toggle compact floating widget")
        print("  |cFFFFFF00/dg font [#]|r    — Set font scale, e.g. |cFFFFFF00/dg font 1.2|r  (0.6 – 2.0)")
        print("  |cFFFFFF00/dg map|r         — Open world map")
        print("  |cFFFFFF00/dg dump|r        — Print raw POI data (debug)")
        print("  |cFFFFFF00/dg chatdump|r    — Print full scan results to chat (for localization reports)")
        print("  |cFFFFFF00/dg roster|r      — Open Roster tab")
        print("  |cFFFFFF00/dg check|r       — Show pre-entry checklist")
        print("  |cFFFFFF00/dg checkdebug|r  — Scan auras to find Valeera role spell ID")
        print("  |cFFFFFF00/dg tier [#]|r    — Manually set current delve tier, e.g. |cFFFFFF00/dg tier 8|r")
        print("  |cFFFFFF00/dg specinfo|r    — Show your detected spec ID (debug)")
        print("  |cFFFFFF00/dg help|r        — Show this help")
    elseif msg:sub(1,5)=="tier " then
        local num = tonumber(msg:sub(6))
        if num and num >= 1 and num <= 11 then
            DelveGuide.currentDelveTier    = tostring(num)
            DelveGuide.currentDelveTierNum = num
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            print("|cFF00BFFF[DelveGuide]|r Delve tier set to |cFFCCCCCC" .. num .. "|r")
        else
            print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg tier 3|r  (1–11)")
        end
    elseif msg=="hud" then
        if DelveGuide.ToggleHUD then DelveGuide.ToggleHUD()
        else print("|cFF00BFFF[DelveGuide]|r HUD not loaded.") end
    elseif msg=="widget" then
        DelveGuideDB.widgetHidden = not DelveGuideDB.widgetHidden
        if compactWidget then
            if DelveGuideDB.widgetHidden then compactWidget:Hide() else compactWidget:Show() end
        end
        print("|cFF00BFFF[DelveGuide]|r Compact widget: "..(DelveGuideDB.widgetHidden and "|cFFFF4444hidden|r" or "|cFF44FF44shown|r"))
    elseif msg=="minimap" then
        DelveGuideDB.minimapHidden = not DelveGuideDB.minimapHidden
        if minimapBtn then
            if DelveGuideDB.minimapHidden then minimapBtn:Hide() else minimapBtn:Show() end
        end
        print("|cFF00BFFF[DelveGuide]|r Minimap button: " .. (DelveGuideDB.minimapHidden and "|cFFFF4444hidden|r" or "|cFF44FF44shown|r"))
    elseif msg:sub(1,4)=="font" then
        local val=tonumber(msg:sub(6))
        if val then DelveGuideDB.fontScale=math.max(0.6,math.min(2.0,val)); RefreshCurrentTab()
            print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx",DelveGuideDB.fontScale))
        else print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx (0.6-2.0)",DelveGuideDB.fontScale)) end
    else DelveGuide.Toggle() end
end

StaticPopupDialogs["DELVEGUIDE_CONFIRM_CLEAR_HISTORY"] = {
    text          = "Clear all delve run history? This cannot be undone.",
    button1       = "Clear",
    button2       = "Cancel",
    OnAccept      = function()
        DelveGuideDB.history = {}
        RefreshCurrentTab()
    end,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DELVEGUIDE_CONFIRM_REMOVE_CHAR"] = {
    text          = "Remove %s from your roster?",
    button1       = "Remove",
    button2       = "Cancel",
    OnAccept      = function(self)
        DelveGuideDB.roster[self.data] = nil
        RefreshCurrentTab()
    end,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
}

local loadFrame=CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED"); loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("AREA_POIS_UPDATED"); loadFrame:RegisterEvent("SCENARIO_COMPLETED")
loadFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED"); loadFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
loadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
loadFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
loadFrame:SetScript("OnEvent",function(self,event,arg1)
    if event=="ADDON_LOADED" and arg1==ADDON_NAME then
        InitSavedVars(); CreateMinimapButton(); CreateCompactWidget()
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  *  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_ENTERING_WORLD" then
        -- Only rescan POIs when in the outdoor world — inside an instance the POI data is empty
        -- and would wipe the activeVariants cache that the HUD relies on.
        local inInst, instType = IsInInstance()
        if not inInst then
            DelveGuide.inDelveInstance = false
            C_Timer.After(0, function() ScanActiveVariants(); UpdateCompactWidget() end)
        elseif instType == "scenario" then
            DelveGuide.inDelveInstance = true
        end
        CacheCurrentChar()
        if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
        if DelveGuideDB.lastSeenVersion ~= ADDON_VERSION then
            DelveGuideDB.lastSeenVersion = ADDON_VERSION
            if DelveGuideDB.showChangelog then
                C_Timer.After(3, ShowChangelogPopup)
            end
        end
    elseif event=="AREA_POIS_UPDATED" then
        if not IsInInstance() then
            C_Timer.After(0, function() ScanActiveVariants(); UpdateCompactWidget() end)
        end
        if mainFrame and mainFrame:IsShown() and currentTabKey=="delves" then SwitchTab("delves") end
    elseif event=="ACTIVE_TALENT_GROUP_CHANGED" then
        if mainFrame and mainFrame:IsShown() and currentTabKey=="curios" then SwitchTab("curios") end
    elseif event=="PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
    elseif event=="ZONE_CHANGED_NEW_AREA" then
        -- PLAYER_ENTERING_WORLD does NOT fire on seamless delve zone transitions.
        -- Defer IsInInstance() — at event fire time the instance state isn't settled yet.
        C_Timer.After(1, function()
            local inInst, instType = IsInInstance()
            if inInst and instType == "scenario" then
                DelveGuide.inDelveInstance = true
                if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            else
                DelveGuide.inDelveInstance = false
                if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            end
        end)
    elseif event=="PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        -- arg1==3 is the delve entrance UI. No accessible tier API exists in Midnight 12.0;
        -- tier is set manually via /dg tier N.
        if arg1 == 3 then
            -- Refresh HUD when player is at the entrance (outside the instance)
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
        end
    elseif event=="UNIT_AURA" then
        -- Reserved for future aura-based detection if Blizzard exposes tier via auras.
    elseif event=="SCENARIO_COMPLETED" then
        local scenarioName=C_Scenario.GetInfo()
        if not scenarioName then return end
        -- In Midnight 12.0, C_Scenario.GetInfo() returns the generic "Delves" for all delve completions.
        -- Also fall back to matching specific names in case Blizzard changes this later.
        local isDelve=false
        pcall(function() isDelve=(scenarioName=="Delves") end)
        if not isDelve and DelveGuideData and DelveGuideData.delves then
            for _,d in ipairs(DelveGuideData.delves) do
                local ok,match=pcall(function() return d.name==scenarioName end)
                if ok and match then isDelve=true; break end
            end
        end
        if isDelve then
            -- Get the actual delve name from the zone — more specific than the generic "Delves" scenario name
            local runName="Unknown Delve"
            pcall(function()
                local zone=GetRealZoneText()
                if zone and zone~="" then runName=zone end
            end)

            local secsUntilReset=C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
            local resetKey=secsUntilReset and (math.floor((time()+secsUntilReset-604800)/3600)*3600) or nil

            -- Tier set manually by player via /dg tier N (no addon API exposes it in Midnight 12.0)
            local tier    = DelveGuide.currentDelveTier    or "?"
            local tierNum = DelveGuide.currentDelveTierNum or nil

            -- Vault ilvl: look up from static table first, fall back to C_WeeklyRewards
            local vaultIlvl=nil
            if tierNum and DelveGuideData.tierRewards and DelveGuideData.tierRewards[tierNum] then
                vaultIlvl=DelveGuideData.tierRewards[tierNum].vault
            else
                pcall(function()
                    if Enum and Enum.WeeklyRewardItemTierType then
                        local data=C_WeeklyRewards.GetActivities(Enum.WeeklyRewardItemTierType.World)
                        if data then
                            for _,a in ipairs(data) do
                                if a.level and a.level>0 and a.progress>=a.threshold then
                                    if not vaultIlvl or a.level>vaultIlvl then vaultIlvl=a.level end
                                end
                            end
                        end
                    end
                end)
            end

            local charName="Unknown"
            pcall(function() charName=UnitName("player") or "Unknown" end)

            table.insert(DelveGuideDB.history,1,{name=runName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier=tier,vaultIlvl=vaultIlvl,char=charName})
            if #DelveGuideDB.history>50 then table.remove(DelveGuideDB.history) end
            local vaultStr=vaultIlvl and ("  |cFFFFD700[Vault: "..vaultIlvl.." ilvl]|r") or ""
            print("|cFF00BFFF[DelveGuide]|r Logged: |cFF00FF44"..runName.."|r  |cFF888888["..tier.."]|r"..vaultStr)
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
        end
    end
end)
