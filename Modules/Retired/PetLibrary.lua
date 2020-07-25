-------------------------------------------------------------------------------
-- API - Retired 
-------------------------------------------------------------------------------
local Lib = LibStub("PetLibrary")
local setmetatable, rawget = setmetatable, rawget
do 
	-- ATTENTION: 
	-- Don't use these methods, they are old and will be removed in the future!
	-- TODO: Remove with Retired files Retail
	function Lib:Add(owner, spells)
		self:AddActionsSpells(owner, spells, true)
	end 

	function Lib:Remove(owner, spells)
		self:RemoveActionsSpells(owner, spells)
	end 

	function Lib:GetSlotHolder(spell)
		-- @return number (slot, 0 if not found)
		return self:GetActionButton(spell) or 0
	end 

	function Lib:GetData(owner)
		-- @return table or nil 
		if self.Data.Actions[owner] then 
			return self.Data.Actions[owner].Spells
		end 
	end 

	function Lib:GetMultiUnitsBySpell(spell, stop)
		-- @return number
		return self:GetInRange(spell, stop)
	end 
	
	setmetatable(Lib, { __index = function(t, v)
		if not v then return end 
		if v == "MainGUID" then 
			return rawget(t, "GUID")
		else 
			return rawget(t, v:lower())
		end 
	end })
	function Lib:GetMainPet()		
		return self 
	end 
	
	function Lib:GetTrackerData()
		-- @return table which holds [petID] = PetData (@table name, duration, count, GUIDs (GUIDs is also @table with [PetGUID] = { updated, start, expiration }))
		return setmetatable({}, { __index = function(t, v)
			if self.Data.Trackers[A[owner]] then 
				t = self.Data.Trackers[A[owner]].PetIDs
				return t
			end 
		end })
	end 
	
	function Lib:GetTrackerGUID()
		-- @return table ([GUID] = petID to navigate in CLEU for PetTrackerData)
		return setmetatable({}, { __index = function(t, v)
			if self.Data.Trackers[A[owner]] then 
				t = self.Data.Trackers[A[owner]].PetGUIDs
				return t
			end 
		end })
	end 
	
	function Lib:InitializeTrackerFor(owner, customConfig)
		self:AddTrackers(owner, customConfig)
	end 
	
	function Lib:UninitializeTrackerFor(owner)
		self:RemoveTrackers(owner)
	end 
end 