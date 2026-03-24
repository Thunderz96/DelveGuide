-- ============================================================
-- DelveGuide_Victory.lua
-- ============================================================
local victoryFrame = nil

DelveGuide.ShowVictoryScreen = function(delveName, tierStr, vaultIlvl, elapsed)
    -- Stop immediately if the user disabled the popup in settings
    if DelveGuideDB and DelveGuideDB.victoryEnabled == false then return end
    if not victoryFrame then        
        victoryFrame = CreateFrame("Frame", "DelveGuideVictoryToast", UIParent, "BackdropTemplate")
        victoryFrame:SetSize(340, 128)
        victoryFrame:SetFrameStrata("DIALOG")
        
        -- 1. Enable Dragging
        victoryFrame:SetMovable(true)
        victoryFrame:EnableMouse(true)
        victoryFrame:RegisterForDrag("LeftButton")
        
        victoryFrame:SetScript("OnDragStart", function(self)
            if DelveGuideDB and not DelveGuideDB.victoryUnlocked then return end
            self:StartMoving()
        end)
        
        victoryFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- 2. Save the new position to the database
            if DelveGuideDB then
                DelveGuideDB.victoryX = self:GetLeft()
                DelveGuideDB.victoryY = self:GetTop() - UIParent:GetHeight()
            end
        end)

        -- 3. Load saved position, or use the default Top-Center
        if DelveGuideDB and DelveGuideDB.victoryX and DelveGuideDB.victoryY then
            victoryFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", DelveGuideDB.victoryX, DelveGuideDB.victoryY)
        else
            victoryFrame:SetPoint("TOP", UIParent, "TOP", 0, -120)
        end
        
        victoryFrame:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 14,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        victoryFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        victoryFrame:SetBackdropBorderColor(1, 0.82, 0, 1) -- Gold border

        -- Header Background Strip
        local hdrBg = victoryFrame:CreateTexture(nil, "ARTWORK")
        hdrBg:SetPoint("TOPLEFT", victoryFrame, "TOPLEFT", 4, -4)
        hdrBg:SetPoint("TOPRIGHT", victoryFrame, "TOPRIGHT", -4, -4)
        hdrBg:SetHeight(28)
        hdrBg:SetColorTexture(0.1, 0.4, 0.8, 0.4)

        victoryFrame.Title = victoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        victoryFrame.Title:SetPoint("TOP", victoryFrame, "TOP", 0, -10)

        victoryFrame.Tier = victoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        victoryFrame.Tier:SetPoint("TOP", victoryFrame.Title, "BOTTOM", 0, -8)

        victoryFrame.Time = victoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        victoryFrame.Time:SetPoint("TOP", victoryFrame.Tier, "BOTTOM", 0, -4)

        victoryFrame.Runs = victoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        victoryFrame.Runs:SetPoint("TOP", victoryFrame.Time, "BOTTOM", 0, -4)

        victoryFrame.Vault = victoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        victoryFrame.Vault:SetPoint("TOP", victoryFrame.Runs, "BOTTOM", 0, -4)

        -- Animations
        victoryFrame.animGroup = victoryFrame:CreateAnimationGroup()
        
        local fadeIn = victoryFrame.animGroup:CreateAnimation("Alpha")
        fadeIn:SetOrder(1); fadeIn:SetDuration(0.5)
        fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1)
        
        local hold = victoryFrame.animGroup:CreateAnimation("Alpha")
        hold:SetOrder(2); hold:SetDuration(5.0) -- Stays on screen for 5 seconds
        hold:SetFromAlpha(1); hold:SetToAlpha(1)
        
        local fadeOut = victoryFrame.animGroup:CreateAnimation("Alpha")
        fadeOut:SetOrder(3); fadeOut:SetDuration(1.0)
        fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0)
        
        victoryFrame.animGroup:SetScript("OnFinished", function() victoryFrame:Hide() end)
    end

    -- 1. Calculate EXACT Delve runs for this character this week (Fixing the Vault API flaw!)
    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
    local currentResetKey = secsUntilReset and (math.floor((time() + secsUntilReset - 604800) / 3600) * 3600) or nil
    local charName = UnitName("player") or "Unknown"
    
    local trueDelveCount = 0
    if DelveGuideDB and DelveGuideDB.history then
        for _, run in ipairs(DelveGuideDB.history) do
            if run.char == charName and run.resetKey == currentResetKey then
                trueDelveCount = trueDelveCount + 1
            end
        end
    end

    -- 2. Populate the Text
    victoryFrame.Title:SetText("|cFFFFD700" .. (delveName or "Unknown Delve") .. " Defeated!|r")
    
    local tStr = tierStr and tostring(tierStr):gsub("Tier ", "") or "?"
    victoryFrame.Tier:SetText("Tier |cFF00FF44" .. tStr .. "|r Completed")

    if elapsed then
        local mins = math.floor(elapsed / 60)
        local secs = math.floor(elapsed % 60)
        victoryFrame.Time:SetText("Completion Time: |cFF00BFFF" .. mins .. "m " .. string.format("%02d", secs) .. "s|r")
        victoryFrame.Time:Show()
    else
        victoryFrame.Time:SetText("")
        victoryFrame.Time:Hide()
    end

    victoryFrame.Runs:SetText("Weekly Delves Completed: |cFF00BFFF" .. trueDelveCount .. "|r")

    if vaultIlvl and vaultIlvl > 0 then
        victoryFrame.Vault:SetText("Great Vault Unlock: |cFFFFD700" .. vaultIlvl .. " ilvl|r")
    else
        victoryFrame.Vault:SetText("|cFF888888Great Vault progress updated.|r")
    end

    victoryFrame.animGroup:Stop() 
    victoryFrame:SetAlpha(1)
    victoryFrame:Show()
    victoryFrame.animGroup:Play()
    

    if not DelveGuideDB or DelveGuideDB.victorySound ~= false then
        PlaySoundFile("Interface\\AddOns\\DelveGuide\\Sounds\\fanfare.ogg", "Master")
    end
end