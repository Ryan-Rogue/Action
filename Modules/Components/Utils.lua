-------------------------------------------------------------------------------
-- TellMeWhen Utils
-------------------------------------------------------------------------------
local TMW 					= TMW
local CNDT 					= TMW.CNDT
local Env 					= CNDT.Env
local strlowerCache  		= TMW.strlowerCache

local A   					= Action
local Listener				= A.Listener
local GetToggle				= A.GetToggle
local toStr 				= A.toStr
local toNum 				= A.toNum
local Print 				= A.Print

local ActionDataColor		= A.Data.C

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_GetSpellInfo, TeamCacheEnemy, TeamCacheEnemyIndexToPLAYERs

Listener:Add("ACTION_EVENT_UTILS", "ADDON_LOADED", function(addonName) 
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_GetSpellInfo					= A.GetSpellInfo
		TeamCacheEnemy					= A.TeamCache.Enemy
		TeamCacheEnemyIndexToPLAYERs	= TeamCacheEnemy.IndexToPLAYERs
		Listener:Remove("ACTION_EVENT_UTILS", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------

local _G, assert, error, tostring, select, type, next, ipairs, table, wipe, hooksecurefunc, message = 
	  _G, assert, error, tostring, select, type, next, ipairs, table, wipe, hooksecurefunc, message
	  
local ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE	= _G.ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE
local ACTION_CONST_TMW_DEFAULT_STATE_HIDE 				= _G.ACTION_CONST_TMW_DEFAULT_STATE_HIDE	  
local ACTION_CONST_TMW_DEFAULT_STATE_SHOW 				= _G.ACTION_CONST_TMW_DEFAULT_STATE_SHOW	  
	  
local tremove				= table.remove	  
local strfind				= _G.strfind	  
local strmatch				= _G.strmatch
local UIParent				= _G.UIParent	
local C_UI					= _G.C_UI  
	  
local CreateFrame, GetCVar, SetCVar =
	  CreateFrame, GetCVar, SetCVar

local GetScreenResolutions, GetPhysicalScreenSize, GetScreenDPIScale =
	  GetScreenResolutions, GetPhysicalScreenSize, GetScreenDPIScale
	  
local GetNumClasses, GetClassInfo,  GetNumSpecializationsForClassID, GetSpecializationInfoForClassID, GetArenaOpponentSpec, GetBattlefieldScore, 	 GetSpellTexture, GetSpellInfo, CombatLogGetCurrentEventInfo =
	  GetNumClasses, GetClassInfo,  GetNumSpecializationsForClassID, GetSpecializationInfoForClassID, GetArenaOpponentSpec, GetBattlefieldScore, TMW.GetSpellTexture, GetSpellInfo, CombatLogGetCurrentEventInfo

local UnitName, UnitGUID 	=
	  UnitName, UnitGUID
	
-------------------------------------------------------------------------------
-- DataBase
-------------------------------------------------------------------------------
-- Clear old global snippets (always even if user accidentally installed it again)
local function ClearTrash()
	if TMW.db and TMW.db.global then 
		if TMW.db.global.CodeSnippets and type(TMW.db.global.CodeSnippets.n) == "number" and TMW.db.global.CodeSnippets.n > 0 then 
			local isRemove = {
				["Stuff"] 						= true, 
				["TMW Monitor"] 				= true,
				["CombatTracker"] 				= true,
				["LibPvP"] 						= true,
				["MultiUnits"] 					= true,
				["Scale and Chat"] 				= true,
				["MSGEvents"] 					= true,
				["AzeriteTraits"] 				= true,
				["Hybrid profile"] 				= true,
				["PMultiplier"] 				= true,
				["HealingEngine"] 				= true, 
				["PetLib"] 						= true, 
				["BossMods"] 					= true, 
				["DEV"] 						= true,			
			}
			for i, snippet in ipairs(TMW.db.global.CodeSnippets) do
				if isRemove[snippet.Name] then
					TMW.db.global.CodeSnippets[i] = nil 
					TMW.db.global.CodeSnippets.n = TMW.db.global.CodeSnippets.n - 1
				end
			end	
			
			isRemove = nil 
		end 
		
		if TMW.db.global.NumGroups and TMW.db.global.NumGroups >= 5 and TMW.db.global.Groups then 
			local isRemove 						= {
				["Global 1: Toggles"]			= true,
				["Global 2: Settings Button"]	= true,
				["Global: Help Text"]			= true,
				["Global: Help Text (Meta)"]	= true,
				["Global Anchor"]				= true,
			}
			
			local wasRemoved
			for i = 1, 5 do 
				for j = 1, 5 do 
					if isRemove[TMW.db.global.Groups[j].Name] then 
						tremove(TMW.db.global.Groups, j)
						wasRemoved = true 
						TMW.db.global.NumGroups = TMW.db.global.NumGroups - 1
						break 
					end 
				end 
			end 
			
			if wasRemoved then 
				A.TimerSet("UPDATE_AFTER_REMOVE", 2, function() TMW:Fire("TMW_ACTION_DEPRECATED_UPDATE_AFTER_REMOVE") end)	
				if TMW.db.global.NumGroups == 0 then 
					message("Reinstall profile again (from server)!")
				end 
			end 
			
			isRemove = nil 
		end 
	end 	
end 
hooksecurefunc(TMW, "InitializeDatabase", ClearTrash)	  

-------------------------------------------------------------------------------
-- CNDT: TalentMap  
-------------------------------------------------------------------------------
CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
CNDT:PLAYER_TALENT_UPDATE()

-------------------------------------------------------------------------------
-- CNDT: UnitSpecs  
-------------------------------------------------------------------------------
-- Note: This code is modified for Action Core 
specNameToRole, Env.ModifiedUnitSpecs = {}, {}

for i = 1, GetNumClasses() do
	local _, class, classID = GetClassInfo(i)
	specNameToRole[class] = {}

	for j = 1, GetNumSpecializationsForClassID(classID) do
		local specID, spec, desc, icon = GetSpecializationInfoForClassID(classID, j)
		specNameToRole[class][spec] = specID
	end
end

local SPECS = CNDT:GetModule("Specs")
function SPECS:UpdateUnitSpecs()
	if Env.UnitSpecs and next(Env.UnitSpecs) then
		wipe(Env.UnitSpecs)	
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end
	
	if next(Env.ModifiedUnitSpecs) then 
		wipe(Env.ModifiedUnitSpecs)
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end

	if A.Zone == "arena" then
		for i = 1, TeamCacheEnemy.MaxSize do 
			local unit = TeamCacheEnemyIndexToPLAYERs[i]

			if unit then 
				local name, server = UnitName(unit)
				if name and name ~= ACTION_CONST_UNKNOWN then
					local specID = GetArenaOpponentSpec(i)
					name = name .. (server and "-" .. server or "")
					if Env.UnitSpecs then 
						Env.UnitSpecs[name] = specID
					end 
					Env.ModifiedUnitSpecs[name] = specID				
				end
			end 
		end

		TMW:Fire("TMW_UNITSPEC_UPDATE")
	elseif A.Zone == "pvp" then
		for i = 1, TeamCacheEnemy.MaxSize do 
			local name, _, _, _, _, _, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
			if name then
				local specID = specNameToRole[classToken][talentSpec]
				if Env.UnitSpecs then 
					Env.UnitSpecs[name] = specID
				end 
				Env.ModifiedUnitSpecs[name] = specID
			end
		end
		
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end
end

SPECS:RegisterEvent("UNIT_NAME_UPDATE",   		"UpdateUnitSpecs")
SPECS:RegisterEvent("ARENA_OPPONENT_UPDATE", 	"UpdateUnitSpecs")
SPECS:RegisterEvent("GROUP_ROSTER_UPDATE", 		"UpdateUnitSpecs")
SPECS:RegisterEvent("PLAYER_ENTERING_WORLD", 	"UpdateUnitSpecs")
SPECS.PrepareUnitSpecEvents = TMW.NULLFUNC

-------------------------------------------------------------------------------
-- Env.LastPlayerCast
-------------------------------------------------------------------------------
-- Note: This code is modified for Action Core 
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
                if (e == "SPELL_CAST_SUCCESS" or e == "SPELL_MISS") and sourceGuid == pGUID and not blacklist[spellID] then
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					A.LastPlayerCastID		= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)    
        
        -- Spells that don't work with CLEU and must be tracked with USS.
		--[[
        local ussSpells = {
            [189110] = true, -- Infernal Strike (DH)
            [189111] = true, -- Infernal Strike (DH)
            [195072] = true, -- Fel Rush (DH)
        }]]
        module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",
            function(_, unit, _, spellID)
                if unit == "player" and not blacklist[spellID] then -- and ussSpells[spellID]
					local spellName			= A_GetSpellInfo(spellID)
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					A.LastPlayerCastID		= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)  
    end
