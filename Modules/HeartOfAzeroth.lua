local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
local Action = Action

local AzeriteEssence = _G.C_AzeriteEssence
local GetMajorBySpellName

if AzeriteEssence then 
	GetMajorBySpellName = {
		-- Taken lowest Azerite Essence ID
		--[[ Essences Used by All Roles ]]
		[Spell:CreateFromSpellID(295373):GetSpellName()] = "Concentrated Flame",
		[Spell:CreateFromSpellID(295186):GetSpellName()] = "Worldvein Resonance",
		[Spell:CreateFromSpellID(302731):GetSpellName()] = "Ripple in Space", 
		[Spell:CreateFromSpellID(298357):GetSpellName()] = "Memory of Lucid Dreams",
		--[[ Tank ]]
		[Spell:CreateFromSpellID(293019):GetSpellName()] = "Azeroth's Undying Gift",
		[Spell:CreateFromSpellID(294926):GetSpellName()] = "Anima of Death",
		[Spell:CreateFromSpellID(298168):GetSpellName()] = "Aegis of the Deep",
		[Spell:CreateFromSpellID(295746):GetSpellName()] = "Empowered Null Barrier",
		[Spell:CreateFromSpellID(293031):GetSpellName()] = "Suppressing Pulse", 
		--[[ Healer ]]
		[Spell:CreateFromSpellID(296197):GetSpellName()] = "Refreshment", 
		[Spell:CreateFromSpellID(296094):GetSpellName()] = "Standstill", 
		[Spell:CreateFromSpellID(293032):GetSpellName()] = "Life-Binder's Invocation", 
		[Spell:CreateFromSpellID(296072):GetSpellName()] = "Overcharge Mana", 
		[Spell:CreateFromSpellID(296230):GetSpellName()] = "Vitality Conduit", 
		--[[ Damager ]]
		[Spell:CreateFromSpellID(295258):GetSpellName()] = "Focused Azerite Beam", 
		[Spell:CreateFromSpellID(295840):GetSpellName()] = "Guardian of Azeroth", 
		[Spell:CreateFromSpellID(297108):GetSpellName()] = "Blood of the Enemy", 
		[Spell:CreateFromSpellID(295337):GetSpellName()] = "Purifying Blast", 
		[Spell:CreateFromSpellID(298452):GetSpellName()] = "The Unbound Force", 
	}	
end 

local AzeriteEssences = {
	ALL = {
		ConcentratedFlame 			= { Type = "HeartOfAzeroth", ID = 295373 	}, -- filler (40y, low priority) HPS / DPS 
		WorldveinResonance			= { Type = "HeartOfAzeroth", ID = 295186 	}, -- filler (small stat burst, cd1min, high priority)
		RippleinSpace				= { Type = "HeartOfAzeroth", ID = 302731 	}, -- movement / -10% deffensive (x3 rank)
		MemoryofLucidDreams			= { Type = "HeartOfAzeroth", ID = 298357 	}, -- burst (100% power regeneration)
	},
	TANK = {
		AzerothsUndyingGift			= { Type = "HeartOfAzeroth", ID = 293019 	}, -- -20% 4sec cd1min / -40% 2sec and then -20% 2sec cd45sec
		AnimaofDeath				= { Type = "HeartOfAzeroth", ID = 294926 	}, -- aoe self heal cd2.5-2min
		AegisoftheDeep				= { Type = "HeartOfAzeroth", ID = 298168 	}, -- physical attack protection cd2-1.5min
		EmpoweredNullBarrier		= { Type = "HeartOfAzeroth", ID = 295746 	}, -- magic attack protection cd3-2.3min
		SuppressingPulse			= { Type = "HeartOfAzeroth", ID = 293031 	}, -- aoe -70% slow and -25% attack speed cd60-45sec
	},
	HEALER = {
		Refreshment					= { Type = "HeartOfAzeroth", ID = 296197 	}, -- filler cd15sec
		Standstill					= { Type = "HeartOfAzeroth", ID = 296094 	}, -- burst (big absorb incoming dmg and hps) cd3min
		LifeBindersInvocation		= { Type = "HeartOfAzeroth", ID = 293032 	}, -- burst aoe (big heal) cd3min
		OverchargeMana				= { Type = "HeartOfAzeroth", ID = 296072 	}, -- filler (my hps < incoming unit dps) cd30sec
		VitalityConduit				= { Type = "HeartOfAzeroth", ID = 296230 	}, -- aoe cd60-45sec 
	},	
	DAMAGER = {
		FocusedAzeriteBeam			= { Type = "HeartOfAzeroth", ID = 295258 	}, -- aoe 
		GuardianofAzeroth			= { Type = "HeartOfAzeroth", ID = 295840 	}, -- burst 
		BloodoftheEnemy				= { Type = "HeartOfAzeroth", ID = 297108 	}, -- aoe 
		PurifyingBlast				= { Type = "HeartOfAzeroth", ID = 295337 	}, -- filler (aoe, high priority)
		TheUnboundForce				= { Type = "HeartOfAzeroth", ID = 298452 	}, -- filler (high priority)
	},
}

