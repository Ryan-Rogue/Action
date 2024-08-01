local _G, error, ipairs, select, error	= _G, error, ipairs, select, error 
	  
local TMW 								= _G.TMW
local A 								= _G.Action
local Covenant 							= _G.LibStub("Covenant")
local CopyTable							= _G.CopyTable 	  
local tContains							= _G.tContains

local IsIndoors							= _G.IsIndoors
local UnitIsUnit						= _G.UnitIsUnit
local UIParent							= _G.UIParent
local CreateFrame						= _G.CreateFrame
--local GetItemInfo						= _G.GetItemInfo or _G.C_Item.GetItemInfo
--local Item							= _G.Item

local CONST 							= A.Const
local Print								= A.Print 
local GetToggle							= A.GetToggle
local Listener							= A.Listener
local LoC								= A.LossOfControl
local BurstIsON							= A.BurstIsON
local AuraIsValid						= A.AuraIsValid
local InstanceInfo						= A.InstanceInfo
local playerClass						= A.PlayerClass

local useDebug							= false 

local MultiUnits, Unit, Player, HealingEngine, EnemyTeam, FriendlyTeam, GetGCD, GetCurrentGCD, GetLatency, GetSpellInfo, Create
Listener:Add("ACTION_EVENT_COVENANT", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		MultiUnits						= A.MultiUnits	
		Unit							= A.Unit	
		Player 							= A.Player		
		HealingEngine					= A.HealingEngine
		EnemyTeam						= A.EnemyTeam
		FriendlyTeam					= A.FriendlyTeam
		GetGCD							= A.GetGCD
		GetCurrentGCD					= A.GetCurrentGCD
		GetLatency						= A.GetLatency
		GetSpellInfo					= A.GetSpellInfo
		Create							= A.Create
		
		Listener:Remove("ACTION_EVENT_COVENANT", "ADDON_LOADED")	
	end 
end)

