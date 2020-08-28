local _G, pairs, next, math				=
	  _G, pairs, next, math
	  
local math_max							= math.max	  
	  
local TMW 								= _G.TMW
local A 								= _G.Action
local CONST 							= A.Const

local Listener							= A.Listener
local GetToggle							= A.GetToggle

local TeamCache							= A.TeamCache
local TeamCacheFriendly 				= TeamCache.Friendly
local TeamCacheFriendlyHEALER			= TeamCacheFriendly.HEALER
local TeamCacheFriendlyIndexToPLAYERs	= TeamCacheFriendly.IndexToPLAYERs

local Azerite 							= _G.LibStub("AzeriteTraits")

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_LoC, A_Unit, A_EnemyTeam, A_MultiUnits, A_HealingEngine, A_Player

Listener:Add("ACTION_EVENT_HEARTOFAZEROTH", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_LoC						= A.LossOfControl
		A_Unit						= A.Unit
		A_EnemyTeam					= A.EnemyTeam
		A_MultiUnits				= A.MultiUnits
		A_HealingEngine				= A.HealingEngine
		A_Player					= A.Player
		
		Listener:Remove("ACTION_EVENT_HEARTOFAZEROTH", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------
	  
local CopyTable						= _G.CopyTable 	  
local UnitIsUnit					= _G.UnitIsUnit	  
local GetSpecializationRoleByID 	= _G.GetSpecializationRoleByID
local AzeriteEssence 				= _G.C_AzeriteEssence
local AzeriteEssences 				= {
	ALL = {
		ConcentratedFlame 			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.ConcentratedFlame 		}, -- filler (40y, low priority) HPS / DPS 
		WorldveinResonance			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.WorldveinResonance 		}, -- filler (small stat burst, cd1min, high priority)
		RippleinSpace				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.RippleinSpace 			}, -- movement / -10% deffensive (x3 rank)
		MemoryofLucidDreams			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.MemoryofLucidDreams 	}, -- burst (100% power regeneration)
	},
	TANK = {
		AzerothsUndyingGift			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AzerothsUndyingGift 	}, -- -20% 4sec cd1min / -40% 2sec and then -20% 2sec cd45sec
		AnimaofDeath				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AnimaofDeath 			}, -- aoe self heal cd2.5-2min
		AegisoftheDeep				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.AegisoftheDeep 			}, -- physical attack protection cd2-1.5min
		EmpoweredNullBarrier		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.EmpoweredNullBarrier 	}, -- magic attack protection cd3-2.3min
		SuppressingPulse			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.SuppressingPulse 		}, -- aoe -70% slow and -25% attack speed cd60-45sec
	},
	HEALER = {
		Refreshment					= { Type = "HeartOfAzeroth", ID = Azerite.CONST.Refreshment 			}, -- filler cd15sec
		Standstill					= { Type = "HeartOfAzeroth", ID = Azerite.CONST.Standstill 				}, -- burst (big absorb incoming dmg and hps) cd3min
		LifeBindersInvocation		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.LifeBindersInvocation 	}, -- burst aoe (big heal) cd3min
		OverchargeMana				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.OverchargeMana 			}, -- filler (my hps < incoming unit dps) cd30sec
		VitalityConduit				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.VitalityConduit 		}, -- aoe cd60-45sec 
	},	
	DAMAGER = {
		FocusedAzeriteBeam			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.FocusedAzeriteBeam 		}, -- aoe 
		GuardianofAzeroth			= { Type = "HeartOfAzeroth", ID = Azerite.CONST.GuardianofAzeroth 		}, -- burst 
		BloodoftheEnemy				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.BloodoftheEnemy 		}, -- aoe 
		PurifyingBlast				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.PurifyingBlast 			}, -- filler (aoe, high priority)
		TheUnboundForce				= { Type = "HeartOfAzeroth", ID = Azerite.CONST.TheUnboundForce 		}, -- filler (high priority)
	},
}

