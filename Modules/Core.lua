local TMW 					= TMW 

local A   					= Action	
local InstanceInfo			= A.InstanceInfo
local UnitCooldown			= A.UnitCooldown
local Unit					= A.Unit 
local Player				= A.Player 
local LoC 					= A.LossOfControl
local MultiUnits			= A.MultiUnits

local _G, pairs				= _G, pairs

local GetCVar				= GetCVar
local UnitIsFriend			= UnitIsFriend
local SpellIsTargeting		= SpellIsTargeting
local IsMouseButtonDown		= IsMouseButtonDown

local ClassPortaits = {
	["WARRIOR"] 			= ACTION_CONST_PORTRAIT_WARRIOR,
	["PALADIN"] 			= ACTION_CONST_PORTRAIT_PALADIN,
	["HUNTER"] 				= ACTION_CONST_PORTRAIT_HUNTER,
	["ROGUE"] 				= ACTION_CONST_PORTRAIT_ROGUE,
	["PRIEST"] 				= ACTION_CONST_PORTRAIT_PRIEST,
	["DEATHKNIGHT"] 		= ACTION_CONST_PORTRAIT_DEATHKNIGHT,
	["SHAMAN"]	 			= ACTION_CONST_PORTRAIT_SHAMAN, -- Custom because it making conflict with Bloodlust
	["MAGE"] 				= ACTION_CONST_PORTRAIT_MAGE,
	["WARLOCK"] 			= ACTION_CONST_PORTRAIT_WARLOCK,
	["MONK"] 				= ACTION_CONST_PORTRAIT_MONK,
	["DRUID"] 				= ACTION_CONST_PORTRAIT_DRUID,
	["DEMONHUNTER"] 		= ACTION_CONST_PORTRAIT_DEMONHUNTER,
}

local GetKeyByRace = {
	-- I use this to check if we have created for spec needed spell 
	Worgen 					= "Darkflight",
	VoidElf 				= "SpatialRift",
	NightElf 				= "Shadowmeld",
	LightforgedDraenei 		= "LightsJudgment",
	KulTiran 				= "Haymaker",
	Human 					= "EveryManforHimself",
	Gnome 					= "EscapeArtist",
	Dwarf 					= "Stoneform",
	Draenei 				= "GiftoftheNaaru",
	DarkIronDwarf 			= "Fireblood",
	Pandaren 				= "QuakingPalm",
	ZandalariTroll 			= "Regeneratin",
	Scourge 				= "WilloftheForsaken",
	Troll 					= "Berserking",
	Tauren 					= "WarStomp",
	Orc 					= "BloodFury",
	Nightborne 				= "ArcanePulse",
	MagharOrc 				= "AncestralCall",
	HighmountainTauren 		= "BullRush",
	BloodElf 				= "ArcaneTorrent",
	Goblin 					= "RocketJump",
}

local player				= "player"
local target 				= "target"
local mouseover				= "mouseover"
local targettarget			= "targettarget"
local arena 				= "arena"

-------------------------------------------------------------------------------
-- Conditions
-------------------------------------------------------------------------------
local FoodAndDrink = {
	43180, 	-- Food 
	27089, 	-- Drink
	257427, -- FoodDrink
	167152, -- Mage's eat
}
function A.PauseChecks()  	
	-- Chat, BindPad, TellMeWhen
	if ACTIVE_CHAT_EDIT_BOX or (BindPadFrame and BindPadFrame:IsVisible()) or not TMW.Locked then 
		return ACTION_CONST_PAUSECHECKS_DISABLED
	end 
	
    if A.GetToggle(1, "CheckVehicle") and Unit(player):InVehicle() then
        return ACTION_CONST_PAUSECHECKS_DISABLED
    end	
	
	if 	(A.GetToggle(1, "CheckDeadOrGhost") and Unit(player):IsDead()) or 
		(
			A.GetToggle(1, "CheckDeadOrGhostTarget") and 
			(
				(Unit(target):IsDead() and not UnitIsFriend(player, target) and (not A.IsInPvP or Unit(target):Class() ~= "HUNTER")) or 
				(A.GetToggle(2, mouseover) and Unit(mouseover):IsDead() and not UnitIsFriend(player, mouseover) and (not A.IsInPvP or Unit(mouseover):Class() ~= "HUNTER"))
			)
		) 
	then 																																																											-- exception in PvP Hunter 
		return ACTION_CONST_PAUSECHECKS_DEAD_OR_GHOST
	end 		
	
	if A.GetToggle(1, "CheckMount") and Player:IsMounted() then 																																													-- exception Divine Steed and combat mounted auras
		return ACTION_CONST_PAUSECHECKS_IS_MOUNTED
	end 

	if A.GetToggle(1, "CheckCombat") and Unit(player):CombatTime() == 0 and Unit(target):CombatTime() == 0 and not Player:IsStealthed() and A.BossMods_Pulling() == 0 then 																		-- exception Stealthed and DBM pulling event 
		return ACTION_CONST_PAUSECHECKS_WAITING
	end 	
	
	if A.GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() then
		return ACTION_CONST_PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if A.GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return ACTION_CONST_PAUSECHECKS_LOOTFRAME
	end	
	
	if A.GetToggle(1, "CheckEatingOrDrinking") and Unit(player):CombatTime() == 0 and Player:IsStaying() and Unit(player):HasBuffs(FoodAndDrink, true) > 0 then
		return ACTION_CONST_PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
