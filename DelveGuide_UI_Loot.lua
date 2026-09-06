-- ============================================================
-- DelveGuide_UI_Loot.lua
-- ============================================================
local UI = DelveGuide.UI

local function CreateLootRow(parent, y, item)
    UI.EnsureFontFiles()
    local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    local btn = UI.AcquireButton()
    btn:SetSize(220, rH)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y + 1)
    
    -- Fetch and display the Item Icon!
    local iconTex = UI.AcquireTexture("ARTWORK")
    iconTex:SetSize(rH + 2, rH + 2)
    iconTex:SetPoint("LEFT", btn, "LEFT", 0, 0)
    if item.id then
        -- 12.1.5 deleted the deprecated global GetItemInfoInstant; the tab errored
        -- on every render (found by /dg selftest). C_Item's form has the same
        -- returns. Kept as an if, not `f and f()`, because `and` truncates a call
        -- to its first return and the icon is the fifth.
        local icon
        local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if getInstant then
            local _, _, _, _, ic = getInstant(item.id)
            icon = ic
        end
        iconTex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    local nameFS = UI.AcquireFontString("OVERLAY")
    nameFS:SetFont(ROW_FONT_FILE, rSize)
    -- Shift the text to the right to make room for the icon
    nameFS:SetPoint("LEFT", iconTex, "RIGHT", 6, 0) 
    nameFS:SetWidth(btn:GetWidth() - rH - 6)
    nameFS:SetJustifyH("LEFT")
    
    if item.id then
        nameFS:SetText("|cFF00BFFF" .. item.name .. "|r")
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(string.format("item:%d::::::::::::1:13648", item.id))
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        nameFS:SetText(item.name)
    end
    
    local notesFS = UI.AcquireFontString("OVERLAY")
    notesFS:SetFont(ROW_FONT_FILE, rSize)
    notesFS:SetPoint("TOPLEFT", parent, "TOPLEFT", 236, -y)
    notesFS:SetWidth(parent:GetWidth() - 244)
    notesFS:SetJustifyH("LEFT")
    notesFS:SetText(item.notes)
    
    return rH
end

DelveGuide.RenderLoot = function()
    local cf = UI.NewContentFrame()
    local y = 10
    
    -- We must define the sizes and fonts up here so the headers can use them!
    UI.EnsureFontFiles()
    local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    
    y = y + UI.CreateHeader(cf, y, "Notable Loot  --  Trinkets, Weapons & Cosmetics from Midnight Delves") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Hover an item name to preview its tooltip.|r") + 4

    -- Season 2 delve reward currencies
    y = y + 4
    y = y + UI.CreateRow(cf, y, "|cFFFFD700Delve Reward Currencies|r  |cFF888888(Season 2)|r")
    y = y + UI.CreateRow(cf, y, "  |cFFAA66CCNebulous Voidcore|r   |cFF888888Transmute into powerful equipment after Midnight raid bosses, Mythic+ dungeons, Bountiful Delves, or Nightmare Prey Hunts. One item per difficulty level, until your spec's pool is exhausted.|r")
    y = y + UI.CreateRow(cf, y, "  |cFFAA66CCAscendant Venomstone|r   |cFF888888Gear-upgrade material (arriving later this season). 10 upgrade one weapon/trinket/neck; a Tier 11 Bountiful Delve guarantees one (~1-2).|r") + 6
    
    for _, slot in ipairs({"Trinket", "Weapon", "Cosmetic"}) do
        y = y + 4
        y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. slot .. "s|r")
        if slot == "Cosmetic" then
            y = y + UI.CreateRow(cf, y, "|cFF888888Mounts, back pieces and toys. Rows marked unverified came from guide sites and have not been seen in game yet.|r")
        end
        
        -- Custom perfectly-aligned header row
        local hName = UI.AcquireFontString("OVERLAY")
        hName:SetFont(ROW_FONT_FILE, rSize)
        hName:SetPoint("TOPLEFT", cf, "TOPLEFT", rH + 16, -y) -- perfectly aligns with item name
        hName:SetText("|cFF888888Item Name|r")
        hName:SetJustifyH("LEFT")
        
        local hNotes = UI.AcquireFontString("OVERLAY")
        hNotes:SetFont(ROW_FONT_FILE, rSize)
        hNotes:SetPoint("TOPLEFT", cf, "TOPLEFT", 236, -y) -- perfectly aligns with item notes
        hNotes:SetText("|cFF888888Effect / Notes|r")
        hNotes:SetJustifyH("LEFT")
        
        y = y + rH + 2
        
        for _, item in ipairs(DelveGuideData.loot) do
            if item.slot == slot then
                if slot == "Cosmetic" then
                    -- Cosmetics are about where they come from, not what they do,
                    -- so the notes column carries the source. Render a shallow copy;
                    -- the data row stays untouched.
                    local shown = { name = item.name, id = item.id,
                        notes = (item.notes or "") .. "  |cFF888888" .. (item.source or "") .. "|r"
                              .. (item.verified == false and "  |cFFFF8800unverified|r" or "") }
                    y = y + CreateLootRow(cf, y, shown)
                else
                    y = y + CreateLootRow(cf, y, item)
                end
            end
        end
        y = y + 8
    end
    
    y = y + 8
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Midnight Delve iLvl Scaling  (Season 2) --|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888End-of-run gear caps at Tier 3 without a Restored Coffer Key; Tiers 9-11 match Tier 8+.|r") + 4
    
    -- Helper function to draw text at exact X positions for perfect columns
    local function MakeScalingCol(x, text)
        local fs = UI.AcquireFontString("OVERLAY")
        fs:SetFont(ROW_FONT_FILE, rSize)
        fs:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
    end

    -- Aligned headers -- values come from DelveGuideData.tierRewards (single source).
    MakeScalingCol(16,  "|cFF888888Tier|r")
    MakeScalingCol(70,  "|cFF888888End-of-run|r")
    MakeScalingCol(190, "|cFF888888Great Vault|r")
    y = y + rH + 4

    local rewards = DelveGuideData.tierRewards or {}
    for tier = 1, 11 do
        local r = rewards[tier]
        if r then
            local tierText = (tier < 10) and ("  " .. tier) or tostring(tier)
            MakeScalingCol(16,  tierText)
            MakeScalingCol(70,  "|cFF00FF00" .. (r.coffer or "?") .. "|r")
            MakeScalingCol(190, "|cFF00BFFF" .. (r.vault or "?") .. "|r")
            y = y + rH + 2
        end
    end
    
    cf:SetHeight(y + 20)
end