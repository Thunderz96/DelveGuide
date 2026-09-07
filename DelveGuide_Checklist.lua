-- ============================================================
-- DelveGuide_Checklist.lua
-- ============================================================
local checklistFrame

local function RunChecklistScan()
    local results = {}

    -- Scalebound Herald's Flute. Tooltip: "Play the Scalebound Herald's Flute,
    -- luring the Nemesis to its location. Only usable after activating an
    -- Abandoned Restoration Stone inside of a Delve. (1 Hour Cooldown)"
    --
    -- So it is used in ANY delve to summon the Nemesis to you -- NOT an access item
    -- for Venomfall Deeps. An earlier cut of this gated the row on targeting a
    -- Nemesis delve, which was exactly backwards and would have hidden it in every
    -- place it is actually used.
    --
    -- Using it guarantees a Trovehunter's Bounty map if you have not looted one
    -- this week, so the reminder leans on the trove state the addon already
    -- tracks: holding a flute with the bounty still unclaimed is the case worth
    -- interrupting someone for.
    do
        local NI = (DelveGuideData and DelveGuideData.nemesisItem) or {}
        local flutes = (NI.ITEM_ID and C_Item.GetItemCount(NI.ITEM_ID, true)) or 0
        if flutes > 0 then
            local label = NI.NAME or "Nemesis flute"
            local troveState = DelveGuide.GetTroveStatus and DelveGuide.GetTroveStatus() or "none"
            local bountyPending = (troveState ~= "weeklyDone")
            table.insert(results, {
                label = string.format("%s  |cFF00FF44(%d in bags)|r", label, flutes),
                ok    = true,
                tip   = bountyPending
                    and "Use it at the Abandoned Restoration Stone to summon the Nemesis. Guarantees this week's Trovehunter's Bounty map, which you have not claimed yet. 1 hour cooldown."
                    or  "Use it at the Abandoned Restoration Stone to summon the Nemesis. You already have this week's Bounty, so no map from this one. 1 hour cooldown.",
            })
        end
    end

    local keyInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards = keyInfo and keyInfo.quantity or 0
    local restoredKeyInfo = C_CurrencyInfo.GetCurrencyInfo(3028)
    local restoredKeys = restoredKeyInfo and restoredKeyInfo.quantity or 0
    local hasKey = shards >= 100 or restoredKeys > 0
    local keyLabel
    if restoredKeys > 0 then
        keyLabel = string.format("Coffer Key  |cFF00FF44(%d restored key%s + %d/600 shards)|r",
            restoredKeys, restoredKeys > 1 and "s" or "", shards)
    else
        keyLabel = string.format("Coffer Key  |cFF888888(%d/600 shards)|r", shards)
    end
    table.insert(results, {
        label = keyLabel,
        ok    = hasKey,
        tip   = not hasKey and "You need 100 shards (1 key) or a Restored Coffer Key to open a Bountiful Coffer." or nil,
    })

    -- Trovehunter's Bounty -- shared state helper (IDs in DelveGuideData.trove)
    -- so this row always matches the Delves tab.
    local troveState, troveCount = "none", 0
    if DelveGuide.GetTroveStatus then troveState, troveCount = DelveGuide.GetTroveStatus() end

    if troveState == "active" then
        table.insert(results, { label="Trovehunter's Bounty  |cFF00FF44(Active)|r", ok=true })
    elseif troveState == "inBags" then
        table.insert(results, {
            label = string.format("Trovehunter's Bounty  |cFFFFD700(%d in bags - not active)|r", troveCount),
            ok    = false,
            tip   = "Right-click the item to activate it before entering.",
        })
    elseif troveState == "weeklyDone" then
        table.insert(results, {
            label = "Trovehunter's Bounty  |cFF44FF44(Used this week)|r",
            ok    = true,
            tip   = "You've already claimed and spent this week's bounty. It resets with the weekly.",
        })
    else
        table.insert(results, {
            label = "Trovehunter's Bounty  |cFFFF4444(None)|r",
            ok    = false,
            tip   = "Complete the weekly 'Purging the Vaults' on the Coiled Isle to earn one, or use a flute to summon the Nemesis and loot one from it.",
        })
    end

    local valeeraOk, valeeraLabel = false, "|cFFFF4444Not detected|r"
    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            local companionID = C_DelvesUI.GetCompanionInfoForActivePlayer()
            if companionID and companionID > 0 then
                local roleNames = { [0]="DPS", [1]="Healer", [2]="Tank" }
                local role = DelvesCompanionConfigurationFrame
                    and DelvesCompanionConfigurationFrame.selectedRole
                local roleStr = role and roleNames[role] or "check role"
                valeeraOk    = true
                valeeraLabel = "|cFF00FF44Present|r  |cFF888888(" .. roleStr .. ")|r"
            end
        end
    end)
    table.insert(results, {
        label = "Valeera  " .. valeeraLabel,
        ok    = valeeraOk,
        tip   = not valeeraOk and "Open the companion panel to configure Valeera." or nil,
    })

    -- Delve glove enhancement (12.1.5). Says something only when it can be
    -- definite: the gloves are above the 334 cap and cannot take one, or --
    -- once DelveGuideData.delveGloveEnhancements has IDs -- one is present or
    -- absent. With the table empty and the gloves under the cap it stays quiet
    -- rather than guess. The enchant ID is field 2 of the item link.
    pcall(function()
        local link = GetInventoryItemLink("player", INVSLOT_HAND or 10)
        if not link then return end
        local enchantID = tonumber(link:match("item:%d+:(%d+):")) or 0
        local ilvl = 0
        if C_Item and C_Item.GetDetailedItemLevelInfo then
            local ok, eff = pcall(C_Item.GetDetailedItemLevelInfo, link)
            if ok and type(eff) == "number" then ilvl = eff end
        end
        local known = (DelveGuideData and DelveGuideData.delveGloveEnhancements) or {}
        local cap = (DelveGuideData and DelveGuideData.DELVE_GLOVE_ENHANCEMENT_MAX_ILVL) or 334
        local hasKnown = next(known) ~= nil
        local name = known[enchantID]
        if name then
            table.insert(results, {
                label = "Delve glove enhancement  |cFF00FF44(" .. name .. ")|r",
                ok    = true,
            })
        elseif ilvl > cap then
            table.insert(results, {
                label = string.format("Delve glove enhancement  |cFFFF4444(gloves are ilvl %d)|r", ilvl),
                ok    = false,
                tip   = string.format("The 12.1.5 glove enhancements only apply to gloves of item level %d or below. Yours cannot take one.", cap),
            })
        elseif hasKnown then
            table.insert(results, {
                label = "Delve glove enhancement  |cFFFF4444(None)|r",
                ok    = false,
                tip   = "A permanent bonus inside delve content. Apply one to your gloves before entering.",
            })
        end
    end)

    -- (The Season 1 "Building the Voidforge" weekly row was retired in 12.1 --
    -- Season 2 has no weekly shard quest; bonus rolls / upgrades live in the
    -- Voidforge tab instead.)

    return results
