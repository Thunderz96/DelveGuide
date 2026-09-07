-- ============================================================
-- DelveGuide.lua  --  Main addon logic
-- ============================================================
DelveGuide = {}

local ADDON_NAME       = "DelveGuide"
local ADDON_VERSION    = "1.11.0"
local WINDOW_W         = 700
local WINDOW_H         = 500
local TAB_HEIGHT       = 28
local BASE_HEADER_SIZE = 14
local BASE_ROW_SIZE    = 11
local BASE_ROW_HEIGHT  = 18
-- Community ranking submission form. Replace with your Google Form SHORT link
-- (forms.gle/...) once it's set up -- /dg submit shows it and the copy code.
local SUBMIT_URL       = "https://forms.gle/BwrGBZkRmbQdwufN8"

local TABS = {
    --{ label = "Dashboard", key = "dashboard" },
    { label = "Delves",   key = "delves"   },
    { label = "Curios",   key = "curios"   },
    { label = "Companion", key = "companion" },
    { label = "Loot",     key = "loot"     },
    { label = "Voidforge", key = "voidforge" },
    { label = "Journey",  key = "quests"   },
    { label = "Nemesis",  key = "nemesis"  },
    { label = "History",  key = "history"  },
    { label = "Future",   key = "future"   },
    { label = "Roster",   key = "roster"   },
    { label = "Settings", key = "settings" },
    { label = "Debug",    key = "debug"    },
}

-- Shared with the Debug tab -- see DelveGuideData.zoneMapIDs / .zoneNames.
local ALL_ZONE_MAP_IDS = DelveGuideData.zoneMapIDs

-- Widget set ID → English delve name lives in DelveGuideData.widgetSetDelves
-- (DelveGuide_Data.lua). A duplicate local copy used to sit here and was never
-- read -- new delve IDs went into it by mistake and had no effect. Removed.

local ZONE_NAMES = DelveGuideData.zoneNames

-- Nemesis delves have no rotational story variant, so their widget set is 0 and
-- their text is empty. Skip them in variant detection and don't log as missing.
-- Built from DelveGuideData.nemesisDelves so this list exists in exactly one
-- place. Kept as a lookup table for the hot path in the scanner.
local NEMESIS_DELVES = {}
for _, n in ipairs((DelveGuideData and DelveGuideData.nemesisDelves) or {}) do
    NEMESIS_DELVES[n] = true
end
-- Note: Venomfall Deeps DOES have a world-map POI (poiID 8779, atlas
-- delves-regular, widget set 0) -- an earlier note here claimed otherwise. It is
-- matched by the set-0 rule in the scanner on every locale, so these name
-- entries are only a belt-and-braces for English clients.

-- ============================================================
-- SHARED HELPERS
-- ------------------------------------------------------------
-- Small things that more than one file (or more than one place in this one)
-- needs. They live up here, ahead of the scanner, because the scanner uses them.
-- ============================================================

-- Strip WoW's inline escape sequences out of a string.
--
-- Five copies of this gsub chain had drifted apart: some stripped only hex
-- colours (|cAARRGGBB), some also the named form (|cnWHITE_FONT_COLOR:), some
-- also textures (|T...|t) and atlases (|A...|a). Missing the named form is what
-- once logged a variant as "|cnWHITE_FONT_COLOR:Basalisk Blitz". This strips
-- the union, so no caller can be the one that forgot a form -- including
-- hyperlinks (|Hitem:...|h[Name]|h), which no copy handled and which turn up in
-- objective-tracker text.
--
-- nil (or any non-string) gives "", because every caller was guarding for that
-- itself before it dared call :gsub.
function DelveGuide.StripEscapes(s)
    if type(s) ~= "string" then return "" end
    -- The parentheses drop gsub's second return value (the match count), which
    -- would otherwise leak into a caller's string.format or table.insert.
    return (s:gsub("|c%x%x%x%x%x%x%x%x", "")
             :gsub("|cn[%w_]+:", "")
             :gsub("|r", "")
             :gsub("|H.-|h(.-)|h", "%1")
             :gsub("|T.-|t", "")
             :gsub("|A.-|a", ""))
end

-- The week a run belongs to, as a stable integer key stored on history rows.
--
-- time() + secondsUntilWeeklyReset is the moment of the NEXT reset; minus one
-- week is the moment of the LAST one, i.e. the start of the current week. That
-- timestamp is already hour-aligned, so the trailing quantisation only exists
-- to absorb drift between the client clock and the server's countdown.
--
-- It used to floor. Flooring an already-aligned value means one second of
-- negative jitter drops the key a whole hour, filing that run under a bucket no
-- other run of the week shares -- so it disappeared from the Roster's weekly
-- delve count, the Victory screen's tally and the History week grouping.
-- Rounding to the nearest hour absorbs jitter in both directions instead.
--
-- Existing SavedVariables rows carry floored keys and still match: on an
-- hour-aligned input floor and round agree, and they only ever disagreed inside
-- the jitter window this change exists to close.
--
-- Returns nil when the API is unavailable; every caller already treats nil as
-- "week unknown", which is what the six inline copies did too.
function DelveGuide.GetResetKey()
    if not (C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset) then return nil end
    local ok, secs = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
    if not ok or type(secs) ~= "number" then return nil end
    return math.floor((time() + secs - 604800) / 3600 + 0.5) * 3600
end

-- ============================================================
-- SAVEDVARIABLES SCHEMA
-- ------------------------------------------------------------
-- Every field that has a default lives in DEFAULTS and is applied by the one
-- loop in InitSavedVars. MIGRATIONS holds one-shot upgrades: [n] takes a DB at
-- version n-1 to version n, and DelveGuideDB.dbVersion records how far a given
-- user's DB has been taken. Work that used to run on EVERY login now runs once.
-- lastSeenVersion deliberately has no default -- nil means the "what's new"
-- popup has never been shown. windowX/windowY/widgetX/widgetY likewise: nil is
-- "never moved", and the frames fall back to their own placement.
-- ============================================================
local DB_VERSION = 3

local DEFAULTS = {
    minimapAngle        = 225,
    minimap             = { hide = false },
    fontScale           = 1.0,
    widgetFontScale     = 1.0,
    history             = {},
    roster              = {},
    labyrinthLog        = {},
    missingTranslations = {},
    -- Learned localized delve name -> English name. Persisted because the POI
    -- scan that discovers it only runs OUTDOORS; without this, a non-EN player
    -- who reloads or logs in inside a delve can't resolve the zone, so the HUD
    -- (and its run timer) never appear for that run.
    localeDelveNames    = {},
    minimapHidden       = false,
    widgetHidden        = false,
    widgetClickOpens    = false,
    widgetTiers         = { S=true, A=true, B=true, C=true, D=true, F=true },
    widgetBountifulOnly = false,
    widgetLocked        = false,
    widgetAutoHide      = false,
    hudLocked           = false,
    hudEnabled          = true,
    checklistEnabled    = true,
    showChangelog       = true,
    showDebugTab        = false,
    mapTooltips         = true,
}

-- Table defaults have to be copied in, or every field would alias the single
-- table held in DEFAULTS and one player's edits would rewrite the default.
local function CopyDefault(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for k, sub in pairs(v) do copy[k] = sub end
    return copy
end

local MIGRATIONS = {
    -- 2: purge missingTranslations entries that are no longer actually missing.
    -- This swept the whole table on every single login; the entries it removes
    -- can only be created by versions before this one, so once is enough.
    --   * Nemesis delves (no rotational variant, so their widget text is empty)
    --   * variants that have since been added to the data table -- every Season 2
    --     variant was logged as "missing" during the window before it was
    --     catalogued, and nothing ever cleared those records afterwards, so the
    --     Debug tab kept reporting translations that had long since been added.
    [2] = function(db)
        local knownVariants = {}
        if DelveGuideData and DelveGuideData.delves then
            for _, d in ipairs(DelveGuideData.delves) do
                if d.variant then knownVariants[d.variant] = true end
            end
        end
        for key, entry in pairs(db.missingTranslations) do
            local stale = false
            if entry and (entry.delve == "Torment's Rise" or entry.delve == "Venomfall Deeps") then
                stale = true
            elseif entry and entry.text then
                for variant in pairs(knownVariants) do
                    if string.find(entry.text, variant, 1, true) then stale = true; break end
                end
                -- ...and entries whose LOCALIZED name has since been added. This is
                -- the case that actually matters: a "missing translation" is by
                -- definition non-English, so a purge that only checked English
                -- names could never clear one. Records survived forever and the
                -- Debug tab / login warning kept reporting variants long after
                -- they were mapped -- reported on esMX (GitHub #5) for Destello
                -- invasor and Potenciamiento ogro, which resolved correctly in
                -- game while still being listed as missing.
                if not stale and DelveGuideData and DelveGuideData.localeVariants then
                    for locName in pairs(DelveGuideData.localeVariants) do
                        if string.find(entry.text, locName, 1, true) then stale = true; break end
                    end
                end
            end
            -- Blurb garbage. Before 1.9.0 the recorder stored widgetTexts[1],
            -- which on a Bountiful delve is the multi-line coffer blurb, and the
            -- table is keyed BY that text. The blurb embeds a live countdown
            -- ("Tiempo restante: 9 h 17 min") and a shard count, so every single
            -- scan minted a brand-new key and the table grew without limit --
            -- one reporter's /dg submit code came out 116,701 characters over
            -- what the form would accept. A real variant line is short and
            -- single-line, so anything else is junk and can never match a
            -- variant name to be purged by the rules above.
            if not stale and entry and entry.text then
                if #entry.text > 80 or string.find(entry.text, string.char(10), 1, true) then
                    stale = true
                end
            end
            if stale then db.missingTranslations[key] = nil end
        end

        -- Hard cap regardless of cause. Unidentified variants are a handful per
        -- locale; anything beyond this is a bug producing junk, and the cost of
        -- that junk is a submission code nobody can paste. Keep the newest.
        local MAX_MISSING = 40
        local keys = {}
        for k in pairs(db.missingTranslations) do table.insert(keys, k) end
        if #keys > MAX_MISSING then
            table.sort(keys, function(a, b)
                local ea, eb = db.missingTranslations[a], db.missingTranslations[b]
                return (ea and ea.firstSeen or "") > (eb and eb.firstSeen or "")
            end)
            for i = MAX_MISSING + 1, #keys do
                db.missingTranslations[keys[i]] = nil
            end
        end
    end,

    -- 3: history rows logged in a Labyrinth before kind="labyrinth" existed
    -- (12.1.5 PTR) look like delve runs with no variant. Tag rather than delete:
    -- the row is a real run the player did, it just can't be a ranking entry.
    [3] = function(db)
        local labNames = {}
        for _, L in ipairs((DelveGuideData and DelveGuideData.labyrinths) or {}) do
            labNames[L.name] = true
        end
        for _, run in ipairs(db.history) do
            if run.name and labNames[run.name] and not run.variant and not run.kind then
                run.kind = "labyrinth-legacy"
            end
        end
    end,
}

local function InitSavedVars()
    local freshInstall = (DelveGuideDB == nil)
    DelveGuideDB = DelveGuideDB or {}

    for key, value in pairs(DEFAULTS) do
        if DelveGuideDB[key] == nil then DelveGuideDB[key] = CopyDefault(value) end
    end

    -- Schema upgrades. A brand-new DB is already current and only needs the
    -- stamp; an existing DB without one predates versioning, so it is v1.
    if freshInstall then
        DelveGuideDB.dbVersion = DB_VERSION
    else
        for v = (DelveGuideDB.dbVersion or 1) + 1, DB_VERSION do
            local migrate = MIGRATIONS[v]
            if migrate then migrate(DelveGuideDB) end
        end
        DelveGuideDB.dbVersion = DB_VERSION
    end

    -- checklistDismissed is session-only; reset on every load. Deliberately not
    -- a default -- it must be forced back to false even when it is already set.
    DelveGuideDB.checklistDismissed = false
end

local activeDelves, activeVariants, rawScanResults = {}, {}, {}
local localizedToEnglish = {}  -- maps localized zone name → English zone name (non-EN clients)
local minimapBtn, currentAngle, RefreshCurrentTab, icon

local function ReadVariantFromWidgetSet(setID)
    if not setID or setID == 0 then return {} end
    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID)
    if not widgets then return {} end
    local texts = {}
    for _, w in ipairs(widgets) do
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo
                     and C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(w.widgetID)
        if info and info.text and info.text ~= "" then table.insert(texts, info.text) end
        info = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo
               and C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(w.widgetID)
        if info and info.text and info.text ~= "" then table.insert(texts, info.text) end
    end
    return texts
end

-- The non-text fields of a widget set. ReadVariantFromWidgetSet keeps only the
-- text; the review's one cheap experiment for a locale-free OUTDOOR variant key
-- is to see whether widgetTag / textureKit / orderIndex differ between two days
-- with different variants (Plumber reads state off exactly these fields).
-- Recorded into rawScanResults and the export; printed by /dg selftest.
local function ReadWidgetSetMeta(setID)
    local meta = {}
    if not setID or setID == 0 then return meta end
    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID)
    if not widgets then return meta end
    for _, w in ipairs(widgets) do
        local m = { id = w.widgetID, type = w.widgetType }
        local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo
                     and C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(w.widgetID)
        if not info and C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo then
            info = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(w.widgetID)
        end
        if info then
            m.tag   = info.widgetTag
            m.kit   = info.textureKit
            m.order = info.orderIndex
            m.anim  = info.scriptedAnimationEffectID
        end
        table.insert(meta, m)
    end
    return meta
end

-- Every widget in the objective tracker's set, with whatever text it carries.
-- This is the capture that settles whether the HUD's lives count is a scenario
-- criterion or a header widget (review hud-victory#7): if the lives appear
-- here and not in the criteria, the criteria scan can never find them.
local function DumpObjectiveTrackerWidgets()
    local out = {}
    local ok, setID = pcall(function()
        return C_UIWidgetManager.GetObjectiveTrackerWidgetSetID
               and C_UIWidgetManager.GetObjectiveTrackerWidgetSetID()
    end)
    if not ok or not setID then return out, nil end
    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID) or {}
    for _, w in ipairs(widgets) do
        local m = { id = w.widgetID, type = w.widgetType }
        pcall(function()
            local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo
                         and C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(w.widgetID)
            if not (info and info.text) and C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo then
                info = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(w.widgetID)
            end
            if info then
                m.text = info.text; m.tag = info.widgetTag; m.kit = info.textureKit; m.order = info.orderIndex
            end
        end)
        table.insert(out, m)
    end
    return out, setID
end

-- The scenario STEP's widget set: the 12th return of C_Scenario.GetStepInfo
-- (842 in every delve and Labyrinth snapshot so far), or
-- C_ScenarioInfo.GetScenarioStepInfo().widgetSetID. This is where the delve
-- header widget lives -- the tier badge and the lives hearts that the HUD
-- currently scrapes off rendered FontStrings. The objective-tracker set the
-- review pointed at (240) is the generic tracker frame and is empty in and
-- out of scenarios. Every widget's visualization info is shallow-copied, so
-- field names we do not know yet (tierText? lives?) still land on disk. The
-- getter for a widget type is looked up by name first, then found by trying
-- every C_UIWidgetManager.*VisualizationInfo until one answers; the name that
-- answered is recorded so the next capture can go straight to it.
local VIZ_GETTERS = {
    [0]  = "GetIconAndTextWidgetVisualizationInfo",
    [2]  = "GetStatusBarWidgetVisualizationInfo",
    [8]  = "GetTextWithStateWidgetVisualizationInfo",
    [11] = "GetScenarioHeaderCurrenciesAndBackgroundWidgetVisualizationInfo",
    [12] = "GetTextureAndTextWidgetVisualizationInfo",
    [13] = "GetSpellDisplayVisualizationInfo",
    [19] = "GetDiscreteProgressStepsVisualizationInfo",
    [21] = "GetTextureWithStateVisualizationInfo",
    [29] = "GetScenarioHeaderDelvesWidgetVisualizationInfo",   -- the delve header: tierText, headerText (69594)
}
local function GetStepWidgetSetID()
    local id
    pcall(function()
        if C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo then
            local st = C_ScenarioInfo.GetScenarioStepInfo()
            id = st and st.widgetSetID
        end
        if not id then id = select(12, C_Scenario.GetStepInfo()) end
    end)
    if id == 0 then id = nil end
    return id
end
local function DumpWidgetSet(setID)
    local out = {}
    if not setID then return out end
    local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(setID) or {}
    for _, w in ipairs(widgets) do
        local m = { id = w.widgetID, type = w.widgetType }
        local function scalars(t)
            local o = {}
            for k, v in pairs(t) do
                local tv = type(v)
                if tv == "string" or tv == "number" or tv == "boolean" then o[k] = v
                elseif tv == "table" then o[k] = "<table>" end
            end
            return o
        end
        -- Two levels: the info's own scalars, and for each table field its
        -- elements' scalars. Enough to see what currencies / spells /
        -- rewardInfo hold without copying the world.
        local function copyInfo(info)
            for k, v in pairs(info) do
                local t = type(v)
                if t == "string" or t == "number" or t == "boolean" then m[k] = v
                elseif t == "table" then
                    local o = {}
                    for kk, vv in pairs(v) do
                        o[kk] = (type(vv) == "table") and scalars(vv) or vv
                    end
                    m[k] = o
                end
            end
        end
        local answered
        local name = VIZ_GETTERS[w.widgetType]
        if name and C_UIWidgetManager[name] then
            local ok, info = pcall(C_UIWidgetManager[name], w.widgetID)
            if ok and type(info) == "table" then copyInfo(info); answered = name end
        end
        if not answered then
            for fname, fn in pairs(C_UIWidgetManager) do
                if type(fn) == "function" and fname:find("VisualizationInfo$") then
                    local ok, info = pcall(fn, w.widgetID)
                    if ok and type(info) == "table" then copyInfo(info); answered = fname; break end
                end
            end
        end
        m.getter = answered or "none answered"
        table.insert(out, m)
    end
    return out
end

-- The delve header widget -- ScenarioHeaderDelves, type 29 -- from the
-- scenario step's widget set. Its visualization info carries tierText, the
-- tier exactly as Blizzard renders it in the objective tracker, plus
-- headerText (the delve name) and tables for currencies, spells and rewards.
-- Read as data, this replaces the frame-tree scrape the HUD has used for the
-- tier since 12.0. Verified on 69594 in Twilight Crypts at Tier 8.
DelveGuide.ReadDelveHeaderWidget = function()
    local info
    pcall(function()
        local setID = GetStepWidgetSetID()
        if not setID then return end
        local getter = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo
        if not getter then return end
        for _, w in ipairs(C_UIWidgetManager.GetAllWidgetsBySetID(setID) or {}) do
            local ok, i = pcall(getter, w.widgetID)
            if ok and type(i) == "table" and i.tierText ~= nil then info = i; break end
        end
    end)
    return info
end

-- Lives, from the same header widget. Its `currencies` list carries one entry
-- whose tooltip is the lives spell link -- "|Hspell:458103|h|nTotal deaths: N"
-- on 69594, icon 6013778 -- and whose text is the lives count. Matched on the
-- spell link or the icon, never on wording, so it holds on every locale.
-- Returns lives (number), deaths (number or nil). Lives were never a scenario
-- criterion; the HUD's criteria scan for them could not succeed.
local LIVES_SPELL_ID, LIVES_ICON_FILE = 458103, 6013778
DelveGuide.ReadDelveLives = function()
    local lives, deaths
    pcall(function()
        local info = DelveGuide.ReadDelveHeaderWidget()
        for _, c in ipairs((info and info.currencies) or {}) do
            local tip = tostring(c.tooltip or "")
            if tip:find("spell:" .. LIVES_SPELL_ID, 1, true) or c.iconFileID == LIVES_ICON_FILE then
                lives = tonumber(tostring(c.text or ""):match("(%d+)"))
                -- "Total deaths: N" is localized, but the number is the last one
                -- in the tooltip on every locale seen so far.
                deaths = tonumber(tip:match("(%d+)%s*$"))
                break
            end
        end
    end)
    return lives, deaths
end

