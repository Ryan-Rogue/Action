--- 2.0
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
local isNumber = TMW.isNumber
local strlowerCache = TMW.strlowerCache
local LibRangeCheck = LibStub("LibRangeCheck-2.0")
local IsSpellInRange = LibStub("SpellRange-1.0").IsSpellInRange

local type, pairs, huge, tableexist = type, pairs, math.huge, tableexist
local GetNetStats = GetNetStats
local IsStealthed, IsFalling, IsUsableSpell, IsPlayerSpell, IsSpellKnown = IsStealthed, IsFalling, IsUsableSpell, IsPlayerSpell, IsSpellKnown

local UnitClass, UnitRace, UnitAura, UnitCastingInfo, UnitChannelInfo, UnitName, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitHealth, UnitHealthMax, UnitExists,
UnitGroupRolesAssigned, UnitEffectiveLevel, UnitIsQuestBoss, UnitLevel, UnitCanAttack, UnitIsEnemy, UnitIsUnit, UnitDetailedThreatSituation, GetUnitSpeed, UnitIsPlayer,
UnitPower, UnitPowerMax = 
UnitClass, UnitRace, UnitAura, UnitCastingInfo, UnitChannelInfo, UnitName, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitHealth, UnitHealthMax, UnitExists,
UnitGroupRolesAssigned, UnitEffectiveLevel, UnitIsQuestBoss, UnitLevel, UnitCanAttack, UnitIsEnemy, UnitIsUnit, UnitDetailedThreatSituation, GetUnitSpeed, UnitIsPlayer,
UnitPower, UnitPowerMax 

local GetSpellInfo, GetShapeshiftForm, GetSpecialization, GetSpecializationInfo, GetSpellCooldown, GetSpellCharges, GetSpellBookItemInfo, GetPowerRegen, GetHaste, GetInventoryItemCooldown = 
Action.GetSpellInfo, GetShapeshiftForm, GetSpecialization, GetSpecializationInfo, GetSpellCooldown, GetSpellCharges, GetSpellBookItemInfo, GetPowerRegen, GetHaste, GetInventoryItemCooldown

local _, pclass = UnitClass("player")
local _, prace = UnitRace("player")
CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
CNDT:PLAYER_TALENT_UPDATE()

--- ========================== Utils ===========================
local function ArraySortByColl(array, col_number)
    for j = 1, #array - 1 do
        for i = 2, #array do
            if array[i][col_number] > array[i-1][col_number] then
                local x = array[i-1]
                array[i-1] = array[i]
                array[i] = x
            end
        end
    end
end

--- ======================= UnitAura ===========================
--- Buffs 
function Env.Buffs(unitID, spell, source, byID)
    local dur, duration
    local filter = "HELPFUL" .. (source and " PLAYER" or "")
    
    if type(spell) == "table" then         
        for i = 1, #spell do            
            dur, duration = Env.AuraDur(unitID, not byID and strlowerCache[GetSpellInfo(spell[i])] or spell[i], filter)                       
            if dur > 0 then
                break
            end
        end
    else
        dur, duration = Env.AuraDur(unitID, not byID and strlowerCache[GetSpellInfo(spell)] or spell, filter)
    end   
    
    return dur, duration
end

function Env.SortBuffs(unitID, spell, source, byID)    
    local dur, duration
    local filter = "HELPFUL" .. (source and " PLAYER" or "") 
    
    if type(spell) == "table" then
        local SortTable = {} 
        
        for i = 1, #spell do            
            dur, duration = Env.AuraDur(unitID, not byID and strlowerCache[GetSpellInfo(spell[i])] or spell[i], filter)                       
            if dur > 0 then
                table.insert(SortTable, {dur, duration})
            end
        end    
        
        if #SortTable > 0 then 
            ArraySortByColl(SortTable, 1)   
            return SortTable[1][1], SortTable[1][2]   
        end 
    else
        dur, duration = Env.AuraDur(unitID, not byID and strlowerCache[GetSpellInfo(spell)] or spell, filter)
    end   
    
    return dur, duration 
end

