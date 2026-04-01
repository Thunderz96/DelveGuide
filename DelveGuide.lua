-- ============================================================
-- DelveGuide.lua  --  Main addon logic
-- ============================================================
DelveGuide = {}

local ADDON_NAME       = "DelveGuide"
local ADDON_VERSION    = "1.7.3"
local WINDOW_W         = 700
local WINDOW_H         = 500
local TAB_HEIGHT       = 28
local BASE_HEADER_SIZE = 14
local BASE_ROW_SIZE    = 11
local BASE_ROW_HEIGHT  = 18

local TABS = {
    --{ label = "Dashboard", key = "dashboard" },
    { label = "Delves",   key = "delves"   },
    { label = "Curios",   key = "curios"   },
    { label = "Companion", key = "companion" },
    { label = "Loot",     key = "loot"     },
    { label = "Nullaeus", key = "nullaeus" },
    { label = "History",  key = "history"  },
    { label = "Future",   key = "future"   },
    { label = "Roster",   key = "roster"   },
    { label = "Settings", key = "settings" },
    { label = "Debug",    key = "debug"    },
}

local ALL_ZONE_MAP_IDS = { 2393, 2437, 2395, 2444, 2413, 2405 }

-- Widget set ID → English DELVE name (not variant name).
-- Set IDs are per-delve-entrance and their text content changes daily.
-- Used only to resolve localized delve names → English names on non-EN clients.
local WIDGET_SET_DELVES = {
    [1611] = "Collegiate Calamity",
    [1738] = "The Grudge Pit",
    [1800] = "Sunkiller Sanctum",
    [1801] = "Shadowguard Point",
    [1802] = "Atal'Aman",
    [1803] = "The Gulf of Memory",
    [1804] = "The Shadow Enclave",
    [1805] = "Twilight Crypts",
}

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
    if not DelveGuideDB.minimap then DelveGuideDB.minimap = { hide = false } end
    if not DelveGuideDB.fontScale then DelveGuideDB.fontScale = 1.0 end
    if not DelveGuideDB.history then DelveGuideDB.history = {} end
    if DelveGuideDB.minimapHidden == nil then DelveGuideDB.minimapHidden = false end
    if DelveGuideDB.widgetHidden == nil then DelveGuideDB.widgetHidden = false end
    if DelveGuideDB.widgetClickOpens == nil then DelveGuideDB.widgetClickOpens = false end
    if not DelveGuideDB.widgetTiers then DelveGuideDB.widgetTiers = {S=true,A=true,B=true,C=true,D=true,F=true} end
    if DelveGuideDB.widgetLocked == nil then DelveGuideDB.widgetLocked = false end
    if DelveGuideDB.hudLocked      == nil then DelveGuideDB.hudLocked      = false end
    if DelveGuideDB.hudEnabled     == nil then DelveGuideDB.hudEnabled     = true  end
    if DelveGuideDB.widgetAutoHide == nil then DelveGuideDB.widgetAutoHide = false end
    if DelveGuideDB.checklistEnabled == nil then DelveGuideDB.checklistEnabled = true end
    if DelveGuideDB.showChangelog == nil then DelveGuideDB.showChangelog = true end
    if DelveGuideDB.mapTooltips == nil then DelveGuideDB.mapTooltips = true end
    -- checklistDismissed is session-only; reset on every load
    DelveGuideDB.checklistDismissed = false
    if not DelveGuideDB.roster then DelveGuideDB.roster = {} end
    if not DelveGuideDB.missingTranslations then DelveGuideDB.missingTranslations = {} end
    -- lastSeenVersion drives the "what's new" popup (nil = never shown)
    if DelveGuideDB.lastSeenVersion == nil then DelveGuideDB.lastSeenVersion = nil end
end

