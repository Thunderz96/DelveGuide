-- ============================================================
-- DelveGuide_Quests.lua  --  Delver's Call quest tracker
-- ============================================================
-- Tracks the per-delve "Delver's Call" quests across characters.
-- Two data sources (auto first, manual fallback):
--   * Auto: when DelveGuideData.delversCall[i].questID is filled in,
--     C_QuestLog answers state directly. No saved-vars needed.
--   * Manual: while questIDs are still nil, the user clicks through
--     three states (fresh -> banked -> completed) and we persist
--     that per-character in DelveGuideDB.delversCall[charKey].
--
-- "banked" is the leveling-alt sweet spot: quest is in the log but
-- the player is intentionally holding it for a level cap turn-in.
-- ============================================================

DelveGuide.Quests = DelveGuide.Quests or {}

local function CharKey()
    local name  = UnitName("player") or "?"
    local realm = GetRealmName()     or "?"
    return name .. "-" .. realm
end

local function ManualStore(create)
    if not DelveGuideDB then return nil end
    if not DelveGuideDB.delversCall then
        if not create then return nil end
        DelveGuideDB.delversCall = {}
    end
    local key = CharKey()
    if not DelveGuideDB.delversCall[key] then
        if not create then return nil end
        DelveGuideDB.delversCall[key] = {}
    end
    return DelveGuideDB.delversCall[key]
end

-- Returns the metadata row for a delve name, or nil.
DelveGuide.GetDelversCallEntry = function(delveName)
    if not DelveGuideData or not DelveGuideData.delversCall then return nil end
    for _, row in ipairs(DelveGuideData.delversCall) do
        if row.delve == delveName then return row end
    end
    return nil
end

-- State strings (in alt-leveling progression order):
--   "fresh"      -- never picked up
--   "inProgress" -- in log, objectives NOT done (need to run the delve)
--   "ready"      -- in log, objectives DONE, banked waiting for turn-in
--   "completed"  -- turned in
-- `auto` indicates the value came from C_QuestLog (vs. user click).
DelveGuide.GetDelversCallState = function(delveName)
    local row = DelveGuide.GetDelversCallEntry(delveName)
    if not row then return "fresh", false end

    if row.questID and C_QuestLog then
        if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(row.questID) then
            return "completed", true
        end
        local logIdx = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(row.questID)
        if logIdx then
            -- Quest is in the log. Distinguish "ready to hand in" from "still
            -- working on objectives" -- pcall both APIs because IsComplete and
            -- ReadyForTurnIn have shifted signatures across patches.
            local objectivesDone = false
            if C_QuestLog.ReadyForTurnIn then
                local ok, ready = pcall(C_QuestLog.ReadyForTurnIn, row.questID)
                if ok and ready then objectivesDone = true end
            end
            if not objectivesDone and C_QuestLog.IsComplete then
                local ok, done = pcall(C_QuestLog.IsComplete, row.questID)
                if ok and done then objectivesDone = true end
            end
            return objectivesDone and "ready" or "inProgress", true
        end
        return "fresh", true
    end

    local store = ManualStore(false)
    if store and store[delveName] then return store[delveName], false end
    return "fresh", false
end

-- Cycles state forward: fresh -> inProgress -> ready -> completed -> fresh.
-- Only meaningful when auto-detect isn't available (no questID).
DelveGuide.CycleDelversCallManual = function(delveName)
    local store = ManualStore(true)
    if not store then return "fresh" end
    local cur = store[delveName] or "fresh"
    local next = (cur == "fresh")      and "inProgress"
              or (cur == "inProgress") and "ready"
              or (cur == "ready")      and "completed"
              or "fresh"
    store[delveName] = (next == "fresh") and nil or next
    return next
end

-- Reset all manual state for the current character (used after a fresh alt).
DelveGuide.ResetDelversCallManual = function()
    local store = ManualStore(false)
    if not store then return end
    for k in pairs(store) do store[k] = nil end
end

-- Summary counts for the current character.
-- Keys: fresh, inProgress, ready, completed, total, autoCount.
DelveGuide.GetDelversCallSummary = function()
    local out = { fresh = 0, inProgress = 0, ready = 0, completed = 0, total = 0, autoCount = 0 }
    if not DelveGuideData or not DelveGuideData.delversCall then return out end
    for _, row in ipairs(DelveGuideData.delversCall) do
        out.total = out.total + 1
        local state, isAuto = DelveGuide.GetDelversCallState(row.delve)
        out[state] = (out[state] or 0) + 1
        if isAuto then out.autoCount = out.autoCount + 1 end
    end
    return out
end

-- Scans the player's quest log for anything matching "Delver's Call" and
-- prints title + ID + suspected delve match. Used by /dg questscan to help
-- the user catalogue questIDs without leaving the game.
DelveGuide.ScanDelversCallQuests = function()
    if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries then
        print("|cFFFF4444[DelveGuide]|r Quest log API unavailable.")
        return
    end
    local total = C_QuestLog.GetNumQuestLogEntries()
    local hits = 0
    print("|cFF00BFFF[DelveGuide]|r Scanning quest log for Delver's Call quests...")
    for i = 1, total do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.title then
            local title = info.title
            local lower = title:lower()
            if lower:find("delver") or lower:find("delve") then
                hits = hits + 1
                local matchedDelve = nil
                if DelveGuideData and DelveGuideData.delversCall then
                    for _, row in ipairs(DelveGuideData.delversCall) do
                        if title:find(row.delve, 1, true) then matchedDelve = row.delve; break end
                    end
                end
                local tag = matchedDelve and ("|cFF44FF44 -> " .. matchedDelve .. "|r") or " |cFF888888(no delve match)|r"
                print(string.format("  |cFFFFD700%d|r  %s%s", info.questID or 0, title, tag))
            end
        end
    end
    if hits == 0 then
        print("|cFF888888  No matches. Pick up a Delver's Call quest first, then re-run.|r")
    else
        print("|cFF888888  Paste these IDs into DelveGuideData.delversCall in DelveGuide_Data.lua.|r")
    end
end