function Env.BuffStack(unitID, spell, source, byID)
    local filter = "HELPFUL" .. (source and " PLAYER" or "")    
    return Env.AuraStacks(unitID, not byID and strlowerCache[GetSpellInfo(spell)] or spell, filter)
end

--- DeBuffs
local IDexception = {
    [31117] = true, -- Unstable Affliction Silence
    [163505] = true, -- Rake Stun
    --[1822] = true, -- Rake spell (spellbook)
    --[231052] = true, -- Rake dot spell
    [155722] = true, -- Rake dot
    --[203123] = true, -- Maim
    --[236025] = true, -- Enraged Maim
    [339] = true, -- Entangling Roots dispel able
    [235963] = true, -- Entangling Roots NO dispel able
	[204085] = true, -- Deathchill (DK Frost PvP Roots)
    -- Garrote types 
    [703] = true, -- Dot 
    --[231719] = true, -- Silence 
    [1330] = true, -- Silence Debuff
    [216411] = true, -- Holy Shock Divine Purpose
    [216413] = true, -- Light of Down Divine Purpose
    [217832] = true, -- Imprison
}

function Env.DeBuffs(unitID, spell, source, byID)
    local dur, duration
    local filter = "HARMFUL" .. (source and " PLAYER" or "")    
    
    if type(spell) == "table" then         
        for i = 1, #spell do            
            dur, duration = Env.AuraDur(unitID, not byID and not IDexception[i] and strlowerCache[GetSpellInfo(spell[i])] or spell[i], filter)                       
            if dur > 0 then
                break
            end
        end
    else
        dur, duration = Env.AuraDur(unitID, not byID and not IDexception[spell] and strlowerCache[GetSpellInfo(spell)] or spell, filter)
    end   
    
    return dur, duration    
end

function Env.SortDeBuffs(unitID, spell, source, byID)
    local dur, duration
    local filter = "HARMFUL" .. (source and " PLAYER" or "")    
    
    if type(spell) == "table" then
        local SortTable = {} 
        
        for i = 1, #spell do            
            dur, duration = Env.AuraDur(unitID, not byID and not IDexception[i] and strlowerCache[GetSpellInfo(spell[i])] or spell[i], filter)                       
            if dur > 0 then
                table.insert(SortTable, {dur, duration})
            end
        end    
        
        if #SortTable > 0 then 
            ArraySortByColl(SortTable, 1)   
            return SortTable[1][1], SortTable[1][2]   
        end 
    else
        dur, duration = Env.AuraDur(unitID, not byID and not IDexception[spell] and strlowerCache[GetSpellInfo(spell)] or spell, filter)
    end   
    
    return dur, duration       
end

function Env.DeBuffStack(unitID, spell, source, byID)
    local filter = "HARMFUL" .. (source and " PLAYER" or "")    
    return Env.AuraStacks(unitID, not byID and not IDexception[spell] and strlowerCache[GetSpellInfo(spell)] or spell, filter)
end

--- Pandemic Threshold
function Env.PT(unitID, spell, debuff, byID)       
    local percent = Env.AuraPercent(unitID, not byID and not IDexception[spell] and strlowerCache[GetSpellInfo(spell)] or spell, (debuff and "HARMFUL" or "HELPFUL") .. " PLAYER")     
    return percent <= 0.3
end

--- ========================== PLAYER ===========================
function Env.global_invisible()
    return IsStealthed() or (pclass == "MAGE" and Env.Unit("player"):HasBuffs({32612, 110959, 198158}) > 0)    
end

function Env.TalentLearn(id)
    return Env.TalentMap[strlowerCache[GetSpellInfo(id)]] or false
end

function Env.PvPTalentLearn(id)
    return Env.PvpTalentMap[strlowerCache[GetSpellInfo(id)]] or false
end

function Env.Stance(n)
    local nStance = GetShapeshiftForm()    
    return nStance and nStance == n
end

function Env.GetStance()
    local nStance = GetShapeshiftForm()    
    return nStance or 0
end