local activeDelves, activeVariants, rawScanResults = {}, {}, {}
local localizedToEnglish = {}  -- maps localized zone name → English zone name (non-EN clients)
local minimapBtn, currentAngle, RefreshCurrentTab, icon

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
    activeDelves, activeVariants, rawScanResults, localizedToEnglish = {}, {}, {}, {}
    DelveGuide.activeDelves        = activeDelves
    DelveGuide.activeVariants      = activeVariants
    DelveGuide.rawScanResults       = rawScanResults
    DelveGuide.localizedToEnglish  = localizedToEnglish
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
                poiID="N/A",name="(GetDelvesForMap returned empty - map IDs may not match this region)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
        else
            for _, poiID in ipairs(poiIDs) do
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info then
                    local delveName=info.name or ""; local widgetSetID=info.tooltipWidgetSet or 0
                    local widgetTexts=ReadVariantFromWidgetSet(widgetSetID)
                    local atlasName = info.atlasName or ""
                    local variantName,isBountiful,hasNemesis=nil,false,false
                    if atlasName:find("bountiful",1,true) then isBountiful=true end
                    -- Variant detection: text matching first (reads today's actual widget text)
                    for _, t in ipairs(widgetTexts) do
                        local clean=t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")
                        if string.find(clean,"Nemesis",1,true) then hasNemesis=true end
                        if not variantName then
                            -- Try English text match first (EN clients)
                            for kVariant in pairs(knownVariants) do
                                if string.find(clean,kVariant,1,true) then variantName=kVariant end
                            end
                            -- Non-EN fallback: Substring match!
                            if not variantName and DelveGuideData.localeVariants then
                                for locName, engName in pairs(DelveGuideData.localeVariants) do
                                    if string.find(clean, locName, 1, true) then
                                        variantName = engName
                                        break
                                    end
                                end
                            end
                        end
                    end
                    -- Key activeDelves by English zone name so lookups work on all locales.
                    -- For EN clients, info.name is already English.
                    -- For non-EN clients, use widget set ID → delve name mapping as fallback.
                    local engZoneName = delveName
                    local delveFromSetID = DelveGuideData.widgetSetDelves and DelveGuideData.widgetSetDelves[widgetSetID]
                    if delveFromSetID then
                        engZoneName = delveFromSetID
                    elseif variantName and DelveGuideData and DelveGuideData.delves then
                        for _, d in ipairs(DelveGuideData.delves) do
                            if d.variant == variantName then engZoneName = d.name; break end
                        end
                    end
                    if engZoneName~="" then
                        activeDelves[engZoneName]={bountiful=isBountiful,nemesis=hasNemesis}
                        if delveName~=engZoneName then localizedToEnglish[delveName]=engZoneName end
                    end

                    -- If we don't know the translation, quarantine the text safely
                    if not variantName or variantName == "" then
                        local safeText = (widgetTexts and widgetTexts[1]) and widgetTexts[1] or "Unknown Variant Text"
                        -- Strip WoW color codes from the raw text to make it readable
                        safeText = safeText:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")
                        variantName = "[Missing Translation] " .. safeText

                        -- Log to SavedVariables for the Debug tab
                        if DelveGuideDB and DelveGuideDB.missingTranslations then
                            local locale = GetLocale and GetLocale() or "unknown"
                            local entryKey = locale .. ":" .. safeText
                            if not DelveGuideDB.missingTranslations[entryKey] then
                                DelveGuideDB.missingTranslations[entryKey] = {
                                    text      = safeText,
                                    locale    = locale,
                                    delve     = delveName,
                                    mapID     = mapID,
                                    firstSeen = date("%Y-%m-%d"),
                                }
                            end
                        end
                    end

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
local RANK_ORDER={S=1,A=2,B=3,C=4,D=5,F=6}
local function TypeColor(t) return (typeColors[t] or "|cFFFFFFFF")..t.."|r" end

local function SetDelveWaypoint(pin)
    if TomTom then
        TomTom:AddWaypoint(pin.mapID, pin.x, pin.y, {
            title = pin.name,
            persistent = false,
            minimap = true,
            world = true
        })
        print("|cFF00BFFF[DelveGuide]|r TomTom waypoint set: |cFFFFD700"..pin.name.."|r")
    else
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin.mapID, pin.x, pin.y))
        print("|cFF00BFFF[DelveGuide]|r Waypoint set: |cFFFFD700"..pin.name.."|r |cFF888888(press M to open map)|r")
    end
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
    fs:SetJustifyH("LEFT"); fs:SetTextColor(1,0.82,0,1); fs:SetText(text)
    
    local actualHeight = fs:GetStringHeight()
    return ((actualHeight and actualHeight > 0) and actualHeight or hSize) + 6
end

