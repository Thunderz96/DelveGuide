local UI = DelveGuide.UI

DelveGuide.RenderFuture = function()
    local cf=UI.NewContentFrame(); local y=10
    y=y+UI.CreateHeader(cf,y,"Future / Upcoming Content & Patch Notes")+4
    local seen,cats={},{}
    for _,f in ipairs(DelveGuideData.future) do
        if not seen[f.category] then seen[f.category]=true; table.insert(cats,f.category) end
    end
    for _,cat in ipairs(cats) do
        y=y+4; y=y+UI.CreateRow(cf,y,"|cFF00FF88"..cat.."|r")
        for _,f in ipairs(DelveGuideData.future) do
            if f.category==cat then y=y+UI.CreateRow(cf,y,"|cFFCCCCCC* |r"..f.note)+2 end
        end; y=y+8
    end; cf:SetHeight(y+20)
end