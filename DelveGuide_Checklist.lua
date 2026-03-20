-- ============================================================
-- DelveGuide_Checklist.lua
-- ============================================================
local checklistFrame

local function RunChecklistScan()
    local results = {}

    local keyInfo = C_CurrencyInfo.GetCurrencyInfo(3310)
    local shards = keyInfo and keyInfo.quantity or 0
    local restoredKeys = C_Item.GetItemCount(3028, true) or 0
    local hasKey = shards >= 100 or restoredKeys > 0
    local keyLabel
    if restoredKeys > 0 then
        keyLabel = string.format("Coffer Key  |cFF00FF44(%d restored key%s + %d/600 shards)|r",
            restoredKeys, restoredKeys > 1 and "s" or "", shards)
    else
        keyLabel = string.format("Coffer Key  |cFF888888(%d/600 shards)|r", shards)
    end
    table.insert(results, {
        label = keyLabel,
        ok    = hasKey,
        tip   = not hasKey and "You need 100 shards (1 key) or a Restored Coffer Key to open a Bountiful Coffer." or nil,
    })

    local hasBountyAura = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
        and C_UnitAuras.GetPlayerAuraBySpellID(1254631) ~= nil
    local bountyCount = C_Item.GetItemCount(265714, true) or 0
    
    if hasBountyAura then
        table.insert(results, { label="Trovehunter's Bounty  |cFF00FF44(Active)|r", ok=true })
    elseif bountyCount > 0 then
        table.insert(results, {
            label = string.format("Trovehunter's Bounty  |cFFFFD700(%d in bags — not active)|r", bountyCount),
            ok    = false,
            tip   = "Right-click the item to activate it before entering.",
        })
    else
        table.insert(results, {
            label = "Trovehunter's Bounty  |cFFFF4444(None)|r",
            ok    = false,
            tip   = "Pick one up from the Delver's Journey rewards or the vendor.",
        })
    end

    local valerraOk, valerraLabel = false, "|cFFFF4444Not detected|r"
    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            local companionID = C_DelvesUI.GetCompanionInfoForActivePlayer()
            if companionID and companionID > 0 then
                local roleNames = { [0]="DPS", [1]="Healer", [2]="Tank" }
                local role = DelvesCompanionConfigurationFrame
                    and DelvesCompanionConfigurationFrame.selectedRole
                local roleStr = role and roleNames[role] or "check role"
                valerraOk    = true
                valerraLabel = "|cFF00FF44Present|r  |cFF888888(" .. roleStr .. ")|r"
            end
        end
    end)
    table.insert(results, {
        label = "Valeera  " .. valerraLabel,
        ok    = valerraOk,
        tip   = not valerraOk and "Open the companion panel to configure Valeera." or nil,
    })

    return results
end

DelveGuide.ShowChecklist = function(force)
    if not force then
        if not DelveGuideDB.checklistEnabled then return end
        if DelveGuideDB.checklistDismissed then return end
    end

    if not checklistFrame then
        local f = CreateFrame("Frame", "DelveGuideChecklist", UIParent, "BackdropTemplate")
        f:SetSize(340, 160)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=false, tileSize=16, edgeSize=14,
            insets={left=4,right=4,top=4,bottom=4}
        })
        f:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
        f:SetBackdropBorderColor(1, 0.7, 0, 0.9)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -10)
        title:SetText("|cFFFFD700[DelveGuide]|r  Pre-Entry Checklist")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
        closeBtn:SetScript("OnClick", function()
            DelveGuideDB.checklistDismissed = true
            f:Hide()
        end)

        f.rows = {}
        for i = 1, 4 do
            local row = f:CreateFontString(nil, "OVERLAY")
            row:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 11)
            row:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(24 + (i-1)*22))
            row:SetWidth(316)
            row:SetJustifyH("LEFT")
            f.rows[i] = row
        end

        local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
        cb:SetChecked(false)
        cb:SetScript("OnClick", function(self)
            DelveGuideDB.checklistDismissed = self:GetChecked()
        end)
        
        local cblbl = f:CreateFontString(nil, "OVERLAY")
        cblbl:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 10)
        cblbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cblbl:SetText("|cFF888888Don't show again this session|r")

        checklistFrame = f
    end

    local results = RunChecklistScan()
    local frameH = 44 + #results * 22
    checklistFrame:SetHeight(frameH)

    for i, row in ipairs(checklistFrame.rows) do
        local r = results[i]
        if r then
            local icon
            if r.ok == true then
                icon = "|cFF00FF44✔|r "
            elseif r.ok == false then
                icon = "|cFFFF4444✘|r "
            else
                icon = "|cFFFF8844?|r " 
            end
            local text = icon .. r.label
            if r.tip then text = text .. "  |cFF888888" .. r.tip .. "|r" end
            row:SetText(text)
            row:Show()
        else
            row:Hide()
        end
    end

    checklistFrame:Show()
end

DelveGuide.OnTargetChanged = function()
    if not DelveGuideDB.checklistEnabled then return end
    if DelveGuideDB.checklistDismissed then return end
    
    local matched = false
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            local ok, result = pcall(function()
                local targetName = UnitName("target")
                return targetName and targetName == d.name
            end)
            if ok and result then matched = true; break end
        end
    end
    
    if matched and DelveGuide.ShowChecklist then 
        DelveGuide.ShowChecklist(false) 
    end
end