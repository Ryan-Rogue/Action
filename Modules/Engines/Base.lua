-------------------------------------------------------------------------------
--[[ 
Global nil-able variables:
A.Zone				(@string)		"none", "pvp", "arena", "party", "raid", "scenario"
A.ZoneID			(@number) 		wow.gamepedia.com/UiMapID
A.IsInInstance		(@boolean)
A.TimeStampZone 	(@number)
A.TimeStampDuel 	(@number)
A.IsInPvP 			(@boolean)
A.IsInDuel			(@boolean)
A.IsInWarMode		(@boolean)

Global tables:
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize, isRated, KeyStone)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------

local TMW 									= TMW
local A   									= Action
local Listener								= A.Listener	

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit 

Listener:Add("ACTION_EVENT_BASE", "ADDON_LOADED", function(event, addonName) -- "ACTION_EVENT_BASE" fires with arg1 event!
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit = A.Unit 
		Listener:Remove("ACTION_EVENT_BASE", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------

local InstanceInfo							= {}
local TeamCache								= { 
	Friendly 								= {
		Size								= 1,
		MaxSize								= 1,
		UNITs								= {},
		GUIDs								= {},
		IndexToPLAYERs						= {},
		IndexToPETs							= {},
		-- [[ Retail only ]]
		HEALER								= {},
		TANK								= {},
		DAMAGER								= {},
		DAMAGER_MELEE						= {},
		DAMAGER_RANGE						= {},
	},
	Enemy 									= {
		Size 								= 0,
		MaxSize								= 0,
		UNITs								= {},
		GUIDs								= {},
		IndexToPLAYERs						= {},
		IndexToPETs							= {},	
		-- [[ Retail only ]]		
		HEALER								= {},
		TANK								= {},
		DAMAGER								= {},
		DAMAGER_MELEE						= {},
		DAMAGER_RANGE						= {},
	},
}

local TeamCacheFriendly 					= TeamCache.Friendly
local TeamCacheFriendlyUNITs				= TeamCacheFriendly.UNITs -- unitID to unitGUID
local TeamCacheFriendlyGUIDs				= TeamCacheFriendly.GUIDs -- unitGUID to unitID
local TeamCacheFriendlyIndexToPLAYERs		= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs			= TeamCacheFriendly.IndexToPETs
local TeamCacheFriendlyHEALER				= TeamCacheFriendly.HEALER
local TeamCacheFriendlyTANK					= TeamCacheFriendly.TANK
local TeamCacheFriendlyDAMAGER				= TeamCacheFriendly.DAMAGER
local TeamCacheFriendlyDAMAGER_MELEE		= TeamCacheFriendly.DAMAGER_MELEE
local TeamCacheFriendlyDAMAGER_RANGE		= TeamCacheFriendly.DAMAGER_RANGE
local TeamCacheEnemy 						= TeamCache.Enemy
local TeamCacheEnemyUNITs					= TeamCacheEnemy.UNITs -- unitID to unitGUID
local TeamCacheEnemyGUIDs					= TeamCacheEnemy.GUIDs -- unitGUID to unitID
local TeamCacheEnemyIndexToPLAYERs			= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local TeamCacheEnemyHEALER					= TeamCacheEnemy.HEALER
local TeamCacheEnemyTANK					= TeamCacheEnemy.TANK
local TeamCacheEnemyDAMAGER					= TeamCacheEnemy.DAMAGER
local TeamCacheEnemyDAMAGER_MELEE			= TeamCacheEnemy.DAMAGER_MELEE
local TeamCacheEnemyDAMAGER_RANGE			= TeamCacheEnemy.DAMAGER_RANGE

local _G, pairs, type, math 				= 
	  _G, pairs, type, math

local huge 									= math.huge 
local wipe									= _G.wipe 
local C_PvP 								= _G.C_PvP
local C_ChallengeMode						= _G.C_ChallengeMode
local C_Map									= _G.C_Map

local IsInRaid, IsInGroup, IsInInstance, IsActiveBattlefieldArena, RequestBattlefieldScoreData = 
	  IsInRaid, IsInGroup, IsInInstance, IsActiveBattlefieldArena, RequestBattlefieldScoreData

local UnitIsUnit, UnitInBattleground, UnitGUID = 
	  UnitIsUnit, UnitInBattleground, UnitGUID

local GetInstanceInfo, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers =
	  GetInstanceInfo, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers

local IsWarModeDesired		= C_PvP.IsWarModeDesired
local IsRatedMap			= C_PvP.IsRatedMap	  
local GetActiveKeystoneInfo = C_ChallengeMode.GetActiveKeystoneInfo	
local GetBestMapForUnit 	= C_Map.GetBestMapForUnit	

local player 								= "player"
local pet									= "pet"
local target 								= "target"
local targettarget							= "targettarget"

-------------------------------------------------------------------------------
-- Instance, Zone, Mode, Duel, TeamCache
-------------------------------------------------------------------------------	  
A.TeamCache 	= TeamCache
A.InstanceInfo 	= InstanceInfo

function A:GetTimeSinceJoinInstance()
	-- @return number
	return (self.TimeStampZone and TMW.time - self.TimeStampZone) or huge
end 

function A:GetTimeDuel()
	-- @return number
	return (self.IsInDuel and TMW.time - self.TimeStampDuel - ACTION_CONST_CACHE_DEFAULT_OFFSET_DUEL) or 0
end 
 
function A:CheckInPvP()
	-- @return boolean
    return 
    self.Zone == "arena" or 
    self.Zone == "pvp" or 
    UnitInBattleground(player) or 
    IsActiveBattlefieldArena() or
    IsWarModeDesired() or
	-- Patch 8.2
	-- 1519 is The Eternal Palace: Precipice of Dreams
    ( A.ZoneID ~= 1519 and A_Unit(target):IsPlayer() and (A_Unit(target):IsEnemy() or (A_Unit(targettarget):IsPlayer() and A_Unit(targettarget):IsEnemy())) )
end

function A.UI_INFO_MESSAGE_IS_WARMODE(...)
	-- @return boolean
	local _, MSG = ...		
    return (type(MSG) == "string" and (MSG == ACTION_CONST_ERR_PVP_WARMODE_TOGGLE_OFF or MSG == ACTION_CONST_ERR_PVP_WARMODE_TOGGLE_ON)) or false
end 

local LastEvent, counter
local IsEventIsChallenge = {
	CHALLENGE_MODE_COMPLETED 		= true,
	CHALLENGE_MODE_RESET			= true,
	CHALLENGE_MODE_KEYSTONE_SLOTTED = true,
}
local function OnEvent(event, ...)    
    -- Don't call it several times
    if TMW.time == LastEvent and TeamCacheFriendlyUNITs.player then 
        return 
    end 
    LastEvent = TMW.time
	
	-- Update IsInInstance, Zone
    A.IsInInstance, A.Zone = IsInInstance()
	if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_LOGIN" or IsEventIsChallenge[event] then 
		A.ZoneID = GetBestMapForUnit(player) or 0
		
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		if name then 
			InstanceInfo.Name 			= name 
			InstanceInfo.Type 			= instanceType
			InstanceInfo.difficultyID 	= difficultyID
			InstanceInfo.ID 			= instanceID
			InstanceInfo.GroupSize		= instanceGroupSize
			InstanceInfo.isRated		= IsRatedMap()
			InstanceInfo.KeyStone		= GetActiveKeystoneInfo() or 0
			if not IsEventIsChallenge[event] then 
				A.TimeStampZone 		= TMW.time
			end 
		end 
	end 
	
	-- Update Mode, Duel
    if not A.IsLockedMode then
		if event == "UI_INFO_MESSAGE" and A.UI_INFO_MESSAGE_IS_WARMODE(...) then     
			A.IsInPvP = IsWarModeDesired()
			A.IsInWarMode = A.IsInPvP or nil
			TMW:Fire("TMW_ACTION_MODE_CHANGED") 
			TMW:Fire("TMW_ACTION_DEPRECATED")			
			return 
		end            
		
		if event == "DUEL_REQUESTED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = true, true, TMW.time
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			return
		elseif event == "DUEL_FINISHED" then
			A.IsInPvP, A.IsInDuel, A.TimeStampDuel = A:CheckInPvP(), nil, nil
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
			TMW:Fire("TMW_ACTION_DEPRECATED")
			return
		end            
		
		if not A.IsInDuel and (event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_LOGIN" or IsEventIsChallenge[event]) then                                
			local oldMode = A.IsInPvP
			A.IsInPvP = A:CheckInPvP()  
			if oldMode ~= A.IsInPvP then 
				TMW:Fire("TMW_ACTION_MODE_CHANGED")
			end 
		end  
	end
	
	-- Update Units 
	if event == "UPDATE_INSTANCE_INFO" or event == "GROUP_ROSTER_UPDATE" or event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then 
		-- Wipe Friendly 
		for _, v in pairs(TeamCacheFriendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy
		for _, v in pairs(TeamCacheEnemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
		
		-- Enemy  		
		if A.Zone == "arena" then 
			TeamCacheEnemy.Size = GetNumArenaOpponents() -- GetNumArenaOpponentSpecs()    
			TeamCacheEnemy.Type = "arena"
			TeamCacheEnemy.MaxSize = 5
		elseif A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			TeamCacheEnemy.Size = GetNumBattlefieldScores()         
			TeamCacheEnemy.Type = "arena"
			TeamCacheEnemy.MaxSize = 40
		else
			TeamCacheEnemy.Size = 0 
			TeamCacheEnemy.Type = nil 
			TeamCacheEnemy.MaxSize = 0
		end
		TeamCacheEnemy.MaxSize = TeamCacheEnemy.Size	
		
		if TeamCacheEnemy.Size > 0 and TeamCacheEnemy.Type then  
			counter = 0
			for i = 1, huge do 
				local arena = TeamCacheEnemy.Type .. i
				local guid  = UnitGUID(arena)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheEnemyUNITs[arena] 					= guid
					TeamCacheEnemyGUIDs[guid] 					= arena		
					TeamCacheEnemyIndexToPLAYERs[i] 			= arena		
					if A_Unit(arena):IsHealer() then 
						TeamCacheEnemyHEALER[arena] 			= arena
					elseif A_Unit(arena):IsTank() then 
						TeamCacheEnemyTANK[arena] 				= arena
					else
						TeamCacheEnemyDAMAGER[arena] 			= arena
						if A_Unit(arena):IsMelee() then 
							TeamCacheEnemyDAMAGER_MELEE[arena] 	= arena
						else 
							TeamCacheEnemyDAMAGER_RANGE[arena] 	= arena
						end                        
					end
					
					local arenapet 								= TeamCacheEnemy.Type .. pet .. i
					local arenapetguid 							= UnitGUID(arenapet)
					if arenapetguid then 
						TeamCacheEnemyUNITs[arenapet] 			= arenapetguid
						TeamCacheEnemyGUIDs[arenapetguid] 		= arenapet					
						TeamCacheEnemyIndexToPETs[i] 			= arenapet	
					end 
				end

				if counter >= TeamCacheEnemy.Size or i >= TeamCacheEnemy.MaxSize then 
					if counter >= TeamCacheEnemy.Size then 
						TeamCacheEnemy.MaxSize = counter
					end 
					break 
				end 
			end   
		end          
		
		-- Friendly
		TeamCacheFriendly.Size = GetNumGroupMembers()
		if IsInRaid() then
			TeamCacheFriendly.Type = "raid"
			TeamCacheFriendly.MaxSize = 40
		elseif IsInGroup() then
			TeamCacheFriendly.Type = "party"   
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size - 1			
		else 
			TeamCacheFriendly.Type = nil 
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size
		end  
			
		local pGUID = UnitGUID(player)
		TeamCacheFriendlyUNITs[player] 	= pGUID
		TeamCacheFriendlyGUIDs[pGUID] 	= player 	
		
		if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then 
			counter = 0
			for i = 1, huge do 
				local member = TeamCacheFriendly.Type .. i
				local guid   = UnitGUID(member)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheFriendlyUNITs[member] 						= guid 
					TeamCacheFriendlyGUIDs[guid] 						= member 
					TeamCacheFriendlyIndexToPLAYERs[i] 					= member
					if not UnitIsUnit(member, player) then 
						if A_Unit(member):IsHealer() then 
							TeamCacheFriendlyHEALER[member]	 			= member
						elseif A_Unit(member):IsTank() then  
							TeamCacheFriendlyTANK[member] 				= member
						else 
							TeamCacheFriendlyDAMAGER[member] 			= member
							if A_Unit(member):IsMelee() then 
								TeamCacheFriendlyDAMAGER_MELEE[member] 	= member
							else 
								TeamCacheFriendlyDAMAGER_RANGE[member] 	= member
							end 
						end
					end
					
					local memberpet 									= TeamCacheFriendly.Type .. pet .. i
					local memberpetguid 								= UnitGUID(memberpet)
					if memberpetguid then 
						TeamCacheFriendlyUNITs[memberpet] 				= memberpetguid
						TeamCacheFriendlyGUIDs[memberpetguid] 			= memberpet					
						TeamCacheFriendlyIndexToPETs[i] 				= memberpet	
					end 
				end 
				
				if counter >= TeamCacheFriendly.Size or i >= TeamCacheFriendly.MaxSize then 
					if counter >= TeamCacheFriendly.Size then 
						TeamCacheFriendly.MaxSize = counter
					end 
					break 
				end 
			end 
		end		
	end 
	
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" or event == "UPDATE_INSTANCE_INFO" then
		TMW:Fire("TMW_ACTION_ENTERING", event)	-- callback is used in PetLibrary.lua, HealingEngine.lua, HybridProfile.lua (retired) to initializate and it's better than event 
	end 
	
	TMW:Fire("TMW_ACTION_DEPRECATED") -- TODO: Remove in the future
end 

Listener:Add("ACTION_EVENT_BASE", "DUEL_FINISHED", 						OnEvent)
Listener:Add("ACTION_EVENT_BASE", "DUEL_REQUESTED", 					OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED", 						OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_INDOORS", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ZONE_CHANGED_NEW_AREA", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "UI_INFO_MESSAGE", 					OnEvent)
Listener:Add("ACTION_EVENT_BASE", "UPDATE_INSTANCE_INFO", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "GROUP_ROSTER_UPDATE", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "ARENA_OPPONENT_UPDATE", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_WORLD", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_ENTERING_BATTLEGROUND", 		OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_TARGET_CHANGED", 				OnEvent)
Listener:Add("ACTION_EVENT_BASE", "PLAYER_LOGIN", 						OnEvent)

-- Retail Challenge Mode 
for k in pairs(IsEventIsChallenge) do 
	Listener:Add("ACTION_EVENT_BASE", k, 								OnEvent)
end 