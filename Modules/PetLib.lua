local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs, type, print = pairs, type, Action.Print
local IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable, GetSpellInfo = IsActionInRange, GetActionInfo, PetHasActionBar, GetPetActionsUsable, Action.GetSpellInfo

local oPetSlots = {
    -- Unholy 
    [252] = {
        [47482] = 0, -- Jump
        [47481] = 0, -- Gnaw
    }, 
}

function Env.PetSpellInRange(id, unit)
    if not unit then unit = "target" end 
    local slot = oPetSlots[Env.PlayerSpec] and oPetSlots[Env.PlayerSpec][id]
    return (slot and slot > 0 and IsActionInRange(slot, unit)) or false
end 

function Env.PetAoE(spellID, stop)
    local UnitPlates = GetActiveUnitPlates("enemy")
    local total = 0 
    if UnitPlates then 
        for reference, unit in pairs(UnitPlates) do
            if type(spellID) == "table" then
                for i = 1, #spellID do
                    if Env.PetSpellInRange(spellID[i], unit) then
                        total = total + 1  
                        break
                    end
                end
            elseif Env.PetSpellInRange(spellID, unit) then 
                total = total + 1                                            
            end  
            
            if stop and total >= stop then
                break                        
            end     
        end
    end 
    return total 
end 

function Env.PetIsActive()
    return PetHasActionBar() or GetPetActionsUsable()
end

-- ================= CORE =================
local PetEvent_timestamp = TMW.time 
local function UpdatePetSlots()
    PetEvent_timestamp = TMW.time 
    local display_error    
    for k, v in pairs(oPetSlots[Env.PlayerSpec]) do            
        if v == 0 then 
            for i = 1, 120 do 
                actionType, id, subType = GetActionInfo(i)
                if subType == "pet" and k == id then 
                    oPetSlots[Env.PlayerSpec][k] = i 
                    break 
                end 
                if i == 120 then 
                    display_error = true
                end 
            end
        end
    end        
    -- Display errors 
    if display_error then 
        print("The following spells are missed on your action bar:")
        print("Note: PetActionBar doesn't work, you need place following pet spells on default action bar")
        for k, v in pairs(oPetSlots[Env.PlayerSpec]) do
            if v == 0 then
                print(GetSpellLink(k) .. " is not found on your action bar")
            end                
        end 
    end       
end 

local function UpdateUnitPet(...)
    if oPetSlots[Env.PlayerSpec] and  ... == "player" and Env.PetIsActive() and TMW.time ~= PetEvent_timestamp then     
        for k, v in pairs(oPetSlots[Env.PlayerSpec]) do
            if v == 0 then 
                UpdatePetSlots()
                break
            end
        end                 
    end 
end 

local function UpdateActionSlotChanged(...)
    local UseUpdate
    if oPetSlots[Env.PlayerSpec] and Env.PetIsActive() and TMW.time ~= PetEvent_timestamp then
        for k, v in pairs(oPetSlots[Env.PlayerSpec]) do
            if v == 0 or v == ... then 
                oPetSlots[Env.PlayerSpec][k] = 0
                UseUpdate = true 
            end
        end         
        if UseUpdate then 
            UpdatePetSlots()
        end
    end
end 

local function Update()
    if oPetSlots[Env.PlayerSpec] then 
        Listener:Add('PetLib_Events', "UNIT_PET", UpdateUnitPet)
        Listener:Add('PetLib_Events', "ACTIONBAR_SLOT_CHANGED", UpdateActionSlotChanged)
        UpdatePetSlots()
    else 
        Listener:Remove('PetLib_Events', "UNIT_PET")
        Listener:Remove('PetLib_Events', "ACTIONBAR_SLOT_CHANGED")
    end 
end 

Listener:Add('PetLib_Events', "PLAYER_ENTERING_WORLD", Update)
Listener:Add('PetLib_Events', "UPDATE_INSTANCE_INFO", Update)
Listener:Add('PetLib_Events', "PLAYER_SPECIALIZATION_CHANGED", Update)

