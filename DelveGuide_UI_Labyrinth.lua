-- ============================================================
-- DelveGuide_UI_Labyrinth.lua  --  Labyrinth tab (D4)
-- ------------------------------------------------------------
-- The Labyrinth of Kindo'jan is not a Delve, but it feeds the same Great
-- Vault: three chambers cleared is one delve vault credit. This tab reports
-- what the addon has actually RECORDED (history rows with kind="labyrinth",
-- and the DelveGuideDB.labyrinthLog observation entries) alongside the
-- reward list from DelveGuideData.labyrinthContent, which is still
-- guide-site sourced and tagged unverified.
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
-- 3. REPUTATION
-- Warband reputations do not show up in GetNumFactions at all (see
-- PTR_12.1.5_Findings.md 5.10), so this is the ID form only. On a live
-- 12.1.0 client the ID is simply not there yet, which is a normal answer
-- and not an error.
-- ------------------------------------------------------------
local function RenderReputation(cf, y)
    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Reputation"] .. "|r") + 4

    local d
    pcall(function()
        if C_Reputation and C_Reputation.GetFactionDataByID then
            d = C_Reputation.GetFactionDataByID(LAB_FACTION)
        end
    end)
    if not (d and d.name and d.name ~= "") then
        return y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Not available on this client yet -- the Kindo'jan reputation only exists on 12.1.5."] .. "|r") + 8
    end

    local rank
    pcall(function()
        if d.reaction then rank = _G["FACTION_STANDING_LABEL" .. d.reaction] end
    end)
    local cur  = tonumber(d.currentStanding) or 0
    local base = tonumber(d.currentReactionThreshold) or 0
    local nxt  = tonumber(d.nextReactionThreshold) or 0
    y = y + UI.CreateRow(cf, y, "  |cFF00BFFF" .. d.name .. "|r  |cFFFFD700" .. (rank or "?") .. "|r")
    if nxt > base then
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. string.format(L["%d / %d to the next rank"], cur - base, nxt - base) .. "|r")
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. L["Maximum rank."] .. "|r")
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
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["recorded from your own runs on PTR build 69594; chamber names may still change"] .. "|r") + 4

    local seen, order = {}, {}
    for _, e in ipairs((DelveGuideDB and DelveGuideDB.labyrinthLog) or {}) do
        if e.kind == "chamber" then
            local key = e.scenarioName
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
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Rows marked unverified came from guide sites and have not been seen in game yet."] .. "|r") + 4

    for _, group in ipairs(REWARD_GROUPS) do
        local any = false
        for _, r in ipairs(content.rewards or {}) do
            if r.group == group then
                if not any then
                    any = true
                    y = y + UI.CreateRow(cf, y, "  |cFF00CFFF" .. (GROUP_HEADING[group] or group) .. "|r") + 2
                end
                y = y + UI.CreateRow(cf, y, "    |cFFCCCCCC" .. r.name .. "|r  |cFF888888-- " .. (r.source or "") .. "|r"
                    .. (r.verified == false and ("  |cFFFF8800" .. L["unverified"] .. "|r") or ""))
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
    y = RenderChambers(cf, y)
    y = RenderRewards(cf, y)

    y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. L["Tips"] .. "|r") + 4
    for _, tip in ipairs(content.tips or {}) do
        y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  " .. tip .. "|r") + 2
    end

    cf:SetHeight(y + 20)
end