-- type() of every Blizzard API this addon leans on, so a namespace move (as
-- 12.1.5 did to scenario criteria) shows up as a line of output instead of
-- failing silently inside a pcall. Shared by /dg export and /dg selftest.
local API_PROBES = {
    { "C_Scenario.GetInfo",                          "C_Scenario",     "GetInfo",                          true  },
    { "C_Scenario.GetStepInfo",                      "C_Scenario",     "GetStepInfo",                      true  },
    { "C_Scenario.IsInScenario",                     "C_Scenario",     "IsInScenario",                     true  },
    { "C_Scenario.GetNumCriteria",                   "C_Scenario",     "GetNumCriteria",                   false }, -- gone in 12.1.5; fallback only
    { "C_Scenario.GetCriteriaInfo",                  "C_Scenario",     "GetCriteriaInfo",                  false }, -- gone in 12.1.5; fallback only
    { "C_ScenarioInfo.GetScenarioInfo",              "C_ScenarioInfo", "GetScenarioInfo",                  true  },
    { "C_ScenarioInfo.GetScenarioStepInfo",          "C_ScenarioInfo", "GetScenarioStepInfo",              false },
    { "C_ScenarioInfo.GetCriteriaInfo",              "C_ScenarioInfo", "GetCriteriaInfo",                  true  },
    { "C_DelvesUI.GetActiveDelveTier",               "C_DelvesUI",     "GetActiveDelveTier",               false }, -- present, returns an empty struct
    { "C_DelvesUI.GetCompanionInfoForActivePlayer",  "C_DelvesUI",     "GetCompanionInfoForActivePlayer",  true  },
    { "C_DelvesUI.HasActiveLair",                    "C_DelvesUI",     "HasActiveLair",                    true  },
    { "C_DelvesUI.GetRoleNodeForCompanion",          "C_DelvesUI",     "GetRoleNodeForCompanion",          false },
    { "C_AreaPoiInfo.GetDelvesForMap",               "C_AreaPoiInfo",  "GetDelvesForMap",                  true  },
    { "C_AreaPoiInfo.GetAreaPOIInfo",                "C_AreaPoiInfo",  "GetAreaPOIInfo",                   true  },
    { "C_UIWidgetManager.GetAllWidgetsBySetID",      "C_UIWidgetManager", "GetAllWidgetsBySetID",          true  },
    { "C_Reputation.GetFactionDataByID",             "C_Reputation",   "GetFactionDataByID",               true  },
    { "C_Reputation.GetFactionDataByIndex",          "C_Reputation",   "GetFactionDataByIndex",            false },
    { "C_Reputation.GetNumFactions",                 "C_Reputation",   "GetNumFactions",                   false },
    { "C_Reputation.ExpandFactionHeader",            "C_Reputation",   "ExpandFactionHeader",              false },
    { "C_MajorFactions.GetMajorFactionIDs",          "C_MajorFactions","GetMajorFactionIDs",               false },
    { "C_CurrencyInfo.GetCurrencyInfo",              "C_CurrencyInfo", "GetCurrencyInfo",                  true  },
    { "C_Item.GetItemInfoInstant",                   "C_Item",         "GetItemInfoInstant",               true  }, -- global form deleted in 12.1.5
    { "C_Item.GetItemCount",                         "C_Item",         "GetItemCount",                     true  },
    { "C_Item.GetDetailedItemLevelInfo",             "C_Item",         "GetDetailedItemLevelInfo",         true  },
    { "C_WeeklyRewards.GetActivities",               "C_WeeklyRewards","GetActivities",                    true  },
    { "C_TaxiMap.GetAllTaxiNodes",                   "C_TaxiMap",      "GetAllTaxiNodes",                  false },
    { "C_Map.SetUserWaypoint",                       "C_Map",          "SetUserWaypoint",                  true  },
    { "C_SuperTrack.SetSuperTrackedUserWaypoint",    "C_SuperTrack",   "SetSuperTrackedUserWaypoint",      false },
}
-- Returns { [label] = "function"|"nil"|... } and a list of REQUIRED labels that
-- came back nil -- those are the ones that would silently break the addon.
local function ProbeAPIs()
    local result, missing = {}, {}
    for _, pr in ipairs(API_PROBES) do
        local label, ns, key, required = pr[1], pr[2], pr[3], pr[4]
        local ok, v = pcall(function() local t = _G[ns]; return t and t[key] end)
        local ty = ok and type(v) or "err"
        result[label] = ty
        if required and ty ~= "function" then table.insert(missing, label) end
    end
    result["GetTaxiMapID (global)"] = type(GetTaxiMapID)
    result["NumTaxiNodes (global)"] = type(NumTaxiNodes)
    result["GetInstanceInfo (global)"] = type(GetInstanceInfo)
    return result, missing
end

-- Seed the localized-name map from the persisted cache so it survives reloads
-- and logins that happen inside a delve (where no POI scan runs).
local function SeedLocalizedNames()
    localizedToEnglish = {}
    if DelveGuideDB and DelveGuideDB.localeDelveNames then
        for loc, eng in pairs(DelveGuideDB.localeDelveNames) do localizedToEnglish[loc] = eng end
    end
    DelveGuide.localizedToEnglish = localizedToEnglish
end

local function ScanActiveVariants()
    -- 2.1c: build into fresh tables, but only replace the live cache if the
    -- scan actually found delves. A rescan during an entry transition can get
    -- empty POI lists and used to wipe the cache the HUD relies on for the
    -- whole run.
    local prevDelves, prevVariants = activeDelves, activeVariants
    activeDelves, activeVariants, rawScanResults = {}, {}, {}
    SeedLocalizedNames()
    DelveGuide.rawScanResults       = rawScanResults
    DelveGuide.localizedToEnglish  = localizedToEnglish
    local knownVariants = {}
    if DelveGuideData and DelveGuideData.delves then
        for _, d in ipairs(DelveGuideData.delves) do knownVariants[d.variant] = true end
    end
    -- Dedupe: Blizzard exposes the same POI on multiple map IDs (e.g. Collegiate
    -- Calamity on 2393 AND 2395). Process each POI once to avoid wasted work
    -- and duplicate rows in the Debug tab.
    --
    -- CAUTION when reading /dg chatdump: the mapID recorded against a POI is
    -- simply the FIRST map in ALL_ZONE_MAP_IDS order that returned it -- NOT
    -- where the delve actually is. 2437 sits second in that order, so POIs it
    -- also exposes get stamped 2437 (The Shadow Enclave reads 2437 though it is
    -- in Eversong 2395; Venomfall Deeps reads 2437 though it is on The Coiled
    -- Isle 2512). Use DelveGuideData.mapPins for real locations, never the dump.
    local seenPOI = {}
    for _, mapID in ipairs(ALL_ZONE_MAP_IDS) do
        local poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
        if poiIDs == nil then
            table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A",name="(GetDelvesForMap returned nil)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
        elseif #poiIDs == 0 then
            table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                poiID="N/A",name="(GetDelvesForMap returned empty - map IDs may not match this region)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
        else
            for _, poiID in ipairs(poiIDs) do
                if seenPOI[poiID] then
                    -- Already processed on a prior map; skip duplicate.
                else
                    seenPOI[poiID] = true
                local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                if info then
                    local delveName=info.name or ""; local widgetSetID=info.tooltipWidgetSet or 0
                    local widgetTexts=ReadVariantFromWidgetSet(widgetSetID)
                    local widgetMeta=ReadWidgetSetMeta(widgetSetID)
                    local atlasName = info.atlasName or ""
                    local variantName,isBountiful,hasNemesis=nil,false,false
                    if atlasName:find("bountiful",1,true) then isBountiful=true end
                    -- Variant detection: text matching first (reads today's actual widget text)
                    for _, t in ipairs(widgetTexts) do
                        -- Strip escapes. WoW uses BOTH hex colours (|cAARRGGBB)
                        -- and named ones (|cnWHITE_FONT_COLOR:) -- the named form
                        -- was being left in, so logged text came out as
                        -- "Story Variant: |cnWHITE_FONT_COLOR:Basalisk Blitz".
                        local clean=DelveGuide.StripEscapes(t)
                        if string.find(clean,"Nemesis",1,true) then hasNemesis=true end
                        if not variantName then
                            -- Try English text match first (EN clients)
                            -- LONGEST match wins, in both loops below. Some variant
                            -- names contain another as a substring: esMX
                            -- "Bombardeo basilisco" (Basalisk Blitz, Shadowguard
                            -- Point) contains "Bombardeo" (Bombing Run, Parhelion
                            -- Plaza) -- a different variant on a different delve.
                            -- These loops used first/last-match-wins over pairs(),
                            -- whose order Lua does not define, so a collision
                            -- resolved to the wrong variant NON-DETERMINISTICALLY
                            -- and silently logged bad runs into the rankings.
                            -- A superstring always has more bytes than its
                            -- substring, so comparing #name is exact here.
                            local bestLen = 0
                            for kVariant in pairs(knownVariants) do
                                if #kVariant > bestLen and string.find(clean,kVariant,1,true) then
                                    variantName = kVariant; bestLen = #kVariant
                                end
                            end
                            -- Non-EN fallback: substring match against localized names.
                            if not variantName and DelveGuideData.localeVariants then
                                for locName, engName in pairs(DelveGuideData.localeVariants) do
                                    if #locName > bestLen and string.find(clean, locName, 1, true) then
                                        variantName = engName; bestLen = #locName
                                    end
                                end
                            end
                        end
                    end
                    -- Key activeDelves by English zone name so lookups work on all locales.
                    -- For EN clients, info.name is already English.
                    -- For non-EN clients, use widget set ID → delve name mapping as fallback.
                    local engZoneName = delveName
                    local delveFromSetID = DelveGuideData.widgetSetDelves and DelveGuideData.widgetSetDelves[widgetSetID]
                    if delveFromSetID then
                        engZoneName = delveFromSetID
                    elseif variantName and DelveGuideData and DelveGuideData.delves then
                        for _, d in ipairs(DelveGuideData.delves) do
                            if d.variant == variantName then engZoneName = d.name; break end
                        end
                    end
                    -- Nemesis delves (e.g. Torment's Rise) have no rotational
                    -- variant, so their widget set is 0 and text is empty.
                    -- Don't treat them as "missing translation".
                    -- Widget set 0 + no widget text is the locale-INDEPENDENT
                    -- signature of a Nemesis delve, and the only test that works
                    -- on non-English clients: NEMESIS_DELVES is keyed by English
                    -- name, and for these delves engZoneName also stays localized
                    -- (no widgetSetDelves entry, since their set is 0). On esMX
                    -- that meant Venomfall Deeps ("Sima del Tosigo", set 0, no
                    -- widget text) failed both name checks and leaked into the
                    -- rotational delve list as a 13th delve with "Unknown Variant
                    -- Text". English clients only escaped this by luck -- delveName
                    -- happens to already be English there.
                    local isNemesisDelve = NEMESIS_DELVES[delveName]
                        or NEMESIS_DELVES[engZoneName]
                        or (widgetSetID == 0 and #widgetTexts == 0)
                    -- Labyrinths (12.1.5) come back from GetDelvesForMap like a
                    -- delve, on a different atlas, with a widget set whose text
                    -- yields no variant line. They are not rotational: keep them
                    -- out of activeDelves AND out of the missing-translation
                    -- quarantine, or the Delves tab shows a junk row. Keyed on
                    -- widget set, the same stable id widgetSetDelves uses. An
                    -- atlas test would be more generic but could misfile a real
                    -- bountiful delve, which is the worse failure.
                    local isLabyrinth = DelveGuideData.labyrinthWidgetSets
                        and DelveGuideData.labyrinthWidgetSets[widgetSetID] or false

                    -- Nemesis delves are NOT rotational, so they must never enter
                    -- activeDelves: the Delves tab and the compact widget both fall
                    -- back to iterating it, and anything in there is rendered as a
                    -- delve of the day. This check used to sit BELOW the insertion,
                    -- so it only suppressed the missing-translation record and the
                    -- delve still showed up -- as "New variant" instead of "Unknown
                    -- Variant Text", which looked fixed but was not.
                    if engZoneName~="" and not isNemesisDelve and not isLabyrinth then
                        activeDelves[engZoneName]={bountiful=isBountiful,nemesis=hasNemesis}
                        if delveName~=engZoneName then
                            localizedToEnglish[delveName]=engZoneName
                            -- Remember it across sessions (see SeedLocalizedNames).
                            if DelveGuideDB and DelveGuideDB.localeDelveNames then
                                DelveGuideDB.localeDelveNames[delveName]=engZoneName
                            end
                        end
                    end


                    -- If we don't know the translation, quarantine the text safely
                    if (not variantName or variantName == "") and not isNemesisDelve and not isLabyrinth then
                        -- Find a line that plausibly IS the variant name: single
                        -- line and short. Bountiful delves prepend a multi-line
                        -- coffer blurb, so widgetTexts[1] is that blurb and the
                        -- variant is widgetTexts[2].
                        local safeText
                        for i = #widgetTexts, 1, -1 do
                            local t = widgetTexts[i]
                            if t and t ~= "" and not t:find(string.char(10), 1, true) and #t <= 120 then
                                safeText = t; break
                            end
                        end
                        local displayText = safeText or "Unknown Variant Text"
                        -- Strip WoW color codes from the raw text to make it readable
                        displayText = DelveGuide.StripEscapes(displayText)
                        variantName = "[Missing Translation] " .. displayText

                        -- Log to SavedVariables for the Debug tab
                        -- Record ONLY when a variant-looking line was found. 1.9.1
                        -- fell back to widgetTexts[1] here, which re-filed the coffer
                        -- blurb as a "missing translation" -- exactly what the purge
                        -- exists to delete. The two fought each other: the purge
                        -- cleared the junk at login and the next scan put it straight
                        -- back. A blurb is not a missing translation; recording
                        -- nothing is strictly better than recording noise.
                        if safeText and DelveGuideDB and DelveGuideDB.missingTranslations then
                            local locale = GetLocale and GetLocale() or "unknown"
                            local entryKey = locale .. ":" .. displayText
                            if not DelveGuideDB.missingTranslations[entryKey] then
                                DelveGuideDB.missingTranslations[entryKey] = {
                                    text      = displayText,
                                    locale    = locale,
                                    delve     = delveName,
                                    mapID     = mapID,
                                    firstSeen = date("%Y-%m-%d"),
                                }
                            end
                        end
                    end

                    table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID=poiID,name=delveName,widgetSetID=tostring(widgetSetID),
                        atlasName=atlasName,widgetTexts=widgetTexts,widgetMeta=widgetMeta,variantName=variantName or (isNemesisDelve and "(nemesis)" or (isLabyrinth and "(labyrinth)") or "(not found)")})
                    if variantName and variantName~="" then activeVariants[variantName]=true end
                else
                    table.insert(rawScanResults,{mapID=mapID,zoneName=ZONE_NAMES[mapID] or ("mapID "..mapID),
                        poiID=poiID,name="(GetAreaPOIInfo returned nil)",widgetSetID="0",atlasName="",widgetTexts={},variantName="(nil)"})
                end
                end  -- end dedupe guard
            end
        end
    end
    if not next(activeDelves) and next(prevDelves or {}) then
        activeDelves, activeVariants = prevDelves, prevVariants
    end
    DelveGuide.activeDelves   = activeDelves
    DelveGuide.activeVariants = activeVariants
end

local function IsVariantActive(v) return activeVariants[v]==true end

-- ============================================================
-- DELVE TIER STATE
-- ------------------------------------------------------------
-- Two independent inputs, one derived answer:
--   manualDelveTier -- set only by /dg tier N; wins while set
--   autoDelveTier   -- refreshed by the HUD's detector on every update
-- currentDelveTier / currentDelveTierNum are DERIVED (History and the
-- Victory screen read them) and always use ONE format: "Tier N" and N.
-- Previously the manual path wrote "8" while auto wrote "Tier 8", and an
-- auto-detected tier was stored in the manual slot -- so the next HUD
-- update relabelled it "(Manual)" and it survived into the next run.
-- Both are cleared on delve exit and on completion.
-- ============================================================
DelveGuide.manualDelveTier = nil
DelveGuide.autoDelveTier   = nil

-- Recompute the derived fields. Returns: tierNum, isManual
DelveGuide.ApplyDelveTier = function()
    local n = DelveGuide.manualDelveTier or DelveGuide.autoDelveTier
    DelveGuide.currentDelveTierNum = n
    DelveGuide.currentDelveTier    = n and ("Tier " .. n) or nil
    return n, (DelveGuide.manualDelveTier ~= nil)
end

-- nil clears the override and falls back to auto-detection.
DelveGuide.SetManualDelveTier = function(n)
    DelveGuide.manualDelveTier = n
    return DelveGuide.ApplyDelveTier()
end

DelveGuide.SetAutoDelveTier = function(n)
    DelveGuide.autoDelveTier = n
    return DelveGuide.ApplyDelveTier()
end

DelveGuide.ClearDelveTier = function()
    DelveGuide.manualDelveTier     = nil
    DelveGuide.autoDelveTier       = nil
    DelveGuide.currentDelveTier    = nil
    DelveGuide.currentDelveTierNum = nil
end

-- Scenario criteria, 12.1.5-safe. Patch 12.1.5 removed C_Scenario.GetNumCriteria
-- and C_Scenario.GetCriteriaInfo; criteria now live on C_ScenarioInfo. Every
-- caller here is inside a pcall, so the removal failed silently -- the HUD just
-- stopped showing lives with no error to notice. Verified on build 69594:
-- C_ScenarioInfo.GetCriteriaInfo returns the same field names the callers read
-- (description, quantity, totalQuantity, quantityString), so only the namespace
-- moved. Both paths are kept so one build runs on 12.1.0 and 12.1.5.
DelveGuide.GetCriteriaCount = function()
    if C_Scenario.GetNumCriteria then return C_Scenario.GetNumCriteria() or 0 end
    -- 3rd return of GetStepInfo is numCriteria, and GetStepInfo survives.
    return select(3, C_Scenario.GetStepInfo()) or 0
end

DelveGuide.GetCriteria = function(i)
    if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
        return C_ScenarioInfo.GetCriteriaInfo(i)
    end
    return C_Scenario.GetCriteriaInfo and C_Scenario.GetCriteriaInfo(i)
end

-- Labyrinth detection (12.1.5). Inside a Labyrinth every cheap signal reads
-- as a delve -- scenario type 8, diffID 208, diffName "Delves" -- so the ONLY
-- reliable test is the instanceID against DelveGuideData.labyrinths. Returns
-- the Labyrinth's name, or nil. The HUD uses it to withhold the delve timer
-- and tier; the completion handler uses it to withhold the delve-shaped
-- history row. Verified on PTR build 69594: 3043 across tiers 11, 1 and 8.
DelveGuide.GetLabyrinthName = function()
    local name
    pcall(function()
        local _,_,_,_,_,_,_, instanceID = GetInstanceInfo()
        local lookup = DelveGuideData and DelveGuideData.labyrinthInstances
        name = instanceID and lookup and lookup[instanceID] or nil
    end)
    return name
end

-- Labyrinth observation log (D3). One flat entry per event inside a
-- Labyrinth -- enter, chamber completion, encounter end, leave -- so a PTR
-- session documents itself and the eventual guide is built from recorded data
-- rather than memory. Nothing renders this yet; read DelveGuideDB.labyrinthLog
-- off disk. Bounded; the oldest entries fall off.
local LAB_LOG_MAX = 80
DelveGuide.LogLabyrinth = function(entry)
    if not DelveGuideDB then return end
    DelveGuideDB.labyrinthLog = DelveGuideDB.labyrinthLog or {}
    entry.at = date("%Y-%m-%d %H:%M:%S")
    entry.labyrinth = entry.labyrinth or DelveGuide.GetLabyrinthName()
    table.insert(DelveGuideDB.labyrinthLog, entry)
    while #DelveGuideDB.labyrinthLog > LAB_LOG_MAX do table.remove(DelveGuideDB.labyrinthLog, 1) end
end

-- Enter/leave boundaries. Called wherever the instance state has settled;
-- compares against the last seen Labyrinth so each transition logs once.
-- labyrinthChamberStart is reset here and after every chamber completion,
-- giving each chamber record an elapsed time.
DelveGuide.TrackLabyrinthPresence = function()
    local now = DelveGuide.GetLabyrinthName()
    local was = DelveGuide.currentLabyrinth
    if now == was then return end
    if was then
        local ran = DelveGuide.labyrinthEnteredAt and (GetTime() - DelveGuide.labyrinthEnteredAt) or nil
        DelveGuide.LogLabyrinth({ kind = "leave", labyrinth = was, elapsed = ran })
        -- Settle the run record's elapsed time; it was created mid-run.
        if DelveGuide.LogLabyrinthRun then DelveGuide.LogLabyrinthRun(was) end
        DelveGuide.currentLabyrinthRow      = nil
        DelveGuide.labyrinthCreditsAnnounced = nil
    end
    if now then
        -- A /reload inside a Labyrinth arrives here with no "was". If the log's
        -- last entry for this Labyrinth is not a "leave", this is the same visit:
        -- keep counting chambers from its "enter" and restore the clock from the
        -- wall time stored on it (the same trick DelveGuideDB.activeRun uses for
        -- delves). GetTime() is session uptime and would otherwise restart at 0.
        local resumed = false
        local log = DelveGuideDB and DelveGuideDB.labyrinthLog or {}
        for i = #log, 1, -1 do
            local e = log[i]
            if e.labyrinth == now then
                if e.kind == "leave" then break end
                if e.kind == "enter" then
                    -- Same visit if the entry is recent. An entry written before
                    -- the epoch field existed still resumes the chamber count,
                    -- just with a fresh clock; one older than three hours is a
                    -- visit that never logged its leave, and is not resumed.
                    local age = e.epoch and (time() - e.epoch) or nil
                    if age == nil or (age >= 0 and age < 3 * 60 * 60) then
                        resumed = true
                        DelveGuide.labyrinthEnteredAt = age and (GetTime() - age) or GetTime()
                    end
                    break
                end
            end
        end
        if not resumed then
            DelveGuide.labyrinthEnteredAt = GetTime()
            DelveGuide.LogLabyrinth({ kind = "enter", labyrinth = now, epoch = time() })
        end
        DelveGuide.labyrinthChamberStart = GetTime()
    else
        DelveGuide.labyrinthEnteredAt    = nil
        DelveGuide.labyrinthChamberStart = nil
    end
    DelveGuide.currentLabyrinth = now
end

-- Trovehunter's Bounty state, shared by the Delves tab, the pre-entry
-- checklist, the roster snapshot and the debug export so they can never
-- disagree. IDs live in DelveGuideData.trove (one place, per season).
-- Returns: state, count, hasAura, weeklyDone
--   state = "active"     -- buff is up right now
--         | "inBags"     -- item held, not used yet
--         | "weeklyDone" -- weekly turned in, bounty already spent
--         | "none"       -- nothing yet this week
DelveGuide.GetTroveStatus = function()
    local T = (DelveGuideData and DelveGuideData.trove) or {}

    local hasAura = false
    if T.AURA_ID and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, T.AURA_ID)
        hasAura = (ok and aura ~= nil) or false
    end

    local count = 0
    if T.ITEM_ID and C_Item and C_Item.GetItemCount then
        local ok, qty = pcall(C_Item.GetItemCount, T.ITEM_ID, true)
        if ok then count = qty or 0 end
    end

    local weeklyDone = false
    if T.WEEKLY_QUEST and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, T.WEEKLY_QUEST)
        weeklyDone = (ok and done) or false
    end

    local state = (hasAura and "active")
               or (count > 0 and "inBags")
               or (weeklyDone and "weeklyDone")
               or "none"
    return state, count, hasAura, weeklyDone
