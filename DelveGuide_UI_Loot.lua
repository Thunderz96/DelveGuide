-- ============================================================
-- DelveGuide_UI_Loot.lua
-- ============================================================
local UI = DelveGuide.UI

local function CreateLootRow(parent, y, item)
    UI.EnsureFontFiles()
    local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(220, rH)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -y + 1)
    
    -- Fetch and display the Item Icon!
    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(rH + 2, rH + 2)
    iconTex:SetPoint("LEFT", btn, "LEFT", 0, 0)
    if item.id then
        local icon = GetItemIcon(item.id)
        iconTex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    local nameFS = btn:CreateFontString(nil, "OVERLAY")
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
    
    local notesFS = parent:CreateFontString(nil, "OVERLAY")
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
    
    y = y + UI.CreateHeader(cf, y, "Notable Loot  --  Trinkets & Weapons from Midnight Delves") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Hover an item name to preview its tooltip.|r") + 4
    
    for _, slot in ipairs({"Trinket", "Weapon"}) do
        y = y + 4
        y = y + UI.CreateRow(cf, y, "|cFFFFD700" .. slot .. "s|r")
        
        -- Custom perfectly-aligned header row
        local hName = cf:CreateFontString(nil, "OVERLAY")
        hName:SetFont(ROW_FONT_FILE, rSize)
        hName:SetPoint("TOPLEFT", cf, "TOPLEFT", rH + 16, -y) -- perfectly aligns with item name
        hName:SetText("|cFF888888Item Name|r")
        hName:SetJustifyH("LEFT")
        
        local hNotes = cf:CreateFontString(nil, "OVERLAY")
        hNotes:SetFont(ROW_FONT_FILE, rSize)
        hNotes:SetPoint("TOPLEFT", cf, "TOPLEFT", 236, -y) -- perfectly aligns with item notes
        hNotes:SetText("|cFF888888Effect / Notes|r")
        hNotes:SetJustifyH("LEFT")
        
        y = y + rH + 2
        
        for _, item in ipairs(DelveGuideData.loot) do
            if item.slot == slot then 
                y = y + CreateLootRow(cf, y, item) 
            end
        end
        y = y + 8
    end
    
    y = y + 8
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- Midnight Delve iLvl Scaling --|r") + 4
    
    -- Helper function to draw text at exact X positions for perfect columns
    local function MakeScalingCol(x, text)
        local fs = cf:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ROW_FONT_FILE, rSize)
        fs:SetPoint("TOPLEFT", cf, "TOPLEFT", x, -y)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
    end

    -- Draw the aligned headers
    MakeScalingCol(16, "|cFF888888Tier|r")
    MakeScalingCol(60, "|cFF888888Recommended|r")
    MakeScalingCol(160, "|cFF888888Bountiful Drop|r")
    MakeScalingCol(264, "|cFF888888Great Vault|r")
    y = y + rH + 4
    
    local tiers = {
        {1,170,220,233}, {2,187,224,237}, {3,200,227,240}, {4,213,230,243}, {5,222,233,246},
        {6,229,237,253}, {7,235,246,256}, {8,244,250,259}, {9,250,250,259}, {10,257,250,259}, {11,265,250,259}
    }
    
    -- Draw the aligned rows
    for _, d in ipairs(tiers) do
        -- Add a tiny space for single-digit tiers so they center nicely under the "Tier" header
        local tierText = (d[1] < 10) and ("  " .. d[1]) or tostring(d[1])
        
        MakeScalingCol(16, tierText)
        MakeScalingCol(60, tostring(d[2]))
        MakeScalingCol(160, "|cFF00FF00" .. d[3] .. "|r")
        MakeScalingCol(264, "|cFF00BFFF" .. d[4] .. "|r")
        y = y + rH + 2
    end
    
    cf:SetHeight(y + 20)
end