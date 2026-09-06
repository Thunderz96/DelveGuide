-- ============================================================
-- DelveGuide_HUD.lua  --  In-run overlay HUD
-- Auto-shows while inside a known Delve, hides on exit.
-- ============================================================

local HUD_W, HUD_H = 290, 196

-- A persisted run start older than this is a stale record from a run that was
-- never finished (logout, disconnect), not something to resume. Three hours
-- comfortably exceeds any real delve.
local RUN_RESUME_MAX = 3 * 60 * 60

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

-- Looser check used for TIMING only. The completion handler logs any run whose
-- scenario is "Delves", but the run timer used to start only when the zone name
-- matched a catalogued delve -- so a non-English client whose localized name
-- hadn't been learned, a Nemesis delve (deliberately not in DelveGuideData.delves),
-- or any uncatalogued delve would log runs with elapsed = nil. Those runs then
-- never reach /dg submit, so affected players silently contributed no data at all.
-- Timing must therefore use the same broad test the logger uses.
local function IsInDelveScenario()
    local inScenario = false
    pcall(function() inScenario = C_Scenario.IsInScenario() end)
    if not inScenario then return false end
    -- A Labyrinth (12.1.5) is a type-8 scenario named "Delves" in its hub, so
    -- every test below would say yes. It is not a delve run: no timer, no tier,
    -- no history row. Gating here switches all of those off from one place.
    if DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName() then return false end
    if GetCurrentDelveName() then return true end          -- recognised by name
    local sName = ""
    pcall(function() sName = C_Scenario.GetInfo() or "" end)
    -- The localized word for "Delves", learned by the completion handler from a
    -- previously confirmed delve. Without this the fallback below is English-only,
    -- so a non-English client in a Nemesis or uncatalogued delve was never timed.
    if sName ~= "" and DelveGuideDB and DelveGuideDB.localeScenarioName
       and sName == DelveGuideDB.localeScenarioName then
        return true
    end
    return sName == "Delves"                                -- generic delve scenario (EN)
end

