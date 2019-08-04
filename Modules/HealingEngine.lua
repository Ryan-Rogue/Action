local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
local A = Action

-- Toggle valid: "TANK", "DAMAGER", "HEALER", "RAID", nil (means "ALL")
_G.HE_Toggle = nil 
_G.HE_Pets   = true

local type, pairs, wipe, huge = 
	  type, pairs, wipe, math.huge
	  
local UnitGetIncomingHeals, UnitHealth, UnitHealthMax, UnitInRange, UnitGUID, UnitIsCharmed, UnitIsConnected, UnitThreatSituation, UnitIsUnit, UnitExists =
	  UnitGetIncomingHeals, UnitHealth, UnitHealthMax, UnitInRange, UnitGUID, UnitIsCharmed, UnitIsConnected, UnitThreatSituation, UnitIsUnit, UnitExists

A.HealingEngine = {}
A.HealingEngine.Refresh = 10
A.HealingEngine.UpdatePause = 0
A.HealingEngine.Frame = CreateFrame("Frame", "TargetColor", UIParent)
A.HealingEngine.Frame:SetBackdrop(nil)
A.HealingEngine.Frame:SetFrameStrata("TOOLTIP")
A.HealingEngine.Frame:SetToplevel(true)
A.HealingEngine.Frame:SetSize(1, 1)
A.HealingEngine.Frame:SetScale(1)
A.HealingEngine.Frame:SetPoint("TOPLEFT", 442, 0)
A.HealingEngine.Frame.texture = A.HealingEngine.Frame:CreateTexture(nil, "TOOLTIP")
A.HealingEngine.Frame.texture:SetAllPoints(true)
A.HealingEngine.Frame.texture:SetColorTexture(0, 0, 0, 1.0)

A.HealingEngine.Members = {
	ALL = {},
	TANK = {},
	DAMAGER = {},
	HEALER = {},
	RAID = {},
	MOSTLYINCDMG = {},
}

A.HealingEngine.Frequency = {
	Actual = {},
	Temp = {},
}

function A.HealingEngine.Members:Wipe()
	for k, v in pairs(self) do 
		if type(v) == "table" then 
			wipe(self[k])	
		end 
	end 
end 

function A.HealingEngine.Frequency:Wipe()
	for k, v in pairs(self) do 
		if type(v) == "table" then 
			wipe(self[k])	
		end 
	end 
end 
	  
local Aura = {
	SmokeBomb = 76577,
} 	  

local function CalculateHP(unitID)	
    local incomingheals = UnitGetIncomingHeals(unitID) or 0
	local cHealth, mHealth = UnitHealth(unitID), UnitHealthMax(unitID)
	
    local PercentWithIncoming = 100 * (cHealth + incomingheals) / mHealth
    local ActualWithIncoming = mHealth - (cHealth + incomingheals)
	
    return PercentWithIncoming, ActualWithIncoming, cHealth, mHealth
end

local function CanHeal(unitID, unitGUID)
    return 
		UnitInRange(unitID)
		and UnitIsConnected(unitID)
		--and UnitCanCooperate("player", unitID)
		and not UnitIsCharmed(unitID)			
		and not Env.InLOS(unitGUID or UnitGUID(unitID)) -- LOS System (target)
		and not Env.InLOS(unitID)           		 	-- LOS System (another such as party)
		and not Env.UNITDead(unitID)		
		and 
		(
			(
				not Env.InPvP() and 
				not Env.Unit(unitID):IsEnemy()
			) or 
			(
				Env.InPvP() and 
				Env.Unit(unitID):DeBuffCyclone() == 0 and 
				( 
					Env.Unit(unitID):HasDeBuffs(Aura.SmokeBomb) == 0 or 
					Env.Unit("player"):HasDeBuffs(Aura.SmokeBomb) > 0
				)  
			)
		) 
		-- 8.2 Underwater Monstrosity - Darkest Depths (DeBuff)
		-- 2164 is The Eternal Palace  
		and 
		( 
			not Env.InstanceInfo or 
			Env.InstanceInfo.instanceID ~= 2164 or 
			Env.Unit(unitID):HasDeBuffs(292127) == 0
		)
end

