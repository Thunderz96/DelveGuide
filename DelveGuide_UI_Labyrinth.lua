-- ============================================================
-- DelveGuide_UI_Labyrinth.lua  --  Labyrinth tab (D4)
-- ------------------------------------------------------------
-- The Labyrinth of Kindo'jan is not a Delve, but it feeds the same Great
-- Vault: three chambers cleared is one delve vault credit. This tab reports
-- what the addon has actually RECORDED (history rows with kind="labyrinth",
-- and the DelveGuideDB.labyrinthLog observation entries), what the GAME
-- records (renown, the tier-ladder achievements, lifetime statistics), and
-- the reward list from DelveGuideData.labyrinthContent, marked earned or
-- collected where the game can say.
-- ============================================================
local UI = DelveGuide.UI
local L = DelveGuide.L

local LAB_FACTION = 2836

local function MMSS(sec)
    sec = math.floor(tonumber(sec) or 0)
    return string.format(L["%dm %02ds"], math.floor(sec / 60), sec % 60)
end

local function Median(list)
    table.sort(list)
    local n = #list
    if n == 0 then return 0 end
    if n % 2 == 1 then return list[(n + 1) / 2] end
    return (list[n / 2] + list[n / 2 + 1]) / 2
end

-- ------------------------------------------------------------
-- 2. THIS WEEK
-- One line per character, summed across however many visits they made:
-- a Labyrinth is resumable, so two sittings on the same character are two
-- history rows and one weekly total.
-- ------------------------------------------------------------
local function RenderThisWeek(cf, y)
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["This Week"] .. "|r") + 4

    local resetKey = DelveGuide.GetResetKey and DelveGuide.GetResetKey()
    local chars, order = {}, {}
    for _, run in ipairs((DelveGuideDB and DelveGuideDB.history) or {}) do
        if run.kind == "labyrinth" and resetKey and run.resetKey == resetKey then
            local ckey = (run.char or "Unknown") .. (run.realm and ("-" .. run.realm) or "")
            local c = chars[ckey]
            if not c then c = { chambers = 0, credits = 0, elapsed = 0 }; chars[ckey] = c; table.insert(order, ckey) end
            c.chambers = c.chambers + (run.chambers or 0)
            c.credits  = c.credits + (run.vaultCredits or 0)
            c.elapsed  = c.elapsed + (tonumber(run.elapsed) or 0)
            local tn = tonumber(run.tierNum)
            if tn and (not c.tier or tn > c.tier) then c.tier = tn end
        end
    end

    if #order == 0 then
        return y + UI.CreateRow(cf, y, "|cFF888888  " .. L["No Labyrinth run logged this week."] .. "|r") + 8
    end

    table.sort(order, function(a, b) return chars[a].chambers > chars[b].chambers end)
    for _, ckey in ipairs(order) do
        local c = chars[ckey]
        local tierStr = c.tier and ("  |cFF888888[" .. string.format(L["Tier %d"], c.tier) .. "]|r")
                        or ("  |cFF888888[" .. L["tier not recorded"] .. "]|r")
        local timeStr = (c.elapsed > 0) and ("  |cFF00BFFF[" .. MMSS(c.elapsed) .. "]|r") or ""
        y = y + UI.CreateRow(cf, y, string.format("  |cFF00FF88%s|r  |cFFCCCCCC%s|r  |cFFFFD700%s|r",
            ckey,
            string.format(L["%d chamber(s)"], c.chambers),
            string.format(L["%d vault credit(s)"], c.credits)) .. tierStr .. timeStr)
    end
    return y + 8
end

-- ------------------------------------------------------------
-- 3. RENOWN
-- Faction 2836 is a renown track like Delver's Journey, not a classic
-- reputation: C_Reputation.GetFactionDataByID returns nil for it, which is
-- why this section only ever said "not available". C_MajorFactions reads it
-- (PTR /dg export, 2026-09-07: renown 1, 2120 / 4200). On a live 12.1.0
-- client the faction does not exist, which is a normal answer, not an error.
-- ------------------------------------------------------------
local function RenderReputation(cf, y)
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Renown"] .. "|r") + 4

    local d, atMax
    pcall(function()
        if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
            d = C_MajorFactions.GetMajorFactionData(LAB_FACTION)
            atMax = C_MajorFactions.HasMaximumRenown and C_MajorFactions.HasMaximumRenown(LAB_FACTION)
        end
    end)
    if not (d and d.name and d.name ~= "") then
        return y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Not available on this client yet -- the Kindo'jan reputation only exists on 12.1.5."] .. "|r") + 8
    end

    local level = tonumber(d.renownLevel) or 0
    local cur   = tonumber(d.renownReputationEarned) or 0
    local need  = tonumber(d.renownLevelThreshold) or 0
    y = y + UI.CreateRow(cf, y, "  |cFF00BFFF" .. d.name .. "|r  |cFFFFD700" .. string.format(L["Renown %d"], level) .. "|r")
    if d.isUnlocked == false then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Not unlocked yet."] .. "|r")
    elseif atMax or need <= 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Maximum rank."] .. "|r")
    else
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. string.format(L["%d / %d to the next rank"], cur, need) .. "|r")
    end
    return y + 8
