-- ============================================================
-- DelveGuide_Voidforge.lua  --  Season 2 bonus-roll & upgrade state
-- ============================================================
-- One source of truth for the delve reward currencies, shared by the
-- widget, checklist, Voidforge tab, history tab, and map tooltip.
--
-- Season 2 (12.1) model:
--   * Nebulous Voidcore (3418) -- BONUS-ROLL currency. Spend one to roll
--       for loot after a raid boss / M+ / Nightmare Prey / Bountiful Delve.
--       Drops from T8+ Bountiful Delves (among other content).
--   * Ascendant Venomstone -- GEAR-UPGRADE material, arriving later this
--       season. 10 upgrade one weapon/trinket/neck; a Tier 11 Bountiful
--       Delve is a guaranteed source (~1-2 each, unconfirmed). Currency/
--       item ID is unknown until it goes live -- fill it in then.
--
-- The old 12.0.5 "Building the Voidforge" weekly (Elementary Voidcore
-- Shards) and Ascendant Voidcore upgrade loop are retired.
-- To find an ID once one is in your log:
--   /run for i=3000,4200 do local c=C_CurrencyInfo.GetCurrencyInfo(i); if c and c.name and (c.name:find("Voidcore") or c.name:find("Venomstone")) then print(i, c.name) end end
DelveGuide.Voidforge = {
    NEBULOUS_CURRENCY_ID    = 3418, -- Season 2 "Nebulous Voidcore" (bonus rolls). Replaced the
                                     -- S1 currency (3513) at the S2 flip. If maxWeeklyQuantity
                                     -- is exposed the cap shows automatically; else raw count.
    VENOMSTONE_CURRENCY_ID  = nil,  -- "Ascendant Venomstone" -- not live yet (arrives later in
                                     -- S2). Set this when it appears as a currency...
    VENOMSTONE_ITEM_ID      = nil,  -- ...or set this if it turns out to be a bag item instead.
    VENOMSTONE_PER_UPGRADE  = 10,   -- 10 Venomstones upgrade one eligible piece.
    MIN_VOIDCORE_TIER       = 8,    -- T8+ Bountiful Delves drop Nebulous Voidcores.
    VENOMSTONE_TIER         = 11,   -- T11 Bountiful Delves guarantee an Ascendant Venomstone.
}

-- Returns a snapshot of current Voidforge state. Any field can be nil
-- if the corresponding ID hasn't been configured yet -- callers must
-- check s.configured before rendering numbers.
DelveGuide.GetVoidforgeStatus = function()
    local V = DelveGuide.Voidforge
    local s = {
        configured       = false,
        cores            = nil,  -- current Nebulous Voidcore (bonus-roll) count
        coreMax          = nil,  -- weekly or seasonal cap (if the API exposes one)
        venomstones      = nil,  -- Ascendant Venomstone count (nil until it goes live)
        venomstonesPerUp = V.VENOMSTONE_PER_UPGRADE,
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

    if V.VENOMSTONE_CURRENCY_ID then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, V.VENOMSTONE_CURRENCY_ID)
        if ok and info then
            s.venomstones = info.quantity or 0
            s.configured = true
        end
    elseif V.VENOMSTONE_ITEM_ID and C_Item and C_Item.GetItemCount then
        local ok, qty = pcall(C_Item.GetItemCount, V.VENOMSTONE_ITEM_ID, true)
        if ok then
            s.venomstones = qty or 0
            s.configured = true
        end
    end

    return s
end

DelveGuide.IsDelveVoidcoreEligible = function(tierNum)
    return type(tierNum) == "number"
        and tierNum >= DelveGuide.Voidforge.MIN_VOIDCORE_TIER
end

-- Equipment slot scan -- powers the Voidforge tab's "upgrade priority" table.
-- We map slot IDs -> human labels here so the UI doesn't have to. Slot 4 (shirt),
-- 18 (legacy ranged), and 19 (tabard) are skipped because they don't take ilvl
-- upgrades from Voidcores.
--
-- `tier` controls upgrade priority (lower = recommend first):
--   1 = weapons & trinkets (highest stat-per-ilvl, biggest DPS/HPS gain)
--   2 = everything else
-- Within a tier, items sort ASC by ilvl, and empty slots beat both tiers.
local SLOT_INFO = {
    { id = 16, label = "Main Hand", tier = 1 },
    { id = 17, label = "Off Hand",  tier = 1 },
    { id = 13, label = "Trinket 1", tier = 1 },
    { id = 14, label = "Trinket 2", tier = 1 },
    { id = 1,  label = "Head",      tier = 2 },
    { id = 2,  label = "Neck",      tier = 2 },
    { id = 3,  label = "Shoulder",  tier = 2 },
    { id = 15, label = "Back",      tier = 2 },
    { id = 5,  label = "Chest",     tier = 2 },
    { id = 9,  label = "Wrist",     tier = 2 },
    { id = 10, label = "Hands",     tier = 2 },
    { id = 6,  label = "Waist",     tier = 2 },
    { id = 7,  label = "Legs",      tier = 2 },
    { id = 8,  label = "Feet",      tier = 2 },
    { id = 11, label = "Finger 1",  tier = 2 },
    { id = 12, label = "Finger 2",  tier = 2 },
}

DelveGuide.VoidforgeSlots = SLOT_INFO

-- Returns a list of {slot, label, tier, ilvl, link, empty} for every gear slot
-- worth upgrading. Sort order: empty slots first, then weapons/trinkets ASC by
-- ilvl, then everything else ASC by ilvl. Weapons & trinkets get bumped to the
-- top because each ilvl on them carries a much larger stat budget than armor.
DelveGuide.GetVoidforgeSlotPriority = function()
    local out = {}
    for _, s in ipairs(SLOT_INFO) do
        local link = GetInventoryItemLink("player", s.id)
        local ilvl = 0
        if link then
            if C_Item and C_Item.GetDetailedItemLevelInfo then
                local ok, effective = pcall(C_Item.GetDetailedItemLevelInfo, link)
                if ok and type(effective) == "number" then ilvl = effective end
            end
            if ilvl == 0 and GetDetailedItemLevelInfo then
                local ok, effective = pcall(GetDetailedItemLevelInfo, link)
                if ok and type(effective) == "number" then ilvl = effective end
            end
        end
        table.insert(out, {
            slot  = s.id,
            label = s.label,
            tier  = s.tier,
            ilvl  = ilvl,
            link  = link,
            empty = link == nil,
        })
    end
    table.sort(out, function(a, b)
        if a.empty ~= b.empty then return a.empty end
        if a.tier ~= b.tier then return a.tier < b.tier end
        return (a.ilvl or 0) < (b.ilvl or 0)
    end)
    return out
end

-- Formats a short status string for the widget line (one line).
-- Returns nil if nothing is configured yet so the caller can hide the row.
DelveGuide.FormatVoidforgeWidgetLine = function()
    local s = DelveGuide.GetVoidforgeStatus()
    if not s.configured then return nil end

    local parts = {}
    if s.cores then
        local capStr = s.coreMax and ("/" .. s.coreMax) or ""
        table.insert(parts, string.format("|cFFAA66CCRolls:|r %d%s", s.cores, capStr))
    end
    if s.venomstones and s.venomstones > 0 then
        table.insert(parts, string.format("|cFFAA66CCStones:|r %d/%d",
            s.venomstones, s.venomstonesPerUp or 10))
    end

    if #parts == 0 then return nil end
    return table.concat(parts, "   ")
end
