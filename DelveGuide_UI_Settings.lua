local UI = DelveGuide.UI
local L = DelveGuide.L

-- Labels for the bindings declared in Bindings.xml (the client auto-loads that
-- file from the addon root, so it has no .toc entry).
BINDING_HEADER_DELVEGUIDE             = "DelveGuide"
BINDING_NAME_DELVEGUIDE_TOGGLE        = L["Toggle DelveGuide window"]
BINDING_NAME_DELVEGUIDE_TOGGLE_HUD    = L["Toggle in-run HUD"]
BINDING_NAME_DELVEGUIDE_TOGGLE_WIDGET = L["Toggle compact widget"]

local function MakeSettingCheckbox(parent, y, labelText, getValue, onToggle)
    UI.EnsureFontFiles(); local _, rSize = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local cb = UI.AcquireCheckButton()
    cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -y)
    cb:SetChecked(getValue())
    local lbl = UI.AcquireFontString("OVERLAY")
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

    y = y + UI.CreateHeader(cf, y, L["Settings"]) + 8

    -- Slash commands stay out of L (see the policy note in DelveGuide_Locale.lua):
    -- they are typed, not read, so they ride into the caption as the %s.
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Minimap"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Show minimap button"] .. "  |cFF888888" .. string.format(L["(or: %s)"], "/dg minimap") .. "|r",
        function() return not DelveGuideDB.minimap.hide end,
        function(checked) DelveGuideDB.minimap.hide = not checked; UI.UpdateMinimap() end) + 4
    -- The compartment is Blizzard's "AddOns" button on the minimap. Until 2.0
    -- the flag was forced on at every load, so there was no way to leave it;
    -- this is the way. LibDBIcon keeps the flag in DelveGuideDB.minimap itself.
    y = y + MakeSettingCheckbox(cf, y, L["Show in the addon compartment"] .. "  |cFF888888" .. L["(the AddOns button on the minimap)"] .. "|r",
        function() return DelveGuideDB.minimap.showInCompartment ~= false end,
        function(checked)
            DelveGuideDB.minimap.showInCompartment = checked
            local lib = LibStub and LibStub("LibDBIcon-1.0", true)
            if not lib then return end
            if checked then
                if lib.AddButtonToCompartment then lib:AddButtonToCompartment("DelveGuide") end
            elseif lib.RemoveButtonFromCompartment then
                lib:RemoveButtonFromCompartment("DelveGuide")
            end
        end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Compact Widget"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Show compact floating widget"] .. "  |cFF888888" .. string.format(L["(or: %s)"], "/dg widget") .. "|r",
        function() return not DelveGuideDB.widgetHidden end,
        function(checked) DelveGuideDB.widgetHidden = not checked; UI.UpdateWidgetVis() end)
    y = y + MakeSettingCheckbox(cf, y, L["Click widget to open/close main window"],
        function() return DelveGuideDB.widgetClickOpens end,
        function(checked) DelveGuideDB.widgetClickOpens = checked end)
    y = y + MakeSettingCheckbox(cf, y, L["Auto-hide widget"] .. "  |cFF888888" .. L["(fades out when not hovered)"] .. "|r",
        function() return DelveGuideDB.widgetAutoHide end,
        function(checked) DelveGuideDB.widgetAutoHide = checked; UI.UpdateWidgetAlpha() end)
    y = y + MakeSettingCheckbox(cf, y, string.format(L["Show only %s delves"], "|cFFFFD700bountiful|r") .. "  |cFF888888" .. string.format(L["(or: %s, or [B] button on widget)"], "/dg bountiful") .. "|r",
        function() return DelveGuideDB.widgetBountifulOnly end,
        function(checked)
            DelveGuideDB.widgetBountifulOnly = checked
            local cw = DelveGuide.compactWidget
            if cw and cw.RefreshBountyBtn then cw.RefreshBountyBtn() end
            UI.UpdateCompactWidget()
        end)

    y = y + 4
    y = y + UI.CreateRow(cf, y, "|cFFAAAAAA" .. L["Widget tier filter - show active variants at these rankings:"] .. "|r") + 6
    local allRanks = {"S","A","B","C","D","F"}
    for i, rank in ipairs(allRanks) do
        local cb = UI.AcquireCheckButton()
        cb:SetSize(22, 22); cb:SetPoint("TOPLEFT", cf, "TOPLEFT", 10 + (i-1)*80, -y)
        cb:SetChecked(DelveGuideDB.widgetTiers[rank])
        local lbl = UI.AcquireFontString("OVERLAY")
        lbl:SetFont(ROW_FONT_FILE, 11)
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetText((UI.RANK_COLORS[rank] or "|cFFFFFFFF")..rank.."|r")
        local r = rank
        cb:SetScript("OnClick", function(self)
            DelveGuideDB.widgetTiers[r] = self:GetChecked(); UI.UpdateCompactWidget()
        end)
    end
    y = y + 30 + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Pre-Entry Checklist"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Show checklist when targeting a delve entrance"] .. "  |cFF888888" .. string.format(L["(or: %s)"], "/dg check") .. "|r",
        function() return DelveGuideDB.checklistEnabled end,
        function(checked) DelveGuideDB.checklistEnabled = checked end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["In-Run HUD"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Auto-show HUD when inside a Delve"] .. "  |cFF888888" .. string.format(L["(or: %s)"], "/dg hud") .. "|r",
        function() return DelveGuideDB.hudEnabled end,
        function(checked) DelveGuideDB.hudEnabled = checked; if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Font Scale"] .. "|r") + 6
    local fsDesc = UI.AcquireFontString("OVERLAY")
    fsDesc:SetFont(ROW_FONT_FILE, rSize)
    fsDesc:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    fsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.fontScale)))
    y = y + rH + 4

    
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Victory Screen"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Enable Victory Screen popup on completion"],
        function() return DelveGuideDB.victoryEnabled ~= false end, -- Defaults to true
        function(checked) DelveGuideDB.victoryEnabled = checked end)
    y = y + MakeSettingCheckbox(cf, y, L["Play victory sound effect"],
        function() return DelveGuideDB.victorySound ~= false end, -- Defaults to true
        function(checked) DelveGuideDB.victorySound = checked end)
    y = y + MakeSettingCheckbox(cf, y, L["Unlock Victory Screen (allows dragging)"],
        function() return DelveGuideDB.victoryUnlocked end,
        function(checked) DelveGuideDB.victoryUnlocked = checked end) + 4
        
    local testVicBtn = UI.AcquirePanelButton()
    testVicBtn:SetSize(160, 22); testVicBtn:SetText(L["Test / Move Popup"])
    testVicBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 14, -y)
    testVicBtn:SetScript("OnClick", function()
        if DelveGuide.ShowVictoryScreen then
            DelveGuide.ShowVictoryScreen("Test Delve", "Tier 8", 610)
        end
    end)
    y = y + 22 + 12 -- Add height for the button and padding

    local function MakeFontScaleBtn(label, xOff, delta)
        local b = UI.AcquirePanelButton()
        b:SetSize(36, 22); b:SetText(label); b:SetPoint("TOPLEFT", cf, "TOPLEFT", xOff, -y)
        b:SetScript("OnClick", function()
            DelveGuideDB.fontScale = math.max(0.6, math.min(2.0, DelveGuideDB.fontScale + delta))
            fsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.fontScale)))
            UI.RefreshCurrentTab()
        end)
    end
    MakeFontScaleBtn("A-", 10, -0.1); MakeFontScaleBtn("A+", 52, 0.1)

    local resetBtn = UI.AcquirePanelButton()
    resetBtn:SetSize(60, 22); resetBtn:SetText(L["Reset"]); resetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 94, -y)
    resetBtn:SetScript("OnClick", function()
        DelveGuideDB.fontScale = 1.0
        fsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.fontScale)))
        UI.RefreshCurrentTab()
    end)
    y = y + 30 + 16

    -- Widget Font Scale (independent of main font scale)
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Widget Font Scale"] .. "|r  |cFF888888" .. L["(independent from main font)"] .. "|r") + 6
    local wfsDesc = UI.AcquireFontString("OVERLAY")
    wfsDesc:SetFont(ROW_FONT_FILE, rSize)
    wfsDesc:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    wfsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.widgetFontScale or 1.0)))
    y = y + rH + 4

    local function MakeWidgetFontBtn(label, xOff, delta)
        local b = UI.AcquirePanelButton()
        b:SetSize(36, 22); b:SetText(label); b:SetPoint("TOPLEFT", cf, "TOPLEFT", xOff, -y)
        b:SetScript("OnClick", function()
            DelveGuideDB.widgetFontScale = math.max(0.6, math.min(2.0, (DelveGuideDB.widgetFontScale or 1.0) + delta))
            wfsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.widgetFontScale)))
            if DelveGuide.RefreshCompactWidgetFonts then DelveGuide.RefreshCompactWidgetFonts() end
        end)
    end
    MakeWidgetFontBtn("A-", 10, -0.1); MakeWidgetFontBtn("A+", 52, 0.1)

    local wResetBtn = UI.AcquirePanelButton()
    wResetBtn:SetSize(60, 22); wResetBtn:SetText(L["Reset"]); wResetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 94, -y)
    wResetBtn:SetScript("OnClick", function()
        DelveGuideDB.widgetFontScale = 1.0
        wfsDesc:SetText(string.format(L["Current: %s  (range: 0.6 - 2.0)"], string.format("|cFFFFFFFF%.1fx|r", DelveGuideDB.widgetFontScale)))
        if DelveGuide.RefreshCompactWidgetFonts then DelveGuide.RefreshCompactWidgetFonts() end
    end)
    y = y + 30 + 16

    -- Map Tooltips Section 
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Map Tooltips"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Enable World Map tooltips for active delves"],
        function() return DelveGuideDB.mapTooltips ~= false end,
        function(checked) 
            DelveGuideDB.mapTooltips = checked 
            print("|cFF00BFFF[DelveGuide]|r " .. L["Map Tooltips:"] .. " " .. (checked and "|cFF44FF44" .. L["Enabled"] .. "|r" or "|cFFFF4444" .. L["Disabled"] .. "|r"))
        end) + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Changelog"] .. "|r") + 6
    y = y + MakeSettingCheckbox(cf, y, L["Show What's New popup on version update"],
        function() return DelveGuideDB.showChangelog end,
        function(checked) DelveGuideDB.showChangelog = checked end) + 4
    y = y + MakeSettingCheckbox(cf, y, L["Show the Debug tab"] .. " |cFF888888" .. L["(for bug reports and translations)"] .. "|r",
        function() return DelveGuideDB.showDebugTab end,
        function(checked)
            DelveGuideDB.showDebugTab = checked
            if DelveGuide.SetDebugTabShown then DelveGuide.SetDebugTabShown(checked) end
        end) + 4
        
    local clBtn = UI.AcquirePanelButton()
    clBtn:SetSize(160, 26); clBtn:SetText(L["View Changelog"])
    clBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    clBtn:SetScript("OnClick", UI.ShowChangelogPopup)
    y = y + 34 + 8

    -- ---- Community Rankings & Contributors ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Community Rankings"] .. "|r") + 6

    local rs = DelveGuideData.rankingStats
    if rs then
        -- The two counts arrive pre-coloured so the sentence a translator sees
        -- carries no markup, and they can move the numbers within it.
        y = y + UI.CreateRow(cf, y, string.format(
            "|cFFCCCCCC" .. L["Delve rankings come from %s player submissions -- %s variants ranked by median Tier 8+ clear time."] .. "|r  |cFF888888" .. L["(updated %s)"] .. "|r",
            "|cFF00FF88" .. (rs.submissions or 0) .. "|r|cFFCCCCCC",
            "|cFF00FF88" .. (rs.variants or 0) .. "|r|cFFCCCCCC",
            rs.updated or "?")) + 4
    end

    local subBtn = UI.AcquirePanelButton()
    subBtn:SetSize(200, 26); subBtn:SetText(L["Contribute Your Times"])
    subBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -y)
    subBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cFFFFD700" .. L["Help rank the delves"] .. "|r")
        GameTooltip:AddLine(L["Copies your run times so you can paste them into the ranking form."], 1, 1, 1, true)
        GameTooltip:AddLine(string.format(L["Same as %s."], "/dg submit"), 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    subBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    subBtn:SetScript("OnClick", function()
        if DelveGuide.ShowSubmitDialog then DelveGuide.ShowSubmitDialog() end
    end)
    y = y + 34

    local contribs = DelveGuideData.contributors
    if contribs and #contribs > 0 then
        y = y + UI.CreateRow(cf, y, string.format("|cFF00FF88" .. L["Thanks to the %d delvers who sent in their times:"] .. "|r", #contribs)) + 4
        -- Wrap the handles into lines that fit the window.
        local line, lineLen = {}, 0
        local function flush()
            if #line > 0 then
                y = y + UI.CreateRow(cf, y, "|cFFCCAAFF  " .. table.concat(line, "  ~  ") .. "|r") + 2
                line, lineLen = {}, 0
            end
        end
        for _, name in ipairs(contribs) do
            if lineLen + #name > 62 then flush() end
            table.insert(line, name)
            lineLen = lineLen + #name + 5
        end
        flush()
        y = y + 4
        y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Submit your own times and your name lands here next update."] .. "|r") + 4
    end

    -- ---- About / Links ----
    y = y + 8
    y = y + UI.CreateHeader(cf, y, L["About"]) + 6

    local version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("DelveGuide", "Version"))
        or (GetAddOnMetadata and GetAddOnMetadata("DelveGuide", "Version")) or "?"
    -- Version string and author name are arguments, never translated content.
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC" .. string.format(L["Version %s by %s"],
        "|cFFFFFFFF" .. version .. "|r|cFFCCCCCC", "|r|cFFFFD700Thunderz|r")) + 8

    -- Links live in edit boxes so they can actually be copied out of the game
    -- (Ctrl+C), the same trick the /dg submit popup uses. Typing in one just
    -- puts the link back.
    local function MakeLinkRow(label, url)
        local lbl = UI.AcquireFontString("OVERLAY")
        lbl:SetFont(ROW_FONT_FILE, rSize)
        lbl:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -(y + 4))
        lbl:SetWidth(110); lbl:SetJustifyH("LEFT")
        lbl:SetText("|cFFAAAAAA" .. label .. "|r")

        local eb = UI.AcquireEditBox()
        eb:SetSize(330, 20)
        eb:SetPoint("TOPLEFT", cf, "TOPLEFT", 126, -y)
        eb:SetAutoFocus(false)
        eb:SetText(url)
        eb:SetCursorPosition(0)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self:SetText(url); self:HighlightText() end
        end)
        y = y + 26
    end

    MakeLinkRow("GitHub", "https://github.com/Thunderz96/DelveGuide")
    MakeLinkRow("CurseForge", "https://www.curseforge.com/wow/addons/delveguide")
    -- Same form /dg submit points at (SUBMIT_URL in DelveGuide.lua).
    MakeLinkRow(L["Rankings form"], "https://forms.gle/BwrGBZkRmbQdwufN8")

    cf:SetHeight(y + 20)
end

-- ESC > Options > AddOns signpost. Players look for addon settings there first
-- and concluded DelveGuide had none; this is a pointer to the real window, not
-- a second copy of the Settings tab.
if Settings and Settings.RegisterCanvasLayoutCategory then
    local panel = CreateFrame("Frame", "DelveGuideOptionsPanel", UIParent)
    panel.name = "DelveGuide"

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    desc:SetText(L["DelveGuide's settings live in its own window."])

    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(180, 24); openBtn:SetText(L["Open DelveGuide"])
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
    openBtn:SetScript("OnClick", function()
        -- The options panel sits on top of everything, so close it or the
        -- window we just opened is invisible behind it.
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        DelveGuide.Toggle()
    end)

    -- The canvas layout calls these on Okay/Defaults/open; no-ops keep it happy.
    panel.OnCommit  = function() end
    panel.OnDefault = function() end
    panel.OnRefresh = function() end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "DelveGuide")
    Settings.RegisterAddOnCategory(category)
end