end

-- true / false when the game can answer, nil when it cannot (an ID this
-- client does not know, e.g. a 12.1.0 client).
local function AchievementDone(id)
    local ok, aid, _, _, completed = pcall(GetAchievementInfo, id)
    if not ok or not aid then return nil end
    return completed and true or false
end

local function RewardStatus(r)
    if r.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
        -- isCollected is the 11th return
        local ok, name, _, _, _, _, _, _, _, _, _, isCollected = pcall(C_MountJournal.GetMountInfoByID, r.mountID)
        if ok and name then return isCollected and true or false end
    end
    if r.itemID and C_ToyBox and C_ToyBox.GetToyInfo and PlayerHasToy then
        -- PlayerHasToy says false for an item the client does not know as a
        -- toy at all, so ask the toy box first; an unknown ID stays unmarked.
        local ok, known = pcall(C_ToyBox.GetToyInfo, r.itemID)
        if ok and known then return PlayerHasToy(r.itemID) and true or false end
    end
    if r.achievementID then return AchievementDone(r.achievementID) end
    if r.renown and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        local ok, d = pcall(C_MajorFactions.GetMajorFactionData, LAB_FACTION)
        if ok and d and d.renownLevel then return d.renownLevel >= r.renown end
    end
    return nil
end

-- ------------------------------------------------------------
-- 3b. PROGRESS
-- The tier ladder is eleven achievements, "3 chambers on Tier N", each
-- unlocking the next tier, so the highest one earned is how far up the
-- ladder the account is. Lifetime counts are the game's own statistics.
-- Hidden on a client that knows none of the achievements.
-- ------------------------------------------------------------
local function Statistic(id)
    local ok, v = pcall(GetStatistic, id)
    if not ok or v == nil or v == "" then return nil end
    v = tostring(v)
    return (v == "--") and "0" or v
end

local function RenderProgress(cf, y, content)
    local ladder = content.tierAchievements or {}
    local top, known = 0, false
    for tier, id in ipairs(ladder) do
        local done = AchievementDone(id)
        if done ~= nil then known = true end
        if done then top = tier end
    end
    if not known then return y end

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Progress"] .. "|r") + 4
    local ladderText
    if top == 0 then
        ladderText = L["Tier ladder: nothing cleared yet. 3 chambers on Tier 1 starts it."]
    elseif top >= #ladder then
        ladderText = string.format(L["Tier ladder: complete (3 chambers on Tier %d)."], top)
    else
        ladderText = string.format(L["Tier ladder: 3 chambers cleared on Tier %d. Next: 3 on Tier %d."], top, top + 1)
    end
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. ladderText .. "|r")

    local ch    = content.statChambers and Statistic(content.statChambers)
    local kills = content.statKills and Statistic(content.statKills)
    if ch or kills then
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. string.format(L["This character, lifetime: %s chambers cleared, Kindo'jan defeated %s time(s)."], ch or "?", kills or "?") .. "|r")
    end
    return y + 8
end

