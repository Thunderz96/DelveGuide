local UI = DelveGuide.UI

local function MakeSettingCheckbox(parent, y, labelText, getValue, onToggle)
    UI.EnsureFontFiles(); local _, rSize = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -y)
    cb:SetChecked(getValue())
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ROW_FONT_FILE, rSize)
    lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    lbl:SetText(labelText)
    cb:SetScript("OnClick", function(self) onToggle(self:GetChecked()) end)
    return 30
end

DelveGuide.RenderSettings = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, "Settings") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Minimap|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Show minimap button  |cFF888888(or: /dg minimap)|r",
        function() return not DelveGuideDB.minimap.hide end,
        function(checked) DelveGuideDB.minimap.hide = not checked; UI.UpdateMinimap() end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Compact Widget|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Show compact floating widget  |cFF888888(or: /dg widget)|r",
        function() return not DelveGuideDB.widgetHidden end,
        function(checked) DelveGuideDB.widgetHidden = not checked; UI.UpdateWidgetVis() end)
    y = y + MakeSettingCheckbox(cf, y, "Click widget to open/close main window",
        function() return DelveGuideDB.widgetClickOpens end,
        function(checked) DelveGuideDB.widgetClickOpens = checked end)
    y = y + MakeSettingCheckbox(cf, y, "Auto-hide widget  |cFF888888(fades out when not hovered)|r",
        function() return DelveGuideDB.widgetAutoHide end,
        function(checked) DelveGuideDB.widgetAutoHide = checked; UI.UpdateWidgetAlpha() end)

    y = y + 4
    y = y + UI.CreateRow(cf, y, "|cFFAAAAAAAAWidget tier filter - show active variants at these rankings:|r") + 6
    local allRanks = {"S","A","B","C","D","F"}
    for i, rank in ipairs(allRanks) do
        local cb = CreateFrame("CheckButton", nil, cf, "UICheckButtonTemplate")
        cb:SetSize(22, 22); cb:SetPoint("TOPLEFT", cf, "TOPLEFT", 10 + (i-1)*80, -y)
        cb:SetChecked(DelveGuideDB.widgetTiers[rank])
        local lbl = cf:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ROW_FONT_FILE, 11)
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText((UI.RANK_COLORS[rank] or "|cFFFFFFFF")..rank.."|r")
        local r = rank
        cb:SetScript("OnClick", function(self)
            DelveGuideDB.widgetTiers[r] = self:GetChecked(); UI.UpdateCompactWidget()
        end)
    end
    y = y + 30 + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Pre-Entry Checklist|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Show checklist when targeting a delve entrance  |cFF888888(or: /dg check)|r",
        function() return DelveGuideDB.checklistEnabled end,
        function(checked) DelveGuideDB.checklistEnabled = checked end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700In-Run HUD|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Auto-show HUD when inside a Delve  |cFF888888(or: /dg hud)|r",
        function() return DelveGuideDB.hudEnabled end,
        function(checked) DelveGuideDB.hudEnabled = checked; if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Font Scale|r") + 6
    local fsDesc = cf:CreateFontString(nil, "OVERLAY")
    fsDesc:SetFont(ROW_FONT_FILE, rSize)
    fsDesc:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 - 2.0)", DelveGuideDB.fontScale))
    y = y + rH + 4

    
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Victory Screen|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Enable Victory Screen popup on completion",
        function() return DelveGuideDB.victoryEnabled ~= false end, -- Defaults to true
        function(checked) DelveGuideDB.victoryEnabled = checked end)
    y = y + MakeSettingCheckbox(cf, y, "Play victory sound effect",
        function() return DelveGuideDB.victorySound ~= false end, -- Defaults to true
        function(checked) DelveGuideDB.victorySound = checked end)
    y = y + MakeSettingCheckbox(cf, y, "Unlock Victory Screen (allows dragging)",
        function() return DelveGuideDB.victoryUnlocked end,
        function(checked) DelveGuideDB.victoryUnlocked = checked end) + 4
        
    local testVicBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    testVicBtn:SetSize(160, 22); testVicBtn:SetText("Test / Move Popup")
    testVicBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 14, -y)
    testVicBtn:SetScript("OnClick", function()
        if DelveGuide.ShowVictoryScreen then
            DelveGuide.ShowVictoryScreen("Test Delve", "Tier 8", 610)
        end
    end)
    y = y + 22 + 12 -- Add height for the button and padding

    local function MakeFontScaleBtn(label, xOff, delta)
        local b = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
        b:SetSize(36, 22); b:SetText(label); b:SetPoint("TOPLEFT", cf, "TOPLEFT", xOff, -y)
        b:SetScript("OnClick", function()
            DelveGuideDB.fontScale = math.max(0.6, math.min(2.0, DelveGuideDB.fontScale + delta))
            fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 - 2.0)", DelveGuideDB.fontScale))
            UI.RefreshCurrentTab()
        end)
    end
    MakeFontScaleBtn("A-", 10, -0.1); MakeFontScaleBtn("A+", 52, 0.1)
    
    local resetBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    resetBtn:SetSize(60, 22); resetBtn:SetText("Reset"); resetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 94, -y)
    resetBtn:SetScript("OnClick", function()
        DelveGuideDB.fontScale = 1.0
        fsDesc:SetText(string.format("Current: |cFFFFFFFF%.1fx|r  (range: 0.6 - 2.0)", DelveGuideDB.fontScale))
        UI.RefreshCurrentTab()
    end)
    y = y + 30 + 16

    -- Map Tooltips Section 
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Map Tooltips|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Enable World Map tooltips for active delves",
        function() return DelveGuideDB.mapTooltips ~= false end,
        function(checked) 
            DelveGuideDB.mapTooltips = checked 
            print("|cFF00BFFF[DelveGuide]|r Map Tooltips: " .. (checked and "|cFF44FF44Enabled|r" or "|cFFFF4444Disabled|r"))
        end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Changelog|r") + 6
    y = y + MakeSettingCheckbox(cf, y, "Show What's New popup on version update",
        function() return DelveGuideDB.showChangelog end,
        function(checked) DelveGuideDB.showChangelog = checked end) + 4
        
    local clBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    clBtn:SetSize(160, 26); clBtn:SetText("View Changelog")
    clBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    clBtn:SetScript("OnClick", UI.ShowChangelogPopup)
    y = y + 34

    cf:SetHeight(y + 20)
end