-- Push 8.3 new essences 
if Azerite.has_8_3_0 then 
	AzeriteEssences.ALL.ReplicaofKnowledge 		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.ReplicaofKnowledge 		}  -- replicate the target current major essence slot giving us R1 or R2 or R3 depending of our current essence rank 
	AzeriteEssences.TANK.VigilantProtector		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.VigilantProtector 		}  -- mass taunt 8 yards 
	AzeriteEssences.HEALER.SpiritofPreservation	= { Type = "HeartOfAzeroth", ID = Azerite.CONST.SpiritofPreservation	}  -- aoe friendly heal 
	AzeriteEssences.HEALER.GuardianShell		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.GuardianShell			}  -- aoe friendly absorb 	 - release 12 protective spheres outward over 4 sec, granting the first ally to touch it a barrier that absorbs X damage for 10 sec
	AzeriteEssences.DAMAGER.MomentofGlory		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.MomentofGlory			}  -- aoe friendly burst 	 - release wave of energy on ally near 15yrd that boost their damage essence by 45%
	AzeriteEssences.DAMAGER.ReapingFlames		= { Type = "HeartOfAzeroth", ID = Azerite.CONST.ReapingFlames			}  -- filler (high priority) - damage the target, if the target has < 20% health then cooldown is reduced by 30sec
end 

local Temp							= {
	TotalAndMagic					= {"TotalImun", "DamageMagicImun"},
	TotalAndFreedom					= {"TotalImun", "Freedom"},
	TotalAndMagicAndPhys			= {"TotalImun", "DamageMagicImun", "DamagePhysImun"},
	MemoryofLucidDreamsSpecs		= {66, 70, 263, 265, 266, 267, 62, 63, 64, 102, 258},
	SilenceAndDisarm				= {"SILENCE", "DISARM"},
}

local TempTotalAndMagic				= Temp.TotalAndMagic
local TempTotalAndFreedom 			= Temp.TotalAndFreedom
local TempTotalAndMagicAndPhys 		= Temp.TotalAndMagicAndPhys
local TempMemoryofLucidDreamsSpecs	= Temp.MemoryofLucidDreamsSpecs
local TempSilenceAndDisarm			= Temp.SilenceAndDisarm

-------------------------------------
-- API
--------------------------------------
function A:CreateEssencesFor(specID) 
	-- If game patch lower than 8.2 it will create empty objects which will be hidden in UI 
	for k, v in pairs(AzeriteEssences.ALL) do 
		self[specID][k] = self.Create(AzeriteEssence and CopyTable(v) or nil)
	end 

	for k, v in pairs(AzeriteEssences[GetSpecializationRoleByID(specID)]) do 
		self[specID][k] = self.Create(AzeriteEssence and CopyTable(v) or nil)
	end 	 
end 