end

-- Expose live scan data so DelveGuide_HUD.lua can read it
DelveGuide = DelveGuide or {}

local HEADER_FONT_FILE,ROW_FONT_FILE=nil,nil
local function EnsureFontFiles()
    if not HEADER_FONT_FILE then
        HEADER_FONT_FILE=GameFontNormalLarge:GetFont() or "Fonts\\FRIZQT__.TTF"
        ROW_FONT_FILE=GameFontNormalSmall:GetFont() or "Fonts\\FRIZQT__.TTF"
    end
end
local function GetScaledSizes()
    local s=DelveGuideDB and DelveGuideDB.fontScale or 1.0
    return math.floor(BASE_HEADER_SIZE*s+0.5),math.floor(BASE_ROW_SIZE*s+0.5),math.floor(BASE_ROW_HEIGHT*s+0.5)
end

local function GradeColor(g) return (DelveGuideData.gradeColors[g] or "|cFFFFFFFF")..g.."|r" end
local zoneColors={["Zul'Aman"]="|cFFFF8C00",["Quel'Thalas"]="|cFF00CED1",["Voidstorm"]="|cFFBF5FFF",["Harandar"]="|cFF7FFF00",["Quel'Danas"]="|cFFFF69B4",["The Coiled Isle"]="|cFF1E90FF"}
local function ZoneColor(z) return (zoneColors[z] or "|cFFCCCCCC")..z.."|r" end
local typeColors={Combat="|cFFFF4444",Utility="|cFF44AAFF"}
local RANK_COLORS={S="|cFF00FF44",A="|cFF66FF44",B="|cFFAAFF44",C="|cFFFFFF44",D="|cFFFF8844",F="|cFFFF4444"}
local RANK_ORDER={S=1,A=2,B=3,C=4,D=5,F=6}
local function TypeColor(t) return (typeColors[t] or "|cFFFFFFFF")..t.."|r" end

-- UID of the waypoint WE set, so we can clear it before setting the next one.
local lastWaypointUID = nil

local function SetDelveWaypoint(pin)
    if not pin or not pin.mapID then return end

    if TomTom then
        -- TomTom de-duplicates: AddWaypoint on coordinates that already hold a
        -- waypoint hands back the existing one WITHOUT re-announcing it or
        -- re-pointing the arrow. Clicking a delve, clicking others, then coming
        -- back to the first therefore looked like a dead button -- our chat line
        -- printed but TomTom stayed silent. Clearing ours first makes every
        -- click produce a genuinely fresh waypoint. (GitHub #6)
        if lastWaypointUID and TomTom.RemoveWaypoint then
            pcall(TomTom.RemoveWaypoint, TomTom, lastWaypointUID)
        end
        lastWaypointUID = nil
        local ok, uid = pcall(TomTom.AddWaypoint, TomTom, pin.mapID, pin.x, pin.y, {
            title      = pin.name,
            persistent = false,
            minimap    = true,
            world      = true,
            crazy      = true,   -- point the arrow at it, every time
        })
        if ok then lastWaypointUID = uid end
        print("|cFF00BFFF[DelveGuide]|r TomTom waypoint set: |cFFFFD700"..pin.name.."|r")
    else
        -- Without TomTom this used to set the waypoint and stop: a chat line, an
        -- opened map, and nothing on screen, because the waypoint was never
        -- super-tracked. Blizzard's own arrow does the job once it is.
        -- CanSetUserWaypointOnMap guards maps that refuse user waypoints.
        local placed = false
        pcall(function()
            if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(pin.mapID) then return end
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(pin.mapID, pin.x, pin.y))
            placed = true
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
        if placed then
            print("|cFF00BFFF[DelveGuide]|r Waypoint set: |cFFFFD700"..pin.name.."|r")
        else
            print("|cFF00BFFF[DelveGuide]|r |cFFFF4444Could not set a waypoint on this map.|r")
        end
    end

    -- Actually open the map. Both the widget and the Delves tab have always
    -- advertised "Click to open map & set waypoint", but nothing here ever
    -- opened it -- the tooltip was simply wrong for every user. (GitHub #6)
    pcall(function()
        if WorldMapFrame then
            if not InCombatLockdown() and not WorldMapFrame:IsShown() then ToggleWorldMap() end
            if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(pin.mapID) end
        end
    end)
end

local function FindPinByName(name)
    for _,p in ipairs(DelveGuideData.mapPins) do if p.name==name then return p end end
end

local scrollFrame,currentContent=nil,nil

-- ============================================================
-- CONTENT FRAME + WIDGET POOLS
-- ============================================================
-- The content frame used to be thrown away and rebuilt on every render
-- (Hide() + SetParent(nil)), which frees nothing: the orphan keeps every child
-- frame, FontString and closure alive until logout. A session of tab-switching
-- and window resizing therefore leaked hundreds of frames and steadily ate FPS.
--
-- One content frame now lives for the window's life and every widget drawn into
-- it comes from a pool that is released at the top of each render. This is the
-- same "build once, then Show/Hide/SetText" idiom the compact widget (f.varLines)
-- and the HUD (MakeRow) already use, applied to the tab renderers.
--
-- IMPORTANT for renderers: never call cf:CreateFontString / cf:CreateTexture /
-- CreateFrame(..., cf) at render time any more. The frame is permanent, so
-- anything created that way survives every render and stacks up on screen.
-- Use the UI.Acquire* helpers, or cache widgets per index and register a reset
-- with UI.AddCacheReset.
local pools = nil
local cacheResets = {}

local function ResetPooledFontString(_, fs)
    fs:Hide(); fs:ClearAllPoints()
    fs:SetDrawLayer("OVERLAY")
    -- The pool runs this on a freshly created string too, before any font is
    -- set, and SetText on a font-less FontString errors ("Font not set").
    if fs:GetFont() then fs:SetText("") end
    fs:SetWidth(0)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(1,1,1,1); fs:SetAlpha(1)
end

local function ResetPooledTexture(_, tex)
    tex:Hide(); tex:ClearAllPoints()
    tex:SetDrawLayer("ARTWORK")
    tex:SetTexture(nil)
    -- There is no ClearGradient; a white-to-white gradient is the neutral one,
    -- otherwise a released row highlight would tint whatever reused it.
    pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(1,1,1,1), CreateColor(1,1,1,1))
    tex:SetVertexColor(1,1,1,1); tex:SetAlpha(1)
end

local POOLED_SCRIPTS = {
    "OnEnter","OnLeave","OnClick","OnMouseDown","OnMouseUp","OnShow","OnHide",
    "OnUpdate","OnEditFocusGained","OnEscapePressed","OnEnterPressed","OnTextChanged",
}
local function ResetPooledFrame(_, f)
    f:Hide(); f:ClearAllPoints()
    for i = 1, #POOLED_SCRIPTS do
        local s = POOLED_SCRIPTS[i]
        if f:HasScript(s) then f:SetScript(s, nil) end
    end
    f:SetAlpha(1)
    if f.RegisterForClicks then f:RegisterForClicks("LeftButtonUp") end
    local bfs = f.GetFontString and f:GetFontString()
    if bfs and bfs:GetFont() then f:SetText("") end
    if f.SetChecked then f:SetChecked(false) end
    if f.ClearFocus then f:ClearFocus() end
    if f.SetBackdrop then f:SetBackdrop(nil) end
end

local function EnsurePools(cf)
    if pools then return end
    pools = {
        fontString  = CreateFontStringPool(cf, "OVERLAY", nil, nil, ResetPooledFontString),
        texture     = CreateTexturePool(cf, "ARTWORK", nil, nil, ResetPooledTexture),
        button      = CreateFramePool("Button", cf, nil, ResetPooledFrame),
        panelButton = CreateFramePool("Button", cf, "UIPanelButtonTemplate", ResetPooledFrame),
        checkButton = CreateFramePool("CheckButton", cf, "UICheckButtonTemplate", ResetPooledFrame),
        editBox     = CreateFramePool("EditBox", cf, "InputBoxTemplate", ResetPooledFrame),
        backdrop    = CreateFramePool("Frame", cf, "BackdropTemplate", ResetPooledFrame),
    }
end

local function NewContentFrame()
    if not currentContent then
        currentContent = CreateFrame("Frame",nil,scrollFrame)
        scrollFrame:SetScrollChild(currentContent)
        EnsurePools(currentContent)
    end
    local cf = currentContent
    for _, pool in pairs(pools) do pool:ReleaseAll() end
    for i = 1, #cacheResets do cacheResets[i]() end
    local w=scrollFrame:GetWidth(); if not w or w==0 then w=WINDOW_W-32 end
    cf:SetWidth(w); cf:SetHeight(2000); cf:Show(); return cf
end

-- Renderers that keep their own per-index widget cache register a hide-all here
-- so NewContentFrame can blank them the same way it releases the pools.
local function AddCacheReset(fn) cacheResets[#cacheResets+1] = fn end

-- Pooled objects all hang off the content frame; callers anchor them wherever
-- they like (anchoring across frames is fine) rather than reparenting, which
-- would mean putting the parent back on release.
local function AcquireFontString(layer, subLayer)
    local fs = pools.fontString:Acquire()
    if layer then fs:SetDrawLayer(layer, subLayer) end
    fs:Show(); return fs
end
local function AcquireTexture(layer, subLayer)
    local tex = pools.texture:Acquire()
    if layer then tex:SetDrawLayer(layer, subLayer) end
    tex:Show(); return tex
end
local function AcquireButton()        local b = pools.button:Acquire();      b:Show(); return b end
local function AcquirePanelButton()   local b = pools.panelButton:Acquire(); b:Show(); return b end
local function AcquireCheckButton()   local b = pools.checkButton:Acquire(); b:Show(); return b end
local function AcquireEditBox()       local b = pools.editBox:Acquire();     b:Show(); return b end
local function AcquireBackdropFrame() local f = pools.backdrop:Acquire();    f:Show(); return f end

local function CreateHeader(parent,y,text)
    EnsureFontFiles(); local hSize=GetScaledSizes()
    -- Pooled, so the font has to be re-applied on every acquire: the string may
    -- have last been used at a different font scale (A- / A+ / Reset).
    local fs=AcquireFontString("OVERLAY"); fs:SetFont(HEADER_FONT_FILE,hSize,"OUTLINE")
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-y); fs:SetWidth(parent:GetWidth()-16)
    fs:SetJustifyH("LEFT"); fs:SetTextColor(1,0.82,0,1); fs:SetText(text)
    
    local actualHeight = fs:GetStringHeight()
    return ((actualHeight and actualHeight > 0) and actualHeight or hSize) + 6
end

local function CreateRow(parent,y,text)
    EnsureFontFiles(); local _,rSize,rH=GetScaledSizes()
    local fs=AcquireFontString("OVERLAY"); fs:SetFont(ROW_FONT_FILE,rSize)
    fs:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-y); fs:SetWidth(parent:GetWidth()-16)
    fs:SetJustifyH("LEFT"); fs:SetText(text)
    local actualHeight = fs:GetStringHeight()
    local finalHeight = (actualHeight and actualHeight > 0) and actualHeight or rH
    
    return finalHeight
end

local function FormatResetTime(secs)
    if not secs or secs <= 0 then return "|cFFFF4444Now|r" end
    local d = math.floor(secs / 86400)
    local h = math.floor((secs % 86400) / 3600)
    local m = math.floor((secs % 3600) / 60)
    if d > 0 then return string.format("%dd %dh", d, h)
    elseif h > 0 then return string.format("%dh %dm", h, m)
    else return string.format("|cFFFF4444%dm|r", m) end
end

local function GetWeeklyVaultData()
    local delveCount, slots, maxThreshold, acts = 0, 0, 0, {}
    -- Midnight 12.0: Enum.WeeklyRewardItemTierType removed. Call GetActivities()
    -- with no argument and filter by type. Delves = WeeklyRewardChestThresholdType.World (6).
    local DELVE_TYPE = (Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World) or 6
    local ok, data = pcall(C_WeeklyRewards.GetActivities)
    if ok and type(data) == "table" then
        for _, a in ipairs(data) do
            if a.type == DELVE_TYPE then
                if a.progress > delveCount then delveCount = a.progress end
                if a.threshold > maxThreshold then maxThreshold = a.threshold end
                if a.progress >= a.threshold then slots = slots + 1 end
                -- Read the REAL reward item level from Blizzard instead of
                -- inferring it from a per-tier table. A vault slot pays at the
                -- level of your Nth-best activity (N = threshold), which no
                -- single run determines -- so a.level is the deciding tier and
                -- a.rewardIlvl is what you'll actually receive.
                pcall(function()
                    local link = C_WeeklyRewards.GetExampleRewardItemHyperlinks
                                 and C_WeeklyRewards.GetExampleRewardItemHyperlinks(a.id)
                    if link and C_Item and C_Item.GetDetailedItemLevelInfo then
                        local ilvl = C_Item.GetDetailedItemLevelInfo(link)
                        if type(ilvl) == "number" and ilvl > 0 then a.rewardIlvl = ilvl end
                    end
                end)
                table.insert(acts, a)
            end
        end
    end
    return delveCount, slots, maxThreshold, acts
end