local function IsInsideDelve()
    -- Zone name alone is unreliable for seamless delves (e.g. Atal'Aman bleeds into
    -- the Zul'Aman overworld). Require an active scenario as a second condition.
    local inScenario = false
    pcall(function() inScenario = C_Scenario.IsInScenario() end)
    if not inScenario then return false end
    return GetCurrentDelveName() ~= nil
end

-- One reader for the lives row. The same criteria scan used to be duplicated
-- verbatim at both call sites (UpdateHUD and the SCENARIO_CRITERIA_UPDATE fast
-- path). Returns the coloured lives string, or nil when no criterion looks like
-- a lives/deaths counter -- callers decide what to show for nil.
local function ReadLivesText()
    local livesText
    pcall(function()
        local numCrit = DelveGuide.GetCriteriaCount()
        for i = 1, (numCrit or 0) do
            local crit = DelveGuide.GetCriteria(i)
            if crit then
                local desc  = crit.description  and crit.description:lower()  or ""
                local qStr  = crit.quantityString and crit.quantityString:lower() or ""
                local searchText = desc .. " " .. qStr
                -- EN: lives/life, death, charge  |  DE: leben  |  FR: vie  |  IT: vita/vite  |  ES: vida
                -- PT: vida  |  KO: 생명/목숨  |  ZH: 生命/命
                if searchText:find("li[fv]") or searchText:find("death") or searchText:find("charge")
                    or searchText:find("leben") or searchText:find("vie") or searchText:find("vit[ae]")
                    or searchText:find("vida") or searchText:find("생명") or searchText:find("목숨")
                    or searchText:find("生命") or searchText:find("命") then
                    livesText = "|cFF00FF88" .. (crit.quantityString or "?") .. "|r"
                    return
                end
            end
        end
    end)
    return livesText
end

-- ── build ────────────────────────────────────────────────────

local function BuildHUD()
    if hudFrame then return end

    hudFrame = CreateFrame("Frame", "DelveGuideHUDFrame", UIParent, "BackdropTemplate")
    
    -- Load saved size or default
    local startW = (DelveGuideDB and DelveGuideDB.hudW) or HUD_W
    local startH = (DelveGuideDB and DelveGuideDB.hudH) or HUD_H
    hudFrame:SetSize(startW, startH)
    
    hudFrame:SetFrameStrata("MEDIUM")
    hudFrame:SetFrameLevel(50)
    hudFrame:SetClampedToScreen(true)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    
    -- Enable Resizing!
    hudFrame:SetResizable(true)
    hudFrame:SetResizeBounds(250, 178, 600, 320)
    
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

    local db = DelveGuideDB
    if db and db.hudX and db.hudY then
        -- hudY is saved as (frame top - screen height), i.e. a negative offset
        -- DOWN from the screen top -- so it must be restored against TOPLEFT.
        -- Restoring it against BOTTOMLEFT (as this used to) placed the frame
        -- below the screen and let SetClampedToScreen shove it to the bottom,
        -- so the HUD never came back where the user left it.
        hudFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", db.hudX, db.hudY)
    else
        hudFrame:SetPoint("CENTER", UIParent, "CENTER", 450, 100)
    end

    hudFrame:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    hudFrame:SetBackdropColor(0, 0, 0, 0.80)
    hudFrame:SetBackdropBorderColor(0.15, 0.45, 0.85, 0.85)

    local hdrBg = hudFrame:CreateTexture(nil, "ARTWORK")
    hdrBg:SetPoint("TOPLEFT",  hudFrame, "TOPLEFT",  3, -3)
    hdrBg:SetPoint("TOPRIGHT", hudFrame, "TOPRIGHT", -3, -3)
    hdrBg:SetHeight(20)
    hdrBg:SetColorTexture(0.05, 0.15, 0.38, 0.95)

    local hdrTitle = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrTitle:SetPoint("LEFT", hdrBg, "LEFT", 6, 0)
    hdrTitle:SetText("|cFF00BFFFDelveGuide|r  |cFF555555--|r  |cFF888888IN RUN|r")

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
    
    -- Resize Grip Handle
    local resizeGrip = CreateFrame("Button", nil, hudFrame)
    resizeGrip:SetPoint("BOTTOMRIGHT", hudFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetSize(12, 12)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(self, btn)
        if DelveGuideDB and DelveGuideDB.hudLocked then return end
        if btn == "LeftButton" then hudFrame:StartSizing("BOTTOMRIGHT") end
    end)
    resizeGrip:SetScript("OnMouseUp", function(self, btn)
        hudFrame:StopMovingOrSizing()
        if DelveGuideDB then
            DelveGuideDB.hudW = hudFrame:GetWidth()
            DelveGuideDB.hudH = hudFrame:GetHeight()
        end
    end)

    local rows = {}
    local labels = {}
    local function MakeRow(key, label, yOff)
        local _, rSize = DelveGuide.UI.GetScaledSizes()
        local fontFile = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

        local lbl = hudFrame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(fontFile, rSize)
        lbl:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 10, yOff)
        lbl:SetText("|cFF666666" .. label .. ":|r")
        lbl:SetWidth(76)
        lbl:SetJustifyH("LEFT")

        local val = hudFrame:CreateFontString(nil, "OVERLAY")
        val:SetFont(fontFile, rSize)
        val:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 88, yOff)
        val:SetWidth(startW - 96)
        val:SetJustifyH("LEFT")
        val:SetText("|cFF888888--|r")
        rows[key] = val
        lbl.default = label
        labels[key] = lbl
    end

    MakeRow("delve",     "Delve",     -30)
    MakeRow("variant",   "Variant",   -48)
    MakeRow("grade",     "Grade",     -66)
    MakeRow("tier",      "Tier",      -84)
    MakeRow("curio",     "Companion", -102)
    MakeRow("nemesis",   "Nemesis",   -120)
    MakeRow("bountiful", "Bountiful", -138)
    MakeRow("lives",     "Lives",     -156)
    MakeRow("timer",     "Time",      -174)

    hudFrame.rows = rows
    hudFrame.labels = labels

    -- Dynamically stretch row text widths when dragged!
    hudFrame:HookScript("OnSizeChanged", function(self, width, height)
        if self.rows then
            for _, val in pairs(self.rows) do
                val:SetWidth(width - 96)
            end
        end
    end)

    -- Tick the timer display once per second (OnUpdate only fires when frame is shown)
    local timerElapsed = 0
    hudFrame:SetScript("OnUpdate", function(self, dt)
        -- Periodic full refresh. UpdateHUD otherwise only runs on zone-change
        -- events, so a single early read (tracker not yet repopulated when you
        -- zone into a delve) would stick for the whole run -- which is exactly
        -- how the previous delve's tier ended up reported against a new one.
        -- Re-reading lets it self-correct, and lives/bountiful stay fresh too.
        timerElapsed = timerElapsed + dt
        if timerElapsed < 1.0 then return end
        timerElapsed = 0
        local start = DelveGuide.runStartTime or DelveGuide.labyrinthEnteredAt
        if self.rows and self.rows.timer and start then
            local elapsed = GetTime() - start
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            self.rows.timer:SetText(string.format("|cFF00BFFF%dm %02ds|r", mins, secs))
        end
    end)

    hudFrame:Hide()
