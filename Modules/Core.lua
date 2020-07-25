local _G, math, pairs, type, select, setmetatable	= _G, math, pairs, type, select, setmetatable

local TMW 											= _G.TMW 
local CNDT 											= TMW.CNDT
local Env 											= CNDT.Env

local A   											= _G.Action	
local CONST 										= A.Const
local A_Hide 										= A.Hide
local Create 										= A.Create
local GetToggle										= A.GetToggle
local IsExplosivesExists							= A.IsExplosivesExists
local IsQueueReady									= A.IsQueueReady
local QueueData										= A.Data.Q
local GetPing										= A.GetPing

local BossMods										= A.BossMods
local InstanceInfo									= A.InstanceInfo
local UnitCooldown									= A.UnitCooldown
local Unit											= A.Unit 
local Player										= A.Player 
local LoC 											= A.LossOfControl
local MultiUnits									= A.MultiUnits

local LoC_GetExtra									= LoC.GetExtra

local huge 											= math.huge

local UnitBuff										= _G.UnitBuff
local UnitIsFriend									= _G.UnitIsFriend

local GetSpellInfo									= _G.GetSpellInfo
local SpellIsTargeting								= _G.SpellIsTargeting
local IsMouseButtonDown								= _G.IsMouseButtonDown

local MACRO											-- nil 
local BINDPAD 										= _G.BindPadFrame
local WIM											= _G.WIM