local function CreateRow(parent,y,text)
    EnsureFontFiles(); local _,rSize,rH=GetScaledSizes()
    local fs=parent:CreateFontString(nil,"OVERLAY"); fs:SetFont(ROW_FONT_FILE,rSize)
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-y); fs:SetWidth(parent:GetWidth()-16)
    fs:SetJustifyH("LEFT"); fs:SetText(text)
    local actualHeight = fs:GetStringHeight()
    local finalHeight = (actualHeight and actualHeight > 0) and actualHeight or rH
    
    return finalHeight
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
    local delveCount, slots, maxThreshold, acts = 0, 0, 0, {}
    -- Midnight 12.0: Enum.WeeklyRewardItemTierType removed. Call GetActivities()
    -- with no argument and filter by type. Delves = WeeklyRewardChestThresholdType.World (6).
    local DELVE_TYPE = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World) or 6
    local ok, data = pcall(C_WeeklyRewards.GetActivities)
    if ok and type(data) == "table" then
        for _, a in ipairs(data) do
            if a.type == DELVE_TYPE then
                if a.progress > delveCount then delveCount = a.progress end
                if a.threshold > maxThreshold then maxThreshold = a.threshold end
                if a.progress >= a.threshold then slots = slots + 1 end
                table.insert(acts, a)
            end
        end
    end
    return delveCount, slots, maxThreshold, acts
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
    local specIcon = nil -- NEW: Store the spec icon
    pcall(function()
        local idx = GetSpecialization()
        if idx then
            local _, sName, _, icon = GetSpecializationInfo(idx)
            if sName then 
                specName = sName
                specIcon = icon 
            end
        end
    end)

    local ilvl = 0
    pcall(function()
        local _, overall = GetAverageItemLevel()
        ilvl = math.floor(overall or 0)
    end)

    local shards = 0
    pcall(function()
        local info = C_CurrencyInfo.GetCurrencyInfo(3310)
        if info then shards = info.quantity or 0 end
    end)

    local bounty = C_Item.GetItemCount(265714, true) or 0
    local restoredKeyInfo = C_CurrencyInfo.GetCurrencyInfo(3028)
    local restoredKeys = restoredKeyInfo and restoredKeyInfo.quantity or 0

    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    local resetKey = secsUntilReset and (math.floor((time() + secsUntilReset - 604800) / 3600) * 3600) or nil
    
    local delveCount = 0
    local weeklyRuns = {} 
    if resetKey and DelveGuideDB.history then
        for _, h in ipairs(DelveGuideDB.history) do
            if h.resetKey == resetKey and h.char == name then
                delveCount = delveCount + 1
                table.insert(weeklyRuns, h)
            end
        end
    end

    local _, vaultSlots, _, acts = GetWeeklyVaultData()
    local maxVaultIlvl = 0 
    for _, a in ipairs(acts) do
        if a.progress >= a.threshold and a.level and a.level > maxVaultIlvl then
            maxVaultIlvl = a.level
        end
    end

    DelveGuideDB.roster[charKey] = {
        name         = name,
        realm        = realm,
        specName     = specName,
        specIcon     = specIcon,     
        ilvl         = ilvl,
        shards       = shards,
        restoredKeys = restoredKeys,
        bounty       = bounty,
        delveCount   = delveCount,
        weeklyRuns   = weeklyRuns,   
        vaultSlots   = vaultSlots,
        maxVaultIlvl = maxVaultIlvl, 
        lastSeen     = date("%Y-%m-%d"),
        resetKey     = resetKey,
    }
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
        title:SetText("|cFF3399FFDelveGuide|r  --  What's New")

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

        for _, block in ipairs(DelveGuideData.changelog) do
            local verLabel = content:CreateFontString(nil, "OVERLAY")
            verLabel:SetFont(ROW_FONT, isFirst and 13 or 11)
            verLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -cy)
            verLabel:SetWidth(content:GetWidth())
            if isFirst then
                verLabel:SetText("|cFF3399FFv" .. block.version .. "|r  |cFF888888- " .. block.date .. "|r")
            else
                verLabel:SetText("|cFF666666v" .. block.version .. "  - " .. block.date .. "|r")
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

-- ============================================================
-- GLOBAL UI HELPERS (For external UI modules)
-- ============================================================
DelveGuide.UI = {
    NewContentFrame = NewContentFrame,
    CreateHeader    = CreateHeader,
    CreateRow       = CreateRow,
    GetScaledSizes  = GetScaledSizes,
    EnsureFontFiles = EnsureFontFiles,
    WINDOW_W        = WINDOW_W,
    GradeColor      = GradeColor,
    ZoneColor       = ZoneColor,
    TypeColor       = TypeColor,
    RANK_COLORS     = RANK_COLORS,
    SetDelveWaypoint= SetDelveWaypoint,
    FindPinByName   = FindPinByName,
    GetWeeklyVaultData = GetWeeklyVaultData,
    ShowChangelogPopup = ShowChangelogPopup,
    RefreshCurrentTab  = function() if RefreshCurrentTab then RefreshCurrentTab() end end,
    UpdateMinimap      = function() if icon then if DelveGuideDB.minimap.hide then icon:Hide("DelveGuide") else icon:Show("DelveGuide") end end end,
    UpdateWidgetVis    = function() if DelveGuide.compactWidget then if DelveGuideDB.widgetHidden then DelveGuide.compactWidget:Hide() else DelveGuide.compactWidget:Show() end end end,
    UpdateWidgetAlpha  = function() if DelveGuide.compactWidget then DelveGuide.compactWidget:SetAlpha(DelveGuideDB.widgetAutoHide and 0.15 or 1.0) end end,
    UpdateCompactWidget= function() if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end end,
}

