-- ============================================================
-- DelveGuide_Widget.lua
-- ============================================================
local UI = DelveGuide.UI
local L = DelveGuide.L

local RANK_ORDER       = UI.RANK_ORDER
local W_HEADER_H       = 28
local W_PAD            = 10
local W_MAX_LINES      = 14   -- 12 rotational delves in Season 2, + headroom
local W_BASE_W         = 220
local W_BASE_ROW_SIZE  = 11
local W_BASE_ROW_HEIGHT = 18

-- Widget uses its OWN scale (DelveGuideDB.widgetFontScale), independent of
-- the main fontScale. This lets users keep a large main UI while keeping
-- the floating widget compact (or vice versa).
local function GetWidgetScale()
    return (DelveGuideDB and DelveGuideDB.widgetFontScale) or 1.0
end

local function GetLineH()
    return math.floor(W_BASE_ROW_HEIGHT * GetWidgetScale() + 0.5)
end

local function GetWidgetRSize()
    return math.floor(W_BASE_ROW_SIZE * GetWidgetScale() + 0.5)
end

local function GetWidgetW()
    return math.floor(W_BASE_W * GetWidgetScale() + 0.5)
end

-- Variants rotate at the daily reset. Read at render time only -- the widget
-- redraws on AREA_POIS_UPDATED, so it needs no ticker of its own.
local function RotationCountdown()
    if not (C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) then return nil end
    local ok, secs = pcall(C_DateAndTime.GetSecondsUntilDailyReset)
    if not ok or type(secs) ~= "number" or secs <= 0 then return nil end
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then return string.format(L["Rotates in %dh %dm"], h, m) end
    return string.format(L["Rotates in %dm"], m)
end

-- ============================================================
-- SHARE TO CHAT
-- ============================================================
-- One sender behind all three share paths (/dg share, the widget button, the
-- Delves tab button). Each used to build and send its own list -- one
-- SendChatMessage per variant, with no check that the channel existed, so
-- sharing to party while solo threw a red error at the player.
local SHARE_LINE_MAX = 240   -- the server's hard chat limit is 255

-- Returns the channel to actually send on, or nil plus a reason to print.
local function ResolveShareChannel(channel)
    if channel == "GUILD" then
        if not IsInGuild() then return nil, L["you are not in a guild"] end
        return "GUILD"
    end
    if channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT" then
        -- An LFG/instance group is not the "home" party: PARTY and RAID go
        -- nowhere there, INSTANCE_CHAT is the one that reaches the group.
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
        if channel == "INSTANCE_CHAT" then return nil, L["you are not in an instance group"] end
        if channel == "RAID" then
            if not IsInRaid() then return nil, L["you are not in a raid"] end
            return "RAID"
        end
        if not IsInGroup() then return nil, L["you are not in a party"] end
        return "PARTY"
    end
    return channel
end

