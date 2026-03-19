-- ============================================================
-- DelveGuide.lua  --  Main addon logic
-- ============================================================
DelveGuide = {}

local ADDON_NAME       = "DelveGuide"
local ADDON_VERSION    = "1.3.8"
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

local ALL_ZONE_MAP_IDS = { 2393, 2437, 2395, 2444, 2413, 2405 }

-- Widget set ID → English variant name.
-- Set IDs are locale-independent, so this table fixes variant detection on all clients.
-- Expand as new variants are discovered.
local WIDGET_SET_VARIANTS = {
    [1611] = "Invasive Glow",
    [1738] = "Dastardly Rotstalk",
    [1800] = "Core of the Problem",
    [1801] = "Stolen Mana",
    [1802] = "Totem Annihilation",
    [1803] = "Descent of the Haranir",
    [1804] = "Traitor's Due",
    [1805] = "Party Crasher",
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
    -- checklistDismissed is session-only; reset on every load
    DelveGuideDB.checklistDismissed = false
    if not DelveGuideDB.roster then DelveGuideDB.roster = {} end
    -- lastSeenVersion drives the "what's new" popup (nil = never shown)
    if DelveGuideDB.lastSeenVersion == nil then DelveGuideDB.lastSeenVersion = nil end
end

local activeDelves, activeVariants, rawScanResults = {}, {}, {}
local localizedToEnglish = {}  -- maps localized zone name → English zone name (non-EN clients)
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
                    -- Variant detection: set ID first (locale-independent), then text fallback
                    variantName = WIDGET_SET_VARIANTS[widgetSetID]
                    for _, t in ipairs(widgetTexts) do
                        local clean=t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")
                        if string.find(clean,"Nemesis",1,true) then hasNemesis=true end
                        if not variantName then
                            for kVariant in pairs(knownVariants) do
                                if string.find(clean,kVariant,1,true) then variantName=kVariant end
                            end
                        end
                    end
                    -- Key activeDelves by English zone name so lookups work on all locales
                    local engZoneName = delveName
                    if variantName and DelveGuideData and DelveGuideData.delves then
                        for _, d in ipairs(DelveGuideData.delves) do
                            if d.variant == variantName then engZoneName = d.name; break end
                        end
                    end
                    if engZoneName~="" then
                        activeDelves[engZoneName]={bountiful=isBountiful,nemesis=hasNemesis}
                        if delveName~=engZoneName then localizedToEnglish[delveName]=engZoneName end
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
    local restoredKeys = C_Item.GetItemCount(3028, true) or 0

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

    local _, vaultSlots, acts = GetWeeklyVaultData()
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

        for _, block in ipairs(DelveGuideData.changelog) do
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
    UpdateWidgetVis    = function() if compactWidget then if DelveGuideDB.widgetHidden then compactWidget:Hide() else compactWidget:Show() end end end,
    UpdateWidgetAlpha  = function() if compactWidget then compactWidget:SetAlpha(DelveGuideDB.widgetAutoHide and 0.15 or 1.0) end end,
    UpdateCompactWidget= function() if UpdateCompactWidget then UpdateCompactWidget() end end,
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
        if DelveGuideDB.widgetAutoHide then
            UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1.0)
        end
    end)
    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        -- IsMouseOver() returns true if the cursor is still within this frame's bounds,
        -- which covers child buttons (varLines, lockBtn) — avoids flicker when mousing over them.
        if DelveGuideDB.widgetAutoHide and not self:IsMouseOver() then
            UIFrameFadeOut(self, 0.5, self:GetAlpha(), 0.15)
        end
    end)
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
    if DelveGuideDB.widgetAutoHide then f:SetAlpha(0.15) end
    compactWidget = f
    UpdateCompactWidget()
end

-- ============================================================
-- MINIMAP BUTTON (LibDataBroker & LibDBIcon)
-- ============================================================
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

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
        InitSavedVars(); icon:Register("DelveGuide", DelveGuideLDB, DelveGuideDB.minimap); CreateCompactWidget()
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