local UnitHealthMax, UnitHealth, UnitPowerMax, UnitPower, UnitGetIncomingHeals, UnitIsPlayer, UnitInRange = 
	  UnitHealthMax, UnitHealth, UnitPowerMax, UnitPower, UnitGetIncomingHeals, UnitIsPlayer, UnitInRange
	  
local IsStealthed = 
	  IsStealthed

local GetNetStats, GetSpecializationRoleByID =
	  GetNetStats, GetSpecializationRoleByID

local function PredictHealing(MajorSpellName, spellID, unitID, VARIATION) 
	-- Exception penalty for low level units / friendly boss
    local UnitLvL = Env.UNITLevel(unitID)
    if (UnitLvL == -1 or (UnitLvL > 0 and UnitLvL < Env.UNITLevel("player") - 10)) and MajorSpellName ~= "Anima of Death" and MajorSpellName ~= "Vitality Conduit" then
        return true, 0
    end     
    
    -- Header
    local variation = (VARIATION and (VARIATION / 100)) or 1  
    
    local total = 0
    local DMG, HPS = getDMG(unitID), getHEAL(unitID)      
    local DifficultHP = -1
        
    -- Spells
    if MajorSpellName == "Concentrated Flame" then  
		-- @direct
		DifficultHP = UnitHealthMax(unitID) - UnitHealth(unitID)  
		
		-- Multiplier (resets on 4th stack, each stack +100%)
		local multiplier = Env.Unit(unitID):HasBuffsStacks(295378, true) + 1
		
		local amount = Env.GetDescription(spellID)[1] * multiplier
		
		-- Additional +75% over next 6 sec 
		local additional = 0
		if AzeriteRank(spellID) >= 2 then
			additional = amount * 0.75 * multiplier + (HPS * 6) - (DMG * 6)
		end 
		
        total = (amount + additional) * variation           
    end
	
	if MajorSpellName == "Anima of Death" then 
		-- @percent 
		local HP = Env.UNITHP(unitID)
		DifficultHP = 100 - HP
		
		local rank = AzeriteRank(spellID)
		-- HP in percent heal per unit 
		local hpperunit = rank >= 3 and 10 or 5
		-- HP limit (on which stop query)
		local hplimit = rank >= 3 and 50 or 25
		local enemies = GetActiveUnitPlates("enemy")
		local totalmobs = 0
		-- Passing (in case if something went wrong with nameplates)
		if not enemies then 
			if HP > 80 then 
				return false, 0
			else
				return true, 0
			end 
		end 
		
		for _, unit in pairs(enemies) do
			if Env.Unit(unit):GetRange() <= 8 then
				totalmobs = totalmobs + 1
				total = totalmobs * hpperunit * variation 
				if total >= hplimit then                
					break            
				end        
			end
		end 	
	end 

	if MajorSpellName == "Refreshment" then 
		local maxUnitHP = UnitHealthMax(unitID)
		-- @direct
		DifficultHP = maxUnitHP - UnitHealth(unitID)  
		-- The Well of Existence do search by name, TMW will do rest work 
		local amount = Env.AuraTooltipNumber("player", Action.GetSpellInfo(296136), "HELPFUL PLAYER") 
		
		if amount < maxUnitHP * 0.2 then 
			-- Do nothing if it heal lower than 20% on a unit
			return false, 0				
		elseif amount >= maxUnitHP and Env.UNITHP(unitID) < 70 then 
			-- Or if we reached cap (?) 
			return true, 0 
		end 
		
		total = amount * variation
	end 
	
	if MajorSpellName == "Vitality Conduit" then 
		-- @AoE 
		local amount = Env.GetDescription(spellID)[1]
		total = amount * variation
		
		local validMembers 	= Action.HealingEngine.GetMinimumUnits(1, 5)
		if validMembers < 2 then 
			validMembers = 2
		end 
		
		local members 		= Action.HealingEngine.GetMembersAll()
		local totalMembers = 0 
		if #members > 0 and validMembers >= 2 then 
			for i = 1, #members do
				if members[i].MHP - members[i].AHP >= total then
					totalMembers = totalMembers + 1
				end
				if totalMembers >= validMembers then 
					return true, total * totalMembers
				end 
			end
		end
		
		return false, 0
	end 
	
	return DifficultHP >= total, total
