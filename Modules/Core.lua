local TMW 											= TMW 
local CNDT 											= TMW.CNDT
local Env 											= CNDT.Env

local A   											= Action	
local A_Hide 										= A.Hide
local Create 										= A.Create
local GetToggle										= A.GetToggle
local BossMods_Pulling								= A.BossMods_Pulling
local IsExplosivesExists							= A.IsExplosivesExists
local IsQueueReady									= A.IsQueueReady
local QueueData										= A.Data.Q

local UnitCooldown									= A.UnitCooldown
local Unit											= A.Unit 
local Player										= A.Player 
local LoC 											= A.LossOfControl
local MultiUnits									= A.MultiUnits

local LoC_GetExtra									= LoC.GetExtra

local _G, math										= _G, math 
local huge 											= math.huge

local UnitBuff										= _G.UnitBuff
local UnitIsFriend									= _G.UnitIsFriend

local GetSpellInfo									= _G.GetSpellInfo
local SpellIsTargeting								= _G.SpellIsTargeting
local IsMouseButtonDown								= _G.IsMouseButtonDown

local ACTION_CONST_STOPCAST							= _G.ACTION_CONST_STOPCAST
local ACTION_CONST_AUTOTARGET						= _G.ACTION_CONST_AUTOTARGET
local ACTION_CONST_LEFT								= _G.ACTION_CONST_LEFT
local ACTION_CONST_RIGHT							= _G.ACTION_CONST_RIGHT
local ACTION_CONST_PAUSECHECKS_DISABLED 			= _G.ACTION_CONST_PAUSECHECKS_DISABLED
local ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST		= _G.ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST
local ACTION_CONST_PAUSECHECKS_IS_MOUNTED			= _G.ACTION_CONST_PAUSECHECKS_IS_MOUNTED
local ACTION_CONST_PAUSECHECKS_WAITING				= _G.ACTION_CONST_PAUSECHECKS_WAITING
local ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING	= _G.ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING
local ACTION_CONST_PAUSECHECKS_LOOTFRAME			= _G.ACTION_CONST_PAUSECHECKS_LOOTFRAME
local ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK		= _G.ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK
local ACTION_CONST_SPELLID_COUNTER_SHOT				= _G.ACTION_CONST_SPELLID_COUNTER_SHOT

local ClassPortaits 								= {
	["WARRIOR"] 									= ACTION_CONST_PORTRAIT_WARRIOR,
	["PALADIN"] 									= ACTION_CONST_PORTRAIT_PALADIN,
	["HUNTER"] 										= ACTION_CONST_PORTRAIT_HUNTER,
	["ROGUE"] 										= ACTION_CONST_PORTRAIT_ROGUE,
	["PRIEST"] 										= ACTION_CONST_PORTRAIT_PRIEST,
	["DEATHKNIGHT"] 								= ACTION_CONST_PORTRAIT_DEATHKNIGHT, 	-- Custom because it making conflict with Obliteration
	["SHAMAN"]	 									= ACTION_CONST_PORTRAIT_SHAMAN, 		-- Custom because it making conflict with Bloodlust
	["MAGE"] 										= ACTION_CONST_PORTRAIT_MAGE,
	["WARLOCK"] 									= ACTION_CONST_PORTRAIT_WARLOCK,
	["MONK"] 										= ACTION_CONST_PORTRAIT_MONK,
	["DRUID"] 										= ACTION_CONST_PORTRAIT_DRUID,
	["DEMONHUNTER"] 								= ACTION_CONST_PORTRAIT_DEMONHUNTER,
}

