local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
local A = Action

local CL_TYPE_PLAYER 	  = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_CONTROL_PLAYER   =	COMBATLOG_OBJECT_CONTROL_PLAYER
local CL_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local CL_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local DRData = LibStub("DRData-1.1")

local type, pairs, print, wipe, bitband, bitbxor = 
	  type, pairs, A.Print, wipe, bit.band, bit.bxor

local UnitHealthMax, UnitHealth, UnitGUID, UnitExists, UnitGetTotalAbsorbs = 
	  UnitHealthMax, UnitHealth, UnitGUID, UnitExists, UnitGetTotalAbsorbs

local GetSpellInfo = A.GetSpellInfo
	  
local InCombatLockdown, CombatLogGetCurrentEventInfo = 
	  InCombatLockdown, CombatLogGetCurrentEventInfo

--- ============================ CONTENT ============================
local Data = {}
local Doubles = {
    [3]   = 'Holy + Physical',
    [5]   = 'Fire + Physical',
    [9]   = 'Nature + Physical',
    [17]  = 'Frost + Physical',
    [33]  = 'Shadow + Physical',
    [65]  = 'Arcane + Physical',
    [127] = 'Arcane + Shadow + Frost + Nature + Fire + Holy + Physical',
}

local function addToData(GUID)
    if not Data[GUID] then
        Data[GUID] = {
            -- Real Damage 
            RealDMG = { 
                -- Damage Taken  
                LastHit_Taken = 0,                             
                dmgTaken = 0,
                dmgTaken_S = 0,
                dmgTaken_P = 0,
                dmgTaken_M = 0,
                hits_taken = 0,                
                -- Damage Done
                LastHit_Done = 0,  
                dmgDone = 0,
                dmgDone_S = 0,
                dmgDone_P = 0,
                dmgDone_M = 0,
                hits_done = 0,
            },  
            -- Sustain Damage 
            DMG = {
                -- Damage Taken
                dmgTaken = 0,
                dmgTaken_S = 0,
                dmgTaken_P = 0,
                dmgTaken_M = 0,
                hits_taken = 0,
                lastHit_taken = 0,
                -- Damage Done
                dmgDone = 0,
                dmgDone_S = 0,
                dmgDone_P = 0,
                dmgDone_M = 0,
                hits_done = 0,
                lastHit_done = 0,
            },
            -- Sustain Healing 
            HPS = {
                -- Healing taken
                heal_taken = 0,
                heal_hits_taken = 0,
                heal_lasttime = 0,
                -- Healing Done
                heal_done = 0,
                heal_hits_done = 0,
                heal_lasttime_done = 0,
            },
            -- DS: Last N sec (Only Taken) 
            DS = {},
            -- Absorb (Only Taken)       
            absorb_spells = dynamic_array(2),
            -- Shared 
            combat_time = TMW.time,
            spell_value = {},
            spell_lastcast_time = {},
            spell_counter = {},			
        }
    end
end

local function isEnemy(Flags)
	return bitband(Flags, CL_REACTION_HOSTILE) == CL_REACTION_HOSTILE or bitband(Flags, CL_REACTION_NEUTRAL) == CL_REACTION_NEUTRAL
end 
local function isPlayer(Flags)
	return bitband(Flags, CL_TYPE_PLAYER) == CL_TYPE_PLAYER or bitband(Flags, CL_CONTROL_PLAYER) == CL_CONTROL_PLAYER
end

