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
    if not DelveGuideDB.history then DelveGuideDB.history = {} end
end

local activeDelves, activeVariants, rawScanResults = {}, {}, {}

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
local function TypeColor(t) return (typeColors[t] or "|cFFFFFFFF")..t.."|r" end

local function SetDelveWaypoint(pin)
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin.mapID,pin.x,pin.y))
    OpenWorldMap(pin.mapID)
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

local function RenderCurios()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Curios Rankings  --  S=Best  |  F=Worst")+4; y=y+4
    y=y+CreateRow(cf,y,"|cFFFFD700-- Season 1 Recommended Valeera Loadouts --|r")
    y=y+CreateRow(cf,y,"|cFF00FF00Safe / Progression:|r Mantle of Stars (Combat) + Motionless Nulltide (Utility)")
    y=y+CreateRow(cf,y,"|cFFFF4444Speed / Farming:|r   Sanctum's Edict (Combat) + Ebon Crown of Subjugation (Utility)")
    y=y+CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+4
    for _,ctype in ipairs({"Combat","Utility"}) do
        y=y+4; y=y+CreateRow(cf,y,TypeColor(ctype).." Curios")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-4s  %-32s  %s","Rank","Name","Effect").."|r")
        for _,c in ipairs(DelveGuideData.curios) do
            if c.curiotype==ctype then y=y+CreateRow(cf,y,string.format("[%s]  %-32s  %s",GradeColor(c.ranking),c.name,c.description)) end
        end; y=y+8
    end; cf:SetHeight(y+20)
end

local function RenderLoot()
    local cf=NewContentFrame(); local y=10
    y=y+CreateHeader(cf,y,"Notable Loot  --  Trinkets & Weapons from Midnight Delves")+4
    for _,slot in ipairs({"Trinket","Weapon"}) do
        y=y+4; y=y+CreateRow(cf,y,"|cFFFFD700"..slot.."s|r")
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-36s  %s","Item Name","Effect / Notes").."|r")
        for _,item in ipairs(DelveGuideData.loot) do
            if item.slot==slot then y=y+CreateRow(cf,y,string.format("|cFF00BFFF%-36s|r  %s",item.name,item.notes)) end
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
    y=y+CreateHeader(cf,y,"Delve Run History (Last 50 Runs)")+4
    if not DelveGuideDB.history or #DelveGuideDB.history==0 then
        y=y+CreateRow(cf,y,"|cFF888888No runs recorded yet. Go complete a Delve!|r")
    else
        y=y+CreateRow(cf,y,"|cFF888888"..string.format("%-20s  %-24s","Date & Time","Delve Completed").."|r")
        y=y+CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+4
        for _,run in ipairs(DelveGuideDB.history) do
            y=y+CreateRow(cf,y,string.format("|cFFCCCCCC%-20s|r  |cFF00BFFF%-24s|r",run.date,run.name))
        end
    end; cf:SetHeight(y+20)
end

local tabRenderers={delves=RenderDelves,curios=RenderCurios,loot=RenderLoot,history=RenderHistory,future=RenderFuture,debug=RenderDebug}
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

local function RefreshCurrentTab() if currentTabKey then SwitchTab(currentTabKey) end end

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
        local completed=0
        if Enum and Enum.WeeklyRewardItemTierType and Enum.WeeklyRewardItemTierType.World then
            local ok,acts=pcall(C_WeeklyRewards.GetActivities,Enum.WeeklyRewardItemTierType.World)
            if ok and type(acts)=="table" then for _,a in ipairs(acts) do if a.progress>=a.threshold then completed=completed+1 end end end
        end
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
        f.TrackerText:SetText(string.format("|cFFFFD700Keys:|r %d/600  |  |cFF00BFFFVault:|r %d/8  |  |cFF00FF88Shard WQs:|r %d",shards,completed,wqCount))
    end
    f:HookScript("OnShow",f.UpdateTracker)
    local function MakeFontBtn(label,xOff,onClick,tip)
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate"); b:SetSize(28,18)
        b:SetPoint("TOPRIGHT",f,"TOPRIGHT",xOff,-12); b:SetText(label); b:SetScript("OnClick",onClick)
        b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:AddLine(tip)
            GameTooltip:AddLine(string.format("|cFFAAAAAACurrent: %.1fx|r",DelveGuideDB.fontScale)); GameTooltip:Show() end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    MakeFontBtn("A-",-200,function() DelveGuideDB.fontScale=math.max(0.6,DelveGuideDB.fontScale-0.1); RefreshCurrentTab() end,"Decrease text size")
    MakeFontBtn("A+",-230,function() DelveGuideDB.fontScale=math.min(2.0,DelveGuideDB.fontScale+0.1); RefreshCurrentTab() end,"Increase text size")
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

-- Minimap button — mirrors NightPulse's MinimapButton.lua exactly.
local minimapBtn = nil
local currentAngle  -- stored in radians, matches NightPulse pattern

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
loadFrame:SetScript("OnEvent",function(self,event,arg1)
    if event=="ADDON_LOADED" and arg1==ADDON_NAME then
        InitSavedVars(); CreateMinimapButton()
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  *  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_ENTERING_WORLD" then
        ScanActiveVariants(); if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
    elseif event=="AREA_POIS_UPDATED" then
        ScanActiveVariants()
        if mainFrame and mainFrame:IsShown() and currentTabKey=="delves" then SwitchTab("delves") end
    elseif event=="SCENARIO_COMPLETED" then
        local scenarioName=C_Scenario.GetInfo(); if not scenarioName then return end
        local isDelve=false
        if DelveGuideData and DelveGuideData.delves then
            for _,d in ipairs(DelveGuideData.delves) do if d.name==scenarioName then isDelve=true; break end end
        end
        if isDelve then
            table.insert(DelveGuideDB.history,1,{name=scenarioName,date=date("%Y-%m-%d %H:%M")})
            if #DelveGuideDB.history>50 then table.remove(DelveGuideDB.history) end
            print("|cFF00BFFF[DelveGuide]|r Logged completion: |cFF00FF44"..scenarioName.."|r")
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
        end
    end
end)
