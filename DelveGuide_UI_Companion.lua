-- ============================================================
-- DelveGuide_UI_Companion.lua
-- ============================================================
local UI = DelveGuide.UI
local L = DelveGuide.L

local function GetSpecRec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    local specID = select(1, GetSpecializationInfo(idx))
    if not specID then return nil end
    return DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID], specID
end

-- Shared with the Curios and Nemesis tabs so the three screens cannot disagree
-- about which Valeera role a spec wants. The Curios tab used to carry a
-- byte-for-byte copy of the function above.
UI.GetSpecRec = GetSpecRec

-- Auto-discovery for Valeera's reputation/renown track. Caches the hit in
-- SavedVariables so we only scan once per character. "major" = C_MajorFactions
-- (renown track); "rep" = regular reputation bar.
--
-- The name sweep below used to be the ONLY filter, which made this tab
-- English-only: ruRU/zhCN/zhTW/koKR transliterate "Valeera Sanguinar", so
-- nothing ever matched and the renown line never appeared. It was also the
-- expensive path -- three sweeps of 501 pcall'd calls, 1,503 per render -- and
-- a miss was never written anywhere, so every render re-ran the whole thing.
-- Resolution order is now: Blizzard's own resolver, then the known constant,
-- then the sweep as a last resort, with misses cached for the session.
local sweepMissed = false   -- session-only: a /reload retries in case the
                            -- companion track has been unlocked since.

local function CacheFaction(id, ftype)
    if DelveGuideDB then
        DelveGuideDB.companionFactionID = id
        DelveGuideDB.companionFactionType = ftype
    end
    return id, ftype
end

local function FindCompanionFactionID()
    if DelveGuideDB and DelveGuideDB.companionFactionID then
        return DelveGuideDB.companionFactionID, DelveGuideDB.companionFactionType
    end

    -- 1. Blizzard's own resolver -- Blizzard_DelvesCompanionConfiguration.lua
    --    maps the active companion to its faction exactly this way. Locale
    --    independent, and one call instead of 1,503.
    if C_DelvesUI and C_DelvesUI.GetFactionForCompanion and C_DelvesUI.GetCompanionInfoForActivePlayer then
        local ok, id = pcall(function()
            return C_DelvesUI.GetFactionForCompanion(C_DelvesUI.GetCompanionInfoForActivePlayer())
        end)
        if ok and type(id) == "number" and id > 0 then
            return CacheFaction(id, "friendship")
        end
    end

    -- 2. The known constant (Valeera Sanguinar = 2744, confirmed in the 12.1.5
    --    faction sweep). Probed rather than trusted blind, so a season that
    --    moves the companion falls through instead of reporting a dead track.
    local constID = DelveGuideData and DelveGuideData.companionFactionID
    if constID and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, constID)
        if ok and d and d.friendshipFactionID and d.friendshipFactionID > 0 then
            return CacheFaction(constID, "friendship")
        end
    end

    -- 3. Last resort: the English-only name sweep. Only reached when both the
    --    API and the constant fail, and only once per session.
    if sweepMissed then return nil, nil end

    local function nameMatches(n)
        if not n then return false end
        return n:find("Valeera") or n:find("Sanguinar")
    end

    -- Friendship factions (Valeera / Brann-style companion tracks) match first,
    -- since the underlying reputation API would also match but returns the
    -- wrong (1-8 reaction) level.
    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        for id = 2600, 3100 do
            local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, id)
            if ok and d and d.friendshipFactionID and d.friendshipFactionID > 0 and nameMatches(d.name) then
                return CacheFaction(id, "friendship")
            end
        end
    end

    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        for id = 2600, 3100 do
            local ok, d = pcall(C_MajorFactions.GetMajorFactionData, id)
            if ok and d and nameMatches(d.name) then
                return CacheFaction(id, "major")
            end
        end
    end

    if C_Reputation and C_Reputation.GetFactionDataByID then
        for id = 2600, 3100 do
            local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
            if ok and d and nameMatches(d.name) then
                return CacheFaction(id, "rep")
            end
        end
    end

    sweepMissed = true
    return nil, nil
end

