---
--- 07.06.2019
---
if not TMW then return end 
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

local function UpdateFrames()
    if not TellMeWhen_Group1 or (not strfind(TellMeWhen_Group1.Name, '[GGL]') and not strfind(TellMeWhen_Group1.Name, 'Main')) then 
        if BlackBackground:IsShown() then
            BlackBackground:Hide()
        end        
        if TargetColor and TargetColor:IsShown() then
            TargetColor:Hide()
        end        
        return 
    end
    local myhight = tonumber(string.match(GetCVar("gxWindowedResolution"), "%d+x(%d+)"))
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
        TellMeWhen_Group2:SetFrameLevel(1)
    end   
    if TargetColor then
        if not TargetColor:IsShown() then
            TargetColor:Show()
        end
        TargetColor:SetScale((0.71111112833023 * (1080 / myhight)) / (TargetColor:GetParent() and TargetColor:GetParent():GetEffectiveScale() or 1))
    end              
end

local function UpdateCVAR()
    if GetCVar("Contrast")~="50" then SetCVar("Contrast", 50) end;
    if GetCVar("Brightness")~="50" then SetCVar("Brightness", 50) end;
    if GetCVar("Gamma")~="1.000000" then SetCVar("Gamma", "1.000000") end;
    if GetCVar("colorblindsimulator")~="0" then SetCVar("colorblindsimulator", 0) end; 
    -- Not neccessary
    if GetCVar("RenderScale")~="1" then SetCVar("RenderScale", 1) end; 
    if GetCVar("MSAAQuality")~="0" then SetCVar("MSAAQuality", 0) end;
    -- Could effect bugs if > 0 but FXAA should work
    if tonumber(GetCVar("ffxAntiAliasingMode")) > 2 then SetCVar("ffxAntiAliasingMode", 0) end; 
    if GetCVar("doNotFlashLowHealthWarning")~="1" then SetCVar("doNotFlashLowHealthWarning", 1) end; 
    -- WM removal
    if GetCVar("screenshotQuality")~="10" then SetCVar("screenshotQuality", 10) end;    
    -- TODO: Delete after new HPaly and RDruid release
    if Env.IamHealer and Env.UNITSpec("player", {65, 105}) and GetCVar("nameplateShowAll")=="0" then
        SetCVar("nameplateShowAll", 1)
    end
    if GetCVar("nameplateShowEnemies")~="1" then
        SetCVar("nameplateShowEnemies", 1) 
        print("Nameplates should be enabled for units check")
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


function Env.BlackBackgroundSet(bool)
    BlackBackground.IsEnable = bool 
    BlackBackground:SetShown(bool)
end

-- TODO: Remove in profiles until June 2019 and then replace in Action
function Env.chat()
    return ACTIVE_CHAT_EDIT_BOX or (BindPadFrame and BindPadFrame:IsVisible())
end

local function ConsoleUpdate()
    UpdateFrames()
    UpdateCVAR()  
end 

Listener:Add('Console_Events', "DISPLAY_SIZE_CHANGED", ConsoleUpdate)
Listener:Add('Console_Events', "UI_SCALE_CHANGED", ConsoleUpdate)
Listener:Add('Console_Events', "PLAYER_ENTERING_WORLD", ConsoleUpdate)
Listener:Add('Console_Events', 'CONSOLE_MESSAGE', function(...)  
        local arg1 = ...
        if strfind(arg1, "FFX: Color correction enabled") then 
            UpdateCVAR() 
        end
end)

