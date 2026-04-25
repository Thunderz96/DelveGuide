-- ============================================================
-- DelveGuide_Voidforge.lua  --  Patch 12.0.5 Voidforge integration
-- ============================================================
-- Centralizes Voidforge currency/quest state so the widget,
-- checklist, history tab, and map tooltip can all share it.
-- ============================================================

-- NOTE: Currency IDs below must be filled in once confirmed in-game.
-- Quick way to find them: run this in chat after the currencies are in
-- your log (they show up in the Currency tab):
--   /run for i=3500,4000 do local c=C_CurrencyInfo.GetCurrencyInfo(i); if c and c.name and (c.name:find("Voidcore") or c.name:find("Shard") or c.name:find("Accolade")) then print(i, c.name) end end
--
-- Systems (patch 12.0.5 "Lingering Shadows"):
--   * Nebulous Voidcore  -- bonus-roll token, +2/wk season cap,
--                           drops from T8+ Bountiful Delves, M+6+,
--                           Nightmare Prey Hunts.
--   * Elementary Voidcore Shard -- weekly "Building the Voidforge"
--                           quest currency (need 3/wk: 1 raid + 1 M+ + 1 delve).
--   * Ascendant Voidcore -- Hero/Myth/Radiance gear item-level upgrades.
DelveGuide.Voidforge = {
    NEBULOUS_CURRENCY_ID   = 3513, -- confirmed 2026-04-23 ("Nebulous Voidcore").
                                    -- NOTE: maxQuantity / maxWeeklyQuantity both return 0,
                                    -- so we display raw count only -- weekly cap isn't
                                    -- exposed on the currency object in 12.0.5.
    ASCENDANT_CURRENCY_ID  = nil,  -- 3000-4500 scan returned nothing matching "Ascendant";
                                    -- likely an ITEM too. Fill SHARD-style item ID or
                                    -- re-scan once you have one in your bags.
    SHARD_CURRENCY_ID      = nil,  -- Confirmed NOT a currency (only Coffer Key / Hellstone /
                                    -- Dundun shards exist). Elementary Voidcore Shard is an
                                    -- item -- use SHARD_ITEM_ID below instead.
    SHARD_ITEM_ID          = nil,  -- TODO: shift-click an Elementary Voidcore Shard and
                                    -- paste the item ID here.
    ASCENDANT_ITEM_ID      = nil,  -- TODO: same deal for Ascendant Voidcore if it's an item.
    BUILDING_QUEST_ID      = 94623, -- "Building The Voidforge" (per wowhead)
    SHARD_WEEKLY_TARGET    = 3,
    MIN_VOIDCORE_TIER      = 8,
}

-- Returns a snapshot of current Voidforge state. Any field can be nil
-- if the corresponding ID hasn't been configured yet -- callers must
-- check s.configured before rendering numbers.
DelveGuide.GetVoidforgeStatus = function()
    local V = DelveGuide.Voidforge
    local s = {
        configured  = false,
        cores       = nil,  -- current Nebulous Voidcore count
        coreMax     = nil,  -- weekly or seasonal cap (if exposed)
        shards      = nil,  -- Elementary Voidcore Shards this week
        shardTarget = V.SHARD_WEEKLY_TARGET,
        questDone   = nil,  -- "Building The Voidforge" turned in this week
        ascendant   = nil,  -- Ascendant Voidcore count
    }

    if V.NEBULOUS_CURRENCY_ID then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, V.NEBULOUS_CURRENCY_ID)
        if ok and info then
            s.cores = info.quantity or 0
            if info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
                s.coreMax = info.maxWeeklyQuantity
            elseif info.maxQuantity and info.maxQuantity > 0 then
                s.coreMax = info.maxQuantity
            end
            s.configured = true
        end
    end

    if V.SHARD_CURRENCY_ID then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, V.SHARD_CURRENCY_ID)
        if ok and info then
            s.shards = info.quantity or 0
            s.configured = true
        end
    elseif V.SHARD_ITEM_ID and C_Item and C_Item.GetItemCount then
        local ok, qty = pcall(C_Item.GetItemCount, V.SHARD_ITEM_ID, true)
        if ok then
            s.shards = qty or 0
            s.configured = true
        end
    end

    if V.ASCENDANT_CURRENCY_ID then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, V.ASCENDANT_CURRENCY_ID)
        if ok and info then
            s.ascendant = info.quantity or 0
            s.configured = true
        end
    elseif V.ASCENDANT_ITEM_ID and C_Item and C_Item.GetItemCount then
        local ok, qty = pcall(C_Item.GetItemCount, V.ASCENDANT_ITEM_ID, true)
        if ok then
            s.ascendant = qty or 0
            s.configured = true
        end
    end

    -- Quest completion is a best-effort fallback when shard currency isn't set.
    if V.BUILDING_QUEST_ID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, V.BUILDING_QUEST_ID)
        if ok then s.questDone = done or false end
    end

    return s
end

DelveGuide.IsDelveVoidcoreEligible = function(tierNum)
    return type(tierNum) == "number"
        and tierNum >= DelveGuide.Voidforge.MIN_VOIDCORE_TIER
end

-- Formats a short status string for the widget line (one line).
-- Returns nil if nothing is configured yet so the caller can hide the row.
DelveGuide.FormatVoidforgeWidgetLine = function()
    local s = DelveGuide.GetVoidforgeStatus()
    if not s.configured then return nil end

    local parts = {}
    if s.cores then
        local capStr = s.coreMax and ("/" .. s.coreMax) or ""
        table.insert(parts, string.format("|cFFAA66CCCores:|r %d%s", s.cores, capStr))
    end
    if s.shards then
        local color = (s.shards >= s.shardTarget) and "|cFF44FF44" or "|cFFFFD700"
        table.insert(parts, string.format("|cFFAA66CCForge:|r %s%d/%d|r",
            color, math.min(s.shards, s.shardTarget), s.shardTarget))
    elseif s.questDone ~= nil then
        local tag = s.questDone and "|cFF44FF44Done|r" or "|cFFFFD700Pending|r"
        table.insert(parts, "|cFFAA66CCForge:|r " .. tag)
    end

    if #parts == 0 then return nil end
    return table.concat(parts, "   ")
end
