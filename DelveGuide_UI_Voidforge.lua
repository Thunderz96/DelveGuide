-- ============================================================
-- DelveGuide_UI_Voidforge.lua  --  Voidforge tracker tab
-- ============================================================
-- Surfaces the data already collected in DelveGuide_Voidforge.lua
-- (cores/shards/quest) plus two new readouts:
--   * lowest-ilvl gear slots (best Voidcore upgrade targets)
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

local function ProgressBar(have, want, color)
    have = math.min(have or 0, want)
    color = color or "|cFFFFD700"
    local filled = math.floor((have / want) * 10 + 0.5)
    local bar = string.rep("=", filled) .. string.rep("-", 10 - filled)
    return string.format("%s[%s]|r %d/%d", color, bar, have, want)
end

DelveGuide.RenderVoidforge = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    y = y + UI.CreateHeader(cf, y, "Voidforge  --  Patch 12.0.5 Upgrade Tracker") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Lingering Shadows added the Voidforge: a weekly gear-upgrade loop fed by Nebulous Voidcores (bonus rolls), Elementary Voidcore Shards (the 'Building the Voidforge' weekly), and Ascendant Voidcores (Hero/Myth/Radiance ilvl bumps).|r") + 8

    -- ---- This Week ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700This Week|r") + 4
    local s = DelveGuide.GetVoidforgeStatus and DelveGuide.GetVoidforgeStatus() or { configured = false }

    if not s.configured then
        y = y + UI.CreateRow(cf, y, "|cFF888888  No Voidforge currencies detected yet. They populate the moment you obtain one in-game (or after a /reload).|r") + 4
    else
        if s.cores then
            local capStr = s.coreMax and ("/" .. s.coreMax) or ""
            y = y + UI.CreateRow(cf, y, string.format("|cFFAA66CC  Nebulous Voidcores:|r |cFFFFFFFF%d%s|r |cFF888888(bonus-roll tokens, +2 weekly cap)|r", s.cores, capStr)) + 2
        end
        if s.shards then
            local pct = math.min(s.shards, s.shardTarget) / s.shardTarget
            local color = pct >= 1 and "|cFF44FF44" or (pct >= 0.66 and "|cFFFFD700" or "|cFFFF8800")
            y = y + UI.CreateRow(cf, y, "|cFFAA66CC  Building the Voidforge:|r " .. ProgressBar(s.shards, s.shardTarget, color)) + 2
        elseif s.questDone ~= nil then
            local tag = s.questDone and "|cFF44FF44Done|r" or "|cFFFF8800Pending|r  |cFF888888(1 raid + 1 M+ + 1 delve)|r"
            y = y + UI.CreateRow(cf, y, "|cFFAA66CC  Building the Voidforge:|r " .. tag) + 2
        end
        if s.ascendant and s.ascendant > 0 then
            y = y + UI.CreateRow(cf, y, string.format("|cFFAA66CC  Ascendant Voidcores:|r |cFFFFFFFF%d|r |cFF888888(Hero / Myth / Radiance ilvl upgrades)|r", s.ascendant)) + 2
        end
    end
    y = y + 6

    -- ---- Where to Earn ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Where to Earn|r") + 4
    local sources = {
        { tag = "|cFFAA66CCNebulous|r",  text = "T8+ Bountiful Delves, M+6 or higher, Nightmare Prey hunts. Soft cap +2 per week." },
        { tag = "|cFFAA66CCShards|r",    text = "Weekly quest 'Building the Voidforge' -- need 1 raid boss kill, 1 M+ run, 1 delve. Reward feeds the Voidforge." },
        { tag = "|cFFAA66CCAscendant|r", text = "Higher-tier content (Mythic raid, M+8+, Tier 11 delves with 1+ life remaining) per current PTR/live notes." },
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

        local totalCores, totalShards, totalAscendant = 0, 0, 0
        for _, k in ipairs(rosterKeys) do
            local v = roster[k].voidforge
            totalCores     = totalCores + (v.cores or 0)
            totalShards    = totalShards + (v.shards or 0)
            totalAscendant = totalAscendant + (v.ascendant or 0)
        end

        y = y + UI.CreateRow(cf, y, string.format("|cFFCCCCCC  Account totals: |cFFAA66CC%d|r cores, |cFFAA66CC%d|r shards, |cFFAA66CC%d|r ascendant",
            totalCores, totalShards, totalAscendant)) + 6

        for _, k in ipairs(rosterKeys) do
            local c = roster[k]
            local v = c.voidforge or {}
            local questTag = ""
            if v.questDone == true then questTag = "  |cFF44FF44[weekly done]|r"
            elseif v.questDone == false then questTag = "  |cFFFF8800[weekly pending]|r" end
            local line = string.format("|cFFCCCCCC  %s|r |cFF666666(%s)|r  --  cores |cFFAA66CC%d|r  shards |cFFAA66CC%d|r  ascendant |cFFAA66CC%d|r%s",
                c.name or "?", c.realm or "?",
                v.cores or 0, v.shards or 0, v.ascendant or 0, questTag)
            y = y + UI.CreateRow(cf, y, line) + 2
        end
    end

    cf:SetHeight(y + 20)
end