-- ------------------------------------------------------------
-- 4. CHAMBERS SEEN
-- Chamber CONTENT is drawn from a pool and re-rolled per run, so the useful
-- unit is the scenario, not the run. The observation log is bounded at 80
-- entries, so this is "what you have seen lately", not a catalogue.
-- ------------------------------------------------------------
local function RenderChambers(cf, y)
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Chambers Seen"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["recorded from your own runs: one row per chamber objective"] .. "|r") + 4

    local seen, order = {}, {}
    for _, e in ipairs((DelveGuideDB and DelveGuideDB.labyrinthLog) or {}) do
        if e.kind == "chamber" then
            -- A chamber is named by its step title: since build 69848 every
            -- chamber's scenario name is the Labyrinth's own, so keying on it
            -- folded the whole list into one row. Entries logged before the
            -- step title was captured still carry the content in scenarioName.
            local key = e.stepTitle
            if not key or key == "" then key = (e.scenarioName ~= e.labyrinth) and e.scenarioName or nil end
            if not key or key == "" then key = e.scenarioID and ("#" .. tostring(e.scenarioID)) or nil end
            if key then
                local s = seen[key]
                if not s then s = { count = 0, secs = {} }; seen[key] = s; table.insert(order, key) end
                s.count = s.count + 1
                local el = tonumber(e.elapsed)
                if el and el > 0 then table.insert(s.secs, el) end
                if e.at and (not s.last or e.at > s.last) then s.last = e.at end
            end
        end
    end

    -- History knows the total chambers cleared even after the log has rolled
    -- old entries off, so say so rather than let the two numbers disagree
    -- silently.
    local histChambers = 0
    for _, run in ipairs((DelveGuideDB and DelveGuideDB.history) or {}) do
        if run.kind == "labyrinth" then histChambers = histChambers + (run.chambers or 0) end
    end

    if #order == 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Nothing recorded yet. The log fills in as you clear chambers -- one entry per chamber, keeping the most recent 80 events."] .. "|r")
        if histChambers > 0 then
            y = y + UI.CreateRow(cf, y, "|cFF888888  " .. string.format(L["History still counts %d chamber(s) cleared."], histChambers) .. "|r")
        end
        return y + 8
    end

    table.sort(order, function(a, b)
        if seen[a].count ~= seen[b].count then return seen[a].count > seen[b].count end
        return a < b
    end)
    for _, key in ipairs(order) do
        local s = seen[key]
        local medStr = (#s.secs >= 2) and ("  |cFF00BFFF" .. MMSS(Median(s.secs)) .. "|r |cFF666666" .. L["median"] .. "|r") or ""
        local lastStr = s.last and ("  |cFF888888" .. s.last:sub(1, 10) .. "|r") or ""
        y = y + UI.CreateRow(cf, y, string.format("  |cFFCCAAFF%-28s|r |cFFCCCCCC%s|r", key,
            string.format(L["seen x%d"], s.count)) .. medStr .. lastStr)
    end
    if histChambers > 0 then
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. string.format(L["History counts %d chamber(s) cleared in total."], histChambers) .. "|r")
    end
    return y + 8
end

-- ------------------------------------------------------------
-- 5. REWARDS
-- Grouped in a fixed order rather than by whatever order the data table
-- happens to be in, so adding a row cannot reshuffle the page.
-- ------------------------------------------------------------
local REWARD_GROUPS = { "Mount", "Titles", "Toys", "Transmog", "Weekly quest" }
local GROUP_HEADING = {
    Mount            = L["Mount"],
    Titles           = L["Titles"],
    Toys             = L["Toys"],
    Transmog         = L["Transmog"],
    ["Weekly quest"] = L["Weekly quest"],
}

local function RenderRewards(cf, y)
    local content = DelveGuideData and DelveGuideData.labyrinthContent or {}
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Rewards"] .. "|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Earned and collected marks come from your achievements, toys and mounts. Rows marked unverified have no game ID yet."] .. "|r") + 4

    for _, group in ipairs(REWARD_GROUPS) do
        local any = false
        for _, r in ipairs(content.rewards or {}) do
            if r.group == group then
                if not any then
                    any = true
                    y = y + UI.CreateRow(cf, y, "  |cFF00CFFF" .. (GROUP_HEADING[group] or group) .. "|r") + 2
                end
                local have = RewardStatus(r)
                local mark = ""
                if have == true then
                    mark = "  |cFF00FF44" .. (r.group == "Titles" and L["earned"] or L["collected"]) .. "|r"
                elseif have == false then
                    mark = "  |cFF666666" .. L["not yet"] .. "|r"
                end
                y = y + UI.CreateRow(cf, y, "    |cFFCCCCCC" .. r.name .. "|r  |cFF888888-- " .. (r.source or "") .. "|r"
                    .. (r.verified == false and ("  |cFFFF8800" .. L["unverified"] .. "|r") or "") .. mark)
            end
        end
        if any then y = y + 4 end
    end
    return y + 4
end

DelveGuide.RenderLabyrinth = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()
    local content = DelveGuideData and DelveGuideData.labyrinthContent or {}

    y = y + UI.CreateHeader(cf, y, L["Labyrinth of Kindo'jan"]) + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. string.format(
        L["Not a delve, but every %d chambers cleared is a delve vault credit -- and progress persists between sessions."],
        content.chambersPerCredit or 3) .. "|r") + 8

    y = RenderThisWeek(cf, y)
    y = RenderReputation(cf, y)
    y = RenderProgress(cf, y, content)
    y = RenderChambers(cf, y)
    y = RenderRewards(cf, y)

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Tips"] .. "|r") + 4
    for _, tip in ipairs(content.tips or {}) do
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. tip .. "|r") + 2
    end

    cf:SetHeight(y + 20)
end