local oFallStamp = 0
function Env.GetFalling()
    local Falling = IsFalling()
    if Falling then         
        if oFallStamp == 0 then 
            oFallStamp = TMW.time 
        elseif TMW.time - oFallStamp > 1.7 then 
            return Falling
        end         
    elseif oFallStamp > 0 then  
        oFallStamp = 0
    end 
    return false 
end
--- ========================== ROTATION ===========================
local function PlayerCastingEnd()
    local castingendtime = (select(5, UnitCastingInfo("player"))) or (select(5, UnitChannelInfo("player"))) or -1    
    return (castingendtime > 0 and castingendtime / 1000 - TMW.time) or -1
end

local LastCastException = {
    ["MAGE"] = 12051,    -- Evocation
    ["PRIEST"] = 15407,  -- Mind Fly
}
function Env.ShouldStop() -- true 
    local ping = (select(4, GetNetStats()) / 1000 * 2) + 0.05 
	local cGCD = Env.CurrentTimeGCD()
    return (Env.GCD() - cGCD > 0.3 and cGCD >= ping + 0.45) or ((not LastCastException[pclass] or Env.LastPlayerCastID ~= LastCastException[pclass]) and PlayerCastingEnd() > ping) or false
end

--- =========================== UNITS ============================
local function UpdatePlayerSpec() 
    local HealerSpecs = {105, 270, 65, 256, 257, 264}
    Env.PlayerSpec = GetSpecializationInfo(GetSpecialization())  
    for i = 1, #HealerSpecs do 
        if HealerSpecs[i] == Env.PlayerSpec then 
            Env.IamHealer = true
            return 
        end 
    end 
    Env.IamHealer = false 
end 
Listener:Add('Spec_Event', "PLAYER_LOGIN", UpdatePlayerSpec)
Listener:Add('Spec_Event', "PLAYER_ENTERING_WORLD", UpdatePlayerSpec)
Listener:Add('Spec_Event', "PLAYER_SPECIALIZATION_CHANGED", UpdatePlayerSpec)
Listener:Add('Spec_Event', "UPDATE_INSTANCE_INFO", UpdatePlayerSpec)

function Env.UNITSpec(unitID, specs)  
    local found
    local name, server = UnitName(unitID)
    if name then
        name = name .. (server and "-" .. server or "")
    else 
        return false 
    end       
    
    if type(specs) == "table" then        
        for i = 1, #specs do
            if unitID == "player" then
                found = specs[i] == Env.PlayerSpec
            else
                found = Env.ModifiedUnitSpecs and Env.ModifiedUnitSpecs[name] and specs[i] == Env.ModifiedUnitSpecs[name]
            end
            
            if found then
                break
            end
        end       
    else
        if unitID == "player" then
            found = specs == Env.PlayerSpec 
        else 
            found = Env.ModifiedUnitSpecs and Env.ModifiedUnitSpecs[name] and specs == Env.ModifiedUnitSpecs[name] 
        end       
    end
    
    return found or false
end

function Env.UNITRole(unitID, role)
    return (role and UnitGroupRolesAssigned(unitID) == role) or (not role and UnitGroupRolesAssigned(unitID)) 
end

function Env.UNITRace(unitID)
    return select(2, UnitRace(unitID)) or "none" 
end

function Env.UNITLevel(unitID)
    return UnitLevel(unitID)   
end

function Env.UNITEnemy(unitID)
    return (unitID and (UnitCanAttack("player", unitID) or UnitIsEnemy("player", unitID))) or false
end

function Env.UNITAgro(unitID, otherunit)
    local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(unitID, otherunit)
    return isTanking or false
end

function Env.UNITRange(unitID)
    local min_range, max_range = LibRangeCheck:GetRange(unitID)
    if not max_range then max_range = 0 end
    return max_range, min_range
end

function Env.UNITCurrentSpeed(unitID)
    return math.floor(GetUnitSpeed(unitID) / 7 * 100)
end

function Env.UNITMaxSpeed(unitID)
    return math.floor(select(2, GetUnitSpeed(unitID)) / 7 * 100)
end