-- Renown can live in three different APIs depending on the faction type:
--   major      -- C_MajorFactions (e.g. Dornogal renown)
--   friendship -- C_GossipInfo.GetFriendshipReputation (Brann, Valeera style,
--                 80-level XP track with a rankInfo.currentLevel)
--   rep        -- plain reputation (Hated..Exalted, 1-8 reaction)
-- Companion tracks (Valeera Sanguinar = faction 2744) are friendship-style,
-- so QueryFriendship must be tried FIRST -- the plain reputation API also
-- returns data for these factions, but reports reaction=8 (Exalted) instead
-- of the real 80-level rank.

local function QueryFriendship(id)
    if not (C_GossipInfo and C_GossipInfo.GetFriendshipReputation) then return nil end
    local ok, d = pcall(C_GossipInfo.GetFriendshipReputation, id)
    if not (ok and d and d.friendshipFactionID and d.friendshipFactionID > 0) then return nil end

    local floor   = d.reactionThreshold or 0
    local ceil    = d.nextThreshold or (floor + 1)
    local cur     = (d.standing or floor) - floor
    local max     = math.max(1, ceil - floor)

    -- Level extraction: companion-style friendships (e.g. Valeera 2744) don't
    -- populate d.rankInfo.currentLevel. The rank number lives in d.reaction
    -- as a localised string like "Level 38", with d.text mirroring it
    -- ("Valeera Sanguinar reached Level 38."). Try the structured field first
    -- for forward compatibility, then pattern-match the strings.
    local level = 0
    if d.rankInfo and d.rankInfo.currentLevel then
        level = d.rankInfo.currentLevel
    elseif type(d.reaction) == "string" then
        level = tonumber(d.reaction:match("(%d+)")) or 0
    end
    if level == 0 and type(d.text) == "string" then
        level = tonumber(d.text:match("(%d+)")) or 0
    end

    return {
        level     = level,
        current   = cur,
        max       = max,
        name      = (d.name and d.name ~= "") and d.name or nil,
        factionID = id,
        ftype     = "friendship",
    }
end

local function QueryMajor(id)
    if not (C_MajorFactions and C_MajorFactions.GetMajorFactionData) then return nil end
    local ok, d = pcall(C_MajorFactions.GetMajorFactionData, id)
    if ok and d and d.name and d.name ~= "" then
        return {
            level     = d.renownLevel or 0,
            current   = d.renownReputationEarned or 0,
            max       = (d.renownLevelThreshold and d.renownLevelThreshold > 0)
                         and d.renownLevelThreshold or 1,
            name      = d.name,
            factionID = id,
            ftype     = "major",
        }
    end
end

local function QueryRep(id)
    if not (C_Reputation and C_Reputation.GetFactionDataByID) then return nil end
    local ok, d = pcall(C_Reputation.GetFactionDataByID, id)
    if ok and d and d.name and d.name ~= "" then
        local floor = d.currentReactionThreshold or 0
        local ceil  = d.nextReactionThreshold or (floor + 1)
        local cur   = (d.currentStanding or floor) - floor
        local max   = math.max(1, ceil - floor)
        return {
            level     = d.reaction or 0,
            current   = cur,
            max       = max,
            name      = d.name,
            factionID = id,
            ftype     = "rep",
        }
    end
end

local function GetCompanionRenown()
    local id, ftype = FindCompanionFactionID()
    if not id then return nil end

    -- Try friendship FIRST -- it returns nil for non-friendship factions, so
    -- it's a harmless probe, but it's the only API that exposes the 80-level
    -- companion XP track for Valeera.
    local result = QueryFriendship(id)
    if not result then
        if ftype == "rep" then
            result = QueryRep(id) or QueryMajor(id)
        else
            result = QueryMajor(id) or QueryRep(id)
        end
    end

    if result and DelveGuideDB and result.ftype ~= ftype then
        DelveGuideDB.companionFactionType = result.ftype
    end
    return result
end