local CovenantActions					= {
	-- [[ Kyrian ]]		
	{ Type = "Spell", ID = 324739, isCovenant = true, covenantID = 1, covenantKey = "SummonSteward", 																		skipRange = true																												},
	{ Type = "Spell", ID = 307865, isCovenant = true, covenantID = 1, covenantKey = "SpearofBastion", 		covenantClass = "WARRIOR", 										skipRange = true, covenantArea = true																							}, -- ground click
	{ Type = "Spell", ID = 312321, isCovenant = true, covenantID = 1, covenantKey = "ScouringTithe", 		covenantClass = "WARLOCK" 																																										}, -- casting 
	{ Type = "Spell", ID = 324386, isCovenant = true, covenantID = 1, covenantKey = "VesperTotem", 			covenantClass = "SHAMAN", 										skipRange = true, covenantArea = true																							}, -- ground click
	{ Type = "Spell", ID = 323547, isCovenant = true, covenantID = 1, covenantKey = "EchoingReprimand", 	covenantClass = "ROGUE" 																																										},
	{ Type = "Spell", ID = 325013, isCovenant = true, covenantID = 1, covenantKey = "BoonoftheAscended", 	covenantClass = "PRIEST", 										skipRange = true, buffID = 325013, Texture = 325013																				}, -- 3min cd - activation spell, texture is BoonoftheAscended 
	{ Type = "Spell", ID = 325020, isCovenant = true, covenantID = 1, covenantKey = "AscendedNova", 		covenantClass = "PRIEST", 										skipRange = true, buffID = 325013, Texture = 325013																				}, -- after activation BoonoftheAscended transforms into AscendedNova, texture is BoonoftheAscended
	{ Type = "Spell", ID = 325315, isCovenant = true, covenantID = 1, covenantKey = "AscendedBlast", 		covenantClass = "PRIEST", covenantSpecIDs = { CONST.PRIEST_SHADOW }						  , buffID = 325013, Texture = 15407																	}, -- after activation BoonoftheAscended, SP will have replaced MindFlay by AscendedBlast, texture is MindFlay
	{ Type = "Spell", ID = 325315, isCovenant = true, covenantID = 1, covenantKey = "AscendedBlast", 		covenantClass = "PRIEST", covenantSpecIDs = { CONST.PRIEST_DISCIPLINE, CONST.PRIEST_HOLY }, buffID = 325013, Texture = 585																		}, -- after activation BoonoftheAscended, Disc/Holy will have replaced Smite by AscendedBlast, texture is Smite
	{ Type = "Spell", ID = 304971, isCovenant = true, covenantID = 1, covenantKey = "DivineToll", 			covenantClass = "PALADIN", spellBySpecID = { [CONST.PALADIN_HOLY] = 20473, [CONST.PALADIN_PROTECTION] = 31935, [CONST.PALADIN_RETRIBUTION] = 20271 }, FixedTexture = 3565448					},
	{ Type = "Spell", ID = 310454, isCovenant = true, covenantID = 1, covenantKey = "WeaponsofOrder", 		covenantClass = "MONK"	 																																										},
	{ Type = "Spell", ID = 307443, isCovenant = true, covenantID = 1, covenantKey = "RadiantSpark", 		covenantClass = "MAGE"	 																																										}, -- casting
	{ Type = "Spell", ID = 308491, isCovenant = true, covenantID = 1, covenantKey = "ResonatingArrow", 		covenantClass = "HUNTER", 										skipRange = true, covenantArea = true																							}, -- ground click 
	{ Type = "Spell", ID = 326434, isCovenant = true, covenantID = 1, covenantKey = "KindredSpirits", 		covenantClass = "DRUID", 										skipRange = true	 , buffID = 326434, Texture = 326434																		}, -- casting - activation spell, texture is KindredSpirits
	{ Type = "Spell", ID = 326446, isCovenant = true, covenantID = 1, covenantKey = "EmpowerBond", 			covenantClass = "DRUID", covenantSpecIDs = { CONST.DRUID_FERAL, CONST.DRUID_BALANCE }, buffID = 326434, Texture = 326434																		}, -- after activation KindredSpirits transforms into EmpowerBond, texture is KindredSpirits
	{ Type = "Spell", ID = 326462, isCovenant = true, covenantID = 1, covenantKey = "EmpowerBond", 			covenantClass = "DRUID", covenantSpecIDs = { CONST.DRUID_GUARDIAN }					 , buffID = 326434, Texture = 326434																		}, -- after activation KindredSpirits transforms into EmpowerBond, texture is KindredSpirits
	{ Type = "Spell", ID = 326647, isCovenant = true, covenantID = 1, covenantKey = "EmpowerBond", 			covenantClass = "DRUID", covenantSpecIDs = { CONST.DRUID_RESTORATION }				 , buffID = 326434, Texture = 326434																		}, -- after activation KindredSpirits transforms into EmpowerBond, texture is KindredSpirits
	{ Type = "Spell", ID = 306830, isCovenant = true, covenantID = 1, covenantKey = "ElysianDecree", 		covenantClass = "DEMONHUNTER", 									skipRange = true, covenantArea = true																							}, -- ground click 
	{ Type = "Spell", ID = 312202, isCovenant = true, covenantID = 1, covenantKey = "ShackletheUnworthy", 	covenantClass = "DEATHKNIGHT" 													 																												}, 
	-- [[ Venthyr ]] 
	{ Type = "Spell", ID = 300728, isCovenant = true, covenantID = 2, covenantKey = "DoorofShadows", 																		skipRange = true, covenantArea = true																							}, -- ground click 
	{ Type = "Spell", ID = 317349, isCovenant = true, covenantID = 2, covenantKey = "Condemn", 				covenantClass = "WARRIOR", covenantSpecIDs = { CONST.WARRIOR_ARMS, CONST.WARRIOR_PROTECTION }, Texture = 163201					 																}, -- replaced Execute!
	{ Type = "Spell", ID = 317485, isCovenant = true, covenantID = 2, covenantKey = "Condemn", 				covenantClass = "WARRIOR", covenantSpecIDs = { CONST.WARRIOR_FURY }							 , Texture = 163201																					}, -- replaced Execute!
	{ Type = "Spell", ID = 321792, isCovenant = true, covenantID = 2, covenantKey = "ImpendingCatastrophe", covenantClass = "WARLOCK" 													 																													}, -- casting
	{ Type = "Spell", ID = 320674, isCovenant = true, covenantID = 2, covenantKey = "ChainHarvest", 		covenantClass = "SHAMAN" 													 																													}, -- casting
	{ Type = "Spell", ID = 323654, isCovenant = true, covenantID = 2, covenantKey = "Slaughter", 			covenantClass = "ROGUE" 													 																													}, -- stealthed
	{ Type = "Spell", ID = 323673, isCovenant = true, covenantID = 2, covenantKey = "Mindgames", 			covenantClass = "PRIEST" 													 																													}, -- casting
	{ Type = "Spell", ID = 316958, isCovenant = true, covenantID = 2, covenantKey = "AshenHallow", 			covenantClass = "PALADIN" 													 																													}, -- casting. Within the Hallow, you may use Hammer of Wrath on any target!
	{ Type = "Spell", ID = 326860, isCovenant = true, covenantID = 2, covenantKey = "FallenOrder", 			covenantClass = "MONK", 										skipRange = true																												},
	{ Type = "Spell", ID = 314793, isCovenant = true, covenantID = 2, covenantKey = "MirrorsofTorment", 	covenantClass = "MAGE"																																											}, -- casting 
	{ Type = "Spell", ID = 324149, isCovenant = true, covenantID = 2, covenantKey = "FlayedShot", 			covenantClass = "HUNTER"																																										},
	{ Type = "Spell", ID = 323546, isCovenant = true, covenantID = 2, covenantKey = "RavenousFrenzy", 		covenantClass = "DRUID", 										skipRange = true																												},
	{ Type = "Spell", ID = 317009, isCovenant = true, covenantID = 2, covenantKey = "SinfulBrand", 			covenantClass = "DEMONHUNTER"																																									},
	{ Type = "Spell", ID = 311648, isCovenant = true, covenantID = 2, covenantKey = "SwarmingMist", 		covenantClass = "DEATHKNIGHT", 									skipRange = true																												},
	-- [[ NightFae ]]
	{ Type = "Spell", ID = 310143, isCovenant = true, covenantID = 3, covenantKey = "Soulshape", 																			skipRange = true, buffID = 310143, Texture = 310143																				},
	{ Type = "Spell", ID = 324701, isCovenant = true, covenantID = 3, covenantKey = "Flicker", 																				skipRange = true, buffID = 310143, Texture = 310143																				},
	{ Type = "Spell", ID = 325886, isCovenant = true, covenantID = 3, covenantKey = "AncientAftershock", 	covenantClass = "WARRIOR", 										skipRange = true																												}, -- can be used as mass interrupt!
	{ Type = "Spell", ID = 325640, isCovenant = true, covenantID = 3, covenantKey = "SoulRot", 				covenantClass = "WARLOCK" 																																										}, -- casting 
	{ Type = "Spell", ID = 328923, isCovenant = true, covenantID = 3, covenantKey = "FaeTransfusion", 		covenantClass = "SHAMAN", 										skipRange = true, covenantArea = true																							}, -- ground click, channeling 
	{ Type = "Spell", ID = 328305, isCovenant = true, covenantID = 3, covenantKey = "Sepsis", 				covenantClass = "ROGUE" 																																										}, 
	{ Type = "Spell", ID = 327661, isCovenant = true, covenantID = 3, covenantKey = "FaeGuardians", 		covenantClass = "PRIEST", 										skipRange = true											  , Texture = 327694												}, 
	{ Type = "Spell", ID = 342132, isCovenant = true, covenantID = 3, covenantKey = "WrathfulFaerie", 		covenantClass = "PRIEST", 										skipRange = true											  , Texture = 327694												}, 
	{ Type = "Spell", ID = 327694, isCovenant = true, covenantID = 3, covenantKey = "GuardianFaerie", 		covenantClass = "PRIEST", 										skipRange = true											  , Texture = 327694												}, 
	{ Type = "Spell", ID = 327710, isCovenant = true, covenantID = 3, covenantKey = "BenevolentFaerie", 	covenantClass = "PRIEST", 										skipRange = true										  	  , Texture = 327694												}, 
	{ Type = "Spell", ID = 328282, isCovenant = true, covenantID = 3, covenantKey = "BlessingofSpring", 	covenantClass = "PALADIN", 										skipRange = true, buffIDs = { 328282, 328620, 328622, 328281 }, Texture = 328278												}, -- Blessing of Spring -> Blessing of Summer -> Blessing of Autumn -> Blessing of Winter
	{ Type = "Spell", ID = 328620, isCovenant = true, covenantID = 3, covenantKey = "BlessingofSummer", 	covenantClass = "PALADIN", 										skipRange = true, buffIDs = { 328282, 328620, 328622, 328281 }, Texture = 328278												}, -- Blessing of Spring -> Blessing of Summer -> Blessing of Autumn -> Blessing of Winter
	{ Type = "Spell", ID = 328622, isCovenant = true, covenantID = 3, covenantKey = "BlessingofAutumn", 	covenantClass = "PALADIN", 										skipRange = true, buffIDs = { 328282, 328620, 328622, 328281 }, Texture = 328278												}, -- Blessing of Spring -> Blessing of Summer -> Blessing of Autumn -> Blessing of Winter
	{ Type = "Spell", ID = 328281, isCovenant = true, covenantID = 3, covenantKey = "BlessingofWinter", 	covenantClass = "PALADIN", 										skipRange = true, buffIDs = { 328282, 328620, 328622, 328281 }, Texture = 328278												}, -- Blessing of Spring -> Blessing of Summer -> Blessing of Autumn -> Blessing of Winter
	{ Type = "Spell", ID = 327104, isCovenant = true, covenantID = 3, covenantKey = "FaelineStomp", 		covenantClass = "MONK", 										skipRange = true																												},
	{ Type = "Spell", ID = 314791, isCovenant = true, covenantID = 3, covenantKey = "ShiftingPower", 		covenantClass = "MAGE", 										skipRange = true																												}, -- channeling
	{ Type = "Spell", ID = 328231, isCovenant = true, covenantID = 3, covenantKey = "WildSpirits", 			covenantClass = "HUNTER", 										skipRange = true, covenantArea = true																							}, -- ground click -- FIX ME: Does it correct ID ?!
	{ Type = "Spell", ID = 323764, isCovenant = true, covenantID = 3, covenantKey = "ConvoketheSpirits",	covenantClass = "DRUID", 										skipRange = true																												}, -- channeling
	{ Type = "Spell", ID = 323639, isCovenant = true, covenantID = 3, covenantKey = "TheHunt",				covenantClass = "DEMONHUNTER"																																									}, -- casting
	{ Type = "Spell", ID = 324128, isCovenant = true, covenantID = 3, covenantKey = "DeathsDue",			covenantClass = "DEATHKNIGHT", 									skipRange = true, covenantArea = true																							}, -- ground click, replaced Death and Decay!
	-- [[ Necrolord ]] 
	{ Type = "Spell", ID = 324631, isCovenant = true, covenantID = 4, covenantKey = "Fleshcraft", 																			skipRange = true																												}, -- channeling
	{ Type = "Spell", ID = 324143, isCovenant = true, covenantID = 4, covenantKey = "ConquerorsBanner", 	covenantClass = "WARRIOR", 										skipRange = true, buffID = 325787																								},
	{ Type = "Spell", ID = 325289, isCovenant = true, covenantID = 4, covenantKey = "DecimatingBolt", 		covenantClass = "WARLOCK"																																										}, -- casting
	{ Type = "Spell", ID = 326059, isCovenant = true, covenantID = 4, covenantKey = "PrimordialWave", 		covenantClass = "SHAMAN"																																										}, -- casting
	{ Type = "Spell", ID = 328547, isCovenant = true, covenantID = 4, covenantKey = "SerratedBoneSpike", 	covenantClass = "ROGUE"																																											}, 
	{ Type = "Spell", ID = 324724, isCovenant = true, covenantID = 4, covenantKey = "UnholyNova", 			covenantClass = "PRIEST", 										skipRange = true																												}, 
	{ Type = "Spell", ID = 328204, isCovenant = true, covenantID = 4, covenantKey = "VanquishersHammer", 	covenantClass = "PALADIN"																																										}, 
	{ Type = "Spell", ID = 325216, isCovenant = true, covenantID = 4, covenantKey = "BonedustBrew", 		covenantClass = "MONK", 										skipRange = true, covenantArea = true																							}, -- ground click
	{ Type = "Spell", ID = 324220, isCovenant = true, covenantID = 4, covenantKey = "Deathborne", 			covenantClass = "MAGE", 										skipRange = true																												}, -- casting
	{ Type = "Spell", ID = 325028, isCovenant = true, covenantID = 4, covenantKey = "DeathChakram", 		covenantClass = "HUNTER"																																										}, 
	{ Type = "Spell", ID = 325727, isCovenant = true, covenantID = 4, covenantKey = "AdaptiveSwarm", 		covenantClass = "DRUID"																																											}, 
	{ Type = "Spell", ID = 329554, isCovenant = true, covenantID = 4, covenantKey = "FoddertotheFlame", 	covenantClass = "DEMONHUNTER", 									skipRange = true																												}, -- AutoTarget feature will force to target summoned demon
	{ Type = "Spell", ID = 315443, isCovenant = true, covenantID = 4, covenantKey = "AbominationLimb", 		covenantClass = "DEATHKNIGHT", 									skipRange = true																												}, 
}; A.CovenantActions = CovenantActions

