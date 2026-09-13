-- ============================================================
-- DelveGuide_UI_Voidforge.lua  --  Voidforge tracker tab
-- ============================================================
-- Surfaces the Season 2 delve reward economy from DelveGuide_Voidforge.lua
-- (Nebulous Voidcore bonus rolls + Ascendant Venomstone upgrades) plus:
--   * the five Venomstone-upgradeable slots (weapons + trinkets + neck) by ilvl
--   * cross-character stockpile rolled up from DelveGuideDB.roster.
-- ============================================================
local UI = DelveGuide.UI
local L = DelveGuide.L

-- Color helpers kept local; everything else routes through UI.CreateRow.
-- Bands are read from DelveGuideData.tierRewards so they rescale with the
-- season instead of going stale. They were hardcoded at 680/700/720 -- The War
-- Within numbers -- while Midnight Season 2 runs 266-305, so every item level
-- on this tab fell through to the white fallback and the colouring was dead.
local function ColorIlvl(ilvl)
    if not ilvl or ilvl == 0 then return "|cFF888888--|r" end
    local t    = (DelveGuideData and DelveGuideData.tierRewards) or {}
    local top  = (t[11] and t[11].vault) or 305   -- best the season pays out
    local epic = (t[8]  and t[8].vault)  or 302   -- Hero track, Tier 8+
    local rare = (t[4]  and t[4].vault)  or 289
    if ilvl >= top  then return "|cFFFF8000" .. ilvl .. "|r" end
    if ilvl >= epic then return "|cFFA335EE" .. ilvl .. "|r" end
    if ilvl >= rare then return "|cFF0070DD" .. ilvl .. "|r" end
    return "|cFFFFFFFF" .. ilvl .. "|r"
end

DelveGuide.RenderVoidforge = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    y = y + UI.CreateHeader(cf, y, L["Voidforge  --  Bonus Rolls & Gear Upgrades"]) + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Season 2 splits the delve reward economy in two: Nebulous Voidcores are bonus-roll tokens (roll for additional loot after a boss or a run), and Ascendant Venomstones -- arriving later this season -- upgrade weapons, trinkets and necks (10 per piece)."] .. "|r") + 8

    local s = DelveGuide.GetVoidforgeStatus and DelveGuide.GetVoidforgeStatus() or { configured = false }

    -- ---- Bonus Rolls (Nebulous Voidcore) ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Bonus Rolls  --  Nebulous Voidcore"] .. "|r") + 4
    if s.cores then
        local capStr = s.coreMax and ("/" .. s.coreMax) or ""
        y = y + UI.CreateRow(cf, y, "|cFFAA66CC  " .. L["Nebulous Voidcores:"] .. "|r |cFFFFFFFF" .. s.cores .. capStr
            .. "|r |cFF888888" .. L["(bonus roll after a raid boss / M+ / Bountiful Delve / Nightmare Prey)"] .. "|r") + 2
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["None yet -- for now the Great Vault is the only source. (Populates in-game or after a /reload.)"] .. "|r") + 2
    end
    y = y + 6

    -- ---- Gear Upgrades (Ascendant Venomstone) ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Gear Upgrades  --  Ascendant Venomstone"] .. "|r") + 4
    local perUp = (DelveGuide.Voidforge and DelveGuide.Voidforge.VENOMSTONE_PER_UPGRADE) or 10
    if s.venomstones then
        local ready = math.floor(s.venomstones / perUp)
        y = y + UI.CreateRow(cf, y, "|cFFAA66CC  " .. L["Ascendant Venomstones:"] .. "|r |cFFFFFFFF" .. s.venomstones .. "|r |cFF888888"
            .. string.format(L["(%d/%d toward the next upgrade -- %d ready)"], s.venomstones % perUp, perUp, ready) .. "|r") + 2
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. string.format(L["Arriving later this season. %d upgrade one weapon / trinket / neck; a Tier 11 Bountiful Delve is a guaranteed source (~1-2 each). Your count appears here once it goes live."], perUp) .. "|r") + 2
    end
    y = y + 6

    -- ---- Where to Earn ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Where to Earn"] .. "|r") + 4
    local sources = {
        { tag = "|cFFAA66CCVoidcores|r",   text = (DelveGuideData.currencyNotes and DelveGuideData.currencyNotes.voidcore or "") },
        { tag = "|cFFAA66CCVenomstones|r", text = (DelveGuideData.currencyNotes and DelveGuideData.currencyNotes.venomstone or "") },
    }
    for _, src in ipairs(sources) do
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. src.tag .. " |r|cFF888888" .. src.text .. "|r") + 2
    end
    y = y + 8

    -- ---- Slot Upgrade Priority ----
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Upgrade Priority"] .. "|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Venomstones upgrade weapons, trinkets and necks only, so these are the five slots that matter, lowest ilvl first. Hover for tooltip, shift-click to chat-link."] .. "|r") + 4

    local slotData = DelveGuide.GetVoidforgeSlotPriority and DelveGuide.GetVoidforgeSlotPriority() or {}
    if #slotData == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["(No equipped gear detected -- log in and reopen this tab.)"] .. "|r") + 4
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
        -- Use Blizzard's own equipped average rather than averaging the slots we
        -- can see. They are not the same calculation: for a two-hander Blizzard
        -- counts the weapon TWICE (once into the empty off-hand) and divides by
        -- 16, while averaging filled slots divides by 15. On a Marksmanship
        -- Hunter with a 321 bow that read 300 here against 301.69 on the
        -- character sheet, which looks like a bug rather than a different metric.
        local avg = 0
        pcall(function()
            local _, equipped = GetAverageItemLevel()
            if type(equipped) == "number" and equipped > 0 then
                avg = math.floor(equipped + 0.5)
            end
        end)
        if avg == 0 then  -- fall back to our own slot average
            avg = count > 0 and math.floor(total / count + 0.5) or 0
        end
        lowest = lowest or 0

        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Equipped average:"] .. " " .. ColorIlvl(avg)
            .. "  --  " .. L["Lowest:"] .. " " .. ColorIlvl(lowest)
            .. "  --  " .. L["Gap:"] .. " |cFFFFD700" .. (avg > 0 and (avg - lowest) or 0) .. "|r |cFF888888" .. L["ilvls"] .. "|r") + 6

        for _, row in ipairs(slotData) do
            local btn = UI.AcquireButton()
            btn:SetPoint("TOPLEFT", cf, "TOPLEFT", 16, -y)
            btn:SetSize(UI.WINDOW_W - 80, rH)
            local fs = UI.AcquireFontString("OVERLAY")
            fs:SetFont(ROW_FONT_FILE, rSize); fs:SetAllPoints(btn); fs:SetJustifyH("LEFT")

            local prefix
            if row.empty then
                prefix = "|cFFFF4444" .. L["[empty]"] .. "   |r "
            else
                -- Every listed slot is upgradeable now; the old [priority]/[low]
                -- split against armour rows has nothing left to contrast with.
                prefix = "          "
            end

            local linkText = row.link or ("|cFF888888" .. L["(empty slot)"] .. "|r")
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
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Alt Stockpile  --  All Cached Characters"] .. "|r") + 4

    local roster = DelveGuideDB.roster or {}
    local rosterKeys = {}
    for k, c in pairs(roster) do
        if c.voidforge then table.insert(rosterKeys, k) end
    end

    if #rosterKeys == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Log in on each alt to populate this list. Voidforge state is captured at PLAYER_ENTERING_WORLD."] .. "|r") + 4
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

        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. L["Account totals:"] .. string.format(" |cFFAA66CC%d|r Voidcores, |cFFAA66CC%d|r Venomstones",
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
