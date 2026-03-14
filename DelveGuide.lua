-- ============================================================
-- DelveGuide.lua  –  Main addon logic
-- ============================================================
DelveGuide = {}

local ADDON_NAME       = "DelveGuide"
local WINDOW_W         = 700
local WINDOW_H         = 500
local TAB_HEIGHT       = 28
local BASE_HEADER_SIZE = 14
local BASE_ROW_SIZE    = 11
local BASE_ROW_HEIGHT  = 18

local TABS = {
    { label = "Delves",  key = "delves"  },
    { label = "Curios",  key = "curios"  },
    { label = "Loot",    key = "loot"    },
    { label = "History", key = "history" },
    { label = "Future",  key = "future"  },
    { label = "Debug",   key = "debug"   },
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
        DelveGuideDB = { minimapAngle=225, windowX=nil, windowY=nil, fontScale=1.0, history={} }
    end
    if not DelveGuideDB.fontScale then DelveGuideDB.fontScale = 1.0 end
    if not DelveGuideDB.history then DelveGuideDB.history = {} end -- For existing users
end

local activeDelves   = {}
local activeVariants = {}
local rawScanResults = {}

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
    activeDelves   = {}
    activeVariants = {}
    rawScanResults = {}

    local knownVariants = {}
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            knownVariants[d.variant] = true
        end
    end

    for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
        local poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
        if poiIDs then
            for _, poiID in ipairs(poiIDs) do
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info then
                    local delveName   = info.name or ""
                    local widgetSetID = info.tooltipWidgetSet or 0
                    local widgetTexts = ReadVariantFromWidgetSet(widgetSetID)

                    local variantName = nil
                    local isBountiful = false
                    local hasNemesis  = false
                    
                    for _, t in ipairs(widgetTexts) do
                        local clean = t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
                        clean = clean:gsub("|T.-|t",""):gsub("|A.-|a","")
                        
                        if string.find(clean, "Bountiful", 1, true) then isBountiful = true end
                        if string.find(clean, "Nemesis", 1, true) then hasNemesis = true end

                        for kVariant in pairs(knownVariants) do
                            if string.find(clean, kVariant, 1, true) then
                                variantName = kVariant
                            end
                        end
                    end
                    
                    if delveName ~= "" then 
                        activeDelves[delveName] = { bountiful = isBountiful, nemesis = hasNemesis } 
                    end

                    table.insert(rawScanResults, {
                        mapID       = mapID,
                        zoneName    = ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID       = poiID,
                        name        = delveName,
                        widgetSetID = tostring(widgetSetID),
                        widgetTexts = widgetTexts,
                        variantName = variantName or "(not found)",
                    })
                    if variantName and variantName ~= "" then
                        activeVariants[variantName] = true
                    end
                end
            end
        else
            table.insert(rawScanResults, {
                mapID="", zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A", name="(GetDelvesForMap returned nil)",
                widgetSetID="0", widgetTexts={}, variantName="(nil)",
            })
        end
    end
end

local function IsVariantActive(v) return activeVariants[v] == true end

local HEADER_FONT_FILE, ROW_FONT_FILE = nil, nil
local function EnsureFontFiles()
    if not HEADER_FONT_FILE then
        HEADER_FONT_FILE = GameFontNormalLarge:GetFont() or "Fonts\\FRIZQT__.TTF"
        ROW_FONT_FILE    = GameFontNormalSmall:GetFont()  or "Fonts\\FRIZQT__.TTF"
    end
end
local function GetScaledSizes()
    local s = DelveGuideDB and DelveGuideDB.fontScale or 1.0
    return math.floor(BASE_HEADER_SIZE*s+0.5), math.floor(BASE_ROW_SIZE*s+0.5), math.floor(BASE_ROW_HEIGHT*s+0.5)
end

local function GradeColor(g) return (DelveGuideData.gradeColors[g] or "|cFFFFFFFF")..g.."|r" end
local zoneColors = {["Zul'Aman"]="|cFFFF8C00",["Quel'Thalas"]="|cFF00CED1",["Voidstorm"]="|cFFBF5FFF",["Harandar"]="|cFF7FFF00",["Quel'Danas"]="|cFFFF69B4"}
local function ZoneColor(z) return (zoneColors[z] or "|cFFCCCCCC")..z.."|r" end
local typeColors = { Combat="|cFFFF4444", Utility="|cFF44AAFF" }
local function TypeColor(t) return (typeColors[t] or "|cFFFFFFFF")..t.."|r" end

local function SetDelveWaypoint(pin)
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin.mapID, pin.x, pin.y))
    OpenWorldMap(pin.mapID)
    print("|cFF00BFFF[DelveGuide]|r Waypoint set: |cFFFFD700"..pin.name.."|r")