end

DelveGuide.ShowChecklist = function(force)
    if not force then
        if not DelveGuideDB.checklistEnabled then return end
        if DelveGuideDB.checklistDismissed then return end
    end

    if not checklistFrame then
        local f = CreateFrame("Frame", "DelveGuideChecklist", UIParent, "BackdropTemplate")
        f:SetSize(340, 160)
        f:SetFrameStrata("DIALOG")
        -- ESC closes it like every other window (review 1.15). Needs the
        -- frame's GLOBAL name, which is why it has one.
        tinsert(UISpecialFrames, "DelveGuideChecklist")

        -- Draggable. A dragged position is remembered and then wins over the
        -- default anchor (the positioning block further down, run on each show).
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        local function StopDrag()
            f:StopMovingOrSizing()
            DelveGuideDB.checklistX = f:GetLeft()
            DelveGuideDB.checklistY = f:GetTop() - UIParent:GetHeight()
        end
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", StopDrag)
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

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        -- X only closes. It used to set checklistDismissed too, which made it a
        -- silent session-long suppress: walk away and back and nothing showed.
        -- The "Don't show again this session" box is the suppress.
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Rows are Buttons, not bare FontStrings, so a row's tip can live in a
        -- GameTooltip on hover (review 1.7). Inline, a long tip wrapped: the
        -- flute row's is ~160 chars, and a FontString pinned only at its top
        -- has no height cap, so it grew three or four lines downward over the
        -- rows below it and into the dismiss checkbox. Same shape as the
        -- widget's varLines rows.
        f.rows = {}
        for i = 1, 6 do
            local row = CreateFrame("Button", nil, f)
            row:SetSize(316, 22)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(24 + (i-1)*22))
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")

            local fs = row:CreateFontString(nil, "OVERLAY")
            fs:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 11)
            fs:SetAllPoints()
            fs:SetJustifyH("LEFT")
            -- One line, always: WoW ellipsises the overflow instead of wrapping.
            fs:SetWordWrap(false)
            row.label = fs

            -- The rows cover nearly the whole window, so forward their drags
            -- or it stops being movable anywhere but its edges.
            row:RegisterForDrag("LeftButton")
            row:SetScript("OnDragStart", function() f:StartMoving() end)
            row:SetScript("OnDragStop", StopDrag)

            row:SetScript("OnEnter", function(self)
                if not self.tip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tipTitle or "")
                GameTooltip:AddLine(self.tip, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            f.rows[i] = row
        end

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

    -- Where to put it, each time it shows. A position the user dragged to
    -- wins. Otherwise sit just above the delve entrance dialog, which is the
    -- thing the checklist is about and what it used to cover when it opened
    -- dead-centre. With no dialog on screen (/dg check), centre it.
    checklistFrame:ClearAllPoints()
    if DelveGuideDB.checklistX and DelveGuideDB.checklistY then
        checklistFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DelveGuideDB.checklistX, DelveGuideDB.checklistY)
    elseif DelvesDifficultyPickerFrame and DelvesDifficultyPickerFrame:IsShown() then
        checklistFrame:SetPoint("BOTTOM", DelvesDifficultyPickerFrame, "TOP", 0, 8)
    else
        checklistFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end

    local results = RunChecklistScan()
    local frameH = 44 + #results * 22
    checklistFrame:SetHeight(frameH)

    for i, row in ipairs(checklistFrame.rows) do
        local r = results[i]
        if r then
            local icon
            if r.ok == true then
                icon = "|cFF00FF44(OK)|r "
            elseif r.ok == false then
                icon = "|cFFFF4444X|r "
            else
                icon = "|cFFFF8844?|r " 
            end
            local text = icon .. r.label
            -- "(?)" so the hover is discoverable; the tip is the tooltip now.
            if r.tip then text = text .. "  |cFF888888(?)|r" end
            row.label:SetText(text)
            row.tip = r.tip
            row.tipTitle = r.label
            row:Show()
        else
            row.tip = nil
            row:Hide()
        end
    end

    checklistFrame:Show()
