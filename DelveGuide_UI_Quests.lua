-- ============================================================
-- DelveGuide_UI_Quests.lua  --  Delver's Call quest tracker tab
-- ============================================================
local UI = DelveGuide.UI

local STATE_LABEL = {
    fresh      = { text = "Available",   color = "|cFF888888" },
    inProgress = { text = "In Progress", color = "|cFFFF8800" },
    ready      = { text = "Banked",      color = "|cFFFFD700" },
    completed  = { text = "Turned In",   color = "|cFF44FF44" },
}

DelveGuide.RenderQuests = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, "Delver's Call  --  World Tour Quest Tracker") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Each rotational delve has a Delver's Call quest. Run every delve once to pick the quest up but |cFFFFD700don't turn it in yet|r|cFF888888 -- the XP scales to your level at turn-in. Bank all 10, then cash them in once you're close to max level for a big push through the final levels. (Turning them in at the cap itself wastes the XP -- you want to be a few levels short.)|r") + 8

    -- Summary bar for the active character.
    local summary = DelveGuide.GetDelversCallSummary and DelveGuide.GetDelversCallSummary() or { fresh=0, inProgress=0, ready=0, completed=0, total=0, autoCount=0 }
    local autoTag = ""
    if summary.autoCount > 0 and summary.autoCount < summary.total then
        autoTag = string.format("  |cFF888888(%d/%d auto-detected)|r", summary.autoCount, summary.total)
    elseif summary.autoCount == summary.total and summary.total > 0 then
        autoTag = "  |cFF44FF44(auto-detect on)|r"
    else
        autoTag = "  |cFFFF8800(manual mode -- /dg questscan to find quest IDs)|r"
    end
    y = y + UI.CreateRow(cf, y, string.format("|cFFCCCCCCThis character:|r  |cFF888888%d|r available  |cFFFF8800%d|r in progress  |cFFFFD700%d|r banked  |cFF44FF44%d|r turned in  |cFF888888(of %d)|r%s",
        summary.fresh or 0, summary.inProgress or 0, summary.ready or 0, summary.completed or 0, summary.total or 0, autoTag)) + 6

    -- Reset button (manual mode only -- auto mode resets itself per character).
    local resetBtn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
    resetBtn:SetSize(170, 22)
    resetBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -10, -8)
    resetBtn:SetText("Reset Manual State")
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Clears the manual checkbox state for this character only.", 1, 1, 1)
        GameTooltip:AddLine("Use this when you start a fresh alt.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resetBtn:SetScript("OnClick", function()
        if DelveGuide.ResetDelversCallManual then DelveGuide.ResetDelversCallManual() end
        UI.RefreshCurrentTab()
    end)

    -- ---- Per-Delve Rows ----
    if not (DelveGuideData and DelveGuideData.delversCall) then
        y = y + UI.CreateRow(cf, y, "|cFFFF4444No Delver's Call data found.|r") + 4
        cf:SetHeight(y + 20); return
    end

    -- Build a delve -> zone map from the existing rankings table for tooltip context.
    local delveZone = {}
    if DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            if d.name and d.zone and not delveZone[d.name] then
                delveZone[d.name] = d.zone
            end
        end
    end

    for _, row in ipairs(DelveGuideData.delversCall) do
        local delveName = row.delve
        local state, isAuto = "fresh", false
        if DelveGuide.GetDelversCallState then
            state, isAuto = DelveGuide.GetDelversCallState(delveName)
        end
        local label = STATE_LABEL[state] or STATE_LABEL.fresh

        local container = CreateFrame("Button", nil, cf)
        container:SetPoint("TOPLEFT", cf, "TOPLEFT", 14, -y)
        container:SetSize(UI.WINDOW_W - 80, rH + 4)

        -- Highlights:
        --   ready (banked & objectives done) -> bright gold bar (do this next at cap)
        --   inProgress (in log, objectives pending) -> dim orange tint
        --   completed -> faint green tint
        if state == "ready" then
            local fill = container:CreateTexture(nil, "BACKGROUND")
            fill:SetAllPoints(container)
            fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            fill:SetGradient("HORIZONTAL", CreateColor(1, 0.85, 0, 0.22), CreateColor(1, 0.85, 0, 0))
            local bar = container:CreateTexture(nil, "ARTWORK")
            bar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            bar:SetSize(3, rH + 4); bar:SetColorTexture(1, 0.85, 0, 1)
        elseif state == "inProgress" then
            local fill = container:CreateTexture(nil, "BACKGROUND")
            fill:SetAllPoints(container)
            fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            fill:SetGradient("HORIZONTAL", CreateColor(1, 0.55, 0, 0.10), CreateColor(1, 0.55, 0, 0))
        elseif state == "completed" then
            local fill = container:CreateTexture(nil, "BACKGROUND")
            fill:SetAllPoints(container)
            fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            fill:SetGradient("HORIZONTAL", CreateColor(0.27, 1, 0.27, 0.12), CreateColor(0.27, 1, 0.27, 0))
        end

        local nameFS = container:CreateFontString(nil, "OVERLAY")
        nameFS:SetFont(ROW_FONT_FILE, rSize)
        nameFS:SetPoint("LEFT", container, "LEFT", 12, 0); nameFS:SetWidth(220); nameFS:SetJustifyH("LEFT")
        nameFS:SetText("|cFF00CFFF" .. delveName .. "|r")

        local zoneFS = container:CreateFontString(nil, "OVERLAY")
        zoneFS:SetFont(ROW_FONT_FILE, rSize)
        zoneFS:SetPoint("LEFT", container, "LEFT", 240, 0); zoneFS:SetWidth(140); zoneFS:SetJustifyH("LEFT")
        zoneFS:SetText("|cFF888888" .. (delveZone[delveName] or "") .. "|r")

        local stateFS = container:CreateFontString(nil, "OVERLAY")
        stateFS:SetFont(ROW_FONT_FILE, rSize)
        stateFS:SetPoint("LEFT", container, "LEFT", 380, 0); stateFS:SetWidth(110); stateFS:SetJustifyH("LEFT")
        local autoMark = isAuto and " |cFF44FF44(auto)|r" or ""
        stateFS:SetText(label.color .. label.text .. "|r" .. autoMark)

        -- Manual cycle button (only meaningful when not auto-detected).
        if not isAuto then
            local cycleBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
            cycleBtn:SetSize(96, 18)
            cycleBtn:SetPoint("LEFT", container, "LEFT", 500, 0)
            local nextLabel = (state == "fresh")      and "Mark In Log"
                          or (state == "inProgress") and "Mark Banked"
                          or (state == "ready")      and "Mark Done"
                          or "Reset"
            cycleBtn:SetText(nextLabel)
            cycleBtn:SetScript("OnClick", function()
                if DelveGuide.CycleDelversCallManual then DelveGuide.CycleDelversCallManual(delveName) end
                UI.RefreshCurrentTab()
            end)
        else
            local autoFS = container:CreateFontString(nil, "OVERLAY")
            autoFS:SetFont(ROW_FONT_FILE, rSize)
            autoFS:SetPoint("LEFT", container, "LEFT", 500, 0); autoFS:SetWidth(110); autoFS:SetJustifyH("LEFT")
            autoFS:SetText("|cFF555555quest #" .. tostring(row.questID) .. "|r")
        end

        y = y + rH + 6
    end

    y = y + 6

    -- ---- Alt Rollup ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Alt Rollup|r") + 4

    local rosterStore = DelveGuideDB and DelveGuideDB.delversCall or {}
    local rosterMeta  = DelveGuideDB and DelveGuideDB.roster or {}
    local seenChars = {}
    for k in pairs(rosterStore) do seenChars[k] = true end
    -- Always include the current character so a fresh alt shows up immediately.
    local currentName  = UnitName("player") or "?"
    local currentRealm = GetRealmName() or "?"
    seenChars[currentName .. "-" .. currentRealm] = true

    local keys = {}
    for k in pairs(seenChars) do table.insert(keys, k) end
    table.sort(keys)

    if #keys == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  No characters tracked yet.|r") + 4
    else
        for _, k in ipairs(keys) do
            local store = rosterStore[k] or {}
            local meta  = rosterMeta[k]  or {}
            local inProg, ready, done = 0, 0, 0
            local total = (DelveGuideData and DelveGuideData.delversCall) and #DelveGuideData.delversCall or 10

            -- For the current character, mix manual + auto so the count is honest.
            local isCurrent = (k == (currentName .. "-" .. currentRealm))
            if isCurrent then
                for _, row in ipairs(DelveGuideData.delversCall) do
                    local s = DelveGuide.GetDelversCallState and DelveGuide.GetDelversCallState(row.delve) or "fresh"
                    if s == "inProgress" then inProg = inProg + 1
                    elseif s == "ready" then ready = ready + 1
                    elseif s == "completed" then done = done + 1 end
                end
            else
                for _, s in pairs(store) do
                    if s == "inProgress" then inProg = inProg + 1
                    elseif s == "ready" then ready = ready + 1
                    elseif s == "completed" then done = done + 1 end
                end
            end

            local nameTag = isCurrent and ("|cFF00CFFF" .. (meta.name or currentName) .. "|r") or ("|cFFCCCCCC" .. (meta.name or k) .. "|r")
            local remaining = math.max(0, total - inProg - ready - done)
            y = y + UI.CreateRow(cf, y, string.format("  %s  |cFF666666(%s)|r  --  |cFFFF8800%d|r in progress  |cFFFFD700%d|r banked  |cFF44FF44%d|r done  |cFF888888%d|r remaining",
                nameTag, meta.realm or "?", inProg, ready, done, remaining)) + 2
        end
    end

    cf:SetHeight(y + 20)
end