end
local function FindPinByName(name)
    for _, p in ipairs(DelveGuideData.mapPins) do if p.name==name then return p end end
end

local scrollFrame, currentContent
local tabFrames = {}
local tabFrames = {}
local function NewContentFrame()
    -- Hide and detach the old frame if it exists
    if currentContent then 
        currentContent:Hide()
        currentContent:SetParent(nil)
    end
    
    -- Create a fresh frame
    local cf = CreateFrame("Frame", nil, scrollFrame)
    
    -- Securely grab the width (fallback to window width if it hasn't drawn yet)
    local currentWidth = scrollFrame:GetWidth()
    if not currentWidth or currentWidth == 0 then
        currentWidth = WINDOW_W - 32
    end
    
    cf:SetWidth(currentWidth)
    cf:SetHeight(2000)
    
    scrollFrame:SetScrollChild(cf)
    currentContent = cf
    return cf
end

local function CreateHeader(parent, y, text)
    EnsureFontFiles(); local hSize = GetScaledSizes()
    local fs = parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(HEADER_FONT_FILE, hSize, "OUTLINE")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y)
    fs:SetWidth(parent:GetWidth()-16); fs:SetJustifyH("LEFT")
    fs:SetTextColor(1,0.82,0,1); fs:SetText(text); return hSize + 6
end

local function CreateRow(parent, y, text)
    EnsureFontFiles(); local _, rSize, rH = GetScaledSizes()
    local fs = parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(ROW_FONT_FILE, rSize)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y)
    fs:SetWidth(parent:GetWidth()-16); fs:SetJustifyH("LEFT"); fs:SetText(text); return rH
end

local function CreateDelveRow(parent, y, d)
    EnsureFontFiles(); local _, rSize, rH = GetScaledSizes()
    local rowW = WINDOW_W - 52
    local active = IsVariantActive(d.variant)
    
    if active then
        local fill = parent:CreateTexture(nil, "BACKGROUND")
        fill:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -(y-1))
        fill:SetSize(rowW - 4, rH + 2)
        -- Set base texture so the gradient has something to paint onto
        fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        -- Create an elegant horizontal fade: Bright Green -> Fully Transparent
        fill:SetGradient("HORIZONTAL", CreateColor(0, 0.7, 0.15, 0.35), CreateColor(0, 0.7, 0.15, 0))
        
        local bar = parent:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -(y-1))
        bar:SetSize(3, rH + 2) -- Thinner, sharper accent line
        bar:SetColorTexture(0, 1, 0.2, 1)
    end
    
    local gradeFS = parent:CreateFontString(nil,"OVERLAY"); gradeFS:SetFont(ROW_FONT_FILE,rSize)
    gradeFS:SetPoint("TOPLEFT",parent,"TOPLEFT",10,-y); gradeFS:SetWidth(46); gradeFS:SetJustifyH("LEFT")
    gradeFS:SetText(string.format("[%s]",GradeColor(d.ranking)))
    
    local pin = FindPinByName(d.name)
    local nameBtn = CreateFrame("Button",nil,parent); nameBtn:SetSize(160,rH)
    nameBtn:SetPoint("TOPLEFT",parent,"TOPLEFT",56,-y+1)
    local nameFS = nameBtn:CreateFontString(nil,"OVERLAY"); nameFS:SetFont(ROW_FONT_FILE,rSize)
    nameFS:SetAllPoints(nameBtn); nameFS:SetJustifyH("LEFT")
    
    if pin then
        nameFS:SetText("|cFF00CFFF"..d.name.."|r")
        nameBtn:SetScript("OnEnter",function(self)
            nameFS:SetText("|cFFFFFFFF"..d.name.."|r")
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine("|cFFFFD700"..d.name.."|r")
            GameTooltip:AddLine("|cFFCCCCCC"..d.zone.."|r"); GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF88Click to open map & set waypoint|r"); GameTooltip:Show()
        end)
        nameBtn:SetScript("OnLeave",function(self) nameFS:SetText("|cFF00CFFF"..d.name.."|r") GameTooltip:Hide() end)
        nameBtn:SetScript("OnClick",function() SetDelveWaypoint(pin) end)
    else nameFS:SetText(d.name) end
    
    local variantText = active and "|cFF44FF44"..d.variant.."|r" or d.variant
    local flags = ""
    if d.isBestRoute then flags=flags.."|cFF00FF00[Best]|r " end
    if d.hasBug       then flags=flags.."|cFFFF4444[Bug]|r "  end
    if d.mountable    then flags=flags.."|cFFFFD700[Mt]|r "   end
    
    local delveStatus = activeDelves[d.name]
    if type(delveStatus) == "table" then
        if delveStatus.bountiful then flags = flags.."|cFFFFFF00[Bountiful]|r " end
        if delveStatus.nemesis   then flags = flags.."|cFFFF4444[Nemesis]|r " end
    end
    
    local infoFS = parent:CreateFontString(nil,"OVERLAY"); infoFS:SetFont(ROW_FONT_FILE,rSize)
    infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y); infoFS:SetWidth(rowW-310); infoFS:SetJustifyH("LEFT")
    infoFS:SetText(ZoneColor(d.zone).."  "..variantText.."  "..flags)
    
    if active then
        local todayFS = parent:CreateFontString(nil,"OVERLAY"); todayFS:SetFont(ROW_FONT_FILE,rSize,"OUTLINE")
        todayFS:SetPoint("TOPLEFT", parent, "TOPLEFT", rowW - 80, -y)
        todayFS:SetJustifyH("LEFT"); todayFS:SetText("|cFF00FF44★ TODAY|r")
    end
    return rH