end   

--------------------------------------
-- OLD PROFILES FUNCTIONAL 
--------------------------------------
-- TODO: Remove on old profiles until June 2019
function Action.HeartOfAzerothShow(icon)
	Action.TMWAPL(icon, "texture", ACTION_CONST_HEARTOFAZEROTH)
	return true 
end 

function Action.LazyHeartOfAzeroth(icon, unit) 
	if AzeriteEssenceIsMajorUseable() then 
		local Major = AzeriteEssenceGetMajor()
		local spellName = Major.spellName 
		local spellID = Major.spellID 

		local MajorSpellName = GetMajorBySpellName[spellName]
		
		if MajorSpellName and Env.SpellCD(spellID) <= select(4, GetNetStats()) / 1000 + 0.025 and CombatTime("player") > 0 then 
			local ShouldStop = Action.ShouldStop()
			local unitID = unit and unit or "target"
			
			--[[ Essences Used by All Roles ]]
			if MajorSpellName == "Concentrated Flame" then 
				-- GCD 1 sec 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Env.SpellInRange(unitID, spellID) and (Env.Unit(unitID):IsEnemy() or PredictHealing(MajorSpellName, spellID, unitID)) then 
					-- PvP condition 
					if not Env.InPvP() or not UnitIsPlayer(unitID) or (not Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):DeBuffCyclone() == 0) or (Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Worldvein Resonance" then 				
				-- GCD 1.5 sec 
				local isMelee = Env.Unit("player"):IsMelee()
				local range = Env.Unit(unitID):GetRange()
				if not ShouldStop and ((isMelee and range <= 8) or (not isMelee and range <= 40)) then  
					-- PvP condition 
					if not Env.InPvP() or not Env.Unit(unitID):IsEnemy() or not UnitIsPlayer(unitID) or (Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamagePhysImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Ripple in Space" then 
				-- GCD 1.5 sec 				
				local isMelee = Env.Unit("player"):IsMelee()
				local range = Env.Unit(unitID):GetRange()
				-- -10% damage reducement over 10 sec
				local isMaxRank = AzeriteRank(spellID) >= 3 
				if not ShouldStop and (
					(isMelee and range >= 10) or 
					(not isMelee and range >= 10 and range <= 25 and Env.UNITCurrentSpeed("player") > 0) or 
					(isMaxRank and (Env.Unit("player"):IsTanking(unitID, 10) or (Env.InPvP() and Env.Unit("player"):UseDeff()))) or 
					(Env.InPvP() and UnitIsPlayer(unitID) and Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):HasBuffs("DamagePhysImun") > 0 and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):WithOutKarmed())
				) then  
					return Action.HeartOfAzerothShow(icon)
				end
			end 
			
			if MajorSpellName == "Memory of Lucid Dreams" then
				-- GCD 1.5 sec
				if not ShouldStop and Env.UNITPW("player") <= 50 and (Env.Zone == "none" or Env.Unit(unitID):IsBoss() or UnitIsPlayer(unitID)) and (Env.Unit("player"):HasBuffs("DamageBuffs", true) > 0 or (Env.InPvP() and Env.Unit(unitID):UseBurst())) then 				
					-- PvP condition
					if not Env.InPvP() or not UnitIsPlayer(unitID) or (not Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):DeBuffCyclone() == 0) or (Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			--[[ Tank ]]
			if MajorSpellName == "Azeroth's Undying Gift" then
				-- GCD 0 sec
				if 	(
						-- HP lose per sec >= 15
						incdmg("player") * 100 / UnitHealthMax("player") >= 15 or 
						TimeToDieX("player", 20) <= 6 or 
						Env.UNITHP("player") < 70 or 
						(
							Env.InPvP() and 
							(
								Env.Unit("player"):UseDeff() or 
								(
									Env.Unit("player"):HasFlags() and 
									getRealTimeDMG("player") > 0 and 
									Env.Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Env.Unit("player"):HasBuffs("DeffBuffs", true) == 0
				then
					return Action.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Anima of Death" then 
				-- GCD 1.5 sec 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Env.UNITHP("player") < 70 and PredictHealing(MajorSpellName, spellID, "player") then
					-- PvP condition
					if not Env.InPvP() or not Env.EnemyTeam("HEALER"):IsBreakAble(8) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "Aegis of the Deep" then 
				-- GCD 1.5 sec
				if 	not ShouldStop and 
					(
						-- HP lose per sec taken from physical attacks >= 25
						incdmgphys("player") * 100 / UnitHealthMax("player") >= 25 or 
						TimeToDieX("player", 25) <= 4 or 
						Env.UNITHP("player") < 30 or 
						(
							Env.InPvP() and 
							(
								Env.Unit("player"):UseDeff() or 
								(
									Env.Unit("player"):HasFlags() and 
									getRealTimeDMG("player") > 0 and 
									Env.Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Env.Unit("player"):HasBuffs("DeffBuffs", true) == 0
				then
					return Action.HeartOfAzerothShow(icon)
				end 			
			end 
			
			if MajorSpellName == "Empowered Null Barrier" then 
				-- GCD 1.5 sec
				if 	not ShouldStop and 
					(
						-- If can fully absorb 
						incdmgmagic("player") * 10 >= Env.GetDescription(spellID)[1] or 
						-- If can die to 25% from magic attacks in less than 6 sec
						TimeToDieMagicX("player", 25) < 6 or 
						-- HP lose per sec >= 30 from magic attacks
						incdmgmagic("player") * 100 / UnitHealthMax("player") >= 30 or 
						-- HP < 40 and real time incoming damage from mage attacks more than 10%
						(
							Env.UNITHP("player") < 40 and 
							select(4, getRealTimeDMG("player")) > UnitHealthMax("player") * 0.1
						) or 
						(
							Env.InPvP() and
							-- Stable real time incoming damage from mage attacks more than 20%
							select(4, getRealTimeDMG("player")) > UnitHealthMax("player") * 0.2 and 							
							(
								Env.Unit("player"):UseDeff() or 
								(
									Env.Unit("player"):HasFlags() and 									
									Env.Unit("player"):IsFocused(nil, true) 
								)
							)
						)
					) and 
					Env.Unit("player"):HasBuffs("DeffBuffsMagic", true) == 0
				then
					return Action.HeartOfAzerothShow(icon)
				end
			end 
			
			if MajorSpellName == "Suppressing Pulse" then 
				-- GCD 1.5 sec
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "ARCANE") == 0 and not ShouldStop and CombatTime("player") > 3 and Env.Unit("player"):IsTanking(unitID, 8) and select(3, getRealTimeDMG("player")) > 0 then 
					if AoE(3, 15) or 
					(
						Env.InPvP() and 
						( 
							(
								UnitIsPlayer(unitID) and 
								Env.Unit(unitID):IsEnemy() and 
								Env.UNITCurrentSpeed(unitID) >= 100 and 
								Env.Unit(unitID):HasBuffs("TotalImun") == 0 and 
								Env.Unit(unitID):HasBuffs("Freedom") == 0
							) or 
							-- If someone enemy player bursting in 15 range with > 3 duration
							Env.EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", 15) > 3 
						)
					) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			--[[ Healer ]]
			if MajorSpellName == "Refreshment" then 
				-- GCD 1.5 sec 
				-- It has 100 yards range but I think it's not truth and 40 yards by UnitInRange enough 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Env.Unit(unitID):IsEnemy() and (not UnitIsPlayer(unitID) or Env.Unit(unitID):DeBuffCyclone() == 0) and UnitInRange(unitID) and PredictHealing(MajorSpellName, nil, unitID) then 
					return Action.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Standstill" then 
				-- GCD 1.5 sec 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "ARCANE") == 0 and not ShouldStop and not Env.Unit(unitID):IsEnemy() and UnitIsPlayer(unitID) and Env.Unit(unitID):DeBuffCyclone() == 0 and UnitInRange(unitID) and (TimeToDie(unitID) <= 6 or incdmg(unitID) * 4 >= Env.GetDescription(spellID)[1]) and Env.Unit(unitID):HasBuffs("TotalImun") == 0 then 
					return Action.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Life-Binder's Invocation" then 
				-- GCD 1.5 sec (this is long cast)
				-- If during latest 3 sec group AHP went down to -30%
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "HOLY") == 0 and not ShouldStop and not Env.Unit(unitID):IsEnemy() and FrequencyAHP(3) > 30 and Env.UNITCurrentSpeed("player") == 0 and (TimeToDie("player") > 9 or not Env.InPvP() or (not Env.Unit("player"):IsFocused() and Env.UNITHP("player") > 20)) then 
					return Action.HeartOfAzerothShow(icon)
				end 
			end  
			
			if MajorSpellName == "Overcharge Mana" then 
				-- GCD 1.5 sec 
				-- If unit TTD <= 16 and TTD > 6 and our mana above 35% or while heroism
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Env.Unit(unitID):IsEnemy() and (not UnitIsPlayer(unitID) or Env.Unit(unitID):DeBuffCyclone() == 0) and UnitInRange(unitID) and ((TimeToDie(unitID) <= 16 and TimeToDie(unitID) > 6 and UnitPower("player") >= UnitPowerMax("player") * 0.35) or Env.Unit("player"):HasBuffs("BurstHaste") > 0) then 
					return Action.HeartOfAzerothShow(icon)
				end 
			end 
			
			if MajorSpellName == "Vitality Conduit" then 
				-- GCD 1.5 sec 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and not ShouldStop and not Env.Unit(unitID):IsEnemy() and (not UnitIsPlayer(unitID) or Env.Unit(unitID):DeBuffCyclone() == 0) and UnitInRange(unitID) and PredictHealing(MajorSpellName, spellID, unitID) then 
					return Action.HeartOfAzerothShow(icon)
				end 
			end 
			
			--[[ Damager ]]
			if MajorSpellName == "Focused Azerite Beam" then 
				-- GCD 1.5 sec (channeled)
				if (AzeriteRank(spellID) >= 3 or Env.UNITStaying("player") >= 1) and Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):GetRange() <= 10 then 
					local isMelee = Env.Unit("player"):IsMelee()
					if (AoE(3, 10) or (isMelee and Env.InPvP() and Env.Unit(unitID):GetRange() >= 6)) and (not Env.InPvP() or (UnitIsPlayer(unitID) and not Env.EnemyTeam("HEALER"):IsBreakAble(10) and Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0) ) then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "Guardian of Azeroth" then 
				-- GCD 1.5 sec (range minion with fire attack)
				if not ShouldStop and Env.Unit(unitID):IsEnemy() then 
					local isMelee = Env.Unit("player"):IsMelee()
					if 	((not isMelee and Env.Unit(unitID):GetRange() <= 40 and Action.LossOfControlIsMissed({"SILENCE", "DISARM"})) or (isMelee and Env.Unit(unitID):GetRange() <= 10 and Action.LossOfControlIsMissed("DISARM"))) and 
						(Env.Unit("player"):HasBuffs("DamageBuffs") > 8 or Env.Unit("player"):HasBuffs("BurstHaste") > 2 or (Env.InPvP() and UnitIsPlayer(unitID) and Env.Unit(unitID):UseBurst())) and 
						(not Env.InPvP() or (UnitIsPlayer(unitID) and Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0)) 					
					then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Blood of the Enemy" then 
				-- GCD 1.5 sec 
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "SHADOW") == 0 and not ShouldStop and Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):GetRange() <= 12 then 
					local isMelee = Env.Unit("player"):IsMelee()
					if 	(not isMelee or (isMelee and Action.LossOfControlIsMissed("DISARM"))) and 
						(Env.Unit("player"):HasBuffs("DamageBuffs") > 0 or Env.Unit("player"):HasBuffs("BurstHaste") > 0 or (Env.InPvP() and UnitIsPlayer(unitID) and Env.Unit(unitID):UseBurst())) and 
						((not Env.InPvP() and AoE(4, 12)) or (UnitIsPlayer(unitID) and not Env.EnemyTeam():IsBreakAble(12) and Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0)) 					
					then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end
			end 
			
			if MajorSpellName == "Purifying Blast" then 
				-- GCD 1.5 sec 
				if not ShouldStop and Env.Unit(unitID):IsEnemy() then
					local isMelee = Env.Unit("player"):IsMelee()
					local n = Env.Zone == "arena" and 2 or 4
					if (
							(isMelee and AoE(n, 8) and (not Env.InPvP() or not Env.EnemyTeam("HEALER"):IsBreakAble(8))) or 
							(not isMelee and CombatUnits(n + 1, 40) and (not Env.InPvP() or not Env.EnemyTeam("HEALER"):IsBreakAble(40)))  
					   ) 
					then 
						return Action.HeartOfAzerothShow(icon)
					end 
				end 
			end 
			
			if MajorSpellName == "The Unbound Force" then 
				-- GCD 1.5 sec (filler)
				if Action.LossOfControlIsMissed("SILENCE") and LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and not ShouldStop and Env.Unit(unitID):IsEnemy() and Env.SpellInRange(unitID, spellID) then
					if not Env.InPvP() or (not Env.Unit(unitID):IsTotem() and (not UnitIsPlayer(unitID) or (Env.Unit(unitID):WithOutKarmed() and Env.Unit(unitID):HasBuffs("TotalImun") == 0 and Env.Unit(unitID):HasBuffs("DamageMagicImun") == 0))) then 
						return Action.HeartOfAzerothShow(icon)
					end
				end 
			end 
			
		end 		
	end 
	
	return false 
end 

-------------------------------------
-- ACTION API
--------------------------------------
function Action:CreateEssencesFor(specID) 
	-- If game patch lower than 8.2 it will create empty objects which will be hidden in UI 
	for k, v in pairs(AzeriteEssences.ALL) do 
		self[specID][k] = self.Create(AzeriteEssence and v or nil)
	end 

	for k, v in pairs(AzeriteEssences[GetSpecializationRoleByID(specID)]) do 
		self[specID][k] = self.Create(AzeriteEssence and v or nil)
	end 	 
end 

function Action:AutoHeartOfAzeroth(unitID, skipAuto)
	-- @return boolean 
	-- Note: This is lazy template for all Heart Of Azerote Essences 
	-- Arguments: skipAuto if true then will skip Auto template conditions and will check only validance (imun, own CC such as silence, range and etc)	
	if self.SubType == "HeartOfAzeroth" and AzeriteEssenceIsMajorUseable() and Action.GetToggle(1, "HeartOfAzeroth") then 
		local Major = AzeriteEssenceGetMajor()
		local MajorSpellName = GetMajorBySpellName[Major.spellName]
		
		if MajorSpellName and Major and Major.spellName == self:Info() then 
			self.ID = Major.spellID
			local ShouldStop = Action.ShouldStop()
			
			--[[ Essences Used by All Roles ]]
			if MajorSpellName == "Concentrated Flame" then 				
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1 sec 
					self:IsReady(unitID) and -- no second arg as 'true' coz it checking range 
					Action.LossOfControlIsMissed("SILENCE") and 
					LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 
				then 
					local isEnemy = Env.Unit(unitID):IsEnemy()
					
					if 	(
							IsEnemy or 
							PredictHealing(MajorSpellName, self.ID, unitID)
						) and 
						(
							(
								not isEnemy and 
								self:AbsentImun(unitID) 
							) or 
							(
								isEnemy and 
								self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"})
							)
						)
					then
						return true 
					end 
				end 
			end 
			
			if MajorSpellName == "Worldvein Resonance" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) and 
					(
						skipAuto or 
						((not Env.Unit("player"):IsMelee() and Env.Unit(unitID):GetRange() <= 40) or Env.Unit(unitID):GetRange() <= 8)
					) and 
					(	
						not Env.Unit(unitID):IsEnemy() or						
						self:AbsentImun(unitID, {"TotalImun", "DamagePhysImun", "DamageMagicImun"})
					)
				then 
					return true 					
				end 					
			end 
			
			if MajorSpellName == "Ripple in Space" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) 
				then
					if skipAuto then 
						return true 
					else
						local isMelee = Env.Unit("player"):IsMelee()
						local range = Env.Unit(unitID):GetRange()
						-- -10% damage reducement over 10 sec
						local isMaxRank = AzeriteRank(self.ID) >= 3
						
						if 	(isMelee and range >= 10) or 
							(not isMelee and range >= 10 and range <= 25 and Env.UNITCurrentSpeed("player") > 0) or 
							(isMaxRank and (Env.Unit("player"):IsTanking(unitID, 10) or (Env.InPvP() and Env.Unit("player"):UseDeff()))) or 
							(Env.InPvP() and UnitIsPlayer(unitID) and Env.Unit(unitID):IsEnemy() and Env.Unit(unitID):HasBuffs("DamagePhysImun") > 0 and self:AbsentImun(unitID, "TotalImun"))							 
						then  
							return true 
						end 
					end 
				end 
			end 
			
			if MajorSpellName == "Memory of Lucid Dreams" then
				if not unitID then 
					unitID = "target"
				end 
				
				if	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) and 
					(
						skipAuto or 
						Env.UNITPW("player") <= 50
					) 
				then 
					local isEnemy = Env.Unit(unitID):IsEnemy()
					
					if	(
							not isEnemy and 
							self:AbsentImun(unitID)
						) or 
						(
							isEnemy and 
							self:AbsentImun(unitID, "TotalImun")
						)					
					then
						return true 
					end 
				end 
			end 
			
			--[[ Tank ]]
			if MajorSpellName == "Azeroth's Undying Gift" then				
				unitID = "player"				
				
				-- GCD 0 sec
				if 	self:IsReady(unitID, true) and 
					(
						skipAuto or
						(
							(
								-- HP lose per sec >= 15
								incdmg(unitID) * 100 / UnitHealthMax(unitID) >= 15 or 
								TimeToDieX(unitID, 20) <= 6 or 
								Env.UNITHP(unitID) < 70 or 
								(
									Env.InPvP() and 
									(
										Env.Unit(unitID):UseDeff() or 
										(
											Env.Unit(unitID):HasFlags() and 
											getRealTimeDMG(unitID) > 0 and 
											Env.Unit(unitID):IsFocused(nil, true) 
										)
									)
								) 
							) and 
							Env.Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					) 
				then
					return true
				end 
			end 
			
			if MajorSpellName == "Anima of Death" then
				unitID = "player"				
				
				if 	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) and 					
					Action.LossOfControlIsMissed("SILENCE") and 
					LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and
					PredictHealing(MajorSpellName, self.ID, unitID) and 
					(
						skipAuto or 
						Env.UNITHP(unitID) < 70
					) and 
					(
						not Env.InPvP() or
						not Env.EnemyTeam("HEALER"):IsBreakAble(8)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Aegis of the Deep" then 
				unitID = "player"				
				
				if 	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) and 					
					(
						skipAuto or 
						(
							(
								-- HP lose per sec taken from physical attacks >= 25
								incdmgphys(unitID) * 100 / UnitHealthMax(unitID) >= 25 or 
								TimeToDieX(unitID, 25) <= 4 or 
								Env.UNITHP(unitID) < 30 or 
								(
									Env.InPvP() and 
									(
										Env.Unit(unitID):UseDeff() or 
										(
											Env.Unit(unitID):HasFlags() and 
											getRealTimeDMG(unitID) > 0 and 
											Env.Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							Env.Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					)
				then 
					return true 
				end 						
			end 
			
			if MajorSpellName == "Empowered Null Barrier" then 
				unitID = "player"				
				
				if 	not ShouldStop and -- GCD 1.5 sec 
					self:IsReady(unitID, true) and 					
					(
						skipAuto or 
						(
							(
								-- If can fully absorb 
								incdmgmagic(unitID) * 10 >= Env.GetDescription(self.ID)[1] or 
								-- If can die to 25% from magic attacks in less than 6 sec
								TimeToDieMagicX(unitID, 25) < 6 or 
								-- HP lose per sec >= 30 from magic attacks
								incdmgmagic(unitID) * 100 / UnitHealthMax(unitID) >= 30 or 
								-- HP < 40 and real time incoming damage from mage attacks more than 10%
								(
									Env.UNITHP(unitID) < 40 and 
									select(4, getRealTimeDMG(unitID)) > UnitHealthMax(unitID) * 0.1
								) or 
								(
									Env.InPvP() and
									-- Stable real time incoming damage from mage attacks more than 20%
									select(4, getRealTimeDMG(unitID)) > UnitHealthMax(unitID) * 0.2 and 							
									(
										Env.Unit(unitID):UseDeff() or 
										(
											Env.Unit(unitID):HasFlags() and 									
											Env.Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							Env.Unit("player"):HasBuffs("DeffBuffsMagic", true) == 0						
						)
					)
				then
					return true 
				end 
			end 
			
			if MajorSpellName == "Suppressing Pulse" then 
				if not unitID or unitID == "player" then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					Action.LossOfControlIsMissed("SILENCE") and 
					LossOfControlGet("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					(
						(
							skipAuto and 
							AoE(1, 15)
						) or 
						(
							not skipAuto and 
							Env.Unit("player"):IsTanking(unitID, 8) and 
							select(3, getRealTimeDMG("player")) > 0 and 
							(
								(
									Env.InPvP() and 
									( 
										(
											UnitIsPlayer(unitID) and 
											Env.Unit(unitID):IsEnemy() and 
											Env.UNITCurrentSpeed(unitID) >= 100 and 
											self:AbsentImun(unitID, {"TotalImun", "Freedom"}, true)
										) or 
										-- If someone enemy player bursting in 15 range with > 3 duration
										Env.EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", 15) > 3 
									)
								) or 
								AoE(3, 15)
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			--[[ Healer ]]
			if MajorSpellName == "Refreshment" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					UnitInRange(unitID) and  -- It has 100 yards range but I think it's not truth and 40 yards by UnitInRange enough 
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					PredictHealing(MajorSpellName, self.ID, unitID)					
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Standstill" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					UnitIsPlayer(unitID) and 
					UnitInRange(unitID) and
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					not Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, "TotalImun") and 
					(
						skipAuto or 
						(TimeToDie(unitID) <= 6 or incdmg(unitID) * 4 >= Env.GetDescription(self.ID)[1])
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Life-Binder's Invocation" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					UnitIsPlayer(unitID) and 
					UnitInRange(unitID) and
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "HOLY") == 0 and
					Env.UNITCurrentSpeed("player") == 0 and 
					not Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 					
					(
						skipAuto or 
						(
							FrequencyAHP(3) > 30 and 
							TimeToDie(unitID) > 8 
						)
					)
				then 
					return true 
				end 
			end  
			
			if MajorSpellName == "Overcharge Mana" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					UnitInRange(unitID) and
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not Env.Unit(unitID):IsEnemy() and
					self:AbsentImun(unitID) and 
					(
						skipAuto or 
						(
							Env.Unit("player"):HasBuffs("BurstHaste") > 0 or 
							(
								TimeToDie(unitID) > 8 and 
								UnitPower("player") >= UnitPowerMax("player") * 0.2 and 
								incdmg(unitID) * 1.2 > getHPS("player")
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Vitality Conduit" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					UnitInRange(unitID) and
					Action.LossOfControlIsMissed("SILENCE") and 
					LossOfControlGet("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					redictHealing(MajorSpellName, self.ID, unitID)
				then 
					return true 
				end 
			end 
			
			--[[ Damager ]]
			if MajorSpellName == "Focused Azerite Beam" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec (channeled)				
					(
						AzeriteRank(self.ID) >= 3 or 
						Env.UNITStaying("player") >= 1
					) and 
					self:IsReady(unitID, true) and 
					Action.LossOfControlIsMissed("SILENCE") and 
					LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					Env.Unit(unitID):IsEnemy() and
					Env.Unit(unitID):GetRange() <= 10 and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					(
						not Env.InPvP() or 
						not Env.EnemyTeam("HEALER"):IsBreakAble(10)
					) and 
					not Env.Unit(unitID):IsTotem() and 
					(
						skipAuto or 
						(
							(
								AoE(2, 10) or 
								(
									Env.InPvP() and 
									Env.Unit("player"):IsMelee() and 
									Env.Unit(unitID):GetRange() >= 6
								)
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Guardian of Azeroth" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec (range minion with fire attack)
					self:IsReady(unitID, true) and 
					Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not Env.Unit(unitID):IsTotem() and 
					(
						(
							Env.Unit("player"):IsMelee() and 
							Env.Unit(unitID):GetRange() <= 10 and 
							Action.LossOfControlIsMissed("DISARM")
						) or 
						(
							not Env.Unit("player"):IsMelee() and 
							Env.Unit(unitID):GetRange() <= 40 and 
							Action.LossOfControlIsMissed({"SILENCE", "DISARM"})
						)
					)  
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Blood of the Enemy" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "SHADOW") == 0 and 
					Env.Unit(unitID):IsEnemy() and 
					Env.Unit(unitID):GetRange() <= 12 and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not Env.Unit(unitID):IsTotem() and 
					(
						not Env.Unit("player"):IsMelee() or 
						Action.LossOfControlIsMissed("DISARM")
					) and 
					(
						not Env.InPvP() or 
						not Env.EnemyTeam():IsBreakAble(12)
					) and 
					(
						skipAuto or 
						Env.InPvP() or
						AoE(2, 12)
					)
				then 
					return true  
				end 
			end 
			
			if MajorSpellName == "Purifying Blast" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID, true) and 
					Env.Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not Env.Unit(unitID):IsTotem()
				then 
					local isMelee = Env.Unit("player"):IsMelee()
					local n = Env.Zone == "arena" and 2 or 4
					
					if	(
							isMelee and 
							(
								not Env.InPvP() or 
								not Env.EnemyTeam("HEALER"):IsBreakAble(8)
							) and 
							(
								skipAuto or 
								AoE(n, 8)
							)
						) or 
						(
							not isMelee and 
							(
								not Env.InPvP() or 
								not Env.EnemyTeam("HEALER"):IsBreakAble(40)
							) and 
							(
								skipAuto or 
								CombatUnits(n + 1, 40)
							)
						)
					then 
						return true 
					end 
				end 
			end 
			
			if MajorSpellName == "The Unbound Force" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not ShouldStop and -- GCD 1.5 sec
					self:IsReady(unitID) and -- no second arg as 'true' coz it checking range 
					Env.Unit(unitID):IsEnemy() and 
					Action.LossOfControlIsMissed("SILENCE") and
					LossOfControlGet("SCHOOL_INTERRUPT", "FIRE") == 0 and
					self:AbsentImun(unitID, {"TotalImun", "DamageMagicImun"}) and 
					not Env.Unit(unitID):IsTotem()
				then 
					return true 
				end 
			end 
			
		end 		
	end 
	
	return false 
end 

function Action:AutoHeartOfAzerothP(unit)
	-- @return boolean 
	-- Note: Just will check validance
	return self:AutoHeartOfAzeroth(unit, true)
end 