end

-------------------------------------------------------------------------------
-- DogTags
-------------------------------------------------------------------------------
local DogTag = LibStub("LibDogTag-3.0", true)
TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED",  	DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_BURST_CHANGED", 	DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_CHANGED", 	 	DogTag.FireEvent, DogTag)
-- Taste's 
TMW:RegisterCallback("TMW_ACTION_CD_MODE_CHANGED", 	DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_MODE_CHANGED", DogTag.FireEvent, DogTag)

local function removeLastChar(text)
	return text:sub(1, -2)
end

if DogTag then
	-- Changes displayed mode on rotation frame
    DogTag:AddTag("TMW", "ActionMode", {
        code = function()
            return A.IsInPvP and "PvP" or "PvE"
        end,
        ret = "string",
        doc = "Displays Rotation Mode",
		example = '[ActionMode] => "PvE"',
        events = "TMW_ACTION_MODE_CHANGED",
        category = "Action",
    })
	-- Changes displayed burst on rotation frame 
	DogTag:AddTag("TMW", "ActionBurst", {
        code = function()
			if A.IsInitialized then 
				local Toggle = GetToggle(1, "Burst") or ""
				Toggle = Toggle and Toggle:upper()
				return Toggle == "EVERYTHING" and ("|c" .. ActionDataColor["GREEN"] .. "EVERY|r") or Toggle == "OFF" and ("|c" .. removeLastChar(ActionDataColor["RED"]) .. Toggle .. "|r") or ("|c" .. ActionDataColor["GREEN"] .. Toggle .. "|r")
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation Burst",
		example = '[ActionBurst] => "Auto, Off, Everything"',
        events = "TMW_ACTION_BURST_CHANGED",
        category = "Action",
    })
	-- Changes displayed aoe on rotation frame 
	DogTag:AddTag("TMW", "ActionAoE", {
        code = function()
			if A.IsInitialized then 
				return GetToggle(2, "AoE") and ("|c" .. ActionDataColor["GREEN"] .. "AoE|r") or "|c" .. removeLastChar(ActionDataColor["RED"]) .. "AoE|r"
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation AoE",
		example = '[ActionAoE] => "AoE (green or red)"',
        events = "TMW_ACTION_AOE_CHANGED",
        category = "Action",
    })
	
	-- Taste's 
    DogTag:AddTag("TMW", "ActionModeCD", {
        code = function()            
			if A.IsInitialized and GetToggle(1, "Burst") ~= "Off" then
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
	DogTag:AddTag("TMW", "ActionModeAoE", {
        code = function()            
			if A.IsInitialized and GetToggle(2, "AoE") then
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
	
	-- The biggest problem of TellMeWhen what he using :setup on frames which use DogTag and it's bring an error
	TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", function()
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
		TMW:Fire("TMW_ACTION_BURST_CHANGED")
		TMW:Fire("TMW_ACTION_AOE_CHANGED")
		-- Taste's 
		TMW:Fire("TMW_ACTION_CD_MODE_CHANGED")		
		TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED")
	end)
end

-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------
-- Note: icon can be "TMW:icon:1S2PCb9iygE4" (as GUID) or "TellMeWhen_Group1_Icon1" (as ID)
function Env.IsIconShown(icon)
	-- @return boolean, if icon physically shown	
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.attributes.realAlpha == 1) or false
end 

function Env.IsIconDisplay(icon)
	-- @return textureID or 0 
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled and FRAME:IsVisible() and FRAME.attributes.texture) or 0    
end

function Env.IsIconEnabled(icon)
	-- @return boolean
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled) or false
end

-------------------------------------------------------------------------------
-- Scales
-------------------------------------------------------------------------------
local BlackBackground = CreateFrame("Frame", nil, UIParent)
BlackBackground:SetBackdrop(nil)
BlackBackground:SetFrameStrata("HIGH")
BlackBackground:SetSize(736, 30)
BlackBackground:SetPoint("TOPLEFT", 0, 12) 
BlackBackground:SetShown(false)
BlackBackground.IsEnable = true
BlackBackground.texture = BlackBackground:CreateTexture(nil, "TOOLTIP")
BlackBackground.texture:SetAllPoints(true)
BlackBackground.texture:SetColorTexture(0, 0, 0, 1)

local isShownOnce
local function UpdateFrames()
    if not TellMeWhen_Group1 or not strfind(strlowerCache(TellMeWhen_Group1.Name), "shown main") then 
        if BlackBackground:IsShown() then
            BlackBackground:Hide()
        end     
		
        if TargetColor and TargetColor:IsShown() then
            TargetColor:Hide()
        end  
		
        return 
    end
	
	local myheight
	
	if GetCVar("gxMaximize") == "1" then 
		-- Fullscreen
		myheight = toNum[strmatch(GetScreenResolutions(), "%dx(%d+)")] 		-- toNum[string.match(GetCVar("gxFullscreenResolution"), "%d+x(%d+)")]		
	else 
		-- Windowed 														-- toNum[strmatch(GetScreenResolutions(), "%dx(%d+)")]
		myheight = select(2, GetPhysicalScreenSize())						-- toNum[string.match(GetCVar("gxWindowedResolution"), "%d+x(%d+)")]
		
		-- Regarding Windows DPI
		-- Note: Full HD 1920x1080 offsets (100% X8 Y31 / 125% X9 Y38)
		-- You might need specific thing to get truth relative graphic area, so just contact me if you see this and can't find fix for DPI > 1 e.g. 100%
		if not isShownOnce and GetScreenDPIScale() ~= 1 then 
			message("100% Windows DPI isn't supported by routines in Windowed mode. Make game in Fullscreen or set X and Y offsets in source.")
			isShownOnce = true
		end 
	end 
	
    local myscale1 = 0.42666670680046 * (1080 / myheight)
    local myscale2 = 0.17777778208256 * (1080 / myheight)    
    local group1, group2 = TellMeWhen_Group1:GetEffectiveScale()
    if TellMeWhen_Group2 and TellMeWhen_Group2.Enabled then
        group2 = TellMeWhen_Group2:GetEffectiveScale()   
    end    
	
	-- "Shown Main"
    if group1 ~= nil and group1 ~= myscale1 then
        TellMeWhen_Group1:SetParent(nil)
        TellMeWhen_Group1:SetScale(myscale1) 
        TellMeWhen_Group1:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group1:SetToplevel(true) 
        if BlackBackground.IsEnable then 
            if not BlackBackground:IsShown() then
                BlackBackground:Show()
            end
            BlackBackground:SetScale(myscale1 / (BlackBackground:GetParent() and BlackBackground:GetParent():GetEffectiveScale() or 1))      
        end 
    end
	
	-- "Shown Cast Bars"
    if group2 ~= nil and group2 ~= myscale2 then        
        TellMeWhen_Group2:SetParent(nil)        
        TellMeWhen_Group2:SetScale(myscale2) 
        TellMeWhen_Group2:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group2:SetToplevel(true)
    end   
	
	-- HealingEngine
    if TargetColor then
        if not TargetColor:IsShown() then
            TargetColor:Show()
        end
        TargetColor:SetScale((0.71111112833023 * (1080 / myheight)) / (TargetColor:GetParent() and TargetColor:GetParent():GetEffectiveScale() or 1))
    end              
end

local function UpdateCVAR()
    if GetCVar("Contrast") ~= "50" then 
		SetCVar("Contrast", 50)
		Print("Contrast should be 50")		
	end
	
    if GetCVar("Brightness") ~= "50" then 
		SetCVar("Brightness", 50) 
		Print("Brightness should be 50")			
	end
	
    if GetCVar("Gamma") ~= "1.000000" then 
		SetCVar("Gamma", "1.000000") 
		Print("Gamma should be 1")	
	end
	
    if GetCVar("colorblindsimulator") ~= "0" then 
		SetCVar("colorblindsimulator", 0) 
	end 
	
	--[[
    if GetCVar("RenderScale") ~= "1" then 
		SetCVar("RenderScale", 1) 
	end
	
    if GetCVar("MSAAQuality") ~= "0" then 
		SetCVar("MSAAQuality", 0) 
	end
	
    -- Could effect bugs if > 0 but FXAA should work, some people saying MSAA working too 
	local AAM = toNum[GetCVar("ffxAntiAliasingMode")]
    if AAM > 2 and AAM ~= 6 then 		
		SetCVar("ffxAntiAliasingMode", 0) 
		Print("You can't set higher AntiAliasing mode than FXAA or not equal to MSAA 8x")
	end
	]]
	
    if GetCVar("doNotFlashLowHealthWarning") ~="1" then 
		SetCVar("doNotFlashLowHealthWarning", 1) 
	end
	
	local nameplateMaxDistance = GetCVar("nameplateMaxDistance")
    if nameplateMaxDistance and toNum[nameplateMaxDistance] < ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE then 
		SetCVar("nameplateMaxDistance", ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE) 
		Print("nameplateMaxDistance " .. nameplateMaxDistance .. " => " .. ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE)	
	end		
	
    -- WM removal
    if GetCVar("screenshotQuality") ~= "10" then 
		SetCVar("screenshotQuality", 10)  
	end
	
    if GetCVar("nameplateShowEnemies") ~= "1" then
        SetCVar("nameplateShowEnemies", 1) 
		Print("Enemy nameplates should be enabled")
    end
	
	if GetCVar("autoSelfCast") ~= "1" then 
		SetCVar("autoSelfCast", 1)
	end 
end

local function ConsoleUpdate()
	UpdateCVAR()
    UpdateFrames()      
end 

local function TrueScaleInit()
    TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(_, frame)
            local str_group = toStr[frame]
            if strfind(str_group, "TellMeWhen_Group2") then                
                UpdateFrames()  
            end
    end)
	
	Listener:Add("ACTION_EVENT_UTILS", "DISPLAY_SIZE_CHANGED", 		ConsoleUpdate	)
	Listener:Add("ACTION_EVENT_UTILS", "UI_SCALE_CHANGED", 			ConsoleUpdate	)
	--Listener:Add("ACTION_EVENT_UTILS", "PLAYER_ENTERING_WORLD", 	ConsoleUpdate	)
	--Listener:Add("ACTION_EVENT_UTILS", "CVAR_UPDATE",				UpdateCVAR		)
	VideoOptionsFrame:HookScript("OnHide", 							ConsoleUpdate	)
	InterfaceOptionsFrame:HookScript("OnHide", 						UpdateCVAR		)
	--TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", 			UpdateCVAR		) -- For GetToggle things we have to make post call
    ConsoleUpdate()
	
    TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TMW_TEMP_SAFESETUP_COMPLETE")