local oMoveStamp = {}
function Env.UNITStaying(unit)   
    local move, GUID = Env.UNITCurrentSpeed(unit), UnitGUID(unit) 
    if move == 0 then
        if not oMoveStamp[GUID] or oMoveStamp[GUID] == -1 then 
            oMoveStamp[GUID] = TMW.time 
        end                        
    elseif move > 0 then  
        oMoveStamp[GUID] = -1
    end 
    return ((not oMoveStamp[GUID] or oMoveStamp[GUID] == -1) and -1) or (TMW.time - oMoveStamp[GUID]) 
end

function Env.UNITDead(unitID)
    return UnitIsDeadOrGhost(unitID) and not UnitIsFeignDeath(unitID)
end

function Env.UNITHP(unitID)
    return UnitHealth(unitID) * 100 / UnitHealthMax(unitID)
end

local function UnitIsBoss(unitID)
    for i = 1, MAX_BOSS_FRAMES do 
        if UnitIsUnit(unitID, "boss" .. i) then 
            return true 
        end 
    end 
    return false 
end 
function Env.UNITBoss(unitID)
    return Env.UNITLevel(unitID) == -1 or UnitEffectiveLevel(unitID) == -1 or UnitIsQuestBoss(unitID) or UnitIsBoss(unitID) or false 
end 

function Env.MyBurst(unit)
    if not unit then unit = "target" end
    return Env.Zone == "none" or Env.UNITBoss(unit) or UnitIsPlayer(unit)
end

--- ========================== SPELLS ===========================
local gcd = 1.5 / (1 + UnitSpellHaste("player") * 0.01)
function Env.GCD()
    if TMW.GCD > 0 then
        gcd = TMW.GCD
    end    
    return gcd
end

function Env.CurrentTimeGCD()
    return Env.CooldownDuration("gcd") -- TMW.GCDSpell
end

function Env.SpellCD(spellID)
    return Env.CooldownDuration(GetSpellInfo(spellID))
end

function Env.SpellCharges(spellID)
    local charges = Env.GetSpellCharges(GetSpellInfo(spellID))
    if not charges then 
        charges = 0
    end 
    return charges
end

function Env.ChargesFrac(spellID)
    local charges, maxCharges, start, duration = Env.GetSpellCharges(GetSpellInfo(spellID))
    if charges == maxCharges then 
        return maxCharges
    end
    return charges + ((TMW.time - start) / duration)    
end

function Env.SpellUsable(spell, offset)
    local offset = offset or ( select(4, GetNetStats()) / 1000 + 0.05)
    local spellName = GetSpellInfo(spell)
    return IsUsableSpell(spellName) and Env.SpellCD(spellName) <= offset -- works for pet spells 01/04/2019
end

function Env.SpellInRange(unit, id)
    return IsSpellInRange(GetSpellInfo(id), unit) == 1 or (Env.PetIsActive() and Env.PetSpellInRange(id))
end

function Env.SpellInteract(unit, range)  
    if not Env.Unit then 
        return false 
    end     
    local cur_range = Env.Unit(unit):GetRange()
    -- Holy Paladin Talent Range buff +50%
    if Env.UNITSpec("player", 65) and Env.Unit("player"):HasBuffs(214202, "player") > 0 then range = range * 1.5 end
    -- Moonkin and Restor +5 yards
    if Env.UNITSpec("player", {102, 105}) and Env.TalentLearn(197488) then range = range + 5 end  
    -- Feral and Guardian +3 yards
    if Env.UNITSpec("player", {103, 104}) and Env.TalentLearn(197488) then range = range + 3 end
    return cur_range and cur_range > 0 and cur_range <= range
end

function Env.SpellExists(spell)   
    if type(spell) ~= "number" then 
        spell = select(7, GetSpellInfo(spell)) 
    end 
    return spell and (IsPlayerSpell(spell) or (Env.PetIsActive() and IsSpellKnown(spell, true)))
end

function Env.GetDescription(spellID)
    local text = GetSpellDescription(spellID) 
    if not text then 
        return {0, 0} 
    end
    local deleted_space, numbers = string.gsub(text, "%s+", ''), {}
    deleted_space = string.gsub(deleted_space, "%d+%%", "")
    for num in string.gmatch(deleted_space, "%d+") do
        table.insert(numbers, tonumber(num))
    end
    if #numbers == 1 then
        return numbers
    end
    table.sort(numbers, function (x, y)
            return x > y
    end)
    return numbers