end

-- Returns: tierNum|nil, methodLabel|nil  (the label powers /dg tierdebug)
local function AutoDetectDelveTier()
    -- Method 1: Instance Difficulty Name (locale-independent — grab any number 1-11)
    local _, _, _, difficultyName = GetInstanceInfo()
    if difficultyName and difficultyName ~= "" then
        local tier = difficultyName:match("(%d+)")
        if tier then
            local n = tonumber(tier)
            if n and n >= 1 and n <= 11 then return n, "1: difficulty name" end
        end
    end

    -- Method 2: Scenario Name & Step Info (locale-independent)
    -- NOTE: `return n` inside the pcall closure returns from the CLOSURE, not
    -- from AutoDetectDelveTier -- so this method never actually reported a
    -- tier. Capture into an upvalue and check it after the pcall instead.
    local scenarioName = ""
    local scenarioTier = nil
    pcall(function()
        if C_Scenario and C_Scenario.GetInfo then
            scenarioName = C_Scenario.GetInfo() or ""
            local tier = scenarioName:match("(%d+)")
            if tier then
                local n = tonumber(tier)
                if n and n >= 1 and n <= 11 then scenarioTier = n; return end
            end

            local stepName = C_Scenario.GetStepInfo()
            if stepName and stepName ~= "" then
                local tier = stepName:match("(%d+)")
                if tier then
                    local n = tonumber(tier)
                    if n and n >= 1 and n <= 11 then scenarioTier = n; return end
                end
            end
        end
    end)
    if scenarioTier then return scenarioTier, "2: scenario/step name" end

    -- Method 3: Objective-tracker scrape.
    -- The Delves tracker block renders as:
    --     Delves                       <- generic header
    --     0/1 <objective text>
    --     <Delve Name>                 <- strong anchor
    --     9                            <- TIER (always right after the name)
    --     5                            <- lives
    --     2
    -- So the tier is the first bare number AFTER the delve-name line. Taking
    -- the first number after the generic "Delves" header instead is what let a
    -- stale/partial tracker report the previous run's tier, so that stays only
    -- as a weak fallback.
    local tracker = _G["ObjectiveTrackerFrame"] or _G["ScenarioObjectiveTracker"]
    if tracker then
        local zoneName = GetRealZoneText() or ""
        -- Only trust the zone name as an anchor when we're actually in a known
        -- delve (otherwise an overworld zone header could arm the match).
        local delveAnchor = GetCurrentDelveName() and zoneName or nil

        local foundDelveHeader, afterDelveName = false, false
        local strongTier, weakTier, explicitTier = nil, nil, nil

        local function SearchForTier(frame)
            if not frame or frame:IsForbidden() then return end

            for _, r in ipairs({frame:GetRegions()}) do
                if r:GetObjectType() == "FontString" and r:IsShown() then
                    local txt = r:GetText()
                    if txt and txt ~= "" then
                        -- Clean all color codes and whitespace
                        local cleanTxt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")

                        -- An explicit "Tier N" always wins outright.
                        local tier = cleanTxt:match("Tier %s*(%d+)") or cleanTxt:match("Tier: %s*(%d+)") or cleanTxt:match("Difficulty: %s*(%d+)")
                        if tier then explicitTier = tonumber(tier); return end

                        if delveAnchor and cleanTxt == delveAnchor then
                            afterDelveName  = true
                            foundDelveHeader = true
                        elseif cleanTxt == "Delves" or (scenarioName ~= "" and cleanTxt == scenarioName) then
                            foundDelveHeader = true
                        elseif cleanTxt:match("^%d+$") then
                            local num = tonumber(cleanTxt)
                            if num and num >= 1 and num <= 11 then
                                if afterDelveName and not strongTier then
                                    strongTier = num
                                    return
                                elseif foundDelveHeader and not weakTier then
                                    weakTier = num
                                end
                            end
                        end
                    end
                end
            end

            for _, child in ipairs({frame:GetChildren()}) do
                SearchForTier(child)
                if explicitTier or strongTier then return end
            end
        end

        SearchForTier(tracker)
        local result = explicitTier or strongTier or weakTier
        if result then
            return result, explicitTier and "3: explicit Tier text"
                        or strongTier and "3: after delve name"
                        or "3: under Delves header (weak)"
        end
    end

    return nil, nil
