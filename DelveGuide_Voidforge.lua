-- ============================================================
-- DelveGuide_Voidforge.lua  --  Season 2 bonus-roll & upgrade state
-- ============================================================
-- One source of truth for the delve reward currencies, shared by the
-- widget, checklist, Voidforge tab, history tab, and map tooltip.
--
-- Season 2 (12.1) model:
--   * Nebulous Voidcore (3418) -- confirmed in game. Transmuted into gear
--       after Midnight raid bosses, M+, Bountiful Delves and Nightmare Prey.
--       One item per difficulty level until the spec's pool is exhausted.
--       Blizzard's own tooltip lists per-character totals, so an account-wide
--       read may be possible -- see /dg currencydebug.
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
    NEBULOUS_CURRENCY_ID    = 3418, -- "Nebulous Voidcore" -- CONFIRMED in game (tooltip shows
                                     -- ID 3418). The addon previously used 3513, which appears
                                     -- to have been wrong rather than a season change: alts show
                                     -- balances on 3418 while "Season Total Earned" reads 0, i.e.
                                     -- carried-over Season 1 currency on this same id.
                                     -- NOTE: info.quantity is the running total INCLUDING those
                                     -- leftovers, not what you earned this season. If a
                                     -- season-scoped figure is wanted, check whether
                                     -- info.totalEarned matches the tooltip (/dg currencydebug).
    VENOMSTONE_CURRENCY_ID  = nil,  -- "Ascendant Venomstone" -- not live yet (arrives later in
                                     -- S2). Set this when it appears as a currency...
    VENOMSTONE_ITEM_ID      = nil,  -- ...or set this if it turns out to be a bag item instead.
    VENOMSTONE_PER_UPGRADE  = 10,   -- 10 Venomstones upgrade one eligible piece.
    MIN_VOIDCORE_TIER       = 8,    -- The tier from which a Bountiful Delve's end-of-run loot is the max
                                     -- pool (Tiers 9-11 match 8), i.e. where a Voidcore bonus roll is worth
                                     -- spending. Voidcores do NOT drop from delves (Nick, live, 2026-09-06).
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
-- Ascendant Venomstones upgrade weapons and trinkets ONLY (Nick, live,
-- 2026-09-06), so these four are the only slots that belong here. The tab
-- used to list all sixteen with armour marked [low]; that implied armour could
-- be upgraded at all, which it cannot.
--
-- `tier` is kept (all 1) so the sort and the UI's prefix logic stay as they
-- were; empty slots still sort first, then ASC by ilvl.
local SLOT_INFO = {
    { id = 16, label = "Main Hand", tier = 1 },
    { id = 17, label = "Off Hand",  tier = 1 },
    { id = 13, label = "Trinket 1", tier = 1 },
    { id = 14, label = "Trinket 2", tier = 1 },
}

DelveGuide.VoidforgeSlots = SLOT_INFO

-- Returns a list of {slot, label, tier, ilvl, link, empty} for the four
-- Venomstone-upgradeable slots. Sort order: empty slots first, then ASC by
-- ilvl, so the lowest weapon or trinket is the first upgrade target.
DelveGuide.GetVoidforgeSlotPriority = function()
    local out = {}

    -- A two-hander or a ranged weapon leaves the off-hand legitimately empty,
    -- and empty slots sort to the top -- so the tab opened with "[empty] Off
    -- Hand" as the first upgrade target for every such spec. Skip the row in
    -- exactly that case: Fury warriors can Titan's Grip two two-handers, so if
    -- anything IS equipped off-hand the row stays.
    local skipOffHand = false
    pcall(function()
        if GetInventoryItemLink("player", INVSLOT_OFFHAND or 17) then return end
        local mhLink = GetInventoryItemLink("player", INVSLOT_MAINHAND or 16)
        if not mhLink then return end
        if not (C_Item and C_Item.GetItemInfoInstant) then return end
        local _, _, _, equipLoc = C_Item.GetItemInfoInstant(mhLink)
        skipOffHand = (equipLoc == "INVTYPE_2HWEAPON")
                   or (equipLoc == "INVTYPE_RANGED")
                   or (equipLoc == "INVTYPE_RANGEDRIGHT")
    end)

    for _, s in ipairs(SLOT_INFO) do
        local skip = skipOffHand and s.id == (INVSLOT_OFFHAND or 17)
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
        if not skip then
            table.insert(out, {
                slot  = s.id,
                label = s.label,
                tier  = s.tier,
                ilvl  = ilvl,
                link  = link,
                empty = link == nil,
            })
        end
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
