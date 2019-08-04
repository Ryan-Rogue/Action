--- Version 2.0
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs, tostring = pairs, tostring
local IsAddOnLoaded = IsAddOnLoaded

--- ============================ ERRORS ============================
local toDisable
for k, v in pairs({"ButtonFacade", "Masque", "Masque_ElvUIesque", "GSE", "Gnome Sequencer Enhanced", "Gnome Sequencer", "AddOnSkins"}) do    
    if IsAddOnLoaded(v) then
        toDisable = (toDisable or "\n") .. v .. "\n"
    end
end
if toDisable then 
	message("Disable next addons:" .. toDisable)
end

--- =========================== Listener ===========================
Listener = {}
local listeners = {}
local frame = CreateFrame("Frame", "Listener_Events")
frame:SetScript("OnEvent", function(_, event, ...)
        if not listeners[event] then return end
        for k in pairs(listeners[event]) do
            if k == "Stuff_Events" then 
                listeners[event][k](event, ...)
            else 
                listeners[event][k](...)
            end
        end
end)

function Listener.Add(_, name, event, callback)
    if not listeners[event] then
        frame:RegisterEvent(event)
        listeners[event] = {}
    end
    if not listeners[event][name] then 
        listeners[event][name] = callback
    end 
end

function Listener.Remove(_, name, event)
    if listeners[event] then
        listeners[event][name] = nil
    end
end

function Listener.Trigger(_, event, ...)
    onEvent(nil, event, ...)
end

--- =========================== GENERAL ===========================
local IsInInstance, IsActiveBattlefieldArena = 
	  IsInInstance, IsActiveBattlefieldArena
local UnitIsPlayer, UnitExists, UnitInBattleground = 
	  UnitIsPlayer, UnitExists, UnitInBattleground
local GetInstanceInfo =
	  GetInstanceInfo
	  
-- TODO: Make if local after fix old profiles	  
function Env.CheckInPvP()
    return 
    Env.Zone == "arena" or 
    Env.Zone == "pvp" or 
    UnitInBattleground("player") or 
    IsActiveBattlefieldArena() or
    C_PvP.IsWarModeDesired() or
    ( UnitIsPlayer("target") and Env.UNITEnemy("target") )
end

local function UpdateZoneAndPvP(event, ...)    
    -- Don't call it several times
    if TMW.time == Env.ZoneTimeStampSinceJoined then 
        return 
    end 
    
	-- Update Instance 
    Env.Instance, Env.Zone = IsInInstance()
	if 	event == "ZONE_CHANGED" or
        event == "ZONE_CHANGED_INDOORS" or 
        event == "ZONE_CHANGED_NEW_AREA" or
        event == "PLAYER_ENTERING_WORLD" or
        event == "PLAYER_ENTERING_BATTLEGROUND"
	then 
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		Env.InstanceInfo = { 
			name = name,
			instanceType = instanceType,
			difficultyID = difficultyID,
			instanceID = instanceID,
			instanceGroupSize = instanceGroupSize,
		} 
		Env.ZoneTimeStampSinceJoined = TMW.time
	end 
	
    if Env.InPvP_Toggle then
        return
    end    
    
    if event == "UI_INFO_MESSAGE" then     
		if Env.UI_INFO_MESSAGE_IS_WARMODE(...) then 
            Env.InPvP_Status = C_PvP.IsWarModeDesired()
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
        end                
        return 
    end            
    
    if event == "DUEL_REQUESTED" then
        Env.InPvP_Status = true
        Env.InPvP_Duel = true
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
        return
    elseif event == "DUEL_FINISHED" then
        Env.InPvP_Status = Env.CheckInPvP() 
        Env.InPvP_Duel = false
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
        return
    end            
    
    if not Env.InPvP_Duel and   
    (
        event == "ZONE_CHANGED" or
        event == "ZONE_CHANGED_INDOORS" or 
        event == "ZONE_CHANGED_NEW_AREA" or
        event == "PLAYER_ENTERING_WORLD" or
        event == "PLAYER_ENTERING_BATTLEGROUND" or
        event == "PLAYER_TARGET_CHANGED" or
        event == "PLAYER_LOGIN"
    )            
    then                                
        Env.InPvP_Status = Env.CheckInPvP()  
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
    end   
end 

function Env.UI_INFO_MESSAGE_IS_WARMODE(...)
	local ID, MSG = ...		
    if type(MSG) == "string" and (MSG == ERR_PVP_WARMODE_TOGGLE_OFF or MSG == ERR_PVP_WARMODE_TOGGLE_ON) then 
		return true 
	end 
	return false 
end 

Env.InPvP_Status, Env.InPvP_Toggle = false, false
Env.Instance, Env.Zone = "none", "none"
Listener:Add("Stuff_Events", "PLAYER_ENTERING_WORLD", 			UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "PLAYER_ENTERING_BATTLEGROUND", 	UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "PLAYER_TARGET_CHANGED", 			UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "DUEL_FINISHED", 					UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "DUEL_REQUESTED", 					UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "ZONE_CHANGED", 					UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "ZONE_CHANGED_INDOORS", 			UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "ZONE_CHANGED_NEW_AREA", 			UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "UI_INFO_MESSAGE", 				UpdateZoneAndPvP)
Listener:Add("Stuff_Events", "PLAYER_LOGIN", 					UpdateZoneAndPvP)