local ClassPortaits 								= {
	["WARRIOR"] 									= CONST.PORTRAIT_WARRIOR,
	["PALADIN"] 									= CONST.PORTRAIT_PALADIN,
	["HUNTER"] 										= CONST.PORTRAIT_HUNTER,
	["ROGUE"] 										= CONST.PORTRAIT_ROGUE,
	["PRIEST"] 										= CONST.PORTRAIT_PRIEST,
	["DEATHKNIGHT"] 								= CONST.PORTRAIT_DEATHKNIGHT, 	-- Custom because it making conflict with Obliteration
	["SHAMAN"]	 									= CONST.PORTRAIT_SHAMAN, 			-- Custom because it making conflict with Bloodlust
	["MAGE"] 										= CONST.PORTRAIT_MAGE,
	["WARLOCK"] 									= CONST.PORTRAIT_WARLOCK,
	["MONK"] 										= CONST.PORTRAIT_MONK,
	["DRUID"] 										= CONST.PORTRAIT_DRUID,
	["DEMONHUNTER"] 								= CONST.PORTRAIT_DEMONHUNTER,
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
local function MacroFrameIsVisible()
	-- @return boolean 
	if MACRO then 
		return MACRO:IsVisible()
	else 
		MACRO = _G.MacroFrame
	end 
end 

local function BindPadFrameIsVisible()
	-- @return boolean 
	return BINDPAD and BINDPAD:IsVisible()
end 

local WIM_ChatFrames = setmetatable({}, { __index = function(t, i)
	local f = _G["WIM3_msgFrame" .. i .. "MsgBox"]
	if f then 
		t[i] = f
	end 
	return f
end })

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
	-- Chat, Macro, BindPad, TellMeWhen
	if _G.ACTIVE_CHAT_EDIT_BOX or MacroFrameIsVisible() or BindPadFrameIsVisible() or not TMW.Locked then 
		return CONST.PAUSECHECKS_DISABLED
	end 
	
	-- Wim Messanger
	if WIM then 
		for i = 1, huge do 
			if not WIM_ChatFrames[i] then 
				break 
			elseif WIM_ChatFrames[i]:IsVisible() and WIM_ChatFrames[i]:HasFocus() then 
				return CONST.PAUSECHECKS_DISABLED
			end 
		end 
	end 
	
    if GetToggle(1, "CheckVehicle") and Unit(player):InVehicle() then
        return CONST.PAUSECHECKS_DISABLED
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
		return CONST.PAUSECHECKS_DEAD_OR_GHOST
	end 		
	
	if GetToggle(1, "CheckMount") and Player:IsMounted() then 																																												-- exception Divine Steed and combat mounted auras
		return CONST.PAUSECHECKS_IS_MOUNTED
	end 

	if GetToggle(1, "CheckCombat") and Unit(player):CombatTime() == 0 and Unit(target):CombatTime() == 0 and not Player:IsStealthed() and BossMods:GetPullTimer() == 0 then 																-- exception Stealthed and DBM pulling event 
		return CONST.PAUSECHECKS_WAITING
	end 	
	
	if GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() then
		return CONST.PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return CONST.PAUSECHECKS_LOOTFRAME
	end	
	
	if GetToggle(1, "CheckEatingOrDrinking") and Unit(player):CombatTime() == 0 and Player:IsStaying() and IsDrinkingOrEating() then
		return CONST.PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
A.PauseChecks = A.MakeFunctionCachedStatic(A.PauseChecks)

local A_PauseChecks = A.PauseChecks

local GetMetaType = setmetatable({}, { __index = function(t, v)
	local istype = type(v)
	t[v] = istype	
	return istype
end })

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.Trinket1 					= Create({ Type = "TrinketBySlot", 	ID = CONST.INVSLOT_TRINKET1,	 				BlockForbidden = true, Desc = "Upper Trinket (/use 13)" 							})
A.Trinket2 					= Create({ Type = "TrinketBySlot", 	ID = CONST.INVSLOT_TRINKET2, 					BlockForbidden = true, Desc = "Lower Trinket (/use 14)"								})
A.HS						= Create({ Type = "Item", 			ID = 5512, 										QueueForbidden = true, Desc = "[6] HealthStone" 									})
A.AbyssalHealingPotion		= Create({ Type = "Item", 			ID = 169451, 									QueueForbidden = true																})
A.GladiatorMedallion		= Create({ Type = "Spell", 			ID = CONST.SPELLID_GLADIATORS_MEDALLION, 		QueueForbidden = true, BlockForbidden = true, IsTalent = true, Desc = "[5] Trinket" })
A.HonorMedallion			= Create({ Type = "Spell", 			ID = CONST.SPELLID_HONOR_MEDALLION, 			QueueForbidden = true, BlockForbidden = true, Desc = "[5] Trinket" 					})

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
			elseif A.Zone ~= "arena" and (A.Zone ~= "pvp" or not InstanceInfo.isRated) and A.AbyssalHealingPotion:IsReady(player, true) then 			
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
	local metatype = GetMetaType[A[A.PlayerSpec][meta] or "nill"]
	
	-- [1] CC / [2] Kick 
	if meta <= 2 then 
		if metatype == "function" and A[A.PlayerSpec][meta](icon) then 
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
		if metatype == "function" and A[A.PlayerSpec][meta](icon) then  
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
			local _, castLeft, _, _, castName, notInterruptable = Unit(player):CastTime() 
			if castName then 
				-- Catch Counter Shot 
				if A.IsInPvP and not notInterruptable and UnitCooldown:GetCooldown(arena, CONST.SPELLID_COUNTER_SHOT) > UnitCooldown:GetMaxDuration(arena, CONST.SPELLID_COUNTER_SHOT) - 1 and UnitCooldown:IsSpellInFly(arena, CONST.SPELLID_COUNTER_SHOT) then 
					local Caster = UnitCooldown:GetUnitID(arena, CONST.SPELLID_COUNTER_SHOT)
					if Caster and Unit(Caster):GetRange() <= 40 and Unit(player):HasBuffs("TotalImun") == 0 and Unit(player):HasBuffs("KickImun") == 0 then 
						return A:Show(icon, CONST.STOPCAST)
					end 
				end 
				
				-- Mythic 7+ 
				-- Quaking Affix
				if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7 and InstanceInfo.GroupSize <= 5 then 
					local QuakingDeBuff = Unit("player"):HasDeBuffs(240447, true)
					if QuakingDeBuff ~= 0 and castLeft >= QuakingDeBuff - GetPing() - 0.1 then 
						return A:Show(icon, CONST.STOPCAST)
					end 
				end 
			end 
		end 
		
		-- Cursor 
		if A.GameTooltipClick and not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then 			
			if A.GameTooltipClick == "LEFT" then 
				return A:Show(icon, CONST.LEFT)			 
			elseif A.GameTooltipClick == "RIGHT" then 
				return A:Show(icon, CONST.RIGHT)
			end 
		end 
		
		-- ReTarget ReFocus 
		if (A.Zone == arena or A.Zone == "pvp") and A:GetTimeSinceJoinInstance() >= 30 then 
			if A.LastTargetTexture and not A.LastTargetIsExists then 
				return A:Show(icon, A.LastTargetTexture)
			end 
			
			if A.LastFocusTexture and not A.LastFocusIsExists then 
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
				return A:Show(icon, CONST.AUTOTARGET)			  				 
			end 
			
			if  (not Unit(target):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and not Unit(target):IsCracklingShard() and Unit(target):CombatTime() == 0 and Unit(target):IsEnemy() and Unit(target):HealthPercent() >= 100)) 	-- No existed or switch target in PvE if we accidentally selected out of combat unit  			
				and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(nil, 1) >= 1) or A.Zone == "pvp") 																																-- If rotation mode is PvE and in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			then 
				return A:Show(icon, CONST.AUTOTARGET)
			end 
			
			-- Patch 8.2
			-- 1519 is The Eternal Palace: Precipice of Dreams
			-- Switch target if accidentally selected player in group under Delirium Realm (DeBuff)
			if not A.IsInPvP and A.ZoneID == 1519 and Unit(target):IsEnemy() and Unit(target):IsPlayer() and Unit(target):InGroup() then 
				return A:Show(icon, CONST.AUTOTARGET)
			end 
		end 
	end 
	
	-- Queue System
	if IsQueueReady(meta) then                                              
		return QueueData[1]:Show(icon)				 
    end 
	
	-- Hide frames which are not used by profile
	if metatype ~= "function" then 
		return A_Hide(icon)
	end 	
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-2, @raid1-3, @arena1-3
	if A[A.PlayerSpec][meta](icon) then 
		return true 
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not GetToggle(1, "DisableClassPortraits") then 
		return A:Show(icon, ClassPortaits[A.PlayerClass])
	end 
	
	A_Hide(icon)			
end 

-- setfenv will make working it way faster as lua condition for TMW frames 
do 
	local vType
	for k, v in pairs(A) do 
		vType = type(v)
		if (vType == "table" or vType == "function") and _G[k] == nil and Env[k] == nil then 
			Env[k] = v
		end		
	end 
end 
--[[
CNDT.EnvMeta.__index = function(t, v)		
	if _G[v] ~= nil then 	
		return _G[v]
	else		
		local vType = type(A[v])
		if vType == "table" or vType == "function" then 
			t[v] = A[v]
		end 
		return A[v]
	end 
end]]