end

local function RenderDelves()
    local cf = NewContentFrame(); local y = 10
    local vc = 0; for _ in pairs(activeVariants) do vc=vc+1 end

    -- Feature 2: Weekly Items Check
    local troveCount = C_Item.GetItemCount(265714, true) or 0
    -- FIX: Removed the "player" argument. This API only takes the spellID!
    local hasTroveAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(1254631)
    local troveText = hasTroveAura and "|cFF00FF44Active|r" or (troveCount > 0 and "|cFFFFFF00In Bags|r" or "|cFFFF4444None|r")
    
    local beaconCount = C_Item.GetItemCount(253342, true) or 0
    local beaconText = beaconCount > 0 and "|cFF00FF44"..beaconCount.." in Bags|r" or "|cFFFF4444None|r"

    local activeData, inactiveData = {}, {}
    for _, d in ipairs(DelveGuideData.delves) do
        if IsVariantActive(d.variant) then table.insert(activeData, d)
        else table.insert(inactiveData, d) end
    end

    local note = vc > 0 and "  |cFF44FF44("..vc.." active today)|r" or "  |cFFAAAAAA(use /dg scan to find active delves)|r"
    y = y + CreateHeader(cf, y, "Delve Rankings — S=Fastest | F=Slowest" .. note) + 4
    
    -- The Checklist UI
    y = y + CreateRow(cf, y, string.format("|cFF3088FFWeekly Items:|r  Trovehunter's Bounty: %s   |   Beacon of Hope: %s", troveText, beaconText))
    y = y + 8

    y = y + CreateRow(cf, y, "|cFFAAAAAA"..string.format("%-6s  %-22s  %-14s  %s","Rank","Delve","Zone","Variant / Flags").."|r")
    y = y + CreateRow(cf, y, "|cFF555555"..string.rep("─",90).."|r") + 2

    if vc > 0 then
        y = y + 4
        y = y + CreateRow(cf, y, "|cFF00FF44── ★ ACTIVE TODAY ──|r")
        for _, d in ipairs(activeData) do y = y + CreateDelveRow(cf, y, d) end
        y = y + 12
        y = y + CreateRow(cf, y, "|cFF888888── ALL VARIANTS (INACTIVE) ──|r")
    end

    local lastZone = ""
    for _, d in ipairs(inactiveData) do
        if d.zone ~= lastZone then 
            y = y + 4
            y = y + CreateRow(cf, y, "|cFF666666── "..d.zone.." ──|r") 
            lastZone = d.zone 
        end
        y = y + CreateDelveRow(cf, y, d)
    end
    cf:SetHeight(y+20)
end