--[[ This Logs the damage for every unit ]]
local logDamage = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, _, school, Amount, a, b, c = CombatLogGetCurrentEventInfo()
    -- Update last hit time
    -- Taken 
    Data[DestGUID].DMG.lastHit_taken = TMW.time
    -- Done 
    Data[SourceGUID].DMG.lastHit_done = TMW.time
    -- Filter by School   
    if Doubles[school] then
        -- Taken 
        Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
        Data[DestGUID].DMG.dmgTaken_M = Data[DestGUID].DMG.dmgTaken_M + Amount
        -- Done 
        Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
        Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
        -- Real Time Damage 
        Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount
        Data[DestGUID].RealDMG.dmgTaken_M = Data[DestGUID].RealDMG.dmgTaken_M + Amount
        Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
        Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount        
    elseif school == 1  then
        -- Pysichal
        -- Taken 
        Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
        -- Done 
        Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
        -- Real Time Damage 
        Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount        
        Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount        
    else
        -- Magic
        -- Taken
        Data[DestGUID].DMG.dmgTaken_M = Data[DestGUID].DMG.dmgTaken_M + Amount
        -- Done 
        Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
        -- Real Time Damage        
        Data[DestGUID].RealDMG.dmgTaken_M = Data[DestGUID].RealDMG.dmgTaken_M + Amount        
        Data[SourceGUID].DMG.dmgDone_M = Data[SourceGUID].DMG.dmgDone_M + Amount
    end
    -- Totals
    -- Taken 
    Data[DestGUID].DMG.dmgTaken = Data[DestGUID].DMG.dmgTaken + Amount
    Data[DestGUID].DMG.hits_taken = Data[DestGUID].DMG.hits_taken + 1   
    -- Done 
    Data[SourceGUID].DMG.hits_done = Data[SourceGUID].DMG.hits_done + 1
    Data[SourceGUID].DMG.dmgDone = Data[SourceGUID].DMG.dmgDone + Amount
    -- Spells (Only Taken)
    local prev = (Data[DestGUID].spell_value[spellID] and Data[DestGUID].spell_value[spellID].Amount) or 0
    Data[DestGUID].spell_value[spellID] = {Amount = prev + Amount, TIME = TMW.time}
    -- Real Time Damage 
    -- Taken
    Data[DestGUID].RealDMG.LastHit_Taken = TMW.time     
    Data[DestGUID].RealDMG.dmgTaken = Data[DestGUID].RealDMG.dmgTaken + Amount
    Data[DestGUID].RealDMG.hits_taken = Data[DestGUID].RealDMG.hits_taken + 1 
    -- Done 
    Data[SourceGUID].RealDMG.LastHit_Done = TMW.time     
    Data[SourceGUID].RealDMG.dmgDone = Data[SourceGUID].RealDMG.dmgDone + Amount
    Data[SourceGUID].RealDMG.hits_done = Data[SourceGUID].RealDMG.hits_done + 1 
    -- DS (Only Taken)
    table.insert(Data[DestGUID].DS, {TIME = TMW.time, Amount = Amount})
end

--[[ This Logs the swings (damage) for every unit ]]
local logSwing = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, Amount = CombatLogGetCurrentEventInfo()
    -- Update last  hit time
    Data[DestGUID].DMG.lastHit_taken = TMW.time
    Data[SourceGUID].DMG.lastHit_done = TMW.time
    -- Damage 
    Data[DestGUID].DMG.dmgTaken_P = Data[DestGUID].DMG.dmgTaken_P + Amount
    Data[DestGUID].DMG.dmgTaken = Data[DestGUID].DMG.dmgTaken + Amount
    Data[DestGUID].DMG.hits_taken = Data[DestGUID].DMG.hits_taken + 1
    Data[SourceGUID].DMG.dmgDone_P = Data[SourceGUID].DMG.dmgDone_P + Amount
    Data[SourceGUID].DMG.dmgDone = Data[SourceGUID].DMG.dmgDone + Amount
    Data[SourceGUID].DMG.hits_done = Data[SourceGUID].DMG.hits_done + 1
    -- Real Time Damage 
    -- Taken
    Data[DestGUID].RealDMG.LastHit_Taken = TMW.time 
    Data[DestGUID].RealDMG.dmgTaken_S = Data[DestGUID].RealDMG.dmgTaken_S + Amount
    Data[DestGUID].RealDMG.dmgTaken_P = Data[DestGUID].RealDMG.dmgTaken_P + Amount
    Data[DestGUID].RealDMG.dmgTaken = Data[DestGUID].RealDMG.dmgTaken + Amount
    Data[DestGUID].RealDMG.hits_taken = Data[DestGUID].RealDMG.hits_taken + 1  
    -- Done 
    Data[SourceGUID].RealDMG.LastHit_Done = TMW.time     
    Data[SourceGUID].RealDMG.dmgDone_S = Data[SourceGUID].RealDMG.dmgDone_S + Amount
    Data[SourceGUID].RealDMG.dmgDone_P = Data[SourceGUID].RealDMG.dmgDone_P + Amount   
    Data[SourceGUID].RealDMG.dmgDone = Data[SourceGUID].RealDMG.dmgDone + Amount
    Data[SourceGUID].RealDMG.hits_done = Data[SourceGUID].RealDMG.hits_done + 1 
    -- DS (Only Taken)
    table.insert(Data[DestGUID].DS, {TIME = TMW.time, Amount = Amount})
end

--[[ This Logs the healing for every unit ]]
local logHealing = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, _,_,_, spellID, _,_, Amount = CombatLogGetCurrentEventInfo()
    -- Update last  hit time
    -- Taken 
    Data[DestGUID].HPS.heal_lasttime = TMW.time
    -- Done 
    Data[SourceGUID].HPS.heal_lasttime_done = TMW.time
    -- Totals    
    -- Taken 
    Data[DestGUID].HPS.heal_taken = Data[DestGUID].HPS.heal_taken + Amount
    Data[DestGUID].HPS.heal_hits_taken = Data[DestGUID].HPS.heal_hits_taken + 1
    -- Done   
    Data[SourceGUID].HPS.heal_done = Data[SourceGUID].HPS.heal_done + Amount
    Data[SourceGUID].HPS.heal_hits_done = Data[SourceGUID].HPS.heal_hits_done + 1   
    -- Spells (Only Taken)
    local prev = (Data[DestGUID].spell_value[spellID] and Data[DestGUID].spell_value[spellID].Amount) or 0
    Data[DestGUID].spell_value[spellID] = {Amount = prev + Amount, TIME = TMW.time} 