end

-- Row labels for the two views. The delve view re-applies the defaults on
-- every refresh so a Labyrinth's labels can never linger into a delve.
local LAB_LABELS = {
    delve = "Labyrinth", variant = "Chamber", grade = "Step", tier = "Objective",
    curio = "Cleared", nemesis = "Note", bountiful = "Tier", lives = "Lives", timer = "Time",
}
local function ApplyLabels(overrides)
    if not (hudFrame and hudFrame.labels) then return end
    for key, lbl in pairs(hudFrame.labels) do
        lbl:SetText("|cFF666666" .. ((overrides and overrides[key]) or lbl.default or key) .. ":|r")
    end
end

-- Chambers completed since this run's "enter" entry in the observation log.
local function CountChambersThisRun()
    local n = 0
    local log = DelveGuideDB and DelveGuideDB.labyrinthLog or {}
    for i = #log, 1, -1 do
        local e = log[i]
        if e.kind == "enter" then break end
        if e.kind == "chamber" then n = n + 1 end
    end
    return n
end

-- D6: the HUD inside a Labyrinth. Not a delve run -- no variant, grade or
-- readable tier -- but the same overlay can show what a Labyrinth does have:
-- which chamber, which step, objective progress (criteria come as a count,
-- 5/6, or a percentage, 42%), chambers cleared this run, and time since
-- entry. Reuses the nine delve rows under different labels.
local function UpdateLabyrinthHUD(name)
    hudFrame:Show()
    ApplyLabels(LAB_LABELS)
    local rows = hudFrame.rows
    rows.delve:SetText("|cFFFFD700" .. name .. "|r")

    local scen, step = "", ""
    pcall(function() scen = C_Scenario.GetInfo() or "" end)
    pcall(function() step = C_Scenario.GetStepInfo() or "" end)
    -- Between chambers the hub reports the generic "Delves" scenario.
    if scen == "" or scen == "Delves" then scen = "|cFF888888Choose your path|r" end
    rows.variant:SetText(scen)
    rows.grade:SetText(step ~= "" and step or "|cFF888888--|r")

    local parts = {}
    pcall(function()
        for i = 1, (DelveGuide.GetCriteriaCount() or 0) do
            local c = DelveGuide.GetCriteria(i)
            if c and c.description and #parts < 2 then
                local prog
                if c.quantityString and c.quantityString:find("%%") then
                    prog = c.quantityString
                elseif c.totalQuantity and c.totalQuantity > 0 then
                    prog = tostring(c.quantity or 0) .. "/" .. tostring(c.totalQuantity)
                else
                    prog = c.quantityString or ""
                end
                table.insert(parts, c.description .. " |cFF00BFFF" .. prog .. "|r")
            end
        end
    end)
    rows.tier:SetText(#parts > 0 and table.concat(parts, "  |cFF555555\194\183|r  ") or "|cFF888888--|r")

    rows.curio:SetText("|cFF00FF44" .. CountChambersThisRun() .. "|r |cFF888888this run|r")
    rows.nemesis:SetText("|cFF888888Delve vault credit at Tier 8+ (final boss)|r")
    rows.bountiful:SetText("|cFF888888not readable in Labyrinths|r")
    rows.lives:SetText(ReadLivesText() or "|cFF888888--|r")
    if DelveGuide.labyrinthEnteredAt then
        local elapsed = GetTime() - DelveGuide.labyrinthEnteredAt
        rows.timer:SetText(string.format("|cFF00BFFF%dm %02ds|r", math.floor(elapsed / 60), math.floor(elapsed % 60)))
    else
        rows.timer:SetText("|cFF888888--|r")
    end
end

local function UpdateHUD()
    if not hudFrame then BuildHUD() end

    -- Labyrinth (12.1.5): the delve tests below all say "not a delve" for it
    -- (A2), which is correct for timing and history -- but it deserves a HUD.
    local labName = DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName()
    if labName then
        if DelveGuideDB and not DelveGuideDB.hudEnabled then hudFrame:Hide(); return end
        UpdateLabyrinthHUD(labName)
        return
    end

    if not IsInsideDelve() then
        hudFrame:Hide()
        return
    end

    -- Detect the tier BEFORE the hudEnabled gate. Tier is not just a HUD field:
    -- History records it and /dg submit sends it, and the community aggregator
    -- discards anything below Tier 8 -- so when this ran after the gate, every
    -- player who simply switched the overlay off silently submitted tier-0 runs
    -- that were thrown away. Only accept a POSITIVE detection; a failed read
    -- (tracker mid-refresh, or the block swapping to "Collect Your Reward!" at
    -- the end of a run) must not wipe a tier we already know -- ClearDelveTier()
    -- on exit/completion owns that.
    local autoTier, autoMethod = AutoDetectDelveTier()
    if autoTier then
        DelveGuide.autoDetectMethod = autoMethod
        DelveGuide.SetAutoDelveTier(autoTier)
    end

    if DelveGuideDB and not DelveGuideDB.hudEnabled then
        hudFrame:Hide()
        return
    end

    hudFrame:Show()
    ApplyLabels(nil)

    local rows = hudFrame.rows
    local zoneName = ""
    pcall(function() zoneName = GetRealZoneText() or "" end)

    -- Delve name
    rows.delve:SetText("|cFFFFD700" .. zoneName .. "|r")

    -- Variant + grade — cross-ref activeVariants exposed by main addon
    local varText   = "|cFF888888Unknown|r"
    local gradeText = "|cFF888888?|r"
    local activeVars = (DelveGuide and DelveGuide.activeVariants) or {}

    -- Translate localized zone name → English for non-EN clients
    local engZoneName = zoneName
    local l10n = DelveGuide and DelveGuide.localizedToEnglish
    if l10n and l10n[zoneName] then engZoneName = l10n[zoneName] end

    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            if d.name == engZoneName and activeVars[d.variant] then
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

    -- Tier: refresh auto-detection every pass; a manual /dg tier override wins
    -- while set. Derived fields (read by History/Victory) update in one place.
    -- Only accept a POSITIVE detection. A failed read (tracker mid-refresh, or
    -- the block swapping to "Collect Your Reward!" at the end of a run) must not
    -- wipe a tier we already know -- ClearDelveTier() on exit/completion owns that.
    local tierNum, isManual = DelveGuide.ApplyDelveTier()

    if tierNum then
        rows.tier:SetText(string.format("%s%d|r |cFF888888(%s)|r",
            isManual and "|cFFCCCCCC" or "|cFF00FF44", tierNum,
            isManual and "Manual" or "Auto"))
    else
        rows.tier:SetText("|cFFFF4444Unknown |cFF555555(/dg tier N)|r")
    end

    -- Companion recommendation. The old per-spec combat/utility curio picks
    -- named retired Season 1 curios, so the HUD was contradicting the Curios
    -- and Companion tabs. Show Valeera's recommended role (still valid) until
    -- per-spec Season 2 curio recs exist.
    local curioText = "|cFF888888--|r"
    pcall(function()
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = GetSpecializationInfo(specIndex)
            local rec = specID and DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID]
            if rec and rec.companion then
                curioText = "Valeera: |cFF00CFFF" .. rec.companion .. "|r"
            end
        end
    end)
    rows.curio:SetText(curioText)

    -- Nemesis & Bountiful from activeDelves exposed by main addon
    local activeDelves = (DelveGuide and DelveGuide.activeDelves) or {}
    local info = activeDelves[engZoneName]

    rows.nemesis:SetText(
        (info and info.nemesis) and "|cFFFF4444[!] ACTIVE|r" or "|cFF00FF44None|r"
    )
    rows.bountiful:SetText(
        (info and info.bountiful) and "|cFFFFD700Yes|r" or "|cFF888888No|r"
    )

    -- Lives row: one shared reader (see ReadLivesText).
    rows.lives:SetText(ReadLivesText() or "|cFF888888--|r")

    -- Timer: show elapsed time since entering delve
    if DelveGuide.runStartTime then
        local elapsed = GetTime() - DelveGuide.runStartTime
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        rows.timer:SetText(string.format("|cFF00BFFF%dm %02ds|r", mins, secs))
    else
        rows.timer:SetText("|cFF888888--|r")
    end