end

--- ========================== POWER ===========================
--- Instead realtime for static power better use cached function Env.CacheGetSpellPowerCost 
--- @return numbers: cost, type
local spellpowercache = setmetatable({}, { __index = function(t, v)
            local pwr = GetSpellPowerCost(GetSpellInfo(v))
            if pwr and pwr[1] then
                t[v] = { pwr[1].cost, pwr[1].type }
                return t[v]
            end     
            return {0, -1}
end })

function Env.CacheGetSpellPowerCost(a)
    return unpack(spellpowercache[a]) 
end

--- Note: This return realtime power cost which changes depend on buffs and etc.. 
function Env.GetPowerCost(spellID)
    local SpellPowerCost = Env.GetSpellPowerCost(GetSpellInfo(spellID)) 
    return SpellPowerCost and SpellPowerCost[1] and SpellPowerCost[1].cost or 0
end

function Env.ComboPoints()
    return UnitPower("player", Enum.PowerType.ComboPoints) or 0
end

function Env.Energy()
    return UnitPower("player", Enum.PowerType.Energy) or 0
end

function Env.EnergyDeficit()
    local max = UnitPowerMax("player", Enum.PowerType.Energy) or 0
    return max - Env.Energy()
end

function Env.EnergyRegen()
    return GetPowerRegen("player")
end

function Env.EnergyRemainingCastRegen(Offset) -- "energy.cast_regen"
    local EnergyRegen, Casting = Env.EnergyRegen(), select(2, Env.CastTime())
    if EnergyRegen == 0 then return -1 end
    -- If we are casting, we check what we will regen until the end of the cast
    if Casting > 0 then
        return EnergyRegen * (Casting + (Offset or 0))
        -- Else we'll use the remaining GCD as "CastTime"
    else
        return EnergyRegen * (Env.CurrentTimeGCD() + (Offset or 0))
    end
end

function Env.EnergyPredicted(Offset) -- Predict the expected Energy at the end of the Cast/GCD.
    local EnergyRegen = Env.EnergyRegen()
    if EnergyRegen == 0 then return -1 end;
    return math.min(UnitPowerMax("player", Enum.PowerType.Energy), UnitPower("player", Enum.PowerType.Energy) + Env.EnergyRemainingCastRegen(Offset))
end

function Env.Rage()
    return UnitPower("player", Enum.PowerType.Rage) or 0
end

function Env.RageDeficit()
    local max = UnitPowerMax("player", Enum.PowerType.Rage) or 0
    return max - Env.Rage()
end

function Env.UNITPW(unitID)
    return UnitPower(unitID) * 100 / UnitPowerMax(unitID)
end

--- ========================== Simcraft ===========================
function Env.execute_time(id) 
    -- Return GCD>CastTime or CastTime>GCD
    local gcd, cast_time = Env.GCD(), Env.CastTime(id)     
    if cast_time > gcd then
        return cast_time 
    else
        return gcd
    end
end

function Env.SpellHaste()
    return 1 / (1 + (GetHaste() / 100))
end

--- ========================== Casts ===========================
local prev_spellID, interruptpct = {}, {}
function Env.RandomKick(unitid, interruptAble)
    if not unitid then unitid = "target" end;
    local pct_castleft, spellID, spellName, notKickAble = select(3, Env.CastTime(nil, unitid))
    if spellID then               
        if not prev_spellID[unitid] or spellID ~= prev_spellID[unitid] then
            -- Soothing Mist
            if spellName ~= GetSpellInfo(209525) then
                interruptpct[unitid] = math.random(38, 83)
            else 
                interruptpct[unitid] = math.random(6, 12)
            end
            prev_spellID[unitid] = spellID
        end    
        return interruptpct[unitid] and pct_castleft >= interruptpct[unitid] and (not interruptAble or not notKickAble)
    end  
    return false
end