end
TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TMW_TEMP_SAFESETUP_COMPLETE")    



function A.BlackBackgroundIsShown()
	-- @return boolean 
	return BlackBackground:IsShown()
end 

function A.BlackBackgroundSet(bool)
    BlackBackground.IsEnable = bool 
    BlackBackground:SetShown(bool)
end

-------------------------------------------------------------------------------
-- Frames 
-------------------------------------------------------------------------------
-- TellMeWhen Documentation - Sets attributes of an icon.
-- 
-- The attributes passed to this function will be processed by a [[api/icon-data-processor/api-documentation/|IconDataProcessor]] (and possibly one or more [[api/icon-data-processor-hook/api-documentation/|IconDataProcessorHook]]) and interested [[api/icon-module/api-documentation/|IconModule]]s will be notified of any changes to the attributes.
-- @name Icon:SetInfo
-- @paramsig signature, ...
-- @param signature [string] A semicolon-delimited string of attribute strings as passed to the constructor of a [[api/icon-data-processor/api-documentation/|IconDataProcessor]].
-- @param ... [...] Any number of params that will match up one-for-one with the signature passed in.
-- @usage icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
--  
--  -- From IconTypes/IconType_wpnenchant:
--  icon:SetInfo("state; start, duration; spell",
--    STATE_ABSENT,
--    0, 0,
--    nil
--  )
-- 
--  -- From IconTypes/IconType_reactive:
--  icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
--    STATE_USABLE,
--    GetSpellTexture(iName),
--    start, duration,
--    charges, maxCharges, chargeStart, chargeDur
--    stack, stack,
--    iName			
local function TMWAPI(icon, ...)
    local attributesString, param = ...
    
    if attributesString == "state" then 
        -- Color if not colored (Alpha will show it)
        if type(param) == "table" and param["Color"] then 
            if icon.attributes.calculatedState.Color ~= param["Color"] then 
                icon:SetInfo(attributesString, {Color = param["Color"], Alpha = param["Alpha"], Texture = param["Texture"]})
            end
            return 
        end 
        
        -- Hide if not hidden
        if type(param) == "number" and (param == 0 or param == ACTION_CONST_TMW_DEFAULT_STATE_HIDE) then
            if icon.attributes.realAlpha ~= 0 then 
                icon:SetInfo(attributesString, param)
            end 
            return 
        end 
    end 
    
    if attributesString == "texture" and type(param) == "number" then         
        if (icon.attributes.calculatedState.Color ~= "ffffffff" or icon.attributes.realAlpha == 0) then 
            -- Show + Texture if hidden
            icon:SetInfo("state; " .. attributesString, ACTION_CONST_TMW_DEFAULT_STATE_SHOW, param)
        elseif icon.attributes.texture ~= param then 
            -- Texture if not applied        
            icon:SetInfo(attributesString, param)
        end 
        return         
    end 
    
    icon:SetInfo(...)
