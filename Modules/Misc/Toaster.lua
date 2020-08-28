-------------------------------------------------------------------------------------
-- Toaster SavedVariables fix 
-------------------------------------------------------------------------------------
local _G, unpack 			= _G, unpack 
local Toaster				= _G.Toaster
local AceDB 				= _G.LibStub("AceDB-3.0", true)

if Toaster and AceDB then 
	local A 				= _G.Action
	local CONST				= A.Const		
	local wrongName			= CONST.ADDON_NAME .. "Settings"

	local AceDBNew_Original = AceDB.New 
	function AceDB:New(...)
		local dbName = ...
		if dbName == wrongName then 
			local vararg = { ... }
			vararg[1] = "ToasterSettings"
			return AceDBNew_Original(self, unpack(vararg))
		else 
			return AceDBNew_Original(self, ...)
		end 
	end 
end 