-- opts.tierFilter    -- respect the widget's S-F tier checkboxes
-- opts.bountifulOnly -- only share delves flagged Bountiful
DelveGuide.ShareActiveVariants = function(channel, opts)
    opts = opts or {}
    local target, why = ResolveShareChannel(channel)
    if not target then
        print("|cFF00BFFF[DelveGuide]|r " .. string.format(L["Can't share to %s: %s."], channel:lower(), why))
        return
    end

    local activeVariants = DelveGuide.activeVariants or {}
    local activeDelves   = DelveGuide.activeDelves   or {}
    local tiers = (DelveGuideDB and DelveGuideDB.widgetTiers) or {}
    local entries, seen = {}, {}
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do
            if activeVariants[d.variant] and not seen[d.variant]
               and ((not opts.tierFilter) or tiers[d.ranking] or not RANK_ORDER[d.ranking]) then
                local ds = activeDelves[d.name]
                local isB = type(ds) == "table" and ds.bountiful
                if (not opts.bountifulOnly) or isB then
                    seen[d.variant] = true
                    table.insert(entries, {variant=d.variant, ranking=d.ranking, delve=d.name})
                end
            end
        end
    end
    if #entries == 0 then
        print("|cFF00BFFF[DelveGuide]|r " .. string.format(L["No matching variants to share. Try %s first."], "|cFFFFFF00/dg scan|r"))
        return
    end
    table.sort(entries, function(a,b) return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99) end)

    -- Pack several variants per line: one message per variant spams the
    -- channel and trips the server's flood protection on a full rotation.
    local line = "[DelveGuide] " .. L["Today's Active Delves:"]
    for _, e in ipairs(entries) do
        local ds = activeDelves[e.delve]
        local bountyTag = (type(ds)=="table" and ds.bountiful) and " [Bountiful]" or ""
        local part = string.format("[%s] %s (%s)%s", e.ranking, e.variant, e.delve, bountyTag)
        if #line + 2 + #part > SHARE_LINE_MAX then
            SendChatMessage(line, target)
            line = part:sub(1, SHARE_LINE_MAX)
        else
            line = line .. "  " .. part
        end
    end
    SendChatMessage(line, target)
    print("|cFF00BFFF[DelveGuide]|r " .. string.format(L["Shared %d variants to %s"], #entries, "|cFFFFFF00"..target.."|r"))
end

DelveGuide.compactWidget = nil

DelveGuide.UpdateCompactWidget = function()
    local cw = DelveGuide.compactWidget
    if not cw or not cw:IsShown() then return end
    
    if cw.rotateFS then
        local rotate = RotationCountdown()
        cw.rotateFS:SetText(rotate and ("|cFF888888"..rotate.."|r") or "")
    end

    local activeVariants = DelveGuide.activeVariants or {}
    local activeDelves   = DelveGuide.activeDelves or {}
    local tiers = DelveGuideDB.widgetTiers or {}
    local bountifulOnly = DelveGuideDB.widgetBountifulOnly
    local entries = {}

    local shownDelve = {}
    -- Delves the tier filter deliberately hid, tracked separately from what we
    -- display. The [?] fallback below would otherwise re-add every one of them
    -- as an unranked row, which defeated the filter completely.
    local tierFiltered = {}
    -- An unranked variant ("?") could be any rank, so it shows while at least
    -- one rank is ticked. With nothing ticked the filter means "show nothing",
    -- and it used to slip through here regardless (PTR, 2026-09-06: all six
    -- boxes clear, widget still listed "[?] Why Did it Have to Be Snakes?").
    local anyTier = false
    for r in pairs(RANK_ORDER) do if tiers[r] then anyTier = true; break end end
    if DelveGuideData and DelveGuideData.delves then
        local seen = {}
        for _, d in ipairs(DelveGuideData.delves) do
            if activeVariants[d.variant] and not seen[d.variant] then
                if tiers[d.ranking] or (anyTier and not RANK_ORDER[d.ranking]) then
                    local ds = activeDelves[d.name]
                    local isB = type(ds) == "table" and ds.bountiful
                    if (not bountifulOnly) or isB then
                        seen[d.variant] = true
                        shownDelve[d.name] = true
                        table.insert(entries, {variant=d.variant, ranking=d.ranking, delve=d.name})
                    end
                else
                    tierFiltered[d.name] = true
                end
            end
        end
    end

    -- Fallback: surface any delve the scan flagged active whose variant we could
    -- not match. The Delves tab has had this since 1.8.1; the widget never got
    -- it, so an unrecognised variant made the entire delve invisible here --
    -- including its Bountiful flag. That is why [B] reported "No bountiful
    -- delves today" on esMX while the Delves tab listed them correctly: the
    -- variant had no localeVariants entry, so the delve never entered the loop
    -- above at all. Affects any client with an uncatalogued variant, not just
    -- non-English ones. (GitHub #7)
    do
        -- rawScanResults is keyed by the LOCALIZED delve name; activeDelves is
        -- keyed by the English one. Map across so non-EN clients get the real
        -- variant text instead of a placeholder.
        local l10n = DelveGuide.localizedToEnglish or {}
        local variantByDelve = {}
        for _, r in ipairs(DelveGuide.rawScanResults or {}) do
            if r.name and type(r.variantName) == "string" then
                local v = r.variantName:gsub("^%[Missing Translation%] ", "")
                if v ~= "" and v ~= "(not found)" and v ~= "(nil)" and v ~= "(nemesis)" then
                    variantByDelve[l10n[r.name] or r.name] = v
                end
            end
        end
        for name, st in pairs(activeDelves) do
            if not anyTier then tierFiltered[name] = true end
            if not shownDelve[name] and not tierFiltered[name] then
                local isB = type(st) == "table" and st.bountiful
                if (not bountifulOnly) or isB then
                    shownDelve[name] = true
                    table.insert(entries, {variant = variantByDelve[name] or name, ranking = "?", delve = name})
                end
            end
        end
    end
    
    table.sort(entries, function(a,b)
        return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99)
    end)
    
    local lineH = GetLineH()
    local overflow = math.max(0, #entries - W_MAX_LINES)
    local n = math.min(#entries, W_MAX_LINES)
    if n == 0 then
        local emptyMsg
        if next(tierFiltered) then
            emptyMsg = "|cFF888888" .. L["No variants match your tier filter"] .. "|r"
        elseif bountifulOnly then
            emptyMsg = "|cFF888888" .. L["No bountiful delves today"] .. "|r"
        else
            emptyMsg = "|cFF888888" .. L["No active variants"] .. "|r"
        end
        cw.varLines[1].label:SetText(emptyMsg)
        cw.varLines[1].pin = nil
        cw.varLines[1]:ClearAllPoints()
        cw.varLines[1]:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, -(W_HEADER_H+4))
        cw.varLines[1]:Show()
        n = 1
        for i = 2, W_MAX_LINES do cw.varLines[i]:Hide() end
    else
        for i = 1, W_MAX_LINES do
            local line = cw.varLines[i]
            local e = entries[i]
            if e then
                local rc = UI.RANK_COLORS[e.ranking] or "|cFFFFFFFF"
                local pin = UI.FindPinByName(e.delve)
                local ds = activeDelves[e.delve]
                local isBountiful = type(ds)=="table" and ds.bountiful
                local bountyTag = isBountiful and "  |cFFFFD700[B]|r" or ""
                local variantColor = isBountiful and "|cFFFFD700" or "|cFF00CFFF"
                local displayName = pin and (variantColor..e.variant.."|r") or e.variant
                -- If more variants are active than we can show, say so on the
                -- last line instead of silently dropping them.
                if i == W_MAX_LINES and overflow > 0 then
                    line.label:SetText("|cFF888888" .. string.format(L["...and %d more (see Delves tab)"], overflow + 1) .. "|r")
                    line.pin = nil
                else
                    line.label:SetText(rc.."["..e.ranking.."]|r  "..displayName..bountyTag)
                    line.pin = pin
                end
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, -(W_HEADER_H+4+(i-1)*lineH))
                line:Show()
            else line:Hide() end
        end
    end

    local keysY = -(W_HEADER_H + 4 + n*lineH + 6)
    cw.keysLine:ClearAllPoints()
    cw.keysLine:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, keysY)

    local CK = DelveGuideData.cofferKeys
    local keysInfo = C_CurrencyInfo.GetCurrencyInfo(CK.SHARD_CURRENCY_ID)
    local shards   = keysInfo and keysInfo.quantity or 0
    local restoredInfo = C_CurrencyInfo.GetCurrencyInfo(CK.RESTORED_CURRENCY_ID)
    local restored = restoredInfo and restoredInfo.quantity or 0
    local keysStr  = "|cFFFFD700" .. L["Keys:"] .. "|r " .. string.format(L["%d/%d shards"], shards, CK.SHARD_WEEKLY_CAP)
    if restored > 0 then
        keysStr = keysStr .. "  |cFF00FF44" .. string.format(L["+%d restored"], restored) .. "|r"
    end
    cw.keysLine:SetText(keysStr)

    -- Voidforge line (only shown if currency IDs are configured).
    local vfStr = DelveGuide.FormatVoidforgeWidgetLine and DelveGuide.FormatVoidforgeWidgetLine() or nil
    local extraH = 0
    if cw.voidforgeLine then
        if vfStr then
            cw.voidforgeLine:SetText(vfStr)
            cw.voidforgeLine:ClearAllPoints()
            cw.voidforgeLine:SetPoint("TOPLEFT", cw, "TOPLEFT", 8, keysY - lineH)
            cw.voidforgeLine:Show()
            extraH = lineH
        else
            cw.voidforgeLine:Hide()
        end
    end
    cw:SetHeight(W_HEADER_H + 4 + n*lineH + 6 + lineH + extraH + W_PAD)
end

DelveGuide.CreateCompactWidget = function()
    local f = CreateFrame("Frame", "DelveGuideCompactWidget", UIParent, "BackdropTemplate")
    local widgetW = GetWidgetW()
    f:SetSize(widgetW, 80)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    
    f:SetScript("OnDragStart", function(self)
        if DelveGuideDB.widgetLocked then return end
        self.dragging = true; self:StartMoving()
    end)
    
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        DelveGuideDB.widgetX = self:GetLeft()
        DelveGuideDB.widgetY = self:GetTop() - UIParent:GetHeight()
        C_Timer.After(0.05, function() self.dragging = false end)
    end)
    
    f:SetScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" and not self.dragging and DelveGuideDB.widgetClickOpens then
            DelveGuide.Toggle()
        end
    end)
    
    if DelveGuideDB.widgetX then
        local wx = DelveGuideDB.widgetX or 0
        local wy = DelveGuideDB.widgetY or 0
        -- Sanity check: positive Y is stale (pre-1.7.0), or coords may be off-screen
        local screenW = UIParent:GetWidth()
        local screenH = UIParent:GetHeight()
        local offScreen = wy > 0 or wx < -50 or wx > screenW - 20 or wy < -(screenH - 20)
        if offScreen then
            DelveGuideDB.widgetX = nil
            DelveGuideDB.widgetY = nil
            f:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
        else
            f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", wx, wy)
        end
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
    end
    
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile="Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=false, tileSize=16, edgeSize=12,
        insets={left=3, right=3, top=3, bottom=3}
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.88)
    f:SetBackdropBorderColor(0.15, 0.5, 1, 0.8)
    
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("|cFF00BFFFDelveGuide|r")
        GameTooltip:AddLine(L["Drag to reposition."], 0.7, 0.7, 0.7)
        if DelveGuideDB.widgetClickOpens then GameTooltip:AddLine(L["Click to open/close."], 1, 1, 1) end
        GameTooltip:Show()
        if DelveGuideDB.widgetAutoHide then UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1.0) end
    end)
    
    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if DelveGuideDB.widgetAutoHide and not self:IsMouseOver() then
            UIFrameFadeOut(self, 0.5, self:GetAlpha(), 0.15)
        end
    end)

    local rSizeInit = GetWidgetRSize()
    local titleFS = f:CreateFontString(nil, "OVERLAY")
    titleFS:SetFont(GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF", rSizeInit + 1, "OUTLINE")
    titleFS:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -9)
    titleFS:SetText("|cFF00BFFFDelveGuide|r")
    f.titleFS = titleFS

    -- Bountiful filter toggle — gold "[B]" pill, dim when off.
    local bountyBtn = CreateFrame("Button", nil, f)
    bountyBtn:SetSize(18, 14); bountyBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -47, -7)
    bountyBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    local bountyLabel = bountyBtn:CreateFontString(nil, "OVERLAY")
    bountyLabel:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bountyLabel:SetPoint("CENTER", bountyBtn, "CENTER", 0, 0)
    local function RefreshBountyBtn()
        if DelveGuideDB.widgetBountifulOnly then
            bountyLabel:SetText("|cFFFFD700[B]|r")
        else
            bountyLabel:SetText("|cFF555555[B]|r")
        end
    end
    bountyBtn:SetScript("OnClick", function()
        DelveGuideDB.widgetBountifulOnly = not DelveGuideDB.widgetBountifulOnly
        RefreshBountyBtn()
        DelveGuide.UpdateCompactWidget()
    end)
    -- Exposed so /dg bountiful (and Settings, later) can sync the icon state.
    f.RefreshBountyBtn = RefreshBountyBtn
    bountyBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700" .. L["Bountiful Filter"] .. "|r")
        if DelveGuideDB.widgetBountifulOnly then
            GameTooltip:AddLine("|cFF44FF44" .. L["ON"] .. "|r -- " .. L["click to show all variants."], 0.7, 1, 0.7)
        else
            GameTooltip:AddLine("|cFF888888" .. L["OFF"] .. "|r -- " .. L["click to show only bountiful delves."], 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    bountyBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    RefreshBountyBtn()

    -- Share button — sends currently displayed variants to chat
    local shareBtn = CreateFrame("Button", nil, f)
    shareBtn:SetSize(14, 14); shareBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, -7)
    shareBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    shareBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    shareBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    shareBtn:SetScript("OnClick", function(_, button)
        local channel = (button == "RightButton") and "GUILD" or "PARTY"
        DelveGuide.ShareActiveVariants(channel, {
            tierFilter    = true,
            bountifulOnly = DelveGuideDB.widgetBountifulOnly,
        })
    end)
    shareBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700" .. L["Share Active Variants"] .. "|r")
        GameTooltip:AddLine(L["Left-click: Share to Party"], 0.7, 1, 0.7)
        GameTooltip:AddLine(L["Right-click: Share to Guild"], 0.5, 0.7, 1)
        GameTooltip:AddLine(L["Only shares ranks shown by your tier filter."], 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local lockBtn = CreateFrame("Button", nil, f)
    lockBtn:SetSize(14, 14); lockBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -7, -7)
    lockBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    
    local function RefreshLock()
        if DelveGuideDB.widgetLocked then
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Locked-Up")
        else
            lockBtn:SetNormalTexture("Interface\\BUTTONS\\LockButton-Unlocked-Up")
        end
    end
    
    lockBtn:SetScript("OnClick", function()
        DelveGuideDB.widgetLocked = not DelveGuideDB.widgetLocked
        RefreshLock()
    end)
    
    lockBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(DelveGuideDB.widgetLocked and ("|cFFFF4444" .. L["Locked"] .. "|r - " .. L["click to unlock"]) or ("|cFF44FF44" .. L["Unlocked"] .. "|r - " .. L["click to lock"]))
        GameTooltip:Show()
    end)
    lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    RefreshLock()

    -- Rotation countdown, tucked into the header between the title and the
    -- buttons. Anchored on both sides so it truncates instead of overlapping
    -- them at large font scales. Text is filled in by UpdateCompactWidget.
    local rotateFS = f:CreateFontString(nil, "OVERLAY")
    rotateFS:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", math.max(8, rSizeInit - 1))
    rotateFS:SetPoint("LEFT", titleFS, "RIGHT", 6, 0)
    rotateFS:SetPoint("RIGHT", bountyBtn, "LEFT", -4, 0)
    rotateFS:SetJustifyH("RIGHT")
    f.rotateFS = rotateFS

    local innerW = widgetW - 16
    local div = f:CreateTexture(nil, "ARTWORK")
    div:SetColorTexture(0.15, 0.5, 1, 0.35); div:SetSize(innerW, 1)
    div:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -26)
    f.divider = div

    local sf = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local lineHInit = GetLineH()
    f.varLines = {}
    for i = 1, W_MAX_LINES do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(innerW, lineHInit)
        btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")

        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(sf, rSizeInit); fs:SetAllPoints(); fs:SetJustifyH("LEFT")
        btn.label = fs
        
        btn:SetScript("OnClick", function(self)
            if self.pin then UI.SetDelveWaypoint(self.pin) end
        end)
        
        btn:SetScript("OnEnter", function(self)
            if self.pin then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("|cFFFFD700"..self.pin.name.."|r")
                GameTooltip:AddLine(L["Click to open map & set waypoint"], 0, 1, 0.5)
                GameTooltip:Show()
            end
        end)
        
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:Hide()
        f.varLines[i] = btn
    end

    f.keysLine = f:CreateFontString(nil, "OVERLAY")
    f.keysLine:SetFont(sf, rSizeInit); f.keysLine:SetWidth(innerW); f.keysLine:SetJustifyH("LEFT")
    f.keysLine:SetText("|cFFFFD700" .. L["Keys:"] .. "|r --")

    f.voidforgeLine = f:CreateFontString(nil, "OVERLAY")
    f.voidforgeLine:SetFont(sf, rSizeInit); f.voidforgeLine:SetWidth(innerW); f.voidforgeLine:SetJustifyH("LEFT")
    f.voidforgeLine:Hide()
    
    if DelveGuideDB.widgetHidden then f:Hide() end
    if DelveGuideDB.widgetAutoHide then f:SetAlpha(0.15) end
    
    DelveGuide.compactWidget = f
    DelveGuide.UpdateCompactWidget()