local function RenderCurios()
    local cf = NewContentFrame(); local y = 10
    y = y + CreateHeader(cf, y, "Curios Rankings  —  S=Best  |  F=Worst") + 4
    y = y + 4
    y = y + CreateRow(cf, y, "|cFFFFD700── Season 1 Recommended Valeera Loadouts ──|r")
    y = y + CreateRow(cf, y, "|cFF00FF00Safe / Progression:|r Mantle of Stars (Combat) + Motionless Nulltide (Utility)")
    y = y + CreateRow(cf, y, "|cFFFF4444Speed / Farming:|r   Sanctum's Edict (Combat) + Ebon Crown of Subjugation (Utility)")
    y = y + CreateRow(cf, y, "|cFF555555"..string.rep("─",90).."|r") + 4
    for _, ctype in ipairs({"Combat","Utility"}) do
        y=y+4; y=y+CreateRow(cf,y,TypeColor(ctype).." Curios")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-4s  %-32s  %s","Rank","Name","Effect").."|r")
        for _, c in ipairs(DelveGuideData.curios) do
            if c.curiotype==ctype then y=y+CreateRow(cf,y,string.format("[%s]  %-32s  %s",GradeColor(c.ranking),c.name,c.description)) end
        end; y=y+8
    end; cf:SetHeight(y+20)
end

local function RenderLoot()
    local cf = NewContentFrame(); local y = 10
    y = y + CreateHeader(cf, y, "Notable Loot  —  Trinkets & Weapons from Midnight Delves") + 4
    
    -- Original Notable Loot
    for _, slot in ipairs({"Trinket","Weapon"}) do
        y=y+4; y=y+CreateRow(cf,y,"|cFFFFD700"..slot.."s|r")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-36s  %s","Item Name","Effect / Notes").."|r")
        for _, item in ipairs(DelveGuideData.loot) do
            if item.slot==slot then y=y+CreateRow(cf,y,string.format("|cFF00BFFF%-36s|r  %s",item.name,item.notes)) end
        end; y=y+8
    end
    
    -- Feature 1: The Tier iLvl Table
    y = y + 8
    y = y + CreateRow(cf, y, "|cFFFFD700── Midnight Delve iLvl Scaling ──|r")
    y = y + CreateRow(cf, y, "|cFF888888Tier  Recommended  Bountiful Drop  Great Vault|r")
    
    local delveTiers = {
        { t=1,  r=170, b=220, v=233 }, { t=2,  r=187, b=224, v=237 },
        { t=3,  r=200, b=227, v=240 }, { t=4,  r=213, b=230, v=243 },
        { t=5,  r=222, b=233, v=246 }, { t=6,  r=229, b=237, v=253 },
        { t=7,  r=235, b=246, v=256 }, { t=8,  r=244, b=250, v=259 },
        { t=9,  r=250, b=250, v=259 }, { t=10, r=257, b=250, v=259 },
        { t=11, r=265, b=250, v=259 }
    }
    for _, d in ipairs(delveTiers) do
        y = y + CreateRow(cf, y, string.format(" %-5d %-12d |cFF00FF00%-14d|r |cFF00BFFF%d|r", d.t, d.r, d.b, d.v))
    end
    
    cf:SetHeight(y+20)
end

local function RenderFuture()
    local cf = NewContentFrame(); local y = 10
    y = y + CreateHeader(cf, y, "Future / Upcoming Content & Patch Notes") + 4
    local seen, cats = {}, {}
    for _, f in ipairs(DelveGuideData.future) do
        if not seen[f.category] then seen[f.category]=true; table.insert(cats,f.category) end
    end
    for _, cat in ipairs(cats) do
        y=y+4; y=y+CreateRow(cf,y,"|cFF00FF88"..cat.."|r")
        for _, f in ipairs(DelveGuideData.future) do
            if f.category==cat then y=y+CreateRow(cf,y,"|cFFCCCCCC• |r"..f.note)+2 end
        end; y=y+8
    end; cf:SetHeight(y+20)
end