end
  
function A.Hide(icon)
	-- @usage A.Hide(icon)
	if not icon then 
		error("A.Hide tried to hide nil 'icon'", 2)
	else 
		if icon.attributes.state ~= ACTION_CONST_TMW_DEFAULT_STATE_HIDE then 
			icon:SetInfo("state; texture", ACTION_CONST_TMW_DEFAULT_STATE_HIDE, "")
		end 
	end 
end 

function A:Show(icon, texture) 
	-- @usage self:Show(icon) for own texture with color filter or self:Show(icon, textureID)
	if not icon then 
		error((not texture and self:GetKeyName() or tostring(texture)) .. " tried to use Show() method with nil 'icon'", 2)
	else 
		if texture then 
			TMWAPI(icon, "texture", texture)
		else 
			TMWAPI(icon, self:Texture())
		end 
		return true 
	end 
end 

function A.FrameHasSpell(frame, spellID)
	-- @return boolean 
	-- @usage A.FrameHasSpell(icon, {123, 168, 18}) or A.FrameHasSpell(icon, 1022)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and type(frame.attributes.texture) == "number" then 
		local texture = frame.attributes.texture
		if type(spellID) == "table" then 
			for i = 1, #spellID do 
				if texture == GetSpellTexture(spellID[i]) then 
					return true 
				end 
			end 
		else 
			return texture == GetSpellTexture(spellID) 
		end 	
	end 
	return false 