-- D2: the Labyrinth run record. A Labyrinth grants Great Vault credit every
-- three chambers cleared (3 / 6 / 9), at any tier -- not on a boss kill. (The
-- Kindo'jan kill at Tier 8+ is a separate reward, the Heroic Soul Fragment,
-- and is not modelled here.) So the row is created the moment the third
-- chamber completes and updated at the sixth and ninth, with
-- vaultCredits = floor(chambers / 3). Called after every chamber completion
-- and once more on leave to settle the elapsed time.
-- kind="labyrinth" and no variant: rankings and /dg submit skip it. The weekly
-- vault tallies (Roster, Victory, History) sum vaultCredits, so one run can
-- count as up to three delves -- which for the vault it is.
DelveGuide.LogLabyrinthRun = function(name)
    if not (DelveGuideDB and DelveGuideDB.history and DelveGuideDB.labyrinthLog) then return end
    local chambers = 0
    for i = #DelveGuideDB.labyrinthLog, 1, -1 do
        local e = DelveGuideDB.labyrinthLog[i]
        if e.kind == "enter" and e.labyrinth == name then break end
        if e.kind == "chamber" then chambers = chambers + 1 end
    end
    local credits = math.floor(chambers / 3)
    local row = DelveGuide.currentLabyrinthRow
    if credits < 1 and not row then return end

    local resetKey = DelveGuide.GetResetKey()
    local charName, charRealm = "Unknown", nil
    pcall(function() charName = UnitName("player") or "Unknown" end)
    pcall(function() charRealm = GetRealmName() end)
    local elapsed = DelveGuide.labyrinthEnteredAt and (GetTime() - DelveGuide.labyrinthEnteredAt) or nil
    local vaultIlvl
    pcall(function()
        local _, _, _, acts = GetWeeklyVaultData()
        for _, a in ipairs(acts or {}) do
            if a.progress >= a.threshold and a.rewardIlvl and (not vaultIlvl or a.rewardIlvl > vaultIlvl) then vaultIlvl = a.rewardIlvl end
        end
    end)

    if not row then
        -- After a /reload the in-memory reference is gone. If history[1] is this
        -- visit's row (same Labyrinth, character and week, started within the
        -- last three hours), reattach rather than open a second row.
        local h1 = DelveGuideDB.history[1]
        if h1 and h1.kind == "labyrinth" and h1.name == name and h1.char == charName
           and h1.resetKey == resetKey and h1.startedEpoch and (time() - h1.startedEpoch) < 3 * 60 * 60 then
            row = h1
            DelveGuide.labyrinthCreditsAnnounced = row.vaultCredits or 0
        else
            row = { kind = "labyrinth", name = name, date = date("%Y-%m-%d %H:%M"), resetKey = resetKey,
                    startedEpoch = time() - math.floor(elapsed or 0), tier = "?", tierNum = nil,
                    char = charName, realm = charRealm, chambers = 0, vaultCredits = 0 }
            table.insert(DelveGuideDB.history, 1, row)
            if #DelveGuideDB.history > 200 then table.remove(DelveGuideDB.history) end
        end
        DelveGuide.currentLabyrinthRow = row
    end

    row.chambers     = math.max(row.chambers or 0, chambers)
    row.vaultCredits = math.max(row.vaultCredits or 0, credits)
    -- Tier from the header widget (read by the HUD's Labyrinth view). Kept as
    -- both tierNum and the display string the History tab expects.
    if DelveGuide.labyrinthTierNum then
        row.tierNum = DelveGuide.labyrinthTierNum
        row.tier    = "Tier " .. DelveGuide.labyrinthTierNum
    end
    if elapsed then row.elapsed = elapsed end
    if vaultIlvl and (not row.vaultIlvl or vaultIlvl > row.vaultIlvl) then row.vaultIlvl = vaultIlvl end

    if row.vaultCredits > (DelveGuide.labyrinthCreditsAnnounced or 0) then
        DelveGuide.labyrinthCreditsAnnounced = row.vaultCredits
        print(string.format("|cFF00BFFF[DelveGuide]|r Logged Labyrinth: |cFF00FF44%s|r  |cFF888888(%d chambers, %d vault credit%s)|r",
            name, row.chambers, row.vaultCredits, row.vaultCredits == 1 and "" or "s"))
        -- mainFrame / currentTabKey are declared further down the file, so from
        -- here they would resolve as globals; go through the exported UI table.
        if DelveGuide.UI and DelveGuide.UI.RefreshCurrentTab then DelveGuide.UI.RefreshCurrentTab() end
    end
end

-- Snapshot the current character's state into SavedVariables.
-- Called ONCE on PLAYER_ENTERING_WORLD — no polling, no OnUpdate.
-- Only caches characters level 80+ (current expansion).
local function CacheCurrentChar()
    if (UnitLevel("player") or 0) < 80 then return end

    local name  = UnitName("player") or "Unknown"
    local realm = GetRealmName()     or "Unknown"
    local charKey = name .. "-" .. realm

    local specName = "?"
    local specIcon = nil -- NEW: Store the spec icon
    pcall(function()
        local idx = GetSpecialization()
        if idx then
            local _, sName, _, icon = GetSpecializationInfo(idx)
            if sName then 
                specName = sName
                specIcon = icon 
            end
        end
    end)

    local ilvl = 0
    pcall(function()
        local _, overall = GetAverageItemLevel()
        ilvl = math.floor(overall or 0)
    end)

    local shards = 0
    pcall(function()
        local info = C_CurrencyInfo.GetCurrencyInfo(DelveGuideData.cofferKeys.SHARD_CURRENCY_ID)
        if info then shards = info.quantity or 0 end
    end)

    local bounty = C_Item.GetItemCount((DelveGuideData.trove and DelveGuideData.trove.ITEM_ID) or 0, true) or 0
    local restoredKeyInfo = C_CurrencyInfo.GetCurrencyInfo(DelveGuideData.cofferKeys.RESTORED_CURRENCY_ID)
    local restoredKeys = restoredKeyInfo and restoredKeyInfo.quantity or 0

    local resetKey = DelveGuide.GetResetKey()
    
    local delveCount = 0
    local weeklyRuns = {} 
    if resetKey and DelveGuideDB.history then
        for _, h in ipairs(DelveGuideDB.history) do
            if h.resetKey == resetKey and h.char == name then
                -- A Labyrinth row carries the vault credits it earned (one per
                -- three chambers); a delve row counts as one.
                delveCount = delveCount + (h.vaultCredits or 1)
                table.insert(weeklyRuns, h)
            end
        end
    end

    -- Highest reward item level actually unlocked this week. This used to store
    -- a.level (the deciding TIER, e.g. 8) into a field named maxVaultIlvl and
    -- render it as an item level -- so the Roster showed "8 ilvl".
    local _, vaultSlots, _, acts = GetWeeklyVaultData()
    local maxVaultIlvl = 0
    for _, a in ipairs(acts) do
        if a.progress >= a.threshold then
            local ilvl = a.rewardIlvl
            if not ilvl and a.level and a.level > 0 and DelveGuideData.tierRewards[a.level] then
                ilvl = DelveGuideData.tierRewards[a.level].vault
            end
            if ilvl and ilvl > maxVaultIlvl then maxVaultIlvl = ilvl end
        end
    end

    -- Per-slot vault snapshot so the Roster tooltip can show each slot's
    -- progress and reward for ALTS too (they aren't logged in to query the API).
    local vaultDetail = {}
    for _, a in ipairs(acts) do
        local ilvl = a.rewardIlvl
        if not ilvl and a.level and a.level > 0 and DelveGuideData.tierRewards[a.level] then
            ilvl = DelveGuideData.tierRewards[a.level].vault
        end
        table.insert(vaultDetail, {
            threshold = a.threshold,
            progress  = a.progress,
            tier      = (a.level and a.level > 0) and a.level or nil,
            ilvl      = ilvl,
        })
    end
    table.sort(vaultDetail, function(x, y) return (x.threshold or 0) < (y.threshold or 0) end)

    -- Voidforge snapshot for the cross-character stockpile in the Voidforge tab.
    local voidforge = nil
    if DelveGuide.GetVoidforgeStatus then
        local ok, vf = pcall(DelveGuide.GetVoidforgeStatus)
        if ok and vf and vf.configured then
            voidforge = {
                cores       = vf.cores,
                venomstones = vf.venomstones,
            }
        end
    end

    DelveGuideDB.roster[charKey] = {
        name         = name,
        realm        = realm,
        specName     = specName,
        specIcon     = specIcon,
        ilvl         = ilvl,
        shards       = shards,
        restoredKeys = restoredKeys,
        bounty       = bounty,
        delveCount   = delveCount,
        weeklyRuns   = weeklyRuns,
        vaultSlots   = vaultSlots,
        maxVaultIlvl = maxVaultIlvl,
        vaultDetail  = vaultDetail,
        voidforge    = voidforge,
        lastSeen     = date("%Y-%m-%d"),
        resetKey     = resetKey,
    }
end

-- ---- What's New popup ----
local changelogFrame

local function ShowChangelogPopup()
    if not changelogFrame then
        local BACKDROP = {
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 16,
            insets = { left=4, right=4, top=4, bottom=4 },
        }
        local f = CreateFrame("Frame", "DelveGuideChangelogFrame", UIParent, "BackdropTemplate")
        tinsert(UISpecialFrames, "DelveGuideChangelogFrame")   -- ESC closes it
        f:SetSize(440, 460)
        f:SetBackdrop(BACKDROP)
        f:SetBackdropColor(0, 0, 0, 0.95)
        f:SetBackdropBorderColor(0.1, 0.5, 1, 1)
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop",  f.StopMovingOrSizing)
        f:SetPoint("CENTER")

        -- Title bar
        local bar = f:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -4)
        bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
        bar:SetHeight(28); bar:SetColorTexture(0.05, 0.25, 0.55, 0.95)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)
        title:SetText("|cFF3399FFDelveGuide|r  --  What's New")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Scroll area
        local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",  12,  -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 44)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(scrollFrame:GetWidth() or 380)
        scrollFrame:SetScrollChild(content)

        -- Populate content
        local ROW_FONT  = "Fonts\\FRIZQT__.TTF"
        local cy = 0
        local isFirst = true

        for _, block in ipairs(DelveGuideData.changelog) do
            local verLabel = content:CreateFontString(nil, "OVERLAY")
            verLabel:SetFont(ROW_FONT, isFirst and 13 or 11)
            verLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -cy)
            verLabel:SetWidth(content:GetWidth())
            if isFirst then
                verLabel:SetText("|cFF3399FFv" .. block.version .. "|r  |cFF888888- " .. block.date .. "|r")
            else
                verLabel:SetText("|cFF666666v" .. block.version .. "  - " .. block.date .. "|r")
            end
            cy = cy + (isFirst and 20 or 17)

            -- Entries
            for _, entry in ipairs(block.entries) do
                local bullet = content:CreateFontString(nil, "OVERLAY")
                bullet:SetFont(ROW_FONT, isFirst and 11 or 10)
                bullet:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -cy)
                bullet:SetWidth(content:GetWidth() - 10)
                bullet:SetJustifyH("LEFT")
                if isFirst then
                    bullet:SetText("|cFFCCCCCC• " .. entry .. "|r")
                else
                    bullet:SetText("|cFF555555• " .. entry .. "|r")
                end
                bullet:SetWordWrap(true)
                cy = cy + bullet:GetStringHeight() + 4
            end

            cy = cy + (isFirst and 12 or 8)
            isFirst = false
        end

        content:SetHeight(math.max(cy, 10))

        -- "Got it!" button
        local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        okBtn:SetSize(100, 26); okBtn:SetText("Got it!")
        okBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
        okBtn:SetScript("OnClick", function() f:Hide() end)

        changelogFrame = f
    end

    changelogFrame:Show()
end

-- ============================================================
-- GLOBAL UI HELPERS (For external UI modules)
-- ============================================================
DelveGuide.UI = {
    NewContentFrame = NewContentFrame,
    CreateHeader    = CreateHeader,
    CreateRow       = CreateRow,
    GetScaledSizes  = GetScaledSizes,
    EnsureFontFiles = EnsureFontFiles,
    AddCacheReset        = AddCacheReset,
    AcquireFontString    = AcquireFontString,
    AcquireTexture       = AcquireTexture,
    AcquireButton        = AcquireButton,
    AcquirePanelButton   = AcquirePanelButton,
    AcquireCheckButton   = AcquireCheckButton,
    AcquireEditBox       = AcquireEditBox,
    AcquireBackdropFrame = AcquireBackdropFrame,
    WINDOW_W        = WINDOW_W,
    GradeColor      = GradeColor,
    StripEscapes    = DelveGuide.StripEscapes,
    ZoneColor       = ZoneColor,
    TypeColor       = TypeColor,
    RANK_COLORS     = RANK_COLORS,
    SetDelveWaypoint= SetDelveWaypoint,
    FindPinByName   = FindPinByName,
    GetWeeklyVaultData = GetWeeklyVaultData,
    ShowChangelogPopup = ShowChangelogPopup,
    RefreshCurrentTab  = function() if RefreshCurrentTab then RefreshCurrentTab() end end,
    UpdateMinimap      = function() if icon then if DelveGuideDB.minimap.hide then icon:Hide("DelveGuide") else icon:Show("DelveGuide") end end end,
    -- Showing must also refresh: UpdateCompactWidget bails while hidden, so a
    -- widget toggled back on would otherwise display stale/empty content.
    UpdateWidgetVis    = function()
        if DelveGuide.compactWidget then
            if DelveGuideDB.widgetHidden then
                DelveGuide.compactWidget:Hide()
            else
                DelveGuide.compactWidget:Show()
                if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end
            end
        end
    end,
    UpdateWidgetAlpha  = function() if DelveGuide.compactWidget then DelveGuide.compactWidget:SetAlpha(DelveGuideDB.widgetAutoHide and 0.15 or 1.0) end end,
    UpdateCompactWidget= function() if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end end,
}

local tabRenderers = {}

local mainFrame,tabButtons,currentTabKey=nil,{},nil

-- Set when a refresh was asked for while the window was hidden. Redrawing a tab
-- nobody can see is pure cost, and POI/currency updates ask for it constantly.
local tabDirty = false

local function SwitchTab(key)
    -- Only a real tab change jumps back to the top. SwitchTab is also the
    -- redraw path (RefreshCurrentTab, the OnShow dirty repaint), and those
    -- used to yank the list to the top on every POI/font/currency update.
    local prevKey = currentTabKey
    currentTabKey = key
    tabDirty = false

    for _, td in ipairs(TABS) do
        local btn = tabButtons[td.key]
        if td.key == key then 
            btn.Text:SetTextColor(1, 0.82, 0, 1)
            btn.Underline:Show()
        else 
            btn.Text:SetTextColor(0.5, 0.5, 0.5, 1)
            btn.Underline:Hide() 
        end
    end
    
    local globalFuncName = "Render" .. key:gsub("^%l", string.upper)
    
    local r = tabRenderers[key] or DelveGuide[globalFuncName]
    
    if r then
        -- Contain the renderer. An error part-way through a tab used to leave a
        -- half-drawn page behind AND take out whatever called us -- and since
        -- POI updates call RefreshCurrentTab, it repeated on every update. The
        -- error still reaches the player's error handler (BugSack, or the
        -- default display); we just also throw the wreckage away and say so.
        local eh = geterrorhandler()
        local errMsg
        local ok = xpcall(r, function(err) errMsg = err; return eh(err) end)
        if not ok then
            -- Exposed so /dg selftest (which pcalls SwitchTab and can no longer
            -- see the error itself) and the Debug tab have something to read.
            DelveGuide.lastRenderError = { key = key, err = errMsg }
            local cf = NewContentFrame()
            local y = 8
            y = y + CreateRow(cf, y, "|cFFFF4444The " .. key .. " tab failed to render.|r") + 4
            CreateRow(cf, y, "|cFF888888Try /reload. If it keeps happening, report it with the version from /dg help.|r")
        end
        if key ~= prevKey then
            scrollFrame:SetVerticalScroll(0)
        end
    end
end

RefreshCurrentTab = function()
    if currentTabKey and mainFrame and mainFrame:IsShown() then
        -- A refresh is not a tab change: put the player back where they were.
        local prev = scrollFrame and scrollFrame:GetVerticalScroll() or 0
        SwitchTab(currentTabKey)
        if scrollFrame then
            scrollFrame:SetVerticalScroll(math.min(prev, scrollFrame:GetVerticalScrollRange()))
        end
    else
        tabDirty = true
    end
end

