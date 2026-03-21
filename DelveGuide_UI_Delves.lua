local UI = DelveGuide.UI

local function CreateDelveRow(parent, y, d)
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local rowW = UI.WINDOW_W - 52
    
    local activeVariants = DelveGuide.activeVariants or {}
    local active = (activeVariants[d.variant] == true)

    if active then
        local fill=parent:CreateTexture(nil,"BACKGROUND"); fill:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        fill:SetSize(rowW-4,rH+2); fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        fill:SetGradient("HORIZONTAL",CreateColor(0,0.7,0.15,0.35),CreateColor(0,0.7,0.15,0))
        local bar=parent:CreateTexture(nil,"ARTWORK"); bar:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        bar:SetSize(3,rH+2); bar:SetColorTexture(0,1,0.2,1)
    end

    local gradeFS=parent:CreateFontString(nil,"OVERLAY"); gradeFS:SetFont(ROW_FONT_FILE,rSize)
    gradeFS:SetPoint("TOPLEFT",parent,"TOPLEFT",10,-y); gradeFS:SetWidth(46); gradeFS:SetJustifyH("LEFT")
    gradeFS:SetText(string.format("[%s]", UI.GradeColor(d.ranking)))

    local pin = UI.FindPinByName(d.name)
    local nameBtn=CreateFrame("Button",nil,parent); nameBtn:SetSize(160,rH)
    nameBtn:SetPoint("TOPLEFT",parent,"TOPLEFT",56,-y+1)
    local nameFS=nameBtn:CreateFontString(nil,"OVERLAY"); nameFS:SetFont(ROW_FONT_FILE,rSize)
    nameFS:SetAllPoints(nameBtn); nameFS:SetJustifyH("LEFT")

    local activeDelves = DelveGuide.activeDelves or {}
    local delveStatus = activeDelves[d.name]
    local isBountiful = type(delveStatus)=="table" and delveStatus.bountiful
    local nameColor = isBountiful and "|cFFFFD700" or "|cFF00CFFF"

    if pin then
        nameFS:SetText(nameColor..d.name.."|r")
        nameBtn:SetScript("OnEnter",function(self)
            nameFS:SetText("|cFFFFFFFF"..d.name.."|r")
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine("|cFFFFD700"..d.name.."|r")
            GameTooltip:AddLine("|cFFCCCCCC"..d.zone.."|r"); GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFF00FF88Click to open map & set waypoint|r"); GameTooltip:Show()
        end)
        nameBtn:SetScript("OnLeave",function() nameFS:SetText(nameColor..d.name.."|r") GameTooltip:Hide() end)
        nameBtn:SetScript("OnClick",function() UI.SetDelveWaypoint(pin) end)
    else nameFS:SetText(isBountiful and ("|cFFFFD700"..d.name.."|r") or d.name) end

    local variantText=active and "|cFF44FF44"..d.variant.."|r" or d.variant
    local flags=""
    if d.isBestRoute then flags=flags.."|cFF00FF00[Best]|r " end
    if d.hasBug then flags=flags.."|cFFFF4444[Bug]|r " end
    if d.mountable then flags=flags.."|cFFFFD700[Mt]|r " end

    if type(delveStatus)=="table" and delveStatus.nemesis then flags=flags.."|cFFFF4444[Nemesis]|r " end

    local infoFS=parent:CreateFontString(nil,"OVERLAY"); infoFS:SetFont(ROW_FONT_FILE,rSize)
    infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y)
    infoFS:SetWidth(isBountiful and (rowW-420) or (rowW-310)); infoFS:SetJustifyH("LEFT")
    infoFS:SetText(UI.ZoneColor(d.zone).."  "..variantText.."  "..flags)

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

DelveGuide.RenderDelves = function()
    local cf=UI.NewContentFrame(); local y=10
    local activeVariants = DelveGuide.activeVariants or {}
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
        if activeVariants[d.variant] then table.insert(activeData,d) else table.insert(inactiveData,d) end
    end
    
    local note=vc>0 and "  |cFF44FF44("..vc.." active today)|r" or "  |cFFAAAAAA(use /dg scan)|r"
    y=y+UI.CreateHeader(cf,y,"Delve Rankings -- S=Fastest | F=Slowest"..note)+4
    y=y+UI.CreateRow(cf,y,string.format("|cFF3088FFWeekly Items:|r  Trovehunter's Bounty: %s   |   Beacon of Hope: %s   |   Restored Coffer Key: %s",troveText,beaconText,restoredKeyText))
    
    local delveCount,_,vaultActs=UI.GetWeeklyVaultData()
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
        y=y+UI.CreateRow(cf,y,string.format("|cFF3088FFGreat Vault:|r  %d delve(s) this week  —  %s",delveCount,table.concat(parts,"  |  ")))
    end
    y=y+8
    y=y+UI.CreateRow(cf,y,"|cFFAAAAAA"..string.format("%-6s  %-22s  %-14s  %s","Rank","Delve","Zone","Variant / Flags").."|r")
    y=y+UI.CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+2
    if vc>0 then
        y=y+4; y=y+UI.CreateRow(cf,y,"|cFF00FF44-- * ACTIVE TODAY --|r")
        for _,d in ipairs(activeData) do y=y+CreateDelveRow(cf,y,d) end
        y=y+12; y=y+UI.CreateRow(cf,y,"|cFF888888-- ALL VARIANTS (INACTIVE) --|r")
    end
    local lastZone=""
    for _,d in ipairs(inactiveData) do
        if d.zone~=lastZone then y=y+4; y=y+UI.CreateRow(cf,y,"|cFF666666-- "..d.zone.." --|r"); lastZone=d.zone end
        y=y+CreateDelveRow(cf,y,d)
    end
    cf:SetHeight(y+20)
end