local tabRenderers = {}

local mainFrame,tabButtons,currentTabKey=nil,{},nil

local function SwitchTab(key)
    currentTabKey = key
    
    for _, td in ipairs(TABS) do
        local btn = tabButtons[td.key]
        if td.key == key then 
            btn.Text:SetTextColor(1, 0.82, 0, 1)
            btn.Underline:Show()
        else 
            btn.Text:SetTextColor(0.5, 0.5, 0.5, 1)
            btn.Underline:Hide() 
        end
    end
    
    local globalFuncName = "Render" .. key:gsub("^%l", string.upper)
    
    local r = tabRenderers[key] or DelveGuide[globalFuncName]
    
    if r then 
        r()
        scrollFrame:SetVerticalScroll(0) 
    end
end

RefreshCurrentTab = function() if currentTabKey then SwitchTab(currentTabKey) end end

local function CreateMainWindow()
    local f=CreateFrame("Frame","DelveGuideFrame",UIParent,"BackdropTemplate")
    
    -- Load saved size or default to WINDOW_W / WINDOW_H
    local startW = DelveGuideDB.windowW or WINDOW_W
    local startH = DelveGuideDB.windowH or WINDOW_H
    f:SetSize(startW, startH); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    
    -- Enable Resizing!
    f:SetResizable(true)
    f:SetResizeBounds(600, 400, 1200, 900) -- Min Width, Min Height, Max Width, Max Height
    
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
    
    -- Resize Grip Handle
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then f:StartSizing("BOTTOMRIGHT") end
    end)
    resizeGrip:SetScript("OnMouseUp", function(self, btn)
        f:StopMovingOrSizing()
        -- Save new size to DB
        DelveGuideDB.windowW = f:GetWidth()
        DelveGuideDB.windowH = f:GetHeight()
        RefreshCurrentTab() -- Redraw tab to fill new space
    end)
    
    f.UpdateTracker = function()
        local COFFER_KEY_SHARD_ID = 3310
        local keysInfo = C_CurrencyInfo.GetCurrencyInfo(COFFER_KEY_SHARD_ID)
        local shards = keysInfo and keysInfo.quantity or 0
        local weeklyCap = keysInfo and keysInfo.maxWeeklyQuantity or 600
        local weeklyEarned = keysInfo and keysInfo.quantityEarnedThisWeek or 0
        local delveCount, vaultSlots, maxThreshold = GetWeeklyVaultData()
        local vaultProgress = math.min(delveCount, maxThreshold)
        local wqCount = 0
        local seenQuests = {}

        local mapIDs = {2393, 2437, 2395, 2444, 2413, 2405, 2424}
        for _, z in ipairs(mapIDs) do
            local quests = C_TaskQuest.GetQuestsOnMap(z)
            if quests then
                for _, q in ipairs(quests) do
                    if not seenQuests[q.questID] and C_QuestLog.IsWorldQuest(q.questID) and not C_QuestLog.IsQuestFlaggedCompleted(q.questID) then
                        seenQuests[q.questID] = true
                        local curs = C_QuestLog.GetQuestRewardCurrencies(q.questID)
                        if curs then
                            for _, c in ipairs(curs) do
                                if c.currencyID == COFFER_KEY_SHARD_ID then
                                    wqCount = wqCount + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        local resetSecs = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
        local resetText = resetSecs and FormatResetTime(resetSecs) or "|cFF888888?|r"

        local keysText
        if weeklyCap > 0 and weeklyEarned >= weeklyCap then
            keysText = string.format("|cFF00FF44%d/%d (Capped)|r", shards, weeklyCap)
        else
            keysText = string.format("%d/%d", shards, weeklyCap > 0 and weeklyCap or 600)
        end

        f.TrackerText:SetText(string.format(
            "|cFFFFD700Keys:|r %s  |  |cFF00BFFFDelves:|r %d  |cFF888888(Vault %d/%d)|r  |  |cFF00FF88WQs:|r %d  |  |cFFAAAA00Reset:|r %s",
            keysText, delveCount, vaultProgress, maxThreshold, wqCount, resetText
        ))
    end
    f:HookScript("OnShow",f.UpdateTracker)
    
    local tabW=(startW-32)/#TABS
    for i,td in ipairs(TABS) do
        local btn=CreateFrame("Button","DelveGuideTab_"..td.key,f); btn:SetSize(tabW-4,TAB_HEIGHT)
        btn:SetPoint("TOPLEFT",f,"TOPLEFT",16+(i-1)*tabW,-36)
        btn.Text=btn:CreateFontString(nil,"OVERLAY","GameFontNormal"); btn.Text:SetPoint("CENTER"); btn.Text:SetText(td.label)
        btn.Underline=btn:CreateTexture(nil,"ARTWORK"); btn.Underline:SetColorTexture(1,0.82,0,1)
        btn.Underline:SetPoint("BOTTOM",btn,"BOTTOM",0,2); btn.Underline:SetSize(btn.Text:GetStringWidth()+16,2); btn.Underline:Hide()
        local k=td.key; btn:SetScript("OnClick",function() SwitchTab(k) end); tabButtons[k]=btn
    end
    
    -- Dynamically scale tabs and the UI layout variable when dragged!
    f:HookScript("OnSizeChanged", function(self, width, height)
        DelveGuide.UI.WINDOW_W = width
        local newTabW = (width - 32) / #TABS
        for i, td in ipairs(TABS) do
            local btn = tabButtons[td.key]
            if btn then
                btn:SetWidth(newTabW - 4)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + (i - 1) * newTabW, -36)
            end
        end
    end)
    
    local sf=CreateFrame("ScrollFrame","DelveGuideScrollFrame",f,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",f,"TOPLEFT",16,-(36+TAB_HEIGHT+10)); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,8)
    scrollFrame=sf; mainFrame=f; SwitchTab(TABS[1].key)
end

function DelveGuide.Toggle()
    if not mainFrame then CreateMainWindow() end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end


-- ============================================================
-- MINIMAP BUTTON (LibDataBroker & LibDBIcon)
-- ============================================================
local LDB = LibStub("LibDataBroker-1.1")
icon = LibStub("LibDBIcon-1.0")

local DelveGuideLDB = LDB:NewDataObject("DelveGuide", {
    type = "data source",
    text = "DelveGuide",
    icon = "Interface\\Icons\\INV_Misc_Map09",
    OnClick = function(_, button)
        if button == "LeftButton" then
            DelveGuide.Toggle()
        elseif button == "RightButton" then
            -- Open directly to settings tab on right-click!
            if not mainFrame or not mainFrame:IsShown() then DelveGuide.Toggle() end
            SwitchTab("settings")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cFF00BFFFDelveGuide|r")
        tooltip:AddLine("Left-Click to open/close.", 1, 1, 1)
        tooltip:AddLine("Right-Click for Settings.", 0.7, 0.7, 0.7)
    end,
})

local function UpdateLDBText()
    -- Shards
    local shards = 0
    pcall(function()
        local info = C_CurrencyInfo.GetCurrencyInfo(3310)
        if info then shards = info.quantity or 0 end
    end)

    -- Best active variant
    local bestVariant, bestRank = nil, 99
    local rankOrder = {S=1, A=2, B=3, C=4, D=5, F=6}
    if DelveGuideData and DelveGuideData.delves then
        local seen = {}
        for _, d in ipairs(DelveGuideData.delves) do
            if activeVariants[d.variant] and not seen[d.variant] then
                seen[d.variant] = true
                local r = rankOrder[d.ranking] or 99
                if r < bestRank then bestRank = r; bestVariant = d.variant; end
            end
        end
    end

    -- Vault
    local delveCount, _, maxThreshold = GetWeeklyVaultData()
    local vaultProgress = math.min(delveCount, maxThreshold > 0 and maxThreshold or 8)

    -- Format
    local parts = {}
    table.insert(parts, string.format("Keys: %d/600", shards))
    if bestVariant then
        local gradeLetter = "?"
        for letter, order in pairs(rankOrder) do if order == bestRank then gradeLetter = letter; break end end
        table.insert(parts, string.format("[%s] %s", gradeLetter, bestVariant))
    end
    table.insert(parts, string.format("Vault: %d/%d", vaultProgress, maxThreshold > 0 and maxThreshold or 8))

    DelveGuideLDB.text = table.concat(parts, " | ")
end
DelveGuide.UpdateLDBText = UpdateLDBText

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
    elseif msg=="minimap" then
        DelveGuideDB.minimap.hide = not DelveGuideDB.minimap.hide
        if icon then
            if DelveGuideDB.minimap.hide then icon:Hide("DelveGuide") else icon:Show("DelveGuide") end
        end
        print("|cFF00BFFF[DelveGuide]|r Minimap button: " .. (DelveGuideDB.minimap.hide and "|cFFFF4444hidden|r" or "|cFF44FF44shown|r"))
    elseif msg=="check" then
        if DelveGuide.ShowChecklist then DelveGuide.ShowChecklist(true) end
    elseif msg=="tierdebug" then
        print("|cFF00BFFF[DelveGuide]|r === Objective Tracker Dump ===")
        local tracker = _G["ObjectiveTrackerFrame"] or _G["ScenarioObjectiveTracker"]
        if tracker then
            local function PrintText(frame, depth)
                if not frame or frame:IsForbidden() then return end
                for _, r in ipairs({frame:GetRegions()}) do
                    if r:GetObjectType() == "FontString" and r:IsShown() then
                        local txt = r:GetText()
                        if txt and txt ~= "" then
                            local cleanTxt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
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
    elseif msg=="huddump" then
        print("|cFF00BFFF[DelveGuide]|r === HUD DEBUG DUMP (share this output) ===")
        print("Version: "..ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
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
            local numCrit = C_Scenario.GetNumCriteria and C_Scenario.GetNumCriteria() or 0
            print("Scenario criteria count: "..tostring(numCrit))
            for i = 1, (numCrit or 0) do
                local crit = C_Scenario.GetCriteriaInfo(i)
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
        table.insert(DelveGuideDB.history,1,{name=testName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier="Tier 8",vaultIlvl=610,char=testChar,elapsed=312})
        print("|cFF00BFFF[DelveGuide]|r TEST: Injected fake run - |cFF00FF44"..testName.."|r")
        -- TRIGGER THE VICTORY SCREEN FOR THE TEST RUN!
        if DelveGuide.ShowVictoryScreen then
            DelveGuide.ShowVictoryScreen(testName, "Tier 8", 610, 312)
        end
        if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
    elseif msg=="help" then
        print("|cFF00BFFF[DelveGuide]|r Commands:")
        print("  |cFFFFFF00/dg|r             - Toggle window")
        print("  |cFFFFFF00/dg scan|r        - Rescan active delve variants")
        print("  |cFFFFFF00/dg minimap|r     - Toggle minimap button")
        print("  |cFFFFFF00/dg hud|r         - Toggle in-run HUD overlay")
        print("  |cFFFFFF00/dg widget|r      - Toggle compact floating widget")
        print("  |cFFFFFF00/dg font [#]|r    - Set font scale, e.g. |cFFFFFF00/dg font 1.2|r  (0.6 - 2.0)")
        print("  |cFFFFFF00/dg map|r         - Open world map")
        print("  |cFFFFFF00/dg dump|r        - Print raw POI data (debug)")
        print("  |cFFFFFF00/dg chatdump|r    - Print full scan results to chat (for localization reports)")
        print("  |cFFFFFF00/dg roster|r      - Open Roster tab")
        print("  |cFFFFFF00/dg check|r       - Show pre-entry checklist")
        print("  |cFFFFFF00/dg checkdebug|r  - Scan auras to find Valeera role spell ID")
        print("  |cFFFFFF00/dg tier [#]|r    - Manually set current delve tier, e.g. |cFFFFFF00/dg tier 8|r")
        print("  |cFFFFFF00/dg share [ch]|r  - Share active variants to chat (party/guild/say/raid)")
        print("  |cFFFFFF00/dg huddump|r     - Dump HUD data for locale debugging (run inside a delve)")
        print("  |cFFFFFF00/dg resetwidget|r - Reset widget position to center (if lost off-screen)")
        print("  |cFFFFFF00/dg specinfo|r    - Show your detected spec ID (debug)")
        print("  |cFFFFFF00/dg help|r        - Show this help")
    elseif msg:sub(1,5)=="tier " then
        local num = tonumber(msg:sub(6))
        if num and num >= 1 and num <= 11 then
            DelveGuide.currentDelveTier    = tostring(num)
            DelveGuide.currentDelveTierNum = num
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            print("|cFF00BFFF[DelveGuide]|r Delve tier set to |cFFCCCCCC" .. num .. "|r")
        else
            print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg tier 3|r  (1-11)")
        end
    elseif msg=="hud" then
        if DelveGuide.ToggleHUD then DelveGuide.ToggleHUD()
        else print("|cFF00BFFF[DelveGuide]|r HUD not loaded.") end
    elseif msg=="widget" then
        if DelveGuide.ToggleWidget then DelveGuide.ToggleWidget() end
    elseif msg=="resetwidget" then
        DelveGuideDB.widgetX = nil
        DelveGuideDB.widgetY = nil
        local cw = DelveGuide.compactWidget
        if cw then
            cw:ClearAllPoints()
            cw:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
            cw:Show()
        end
        DelveGuideDB.widgetHidden = false
        print("|cFF00BFFF[DelveGuide]|r Widget position reset to center.")
    elseif msg:sub(1,4)=="font" then
        local val=tonumber(msg:sub(6))
        if val then DelveGuideDB.fontScale=math.max(0.6,math.min(2.0,val)); RefreshCurrentTab()
            print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx",DelveGuideDB.fontScale))
        else print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx (0.6-2.0)",DelveGuideDB.fontScale)) end
    elseif msg:sub(1,5)=="share" then
        local channel = strtrim(msg:sub(7)):upper()
        if channel == "" then channel = "PARTY" end
        local validChannels = {PARTY=true, GUILD=true, SAY=true, RAID=true, INSTANCE_CHAT=true}
        if not validChannels[channel] then
            print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg share [party|guild|say|raid]|r")
            return
        end
        -- Build sorted active variant list (same pattern as compact widget)
        local entries, seen = {}, {}
        if DelveGuideData and DelveGuideData.delves then
            for _, d in ipairs(DelveGuideData.delves) do
                if activeVariants[d.variant] and not seen[d.variant] then
                    seen[d.variant] = true
                    table.insert(entries, {variant=d.variant, ranking=d.ranking, delve=d.name})
                end
            end
        end
        if #entries == 0 then
            print("|cFF00BFFF[DelveGuide]|r No active variants found. Try |cFFFFFF00/dg scan|r first.")
            return
        end
        table.sort(entries, function(a,b) return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99) end)
        SendChatMessage("[DelveGuide] Today's Active Delves:", channel)
        for _, e in ipairs(entries) do
            local ds = activeDelves[e.delve]
            local bountyTag = (type(ds)=="table" and ds.bountiful) and " [Bountiful]" or ""
            SendChatMessage(string.format("  [%s] %s (%s)%s", e.ranking, e.variant, e.delve, bountyTag), channel)
        end
        print("|cFF00BFFF[DelveGuide]|r Shared "..#entries.." variants to |cFFFFFF00"..channel.."|r")
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
        InitSavedVars(); icon:Register("DelveGuide", DelveGuideLDB, DelveGuideDB.minimap); if DelveGuide.CreateCompactWidget then DelveGuide.CreateCompactWidget() end
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  *  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_ENTERING_WORLD" then
        -- Only rescan POIs when in the outdoor world — inside an instance the POI data is empty
        -- and would wipe the activeVariants cache that the HUD relies on.
        local inInst, instType = IsInInstance()
        if not inInst then
            DelveGuide.inDelveInstance = false
            C_Timer.After(0, function()
                ScanActiveVariants()
                if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end
                UpdateLDBText()
                -- One-time flag if missing translations exist on this client
                if DelveGuideDB.missingTranslations then
                    local count = 0
                    for _ in pairs(DelveGuideDB.missingTranslations) do count = count + 1 end
                    if count > 0 and not DelveGuideDB.missingNotified then
                        DelveGuideDB.missingNotified = true
                        print("|cFF00BFFF[DelveGuide]|r |cFFFFFF00" .. count .. " untranslated variant(s) on your client.|r Use |cFFFFFF00/dg chatdump|r to help add your language!")
                    end
                end
            end)
        elseif instType == "scenario" then
            DelveGuide.inDelveInstance = true
        end
        CacheCurrentChar()
        UpdateLDBText()
        if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
        if DelveGuideDB.lastSeenVersion ~= ADDON_VERSION then
            DelveGuideDB.lastSeenVersion = ADDON_VERSION
            if DelveGuideDB.showChangelog then
                C_Timer.After(3, ShowChangelogPopup)
            end
        end
    elseif event=="AREA_POIS_UPDATED" then
        if not IsInInstance() then
            C_Timer.After(0, function() ScanActiveVariants(); if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end; UpdateLDBText() end)
        end
        if mainFrame and mainFrame:IsShown() and currentTabKey=="delves" then SwitchTab("delves") end
    elseif event=="ACTIVE_TALENT_GROUP_CHANGED" then
        if mainFrame and mainFrame:IsShown() and currentTabKey=="curios" then SwitchTab("curios") end
    elseif event=="PLAYER_TARGET_CHANGED" then
        if DelveGuide.OnTargetChanged then DelveGuide.OnTargetChanged() end
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
                    local DELVE_TYPE = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World) or 6
                    local data=C_WeeklyRewards.GetActivities()
                    if data then
                        for _,a in ipairs(data) do
                            if a.type == DELVE_TYPE and a.level and a.level>0 and a.progress>=a.threshold then
                                if not vaultIlvl or a.level>vaultIlvl then vaultIlvl=a.level end
                            end
                        end
                    end
                end)
            end

            local charName="Unknown"
            pcall(function() charName=UnitName("player") or "Unknown" end)

            -- Capture completion timer (runStartTime set by HUD on delve entry)
            local elapsed = nil
            if DelveGuide.runStartTime then
                elapsed = GetTime() - DelveGuide.runStartTime
                DelveGuide.runStartTime = nil
            end

            table.insert(DelveGuideDB.history,1,{name=runName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier=tier,vaultIlvl=vaultIlvl,char=charName,elapsed=elapsed})
            if #DelveGuideDB.history>50 then table.remove(DelveGuideDB.history) end
            local vaultStr=vaultIlvl and ("  |cFFFFD700[Vault: "..vaultIlvl.." ilvl]|r") or ""
            local timeStr=elapsed and string.format("  |cFF00BFFF[%dm %02ds]|r",math.floor(elapsed/60),math.floor(elapsed%60)) or ""
            print("|cFF00BFFF[DelveGuide]|r Logged: |cFF00FF44"..runName.."|r  |cFF888888["..tier.."]|r"..vaultStr..timeStr)
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
            -- TRIGGER THE VICTORY SCREEN!
            if DelveGuide.ShowVictoryScreen then
                DelveGuide.ShowVictoryScreen(runName, tier, vaultIlvl, elapsed)
            end

        end
    end
