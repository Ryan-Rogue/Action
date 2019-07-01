local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local next, pairs = 
	  next, pairs
	  
local IsEquippedItem = 
	  IsEquippedItem

Env.TierGear = { 
	IsInitialized = false,
	CheckItems = {},	
	CountItems = {},
} 

function Env.TierGear.Update()	
	for tier_name, items in pairs(Env.TierGear.CheckItems) do 
		local count = 0
		for i = 1, #items do 
			if IsEquippedItem(items[i]) then 
				count = count + 1
			end 
		end 
		Env.TierGear.CountItems[tier_name] = count
	end 
end 

function Env.TierGear:GetCount(tier)
	return self.CountItems[tier] or 0
end

function Env.TierGear:Remove(tier)
	self.CheckItems[tier] = nil 
	self.CountItems[tier] = nil
	if not next(self.CheckItems) then 
		self.IsInitialized = false 
		Listener:Remove("TierGear_Events", "PLAYER_ENTERING_WORLD")
		Listener:Remove("TierGear_Events", "PLAYER_EQUIPMENT_CHANGED")		
	end 
end 

function Env.TierGear:Add(tier, items)
	self.CheckItems[tier] = items 
	self.CountItems[tier] = 0
	if not self.IsInitialized then 
		self.IsInitialized = true 
		Listener:Add("TierGear_Events", "PLAYER_ENTERING_WORLD", Env.TierGear.Update)
		Listener:Add("TierGear_Events", "PLAYER_EQUIPMENT_CHANGED", Env.TierGear.Update)		
	end 
end 