local GetKeyByRace 									= {
	-- I use this to check if we have created for spec needed spell 
	Worgen 											= "Darkflight",
	VoidElf 										= "SpatialRift",
	NightElf 										= "Shadowmeld",
	LightforgedDraenei 								= "LightsJudgment",
	KulTiran 										= "Haymaker",
	Human 											= "EveryManforHimself",
	Gnome 											= "EscapeArtist",
	Dwarf 											= "Stoneform",
	Draenei 										= "GiftoftheNaaru",
	DarkIronDwarf 									= "Fireblood",
	Pandaren 										= "QuakingPalm",
	ZandalariTroll 									= "Regeneratin",
	Scourge 										= "WilloftheForsaken",
	Troll 											= "Berserking",
	Tauren 											= "WarStomp",
	Orc 											= "BloodFury",
	Nightborne 										= "ArcanePulse",
	MagharOrc 										= "AncestralCall",
	HighmountainTauren 								= "BullRush",
	BloodElf 										= "ArcaneTorrent",
	Goblin 											= "RocketJump",
}

local player										= "player"
local target 										= "target"
local mouseover										= "mouseover"
local targettarget									= "targettarget"
local arena 										= "arena"

-------------------------------------------------------------------------------
-- Conditions
-------------------------------------------------------------------------------
local FoodAndDrink 									= {
	[GetSpellInfo(43180)] 							= true, -- Food 
	[GetSpellInfo(27089)] 							= true, -- Drink
	[GetSpellInfo(257427)] 							= true, -- FoodDrink
	[GetSpellInfo(167152)] 							= true, -- Mage's eat
}
local function IsDrinkingOrEating()
	-- @return boolean 
	local auraName
	for i = 1, huge do 
		auraName = UnitBuff(player, i, "HELPFUL PLAYER")
		if not auraName then 
			break 
		elseif FoodAndDrink[auraName] then 
			return true 
		end 
	end 
end 

function A.PauseChecks()  	
	-- Chat, BindPad, TellMeWhen
	if ACTIVE_CHAT_EDIT_BOX or (BindPadFrame and BindPadFrame:IsVisible()) or not TMW.Locked then 
		return ACTION_CONST_PAUSECHECKS_DISABLED
	end 
	
    if GetToggle(1, "CheckVehicle") and Unit(player):InVehicle() then
        return ACTION_CONST_PAUSECHECKS_DISABLED
    end	
	
	if 	(GetToggle(1, "CheckDeadOrGhost") and Unit(player):IsDead()) or 
		(
			GetToggle(1, "CheckDeadOrGhostTarget") and 
			(
				(Unit(target):IsDead() and not UnitIsFriend(player, target) and (not A.IsInPvP or Unit(target):Class() ~= "HUNTER")) or 
				(GetToggle(2, mouseover) and Unit(mouseover):IsDead() and not UnitIsFriend(player, mouseover) and (not A.IsInPvP or Unit(mouseover):Class() ~= "HUNTER"))
			)
		) 
	then 																																																									-- exception in PvP Hunter 
		return ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST
	end 		
	
	if GetToggle(1, "CheckMount") and Player:IsMounted() then 																																												-- exception Divine Steed and combat mounted auras
		return ACTION_CONST_PAUSECHECKS_IS_MOUNTED
	end 

	if GetToggle(1, "CheckCombat") and Unit(player):CombatTime() == 0 and Unit(target):CombatTime() == 0 and not Player:IsStealthed() and BossMods_Pulling() == 0 then 																		-- exception Stealthed and DBM pulling event 
		return ACTION_CONST_PAUSECHECKS_WAITING
	end 	
	
	if GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() then
		return ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return ACTION_CONST_PAUSECHECKS_LOOTFRAME
	end	
	
	if GetToggle(1, "CheckEatingOrDrinking") and Unit(player):CombatTime() == 0 and Player:IsStaying() and IsDrinkingOrEating() then
		return ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
A.PauseChecks = A.MakeFunctionCachedStatic(A.PauseChecks)