local function RenderDebug()
    local cf = NewContentFrame(); local y = 10
    y = y + CreateHeader(cf, y, "DEBUG — Variant Detection Results") + 4
    y = y + CreateRow(cf, y, "|cFFFFFF00/dg scan  refreshes  |  /dg dump  prints raw API fields to chat|r") + 8
    if #rawScanResults == 0 then
        y = y + CreateRow(cf, y, "|cFFFF4444No data — type /dg scan first.|r")
    else
        local vc = 0; for _ in pairs(activeVariants) do vc=vc+1 end
        local vcColor = vc > 0 and "|cFF44FF44" or "|cFFFF4444"
        y = y + CreateRow(cf, y, string.format("%s%d variant(s) detected today:|r", vcColor, vc))
        if vc == 0 then
            y = y + CreateRow(cf, y, "|cFFFF4444  Widget texts empty — hover a delve on the map then /dg scan.|r")
        else
            for v in pairs(activeVariants) do y = y + CreateRow(cf, y, "|cFF44FF44  ✓ "..v.."|r") end
        end
        y = y + 8
        y = y + CreateRow(cf, y, "|cFFFFD700── Per-Delve Widget Texts ──|r")
        for _, r in ipairs(rawScanResults) do
            y = y + 4
            local vColor = (r.variantName=="(not found)" or r.variantName=="(nil)") and "|cFFFF4444" or "|cFF44FF44"
            y = y + CreateRow(cf, y, string.format("|cFFFFD700%-24s|r  set=%-6s  → %s%s|r",
                r.name, r.widgetSetID, vColor, r.variantName))
            if r.widgetTexts and #r.widgetTexts > 0 then
                for _, t in ipairs(r.widgetTexts) do y = y + CreateRow(cf, y, "   |cFF888888> "..t.."|r") end
            else
                y = y + CreateRow(cf, y, "   |cFF555555(no texts in widget set)|r")
            end
        end
    end
    cf:SetHeight(y + 20)
end

local function RenderHistory()
    local cf = NewContentFrame(); local y = 10
    y = y + CreateHeader(cf, y, "Delve Run History (Last 50 Runs)") + 4

    if not DelveGuideDB.history or #DelveGuideDB.history == 0 then
        y = y + CreateRow(cf, y, "|cFF888888No runs recorded yet. Go complete a Delve!|r")
    else
        y = y + CreateRow(cf, y, "|cFF888888"..string.format("%-20s  %-24s", "Date & Time", "Delve Completed").."|r")
        y = y + CreateRow(cf, y, "|cFF555555"..string.rep("─",90).."|r") + 4
        for _, run in ipairs(DelveGuideDB.history) do
            y = y + CreateRow(cf, y, string.format("|cFFCCCCCC%-20s|r  |cFF00BFFF%-24s|r", run.date, run.name))
        end
    end
    
    cf:SetHeight(y + 20)
end

local tabRenderers = { delves=RenderDelves, curios=RenderCurios, loot=RenderLoot, history=RenderHistory, future=RenderFuture, debug=RenderDebug }
local mainFrame, tabButtons, currentTabKey = nil, {}, nil

local function SwitchTab(key)
    currentTabKey = key
    for _, td in ipairs(TABS) do
        local btn = tabButtons[td.key]
        if td.key == key then
            btn.Text:SetTextColor(1, 0.82, 0, 1) -- Gold text
            btn.Underline:Show()                 -- Show highlight bar
        else
            btn.Text:SetTextColor(0.5, 0.5, 0.5, 1) -- Dim text
            btn.Underline:Hide()                 -- Hide highlight bar
        end
    end
    local r = tabRenderers[key]; if r then r(); scrollFrame:SetVerticalScroll(0) end
end

local function RefreshCurrentTab() if currentTabKey then SwitchTab(currentTabKey) end end