end

--[[ This Logs the shields for every unit ]]
local logAbsorb = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, DestName,_,_, spellID, spellName,_, auraType, Amount = CombatLogGetCurrentEventInfo()    
    if auraType == "BUFF" and Amount then
        Data[DestGUID].absorb_spells[spellName]["Amount"] = Amount      
    end    
end

local remove_logAbsorb = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, DestName,_,_, spellID, spellName,_, auraType, Amount = CombatLogGetCurrentEventInfo()
    if auraType == "BUFF" and Amount then
        Data[DestGUID].absorb_spells[spellName]["Amount"] = nil               
    end
end

--[[ This Logs the last cast and amount for every unit ]]
local logLastCast = function(...)
    local _,_,_, SourceGUID, _,_,_, DestGUID, DestName,_,_, spellID, spellName = CombatLogGetCurrentEventInfo()
    -- LastCast time
    Data[SourceGUID].spell_lastcast_time[spellID] = TMW.time 
    Data[SourceGUID].spell_lastcast_time[spellName] = TMW.time 
    -- Counter 
    Data[SourceGUID].spell_counter[spellID] = (not Data[SourceGUID].spell_counter[spellID] and 1) or (Data[SourceGUID].spell_counter[spellID] + 1)
    Data[SourceGUID].spell_counter[spellName] = (not Data[SourceGUID].spell_counter[spellName] and 1) or (Data[SourceGUID].spell_counter[spellName] + 1)
end 

