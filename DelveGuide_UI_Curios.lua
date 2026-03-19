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
    y=y+UI.CreateHeader(cf,y,"Curios Rankings  --  S=Best  |  F=Worst")+4

    if rec then
        local hi=cf:CreateTexture(nil,"BACKGROUND"); hi:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
        hi:SetSize(UI.WINDOW_W-52,rH*3+14); hi:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        hi:SetGradient("HORIZONTAL",CreateColor(0,0.4,1,0.18),CreateColor(0,0.4,1,0))
        local bar=cf:CreateTexture(nil,"ARTWORK"); bar:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
        bar:SetSize(3,rH*3+14); bar:SetColorTexture(0,0.6,1,1)
        y=y+UI.CreateRow(cf,y,string.format("|cFF00BFFFYour Spec:|r |cFFFFFFFF%s|r  |cFF888888(specID %d)|r", rec.spec, specID))
        y=y+UI.CreateRow(cf,y,string.format("|cFF00FF88Recommended:|r  Combat: |cFFFFD700%s|r   Utility: |cFFFFD700%s|r   Valeera: |cFF00CFFF%s|r", rec.combat, rec.utility, rec.companion))
        if rec.notes then y=y+UI.CreateRow(cf,y,"|cFF888888"..rec.notes.."|r") end
        y=y+6
        y=y+UI.CreateRow(cf,y,"|cFFFF8844[Nemesis Warning]|r Mandate of Sacred Death procs require profession nodes. Nullaeus arena has none — swap to Overflowing Voidspire or Ebon Crown.")
        y=y+8
    else
        y=y+UI.CreateRow(cf,y,"|cFF888888No spec data available — enter the world to detect your specialization.|r")
        y=y+8
    end

    y=y+UI.CreateRow(cf,y,"|cFFFFD700-- General Loadout Reference --|r")
    y=y+UI.CreateRow(cf,y,"|cFF00FF00Safe / Progression:|r  Sanctum's Edict (Combat)  +  Ebon Crown of Subjugation (Utility)")
    y=y+UI.CreateRow(cf,y,"|cFFFF4444Speed / Farming:|r    Porcelain Blade Tip (Combat)  +  Mandate of Sacred Death (Utility)")
    y=y+UI.CreateRow(cf,y,"|cFF555555"..string.rep("-",90).."|r")+4

    local specCombat  = rec and rec.combat  or nil
    local specUtility = rec and rec.utility or nil
    for _,ctype in ipairs({"Combat","Utility"}) do
        local specPick = ctype=="Combat" and specCombat or specUtility
        y=y+4; y=y+UI.CreateRow(cf,y,UI.TypeColor(ctype).." Curios")
        y=y+UI.CreateRow(cf,y,"|cFF888888"..string.format("%-4s  %-32s  %s","Rank","Name","Effect").."|r")
        for _,c in ipairs(DelveGuideData.curios) do
            if c.curiotype==ctype then
                local badge = (c.name==specPick) and "|cFF00FF88[Your Spec] |r" or ""
                if c.name==specPick then
                    local fw=cf:CreateTexture(nil,"BACKGROUND"); fw:SetPoint("TOPLEFT",cf,"TOPLEFT",2,-(y-1))
                    fw:SetSize(UI.WINDOW_W-52,rH+2); fw:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                    fw:SetGradient("HORIZONTAL",CreateColor(0,1,0.3,0.15),CreateColor(0,1,0.3,0))
                end
                y=y+UI.CreateRow(cf,y,string.format("%s[%s]  %-32s  %s",badge,UI.GradeColor(c.ranking),c.name,c.description))
            end
        end; y=y+8
    end
    cf:SetHeight(y+20)
end