function Env.QuakingPalm(unit)
    local total, cur_castleft, pct_castleft, spellID, spellName, notKickAble = Env.CastTime(nil, unit)
    if spellID and cur_castleft < Env.GCD() then 
        return true 
    end 
    return false 
end 

function Env.CastTime(id, unitid)    
    -- 1: Total CastTime, 2: Current CastingTime Left, 3: Current CastingTime Percent 
    -- 4: ID, 5: Name, 6: notInterruptable (true yes, false able to kick)
    if not unitid then unitid = "player" end;
    local total, castleft, pct_castleft = 0, 0, 0
    local castName, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = UnitCastingInfo(unitid)
    if not castName then 
        castName, _, _, castStartTime, castEndTime, _, notInterruptable, spellID = UnitChannelInfo(unitid)
    end 
    
    if unitid == "player" and id then 
        total = (select(4, GetSpellInfo(id)) or 0) / 1000
        castleft = total 
    end 
    if castName and (not id or GetSpellInfo(id) == castName) then     
        total = (castEndTime - castStartTime) / 1000
        castleft = (TMW.time * 1000 - castStartTime) / 1000
        pct_castleft = castleft * 100 / total
    end
    return total, total-castleft, pct_castleft, spellID, castName, notInterruptable
end

--- ========================== CORE ===========================
Listener:Add('TMWMonitor_Event', "PLAYER_REGEN_ENABLED", function() 
        wipe(oMoveStamp) 
        wipe(prev_spellID)
        wipe(interruptpct)
end)

--- ======================== LASTCAST =========================
do
    local module = CNDT:GetModule("LASTCAST", true)
    if not module then
        module = CNDT:NewModule("LASTCAST", "AceEvent-3.0")
        
        local pGUID = UnitGUID("player")
        assert(pGUID, "pGUID was null when func string was generated!")
        
        local blacklist = {
            [204255] = true -- Soul Fragment (happens after casting Sheer for DH tanks)
        }
        
        module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",
            function()
                local _, e, _, sourceGuid, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
                if e == "SPELL_CAST_SUCCESS" and sourceGuid == pGUID and not blacklist[spellID] then
                    Env.LastPlayerCastName = strlower(spellName)
                    Env.LastPlayerCastID = spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)    
        
        -- Spells that don't work with CLEU and must be tracked with USS.
        local ussSpells = {
            [189110] = true, -- Infernal Strike (DH)
            [189111] = true, -- Infernal Strike (DH)
            [195072] = true, -- Fel Rush (DH)
        }
        module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",
            function(_, unit, _, spellID)
                if unit == "player" and ussSpells[spellID] and not blacklist[spellID] then
                    Env.LastPlayerCastName = strlower(GetSpellInfo(spellID))
                    Env.LastPlayerCastID = spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)  
    end
end

--- ========================== ITEMS ===========================
--- TODO: Remove on old profiles since it does now LibPvP 2.1+
function Env.UseItem(slot)    
    local start, duration, enable = GetInventoryItemCooldown("player", slot)    
    if enable == 0 or start + duration - TMW.time > 0 then
        return false
    end    
    return true
end

--- ========================== RACIALS ===========================
--- TODO: Remove on old profiles until June 2019
local Race = {
	SpellID = {
		Human = 59752, 
		NightElf = 58984,
		Dwarf = 20594, 
		Gnome = 20589, 
		Draenei = 28880, 
		Worgen = 68992, 
		Orc = 33697, 
		Troll = 26297, 
		Scourge = 7744,
		Tauren = 20549,
		BloodElf = 28730,
		Goblin = 69070, 
		Pandaren = 107079, 
		VoidElf = 256948,  
		LightforgedDraenei = 255647, 
		DarkIronDwarf = 265221, 
		HighmountainTauren = 255654, 
		Nightborne = 260364,
		Maghar = 274738,	
	},
	DAMAGE = {
		Orc = true, 
		Troll = true,
		BloodElf = true, 
		LightforgedDraenei = true,
		DarkIronDwarf = true, 
		Nightborne = true, 
		["Mag'har"] = true, 
	}, 
    TRINKET = {
        Human = true, 
        Dwarf = true,
        Gnome = true,
        Scourge = true,
        DarkIronDwarf = true,
    },
    DEFF = {
        Dwarf = true,
        Draenei = true,
    },
    SPRINT = {
        Worgen = true, 
        Goblin = true,
        HighmountainTauren = false,
    },
    CC = {
        Tauren = true,
        BloodElf = true,
        Pandaren = false,
        HighmountainTauren = false, 
    }, 	
}

