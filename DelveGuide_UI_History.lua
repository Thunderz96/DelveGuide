local UI = DelveGuide.UI

DelveGuide.RenderHistory = function()
    local cf=UI.NewContentFrame(); local y=10
    y=y+UI.CreateHeader(cf,y,"Delve Run History  --  Weekly Great Vault Summary")+4

    local clearBtn=CreateFrame("Button",nil,cf,"UIPanelButtonTemplate")
    clearBtn:SetSize(110,22); clearBtn:SetPoint("TOPRIGHT",cf,"TOPRIGHT",-10,-8)
    clearBtn:SetText("Clear History")
    clearBtn:SetScript("OnClick",function() StaticPopup_Show("DELVEGUIDE_CONFIRM_CLEAR_HISTORY") end)

    if not DelveGuideDB.history or #DelveGuideDB.history==0 then
        y=y+UI.CreateRow(cf,y,"|cFF888888No runs recorded yet. Go complete a Delve!|r")
    else
        local weeks,weekOrder={},{}
        for _,run in ipairs(DelveGuideDB.history) do
            local key=run.resetKey or 0
            if not weeks[key] then weeks[key]={}; table.insert(weekOrder,key) end
            table.insert(weeks[key],run)
        end
        table.sort(weekOrder,function(a,b)
            if a==0 then return false end; if b==0 then return true end; return a>b
        end)
        for _,key in ipairs(weekOrder) do
            local runs=weeks[key]; local count=#runs
            local weekLabel=key==0 and "|cFF888888Earlier / Legacy Runs|r" or ("|cFFFFD700Week of "..date("%b %d, %Y",key).."|r")
            local vaultText
            if count>=8 then vaultText="|cFF00FF44All 3 vault slots unlocked!|r"
            elseif count>=4 then vaultText=string.format("|cFFFFFF002/3 vault slots|r  |cFF888888(%d more for 3rd)|r",8-count)
            elseif count>=1 then vaultText=string.format("|cFFFF88441/3 vault slots|r  |cFF888888(%d more for 2nd)|r",4-count)
            else vaultText="|cFFFF4444No vault slots|r" end
            
            y=y+8
            y=y+UI.CreateRow(cf,y,weekLabel.."  |cFF888888"..count.." run(s)|r  --  "..vaultText)
            y=y+UI.CreateRow(cf,y,"|cFF555555"..string.rep("-",80).."|r")+2
            
            for _,run in ipairs(runs) do
                local tierStr=run.tier and ("  |cFF888888["..run.tier.."]|r") or ""
                local vaultStr=run.vaultIlvl and ("  |cFFFFD700"..run.vaultIlvl.." ilvl|r") or ""
                local charStr=run.char and ("|cFF00FF88"..run.char.."|r  ") or ""
                local timeStr=run.elapsed and string.format("  |cFF00BFFF[%dm %02ds]|r",math.floor(run.elapsed/60),math.floor(run.elapsed%60)) or ""
                local varStr=run.variant and ("  |cFFCCAAFF("..run.variant..")|r") or ""
                y=y+UI.CreateRow(cf,y,string.format("  |cFFCCCCCC%-18s|r  %s|cFF00BFFF%s|r",run.date,charStr,run.name)..varStr..tierStr..vaultStr..timeStr)
            end
        end
    end; cf:SetHeight(y+20)
end