function A:IsEssenceUseable()
	-- @return boolean (if Major essence has active spell and it's selected on character)
	return Azerite:EssenceIsMajorUseable(self.ID) 
end 

function A:AutoHeartOfAzeroth(unitID, skipShouldStop, skipAuto)
	-- @return boolean 
	-- Note: This is lazy template for all Heart Of Azerote Essences 
	-- Arguments: skipAuto if true then will skip AUTO template conditions and will check only validance (imun, own CC such as silence, range and etc)	
	if self.SubType == "HeartOfAzeroth" and Azerite:EssenceIsMajorUseable() and GetToggle(1, "HeartOfAzeroth") then 
		local MajorSpellName 	= Azerite:EssenceGetMajorBySpellNameOnENG(Azerite:EssenceGetMajor().spellName)
		
		if MajorSpellName and Azerite:EssenceGetMajor().spellName == self:Info() then 
			if self.ID ~= Azerite:EssenceGetMajor().spellID then 
				self.ID 		= Azerite:EssenceGetMajor().spellID
			end 
			
			--[[ Essences Used by All Roles ]]
			if MajorSpellName == "Concentrated Flame" then 				
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it checking range 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 
				then 
					local isEnemy = A_Unit(unitID):IsEnemy()
					
					if 	(
							IsEnemy or 
							Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)
						) and 
						(
							(
								not isEnemy and 
								self:AbsentImun(unitID) 
							) or 
							(
								isEnemy and 
								self:AbsentImun(unitID, TempTotalAndMagic)
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
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or 
						((not A_Unit("player"):IsMelee() and A_Unit(unitID):GetRange() <= 40) or A_Unit(unitID):GetRange() <= 12)
					) and 
					(	
						not A_Unit(unitID):IsEnemy() or						
						self:AbsentImun(unitID, TempTotalAndMagicAndPhys)
					)
				then 
					return true 					
				end 					
			end 
			
			if MajorSpellName == "Ripple in Space" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if self:IsReady(unitID, true, nil, skipShouldStop) then
					if skipAuto then 
						return true 
					else
						local isMelee 	= A_Unit("player"):IsMelee()
						local range 	= A_Unit(unitID):GetRange()
						-- -10% damage reducement over 10 sec
						local isMaxRank = self:GetAzeriteRank() >= 3
						
						if 	(isMelee and range >= 10) or 
							(not isMelee and range >= 10 and range <= 25 and A_Unit("player"):GetCurrentSpeed() > 0) or 
							(isMaxRank and (A_Unit("player"):IsTanking(unitID, 10) or (A.IsInPvP and A_Unit("player"):UseDeff()))) or 
							(A.IsInPvP and A_Unit(unitID):IsPlayer() and A_Unit(unitID):IsEnemy() and A_Unit(unitID):HasBuffs("DamagePhysImun") > 0 and self:AbsentImun(unitID, "TotalImun"))							 
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
				
				if	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or 
						-- Note: Retribution, Protection, Elemental, Warlock, Mage, Balance, Shadow an exception for power check 
						A_Unit("player"):HasSpec(TempMemoryofLucidDreamsSpecs) or
						A_Unit("player"):PowerPercent() <= 50
					) 
				then 
					local isEnemy = A_Unit(unitID):IsEnemy()
					
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
			
			if MajorSpellName == "Replica of Knowledge" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	not UnitIsUnit(unitID, "player") and
					self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it checking range 
					A_Player:IsStaying() and 
					A_Unit(unitID):IsPlayer() and 
					A_Unit(unitID):GetLevel() >= A.PlayerLevel and
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					(
						skipAuto or 
						(
							A_Unit("player"):CombatTime() > 0 and 
							(
								(A_Unit("player"):IsDamager() and A_Unit(unitID):IsDamager()) or 
								(A_Unit("player"):IsHealer() and (A_Unit(unitID):IsHealer() or (not next(TeamCacheFriendlyHEALER) and A_Unit(unitID):IsDamager())) and A_Unit(unitID):TimeToDie() > 10) or
								(A_Unit("player"):IsTank() and (A_Unit(unitID):IsHealer() or A_Unit(unitID):IsTank()))
							)
						)
					) and 
					self:AbsentImun(unitID) 
				then
					return true
				end 
			end 
			
			--[[ Tank ]]
			if MajorSpellName == "Azeroth's Undying Gift" then				
				unitID = "player"				
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					(
						skipAuto or
						(
							(
								-- HP lose per sec >= 15
								A_Unit(unitID):GetDMG() * 100 / math_max(A_Unit(unitID):HealthMax(), 1) >= 15 or 
								A_Unit(unitID):TimeToDieX(20) <= 6 or 
								A_Unit(unitID):HealthPercent() < 70 or 
								(
									A.IsInPvP and 
									(
										A_Unit(unitID):UseDeff() or 
										(
											A_Unit(unitID):HasFlags() and 
											A_Unit(unitID):GetRealTimeDMG() > 0 and 
											A_Unit(unitID):IsFocused(nil, true) 
										)
									)
								) 
							) and 
							A_Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					) 
				then
					return true
				end 
			end 
			
			if MajorSpellName == "Anima of Death" then
				unitID = "player"				
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 					
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID) and 
					(
						skipAuto or 
						A_Unit(unitID):HealthPercent() < 70
					) and 
					(
						not A.IsInPvP or
						not A_EnemyTeam("HEALER"):IsBreakAble(8)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Aegis of the Deep" then 
				unitID = "player"				
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 					
					(
						skipAuto or 
						(
							(
								-- HP lose per sec taken from physical attacks >= 25
								A_Unit(unitID):GetDMG(3) * 100 / math_max(A_Unit(unitID):HealthMax(), 1) >= 25 or 
								A_Unit(unitID):TimeToDieX(25) <= 4 or 
								A_Unit(unitID):HealthPercent() < 30 or 
								(
									A.IsInPvP and 
									(
										A_Unit(unitID):UseDeff() or 
										(
											A_Unit(unitID):HasFlags() and 
											A_Unit(unitID):GetRealTimeDMG() > 0 and 
											A_Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							A_Unit(unitID):HasBuffs("DeffBuffs", true) == 0
						)
					)
				then 
					return true 
				end 						
			end 
			
			if MajorSpellName == "Empowered Null Barrier" then 
				unitID = "player"				
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 					
					(
						skipAuto or 
						(
							(
								-- If can fully absorb 
								A_Unit(unitID):GetDMG(4) * 10 >= self:GetSpellDescription()[1] or 
								-- If can die to 25% from magic attacks in less than 6 sec
								A_Unit(unitID):TimeToDieMagicX(25) < 6 or 
								-- HP lose per sec >= 30 from magic attacks
								A_Unit(unitID):GetDMG(4) * 100 / math_max(A_Unit(unitID):HealthMax(), 1) >= 30 or 
								-- HP < 40 and real time incoming damage from mage attacks more than 10%
								(
									A_Unit(unitID):HealthPercent() < 40 and 
									A_Unit(unitID):GetRealTimeDMG(4) > A_Unit(unitID):HealthMax() * 0.1
								) or 
								(
									A.IsInPvP and
									-- Stable real time incoming damage from mage attacks more than 20%
									A_Unit(unitID):GetRealTimeDMG(4) > A_Unit(unitID):HealthMax() * 0.2 and 							
									(
										A_Unit(unitID):UseDeff() or 
										(
											A_Unit(unitID):HasFlags() and 									
											A_Unit(unitID):IsFocused(nil, true) 
										)
									)
								)
							) and 
							A_Unit(unitID):HasBuffs("DeffBuffsMagic", true) == 0						
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
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					(
						(
							skipAuto and 
							A_MultiUnits:GetByRange(15, 1) >= 1						
						) or 
						(
							not skipAuto and 
							A_Unit("player"):IsTanking(unitID, 8) and 
							A_Unit("player"):GetRealTimeDMG(3) > 0 and 
							(
								(
									A.IsInPvP and 
									( 
										(
											A_Unit(unitID):IsPlayer() and 
											A_Unit(unitID):IsEnemy() and 
											A_Unit(unitID):GetCurrentSpeed() >= 100 and 
											self:AbsentImun(unitID, TempTotalAndFreedom, true)
										) or 
										-- If someone enemy player bursting in 15 range with > 3 duration
										A_EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", 15) > 3 
									)
								) or 
								A_MultiUnits:GetByRange(15, 3) >= 3
							)
						)
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Vigilant Protector" then 
				if 	self:IsReady(unitID or "player", true, nil, skipShouldStop) and 
					(						
						skipAuto or
						(
							A_Unit("player"):CombatTime() >= 5 and
							A_MultiUnits:GetByRangeTaunting(8, 3, 10) >= 3
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
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):InRange() and  -- It has 100 yards range but I think it's not truth and 40 yards is enough 
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)					
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Standstill" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):IsPlayer() and 
					A_Unit(unitID):InRange() and
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and
					not A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, "TotalImun") and 
					(
						skipAuto or 
						(A_Unit(unitID):TimeToDie() <= 6 or A_Unit(unitID):GetDMG() * 4 >= self:GetSpellDescription()[1])
					)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Life-Binder's Invocation" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if  self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):IsPlayer() and 
					A_Unit(unitID):InRange() and 
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "HOLY") == 0 and
					A_Unit("player"):GetCurrentSpeed() == 0 and 
					not A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 					
					(
						skipAuto or 
						(
							A_HealingEngine.GetHealthFrequency(3) < -30 and 
							A_Unit(unitID):TimeToDie() > 8 
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
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):InRange() and 
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A_Unit(unitID):IsEnemy() and
					self:AbsentImun(unitID) and 
					(
						skipAuto or 
						(
							A_Unit("player"):HasBuffs("BurstHaste") > 0 or 
							(
								A_Unit(unitID):TimeToDie() > 8 and 
								A_Unit("player"):PowerPercent() >= 20 and 
								A_Unit(unitID):GetDMG() * 1.2 > A_Unit("player"):GetHPS()
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
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):InRange() and 				
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and
					not A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID) and 
					Azerite:EssencePredictHealing(MajorSpellName, self.ID, unitID)
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Spirit of Preservation" then 
				if 	A_Player:IsStayingTime() > 0.7 and 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and 
					A_Unit("player"):CombatTime() > 0 and		
					(
						skipAuto or 
						(
							A_Unit(unitID or "target"):TimeToDie() > 8 and 
							A_HealingEngine.HealingBySpiritofPreservation(self, A_HealingEngine.GetMinimumUnits(2, 5), skipShouldStop) >= A_HealingEngine.GetMinimumUnits(2, 5)
						)
					)
				then 
					return true 
				end 
			end
			
			if MajorSpellName == "Guardian Shell" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 				
					A_Player:IsStayingTime() > 0.7 and 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					A_Unit("player"):CombatTime() > 0 and		
					A_Unit(unitID):InRange() and
					(						
						skipAuto or 
						(								
							A_Unit(unitID):TimeToDie() > 14 and 
							(
								A_HealingEngine.GetTimeToFullDie() < 12 or 
								(
									A_HealingEngine.GetHealthFrequency(3) < -25 and 
									A_HealingEngine.GetIncomingDMGAVG() >= 15
								)
							)
						)
					)
				then 
					return true 
				end 			
			end 
			
			--[[ Damager ]]
			if MajorSpellName == "Focused Azerite Beam" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	A_Unit("player"):CombatTime() > 2 and
					(
						self:GetAzeriteRank() >= 3 or 
						A_Unit("player"):IsStayingTime() >= 1
					) and 
					self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					A_Unit(unitID):IsEnemy() and
					A_Unit(unitID):GetRange() <= 10 and 
					A_MultiUnits:GetByRange(10, 3) >= 3 and
					self:AbsentImun(unitID, TempTotalAndMagic) and 
					(
						not A.IsInPvP or 
						not A_EnemyTeam("HEALER"):IsBreakAble(10)
					) and 
					not A_Unit(unitID):IsTotem() 
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Guardian of Azeroth" then 
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, TempTotalAndMagic) and 
					not A_Unit(unitID):IsTotem() and 
					(
						(
							A_Unit("player"):IsMelee() and 
							A_Unit(unitID):GetRange() <= 10 and 
							A_LoC:IsMissed("DISARM")
						) or 
						(
							not A_Unit("player"):IsMelee() and 
							A_Unit(unitID):GetRange() <= 40 and 
							A_LoC:IsMissed(TempSilenceAndDisarm)
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
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and 
					A_Unit(unitID):IsEnemy() and 
					A_Unit(unitID):GetRange() <= 12 and 
					self:AbsentImun(unitID, TempTotalAndMagic) and 
					not A_Unit(unitID):IsTotem() and 
					(
						not A_Unit("player"):IsMelee() or 
						A_LoC:IsMissed("DISARM")
					) and 
					(
						not A.IsInPvP or 
						not A_EnemyTeam():IsBreakAble(12)
					) and 
					(
						skipAuto or 
						A.IsInPvP or
						A_MultiUnits:GetByRange(12, 2) >= 2
					)
				then 
					return true  
				end 
			end 
			
			if MajorSpellName == "Purifying Blast" then
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, true, nil, skipShouldStop) and 
					A_Unit(unitID):IsEnemy() and 
					self:AbsentImun(unitID, TempTotalAndMagic) and 
					not A_Unit(unitID):IsTotem()
				then 
					local isMelee = A_Unit("player"):IsMelee()
					local n = A.Zone == "arena" and 2 or 4
					
					if	(
							isMelee and 
							(
								not A.IsInPvP or 
								not A_EnemyTeam("HEALER"):IsBreakAble(8)
							) and 
							(
								skipAuto or 
								A_MultiUnits:GetByRange(8, n) >= n
							)
						) or 
						(
							not isMelee and 
							(
								not A.IsInPvP or 
								not A_EnemyTeam("HEALER"):IsBreakAble(40)
							) and 
							(
								skipAuto or 
								A_MultiUnits:GetByRangeInCombat(40, n + 1) >= n + 1
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
				
				if 	self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it's checking range 
					A_Unit(unitID):IsEnemy() and 
					A_LoC:IsMissed("SILENCE") and
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and
					self:AbsentImun(unitID, TempTotalAndMagic) and 
					not A_Unit(unitID):IsTotem()
				then 
					return true 
				end 
			end 
			
			if MajorSpellName == "Moment of Glory" then 
				-- Note: Need some tweaks regarding used essences by members probably or not - have to think how to play with it, no auto template right now e.g. use on CD on bosses / players usually
				if self:IsReady("player", true, nil, skipShouldStop) and A_Player:IsStaying() and A_LoC:IsMissed("SILENCE") and A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and (skipAuto or A_Unit("player"):CombatTime() > 0) then 
					local member
					for i = 1, TeamCacheFriendly.MaxSize do
						member = TeamCacheFriendlyIndexToPLAYERs[i]						
						if member and A_Unit(member):InRange() then 
							if A_Unit(member):HasBuffs(self.ID) > 0 then 
								return false 
							end 
							
							if A_Unit(member):GetLevel() >= A.PlayerLevel then
								return true
							end 
						end 
					end 
				end 
			end 
			
			if MajorSpellName == "Reaping Flames" then 				
				if not unitID then 
					unitID = "target"
				end 
				
				if 	self:IsReady(unitID, nil, nil, skipShouldStop) and -- no second arg as 'true' coz it checking range 
					A_LoC:IsMissed("SILENCE") and 
					A_LoC:Get("SCHOOL_INTERRUPT", "FIRE") == 0 and 
					self:AbsentImun(unitID, TempTotalAndMagic) 
				then 
					if skipAuto then 
						return true
					end 
										
					local TTD20					= A_Unit(unitID):TimeToDieX(20)
					-- Note: Don't use if
					if TTD20 > 0 and TTD20 <= 30 and (Azerite:GetRank(self.ID) < 2 or A_Unit(unitID):HealthPercent() < 80) then 
						return false 
					end 

					return true 
				end 
			end 
		end 		
	end 
	
	return false 
end 

function A:AutoHeartOfAzerothP(unitID, skipShouldStop)
	-- @return boolean 
	-- Note: No AUTO template 
	return self:AutoHeartOfAzeroth(unitID, skipShouldStop, true)
end 

--------------------------------------
-- Azerite 
--------------------------------------
function A:IsAzeriteEnabled()
	-- @return boolean 
	return Azerite:GetRank(self.ID) > 0
end 

function A:GetAzeriteRank()
	-- @return number (0 - is not exists)
	return Azerite:GetRank(self.ID)
end 