local Auras 							= {
	Total_MagicDamage_Imun				= {"TotalImun", "DamageMagicImun"},
	Total_PhysDamage_Imun				= {"TotalImun", "DamagePhysImun"},
	Total_MagicDamage_PhysDamage_Imun	= {"TotalImun", "DamageMagicImun", "DamagePhysImun"},
}

local CovenantFunctions 				= {
	[1]									= {
		-- Shared 
		SummonSteward					= function(self, unitID)
			return true -- Unit("player"):CombatTime() == 0
		end,
		PhialofSerenity					= function(self, unitID)
			return true 
		end,
		-- Warrior 
		SpearofBastion					= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Player:IsStaying() and Player:RageDeficit() >= 25 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(5))
		end,
		-- Warlock 
		ScouringTithe					= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Shaman 
		VesperTotem						= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and self:GetSpellTimeSinceLastCast() > 30 -- and Player:IsStaying()
		end,	
		-- Rogue 		
		EchoingReprimand				= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Player:ComboPointsDeficit() >= 3 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
			-- FIX ME: Do we need to check the stacks of buff for recharged anima CP ??
		end,
		-- Priest 
		BoonoftheAscended				= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit("player"):HasBuffs(self.buffID, true) == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		AscendedNova					= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Unit("player"):HasBuffs(self.buffID, true) > 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(8))
		end,
		AscendedBlast					= function(self, unitID) 
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Unit("player"):HasBuffs(self.buffID, true) > 0 and (not A.IamHealer or Player:InsanityDeficit() >= 12) and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Paladin 
		DivineToll						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or A.IamHealer or not EnemyTeam("HEALER"):IsBreakAble(30))
		end,
		-- Monk 
		WeaponsofOrder					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0
		end,
		-- Mage 
		RadiantSpark					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Hunter 
		ResonatingArrow					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0
		end,
		-- Druid 
		KindredSpirits					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit("player"):HasBuffs(self.buffID, true) == 0
		end,
		EmpowerBond						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Unit("player"):HasBuffs(self.buffID, true) > 0 -- and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- DemonHunter
		ElysianDecree					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and Player:IsStaying() and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(8))
		end,
		-- DeathKnight
		ShackletheUnworthy				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
	},
	[2]									= {
		-- Shared
		DoorofShadows					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and Player:IsStayingTime() > 0.5 and Player:IsStayingTime() < 3.5 and (not Unit(unitID):IsExists() or UnitIsUnit(unitID, "player")) and IsIndoors() and not Player:IsMounted()
		end,
		-- Warrior 
		Condemn							= function(self, unitID)
			return LoC:Get("DISARM") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Unit(unitID):HealthPercent() >= 80 or Unit(unitID):HealthPercent() <= 20)
		end,
		-- Warlock 
		ImpendingCatastrophe			= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40))
		end,
		-- Shaman 
		ChainHarvest					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Rogue 
		Slaughter						= function(self, unitID)
			return LoC:Get("DISARM") == 0 and Player:IsStealthed()
		end,
		-- Priest 
		Mindgames						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Paladin 
		AshenHallow						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and Player:IsStaying() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(20))
		end,
		-- Monk 
		FallenOrder						= function(self, unitID)
			 return self:AbsentImun(unitID, Auras.Total_PhysDamage_Imun) 
		end,
		-- Mage 
		ShiftingPower					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) 
		end,
		-- Hunter 
		FlayedShot						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_PhysDamage_Imun) 
		end,
		-- Druid 
		RavenousFrenzy					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, (A.PlayerSpec == CONST.DRUID_BALANCE or A.IamHealer) and Auras.Total_MagicDamage_Imun or Auras.Total_PhysDamage_Imun)
		end,
		-- DemonHunter
		SinfulBrand						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) 
		end,
		-- DeathKnight
		SwarmingMist					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(10))
		end,
	},
	[3]									= {
		-- Shared 
		Soulshape						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and Unit("player"):HasBuffs(self.buffID, true) == 0 and Player:IsMoving() and IsIndoors() and (not Unit(unitID):IsExists() or (not A.IamHealer and UnitIsUnit(unitID, "player")) or Unit(unitID):GetRange() >= 15) and not Player:IsMounted()
		end,
		Flicker							= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and Unit("player"):HasBuffs(self.buffID, true) > 0  and Player:IsMoving() and (not Unit(unitID):IsExists() or (not A.IamHealer and UnitIsUnit(unitID, "player")) or Unit(unitID):GetRange() >= 15)
		end,
		-- Warrior 
		AncientAftershock				= function(self, unitID)
			return LoC:Get("DISARM") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Warlock 
		SoulRot							= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40)) and Unit("player"):HealthPercent() >= 30 -- 20% but we will use 30% to be safe
		end,
		-- Shaman 
		FaeTransfusion					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40))
		end,
		-- Rogue 
		Sepsis							= function(self, unitID)
			return LoC:Get("DISARM") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Priest
		FaeBlessings					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Paladin
		BlessingofSpring				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 
		end,
		BlessingofSummer				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 
		end,
		BlessingofAutumn				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 
		end,
		BlessingofWinter				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 
		end,
		-- Monk
		FaelineStomp					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(6))
		end,
		-- Mage
		ShiftingPower					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(15))
		end,
		-- Hunter
		WildSpirits						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Druid 
		ConvoketheSpirits				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40))
		end,
		-- DemonHunter
		TheHunt							= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- DeathKnight
		DeathsDue						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(8))
		end,
	},
	[4]									= {
		-- Shared 
		Fleshcraft						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and Player:IsStaying()
		end,
		-- Warrior 
		ConquerorsBanner				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 
		end,
		-- Warlock 
		DecimatingBolt					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Shaman 
		PrimordialWave					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and (Player:IsStaying() or self:GetSpellCastTime() == 0) and Unit(unitID):TimeToDie() >= self:GetSpellCastTime() + GetCurrentGCD() + GetLatency() and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun)
		end,
		-- Rogue 
		SerratedBoneSpike				= function(self, unitID)
			return LoC:Get("DISARM") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0
		end,
		-- Priest 
		UnholyNova						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(15))
		end,
		-- Paladin
		VanquishersHammer				= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0
		end,
		-- Monk
		BonedustBrew					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0
		end,
		-- Mage
		Deathborne						= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0
		end,
		-- Hunter
		DeathChakram					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(40))
		end,
		-- Druid 
		AdaptiveSwarm					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0
		end,
		-- DemonHunter
		FoddertotheFlame				= function(self, unitID)
			return true -- Physical
		end,
		-- DeathKnight
		AbominationLimb					= function(self, unitID)
			return LoC:Get("SILENCE") == 0 and LoC:Get("SCHOOL_INTERRUPT", "SHADOW") == 0 and self:AbsentImun(unitID, Auras.Total_MagicDamage_Imun) and (not A.IsInPvP or not EnemyTeam("HEALER"):IsBreakAble(20))
		end,
	},
}; A.CovenantFunctions = CovenantFunctions

