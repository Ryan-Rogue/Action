-- Version 2.0
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs, next, type = 
	  pairs, next, type
	  
local UnitIsPlayer, UnitExists, UnitGUID, UnitAffectingCombat = 
	  UnitIsPlayer, UnitExists, UnitGUID, UnitAffectingCombat
	  
local GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit
local activeUnitPlates = dynamic_array(2)

local CL_TYPE_PLAYER 	  = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_CONTROL_PLAYER   =	COMBATLOG_OBJECT_CONTROL_PLAYER
local CL_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local CL_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local function isEnemy(Flags)
	return bitband(Flags, CL_REACTION_HOSTILE) == CL_REACTION_HOSTILE or bitband(Flags, CL_REACTION_NEUTRAL) == CL_REACTION_NEUTRAL
end 
local function isPlayer(Flags)
	return bitband(Flags, CL_TYPE_PLAYER) == CL_TYPE_PLAYER or bitband(Flags, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER
end

--- ============================ CONTENT ============================
local function AddNameplate(unitID)
    local nameplate = GetNamePlateForUnit(unitID)
    local unitframe = nameplate.UnitFrame  
    local reaction = (Env.Unit(unitID):IsEnemy() and "enemy") or "friendly"
    if unitframe and unitID then 
        activeUnitPlates[reaction][unitframe] = unitID
    end
end

local function RemoveNameplate(unitID)
    local nameplate = GetNamePlateForUnit(unitID)
    local unitframe = nameplate.UnitFrame
    if unitframe then
        activeUnitPlates["enemy"][unitframe] = nil  
        activeUnitPlates["friendly"][unitframe] = nil 
    end     
end

-- For refference 
function GetActiveUnitPlates(reaction)
    return activeUnitPlates[reaction] or nil
end 

--- ========================== FUNCTIONAL ===========================
-- For Tank 
function PvPMassTaunt(stop, range, outrange)
    local totalmobs = 0
    if not range then range = 40 end;   
    if not outrange then outrange = 8 end; 
    if activeUnitPlates["enemy"] then        
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            if 
            UnitIsPlayer(unit) and 
            Env.Unit(unit):GetRange() >= outrange and         
            Env.SpellInteract(unit, range) then 
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then                    
                    break
                end    
            end
        end   
    end    
    -- True/False or Number
    return (stop and totalmobs >= stop) or (not stop and totalmobs)
end

function MassTaunt(stop, range, ttd)
    local totalmobs = 0 
    if not range then range = 40 end;   
    if not ttd then ttd = 10 end; 
    if activeUnitPlates["enemy"] then
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            if 
            CombatTime(unit) > 0 and 
            TimeToDie(unit) >= ttd and 
            Env.UNITLevel(unit) ~= -1 and 
            Env.Unit(unit):GetRange() <= range and 
            not Env.Unit(unit .. "target"):IsTank() then 
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then                
                    break
                end    
            end
        end   
    end    
    -- True/False or Number
    return (stop and totalmobs >= stop) or (not stop and totalmobs) 
end

-- Multi DoTs
-- Missed dots on valid targets (only NUMERIC returns!!)
function MultiDots(range, dots, ttd, stop)
    local totalmobs = 0 
    if activeUnitPlates["enemy"] then
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            if 
            CombatTime(unit) > 0 and 
            Env.UNITLevel(unit) ~= -1 and 
            ( not Env.InPvP() or UnitIsPlayer(unit)) and
            ( not ttd or TimeToDie(unit) >= ttd ) and 
            ( not range or Env.SpellInteract(unit, range) ) and 
            Env.Unit(unit):HasDeBuffs(dots, "player") == 0 then               
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then
                    break
                end    
            end
        end   
    end    
    return totalmobs
end

-- Applied dots on valid targets 
function UnitsDots(stop, dots, range, ttd)
    local totalmobs = 0   
    if activeUnitPlates["enemy"] then
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            if 
            CombatTime(unit) > 0 and 
            ( not ttd or TimeToDie(unit) >= ttd ) and 
            Env.UNITLevel(unit) ~= -1 and 
            Env.Unit(unit):HasDeBuffs(dots, "player") > 0 and 
            ( not range or Env.SpellInteract(unit, range) ) then                 
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then
                    break
                end    
            end
        end   
    end    
    -- True/False or Number
    return (stop and totalmobs >= stop) or (not stop and totalmobs) 
end

-- Units 
-- AutoTarget 
function CombatUnits(stop, range, upttd)
    local totalmobs = 0   
    if activeUnitPlates["enemy"] then
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            if 
            CombatTime(unit) > 0 and 
            ( not range or Env.SpellInteract(unit, range) ) and 
            ( not upttd or TimeToDie(unit) >= upttd ) then 
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then                  
                    break
                end    
            end
        end   
    end    
    -- True/False or Number
    return (stop and totalmobs >= stop) or (not stop and totalmobs) 
end

function CastingUnits(stop, range, kickAble)
    local totalmobs = 0
    if not range then range = 40 end;   
    if activeUnitPlates["enemy"] then
        for reference, unit in pairs(activeUnitPlates["enemy"]) do
            local current, _, _, _, notInterruptable = select(2, Env.CastTime(nil, unit))
            if 
            current > 0 and
            ( not kickAble or not notInterruptable ) and 
            CombatTime(unit) > 0 and 
            Env.UNITLevel(unit) ~= -1 and             
            Env.SpellInteract(unit, range) then 
                totalmobs = totalmobs + 1            
                
                if stop and totalmobs >= stop then                    
                    break
                end    
            end
        end   
    end    
    -- True/False or Number
    return (stop and totalmobs >= stop) or (not stop and totalmobs) 
end 

-- Checking by spell
local function GetMobsBySpell(count, spellId, reaction)
    local totalmobs = 0
    for reference, unit in pairs(activeUnitPlates[reaction]) do
        if Env.SpellInRange(unit, spellId) then
            totalmobs = totalmobs + 1            
            if count and type(count) == "number" and totalmobs >= count then                
                break                
            end              
        end
    end    
    return totalmobs
end

-- Checking by range
local function GetMobsByRange(count, range, reaction)
    local totalmobs = 0
    for reference, unit in pairs(activeUnitPlates[reaction]) do
        if Env.SpellInteract(unit, range) then
            totalmobs = totalmobs + 1            
            if count and type(count) == "number" and totalmobs >= count then                
                break            
            end        
        end
    end   
    return totalmobs
end

-- General result (usually melee usage / or range if active_enemies is empty)
-- TODO: Make another cache
local mobs = { ["friendly"] = {}, ["enemy"] = {} }
function AoE(count, num, type) 
    if not type then type = "enemy" end  
    if not num then num = 40 end 
    if not count then count = "" end
    -- If last refresh for these arguments wasn't early than 0.2 (global) timer then update it 
    if fLastCall("AoE" .. count .. num .. type) then  
        -- FPS saver, prevent refresh with same arguments by preset time       
        oLastCall["AoE" .. count .. num .. type] = TMW.time + oLastCall["global"]               
        
        if num < 100 then
            mobs[type][count .. num] = GetMobsByRange(count, num, type)
        else 
            mobs[type][count .. num] = GetMobsBySpell(count, num, type)
        end                         
    end       
    
    if not count or count == "" then
        return mobs[type][count .. num] or 0
    else
        return mobs[type][count .. num] and mobs[type][count .. num] >= count
    end    
end

-- Range
local logUnits, activeUnits = {}, {}
local function ActiveEnemiesCLEU(...)
	local ts, event, _, SourceGUID, SourceName,_, sourceFlags, DestGUID, DestName, destFlags,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()
    if 
    (
		isEnemy(destFlags) and
        (
            event == "SWING_DAMAGE" or
            event == "RANGE_DAMAGE" or
            event == "SPELL_DAMAGE" or
            (
                (
                    event == "SPELL_AURA_APPLIED" or
                    event == "SPELL_AURA_REFRESH"
                ) and
                auraType == "DEBUFF" and
                UnitGUID("player") == SourceGUID                    
            )
        ) 
    ) then   
        ts = round(ts, 0)  
        
        if not logUnits[SourceGUID] then 
            logUnits[SourceGUID] = {
                TS = ts,                     
                Count = 0,
                Units = {},
            }
        end 
        
        if logUnits[SourceGUID] then     
            if not logUnits[SourceGUID].Units[DestGUID] then 
                logUnits[SourceGUID].TS = ts
                logUnits[SourceGUID].Count = logUnits[SourceGUID].Count + 1    
                logUnits[SourceGUID].Units[DestGUID] = TMW.time
            end 
            
            if logUnits[SourceGUID].TS == ts then 
                logUnits[SourceGUID].Units[DestGUID] = TMW.time
            end 
        end         
    end  
    
    -- Remove dead units
    if event == "UNIT_DIED" and next(logUnits) then
        for GUID in pairs(logUnits) do
            if logUnits[GUID].Units[DestGUID] then 
                logUnits[GUID].Count = logUnits[GUID].Count - 1
                logUnits[GUID].Units[DestGUID] = nil
            end 
        end                    
    end     
end 

local function ActiveEnemiesUpdate()
    if Env.PlayerSpec then 
		if Env.UNITSpec("player", {102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267}) then 
			Listener:Add("Active_Enemies", "COMBAT_LOG_EVENT_UNFILTERED", ActiveEnemiesCLEU)
			Listener:Add("Active_Enemies", "PLAYER_REGEN_ENABLED", function()
					if not InCombatLockdown() and not UnitAffectingCombat("player") then
						wipe(logUnits)
						wipe(activeUnits)            
					end        
			end)
			Listener:Add("Active_Enemies", "PLAYER_REGEN_DISABLED", function()
					if TMW.time - SpellLastCast("player", Env.LastPlayerCastID) > 0.5 then 
						wipe(logUnits)
						wipe(activeUnits)
					end 
			end)
			return 
		end          
        
        wipe(logUnits)
        wipe(activeUnits)
        Listener:Remove("Active_Enemies", "COMBAT_LOG_EVENT_UNFILTERED")
        Listener:Remove("Active_Enemies", "PLAYER_REGEN_ENABLED")
        Listener:Remove("Active_Enemies", "PLAYER_REGEN_DISABLED")
    end 
end 

function active_enemies()   
    local total = 1   
    -- CombatLogs 
    if next(logUnits) and UnitExists("target") then 
        wipe(activeUnits)        
        -- Check units  
        local needRemove = true 
        for GUID in pairs(logUnits) do                
            for UNIT, TIME in pairs(logUnits[GUID].Units) do 
                -- Remove old units 
                if TMW.time - TIME > 4.5 then 
                    logUnits[GUID].Count = logUnits[GUID].Count - 1
                    logUnits[GUID].Units[UNIT] = nil                     
                end 
                -- Check if Source caster has same target as your then we don't will delete 
                if needRemove and UnitGUID("target") == UNIT then 
                    needRemove = false  
                end 
            end 
            if not needRemove then 
                -- Added actual active units count
                table.insert(activeUnits, logUnits[GUID].Count)
                needRemove = true 
            end 
        end 
        -- Sort my highest units count 
        table.sort(activeUnits, function (a, b) return (a > b) end)
        -- Result 
        local sortedUnits = activeUnits[1] or 0
        total = (sortedUnits > 0 and sortedUnits) or 1
    end 
    
    -- If CombatLogs corrupted then query nameplates by units into combat
    -- Note: Worn method since it can't keep in mind position 
    if total == 1 then 
        total = CombatUnits(nil, 40)              
    end
    
    return total
end

Listener:Add('Active_Enemies', "PLAYER_ENTERING_WORLD", ActiveEnemiesUpdate)
Listener:Add('Active_Enemies', "UPDATE_INSTANCE_INFO", ActiveEnemiesUpdate)
Listener:Add('Active_Enemies', "PLAYER_SPECIALIZATION_CHANGED", ActiveEnemiesUpdate)
Listener:Add('Active_Enemies', "PLAYER_TALENT_UPDATE", ActiveEnemiesUpdate)

Listener:Add("MultiUnits_Events", "PLAYER_ENTERING_WORLD", function()
        wipe(activeUnitPlates)  
        -- TODO: Make another cache
        mobs = { ["friendly"] = {}, ["enemy"] = {} }
        oLastCall = { ["global"] = 0.2 }
end) 
Listener:Add("MultiUnits_Events", "UPDATE_INSTANCE_INFO", function()
        wipe(activeUnitPlates)
        -- TODO: Make another cache
        mobs = { ["friendly"] = {}, ["enemy"] = {} }
        oLastCall = { ["global"] = 0.2 }
end) 
Listener:Add("MultiUnits_Events", "PLAYER_REGEN_DISABLED", function()
        -- TODO: Make another cache
        mobs = { ["friendly"] = {}, ["enemy"] = {} }
        oLastCall = { ["global"] = 0.2 }
end)
Listener:Add("MultiUnits_Events", "NAME_PLATE_UNIT_ADDED", AddNameplate)
Listener:Add("MultiUnits_Events", "NAME_PLATE_UNIT_REMOVED", RemoveNameplate)

