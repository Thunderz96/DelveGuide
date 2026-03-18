-- ============================================================
-- DelveGuide_HUD.lua  --  In-run overlay HUD
-- Auto-shows while inside a known Delve, hides on exit.
-- ============================================================

local HUD_W, HUD_H = 290, 178

local hudFrame  = nil
local lockBtn   = nil

-- ── helpers ──────────────────────────────────────────────────

local function GetCurrentDelveName()
    local zoneName = ""
    pcall(function() zoneName = GetRealZoneText() or "" end)
    if not DelveGuideData or not DelveGuideData.delves then return nil end
    -- Direct match (EN clients)
    for _, d in ipairs(DelveGuideData.delves) do
        if d.name == zoneName then return zoneName end
    end
    -- Localized → English fallback (non-EN clients)
    local l10n = DelveGuide and DelveGuide.localizedToEnglish
    if l10n and l10n[zoneName] then return l10n[zoneName] end
    return nil
end

local function IsInsideDelve()
    -- Zone name alone is unreliable for seamless delves (e.g. Atal'Aman bleeds into
    -- the Zul'Aman overworld). Require an active scenario as a second condition.
    local inScenario = false
    pcall(function() inScenario = C_Scenario.IsInScenario() end)
    if not inScenario then return false end
    return GetCurrentDelveName() ~= nil
end

-- ── build ────────────────────────────────────────────────────

local function BuildHUD()
    if hudFrame then return end

    hudFrame = CreateFrame("Frame", "DelveGuideHUDFrame", UIParent, "BackdropTemplate")
    hudFrame:SetSize(HUD_W, HUD_H)
    hudFrame:SetFrameStrata("MEDIUM")
    hudFrame:SetFrameLevel(50)
    hudFrame:SetClampedToScreen(true)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", function(self)
        if DelveGuideDB and DelveGuideDB.hudLocked then return end
        self:StartMoving()
    end)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x = self:GetLeft()
        local y = self:GetTop() - UIParent:GetHeight()
        if DelveGuideDB then DelveGuideDB.hudX = x; DelveGuideDB.hudY = y end
    end)

    -- Restore saved position or default to right-center
    local db = DelveGuideDB
    if db and db.hudX and db.hudY then
        hudFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.hudX, db.hudY)
    else
        hudFrame:SetPoint("CENTER", UIParent, "CENTER", 450, 100)
    end

    -- Backdrop (background + border)
    hudFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    hudFrame:SetBackdropColor(0, 0, 0, 0.80)
    hudFrame:SetBackdropBorderColor(0.15, 0.45, 0.85, 0.85)

    -- Header bar (dark blue strip)
    local hdrBg = hudFrame:CreateTexture(nil, "ARTWORK")
    hdrBg:SetPoint("TOPLEFT",  hudFrame, "TOPLEFT",  3, -3)
    hdrBg:SetPoint("TOPRIGHT", hudFrame, "TOPRIGHT", -3, -3)
    hdrBg:SetHeight(20)
    hdrBg:SetColorTexture(0.05, 0.15, 0.38, 0.95)

    local hdrTitle = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrTitle:SetPoint("LEFT", hdrBg, "LEFT", 6, 0)
    hdrTitle:SetText("|cFF00BFFFDelveGuide|r  |cFF555555--|r  |cFF888888IN RUN|r")

    -- Lock button (top-right of header)
    lockBtn = CreateFrame("Button", nil, hudFrame)
    lockBtn:SetSize(14, 14)
    lockBtn:SetPoint("RIGHT", hdrBg, "RIGHT", -4, 0)
    lockBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    local function RefreshLockBtn()
        if DelveGuideDB and DelveGuideDB.hudLocked then
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Locked-Up")
        else
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Unlocked-Up")
        end
    end
    lockBtn:SetScript("OnClick", function()
        if DelveGuideDB then
            DelveGuideDB.hudLocked = not DelveGuideDB.hudLocked
            RefreshLockBtn()
        end
    end)
    lockBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local locked = DelveGuideDB and DelveGuideDB.hudLocked
        GameTooltip:AddLine(locked and "|cFFFF4444Locked|r -- click to unlock" or "|cFF44FF44Unlocked|r -- click to lock")
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    RefreshLockBtn()

    -- Rows: label on left, value on right
    local rows = {}
    local function MakeRow(key, label, yOff)
        local lbl = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 10, yOff)
        lbl:SetText("|cFF666666" .. label .. ":|r")
        lbl:SetWidth(76)
        lbl:SetJustifyH("LEFT")

        local val = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        val:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 88, yOff)
        val:SetWidth(HUD_W - 96)
        val:SetJustifyH("LEFT")
        val:SetText("|cFF888888--|r")
        rows[key] = val
    end

    MakeRow("delve",     "Delve",     -30)
    MakeRow("variant",   "Variant",   -48)
    MakeRow("grade",     "Grade",     -66)
    MakeRow("tier",      "Tier",      -84)
    MakeRow("curio",     "Rec Curio", -102)
    MakeRow("nemesis",   "Nemesis",   -120)
    MakeRow("bountiful", "Bountiful", -138)
    MakeRow("lives",     "Lives",     -156)

    hudFrame.rows = rows
    hudFrame:Hide()
end

-- ── update ───────────────────────────────────────────────────