local healingTarget, healingTargetGUID = "None", "None"
local function HealingEngine(MODE, useActualHP)   
	local mode = MODE or "ALL"
    local ActualHP = useActualHP or false
	A.HealingEngine.Members:Wipe()
	
    if Env.PvPCache["Group_FriendlyType"] ~= "raid" then 
		local pHP, aHP, _, mHP = CalculateHP("player")
        table.insert(A.HealingEngine.Members.ALL, { Unit = "player", GUID = UnitGUID("player"), HP = pHP, AHP = aHP, isPlayer = true, incDMG = getRealTimeDMG("player") })
    end 
    
    local isQueuedDispel = false 
    local group = Env.PvPCache["Group_FriendlyType"]
    for i = 1, Env.PvPCache["Group_FriendlySize"] do
        local member = group .. i        
        local memberhp, memberahp, _, membermhp = CalculateHP(member)
        local memberGUID = UnitGUID(member)

        -- Note: We can't use CanHeal here because it will take not all units results could be wrong
		A.HealingEngine.Frequency.Temp.MAXHP = (A.HealingEngine.Frequency.Temp.MAXHP or 0) + membermhp 
        A.HealingEngine.Frequency.Temp.AHP 	 = (A.HealingEngine.Frequency.Temp.AHP   or 0) + memberahp
        
        -- Party/Raid
        if CanHeal(member, memberGUID) then
            local DMG = getRealTimeDMG(member) 
            local Actual_DMG = DMG
            
            -- Stop decrease predict HP if offset for DMG more than 15% of member's HP
            local DMG_offset = membermhp * 0.15
            if DMG > DMG_offset then 
                DMG = DMG_offset
            end
            
            -- Checking if Member has threat
			local threat = UnitThreatSituation(member)
            if threat == 3 then
                memberhp = memberhp - threat
            end            
            
			-- Enable specific instructions by profile 
			if A.IsGGLprofile then 
				-- Holy Paladin 
				if Env.UNITSpec("player", 65) then                 
					if (not isQueuedDispel or Env.Unit(member, A.HealingEngine.Refresh):IsHealer()) and Env.SpellUsable(4987) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						-- if we will have lower unit than 50% then don't dispel it
						memberhp = 50
						if Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then 
							memberhp = 25
						end
					elseif AzeriteRank(287268) > 0 and Env.SpellCD(20473) <= Env.CurrentTimeGCD() and Env.Unit(member, 0.5):HasBuffs(287280, "player") <= Env.GCD() then 
						-- Glimmer of Light 
						-- Generally, prioritize players that might die in the next few seconds > non-Beaconed tank (without Glimmer buff) > Beaconed tank (without Glimmer buff) > players without the Glimmer buff
						if Env.PredictHeal("HolyShock", member) then 
							if Env.Unit(member, A.HealingEngine.Refresh):IsTank() then 
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
							memberhp = memberhp + ( 100 * (Env.GetDescription(223306)[1]) / membermhp )
						end 
						-- Checking if Member has Beacons on them            
						if Env.Unit(member):HasBuffs({53563, 156910}, "player") > 0 then
							memberhp = memberhp + ( 100 * (getHPS("player") * 0.4) / membermhp ) - ( 100 * DMG / membermhp )
						end  
					end 
				end 
				
				-- Restor Druid 
				if Env.UNITSpec("player", 105) then 					
					if (not isQueuedDispel or Env.Unit(member, A.HealingEngine.Refresh):IsHealer()) and Env.SpellUsable(88423) and not UnitIsUnit("player", member) and Env.Dispel(member) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then 
							memberhp = 25
						end						
					elseif memberhp < 100 then   
						-- HOT SYSTEM: current ticking and total duration
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
							if healingTarget and healingTarget ~= "None" and Env.Unit(healingTarget, A.HealingEngine.Refresh):IsTank() then 
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
							-- current HP % with pre casting heal + predict hot heal - predict incoming dmg 
							memberhpHotSystem = memberhp + ( 100 * summup / membermhp ) - ( 100 * (DMG * summdmg[1]) / membermhp )
							if memberhpHotSystem < 100 then
								memberhp = memberhpHotSystem
							end
						end                    
					end
				end
				
				-- Discipline Priest
				if Env.UNITSpec("player", 256) then                 
					if (not isQueuedDispel or Env.Unit(member, A.HealingEngine.Refresh):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then 
							memberhp = 25
						end 
					elseif AtonementRenew_Toggle and Env.Unit(member):HasBuffs(81749, "player") <= Env.CurrentTimeGCD() then 				
						-- Toggle "Group Atonement/Renew﻿"
						memberhp = 50
					elseif memberhp < 100 then                    
						-- Atonement priority 
						if Env.Unit(member):HasBuffs(81749, "player") > 0 and Env.oPR and Env.oPR["AtonementHPS"] then 
							memberhp = memberhp + ( 100 * Env.oPR["AtonementHPS"] / membermhp )
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
							memberhp = memberhp + ( 100 * getAbsorb(member, 17) / membermhp )
						end 
					end 
				end 
				
				-- Holy Priest
				if Env.UNITSpec("player", 257) then                 
					if (not isQueuedDispel or Env.Unit(member, A.HealingEngine.Refresh):IsHealer()) and not UnitIsUnit("player", member) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- if we will have lower unit than 50% then don't dispel it
						if Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then 
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
								memberhp = memberhp + ( 100 * (Env.GetDescription(2061)[1] * 0.35) / membermhp )
							elseif ST == 2060 then 
								memberhp = memberhp + ( 100 * (Env.GetDescription(2060)[1] * 0.35) / membermhp )
							end 
						end 
					end 
				end 
			   
				-- Mistweaver Monk 
				if A.IsInitialized and ACTION_CONST_MONK_MW and Env.UNITSpec("player", ACTION_CONST_MONK_MW) then 
					if (not isQueuedDispel or Env.Unit(member, A.HealingEngine.Refresh):IsHealer()) and not UnitIsUnit("player", member) and A.AuraIsValid(member, "UseDispel", "Dispel") then 
						-- DISPEL PRIORITY
						isQueuedDispel = true 
						memberhp = 50 
						-- If we will have lower unit than 50% then don't dispel it
						if Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then 
							memberhp = 25
						end 
					elseif memberhp < 100 and A.GetToggle(2, "HealingEngineAutoHot") and A[ACTION_CONST_MONK_MW].RenewingMist:IsReady() then 
						-- Keep Renewing Mist hots as much as it possible on cooldown
						local RenewingMist = Env.Unit(member):HasBuffs(A[ACTION_CONST_MONK_MW].RenewingMist.ID, true)
						if RenewingMist == 0 and Env.PredictHeal("RenewingMist", A[ACTION_CONST_MONK_MW].RenewingMist.ID, member) then 
							memberhp = memberhp - 40
							if memberhp < 55 then 
								memberhp = 55 
							end 
						end 
					end 
				end 
			end 
			
            -- Misc: Sort by Roles 			
            if Env.Unit(member, A.HealingEngine.Refresh):IsTank() then
                memberhp = memberhp - 2
				
				if mode == "TANK" then 
					table.insert(A.HealingEngine.Members.TANK, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })      
				end 
            elseif Env.Unit(member, A.HealingEngine.Refresh):IsHealer() then                
                if UnitIsUnit("player", member) and memberhp < 95 then 
					if Env.InPvP() and Env.Unit("player"):IsFocused(nil, true) then 
						memberhp = memberhp - 20
					else 
						memberhp = memberhp - 2
					end 
                else 
                    memberhp = memberhp + 2
                end
				
				if mode == "HEALER" then 
					table.insert(A.HealingEngine.Members.HEALER, 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				elseif mode == "RAID" then 	
					table.insert(A.HealingEngine.Members.RAID, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				end 				 
			else 
				memberhp = memberhp - 1
				
				if mode == "DAMAGER" then 
					table.insert(A.HealingEngine.Members.DAMAGER, 	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				elseif mode == "RAID" then  
					table.insert(A.HealingEngine.Members.RAID, 		{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
				end			 
            end

            table.insert(A.HealingEngine.Members.ALL, 				{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG })  
        end        
        
        -- Pets 
        if _G.HE_Pets then
            local memberpet = group .. "pet" .. i
			local memberpetGUID = UnitGUID(memberpet)
			local memberpethp, memberpetahp, _, memberpetmhp = CalculateHP(memberpet) 
			
			-- Note: We can't use CanHeal here because it will take not all units results could be wrong
			A.HealingEngine.Frequency.Temp.MAXHP = (A.HealingEngine.Frequency.Temp.MAXHP or 0) + memberpetmhp 
			A.HealingEngine.Frequency.Temp.AHP 	 = (A.HealingEngine.Frequency.Temp.AHP   or 0) + memberpetahp			
			
			if CanHeal(memberpet, memberpetGUID) then 
				if CombatTime("player") > 0 then                
					memberpethp  = memberpethp * 1.35
					memberpetahp = memberpetahp * 1.35
				else                
					memberpethp  = memberpethp * 1.15
					memberpetahp = memberpetahp * 1.15
				end
				
				table.insert(A.HealingEngine.Members.ALL, 			{ Unit = memberpet, GUID = memberpetGUID, HP = memberpethp, AHP = memberpetahp, isPlayer = false, incDMG = getRealTimeDMG(memberpet) }) 
			end 
        end
    end
    
    -- Frequency (Summary)
    if A.HealingEngine.Frequency.Temp.MAXHP and A.HealingEngine.Frequency.Temp.MAXHP > 0 then 
        table.insert(A.HealingEngine.Frequency.Actual, { 	                
                -- Max Group HP
                MAXHP	= A.HealingEngine.Frequency.Temp.MAXHP, 
                -- Current Group Actual HP
                AHP 	= A.HealingEngine.Frequency.Temp.AHP,
				-- Current Time on this record 
				TIME 	= TMW.time, 
        })
		
		-- Clear temp by old record
        wipe(A.HealingEngine.Frequency.Temp)
		
		-- Clear actual from older records
        for i = #A.HealingEngine.Frequency.Actual, 1, -1 do             
            -- Remove data longer than 5 seconds 
            if TMW.time - A.HealingEngine.Frequency.Actual[i].TIME > 10 then 
                table.remove(A.HealingEngine.Frequency.Actual, i)                
            end 
        end 
    end 
    
	-- Sort for next target / incDMG (Summary)
    if #A.HealingEngine.Members.ALL > 1 then 
        -- Sort by most damage receive
		for i = 1, #A.HealingEngine.Members.ALL do 
			local t = A.HealingEngine.Members.ALL[i]
			table.insert(A.HealingEngine.Members.MOSTLYINCDMG, 		{ Unit = t.Unit, GUID = t.GUID, incDMG = t.incDMG })
		end 
        table.sort(A.HealingEngine.Members.MOSTLYINCDMG, function(x, y)
                return x.incDMG > y.incDMG
        end)  
        
        -- Sort by Percent or Actual
        if not ActualHP then
			for k, v in pairs(A.HealingEngine.Members) do 
				if type(v) == "table" and #v > 1 and v[1].HP then 
					table.sort(v, function(x, y) return x.HP < y.HP end)
				end 
			end 		
        elseif ActualHP then
			for k, v in pairs(A.HealingEngine.Members) do 
				if type(v) == "table" and #v > 1 and v[1].AHP then 
					table.sort(v, function(x, y) return x.AHP > y.AHP end)
				end 
			end 		
        end
    end 
end

local function setHealingTarget(MODE, HP)
    local mode = MODE or "ALL"
    local hp = HP or 99
	
	if #A.HealingEngine.Members[mode] > 0 and A.HealingEngine.Members[mode][1].HP < hp then 
		healingTarget 		= A.HealingEngine.Members[mode][1].Unit
		healingTargetGUID 	= A.HealingEngine.Members[mode][1].GUID
		return 
	end 	 

    healingTarget 	  = "None"
    healingTargetGUID = "None"
end

local function setColorTarget(isForced)
    --Default 
    A.HealingEngine.Frame.texture:SetColorTexture(0, 0, 0, 1.0)   
	
	if not isForced then 
		--If we have no one to heal
		if healingTarget == nil or healingTarget == "None" or healingTargetGUID == nil or healingTargetGUID == "None" then
			return
		end	
		
		--If we have a mouseover friendly unit
		if (A.IsInitialized and A.IsUnitFriendly("mouseover")) or (not A.IsInitialized and MouseOver_Toggle and MouseHasFrame()) then       
			return
		end
		
		--If we have a current target equiled to suggested or he is a boss
		if UnitExists("target") and (healingTargetGUID == UnitGUID("target") or Env.Unit("target", A.HealingEngine.Refresh):IsBoss()) then
			return
		end     
		
		--If we have enemy as primary unit 
		--TODO: Remove for old profiles until June 2019
		if not A.IsInitialized and ((MouseOver_Toggle and Env.Unit("mouseover"):IsEnemy()) or Env.Unit("target"):IsEnemy()) then 
			-- Old profiles 
			return 
		end 
		
		if A.IsInitialized and (A.IsUnitEnemy("mouseover") or A.IsUnitEnemy("target")) then 
			-- New profiles 
			return 
		end 
		
		--Mistweaver Monk
		if A.IsInitialized and ACTION_CONST_MONK_MW and Env.UNITSpec("player", ACTION_CONST_MONK_MW) and A.GetToggle(2, "HealingEnginePreventSuggest") then 
			local unit = "target"
			if A.IsUnitFriendly("mouseover") then 
				unit = "mouseover"
			end 
			if Env.Unit(unit):HasBuffs(A[ACTION_CONST_MONK_MW].SoothingMist.ID, true) > 3 and Env.UNITHP(unit) <= A.GetToggle(2, "SoothingMistHP") then 
				return 
			end 
		end 
    end 
	
    --Party
    if healingTarget == "party1" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.345098, 0.239216, 0.741176, 1.0)
        return
    end
    if healingTarget == "party2" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.407843, 0.501961, 0.086275, 1.0)
        return
    end
    if healingTarget == "party3" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.160784, 0.470588, 0.164706, 1.0)
        return
    end
    if healingTarget == "party4" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.725490, 0.572549, 0.647059, 1.0)
        return
    end   
    
    --PartyPET
    if healingTarget == "partypet1" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
        return
    end
    if healingTarget == "partypet2" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
        return
    end
    if healingTarget == "partypet3" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
        return
    end
    if healingTarget == "partypet4" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
        return
    end        
    
    --Raid
    if healingTarget == "raid1" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
        return
    end
    if healingTarget == "raid2" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
        return
    end
    if healingTarget == "raid3" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
        return
    end
    if healingTarget == "raid4" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
        return
    end
    if healingTarget == "raid5" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
        return
    end
    if healingTarget == "raid6" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid7" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
        return
    end
    if healingTarget == "raid8" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid9" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid10" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
        return
    end
    if healingTarget == "raid11" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
        return
    end
    if healingTarget == "raid12" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid13" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
        return
    end
    if healingTarget == "raid14" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid15" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
        return
    end
    if healingTarget == "raid16" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
        return
    end
    if healingTarget == "raid17" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
        return
    end
    if healingTarget == "raid18" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
        return
    end
    if healingTarget == "raid19" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
        return
    end
    if healingTarget == "raid20" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
        return
    end
    if healingTarget == "raid21" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
        return
    end
    if healingTarget == "raid22" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
        return
    end
    if healingTarget == "raid23" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
        return
    end
    if healingTarget == "raid24" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
        return
    end
    if healingTarget == "raid25" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
        return
    end
    if healingTarget == "raid26" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
        return
    end
    if healingTarget == "raid27" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
        return
    end
    if healingTarget == "raid28" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
        return
    end
    if healingTarget == "raid29" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
        return
    end
    if healingTarget == "raid30" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
        return
    end
    if healingTarget == "raid31" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
        return
    end
    if healingTarget == "raid32" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
        return
    end
    if healingTarget == "raid33" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
        return
    end
    if healingTarget == "raid34" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
        return
    end    
    if healingTarget == "raid35" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
        return
    end
    if healingTarget == "raid36" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
        return
    end
    if healingTarget == "raid37" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
        return
    end
    if healingTarget == "raid38" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
        return
    end
    if healingTarget == "raid39" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid40" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
        return
    end
    if healingTarget == "raidpet1" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet2" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
        return
    end
    if healingTarget == "raidpet3" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
        return
    end
    if healingTarget == "raidpet4" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet5" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
        return
    end
    if healingTarget == "raidpet6" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet7" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
        return
    end
    if healingTarget == "raidpet8" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
        return
    end
    if healingTarget == "raidpet9" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
        return
    end
    if healingTarget == "raidpet10" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
        return
    end
    if healingTarget == "raidpet11" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
        return
    end
    if healingTarget == "raidpet12" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
        return
    end
    if healingTarget == "raidpet13" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
        return
    end
    if healingTarget == "raidpet14" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
        return
    end
    if healingTarget == "raidpet15" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
        return
    end
    if healingTarget == "raidpet16" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
        return
    end
    if healingTarget == "raidpet17" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
        return
    end
    if healingTarget == "raidpet18" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
        return
    end
    if healingTarget == "raidpet19" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
        return
    end
    if healingTarget == "raidpet20" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
        return
    end
    if healingTarget == "raidpet21" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
        return
    end
    if healingTarget == "raidpet22" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
        return
    end
    if healingTarget == "raidpet23" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
        return
    end
    if healingTarget == "raidpet24" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
        return
    end
    if healingTarget == "raidpet25" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
        return
    end
    if healingTarget == "raidpet26" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet27" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
        return
    end
    if healingTarget == "raidpet28" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet29" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
        return
    end
    if healingTarget == "raidpet30" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
        return
    end
    if healingTarget == "raidpet31" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
        return
    end
    if healingTarget == "raidpet32" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
        return
    end
    if healingTarget == "raidpet33" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
        return
    end
    if healingTarget == "raidpet34" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet35" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
        return
    end
    if healingTarget == "raidpet36" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
        return
    end
    if healingTarget == "raidpet37" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
        return
    end
    if healingTarget == "raidpet38" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
        return
    end
    if healingTarget == "raidpet39" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
        return
    end
    if healingTarget == "raidpet40" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
        return
    end
    
    --Stuff
    if healingTarget == "player" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
        return
    end
    if healingTarget == "focus" then
        A.HealingEngine.Frame.texture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
        return
    end
    --[[
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        A.HealingEngine.Frame.texture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
        return
    end   
    if healingTarget == PLACEHOLDER then --was party5
        A.HealingEngine.Frame.texture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
        return
    end     
    if healingTarget == PLACEHOLDER then --was party5pet
        A.HealingEngine.Frame.texture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
        return
    end
    ]]
end

local function UpdateLOS()
	if UnitExists("target") then
		if A.IsInitialized then
			-- New profiles 
			if not A.IsUnitFriendly("mouseover") then 
				GetLOS(UnitGUID("target"))
			end 		
		elseif Env.IsGGLprofile and (not MouseOver_Toggle or Env.Unit("mouseover"):IsEnemy() or not MouseHasFrame()) then 
			-- TODO: Remove on old profiles until June 2019
			-- Old profiles 
			GetLOS(UnitGUID("target"))
		end 
	end 
end

local function HealingEngineInit()
	if Env.IamHealer then 
		Listener:Add("HealerEngine_Events", "PLAYER_TARGET_CHANGED", 	UpdateLOS)
		Listener:Add("HealerEngine_Events", "PLAYER_REGEN_ENABLED", 	function() wipe(A.HealingEngine.Frequency.Actual) end)
		Listener:Add("HealerEngine_Events", "PLAYER_REGEN_DISABLED", 	function() wipe(A.HealingEngine.Frequency.Actual) end)
		A.HealingEngine.Frame:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed   
			local INTV = (TMW.UPD_INTV > 0.25 and TMW.UPD_INTV or 0.25) + A.HealingEngine.UpdatePause
			if Env.IamHealer and self.elapsed > INTV then 
				HealingEngine(_G.HE_Toggle) 
				setHealingTarget(_G.HE_Toggle) 
				setColorTarget()   
				UpdateLOS() 
				self.elapsed = 0
			end			
		end)
	elseif #A.HealingEngine.Members.ALL > 0 then
		A.HealingEngine.Members:Wipe()
		A.HealingEngine.Frequency:Wipe()
		Listener:Remove("HealerEngine_Events", "PLAYER_TARGET_CHANGED")
		Listener:Remove("HealerEngine_Events", "PLAYER_REGEN_ENABLED")
		Listener:Remove("HealerEngine_Events", "PLAYER_REGEN_DISABLED")
		A.HealingEngine.Frame:SetScript("OnUpdate", nil)
	end 