local A_PauseChecks = A.PauseChecks

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.Trinket1 					= Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET1,	 			BlockForbidden = true, Desc = "Upper Trinket (/use 13)" 							})
A.Trinket2 					= Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET2, 			BlockForbidden = true, Desc = "Lower Trinket (/use 14)"								})
A.HS						= Create({ Type = "Item", 			ID = 5512, 										QueueForbidden = true, Desc = "[6] HealthStone" 									})
A.AbyssalHealingPotion		= Create({ Type = "Item", 			ID = 169451, 									QueueForbidden = true																})
A.GladiatorMedallion		= Create({ Type = "Spell", 			ID = ACTION_CONST_SPELLID_GLADIATORS_MEDALLION, QueueForbidden = true, BlockForbidden = true, IsTalent = true, Desc = "[5] Trinket" })
A.HonorMedallion			= Create({ Type = "Spell", 			ID = ACTION_CONST_SPELLID_HONOR_MEDALLION, 		QueueForbidden = true, BlockForbidden = true, Desc = "[5] Trinket" 					})

function A.CanUseHealthstoneOrAbyssalHealingPotion()
	-- @return object 
	if not Player:IsStealthed() then 			 
		local Healthstone = GetToggle(1, "HealthStone") 
		if Healthstone >= 0 then 
			if A.HS:IsReady(player, true) then 			
				if Healthstone >= 100 then -- AUTO 
					if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 then 
						return A.HS
					end 
				elseif Unit(player):HealthPercent() <= Healthstone then 
					return A.HS							 
				end
			elseif A.AbyssalHealingPotion:IsReady(player, true) then 			
				if Healthstone >= 100 then -- AUTO 
					if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 and Unit(player):HealthDeficit() >= A.AbyssalHealingPotion:GetItemDescription()[1] then 
						return A.AbyssalHealingPotion
					end 
				elseif Unit(player):HealthPercent() <= Healthstone then 
					return A.AbyssalHealingPotion						 
				end
			end 
		end 
	end
end 