end

-- ── shared state evaluation ──────────────────────────────────
-- One authority for "are we in a delve, is the run timed, is the tier known".
-- Called both from zone events (immediate response) and from a watchdog ticker
-- (recovery), so a mistimed single read can never strand the HUD or the timer.
local function EvaluateDelveState()
    if not hudFrame then BuildHUD() end
    -- Time any delve scenario, even one we can't name; only the HUD's *display*
    -- needs a recognised name (UpdateHUD hides itself when it has none).
    local nowInside = IsInDelveScenario()

    if nowInside then
        -- Start the run timer once per run. runCompleted guards against
        -- restarting it while the player lingers inside after finishing.
        --
        -- GetTime() is session uptime and resets on /reload, so a reload
        -- mid-run used to restart the timer from zero and log a fabricated
        -- fast time straight into the community median. The start is now also
        -- persisted as wall clock in DelveGuideDB.activeRun; if a record for
        -- THIS instance is found and is recent, the timer resumes from it
        -- instead of starting fresh. Cleared on completion (main handler) and
        -- on leaving (below), so it cannot bleed into the next run.
        if not DelveGuide.runStartTime and not DelveGuide.runCompleted then
            local instanceID = select(8, GetInstanceInfo())
            local ar = DelveGuideDB and DelveGuideDB.activeRun
            if ar and ar.instanceID == instanceID and ar.startEpoch
               and (time() - ar.startEpoch) >= 0 and (time() - ar.startEpoch) < RUN_RESUME_MAX then
                DelveGuide.runStartTime = GetTime() - (time() - ar.startEpoch)
                DelveGuide.runResumed   = true
            else
                DelveGuide.runStartTime = GetTime()
                DelveGuide.runResumed   = nil
                if DelveGuideDB then
                    DelveGuideDB.activeRun = { startEpoch = time(), instanceID = instanceID }
                end
            end
        end
        UpdateHUD()
    else
        -- Left the delve: release the timer and the tier so neither can leak
        -- into the next run (History and Victory read the derived tier fields).
        if DelveGuide.runStartTime or DelveGuide.runCompleted or DelveGuide.currentDelveTierNum then
            DelveGuide.runStartTime = nil
            DelveGuide.runCompleted = nil
            DelveGuide.runResumed   = nil
            if DelveGuideDB then DelveGuideDB.activeRun = nil end
            if DelveGuide.ClearDelveTier then DelveGuide.ClearDelveTier() end
        end
        -- Inside a Labyrinth nowInside is false by design (A2); still drive the
        -- HUD so the Labyrinth view appears on entry and refreshes each tick.
        if (hudFrame and hudFrame:IsShown()) or (DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName()) then
            UpdateHUD()
        end
    end
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
        -- A Labyrinth chamber completing is not the run ending: keep the view
        -- up and refresh it (chamber count, next step) instead of hiding.
        if DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName() then
            UpdateHUD()
            return
        end
        -- Do NOT clear runStartTime here. This frame and the main addon's frame
        -- BOTH listen for SCENARIO_COMPLETED, and WoW does not guarantee which
        -- one fires first. Clearing it here meant that whenever this frame won
        -- the race, the completion handler found no start time and logged the
        -- run with elapsed = nil -- the timer had run correctly the whole way,
        -- the value was just destroyed a moment before it was read. The main
        -- handler consumes and clears it; the watchdog clears it on exit.
        DelveGuide.runCompleted = true -- stops the watchdog restarting a phantom timer
        if hudFrame then hudFrame:Hide() end
        return
    end
    if event == "SCENARIO_CRITERIA_UPDATE" then
        -- Labyrinth: the objective row IS the criteria; refresh the whole view.
        if DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName() then
            UpdateHUD()
            return
        end
        -- Fast path: refresh lives row if HUD is visible
        if hudFrame and hudFrame:IsShown() and hudFrame.rows then
            local t = ReadLivesText()
            if t then hudFrame.rows.lives:SetText(t) end
        end
        return
    end
    -- Zone changes: defer slightly to let zone APIs settle, then let the shared
    -- state check below do the work (the watchdog repeats it, so a too-early
    -- read here is no longer permanent).
    C_Timer.After(0.5, EvaluateDelveState)
end)

-- Watchdog: re-evaluate delve state every 2s regardless of HUD visibility.
-- Zone events alone were not enough -- entering a delve fires ZONE_CHANGED
-- before C_Scenario registers the scenario, so the single 0.5s check could
-- decide "not in a delve", never start the run timer, and never re-check
-- (SCENARIO_CRITERIA_UPDATE bails early while hidden, and OnUpdate doesn't
-- run on a hidden frame). An untimed run also never reaches the rankings.
C_Timer.NewTicker(2, function() EvaluateDelveState() end)

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