end 

Listener:Add("HealingEngine_Events", "PLAYER_ENTERING_WORLD", 			HealingEngineInit)
Listener:Add("HealingEngine_Events", "UPDATE_INSTANCE_INFO", 			HealingEngineInit)
Listener:Add("HealingEngine_Events", "PLAYER_SPECIALIZATION_CHANGED", 	HealingEngineInit)

--- ============================= API ==============================
--- API valid only for healer specializations  
--- Members are depend on _G.HE_Pets variable 

--- SetTarget Controller 
function A.HealingEngine.SetTargetMostlyIncDMG()
	local GUID = UnitGUID("target")
	if GUID and GUID ~= healingTargetGUID and #A.HealingEngine.Members.MOSTLYINCDMG > 0 then 
		healingTargetGUID 	= A.HealingEngine.Members.MOSTLYINCDMG[1].GUID
		healingTarget		= A.HealingEngine.Members.MOSTLYINCDMG[1].Unit
		setColorTarget(true)
		A.HealingEngine.UpdatePause = 2
	end 
end 

function A.HealingEngine.SetTarget(unitID)
	local GUID = UnitGUID(unitID)
	if GUID and GUID ~= healingTargetGUID and #A.HealingEngine.Members.ALL > 0 then 
		healingTargetGUID 	= GUID
		healingTarget		= unitID
		setColorTarget(true)
		A.HealingEngine.UpdatePause = 2
	end 
