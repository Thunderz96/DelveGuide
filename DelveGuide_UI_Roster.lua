-- ============================================================
-- DelveGuide_UI_Roster.lua
-- ============================================================
local UI = DelveGuide.UI

DelveGuide.RenderRoster = function()
    local cf = UI.NewContentFrame()
    local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, "Roster  --  All Characters  |cFF888888(updates on login)|r") + 4

    local currentName  = UnitName("player") or "?"
    local currentRealm = GetRealmName()     or "?"
    local currentKey   = currentName .. "-" .. currentRealm

    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    local currentResetKey = secsUntilReset and (math.floor((time() + secsUntilReset - 604800) / 3600) * 3600) or nil
    local roster = DelveGuideDB.roster or {}

    local COL = { name=8, spec=160, ilvl=278, shards=322, bounty=385, delves=438, vault=480, seen=530, del=626 }

    local function MakeHeaderCol(x, w, text)
        local fs = cf:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ROW_FONT_FILE, rSize); fs:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y)
        fs:SetWidth(w); fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.67, 0.67, 0.67, 1); fs:SetText(text)
    end
    MakeHeaderCol(COL.name, 148, "Character"); MakeHeaderCol(COL.spec, 114, "Spec")
    MakeHeaderCol(COL.ilvl, 60, "iLvl"); MakeHeaderCol(COL.shards, 60, "Shards")
    MakeHeaderCol(COL.bounty, 50, "Bounty"); MakeHeaderCol(COL.delves, 40, "Delves")
    MakeHeaderCol(COL.vault, 45, "Vault"); MakeHeaderCol(COL.seen, 100, "Last Seen")
    y = y + rH

    local sep = cf:CreateTexture(nil, "OVERLAY")
    sep:SetPoint("TOPLEFT", cf, "TOPLEFT", 4, -y)
    sep:SetSize(UI.WINDOW_W - 60, 1); sep:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    y = y + 6

    local keys = {}
    for k in pairs(roster) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
        if a == currentKey then return true end
        if b == currentKey then return false end
        return a < b
    end)

    if #keys == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888No characters cached yet - log in on each alt to populate their row.|r")
    else
        for _, k in ipairs(keys) do
            local c = roster[k]
            local isCurrent = (k == currentKey)
            local isStale = currentResetKey and c.resetKey and (c.resetKey ~= currentResetKey)
            local alpha = isStale and 0.45 or 1.0

            if isCurrent then
                local fill = cf:CreateTexture(nil, "BACKGROUND")
                fill:SetPoint("TOPLEFT", cf, "TOPLEFT", 2, -(y - 1))
                fill:SetSize(UI.WINDOW_W - 56, rH + 2)
                fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                fill:SetGradient("HORIZONTAL", CreateColor(0, 0.4, 1, 0.18), CreateColor(0, 0.4, 1, 0))
                local bar = cf:CreateTexture(nil, "ARTWORK")
                bar:SetPoint("TOPLEFT", cf, "TOPLEFT", 2, -(y - 1))
                bar:SetSize(3, rH + 2); bar:SetColorTexture(0, 0.6, 1, 1)
            end

            local function MakeCol(x, w, text, justify, tooltipData)
                local btn = CreateFrame("Button", nil, cf)
                btn:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y); btn:SetSize(w, rH)
                local fs = btn:CreateFontString(nil, "OVERLAY")
                fs:SetFont(ROW_FONT_FILE, rSize); fs:SetAllPoints(btn)
                fs:SetJustifyH(justify or "LEFT"); fs:SetAlpha(alpha); fs:SetText(text)
                
                if tooltipData then
                    btn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(tooltipData.title)
                        for _, line in ipairs(tooltipData.lines) do GameTooltip:AddLine(line) end
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
                return btn, fs
            end

            local nameText = isCurrent and ("|cFF00CFFF" .. c.name .. "|r  |cFF888888" .. c.realm .. "|r") or (c.name .. "  |cFF666666" .. c.realm .. "|r")
            MakeCol(COL.name, 148, nameText)

            -- Spec Icon!
            local specBtn, specFs = MakeCol(COL.spec, 114, c.specName or "?")
            if c.specIcon then
                local icon = specBtn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(rH-2, rH-2); icon:SetPoint("LEFT", specBtn, "LEFT", 0, 0)
                icon:SetTexture(c.specIcon); icon:SetAlpha(alpha)
                
                -- Clear the original MakeCol anchors before setting the new ones!
                specFs:ClearAllPoints()
                specFs:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                specFs:SetPoint("RIGHT", specBtn, "RIGHT", 0, 0)
            end

            local rk = c.restoredKeys or 0
            local shardsText = ((c.shards or 0) >= 100 or rk > 0) and ("|cFF00FF44" .. (c.shards or 0) .. "|r") or tostring(c.shards or 0)
            if rk > 0 then shardsText = shardsText .. " |cFFFFD700(+" .. rk .. "r)|r" end

            MakeCol(COL.ilvl, 38, c.ilvl and c.ilvl > 0 and tostring(c.ilvl) or "|cFF888888?|r", "RIGHT")
            MakeCol(COL.shards, 60, shardsText)
            MakeCol(COL.bounty, 45, (c.bounty or 0) > 0 and ("|cFF00FF44" .. (c.bounty or 0) .. "|r") or "|cFF666666--|r")

            -- Delve Tooltip Data!
            local delveLines = {}
            if c.weeklyRuns and #c.weeklyRuns > 0 then
                for _, run in ipairs(c.weeklyRuns) do
                    table.insert(delveLines, "|cFFCCCCCC" .. run.name .. "|r  |cFF888888[" .. (run.tier or "?") .. "]|r")
                end
            else
                table.insert(delveLines, "|cFF888888No delves recorded this week.|r")
            end
            MakeCol(COL.delves, 38, tostring(c.delveCount or 0), "RIGHT", {title="|cFFFFD700Completed Delves (This Week)|r", lines=delveLines})

            -- Vault Tooltip Data!
            local vaultText = (c.vaultSlots or 0) > 0 and ("|cFF00FF44" .. (c.vaultSlots or 0) .. "|r") or "|cFF888888-|r"
            local vaultLines = {}
            if c.maxVaultIlvl and c.maxVaultIlvl > 0 then
                table.insert(vaultLines, "Highest Unlock: |cFFFFD700" .. c.maxVaultIlvl .. " ilvl|r")
            else
                table.insert(vaultLines, "|cFF888888Complete more high-tier delves to increase item level.|r")
            end
            MakeCol(COL.vault, 38, vaultText, "RIGHT", {title="|cFF00BFFFGreat Vault Status|r", lines=vaultLines})

            MakeCol(COL.seen, 100, "|cFF888888" .. (c.lastSeen or "?") .. "|r" .. (isStale and " |cFF888888[prev]|r" or ""))

            if not isCurrent then
                local capK, capName = k, c.name
                local delBtn = CreateFrame("Button", nil, cf)
                delBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", COL.del, -y); delBtn:SetSize(18, rH)
                local delLabel = delBtn:CreateFontString(nil, "OVERLAY")
                delLabel:SetFont(ROW_FONT_FILE, rSize); delLabel:SetPoint("CENTER"); delLabel:SetText("|cFFFF4444x|r")
                delBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Remove " .. capName .. " from roster", 1, 1, 1, 1, true); GameTooltip:Show()
                end)
                delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                delBtn:SetScript("OnClick", function()
                    local dialog = StaticPopup_Show("DELVEGUIDE_CONFIRM_REMOVE_CHAR", capName)
                    if dialog then dialog.data = capK end
                end)
            end
            y = y + rH + 2
        end
    end

    y = y + 12
    y = y + UI.CreateRow(cf, y, "|cFF555555Hover over Vault and Delves numbers for detailed tooltips.|r")
    cf:SetHeight(y + 20)
end