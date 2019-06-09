---
--- 23.05.2019
---
--- ============================ HEADER ============================
if not TMW then return end 
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
local TargetColor = CreateFrame("Frame", "TargetColor", UIParent)
TargetColor:SetBackdrop(nil)
TargetColor:SetFrameStrata("TOOLTIP")
TargetColor:SetToplevel(true)
TargetColor:SetSize(1, 1)
TargetColor:SetScale(1);
TargetColor:SetPoint("TOPLEFT", 442, 0)
TargetColor.texture = TargetColor:CreateTexture(nil, "TOOLTIP")
TargetColor.texture:SetAllPoints(true)
TargetColor.texture:SetColorTexture(0, 0, 0, 1.0)
local members, incDMG_members, R_CustomT = {}, {}, {}
local R_Tanks, R_DPS, R_Heal = {}, {}, {}
local Frequency, FrequencyPairs = {}, {}

local pairs, tableexist = pairs, tableexist
local UnitGetIncomingHeals, UnitHealth, UnitHealthMax, UnitInRange, UnitGUID, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsConnected, UnitThreatSituation, UnitIsUnit, UnitExists, UnitIsPlayer =
UnitGetIncomingHeals, UnitHealth, UnitHealthMax, UnitInRange, UnitGUID, UnitIsCharmed, UnitIsDeadOrGhost, UnitIsConnected, UnitThreatSituation, UnitIsUnit, UnitExists, UnitIsPlayer

-- Toggle valid: "TANK", "DAMAGER", "HEALER", "RAID", nil
HE_Toggle = nil -- will heal everything
-- Toggle for pets 
HE_Pets = true

local function CalculateHP(t)
    incomingheals = UnitGetIncomingHeals(t) and UnitGetIncomingHeals(t) or 0
    local PercentWithIncoming = 100 * (UnitHealth(t) + incomingheals) / UnitHealthMax(t)
    local ActualWithIncoming = (UnitHealthMax(t) - (UnitHealth(t) + incomingheals))
    return PercentWithIncoming, ActualWithIncoming
end
local function CanHeal(t)
    return UnitInRange(t)
    and not Env.InLOS(UnitGUID(t)) -- LOS System (target)
    and not Env.InLOS(t)           -- LOS System (another such as party)
    --and UnitCanCooperate("player", t)
    and not UnitIsCharmed(t)
    and not Env.UNITDead(t)
    and UnitIsConnected(t)
    and Env.Unit(t):DeBuffCyclone() == 0 -- Cyclone
    and 
    ( 
        Env.Unit(t):HasDeBuffs(76577) == 0 or -- Smoke Bomb
        Env.Unit("player"):HasDeBuffs(76577) > 0
    )    
end

