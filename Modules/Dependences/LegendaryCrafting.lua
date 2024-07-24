------------------------------------------------------------------------------------------------
-- LegendaryCrafting is special written lib to provide API for equipped legendary crafted items
-- This library does nothing if not exist required API and all returns will be unvalid
------------------------------------------------------------------------------------------------
local _G, ipairs, next					= _G, ipairs, next

local wipe 								= _G.wipe 

local TMW 								= _G.TMW 

local A 								= _G.Action 
local CONST								= A.Const
local Listener							= A.Listener

local Lib 								= _G.LibStub:NewLibrary("LegendaryCrafting", 1)

if not Lib then 
	if A.BuildToC >= 90001 then 
		A.Print("[Error] LegendaryCrafting - Library wasn't initialized")
	end 
	return 
end 

-------------------------------------------------------------------------------
-- Locals
-------------------------------------------------------------------------------
local Item								= _G.Item
local C_LegendaryCrafting				= _G.C_LegendaryCrafting

local IsRuneforgeLegendary, GetRuneforgeLegendaryComponentInfo, GetRuneforgePowerInfo
if C_LegendaryCrafting then 
	IsRuneforgeLegendary 				= C_LegendaryCrafting.IsRuneforgeLegendary
	GetRuneforgeLegendaryComponentInfo 	= C_LegendaryCrafting.GetRuneforgeLegendaryComponentInfo
	GetRuneforgePowerInfo			 	= C_LegendaryCrafting.GetRuneforgePowerInfo
end 

-- LegendaryItemData[powerID or "powerName"] methods getting through Lib:GetItem(powerID or "powerName"):
-- :GetCurrentItemLevel()				-- @returns number
-- :GetInventoryType()					-- @returns number (invSlot)
-- :GetInventoryTypeName()				-- @returns string (itemEquipLoc), number (icon), number (itemClassID), number (itemSubClassID)
-- :GetItemGUID()						-- @returns string (this is GUID which can be used on events)
-- :GetItemID()							-- @returns number
-- :GetItemIcon()						-- @returns number 
-- :GetItemLink()						-- @returns string 
-- :GetItemLocation()					-- @returns table { Clear, GetBagAndSlot, GetEquipmentSlot, HasAnyLocation, IsBagAndSlot, IsEqualTo, IsEqualToBagAndSlot, IsEqualToEquipmentSlot, IsEqualToSlot, IsValid, SetBagAndSlot, SetEquipmentSlot, equipmentSlotIndex }
-- :GetItemName()						-- @returns string (only after initialized loaded data from server, can be nil at first time call after login)
-- :GetItemQuality()					-- @returns number 
-- :GetItemQualityColor()				-- @returns table { r = number, g = number, b = number, hex = string, color = table { GenerateHexColor, GenerateHexColorMarkup, GetRGB, GetRGBA, GetRGBAAsBytes, GetRGBAsBytes, IsEqualTo, OnLoad, SetRGB, SetRGBA, WrapTextInColorCode } }
-- :GetStaticBackingItem()				-- @returns itemLink or itemID or nil 
-- :HasItemLocation()					-- @returns boolean
-- :IsDataEvictable()					-- @returns boolean 
-- :IsItemDataCached()					-- @returns boolean 
-- :IsItemEmpty()						-- @returns boolean 
-- :IsItemInPlayersControl()			-- @returns boolean 
-- :IsItemLocked()						-- @returns boolean 
-- :Clear()								-- control func 
-- :LockItem()							-- control func 
-- :UnlockItem()						-- control func
-- :SetItemID()							-- control func 
-- :SetItemID()							-- control func 
-- :SetItemLink()						-- control func 
-- :SetItemLocation()					-- control func 
-- .itemLocation						-- table, pointer to :GetItemLocation() method 
-- :ContinueOnItemLoad()				-- internal system func 
-- :ContinueWithCancelOnItemLoad()		-- internal system func 

local LegendaryItemSlots
local LegendaryItemData = {}
local function UpdateLegendaryEquipment()		
	if not LegendaryItemSlots then 
		LegendaryItemSlots = {}
		Lib.LegendaryItemSlots = LegendaryItemSlots
		for i = 1, CONST.INVSLOT_LAST_EQUIPPED do 
			LegendaryItemSlots[i] = Item:CreateFromEquipmentSlot(i)						
		end 
	end 
	
	wipe(LegendaryItemData)
	local itemLoc, itemComponentInfo, itemPowerInfo
	for itemSlot, item in ipairs(LegendaryItemSlots) do 
		if not item:IsItemEmpty() then
			itemLoc = item:GetItemLocation()
			
			if IsRuneforgeLegendary(itemLoc) then 
				itemComponentInfo = GetRuneforgeLegendaryComponentInfo(itemLoc)
				-- Returns:
				-- .modifiers 		- array like @table with values of modifierIDs
				-- .powerID			- @number 
				itemPowerInfo	  = GetRuneforgePowerInfo(itemComponentInfo.powerID)
				-- Returns:
				-- .name 			- @string   
				-- .description 	- @string (nil-able at first time login)  
				-- .iconFileID		- @number 
				
				LegendaryItemData[itemComponentInfo.powerID] = item
				LegendaryItemData[itemPowerInfo.name] = item
				LegendaryItemData[item:GetItemID()] = item
				--LegendaryItemData[item:GetItemName()] = item -- requires item data to be loaded, so we will not use it 
			end 
		end 
	end 
end 

if C_LegendaryCrafting then 
	Listener:Add("ACTION_EVENT_LEGENDARY_CRAFTING", "PLAYER_EQUIPMENT_CHANGED", 				UpdateLegendaryEquipment)	
	TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 							UpdateLegendaryEquipment)
	--Listener:Add("ACTION_EVENT_LEGENDARY_CRAFTING", "RUNEFORGE_LEGENDARY_CRAFTING_CLOSED", 	UpdateLegendaryEquipment) -- If item is equipped but was changed through rune crafter. Tests showed what this event is no need since "PLAYER_EQUIPMENT_CHANGED" event will be fired when item crafted
	--TMW:RegisterSelfDestructingCallback("TMW_ACTION_ENTERING", 								UpdateLegendaryEquipment) -- Should fine since "TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED" will be fired first time after login. MUST HAVE RETURN TRUE TO DESTROY CALLBACK!
end 

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
Lib.LegendaryItemData = LegendaryItemData

function Lib:IsLoaded()
	-- @return boolean 
	return C_LegendaryCrafting and true 
end

function Lib:GetItem(powerOrItemID)
	-- @return table or nil 
	if powerOrItemID == nil then 
		local _, item = next(LegendaryItemData)
		return item 
	else 
		return LegendaryItemData[powerOrItemID]
	end 
end

function Lib:IsEquipped(itemID)
	-- @return boolean 
	if itemID == nil then 
		return next(LegendaryItemData) and true 
	else 
		return self:GetItem(itemID) and true
	end 
end

function Lib:HasPower(power)
	-- @return boolean 
	if power == nil then 
		return next(LegendaryItemData) and true 
	else 
		return self:GetItem(power) and true
	end 
end