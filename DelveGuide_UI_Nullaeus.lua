local UI = DelveGuide.UI

DelveGuide.RenderNullaeus = function()
    local cf = UI.NewContentFrame(); local y = 10
    UI.EnsureFontFiles()

    y = y + UI.CreateHeader(cf, y, "Nullaeus  —  Season 1 Nemesis  |cFF888888(Tier ? / Tier ??)|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF888888Domanaar, Hand of the Harbinger. The '?' and '??' tier names are intentional — Blizzard masked the difficulty labels. Torment's Rise unlocked March 17 with Season 1.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Location|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Torment's Rise  —  Voidstorm|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  /way #2405 61.17 71.37  (between Nexus-Point Xenas and Obscurion Citadel)|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Unlock Requirements|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFFF8800  Tier ?   |r|cFFCCCCCC Complete any Tier 7 delve with at least 1 life remaining|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF4444  Tier ??  |r|cFFCCCCCC Complete any Tier 10 delve with at least 1 life remaining|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFF00FF88Beacon of Hope  —  Skip Torment's Rise entirely|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Purchase from |cFFFFD700Naleidea Rivergleam|r|cFFCCCCCC at Delver's HQ, Silvermoon — |cFFFFD7005,000 Undercoins|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFCCCCCC  Use inside any standard delve |cFFFFD700after the checkpoint|r|cFFCCCCCC. Nullaeus spawns — burn him to |cFF00FF8850% HP|r|cFFCCCCCC, loot the gold pile. Done.|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF8800  Tip: |r|cFFCCCCCC Use on Tier 8+ for best loot scaling. Cooldown: 1 hour. Weekly Bounty: once per week.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Boss Mechanics|r") + 4
    local mechanics = {
        { name="Emptiness of the Void", color="|cFFFF4444", desc="AoE Shadow damage, ~20s cooldown. |cFFFF4444Interrupt every single cast.|r No exceptions." },
        { name="Devouring Essence",     color="|cFFFF8800", desc="2.5s cast (Spell 1256358). Applies Shadow DoT every 2s for 18s. Interrupt or dispel via Valeera (Healer). Each tick it lands builds |cFFFF4444Umbral Rage|r stacks." },
        { name="Dread Portal",          color="|cFFBF5FFF", desc="Opens a portal: spawns add wave + applies |cFFFF4444Oblivion Shell|r (boss takes zero damage until all adds are dead). Immediately AoE the adds — do not tunnel Nullaeus." },
        { name="Umbral Rage",           color="|cFFFF4444", desc="+10% damage per stack. |cFFFF4444Never decays|r during the fight. Stacks from lingering adds and unimpeded Devouring Essence ticks. This is the mechanic that kills groups — it compounds." },
    }
    for _, m in ipairs(mechanics) do
        y = y + UI.CreateRow(cf, y, m.color .. "  " .. m.name .. "|r") + 2
        y = y + UI.CreateRow(cf, y, "|cFF888888  " .. m.desc .. "|r") + 4
    end

    y = y + 4; y = y + UI.CreateRow(cf, y, "|cFFFFD700Phase Transitions  |cFF888888(Tier ? reference)|r") + 4
    local phases = {
        { hp="75%", event="2x Razorshell Ravagers spawn + first Void Orb activates (persistent arena goop)" },
        { hp="50%", event="7x Spitting Ticks spawn + Gravity Well activates" },
        { hp="25%", event="|cFFFF4444Enslaved Voidcaster|r appears — high HP, spams Shadow Bolt (~55k/hit)" },
    }
    for _, p in ipairs(phases) do y = y + UI.CreateRow(cf, y, string.format("|cFF00BFFF  %-5s|r  |cFFCCCCCC%s|r", p.hp, p.event)) + 2 end
    y = y + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Recommended Setup|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF44AAFF  Companion:     |r|cFFCCCCCCValeera Sanguinar — |cFF00FF88Healer spec|r|cFFCCCCCC (dispels Devouring Essence, sustains melee)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF44AAFF  Combat Curio:  |r|cFFCCCCCCPorcelain Blade Tip (burst DPS aligned with add-phase windows)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF44AAFF  Utility Curio: |r|cFFCCCCCCOverflowing Voidspire (activates ~25s in, dual damage + healing value)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF44AAFF  Valeera level: |r|cFFCCCCCC20+ for curio slots to be meaningful|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Recommended Item Level|r") + 4
    y = y + UI.CreateRow(cf, y, "|cFF00FF88  Tier ?   |r|cFFCCCCCC~255 ilvl  (fresh Midnight launch gear is sufficient)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFFFF8800  Tier ??  |r|cFFCCCCCC272–278 ilvl  (Hero track target; 285+ Mythic gear = clean clear)|r") + 2
    y = y + UI.CreateRow(cf, y, "|cFF888888  Note: clean interrupt discipline compensates for roughly 10–15 ilvl of deficit.|r") + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Tips & Strategy|r") + 4
    local tips = {
        "|cFFFF4444Interrupt Emptiness of the Void every cast.|r  This is non-negotiable.",
        "When Dread Portal fires, |cFFFFD700immediately AoE the adds.|r  Oblivion Shell makes the boss unkillable — faster add clears = fewer Umbral Rage stacks.",
        "Treat Umbral Rage as a |cFFFF4444compounding timer,|r not a soft enrage. Two missed interrupts early will make the last phase unsurvivable.",
        "The 25% Voidcaster hits hard — save a |cFF44AAFF defensive cooldown|r for that phase.",
        "Tank specs have an inherent advantage due to white swing mitigation. Good first-clear option.",
        "Install |cFFFFD700Deadly Boss Mods|r — Nullaeus's ability timing is consistent enough that audio alerts let you pre-position interrupts rather than reacting to cast bars.",
        "For the Beacon of Hope workflow: you only need 50% — once the gold pile spawns, |cFF00FF88you can stop fighting.|r",
        "Save your Beacon of Hope for a |cFFFF8800Tier 8+|r delve run. The Hidden Trove loot scales with delve tier.",
    }
    for _, tip in ipairs(tips) do y = y + UI.CreateRow(cf, y, "|cFF888888  • |r" .. tip) + 3 end
    y = y + 8

    y = y + UI.CreateRow(cf, y, "|cFFFFD700Rewards|r") + 4
    local rewards = {
        { label="Nullaeus Domaneye",           detail="Cosmetic helm + 30 Hero Dawncrests (outside seasonal cap)  — any difficulty kill" },
        { label="\"the Ominous\" title",       detail="+ 30 more Hero Dawncrests — requires Tier ?? kill" },
        { label="Arcanovoid Construct",        detail="Flying mount — solo Tier ?? clear" },
        { label="Fabled Vanquisher of Nullaeus", detail="|cFFFF4444Region-limited to first 4,000 players|r — solo Tier ?? title, time-sensitive" },
        { label="Dominating Victory (toy)",    detail="From the introductory questline: A Missing Member > Nulling Nullaeus" },
    }
    for _, r in ipairs(rewards) do y = y + UI.CreateRow(cf, y, "|cFFFFD700  " .. r.label .. "  |r|cFF888888" .. r.detail .. "|r") + 2 end

    cf:SetHeight(y + 20)
end