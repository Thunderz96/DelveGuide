-- ============================================================
-- DelveGuide.lua  --  Main addon logic
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
    { label = "Delves",   key = "delves"   },
    { label = "Curios",   key = "curios"   },
    { label = "Loot",     key = "loot"     },
    { label = "History",  key = "history"  },
    { label = "Future",   key = "future"   },
    { label = "Settings", key = "settings" },
    { label = "Debug",    key = "debug"    },
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
    if DelveGuideDB.checklistEnabled == nil then DelveGuideDB.checklistEnabled = true end
    -- checklistDismissed is session-only; reset on every load
    DelveGuideDB.checklistDismissed = false
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
    local knownVariants = {}
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do knownVariants[d.variant] = true end
    end
    for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
        local poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
        if poiIDs then
            for _, poiID in ipairs(poiIDs) do
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info then
                    local delveName=info.name or ""; local widgetSetID=info.tooltipWidgetSet or 0
                    local widgetTexts=ReadVariantFromWidgetSet(widgetSetID)
                    local variantName,isBountiful,hasNemesis=nil,false,false
                    for _, t in ipairs(widgetTexts) do
                        local clean=t:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t",""):gsub("|A.-|a","")
                        if string.find(clean,"Bountiful",1,true) then isBountiful=true end
                        if string.find(clean,"Nemesis",1,true) then hasNemesis=true end
                        for kVariant in pairs(knownVariants) do
                            if string.find(clean,kVariant,1,true) then variantName=kVariant end
                        end
                    end
                    if delveName~="" then activeDelves[delveName]={bountiful=isBountiful,nemesis=hasNemesis} end
                    table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID=poiID,name=delveName,widgetSetID=tostring(widgetSetID),
                        widgetTexts=widgetTexts,variantName=variantName or "(not found)"})
                    if variantName and variantName~="" then activeVariants[variantName]=true end
                end
            end
        else
            table.insert(rawScanResults,{mapID="",zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A",name="(GetDelvesForMap returned nil)",widgetSetID="0",widgetTexts={},variantName="(nil)"})
        end
    end
end

local function IsVariantActive(v) return activeVariants[v]==true end

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
    -- Defer OpenWorldMap out of the click handler's execution chain to avoid tainting
    -- the secure map frame (ADDON_ACTION_BLOCKED: Frame:SetPropagateMouseClicks)
    C_Timer.After(0, function() OpenWorldMap(pin.mapID) end)
    print("|cFF00BFFF[DelveGuide]|r Waypoint set: |cFFFFD700"..pin.name.."|r")
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
    if type(delveStatus)=="table" then
        if delveStatus.bountiful then flags=flags.."|cFFFFFF00[Bountiful]|r " end
        if delveStatus.nemesis then flags=flags.."|cFFFF4444[Nemesis]|r " end
    end
    local infoFS=parent:CreateFontString(nil,"OVERLAY"); infoFS:SetFont(ROW_FONT_FILE,rSize)
    infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y); infoFS:SetWidth(rowW-310); infoFS:SetJustifyH("LEFT")
    infoFS:SetText(ZoneColor(d.zone).."  "..variantText.."  "..flags)
    if active then
        local todayFS=parent:CreateFontString(nil,"OVERLAY"); todayFS:SetFont(ROW_FONT_FILE,rSize,"OUTLINE")
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

local function RenderDelves()
    local cf=NewContentFrame(); local y=10
    local vc=0; for _ in pairs(activeVariants) do vc=vc+1 end
    local troveCount=C_Item.GetItemCount(265714,true) or 0
    local hasTroveAura=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(1254631)
    local troveText=hasTroveAura and "|cFF00FF44Active|r" or (troveCount>0 and "|cFFFFFF00In Bags|r" or "|cFFFF4444None|r")
    local beaconCount=C_Item.GetItemCount(253342,true) or 0
    local beaconText=beaconCount>0 and "|cFF00FF44"..beaconCount.." in Bags|r" or "|cFFFF4444None|r"
    local activeData,inactiveData={},{}
    for _,d in ipairs(DelveGuideData.delves) do
        if IsVariantActive(d.variant) then table.insert(activeData,d) else table.insert(inactiveData,d) end
    end
    local note=vc>0 and "  |cFF44FF44("..vc.." active today)|r" or "  |cFFAAAAAA(use /dg scan)|r"
    y=y+CreateHeader(cf,y,"Delve Rankings -- S=Fastest | F=Slowest"..note)+4
    y=y+CreateRow(cf,y,string.format("|cFF3088FFWeekly Items:|r  Trovehunter's Bounty: %s   |   Beacon of Hope: %s",troveText,beaconText))
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
    y = y + 30

    cf:SetHeight(y + 20)
end

local function RenderDebug()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"DEBUG -- Variant Detection Results")+4
    y=y+CreateRow(cf,y,"|cFFFFFF00/dg scan refreshes | /dg dump prints raw API fields to chat|r")+8
    if #rawScanResults==0 then y=y+CreateRow(cf,y,"|cFFFF4444No data -- type /dg scan first.|r")
    else
        local vc=0; for _ in pairs(activeVariants) do vc=vc+1 end
        local vcColor=vc>0 and "|cFF44FF44" or "|cFFFF4444"
        y=y+CreateRow(cf,y,string.format("%s%d variant(s) detected today:|r",vcColor,vc))
        if vc==0 then y=y+CreateRow(cf,y,"|cFFFF4444  Widget texts empty -- hover a delve on the map then /dg scan.|r")
        else for v in pairs(activeVariants) do y=y+CreateRow(cf,y,"|cFF44FF44  + "..v.."|r") end end
        y=y+8; y=y+CreateRow(cf,y,"|cFFFFD700-- Per-Delve Widget Texts --|r")
        for _,r in ipairs(rawScanResults) do
            y=y+4
            local vColor=(r.variantName=="(not found)" or r.variantName=="(nil)") and "|cFFFF4444" or "|cFF44FF44"
            y=y+CreateRow(cf,y,string.format("|cFFFFD700%-24s|r  set=%-6s  -> %s%s|r",r.name,r.widgetSetID,vColor,r.variantName))
            if r.widgetTexts and #r.widgetTexts>0 then
                for _,t in ipairs(r.widgetTexts) do y=y+CreateRow(cf,y,"   |cFF888888> "..t.."|r") end
            else y=y+CreateRow(cf,y,"   |cFF555555(no texts in widget set)|r") end
        end
    end; cf:SetHeight(y+20)