function A.Rotation(icon)
	if not A.IsInitialized or not A[A.PlayerSpec] then 
		return A_Hide(icon)		
	end 	
	
	local meta = icon.ID
	
	-- [1] CC / [2] Kick 
	if meta <= 2 then 
		if A[A.PlayerSpec][meta] and A[A.PlayerSpec][meta](icon) then 
			return true
		end 
		return A_Hide(icon)
	end 
	
	-- [5] Trinket 
	if meta == 5 then 
		local result, isApplied, RacialAction
		
		-- Use racial available trinkets if we don't have additional RACIAL_LOC
		-- Note: Additional RACIAL_LOC is the main reason why I avoid here :AutoRacial (see below 'if isApplied then ')
		if GetToggle(1, "Racial") then 
			RacialAction 		= A[A.PlayerSpec][GetKeyByRace[A.PlayerRace]]			
			local RACIAL_LOC 	= LoC_GetExtra[A.PlayerRace]							-- Loss Of Control 
			if RACIAL_LOC and RacialAction and RacialAction:IsReady(player, true) and RacialAction:IsExists() then 
				result, isApplied = LoC:IsValid(RACIAL_LOC.Applied, RACIAL_LOC.Missed, A.PlayerRace == "Dwarf" or A.PlayerRace == "Gnome")
				if result then 
					return RacialAction:Show(icon)
				end 
			end 		
		end	
		
		-- Use specialization spell trinkets
		if A[A.PlayerSpec][meta] and A[A.PlayerSpec][meta](icon) then  
			return true 			
		end 	

		-- Use (H)G.Medallion
		local Medallion = LoC_GetExtra["GladiatorMedallion"]
		if Medallion and Medallion.isValid() and LoC:IsValid(Medallion.Applied) then 			
			return A.GladiatorMedallion:Show(icon)
		end 		
		
		-- Use racial if nothing is not available 
		if isApplied then 
			return RacialAction:Show(icon)
		end 
			
		return A_Hide(icon)		 
	end 
	
	local PauseChecks = A_PauseChecks()
	if PauseChecks then
		if meta == 3 then 
			return A:Show(icon, PauseChecks)
		end  
		return A_Hide(icon)		
	end 		
	
	-- [6] Passive: @player, @raid1, @arena1 
	if meta == 6 then 
		-- Shadowmeld
		if A[A.PlayerSpec].Shadowmeld and A[A.PlayerSpec].Shadowmeld:AutoRacial(player) then 
			return A[A.PlayerSpec].Shadowmeld:Show(icon)
		end 
		
		-- Stopcasting
		if GetToggle(1, "StopCast") then 
			local castName, _, _, notInterruptable = Unit(player):IsCasting() 
			if castName then 
				-- Catch Counter Shot 
				if A.IsInPvP and not notInterruptable and UnitCooldown:GetCooldown(arena, ACTION_CONST_SPELLID_COUNTER_SHOT) > UnitCooldown:GetMaxDuration(arena, ACTION_CONST_SPELLID_COUNTER_SHOT) - 1 and UnitCooldown:IsSpellInFly(arena, ACTION_CONST_SPELLID_COUNTER_SHOT) then 
					local Caster = UnitCooldown:GetUnitID(arena, ACTION_CONST_SPELLID_COUNTER_SHOT)
					if Caster and Unit(Caster):GetRange() <= 40 and Unit(player):HasBuffs("TotalImun") == 0 and Unit(player):HasBuffs("KickImun") == 0 then 
						return A:Show(icon, ACTION_CONST_STOPCAST)
					end 
				end 
			end 
		end 
		
		-- Cursor 
		if A.GameTooltipClick and not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then 			
			if A.GameTooltipClick == "LEFT" then 
				return A:Show(icon, ACTION_CONST_LEFT)			 
			elseif A.GameTooltipClick == "RIGHT" then 
				return A:Show(icon, ACTION_CONST_RIGHT)
			end 
		end 
		
		-- ReTarget ReFocus 
		if (A.Zone == arena or A.Zone == "pvp") and A:GetTimeSinceJoinInstance() >= 30 then 
			if A.LastTarget and not A.LastTargetIsExists then 
				return A:Show(icon, A.LastTargetTexture)
			end 
			
			if A.LastFocus and not A.LastFocusIsExists then 
				return A:Show(icon, A.LastFocusTexture)
			end 
		end 
		
		-- Healthstone | AbyssalHealingPotion
		local HealingObject = A.CanUseHealthstoneOrAbyssalHealingPotion() 
		if HealingObject then 
			return HealingObject:Show(icon)
		end 		
		
		-- AutoTarget 
		if GetToggle(1, "AutoTarget") and not A.IamHealer and Unit(player):CombatTime() > 0 and not Unit(target):IsExplosives() then 		
			if IsExplosivesExists() then
				return A:Show(icon, ACTION_CONST_AUTOTARGET)			  				 
			end 
			
			if  (not Unit(target):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and Unit(target):CombatTime() == 0 and Unit(target):IsEnemy())) 	-- No existed or switch target in PvE if we accidentally selected out of combat unit  			
				and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(nil, 1) >= 1) or A.Zone == "pvp") 												-- If rotation mode is PvE and in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			then 
				return A:Show(icon, ACTION_CONST_AUTOTARGET)
			end 
			
			-- Patch 8.2
			-- 1519 is The Eternal Palace: Precipice of Dreams
			-- Switch target if accidentally selected player in group under Delirium Realm (DeBuff)
			if not A.IsInPvP and A.ZoneID == 1519 and Unit(target):IsEnemy() and Unit(target):IsPlayer() and Unit(target):InGroup() then 
				return A:Show(icon, ACTION_CONST_AUTOTARGET)
			end 
		end 
	end 
	
	-- Queue System
	if IsQueueReady(meta) then                                              
		return QueueData[1]:Show(icon)				 
    end 
	
	-- Hide frames which are not used by profile
	if not A[A.PlayerSpec][meta] then 
		return A_Hide(icon)
	end 	
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-2, @raid1-3, @arena1-3
	if A[A.PlayerSpec][meta] and A[A.PlayerSpec][meta](icon) then 
		return true 
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not GetToggle(1, "DisableClassPortraits") then 
		return A:Show(icon, ClassPortaits[A.PlayerClass])
	end 
	
	A_Hide(icon)			
end 

-- setfenv will make working it way faster as lua condition for TMW frames 
Env.Rotation = A.Rotation 