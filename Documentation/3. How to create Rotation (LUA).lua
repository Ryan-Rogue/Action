--[[
-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
If you plan to build profile without use lua then you can skip this guide

-------------------------------------------------------------------------------
-- №1: Create snippet 
-------------------------------------------------------------------------------
Write in chat "/tmw options" > LUA Snippets > Profile (left side) > "+" > Write name of specialization in title of the snippet

--]]
-------------------------------------------------------------------------------
-- №2: Set profile defaults 
-------------------------------------------------------------------------------
-- Map locals to get faster performance
local _G, setmetatable					= _G, setmetatable
local TMW 								= _G.TMW 
local A 								= _G.Action
local Create							= A.Create

-- Create actions (spells, items, potions, auras, azerites, talents and etc)
-- Structure:
Action[PLAYERSPEC] = {			-- PLAYERSPEC is Constance (example: ACTION_CONST_MONK_BREWMASTER) which we created in ProfileUI
	Key = Create({ 				-- Key is name of the action which will be used in APL (Action Priority List)
	--[[@usage: attributes (table)
		Required: 
			Type (@string)	- Spell|SpellSingleColor|Item|ItemSingleColor|Potion|Trinket|TrinketBySlot|HeartOfAzeroth|SwapEquip (TrinketBySlot is only in CORE!)
			ID (@number) 	- spellID | itemID | textureID (textureID only for Type "SwapEquip")
			Color (@string) - only if type is Spell|SpellSingleColor|Item|ItemSingleColor|SwapEquip, this will set color which stored in A.Data.C[Color] or here can be own hex 
	 	Optional: 
			Desc (@string) uses in UI near Icon tab (usually to describe relative action like Penance can be for heal and for dps and it's different actions but with same name)
			QueueForbidden (@boolean) uses to preset for action fixed queue valid 
			BlockForbidden (@boolean) uses to preset for action fixed block valid 
			Texture (@number) valid only if Type is Spell|Item|Potion|Trinket|HeartOfAzeroth|SwapEquip
			FixedTexture (@number or @file) valid only if Type is Spell|Item|Potion|Trinket|SwapEquip
			MetaSlot (@number) allows set fixed meta slot use for action whenever it will be tried to set in queue 
			Hidden (@boolean) allows to hide from UI this action 
			isStance (@number) will check in :GetCooldown cooldown timer by GetShapeshiftFormCooldown function instead of default
			isTalent (@boolean) will check in :IsCastable method condition through :IsTalentLearned(), only if Type is Spell|SpellSingleColor|HeartOfAzeroth				
			isReplacement (@boolean) will check in :IsCastable method condition through :IsExists(true), only if Type is Spell|SpellSingleColor|HeartOfAzeroth	
			skipRange (@boolean) will skip check in :IsInRange method which is also used by Queue system, only if Type is Spell|SpellSingleColor|Item|ItemSingleColor|Trinket|TrinketBySlot|HeartOfAzeroth
			covenantID (@number) will check in :IsCastable method condition through :IsCovenantAvailable(), only if Type is Spell|SpellSingleColor	
			Equip1, Equip2 (@function) between which equipments do swap, used in :IsExists() method, only if Type is SwapEquip
			... any custom key-value will be inserted also 
	]]
	}),
}

-- For racials use following values as Key from racial key:
local RacialKeys = {
	Worgen = "Darkflight",
	VoidElf = "SpatialRift",
	NightElf = "Shadowmeld",
	LightforgedDraenei = "LightsJudgment",
	KulTiran = "Haymaker",
	Human = "EveryManforHimself",
	Gnome = "EscapeArtist",
	Dwarf = "Stoneform",
	Draenei = "GiftoftheNaaru",
	DarkIronDwarf = "Fireblood",
	Pandaren = "QuakingPalm",
	ZandalariTroll = "Regeneratin",
	Scourge = "WilloftheForsaken",
	Troll = "Berserking",
	Tauren = "WarStomp",
	Orc = "BloodFury",
	Nightborne = "ArcanePulse",
	MagharOrc = "AncestralCall",
	HighmountainTauren = "BullRush",
	BloodElf = "ArcaneTorrent",
	Goblin = "RocketJump",
}

-- To create essences use next code:
Action:CreateEssencesFor(PLAYERSPEC)		-- where PLAYERSPEC is Constance (example: ACTION_CONST_MONK_BREWMASTER)
-- It will push to Action[PLAYERSPEC] already preconfigured keys from HeartOfAzeroth.lua in the next format sorted by specialization role:
-- Note: Does nothing if game hasn't 8.2 API for essences
local AzeriteEssences = {
	ConcentratedFlame 						= { Type = "HeartOfAzeroth", ID = 295373 	}, -- filler (40y, low priority) HPS / DPS 
	WorldveinResonance						= { Type = "HeartOfAzeroth", ID = 295186 	}, -- filler (small stat burst, cd1min, high priority)
	RippleinSpace							= { Type = "HeartOfAzeroth", ID = 302731 	}, -- movement / -10% deffensive (x3 rank)
	MemoryofLucidDreams						= { Type = "HeartOfAzeroth", ID = 298357 	}, -- burst (100% power regeneration)
	AzerothsUndyingGift						= { Type = "HeartOfAzeroth", ID = 293019 	}, -- -20% 4sec cd1min / -40% 2sec and then -20% 2sec cd45sec
	AnimaofDeath							= { Type = "HeartOfAzeroth", ID = 294926 	}, -- aoe self heal cd2.5-2min
	AegisoftheDeep							= { Type = "HeartOfAzeroth", ID = 298168 	}, -- physical attack protection cd2-1.5min
	EmpoweredNullBarrier					= { Type = "HeartOfAzeroth", ID = 295746 	}, -- magic attack protection cd3-2.3min
	SuppressingPulse						= { Type = "HeartOfAzeroth", ID = 293031 	}, -- aoe -70% slow and -25% attack speed cd60-45sec
	Refreshment								= { Type = "HeartOfAzeroth", ID = 296197 	}, -- filler cd15sec
	Standstill								= { Type = "HeartOfAzeroth", ID = 296094 	}, -- burst (big absorb incoming dmg and hps) cd3min
	LifeBindersInvocation					= { Type = "HeartOfAzeroth", ID = 293032 	}, -- burst aoe (big heal) cd3min
	OverchargeMana							= { Type = "HeartOfAzeroth", ID = 296072 	}, -- filler (my hps < incoming unit dps) cd30sec
	VitalityConduit							= { Type = "HeartOfAzeroth", ID = 296230 	}, -- aoe cd60-45sec 
	FocusedAzeriteBeam						= { Type = "HeartOfAzeroth", ID = 295258 	}, -- aoe 
	GuardianofAzeroth						= { Type = "HeartOfAzeroth", ID = 295840 	}, -- burst 
	BloodoftheEnemy							= { Type = "HeartOfAzeroth", ID = 297108 	}, -- aoe 
	PurifyingBlast							= { Type = "HeartOfAzeroth", ID = 295337 	}, -- filler (aoe, high priority)
	TheUnboundForce							= { Type = "HeartOfAzeroth", ID = 298452 	}, -- filler (high priority)
}

-- This code making shorter access to both tables Action[PLAYERSPEC] and Action
-- However if you prefer long access it still can be used like Action[PLAYERSPEC].Guard:IsReady(), it doesn't make any conflict if you will skip shorter access
-- So with shorter access you can just do A.Guard:IsReady() instead of Action[PLAYERSPEC].Guard:IsReady()
local A = setmetatable(Action[PLAYERSPEC], { __index = Action })

-- Example:
Action[ACTION_CONST_MONK_BREWMASTER] = {
	POWS 									= Create({ Type = "Spell", ID = 17}),
	PetKick 								= Create({ Type = "Spell", ID = 47482, Color = "RED", Desc = "RED" }),  
	POWS_Rank2 								= Create({ Type = "SpellSingleColor", ID = 17, Color = "BLUE", Desc = "Rank2" }), 
	TrinketTest 							= Create({ Type = "Trinket", ID = 122530, QueueForbidden = true }),
	TrinketTest2 							= Create({ Type = "Trinket", ID = 159611, QueueForbidden = true }),	
	PotionTest 								= Create({ Type = "Potion", ID = 142117, QueueForbidden = true }),
	-- Mix will use action with ID 2983 as itself Rogue's Sprint but it will display Power Word: Shield with applied over color "LIGHT BLUE" and UI will displays Note with "Test", also Queue system will not run Queue with this action
	Sprint 									= Create({ Type = "SpellSingleColor", ID = 2983, QueueForbidden = true, Desc = "Test", Color = "LIGHT BLUE", Texture = 17}),
	Guard								  	= Create({ Type = "Spell", ID = 115295 	}),	
	HealingElixir						  	= Create({ Type = "Spell", ID = 122281, isTalent = true 	}),
	NimbleBrew 								= Create({ Type = "Item", ID = 137648, Color = "RED" }),
	PotionofReconstitution				 	= Create({ Type = "Potion", ID = 168502 	}), 	
	CoastalManaPotion						= Create({ Type = "Potion", ID = 152495 	}),	
	-- Hidden 
	TigerTailSweep							= Create({ Type = "Spell", ID = 264348, Hidden = true }), -- 4/1 Talent +2y increased range of LegSweep	
	RisingMist								= Create({ Type = "Spell", ID = 274909, Hidden = true }), -- 7/3 Talent "Fistweaving Rotation by damage healing"
	SpiritoftheCrane						= Create({ Type = "Spell", ID = 210802, Hidden = true }), -- 3/2 Talent "Mana regen by BlackoutKick"
	Innervate								= Create({ Type = "Spell", ID = 29166, Hidden = true }), -- Aura Buff
	TeachingsoftheMonastery					= Create({ Type = "Spell", ID = 202090, Hidden = true }), -- Aura Buff
	-- Racial
	ArcaneTorrent                         	= Create({ Type = "Spell", ID = 50613 	}),
	BloodFury                             	= Create({ Type = "Spell", ID = 20572  	}),
	Fireblood 							  	= Create({ Type = "Spell", ID = 265221 	}),
	AncestralCall						  	= Create({ Type = "Spell", ID = 274738 	}),
	Berserking                            	= Create({ Type = "Spell", ID = 26297	}),
	ArcanePulse							  	= Create({ Type = "Spell", ID = 260364	}),
	QuakingPalm							  	= Create({ Type = "Spell", ID = 107079 	}),
	Haymaker							  	= Create({ Type = "Spell", ID = 287712 	}), 
	WarStomp							  	= Create({ Type = "Spell", ID = 20549 	}),
	BullRush							  	= Create({ Type = "Spell", ID = 255654 	}),	
	GiftofNaaru 						  	= Create({ Type = "Spell", ID = 59544	}),
	Shadowmeld							  	= Create({ Type = "Spell", ID = 58984	}), 
	Stoneform						  		= Create({ Type = "Spell", ID = 20594	}), 
	WilloftheForsaken				  		= Create({ Type = "Spell", ID = 7744	}), 
	EscapeArtist						  	= Create({ Type = "Spell", ID = 20589	}), 
	EveryManforHimself				  		= Create({ Type = "Spell", ID = 59752	}), 
}
Action:CreateEssencesFor(ACTION_CONST_MONK_BREWMASTER)
local A = setmetatable(Action[ACTION_CONST_MONK_BREWMASTER], { __index = Action })

-------------------------------------------------------------------------------
-- №3: Create rotations
-------------------------------------------------------------------------------
--[[
If you didn't read 1. Introduction.lua, please, read it before you will read below
]]

-- Structure (described on shorter access):
A['@number'] = function(icon)		-- @number is from 1 to 8, where for example 1 is equal for "Meta Icon" #1 in "Shown Main" 
	-- icon is refference for that "Meta Icon" e.g. for that frame 
	
	-- your code:
	-- Key is what you used in Action[PLAYERSPEC] table 
	if A.Key:IsReady('@string', '@boolean') and "next rotation conditions which you want to use" then 																			                                           	
        return A.Key:Show(icon)    -- :Show(icon) method will make 'icon' frame display texture taken from 'Key'    		
    end 	
	
	--[[ mostly often useable methods (more info about methods in Action.lua):
	:IsReady(unit, skiprange)					-- checks block by Queue and SetBlocker, range for unit (if skiprange isn't true), action available (cooldown, useable by power as reactive e.g. example Execute) 
	:IsReadyP(unit, skiprange, skiplua)			-- does same but it skip block check 
	:AutoRacial(unit, isReadyCheck)				-- is already preconfigured template with logic conditions. isReadyCheck if true then will use method :IsReady 
	:AutoRacialP(unit, isReadyCheck)			-- same but without logic conditions, means will check only available (range, imun, school lock, cooldown and etc)
	:AutoHeartOfAzeroth(unit, skipAuto)			-- is already preconfigured template with logic conditions. skipAuto will skip logic and check only available (range, imun, school lock, cooldown and etc)
	:AutoHeartOfAzerothP(unit)					-- same but without logic conditions, means will check only available 
	]]
end

-- If you don't have any rotation or any time to make each meta frame rotation you can skip them and create just [3] for Single Rotation
-- Even if rest meta functions will be omitted 'The Action' core still will do shared general things for them (more info in Action.lua at the end)

-- Example:
-- Map to make it faster 
local GetToggle 				= A.GetToggle
local Player					= A.Player
local Unit 						= A.Unit
local IsUnitEnemy				= A.IsUnitEnemy
local IsUnitFriendly			= A.IsUnitFriendly
local LossOfControl 			= A.LossOfControl
local player 					= "player"

local Temp 						= {
	TotalAndPhys 				= {"DamagePhysImun", "TotalImun"},
}

local function IsSchoolFree()
	return LossOfControl:IsMissed("SILENCE") and LossOfControl:Get("SCHOOL_INTERRUPT", "NATURE") == 0
end 

local function SelfDefensives()
	if Unit(player):CombatTime() == 0 then 
		return 
	end 
	
	-- HealingElixir
	local HealingElixir = GetToggle(2, "HealingElixir")
	if 	HealingElixir >= 0 and A.HealingElixir:IsReady(player) and IsSchoolFree() and
		(
			( 	-- Auto 
				HealingElixir >= 85 and 
				(
					Unit(player):HealthPercent() <= 20 or
					(						
						Unit(player):HealthPercent() < 70 and 
						A.HealingElixir:GetSpellChargesFrac() > 1.1
					) or 
					(
						Unit(player):HealthPercent() < 40 and 
						Unit(player):IsTanking("target", 8)
					) 
				)
			) or 
			(	-- Custom
				HealingElixir < 85 and 
				Unit(player):HealthPercent() <= HealingElixir
			)
		) 
	then 
		return A.HealingElixir
	end 
end 

-- [3] is Rotation
A[3] = function(icon)
	local Deffensive = SelfDefensives()
	if Deffensive then 
		return Deffensive:Show(icon)
	end 
	
	local unit 
	local DamageRotation, HealingRotation
	function DamageRotation(unit)
		if A.ArcaneTorrent:AutoRacial(unit, true) then 
			return A.ArcaneTorrent:Show(icon)
		end 	
		
		-- blackout_strike
		if A.BlackoutStrike:IsReady(unit) and LossOfControl:IsMissed("DISARM") and A.BlackoutStrike:AbsentImun(unit, Temp.TotalAndPhys) then -- AbsentImun is better to locate at the end of conditions due performance reasons
			return A.BlackoutStrike:Show(icon)
		end

		-- self healing 
		if HealingRotation(player) then 
			return true 
		end 
	end 
	
	function HealingRotation(unit)
		if A.ArcaneTorrent:AutoRacial(unit, true) then 
			return A.ArcaneTorrent:Show(icon)
		end 	
		
		if IsSchoolFree() and A.Vivify:IsReady(unit) and Player:IsStaying() and A.Vivify:PredictHeal(unit) and A.Vivify:AbsentImun(unit) then 
			return A.Vivify:Show(icon)
		end 
	end 
	
	-- Mouseover 
	-- if you use IsUnitEnemy or IsUnitFriendly with "mouseover" or "targettarget" or "focustarget" then make sure what you created checkbox for ProfileUI with same DB name in LOWER CASE! Otherwise it will bring you an a error 
	if IsUnitEnemy("mouseover") then 
		unit = "mouseover"
		
		if DamageRotation(unit) then 
			return true 
		end 
	end 
	
	if IsUnitFriendly("mouseover") then 
		unit = "mouseover"	
		
		if HealingRotation(unit) then 
			return true 
		end 			
	end 
	
	-- Target 	
	if IsUnitEnemy("target") then 
		unit = "target"
		
		if DamageRotation(unit) then 
			return true 
		end 
	end 
	
	if IsUnitFriendly("target") then -- IsUnitEnemy("targettarget") is valid only inside here because macros supposed use damage rotation if @target is friendly and his @targettarget is enemy
		unit = "target"
		
		if HealingRotation(unit) then 
			return true 
		end 
	end 	
end  

--[[
You're not limited to use snippets, their fixed names and any lua codes inside them (limit if they are more than 6k+ lines) 
So you can even use HeroLib API actually, that will be described in another documentation guide

-------------------------------------------------------------------------------
-- №4: Apply rotations on TellMeWhen
-------------------------------------------------------------------------------
If you use "[GGL] Template" then you can skip it because it has already preconfigured it 

For "Shown Main" group:
1. You have to create in /tmw new profile group with 8 icons with type "Condition Icon"
2. Right click on "Condition Icon" make checked "Hide Always"
3. At the bottom you will see "Conditions" tab, go there and click "+" to add condition "LUA"
4. Write next code: 
Action.Rotation(thisobj) -- this is slower than method below 
Rotation(thisobj)		 -- this is faster method than above since TMW lua has setfenv and this function is linked as pointer to Action.Rotation e.g. Env.Rotation == Action.Rotation but works much faster 
5. Click and drag itself "Condition Icon" frame to "Shown Main" group and select from opened menu "Add to meta"
6. Make sure if you moving "Condition Icon" #1 you additing it to "Meta Icon" #1 also in "Shown Main" 
7. Do same for each "Condition Icon"

For "Shown Cast Bars":
1. You have to create in /tmw new profile group with 3-9 icons with type "Casting" 
2. Right click on "Casting" make checked "Hide Always"
3. At the bottom you will see "Conditions" tab, go there and click "+" to add condition "LUA"
4. Write shared code which can be stored in ProfileUI snippet 
5. Don't forget which colors as casting bar icons use (look any [GGL] profile for colors), and also make sure what profile has "Flat" texture (you can check it in /tmw > 'General' > 'Main settings' (or 'Main options')
--]]