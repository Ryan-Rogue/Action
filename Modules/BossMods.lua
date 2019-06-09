---
--- 06.06.2019
---
--- ============================ HEADER ============================
if not TMW then return end 
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local pairs, type = pairs, type
local UnitName = UnitName
--- ============================= CORE ==============================
local function DBM_timer_init()
    DBM_timer_init = true
    if not DBM then
        function Env.DBM_GetTimeRemaining()
            return 0, 0
        end
        
        return
    end
    
    local Timers = {}
    DBM:RegisterCallback("DBM_TimerStart", function(_, id, text, timerRaw)
            -- Older versions of DBM return this value as a string:
            local duration
            if type(timerRaw) == "string" then
                duration = tonumber(timerRaw:match("%d+"))
            else
                duration = timerRaw
            end
            
            Timers[id] = {text = text:lower(), start = TMW.time, duration = duration}          
    end)
    DBM:RegisterCallback("DBM_TimerStop", function(_, id) Timers[id] = nil end)
    
    
    function Env.DBM_GetTimeRemaining(text)        
        for id, t in pairs(Timers) do            
            if t.text:match(text) then
                local expirationTime = t.start + t.duration
                local remaining = (expirationTime) - TMW.time
                if remaining < 0 then remaining = 0 end
                
                return remaining, expirationTime
            end
        end
        
        return 0, 0
    end
end

local function DBM_engaged_init()
    DBM_engaged_init = true
    if not DBM then
        function Env.DBM_IsBossEngaged()
            return false
        end
        
        return
    end
    
    local EngagedBosses = {}
    hooksecurefunc(DBM, "StartCombat", function(DBM, mod, delay, event)
            if event ~= "TIMER_RECOVERY" then
                EngagedBosses[mod] = true            
            end
    end)
    hooksecurefunc(DBM, "EndCombat", function(DBM, mod)
            EngagedBosses[mod] = nil            
    end)
    
    
    function Env.DBM_IsBossEngaged(bossName)
        for mod in pairs(EngagedBosses) do
            
            if mod.localization.general.name:lower():match(bossName) or mod.id:lower():match(bossName) then
                return mod.inCombat and true or false
            end
        end
        
        return false
    end
end

if not Env.DBM_GetTimeRemaining then 
    DBM_timer_init()
end 

if not Env.DBM_IsBossEngaged then
    DBM_engaged_init()
end 

--- ========================== FUNCTIONAL ===========================
-- Note: /dbm pull <5>
-- Note: /dbm timer <10> <Name>
function Env.DBM_PullTimer()
    local name = DBM_CORE_TIMER_PULL:lower()   
    return Env.DBM_GetTimeRemaining(name)
end 

function Env.DBM_GetTimer(name)        
    if not Action.IsInitialized or not Action.GetToggle(1, "DBM") then
        return 0
    end
    
    --local timername = format("%q", name:gsub("([%(%)%%%[%]%-%+%*%.%^%$])", "%%%1"):lower())  
    local timername = name:lower()
    return Env.DBM_GetTimeRemaining(timername)
end 

function Env.DBM_IsEngage()
    if not Action.IsInitialized or not Action.GetToggle(1, "DBM") then
        return 0
    end
    -- Not tested  
    local BossName = UnitName("boss1")
    local name = BossName and format("%q", BossName:gsub("%%", "%%%%"):lower())
    return name and Env.DBM_IsBossEngaged(name) or false
end 