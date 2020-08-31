-------------------------------------------------------------------------------------
-- Toaster SavedVariables fix 
-------------------------------------------------------------------------------------
local ADDON_NAME, private	= ...
local _G, unpack 			= _G, unpack 
local hooksecurefunc		= _G.hooksecurefunc
local Toaster				= _G.Toaster
local LibStub				= _G.LibStub
local AceDB 				= LibStub("AceDB-3.0", true)

if Toaster and AceDB then 
	local A 				= _G.Action
	
	-- Reallocate Toaster into Action 
	A.Toaster 				= Toaster 
	
	-- Reassign DB object in the SavedVariables
	local wrongName	= ADDON_NAME .. "Settings"
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
	
	hooksecurefunc(Toaster, "OnInitialize", function()
		-- Turns off minimap
		local LibDBIcon = LibStub("LibDBIcon-1.0")
		private.db.global.general.minimap_icon.hide = true
		if LibDBIcon.objects[ADDON_NAME] then 
			LibDBIcon:Hide(ADDON_NAME)
			LibDBIcon.objects[ADDON_NAME] = nil 
		end 
		
		-- Turns off slash commands
		Toaster:UnregisterChatCommand("toaster")
		
		-- Creates function to open options panel of the Toaster 
		local optionsFrame = _G.InterfaceOptionsFrame
		local openToCategory = _G.InterfaceOptionsFrame_OpenToCategory
		function Toaster:Toggle() 		
			if optionsFrame:IsVisible() then
				optionsFrame:Hide()
			else
				openToCategory(self.OptionsFrame)
			end
		end 

		-- Change names for its frames
		local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")		
		AceConfigRegistry.tables["Toaster"] = AceConfigRegistry.tables[ADDON_NAME]; AceConfigRegistry.tables[ADDON_NAME] = nil 
		AceConfigRegistry.tables["Toaster:Color"] = AceConfigRegistry.tables[ADDON_NAME .. ":Color"]; AceConfigRegistry.tables[ADDON_NAME .. ":Color"] = nil 
		Toaster.name 			= "Toaster"
		Toaster.baseName		= "Toaster"
	
		Toaster.ColorOptions.parent = "Toaster"
		Toaster.ColorOptions.obj.frame.parent = "Toaster"
		Toaster.ColorOptions.obj.userdata.appName = "Toaster:Color"
		
		Toaster.OptionsFrame.name = "Toaster"		
		Toaster.OptionsFrame.obj.frame.name = "Toaster"
		--[[Toaster.OptionsFrame.obj.label:SetText("Toaster")
		Toaster.OptionsFrame.obj:SetName("Toaster")
		Toaster.OptionsFrame.obj:SetTitle("Toaster")
		Toaster.OptionsFrame:HookScript("OnShow", function(self)
			self.obj.label:SetText("Toaster")
		end)]]
		Toaster.OptionsFrame.obj.userdata.appName = "Toaster"
		
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		AceConfigDialog.BlizOptions["Toaster"] = AceConfigDialog.BlizOptions[ADDON_NAME]
		AceConfigDialog.BlizOptions["Toaster"]["Toaster"] = AceConfigDialog.BlizOptions["Toaster"][ADDON_NAME]
		AceConfigDialog.BlizOptions[ADDON_NAME] = nil
		AceConfigDialog.BlizOptions["Toaster"][ADDON_NAME] = nil 
		
		AceConfigDialog.BlizOptions["Toaster:Color"] = AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions["Toaster:Color"]["Toaster:Color"] = AceConfigDialog.BlizOptions["Toaster:Color"][ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"] = nil 
		AceConfigDialog.BlizOptions["Toaster:Color"][ADDON_NAME .. ":Color"] = nil 
	end)
end 