end

DelveGuide.RefreshCompactWidgetFonts = function()
    local cw = DelveGuide.compactWidget
    if not cw then return end
    local rSize = GetWidgetRSize()
    local lineH = GetLineH()
    local widgetW = GetWidgetW()
    local innerW = widgetW - 16
    local sf = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local titleFont = GameFontNormal:GetFont() or "Fonts\\FRIZQT__.TTF"

    cw:SetWidth(widgetW)
    if cw.titleFS then cw.titleFS:SetFont(titleFont, rSize + 1, "OUTLINE") end
    if cw.divider then cw.divider:SetSize(innerW, 1) end
    if cw.rotateFS then cw.rotateFS:SetFont(sf, math.max(8, rSize - 1)) end
    if cw.keysLine then cw.keysLine:SetFont(sf, rSize); cw.keysLine:SetWidth(innerW) end
    if cw.voidforgeLine then cw.voidforgeLine:SetFont(sf, rSize); cw.voidforgeLine:SetWidth(innerW) end
    if cw.varLines then
        for i = 1, W_MAX_LINES do
            local btn = cw.varLines[i]
            if btn then
                btn:SetSize(innerW, lineH)
                if btn.label then btn.label:SetFont(sf, rSize) end
            end
        end
    end
    DelveGuide.UpdateCompactWidget()
end

DelveGuide.ToggleWidget = function()
    DelveGuideDB.widgetHidden = not DelveGuideDB.widgetHidden
    local cw = DelveGuide.compactWidget
    if cw then
        -- Refresh on show: UpdateCompactWidget early-returns while hidden, so
        -- without this the widget can open showing yesterday's variants (or
        -- nothing at all, if it was hidden at login before the first scan).
        if DelveGuideDB.widgetHidden then cw:Hide() else cw:Show(); UI.UpdateCompactWidget() end
    end
    print("|cFF00BFFF[DelveGuide]|r " .. L["Compact widget:"] .. " " .. (DelveGuideDB.widgetHidden and ("|cFFFF4444" .. L["hidden"] .. "|r") or ("|cFF44FF44" .. L["shown"] .. "|r")))
end