end

local function RenderHistory()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Delve Run History  —  Weekly Great Vault Summary")+4
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
                y=y+CreateRow(cf,y,string.format("  |cFFCCCCCC%-18s|r  |cFF00BFFF%s|r",run.date,run.name))
            end
        end
    end; cf:SetHeight(y+20)
end

local tabRenderers={delves=RenderDelves,curios=RenderCurios,loot=RenderLoot,history=RenderHistory,future=RenderFuture,settings=RenderSettings,debug=RenderDebug}
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

    -- 1. Coffer Key shards (100 shards = 1 key)
    local keyInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards = keyInfo and keyInfo.quantity or 0
    local hasKey = shards >= 100
    table.insert(results, {
        label = string.format("Coffer Key  |cFF888888(%d/600 shards)|r", shards),
        ok    = hasKey,
        tip   = not hasKey and "You need at least 100 shards (1 key) to open a Bountiful Coffer." or nil,
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
                line.label:SetText(rc.."["..e.ranking.."]|r  "..nameText)
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
    local keysInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    compactWidget.keysLine:SetText(string.format("|cFFFFD700Keys:|r %d/600", keysInfo and keysInfo.quantity or 0))
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
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * 80,
        math.sin(angle) * 80)
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
    elseif msg=="help" then
        print("|cFF00BFFF[DelveGuide]|r Commands:")
        print("  |cFFFFFF00/dg|r             — Toggle window")
        print("  |cFFFFFF00/dg scan|r        — Rescan active delve variants")
        print("  |cFFFFFF00/dg minimap|r     — Toggle minimap button")
        print("  |cFFFFFF00/dg widget|r      — Toggle compact floating widget")
        print("  |cFFFFFF00/dg font [#]|r    — Set font scale, e.g. |cFFFFFF00/dg font 1.2|r  (0.6 – 2.0)")
        print("  |cFFFFFF00/dg map|r         — Open world map")
        print("  |cFFFFFF00/dg dump|r        — Print raw POI data (debug)")
        print("  |cFFFFFF00/dg check|r       — Show pre-entry checklist")
        print("  |cFFFFFF00/dg checkdebug|r  — Scan auras to find Valeera role spell ID")
        print("  |cFFFFFF00/dg specinfo|r    — Show your detected spec ID (debug)")
        print("  |cFFFFFF00/dg help|r        — Show this help")
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

local loadFrame=CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED"); loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("AREA_POIS_UPDATED"); loadFrame:RegisterEvent("SCENARIO_COMPLETED")
loadFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED"); loadFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
loadFrame:SetScript("OnEvent",function(self,event,arg1)
    if event=="ADDON_LOADED" and arg1==ADDON_NAME then
        InitSavedVars(); CreateMinimapButton(); CreateCompactWidget()
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  *  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_ENTERING_WORLD" then
        ScanActiveVariants(); UpdateCompactWidget()
        if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
    elseif event=="AREA_POIS_UPDATED" then
        ScanActiveVariants(); UpdateCompactWidget()
        if mainFrame and mainFrame:IsShown() and currentTabKey=="delves" then SwitchTab("delves") end
    elseif event=="ACTIVE_TALENT_GROUP_CHANGED" then
        if mainFrame and mainFrame:IsShown() and currentTabKey=="curios" then SwitchTab("curios") end
    elseif event=="PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
    elseif event=="SCENARIO_COMPLETED" then
        local scenarioName=C_Scenario.GetInfo(); if not scenarioName then return end
        local isDelve=false
        if DelveGuideData and DelveGuideData.delves then
            for _,d in ipairs(DelveGuideData.delves) do if d.name==scenarioName then isDelve=true; break end end
        end
        if isDelve then
            local secsUntilReset=C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
            local resetKey=secsUntilReset and (math.floor((time()+secsUntilReset-604800)/3600)*3600) or nil
            table.insert(DelveGuideDB.history,1,{name=scenarioName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey})
            if #DelveGuideDB.history>50 then table.remove(DelveGuideDB.history) end
            print("|cFF00BFFF[DelveGuide]|r Logged completion: |cFF00FF44"..scenarioName.."|r")
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
        end
    end
end)
