local DogTag = LibStub("LibDogTag-3.0", true)
local TMW = TMW
local CNDT = TMW.CNDT 
local Env = CNDT.Env

TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", DogTag.FireEvent, DogTag)

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