end)
-- ============================================================
-- WORLD MAP TOOLTIP INJECTIONS
-- ============================================================
local function InjectDelveData(self)
    if DelveGuideDB and DelveGuideDB.mapTooltips == false then return end

    local titleFS = _G[self:GetName() .. "TextLeft1"]
    if not titleFS then return end

    local poiName = titleFS:GetText()
    if not poiName then return end

    -- 1. Put ALL string comparisons inside the pcall bubble. 
    -- If it is a secret string, the pcall catches the security block and silently fails.
    local ok, result = pcall(function()
        if poiName == "" then return "IGNORE" end
        if self.dgLastCheckedName == poiName then return "IGNORE" end
        
        -- It's safe! Remember it for the next frame to prevent the memory leak.
        self.dgLastCheckedName = poiName
        
        return (DelveGuide.localizedToEnglish and DelveGuide.localizedToEnglish[poiName]) or poiName
    end)

    -- 2. If it was a secret string (not ok) or we already checked it ("IGNORE"), stop here!
    if not ok or not result or result == "IGNORE" then return end
    
    local engName = result

    local ok2, isActive = pcall(function()
        return DelveGuide.activeDelves and DelveGuide.activeDelves[engName]
    end)
    if not ok2 or not isActive then return end

    local activeVariant = nil
    local ranking = "N/A"
    local flags = ""

    for _, d in ipairs(DelveGuideData.delves) do
        if d.name == engName and DelveGuide.activeVariants[d.variant] then
            activeVariant = d.variant
            ranking = d.ranking
            if d.isBestRoute then flags = flags .. "|cFF00FF00[Best Route]|r " end
            if d.mountable then flags = flags .. "|cFFFFD700[Mountable]|r " end
            if d.hasBug then flags = flags .. "|cFFFF4444[Bugged]|r " end
            break
        end
    end

    -- 3. Inject the DelveGuide Data!
    if activeVariant then
        self:AddLine(" ") 
        self:AddLine("|cFF00BFFFDelveGuide:|r")

        local gradeText = DelveGuide.UI and DelveGuide.UI.GradeColor(ranking) or ("|cFFFFFFFF" .. ranking .. "|r")
        self:AddLine("Speed Grade: " .. gradeText .. "  " .. flags)

        self:Show() 
    end
end

-- Hook OnUpdate so we catch the tooltip constantly redrawing the Bountiful timer
GameTooltip:HookScript("OnUpdate", InjectDelveData)

-- Reset our memory every single time Blizzard completely clears the tooltip
GameTooltip:HookScript("OnTooltipCleared", function(self)
    self.dgLastCheckedName = nil
end)