end 

--- Group Controller 
function A.HealingEngine.GetMembersAll()
	-- @return table 
	return A.HealingEngine.Members.ALL 
end 

function A.HealingEngine.GetMembersByMode()
	-- @return table 
	local mode = _G.HE_Toggle or "ALL"
	return A.HealingEngine.Members[mode] 
end 

function A.HealingEngine.GetBuffsCount(ID, duration, source)
	-- @return number 	
	-- Only players 
    local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if m[i].isPlayer and Env.Unit(m[i].Unit):HasBuffs(ID, source) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 
A.HealingEngine.GetBuffsCount = A.MakeFunctionCachedDynamic(A.HealingEngine.GetBuffsCount)

function A.HealingEngine.GetDeBuffsCount(ID, duration)
	-- @return number 	
	-- Only players 
    local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if m[i].isPlayer and Env.Unit(m[i].Unit):HasDeBuffs(ID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 
A.HealingEngine.GetDeBuffsCount = A.MakeFunctionCachedDynamic(A.HealingEngine.GetDeBuffsCount)

function A.HealingEngine.GetHealth()
	-- @return number 
	-- Return actual group health 
	local f = A.HealingEngine.Frequency.Actual 
	if #f > 0 then 
		return f[#f].AHP
	end 
	return huge
end 

function A.HealingEngine.GetHealthAVG() 
	-- @return number 
	-- Return current percent (%) of the group health
	local f = A.HealingEngine.Frequency.Actual
	if #f > 0 then 
		return f[#f].AHP * 100 / f[#f].MAXHP
	end 
	return 100  
end 
A.HealingEngine.GetHealthAVG = A.MakeFunctionCachedStatic(A.HealingEngine.GetHealthAVG)

function A.HealingEngine.GetHealthFrequency(timer)
	-- @return number 
	-- Return percent (%) of the group HP changed during lasts 'timer'. Positive (+) is HP lost, Negative (-) is HP gain, 0 - nothing is not changed 
    local total, counter = 0, 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 1 then 
        for i = 1, #f - 1 do 
            -- Getting history during that time rate
            if TMW.time - f[i].TIME <= timer then 
                counter = counter + 1
                total 	= total + f[i].AHP
            end 
        end        
    end 
	
	if total > 0 then           
		total = (f[#f].AHP * 100 / f[#f].MAXHP) - (total / counter * 100 / f[#f].MAXHP)
	end  	
	
    return total 
end 
A.HealingEngine.GetHealthFrequency = A.MakeFunctionCachedDynamic(A.HealingEngine.GetHealthFrequency)

function A.HealingEngine.GetIncomingDMG()
	-- @return number, number 
	-- Return REALTIME actual: total - group HP lose per second, avg - average unit HP lose per second
	local total, avg = 0, 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            total = total + m[i].incDMG
        end
		
		avg = total / #m
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingDMG = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingDMG)

function A.HealingEngine.GetIncomingHPS()
	-- @return number , number
	-- Return PERSISTENT actual: total - group HP gain per second, avg - average unit HP gain per second 
	local total, avg = 0, 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            total = total + getHEAL(m[i].Unit)
        end
		
		avg = total / #m
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingHPS = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingHPS)

function A.HealingEngine.GetIncomingDMGAVG()
	-- @return number  
	-- Return REALTIME average percent group HP lose per second 
	local avg = 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 0 then 
		avg = A.HealingEngine.GetIncomingDMG() * 100 / f[#f].MAXHP
    end 
    return avg 
end
A.HealingEngine.GetIncomingDMGAVG = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingDMGAVG)

function A.HealingEngine.GetIncomingHPSAVG()
	-- @return number  
	-- Return REALTIME average percent group HP gain per second 
	local avg = 0
	local f = A.HealingEngine.Frequency.Actual
    if #f > 0 then 
		avg = A.HealingEngine.GetIncomingHPS() * 100 / f[#f].MAXHP
    end 
    return avg 
end 
A.HealingEngine.GetIncomingHPSAVG = A.MakeFunctionCachedStatic(A.HealingEngine.GetIncomingHPSAVG)

function A.HealingEngine.GetTimeToDieUnits(timer)
	-- @return number 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if TimeToDie(m[i].Unit) <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToDieMagicUnits(timer)
	-- @return number 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if TimeToDieMagic(m[i].Unit) <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToFullHealth()
	-- @return number
	local f = A.HealingEngine.Frequency.Actual
	if #f > 0 then 
		local HPS = A.HealingEngine.GetIncomingHPS()
		if HPS > 0 then
			return (f[#f].MAXHP - f[#f].AHP) / HPS
		end 
	end 
	return 0 
end 

function A.HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit)
	-- @return number 
	-- This is easy template to known how many people minimum required be to heal by AoE with different group size or if some units out of range or in cyclone and etc..
	-- More easy to figure - which minimum units require if available group members <= 1 / <= 3 / <= 5 or > 5
	local m = A.HealingEngine.GetMembersAll()
	local members = #m
	return 	( members <= 1 and 1 ) or 
			( members <= 3 and members ) or 
			( members <= 5 and members - (fullPartyMinus or 0) ) or 
			(
				members > 5 and 
				(
					(
						raidLimit ~= nil and
						(
							(
								members >= raidLimit and 
								raidLimit
							) or 
							(
								members < raidLimit and 
								members
							)
						)
					) or 
					(
						raidLimit == nil and 
						members
					)
				)
			)
end 

function A.HealingEngine.GetBelowHealthPercentUnits(pHP, range)
	local total = 0 
	local m = A.HealingEngine.GetMembersAll()
    if #m > 0 then 
        for i = 1, #m do
            if (not range or Env.SpellInteract(m[i].Unit, range)) and m[i].HP <= pHP then
                total = total + 1
            end
        end
    end 
	return total 
end 

function A.HealingEngine.HealingByRange(range, predictName, spellID, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified range with spell
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
	if #m > 0 then 		
		for i = 1, #m do 
			if 	(not isMelee or Env.Unit(m[i].Unit, A.HealingEngine.Refresh):IsMelee()) and 
				Env.SpellInteract(m[i].Unit, range) and
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, m[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and Env.PredictHeal(predictName, spellID, m[i].Unit))
				)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

function A.HealingEngine.HealingBySpell(predictName, spellID, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified spell 
	local total = 0
	local m = A.HealingEngine.GetMembersAll()
	if #m > 0 then 		
		for i = 1, #m do 
			if 	(not isMelee or Env.Unit(m[i].Unit, A.HealingEngine.Refresh):IsMelee()) and 
				Env.SpellInRange(m[i].Unit, spellID) and
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, m[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and Env.PredictHeal(predictName, spellID, m[i].Unit))
				)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

--- Unit Controller 
function A.HealingEngine.IsMostlyIncDMG(unitID)
	-- @return boolean, number (realtime incoming damage)	
	if #A.HealingEngine.Members.MOSTLYINCDMG > 0 then 
		return UnitIsUnit(unitID, A.HealingEngine.Members.MOSTLYINCDMG[1].Unit), A.HealingEngine.Members.MOSTLYINCDMG[1].incDMG
	end 
	return false, 0
end 

function A.HealingEngine.GetTarget()
	return healingTarget, healingTargetGUID
end 

--- =========================== OLD API ============================
-- TODO: Remove since we have now Action
local tableexist = tableexist
local UnitIsPlayer = UnitIsPlayer
function GetMembers()
    return A.HealingEngine.GetMembersAll()
end 
function MostlyIncDMG(unitID)
    return A.HealingEngine.IsMostlyIncDMG(unitID)
end 
function Group_incDMG()
    return select(2, A.HealingEngine.GetIncomingDMG())
end
function Group_getHEAL()
    return select(2, A.HealingEngine.GetIncomingHPS())
end
function FrequencyAHP(timer)    
    return A.HealingEngine.GetHealthFrequency(timer)
end 
function AoETTD(timer)
    return A.HealingEngine.GetTimeToDieUnits(timer)   
end
function AoEBuffsExist(ID, duration)
	return A.HealingEngine.GetBuffsCount(ID, duration)
end
function AoEHP(pHP)
    return A.HealingEngine.GetBelowHealthPercentUnits(pHP) 
end
function AoEHealingByRange(range, predictName, isMelee)
	return A.HealingEngine.HealingByRange(range, predictName, nil, isMelee)
end
function AoEHealingBySpell(spell, predictName, isMelee) 
	return A.HealingEngine.HealingBySpell(predictName, spell, isMelee)
end
-- Deprecated
function ValidMembers(IsPlayer)
	if not IsPlayer or not _G.HE_Pets then 
		return #A.HealingEngine.Members.ALL
	else 
		local total = 0 
		local f = A.HealingEngine.GetMembersAll()
		if #f > 0 then 
			for i = 1, #f do
				if UnitIsPlayer(f[i].Unit) then
					total = total + 1
				end
			end 
		end 
		return total 
	end 
end
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
function AoEHPAvg(isPlayer, minCount)
    local total, maxhp, counter = 0, 0, 0
	local members = A.HealingEngine.GetMembersAll()
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
	local members = A.HealingEngine.GetMembersAll()
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
		-- Blazing Chomp
		{ id = 294929, dur = 0, stack = 0 },
		-- 8.2 Queen Azshara - Arcane Burst
		{ id = 303657, dur = 10, stack = 0 },
		-- 8.2 Za'qul - Dread
		{ id = 292963, dur = 0, stack = 0 },
		-- 8.2 Za'qul - Shattered Psyche
		{ id = 295327, dur = 0, stack = 0 },
		-- 8.2 Radiance of Azshara - Arcane Bomb
		-- { id = 296746, dur = 0, stack = 0 }, -- need predict unit position to dispel only when they are out of raid 
		-- The Restless Cabal - Promises of Power 
		{ id = 282562, dur = 0, stack = 3 },
		-- Jadefire Masters - Searing Embers
		{ id = 286988, dur = 0, stack = 0 },
		-- Conclave of the Chosen - Mind Wipe
		{ id = 285878, dur = 0, stack = 0 },
		-- Lady Jaina - Grasp of Frost
		{ id = 287626, dur = 0, stack = 0 },
		-- Lady Jaina - Hand of Frost
		{ id = 288412, dur = 0, stack = 0 },
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