--[[ These are the events we're looking for and its respective action ]]
local EVENTS = {
    ['SPELL_DAMAGE'] = logDamage,
    ['DAMAGE_SHIELD'] = logDamage,
    ['SPELL_PERIODIC_DAMAGE'] = logDamage,
    ['SPELL_BUILDING_DAMAGE'] = logDamage,
    ['RANGE_DAMAGE'] = logDamage,
    ['SWING_DAMAGE'] = logSwing,
    ['SPELL_HEAL'] = logHealing,
    ['SPELL_PERIODIC_HEAL'] = logHealing,
    ['SPELL_AURA_APPLIED'] = logAbsorb,   
    ['SPELL_AURA_REFRESH'] = logAbsorb,  
    ['SPELL_AURA_REMOVED'] = remove_logAbsorb,  
    ['SPELL_CAST_SUCCESS'] = logLastCast,
    ['UNIT_DIED'] = function(...) Data[select(8, CombatLogGetCurrentEventInfo())] = nil end,
}

--- ========================== FUNCTIONAL ===========================
--[[ Returns the total ammount of time a unit is in-combat for ]]
function CombatTime(UNIT)
    if not UNIT then 
		UNIT = "player" 
	end
	
    local GUID = UnitGUID(UNIT)     
    if Data[GUID] and InCombatLockdown() then
        local combatTime = TMW.time - Data[GUID].combat_time       
        return combatTime              
    end
	
    return 0
end

--[[ Get RealTime DMG Taken ]]
function getRealTimeDMG(UNIT)
    local total, Hits, phys, magic, swing = 0, 0, 0, 0, 0
    local combatTime = CombatTime(UNIT)
    local GUID = UnitGUID(UNIT)
    if Data[GUID] and combatTime > 0 and Data[GUID].RealDMG.LastHit_Taken > 0 then 
        local realtime = TMW.time - Data[GUID].RealDMG.LastHit_Taken
        local Hits = Data[GUID].RealDMG.hits_taken        
        -- Remove a unit if it hasnt recived dmg for more then our gcd
        if realtime > Env.GCD() + Env.CurrentTimeGCD() + 1 then 
            -- Damage Taken 
            Data[GUID].RealDMG.dmgTaken = 0
            Data[GUID].RealDMG.dmgTaken_S = 0
            Data[GUID].RealDMG.dmgTaken_P = 0
            Data[GUID].RealDMG.dmgTaken_M = 0
            Data[GUID].RealDMG.hits_taken = 0
            Data[GUID].RealDMG.lastHit_taken = 0  
        elseif Hits > 0 then                     
            total = Data[GUID].RealDMG.dmgTaken / Hits
            phys = Data[GUID].RealDMG.dmgTaken_P / Hits
            magic = Data[GUID].RealDMG.dmgTaken_M / Hits     
            swing = Data[GUID].RealDMG.dmgTaken_S / Hits 
        end
    end
    return total, Hits, phys, magic, swing
end

--[[ Get RealTime DMG Done ]]
function getRealTimeDPS(UNIT)
    local total, Hits, phys, magic, swing = 0, 0, 0, 0, 0
    local combatTime = CombatTime(UNIT)
    local GUID = UnitGUID(UNIT)
    if Data[GUID] and combatTime > 0 and Data[GUID].RealDMG.LastHit_Done > 0 then   
        local realtime = TMW.time - Data[GUID].RealDMG.LastHit_Done
        local Hits = Data[GUID].RealDMG.hits_done
        -- Remove a unit if it hasnt done dmg for more then our gcd
        if realtime > Env.GCD() + Env.CurrentTimeGCD() + 1 then 
            -- Damage Done
            Data[GUID].RealDMG.dmgDone = 0
            Data[GUID].RealDMG.dmgDone_S = 0
            Data[GUID].RealDMG.dmgDone_P = 0
            Data[GUID].RealDMG.dmgDone_M = 0
            Data[GUID].RealDMG.hits_done = 0
            Data[GUID].RealDMG.LastHit_Done = 0 
        elseif Hits > 0 then                         
            total = Data[GUID].RealDMG.dmgDone / Hits
            phys = Data[GUID].RealDMG.dmgDone_P / Hits
            magic = Data[GUID].RealDMG.dmgDone_M / Hits  
            swing = Data[GUID].RealDMG.dmgDone_S / Hits 
        end
    end
    return total, Hits, phys, magic, swing
end

--[[ Get DMG Taken ]]
function getDMG(UNIT)
    local total, Hits, phys, magic = 0, 0, 0, 0
    local GUID = UnitGUID(UNIT)
    if Data[GUID] then
        local combatTime = CombatTime(UNIT)
        -- Remove a unit if it hasn't recived dmg for more then 5 sec
        if TMW.time - Data[GUID].DMG.lastHit_taken > 5 then   
            -- Damage Taken 
            Data[GUID].DMG.dmgTaken = 0
            Data[GUID].DMG.dmgTaken_S = 0
            Data[GUID].DMG.dmgTaken_P = 0
            Data[GUID].DMG.dmgTaken_M = 0
            Data[GUID].DMG.hits_taken = 0
            Data[GUID].DMG.lastHit_taken = 0            
        elseif combatTime > 0 then
            total = Data[GUID].DMG.dmgTaken / combatTime
            phys = Data[GUID].DMG.dmgTaken_P / combatTime
            magic = Data[GUID].DMG.dmgTaken_M / combatTime
            Hits = Data[GUID].DMG.hits_taken or 0
        end
    end
    return total, Hits, phys, magic 
end

--[[ Get DMG Done ]]
function getDPS(UNIT)
    local total, Hits, phys, magic = 0, 0, 0, 0
    local GUID = UnitGUID(UNIT)
    if Data[GUID] then
        local Hits = Data[GUID].DMG.hits_done        
        -- Remove a unit if it hasn't done dmg for more then 5 sec
        if TMW.time - Data[GUID].DMG.lastHit_done > 5 then                    
            -- Damage Done
            Data[GUID].DMG.dmgDone = 0
            Data[GUID].DMG.dmgDone_S = 0
            Data[GUID].DMG.dmgDone_P = 0
            Data[GUID].DMG.dmgDone_M = 0
            Data[GUID].DMG.hits_done = 0
            Data[GUID].DMG.lastHit_done = 0            
        elseif Hits > 0 then
            total = Data[GUID].DMG.dmgDone / Hits
            phys = Data[GUID].DMG.dmgDone_P / Hits
            magic = Data[GUID].DMG.dmgDone_M / Hits            
        end
    end
    return total, Hits, phys, magic
end

--[[ Get Heal Taken ]]
function getHEAL(UNIT)
    local total, Hits = 0, 0
    local GUID = UnitGUID(UNIT)   
    if Data[GUID] then
        local combatTime = CombatTime(UNIT)
        -- Remove a unit if it hasn't recived heal for more then 5 sec
        if TMW.time - Data[GUID].HPS.heal_lasttime > 5 then            
            -- Heal Taken 
            Data[GUID].HPS.heal_taken = 0
            Data[GUID].HPS.heal_hits_taken = 0
            Data[GUID].HPS.heal_lasttime = 0            
        elseif combatTime > 0 then
            Hits = Data[GUID].HPS.heal_hits_taken
            total = Data[GUID].HPS.heal_taken / Hits                              
        end
    end
    return total, Hits      
end

--[[ Get Heal Done ]]
function getHPS(UNIT) 
    local total, Hits = 0, 0
    local GUID = UnitGUID(UNIT)   
    if Data[GUID] then
        local Hits = Data[GUID].HPS.heal_hits_done
        -- Remove a unit if it hasn't done heal for more then 5 sec
        if TMW.time - Data[GUID].HPS.heal_lasttime_done > 5 then            
            -- Healing Done
            Data[GUID].HPS.heal_done = 0
            Data[GUID].HPS.heal_hits_done = 0
            Data[GUID].HPS.heal_lasttime_done = 0
        elseif Hits > 0 then             
            total = Data[GUID].HPS.heal_done / Hits 
        end
    end
    return total, Hits      
end 

--[[ Get Spell Amount Taken with time ]]
function getHealSpellAmount(UNIT, SPELL, TIMER)
    if not TIMER then 
		TIMER = 5 
	end
	
    local total = 0
    local GUID = UnitGUID(UNIT)   
    if Data[GUID] and Data[GUID].spell_value[SPELL] then
        if TMW.time - Data[GUID].spell_value[SPELL].TIME <= TIMER then 
            total = Data[GUID].spell_value[SPELL].Amount
        else
            Data[GUID].spell_value[SPELL] = nil
        end 
    end
	
    return total  
end

--[[ Get Absorb Taken ]]
function getAbsorb(UNIT, spellID)
    local GUID = UnitGUID(UNIT)
    return (not spellID and UnitGetTotalAbsorbs(UNIT)) or (spellID and Data[GUID] and Data[GUID].absorb_spells[GetSpellInfo(spellID)]["Amount"]) or 0
end 

--[[ Time To Die ]]
function TimeToDieX(UNIT, X)
    if not UNIT then 
		UNIT = "target" 
	end

    local ttd = UnitHealth(UNIT) - ( UnitHealthMax(UNIT) * (X / 100) )
    local DMG, Hits = getDMG(UNIT)
	
    if DMG >= 1 and Hits > 1 then
        ttd = ttd / DMG
    end    
	
	-- Trainer dummy totems exception 
    if Env.Zone == "none" and UnitHealth(UNIT) == 1 then
        ttd = 500
    end
	
    return ttd
end

function TimeToDie(UNIT)
    if not UNIT then 
		UNIT = "target" 
	end
	
    local ttd = UnitHealthMax(UNIT)
    local DMG, Hits = getDMG(UNIT)
	
    if DMG >= 1 and Hits > 1 then
        ttd = UnitHealth(UNIT) / DMG
    end    
	
	-- Trainer dummy totems exception 
    if Env.Zone == "none" and UnitHealth(UNIT) == 1 then
        ttd = 500
    end
	
    return ttd
end

function TimeToDieMagicX(UNIT, X)
    if not UNIT then 
		UNIT = "target" 
	end

    local ttd = UnitHealth(UNIT) - ( UnitHealthMax(UNIT) * (X / 100) )
    local Hits, _, DMG = select(2, getDMG(UNIT))
	
    if DMG >= 1 and Hits > 1 then
        ttd = ttd / DMG
    end    
	
	-- Trainer dummy totems exception 
    if Env.Zone == "none" and UnitHealth(UNIT) == 1 then
        ttd = 500
    end
	
    return ttd
end

function TimeToDieMagic(UNIT)
    if not UNIT then 
		UNIT = "target" 
	end
	
    local ttd = UnitHealthMax(UNIT)
    local Hits, _, DMG = select(2, getDMG(UNIT))
	
    if DMG >= 1 and Hits > 1 then
        ttd = UnitHealth(UNIT) / DMG
    end  
	
	-- Trainer dummy totems exception 
    if Env.Zone == "none" and UnitHealth(UNIT) == 1 then
        ttd = 500
    end
	
    return ttd
end

--[[ SPELLS ]]
function SpellAmount(UNIT, spellID)
    local GUID = UnitGUID(UNIT)
    return (Data[GUID] and Data[GUID].spell_value[spellID].Amount) or 0
end

function SpellLastCast(UNIT, SPELL, byID)
	-- @return TMW.time stamp when spell was casted 
    local timer = 0
    local GUID = UnitGUID(UNIT)
    if Data[GUID] then
        if not byID and type(SPELL) == "number" then 
            SPELL = GetSpellInfo(SPELL)
        end 
        timer = Data[GUID].spell_lastcast_time[SPELL] or 0
    end 
    return timer
end 

function SpellTimeSinceLastCast(UNIT, SPELL, byID)
	-- @return time ticked since last time cast 
    local timer = 0
    local GUID = UnitGUID(UNIT)
    if Data[GUID] then
        if not byID and type(SPELL) == "number" then 
            SPELL = GetSpellInfo(SPELL)
        end 
        timer = Data[GUID].spell_lastcast_time[SPELL] or 0
		if timer > 0 then 
			timer = TMW.time - timer
		end 
    end 
    return timer
end 

function SpellCounter(UNIT, SPELL, byID)
    local timer = 0
    local GUID = UnitGUID(UNIT)
    if Data[GUID] then
        if not byID and type(SPELL) == "number" then 
            SPELL = GetSpellInfo(SPELL)
        end 
        timer = Data[GUID].spell_counter[SPELL] or 0
    end 
    return timer
end 

--[[ Mage Shrimmer/Blink Tracker (only enemy) ]]
local BlinkID = {
	[1953] = true, 
}
function GetShrimmer(UNIT)
	-- Default has no charges (means never used so it can be just normal Blink which should return 0 as charges then)
	local GUID = UnitGUID(unit) 
    local charges, cooldown, summary_cooldown = 0, 0, 0    
    if Data[GUID] then 
		if Data[GUID].Shrimmer then
			charges = 2
			for i = #Data[GUID].Shrimmer, 1, -1 do
				cooldown = Data[GUID].Shrimmer[i] - TMW.time
				if cooldown > 0 then
					charges = charges - 1
					summary_cooldown = summary_cooldown + cooldown												
				end            
			end 			
		elseif Data[GUID].Blink then 
			cooldown = Data[GUID].Blink - TMW.time
			if cooldown <= 0 then 
				cooldown = 0 
			else 
				summary_cooldown = cooldown
			end 
		end 
	end 
    return charges, cooldown, summary_cooldown
end 

--[[ DR: Diminishing (only enemy) ]]
function getDR(UNIT, drCat) 
	-- @return Tick (number: 100% -> 0%), Remain (number: 0 -> 18), Application (number: 0 -> 5), ApplicationMax (number: 0 -> 5)
--[[ drCat accepts:
	"root"           
	"stun"      -- PvE unlocked     
	"disorient"      
	"disarm" 	-- added in 1.1		   
	"silence"        
	"taunt"     -- PvE unlocked      
	"incapacitate"   
	"knockback" -- removed in 1.1
]]
	local GUID = UnitGUID(UNIT)
	-- Default 100% means no DR at all, and 0 if no ticks then no remaning time, Application is how much DR was applied and how much by that category can be applied totally 
	local DR_Tick, DR_Remain, DR_Application, DR_ApplicationMax = 100, 0, 0, DRData:GetApplicationMax(drCat)  	
	-- About Tick:
	-- Ticks go like 100 -> 50 -> 25 -> 0 or for Taunt 100 -> 65 -> 42 -> 27 -> 0
	-- 100 no DR, 0 full DR 
	if Data[GUID] and Data[GUID].DR and Data[GUID].DR[drCat] and Data[GUID].DR[drCat].reset and Data[GUID].DR[drCat].reset >= TMW.time then 
		DR_Tick 			= Data[GUID].DR[drCat].diminished
		DR_Remain 			= Data[GUID].DR[drCat].reset - TMW.time
		DR_Application 		= Data[GUID].DR[drCat].application
		DR_ApplicationMax 	= Data[GUID].DR[drCat].applicationMax
	end 
	
	return DR_Tick, DR_Remain, DR_Application, DR_ApplicationMax
end 

--- ============================= CORE ==============================
--[[ Combat Tracker ]]
Listener:Add("CombatTracker_Events", "COMBAT_LOG_EVENT_UNFILTERED", function(...)
        local _, EVENT, _, SourceGUID, _,_, sourceFlags, DestGUID, _, destFlags,_, spellID, spellName, _, auraType = CombatLogGetCurrentEventInfo()
		
        -- Add the unit to our data if we dont have it
        addToData(SourceGUID)
        addToData(DestGUID) 
		
        -- Triggers 
        if EVENTS[EVENT] then 
			EVENTS[EVENT](...) 
		end
		
		-- On hostile flags
		-- PvP players tracker 
		if EVENT == "SPELL_CAST_SUCCESS" and Env.InPvP() and isEnemy(sourceFlags) and isPlayer(sourceFlags) then 
			-- Shrimmer
			if spellID == 212653 then 
				local ShrimmerCD = 0
				if not Data[SourceGUID].Shrimmer then 
					Data[SourceGUID].Shrimmer = {}
				end 		
				
				table.insert(Data[SourceGUID].Shrimmer, TMW.time + 20)
				
				-- Since it has only 2 charges by default need remove old ones 
				if #Data[SourceGUID].Shrimmer > 2 then 
					table.remove(Data[SourceGUID].Shrimmer, 1)
				end 				
			end 
			-- Blink
			if BlinkID[spellID] then 
				Data[SourceGUID].Blink = TMW.time + 15				
			end 
		end 
		
		-- On hostile flags
		-- Diminishing (DR-Tracker)
		if (EVENT == "SPELL_AURA_REMOVED" or EVENT == "SPELL_AURA_APPLIED" or EVENT == "SPELL_AURA_REFRESH") and auraType == "DEBUFF" and isEnemy(destFlags) then 
			local drCat = DRData:GetSpellCategory(spellID)
			if drCat and (DRData:IsPVE(drCat) or isPlayer(destFlags)) then
				if not Data[DestGUID].DR then 
					Data[DestGUID].DR = {}
				end 
				
				local dr = Data[DestGUID].DR[drCat]				
				if EVENT == "SPELL_AURA_APPLIED" then 
					-- If something is applied, and the timer is expired,
					-- reset the timer in preparation for the effect falling off
					
					-- Here is has a small bug due specific of release through SPELL_AURA_REFRESH event 
					-- As soon as unit receive applied debuff aura (DR) e.g. this event SPELL_AURA_APPLIED he WILL NOT be diminished until next events such as SPELL_AURA_REFRESH or SPELL_AURA_REMOVED will be triggered
					-- Why this released like that by DRData Lib - I don't know and this probably can be tweaked however I don't have time to pay attention on it 
					-- What's why I added in 1.1 thing named 'Application' so feel free to use it to solve this bug
					if dr and dr.diminished ~= 100 and dr.reset < TMW.time then						
						dr.diminished = 100
						dr.application = 0
						dr.reset = 0
						-- No reason to this:
						--dr.applicationMax = DRData:GetApplicationMax(drCat) 
					end			
				else
					if not dr then
						-- If there isn't already a table, make one
						-- Start it at 1th application because the unit just got diminished
						local diminishedNext, applicationNext, applicationMaxNext = DRData:NextDR(100, drCat)
						dr = {
							diminished = diminishedNext,
							application = applicationNext,
							applicationMax = applicationMaxNext,
							reset = TMW.time + DRData:GetResetTime(drCat),
						}
						Data[DestGUID].DR[drCat] = dr
					else
						-- Diminish the unit by one tick
						-- Ticks go 100 -> 0						
						if dr.diminished and dr.diminished ~= 0 then
							dr.diminished, dr.application, dr.applicationMax = DRData:NextDR(dr.diminished, drCat)
							dr.reset = TMW.time + DRData:GetResetTime(drCat)
						end
					end				
				end 
			end 
		end 				
end)

Listener:Add("CombatTracker_Events", "PLAYER_REGEN_ENABLED", function()
        wipe(Data)                   
end)

Listener:Add("CombatTracker_Events", "PLAYER_REGEN_DISABLED", function()
		-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
        if SpellTimeSinceLastCast("player", Env.LastPlayerCastID) > 0.5 then 
            wipe(Data)
        end 
end)

--- ========================== INCOMING ============================
-- DS 
function LastIncDMG(unit, seconds)
    if not seconds then seconds = 5 end;
    local GUID, Amount = UnitGUID(unit), 0    
    if Data[GUID] then        
        for i in pairs(Data[GUID].DS) do
            -- Remove old trash values to clear table 
            if Data[GUID].DS[i].TIME < TMW.time - 20 then 
                Data[GUID].DS[i] = nil 
            elseif Data[GUID].DS[i].TIME >= TMW.time - seconds then
                Amount = Amount + Data[GUID].DS[i].Amount 
            end
        end    
    end
    return Amount
end

function incdmg(unit)
    if UnitExists(unit) then
        local pDMG = getDMG(unit)
        return pDMG or 0
    end
    return 0
end

function incdmgphys(unit)
    if UnitExists(unit) then
        local pDMG = select(3, getDMG(unit))
        return pDMG
    end
    return 0
end

function incdmgmagic(unit)
    if UnitExists(unit) then
        local mDMG = select(4, getDMG(unit))
        return mDMG
    end
    return 0
end

--- ========================== LOS OF CONTROL ============================
local cLossOfControl = _G.C_LossOfControl
local GetEventInfo = cLossOfControl.GetEventInfo
local GetNumEvents = cLossOfControl.GetNumEvents

local LossOfControl = {} 
--[[ 
Hex Schools:
0x1 Physical
0x2 Holy
0x4 Fire
0x8 Nature
0x10 Frost
0x20 Shadow
0x40 Arcane

locType:
BANISH
CHARM
CYCLONE
DAZE
DISARM
DISORIENT
DISTRACT
FREEZE
HORROR
INCAPACITATE
INTERRUPT
INVULNERABILITY
MAGICAL_IMMUNITY
PACIFY
PACIFYSILENCE -- "Disabled"
POLYMORPH
POSSESS
SAP
SHACKLE_UNDEAD
SLEEP
SNARE -- "Snared" slow usually example Concussive Shot
TURN_UNDEAD -- "Feared Undead" currently not usable in BFA PvP 
LOSECONTROL_TYPE_SCHOOLLOCK -- HAS SPECIAL HANDLING (per spell school) as "SCHOOL_INTERRUPT"
ROOT -- "Rooted"
CONFUSE -- "Confused" 
STUN -- "Stunned"
SILENCE -- "Silenced"
FEAR -- "Feared"
Usage: (string [required], string [only for "SCHOOL_INTERRUPT"], hex-number|table-hex-number [only for "SCHOOL_INTERRUPT"]
]]
function LossOfControlCreate(locType, name, ...)
    if locType == "SCHOOL_INTERRUPT" then 
        if not name then 
            print("[Debug Error] Can't create LossOfControl SCHOOL_INTERRUPT without name")
            return 
        elseif not ... then 
            print("[Debug Error] Can't create LossOfControl SCHOOL_INTERRUPT without hex values for school")
            return 
        end 
        
        if not LossOfControl[locType] then 
            LossOfControl[locType] = {}
        end         
      
        LossOfControl[locType][name] = {
			hex = type(...) == "table" and bitbxor(unpack(...)) or ...,
			result = 0,
		}
    else 
        if LossOfControl[locType] then 
            print("[Debug Error] Attemp to create LossOfControl with already existed locType: " .. locType)
            return         
        end 
        LossOfControl[locType] = 0 
    end     
end 

function LossOfControlRemove(locType, name)
	if LossOfControl[locType] then 
		if name then 
			if LossOfControl[locType][name] then 
				LossOfControl[locType][name] = nil 
			end 
		else
			LossOfControl[locType] = nil 
		end 
	end 
end 

function LossOfControlGet(locType, name)
    local result = 0
    if not LossOfControl[locType] then
        print("[Debug Error] Trying get LossOfControl which is not exist: " .. locType)
        return result
    end
    
    if name then 
        result = LossOfControl[locType][name] and LossOfControl[locType][name].result or 0
    else 
        result = LossOfControl[locType]        
    end 
    
    return (TMW.time >= result and 0) or result - TMW.time 
end 

local LossOfControlUpdateElipse = 0
local function LossOfControlUpdate()
    if TMW.time == LossOfControlUpdateElipse then
        return
    end
    LossOfControlUpdateElipse = TMW.time
    
    local isValidType = false
    for eventIndex = 1, GetNumEvents() do 
        local locType, spellID, text, _, start, timeRemaining, duration, lockoutSchool = GetEventInfo(eventIndex)  	
		
        if locType == "SCHOOL_INTERRUPT" then
            -- Check that the user has requested the schools that are locked out.
            if LossOfControl[locType] and lockoutSchool and lockoutSchool ~= 0 then 
                for name, val in pairs(LossOfControl[locType]) do
					if type(val) == "table" and val.hex and bitband(lockoutSchool, val.hex) ~= 0 then 						                 						
						isValidType = true
						LossOfControl[locType][name].result = (start or 0) + (duration or 0)											
					end 
                end 
            end 
        else 
            for name, val in pairs(LossOfControl) do 
                if type(val) ~=  "table" and _G["LOSS_OF_CONTROL_DISPLAY_" .. name] == text then 
                    -- Check that the user has requested the category that is active on the player.
                    isValidType = true
                    LossOfControl[locType] = (start or 0) + (duration or 0)
                    break 
                end 
            end 
        end
    end 
    
    -- Reset running durations.
    if not isValidType then 
        for name, val in pairs(LossOfControl) do 
            if type(val) ~= "table" and LossOfControlGet(name) > 0 then
                LossOfControl[name] = 0
            end            
        end
    end
end

--- Create all locType (exception INVULNERABILITY, MAGICAL_IMMUNITY, TURN_UNDEAD) and schools HOLY, ARCANE, NATURE
do 
	LossOfControlCreate("DAZE")
	LossOfControlCreate("DISTRACT")
	LossOfControlCreate("PACIFY")
	LossOfControlCreate("CONFUSE")
    --- PvP Trinket:
    LossOfControlCreate("DISARM")
    LossOfControlCreate("INCAPACITATE")
    LossOfControlCreate("DISORIENT")
    LossOfControlCreate("FREEZE")        
    LossOfControlCreate("SILENCE")
    LossOfControlCreate("POSSESS")    
    LossOfControlCreate("SAP")    
    LossOfControlCreate("CYCLONE")
    LossOfControlCreate("BANISH")
    LossOfControlCreate("PACIFYSILENCE")
    --- Dworf|DarkIronDwarf
    LossOfControlCreate("POLYMORPH")    
    LossOfControlCreate("SLEEP")
    LossOfControlCreate("SHACKLE_UNDEAD")
    --- Scourge + WR Berserk Rage + DK Lichborne
    LossOfControlCreate("FEAR")    
    LossOfControlCreate("HORROR")    
    --- Scourge
    LossOfControlCreate("CHARM")        
    --- Gnome and any freedom effects 
    LossOfControlCreate("ROOT")        
    LossOfControlCreate("SNARE")
    --- Human + DK Icebound|Lichborne
    LossOfControlCreate("STUN")
	--- Draenei / LightforgedDraenei
	LossOfControlCreate("SCHOOL_INTERRUPT", "HOLY", 0x2)
	--- BloodElf / Nightborne
	LossOfControlCreate("SCHOOL_INTERRUPT", "ARCANE", 0x40)
	--- ZandalariTroll
	LossOfControlCreate("SCHOOL_INTERRUPT", "NATURE", 0x8)
end 

Listener:Add('CombatTracker_Events', "LOSS_OF_CONTROL_UPDATE", LossOfControlUpdate)
Listener:Add('CombatTracker_Events', "LOSS_OF_CONTROL_ADDED", LossOfControlUpdate)