-- ============================================================
-- LIVE LOADOUT -- read from Valeera's trait nodes (12.1)
-- ------------------------------------------------------------
-- What this replaces. RenderCompanion used to learn the equipped role and
-- curios by walking Blizzard's DelvesCompanionConfigurationFrame and comparing
-- every FontString it found against fixed strings (that scrape is still below,
-- as the fallback). Two things were wrong with it:
--
--   * It preferred a child named `CompanionConfigInfo`, which does not exist.
--     The frame's direct children on 12.1.5 are Border, CloseButton,
--     CompanionPortraitFrame, CompanionExperienceRingFrame,
--     CompanionLevelFrame, CompanionInfoFrame, CompanionSlots and
--     CompanionConfigShowAbilitiesButton -- so that branch was dead code and
--     the walk always started at the whole frame instead.
--   * Every match was an English literal ("Healer", "DPS", "Tank", plus curio
--     names out of DelveGuideData). On a deDE/frFR/ruRU/zhCN client nothing
--     ever matched: the role stayed "Unknown" and no curio was detected. It
--     also only worked while Blizzard's panel happened to be open on screen.
--
-- The node path below is exactly what Blizzard's own panel does
-- (Blizzard_DelvesCompanionConfiguration.lua): companion -> trait tree ->
-- config -> node -> activeEntry -> entry -> definition -> spell. It is
-- READ-ONLY -- nothing here writes to a trait configuration, so none of the
-- taint exposure a write path would carry -- and it is locale independent,
-- because what we compare on is a spell ID, not a name.
--
-- Every call is existence-checked and pcall wrapped. On a build where any of
-- them is missing the whole thing returns nil and the scrape runs as before.
--
-- API provenance (all verified against the 12.1.5 / build 69594 generated docs
-- in Gethe/wow-ui-source `ptr`, the same source as API_12.1.5_Research.md):
--   C_DelvesUI.GetCompanionInfoForActivePlayer()          -> companionID
--   C_DelvesUI.GetTraitTreeForCompanion(companionID)      -> treeID
--   C_DelvesUI.GetRoleNodeForCompanion(companionID)       -> nodeID
--   C_DelvesUI.GetRoleSubtreeForCompanion(roleType, cID)  -> subTreeID
--   C_DelvesUI.GetCurioNodeForCompanion(curioType, cID)   -> nodeID
--   C_Traits.GetConfigIDByTreeID / GetNodeInfo / GetEntryInfo / GetDefinitionInfo
--   C_Spell.GetSpellName(spellID)
-- Note GetRoleNodeForCompanion takes the companion ID ALONE, and
-- GetCurioNodeForCompanion takes the curio type FIRST.
-- ============================================================

local function TryCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if ok then return v end
    return nil
end

-- Enum.CompanionRoleType = { Dps=0, Heal=1, Tank=2 } and
-- Enum.CurioType = { Combat=0, Utility=1 } on build 69594. Read from Enum when
-- it is there so a re-numbering follows the client; the observed values are the
-- fallback for a build that does not expose the enum.
local function EnumValue(enumName, key, fallback)
    local e = Enum and Enum[enumName]
    local v = e and e[key]
    if type(v) == "number" then return v end
    return fallback
end

-- `label` is OUR word for the role and matches
-- DelveGuideData.specCurioRecs[*].companion, so the recommendation compare in
-- RenderCompanion never touches a client string.
local ROLE_TYPES = {
    { key = "Dps",  label = "Damage Dealer", fallback = 0 },
    { key = "Heal", label = "Healer",        fallback = 1 },
    { key = "Tank", label = "Tank",          fallback = 2 },
}

-- `label` matches DelveGuideData.curios[*].curiotype.
local CURIO_TYPES = {
    { key = "Combat",  label = "Combat",  fallback = 0 },
    { key = "Utility", label = "Utility", fallback = 1 },
}

-- companionID plus the trait config that holds her nodes. Returns nil when
-- there is no active companion, and companionID with no config when the trait
-- lookup is unavailable.
local function NoSay() end

