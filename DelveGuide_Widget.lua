-- ============================================================
-- DelveGuide_Widget.lua
-- ============================================================
local UI = DelveGuide.UI

local RANK_ORDER  = {S=1, A=2, B=3, C=4, D=5, F=6}
local W_HEADER_H  = 28
local W_LINE_H    = 18
local W_PAD       = 10
local W_MAX_LINES = 8

DelveGuide.compactWidget = nil

DelveGuide.UpdateCompactWidget = function()
    local cw = DelveGuide.compactWidget
    if not cw or not cw:IsShown() then return end
    
    local activeVariants = DelveGuide.activeVariants or {}
    local activeDelves   = DelveGuide.activeDelves or {}
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
    
    local n = math.min(#entries, W_MAX_LINES)
    if n == 0 then
        cw.varLines[1].label:SetText("|cFF888888No active variants|r")
        cw.varLines[1].pin = nil
        cw.varLines[1]:ClearAllPoints()
        cw.varLines[1]:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, -(W_HEADER_H+4))
        cw.varLines[1]:Show()
        n = 1
        for i = 2, W_MAX_LINES do cw.varLines[i]:Hide() end
    else
        for i = 1, W_MAX_LINES do
            local line = cw.varLines[i]
            local e = entries[i]
            if e then
                local rc = UI.RANK_COLORS[e.ranking] or "|cFFFFFFFF"
                local pin = UI.FindPinByName(e.delve)
                local nameText = pin and ("|cFF00CFFF"..e.variant.."|r") or e.variant
                local ds = activeDelves[e.delve]
                local bountyTag = (type(ds)=="table" and ds.bountiful) and "  |cFFFFD700[B]|r" or ""
                line.label:SetText(rc.."["..e.ranking.."]|r  "..nameText..bountyTag)
                line.pin = pin
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, -(W_HEADER_H+4+(i-1)*W_LINE_H))
                line:Show()
            else line:Hide() end
        end
    end
    
    local keysY = -(W_HEADER_H + 4 + n*W_LINE_H + 6)
    cw.keysLine:ClearAllPoints()
    cw.keysLine:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, keysY)
    cw:SetHeight(W_HEADER_H + 4 + n*W_LINE_H + 6 + W_LINE_H + W_PAD)
    
    local keysInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards   = keysInfo and keysInfo.quantity or 0
    local restored = C_Item.GetItemCount(3028, true) or 0
    local keysStr  = string.format("|cFFFFD700Keys:|r %d/600 shards", shards)
    
    if restored > 0 then
        keysStr = keysStr .. string.format("  |cFF00FF44+%d restored|r", restored)
    end
    cw.keysLine:SetText(keysStr)
end

DelveGuide.CreateCompactWidget = function()
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
    else 
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 250) 
    end
    
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=false, tileSize=16, edgeSize=12,
        insets={left=3, right=3, top=3, bottom=3}
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.88)
    f:SetBackdropBorderColor(0.15, 0.5, 1, 0.8)
    
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cFF00BFFFDelveGuide|r")
        GameTooltip:AddLine("Drag to reposition.", 0.7, 0.7, 0.7)
        if DelveGuideDB.widgetClickOpens then GameTooltip:AddLine("Click to open/close.", 1, 1, 1) end
        GameTooltip:Show()
        if DelveGuideDB.widgetAutoHide then UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1.0) end
    end)
    
    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if DelveGuideDB.widgetAutoHide and not self:IsMouseOver() then
            UIFrameFadeOut(self, 0.5, self:GetAlpha(), 0.15)
        end
    end)

    local titleFS = f:CreateFontString(nil, "OVERLAY")
    titleFS:SetFont(GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    titleFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -9)
    titleFS:SetText("|cFF00BFFFDelveGuide|r")

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

    local div = f:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(0.15, 0.5, 1, 0.35); div:SetSize(204, 1)
    div:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)

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
            if self.pin then UI.SetDelveWaypoint(self.pin) end
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

    f.keysLine = f:CreateFontString(nil, "OVERLAY")
    f.keysLine:SetFont(sf, 11); f.keysLine:SetWidth(204); f.keysLine:SetJustifyH("LEFT")
    f.keysLine:SetText("|cFFFFD700Keys:|r --")
    
    if DelveGuideDB.widgetHidden then f:Hide() end
    if DelveGuideDB.widgetAutoHide then f:SetAlpha(0.15) end
    
    DelveGuide.compactWidget = f
    DelveGuide.UpdateCompactWidget()
end

DelveGuide.ToggleWidget = function()
    DelveGuideDB.widgetHidden = not DelveGuideDB.widgetHidden
    local cw = DelveGuide.compactWidget
    if cw then
        if DelveGuideDB.widgetHidden then cw:Hide() else cw:Show() end
    end
    print("|cFF00BFFF[DelveGuide]|r Compact widget: "..(DelveGuideDB.widgetHidden and "|cFFFF4444hidden|r" or "|cFF44FF44shown|r"))
end