-- Restricted environment
local macroInstalled, itemPhialofSerenity, isLoaded
if Covenant:IsLoaded() then 
	isLoaded = true 
	
	local IDs = {}
	for _, obj in ipairs(CovenantActions) do 
		IDs[obj.covenantKey] = obj.ID
	end 
	
	local CovenantSignature = CreateFrame("Button", "CovenantSignature", UIParent, "SecureActionButtonTemplate")
	CovenantSignature.pattern = "/cast %s"
	CovenantSignature:SetAttribute("type", "macro")
	CovenantSignature:SetAttribute("macrotext", "")
	CovenantSignature:RegisterForClicks("AnyDown")
	
	local CovenantClass = CreateFrame("Button", "CovenantClass", UIParent, "SecureActionButtonTemplate")
	CovenantClass.pattern = "/cast [@mouseover, exists]%s; %s"
	CovenantClass.patternArea = "/cast [@mouseover, help]%s; [@target, help]%s; %s" -- if destination is equal to self it will be dropped at self position
	CovenantClass.patternAreaSelf = "/cast [@player] %s"
	CovenantClass:SetAttribute("type", "macro")
	CovenantClass:SetAttribute("macrotext", "")
	CovenantClass:RegisterForClicks("AnyDown")	
	
	local function IsButtonsInstalled()
		if CovenantSignature.installed and CovenantClass.installed then 
			macroInstalled = true 
			if useDebug then 
				Print("[Covenant] Macro 'CovenantSignature' has: " .. CovenantSignature:GetAttribute("macrotext"))
				Print("[Covenant] Macro 'CovenantClass' has: " .. CovenantClass:GetAttribute("macrotext"))
			end 
			
			return true 
		end 
	end 
	
	local function InstallButtons()
		if Covenant.covenantID and CovenantSignature:CanChangeAttribute() and CovenantClass:CanChangeAttribute() then 			
			CovenantSignature.installed, CovenantClass.installed, macroInstalled = nil, nil, nil 
			for _, obj in ipairs(CovenantActions) do 
				if obj.covenantID == Covenant.covenantID then 
					if obj.covenantClass == nil then 
						-- CovenantSignature
						if not CovenantSignature.installed then  
							local spellName = GetSpellInfo(obj.ID)								
							if not spellName then 
								error("CovenantSignature couldn't get spellName from " .. obj.covenantKey)
								return 
							end
							
							CovenantSignature:SetAttribute("macrotext", CovenantSignature.pattern:format(spellName))
							CovenantSignature.installed = true													
						end 
					elseif obj.covenantClass == playerClass then 
						-- CovenantClass
						if obj.covenantArea then 
							-- Range specs will not have [@player] except self destination, only melee specs will have for ground click spells [@player]	
							if A.IamMelee or (A.IamHealer and obj.covenantKey == "VesperTotem") then 
								local spellName = GetSpellInfo(obj.ID)								
								if not spellName then 
									error("CovenantClass couldn't get spellName from " .. obj.covenantKey)
									return 
								end
								
								CovenantClass:SetAttribute("macrotext", CovenantClass.patternAreaSelf:format(spellName))
							else 
								local spellName = GetSpellInfo(obj.ID)								
								if not spellName then 
									error("CovenantClass couldn't get spellName from " .. obj.covenantKey)
									return 
								end
								
								CovenantClass:SetAttribute("macrotext", CovenantClass.patternArea:format(spellName, spellName, spellName))
							end 
						else 
							local spellName = GetSpellInfo(obj.ID)								
							if not spellName then 
								error("CovenantClass couldn't get spellName from " .. obj.covenantKey)
								return 
							end
							
							-- Fix Paladin's NightFae 
							if obj.covenantClass == "PALADIN" and obj.covenantID == 3 then 
								local macrotext = CovenantClass:GetAttribute("macrotext") 
								for _, subObj in ipairs(CovenantActions) do 
									if subObj.covenantClass == "PALADIN" and subObj.covenantID == 3 then
										spellName = GetSpellInfo(subObj.ID)								
										if not spellName then 
											error("CovenantClass couldn't get spellName from " .. subObj.covenantKey)
											return 
										end				
										
										CovenantClass:SetAttribute("macrotext", CovenantClass.pattern:format(spellName, spellName) .. (macrotext and ("\n" .. macrotext) or ""))
									end 
								end
							-- Fix Paladin's DivineToll
							elseif obj.covenantClass == "PALADIN" and obj.covenantID == 1 and obj.spellBySpecID and obj.spellBySpecID[A.PlayerSpec] then 
								spellName = GetSpellInfo(obj.spellBySpecID[A.PlayerSpec])
								CovenantClass:SetAttribute("macrotext", CovenantClass.pattern:format(spellName, spellName))
							-- Fix Priest's Fae Guardians
							elseif obj.covenantClass == "PRIEST" and obj.covenantID == 3 then 
								local macrotext = CovenantClass:GetAttribute("macrotext") 
								for _, subObj in ipairs(CovenantActions) do 
									if subObj.covenantClass == "PRIEST" and subObj.covenantID == 3 then
										spellName = GetSpellInfo(subObj.ID)								
										if not spellName then 
											error("CovenantClass couldn't get spellName from " .. subObj.covenantKey)
											return 
										end				
										
										CovenantClass:SetAttribute("macrotext", CovenantClass.pattern:format(spellName, spellName) .. (macrotext and ("\n" .. macrotext) or ""))
									end 
								end
							else 
								CovenantClass:SetAttribute("macrotext", CovenantClass.pattern:format(spellName, spellName))
							end 
						end 
						
						CovenantClass.installed = true 
					end 
					
					if IsButtonsInstalled() then 
						break 
					end 					
				end 				
			end 
		end 
	end
	
	TMW:RegisterSelfDestructingCallback("TMW_ACTION_COVENANT_LIB_UPDATED", function()
		InstallButtons()
		TMW:RegisterCallback("TMW_ACTION_COVENANT_LIB_UPDATED", InstallButtons)
		TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", function()
			macroInstalled = nil 
			InstallButtons()
		end)
		Listener:Add("ACTION_EVENT_COVENANT", "PLAYER_REGEN_ENABLED", function()
			if not macroInstalled then 
				if useDebug then 
					Print("Attempt to install covenant buttons..")
				end 
				InstallButtons()
				if useDebug then 
					if macroInstalled then 
						Print("Successful installed by attempt!")
					else 
						Print("Failed to install by attempt!")
					end 
				end 
			end 
		end)		
		return true -- Signal RegisterSelfDestructingCallback to unregister
	end)