A.PauseChecks = A.MakeFunctionCachedStatic(A.PauseChecks)

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.Trinket1 					= A.Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET1,	 			BlockForbidden = true, Desc = "Upper Trinket (/use 13)" 							})
A.Trinket2 					= A.Create({ Type = "TrinketBySlot", 	ID = ACTION_CONST_INVSLOT_TRINKET2, 			BlockForbidden = true, Desc = "Lower Trinket (/use 14)"								})
A.HS						= A.Create({ Type = "Item", 			ID = 5512, 										QueueForbidden = true, BlockForbidden = true, Desc = "[6] HealthStone" 				})
A.GladiatorMedallion		= A.Create({ Type = "Spell", 			ID = ACTION_CONST_SPELLID_GLADIATORS_MEDALLION, QueueForbidden = true, BlockForbidden = true, IsTalent = true, Desc = "[5] Trinket" })
A.HonorMedallion			= A.Create({ Type = "Spell", 			ID = ACTION_CONST_SPELLID_HONOR_MEDALLION, 		QueueForbidden = true, BlockForbidden = true, Desc = "[5] Trinket" 					})

function A.Rotation(icon)
	if not A.IsInitialized or not A[A.PlayerSpec] then 
		return A.Hide(icon)		
	end 	
	
	local meta = icon.ID
	
	-- [1] CC / [2] Kick 
	if meta <= 2 then 
		if A[A.PlayerSpec][meta] and A[A.PlayerSpec][meta](icon) then 
			return true
		end 
		return A.Hide(icon)
	end 
	
	-- [5] Trinket 
	if meta == 5 then 
		-- Use racial available trinkets if we don't have additional RACIAL_LOC
		-- Note: Additional RACIAL_LOC is the main reason why I avoid here :AutoRacial (see below 'if isApplied then ')
		if A.GetToggle(1, "Racial") then 
			local RacialAction 	= A[A.PlayerSpec][GetKeyByRace[A.PlayerRace]]			
			local RACIAL_LOC 	= LoC.GetExtra[A.PlayerRace]							-- Loss Of Control 
			if RACIAL_LOC and RacialAction and RacialAction:IsReady(player, true) and RacialAction:IsExists() then 
				local result, isApplied = LoC:IsValid(RACIAL_LOC.Applied, RACIAL_LOC.Missed, A.PlayerRace == "Dwarf" or A.PlayerRace == "Gnome")
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
		local Medallion = LoC.GetExtra["GladiatorMedallion"]
		if Medallion and Medallion.isValid() and LoC:IsValid(Medallion.Applied) then 			
			return A.GladiatorMedallion:Show(icon)
		end 		
		
		-- Use racial if nothing is not available 
		if isApplied then 
			return RacialAction:Show(icon)
		end 
			
		return A.Hide(icon)		 
	end 
	
	local PauseChecks = A.PauseChecks()
	if PauseChecks then
		if meta == 3 then 
			return A:Show(icon, PauseChecks)
		end  
		return A.Hide(icon)		
	end 		
	
	-- [6] Passive: @player, @raid1, @arena1 
	if meta == 6 then 
		-- Shadowmeld
		if A[A.PlayerSpec].Shadowmeld and A[A.PlayerSpec].Shadowmeld:AutoRacial(player) then 
			return A[A.PlayerSpec].Shadowmeld:Show(icon)
		end 
		
		-- Stopcasting
		if A.GetToggle(1, "StopCast") then 
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
		
		-- Healthstone
		if not Player:IsStealthed() then 			 
			local Healthstone = A.GetToggle(1, "HealthStone") 
			if Healthstone >= 0 then 
				if A.HS:IsReady(player, true) then 			
					if Healthstone >= 100 then -- AUTO 
						if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 then 
							return A.HS:Show(icon)	
						end 
					elseif Unit(player):HealthPercent() <= Healthstone then 
						return A.HS:Show(icon)								 
					end 
				end 
			end 
		end
		
		-- AutoTarget 
		if A.GetToggle(1, "AutoTarget") and not A.IamHealer and Unit(player):CombatTime() > 0 and not Unit(target):IsExplosives() then 							
			if  (not Unit(target):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and Unit(target):CombatTime() == 0)) 	-- No existed or switch target in PvE if we accidentally selected out of combat unit  			
				and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(40, 1) >= 1) or A.Zone == "pvp") 							-- If rotation mode is PvE and in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			then 
				return A:Show(icon, ACTION_CONST_AUTOTARGET)
			end 
			
			if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7 then
				-- CLEU search 
				if A.IsExplosivesExists() then 
					return A:Show(icon, ACTION_CONST_AUTOTARGET)
				end 
				
				-- Nameplates seach (only if enemy totems are enabled)
				local nameplates = MultiUnits:GetActiveUnitPlates()
				if nameplates and GetCVar("nameplateShowEnemyTotems") then 
					for nameplateUnitID in pairs(nameplates) do 
						if Unit(nameplateUnitID):IsExplosives() then 
							return A:Show(icon, ACTION_CONST_AUTOTARGET)			 
						end 
					end 
				end 				 
			end 
		end 
	end 
	
	-- Queue System
	if A.IsQueueReady(meta) then                                              
		return A.Data.Q[1]:Show(icon)				 
    end 
	
	-- Hide frames which are not used by profile
	if not A[A.PlayerSpec][meta] then 
		return A.Hide(icon)
	end 	
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-2, @raid1-3, @arena1-3
	if A[A.PlayerSpec][meta] and A[A.PlayerSpec][meta](icon) then 
		return true 
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not A.GetToggle(1, "DisableClassPortraits") then 
		return A:Show(icon, ClassPortaits[A.PlayerClass])
	end 
	
	A.Hide(icon)			
end 