local function UpdateHUD()
    if not hudFrame then BuildHUD() end

    if not IsInsideDelve() or (DelveGuideDB and not DelveGuideDB.hudEnabled) then
        hudFrame:Hide()
        return
    end

    hudFrame:Show()

    local rows = hudFrame.rows
    local zoneName = ""
    pcall(function() zoneName = GetRealZoneText() or "" end)

    -- Delve name
    rows.delve:SetText("|cFFFFD700" .. zoneName .. "|r")

    -- Variant + grade — cross-ref activeVariants exposed by main addon
    local varText   = "|cFF888888Unknown|r"
    local gradeText = "|cFF888888?|r"
    local activeVars = (DelveGuide and DelveGuide.activeVariants) or {}

    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            if d.name == zoneName and activeVars[d.variant] then
                local gc = (DelveGuideData.gradeColors and DelveGuideData.gradeColors[d.ranking]) or "|cFFFFFFFF"
                varText   = d.variant
                gradeText = gc .. d.ranking .. "|r"
                    .. (d.isBestRoute and "  |cFF00FF88[Best Route]|r" or "")
                    .. (d.hasBug     and "  |cFFFF4444[Bug]|r"        or "")
                break
            end
        end
    end
    rows.variant:SetText(varText)
    rows.grade:SetText(gradeText)

    -- Tier — not exposed by Midnight 12.0 API; set manually with /dg tier N
    if DelveGuide.currentDelveTier then
        rows.tier:SetText("|cFFCCCCCC" .. DelveGuide.currentDelveTier .. "|r")
    else
        rows.tier:SetText("|cFF444444/dg tier [1-11]|r")
    end

    -- Spec curio recommendation
    local curioText = "|cFF888888--|r"
    pcall(function()
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = GetSpecializationInfo(specIndex)
            if specID and DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID] then
                local rec = DelveGuideData.specCurioRecs[specID]
                local parts = {}
                if rec.combat  then table.insert(parts, "|cFF44AAFF"  .. rec.combat  .. "|r") end
                if rec.utility then table.insert(parts, "|cFF44FF88" .. rec.utility .. "|r") end
                if #parts > 0 then curioText = table.concat(parts, "  |cFF555555/|r  ") end
            end
        end
    end)
    rows.curio:SetText(curioText)

    -- Nemesis & Bountiful from activeDelves exposed by main addon
    local activeDelves = (DelveGuide and DelveGuide.activeDelves) or {}
    local info = activeDelves[zoneName]

    rows.nemesis:SetText(
        (info and info.nemesis) and "|cFFFF4444[!] ACTIVE|r" or "|cFF00FF44None|r"
    )
    rows.bountiful:SetText(
        (info and info.bountiful) and "|cFFFFD700Yes|r" or "|cFF888888No|r"
    )

    -- Lives: scan scenario criteria for a deaths/lives entry
    local livesText = "|cFF888888--|r"
    pcall(function()
        local numCrit = C_Scenario.GetNumCriteria()
        for i = 1, (numCrit or 0) do
            local crit = C_Scenario.GetCriteriaInfo(i)
            if crit and crit.quantityString then
                local clean = crit.quantityString:lower()
                if clean:find("li[fv]") or clean:find("death") or clean:find("charge") then
                    livesText = "|cFF00FF88" .. crit.quantityString .. "|r"
                    break
                end
            end
        end
    end)
    rows.lives:SetText(livesText)
end

-- ── event handler ────────────────────────────────────────────

local hudEvents = CreateFrame("Frame")
hudEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
hudEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
hudEvents:RegisterEvent("ZONE_CHANGED")
hudEvents:RegisterEvent("PLAYER_LEAVING_WORLD")
hudEvents:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
hudEvents:RegisterEvent("SCENARIO_COMPLETED")

hudEvents:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LEAVING_WORLD" then
        if hudFrame then hudFrame:Hide() end
        return
    end
    -- Delve completed — hide immediately, no zone check needed
    if event == "SCENARIO_COMPLETED" then
        if hudFrame then hudFrame:Hide() end
        return
    end
    if event == "SCENARIO_CRITERIA_UPDATE" then
        -- Fast path: refresh lives row if HUD is visible
        if hudFrame and hudFrame:IsShown() and hudFrame.rows then
            pcall(function()
                local numCrit = C_Scenario.GetNumCriteria()
                for i = 1, (numCrit or 0) do
                    local crit = C_Scenario.GetCriteriaInfo(i)
                    if crit and crit.quantityString then
                        local clean = crit.quantityString:lower()
                        if clean:find("li[fv]") or clean:find("death") or clean:find("charge") then
                            hudFrame.rows.lives:SetText("|cFF00FF88" .. crit.quantityString .. "|r")
                            break
                        end
                    end
                end
            end)
        end
        return
    end
    -- Zone changes: defer slightly to let zone APIs settle
    C_Timer.After(0.5, function()
        if not hudFrame then BuildHUD() end
        UpdateHUD()
    end)
end)

-- ── public API (for /dg hud toggle and main addon refresh) ───

DelveGuide = DelveGuide or {}
DelveGuide.UpdateHUD = UpdateHUD
DelveGuide.ToggleHUD = function()
    if not hudFrame then BuildHUD() end
    if hudFrame:IsShown() then
        hudFrame:Hide()
    else
        UpdateHUD()  -- only shows if actually in a delve
        if not hudFrame:IsShown() then
            -- Force-show for manual toggle outside a delve (preview mode)
            hudFrame:Show()
        end
    end
end
