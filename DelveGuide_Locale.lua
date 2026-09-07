-- ============================================================
-- DelveGuide_Locale.lua  --  UI string table (review 3.4)
-- ============================================================
-- Loads first, right after the libraries, so every other file can write
--   local L = DelveGuide.L
-- and wrap user-visible text as L["Some English text"].
--
-- The English text IS the key and IS the default: an unknown key returns
-- itself, so enUS needs no table at all and a locale with a missing phrase
-- shows English for that one phrase instead of erroring or showing nothing.
--
-- Translations come from CurseForge's localization platform at package
-- time. Each @localization@ line below is replaced by the BigWigs packager
-- with `L["English"] = "translation"` lines for that locale (format
-- lua_additive_table); phrases nobody has translated are left out
-- (handle-unlocalized="ignore") and fall back to the key. Running from
-- source, the lines are comments and every locale reads English.
--
-- What gets wrapped: text a player reads in the window, HUD, widget,
-- checklist, Victory screen, tooltips and normal chat messages. What does
-- NOT: game data used for matching (delve, variant, zone, item, faction
-- names), slash-command words, debug / export output meant for bug
-- reports, changelog text, colour codes and SavedVariables keys.
--
-- Placeholders: keep %s / %d in the translation, in the same order; use
-- %1$s-style positions only if a locale needs to reorder them.

DelveGuide = DelveGuide or {}

local L = setmetatable({}, { __index = function(_, key) return key end })
DelveGuide.L = L

local locale = GetLocale and GetLocale() or "enUS"

if locale == "deDE" then
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "esES" then
--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "esMX" then
--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "frFR" then
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "itIT" then
--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "koKR" then
--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="ignore")@
elseif locale == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="ignore")@
end