end

-- Called when the entrance dialog closes (walked away, entered, cancelled).
-- Frames cannot be destroyed in WoW; hidden is what the player sees.
DelveGuide.HideChecklist = function()
    if checklistFrame and checklistFrame:IsShown() then checklistFrame:Hide() end
end

-- Every name that means "delve entrance", hashed once at load: catalogued
-- delves, Nemesis delves and Labyrinths. OnTargetChanged used to walk all three
-- lists on every PLAYER_TARGET_CHANGED -- ~50 string comparisons per target
-- swap, and in a raid that fires constantly. All three source tables are
-- static: DelveGuideData.delves and friends are built once in the data file and
-- never appended to, so a load-time hash can never go stale.
--
-- Building this is safe even though the lookup key may be secret. The VALUES
-- here come from the addon's own data file and are ordinary strings; the only
-- secret value involved is the key we index WITH, and that stays inside the
-- pcall below exactly as before.
local delveNameSet = {}
do
    for _, d in ipairs((DelveGuideData and DelveGuideData.delves) or {}) do
        if d.name then delveNameSet[d.name] = true end
    end
    -- Nemesis delves are deliberately absent from DelveGuideData.delves.
    for _, n in ipairs((DelveGuideData and DelveGuideData.nemesisDelves) or {}) do
        delveNameSet[n] = true
    end
    -- Labyrinths (12.1.5). Assumes the entrance object carries the
    -- Labyrinth's name like delve entrances do -- unverified on the PTR.
    for _, L in ipairs((DelveGuideData and DelveGuideData.labyrinths) or {}) do
        if L.name then delveNameSet[L.name] = true end
    end
end

-- NOTE: as of the PLAYER_INTERACTION_MANAGER_FRAME_SHOW (type 79) trigger this
-- is no longer how the pre-entry checklist normally fires -- delve entrances
-- are game objects, not units, so they were never targetable and this path
-- almost certainly never matched. It is kept as a second trigger rather than
-- deleted, and cheapened so that being effectively dead costs nothing. If the
-- interaction trigger proves reliable in the field, this and its
-- PLAYER_TARGET_CHANGED registration can go.
DelveGuide.OnTargetChanged = function()
    if not DelveGuideDB.checklistEnabled then return end
    if DelveGuideDB.checklistDismissed then return end

    -- Cheapest possible rejection of the common case. A protected unit name is
    -- never a delve, and in a raid nearly every target change produces one, so
    -- test for it before paying for the pcall. issecretvalue does not exist on
    -- every client build; when it is missing this is simply skipped and the
    -- pcall below remains the only line of defence, as it was before.
    -- UnitName() itself never raises -- only comparing or indexing with what it
    -- returns does -- so fetching the name out here is safe.
    local targetName = UnitName("target")
    if issecretvalue and issecretvalue(targetName) then return end

    -- EVERYTHING that touches the target name stays inside one pcall. In
    -- Midnight, UnitName("target") can return a SECRET STRING (protected unit
    -- names -- other players in raids, mostly), and tainted code cannot compare
    -- or table-index one without raising. The 1.10.1 rewrite fetched the name
    -- inside a pcall but compared it OUTSIDE, so every target change in a raid
    -- threw "attempt to compare local 'targetName' (a secret string value)" --
    -- 215 times in one report (GitHub #8). The original code had every
    -- comparison inside the bubble, and InjectDelveData's comment spells out
    -- the rule; this restores it. A secret string aborts the pcall on first
    -- comparison and matched stays false, which is correct: a protected unit
    -- name is never a delve.
    local matched = false
    pcall(function()
        if not targetName or targetName == "" then return end

        -- Localized -> English first, so the checklist fires on non-EN clients.
        -- This mapping is what makes delveNameSet's English-only keys enough:
        -- localizedToEnglish is populated at runtime by the POI scan, so its
        -- keys cannot be baked into a load-time set, but one index through it
        -- converts a localized name to a key the set does have.
        local engName = (DelveGuide.localizedToEnglish
                         and DelveGuide.localizedToEnglish[targetName]) or targetName

        if delveNameSet[engName] then matched = true end
    end)

    if matched and DelveGuide.ShowChecklist then
        DelveGuide.ShowChecklist(false)
    end
end
