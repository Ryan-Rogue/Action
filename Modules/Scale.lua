local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env
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

local tostring, tonumber, print = 
	  tostring, tonumber, Action.Print
	  
-- Just checks what it has 8.2+	  
local AzeriteEssence = _G.C_AzeriteEssence		  

local function UpdateFrames()
    if not TellMeWhen_Group1 or (not strfind(TellMeWhen_Group1.Name, "[GGL]") and not strfind(TellMeWhen_Group1.Name, "Main")) then 
        if BlackBackground:IsShown() then
            BlackBackground:Hide()
        end        
        if TargetColor and TargetColor:IsShown() then
            TargetColor:Hide()
        end        
        return 
    end
	local myhight
	
	if GetCVar("gxMaximize") == "1" and AzeriteEssence then 
		-- Fullscreen (only 8.2+)
		myhight = tonumber(string.match(GetCVar("gxFullscreenResolution"), "%d+x(%d+)"))
	else 
		-- Windowed 
		myhight = tonumber(string.match(GetCVar("gxWindowedResolution"), "%d+x(%d+)"))
	end 
	
    local myscale1 = 0.42666670680046 * (1080 / myhight)
    local myscale2 = 0.17777778208256 * (1080 / myhight)    
    local group1, group2 = TellMeWhen_Group1:GetEffectiveScale()
    if TellMeWhen_Group2 and TellMeWhen_Group2.Enabled then
        group2 = TellMeWhen_Group2:GetEffectiveScale()   
    end    
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
    if group2 ~= nil and group2 ~= myscale2 then        
        TellMeWhen_Group2:SetParent(nil)        
        TellMeWhen_Group2:SetScale(myscale2) 
        TellMeWhen_Group2:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group2:SetToplevel(true)
    end   
    if TargetColor then
        if not TargetColor:IsShown() then
            TargetColor:Show()
        end
        TargetColor:SetScale((0.71111112833023 * (1080 / myhight)) / (TargetColor:GetParent() and TargetColor:GetParent():GetEffectiveScale() or 1))
    end              
end

local function UpdateCVAR()
    if GetCVar("Contrast")~="50" then 
		SetCVar("Contrast", 50)
		print("Contrast should be 50")		
	end
    if GetCVar("Brightness")~="50" then 
		SetCVar("Brightness", 50) 
		print("Brightness should be 50")			
	end
    if GetCVar("Gamma")~="1.000000" then 
		SetCVar("Gamma", "1.000000") 
		print("Gamma should be 1")	
	end
    if GetCVar("colorblindsimulator")~="0" then SetCVar("colorblindsimulator", 0) end; 
    -- Not neccessary
    if GetCVar("RenderScale")~="1" then SetCVar("RenderScale", 1) end; 
    if GetCVar("MSAAQuality")~="0" then SetCVar("MSAAQuality", 0) end;
    -- Could effect bugs if > 0 but FXAA should work, some people saying MSAA working too 
	local AAM = tonumber(GetCVar("ffxAntiAliasingMode"))
    if AAM > 2 and AAM ~= 6 then 		
		SetCVar("ffxAntiAliasingMode", 0) 
		print("You can't set higher AntiAliasing mode than FXAA or not equal to MSAA 8x")
	end
    if GetCVar("doNotFlashLowHealthWarning")~="1" then SetCVar("doNotFlashLowHealthWarning", 1) end; 
    -- WM removal
    if GetCVar("screenshotQuality")~="10" then SetCVar("screenshotQuality", 10) end;    
    -- UNIT_NAMEPLAYES_AUTOMODE (must be visible)
    if GetCVar("nameplateShowAll")=="0" then
        SetCVar("nameplateShowAll", 1)
		print("All nameplates should be visible")
    end
    if GetCVar("nameplateShowEnemies")~="1" then
        SetCVar("nameplateShowEnemies", 1) 
        print("Enemy nameplates should be enabled")
    end
end

local function TrueScaleInit()
    TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(_, frame)
            local str_group = tostring(frame)        
            if strfind(str_group, "TellMeWhen_Group2") then                
                UpdateFrames()  
            end
    end)
    UpdateFrames()
    TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TEMP_TMW_SAFESETUP_COMPLETE")
end

TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", TrueScaleInit, "TEMP_TMW_SAFESETUP_COMPLETE")    


local function ConsoleUpdate()
    UpdateFrames()
    UpdateCVAR()  
end 

Listener:Add("Console_Events", "DISPLAY_SIZE_CHANGED", ConsoleUpdate)
Listener:Add("Console_Events", "UI_SCALE_CHANGED", ConsoleUpdate)
Listener:Add("Console_Events", "PLAYER_ENTERING_WORLD", ConsoleUpdate)
VideoOptionsFrame:HookScript("OnHide", ConsoleUpdate)
InterfaceOptionsFrame:HookScript("OnHide", UpdateCVAR)

function Env.BlackBackgroundSet(bool)
    BlackBackground.IsEnable = bool 
    BlackBackground:SetShown(bool)
end

-- TODO: Remove in profiles until June 2019
function Env.chat()
    return ACTIVE_CHAT_EDIT_BOX or (BindPadFrame and BindPadFrame:IsVisible())
end