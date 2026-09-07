local UI = DelveGuide.UI
local L = DelveGuide.L
local RANK_ORDER = UI.RANK_ORDER

-- ---- Zone names for display (review 3.4) ---------------------------------
-- Every lookup -- colours, data, SavedVariables -- keeps the ENGLISH zone key.
-- Only the text the player reads goes through here.
--
-- The English zone -> uiMapID map is built once from the entrance pins: they
-- carry a name and a mapID but no zone, so they are joined to
-- DelveGuideData.delves on the delve name.
--
-- The guard against DelveGuideData.zoneNames matters. Two of the six zone
-- labels are addon groupings rather than map names -- "Quel'Thalas" covers
-- Silvermoon City (2393) AND Eversong Woods (2395), and "Quel'Danas" is the
-- map's "Isle of Quel'Danas" -- so taking the first pin's mapID unguarded
-- would relabel those rows on an ENGLISH client too. Substituting only when
-- the addon's own English name for that mapID matches the label keeps enUS
-- byte-identical; those two zones stay English everywhere until the data
-- carries a real mapID for them.
local zoneMapID
function UI.ZoneDisplayName(englishZone)
    if not englishZone or englishZone == "" then return englishZone end
    if not zoneMapID then
        zoneMapID = {}
        local pinByName = {}
        for _, p in ipairs(DelveGuideData.mapPins or {}) do
            if p.name and p.mapID then pinByName[p.name] = pinByName[p.name] or p.mapID end
        end
        local englishNames = DelveGuideData.zoneNames or {}
        for _, d in ipairs(DelveGuideData.delves or {}) do
            local id = d.zone and pinByName[d.name]
            if id and not zoneMapID[d.zone] and englishNames[id] == d.zone then
                zoneMapID[d.zone] = id
            end
        end
    end
    local id = zoneMapID[englishZone]
    if not id or not (C_Map and C_Map.GetMapInfo) then return englishZone end
    local ok, info = pcall(C_Map.GetMapInfo, id)
    if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
        return info.name
    end
    return englishZone
end

