-------------------------------------------------------------------------------------
-- Toaster as built-in embeds with own stand alone category and db
-------------------------------------------------------------------------------------
-- All API should be used through Action.Toaster instead of _G.Toaster (!) 
-- All API are located in the LibToast and Toaster, spawn is access able like LibToast:Spawn("ToasterPreview", "very_low")
local ADDON_NAME, private					= ...
local _G, unpack, type, pairs, error, next	= _G, unpack, type, pairs, error, next
local tremove								= table.remove
local wipe									= _G.wipe
local hooksecurefunc						= _G.hooksecurefunc
local CopyTable								= _G.CopyTable
local Toaster								= _G.Toaster
local LibStub								= _G.LibStub
local AceDB 								= LibStub("AceDB-3.0", true)
local AceConfigRegistry 					= LibStub("AceConfigRegistry-3.0", true)	
local AceConfigDialog 						= LibStub("AceConfigDialog-3.0", true)	
local LibWindow 							= LibStub("LibWindow-1.1", true)

if Toaster and AceDB and AceConfigRegistry and AceConfigDialog and LibWindow then 
	local TOASTER_NAME 						= "The Action Toaster"
	local A 								= _G.Action
	local Listener							= A.Listener
			
	-- SavedVariables db object
	local wrongName							= ADDON_NAME .. "Settings"
	local AceDBNew_Original 				= AceDB.New 
	function AceDB:New(...)		
		local dbName = ...
		if dbName == wrongName then 
			local vararg = { ... }
			vararg[1] = "ToasterSavedVariables"
			local db = AceDBNew_Original(self, unpack(vararg)) -- traversed into private.db			
			if not db.global.addons[ADDON_NAME] then
				db.global.addons[ADDON_NAME] = CopyTable(private.DATABASE_DEFAULTS.global.addons["*"])				
			end 
			db.global.addons[ADDON_NAME].known = false  
			private.AddOnObjects[ADDON_NAME] = { name = ADDON_NAME }
			return db 
		elseif dbName == "ToasterSettings" and private.db then 
			-- Unregister The Action Toaster db and use original Toaster db
			-- In the Toaster private.db never changes only used as pointer to other tables inside which will be reallocated
			local db = AceDBNew_Original(self, ...)
			for k, v in pairs(db) do 
				private.db[k] = v
			end 
			
			if db.global.addons[ADDON_NAME] then 
				db.global.addons[ADDON_NAME].known = true 
			end 
			private.AddOnObjects[ADDON_NAME] = nil 
			
			return db 
		else 
			return AceDBNew_Original(self, ...)
		end 
	end 
	
	-- Interface Options Panel
	local function resetTableFromTable(t1, t2)
		if not t1 then 
			t1 = {}
		end 
		
		if type(t2) == "table" then 
			for k, v in pairs(t2) do 
				if type(v) == "table" then 
					resetTableFromTable(t1[k], v)
				else 
					t1[k] = v 
				end 
			end 
		end 
		
		if type(t1) == "table" then 
			for k, v in pairs(t1) do 
				if type(v) == "table" and type(t2[k]) == "table" then 
					resetTableFromTable(v, t2[k])
				elseif t2[k] == nil then 
					t1[k] = nil 
				end 
			end 
		end 
	end 	
	hooksecurefunc(AceConfigRegistry, "RegisterOptionsTable", function(...)		
		local _, argName, argOptions = ...
		
		-- The Action Toaster
		if argName == ADDON_NAME and type(argOptions) == "function" then 
			-- That will return by function the options table which is static in the Toaster\Config.lua 
			-- This code is private which means what global Toaster's instance will not be affected by this 
			local anchorFrame
			local storage = private.db.global.display.anchor
			for windowFrame, windowObject in pairs(LibWindow.windowData) do 
				if windowObject.storage == storage then 
					anchorFrame = windowFrame
					break 
				end 
			end 
			
			local options = argOptions()
			options.name = TOASTER_NAME					
			
			-- Remove first tab since its built-in embeds
			options.args.addOnsOptions = nil 
			
			-- Modify remain tab 
			local defaultOptions = options.args.defaultOptions
			defaultOptions.args.minimap_icon = nil
			defaultOptions.args.reset.func = function()
				-- This is fix for original code 
				resetTableFromTable(private.db.global.display.anchor, private.DATABASE_DEFAULTS.global.display.anchor)
                LibWindow.RestorePosition(anchorFrame)
			end	

			-- Reallocate to Action.Toaster 
			Toaster.options = options
			Toaster.anchorFrame = anchorFrame
			Toaster.storage = storage
		end 
		
		-- Toaster (original, stand alone)
		if argName == "Toaster" and _G.Toaster ~= Toaster and _G.Toaster.name == "Toaster" and type(argOptions) == "function" then 		
			local anchorFrame, storage			
			
			local function GetAnchorFrameAndStorage()
				if not anchorFrame and _G.ToasterSettings then 
					storage = _G.ToasterSettings.global.display.anchor
					for windowFrame, windowObject in pairs(LibWindow.windowData) do 
						if windowObject.storage == storage then 
							anchorFrame = windowFrame
							Toaster.anchorFrame = anchorFrame
							Toaster.storage = storage
							break 
						end 
					end 				
				end 

				return anchorFrame, storage
			end 
			
			local options = argOptions()
			options.args.defaultOptions.args.reset.func = function()
				-- This is fix for original code 
				resetTableFromTable(_G.ToasterSettings.global.display.anchor, private.DATABASE_DEFAULTS.global.display.anchor)
				
				GetAnchorFrameAndStorage()
				
				if anchorFrame then 
					LibWindow.RestorePosition(anchorFrame)
				end 
			end	
			
			-- Unregister The Action Toaster - Interface Options Panel and use original Toaster panel
			LibWindow.windowData[Toaster.anchorFrame] = nil 
			AceConfigRegistry.tables[ADDON_NAME] = nil			
			AceConfigRegistry.tables[ADDON_NAME .. ":Color"] = nil 
			AceConfigRegistry.tables[TOASTER_NAME] = nil
			AceConfigRegistry.tables[TOASTER_NAME .. ":Color"] = nil 
			
			AceConfigDialog.BlizOptions[ADDON_NAME] = nil 
			AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"] = nil 
			AceConfigDialog.BlizOptions[TOASTER_NAME] = nil 
			AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"] = nil 
			
			local categories = INTERFACEOPTIONS_ADDONCATEGORIES
			local i, data = next(categories)
			while i ~= nil do 
				if data.name == TOASTER_NAME or data.parent == TOASTER_NAME then 
					tremove(categories, i)
				end 			
				i, data = next(categories, i)
			end 
						
			Toaster.options = options
			Toaster.anchorFrame, Toaster.storage = GetAnchorFrameAndStorage() 			
		end 			
	end)
	
	-- OnInitialize
	hooksecurefunc(Toaster, "OnInitialize", function(self)
		if self.name ~= ADDON_NAME then 
			error("Toaster.lua failed in hook on 'Toaster:OnInitialize'. Object doesn't match addon's own object") 
			return
		end 
		
		-- Reallocates Toaster into Action 
		Toaster							= self 
		A.Toaster 						= Toaster 		
		
		-- Creates function to open options panel
		local optionsFrame 				= _G.InterfaceOptionsFrame
		local openToCategory 			= _G.InterfaceOptionsFrame_OpenToCategory
		function Toaster:Toggle() 		
			if optionsFrame:IsVisible() then
				optionsFrame:Hide()
			else
				openToCategory(self.OptionsFrame)
			end
		end 		
		
		-- Turns off minimap
		local LibDBIcon = LibStub("LibDBIcon-1.0")
		private.db.global.general.minimap_icon.hide = true
		if LibDBIcon.objects[ADDON_NAME] then 
			LibDBIcon:Hide(ADDON_NAME)
			wipe(LibDBIcon.objects[ADDON_NAME])
			LibDBIcon.objects[ADDON_NAME] = nil 
		end 
		
		-- Turns off slash command
		Toaster:UnregisterChatCommand("toaster")

		-- Reallocates names so it will keep available running more than one Toaster's instances
		AceConfigRegistry.tables[TOASTER_NAME] = AceConfigRegistry.tables[ADDON_NAME]; AceConfigRegistry.tables[ADDON_NAME] = nil 
		AceConfigRegistry.tables[TOASTER_NAME .. ":Color"] = AceConfigRegistry.tables[ADDON_NAME .. ":Color"]; AceConfigRegistry.tables[ADDON_NAME .. ":Color"] = nil 
		Toaster.name 			= TOASTER_NAME
		Toaster.baseName		= TOASTER_NAME
	
		Toaster.ColorOptions.parent = TOASTER_NAME
		Toaster.ColorOptions.obj.frame.parent = TOASTER_NAME
		Toaster.ColorOptions.obj.userdata.appName = TOASTER_NAME .. ":Color"
		
		Toaster.OptionsFrame.name = TOASTER_NAME		
		Toaster.OptionsFrame.obj.frame.name = TOASTER_NAME
		Toaster.OptionsFrame.obj.label:SetText(TOASTER_NAME)
		Toaster.OptionsFrame.obj:SetName(TOASTER_NAME)
		Toaster.OptionsFrame.obj:SetTitle(TOASTER_NAME)
		Toaster.OptionsFrame.obj.userdata.appName = TOASTER_NAME
				
		AceConfigDialog.BlizOptions[TOASTER_NAME] = AceConfigDialog.BlizOptions[ADDON_NAME]
		AceConfigDialog.BlizOptions[TOASTER_NAME][TOASTER_NAME] = AceConfigDialog.BlizOptions[TOASTER_NAME][ADDON_NAME]
		AceConfigDialog.BlizOptions[ADDON_NAME] = nil
		AceConfigDialog.BlizOptions[TOASTER_NAME][ADDON_NAME] = nil 
		
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"] = AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][TOASTER_NAME .. ":Color"] = AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"] = nil 
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][ADDON_NAME .. ":Color"] = nil 
		
		-- Register Action addon to be visible if running stand alone Toaster 
		Listener:Add("ACTION_EVENT_TOASTER", "ADDON_LOADED", function(addonName)			
			if addonName == "Toaster" and _G.Toaster ~= Toaster and _G.Toaster.name == "Toaster" then 	
				-- This thing doesn't hide anything but interracts with private.db of its _G.Toaster to register as an addon in the first tab
				_G.Toaster:HideToastsFromSource(ADDON_NAME)		
				Toaster.OptionsFrame = _G.Toaster.OptionsFrame
				Toaster.ColorOptions = _G.Toaster.ColorOptions				
				Listener:Remove("ACTION_EVENT_TOASTER", "ADDON_LOADED")				
			end 
		end)
	end)
end 