local function CreateMainWindow()
    -- Use BackdropTemplate for a custom flat design
    local f = CreateFrame("Frame", "DelveGuideFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_W, WINDOW_H)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        DelveGuideDB.windowX = self:GetLeft()
        DelveGuideDB.windowY = self:GetTop() 
    end)
    
    if DelveGuideDB.windowX then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DelveGuideDB.windowX, DelveGuideDB.windowY)
    else 
        f:SetPoint("CENTER") 
    end
    f:SetFrameStrata("HIGH"); f:Hide()

    -- Apply the modern flat dark backdrop
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.92) -- Very dark gray/black, slightly transparent
    f:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) -- Clean, subtle edge

    -- Manually add a Close button since we removed the Blizzard template
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

    -- Modern Title Text
    f.TitleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.TitleText:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
    f.TitleText:SetText("|cFF00BFFFDelveGuide|r — Midnight Reference")
    
    f.TrackerText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.TrackerText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -40, -14)
    
    f.UpdateTracker = function()
        local keysInfo = C_CurrencyInfo.GetCurrencyInfo(3310) 
        local shards = keysInfo and keysInfo.quantity or 0
        local completed = 0
        
        -- Safe Vault Check
        if Enum and Enum.WeeklyRewardItemTierType and Enum.WeeklyRewardItemTierType.World then
            local success, vaultActivities = pcall(C_WeeklyRewards.GetActivities, Enum.WeeklyRewardItemTierType.World)
            if success and type(vaultActivities) == "table" then
                for _, act in ipairs(vaultActivities) do
                    if act.progress >= act.threshold then completed = completed + 1 end
                end
            end
        end
        
        -- Feature 3: Scan for WQs offering Coffer Key Shards
        local wqCount = 0
        local zonesToCheck = {2393, 2437, 2395, 2444, 2413, 2405, 2424}
        for _, z in ipairs(zonesToCheck) do
            local quests = C_TaskQuest.GetQuestsOnMap(z)
            if quests then
                for _, q in ipairs(quests) do
                    if C_QuestLog.IsWorldQuest(q.questID) and not C_QuestLog.IsQuestFlaggedCompleted(q.questID) then
                        local currencies = C_QuestLog.GetQuestRewardCurrencies(q.questID)
                        if currencies then
                            for _, c in ipairs(currencies) do
                                if c.currencyID == 3310 then wqCount = wqCount + 1 end
                            end
                        end
                    end
                end
            end
        end
        
        f.TrackerText:SetText(string.format("|cFFFFD700Keys:|r %d/600  |  |cFF00BFFFVault:|r %d/8  |  |cFF00FF88Shard WQs:|r %d", shards, completed, wqCount))
    end

    f:HookScript("OnShow", f.UpdateTracker)
    
    local function MakeFontBtn(label,xOff,onClick,tip)
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); b:SetSize(28,18)
        b:SetPoint("TOPRIGHT",f,"TOPRIGHT",xOff,-12); b:SetText(label); b:SetScript("OnClick",onClick)
        b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:AddLine(tip)
            GameTooltip:AddLine(string.format("|cFFAAAAAACurrent: %.1fx|r",DelveGuideDB.fontScale)); GameTooltip:Show() end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    MakeFontBtn("A-",-200,function() DelveGuideDB.fontScale=math.max(0.6,DelveGuideDB.fontScale-0.1); RefreshCurrentTab() end,"Decrease text size")
    MakeFontBtn("A+",-230,function() DelveGuideDB.fontScale=math.min(2.0,DelveGuideDB.fontScale+0.1); RefreshCurrentTab() end,"Increase text size")
    
    local tabW = (WINDOW_W - 32) / #TABS
    for i, td in ipairs(TABS) do
        local btn = CreateFrame("Button", "DelveGuideTab_"..td.key, f)
        btn:SetSize(tabW - 4, TAB_HEIGHT)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + (i - 1) * tabW, -36)
        
        -- Flat text instead of a button texture
        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.Text:SetPoint("CENTER")
        btn.Text:SetText(td.label)
        
        -- Create the Gold Underline
        btn.Underline = btn:CreateTexture(nil, "ARTWORK")
        btn.Underline:SetColorTexture(1, 0.82, 0, 1)
        btn.Underline:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
        btn.Underline:SetSize(btn.Text:GetStringWidth() + 16, 2)
        btn.Underline:Hide()
        
        local k = td.key
        btn:SetScript("OnClick", function() SwitchTab(k) end)
        tabButtons[k] = btn
    end
    
    local sf=CreateFrame("ScrollFrame","DelveGuideScrollFrame",f,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",f,"TOPLEFT",16,-(36+TAB_HEIGHT+10)); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,8)
    scrollFrame=sf; mainFrame=f; SwitchTab(TABS[1].key)
end

function DelveGuide.Toggle()
    if not mainFrame then CreateMainWindow() end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end

local minimapBtn = nil
-- Ported from MidnightCheck: cleaner left-drag pattern using RegisterForDrag.
-- Angle saved in degrees to DelveGuideDB.minimapAngle.
local function UpdateMinimapPos()
    local a = math.rad(DelveGuideDB.minimapAngle or 45)
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end

local function CreateMinimapButton()
    local btn = CreateFrame("Button", "DelveGuideMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)

    -- Map icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map09")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    -- Tracking ring border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", -11, 11)

    -- Hover highlight
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Left-drag to reposition (same pattern as MidnightCheck / NightPulse)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local cx, cy = GetCursorPosition()
            local scale  = self:GetEffectiveScale()
            local mx     = Minimap:GetLeft()   + Minimap:GetWidth()  / 2
            local my     = Minimap:GetBottom() + Minimap:GetHeight() / 2
            local angle  = math.atan2(cy / scale - my, cx / scale - mx)
            DelveGuideDB.minimapAngle = math.deg(angle)
            minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
                math.cos(angle) * 80, math.sin(angle) * 80)
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self:SetScript("OnUpdate", nil)
    end)

    -- Left-click to toggle (click fires on up, after drag is already stopped)
    btn:SetScript("OnClick", function() DelveGuide.Toggle() end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFF00BFFFDelveGuide|r")
        GameTooltip:AddLine("Left-click: open/close", 1, 1, 1)
        GameTooltip:AddLine("Left-drag: reposition",  0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    minimapBtn = btn
    UpdateMinimapPos()
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
        for _ in pairs(activeDelves)   do dc=dc+1 end
        print(string.format("|cFF00BFFF[DelveGuide]|r Scan: |cFF44FF44%d|r delves, |cFF44FF44%d|r variants.",dc,vc))
        if vc > 0 then
            local list={}; for v in pairs(activeVariants) do table.insert(list,v) end
            print("|cFF00BFFF[DelveGuide]|r Active variants: "..table.concat(list,", "))
        end
    elseif msg=="dump" then
        print("|cFF00BFFF[DelveGuide]|r === RAW POI FIELD DUMP ===")
        local found=0
        for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
            local poiIDs=C_AreaPoiInfo.GetDelvesForMap(mapID)
            if poiIDs and #poiIDs>0 then
                local info=C_AreaPoiInfo.GetAreaPOIInfo(mapID,poiIDs[1])
                print(string.format("|cFFFFD700mapID=%-6d  poiID=%d|r",mapID,poiIDs[1]))
                if info then
                    for k,v in pairs(info) do
                        local vs=tostring(v)
                        local c=(vs=="" or vs=="false" or vs=="0") and "|cFF888888" or "|cFF44FF44"
                        print(string.format("  |cFFCCCCCC%-22s|r = %s%s|r",tostring(k),c,vs))
                    end; found=found+1
                else print("  |cFFFF4444(nil)|r") end
                if found>=2 then break end
            end
        end
        if found==0 then print("|cFFFF4444No delves found.|r") end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg:sub(1,4)=="font" then
        local val=tonumber(msg:sub(6))
        if val then DelveGuideDB.fontScale=math.max(0.6,math.min(2.0,val)); RefreshCurrentTab()
            print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx",DelveGuideDB.fontScale))
        else print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx (0.6-2.0)",DelveGuideDB.fontScale)) end
    else DelveGuide.Toggle() end
end

local loadFrame=CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("AREA_POIS_UPDATED")
loadFrame:RegisterEvent("SCENARIO_COMPLETED") -- New Event Hook

loadFrame:SetScript("OnEvent",function(self,event,arg1)
    if event=="ADDON_LOADED" and arg1==ADDON_NAME then
        InitSavedVars(); CreateMinimapButton()
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  •  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event=="PLAYER_ENTERING_WORLD" then
        ScanActiveVariants()
        if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
        
    elseif event=="AREA_POIS_UPDATED" then
        ScanActiveVariants()
        if mainFrame and mainFrame:IsShown() and currentTabKey=="delves" then SwitchTab("delves") end
        
    elseif event=="SCENARIO_COMPLETED" then
        -- Grab the name of the scenario that just finished
        local scenarioName = C_Scenario.GetInfo()
        if not scenarioName then return end
        
        -- Check if it's a known Delve from our database
        local isDelve = false
        if DelveGuideData and DelveGuideData.delves then
            for _, d in ipairs(DelveGuideData.delves) do
                if d.name == scenarioName then isDelve = true; break end
            end
        end
        
        -- If it's a delve, log the date and time
        if isDelve then
            local timestamp = date("%Y-%m-%d %H:%M")
            table.insert(DelveGuideDB.history, 1, {
                name = scenarioName,
                date = timestamp
            })
            
            -- Keep the database clean by only saving the last 50 runs
            if #DelveGuideDB.history > 50 then 
                table.remove(DelveGuideDB.history) 
            end
            
            print("|cFF00BFFF[DelveGuide]|r Logged completion: |cFF00FF44"..scenarioName.."|r")
            
            -- Refresh the UI if the user is looking at the History tab right now
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then 
                SwitchTab("history") 
            end
        end
    end
end)