function Env.SpellRace(key)	
    local id = Race.SpellID[prace]
	if id and Race[key][prace] and Env.SpellCD(id) <= 0.02 and Env.SpellExists(GetSpellInfo(id)) then 
		if key == "CC" then 
			if (prace == "BloodElf" or prace == "Tauren") and AoE(1, 8) then 
				return id 
			end 
			
			if prace == "Pandaren" and Env.QuakingPalm("target") then 
				return id 
			end 					
		end 
		
		if key == "SPRINT" then 
			if LossOfControlGet("ROOT") <= Env.CurrentTimeGCD() and LossOfControlGet("SNARE") <= Env.CurrentTimeGCD() then 
				return id 
			end 
		end
		
		if key == "DEFF" then 
			if prace == "Dwarf" and incdmgphys("player") >= incdmg("player") / 2 and TimeToDie("player") <= 10 then 
				return id 
			end 
			
			if prace == "Draenei" and TimeToDieX("player", 25) <= 5 and (UnitIsUnit("target", "player") or Env.Unit("target"):IsEnemy())then 
				return id 
			end 
		end 
		
		if key == "TRINKET" then 
			local Medallion = Env.PvPTalentLearn(208683) and 208683 or 195710	
			if prace == "Human" and LossOfControlGet("STUN") > 0 and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LossOfControlGet("DISARM") == 0 and 
				LossOfControlGet("INCAPACITATE") == 0 and
				LossOfControlGet("DISORIENT") == 0 and
				LossOfControlGet("FREEZE") == 0 and
				LossOfControlGet("SILENCE") == 0 and
				LossOfControlGet("POSSESS") == 0 and
				LossOfControlGet("SAP") == 0 and
				LossOfControlGet("CYCLONE") == 0 and
				LossOfControlGet("BANISH") == 0 and
				LossOfControlGet("PACIFYSILENCE") == 0 and
				LossOfControlGet("POLYMORPH") == 0 and
				LossOfControlGet("SLEEP") == 0 and
				LossOfControlGet("SHACKLE_UNDEAD") == 0 and
				LossOfControlGet("FEAR") == 0 and
				LossOfControlGet("HORROR") == 0 and
				LossOfControlGet("CHARM") == 0 and
				LossOfControlGet("ROOT") == 0)) then 
				return id 
			end
			
			if prace == "Dwarf" and (
				LossOfControlGet("POLYMORPH") > 0 or 
				LossOfControlGet("SLEEP") > 0 or 
				LossOfControlGet("SHACKLE_UNDEAD") > 0 or 
				Env.Unit("player"):HasDeBuffs("Poison") > 0 or 
				Env.Unit("player"):HasDeBuffs("Curse") > 0 or 
				Env.Unit("player"):HasDeBuffs("Magic") > 0
			) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LossOfControlGet("DISARM") == 0 and 
				LossOfControlGet("INCAPACITATE") == 0 and
				LossOfControlGet("DISORIENT") == 0 and
				LossOfControlGet("FREEZE") == 0 and
				LossOfControlGet("SILENCE") == 0 and
				LossOfControlGet("POSSESS") == 0 and
				LossOfControlGet("SAP") == 0 and
				LossOfControlGet("CYCLONE") == 0 and
				LossOfControlGet("BANISH") == 0 and
				LossOfControlGet("PACIFYSILENCE") == 0 and
				LossOfControlGet("STUN") == 0 and
				LossOfControlGet("FEAR") == 0 and
				LossOfControlGet("HORROR") == 0 and
				LossOfControlGet("CHARM") == 0 and
				LossOfControlGet("ROOT") == 0				
			)) then 
				return id 
			end 
			
			if prace == "Scourge" and (
				LossOfControlGet("FEAR") > 0 or 
				LossOfControlGet("HORROR") > 0 or 
				LossOfControlGet("SLEEP") > 0 or 
				LossOfControlGet("CHARM") > 0
			) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LossOfControlGet("DISARM") == 0 and 
				LossOfControlGet("INCAPACITATE") == 0 and
				LossOfControlGet("DISORIENT") == 0 and
				LossOfControlGet("FREEZE") == 0 and
				LossOfControlGet("SILENCE") == 0 and
				LossOfControlGet("POSSESS") == 0 and
				LossOfControlGet("SAP") == 0 and
				LossOfControlGet("CYCLONE") == 0 and
				LossOfControlGet("BANISH") == 0 and
				LossOfControlGet("PACIFYSILENCE") == 0 and
				LossOfControlGet("POLYMORPH") == 0 and
				LossOfControlGet("STUN") == 0 and
				LossOfControlGet("SHACKLE_UNDEAD") == 0 and 				
				LossOfControlGet("ROOT") == 0				
			)) then 
				return id
			end 
			
			if prace == "Gnome" and (LossOfControlGet("ROOT") > 0 or LossOfControlGet("SNARE") > 0) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LossOfControlGet("DISARM") == 0 and 
				LossOfControlGet("INCAPACITATE") == 0 and
				LossOfControlGet("DISORIENT") == 0 and
				LossOfControlGet("FREEZE") == 0 and
				LossOfControlGet("SILENCE") == 0 and
				LossOfControlGet("POSSESS") == 0 and
				LossOfControlGet("SAP") == 0 and
				LossOfControlGet("CYCLONE") == 0 and
				LossOfControlGet("BANISH") == 0 and
				LossOfControlGet("PACIFYSILENCE") == 0 and
				LossOfControlGet("POLYMORPH") == 0 and
				LossOfControlGet("SLEEP") == 0 and 
				LossOfControlGet("STUN") == 0 and
				LossOfControlGet("SHACKLE_UNDEAD") == 0 and 	
				LossOfControlGet("FEAR") == 0 and    
				LossOfControlGet("HORROR") == 0 			
			)) then 
				return id 
			end 

		end 
		
		if key == "DAMAGE" then 
			return id 
		end 		
	end 
	
    return false