end 

local function IsComparedObject(object, ...)
	local n = select("#", ...)
	if n > 0 then 
		for i = 1, n do 			
			if object == select(i, ...) then 
				return true 
			end 
		end 
	end 
end 

-------------------------------------
-- API
-------------------------------------
-- Creates action objects for specID 
function A:CreateCovenantsFor(specID) 
	-- @usage: Action:CreateCovenantsFor(specID)
	-- If game patch lower than 9x+ it will create empty objects which will be hidden in UI 		
	if self[specID] == nil then 
		error("[Debug] Covenant tried to call 'CreateCovenantsFor' function for unexist specID in the self table!")
		return 
	end 
	
	for _, action in ipairs(CovenantActions) do 
		if (not action.covenantClass or action.covenantClass == playerClass) and (not action.covenantSpecIDs or tContains(action.covenantSpecIDs, specID)) then 
			self[specID][action.covenantKey] = Create(isLoaded and CopyTable(action) or nil)
		end 
	end 	 
end 

function A.AuraIsValidByPhialofSerenity()
	-- @return boolean 
	local toggle = GetToggle(2, "PhialofSerenityDispel")
	return toggle and (AuraIsValid("player", toggle, "Disease") or AuraIsValid("player", toggle, "Poison") or AuraIsValid("player", toggle, "Curse") or AuraIsValid("player", toggle, "Bleeds"))
end; local AuraIsValidByPhialofSerenity = A.AuraIsValidByPhialofSerenity

-- Checks usable conditions such as school, movement, power deficit
function A:IsCovenantCastable(unitID)
	-- @return boolean 
	return CovenantFunctions[self.covenantID][self.covenantKey](self, unitID or "target") 
end 

-- Executes :IsReady and :IsCovenantCastable which is supposed to continue condition line by own logic 
function A:AutoCovenant(unitID)
	-- @returb boolean 
	return self:IsReady(unitID) and self:IsCovenantCastable(unitID)
end 

