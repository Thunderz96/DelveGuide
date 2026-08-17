local UI = DelveGuide.UI

DelveGuide.RenderHistory = function()
    local cf=UI.NewContentFrame(); local y=10
    y=y+UI.CreateHeader(cf,y,"Delve Run History  --  Weekly Great Vault Summary")+4

    -- Your Fastest Variants -- averaged from your own timed runs. This is also
    -- exactly the data /dg submit shares to help build community rankings.
    local vstats = DelveGuide.GetVariantRunStats and DelveGuide.GetVariantRunStats() or {}
    if #vstats > 0 then
        y=y+UI.CreateRow(cf,y,"|cFFFFD700Your Fastest Variants|r  |cFF888888(avg clear time from your timed runs -- help rank these via /dg submit)|r")+4
        for i,s in ipairs(vstats) do
            if i<=12 then
                y=y+UI.CreateRow(cf,y,string.format("  |cFF00BFFF[%dm %02ds]|r  |cFFCCAAFF%s|r |cFF888888(%s)|r  |cFF888888x%d run%s, ~T%d|r",
                    math.floor(s.avgSec/60), s.avgSec%60, s.variant, s.delve, s.count, s.count==1 and "" or "s", s.avgTier))
            end
        end
        if #vstats>12 then y=y+UI.CreateRow(cf,y,"|cFF888888  ...and "..(#vstats-12).." more|r") end
        y=y+10
    end

    local clearBtn=CreateFrame("Button",nil,cf,"UIPanelButtonTemplate")
    clearBtn:SetSize(110,22); clearBtn:SetPoint("TOPRIGHT",cf,"TOPRIGHT",-10,-8)
    clearBtn:SetText("Clear History")
    clearBtn:SetScript("OnClick",function() StaticPopup_Show("DELVEGUIDE_CONFIRM_CLEAR_HISTORY") end)

    if not DelveGuideDB.history or #DelveGuideDB.history==0 then
        y=y+UI.CreateRow(cf,y,"|cFF888888No runs recorded yet. Go complete a Delve!|r")
    else
        -- The Great Vault is PER CHARACTER, so vault progress must be counted
        -- per character too. Grouping only by week (as this used to) merged
        -- every alt's runs into one imaginary vault -- four alts with two runs
        -- each looked like "8 runs, all 3 slots unlocked" when in reality none
        -- of them had filled a single slot.
        local weeks,weekOrder={},{}
        for _,run in ipairs(DelveGuideDB.history) do
            local wkey=run.resetKey or 0
            if not weeks[wkey] then weeks[wkey]={chars={},order={},count=0}; table.insert(weekOrder,wkey) end
            local wk=weeks[wkey]
            -- Include realm so same-named alts on different realms don't merge.
            local ckey=(run.char or "Unknown")..(run.realm and ("-"..run.realm) or "")
            if not wk.chars[ckey] then wk.chars[ckey]={}; table.insert(wk.order,ckey) end
            table.insert(wk.chars[ckey],run)
            wk.count=wk.count+1
        end
        table.sort(weekOrder,function(a,b)
            if a==0 then return false end; if b==0 then return true end; return a>b
        end)

        local minCoreTier = (DelveGuide.Voidforge and DelveGuide.Voidforge.MIN_VOIDCORE_TIER) or 8

        -- Great Vault delve slots unlock at 2 / 4 / 8 runs.
        local function VaultText(n)
            if n>=8 then return "|cFF00FF44All 3 vault slots|r"
            elseif n>=4 then return string.format("|cFFFFFF002/3 vault slots|r  |cFF888888(%d more for 3rd)|r",8-n)
            elseif n>=2 then return string.format("|cFFFF88441/3 vault slots|r  |cFF888888(%d more for 2nd)|r",4-n)
            else return string.format("|cFFFF4444No vault slots|r  |cFF888888(%d more for 1st)|r",2-n) end
        end

        for _,wkey in ipairs(weekOrder) do
            local wk=weeks[wkey]
            local weekLabel=wkey==0 and "|cFF888888Earlier / Legacy Runs|r" or ("|cFFFFD700Week of "..date("%b %d, %Y",wkey).."|r")
            y=y+8
            y=y+UI.CreateRow(cf,y,weekLabel.."  |cFF888888"..wk.count.." run(s) across "..#wk.order.." character(s)|r")
            y=y+UI.CreateRow(cf,y,"|cFF555555"..string.rep("-",80).."|r")+2

            -- Most-active character first
            table.sort(wk.order,function(a,b) return #wk.chars[a] > #wk.chars[b] end)

            for _,ckey in ipairs(wk.order) do
                local runs=wk.chars[ckey]
                local count=#runs

                -- Voidcore eligibility needs a BOUNTIFUL run at T8+, not just
                -- any T8+ run. Runs logged before we recorded that flag are
                -- counted separately rather than silently assumed eligible.
                local coreRuns, unknownCore = 0, 0
                for _,run in ipairs(runs) do
                    if type(run.tierNum)=="number" and run.tierNum>=minCoreTier then
                        if run.bountiful==true then coreRuns=coreRuns+1
                        elseif run.bountiful==nil then unknownCore=unknownCore+1 end
                    end
                end
                local coreText=""
                if coreRuns>0 then
                    coreText=string.format("  --  |cFFAA66CC%d Voidcore-eligible|r |cFF888888(bountiful T%d+)|r",coreRuns,minCoreTier)
                elseif unknownCore>0 then
                    coreText=string.format("  --  |cFF888888%d T%d+ run(s), bountiful status not recorded|r",unknownCore,minCoreTier)
                end

                y=y+UI.CreateRow(cf,y,string.format("  |cFF00FF88%s|r  |cFF888888%d run(s)|r  --  %s%s",
                    ckey,count,VaultText(count),coreText))

                for _,run in ipairs(runs) do
                    local tierStr=run.tier and ("  |cFF888888["..run.tier.."]|r") or ""
                    local vaultStr=run.vaultIlvl and ("  |cFFFFD700"..run.vaultIlvl.." ilvl|r") or ""
                    local timeStr=run.elapsed and string.format("  |cFF00BFFF[%dm %02ds]|r",math.floor(run.elapsed/60),math.floor(run.elapsed%60)) or ""
                    local varStr=run.variant and ("  |cFFCCAAFF("..run.variant..")|r") or ""
                    local bountyStr=run.bountiful and "  |cFFFFD700[B]|r" or ""
                    -- Show the player's own language when we captured it; `name`
                    -- is the canonical English used for grouping and submissions.
                    local displayName = run.locName or run.name
                    y=y+UI.CreateRow(cf,y,string.format("      |cFFCCCCCC%-18s|r  |cFF00BFFF%s|r",run.date,displayName)..varStr..tierStr..bountyStr..vaultStr..timeStr)
                end
                y=y+4
            end
        end
    end; cf:SetHeight(y+20)
end