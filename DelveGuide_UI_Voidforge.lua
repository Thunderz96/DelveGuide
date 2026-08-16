-- ============================================================
-- DelveGuide_UI_Voidforge.lua  --  Voidforge tracker tab
-- ============================================================
-- Surfaces the Season 2 delve reward economy from DelveGuide_Voidforge.lua
-- (Nebulous Voidcore bonus rolls + Ascendant Venomstone upgrades) plus:
--   * lowest-ilvl gear slots (best Venomstone upgrade targets)
--   * cross-character stockpile rolled up from DelveGuideDB.roster.
-- ============================================================
local UI = DelveGuide.UI

-- Color helpers kept local; everything else routes through UI.CreateRow.
local function ColorIlvl(ilvl)
    if not ilvl or ilvl == 0 then return "|cFF888888--|r" end
    if ilvl >= 720 then return "|cFFFF8000" .. ilvl .. "|r" end -- legendary tier
    if ilvl >= 700 then return "|cFFA335EE" .. ilvl .. "|r" end -- epic
    if ilvl >= 680 then return "|cFF0070DD" .. ilvl .. "|r" end -- rare
    return "|cFFFFFFFF" .. ilvl .. "|r"
end

DelveGuide.RenderVoidforge = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    y = y + UI.CreateHeader(cf, y, "Voidforge  --  Bonus Rolls & Gear Upgrades") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Season 2 splits the delve reward economy in two: Nebulous Voidcores are bonus-roll tokens (roll for extra loot after a run), and Ascendant Venomstones -- arriving later this season -- upgrade your gear (10 per piece).|r") + 8

    local s = DelveGuide.GetVoidforgeStatus and DelveGuide.GetVoidforgeStatus() or { configured = false }

    -- ---- Bonus Rolls (Nebulous Voidcore) ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Bonus Rolls  --  Nebulous Voidcore|r") + 4
    if s.cores then
        local capStr = s.coreMax and ("/" .. s.coreMax) or ""
        y = y + UI.CreateRow(cf, y, string.format("|cFFAA66CC  Nebulous Voidcores:|r |cFFFFFFFF%d%s|r |cFF888888(spend one to roll for loot after a raid boss / M+ / Prey / Bountiful Delve)|r", s.cores, capStr)) + 2
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888  None yet -- they drop from T8+ Bountiful Delves, M+, and Nightmare Prey. (Populates in-game or after a /reload.)|r") + 2
    end
    y = y + 6

    -- ---- Gear Upgrades (Ascendant Venomstone) ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Gear Upgrades  --  Ascendant Venomstone|r") + 4
    local perUp = (DelveGuide.Voidforge and DelveGuide.Voidforge.VENOMSTONE_PER_UPGRADE) or 10
    if s.venomstones then
        local ready = math.floor(s.venomstones / perUp)
        y = y + UI.CreateRow(cf, y, string.format("|cFFAA66CC  Ascendant Venomstones:|r |cFFFFFFFF%d|r |cFF888888(%d/%d toward the next upgrade -- %d ready)|r",
            s.venomstones, s.venomstones % perUp, perUp, ready)) + 2
    else
        y = y + UI.CreateRow(cf, y, string.format("|cFF888888  Arriving later this season. %d upgrade one weapon / trinket / neck; a Tier 11 Bountiful Delve is a guaranteed source (~1-2 each). Your count appears here once it goes live.|r", perUp)) + 2
    end
    y = y + 6

    -- ---- Where to Earn ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Where to Earn|r") + 4
    local sources = {
        { tag = "|cFFAA66CCVoidcores|r",   text = "T8+ Bountiful Delves, Mythic+, and Nightmare Prey hunts. Also selectable as a Great Vault consolation." },
        { tag = "|cFFAA66CCVenomstones|r", text = "Tier 11 Bountiful Delves guarantee one (~1-2); also Heroic/Mythic raid and M+10+. Live later this season." },
    }
    for _, src in ipairs(sources) do
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. src.tag .. " |r|cFF888888" .. src.text .. "|r") + 2
    end
    y = y + 8

    -- ---- Slot Upgrade Priority ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Upgrade Priority|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888  Weapons & trinkets first (largest stat-per-ilvl gain), then armor by lowest ilvl. Hover for tooltip, shift-click to chat-link.|r") + 4

    local slotData = DelveGuide.GetVoidforgeSlotPriority and DelveGuide.GetVoidforgeSlotPriority() or {}
    if #slotData == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  (No equipped gear detected -- log in and reopen this tab.)|r") + 4
    else
        local _, rSize, rH = UI.GetScaledSizes()
        local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
        local total, count, lowest = 0, 0, nil
        for _, row in ipairs(slotData) do
            if row.ilvl and row.ilvl > 0 then
                total = total + row.ilvl; count = count + 1
                if not lowest or row.ilvl < lowest then lowest = row.ilvl end
            end
        end
        local avg = count > 0 and math.floor(total / count + 0.5) or 0
        lowest = lowest or 0

        y = y + UI.CreateRow(cf, y, string.format("|cFFCCCCCC  Equipped average: %s  --  Lowest: %s  --  Gap: |cFFFFD700%d|r |cFF888888ilvls|r",
            ColorIlvl(avg), ColorIlvl(lowest), avg > 0 and (avg - lowest) or 0)) + 6

        local tier2Rank = 0
        for _, row in ipairs(slotData) do
            local btn = CreateFrame("Button", nil, cf)
            btn:SetPoint("TOPLEFT", cf, "TOPLEFT", 16, -y)
            btn:SetSize(UI.WINDOW_W - 80, rH)
            local fs = btn:CreateFontString(nil, "OVERLAY")
            fs:SetFont(ROW_FONT_FILE, rSize); fs:SetAllPoints(btn); fs:SetJustifyH("LEFT")

            local prefix
            if row.empty then
                prefix = "|cFFFF4444[empty]   |r "
            elseif row.tier == 1 then
                prefix = "|cFFFF8000[priority]|r "
            else
                tier2Rank = tier2Rank + 1
                if tier2Rank <= 4 then
                    prefix = "|cFFFFD700[low]     |r "
                else
                    prefix = "          "
                end
            end

            local linkText = row.link or "|cFF888888(empty slot)|r"
            fs:SetText(string.format("%s|cFFAAAAAA%-10s|r  %s  %s",
                prefix, row.label, ColorIlvl(row.ilvl), linkText))

            if row.link then
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(row.link)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                btn:SetScript("OnClick", function()
                    if IsModifiedClick("CHATLINK") then
                        ChatEdit_InsertLink(row.link)
                    end
                end)
            end
            y = y + rH + 2
        end
    end
    y = y + 8

    -- ---- Cross-Character Stockpile ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Alt Stockpile  --  All Cached Characters|r") + 4

    local roster = DelveGuideDB.roster or {}
    local rosterKeys = {}
    for k, c in pairs(roster) do
        if c.voidforge then table.insert(rosterKeys, k) end
    end

    if #rosterKeys == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  Log in on each alt to populate this list. Voidforge state is captured at PLAYER_ENTERING_WORLD.|r") + 4
    else
        table.sort(rosterKeys, function(a, b)
            local va, vb = roster[a].voidforge or {}, roster[b].voidforge or {}
            return (va.cores or 0) > (vb.cores or 0)
        end)

        local totalCores, totalStones = 0, 0
        for _, k in ipairs(rosterKeys) do
            local v = roster[k].voidforge
            totalCores  = totalCores + (v.cores or 0)
            totalStones = totalStones + (v.venomstones or 0)
        end

        y = y + UI.CreateRow(cf, y, string.format("|cFFCCCCCC  Account totals: |cFFAA66CC%d|r Voidcores, |cFFAA66CC%d|r Venomstones",
            totalCores, totalStones)) + 6

        for _, k in ipairs(rosterKeys) do
            local c = roster[k]
            local v = c.voidforge or {}
            local line = string.format("|cFFCCCCCC  %s|r |cFF666666(%s)|r  --  Voidcores |cFFAA66CC%d|r  Venomstones |cFFAA66CC%d|r",
                c.name or "?", c.realm or "?",
                v.cores or 0, v.venomstones or 0)
            y = y + UI.CreateRow(cf, y, line) + 2
        end
    end

    cf:SetHeight(y + 20)
end