-- UI.ZoneColor wraps the English name in its colour; peel the colour off and
-- re-wrap the display name so the colour lookup still uses the English key.
-- (UI.ZoneColor itself lives in DelveGuide.lua and is left alone.)
local function ColoredZone(englishZone)
    local wrapped = UI.ZoneColor(englishZone)
    return wrapped:sub(1, #wrapped - #englishZone - 2) .. UI.ZoneDisplayName(englishZone) .. "|r"
end

-- Variants rotate at the daily reset -- the single most-asked question about
-- the "active today" list. Read at render time only; the tab redraws on its
-- own events, so it needs no ticker.
local function RotationCountdown()
    if not (C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) then return nil end
    local ok, secs = pcall(C_DateAndTime.GetSecondsUntilDailyReset)
    if not ok or type(secs) ~= "number" or secs <= 0 then return nil end
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then return string.format(L["Rotates in %dh %dm"], h, m) end
    return string.format(L["Rotates in %dm"], m)
end

-- ---- Per-index row cache -------------------------------------------------
-- 44 delves x (5-16 widgets + 3-5 closures) was ~100 child frames and ~300
-- objects created on every RenderDelves, and the flag badges were most of it.
-- Each row's widgets are now built once and only re-anchored/re-texted, with
-- OnEnter/OnLeave/OnClick wired at creation reading whatever the render put on
-- the widget (self.pin, self.flagTip) -- the compact widget's self.pin idiom.
local delveRows = {}

local function HideDelveRow(row)
    row.fill:Hide(); row.bar:Hide()
    row.gradeFS:Hide(); row.nameBtn:Hide(); row.infoFS:Hide()
    for j = 1, #row.badges do row.badges[j].btn:Hide() end
end

UI.AddCacheReset(function()
    for i = 1, #delveRows do HideDelveRow(delveRows[i]) end
end)

local function GetDelveRow(parent, i)
    local row = delveRows[i]
    if row then return row end

    row = { badges = {} }
    row.fill = parent:CreateTexture(nil, "BACKGROUND")
    row.fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    row.bar = parent:CreateTexture(nil, "ARTWORK")
    row.bar:SetColorTexture(0, 1, 0.2, 1)

    row.gradeFS = parent:CreateFontString(nil, "OVERLAY")
    row.gradeFS:SetWidth(46); row.gradeFS:SetJustifyH("LEFT")

    row.nameBtn = CreateFrame("Button", nil, parent)
    row.nameFS = row.nameBtn:CreateFontString(nil, "OVERLAY")
    row.nameFS:SetAllPoints(row.nameBtn); row.nameFS:SetJustifyH("LEFT")

    row.infoFS = parent:CreateFontString(nil, "OVERLAY")
    row.infoFS:SetJustifyH("LEFT")

    -- No pin means the row was inert before this change (the old code simply
    -- never attached scripts), so every handler bails when self.pin is nil.
    row.nameBtn:SetScript("OnEnter", function(self)
        if not self.pin then return end
        row.nameFS:SetText("|cFFFFFFFF"..self.delveName.."|r")
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine("|cFFFFD700"..self.delveName.."|r")
        GameTooltip:AddLine("|cFFCCCCCC"..self.delveZone.."|r"); GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF88"..L["Click to open map & set waypoint"].."|r"); GameTooltip:Show()
    end)
    row.nameBtn:SetScript("OnLeave", function(self)
        if not self.pin then return end
        row.nameFS:SetText(self.nameText); GameTooltip:Hide()
    end)
    row.nameBtn:SetScript("OnClick", function(self)
        if self.pin then UI.SetDelveWaypoint(self.pin) end
    end)

    delveRows[i] = row
    return row
end

local function GetDelveBadge(parent, row, j)
    local badge = row.badges[j]
    if badge then return badge end

    badge = {}
    badge.btn = CreateFrame("Button", nil, parent)
    badge.fs = badge.btn:CreateFontString(nil, "OVERLAY")
    badge.fs:SetAllPoints(badge.btn); badge.fs:SetJustifyH("LEFT")
    badge.btn:SetScript("OnEnter", function(self)
        if not self.flagTip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("|cFFFFD700" .. self.flagTip .. "|r")
        GameTooltip:AddLine(self.flagDesc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    badge.btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.badges[j] = badge
    return badge
end

local function CreateDelveRow(parent, y, d, index)
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT_FILE = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    local rowW = UI.WINDOW_W - 52
    local row = GetDelveRow(parent, index)

    local activeVariants = DelveGuide.activeVariants or {}
    local active = (activeVariants[d.variant] == true)

    if active then
        row.fill:ClearAllPoints(); row.fill:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        row.fill:SetSize(rowW-4,rH+2)
        -- 0.35 read as too intense under the salmon/orange top grades; 0.22
        -- vanished on Nick's screen. 0.30 is the middle (2026-09-07).
        row.fill:SetGradient("HORIZONTAL",CreateColor(0,0.7,0.15,0.30),CreateColor(0,0.7,0.15,0))
        row.fill:Show()
        row.bar:ClearAllPoints(); row.bar:SetPoint("TOPLEFT",parent,"TOPLEFT",2,-(y-1))
        row.bar:SetSize(3,rH+2); row.bar:Show()
    else
        row.fill:Hide(); row.bar:Hide()
    end

    row.gradeFS:SetFont(ROW_FONT_FILE,rSize)
    row.gradeFS:ClearAllPoints(); row.gradeFS:SetPoint("TOPLEFT",parent,"TOPLEFT",10,-y)
    row.gradeFS:SetText(string.format("[%s]", UI.GradeColor(d.ranking)))
    row.gradeFS:Show()

    local pin = UI.FindPinByName(d.name)
    row.nameBtn:SetSize(160,rH)
    row.nameBtn:ClearAllPoints(); row.nameBtn:SetPoint("TOPLEFT",parent,"TOPLEFT",56,-y+1)
    row.nameFS:SetFont(ROW_FONT_FILE,rSize)

    local activeDelves = DelveGuide.activeDelves or {}
    local delveStatus = activeDelves[d.name]
    local isBountiful = type(delveStatus)=="table" and delveStatus.bountiful
    local nameColor = isBountiful and "|cFFFFD700" or "|cFF00CFFF"

    local nameText
    if pin then nameText = nameColor..d.name.."|r"
    else nameText = isBountiful and ("|cFFFFD700"..d.name.."|r") or d.name end
    row.nameBtn.pin       = pin
    row.nameBtn.delveName = d.name
    -- Display only (the row tooltip); nothing looks this value up.
    row.nameBtn.delveZone = UI.ZoneDisplayName(d.zone)
    row.nameBtn.nameText  = nameText
    row.nameFS:SetText(nameText)
    row.nameBtn:Show()

    local variantText=active and "|cFF44FF44"..d.variant.."|r" or d.variant

    row.infoFS:SetFont(ROW_FONT_FILE,rSize)
    row.infoFS:ClearAllPoints(); row.infoFS:SetPoint("TOPLEFT",parent,"TOPLEFT",220,-y)
    -- Drop last render's fixed width first, or GetStringWidth below measures
    -- the old box instead of this row's text.
    row.infoFS:SetWidth(0)
    row.infoFS:SetText(ColoredZone(d.zone).."  "..variantText)
    -- Let the FontString auto-size to its text content (no fixed width)
    -- so flag buttons chain correctly after the actual text
    local infoTextW = row.infoFS:GetStringWidth()
    row.infoFS:SetWidth(math.max(infoTextW + 4, 100))
    row.infoFS:Show()

    -- Interactive flag badges with hover tooltips — all tags flow in one chain
    local FLAG_DEFS = {}
    if d.isBestRoute then table.insert(FLAG_DEFS, {text="|cFF00FF00"..L["[Best]"].."|r", tip=L["Best Route"], desc=L["This variant has the fastest known clear path for speed runs."]}) end
    if d.hasBug then table.insert(FLAG_DEFS, {text="|cFFFF4444"..L["[Bug]"].."|r", tip=L["Known Bug"], desc=L["This variant has a known bug that may cause issues during the run."]}) end
    if d.mountable then table.insert(FLAG_DEFS, {text="|cFFFFD700"..L["[Mt]"].."|r", tip=L["Mountable"], desc=L["You can use your mount inside this delve to move between packs faster."]}) end
    if type(delveStatus)=="table" and delveStatus.nemesis then table.insert(FLAG_DEFS, {text="|cFFFF4444"..L["[Nemesis]"].."|r", tip=L["Nemesis Active"], desc=L["A Nemesis boss is present in this delve today -- a tougher fight with its own mechanics. See the Nemesis tab for what it does and how to handle it."]}) end
    if isBountiful then table.insert(FLAG_DEFS, {text="|cFFFFD700"..L["[Bountiful]"].."|r", tip=L["Bountiful Delve"], desc=L["This delve is Bountiful today. Use a Coffer Key to open the Bountiful Coffer for bonus loot."]}) end
    if active then table.insert(FLAG_DEFS, {text="|cFF00FF44"..L["* TODAY"].."|r", tip=L["Active Today"], desc=L["This variant is the one currently available for this delve."]}) end

    local lastAnchor = row.infoFS
    for j = 1, #FLAG_DEFS do
        local flag = FLAG_DEFS[j]
        local badge = GetDelveBadge(parent, row, j)
        badge.fs:SetFont(ROW_FONT_FILE, rSize)
        badge.fs:SetText(flag.text)
        badge.btn:SetSize(40, rH)
        badge.btn:ClearAllPoints()
        badge.btn:SetPoint("LEFT", lastAnchor, "RIGHT", lastAnchor == row.infoFS and 4 or 2, 0)
        badge.btn:SetWidth(math.max(badge.fs:GetStringWidth() + 4, 30))
        badge.btn.flagTip  = flag.tip
        badge.btn.flagDesc = flag.desc
        badge.btn:Show()
        lastAnchor = badge.btn
    end
    for j = #FLAG_DEFS + 1, #row.badges do row.badges[j].btn:Hide() end

    return rH
end

DelveGuide.RenderDelves = function()
    local cf=UI.NewContentFrame(); local y=10; local rowIndex=0
    local activeVariants = DelveGuide.activeVariants or {}
    local vc=0; for _ in pairs(activeVariants) do vc=vc+1 end
    
    -- Trovehunter's Bounty (weekly) -- state comes from the shared helper so
    -- this row and the pre-entry checklist can't disagree. IDs: DelveGuideData.trove.
    local troveState = DelveGuide.GetTroveStatus and DelveGuide.GetTroveStatus() or "none"
    local troveText = (troveState == "active")     and ("|cFF00FF44"..L["Active"].."|r")
                   or (troveState == "inBags")     and ("|cFFFFFF00"..L["In Bags"].."|r")
                   or (troveState == "weeklyDone") and ("|cFF44FF44"..L["Done this week"].."|r")
                   or ("|cFFFF4444"..L["None"].."|r")
    -- ID lives in DelveGuideData.nemesisItem, not here. It was hardcoded to the
    -- Season 1 Beacon of Hope (253342), so after 12.1 replaced it this row was
    -- counting an item nobody could obtain and always read "None".
    local NI = DelveGuideData.nemesisItem or {}
    local beaconCount = (NI.ITEM_ID and C_Item.GetItemCount(NI.ITEM_ID, true)) or 0
    local beaconText=beaconCount>0 and ("|cFF00FF44"..string.format(L["%d in Bags"],beaconCount).."|r") or ("|cFFFF4444"..L["None"].."|r")
    local restoredKeyInfo=C_CurrencyInfo.GetCurrencyInfo(DelveGuideData.cofferKeys.RESTORED_CURRENCY_ID)
    local restoredKeyCount=restoredKeyInfo and restoredKeyInfo.quantity or 0
    local restoredKeyText=restoredKeyCount>0 and ("|cFF00FF44"..string.format(L["%d in Bags"],restoredKeyCount).."|r") or ("|cFF888888"..L["None"].."|r")
    
    local activeData,inactiveData={},{}
    for _,d in ipairs(DelveGuideData.delves) do
        if activeVariants[d.variant] then table.insert(activeData,d) else table.insert(inactiveData,d) end
    end

    -- Fallback: surface any delve the scan flagged active whose current variant
    -- isn't catalogued above -- a new delve, or an S2 variant that rotates in
    -- before it's been added/ranked. Without this, a detected delve silently
    -- drops off "Active Today" just because its variant row doesn't exist yet.
    do
        local shown = {}
        for _,d in ipairs(activeData) do shown[d.name] = true end
        -- rawScanResults is keyed by the LOCALIZED delve name while activeDelves
        -- below is keyed by the English one, so on non-EN clients this lookup
        -- always missed and every fallback row read "New variant". Map across.
        local l10n = DelveGuide.localizedToEnglish or {}
        local variantByDelve = {}
        for _,r in ipairs(DelveGuide.rawScanResults or {}) do
            if r.name and type(r.variantName)=="string" then
                local v = r.variantName:gsub("^%[Missing Translation%] ","")
                if v~="" and v~="(not found)" and v~="(nil)" and v~="(nemesis)" then
                    variantByDelve[l10n[r.name] or r.name] = v
                end
            end
        end
        local zoneByName = {}
        for _,d in ipairs(DelveGuideData.delves) do zoneByName[d.name] = zoneByName[d.name] or d.zone end
        for name, st in pairs(DelveGuide.activeDelves or {}) do
            if not shown[name] then
                shown[name] = true
                table.insert(activeData, {
                    name=name, zone=zoneByName[name] or "",
                    variant=variantByDelve[name] or L["New variant"],
                    ranking="?", mountable=false, hasBug=false, isBestRoute=false,
                })
            end
        end
    end

    table.sort(activeData, function(a,b) return (RANK_ORDER[a.ranking] or 99) < (RANK_ORDER[b.ranking] or 99) end)
    
    local note=vc>0 and ("  |cFF44FF44"..string.format(L["(%d active today)"],vc).."|r") or ("  |cFFAAAAAA"..L["(use /dg scan)"].."|r")
    local rotate=RotationCountdown()
    if rotate then note=note.."  |cFF888888"..rotate.."|r" end
    -- Hover target over the ranking header. Three CurseForge threads asked what
    -- S-F actually measures, so the answer lives on the header itself rather
    -- than on every row.
    local headerY=y
    local headerH=UI.CreateHeader(cf,headerY,L["Delve Rankings -- S=Fastest | F=Slowest"].." |cFF888888[?]|r"..note)
    local gradeHelp=UI.AcquireButton()
    gradeHelp:SetPoint("TOPLEFT",cf,"TOPLEFT",8,-headerY)
    -- Clamped so a big font scale can't slide the hover region under the
    -- "What are Delves?" button in the top-right corner.
    gradeHelp:SetSize(math.min(math.floor(340*(DelveGuideDB.fontScale or 1)),math.max(80,cf:GetWidth()-60)),headerH)
    gradeHelp:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine("|cFFFFD700"..L["How grades work"].."|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["S = fastest, F = slowest."],1,1,1,true)
        -- Whole sentences for translators; the coloured bits go in as arguments.
        GameTooltip:AddLine(string.format(L["Grades come from timed runs players sent in with %s -- not from how hard a delve is."],"|cFFFFFF00/dg submit|r"),1,1,1,true)
        GameTooltip:AddLine(L["Only Tier 8 and above count."],1,1,1,true)
        GameTooltip:AddLine(string.format(L["A %s grade means not enough runs yet."],"|cFF888888[?]|r"),1,1,1,true)
        GameTooltip:Show()
    end)
    gradeHelp:SetScript("OnLeave",function() GameTooltip:Hide() end)
    y=y+headerH+4
    local rs=DelveGuideData.rankingStats
    if rs then
        -- One sentence for translators: each coloured figure closes and re-opens
        -- the surrounding grey itself, so the rendered bytes are unchanged.
        local subsPart   = "|r|cFF00FF88"..(rs.submissions or 0).."|r|cFF888888"
        local submitPart = "|r|cFFFFFF00/dg submit|r|cFF888888"
        y=y+UI.CreateRow(cf,y,"|cFF888888"..string.format(
            L["Community-timed from %s player submissions -- add yours with %s. Credits in Settings."],
            subsPart, submitPart).."|r")
    end
    -- The item names in this row are game data and stay English keys.
    y=y+UI.CreateRow(cf,y,"|cFF3088FF"..L["Weekly Items:"].."|r"..string.format("  Trovehunter's Bounty: %s   |   %s: %s   |   Restored Coffer Key: %s",
        troveText, (DelveGuideData.nemesisItem and DelveGuideData.nemesisItem.NAME) or "Nemesis Item", beaconText, restoredKeyText))
    
    local delveCount,_,_,vaultActs=UI.GetWeeklyVaultData()
    if #vaultActs>0 then
        local parts={}
        for _,a in ipairs(vaultActs) do
            local done=a.progress>=a.threshold
            local tierNum=a.level and a.level>0 and a.level or nil
            -- Prefer the real reward item level Blizzard reports for this slot;
            -- the per-tier table is only a fallback (and can't know which of
            -- your activities actually decides the slot).
            local reward=tierNum and DelveGuideData.tierRewards and DelveGuideData.tierRewards[tierNum]
            local ilvlText=a.rewardIlvl and ("|cFFFFD700"..string.format(L["%s ilvl"],a.rewardIlvl).."|r")
                or (reward and ("|cFFFFD700"..string.format(L["%s ilvl"],reward.vault).."|r"))
                or (tierNum and ("|cFFFFD700"..string.format(L["T%s"],tierNum).."|r")) or "|cFF888888?|r"
            if done then
                table.insert(parts,"|cFF00FF44"..string.format(L["Slot %d"],a.index or #parts+1).."|r ("..ilvlText..")")
            else
                table.insert(parts,"|cFF888888"..string.format(L["Slot %d:"],a.index or #parts+1).."|r "..string.format(L["%d/%d needed"],a.progress,a.threshold))
            end
        end
        y=y+UI.CreateRow(cf,y,"|cFF3088FF"..L["Great Vault:"].."|r  "..string.format(L["%d delve(s) this week"],delveCount).."  --  "..table.concat(parts,"  |  "))
    end
    y=y+8

    -- "What are Delves?" hover tooltip — subtle "?" near header
    local helpBtn = UI.AcquireButton()
    helpBtn:SetSize(16, 16) -- size is immaterial since the FontString fills the button and handles mouse events
    helpBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -8, -8)
    local helpFS = UI.AcquireFontString("OVERLAY")
    helpFS:SetFont(GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF", 21, "OUTLINE", "BOLD")
    helpFS:SetAllPoints(helpBtn); helpFS:SetJustifyH("CENTER")
    helpFS:SetText("|cFF777777?|r")
    helpBtn:SetScript("OnEnter", function(self)
        helpFS:SetText("|cFFFFFFFF?|r")
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700"..L["What are Delves?"].."|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Short 1-5 player mini-dungeons across Quel'Thalas."], 1, 1, 1, true)
        GameTooltip:AddLine(L["No role requirements - bring any spec, any class."], 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFFD700"..L["Variants:"].."|r "..L["Each delve has rotating story variants that change daily."], 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700"..L["Tiers:"].."|r "..L["1-11 control difficulty. Tier 8+ end-of-run gear is Champion-track (295 ilvl)."], 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700"..L["Bountiful:"].."|r "..L["Marked delves that drop bonus loot when opened with a Restored Coffer Key."], 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700"..L["Coffer Keys:"].."|r "..string.format(L["Earn Coffer Key Shards (%d/week cap) - %d shards = 1 key."],
            DelveGuideData.cofferKeys.SHARD_WEEKLY_CAP, DelveGuideData.cofferKeys.SHARDS_PER_KEY), 1, 1, 1, true)
        GameTooltip:AddLine("|cFFFFD700"..L["Great Vault:"].."|r "..L["2/4/8 delves unlock vault slots. Tier 8+ gives Hero-track (305 ilvl) vault rewards."], 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        -- These two lines are one sentence split across two AddLine calls; kept
        -- split so the wrapped rendering is unchanged. The companion name is a
        -- format argument because it is game data, not text to translate.
        GameTooltip:AddLine(string.format(L["Your companion %s joins every run. Set her role (DPS/Healer/Tank)"], "Valeera"), 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(L["at Restoration Stones inside the delve. She levels up as you play."], 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    helpBtn:SetScript("OnLeave", function() helpFS:SetText("|cFF777777?|r"); GameTooltip:Hide() end)

    -- Share to Chat button
    local shareBtn = UI.AcquirePanelButton()
    shareBtn:SetSize(110, 20)
    shareBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -10, -(y - 2))
    shareBtn:SetText(L["Share to Party"])
    shareBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    shareBtn:SetScript("OnClick", function(_, button)
        local channel = (button == "RightButton") and "GUILD" or "PARTY"
        DelveGuide.ShareActiveVariants(channel)
    end)
    shareBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFD700"..L["Share Active Variants"].."|r")
        GameTooltip:AddLine(L["Left-click: Share to Party"], 0.7, 1, 0.7)
        GameTooltip:AddLine(L["Right-click: Share to Guild"], 0.5, 0.7, 1)
        GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    y=y+UI.CreateRow(cf,y,"|cFFAAAAAA"..string.format("%-6s  %-22s  %-14s  %s",L["Rank"],L["Delve"],L["Zone"],L["Variant / Flags"]).."|r")
    y=y+UI.CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+2
    if vc>0 then
        y=y+4; y=y+UI.CreateRow(cf,y,"|cFF00FF44"..L["-- * ACTIVE TODAY --"].."|r")
        for _,d in ipairs(activeData) do rowIndex=rowIndex+1; y=y+CreateDelveRow(cf,y,d,rowIndex) end
        y=y+12; y=y+UI.CreateRow(cf,y,"|cFF888888"..L["-- ALL VARIANTS (INACTIVE) --"].."|r")
    end
    local lastZone=""
    for _,d in ipairs(inactiveData) do
        -- Grouping still compares the English zone; only the label is translated.
        if d.zone~=lastZone then y=y+4; y=y+UI.CreateRow(cf,y,"|cFF666666"..string.format(L["-- %s --"],UI.ZoneDisplayName(d.zone)).."|r"); lastZone=d.zone end
        rowIndex=rowIndex+1; y=y+CreateDelveRow(cf,y,d,rowIndex)
    end
    cf:SetHeight(y+20)
end