local function HealingEngine(ACTUALHP)    
    local ActualHP = ACTUALHP or false
    wipe(members)
    wipe(incDMG_members)
    wipe(R_Tanks)
    wipe(R_DPS)
    wipe(R_Heal)
    incDMG_members = {}
    R_Tanks, R_DPS, R_Heal = {}, {}, {}
    if Env.PvPCache["Group_FriendlyType"] ~= "raid" then 
        members = { { Unit = "player", HP = CalculateHP("player"), GUID = UnitGUID("player"), AHP = select(2, CalculateHP("player")), incDMG = incdmg("player") } }
    else 
        members = {}
    end 
    
    -- Check if the Player is apart of the Custom Table
    for i = 1, #R_CustomT do
        if UnitGUID("player") == R_CustomT[i].GUID then
            R_CustomT[i].Unit = "player"
            R_CustomT[i].HP = CalculateHP("player")
            R_CustomT[i].AHP = select(2, CalculateHP("player"))
        end
    end
    
    local skip_dispel = false 
    local group = Env.PvPCache["Group_FriendlyType"]
    for i = 1, Env.PvPCache["Group_FriendlySize"] do
        local member = group .. i        
        local memberhp, memberahp = CalculateHP(member)
        local memberGUID = UnitGUID(member)
        -- Frequency (Record By Each Member)
        -- Note: We can't use CanHeal here because it will take not all units results could be wrong
        FrequencyPairs["MAXHP"] = (FrequencyPairs["MAXHP"] or 0) + UnitHealthMax(member)
        FrequencyPairs["AHP"] = (FrequencyPairs["AHP"] or 0) + memberahp
        
        -- Checking all Party/Raid Members for Range/Health
        if CanHeal(member) then
            local DMG = getRealTimeDMG(member) -- incdmg(member)
            local Actual_DMG = DMG
            --local HPS = getHEAL(member)            
            
            -- Stop decrease predict HP if offset for DMG more than 15% of member's HP
            local DMG_offset = UnitHealthMax(member) * 0.15
            if DMG > DMG_offset then 
                DMG = DMG_offset
            end
            
            -- Checking if Member has threat
            if UnitThreatSituation(member) == 3 then
                memberhp = memberhp - 3
            end            
            
            -- Holy Paladin 
            if Env.UNITSpec("player", 65) then                 
                if (not skip_dispel or Env.Unit(member):IsHealer()) and Env.SpellUsable(4987) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
					-- DISPEL PRIORITY
                    skip_dispel = true 
                    memberhp = 50 -- if we will have lower unit than 50% then don't dispel it
                    if Env.Unit(member):IsHealer() then 
                        memberhp = 25
                    end
                elseif AzeriteRank(287268) > 0 and Env.SpellCD(20473) <= Env.CurrentTimeGCD() and Env.Unit(member, 0.5):HasBuffs(287280, "player") <= Env.GCD() then 
					-- Glimmer of Light 
					-- Generally, prioritize players that might die in the next few seconds > non-Beaconed tank (without Glimmer buff) > Beaconed tank (without Glimmer buff) > players without the Glimmer buff
					if Env.PredictHeal("HolyShock", member) then 
						if Env.Unit(member):IsTank() then 
							if Env.Unit(member):HasBuffs({156910, 53563}, "player") == 0 then 
								memberhp = 35
							else 
								memberhp = 45
							end 
						else 
							memberhp = memberhp - 35
						end 
					else
						memberhp = memberhp - 10
					end 
                elseif memberhp < 100 then      
					-- Beacon HPS SYSTEM + hot current ticking and total duration
                    local BestowFaith1, BestowFaith2 = Env.Unit(member):HasBuffs(223306, "player")
                    if BestowFaith1 > 0 then 
                        memberhp = memberhp + ( 100 * (Env.GetDescription(223306)[1]) / UnitHealthMax(member) )
                    end 
                    -- Checking if Member has Beacons on them            
                    if Env.Unit(member):HasBuffs({53563, 156910}, "player") > 0 then
                        memberhp = memberhp + ( 100 * (getHPS("player")*0.4) / UnitHealthMax(member) ) - ( 100 * DMG / UnitHealthMax(member) )
                    end  
                end 
            end 
            
            -- Restor Druid 
            if Env.UNITSpec("player", 105) then 
                -- DISPEL PRIORITY
                if (not skip_dispel or Env.Unit(member):IsHealer()) and Env.SpellUsable(88423) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
                    skip_dispel = true 
                    memberhp = 50 -- if we will have lower unit than 50% then don't dispel it
                    if Env.Unit(member):IsHealer() then 
                        memberhp = 25
                    end
                    -- HOT SYSTEM: current ticking and total duration
                elseif memberhp < 100 then                    
                    local Rejuvenation1, Rejuvenation2 = Env.Unit(member):HasBuffs(774, "player")
                    local Regrowth1, Regrowth2 = Env.Unit(member):HasBuffs(8936, "player")
                    local WildGrowth1, WildGrowth2 = Env.Unit(member):HasBuffs(48438, "player")
                    local Lifebloom1, Lifebloom2 = Env.Unit(member):HasBuffs(33763, "player")                
                    local Germination1, Germination2 = Env.Unit(member):HasBuffs(155777, "player") -- Rejuvenation Talent 
                    local summup, summdmg = 0, {}
                    if Rejuvenation1 > 0 then 
                        summup = summup + (Env.GetDescription(774)[1] / Rejuvenation2 * Rejuvenation1)
                        table.insert(summdmg, Rejuvenation1)
                    else
                        -- If current target is Tank then to prevent staying on that target we will cycle rest units 
                        if healingTarget and healingTarget ~= "None" and Env.Unit(healingTarget):IsTank() then 
                            memberhp = memberhp - 15
                        else 
                            summup = summup - (Env.GetDescription(774)[1] * 3)
                        end 
                    end
                    
                    if Regrowth1 > 0 then 
                        summup = summup + (Env.GetDescription(8936)[2] / Regrowth2 * Regrowth1)
                        table.insert(summdmg, Regrowth1)
                    end
                    
                    if WildGrowth1 > 0 then 
                        summup = summup + (Env.GetDescription(48438)[1] / WildGrowth2 * WildGrowth1)
                        table.insert(summdmg, WildGrowth1)                    
                    end
                    
                    if Lifebloom1 > 0 then 
                        summup = summup + (Env.GetDescription(33763)[1] / Lifebloom2 * Lifebloom1) 
                        table.insert(summdmg, Lifebloom1)    
                    end
                    
                    if Germination1 > 0 then -- same with Rejuvenation
                        summup = summup + (Env.GetDescription(774)[1] / Germination2 * Germination1)
                        table.insert(summdmg, Germination1)    
                    end
                    
                    -- Get longer hot duration and predict incoming damage by that 
                    table.sort(summdmg, function (x, y)
                            return x > y
                    end)
                    
                    -- Now we convert it to persistent (from value to % as HP)
                    if summup > 0 then 
                        -- current %HP with pre casting heal + predict hot heal - predict incoming dmg 
                        memberhpHotSystem = memberhp + ( 100 * summup / UnitHealthMax(member) ) - ( 100 * (DMG * summdmg[1]) / UnitHealthMax(member) )
                        if memberhpHotSystem < 100 then
                            memberhp = memberhpHotSystem
                        end
                    end                    
                end
            end
            
            -- Discipline Priest
            if Env.UNITSpec("player", 256) then                 
                if (not skip_dispel or Env.Unit(member):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
					-- DISPEL PRIORITY
                    skip_dispel = true 
                    memberhp = 50 -- if we will have lower unit than 50% then don't dispel it
                    if Env.Unit(member):IsHealer() then 
                        memberhp = 25
                    end 
				elseif AtonementRenew_Toggle and Env.Unit(member):HasBuffs(81749, "player") <= Env.CurrentTimeGCD() then 				
					-- Toggle "Group Atonement/Renew﻿"
					memberhp = 50
                elseif memberhp < 100 then                    
                    -- Atonement priority 
                    if Env.Unit(member):HasBuffs(81749, "player") > 0 and Env.oPR and Env.oPR["AtonementHPS"] then 
                        memberhp = memberhp + ( 100 * Env.oPR["AtonementHPS"] / UnitHealthMax(member) )
                    end 
                    
                    -- Absorb system 
                    -- Pre pare 
                    if CombatTime("player") <= 5 and 
                    (
                        CombatTime("player") > 0 or 
                        (
                            -- Pre shield before battle will start
                            ( Env.Zone == "arena" or Env.Zone == "pvp" ) and
                            TMW.time - Env.ZoneTimeStampSinceJoined < 120                             
                        )
                    ) and getAbsorb(member, 17) == 0 then 
                        memberhp = memberhp - 10
                    end                     
                    
                    -- Toggle or PrePare combat or while Rapture always
                    if HE_Absorb or CombatTime("player") <= 5 or Env.Unit("player"):HasBuffs(47536, "player") > Env.CurrentTimeGCD() then 
                        memberhp = memberhp + ( 100 * getAbsorb(member, 17) / UnitHealthMax(member) )
                    end 
                end 
            end 
            
            -- Holy Priest
            if Env.UNITSpec("player", 257) then                 
                if (not skip_dispel or Env.Unit(member):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
					-- DISPEL PRIORITY
                    skip_dispel = true 
                    memberhp = 50 -- if we will have lower unit than 50% then don't dispel it
                    if Env.Unit(member):IsHealer() then 
                        memberhp = 25
                    end  
				elseif AtonementRenew_Toggle and Env.Unit(member):HasBuffs(139, "player") <= Env.CurrentTimeGCD() then 				
					-- Toggle "Group Atonement/Renew﻿"
					memberhp = 50
                elseif memberhp < 100 then 
                    if Env.UnitIsTrailOfLight(member) then 
                        -- Single Rotation 
                        local ST = Env.IsIconDisplay("TMW:icon:1RhherQmOw_V") or 0
                        if ST == 2061 then 
                            memberhp = memberhp + ( 100 * (Env.GetDescription(2061)[1] * 0.35) / UnitHealthMax(member) )
                        elseif ST == 2060 then 
                            memberhp = memberhp + ( 100 * (Env.GetDescription(2060)[1] * 0.35) / UnitHealthMax(member) )
                        end 
                    end 
                end 
            end 
            
            -- Misc: Sort by Roles 
            if Env.Unit(member):IsTank() then
                memberhp = memberhp - 2
                table.insert(R_Tanks, { Unit = member, HP = memberhp, GUID = memberGUID, AHP = memberahp, incDMG = Actual_DMG })      
            elseif Env.UNITRole(member, "DAMAGER")  then
                memberhp = memberhp - 1
                table.insert(R_DPS, { Unit = member, HP = memberhp, GUID = memberGUID, AHP = memberahp, incDMG = Actual_DMG })
            elseif Env.Unit(member):IsHealer() then                
                if UnitIsUnit("player", member) and Env.UNITHP("player") < 97 then 
                    memberhp = memberhp - 2
                else 
                    memberhp = memberhp + 2
                end
                table.insert(R_Heal, { Unit = member, HP = memberhp, GUID = memberGUID, AHP = memberahp, incDMG = Actual_DMG })
            end
            -- Misc: If they are in the Custom Table add their info in
            for i = 1, #R_CustomT do
                if UnitGUID(member) == R_CustomT[i].GUID then
                    R_CustomT[i].Unit = member
                    R_CustomT[i].HP = memberhp
                    R_CustomT[i].AHP = memberahp
                end
            end
            table.insert(members, { Unit = member, HP = memberhp, GUID = memberGUID, AHP = memberahp, incDMG = Actual_DMG } )
        end        
        
        -- Checking Pets in the group
        if HE_Pets and CanHeal(group .. "pet" .. i) then
            local memberpet, memberpethp = group .. "pet" .. i, nil
            if CombatTime("player") > 0 then                
                memberpethp = CalculateHP(memberpet) * 1.35
            else                
                memberpethp = CalculateHP(memberpet) * 1.15
            end
            
            -- Checking if Pet is apart of the CustomTable
            for i = 1, #R_CustomT do
                if UnitGUID(memberpet) == R_CustomT[i].GUID then
                    R_CustomT[i].Unit = memberpet
                    R_CustomT[i].HP = memberpethp
                    R_CustomT[i].AHP = select(2, CalculateHP(memberpet))
                end
            end
            table.insert(members, { Unit = memberpet, HP = memberpethp, GUID = UnitGUID(memberpet), AHP = select(2, CalculateHP(memberpet)), incDMG = getRealTimeDMG(memberpet) }) -- incdmg(memberpet)
        end
    end
    
    -- Frequency (Summary)
    if FrequencyPairs["MAXHP"] and FrequencyPairs["MAXHP"] > 0 then 
        table.insert(Frequency, { 
                TIME = TMW.time, 
                -- Max Members Actual HP
                MAXHP = FrequencyPairs["MAXHP"], 
                -- Current Members Actual HP
                AHP = FrequencyPairs["AHP"],
        })
        wipe(FrequencyPairs)
        for i = #Frequency, 1, -1 do             
            -- Remove data longer than 5 seconds 
            if TMW.time - Frequency[i].TIME > 5 then 
                table.remove(Frequency, i)                
            end 
        end 
    end 
    
    -- So if we pass that ActualHP is true, then we will sort by most health missing. If not, we sort by lowest % of health.
    if #members > 1 then 
        -- Sort by most damage receive
        for k, v in pairs(members) do
            table.insert(incDMG_members, v)
        end
        table.sort(incDMG_members, function(x, y)
                return x.incDMG > y.incDMG
        end)  
        
        -- Sort by HP or AHP
        if not ActualHP then                
            table.sort(members, function(x, y)
                    return x.HP < y.HP
            end)
            if #R_Tanks > 1 then
                table.sort(R_Tanks, function(x, y)
                        return x.HP < y.HP
                end)
            end
            if #R_DPS > 1 then
                table.sort(R_DPS, function(x, y)
                        return x.HP < y.HP
                end)
            end
            if #R_Heal > 1 then
                table.sort(R_Heal, function(x, y)
                        return x.HP < y.HP
                end)
            end
        elseif ActualHP then
            table.sort(members, function(x, y)
                    return x.AHP > y.AHP
            end)
            if #R_Tanks > 1 then
                table.sort(R_Tanks, function(x, y)
                        return x.AHP > y.AHP
                end)
            end
            if #R_DPS > 1 then
                table.sort(R_DPS, function(x, y)
                        return x.AHP > y.AHP
                end)
            end
            if #R_Heal > 1 then
                table.sort(R_Heal, function(x, y)
                        return x.AHP > y.AHP
                end)
            end
        end
    end 
end

local healingTarget, healingTargetGUID = "None", "None"
local function setHealingTarget(TARGET, HP)
    local target = TARGET or nil
    local hp = HP or 99
    
    if TARGET == "TANK" and #R_Tanks > 0 then
        healingTarget = R_Tanks[1].Unit
        healingTargetGUID = R_Tanks[1].GUID
        return R_Tanks[1].HP
    end
    
    if TARGET == "DAMAGER" and #R_DPS > 0 and R_DPS[1].HP < hp then
        healingTarget = R_DPS[1].Unit
        healingTargetGUID = R_DPS[1].GUID
        return R_DPS[1].HP
    end
    
    if TARGET == "HEALER" and #R_Heal > 0 and R_Heal[1].HP < hp then
        healingTarget = R_Heal[1].Unit
        healingTargetGUID = R_Heal[1].GUID
        return R_Heal[1].HP
    end
    
    if TARGET == "RAID" then -- No Tanks
        if #R_DPS > 0 and #R_Heal > 0 and R_DPS[1].HP <= R_Heal[1].HP then 
            healingTarget = R_DPS[1].Unit
            healingTargetGUID = R_DPS[1].GUID
            return R_DPS[1].HP 
        elseif #R_Heal > 0 then 
            healingTarget = R_Heal[1].Unit
            healingTargetGUID = R_Heal[1].GUID
            return R_Heal[1].HP
        end
    end
    
    if TARGET == nil and #members > 0 and members[1].HP < 99 then
        healingTarget = members[1].Unit
        healingTargetGUID = members[1].GUID
        return members[1].HP
    end
    healingTarget = "None"
    healingTargetGUID = "None"
end

local function setColorTarget()
    --Default START COLOR
    TargetColor.texture:SetColorTexture(0, 0, 0, 1.0)   
    
    --If we have a mouseover target, stop healing engine
    if MouseOver_Toggle and MouseHasFrame() then       
        return
    end
    
    --If we have a current target or boss then do nothing.
    if UnitExists("target") and (healingTargetGUID == UnitGUID("target") or Env.UNITLevel("target") == -1) then
        return
    end
    
    --If we have no one to heal then do nothing.
    if healingTarget == nil or healingTargetGUID == nil or (MouseOver_Toggle and Env.Unit("mouseover"):IsEnemy()) or Env.Unit("target"):IsEnemy() then
        return
    end
    
    --Party
    if healingTarget == "party1" then
        TargetColor.texture:SetColorTexture(0.345098, 0.239216, 0.741176, 1.0)
        return
    end
    if healingTarget == "party2" then
        TargetColor.texture:SetColorTexture(0.407843, 0.501961, 0.086275, 1.0)
        return
    end
    if healingTarget == "party3" then
        TargetColor.texture:SetColorTexture(0.160784, 0.470588, 0.164706, 1.0)
        return
    end
    if healingTarget == "party4" then
        TargetColor.texture:SetColorTexture(0.725490, 0.572549, 0.647059, 1.0)
        return
    end   
    
    --PartyPET
    if healingTarget == "partypet1" then
        TargetColor.texture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
        return
    end
    if healingTarget == "partypet2" then
        TargetColor.texture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
        return
    end
    if healingTarget == "partypet3" then
        TargetColor.texture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
        return
    end
    if healingTarget == "partypet4" then
        TargetColor.texture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
        return
    end        
    
    --Raid
    if healingTarget == "raid1" then
        TargetColor.texture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
        return
    end
    if healingTarget == "raid2" then
        TargetColor.texture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
        return
    end
    if healingTarget == "raid3" then
        TargetColor.texture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
        return
    end
    if healingTarget == "raid4" then
        TargetColor.texture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
        return
    end
    if healingTarget == "raid5" then
        TargetColor.texture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
        return
    end
    if healingTarget == "raid6" then
        TargetColor.texture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid7" then
        TargetColor.texture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
        return
    end
    if healingTarget == "raid8" then
        TargetColor.texture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid9" then
        TargetColor.texture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid10" then
        TargetColor.texture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
        return
    end
    if healingTarget == "raid11" then
        TargetColor.texture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
        return
    end
    if healingTarget == "raid12" then
        TargetColor.texture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid13" then
        TargetColor.texture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
        return
    end
    if healingTarget == "raid14" then
        TargetColor.texture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid15" then
        TargetColor.texture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
        return
    end
    if healingTarget == "raid16" then
        TargetColor.texture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
        return
    end
    if healingTarget == "raid17" then
        TargetColor.texture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
        return
    end
    if healingTarget == "raid18" then
        TargetColor.texture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
        return
    end
    if healingTarget == "raid19" then
        TargetColor.texture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
        return
    end
    if healingTarget == "raid20" then
        TargetColor.texture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
        return
    end
    if healingTarget == "raid21" then
        TargetColor.texture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
        return
    end
    if healingTarget == "raid22" then
        TargetColor.texture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
        return
    end
    if healingTarget == "raid23" then
        TargetColor.texture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
        return
    end
    if healingTarget == "raid24" then
        TargetColor.texture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
        return
    end
    if healingTarget == "raid25" then
        TargetColor.texture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
        return
    end
    if healingTarget == "raid26" then
        TargetColor.texture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
        return
    end
    if healingTarget == "raid27" then
        TargetColor.texture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
        return
    end
    if healingTarget == "raid28" then
        TargetColor.texture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
        return
    end
    if healingTarget == "raid29" then
        TargetColor.texture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
        return
    end
    if healingTarget == "raid30" then
        TargetColor.texture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
        return
    end
    if healingTarget == "raid31" then
        TargetColor.texture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
        return
    end
    if healingTarget == "raid32" then
        TargetColor.texture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
        return
    end
    if healingTarget == "raid33" then
        TargetColor.texture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
        return
    end
    if healingTarget == "raid34" then
        TargetColor.texture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
        return
    end    
    if healingTarget == "raid35" then
        TargetColor.texture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
        return
    end
    if healingTarget == "raid36" then
        TargetColor.texture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
        return
    end
    if healingTarget == "raid37" then
        TargetColor.texture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
        return
    end
    if healingTarget == "raid38" then
        TargetColor.texture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
        return
    end
    if healingTarget == "raid39" then
        TargetColor.texture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid40" then
        TargetColor.texture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
        return
    end
    if healingTarget == "raidpet1" then
        TargetColor.texture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet2" then
        TargetColor.texture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
        return
    end
    if healingTarget == "raidpet3" then
        TargetColor.texture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
        return
    end
    if healingTarget == "raidpet4" then
        TargetColor.texture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet5" then
        TargetColor.texture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
        return
    end
    if healingTarget == "raidpet6" then
        TargetColor.texture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet7" then
        TargetColor.texture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
        return
    end
    if healingTarget == "raidpet8" then
        TargetColor.texture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
        return
    end
    if healingTarget == "raidpet9" then
        TargetColor.texture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
        return
    end
    if healingTarget == "raidpet10" then
        TargetColor.texture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
        return
    end
    if healingTarget == "raidpet11" then
        TargetColor.texture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
        return
    end
    if healingTarget == "raidpet12" then
        TargetColor.texture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
        return
    end
    if healingTarget == "raidpet13" then
        TargetColor.texture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
        return
    end
    if healingTarget == "raidpet14" then
        TargetColor.texture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
        return
    end
    if healingTarget == "raidpet15" then
        TargetColor.texture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
        return
    end
    if healingTarget == "raidpet16" then
        TargetColor.texture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
        return
    end
    if healingTarget == "raidpet17" then
        TargetColor.texture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
        return
    end
    if healingTarget == "raidpet18" then
        TargetColor.texture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
        return
    end
    if healingTarget == "raidpet19" then
        TargetColor.texture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
        return
    end
    if healingTarget == "raidpet20" then
        TargetColor.texture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
        return
    end
    if healingTarget == "raidpet21" then
        TargetColor.texture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
        return
    end
    if healingTarget == "raidpet22" then
        TargetColor.texture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
        return
    end
    if healingTarget == "raidpet23" then
        TargetColor.texture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
        return
    end
    if healingTarget == "raidpet24" then
        TargetColor.texture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
        return
    end
    if healingTarget == "raidpet25" then
        TargetColor.texture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
        return
    end
    if healingTarget == "raidpet26" then
        TargetColor.texture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet27" then
        TargetColor.texture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
        return
    end
    if healingTarget == "raidpet28" then
        TargetColor.texture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet29" then
        TargetColor.texture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
        return
    end
    if healingTarget == "raidpet30" then
        TargetColor.texture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
        return
    end
    if healingTarget == "raidpet31" then
        TargetColor.texture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
        return
    end
    if healingTarget == "raidpet32" then
        TargetColor.texture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
        return
    end
    if healingTarget == "raidpet33" then
        TargetColor.texture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
        return
    end
    if healingTarget == "raidpet34" then
        TargetColor.texture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet35" then
        TargetColor.texture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
        return
    end
    if healingTarget == "raidpet36" then
        TargetColor.texture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
        return
    end
    if healingTarget == "raidpet37" then
        TargetColor.texture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
        return
    end
    if healingTarget == "raidpet38" then
        TargetColor.texture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
        return
    end
    if healingTarget == "raidpet39" then
        TargetColor.texture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
        return
    end
    if healingTarget == "raidpet40" then
        TargetColor.texture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
        return
    end
    
    --Stuff
    if healingTarget == "player" then
        TargetColor.texture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
        return
    end
    if healingTarget == "focus" then
        TargetColor.texture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
        return
    end
    --[[
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        TargetColor.texture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
        return
    end   
    if healingTarget == PLACEHOLDER then --was party5
        TargetColor.texture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
        return
    end     
    if healingTarget == PLACEHOLDER then --was party5pet
        TargetColor.texture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
        return
    end
    ]]
end

-- Update LOS status for target 
local function UpdateLOS()
    if UnitExists("target") and (not MouseOver_Toggle or Env.Unit("mouseover"):IsEnemy() or not MouseHasFrame()) then 
        GetLOS(UnitGUID("target"))
    end
end

-- Wipe everything 
local function WipeAll()
    wipe(members)
    wipe(incDMG_members)
    wipe(R_Tanks)
    wipe(R_DPS)
    wipe(R_Heal)
	wipe(Frequency)
	wipe(FrequencyPairs)
end 

local function HealingEngineLaunch()
	if Env.IamHealer then 
		Listener:Add('HealerEngine_Events', "PLAYER_TARGET_CHANGED", UpdateLOS)
		Listener:Add('HealerEngine_Events', 'PLAYER_REGEN_ENABLED', function() wipe(Frequency) end)
		Listener:Add('HealerEngine_Events', 'PLAYER_REGEN_DISABLED', function() wipe(Frequency) end)
	elseif #members > 0 then 
		WipeAll()
		Listener:Remove('HealerEngine_Events', "PLAYER_TARGET_CHANGED")
		Listener:Remove('HealerEngine_Events', 'PLAYER_REGEN_ENABLED')
		Listener:Remove('HealerEngine_Events', 'PLAYER_REGEN_DISABLED')
	end 
end 

Listener:Add('HealingEngine_Events', "PLAYER_ENTERING_WORLD", HealingEngineLaunch)
Listener:Add('HealingEngine_Events', "UPDATE_INSTANCE_INFO", HealingEngineLaunch)
Listener:Add('HealingEngine_Events', "PLAYER_SPECIALIZATION_CHANGED", HealingEngineLaunch)

local function refreshColor()
    HealingEngine() -- Updates Arrays/Table
    setHealingTarget(HE_Toggle) -- Who to heal?
    setColorTarget() -- Show Pixels    
    UpdateLOS() -- Update LOS status for target 
end

local updateHealing = CreateFrame("frame")
updateHealing:SetScript("OnUpdate", function (self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed;    
        if Env.IamHealer and self.elapsed > 0.25 then -- and Env.IsGGLprofile
            refreshColor()
            self.elapsed = 0
        end
end)

-- For refference
function GetMembers()
    return members
end 

-- Other functions to use for spells 
function MostlyIncDMG(unit)
    -- true if current unit is unit, return value of incoming damage
    if tableexist(incDMG_members) and incDMG_members[1] and incDMG_members[1].incDMG then 
        return UnitIsUnit(unit, incDMG_members[1].Unit), incDMG_members[1].incDMG 
    end 
    return false, 0
end 

-- Group 
function Group_incDMG()
    -- return averange raid/party incoming dmg
    local total, tick = 0, 0
    if tableexist(members) then 
        for i = 1, #members do           
            if UnitIsPlayer(members[i].Unit) then
                total = total + members[i].incDMG
                tick = tick + 1
            end
        end
    end
    if total > 0 and tick > 0 then 
        return total / tick
    end 
    return total or 0
end

function Group_getHEAL()
    -- return averange raid/party incoming heal
    local total, tick = 0, 0
    if tableexist(members) then 
        for i = 1, #members do
            if UnitIsPlayer(members[i].Unit) then
                total = total + getHEAL(members[i].Unit)
                tick = tick + 1
            end
        end
    end
    if total > 0 and tick > 0 then 
        return total / tick
    end 
    return total or 0
end

-- Dynamic Reaction on changed AHP by members in persistent lasts TIMER 
function FrequencyAHP(TIMER)    
    local total, counter = 0, 0
    if #Frequency > 1 then 
        for i = 1, #Frequency - 1 do 
            -- Getting history during that time rate
            if TMW.time - Frequency[i].TIME <= TIMER then 
                counter = counter + 1
                total = total + Frequency[i].AHP
            end 
        end 
        if total > 0 then 
            --total = (total / counter * 100 / Frequency[#Frequency].MAXHP) - (Frequency[#Frequency].AHP * 100 / Frequency[#Frequency].MAXHP)
            total = (Frequency[#Frequency].AHP * 100 / Frequency[#Frequency].MAXHP) - (total / counter * 100 / Frequency[#Frequency].MAXHP)
        end         
    end 
    return total 
end 

function ValidMembers(IsPlayer)
    local total = 0 
    if IsPlayer and tableexist(members) then 
        for i = 1, #members do
            if UnitIsPlayer(members[i].Unit) then
                total = total + 1
            end
        end
    else 
        total = #members
    end
    return total 
end

-- Refference for members in range as counter which usefully to check how much units should be done for AoE heal
function AoEMembers(IsPlayer, SubStract, Limit)
    if not SubStract then SubStract = 1 end 
    if not Limit then Limit = 4 end
    local ValidUnits = ValidMembers(IsPlayer)
    return 
    ( ValidUnits <= 1 and 1 ) or    
    ( ValidUnits <= 3 and 2 ) or 
    ( ValidUnits <= 5 and ValidUnits - SubStract ) or 
    ( 
        ValidUnits > 5 and 
        (
            (
                Limit <= ValidUnits and 
                Limit 
            ) or 
            (
                Limit > ValidUnits and 
                ValidUnits
            )
        )
    )
end

--
function AoETTD(seconds)
    local totalMembersDying = 0
    if tableexist(members) then 
        for i = 1, #members do
            if UnitIsPlayer(members[i].Unit) and TimeToDie(members[i].Unit) <= seconds then
                totalMembersDying = totalMembersDying + 1
            end
        end
    end
    return totalMembersDying or 0   
end

function AoEHP(hp)
    local totalhp = 0
    if tableexist(members) then 
        for i = 1, #members do
            if UnitIsPlayer(members[i].Unit) and Env.UNITHP(members[i].Unit) <= hp then
                totalhp = totalhp + 1
            end
        end
    end
    return totalhp or 0   
end

-- Setting Low HP Members variable for AoE Healing By Range
function AoEHealingByRange(range, predictName, isMelee)
    local lowhpmembers = 0
    if tableexist(members) then 
        for i = 1, #members do
            local unit = members[i].Unit
            if (not isMelee or Env.Unit(unit):IsMelee())
            and unit ~= "player"
            and Env.SpellInteract(unit, range) 
            and (not predictName or Env.PredictHeal(predictName, unit)) then
                lowhpmembers = lowhpmembers + 1
            end
        end
    end
    return lowhpmembers or 0
end

-- Setting Low HP Members variable for AoE Healing By Spell
function AoEHealingBySpell(spell, predictName, isMelee) 
    local lowhpmembers = 0
    if tableexist(members) then 
        for i = 1, #members do
            local unit = members[i].Unit
            if (not isMelee or Env.Unit(unit):IsMelee())
            and unit ~= "player"
            and Env.SpellInRange(unit, spell) 
            and (not predictName or Env.PredictHeal(predictName, unit)) then
                lowhpmembers = lowhpmembers + 1
            end
        end
    end
    return lowhpmembers or 0
end

function AoEBuffsExist(id, dur)
    local total = 0
    if not dur then dur = 0 end
    if tableexist(members) then 
        for i = 1, #members do
            if Env.Unit(members[i].Unit):HasBuffs(id, "player") > dur then
                total = total + 1
            end
        end
    end 
    return total 
end

function AoEHPAvg(isPlayer, minCount)
    local total, maxhp, counter = 0, 0, 0
    if tableexist(members) then 
        for i = 1, #members do
            if (not isPlayer or UnitIsPlayer(members[i].Unit)) then                
                total = total + UnitHealth(members[i].Unit)
                maxhp = maxhp + UnitHealthMax(members[i].Unit)
                counter = counter + 1
            end
        end
        if total > 0 and (not minCount or counter >= minCount) then 
            total = total * 100 / maxhp
        end 
    end
    return total  
end

-- Restor Druid 
function Env.AoEFlourish(pHP)    
    if tableexist(members) then 
        local total = 0
        for i = 1, #members do
            if Env.UNITHP(members[i].Unit) <= pHP and
            -- Rejuvenation
            Env.Unit(members[i].Unit):HasBuffs(774) > 0 and 
            (
                -- Wild Growth
                Env.Unit(members[i].Unit):HasBuffs(48438) > 0 or 
                -- Lifebloom or Regrowth or Germination
                Env.Unit(members[i].Unit):HasBuffs({33763, 8936, 155777}) > 0 
            )
            then
                total = total + 1
            end
        end
        return total >= #members * 0.3
    end 
    return false
end

-- PVE Dispels
-- TODO: Remove since we have now Action
local types = {
    Poison = {
        -- Venomfang Strike
        { id = 252687, dur = 0, stack = 0},
        -- Hidden Blade
        { id = 270865, dur = 0, stack = 0},
        -- Embalming Fluid 
        { id = 271563, dur = 0, stack = 3},
        -- Poison Barrage 
        { id = 270507, dur = 0, stack = 0},
        -- Stinging Venom Coating
        { id = 275835, dur = 0, stack = 4},
        -- Neurotoxin 
        { id = 273563, dur = 1.49, stack = 0},
        -- Cytotoxin 
        { id = 267027, dur = 0, stack = 2},
        -- Venomous Spit
        { id = 272699, dur = 0, stack = 0},
        -- Widowmaker Toxin
        { id = 269298, dur = 0, stack = 2}, 
        -- Stinging Venom
        { id = 275836, dur = 0, stack = 5},        
    },
    Disease = {
        -- Infected Wound
        { id = 258323, dur = 0, stack = 1},
        -- Plague Step
        { id = 257775, dur = 0, stack = 0},
        -- Wretched Discharge
        { id = 267763, dur = 0, stack = 0},
        -- Plague 
        { id = 269686, dur = 0, stack = 0},
        -- Festering Bite
        { id = 263074, dur = 0, stack = 0},
        -- Decaying Mind
        { id = 278961, dur = 0, stack = 0},
        -- Decaying Spores
        { id = 259714, dur = 0, stack = 1},
        -- Festering Bite
        { id = 263074, dur = 0, stack = 0},
    }, 
    Curse = {
        -- Wracking Pain
        { id = 250096, dur = 0, stack = 0},
        -- Pit of Despair
        { id = 276031, dur = 0, stack = 0},
        -- Hex 
        { id = 270492, dur = 0, stack = 0},
        -- Cursed Slash
        { id = 257168, dur = 0, stack = 2},
        -- Withering Curse
        { id = 252687, dur = 0, stack = 2},
    },
    Magic = {
        -- Molten Gold
        { id = 255582, dur = 0, stack = 0},
        -- Terrifying Screech
        { id = 255041, dur = 0, stack = 0},
        -- Terrifying Visage
        { id = 255371, dur = 0, stack = 0},
        -- Oiled Blade
        { id = 257908, dur = 0, stack = 0},
        -- Choking Brine
        { id = 264560, dur = 0, stack = 0},
        -- Electrifying Shock
        { id = 268233, dur = 0, stack = 0},
        -- Touch of the Drowned (if no party member is afflicted by Mental Assault (268391))
        { id = 268322, dur = 0, stack = 0},
        -- Mental Assault 
        { id = 268391, dur = 0, stack = 0},
        -- Explosive Void
        { id = 269104, dur = 0, stack = 0},
        -- Choking Waters
        { id = 272571, dur = 0, stack = 0},
        -- Putrid Waters
        { id = 274991, dur = 0, stack = 0},
        -- Flame Shock (if no party member is afflicted by Snake Charm (268008)))
        { id = 268013, dur = 0, stack = 0},
        -- Snake Charm
        { id = 268008, dur = 0, stack = 0},
        -- Brain Freeze
        { id = 280605, dur = 1.49, stack = 0},
        -- Transmute: Enemy to Goo
        { id = 268797, dur = 0, stack = 0},
        -- Chemical Burn
        { id = 259856, dur = 0, stack = 0},
        -- Debilitating Shout
        { id = 258128, dur = 0, stack = 0},
        -- Torch Strike 
        { id = 265889, dur = 0, stack = 1},
        -- Fuselighter 
        { id = 257028, dur = 0, stack = 0},
        -- Death Bolt 
        { id = 272180, dur = 0, stack = 0},
        -- Putrid Blood
        { id = 269301, dur = 0, stack = 2},
        -- Grasping Thorns
        { id = 263891, dur = 0, stack = 0},
        -- Fragment Soul
        { id = 264378, dur = 0, stack = 0},
        -- Reap Soul
        { id = 288388, dur = 0, stack = 20},
        -- Putrid Waters
        { id = 275014, dur = 0, stack = 0},
    }, 
}
local UnitAuras = {
    -- Restor Druid 
    [105] = {
        types.Poison,
        types.Curse,
        types.Magic,
    },
    -- Balance
    [102] = {
        types.Curse,
    },
    -- Feral
    [103] = {
        types.Curse,
    },
    -- Guardian
    [104] = {
        types.Curse,
    },
    -- Arcane
    [62] = {
        types.Curse,
    },
    -- Fire
    [63] = {
        types.Curse,
    },
    -- Frost
    [64] = {
        types.Curse,
    },
    -- Mistweaver
    [270] = {
        types.Poison,
        types.Disease,
        types.Magic,
    },
    -- Windwalker
    [269] = {
        types.Poison,
        types.Disease,
    },
    -- Brewmaster
    [268] = {
        types.Poison,
        types.Disease,
    },
    -- Holy Paladin
    [65] = {
        types.Poison,
        types.Disease,
        types.Magic,
    },
    -- Protection Paladin
    [66] = {
        types.Poison,
        types.Disease,
    },
    -- Retirbution Paladin
    [70] = {
        types.Poison,
        types.Disease,
    },
    -- Discipline Priest 
    [256] = {
        types.Disease,
        types.Magic,
    }, 
    -- Holy Priest 
    [257] = {
        types.Disease,
        types.Magic,
    }, 
    -- Shadow Priest 
    [258] = {
        types.Disease,
    },
    -- Elemental
    [262] = {
        types.Curse,
    },
    -- Enhancement
    [263] = {
        types.Curse,
    },
    -- Restoration
    [264] = {
        types.Curse,
        types.Magic,
    },
    -- Affliction
    [265] = {
        types.Magic,
    },
    -- Demonology
    [266] = {
        types.Magic,
    },
    -- Destruction
    [267] = {
        types.Magic,
    },
}
function Env.PvEDispel(unit)
	if not Env.InPvP() and UnitAuras[Env.PlayerSpec] then 
        for k, v in pairs(UnitAuras[Env.PlayerSpec]) do 
            for _, Spell in pairs(v) do 
                duration = (Spell.dur == 0 and Env.GCD() + Env.CurrentTimeGCD()) or Spell.dur
                -- Exception 
                -- Touch of the Drowned (268322, if no party member is afflicted by Mental Assault (268391))
                -- Flame Shock (268013, if no party member is afflicted by Snake Charm (268008))
                -- Putrid Waters (275014, don't dispel self)
                if Spell.stack == 0 then 
                    if Env.Unit(unit):HasDeBuffs(Spell.id) > duration then 
                        if (Spell.id ~= 268322 or Env.FriendlyTeam():GetDeBuffs(268391) == 0) and 
                        (Spell.id ~= 268013 or Env.FriendlyTeam():GetDeBuffs(268008) == 0) and 
                        (Spell.id ~= 275014 or not UnitIsUnit("player", unit)) then 
                            return true 
                        end
                    end 
                else
                    if Env.Unit(unit):HasDeBuffs(Spell.id) > duration and Env.DeBuffStack(unit, Spell.id, nil, true) > Spell.stack then 
                        if (Spell.id ~= 268322 or Env.FriendlyTeam():GetDeBuffs(268391) == 0) and 
                        (Spell.id ~= 268013 or Env.FriendlyTeam():GetDeBuffs(268008) == 0) and 
                        (Spell.id ~= 275014 or not UnitIsUnit("player", unit)) then 
                            return true 
                        end
                    end 
                end                 
            end 
        end 
    end 
    return false 
end 