-- Executes :AutoCovenant for each covenant spell and continues by implement in template logic
function A:RunAutoCovenants(icon, unitID, ...)
	-- @return boolean and shows picture
	-- vararg is a skip action objects 
	if self.CovenantIsON() then 
		local unitID = unitID or "target"
		
		-- [[ Kyrian ]]
		if Covenant.covenantID == 1 then 
			-- Shared
			if self.SummonSteward:AutoCovenant(unitID) and not IsComparedObject(self.SummonSteward, ...) then 	
				if Player:IsStayingTime() >= 2.5 and not self.PhialofSerenity:IsBlockedByAny() and self.PhialofSerenity:GetCount() == 0 and Unit("player"):CombatTime() == 0 then 
					return self.SummonSteward:Show(icon)
				end 
			end 	
			
			-- Warrior 
			if playerClass == "WARRIOR" and self.SpearofBastion:AutoCovenant(unitID) and not IsComparedObject(self.SpearofBastion, ...) then 	
				if GetToggle(2, "AoE") and ((Player:IsStayingTime() > 0.5 and MultiUnits:GetByRangeInCombat(5, 2, 6) >= 2) or (A.IsInPvP and Unit(unitID):IsEnemy() and Unit(unitID):IsMovingOut() and Unit(unitID):GetRange() <= 5)) then 
					return self.SpearofBastion:Show(icon)
				end 
			end 
			
			-- Warlock 
			if playerClass == "WARLOCK" and self.ScouringTithe:AutoCovenant(unitID) and not IsComparedObject(self.ScouringTithe, ...) then 	
				if Unit(unitID):IsEnemy() then 
					return self.ScouringTithe:Show(icon)
				end 
			end 
			
			-- Shaman 
			if playerClass == "SHAMAN" and self.VesperTotem:AutoCovenant(unitID) and not IsComparedObject(self.VesperTotem, ...) then 	
				if Player:IsStayingTime() >= 1 and Unit("player"):CombatTime() > 0 and ((A.IamHealer and (HealingEngine.GetTimeToFullHealth() >= 30 or HealingEngine.GetTimeToDieUnits(12) >= 2)) or (not A.IamHealer and GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(A.IamMelee and 5 or nil, 3, GetGCD() * 4) >= 3)) then 
					return self.VesperTotem:Show(icon)
				end 
			end 	
			
			-- Rogue 
			if playerClass == "ROGUE" and self.EchoingReprimand:AutoCovenant(unitID) and not IsComparedObject(self.EchoingReprimand, ...) then 	
				if Unit(unitID):IsEnemy() and not Player:IsStealthed() then 
					return self.EchoingReprimand:Show(icon)
				end 
			end 	
			
			-- Priest 
			if playerClass == "PRIEST" and self.BoonoftheAscended:AutoCovenant(unitID) and not IsComparedObject(self.BoonoftheAscended, ...) then 	
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 then 
					return self.BoonoftheAscended:Show(icon)
				end 
			end 	

			if playerClass == "PRIEST" and self.AscendedNova:AutoCovenant(unitID) and not IsComparedObject(self.AscendedNova, ...) then 	
				if GetToggle(2, "AoE") and ((A.IamHealer and HealingEngine.GetBelowHealthPercentUnits(90, 8) >= 1) or ((not A.IamHealer or Unit(unitID):IsEnemy()) and MultiUnits:GetByRangeInCombat(8, 2) >= 2)) then 
					return self.AscendedNova:Show(icon)
				end 
			end 	
			
			if playerClass == "PRIEST" and self.AscendedBlast:AutoCovenant(unitID) and not IsComparedObject(self.AscendedBlast, ...) then
				if Unit(unitID):IsEnemy() then 
					return self.AscendedBlast:Show(icon)				
				end 
			end 
			
			-- Paladin 
			if playerClass == "PALADIN" and self.DivineToll:AutoCovenant(unitID) and not IsComparedObject(self.DivineToll, ...) then 
				if GetToggle(2, "AoE") then 
					if 	(A.IamHealer and self.HolyShock and HealingEngine.HealingBySpell(nil, self.HolyShock) >= HealingEngine.GetMinimumUnits(1, 5)) or 
						(A.PlayerSpec == CONST.PALADIN_PROTECTION  and Unit(unitID):IsEnemy() and (MultiUnits:GetByRangeInCombat(30, 3) >= 3 or MultiUnits:GetByRangeCasting(30, 2, true) >= 2)) or 
						(A.PlayerSpec == CONST.PALADIN_RETRIBUTION and Unit(unitID):IsEnemy() and Player:HolyPowerDeficit() >= MultiUnits:GetByRange(30, 5))
					then
						return self.DivineToll:Show(icon)
					end 
				end 
			end 
			
			-- Monk 
			if playerClass == "MONK" and self.WeaponsofOrder:AutoCovenant(unitID) and not IsComparedObject(self.WeaponsofOrder, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 then 
					if  (A.PlayerSpec == CONST.MONK_BREWMASTER and Unit(unitID):IsEnemy() and (not self.KegSmash or (self.KegSmash:GetSpellTimeSinceLastCast() <= 3 and self.KegSmash:IsInRange(unitID)))) or 
						(A.PlayerSpec == CONST.MONK_MISTWEAVER and not Unit(unitID):IsEnemy() and LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and (not self.EssenceFont or self.EssenceFont:GetSpellTimeSinceLastCast() <= 3)) or 
						(A.PlayerSpec == CONST.MONK_WINDWALKER and Unit(unitID):IsEnemy() and (not self.RisingSunKick or (self.RisingSunKick:GetSpellTimeSinceLastCast() <= 3 and self.RisingSunKick:IsInRange(unitID))))
					then
						return self.WeaponsofOrder:Show(icon)
					end 
				end 
			end 
			
			-- Mage 
			if playerClass == "MAGE" and self.RadiantSpark:AutoCovenant(unitID) and not IsComparedObject(self.RadiantSpark, ...) then 
				if Unit(unitID):IsEnemy() and not Player:IsStealthed() then 
					return self.RadiantSpark:Show(icon)
				end 
			end 
			
			-- Hunter 
			if playerClass == "HUNTER" and self.ResonatingArrow:AutoCovenant(unitID) and not IsComparedObject(self.ResonatingArrow, ...) then 
				if GetToggle(2, "AoE") and Player:IsStayingTime() > 0.5 and Unit(unitID):IsEnemy() and Unit(unitID):GetRange() <= 40 and ((A.IamRanger and MultiUnits:GetActiveEnemies() >= 3) or MultiUnits:GetByRangeInCombat(40, 3, 8) >= 3) and not Player:IsStealthed() then 
					return self.ResonatingArrow:Show(icon)
				end 
			end 
			
			-- Druid 
			if playerClass == "DRUID" and self.KindredSpirits:AutoCovenant(unitID) and not IsComparedObject(self.KindredSpirits, ...) then 
				if (Unit(unitID):IsEnemy() or Unit(unitID):IsPlayer()) and not Player:IsStealthed() then
					return self.KindredSpirits:Show(icon)
				end 
			end 
			
			if playerClass == "DRUID" and self.EmpowerBond:AutoCovenant(unitID) and not IsComparedObject(self.EmpowerBond, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 then 
					return self.EmpowerBond:Show(icon)
				end 
			end 
			
			-- DemonHunter  
			if playerClass == "DEMONHUNTER" and self.ElysianDecree:AutoCovenant(unitID) and not IsComparedObject(self.ElysianDecree, ...) then 
				if GetToggle(2, "AoE") and Player:IsStayingTime() > 1 and Unit("player"):CombatTime() > 0 and MultiUnits:GetByRangeInCombat(8, 2, 3) >= 2 then
					return self.ElysianDecree:Show(icon)
				end 
			end 
			
			-- DeathKnight 
			if playerClass == "DEATHKNIGHT" and self.ShackletheUnworthy:AutoCovenant(unitID) and not IsComparedObject(self.ShackletheUnworthy, ...) then 
				if Unit(unitID):IsEnemy() and Unit("player"):CombatTime() > 0 and Unit(unitID):TimeToDie() >= 14 then
					return self.ShackletheUnworthy:Show(icon)
				end 
			end 
		end 
		
		-- [[ Venthyr ]] 
		if Covenant.covenantID == 2 then 
			-- Shared
			if self.DoorofShadows:AutoCovenant(unitID) and not IsComparedObject(self.DoorofShadows, ...) then 	 
				if Unit("player"):CombatTime() == 0 then 
					return self.DoorofShadows:Show(icon)
				end 
			end 
			
			-- Warrior 
			if playerClass == "WARRIOR" and self.Condemn:AutoCovenant(unitID) and not IsComparedObject(self.Condemn, ...) then 
				if Unit(unitID):IsEnemy() then 
					return self.Condemn:Show(icon)
				end 
			end 
			
			-- Warlock 
			if playerClass == "WARLOCK" and self.ImpendingCatastrophe:AutoCovenant(unitID) and not IsComparedObject(self.ImpendingCatastrophe, ...) then 
				if GetToggle(2, "AoE") and Unit(unitID):IsEnemy() and MultiUnits:GetActiveEnemies() >= 4 and MultiUnits:GetByRangeInCombat(nil, 4, 12) >= 4 then 
					return self.ImpendingCatastrophe:Show(icon)
				end 
			end 
			
			-- Shaman 
			if playerClass == "SHAMAN" and self.ChainHarvest:AutoCovenant(unitID) and not IsComparedObject(self.ChainHarvest, ...) then 
				if GetToggle(2, "AoE") and BurstIsON(unitID) and ((A.IamHealer and HealingEngine.GetBelowHealthPercentUnits(50, 40) >= 2) or ((not A.IamHealer or Unit(unitID):IsEnemy()) and MultiUnits:GetByRangeInCombat(40, 2) >= 2)) then 
					return self.ChainHarvest:Show(icon)
				end 
			end 
			
			-- Rogue 
			if playerClass == "ROGUE" and self.Slaughter:AutoCovenant(unitID) and not IsComparedObject(self.Slaughter, ...) then 
				if Unit(unitID):IsEnemy() and Player:ComboPointsDeficit() >= 2 then 
					return self.Slaughter:Show(icon)
				end 
			end 
			
			-- Priest 
			if playerClass == "PRIEST" and self.Mindgames:AutoCovenant(unitID) and not IsComparedObject(self.Mindgames, ...) then 
				if Unit(unitID):IsEnemy() and Unit(unitID):CombatTime() > 0 and Unit(unitID):TimeToDie() >= 6 then 
					return self.Mindgames:Show(icon)
				end 
			end 
			
			-- Paladin 
			if playerClass == "PALADIN" and self.AshenHallow:AutoCovenant(unitID) and not IsComparedObject(self.AshenHallow, ...) then 
				if GetToggle(2, "AoE") and BurstIsON(unitID) and Unit("player"):CombatTime() > 0 and (not A.IamHealer or HealingEngine.GetTimeToDieUnits(10) >= 2) then 
					return self.AshenHallow:Show(icon)
				end 
			end 
			
			-- Monk 
			if playerClass == "MONK" and self.FallenOrder:AutoCovenant(unitID) and not IsComparedObject(self.FallenOrder, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 and (not A.IamHealer or HealingEngine.GetTimeToDieUnits(10) >= 2) and (not self.TigerPalm or self.TigerPalm:IsInRange(unitID)) then 
					return self.FallenOrder:Show(icon)
				end 
			end 
						
			-- Mage 
			if playerClass == "MAGE" and self.ShiftingPower:AutoCovenant(unitID) and not IsComparedObject(self.ShiftingPower, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 and Unit(unitID):IsEnemy() and not Player:IsStealthed() then 
					return self.ShiftingPower:Show(icon)
				end 
			end 
			
			-- Hunter 
			if playerClass == "HUNTER" and self.FlayedShot:AutoCovenant(unitID) and not IsComparedObject(self.FlayedShot, ...) then 
				if Unit(unitID):IsEnemy() and Unit(unitID):TimeToDie() >= 20 and not Player:IsStealthed() then 
					return self.FlayedShot:Show(icon)
				end 
			end 
			
			-- Druid 
			if playerClass == "DRUID" and self.RavenousFrenzy:AutoCovenant(unitID) and not IsComparedObject(self.RavenousFrenzy, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 and (not A.IamHealer or HealingEngine.GetTimeToDieUnits(10) >= 2) and (((A.PlayerSpec == CONST.DRUID_BALANCE or A.IamHealer) and Unit(unitID):CanInterract(40)) or (A.PlayerSpec == CONST.DRUID_FERAL and (not self.Shred or self.Shred:IsInRange(unitID))) or (A.PlayerSpec == CONST.DRUID_GUARDIAN and (not self.Mangle or self.Mangle:IsInRange(unitID)))) and not Player:IsStealthed() then 
					return self.RavenousFrenzy:Show(icon)
				end 
			end 
			
			-- DemonHunter 
			if playerClass == "DEMONHUNTER" and self.SinfulBrand:AutoCovenant(unitID) and not IsComparedObject(self.SinfulBrand, ...) then 
				if Unit("player"):CombatTime() > 0 and Unit(unitID):IsEnemy() and Unit(unitID):HasDeBuffs(self.SinfulBrand.ID) == 0 and Unit(unitID):TimeToDie() >= 8 + GetGCD() then 
					return self.SinfulBrand:Show(icon)
				end 
			end 
			
			-- DeathKnight 
			if playerClass == "DEATHKNIGHT" and self.SwarmingMist:AutoCovenant(unitID) and not IsComparedObject(self.SwarmingMist, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(10, 3, 8 + GetGCD()) >= 3 and Player:RunicPowerPercentage() >= 30 then 
					return self.SwarmingMist:Show(icon)
				end 
			end 
		end
		
		-- [[ NightFae ]]
		if Covenant.covenantID == 3 then 
			-- Shared
			if self.Soulshape:AutoCovenant(unitID) and not IsComparedObject(self.Soulshape, ...) then 
				if Player:IsMovingTime() >= 2.5 and Unit(unitID):IsExists() and Unit(unitID):GetRange() >= ((A.IamMelee or Unit("player"):CombatTime() == 0) and 15 or 45) then 
					return self.Soulshape:Show(icon)
				end
			end 
			
			if self.Flicker:AutoCovenant(unitID) and not IsComparedObject(self.Flicker, ...) then 
				if Player:IsMovingTime() >= 2.5 and Unit(unitID):IsExists() and Unit(unitID):GetRange() >= ((A.IamMelee or Unit("player"):CombatTime() == 0) and 15 or 45) then 
					return self.Flicker:Show(icon)
				end
			end 
						
			-- Warrior 
			if playerClass == "WARRIOR" and self.AncientAftershock:AutoCovenant(unitID) and not IsComparedObject(self.AncientAftershock, ...) then 
				if GetToggle(2, "AoE") and (MultiUnits:GetByRangeInCombat(12, 5, 12 + GetGCD()) >= 5 or MultiUnits:GetByRangeCasting(12, 2) >= 2) then 
					return self.AncientAftershock:Show(icon)
				end 
			end 
			
			-- Warlock 
			if playerClass == "WARLOCK" and self.SoulRot:AutoCovenant(unitID) and not IsComparedObject(self.SoulRot, ...) then 
				if GetToggle(2, "AoE") and Unit(unitID):IsEnemy() and (MultiUnits:GetActiveEnemies() >= 4 or MultiUnits:GetByRangeInCombat(40, 4, 8) >= 4) then 
					return self.SoulRot:Show(icon)
				end 				
			end 
			
			-- Shaman 
			if playerClass == "SHAMAN" and self.FaeTransfusion:AutoCovenant(unitID) and not IsComparedObject(self.FaeTransfusion, ...) then 
				if GetToggle(2, "AoE") and Player:IsStayingTime() > 0.5 and MultiUnits:GetByRangeInCombat(40, 4, 3) >= 4 then 
					return self.FaeTransfusion:Show(icon)
				end
			end 
			
			-- Rogue 
			if playerClass == "ROGUE" and self.Sepsis:AutoCovenant(unitID) and not IsComparedObject(self.Sepsis, ...) then 
				if Unit(unitID):IsEnemy() and BurstIsON(unitID) and Unit(unitID):TimeToDie() > 11 and not Player:IsStealthed() then 
					return self.Sepsis:Show(icon)
				end 
			end 
			
			-- Priest 
			if playerClass == "PRIEST" and self.FaeBlessings:AutoCovenant(unitID) and not IsComparedObject(self.FaeBlessings, ...) then 
				if BurstIsON(unitID) and Unit("player"):CombatTime() > 0 and (not A.IamHealer or Unit(unitID):TimeToDie() <= 8) then 
					return self.FaeBlessings:Show(icon)
				end 
			end 
			
			-- Paladin 
			if playerClass == "PALADIN" and self.BlessingofSpring:AutoCovenant(unitID) and not IsComparedObject(self.BlessingofSpring, ...) then 
				if (Unit(unitID):IsEnemy() and Unit("player"):HasBuffs(self.BlessingofSpring.buffIDs) == 0) or (not Unit(unitID):IsEnemy() and Unit(unitID):HasBuffs(self.BlessingofSpring.buffIDs) == 0) then 
					return self.BlessingofSpring:Show(icon)
				end 
			end 
			
			if playerClass == "PALADIN" and self.BlessingofSummer:AutoCovenant(unitID) and not IsComparedObject(self.BlessingofSummer, ...) then 
				if (Unit(unitID):IsEnemy() and Unit("player"):HasBuffs(self.BlessingofSummer.buffIDs) == 0) or (not Unit(unitID):IsEnemy() and Unit(unitID):HasBuffs(self.BlessingofSummer.buffIDs) == 0) then 
					return self.BlessingofSummer:Show(icon)
				end 
			end 
			
			if playerClass == "PALADIN" and self.BlessingofAutumn:AutoCovenant(unitID) and not IsComparedObject(self.BlessingofAutumn, ...) then 
				if (Unit(unitID):IsEnemy() and Unit("player"):HasBuffs(self.BlessingofAutumn.buffIDs) == 0) or (not Unit(unitID):IsEnemy() and Unit(unitID):HasBuffs(self.BlessingofAutumn.buffIDs) == 0) then 
					return self.BlessingofAutumn:Show(icon)
				end 
			end 
			
			if playerClass == "PALADIN" and self.BlessingofWinter:AutoCovenant(unitID) and not IsComparedObject(self.BlessingofWinter, ...) then 
				if (Unit(unitID):IsEnemy() and Unit("player"):HasBuffs(self.BlessingofWinter.buffIDs) == 0) or (not Unit(unitID):IsEnemy() and Unit(unitID):HasBuffs(self.BlessingofWinter.buffIDs) == 0) then 
					return self.BlessingofWinter:Show(icon)
				end 
			end 
			
			-- Monk 
			if playerClass == "MONK" and self.FaelineStomp:AutoCovenant(unitID) and not IsComparedObject(self.FaelineStomp, ...) then 
				if Unit(unitID):IsEnemy() and (Unit(unitID):GetRange() <= 6 or (self.TigerPalm and self.TigerPalm:IsInRange(unitID))) then 
					return self.FaelineStomp:Show(icon)
				end 
			end 
			
			-- Mage 
			if playerClass == "MAGE" and self.ShiftingPower:AutoCovenant(unitID) and not IsComparedObject(self.ShiftingPower, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(15, 4, 6 + GetGCD()) >= 4 then 
					return self.ShiftingPower:Show(icon)
				end 
			end 
			
			-- Hunter 
			if playerClass == "HUNTER" and self.WildSpirits:AutoCovenant(unitID) and not IsComparedObject(self.WildSpirits, ...) then 
				if GetToggle(2, "AoE") and Player:IsStayingTime() > 0.5 and Unit(unitID):IsEnemy() and Unit(unitID):GetRange() <= 40 and ((A.IamRanger and MultiUnits:GetActiveEnemies() >= 6) or MultiUnits:GetByRangeInCombat(40, 6, 15) >= 6) and not Player:IsStealthed() then 
					return self.WildSpirits:Show(icon)
				end 
			end 
			
			-- Druid 
			if playerClass == "DRUID" and self.ConvoketheSpirits:AutoCovenant(unitID) and not IsComparedObject(self.ConvoketheSpirits, ...) then 
				if GetToggle(2, "AoE") and Player:IsStayingTime() > 0.5 and MultiUnits:GetByRangeInCombat(15, 4, 4 + GetGCD()) >= 4 then 	
					return self.ConvoketheSpirits:Show(icon)
				end
			end 
			
			-- DemonHunter 
			if playerClass == "DEMONHUNTER" and self.TheHunt:AutoCovenant(unitID) and not IsComparedObject(self.TheHunt, ...) then 
				if Unit(unitID):IsEnemy() and ((self.TheHunt:GetSpellCastTime() >= 180 and BurstIsON(unitID) and Unit(unitID):GetRange() > 20) or (self.TheHunt:GetSpellCastTime() < 180 and Unit(unitID):HasDeBuffs(self.TheHunt.ID, true) > 0 and Unit(unitID):GetRange() >= 10)) then 
					return self.TheHunt:Show(icon)
				end 
			end 
			
			-- DeathKnight 
			if playerClass == "DEATHKNIGHT" and self.DeathsDue:AutoCovenant(unitID) and not IsComparedObject(self.DeathsDue, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(8, 2) >= 2 then 
					return self.DeathsDue:Show(icon)
				end 
			end 
		end
		
		-- [[ Necrolord ]] 
		if Covenant.covenantID == 4 then 
			-- Shared 
			if self.Fleshcraft:AutoCovenant(unitID) and not IsComparedObject(self.Fleshcraft, ...) then 
				if Player:IsStayingTime() > 0.5 and Unit("player"):CombatTime() > 0 and (Unit("player"):IsExecuted() or (Unit("player"):HealthPercent() <= 40 and Unit("player"):TimeToDie() < 8)) then 
					return self.Fleshcraft:Show(icon)
				end 
			end 
			
			-- Warrior 
			if playerClass == "WARRIOR" and self.ConquerorsBanner:AutoCovenant(unitID) and not IsComparedObject(self.ConquerorsBanner, ...) then 
				if Unit("player"):HasBuffs(self.ConquerorsBanner.ID, true) == 0 or (Unit("player"):HasBuffsStacks(self.ConquerorsBanner.buffID, true) >= 15 and ((BurstIsON(unitID) and Player:IsStayingTime() > 0.5) or FriendlyTeam():GetTTD(2, 8, 15))) then 
					return self.ConquerorsBanner:Show(icon)
				end 
			end 
			
			-- Warlock 
			if playerClass == "WARLOCK" and self.DecimatingBolt:AutoCovenant(unitID) and not IsComparedObject(self.DecimatingBolt, ...) then 
				if Unit(unitID):IsEnemy() and Unit(unitID):TimeToDie() > 6 then 
					return self.DecimatingBolt:Show(icon)
				end 
			end 
			
			-- Shaman
			if playerClass == "SHAMAN" and self.PrimordialWave:AutoCovenant(unitID) and not IsComparedObject(self.PrimordialWave, ...) then 
				if Unit(unitID):IsEnemy() or Unit(unitID):TimeToDie() <= 14 then 
					return self.PrimordialWave:Show(icon)
				end 
			end 
			
			-- Rogue 
			if playerClass == "ROGUE" and self.SerratedBoneSpike:AutoCovenant(unitID) and not IsComparedObject(self.SerratedBoneSpike, ...) then 								
				if Unit(unitID):IsEnemy() and not Player:IsStealthed() then 
					local generateCP = Unit(unitID):HasDeBuffsStacks(self.SerratedBoneSpike.ID, true)
					if generateCP == 0 then 
						generateCP = 1
					end 
					
					if Player:ComboPointsDeficit() >= generateCP then 
						return self.SerratedBoneSpike:Show(icon)
					end 
				end 
			end 
			
			-- Priest 
			if playerClass == "PRIEST" and self.UnholyNova:AutoCovenant(unitID) and not IsComparedObject(self.UnholyNova, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(15, 4) >= 4 then 
					return self.UnholyNova:Show(icon)
				end 
			end 
			
			-- Paladin 
			if playerClass == "PALADIN" and self.VanquishersHammer:AutoCovenant(unitID) and not IsComparedObject(self.VanquishersHammer, ...) then 
				if Unit("player"):CombatTime() > 0 and Player:HolyPower() >= 3 and Unit(unitID):IsEnemy() then 
					return self.VanquishersHammer:Show(icon)
				end 
			end 
			
			-- Monk 
			if playerClass == "MONK" and self.BonedustBrew:AutoCovenant(unitID) and not IsComparedObject(self.BonedustBrew, ...) then 
				if GetToggle(2, "AoE") and Unit("player"):CombatTime() > 0 then 
					if  (A.PlayerSpec == CONST.MONK_BREWMASTER and ((not self.IronskinBrew and MultiUnits:GetByRangeInCombat(8, 4) >= 4) or (self.IronskinBrew and self.IronskinBrew:GetSpellChargesFrac() <= 1))) or 
						(A.PlayerSpec == CONST.MONK_WINDWALKER and MultiUnits:GetByRangeInCombat(8, 3) >= 3) or 
						(A.PlayerSpec == CONST.MONK_MISTWEAVER and not Unit(unitID):IsEnemy() and HealingEngine.GetBelowHealthPercentUnits(70, 40) >= 2)
					then 
						return self.BonedustBrew:Show(icon)
					end 
				end 
			end 
			
			-- Mage 
			if playerClass == "MAGE" and self.Deathborne:AutoCovenant(unitID) and not IsComparedObject(self.Deathborne, ...) then 
				if BurstIsON(unitID) and Unit(unitID):IsEnemy() and Unit("player"):CombatTime() > 0 and Player:IsStaying() then 
					return self.Deathborne:Show(icon)
				end 
			end 
			
			-- Hunter 
			if playerClass == "HUNTER" and self.DeathChakram:AutoCovenant(unitID) and not IsComparedObject(self.DeathChakram, ...) then 
				if Unit(unitID):IsEnemy() and Player:FocusDeficit() >= 3 * 7 then 
					return self.DeathChakram:Show(icon)
				end 
			end 
			
			-- Druid 
			if playerClass == "DRUID" and self.AdaptiveSwarm:AutoCovenant(unitID) and not IsComparedObject(self.AdaptiveSwarm, ...) then 
				if (Unit(unitID):IsEnemy() and Unit(unitID):TimeToDie() >= 12) or (not Unit(unitID):IsEnemy() and Unit(unitID):TimeToDie() > 12 and Unit(unitID):HealthPercent() < 70) then 
					return self.AdaptiveSwarm:Show(icon)
				end 
			end 
			
			-- DemonHunter 
			if playerClass == "DEMONHUNTER" and self.FoddertotheFlame:AutoCovenant(unitID) and not IsComparedObject(self.FoddertotheFlame, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(15, 5, 30) >= 5 and Unit("player"):CombatTime() >= 4 then 
					return self.FoddertotheFlame:Show(icon)
				end 
			end 
			
			-- DeathKnight 
			if playerClass == "DEATHKNIGHT" and self.AbominationLimb:AutoCovenant(unitID) and not IsComparedObject(self.AbominationLimb, ...) then 
				if GetToggle(2, "AoE") and MultiUnits:GetByRangeInCombat(20, 4, 12) >= 4 and Unit("player"):CombatTime() >= 4 then 
					return self.AbominationLimb:Show(icon)
				end 
			end 			
		end		
	end 
end 

--------------------------------------
-- Covenant
--------------------------------------
function A.CovenantIsON()
	-- @return boolean 
	-- Note: Used by :RunAutoCovenants
	return Covenant.covenantID and GetToggle(1, "Covenant")
end 

function A:IsCovenantLearned()
	-- @return boolean 
	-- Note: Used by Action.lua for [3] tab 
	return self.isCovenant and self.covenantID == Covenant.covenantID
end 

function A:IsCovenantAvailable()
	-- @return boolean 
	-- Note: Used by Actions.lua for :IsCastable (only Spell type)
	return (macroInstalled or (self.covenantClass and CovenantClass.installed) or (not self.covenantClass and CovenantSignature.installed)) and self:IsCovenantLearned() and GetToggle(1, "Covenant")
end 

--------------------------------------
-- Soulbind 
--------------------------------------
function A:IsSoulbindLearned()
	-- @return boolean 
	return Covenant:HasSoulbind((self:Info()))
end 