end 	

function Env.GladiatorMedallion()
	return 
	Env.InPvP() and 
	(
		(
			Env.PvPTalentLearn(208683) and -- Gladiator
			Env.SpellCD(208683) == 0
		) or 
		(
			not Env.PvPTalentLearn(208683) and
			Env.SpellExists(195710) and -- Honor
			Env.SpellCD(195710) == 0
		)
	) and 
	(
		--- PvP Trinket:
		LossOfControlGet("DISARM") > 0 or 
		LossOfControlGet("INCAPACITATE") > 0 or 
		LossOfControlGet("DISORIENT") > 0 or 
		LossOfControlGet("FREEZE") > 0 or       
		LossOfControlGet("SILENCE") > 0 or 
		LossOfControlGet("POSSESS") > 0 or     
		LossOfControlGet("SAP") > 0 or     
		LossOfControlGet("CYCLONE") > 0 or 
		LossOfControlGet("BANISH") > 0 or 
		LossOfControlGet("PACIFYSILENCE") > 0 or 
		--- Dworf|DarkIronDwarf
		LossOfControlGet("POLYMORPH") > 0 or     
		LossOfControlGet("SLEEP") > 0 or 
		LossOfControlGet("SHACKLE_UNDEAD") > 0 or 
		--- Scourge + WR Berserk Rage + DK Lichborne
		LossOfControlGet("FEAR") > 0 or     
		LossOfControlGet("HORROR") > 0 or     
		--- Scourge
		LossOfControlGet("CHARM") > 0 or         
		--- Gnome and any freedom effects 
		LossOfControlGet("ROOT") > 0 or         
		LossOfControlGet("SNARE") > 0 or 
		--- Human + DK Icebound|Lichborne
		LossOfControlGet("STUN") > 0 
	)	
end

