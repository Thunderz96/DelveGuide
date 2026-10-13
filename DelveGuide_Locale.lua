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
-- Translations live in this repository as Locales\<locale>.lua files (deDE,
-- esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, zhTW), each shaped
--   if GetLocale() ~= "deDE" then return end
--   local L = DelveGuide.L
--   L["Keys: %d/%d"] = "Schlüssel: %d/%d"
-- and listed in DelveGuide.toc directly after this file, before
-- DelveGuide_Data.lua (the data file reads L while it loads). A translator
-- starts from Locales\TEMPLATE.lua, which tools/extract_locale_phrases.py
-- regenerates from the code, and sends a pull request. Lines left
-- untranslated should be deleted so they fall back to English.
--
-- CurseForge's own translation platform is NOT available to this project
-- (created on the new authors portal, which never got that feature --
-- checked 2026-09-06), which is why the files are hosted here.
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

DelveGuide.L = setmetatable({}, { __index = function(_, key) return key end })