-- Blizzard's companion frame calls the C_DelvesUI lookups with NO companion
-- ID whenever its own is unset ("DelvesUI accessors will default to the
-- active mirror data companion otherwise" -- Blizzard_DelvesCompanionConfiguration.lua).
-- GetTraitTreeForCompanion(12) returned 0 on the PTR with the panel open and
-- closed alike, so the ID from GetCompanionInfoForActivePlayer may not be the
-- ID these accessors want. Try with the ID, then without.
local function Positive(v) return (type(v) == "number" and v > 0) and v or nil end
local function GetCompanionConfig(say)
    say = say or NoSay
    if not C_DelvesUI then say("C_DelvesUI missing"); return nil end
    local compID = TryCall(C_DelvesUI.GetCompanionInfoForActivePlayer)
    say("GetCompanionInfoForActivePlayer ->", compID)
    if type(compID) ~= "number" or compID <= 0 then return nil end
    if not C_Traits then say("C_Traits missing"); return compID end
    local treeID = Positive(TryCall(C_DelvesUI.GetTraitTreeForCompanion, compID))
    say("GetTraitTreeForCompanion(" .. tostring(compID) .. ") ->", treeID)
    if not treeID then
        treeID = Positive(TryCall(C_DelvesUI.GetTraitTreeForCompanion, nil))
        say("GetTraitTreeForCompanion(nil) ->", treeID)
    end
    local configID
    if treeID then
        configID = TryCall(C_Traits.GetConfigIDByTreeID, treeID)
        say("GetConfigIDByTreeID ->", configID, "(", type(C_Traits.GetConfigIDByTreeID), ")")
    end
    -- The tree reads 0 until the server has sent this session's companion
    -- config, which happens when the companion panel opens: Blizzard's own
    -- frame makes these same two calls in its OnShow and never earlier
    -- (PTR trace, 2026-09-07: companion 12, tree 0, panel closed). The IDs
    -- are constants for a companion, so remember them the first time they
    -- resolve and use the memory when the live read comes back empty.
    if type(configID) == "number" and configID > 0 then
        if DelveGuideDB then
            DelveGuideDB.companionConfig = { companionID = compID, treeID = treeID, configID = configID }
        end
        return compID, configID
    end
    local cached = DelveGuideDB and DelveGuideDB.companionConfig
    if cached and cached.companionID == compID and type(cached.configID) == "number" then
        say("live read empty; using remembered configID", cached.configID)
        return compID, cached.configID
    end
    return compID
end

-- What is socketed in one node right now, or nil for an empty/unreadable node.
local function ReadActiveEntry(configID, nodeID)
    if type(nodeID) ~= "number" or nodeID <= 0 then return nil end
    local nodeInfo = TryCall(C_Traits.GetNodeInfo, configID, nodeID)
    local activeEntry = nodeInfo and nodeInfo.activeEntry
    local entryID = activeEntry and activeEntry.entryID
    if type(entryID) ~= "number" then return nil end

    local out = { entryID = entryID }
    local entryInfo = TryCall(C_Traits.GetEntryInfo, configID, entryID)
    if entryInfo then
        out.subTreeID = entryInfo.subTreeID
        if entryInfo.definitionID then
            local def = TryCall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
            if def then
                -- Same precedence Blizzard's own panel uses: an override wins.
                out.spellID = def.overriddenSpellID or def.spellID
                out.name    = def.overrideName
            end
        end
    end
    if not out.name and out.spellID and C_Spell then
        out.name = TryCall(C_Spell.GetSpellName, out.spellID)
    end
    return out
end

-- Read-only snapshot of what the active companion actually has socketed.
-- Returns nil when the node path is unavailable; it never errors.
--   { companionID, configID,
--     role   = { entryID, spellID, name, subTreeID, roleType, roleLabel },
--     curios = { Combat = {...}, Utility = {...} } }
-- In-game check:  /dump DelveGuide.ReadCompanionLoadout()
-- Pass true to print every step to chat; the first PTR call returned nil with
-- nothing to say about why. /run DelveGuide.ReadCompanionLoadout(true)
function DelveGuide.ReadCompanionLoadout(verbose)
    local say = verbose and function(...) print("|cFF00BFFF[DelveGuide]|r", ...) end or NoSay
    local compID, configID = GetCompanionConfig(say)
    say("GetNodeInfo:", type(C_Traits and C_Traits.GetNodeInfo))
    if not (compID and configID and C_Traits and C_Traits.GetNodeInfo) then say("-> nil: no config"); return nil end

    local out = { companionID = compID, configID = configID, curios = {} }

    -- Role. The active entry carries the subtree it belongs to, and
    -- GetRoleSubtreeForCompanion names one subtree per role, so the role falls
    -- out of an ID compare -- no client string at any step.
    local roleNode = Positive(TryCall(C_DelvesUI.GetRoleNodeForCompanion, compID))
                  or Positive(TryCall(C_DelvesUI.GetRoleNodeForCompanion, nil))
    local roleEntry = ReadActiveEntry(configID, roleNode)
    say("role node", roleNode, "entry", roleEntry and roleEntry.entryID, "subTree", roleEntry and roleEntry.subTreeID, "name", roleEntry and roleEntry.name)
    if roleEntry then
        for _, r in ipairs(ROLE_TYPES) do
            local roleType  = EnumValue("CompanionRoleType", r.key, r.fallback)
            local subTreeID = Positive(TryCall(C_DelvesUI.GetRoleSubtreeForCompanion, roleType, compID))
                           or Positive(TryCall(C_DelvesUI.GetRoleSubtreeForCompanion, roleType, nil))
            if subTreeID and roleEntry.subTreeID and subTreeID == roleEntry.subTreeID then
                roleEntry.roleType  = roleType
                roleEntry.roleLabel = r.label
                break
            end
        end
        out.role = roleEntry
    end

    for _, c in ipairs(CURIO_TYPES) do
        local curioType = EnumValue("CurioType", c.key, c.fallback)
        local nodeID    = Positive(TryCall(C_DelvesUI.GetCurioNodeForCompanion, curioType, compID))
                       or Positive(TryCall(C_DelvesUI.GetCurioNodeForCompanion, curioType, nil))
        out.curios[c.label] = ReadActiveEntry(configID, nodeID)
        local e = out.curios[c.label]
        say(c.label, "type", curioType, "node", nodeID, "entry", e and e.entryID, "spell", e and e.spellID, "name", e and e.name)
    end

    if not (out.role or out.curios.Combat or out.curios.Utility) then say("-> nil: no role and no curio read"); return nil end
    return out
end

-- DelveGuideData.curios[*].id is the curio's spell ID, so a socketed entry is
-- identified by ID first. The English name compare is only the last resort --
-- it is all the old scrape could ever do, and it never matched off enUS.
local function MatchCurio(entry)
    if not (entry and DelveGuideData and DelveGuideData.curios) then return nil end
    if entry.spellID then
        for _, c in ipairs(DelveGuideData.curios) do
            if c.id and c.id == entry.spellID then return c end
        end
    end
    if entry.name then
        for _, c in ipairs(DelveGuideData.curios) do
            if c.name == entry.name then return c end
        end
    end
    return nil
end

DelveGuide.RenderCompanion = function()
    local cf = UI.NewContentFrame()
    local y = 10
    UI.EnsureFontFiles(); local _, rSize, rH = UI.GetScaledSizes()
    local ROW_FONT = GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"

    y = y + UI.CreateHeader(cf, y, L["Companion  --  XP, Role & Live Curio Loadout"]) + 8

    -- 1. Fetch initial API Data
    local compID = nil
    local compName = L["Companion"]
    local compLevel, compXP, compMaxXP = 0, 0, 1
    -- NOT wrapped: `roleStr` is compared against "Unknown" below (foundRole), and
    -- its other values are either ROLE_TYPES labels -- which must stay raw for the
    -- specCurioRecs compare -- or a client string. Wrapping it would break both.
    local roleStr = "Unknown"

    pcall(function()
        if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then
            compID = C_DelvesUI.GetCompanionInfoForActivePlayer()
        end
        if compID and compID > 0 then
            compName = (compID == 11) and "Valeera Sanguinar" or L["Companion"]
            if C_DelvesUI.GetCompanionInfo then
                local info = C_DelvesUI.GetCompanionInfo(compID)
                if info then
                    compLevel = info.level or 0
                    compXP = info.experience or 0
                    compMaxXP = info.maxExperience or 1
                end
            end
        end
    end)

    -- Prefer faction/renown data when available -- works outside of delves,
    -- unlike C_DelvesUI.GetCompanionInfo which is only populated in-instance.
    local renown = GetCompanionRenown()
    if renown then
        compLevel  = renown.level
        compXP     = renown.current
        compMaxXP  = renown.max
        if renown.name and renown.name ~= "" then compName = renown.name end
        if not compID or compID == 0 then compID = 11 end
    end

    -- 2. Live loadout. Preferred path is the trait-node read above: locale
    -- independent, and it does not care whether Blizzard's panel is open.
    local liveCombat, liveUtility
    local liveSource            -- "node" once the node read supplied anything
    local roleFromNode = false  -- true only when the role came from an ID compare

    local loadout = DelveGuide.ReadCompanionLoadout()
    if loadout then
        liveSource = "node"
        if loadout.role then
            if loadout.role.roleLabel then
                roleStr = loadout.role.roleLabel
                roleFromNode = true
            elseif loadout.role.name then
                -- Subtree compare came up empty (a role Blizzard added since):
                -- show the localised entry name, but do NOT treat it as a role
                -- key -- the mismatch warning below stays silent rather than
                -- comparing a client string against our English label.
                roleStr = loadout.role.name
            end
        end
        local combat  = loadout.curios.Combat
        local utility = loadout.curios.Utility
        local mc, mu  = MatchCurio(combat), MatchCurio(utility)
        liveCombat  = (mc and mc.name) or (combat and combat.name)
        liveUtility = (mu and mu.name) or (utility and utility.name)
        if not compID or compID == 0 then compID = loadout.companionID end
    end

-- 2b. UI SCRAPING -- FALLBACK ONLY. English-only and panel-only (see the long
-- note above the node read); it now runs only when the node path returned
-- nothing, or when the level is still unknown, which is the one thing the
-- scrape reads that the node path does not. `foundRole` is seeded from what the
-- node read already established so the scrape cannot overwrite it, and the
-- curio matches below are already first-match-wins.
    local foundRole = (roleStr ~= "Unknown") -- Flag to prevent overwriting the role

    local function ScrapeUI(frame)
        if not frame or frame:IsForbidden() then return end
        
        local fName = frame:GetName() or ""
        if fName:find("ScrollBox") or fName:find("DropDownList") then return end
        
        -- Scan all text on the frame
        for _, r in ipairs({frame:GetRegions()}) do
            if r:GetObjectType() == "FontString" and r:IsShown() then
                local txt = r:GetText()
                if txt and txt ~= "" then
                    local cleanTxt = DelveGuide.StripEscapes(txt)
                    
                    -- Detect Role (Lock in the FIRST match)
                    if not foundRole and (cleanTxt == "Healer" or cleanTxt == "DPS" or cleanTxt == "Damage Dealer" or cleanTxt == "Tank") then
                        roleStr = cleanTxt
                        foundRole = true
                    end
                    
                    -- Detect Level (Lock in the FIRST match)
                    local num = tonumber(cleanTxt)
                    if num and num > 0 and num < 100 then
                        if compLevel == 0 then compLevel = num end
                    end
                    
                    -- Detect Curios (Lock in the FIRST match for each type)
                    if DelveGuideData and DelveGuideData.curios then
                        for _, c in ipairs(DelveGuideData.curios) do
                            if cleanTxt == c.name then
                                if c.curiotype == "Combat" and not liveCombat then 
                                    liveCombat = c.name 
                                end
                                if c.curiotype == "Utility" and not liveUtility then 
                                    liveUtility = c.name 
                                end
                            end
                        end
                    end
                end
            end
        end
        -- Recurse through allowed child frames
        for _, child in ipairs({frame:GetChildren()}) do
            ScrapeUI(child)
        end
    end

    -- Trigger the scrape if the Blizzard UI is open and the node read left
    -- something unanswered.
    local blizzFrame = _G["DelvesCompanionConfigurationFrame"]
    if (not liveSource or compLevel == 0) and blizzFrame and blizzFrame:IsShown() then
        if not compID or compID == 0 then compID = 11; compName = "Valeera Sanguinar" end
        
        -- The scrape walks Blizzard's own frame tree, which we don't control: a
        -- forbidden or unexpected child throws, and that error used to abort this
        -- render with the tab half-drawn. Contain it -- whatever the walk read
        -- before it threw is kept, and the rest of the tab still draws from the
        -- API/renown values gathered above.
        local ok, err
        -- CompanionConfigInfo is not a child of this frame on 12.1.5 (see the
        -- header note), so this first branch never fires; kept in case a future
        -- build adds it.
        if blizzFrame.CompanionConfigInfo then
            ok, err = pcall(ScrapeUI, blizzFrame.CompanionConfigInfo)
        else
            ok, err = pcall(ScrapeUI, blizzFrame)
        end
        if not ok then DelveGuide.lastScrapeError = err end
    end
    -- 3. Draw Header
    y = y + UI.CreateRow(cf, y, "|cFF00BFFF" .. compName .. "|r  -  " .. string.format(L["Level %s  -  Role: %s"],
        "|cFFFFD700" .. compLevel .. "|r", "|cFF00FF44" .. roleStr .. "|r")) + 6

    -- 4. Draw XP Progress Bar
    local barW = UI.WINDOW_W - 32; local barH = 20
    local xpBg = UI.AcquireTexture("BACKGROUND")
    xpBg:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    xpBg:SetSize(barW, barH); xpBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local xpFill = UI.AcquireTexture("ARTWORK")
    xpFill:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -y)
    local fillPct = math.min(1, math.max(0, compXP / compMaxXP))
    xpFill:SetSize(math.max(1, barW * fillPct), barH)
    xpFill:SetColorTexture(0.5, 0.2, 0.9, 0.8)

    local xpBorder = UI.AcquireBackdropFrame()
    xpBorder:SetPoint("TOPLEFT", cf, "TOPLEFT", 6, -(y - 2))
    xpBorder:SetSize(barW + 4, barH + 4)
    xpBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    xpBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local xpText = UI.AcquireFontString("OVERLAY")
    xpText:SetFont(ROW_FONT, rSize)
    xpText:SetPoint("CENTER", xpBg, "CENTER", 0, 0)
    
    if compMaxXP > 1 then
        xpText:SetText(string.format(L["%d / %d XP  (%.1f%%)"], compXP, compMaxXP, fillPct * 100))
    else
        xpText:SetText("|cFF888888" .. string.format(L["XP Data unavailable  -  try %s"], "/dg companionscan") .. "|r")
    end
    y = y + barH + 20

    -- 5. Curio loadout: recommended Valeera role (still valid) plus whatever the
    -- live scan detects equipped. Per-spec S2 curio picks are pending (S1's are
    -- gone), so equipped curios show as info; the Curios tab is the full S2
    -- curio + poison reference.
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- " .. L["Curio Loadout"] .. " --|r") + 4

    local rec, specID = GetSpecRec()
    if rec then
        y = y + UI.CreateRow(cf, y, string.format(L["Your Spec: %s  --  Recommended Valeera role: %s"],
            "|cFFFFFFFF" .. rec.spec .. "|r", "|cFF00CFFF" .. (rec.companion or "--") .. "|r")) + 6
    end

    -- Role mismatch. Only raised when the live role came from the subtree ID
    -- compare: both sides are then our own English labels, so this is a real
    -- disagreement rather than a failed string match on a translated client.
    if rec and rec.companion and roleFromNode and roleStr ~= rec.companion then
        y = y + UI.CreateRow(cf, y, "|cFFFF4444" .. L["Mismatch:"] .. "|r " .. string.format(L["Valeera is set to %s but this spec wants %s."],
            "|cFFFFD700" .. roleStr .. "|r", "|cFF00CFFF" .. rec.companion .. "|r")) + 6
    end

    if liveCombat or liveUtility then
        y = y + UI.CreateRow(cf, y, "|cFF00FF88" .. L["Equipped now:"] .. "|r  " .. string.format(L["Combat: %s   Utility: %s"],
            "|cFFFFD700" .. (liveCombat or "--") .. "|r", "|cFFFFD700" .. (liveUtility or "--") .. "|r"))
    elseif liveSource then
        y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["No curios socketed -- open Valeera's supplies menu to slot one."] .. "|r")
    else
        y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Open Blizzard's Companion panel, then reopen this tab to scan your equipped curios."] .. "|r")
    end
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Full Season 2 curio & poison list: the Curios tab."] .. "|r") + 4

    -- 6. Poisons (new 12.1 choice node in Valeera's supplies menu -- independent
    -- of her role). Rendered from DelveGuideData.poisons (same as the Curios tab).
    y = y + 8
    y = y + UI.CreateRow(cf, y, "|cFFFFD700-- " .. L["Poisons  (new in 12.1)"] .. " --|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888" .. L["Pick one in Valeera's supplies menu -- independent of her role now."] .. "|r") + 6
    for _, p in ipairs(DelveGuideData.poisons or {}) do
        local tag = p.base and "|cFF00FF88" .. L["[Base]"] .. " |r" or "|cFFFFD700" .. L["[Quest]"] .. "|r"
        y = y + UI.CreateRow(cf, y, string.format("%s |cFFAA66CC%s|r  |cFFCCCCCC%s|r  |cFF888888%s|r", tag, p.name, p.effect, p.use)) + 2
    end
    y = y + UI.CreateRow(cf, y, "|cFF00FF88" .. L["Rule of thumb:"] .. "|r |cFFCCCCCC" .. L["Bloodcrypt Toxin is the safe default; Frostheart Venom for defense once unlocked. Forgotten Master loses all stacks when you take damage -- only worth it if you're rarely getting hit."] .. "|r") + 4

    cf:SetHeight(y + 20)
end