end 

function A.FrameHasObject(frame, ...)
	-- @return boolean 
	-- @usage A.FrameHasObject(frame, A.Spell1, A.Item1)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and frame.attributes.texture and frame.attributes.texture ~= "" then 
		local texture = frame.attributes.texture
		for i = 1, select("#", ...) do 
			local obj = select(i, ...)
			local _, objTexture = obj:Texture()
			if objTexture and objTexture == texture then 
				return true 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- TMW PlayerNames fix
-------------------------------------------------------------------------------
if TELLMEWHEN_VERSIONNUMBER <= 87302 then -- Retail 87302
	local NAMES 											= TMW.NAMES
	local GetNumBattlefieldScores, 	  GetBattlefieldScore 	= 
	   _G.GetNumBattlefieldScores, _G.GetBattlefieldScore
	function NAMES:UPDATE_BATTLEFIELD_SCORE()
		for i = 1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, class, classToken = GetBattlefieldScore(i)
			if name then 
				if self.ClassColors[classToken] then 
					self.ClassColoredNameCache[name] = self.ClassColors[classToken] .. name .. "|r"
				elseif self.ClassColors[class] then 
					self.ClassColoredNameCache[name] = self.ClassColors[class] .. name .. "|r"
				end 
			end
		end
	end
end 

-------------------------------------------------------------------------------
-- TMW IconConfig.lua attempt to index field 'CurrentTabGroup' (nil value) fix
-------------------------------------------------------------------------------
local IE 			= TMW.IE
local CI 			= TMW.CI
local PlaySound 	= _G.PlaySound
function IE:LoadIcon(isRefresh, icon)
	if icon ~= nil then

		local ic_old = CI.icon

		if type(icon) == "table" then			
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
			IE:SaveSettings()
			
			CI.icon = icon
			
			if ic_old ~= CI.icon then
				IE.Pages.IconMain.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
				IE.Pages.IconMain.PanelsRight.ScrollFrame:SetVerticalScroll(0)
			end

			IE.TabGroups.ICON:SetChildrenEnabled(true)

		elseif icon == false then
			CI.icon = nil
			IE.TabGroups.ICON:SetChildrenEnabled(false)

			if IE.CurrentTabGroup and IE.CurrentTabGroup.identifier == "ICON" then
				IE.ResetButton:Disable()
			end
		end

		TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", CI.icon, ic_old)
	end

	IE:Load(isRefresh)
end