local UI = DelveGuide.UI
local RANK_ORDER = {S=1, A=2, B=3, C=4, D=5, F=6}

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

    local infoFS=parent:CreateFontString(nil,"OVERLAY"); infoFS:SetFont(ROW_FONT_FILE,rSize)
    infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y)
    infoFS:SetJustifyH("LEFT")
    infoFS:SetText(UI.ZoneColor(d.zone).."  "..variantText)
    -- Let the FontString auto-size to its text content (no fixed width)
    -- so flag buttons chain correctly after the actual text
    local infoTextW = infoFS:GetStringWidth()
    infoFS:SetWidth(math.max(infoTextW + 4, 100))

    -- Interactive flag badges with hover tooltips — all tags flow in one chain
    local FLAG_DEFS = {}
    if d.isBestRoute then table.insert(FLAG_DEFS, {text="|cFF00FF00[Best]|r", tip="Best Route", desc="This variant has the fastest known clear path for speed runs."}) end
    if d.hasBug then table.insert(FLAG_DEFS, {text="|cFFFF4444[Bug]|r", tip="Known Bug", desc="This variant has a known bug that may cause issues during the run."}) end
    if d.mountable then table.insert(FLAG_DEFS, {text="|cFFFFD700[Mt]|r", tip="Mountable", desc="You can use your mount inside this delve to move between packs faster."}) end
    if type(delveStatus)=="table" and delveStatus.nemesis then table.insert(FLAG_DEFS, {text="|cFFFF4444[Nemesis]|r", tip="Nemesis Active", desc="A Nemesis boss is present in this delve today. Swap Mandate of Sacred Death — no profession nodes in the arena."}) end
    if isBountiful then table.insert(FLAG_DEFS, {text="|cFFFFD700[Bountiful]|r", tip="Bountiful Delve", desc="This delve is Bountiful today. Use a Coffer Key to open the Bountiful Coffer for bonus loot."}) end
    if active then table.insert(FLAG_DEFS, {text="|cFF00FF44* TODAY|r", tip="Active Today", desc="This variant is the one currently available for this delve."}) end

    local lastAnchor = infoFS
    for _, flag in ipairs(FLAG_DEFS) do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(40, rH)
        btn:SetPoint("LEFT", lastAnchor, "RIGHT", lastAnchor == infoFS and 4 or 2, 0)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ROW_FONT_FILE, rSize)
        fs:SetAllPoints(); fs:SetJustifyH("LEFT")
        fs:SetText(flag.text)
        btn:SetWidth(math.max(fs:GetStringWidth() + 4, 30))
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("|cFFFFD700" .. flag.tip .. "|r")
            GameTooltip:AddLine(flag.desc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lastAnchor = btn
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

    -- "What are Delves?" hover tooltip — subtle "?" near header
    local helpBtn = CreateFrame("Button", nil, cf)
    helpBtn:SetSize(16, 16) -- size is immaterial since the FontString fills the button and handles mouse events
    helpBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -8, -8)
    local helpFS = helpBtn:CreateFontString(nil, "OVERLAY")
    helpFS:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 21, "OUTLINE", "BOLD")
    helpFS:SetAllPoints(); helpFS:SetJustifyH("CENTER")
    helpFS:SetText("|cFF777777?|r")
    helpBtn:SetScript("OnEnter", function(self)
        helpFS:SetText("|cFFFFFFFF?|r")
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700What are Delves?|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Short 1-5 player mini-dungeons across Quel'Thalas.", 1, 1, 1, true)
        GameTooltip:AddLine("No role requirements — bring any spec, any class.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFFD700Variants:|r Each delve has rotating story variants that change daily.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700Tiers:|r 1-11 control difficulty. Tier 8+ drops Hero-track (259 ilvl) gear.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700Bountiful:|r Marked delves that drop bonus loot when opened with a Restored Coffer Key.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700Coffer Keys:|r Earn Coffer Key Shards (600/week cap) — 100 shards = 1 key.", 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700Great Vault:|r 2/4/8 delves unlock vault slots. Tier 8+ gives 259 ilvl vault rewards.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Your companion Valeera joins every run. Set her role (DPS/Healer/Tank)", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("at Restoration Stones inside the delve. She levels up as you play.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() helpFS:SetText("|cFF777777?|r"); GameTooltip:Hide() end)

    -- Share to Chat button
    local shareBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    shareBtn:SetSize(110, 20)
    shareBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -10, -(y - 2))
    shareBtn:SetText("Share to Party")
    shareBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    shareBtn:SetScript("OnClick", function(_, button)
        local channel = (button == "RightButton") and "GUILD" or "PARTY"
        local av = DelveGuide.activeVariants or {}
        local ad = DelveGuide.activeDelves or {}
        local entries, seen = {}, {}
        if DelveGuideData and DelveGuideData.delves then
            for _, d in ipairs(DelveGuideData.delves) do
                if av[d.variant] and not seen[d.variant] then
                    seen[d.variant] = true
                    table.insert(entries, {variant=d.variant, ranking=d.ranking, delve=d.name})
                end
            end
        end
        if #entries == 0 then
            print("|cFF00BFFF[DelveGuide]|r No active variants to share. Try |cFFFFFF00/dg scan|r first.")
            return
        end
        table.sort(entries, function(a,b) return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99) end)
        SendChatMessage("[DelveGuide] Today's Active Delves:", channel)
        for _, e in ipairs(entries) do
            local ds = ad[e.delve]
            local bountyTag = (type(ds)=="table" and ds.bountiful) and " [Bountiful]" or ""
            SendChatMessage(string.format("  [%s] %s (%s)%s", e.ranking, e.variant, e.delve, bountyTag), channel)
        end
        print("|cFF00BFFF[DelveGuide]|r Shared "..#entries.." variants to |cFFFFFF00"..channel.."|r")
    end)
    shareBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700Share Active Variants|r")
        GameTooltip:AddLine("Left-click: Share to Party", 0.7, 1, 0.7)
        GameTooltip:AddLine("Right-click: Share to Guild", 0.5, 0.7, 1)
        GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

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