local UI = DelveGuide.UI

local function GetSpecRec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return nil end
    local specID = select(1, GetSpecializationInfo(idx))
    if not specID then return nil end
    return DelveGuideData.specCurioRecs and DelveGuideData.specCurioRecs[specID], specID
end

DelveGuide.RenderCurios = function()
    local cf=UI.NewContentFrame(); local y=10
    UI.EnsureFontFiles(); local _,_,rH=UI.GetScaledSizes()

    local rec, specID = GetSpecRec()
    y=y+UI.CreateHeader(cf,y,"Curios & Poisons  --  Season 2")+4
    y=y+UI.CreateRow(cf,y,"|cFF888888Season 2 rotated the curio set -- last season's curios are gone. Rankings show [?] until the meta settles; the description tells you what each does.|r")+6

    if rec then
        y=y+UI.CreateRow(cf,y,string.format("|cFF00BFFFYour Spec:|r |cFFFFFFFF%s|r  |cFF888888(specID %d)|r", rec.spec, specID))
        y=y+UI.CreateRow(cf,y,string.format("|cFF00FF88Recommended Valeera role:|r |cFF00CFFF%s|r", rec.companion or "--"))
    else
        y=y+UI.CreateRow(cf,y,"|cFF888888No spec data - enter the world to detect your specialization.|r")
    end
    y=y+UI.CreateRow(cf,y,"|cFF888888Per-spec curio picks are being rebuilt for Season 2. The most commonly recommended Combat pick so far is |r|cFFFFD700Corrosive Bilespear|r|cFF888888.|r")+8

    -- Season 2 curios, grouped by type
    for _,ctype in ipairs({"Combat","Utility"}) do
        y=y+4; y=y+UI.CreateRow(cf,y,UI.TypeColor(ctype).." Curios")
        y=y+UI.CreateRow(cf,y,"|cFF888888"..string.format("%-4s  %-26s  %s","Rank","Name","Effect").."|r")
        for _,c in ipairs(DelveGuideData.curios) do
            if c.curiotype==ctype then
                y=y+UI.CreateRow(cf,y,string.format("[%s]  |cFFFFFFFF%-26s|r  |cFF888888%s|r",UI.GradeColor(c.ranking),c.name,c.description))
            end
        end; y=y+8
    end

    -- Poisons (new 12.1 choice node -- independent of Valeera's role)
    y=y+4; y=y+UI.CreateRow(cf,y,"|cFFFFD700Poisons|r  |cFF888888(new in 12.1 -- pick one in Valeera's supplies menu, independent of her role)|r")
    for _,p in ipairs(DelveGuideData.poisons or {}) do
        local tag = p.base and "|cFF00FF88[Base] |r" or "|cFFFFD700[Quest]|r"
        y=y+UI.CreateRow(cf,y,string.format("%s |cFFAA66CC%s|r  |cFFCCCCCC%s|r  |cFF888888%s|r", tag, p.name, p.effect, p.use))
    end
    y=y+UI.CreateRow(cf,y,"|cFF00FF88Rule of thumb:|r |cFFCCCCCCBloodcrypt Toxin is the safe default; Frostheart Venom (once unlocked) is a strong all-round defensive pick. Forgotten Master looks strong but drops every stack the moment you take a hit, so it only pays off when you're comfortably out-gearing the tier.|r")+8

    cf:SetHeight(y+20)
end