function Env.InPvP()    
    return Env.InPvP_Status or false
end

function Env.GetTimeSinceJoinInstance()
	if Env.ZoneTimeStampSinceJoined then 
		return TMW.time - Env.ZoneTimeStampSinceJoined
	end 
	return math.huge 
end 

--- ============================= FRAME =============================
function Env.IsIconShown(icon)
    local data = TMW:GetDataOwner(icon)
    return (data and data.attributes.realAlpha == 1) or false
end -- /dump TMW.CNDT.Env.IsIconShown("TMW:icon:1S2PCb9iygE4")

function Env.IsIconDisplay(icon)
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled and FRAME:IsVisible() and FRAME.attributes.texture) or 0    
end

function Env.IsIconEnabled(icon)
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled) or false
end

--- ============================= UTILS =============================
function quote(str)
    return "\""..str.."\""
end

function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function tableexist(self)  
    return (type(self) == "table" and next(self)) or false
end

function dynamic_array(dimension)
    local metatable = {}
    for i=1, dimension do
        metatable[i] = {__index = function(tbl, key)
                if i < dimension then
                    tbl[key] = setmetatable({}, metatable[i+1])
                    return tbl[key]
                end
            end
        }
    end
    return setmetatable({}, metatable[1])
end

-- ElvUI Fix
if ElvUI then 
    local handled = {["Frame"] = true}
	local object = CreateFrame("Frame")
    object.t = object:CreateTexture(nil,"BACKGROUND")
    local OldTexelSnappingBias = object.t:GetTexelSnappingBias()
    
    local function Fix(frame)
        if (frame and not frame:IsForbidden()) and frame.PixelSnapDisabled and not frame.PixelSnapTurnedOff then
            if frame.SetSnapToPixelGrid then
                frame:SetTexelSnappingBias(OldTexelSnappingBias)
            elseif frame.GetStatusBarTexture then
                local texture = frame:GetStatusBarTexture()
                if texture and texture.SetSnapToPixelGrid then                
                    texture:SetTexelSnappingBias(OldTexelSnappingBias)
                end
            end
            frame.PixelSnapTurnedOff = true 
        end
    end
    
    local function addapi(object)
        local mt = getmetatable(object).__index
        if mt.DisabledPixelSnap then 
            if mt.SetSnapToPixelGrid then hooksecurefunc(mt, 'SetSnapToPixelGrid', Fix) end
            if mt.SetStatusBarTexture then hooksecurefunc(mt, 'SetStatusBarTexture', Fix) end
            if mt.SetColorTexture then hooksecurefunc(mt, 'SetColorTexture', Fix) end
            if mt.SetVertexColor then hooksecurefunc(mt, 'SetVertexColor', Fix) end
            if mt.CreateTexture then hooksecurefunc(mt, 'CreateTexture', Fix) end
            if mt.SetTexCoord then hooksecurefunc(mt, 'SetTexCoord', Fix) end
            if mt.SetTexture then hooksecurefunc(mt, 'SetTexture', Fix) end
        end
    end
    
    addapi(object)
    addapi(object:CreateTexture())
    addapi(object:CreateFontString())
    addapi(object:CreateMaskTexture())
    object = EnumerateFrames()
    while object do
        if not object:IsForbidden() and not handled[object:GetObjectType()] then
            addapi(object)
            handled[object:GetObjectType()] = true
        end
        
        object = EnumerateFrames(object)
    end
end 

-------------------------------------------------------------------------------
-- Deprecated
-------------------------------------------------------------------------------
--- TODO: Remove from old profiles realesed until Priest 
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for i = 1, #orig do
            table.insert(copy, orig[1])
        end
        --[[ meta table
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
        --]]
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- Protector against FPS drop
--- TODO: Remove from old profiles realesed until Priest 
oLastCall = { ["global"] = 0.2 } -- refresh interval for few lua funcs
function fLastCall(obj)
    if not oLastCall[obj] then
        oLastCall[obj] = 0
    end
    return TMW.time >= oLastCall[obj]
end

--- ToolTip
--[[
local scanTip = CreateFrame("GameTooltip", "Scanner", UIParent, "GameTooltipTemplate")
local scanLine
function ScanToolTip(spellID)
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetSpellByID(spellID)
    scanLine = ScannerTextLeft3
    local t = scanLine:GetText()
    if (not t) then return end
    
    local numbers = {}
    for i=1,Scanner:NumLines() do
        local tooltipText = _G["ScannerTextLeft"..i]:GetText()
        tooltipText = string.gsub( tooltipText, "%p", '' )
        tooltipText = string.gsub( tooltipText, "%s", '' )
        
        for num in string.gmatch(tooltipText, "%d+") do
            table.insert(numbers, num)
        end
    end
    
    scanTip:Hide()
    return numbers
end
]]