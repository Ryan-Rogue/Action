local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs = pairs
local ListenedSpells = {}
local ListenedAuras = {}
local ListenedLastCast = {}
local UnitGUID, GetSpellInfo = UnitGUID, Action.GetSpellInfo
local _, pclass = UnitClass("player")

--- ============================ CONTENT ============================
-- PMultiplier Calculator
local function ComputePMultiplier(ListenedSpell)
    local PMultiplier = 1
    for j = 1, #ListenedSpell.Buffs do
        local Buff = ListenedSpell.Buffs[j]
        local Spell = Buff[1]
        local Modifier = Buff[2]
        -- Check if we did registered a Buff to check + a modifier (as a number or through a function).
        if Modifier then
            if Env.Buffs("player", Spell, "player")>0 or (ListenedLastCast[SpellID] and TMW.time-ListenedLastCast[SpellID] < 0.1)  then
                local ModifierType = type(Modifier)
                if ModifierType == "number" then
                    PMultiplier = PMultiplier * Modifier
                elseif ModifierType == "function" then
                    PMultiplier = PMultiplier * Modifier()
                end
            end
        else
            -- If there is only one element, then check if it's an AIO function and call it.
            if type(Spell) == "function" then
                PMultiplier = PMultiplier * Spell()
            end
        end
    end
    return PMultiplier
end

local function PMultiplierLaunch(...)
	-- Feral 
	if Env.UNITSpec("player", 103) then 
		Listener:Add('PMultiplier', "COMBAT_LOG_EVENT_UNFILTERED", function(...)
			local _, EVENT, _, SourceGUID, _,_,_, DestGUID, _, _, _, SpellID  = CombatLogGetCurrentEventInfo()
			-- PMultiplier OnCast Listener
			if SourceGUID ~= UnitGUID("player") then
				return
			end
			
			if EVENT == "SPELL_CAST_SUCCESS" then 
				local ListenedSpell = ListenedSpells[SpellID]
				if ListenedSpell then
					local PMultiplier = ComputePMultiplier(ListenedSpell)
					ListenedSpell.PMultiplier[DestGUID] = { PMultiplier = PMultiplier, Time = TMW.time, Applied = false }
					ListenedLastCast[SpellID] = TMW.time
				end    
				-- PMultiplier OnApply/OnRefresh Listener
			elseif EVENT == "SPELL_AURA_APPLIED" or EVENT == "SPELL_AURA_REFRESH" then 
				local ListenedAura = ListenedAuras[SpellID]
				if ListenedAura then
					local ListenedSpell = ListenedSpells[ListenedAura]
					if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
						ListenedSpell.PMultiplier[DestGUID].Applied = true
					end
				end    
			elseif EVENT == "SPELL_AURA_REMOVED" then 
				local ListenedAura = ListenedAuras[SpellID]
				if ListenedAura then
					local ListenedSpell = ListenedSpells[ListenedAura]
					if ListenedSpell and ListenedSpell.PMultiplier[DestGUID] then
						ListenedSpell.PMultiplier[DestGUID].Applied = false
					end
				end    
				-- PMultiplier OnRemove & OnUnitDeath Listener    
			elseif EVENT == "UNIT_DIED"    or EVENT == "UNIT_DESTROYED" then         
				for SpellID, Spell in pairs(ListenedSpells) do
					if Spell.PMultiplier[DestGUID] then
						Spell.PMultiplier[DestGUID] = nil
					end
				end            
			end 		
		end)
	else 
		Listener:Remove('PMultiplier', "COMBAT_LOG_EVENT_UNFILTERED")
	end
end

if pclass == "DRUID" then 
	Listener:Add('PMultiplier', "PLAYER_SPECIALIZATION_CHANGED", PMultiplierLaunch)
	PMultiplierLaunch()
end 

function RegisterPMultiplier(...)
    local Args = { ... }
    local SelfSpellID = Args[1]
    -- Get the SpellID to check on AURA_APPLIED/AURA_REFRESH, should be specified as first arg or it'll take the current spell object.
    local SpellAura = SelfSpellID
    if type(Args[2]) == "number" then
        SpellAura = Args[2]
        table.remove(Args, 2)
    end
    table.remove(Args, 1)
    
    ListenedAuras[SpellAura] = SelfSpellID
    ListenedSpells[SelfSpellID] = { Buffs = Args, PMultiplier = {} }
    --[[
    for k,v in pairs(Args) do
        if type(v) == "table" then
            for _, v1 in pairs(v) do
                if type(v1) == "function" then
                    print(k .. " and " .. v1())
                else
                    print(k .. " and " .. v1)
                end
            end
        elseif type(v) == "function" then
            print(k .. " and " .. v())
        else
            print(k .. " and " .. v)           
        end
    end
    print(Args[1])
]]
end

local function SpellRegisterError(Spell)
    local SpellName = GetSpellInfo(Spell)
    if SpellName then
        return "You forgot to register the spell: " .. SpellName .. " in PMultiplier handler."
    else
        return "You forgot to register the spell object."
    end
end

-- dot.foo.pmultiplier
function PMultiplier(Unit, SpellID)
    if ListenedSpells[SpellID].PMultiplier then
        local UnitDot = ListenedSpells[SpellID].PMultiplier[UnitGUID(Unit)]
        return UnitDot and UnitDot.Applied and UnitDot.PMultiplier or 0
    else
        error(SpellRegisterError(SpellID))
    end
end

-- action.foo.persistent_multiplier
function Persistent_PMultiplier(SpellID)
    local ListenedSpell = ListenedSpells[SpellID]
    if ListenedSpell then
        return ComputePMultiplier(ListenedSpell)
    else
        error(SpellRegisterError(SpellID))
    end
end


-- Test https://github.com/herotc/hero-lib/blob/0918fba55949f42f75801c566dbbad2801ad59c2/HeroLib/Events/PMultiplier.lua
--[[
RegisterPMultiplier( -- Rake dot and action
    1822,
    155722, 
    {function ()
            return Env.global_invisible() and 2 or 1
    end},
    {145152, 1.2}, {52610, 1.15}, {5217, 1.15}
)
RegisterPMultiplier(
    1079, -- Rip action
    -- BloodtalonsBuff, SavageRoar, TigersFury
    {145152, 1.2}, {52610, 1.15}, {5217, 1.15}
)
-- Usage
Persistent_PMultiplier(1822)
PMultiplier("target", 1822)
]]