local function CreateMainWindow()
    local f=CreateFrame("Frame","DelveGuideFrame",UIParent,"BackdropTemplate")
    -- ESC closes it, like every other WoW window. Requested by a submitter, and
    -- it had simply never been wired up -- UISpecialFrames needs the frame's
    -- GLOBAL name, which is why both windows here are named rather than anonymous.
    tinsert(UISpecialFrames, "DelveGuideFrame")
    
    -- Load saved size or default to WINDOW_W / WINDOW_H
    local startW = DelveGuideDB.windowW or WINDOW_W
    local startH = DelveGuideDB.windowH or WINDOW_H
    f:SetSize(startW, startH); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    
    -- Enable Resizing!
    f:SetResizable(true)
    f:SetResizeBounds(600, 400, 1200, 900) -- Min Width, Min Height, Max Width, Max Height
    
    f:SetScript("OnDragStart",f.StartMoving)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); DelveGuideDB.windowX=self:GetLeft(); DelveGuideDB.windowY=self:GetTop() end)
    
    if DelveGuideDB.windowX then f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",DelveGuideDB.windowX,DelveGuideDB.windowY)
    else f:SetPoint("CENTER") end
    
    f:SetFrameStrata("HIGH"); f:Hide()
    f:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=false,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(0.08,0.08,0.08,0.92); f:SetBackdropBorderColor(0.2,0.2,0.2,1)
    
    local closeBtn=CreateFrame("Button",nil,f,"UIPanelCloseButton"); closeBtn:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
    f.TitleText=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    f.TitleText:SetPoint("TOPLEFT",f,"TOPLEFT",16,-12); f.TitleText:SetText("|cFF00BFFFDelveGuide|r |cFF888888v"..ADDON_VERSION.."|r -- Midnight Reference")
    f.TrackerText=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.TrackerText:SetPoint("TOPRIGHT",f,"TOPRIGHT",-40,-14)
    
    -- Resize Grip Handle
    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then f:StartSizing("BOTTOMRIGHT") end
    end)
    resizeGrip:SetScript("OnMouseUp", function(self, btn)
        f:StopMovingOrSizing()
        -- Save new size to DB
        DelveGuideDB.windowW = f:GetWidth()
        DelveGuideDB.windowH = f:GetHeight()
        RefreshCurrentTab() -- Redraw tab to fill new space
    end)
    
    f.UpdateTracker = function()
        local CK = DelveGuideData.cofferKeys
        local keysInfo = C_CurrencyInfo.GetCurrencyInfo(CK.SHARD_CURRENCY_ID)
        local shards = keysInfo and keysInfo.quantity or 0
        local weeklyCap = keysInfo and keysInfo.maxWeeklyQuantity or CK.SHARD_WEEKLY_CAP
        local weeklyEarned = keysInfo and keysInfo.quantityEarnedThisWeek or 0
        local delveCount, vaultSlots, maxThreshold = GetWeeklyVaultData()
        local vaultProgress = math.min(delveCount, maxThreshold)
        local wqCount = 0
        local seenQuests = {}

        -- Shared zone list: this was a third hardcoded copy and, like the Debug
        -- tab's, never gained the Coiled Isle -- so Season 2 world quests
        -- rewarding Coffer Key Shards weren't counted. Quests are deduped by
        -- questID below, so overlapping maps are harmless.
        for _, z in ipairs(ALL_ZONE_MAP_IDS) do
            local quests = C_TaskQuest.GetQuestsOnMap(z)
            if quests then
                for _, q in ipairs(quests) do
                    if not seenQuests[q.questID] and C_QuestLog.IsWorldQuest(q.questID) and not C_QuestLog.IsQuestFlaggedCompleted(q.questID) then
                        seenQuests[q.questID] = true
                        local curs = C_QuestLog.GetQuestRewardCurrencies(q.questID)
                        if curs then
                            for _, c in ipairs(curs) do
                                if c.currencyID == COFFER_KEY_SHARD_ID then
                                    wqCount = wqCount + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        local resetSecs = C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset() or nil
        local resetText = resetSecs and FormatResetTime(resetSecs) or "|cFF888888?|r"

        local keysText
        if weeklyCap > 0 and weeklyEarned >= weeklyCap then
            keysText = string.format("|cFF00FF44%d/%d (Capped)|r", shards, weeklyCap)
        else
            keysText = string.format("%d/%d", shards, weeklyCap > 0 and weeklyCap or CK.SHARD_WEEKLY_CAP)
        end

        f.TrackerText:SetText(string.format(
            "|cFFFFD700Keys:|r %s  |  |cFF00BFFFDelves:|r %d  |cFF888888(Vault %d/%d)|r  |  |cFF00FF88WQs:|r %d  |  |cFFAAAA00Reset:|r %s",
            keysText, delveCount, vaultProgress, maxThreshold, wqCount, resetText
        ))
    end
    f:HookScript("OnShow", function(self)
        self.UpdateTracker(self)
        -- 2.1f: RefreshCurrentTab skips redrawing while the window is hidden
        -- and sets tabDirty instead; paint it now that it can be seen.
        if tabDirty and currentTabKey then SwitchTab(currentTabKey) end
    end)
    
    local tabW=(startW-32)/#TABS
    for i,td in ipairs(TABS) do
        local btn=CreateFrame("Button","DelveGuideTab_"..td.key,f); btn:SetSize(tabW-4,TAB_HEIGHT)
        btn:SetPoint("TOPLEFT",f,"TOPLEFT",16+(i-1)*tabW,-36)
        btn.Text=btn:CreateFontString(nil,"OVERLAY","GameFontNormal"); btn.Text:SetPoint("CENTER"); btn.Text:SetText(td.label)
        btn.Underline=btn:CreateTexture(nil,"ARTWORK"); btn.Underline:SetColorTexture(1,0.82,0,1)
        btn.Underline:SetPoint("BOTTOM",btn,"BOTTOM",0,2); btn.Underline:SetSize(btn.Text:GetStringWidth()+16,2); btn.Underline:Hide()
        local k=td.key; btn:SetScript("OnClick",function() SwitchTab(k) end); tabButtons[k]=btn
    end
    -- The Debug tab is for bug reports and localisation work, not daily use.
    -- Hidden unless the Settings checkbox turns it on. It is the LAST tab, so
    -- hiding its button leaves trailing space rather than a gap in the row.
    if tabButtons.debug and not (DelveGuideDB and DelveGuideDB.showDebugTab) then tabButtons.debug:Hide() end
    
    -- Dynamically scale tabs and the UI layout variable when dragged!
    f:HookScript("OnSizeChanged", function(self, width, height)
        DelveGuide.UI.WINDOW_W = width
        local newTabW = (width - 32) / #TABS
        for i, td in ipairs(TABS) do
            local btn = tabButtons[td.key]
            if btn then
                btn:SetWidth(newTabW - 4)
                btn:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + (i - 1) * newTabW, -36)
            end
        end
    end)
    
    local sf=CreateFrame("ScrollFrame","DelveGuideScrollFrame",f,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",f,"TOPLEFT",16,-(36+TAB_HEIGHT+10)); sf:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,8)
    scrollFrame=sf; mainFrame=f; SwitchTab(TABS[1].key)
end

function DelveGuide.Toggle()
    if not mainFrame then CreateMainWindow() end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end

-- Settings checkbox target. Hiding the tab while it is the one being viewed
-- switches to Delves so the window never shows a tab it has no button for.
DelveGuide.SetDebugTabShown = function(shown)
    local btn = tabButtons.debug
    if not btn then return end
    if shown then btn:Show() else
        btn:Hide()
        if currentTabKey == "debug" then SwitchTab("delves") end
    end
end


-- ============================================================
-- MINIMAP BUTTON (LibDataBroker & LibDBIcon)
-- ============================================================
local LDB = LibStub("LibDataBroker-1.1")
icon = LibStub("LibDBIcon-1.0")

local DelveGuideLDB = LDB:NewDataObject("DelveGuide", {
    type = "data source",
    text = "DelveGuide",
    icon = "Interface\\Icons\\INV_Misc_Map09",
    OnClick = function(_, button)
        if button == "LeftButton" then
            DelveGuide.Toggle()
        elseif button == "RightButton" then
            -- Open directly to settings tab on right-click!
            if not mainFrame or not mainFrame:IsShown() then DelveGuide.Toggle() end
            SwitchTab("settings")
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cFF00BFFFDelveGuide|r")
        tooltip:AddLine("Left-Click to open/close.", 1, 1, 1)
        tooltip:AddLine("Right-Click for Settings.", 0.7, 0.7, 0.7)
    end,
})

local function UpdateLDBText()
    -- Shards
    local shards = 0
    pcall(function()
        local info = C_CurrencyInfo.GetCurrencyInfo(3310)
        if info then shards = info.quantity or 0 end
    end)

    -- Best active variant
    local bestVariant, bestRank = nil, 99
    local rankOrder = {S=1, A=2, B=3, C=4, D=5, F=6}
    if DelveGuideData and DelveGuideData.delves then
        local seen = {}
        for _, d in ipairs(DelveGuideData.delves) do
            if activeVariants[d.variant] and not seen[d.variant] then
                seen[d.variant] = true
                local r = rankOrder[d.ranking] or 99
                if r < bestRank then bestRank = r; bestVariant = d.variant; end
            end
        end
    end

    -- Vault
    local delveCount, _, maxThreshold = GetWeeklyVaultData()
    local vaultProgress = math.min(delveCount, maxThreshold > 0 and maxThreshold or 8)

    -- Format
    local parts = {}
    table.insert(parts, string.format("Keys: %d/600", shards))
    if bestVariant then
        local gradeLetter = "?"
        for letter, order in pairs(rankOrder) do if order == bestRank then gradeLetter = letter; break end end
        table.insert(parts, string.format("[%s] %s", gradeLetter, bestVariant))
    end
    table.insert(parts, string.format("Vault: %d/%d", vaultProgress, maxThreshold > 0 and maxThreshold or 8))

    DelveGuideLDB.text = table.concat(parts, " | ")
end
DelveGuide.UpdateLDBText = UpdateLDBText

SLASH_DELVEGUIDE1="/delveguide"; SLASH_DELVEGUIDE2="/dg"
SlashCmdList["DELVEGUIDE"]=function(msg)
    msg=strtrim(msg:lower())
    if msg=="hide" then if mainFrame then mainFrame:Hide() end
    elseif msg=="show" then if not mainFrame then CreateMainWindow() end; mainFrame:Show()
    elseif msg=="map" then ToggleWorldMap()
    elseif msg=="scan" then
        ScanActiveVariants(); RefreshCurrentTab()
        local vc,dc=0,0
        for _ in pairs(activeVariants) do vc=vc+1 end
        for _ in pairs(activeDelves) do dc=dc+1 end
        print(string.format("|cFF00BFFF[DelveGuide]|r Scan: |cFF44FF44%d|r delves, |cFF44FF44%d|r variants.",dc,vc))
        if vc>0 then
            local list={}; for v in pairs(activeVariants) do table.insert(list,v) end
            print("|cFF00BFFF[DelveGuide]|r Active variants: "..table.concat(list,", "))
        end
    elseif msg=="chatdump" then
        print("|cFF00BFFF[DelveGuide]|r === LOCALIZATION DUMP (share this output) ===")
        print("Version: "..ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
        if #rawScanResults==0 then
            print("|cFFFF4444No scan data. Run /dg scan first.|r")
            print("Checked map IDs: "..table.concat(ALL_ZONE_MAP_IDS,", "))
        else
            for _,r in ipairs(rawScanResults) do
                print(string.format("mapID=%s  poiID=%s  name=[%s]  atlas=[%s]  set=%s",
                    tostring(r.mapID),tostring(r.poiID),tostring(r.name),tostring(r.atlasName),tostring(r.widgetSetID)))
                if r.widgetTexts and #r.widgetTexts>0 then
                    for i,t in ipairs(r.widgetTexts) do
                        print(string.format("  text[%d]=[%s]",i,t))
                    end
                else
                    print("  (no widget texts)")
                end
            end
        end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="findplaza" then
        -- Brute-force scan a range of map IDs looking for Parhelion Plaza's POI.
        -- Run this if Parhelion Plaza isn't showing in Active Today — report the
        -- map ID that appears, so it can be added to ALL_ZONE_MAP_IDS.
        print("|cFF00BFFF[DelveGuide]|r Scanning map IDs 2200-2700 for Parhelion Plaza...")
        local found = 0
        for mapID = 2200, 2700 do
            local ok, poiIDs = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
            if ok and poiIDs and #poiIDs > 0 then
                for _, poiID in ipairs(poiIDs) do
                    local okInfo, info = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
                    if okInfo and info and info.name and string.find(info.name, "Parhelion", 1, true) then
                        print(string.format("|cFF44FF44FOUND: mapID=%d poiID=%d name=[%s] set=%s|r",
                            mapID, poiID, info.name, tostring(info.tooltipWidgetSet or 0)))
                        found = found + 1
                    end
                end
            end
        end
        print(string.format("|cFF00BFFF[DelveGuide]|r Scan complete. Found %d Parhelion POI(s).", found))
        if found == 0 then
            print("|cFFFF4444Not found in 2200-2700. POI may be exposed only when delve is in rotation, or lives on an unusual map ID.|r")
        end
    elseif msg=="dump" then
        print("|cFF00BFFF[DelveGuide]|r === RAW POI FIELD DUMP ===")
        local found=0
        for _,mapID in ipairs(ALL_ZONE_MAP_IDS) do
            local poiIDs=C_AreaPoiInfo.GetDelvesForMap(mapID)
            if poiIDs and #poiIDs>0 then
                local info=C_AreaPoiInfo.GetAreaPOIInfo(mapID,poiIDs[1])
                print(string.format("|cFFFFD700mapID=%-6d  poiID=%d|r",mapID,poiIDs[1]))
                if info then
                    for k,v in pairs(info) do
                        local vs=tostring(v); local c=(vs=="" or vs=="false" or vs=="0") and "|cFF888888" or "|cFF44FF44"
                        print(string.format("  |cFFCCCCCC%-22s|r = %s%s|r",tostring(k),c,vs))
                    end; found=found+1
                else print("  |cFFFF4444(nil)|r") end
                if found>=2 then break end
            end
        end
        if found==0 then print("|cFFFF4444No delves found.|r") end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="export" then
        -- Capture a structured snapshot into SavedVariables so PTR data
        -- can be pulled from disk instead of copied out of chat. Run it
        -- inside each delve (and once outside), then /reload to flush.
        DelveGuideDB.ptrExports = DelveGuideDB.ptrExports or {}
        local snap = { at = date("%Y-%m-%d %H:%M:%S"), build = {GetBuildInfo()} }
        pcall(function() snap.zone = GetRealZoneText(); snap.subzone = GetSubZoneText() end)
        pcall(function()
            local name, instType, diffID, diffName, _, _, _, instanceID = GetInstanceInfo()
            snap.instance = {name=name, type=instType, diffID=diffID, diffName=diffName, instanceID=instanceID}
        end)
        pcall(function()
            if C_Scenario and C_Scenario.GetInfo then snap.scenario = {C_Scenario.GetInfo()} end
            if C_Scenario and C_Scenario.GetStepInfo then snap.scenarioStep = {C_Scenario.GetStepInfo()} end
        end)
        pcall(function()
            local mapID = C_Map.GetBestMapForUnit("player")
            snap.mapID = mapID
            if mapID then
                local info = C_Map.GetMapInfo(mapID)
                snap.mapName = info and info.name
                snap.parentMapID = info and info.parentMapID
                local pos = C_Map.GetPlayerMapPosition(mapID, "player")
                if pos then snap.pos = {x=pos.x, y=pos.y} end
            end
        end)
        pcall(function()
            if C_DelvesUI and C_DelvesUI.HasActiveLair then snap.hasActiveLair = C_DelvesUI.HasActiveLair() end
            if C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer then snap.companionID = C_DelvesUI.GetCompanionInfoForActivePlayer() end
        end)
        pcall(function()
            local state, count, hasAura, weeklyDone = DelveGuide.GetTroveStatus()
            snap.troveState  = state
            snap.bountyAura  = hasAura
            snap.bountyCount = count
            snap.troveWeekly = weeklyDone
        end)
        pcall(function()
            snap.delversCallQuests = {}
            for i = 1, C_QuestLog.GetNumQuestLogEntries() do
                local q = C_QuestLog.GetInfo(i)
                if q and not q.isHeader and q.title and q.title:find("Delver") then
                    table.insert(snap.delversCallQuests, {id=q.questID, title=q.title})
                end
            end
        end)
        pcall(function()
            snap.delvePOIs = {}
            local maps, seen = {}, {}
            for _, m in ipairs(ALL_ZONE_MAP_IDS) do table.insert(maps, m) end
            if snap.mapID then table.insert(maps, snap.mapID) end
            if snap.parentMapID then table.insert(maps, snap.parentMapID) end
            for _, mapID in ipairs(maps) do
                if not seen[mapID] then
                    seen[mapID] = true
                    local poiIDs = C_AreaPoiInfo.GetDelvesForMap(mapID)
                    if poiIDs then
                        for _, poiID in ipairs(poiIDs) do
                            local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                            if info then
                                table.insert(snap.delvePOIs, {mapID=mapID, poiID=poiID, name=info.name, atlas=info.atlasName, set=info.tooltipWidgetSet})
                            end
                        end
                    end
                end
            end
        end)
        -- API presence probe, shared with /dg selftest (see ProbeAPIs).
        pcall(function() snap.api, snap.apiMissing = ProbeAPIs() end)

        -- Objective-tracker widget set: settles whether lives are a criterion
        -- or a header widget (see DumpObjectiveTrackerWidgets).
        pcall(function() snap.trackerWidgets, snap.trackerWidgetSetID = DumpObjectiveTrackerWidgets() end)

        -- The scenario step's widget set: tier badge and lives live here.
        pcall(function()
            snap.stepWidgetSetID = GetStepWidgetSetID()
            snap.stepWidgets = DumpWidgetSet(snap.stepWidgetSetID)
        end)

        -- Scenario criteria, through the 12.1.5-safe helpers.
        pcall(function()
            snap.criteria = {}
            local n = DelveGuide.GetCriteriaCount and DelveGuide.GetCriteriaCount() or 0
            snap.criteriaCount = n
            for i = 1, n do
                local c = DelveGuide.GetCriteria(i)
                if c then
                    table.insert(snap.criteria, {
                        id = c.criteriaID, desc = c.description, qty = c.quantity,
                        total = c.totalQuantity, qtyStr = c.quantityString,
                        completed = c.completed, failed = c.failed, assetID = c.assetID,
                        elapsed = c.elapsed, duration = c.duration,
                        ctype = c.criteriaType, cflags = c.flags,
                    })
                end
            end
        end)

        -- Modern scenario structs, which carry named fields the positional
        -- C_Scenario.GetInfo array does not.
        pcall(function()
            if C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo then
                local si = C_ScenarioInfo.GetScenarioInfo()
                if si then
                    snap.scenarioInfo = {
                        name = si.name, scenarioID = si.scenarioID, type = si.type,
                        flags = si.flags, currentStage = si.currentStage,
                        numStages = si.numStages, isComplete = si.isComplete, area = si.area,
                    }
                end
            end
            if C_ScenarioInfo and C_ScenarioInfo.GetScenarioStepInfo then
                local st = C_ScenarioInfo.GetScenarioStepInfo()
                if st then
                    snap.scenarioStepInfo = {
                        title = st.title, description = st.description,
                        numCriteria = st.numCriteria, stageID = st.stageID,
                        isComplete = st.isComplete,
                    }
                end
            end
        end)

        -- Delve tier struct. Returned all zeros inside a Labyrinth on 69594;
        -- captured in full so the shape can be compared across content types.
        pcall(function()
            if C_DelvesUI and C_DelvesUI.GetActiveDelveTier then
                local t = C_DelvesUI.GetActiveDelveTier()
                if type(t) == "table" then
                    snap.delveTier = {
                        tier = t.tier, unlocked = t.unlocked, difficultyID = t.difficultyID,
                        suggestedILvl = t.suggestedILvl, tierDescription = t.tierDescription,
                        modifierUIWidgetSetID = t.modifierUIWidgetSetID,
                        overrideTooltipSpellID = t.overrideTooltipSpellID,
                        queueAsLFG = t.queueAsLFG,
                    }
                else
                    snap.delveTier = { raw = tostring(t) }
                end
            end
        end)

        -- Outdoor POI widget texts, so the variant-text question no longer needs
        -- /dg scan + /dg chatdump pasted into chat. Populated only if a scan has
        -- run this session.
        pcall(function()
            snap.zoneEnglish = localizedToEnglish and localizedToEnglish[GetRealZoneText() or ""] or nil
            snap.rawScan = {}
            for _, r in ipairs(rawScanResults or {}) do
                table.insert(snap.rawScan, {
                    mapID = r.mapID, poiID = r.poiID, name = r.name,
                    atlas = r.atlasName, set = r.widgetSetID, texts = r.widgetTexts,
                    meta = r.widgetMeta,
                })
            end
        end)

        -- Faction ID sweep. GetNumFactions does not enumerate warband
        -- reputations: "Delves: Season 2" and "The Labyrinth of Kindo'jan" both
        -- award rep in chat yet neither appears in the list even with every
        -- header expanded. GetFactionDataByID answers for them directly, so
        -- sweep the modern ID range and keep whatever returns a name. A first
        -- pass over 2400-2900 returned 130+ factions but neither target (top hit
        -- 2838), so the new warband reps sit above that -- widened to 2200-3400.
        pcall(function()
            snap.factionSweep = {}
            if C_Reputation and C_Reputation.GetFactionDataByID then
                for id = 2200, 3400 do
                    local d = C_Reputation.GetFactionDataByID(id)
                    if d and d.name and d.name ~= "" then
                        table.insert(snap.factionSweep, {
                            id = id, name = d.name, standing = d.currentStanding,
                            reaction = d.reaction, nextThreshold = d.nextReactionThreshold,
                        })
                    end
                end
            end
        end)

        -- Watched faction. Warband reputations answer to neither GetNumFactions
        -- nor a GetFactionDataByID sweep of 2200-3400, but GetWatchedFactionData
        -- returns the factionID of whatever the player is tracking on the XP bar.
        -- Track "The Labyrinth of Kindo'jan" (or "Delves: Season 2") and export
        -- to capture its ID directly.
        pcall(function()
            if C_Reputation and C_Reputation.GetWatchedFactionData then
                local w = C_Reputation.GetWatchedFactionData()
                if w then
                    snap.watchedFaction = {
                        id = w.factionID, name = w.name, standing = w.currentStanding,
                        reaction = w.reaction, nextThreshold = w.nextReactionThreshold,
                    }
                end
            end
        end)

        -- Direct probe of factionID 2836, which WoWhead lists as "The Labyrinth
        -- of Kindo'jan". The 2200-3400 sweep already called this ID and kept
        -- nothing because it filters on a non-empty name; record the raw return
        -- here so "exists but unnamed client-side" is distinguishable from "nil".
        pcall(function()
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local d = C_Reputation.GetFactionDataByID(2836)
                snap.faction2836 = d and {
                    name = d.name, standing = d.currentStanding, reaction = d.reaction,
                    nextThreshold = d.nextReactionThreshold, isHeader = d.isHeader,
                    isAccountWide = d.isAccountWide,
                } or "nil"
            end
        end)

        -- Major factions (renown). The new Kindo'jan reputation did not appear
        -- in the standard C_Reputation list even with every header expanded, so
        -- it is probably a renown track rather than a classic faction.
        pcall(function()
            snap.majorFactions = {}
            if C_MajorFactions and C_MajorFactions.GetMajorFactionIDs then
                for _, id in ipairs(C_MajorFactions.GetMajorFactionIDs() or {}) do
                    local d = C_MajorFactions.GetMajorFactionData(id)
                    if d then
                        table.insert(snap.majorFactions, {
                            id = id, name = d.name, renown = d.renownLevel,
                            current = d.renownReputationEarned,
                            needed = d.renownLevelThreshold,
                            unlocked = d.isUnlocked,
                        })
                    end
                end
            end
        end)

        -- Equipped gloves: link, parsed enchant ID, item level. The first export
        -- taken with a 12.1.5 delve glove enhancement applied gives the enchant
        -- ID that DelveGuideData.delveGloveEnhancements is keyed on.
        pcall(function()
            local link = GetInventoryItemLink("player", INVSLOT_HAND or 10)
            if link then
                local ilvl
                if C_Item and C_Item.GetDetailedItemLevelInfo then
                    local ok, eff = pcall(C_Item.GetDetailedItemLevelInfo, link)
                    if ok then ilvl = eff end
                end
                snap.gloves = { link = link, enchantID = tonumber(link:match("item:%d+:(%d+):")) or 0, ilvl = ilvl }
            end
        end)

        -- Where the player is standing: the map the client considers current
        -- and the position on it. Replaces a hand-typed /dump with a guessed
        -- map ID (2512 came back empty at Venomfall Deeps -- wrong map).
        pcall(function()
            local mapID = C_Map.GetBestMapForUnit("player")
            local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
            local info = mapID and C_Map.GetMapInfo(mapID)
            snap.playerMap = { mapID = mapID, name = info and info.name,
                x = pos and pos.x, y = pos and pos.y }
        end)

        -- A vendor window that is open right now: every item with its price
        -- and currency. Run /dg export with the delve vendor open and the
        -- cosmetic rows' IDs, sources and costs come straight from the game.
        -- First attempt (export #35, Naleidea Rivergleam) recorded the NPC and
        -- zero items: one of the merchant globals errored inside the pcall and
        -- the error vanished with it. Now the capture records type() of every
        -- API it leans on, tries the C_MerchantFrame forms first, and keeps the
        -- first error text, so a failed capture explains itself.
        do
            local okM, errM = pcall(function()
                if not (MerchantFrame and MerchantFrame:IsShown()) then return end
                local CM = C_MerchantFrame
                local m = { npc = UnitName("npc"), items = {}, api = {
                    GetMerchantNumItems     = type(GetMerchantNumItems),
                    C_GetNumItems           = type(CM and CM.GetNumItems),
                    GetMerchantItemInfo     = type(GetMerchantItemInfo),
                    C_GetItemInfo           = type(CM and CM.GetItemInfo),
                    GetMerchantItemLink     = type(GetMerchantItemLink),
                    GetMerchantItemCostInfo = type(GetMerchantItemCostInfo),
                    GetMerchantItemCostItem = type(GetMerchantItemCostItem),
                } }
                snap.merchant = m
                local n = (CM and CM.GetNumItems and CM.GetNumItems())
                       or (GetMerchantNumItems and GetMerchantNumItems()) or 0
                m.count = n
                for i = 1, n do
                    local ok, err = pcall(function()
                        local e = {}
                        if CM and CM.GetItemInfo then
                            local info = CM.GetItemInfo(i)
                            if type(info) == "table" then
                                e.name, e.price, e.qty = info.name, info.price, info.stackCount
                                e.currencyID, e.hasExtendedCost = info.currencyID, info.hasExtendedCost
                            end
                        end
                        if not e.name and GetMerchantItemInfo then
                            local name, _, price, qty = GetMerchantItemInfo(i)
                            e.name, e.price, e.qty = name, price, qty
                        end
                        local link = GetMerchantItemLink and GetMerchantItemLink(i)
                        e.link = link
                        e.itemID = link and tonumber(link:match("item:(%d+)"))
                        -- Export #37: seven of 22 rows came back with no name and
                        -- no link -- the client had not cached those items yet.
                        -- Say so, rather than leaving a bare cost.
                        if not e.name and not link then e.uncached = true end
                        local nCosts = (GetMerchantItemCostInfo and GetMerchantItemCostInfo(i)) or 0
                        if nCosts > 0 and GetMerchantItemCostItem then
                            e.costs = {}
                            for j = 1, nCosts do
                                local _, value, costLink, currencyName = GetMerchantItemCostItem(i, j)
                                table.insert(e.costs, { value = value, link = costLink, currency = currencyName })
                            end
                        end
                        table.insert(m.items, e)
                    end)
                    if not ok then m.firstError = m.firstError or (i .. ": " .. tostring(err)); break end
                end
            end)
            if not okM then snap.merchantError = tostring(errM) end
        end

        -- Last PLAYER_INTERACTION_MANAGER_FRAME_SHOW type seen, to learn the
        -- delve entrance dialog's real enum value.
        snap.lastInteractionType = DelveGuide.lastInteractionType
        snap.pickerEnum = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.DelvesDifficultyPicker

        -- Tier, as the addon currently believes it. Read the stored fields
        -- rather than calling ApplyDelveTier so the export stays side-effect
        -- free. Needed to correlate scenarioID against tier: 3580 was seen at
        -- tier 11 and 3582 at tier 1, and until tier is recorded alongside the
        -- ID we cannot tell whether scenarioID is per-chamber or per-tier (5.7).
        pcall(function()
            snap.tierNum    = DelveGuide.currentDelveTierNum
            snap.tierManual = DelveGuide.manualDelveTier
            snap.tierAuto   = DelveGuide.autoDelveTier
        end)

        -- Reputations, id + name + standing. 12.1.5 adds a "The Labyrinth of
        -- Kindo'jan" faction; capturing the whole list means its factionID (and
        -- any future one) is on disk without having to guess or paste it.
        -- GetNumFactions only enumerates rows that are currently VISIBLE, so
        -- collapsed headers hide most of the list -- the first attempt at this
        -- returned 9 factions and missed the new one entirely. Expand every
        -- header first. NOTE: this leaves the Reputation pane expanded.
        pcall(function()
            local guard, again = 0, true
            while again and guard < 200 do
                again, guard = false, guard + 1
                for i = 1, (C_Reputation.GetNumFactions() or 0) do
                    local d = C_Reputation.GetFactionDataByIndex(i)
                    if d and d.isHeader and d.isCollapsed then
                        C_Reputation.ExpandFactionHeader(i)
                        again = true
                        break
                    end
                end
            end
            snap.factions = {}
            for i = 1, (C_Reputation.GetNumFactions() or 0) do
                local d = C_Reputation.GetFactionDataByIndex(i)
                if d then
                    table.insert(snap.factions, {
                        id = d.factionID, name = d.name, header = d.isHeader or nil,
                        reaction = d.reaction, standing = d.currentStanding,
                        nextThreshold = d.nextReactionThreshold,
                    })
                end
            end
            snap.factionCount = #snap.factions
        end)

        -- Taxi network. Labyrinths carry their own in-instance flight map
        -- (12_15_Labyrinth_Taxi) whose unlocked nodes track how deep the run has
        -- been cleared -- numeric nodeIDs, and a property of the instance rather
        -- than the current scenario phase, so unlike criteria it survives the
        -- mid-run scenario swap. Needs the flight map OPEN to return anything.
        -- Both the modern and classic APIs are tried; whichever answers, answers.
        pcall(function()
            snap.taxiMapID = GetTaxiMapID and GetTaxiMapID() or nil
            snap.taxiMapOpen = (snap.taxiMapID ~= nil)
            snap.taxiNodes = {}
            local nodes = C_TaxiMap and C_TaxiMap.GetAllTaxiNodes
                and C_TaxiMap.GetAllTaxiNodes(snap.taxiMapID)
            if nodes then
                for _, n in ipairs(nodes) do
                    table.insert(snap.taxiNodes, {
                        id    = n.nodeID,
                        name  = n.name,
                        state = n.state,
                        x     = n.position and n.position.x,
                        y     = n.position and n.position.y,
                    })
                end
            end
            snap.taxiClassic = {}
            if NumTaxiNodes then
                for i = 1, (NumTaxiNodes() or 0) do
                    table.insert(snap.taxiClassic, {
                        i    = i,
                        name = TaxiNodeName and TaxiNodeName(i) or nil,
                        kind = TaxiNodeGetType and TaxiNodeGetType(i) or nil,
                    })
                end
            end
        end)

        table.insert(DelveGuideDB.ptrExports, snap)
        print(string.format("|cFF00BFFF[DelveGuide]|r Export snapshot |cFF44FF44#%d|r captured (%s). |cFFFFD700/reload|r or logout to write to disk.",
            #DelveGuideDB.ptrExports, snap.zone or "?"))
    elseif msg=="selftest" then
        -- One command that turns "does this still work on the new patch" into
        -- a pasteable pass/fail block: every tab rendered under pcall, every
        -- API the addon leans on probed, the data file's invariants checked,
        -- and the two widget dumps that settle open questions. Also written to
        -- DelveGuideDB.lastSelftest so it can be read off disk after /reload.
        local P = "|cFF00BFFF[DelveGuide]|r "
        local PASS, FAIL, INFO = "|cFF00FF44PASS|r", "|cFFFF4444FAIL|r", "|cFF888888info|r"
        local report = { at = date("%Y-%m-%d %H:%M:%S"), build = {GetBuildInfo()}, fails = 0 }
        local function line(status, text) print(P..status.."  "..text) end
        local function fail(text) report.fails = report.fails + 1; line(FAIL, text) end
        print(P.."=== SELF-TEST  "..ADDON_VERSION.."  build "..tostring(report.build[2]).."  iface "..tostring(report.build[4]).." ===")

        -- 1. APIs
        local api, missing = ProbeAPIs()
        report.api, report.apiMissing = api, missing
        if #missing == 0 then line(PASS, "all required APIs present") end
        for _, m in ipairs(missing) do fail("required API missing: "..m) end
        for _, pr in ipairs(API_PROBES) do
            if not pr[4] and api[pr[1]] ~= "function" then line(INFO, pr[1].." = "..tostring(api[pr[1]]).." (optional)") end
        end

        -- 2. Data invariants
        report.data = {}
        do
            local badGrade, badZone, dupVariant, seen = {}, {}, {}, {}
            for _, d in ipairs(DelveGuideData.delves or {}) do
                if d.ranking ~= "?" and not DelveGuideData.gradeColors[d.ranking] then table.insert(badGrade, d.name..":"..tostring(d.ranking)) end
                if not zoneColors[d.zone] then badZone[d.zone or "?"] = true end
                if seen[d.variant] then table.insert(dupVariant, d.variant) end
                seen[d.variant] = true
            end
            if #badGrade == 0 then line(PASS, "every ranking has a colour") else fail("rankings with no colour: "..table.concat(badGrade, ", ")) end
            local bz = {}; for z in pairs(badZone) do table.insert(bz, z) end
            if #bz == 0 then line(PASS, "every zone has a colour") else fail("zones with no colour: "..table.concat(bz, ", ")) end
            if #dupVariant == 0 then line(PASS, "variant names unique") else fail("duplicate variants: "..table.concat(dupVariant, ", ")) end
            local tr = DelveGuideData.tierRewards or {}
            local okTier = tr[8] and tr[8].coffer == 295 and tr[8].vault == 302 and tr[11] and tr[11].vault == 305
            if okTier then line(PASS, "tierRewards: T8 coffer 295 / vault 302, T11 vault 305") else fail("tierRewards no longer match the 295/302/305 the UI text claims") end
            local badSet = {}
            for setID, name in pairs(DelveGuideData.widgetSetDelves or {}) do
                local found = false
                for _, d in ipairs(DelveGuideData.delves or {}) do if d.name == name then found = true; break end end
                if not found then table.insert(badSet, setID..":"..name) end
            end
            if #badSet == 0 then line(PASS, "every widgetSetDelves entry names a catalogued delve") else fail("widgetSetDelves -> unknown delve: "..table.concat(badSet, ", ")) end
            local badMap = {}
            for _, mapID in ipairs(DelveGuideData.zoneMapIDs or {}) do if not (DelveGuideData.zoneNames or {})[mapID] then table.insert(badMap, tostring(mapID)) end end
            if #badMap == 0 then line(PASS, "every zoneMapID has a zoneName") else fail("zoneMapIDs with no zoneName: "..table.concat(badMap, ", ")) end
            report.data = { badGrade = badGrade, badZone = bz, dupVariant = dupVariant, tierOK = okTier and true or false, badSet = badSet, badMap = badMap }
        end

        -- 3. Every tab renders
        report.tabs = {}
        do
            if not mainFrame then CreateMainWindow() end
            local wasShown, origTab = mainFrame:IsShown(), currentTabKey
            for _, td in ipairs(TABS) do
                -- SwitchTab now contains renderer errors (2.7) and paints a
                -- "failed to render" row, so pcall alone would call a broken
                -- tab a pass. It records the error; read it back.
                DelveGuide.lastRenderError = nil
                local ok, err = pcall(SwitchTab, td.key)
                local rec = DelveGuide.lastRenderError
                if ok and rec and rec.key == td.key then ok, err = false, rec.err end
                report.tabs[td.key] = ok and "ok" or tostring(err)
                if ok then line(PASS, "tab renders: "..td.label) else fail("tab "..td.label..": "..tostring(err)) end
            end
            pcall(SwitchTab, origTab or "delves")   -- never leave the window parked on Debug
            if not wasShown then mainFrame:Hide() end
        end

        -- 4. Widget-set metadata for every scanned POI (non-text fields; the
        --    outdoor variant-key experiment). Needs a scan this session.
        report.poiMeta = {}
        if #rawScanResults == 0 then
            line(INFO, "no POI scan this session -- run /dg scan first for widget metadata")
        else
            local seenName = {}   -- the scan records a delve once per map it appears on
            for _, r in ipairs(rawScanResults) do
                if r.widgetMeta and #r.widgetMeta > 0 and not seenName[r.name] then
                    seenName[r.name] = true
                    local parts = {}
                    for _, m in ipairs(r.widgetMeta) do
                        table.insert(parts, string.format("id=%s t=%s tag=%s kit=%s ord=%s", tostring(m.id), tostring(m.type), tostring(m.tag), tostring(m.kit), tostring(m.order)))
                    end
                    line(INFO, string.format("%s set=%s  %s", tostring(r.name), tostring(r.widgetSetID), table.concat(parts, " | ")))
                    report.poiMeta[tostring(r.name)] = r.widgetMeta
                end
            end
        end

        -- 5. Objective-tracker widgets (lives: criterion or widget?)
        do
            local widgets, setID = DumpObjectiveTrackerWidgets()
            report.trackerWidgets, report.trackerWidgetSetID = widgets, setID
            if not setID then
                line(INFO, "objective tracker widget set: none (not in a scenario?)")
            else
                line(INFO, "objective tracker widget set "..tostring(setID)..": "..#widgets.." widget(s)")
                for _, m in ipairs(widgets) do
                    line(INFO, string.format("  id=%s type=%s text=[%s] tag=%s kit=%s", tostring(m.id), tostring(m.type), tostring(m.text), tostring(m.tag), tostring(m.kit)))
                end
            end
        end

        -- 5b. The scenario step's widget set -- where tier and lives should be.
        do
            local setID = GetStepWidgetSetID()
            report.stepWidgetSetID = setID
            if not setID then
                line(INFO, "scenario step widget set: none (not in a scenario?)")
            else
                local widgets = DumpWidgetSet(setID)
                report.stepWidgets = widgets
                line(INFO, "scenario step widget set "..tostring(setID)..": "..#widgets.." widget(s)")
                for _, m in ipairs(widgets) do
                    local keys = {}
                    for k in pairs(m) do table.insert(keys, k) end
                    table.sort(keys)
                    local function fmt(v)
                        if type(v) ~= "table" then return tostring(v) end
                        local items = {}
                        for kk, vv in pairs(v) do
                            if type(vv) == "table" then
                                local inner = {}
                                for k3, v3 in pairs(vv) do table.insert(inner, k3.."="..tostring(v3)) end
                                table.sort(inner); table.insert(items, tostring(kk).."{"..table.concat(inner, ",").."}")
                            else
                                table.insert(items, tostring(kk).."="..tostring(vv))
                            end
                        end
                        table.sort(items)
                        return "{"..table.concat(items, " ").."}"
                    end
                    local parts = {}
                    for _, k in ipairs(keys) do table.insert(parts, k.."="..fmt(m[k])) end
                    line(INFO, "  "..table.concat(parts, " "))
                end
            end
        end

        print(P.."=== "..(report.fails == 0 and "|cFF00FF44ALL PASS|r" or ("|cFFFF4444"..report.fails.." FAIL|r")).."  (also saved to DelveGuideDB.lastSelftest) ===")
        DelveGuideDB.lastSelftest = report
    elseif msg=="exportclear" then
        DelveGuideDB.ptrExports = nil
        print("|cFF00BFFF[DelveGuide]|r Export snapshots cleared.")
    -- Tab aliases OPEN the window; they used to Toggle it, so running one
    -- twice in a row just closed the guide again.
    elseif msg=="roster" then
        if not mainFrame or not mainFrame:IsShown() then DelveGuide.Toggle() end
        SwitchTab("roster")
    elseif msg=="voidforge" or msg=="forge" then
        if not mainFrame or not mainFrame:IsShown() then DelveGuide.Toggle() end
        SwitchTab("voidforge")
    elseif msg=="quests" or msg=="journey" then
        if not mainFrame or not mainFrame:IsShown() then DelveGuide.Toggle() end
        SwitchTab("quests")
    elseif msg=="questscan" then
        if DelveGuide.ScanDelversCallQuests then DelveGuide.ScanDelversCallQuests() end
    elseif msg=="submit" or msg=="rank" then
        DelveGuide.ShowSubmitDialog()
    elseif msg=="minimap" then
        DelveGuideDB.minimap.hide = not DelveGuideDB.minimap.hide
        if icon then
            if DelveGuideDB.minimap.hide then icon:Hide("DelveGuide") else icon:Show("DelveGuide") end
        end
        print("|cFF00BFFF[DelveGuide]|r Minimap button: " .. (DelveGuideDB.minimap.hide and "|cFFFF4444hidden|r" or "|cFF44FF44shown|r"))
    elseif msg=="check" then
        if DelveGuide.ShowChecklist then DelveGuide.ShowChecklist(true) end
    elseif msg=="currencydebug" then
        -- Dump every field of the delve currencies so season-scoped vs lifetime
        -- totals can be told apart (the in-game tooltip shows both).
        print("|cFF00BFFF[DelveGuide]|r === Currency Fields ===")
        local ids = { 3418, 3513, 3310, 3028 }
        for _, id in ipairs(ids) do
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info then
                local bits = {}
                for _, f in ipairs({"name","quantity","totalEarned","maxQuantity","maxWeeklyQuantity",
                                    "quantityEarnedThisWeek","useTotalEarnedForMaxQty","isAccountWide",
                                    "isAccountTransferable","discovered"}) do
                    if info[f] ~= nil then table.insert(bits, f.."="..tostring(info[f])) end
                end
                print(string.format("  |cFFFFD700%d|r  %s", id, table.concat(bits, "  ")))
            else
                print(string.format("  |cFF888888%d  (no data)|r", id))
            end
        end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="vaultdebug" then
        -- Dumps the real Great Vault activity data so the reward item levels can
        -- be read from Blizzard rather than a hardcoded per-tier table.
        print("|cFF00BFFF[DelveGuide]|r === Great Vault Activities ===")
        local ok, acts = pcall(C_WeeklyRewards.GetActivities)
        if not ok or type(acts) ~= "table" then
            print("  |cFFFF4444GetActivities failed|r")
        else
            for _, a in ipairs(acts) do
                local bits = {}
                for _, f in ipairs({"id","type","index","level","threshold","progress","claimID"}) do
                    if a[f] ~= nil then table.insert(bits, f.."="..tostring(a[f])) end
                end
                print("  " .. table.concat(bits, "  "))
                -- Reward item level, if the API will give it to us directly.
                pcall(function()
                    local links = C_WeeklyRewards.GetExampleRewardItemHyperlinks and C_WeeklyRewards.GetExampleRewardItemHyperlinks(a.id)
                    if links then
                        local ilvl = C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(links)
                        print("      reward: " .. tostring(links) .. "   ilvl=" .. tostring(ilvl))
                    end
                end)
                pcall(function()
                    if a.id and C_WeeklyRewards.GetActivityEncounterInfo then
                        local enc = C_WeeklyRewards.GetActivityEncounterInfo(a.type, a.index)
                        if enc then for _, e in ipairs(enc) do
                            print("      encounter: bestDifficulty=" .. tostring(e.bestDifficulty) .. " name=" .. tostring(e.encounterName))
                        end end
                    end
                end)
            end
        end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="tierdebug" then
        print("|cFF00BFFF[DelveGuide]|r === Tier State ===")
        local function fmt(v) return v == nil and "|cFF555555nil|r" or ("|cFFFFFFFF"..tostring(v).."|r") end
        print("  manual (/dg tier):  " .. fmt(DelveGuide.manualDelveTier))
        print("  auto (detected):    " .. fmt(DelveGuide.autoDelveTier)
              .. "   |cFF888888via " .. tostring(DelveGuide.autoDetectMethod or "none") .. "|r")
        print("  --> effective num:  " .. fmt(DelveGuide.currentDelveTierNum))
        print("  --> effective str:  " .. fmt(DelveGuide.currentDelveTier))
        local inScen = false; pcall(function() inScen = C_Scenario.IsInScenario() end)
        local zone = ""; pcall(function() zone = GetRealZoneText() or "" end)
        print(string.format("  inScenario: %s   zone: |cFFCCCCCC%s|r   runTimer: %s",
            tostring(inScen), zone, DelveGuide.runStartTime and "running" or "|cFF555555stopped|r"))
        print("|cFF00BFFF[DelveGuide]|r === Objective Tracker Dump ===")
        local tracker = _G["ObjectiveTrackerFrame"] or _G["ScenarioObjectiveTracker"]
        if tracker then
            local function PrintText(frame, depth)
                if not frame or frame:IsForbidden() then return end
                for _, r in ipairs({frame:GetRegions()}) do
                    if r:GetObjectType() == "FontString" and r:IsShown() then
                        local txt = r:GetText()
                        if txt and txt ~= "" then
                            local cleanTxt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", "")
                            print("  ["..depth.."] " .. cleanTxt)
                        end
                    end
                end
                for _, child in ipairs({frame:GetChildren()}) do
                    PrintText(child, depth + 1)
                end
            end
            PrintText(tracker, 0)
        else
            print("  |cFFFF4444No tracker found on screen!|r")
        end
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="checkdebug" then
        print("|cFF00BFFF[DelveGuide]|r === Valeera Role Debug ===")
        local id = C_DelvesUI and C_DelvesUI.GetCompanionInfoForActivePlayer and C_DelvesUI.GetCompanionInfoForActivePlayer()
        print("  companionID: " .. tostring(id))
        if id and id > 0 then
            for roleType, roleName in pairs({[0]="DPS",[1]="Heal",[2]="Tank"}) do
                local node    = C_DelvesUI.GetRoleNodeForCompanion    and C_DelvesUI.GetRoleNodeForCompanion(roleType, id)
                local subtree = C_DelvesUI.GetRoleSubtreeForCompanion and C_DelvesUI.GetRoleSubtreeForCompanion(roleType, id)
                print(string.format("  %s: node=%s  subtree=%s", roleName, tostring(node), tostring(subtree)))
            end
        end
        local f = DelvesCompanionConfigurationFrame
        if f then
            print("  frame.selectedRole: " .. tostring(f.selectedRole))
            if f.RoleDropdown then print("  RoleDropdown.selectedValue: " .. tostring(f.RoleDropdown.selectedValue)) end
        end
        -- Check active trait configs
        if C_Traits and C_Traits.GetActiveConfigID then
            print("  activeConfigID: " .. tostring(C_Traits.GetActiveConfigID()))
        end
        print("|cFF00BFFF[DelveGuide]|r === End ===")
        -- Also scan auras
        local i = 1
        while true do
            local aura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            -- tostring() keeps this safe if aura fields come back as secret values (12.1+)
            print(string.format("  aura[%d] spellID=%s  %s", i, tostring(aura.spellId), tostring(aura.name)))
            i = i + 1
        end
    elseif msg=="huddump" then
        print("|cFF00BFFF[DelveGuide]|r === HUD DEBUG DUMP (share this output) ===")
        print("Version: "..ADDON_VERSION.."  |  Locale: "..(GetLocale and GetLocale() or "unknown"))
        -- Zone info
        local zone = ""; pcall(function() zone = GetRealZoneText() or "" end)
        print("GetRealZoneText: ["..zone.."]")
        -- Instance info
        pcall(function()
            local name, instType, diffID, diffName = GetInstanceInfo()
            print(string.format("GetInstanceInfo: name=[%s]  type=[%s]  diffID=[%s]  diffName=[%s]",
                tostring(name), tostring(instType), tostring(diffID), tostring(diffName)))
        end)
        -- Scenario info
        pcall(function()
            if C_Scenario and C_Scenario.GetInfo then
                local scenName = C_Scenario.GetInfo()
                print("C_Scenario.GetInfo: ["..tostring(scenName).."]")
            end
            if C_Scenario and C_Scenario.GetStepInfo then
                local stepName = C_Scenario.GetStepInfo()
                print("C_Scenario.GetStepInfo: ["..tostring(stepName).."]")
            end
            local inScenario = C_Scenario.IsInScenario and C_Scenario.IsInScenario()
            print("IsInScenario: "..tostring(inScenario))
        end)
        -- Scenario criteria (lives detection)
        pcall(function()
            local numCrit = DelveGuide.GetCriteriaCount()
            print("Scenario criteria count: "..tostring(numCrit))
            for i = 1, (numCrit or 0) do
                local crit = DelveGuide.GetCriteria(i)
                if crit then
                    print(string.format("  crit[%d] desc=[%s]  qtyStr=[%s]  qty=%s  total=%s",
                        i, tostring(crit.description), tostring(crit.quantityString),
                        tostring(crit.quantity), tostring(crit.totalQuantity)))
                end
            end
        end)
        -- Localized → English mapping
        local l10n = DelveGuide.localizedToEnglish or {}
        local mapped = l10n[zone]
        print("localizedToEnglish["..zone.."] = "..tostring(mapped))
        print("|cFF00BFFF[DelveGuide]|r === END ===")
    elseif msg=="specinfo" then
        local idx = GetSpecialization and GetSpecialization()
        if not idx then print("|cFF00BFFF[DelveGuide]|r GetSpecialization() returned nil"); return end
        local specID, specName = GetSpecializationInfo(idx)
        print(string.format("|cFF00BFFF[DelveGuide]|r specIndex=%d  specID=%d  specName=%s", idx, specID or -1, specName or "nil"))
        local rec = DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID]
        if rec then
            -- combat/utility were Season 1 curios and are gone from the table.
            -- Printing them with %s would also error outright, since string.format
            -- rejects nil for %s.
            print(string.format("|cFF00BFFF[DelveGuide]|r Rec found: %s (%s)  Valeera=%s",
                tostring(rec.spec or "?"), tostring(rec.role or "?"), tostring(rec.companion or "?")))
        else
            print("|cFF00BFFF[DelveGuide]|r No rec entry for specID "..tostring(specID))
        end
    elseif msg=="testrun" then
        -- DEV ONLY: simulate a delve completion for the first delve in the DB
        local testName = DelveGuideData and DelveGuideData.delves and DelveGuideData.delves[1] and DelveGuideData.delves[1].name or "Test Delve"
        local resetKey = DelveGuide.GetResetKey()
        local testChar="Unknown"; pcall(function() testChar=UnitName("player") or "Unknown" end)
        table.insert(DelveGuideDB.history,1,{name=testName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier="Tier 8",vaultIlvl=610,char=testChar,elapsed=312})
        print("|cFF00BFFF[DelveGuide]|r TEST: Injected fake run - |cFF00FF44"..testName.."|r")
        -- TRIGGER THE VICTORY SCREEN FOR THE TEST RUN!
        if DelveGuide.ShowVictoryScreen then
            DelveGuide.ShowVictoryScreen(testName, "Tier 8", 610, 312)
        end
        if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
    elseif msg=="help" then
        print("|cFF00BFFF[DelveGuide]|r |cFFFFFFFFv"..ADDON_VERSION.."|r  |cFF888888(include this in bug reports)|r")
        print("|cFF00BFFF[DelveGuide]|r Commands:")
        print("  |cFFFFFF00/dg|r                    - Toggle window")
        print("  |cFFFFFF00/dg scan|r               - Rescan active delve variants")
        print("  |cFFFFFF00/dg map|r                - Open world map")
        print("  |cFFFFFF00/dg minimap|r            - Toggle minimap button")
        print("  |cFFFFFF00/dg hud|r                - Toggle in-run HUD overlay")
        print("  |cFFFFFF00/dg widget|r             - Toggle compact floating widget")
        print("  |cFFFFFF00/dg resetwidget|r        - Reset widget position to center")
        print("  |cFFFFFF00/dg resethud|r           - Reset the in-run HUD position")
        print("  |cFFFFFF00/dg bountiful|r          - Toggle widget filter to show only bountiful delves")
        print("  |cFFFFFF00/dg check|r              - Show pre-entry checklist")
        print("  |cFFFFFF00/dg roster|r             - Open Roster tab")
        print("  |cFFFFFF00/dg voidforge|r          - Open Voidforge tab (bonus rolls, upgrades, slot priority)")
        print("  |cFFFFFF00/dg journey|r            - Open the Journey tab: Delver's Journey ranks + Delver's Call quests (alias /dg quests)")
        print("  |cFFFFFF00/dg submit|r             - Copy your run times to submit for community variant rankings")
        print("  |cFFFFFF00/dg questscan|r          - Scan quest log for Delver's Call quest IDs")
        print("  |cFFFFFF00/dg export|r             - Snapshot zone/delve/quest data to SavedVariables (attach to bug reports)")
        print("  |cFFFFFF00/dg exportclear|r        - Clear export snapshots")
        print("  |cFFFFFF00/dg companionscan|r      - Re-scan for the companion reputation faction")
        print("  |cFFFFFF00/dg companionfaction <id>|r - Manually pin the companion faction ID")
        print("  |cFFFFFF00/dg tier <1-11>|r        - Manually set current delve tier")
        print("  |cFFFFFF00/dg share [channel]|r    - Share active variants (party/guild/say/raid)")
        print("  |cFFFFFF00/dg font <0.6-2.0>|r     - Main UI font scale")
        print("  |cFFFFFF00/dg widgetfont <0.6-2.0>|r - Widget-only font scale (independent)")
        print("|cFF888888  Debug:|r |cFFCCCCCCdump, chatdump, huddump, tierdebug, checkdebug, specinfo, findplaza|r")
        print("  |cFFFFFF00/dg help|r               - Show this help")
    elseif msg:sub(1,5)=="tier " then
        local arg = msg:sub(6)
        local num = tonumber(arg)
        if num and num >= 1 and num <= 11 then
            DelveGuide.SetManualDelveTier(num)
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            print("|cFF00BFFF[DelveGuide]|r Delve tier set to |cFFCCCCCC" .. num .. "|r |cFF888888(manual override -- /dg tier auto to clear)|r")
        elseif arg == "auto" or num == 0 then
            DelveGuide.SetManualDelveTier(nil)
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            print("|cFF00BFFF[DelveGuide]|r Manual tier cleared -- back to auto-detection.")
        else
            print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg tier 3|r  (1-11), or |cFFFFFF00/dg tier auto|r to clear")
        end
    elseif msg=="hud" then
        if DelveGuide.ToggleHUD then DelveGuide.ToggleHUD()
        else print("|cFF00BFFF[DelveGuide]|r HUD not loaded.") end
    elseif msg=="widget" then
        if DelveGuide.ToggleWidget then DelveGuide.ToggleWidget() end
    elseif msg=="resethud" then
        -- Parity with /dg resetwidget. Asked for by a user whose HUD kept
        -- landing at the bottom of the screen (the restore-anchor bug), with
        -- no way to put it back.
        DelveGuideDB.hudX = nil
        DelveGuideDB.hudY = nil
        local hf = _G["DelveGuideHUDFrame"]
        if hf then
            hf:ClearAllPoints()
            hf:SetPoint("CENTER", UIParent, "CENTER", 450, 100)
        end
        print("|cFF00BFFF[DelveGuide]|r In-run HUD position reset. Drag it where you want it and it will stay there.")
    elseif msg=="resetwidget" then
        DelveGuideDB.widgetX = nil
        DelveGuideDB.widgetY = nil
        local cw = DelveGuide.compactWidget
        if cw then
            cw:ClearAllPoints()
            cw:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
            cw:Show()
        end
        DelveGuideDB.widgetHidden = false
        print("|cFF00BFFF[DelveGuide]|r Widget position reset to center.")
    elseif msg:sub(1,16)=="companionfaction" then
        local val = tonumber(msg:sub(18))
        if val and DelveGuideDB then
            DelveGuideDB.companionFactionID   = val
            DelveGuideDB.companionFactionType = nil  -- let the renown query auto-detect Major vs Reputation
            print("|cFF00BFFF[DelveGuide]|r Companion faction ID set to "..val..". Open Companion tab to verify.")
            if currentTabKey=="companion" then RefreshCurrentTab() end
        else
            print("|cFF00BFFF[DelveGuide]|r Usage: /dg companionfaction <factionID>")
        end
    elseif msg=="companionscan" then
        if DelveGuideDB then
            DelveGuideDB.companionFactionID   = nil
            DelveGuideDB.companionFactionType = nil
        end
        print("|cFF00BFFF[DelveGuide]|r Companion faction cache cleared. Open Companion tab to rescan.")
        if currentTabKey=="companion" then RefreshCurrentTab() end
    elseif msg=="bountiful" then
        DelveGuideDB.widgetBountifulOnly = not DelveGuideDB.widgetBountifulOnly
        local cw = DelveGuide.compactWidget
        if cw and cw.RefreshBountyBtn then cw.RefreshBountyBtn() end
        if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end
        print("|cFF00BFFF[DelveGuide]|r Widget bountiful filter: "
            ..(DelveGuideDB.widgetBountifulOnly and "|cFFFFD700ON|r (only bountiful delves)" or "|cFF888888OFF|r (all variants)"))
    elseif msg:sub(1,10)=="widgetfont" then
        local val=tonumber(msg:sub(12))
        if val then DelveGuideDB.widgetFontScale=math.max(0.6,math.min(2.0,val))
            if DelveGuide.RefreshCompactWidgetFonts then DelveGuide.RefreshCompactWidgetFonts() end
            print(string.format("|cFF00BFFF[DelveGuide]|r Widget font: %.1fx",DelveGuideDB.widgetFontScale))
        else print(string.format("|cFF00BFFF[DelveGuide]|r Widget font: %.1fx (0.6-2.0)",DelveGuideDB.widgetFontScale)) end
    elseif msg:sub(1,4)=="font" then
        local val=tonumber(msg:sub(6))
        if val then DelveGuideDB.fontScale=math.max(0.6,math.min(2.0,val)); RefreshCurrentTab()
            print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx",DelveGuideDB.fontScale))
        else print(string.format("|cFF00BFFF[DelveGuide]|r Font: %.1fx (0.6-2.0)",DelveGuideDB.fontScale)) end
    elseif msg:sub(1,5)=="share" then
        local channel = strtrim(msg:sub(7)):upper()
        if channel == "" then channel = "PARTY" end
        local validChannels = {PARTY=true, GUILD=true, SAY=true, RAID=true, INSTANCE_CHAT=true}
        if not validChannels[channel] then
            print("|cFF00BFFF[DelveGuide]|r Usage: |cFFFFFF00/dg share [party|guild|say|raid]|r")
            return
        end
        -- Group/guild checks, list building, line packing and sending all live
        -- in one place now (DelveGuide_Widget.lua) -- shared with both buttons.
        DelveGuide.ShareActiveVariants(channel)
    else DelveGuide.Toggle() end
end

-- ============================================================
-- COMMUNITY RANKING: aggregate the player's own timed runs into
-- per-variant stats. Powers the "Your Fastest Variants" panel and
-- the /dg submit copy code (the data we pool to rank variants).
-- ============================================================
DelveGuide.GetVariantRunStats = function()
    local agg = {}
    for _, run in ipairs(DelveGuideDB and DelveGuideDB.history or {}) do
        if run.variant and type(run.elapsed) == "number" and run.elapsed > 0 then
            local key = (run.name or "?") .. "||" .. run.variant
            local a = agg[key]
            if not a then a = { delve = run.name or "?", variant = run.variant, secs = {}, totTier = 0, count = 0, tierCount = 0 }; agg[key] = a end
            table.insert(a.secs, run.elapsed)
            a.count   = a.count + 1
            -- Average tier over runs that actually HAVE a tier. Counting an
            -- unknown tier as 0 dragged the average down and got otherwise
            -- valid submissions filtered out by the aggregator's tier floor.
            local t = tonumber(run.tierNum)
            if t and t > 0 then
                a.totTier   = a.totTier + t
                a.tierCount = a.tierCount + 1
            end
        end
    end
    local out = {}
    for _, a in pairs(agg) do
        -- Median, not mean. One disconnect or AFK run used to drag a player's
        -- figure for a variant, and that figure is what /dg submit ships; the
        -- aggregator medians ACROSS players, so a mean here was the one
        -- outlier-sensitive step left in the pipeline. The field keeps its
        -- wire name (avgSec) because the DG1 submission format and the
        -- aggregator read it by position.
        table.sort(a.secs)
        local n = #a.secs
        local median = (n % 2 == 1) and a.secs[(n + 1) / 2] or (a.secs[n / 2] + a.secs[n / 2 + 1]) / 2
        table.insert(out, {
            delve = a.delve, variant = a.variant, count = a.count,
            avgSec = math.floor(median + 0.5),
            avgTier = (a.tierCount > 0) and math.floor(a.totTier / a.tierCount + 0.5) or 0,
        })
    end
    table.sort(out, function(x, y) return x.avgSec < y.avgSec end)
    return out
end

-- Compact, form-friendly submission string. Format (version DG1):
--   DG1;delve~variant~avgTier~avgSec~count;...[|MISSING;delve~locale~text;...]
-- ~ ; and | are stripped from names so the aggregator can split cleanly.
--
-- The MISSING section reports variants this client saw but could not identify.
-- It matters because such runs are logged WITHOUT a variant, so they can never
-- appear in the run data above -- meaning a variant nobody has catalogued yet
-- is invisible to the whole community pipeline and only gets discovered if the
-- author happens to notice it in their own Debug tab. It also carries the
-- localized variant text from non-English clients, which is the one thing that
-- can't be looked up externally.
DelveGuide.BuildSubmissionCode = function()
    local stats = DelveGuide.GetVariantRunStats()
    local parts = {}
    for _, s in ipairs(stats) do
        local d = (s.delve or ""):gsub("[~;|]", " ")
        local v = (s.variant or ""):gsub("[~;|]", " ")
        table.insert(parts, string.format("%s~%s~%d~%d~%d", d, v, s.avgTier or 0, s.avgSec or 0, s.count or 0))
    end

    local missing = {}
    for _, entry in pairs(DelveGuideDB and DelveGuideDB.missingTranslations or {}) do
        if entry and entry.text and entry.text ~= "" then
            table.insert(missing, string.format("%s~%s~%s",
                (entry.delve  or "?"):gsub("[~;|]", " "),
                (entry.locale or "?"):gsub("[~;|]", " "),
                entry.text:gsub("[~;|]", " ")))
        end
    end

    -- A player with no timed runs can still contribute discoveries.
    if #parts == 0 and #missing == 0 then return nil end

    -- Length budget. The code is pasted into a Google Form field, and a code that
    -- will not fit is worth nothing -- one reporter's came out 116,701 characters
    -- over. Run data is the point of the submission, so it is never trimmed;
    -- MISSING entries are extras and get dropped until the whole thing fits.
    local MAX_CODE = 8000
    local body = table.concat(parts, ";")
    local code = (#parts > 0) and ("DG1;" .. body) or "DG1;"

    -- The MISSING section used to be attached ONLY when the player had no runs at
    -- all, so every real submitter silently dropped their unidentified variants --
    -- which is why no submission had ever carried one. Always attach it now.
    if #missing > 0 then
        local kept = {}
        for _, m in ipairs(missing) do
            local candidate = code .. "|MISSING;" .. table.concat(kept, ";")
                              .. ((#kept > 0) and ";" or "") .. m
            if #candidate <= MAX_CODE then
                table.insert(kept, m)
            else
                break
            end
        end
        if #kept > 0 then
            code = code .. "|MISSING;" .. table.concat(kept, ";")
        end
    end

    -- Runs alone over budget means a genuinely enormous history; better a
    -- truncated code at a segment boundary than one the form rejects outright.
    if #code > MAX_CODE then
        code = code:sub(1, MAX_CODE)
        local cut = code:match("^.*()[;|]")
        if cut and cut > 5 then code = code:sub(1, cut - 1) end
    end

    return code
end

-- Shared entry point for the submission flow: slash command, the one-time
-- call-to-arms popup, and the Settings tab button all funnel through here.
DelveGuide.ShowSubmitDialog = function()
    local code = DelveGuide.BuildSubmissionCode and DelveGuide.BuildSubmissionCode()
    if not code then
        print("|cFF00BFFF[DelveGuide]|r Nothing to send yet -- complete a few delves, then |cFFFFFF00/dg submit|r to help rank them.")
        return false
    end
    print("|cFF00BFFF[DelveGuide]|r Thanks for helping rank the delves! Paste the copied code into the form: |cFFFFFF00" .. SUBMIT_URL .. "|r")
    StaticPopup_Show("DELVEGUIDE_SUBMIT_EXPORT", nil, nil, code)
    return true
end

StaticPopupDialogs["DELVEGUIDE_SUBMIT_EXPORT"] = {
    text = "Copy the code below (it's pre-selected -- Ctrl+C), then paste it into the ranking form:\n\n" .. SUBMIT_URL,
    button1 = CLOSE or "Close",
    -- The form URL was plain dialog text, so there was no way to get it out of
    -- the game short of retyping it -- asked for by a submitter. This swaps to a
    -- popup holding the link in a highlighted edit box.
    button2 = "Copy Form Link",
    OnCancel = function() StaticPopup_Show("DELVEGUIDE_SUBMIT_URL") end,
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self, data)
        local eb = self.editBox or self.EditBox
        if eb then
            -- Default edit boxes cap input length; a long history would be
            -- silently cut off mid-code. 0 = unlimited.
            if eb.SetMaxLetters then eb:SetMaxLetters(0) end
            eb:SetText(data or "")
            eb:SetCursorPosition(0)   -- show the DG1; prefix, not the tail
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    EditBoxOnEnterPressed  = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DELVEGUIDE_SUBMIT_URL"] = {
    text = "Ranking form link (pre-selected -- Ctrl+C):",
    button1 = CLOSE or "Close",
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        local eb = self.editBox or self.EditBox
        if eb then
            if eb.SetMaxLetters then eb:SetMaxLetters(0) end
            eb:SetText(SUBMIT_URL)
            eb:SetCursorPosition(0)
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    EditBoxOnEnterPressed  = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DELVEGUIDE_RANKING_CALL"] = {
    text = "|cFFFFD700DELVEGUIDE NEEDS YOU, DELVER!|r\n\n"
        .. "Season 2's new delves are crawling with |cFF888888[?]|r unranked variants -- and your addon has been timing your runs this whole time.\n\n"
        .. "Enlist! Send your clear times to help build the community rankings. No character or account data -- just cold, hard times, |cFFFFFF00FOR THE VAULT!|r\n\n"
        .. "Your times become everyone's rankings.\n|cFF888888(You can always enlist later with /dg submit.)|r",
    button1 = "Enlist Now!",
    button2 = "Maybe Later",
    OnAccept = function()
        if DelveGuide.ShowSubmitDialog then DelveGuide.ShowSubmitDialog() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["DELVEGUIDE_CONFIRM_CLEAR_HISTORY"] = {
    text          = "Clear all delve run history? This cannot be undone.",
    button1       = "Clear",
    button2       = "Cancel",
    OnAccept      = function()
        DelveGuideDB.history = {}
        RefreshCurrentTab()
    end,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
}

StaticPopupDialogs["DELVEGUIDE_CONFIRM_REMOVE_CHAR"] = {
    text          = "Remove %s from your roster?",
    button1       = "Remove",
    button2       = "Cancel",
    OnAccept      = function(self)
        DelveGuideDB.roster[self.data] = nil
        RefreshCurrentTab()
    end,
    timeout       = 0,
    whileDead     = true,
    hideOnEscape  = true,
    preferredIndex = 3,
}

-- 2.1a/b: AREA_POIS_UPDATED can arrive several times in one frame. Queue ONE
-- scan half a second out; the Delves tab repaints inside that callback, after
-- the scan, so it paints once with fresh data instead of stale-then-again.
local scanQueued = false
local function QueueScan()
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(0.5, function()
        scanQueued = false
        if IsInInstance() then return end
        ScanActiveVariants()
        if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end
        UpdateLDBText()
        if mainFrame and mainFrame:IsShown() and currentTabKey == "delves" then SwitchTab("delves") end
    end)
end

-- Is this PLAYER_INTERACTION_MANAGER_FRAME_SHOW/HIDE type the delve entrance
-- dialog? 79 on build 69594 at a delve entrance and at the Labyrinth's alike
-- (both recorded by /dg export). Enum.PlayerInteractionType has no
-- DelvesDifficultyPicker member there, so the enum is searched for any
-- Delve-named key before falling back to the observed value.
local function IsEntranceDialogType(t)
    local pickerType
    if Enum and Enum.PlayerInteractionType then
        for k, v in pairs(Enum.PlayerInteractionType) do
            if type(k) == "string" and k:lower():find("delve", 1, true) then pickerType = v; break end
        end
    end
    return t == (pickerType or 79)
end

local loadFrame=CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED"); loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("AREA_POIS_UPDATED"); loadFrame:RegisterEvent("SCENARIO_COMPLETED")
loadFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED"); loadFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
loadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
loadFrame:RegisterEvent("ENCOUNTER_END")
loadFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
loadFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
loadFrame:SetScript("OnEvent",function(self,event,arg1,arg2,arg3,arg4,arg5)
    if event=="ADDON_LOADED" and arg1==ADDON_NAME then
        InitSavedVars(); SeedLocalizedNames(); DelveGuideDB.minimap.showInCompartment = true; icon:Register("DelveGuide", DelveGuideLDB, DelveGuideDB.minimap); if DelveGuide.CreateCompactWidget then DelveGuide.CreateCompactWidget() end
        print("|cFF00BFFF[DelveGuide]|r Loaded! |cFFFFFF00/dg|r  *  |cFFFFFF00/dg scan|r")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_ENTERING_WORLD" then
        -- Only rescan POIs when in the outdoor world — inside an instance the POI data is empty
        -- and would wipe the activeVariants cache that the HUD relies on.
        local inInst, instType = IsInInstance()
        if not inInst then
            DelveGuide.inDelveInstance = false
            C_Timer.After(0, function()
                ScanActiveVariants()
                if DelveGuide.UpdateCompactWidget then DelveGuide.UpdateCompactWidget() end
                UpdateLDBText()
                -- One-time flag if missing translations exist on this client
                if DelveGuideDB.missingTranslations then
                    local count = 0
                    for _ in pairs(DelveGuideDB.missingTranslations) do count = count + 1 end
                    if count > 0 and not DelveGuideDB.missingNotified then
                        DelveGuideDB.missingNotified = true
                        print("|cFF00BFFF[DelveGuide]|r |cFFFFFF00" .. count .. " untranslated variant(s) on your client.|r Use |cFFFFFF00/dg chatdump|r to help add your language!")
                    end
                end
            end)
        elseif instType == "scenario" then
            DelveGuide.inDelveInstance = true
        end
        if DelveGuide.TrackLabyrinthPresence then DelveGuide.TrackLabyrinthPresence() end
        CacheCurrentChar()
        UpdateLDBText()
        if mainFrame and mainFrame:IsShown() then RefreshCurrentTab() end
        if DelveGuideDB.lastSeenVersion ~= ADDON_VERSION then
            DelveGuideDB.lastSeenVersion = ADDON_VERSION
            if DelveGuideDB.showChangelog then
                C_Timer.After(3, ShowChangelogPopup)
            end
        end
        -- One-time "help rank the delves" call to arms. Fires once ever
        -- (rankingCallSeen flag), and respects the changelog-popup setting.
        if DelveGuideDB.showChangelog and not DelveGuideDB.rankingCallSeen then
            DelveGuideDB.rankingCallSeen = true
            C_Timer.After(6, function() StaticPopup_Show("DELVEGUIDE_RANKING_CALL") end)
        end
    elseif event=="AREA_POIS_UPDATED" then
        if not IsInInstance() then QueueScan() end
    elseif event=="ACTIVE_TALENT_GROUP_CHANGED" then
        if mainFrame and mainFrame:IsShown() and currentTabKey=="curios" then SwitchTab("curios") end
    elseif event=="PLAYER_TARGET_CHANGED" then
        if DelveGuide.OnTargetChanged then DelveGuide.OnTargetChanged() end
    elseif event=="ZONE_CHANGED_NEW_AREA" then
        -- PLAYER_ENTERING_WORLD does NOT fire on seamless delve zone transitions.
        -- Defer IsInInstance() — at event fire time the instance state isn't settled yet.
        C_Timer.After(1, function()
            local inInst, instType = IsInInstance()
            if inInst and instType == "scenario" then
                DelveGuide.inDelveInstance = true
                if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            else
                DelveGuide.inDelveInstance = false
                if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            end
            if DelveGuide.TrackLabyrinthPresence then DelveGuide.TrackLabyrinthPresence() end
        end)
    elseif event=="PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        -- The entrance dialog closed (walked away, entered, cancelled): take
        -- the checklist with it rather than leave it hanging on screen.
        if IsEntranceDialogType(arg1) and DelveGuide.HideChecklist then DelveGuide.HideChecklist() end
    elseif event=="PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        -- The delve entrance dialog (the tier picker) opens through this event.
        -- It is the real pre-entry moment: a delve entrance is a game object,
        -- not a unit, so the checklist's PLAYER_TARGET_CHANGED trigger could
        -- never see one and the automatic checklist never fired. The Labyrinth
        -- uses the same dialog, so this covers it without a name match.
        -- The interaction type is matched by enum name, with the literal 3 this
        -- code has always used kept as a fallback; the value seen is recorded
        -- so /dg export shows which one the client actually sends.
        DelveGuide.lastInteractionType = arg1
        -- See IsEntranceDialogType. The old literal 3 was the trainer type; it
        -- never fired for an entrance.
        if IsEntranceDialogType(arg1) then
            -- Refresh HUD when player is at the entrance (outside the instance)
            if DelveGuide.UpdateHUD then DelveGuide.UpdateHUD() end
            if DelveGuide.ShowChecklist then DelveGuide.ShowChecklist(false) end
        end
    elseif event=="UNIT_AURA" then
        -- Reserved for future aura-based detection if Blizzard exposes tier via auras.
    elseif event=="ENCOUNTER_END" then
        -- D3: boss chambers fire ENCOUNTER_START/END; objective chambers do
        -- not, so this supplements the chamber record rather than replacing it
        -- (PTR_12.1.5_Findings.md 5.4). Delve encounters are not logged.
        if DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName() then
            DelveGuide.LogLabyrinth({ kind = "encounter", encounterID = arg1, name = arg2,
                difficultyID = arg3, groupSize = arg4, success = (arg5 == 1) })
        end
    elseif event=="SCENARIO_COMPLETED" then
        local scenarioName=C_Scenario.GetInfo()
        if not scenarioName then return end
        -- Labyrinth chambers are type-8 scenarios, so every test below says
        -- "delve", and a cleared chamber logged a delve row with no variant and
        -- tier "?" -- one per chamber, since each chamber is its own scenario
        -- (PTR, 2026-09-05). Withhold the delve row; the Labyrinth run record is
        -- a separate shape. Returning early also stops localeScenarioName below
        -- learning "Soul King" as this client's word for Delves, which would
        -- have broken test (d) for real delves.
        local labName = DelveGuide.GetLabyrinthName and DelveGuide.GetLabyrinthName()
        if labName then
            -- D3: record the chamber first. Fires once per cleared chamber. If
            -- scenario info is already torn down at this event, scenarioID and
            -- stepTitle land as nil -- which itself answers whether completion
            -- data must be captured on entry instead (2.0 plan gate G2).
            pcall(function()
                local e = { kind = "chamber", labyrinth = labName }
                local info = { C_Scenario.GetInfo() }
                e.scenarioName, e.currentStage, e.numStages, e.flags = info[1], info[2], info[3], info[4]
                e.scenarioID = info[13]
                if C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo then
                    local si = C_ScenarioInfo.GetScenarioInfo()
                    if si and si.scenarioID then e.scenarioID = si.scenarioID end
                end
                e.stepTitle = (C_Scenario.GetStepInfo())
                e.subzone   = GetSubZoneText()
                e.criteria  = {}
                for i = 1, (DelveGuide.GetCriteriaCount() or 0) do
                    local c = DelveGuide.GetCriteria(i)
                    if c then
                        table.insert(e.criteria, { desc = c.description, qty = c.quantity, total = c.totalQuantity,
                            ctype = c.criteriaType, assetID = c.assetID, completed = c.completed })
                    end
                end
                if DelveGuide.labyrinthChamberStart then e.elapsed = GetTime() - DelveGuide.labyrinthChamberStart end
                DelveGuide.labyrinthChamberStart = GetTime()
                DelveGuide.LogLabyrinth(e)
            end)
            -- D2: vault credit lands every third chamber; upsert the run record.
            if DelveGuide.LogLabyrinthRun then DelveGuide.LogLabyrinthRun(labName) end
            return
        end
        -- Deciding "was that a delve?" USED to be `scenarioName == "Delves"` plus a
        -- match against English delve names. C_Scenario.GetInfo() returns a
        -- LOCALIZED string, so on a non-English client both tests failed and this
        -- handler returned before reaching the single write to DelveGuideDB.history.
        -- Confirmed in game on esMX (2026-08-23): the run timer ran, the HUD showed
        -- the delve and tier correctly, and the completed run was still never logged.
        -- Non-English players therefore had NO history and could never /dg submit,
        -- so every ranking shipped to date came from English clients only. Worse,
        -- the bug hides its own victims: with nothing logged they cannot appear in
        -- the response data at all.
        --
        -- Five tests now, ordered cheapest first. Only the last is language-bound.
        local isDelve=false

        -- (a) scenarioType (10th return of C_Scenario.GetInfo) == 8. A plain
        --     number, identical in every language, and it works on a fresh
        --     install's FIRST delve with nothing learned yet. Observed on esMX
        --     2026-08-23 inside Gnarldor Isle:
        --       { "Abismos", 2, 4, 18, false,false,false, 0, 0, 8, "UNKNOWN", nil, 3414 }
        --     ("Abismos" being exactly why the old English check failed.) Only one
        --     sample so far, so it is a signal rather than the sole authority --
        --     the checks below still stand behind it.
        pcall(function()
            local sType = select(10, C_Scenario.GetInfo())
            if sType == 8 then isDelve=true end
        end)

        -- (b) The zone is a delve we catalogue. localizedToEnglish maps the
        --     localized zone name back to English, so this works on every locale.
        pcall(function()
            local zone=GetRealZoneText() or ""
            if zone~="" then
                local eng=(localizedToEnglish and localizedToEnglish[zone]) or zone
                for _,d in ipairs(DelveGuideData.delves or {}) do
                    if d.name==eng then isDelve=true; break end
                end
            end
        end)

        -- (c) A run timer was started, i.e. the HUD already identified this as a
        --     delve on entry. Covers Nemesis and uncatalogued delves too.
        if not isDelve and DelveGuide.runStartTime then isDelve=true end

        -- (d) The localized scenario name we learned on a previous confirmed delve.
        if not isDelve and DelveGuideDB and DelveGuideDB.localeScenarioName then
            pcall(function() isDelve=(scenarioName==DelveGuideDB.localeScenarioName) end)
        end

        -- (e) English literal / catalogued English delve name (EN clients).
        if not isDelve then
            pcall(function() isDelve=(scenarioName=="Delves") end)
            if not isDelve and DelveGuideData and DelveGuideData.delves then
                for _,d in ipairs(DelveGuideData.delves) do
                    local ok,match=pcall(function() return d.name==scenarioName end)
                    if ok and match then isDelve=true; break end
                end
            end
        end

        -- Learn this client's word for "Delves" from any confirmed delve, so a
        -- later run in an uncatalogued zone still logs via (d). Self-healing:
        -- no translation table, works in locales neither of us can test.
        if isDelve and DelveGuideDB and scenarioName~="" then
            DelveGuideDB.localeScenarioName = scenarioName
        end

        if isDelve then
            -- Get the actual delve name from the zone — more specific than the generic "Delves" scenario name
            local runName="Unknown Delve"
            pcall(function()
                local zone=GetRealZoneText()
                if zone and zone~="" then runName=zone end
            end)

            local resetKey=DelveGuide.GetResetKey()

            -- Tier set manually by player via /dg tier N (no addon API exposes it in Midnight 12.0)
            local tier    = DelveGuide.currentDelveTier    or "?"
            local tierNum = DelveGuide.currentDelveTierNum or nil

            -- Vault ilvl recorded against this run = what a delve of THIS TIER
            -- contributes to the Great Vault. (The slot you actually receive is
            -- decided by your Nth-best activity for the week, not by one run.)
            -- Fall back to the live reward item level if the tier is unknown --
            -- the old fallback stored a.level, i.e. a TIER, into an ilvl field.
            local vaultIlvl=nil
            if tierNum and DelveGuideData.tierRewards and DelveGuideData.tierRewards[tierNum] then
                vaultIlvl=DelveGuideData.tierRewards[tierNum].vault
            else
                pcall(function()
                    local _,_,_,acts = GetWeeklyVaultData()
                    for _,a in ipairs(acts or {}) do
                        if a.progress>=a.threshold and a.rewardIlvl then
                            if not vaultIlvl or a.rewardIlvl>vaultIlvl then vaultIlvl=a.rewardIlvl end
                        end
                    end
                end)
            end

            local charName="Unknown"
            local charRealm=nil
            pcall(function() charName=UnitName("player") or "Unknown" end)
            pcall(function() charRealm=GetRealmName() end)

            -- Capture completion timer (runStartTime set by HUD on delve entry)
            local elapsed = nil
            if DelveGuide.runStartTime then
                elapsed = GetTime() - DelveGuide.runStartTime
                DelveGuide.runStartTime = nil
            end

            -- Capture current variant from active scan data
            local runVariant = nil
            local engRunName = runName
            if localizedToEnglish and localizedToEnglish[runName] then engRunName = localizedToEnglish[runName] end
            if DelveGuideData and DelveGuideData.delves then
                for _, d in ipairs(DelveGuideData.delves) do
                    if d.name == engRunName and activeVariants[d.variant] then
                        runVariant = d.variant
                        break
                    end
                end
            end

            -- Store the ENGLISH delve name as the canonical `name` so history,
            -- weekly grouping and /dg submit all agree across locales (a localized
            -- name would fragment community rankings into per-language buckets).
            -- `locName` keeps the player's own language for display.
            local locName = (runName ~= engRunName) and runName or nil
            -- Bountiful status decides Voidcore eligibility, so record it with
            -- the run instead of inferring "T8+ therefore eligible" later.
            local runBountiful = nil
            do
                local st = activeDelves and activeDelves[engRunName]
                if type(st)=="table" then runBountiful = st.bountiful and true or false end
            end
            -- SCENARIO_COMPLETED can fire twice for one completion. The second
            -- pass found runStartTime already consumed and appended a duplicate
            -- row with elapsed=nil. Five seconds cannot collide with a real run.
            if DelveGuide.lastRunLoggedAt and (GetTime() - DelveGuide.lastRunLoggedAt) < 5 then return end
            DelveGuide.lastRunLoggedAt = GetTime()
            -- The run is over: drop the persisted start so it cannot resume.
            local runResumed = DelveGuide.runResumed or nil
            DelveGuide.runResumed = nil
            -- After a /reload the outdoor scan cache is empty and runVariant
            -- above came back nil; the run record captured the variant when
            -- the timer started, so take it from there.
            if not runVariant and DelveGuideDB.activeRun and DelveGuideDB.activeRun.variant then
                runVariant = DelveGuideDB.activeRun.variant
            end
            DelveGuideDB.activeRun = nil
            table.insert(DelveGuideDB.history,1,{name=engRunName,locName=locName,date=date("%Y-%m-%d %H:%M"),resetKey=resetKey,tier=tier,tierNum=tierNum,vaultIlvl=vaultIlvl,char=charName,realm=charRealm,bountiful=runBountiful,elapsed=elapsed,variant=runVariant,resumed=runResumed})
            -- 50 was too tight for an account running several alts each week --
            -- a busy week could push older characters' runs out and undercount
            -- their vault progress. History rows are tiny.
            if #DelveGuideDB.history>200 then table.remove(DelveGuideDB.history) end
            local vaultStr=vaultIlvl and ("  |cFFFFD700[Vault: "..vaultIlvl.." ilvl]|r") or ""
            local timeStr=elapsed and string.format("  |cFF00BFFF[%dm %02ds]|r",math.floor(elapsed/60),math.floor(elapsed%60)) or ""
            local varLogStr=runVariant and ("  |cFFCCAAFF("..runVariant..")|r") or ""
            print("|cFF00BFFF[DelveGuide]|r Logged: |cFF00FF44"..runName.."|r"..varLogStr.."  |cFF888888["..tier.."]|r"..vaultStr..timeStr)
            -- The comparison the Victory toast shows, also in chat as a system
            -- message so it survives the toast fading (or being turned off).
            if DelveGuide.GetRunComparison then
                local cmp = DelveGuide.GetRunComparison(runName, runVariant, elapsed, tierNum, engRunName)
                if cmp then
                    local msg = "[DelveGuide] "..runName..": "..cmp
                    if ChatFrame_DisplaySystemMessageInPrimary then ChatFrame_DisplaySystemMessageInPrimary(msg) else print(msg) end
                end
            end
            if mainFrame and mainFrame:IsShown() and currentTabKey=="history" then SwitchTab("history") end
            -- TRIGGER THE VICTORY SCREEN!
            if DelveGuide.ShowVictoryScreen then
                DelveGuide.ShowVictoryScreen(runName, tier, vaultIlvl, elapsed, runVariant, tierNum, engRunName)
            end

            -- Run is logged and shown -- release the tier so the next delve
            -- starts clean instead of inheriting this one's.
            if DelveGuide.ClearDelveTier then DelveGuide.ClearDelveTier() end

        end
    end
end)
-- ============================================================
-- WORLD MAP TOOLTIP INJECTIONS
-- ============================================================
-- 2.1e: this runs on GameTooltip's OnUpdate -- every frame any tooltip is on
-- screen, anywhere in the game. It used to allocate two closures and a string
-- per frame. The title FontString is hoisted, the two pcall bodies are named
-- functions (pcall(f, args) allocates nothing), and a hidden tooltip or a
-- secret value returns before any of it. The pcall stays as the backstop:
-- issecretvalue is the cheap early-out, not a replacement for the bubble.
local GameTooltipTextLeft1 = _G["GameTooltipTextLeft1"]
local function ResolveTooltipName(self, poiName)
    if poiName == "" then return "IGNORE" end
    if self.dgLastCheckedName == poiName then return "IGNORE" end
    -- Remember it for the next frame so the work below runs once per name.
    self.dgLastCheckedName = poiName
    return (DelveGuide.localizedToEnglish and DelveGuide.localizedToEnglish[poiName]) or poiName
end
local function IsActiveDelveName(engName)
    return DelveGuide.activeDelves and DelveGuide.activeDelves[engName]
end

local function InjectDelveData(self)
    if DelveGuideDB and DelveGuideDB.mapTooltips == false then return end
    if not self:IsShown() then return end

    local titleFS = (self == GameTooltip and GameTooltipTextLeft1) or _G[self:GetName() .. "TextLeft1"]
    if not titleFS then return end

    local poiName = titleFS:GetText()
    if not poiName then return end
    -- A protected unit name is never a delve; skip the bubble entirely.
    if issecretvalue and issecretvalue(poiName) then return end

    -- ALL string comparisons stay inside the pcall bubble (see the note on
    -- secret strings in OnTargetChanged); a secret that slipped past the
    -- early-out aborts here and the tooltip is left alone.
    local ok, result = pcall(ResolveTooltipName, self, poiName)
    if not ok or not result or result == "IGNORE" then return end

    local engName = result
    local ok2, isActive = pcall(IsActiveDelveName, engName)
    if not ok2 or not isActive then return end

    local activeVariant = nil
    local ranking = "N/A"
    local flags = ""

    for _, d in ipairs(DelveGuideData.delves) do
        if d.name == engName and DelveGuide.activeVariants[d.variant] then
            activeVariant = d.variant
            ranking = d.ranking
            if d.isBestRoute then flags = flags .. "|cFF00FF00[Best Route]|r " end
            if d.mountable then flags = flags .. "|cFFFFD700[Mountable]|r " end
            if d.hasBug then flags = flags .. "|cFFFF4444[Bugged]|r " end
            break
        end
    end

    -- 3. Inject the DelveGuide Data!
    if activeVariant then
        self:AddLine(" ")
        self:AddLine("|cFF00BFFFDelveGuide:|r")

        local gradeText = DelveGuide.UI and DelveGuide.UI.GradeColor(ranking) or ("|cFFFFFFFF" .. ranking .. "|r")
        self:AddLine("Speed Grade: " .. gradeText .. "  " .. flags)

        local minT = (DelveGuide.Voidforge and DelveGuide.Voidforge.MIN_VOIDCORE_TIER) or 8
        -- Voidcores do not drop from delves; T8+ is where the end-of-run loot
        -- hits the max pool, which is what makes a bonus roll there worthwhile.
        self:AddLine(string.format("|cFFAA66CCT%d+: max-ilvl loot -- worth a Voidcore bonus roll|r", minT))

        self:Show()
    end
end

-- Hook OnUpdate so we catch the tooltip constantly redrawing the Bountiful timer
GameTooltip:HookScript("OnUpdate", InjectDelveData)

-- Reset our memory every single time Blizzard completely clears the tooltip
GameTooltip:HookScript("OnTooltipCleared", function(self)
    self.dgLastCheckedName = nil
end)