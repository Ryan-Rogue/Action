local TMW 								= TMW
local CNDT 								= TMW.CNDT
local Env 								= CNDT.Env

local A 								= Action
local Listener							= A.Listener
local MakeFunctionCachedDynamic			= A.MakeFunctionCachedDynamic
local MakeFunctionCachedStatic			= A.MakeFunctionCachedStatic
local TeamCacheFriendly					= A.TeamCache.Friendly
local TeamCacheFriendlyUNITs			= TeamCacheFriendly.UNITs
local TeamCacheFriendlyGUIDs			= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs	= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs		= TeamCacheFriendly.IndexToPETs
local GetToggle							= A.GetToggle
local AuraIsValid						= A.AuraIsValid
local GetLOS							= GetLOS -- it's correct

local player 							= "player"

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_IsUnitFriendly, A_IsUnitEnemy
local A_GetCurrentGCD, A_GetGCD, A_GetSpellDescription

Listener:Add("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit 							= A.Unit 
		A_IsUnitFriendly 				= A.IsUnitFriendly
		A_IsUnitEnemy					= A.IsUnitEnemy
		
		-- Retail only 
		A_GetCurrentGCD					= A.GetCurrentGCD
		A_GetGCD						= A.GetGCD
		A_GetSpellDescription			= A.GetSpellDescription		
		-- 

		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

local _G, type, pairs, table, math		= 
	  _G, type, pairs, table, math
	  
--local tinsert 						= table.insert	-- Short inline expressions can be faster than function calls. t[#t+1] = 0 is faster than table.insert(t, 0)
local tremove							= table.remove 
local tsort								= table.sort 
local huge 								= math.huge
local wipe 								= _G.wipe

local  CreateFrame,    UIParent			= 
	_G.CreateFrame, _G.UIParent	  
	  
local UnitGUID, UnitIsUnit 				= 
	  UnitGUID, UnitIsUnit

local Frame 							= CreateFrame("Frame", "TargetColor", UIParent)
Frame:SetBackdrop(nil)
Frame:SetFrameStrata("TOOLTIP")
Frame:SetToplevel(true)
Frame:SetSize(1, 1)
Frame:SetScale(1)
Frame:SetPoint("TOPLEFT", 442, 0)
Frame.texture = Frame:CreateTexture(nil, "TOOLTIP")
Frame.texture:SetAllPoints(true)
Frame.texture:SetColorTexture(0, 0, 0, 1.0)
local Frametexture 						= Frame.texture
local None, healingTarget, healingTargetGUID, healingTargetDelay = "None", "None", "None", 0

local function sort_high(x, y)
	return x > y
end

local function sort_incDMG(x, y)
	return x.incDMG > y.incDMG
end

local function sort_HP(x, y) 
	return x.HP < y.HP 
end

local function sort_AHP(x, y) 
	return x.AHP > y.AHP 
end

-- [[ Retail ]]	
local Azerite 							= LibStub("AzeriteTraits")

-- [[ Retail Monk Locals ]]
local MK

-- [[ Retail - Old profiles but it's synchronized with actual API so don't remove ]]
-- Toggle valid: "TANK", "DAMAGER", "HEALER", "RAID", nil (means "ALL")
_G.HE_Toggle 							= nil 
_G.HE_Pets   							= true

local Aura = {
	SmokeBomb = 76577,
} 	

local Temp = {	-- TODO: Remove this table coz of old profiles 
	Beacons = {156910, 53563},
	SumDMG	= {},
}  

-- [[ Core ]]
local HealingEngine 					= {
	IsRunning							= false,
	QueueOrder							= {},
	Members  							= {
		ALL 							= {},
		TANK 							= {},
		DAMAGER 						= {},
		HEALER 							= {},
		RAID 							= {},
		MOSTLYINCDMG 					= {},
		Wipe 							= function(self)
			for k in pairs(self) do 
				if k ~= "Wipe" then 
					wipe(self[k])	
				end 
			end 		
		end,
	},
	Frequency 							= {
		Actual 							= {},
		Temp 							= {},
		Wipe 							= function(self)
			for k in pairs(self) do 
				if k ~= "Wipe" then 
					wipe(self[k])	
				end 
			end 		
		end,
	},
}

local HealingEngineQueueOrder			= HealingEngine.QueueOrder
local HealingEngineMembers 				= HealingEngine.Members
local HealingEngineMembersALL			= HealingEngineMembers.ALL
local HealingEngineMembersTANK			= HealingEngineMembers.TANK
local HealingEngineMembersDAMAGER		= HealingEngineMembers.DAMAGER
local HealingEngineMembersHEALER		= HealingEngineMembers.HEALER
local HealingEngineMembersRAID			= HealingEngineMembers.RAID
local HealingEngineMembersTANKANDPARTY	= HealingEngineMembers.TANKANDPARTY
local HealingEngineMembersPARTY			= HealingEngineMembers.PARTY
local HealingEngineMembersMOSTLYINCDMG	= HealingEngineMembers.MOSTLYINCDMG
local HealingEngineFrequency 			= HealingEngine.Frequency
local HealingEngineFrequencyActual		= HealingEngineFrequency.Actual
local HealingEngineFrequencyTemp		= HealingEngineFrequency.Temp

local function CalculateHP(unitID)	
    local incomingheals 			= A_Unit(unitID):GetIncomingHeals()
	local cHealth, mHealth 			= A_Unit(unitID):Health(), A_Unit(unitID):HealthMax()
	
    local PercentWithIncoming 		= 100 * (cHealth + incomingheals) / mHealth
    local ActualWithIncoming 		= mHealth - (cHealth + incomingheals)
	
    return PercentWithIncoming, ActualWithIncoming, cHealth, mHealth
end

local function CanHeal(unitID, unitGUID)
    return 
		A_Unit(unitID):InRange()
		and A_Unit(unitID):IsConnected()
		--and A_Unit(unitID):CanCooperate(player)
		and not A_Unit(unitID):IsCharmed()			
		and not A_Unit(unitID):InLOS(unitGUID) 
		and not A_Unit(unitID):IsDead()
		and 
		(
			(
				not A.IsInPvP and 
				not A_Unit(unitID):IsEnemy()
			) or 
			(
				A.IsInPvP and 
				A_Unit(unitID):DeBuffCyclone(unitGUID) == 0 and 
				( 
					A_Unit(unitID):HasDeBuffs(Aura.SmokeBomb) == 0 or 
					A_Unit(player):HasDeBuffs(Aura.SmokeBomb) > 0
				)  
			)
		) 
		-- Patch 8.2
		-- 1514 is The Eternal Palace: Darkest Depths
		-- 292127 is Darkest Depths (DeBuff)
		and ( A.ZoneID ~= 1514 or A_Unit(unitID):HasDeBuffs(292127) == 0 )
end

local function PerformByProfileHP(member, memberhp, membermhp, DMG)
	-- Enable specific instructions by profile 
	if A.IsGGLprofile and not A.IsBasicProfile then 
		-- Holy Paladin 
		if A_Unit(player):HasSpec(ACTION_CONST_PALADIN_HOLY) then                 
			if (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and Env.SpellUsable(4987) and (not Env.InPvP() or not UnitIsUnit(player, member)) and Env.Dispel(member) then 
				-- DISPEL PRIORITY
				HealingEngineQueueOrder.Dispel = true 
				-- if we will have lower unit than 50% then don't dispel it
				memberhp = 50
				if A_Unit(member):IsHealer() then 
					memberhp = 25
				end
			elseif Azerite:GetRank(287268) > 0 and Env.SpellCD(20473) <= A_GetCurrentGCD() and A_Unit(member, 0.5):HasBuffs(287280, true) <= A_GetGCD() then 
				-- Glimmer of Light 
				-- Generally, prioritize players that might die in the next few seconds > non-Beaconed tank (without Glimmer buff) > Beaconed tank (without Glimmer buff) > players without the Glimmer buff
				if Env.PredictHeal("HolyShock", member) then 
					if A_Unit(member):IsTank() then 
						if A_Unit(member):HasBuffs(Temp.Beacons, true) == 0 then 
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
				local BestowFaith1, BestowFaith2 = A_Unit(member):HasBuffs(223306, true)
				if BestowFaith1 > 0 then 
					memberhp = memberhp + ( 100 * A_GetSpellDescription(223306)[1] / membermhp )
				end 
				-- Checking if Member has Beacons on them            
				if A_Unit(member):HasBuffs(Temp.Beacons, true) > 0 then
					memberhp = memberhp + ( 100 * (A_Unit(player):GetHPS() * 0.4) / membermhp ) - ( 100 * DMG / membermhp )
				end  
			end 
		end 
		
		-- Restor Druid 
		if A_Unit(player):HasSpec(ACTION_CONST_DRUID_RESTORATION) then 					
			if (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and Env.SpellUsable(88423) and (not Env.InPvP() or not UnitIsUnit(player, member)) and Env.Dispel(member) then 
				-- DISPEL PRIORITY
				HealingEngineQueueOrder.Dispel = true 
				memberhp = 50 
				-- if we will have lower unit than 50% then don't dispel it
				if A_Unit(member):IsHealer() then 
					memberhp = 25
				end						
			elseif memberhp < 100 then   
				-- HOT SYSTEM: current ticking and total duration
				local Rejuvenation1, Rejuvenation2 	= A_Unit(member):HasBuffs(774, true)
				local Regrowth1, Regrowth2 			= A_Unit(member):HasBuffs(8936, true)
				local WildGrowth1, WildGrowth2		= A_Unit(member):HasBuffs(48438, true)
				local Lifebloom1, Lifebloom2 		= A_Unit(member):HasBuffs(33763, true)                
				local Germination1, Germination2 	= A_Unit(member):HasBuffs(155777, true) -- Rejuvenation Talent 
				local summup = 0
				
				wipe(Temp.SumDMG)
				
				if Rejuvenation1 > 0 then 
					summup = summup + (A_GetSpellDescription(774)[1] / Rejuvenation2 * Rejuvenation1)
					Temp.SumDMG[#Temp.SumDMG + 1]	= Rejuvenation1
				else
					-- If current target is Tank then to prevent staying on that target we will cycle rest units 
					if healingTarget and healingTarget ~= "None" and A_Unit(healingTarget):IsTank() then 
						memberhp = memberhp - 15
					else 
						summup = summup - (A_GetSpellDescription(774)[1] * 3)
					end 
				end
				
				if Regrowth1 > 0 then 
					summup = summup + (A_GetSpellDescription(8936)[2] / Regrowth2 * Regrowth1)
					Temp.SumDMG[#Temp.SumDMG + 1]	= Regrowth1
				end
				
				if WildGrowth1 > 0 then 
					summup = summup + (A_GetSpellDescription(48438)[1] / WildGrowth2 * WildGrowth1)
					Temp.SumDMG[#Temp.SumDMG + 1]	= WildGrowth1                    
				end
				
				if Lifebloom1 > 0 then 
					summup = summup + (A_GetSpellDescription(33763)[1] / Lifebloom2 * Lifebloom1) 
					Temp.SumDMG[#Temp.SumDMG + 1]	= Lifebloom1    
				end
				
				if Germination1 > 0 then -- same with Rejuvenation
					summup = summup + (A_GetSpellDescription(774)[1] / Germination2 * Germination1)
					Temp.SumDMG[#Temp.SumDMG + 1]	= Germination1    
				end
				
				-- Get longer hot duration and predict incoming damage by that 
				tsort(Temp.SumDMG, sort_high)
				
				-- Now we convert it to persistent (from value to % as HP)
				if summup > 0 then 
					-- current HP % with pre casting heal + predict hot heal - predict incoming dmg 
					local memberhpHotSystem = memberhp + ( 100 * summup / membermhp ) - ( 100 * (DMG * Temp.SumDMG[1]) / membermhp )
					if memberhpHotSystem < 100 then
						memberhp = memberhpHotSystem
					end
				end                    
			end
		end
		
		-- Discipline Priest
		if A_Unit(player):HasSpec(ACTION_CONST_PRIEST_DISCIPLINE) then                 
			if (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and (not Env.InPvP() or not UnitIsUnit(player, member)) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
				-- DISPEL PRIORITY
				HealingEngineQueueOrder.Dispel = true 
				memberhp = 50 
				-- if we will have lower unit than 50% then don't dispel it
				if A_Unit(member):IsHealer() then 
					memberhp = 25
				end 
			elseif AtonementRenew_Toggle and A_Unit(member):HasBuffs(81749, true) <= A_GetCurrentGCD() then 				
				-- Toggle "Group Atonement/Renew﻿"
				memberhp = 50
			elseif memberhp < 100 then                    
				-- Atonement priority 
				if A_Unit(member):HasBuffs(81749, true) > 0 and Env.oPR and Env.oPR["AtonementHPS"] then 
					memberhp = memberhp + ( 100 * Env.oPR["AtonementHPS"] / membermhp )
				end 
				
				-- Absorb system 
				-- Pre pare 
				if A_Unit(player):CombatTime() <= 5 and 
				(
					A_Unit(player):CombatTime() > 0 or 
					(
						-- Pre shield before battle will start
						( A.Zone == "arena" or A.Zone == "pvp" ) and
						A:GetTimeSinceJoinInstance() < 120                             
					)
				) and A_Unit(member):GetAbsorb(17) == 0 then 
					memberhp = memberhp - 10
				end                     
				
				-- Toggle or PrePare combat or while Rapture always
				if _G.HE_Absorb or A_Unit(player):CombatTime() <= 5 or A_Unit(player):HasBuffs(47536, true) > A_GetCurrentGCD() then 
					memberhp = memberhp + ( 100 * A_Unit(member):GetAbsorb(17) / membermhp )
				end 
			end 
		end 
		
		-- Holy Priest
		if A_Unit(player):HasSpec(ACTION_CONST_PRIEST_HOLY) then                 
			if (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and (not Env.InPvP() or not UnitIsUnit(player, member)) and (Env.Dispel(member) or Env.Purje(member) or Env.MassDispel(member)) then 
				-- DISPEL PRIORITY
				HealingEngineQueueOrder.Dispel = true 
				memberhp = 50 
				-- if we will have lower unit than 50% then don't dispel it
				if A_Unit(member):IsHealer() then 
					memberhp = 25
				end  
			elseif _G.AtonementRenew_Toggle and A_Unit(member):HasBuffs(139, true) <= A_GetCurrentGCD() then 				
				-- Toggle "Group Atonement/Renew﻿"
				memberhp = 50
			elseif memberhp < 100 then 
				if Env.UnitIsTrailOfLight(member) then 
					-- Single Rotation 
					local ST = Env.IsIconDisplay("TMW:icon:1RhherQmOw_V") or 0
					if ST == 2061 then 
						memberhp = memberhp + ( 100 * (A_GetSpellDescription(2061)[1] * 0.35) / membermhp )
					elseif ST == 2060 then 
						memberhp = memberhp + ( 100 * (A_GetSpellDescription(2060)[1] * 0.35) / membermhp )
					end 
				end 
			end 
		end 
	   
		-- Mistweaver Monk 
		if A.IsInitialized and A_Unit(player):HasSpec(ACTION_CONST_MONK_MISTWEAVER) then 
			if not MK then 
				MK = A[ACTION_CONST_MONK_MISTWEAVER]
			end 
			
			if MK then 
				if (not HealingEngineQueueOrder.Dispel or A_Unit(member):IsHealer()) and (not A.IsInPvP or not UnitIsUnit(player, member)) and AuraIsValid(member, "UseDispel", "Dispel") then 
					-- DISPEL PRIORITY
					HealingEngineQueueOrder.Dispel = true 
					memberhp = 50 
					-- If we will have lower unit than 50% then don't dispel it
					if A_Unit(member):IsHealer() then 
						memberhp = 25
					end 
				elseif memberhp < 100 and GetToggle(2, "HealingEngineAutoHot") and MK.RenewingMist:IsReady() then 
					-- Keep Renewing Mist hots as much as it possible on cooldown
					local RenewingMist = A_Unit(member):HasBuffs(MK.RenewingMist.ID, true)
					if RenewingMist == 0 and MK.RenewingMist:PredictHeal("RenewingMist", member) then 
						memberhp = memberhp - 40
						if memberhp < 55 then 
							memberhp = 55 
						end 
					end 
				end 
			end 
		end 
	end 
	
	return memberhp
end

local function OnUpdate(MODE, useActualHP)   
	local group 				= TeamCacheFriendly.Type
    local ActualHP 				= useActualHP or false	
	HealingEngineMembers:Wipe()
	
    if group ~= "raid" then 
		local pHP, aHP, _, mHP 	= CalculateHP(player)
		local DMG 				= A_Unit(player):GetRealTimeDMG() 
		pHP				 		= PerformByProfileHP(player, pHP, mHP, DMG)
        HealingEngineMembersALL[#HealingEngineMembersALL + 1]									=	{ Unit = player, GUID = TeamCacheFriendlyUNITs.player or UnitGUID(player), HP = pHP, AHP = aHP, isPlayer = true, incDMG = DMG }
    end 
            
	if not group then 
		return 
	end 
	
    for i = 1, TeamCacheFriendly.MaxSize do
        local member 							= TeamCacheFriendlyIndexToPLAYERs[i]   
		local memberGUID 						= member and TeamCacheFriendlyUNITs[member]
		
		if memberGUID then 
			local memberhp, memberahp, _, membermhp = CalculateHP(member)
			-- Note: We can't use CanHeal here because it will take not all units results could be wrong
			HealingEngineFrequencyTemp.MAXHP 	= (HealingEngineFrequencyTemp.MAXHP or 0) + membermhp 
			HealingEngineFrequencyTemp.AHP 		= (HealingEngineFrequencyTemp.AHP   or 0) + memberahp
			
			-- Party/Raid
			if membermhp > 0 and CanHeal(member, memberGUID) then
				local DMG = A_Unit(member):GetRealTimeDMG() 
				local Actual_DMG = DMG
				
				-- Stop decrease predict HP if offset for DMG more than 15% of member's HP
				local DMG_offset = membermhp * 0.15
				if DMG > DMG_offset then 
					DMG = DMG_offset
				end
				
				-- Checking if Member has threat
				local threat = A_Unit(member):ThreatSituation()
				if threat >= 3 then
					memberhp = memberhp - threat
				end            
				
				memberhp = PerformByProfileHP(member, memberhp, membermhp, DMG)

				-- Misc: Sort by Roles 			
				if A_Unit(member):IsTank() then
					memberhp = memberhp - 2
					
					if mode == "TANK" then 
						HealingEngineMembersTANK[#HealingEngineMembersTANK + 1]					=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					end 
				elseif A_Unit(member):IsHealer() then                
					if UnitIsUnit(player, member) and memberhp < 95 then 
						if A.IsInPvP and A_Unit(player):IsFocused(nil, true) then 
							memberhp = memberhp - 20
						else 
							memberhp = memberhp - 2
						end 
					else 
						memberhp = memberhp + 2
					end
					
					if mode == "HEALER" then 
						HealingEngineMembersHEALER[#HealingEngineMembersHEALER + 1]				=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif mode == "RAID" then 	
						HealingEngineMembersRAID[#HealingEngineMembersRAID + 1]					=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					end 				 
				else 
					memberhp = memberhp - 1
					
					if mode == "DAMAGER" then 
						HealingEngineMembersDAMAGER[#HealingEngineMembersDAMAGER + 1]			=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					elseif mode == "RAID" then  
						HealingEngineMembersRAID[#HealingEngineMembersRAID + 1]					=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
					end			 
				end

				HealingEngineMembersALL[#HealingEngineMembersALL + 1]							=	{ Unit = member, GUID = memberGUID, HP = memberhp, AHP = memberahp, isPlayer = true, incDMG = Actual_DMG }
			end        
			
			-- Pets 
			if _G.HE_Pets then
				local memberpet 										= TeamCacheFriendlyIndexToPETs[i]
				local memberpetGUID 									= memberpet and TeamCacheFriendlyUNITs[memberpet]
				
				if memberpetGUID then 
					local memberpethp, memberpetahp, _, memberpetmhp 	= CalculateHP(memberpet) 
					
					-- Note: We can't use CanHeal here because it will take not all units results could be wrong
					HealingEngineFrequencyTemp.MAXHP 					= (HealingEngineFrequencyTemp.MAXHP or 0) + memberpetmhp 
					HealingEngineFrequencyTemp.AHP 	 					= (HealingEngineFrequencyTemp.AHP   or 0) + memberpetahp			
					
					if memberpetmhp > 0 and CanHeal(memberpet, memberpetGUID) then 
						if A_Unit(player):CombatTime() > 0 then                
							memberpethp  = memberpethp * 1.35
							memberpetahp = memberpetahp * 1.35
						else                
							memberpethp  = memberpethp * 1.15
							memberpetahp = memberpetahp * 1.15
						end
						
						HealingEngineMembersALL[#HealingEngineMembersALL + 1]					=	{ Unit = memberpet, GUID = memberpetGUID, HP = memberpethp, AHP = memberpetahp, isPlayer = false, incDMG = A_Unit(memberpet):GetRealTimeDMG() } 
					end 
				end 
			end
		end 
    end
    
    -- Frequency (Summary)
    if HealingEngineFrequencyTemp.MAXHP and HealingEngineFrequencyTemp.MAXHP > 0 then 
        HealingEngineFrequencyActual[#HealingEngineFrequencyActual + 1] = { 	                
                -- Max Group HP
                MAXHP	= HealingEngineFrequencyTemp.MAXHP, 
                -- Current Group Actual HP
                AHP 	= HealingEngineFrequencyTemp.AHP,
				-- Current Time on this record 
				TIME 	= TMW.time, 
        }
		
		-- Clear temp by old record
        wipe(HealingEngineFrequencyTemp)
		
		-- Clear actual from older records
        for i = #HealingEngineFrequencyActual, 1, -1 do             
            -- Remove data longer than 5 seconds 
            if TMW.time - HealingEngineFrequencyActual[i].TIME > 10 then 
                tremove(HealingEngineFrequencyActual, i)                
            end 
        end 
    end 
    
	-- Sort for next target / incDMG (Summary)
    if #HealingEngineMembersALL > 1 then 
        -- Sort by most damage receive
		for i = 1, #HealingEngineMembersALL do 
			HealingEngineMembersMOSTLYINCDMG[#HealingEngineMembersMOSTLYINCDMG + 1]				=	{ Unit = HealingEngineMembersALL[i].Unit, GUID = HealingEngineMembersALL[i].GUID, incDMG = HealingEngineMembersALL[i].incDMG }
		end 
        tsort(HealingEngineMembersMOSTLYINCDMG, sort_incDMG)  
        
        -- Sort by Percent or Actual
        if not ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].HP then 
					tsort(v, sort_HP)
				end 
			end 		
        elseif ActualHP then
			for _, v in pairs(HealingEngineMembers) do 
				if type(v) == "table" and #v > 1 and v[1].AHP then 
					tsort(v, sort_AHP)
				end 
			end 		
        end
    end 
end

local function SetHealingTarget(MODE)
	if #HealingEngineMembers[MODE] > 0 and HealingEngineMembers[MODE][1].HP < 99 then 
		healingTarget 		= HealingEngineMembers[MODE][1].Unit
		healingTargetGUID 	= HealingEngineMembers[MODE][1].GUID
		return 
	end 	 

    healingTarget 	  		= None
    healingTargetGUID 		= None
end

local function SetColorTarget(isForced)
    --Default 
    Frametexture:SetColorTexture(0, 0, 0, 1.0)   
	
	if not isForced then 
		--If we have no one to heal
		if healingTarget == nil or healingTarget == None or healingTargetGUID == nil or healingTargetGUID == None then
			return
		end	
		
		--If we have a mouseover friendly unit
		if (A.IsInitialized and A_IsUnitFriendly("mouseover")) or (not A.IsInitialized and MouseOver_Toggle and A.MouseHasFrame()) then    -- TODO: Remove "or (not A.IsInitialized and MouseOver_Toggle and A.MouseHasFrame())"
			return
		end
		
		--If we have a current target equiled to suggested or he is a boss
		if A_Unit("target"):IsExists() and (healingTargetGUID == UnitGUID("target") or A_Unit("target"):IsBoss()) then
			return
		end     
		
		--If we have enemy as primary unit 
		-- TODO: Remove for old profiles until June 2019
		if not A.IsInitialized and ((MouseOver_Toggle and A_Unit("mouseover"):IsEnemy()) or A_Unit("target"):IsEnemy()) then 
			-- Old profiles 
			return 
		end 
		
		--If we decided to perform damage
		if A.IsInitialized and (A_IsUnitEnemy("mouseover") or A_IsUnitEnemy("target")) then 
			return 
		end 
		
		--Mistweaver Monk
		if A.IsInitialized and A.IsGGLprofile and A_Unit(player):HasSpec(ACTION_CONST_MONK_MISTWEAVER) and GetToggle(2, "HealingEnginePreventSuggest") then 
			local unit = "target"
			if A_IsUnitFriendly("mouseover") then 
				unit = "mouseover"
			end 
			if A_Unit(unit):HasBuffs(A[ACTION_CONST_MONK_MISTWEAVER].SoothingMist.ID, true) > 3 and A_Unit(unit):HealthPercent() <= GetToggle(2, "SoothingMistHP") then 
				return 
			end 
		end 
    end 
	
    --Party
    if healingTarget == "party1" then
        Frametexture:SetColorTexture(0.345098, 0.239216, 0.741176, 1.0)
        return
    end
    if healingTarget == "party2" then
        Frametexture:SetColorTexture(0.407843, 0.501961, 0.086275, 1.0)
        return
    end
    if healingTarget == "party3" then
        Frametexture:SetColorTexture(0.160784, 0.470588, 0.164706, 1.0)
        return
    end
    if healingTarget == "party4" then
        Frametexture:SetColorTexture(0.725490, 0.572549, 0.647059, 1.0)
        return
    end   
    
    --PartyPET
    if healingTarget == "partypet1" then
        Frametexture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
        return
    end
    if healingTarget == "partypet2" then
        Frametexture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
        return
    end
    if healingTarget == "partypet3" then
        Frametexture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
        return
    end
    if healingTarget == "partypet4" then
        Frametexture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
        return
    end        
    
    --Raid
    if healingTarget == "raid1" then
        Frametexture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
        return
    end
    if healingTarget == "raid2" then
        Frametexture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
        return
    end
    if healingTarget == "raid3" then
        Frametexture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
        return
    end
    if healingTarget == "raid4" then
        Frametexture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
        return
    end
    if healingTarget == "raid5" then
        Frametexture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
        return
    end
    if healingTarget == "raid6" then
        Frametexture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid7" then
        Frametexture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
        return
    end
    if healingTarget == "raid8" then
        Frametexture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid9" then
        Frametexture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
        return
    end
    if healingTarget == "raid10" then
        Frametexture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
        return
    end
    if healingTarget == "raid11" then
        Frametexture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
        return
    end
    if healingTarget == "raid12" then
        Frametexture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid13" then
        Frametexture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
        return
    end
    if healingTarget == "raid14" then
        Frametexture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
        return
    end
    if healingTarget == "raid15" then
        Frametexture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
        return
    end
    if healingTarget == "raid16" then
        Frametexture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
        return
    end
    if healingTarget == "raid17" then
        Frametexture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
        return
    end
    if healingTarget == "raid18" then
        Frametexture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
        return
    end
    if healingTarget == "raid19" then
        Frametexture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
        return
    end
    if healingTarget == "raid20" then
        Frametexture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
        return
    end
    if healingTarget == "raid21" then
        Frametexture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
        return
    end
    if healingTarget == "raid22" then
        Frametexture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
        return
    end
    if healingTarget == "raid23" then
        Frametexture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
        return
    end
    if healingTarget == "raid24" then
        Frametexture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
        return
    end
    if healingTarget == "raid25" then
        Frametexture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
        return
    end
    if healingTarget == "raid26" then
        Frametexture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
        return
    end
    if healingTarget == "raid27" then
        Frametexture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
        return
    end
    if healingTarget == "raid28" then
        Frametexture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
        return
    end
    if healingTarget == "raid29" then
        Frametexture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
        return
    end
    if healingTarget == "raid30" then
        Frametexture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
        return
    end
    if healingTarget == "raid31" then
        Frametexture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
        return
    end
    if healingTarget == "raid32" then
        Frametexture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
        return
    end
    if healingTarget == "raid33" then
        Frametexture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
        return
    end
    if healingTarget == "raid34" then
        Frametexture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
        return
    end    
    if healingTarget == "raid35" then
        Frametexture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
        return
    end
    if healingTarget == "raid36" then
        Frametexture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
        return
    end
    if healingTarget == "raid37" then
        Frametexture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
        return
    end
    if healingTarget == "raid38" then
        Frametexture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
        return
    end
    if healingTarget == "raid39" then
        Frametexture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
        return
    end
    if healingTarget == "raid40" then
        Frametexture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
        return
    end
    if healingTarget == "raidpet1" then
        Frametexture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet2" then
        Frametexture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
        return
    end
    if healingTarget == "raidpet3" then
        Frametexture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
        return
    end
    if healingTarget == "raidpet4" then
        Frametexture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet5" then
        Frametexture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
        return
    end
    if healingTarget == "raidpet6" then
        Frametexture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
        return
    end
    if healingTarget == "raidpet7" then
        Frametexture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
        return
    end
    if healingTarget == "raidpet8" then
        Frametexture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
        return
    end
    if healingTarget == "raidpet9" then
        Frametexture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
        return
    end
    if healingTarget == "raidpet10" then
        Frametexture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
        return
    end
    if healingTarget == "raidpet11" then
        Frametexture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
        return
    end
    if healingTarget == "raidpet12" then
        Frametexture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
        return
    end
    if healingTarget == "raidpet13" then
        Frametexture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
        return
    end
    if healingTarget == "raidpet14" then
        Frametexture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
        return
    end
    if healingTarget == "raidpet15" then
        Frametexture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
        return
    end
    if healingTarget == "raidpet16" then
        Frametexture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
        return
    end
    if healingTarget == "raidpet17" then
        Frametexture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
        return
    end
    if healingTarget == "raidpet18" then
        Frametexture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
        return
    end
    if healingTarget == "raidpet19" then
        Frametexture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
        return
    end
    if healingTarget == "raidpet20" then
        Frametexture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
        return
    end
    if healingTarget == "raidpet21" then
        Frametexture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
        return
    end
    if healingTarget == "raidpet22" then
        Frametexture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
        return
    end
    if healingTarget == "raidpet23" then
        Frametexture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
        return
    end
    if healingTarget == "raidpet24" then
        Frametexture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
        return
    end
    if healingTarget == "raidpet25" then
        Frametexture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
        return
    end
    if healingTarget == "raidpet26" then
        Frametexture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet27" then
        Frametexture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
        return
    end
    if healingTarget == "raidpet28" then
        Frametexture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
        return
    end
    if healingTarget == "raidpet29" then
        Frametexture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
        return
    end
    if healingTarget == "raidpet30" then
        Frametexture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
        return
    end
    if healingTarget == "raidpet31" then
        Frametexture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
        return
    end
    if healingTarget == "raidpet32" then
        Frametexture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
        return
    end
    if healingTarget == "raidpet33" then
        Frametexture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
        return
    end
    if healingTarget == "raidpet34" then
        Frametexture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
        return
    end
    if healingTarget == "raidpet35" then
        Frametexture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
        return
    end
    if healingTarget == "raidpet36" then
        Frametexture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
        return
    end
    if healingTarget == "raidpet37" then
        Frametexture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
        return
    end
    if healingTarget == "raidpet38" then
        Frametexture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
        return
    end
    if healingTarget == "raidpet39" then
        Frametexture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
        return
    end
    if healingTarget == "raidpet40" then
        Frametexture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
        return
    end
    
    --Stuff
    if healingTarget == player then
        Frametexture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
        return
    end
    if healingTarget == "focus" then
        Frametexture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
        return
    end
    --[[
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
        return
    end
    if healingTarget == PLACEHOLDER then
        Frametexture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
        return
    end   
    if healingTarget == PLACEHOLDER then --was party5
        Frametexture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
        return
    end     
    if healingTarget == PLACEHOLDER then --was party5pet
        Frametexture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
        return
    end
    ]]
end

local function UpdateLOS()
	if A_Unit("target"):IsExists() then
		if A.IsInitialized then
			-- New profiles 
			if not A_IsUnitFriendly("mouseover") then 
				GetLOS("target")
			end 		
		elseif A.IsGGLprofile and (not _G.MouseOver_Toggle or A_Unit("mouseover"):IsEnemy() or not A.MouseHasFrame()) then 
			-- TODO: Remove on old profiles until June 2019
			-- Old profiles 
			GetLOS("target")
		end 
	end 
end

local function WipeFrequencyActual()
	wipe(HealingEngineFrequencyActual)
end 

local function HealingEngineInit()
	if A.IamHealer then 
		if not HealingEngine.IsRunning then 
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED", 	UpdateLOS			)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED", 		WipeFrequencyActual	)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED", 	WipeFrequencyActual	)
			Frame:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = (self.elapsed or 0) + elapsed   
				local INTV = TMW.UPD_INTV and TMW.UPD_INTV > 0.3 and TMW.UPD_INTV or 0.3
				if self.elapsed > INTV then 
					local ROLE = _G.HE_Toggle or "ALL"
					
					OnUpdate(ROLE) 
					
					if TMW.time > healingTargetDelay then 
						SetHealingTarget(ROLE) 
						SetColorTarget()   
					end 
					
					UpdateLOS() 
					
					self.elapsed = 0
				end			
			end)
			HealingEngine.IsRunning = true 
		end 
	elseif HealingEngine.IsRunning then
		Frame:SetScript("OnUpdate", nil)
		Frametexture:SetColorTexture(0, 0, 0, 1.0) 
		HealingEngineMembers:Wipe()
		HealingEngineFrequency:Wipe()
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED")
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED")
		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED")	
		HealingEngine.IsRunning = false 
	end 
end 

TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 				HealingEngineInit) 
TMW:RegisterCallback("TMW_ACTION_ENTERING", 									HealingEngineInit) 

--- ============================= API ==============================
--- API valid only for healer specializations  
--- Members are depend on _G.HE_Pets variable 

--- Globals
A.HealingEngine = {}

--- SetTarget Controller 
function A.HealingEngine.SetTargetMostlyIncDMG(delay)
	if #HealingEngineMembersMOSTLYINCDMG > 0 then 
		healingTargetDelay 		= TMW.time + (delay or 2)
		if UnitGUID("target") ~= healingTargetGUID then 
			healingTargetGUID 	= HealingEngineMembersMOSTLYINCDMG[1].GUID
			healingTarget		= HealingEngineMembersMOSTLYINCDMG[1].Unit
			SetColorTarget(true)
		end 
	end 
end 

function A.HealingEngine.SetTarget(unitID, delay)
	-- Sets in HealingEngine specified unitID with delay which will prevent reset target during next few seconds 
	local GUID = TeamCacheFriendlyUNITs[unitID] or UnitGUID(unitID)
	if GUID then 
		healingTargetDelay 		= TMW.time + (delay or 2)
		if GUID ~= healingTargetGUID and #HealingEngineMembersALL > 0 then 
			healingTargetGUID 	= GUID
			healingTarget		= TeamCacheFriendlyGUIDs[unitID] or unitID
			SetColorTarget(true)
		end 
	end 
end

--- Group Controller 
function A.HealingEngine.GetMembersAll()
	-- @return table 
	return HealingEngineMembersALL 
end 

function A.HealingEngine.GetMembersByMode(MODE)
	-- @return table 
	local mode = MODE or _G.HE_Toggle or "ALL"
	return HealingEngineMembers[mode] 
end 

function A.HealingEngine.GetBuffsCount(ID, duration, source, byID)
	-- @return number 	
	-- Only players 
    local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if HealingEngineMembersALL[i].isPlayer and A_Unit(HealingEngineMembersALL[i].Unit):HasBuffs(ID, source, byID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetDeBuffsCount(ID, duration, source, byID)
	-- @return number 	
	-- Only players 
    local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if HealingEngineMembersALL[i].isPlayer and A_Unit(HealingEngineMembersALL[i].Unit):HasDeBuffs(ID, source, byID) > (duration or 0) then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetHealth()
	-- @return number 
	-- Return actual group health 
	if #HealingEngineFrequencyActual > 0 then 
		return HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP
	end 
	return huge
end 

function A.HealingEngine.GetHealthAVG() 
	-- @return number 
	-- Return current percent (%) of the group health
	if #HealingEngineFrequencyActual > 0 then 
		return HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
	end 
	return 100  
end 

function A.HealingEngine.GetHealthFrequency(timer)
	-- @return number 
	-- Return percent (%) of the group HP changed during lasts 'timer'. Positive (+) is HP lost, Negative (-) is HP gain, 0 - nothing is not changed 
    local total, counter = 0, 0

    if #HealingEngineFrequencyActual > 1 then 
        for i = 1, #HealingEngineFrequencyActual - 1 do 
            -- Getting history during that time rate
            if TMW.time - HealingEngineFrequencyActual[i].TIME <= timer then 
                counter = counter + 1
                total 	= total + HealingEngineFrequencyActual[i].AHP
            end 
        end        
    end 
	
	if total > 0 then           
		total = (HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP) - (total / counter * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP)
	end  	
	
    return total 
end 
A.HealingEngine.GetHealthFrequency = MakeFunctionCachedDynamic(A.HealingEngine.GetHealthFrequency)

function A.HealingEngine.GetIncomingDMG()
	-- @return number, number 
	-- Return REALTIME actual: total - group HP lose per second, avg - average unit HP lose per second
	local total, avg = 0, 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            total = total + HealingEngineMembersALL[i].incDMG
        end
		
		avg = total / #HealingEngineMembersALL
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingDMG = MakeFunctionCachedStatic(A.HealingEngine.GetIncomingDMG)

function A.HealingEngine.GetIncomingHPS()
	-- @return number , number
	-- Return PERSISTENT actual: total - group HP gain per second, avg - average unit HP gain per second 
	local total, avg = 0, 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            total = total + A_Unit(HealingEngineMembersALL[i].Unit):GetHEAL()
        end
		
		avg = total / #HealingEngineMembersALL
    end 
    return total, avg 
end 
A.HealingEngine.GetIncomingHPS = MakeFunctionCachedStatic(A.HealingEngine.GetIncomingHPS)

function A.HealingEngine.GetIncomingDMGAVG()
	-- @return number  
	-- Return REALTIME average percent group HP lose per second 
    if #HealingEngineFrequencyActual > 0 then 
		return A.HealingEngine.GetIncomingDMG() * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
    end 
    return 0 
end

function A.HealingEngine.GetIncomingHPSAVG()
	-- @return number  
	-- Return REALTIME average percent group HP gain per second 
    if #HealingEngineFrequencyActual > 0 then 
		return A.HealingEngine.GetIncomingHPS() * 100 / HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP
    end 
    return 0 
end 

function A.HealingEngine.GetTimeToFullDie()
	-- @return number 
	-- Returns AVG time to die all group members 
	local total = 0
	
    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
			total = total + A_Unit(HealingEngineMembersALL[i].Unit):TimeToDie()
        end
		return total / #HealingEngineMembersALL
	else 
		return huge 
    end 
end 

function A.HealingEngine.GetTimeToDieUnits(timer)
	-- @return number 
	local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if A_Unit(HealingEngineMembersALL[i].Unit):TimeToDie() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToDieMagicUnits(timer)
	-- @return number 
	local total = 0

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if A_Unit(HealingEngineMembersALL[i].Unit):TimeToDieMagic() <= timer then
                total = total + 1
            end
        end
    end 
    return total 
end 

function A.HealingEngine.GetTimeToFullHealth()
	-- @return number
	if #HealingEngineFrequencyActual > 0 then 
		local HPS = A.HealingEngine.GetIncomingHPS()
		if HPS > 0 then
			return (HealingEngineFrequencyActual[#HealingEngineFrequencyActual].MAXHP - HealingEngineFrequencyActual[#HealingEngineFrequencyActual].AHP) / HPS
		end 
	end 
	return 0 
end 

function A.HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit)
	-- @return number 
	-- This is easy template to known how many people minimum required be to heal by AoE with different group size or if some units out of range or in cyclone and etc..
	-- More easy to figure - which minimum units require if available group members <= 1 / <= 3 / <= 5 or > 5
	local members = #HealingEngineMembersALL
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

function A.HealingEngine.GetBelowHealthPercentercentUnits(pHP, range)
	-- @return number 
	-- Return how much members below percent of health with range (range can be nil)
	local total = 0 

    if #HealingEngineMembersALL > 0 then 
        for i = 1, #HealingEngineMembersALL do
            if (not range or A_Unit(HealingEngineMembersALL[i].Unit):CanInterract(range)) and HealingEngineMembersALL[i].HP <= pHP then
                total = total + 1
            end
        end
    end 
	return total 
end 

function A.HealingEngine.HealingByRange(range, predictName, spell, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified range with spell
	local total = 0

	if #HealingEngineMembersALL > 0 then 		
		for i = 1, #HealingEngineMembersALL do 
			if 	(not isMelee or A_Unit(HealingEngineMembersALL[i].Unit):IsMelee()) and 
				A_Unit(HealingEngineMembersALL[i].Unit):CanInterract(range) and
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, HealingEngineMembersALL[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and spell:PredictHeal(predictName, HealingEngineMembersALL[i].Unit))
				)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

function A.HealingEngine.HealingBySpell(predictName, spell, isMelee)
	-- @return number 
	-- Return how much members can be healed by specified spell 
	local total = 0

	if #HealingEngineMembersALL > 0 then 		
		for i = 1, #HealingEngineMembersALL do 
			if 	(not isMelee or A_Unit(HealingEngineMembersALL[i].Unit):IsMelee()) and 
				(
					(not A.IsInitialized and Env.SpellInRange(HealingEngineMembersALL[i].Unit, spell)) or
					(A.IsInitialized and spell:IsInRange(HealingEngineMembersALL[i].Unit))
				) and 
				(
					-- Old profiles 
					-- TODO: Remove after rewrite old profiles 
					(not A.IsInitialized and Env.PredictHeal(predictName, HealingEngineMembersALL[i].Unit)) or 
					-- New profiles 
					(A.IsInitialized and spell:PredictHeal(predictName, HealingEngineMembersALL[i].Unit))
				)
			then
                total = total + 1
            end
		end 		
	end 
	return total 
end 

function A.HealingEngine.HealingBySpiritofPreservation(obj, stop, skipShouldStop)
	-- @return number 
	local total 	= 0
	local isTable 	= type(obj) == "table"
	
	if #HealingEngineMembersALL > 0 then 		
		for i = 1, #HealingEngineMembersALL do 
			if isTable then 
				if obj:IsReady(HealingEngineMembersALL[i].Unit, true, nil, skipShouldStop) and Azerite:EssencePredictHealing("Spirit of Preservation", obj.ID, HealingEngineMembersALL[i].Unit) then
					total = total + 1
				end
			else
				if Env.SpellInRange(HealingEngineMembersALL[i].Unit, obj) and Azerite:EssencePredictHealing("Spirit of Preservation", obj, HealingEngineMembersALL[i].Unit) then
					total = total + 1
				end
			end 
			
			if stop and total >= stop then 
				break 
			end 
		end 		
	end 
	return total 	
end 

--- Unit Controller 
function A.HealingEngine.IsMostlyIncDMG(unitID)
	-- @return boolean, number (realtime incoming damage)	
	if #HealingEngineMembersMOSTLYINCDMG > 0 then 
		return UnitIsUnit(unitID, HealingEngineMembersMOSTLYINCDMG[1].Unit), HealingEngineMembersMOSTLYINCDMG[1].incDMG
	end 
	return false, 0
end 

function A.HealingEngine.GetTarget()
	return healingTarget, healingTargetGUID
end 