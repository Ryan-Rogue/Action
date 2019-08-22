local DogTag = LibStub("LibDogTag-3.0", true)
local TMW = TMW
local CNDT = TMW.CNDT 
local Env = CNDT.Env
local StdUi = LibStub("StdUi")
local Action = Action

TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_CD_MODE_CHANGED", DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_MODE_CHANGED", DogTag.FireEvent, DogTag)

-- CDs
if DogTag then
    DogTag:AddTag("TMW", "ActionModeCD", {
        code = function()            			
			if Env.UseCDs == true then
			    return "|cff00ff00CD|r"
			else 
				return "|cFFFF0000CD|r"
			end			
        end,
        ret = "string",
        doc = "Displays CDs Mode",
		example = '[ActionModeCD] => "CDs ON"',
        events = "TMW_ACTION_CD_MODE_CHANGED",
        category = "ActionCDs",
    })
end

-- AoE
if DogTag then
    DogTag:AddTag("TMW", "ActionModeAoE", {
        code = function()		
			if Env.UseAoE == true then
			    return "|cff00ff00AoE|r"
			else 
				return "|cFFFF0000AoE|r"
			end
        end,
        ret = "string",
        doc = "Displays AoE Mode",
		example = '[ActionModeAoE] => "AoE ON"',
        events = "TMW_ACTION_AOE_MODE_CHANGED",
        category = "ActionAoE",
    })
end

-- PvP / PvE Mode
if DogTag then
    DogTag:AddTag("TMW", "ActionMode", {
        code = function()
            return Env.InPvP() and "PvP" or "PvE"
        end,
        ret = "string",
        doc = "Displays Rotation Mode",
		example = '[ActionMode] => "PvE"',
        events = "TMW_ACTION_MODE_CHANGED",
        category = "Action",
    })
end

