local Action = Action 

local pairs, ipairs, wipe = pairs, ipairs, wipe
local GetSpellInfo = Action.GetSpellInfo
local ItemSlots = { 1, 2, 3, 5 }

local AzeriteEmpoweredItem = _G.C_AzeriteEmpoweredItem
local AzeriteTraits = {}

local AzeriteEssence = _G.C_AzeriteEssence
local AzeriteEssences = { Total = {} }

if AzeriteEssence then 
	AzeriteEssences.IsPassive = {
		-- Checking by spellID which converts to spellName (it's more stable than ID because ID can be changed by Rank and Spec)
		-- Vision of Perfection
		[Spell:CreateFromSpellID(299368):GetSpellName()] = true, 
		-- Conflict and Strife
		[Spell:CreateFromSpellID(304017):GetSpellName()] = true, 
	}
end 

function AzeriteEssences.GetInfo(milestone) 
	local spellID = AzeriteEssence.GetMilestoneSpell(milestone.ID)
	local essenceID = AzeriteEssence.GetMilestoneEssence(milestone.ID) 
	if essenceID then 
		local info = AzeriteEssence.GetEssenceInfo(essenceID)
		local temp = {
			spellID = spellID,
			spellName = GetSpellInfo(spellID),
			essenceID = essenceID,
			milestoneID = milestone.ID,
			requiredLevel = milestone.requiredLevel,
			slot = milestone.slot, 							-- selected position in AzeriteEssenceUI
			canUnlock = milestone.canUnlock,
			ID = info.ID, 									-- ID of what? (number)
			Name = info.name, 								-- Name of essence (not a spell) 
			Rank = info.rank, 
			Unlocked = info.unlocked, 						-- or milestone.unlocked?
			Valid = info.valid, 							-- what is it? (boolean)
			Icon = info.icon,
		}
		return temp 
	end 
end 

function AzeriteEssences.Update() 
	local self = AzeriteEssences 
	self.Major = nil
	self.MinorOne = nil 
	self.MinorTwo = nil
	wipe(self.Total)
	
	if AzeriteEssence and AzeriteEmpoweredItem.IsHeartOfAzerothEquipped() then
		local milestones = AzeriteEssence.GetMilestones()
		for i, milestone in ipairs(milestones) do
			-- Enumerates each milestone with output table 'milestone' with keys: ID, requiredLevel, canUnlock, unlocked, slot
			if milestone.slot == Enum.AzeriteEssence.MainSlot then
				self.Major = self.GetInfo(milestone)
				if self.Major then 
					self.Total[self.Major.spellName] = self.Major 
				end 
			elseif milestone.slot == Enum.AzeriteEssence.PassiveOneSlot then 
				self.MinorOne = self.GetInfo(milestone)
				if self.MinorOne then 
					self.Total[self.MinorOne.spellName] = self.MinorOne 
				end 
			elseif milestone.slot == Enum.AzeriteEssence.PassiveTwoSlot then 
				self.MinorTwo = self.GetInfo(milestone)
				if self.MinorTwo then 
					self.Total[self.MinorTwo.spellName] = self.MinorTwo 
				end
			end
		end 
	end 
end 

local function AzeriteTraitsUpdate()  	
	local AzeriteItems = {}      	
	for i = 1, #ItemSlots do
		AzeriteItems[ItemSlots[i]] = Item:CreateFromEquipmentSlot(ItemSlots[i])
	end
	wipe(AzeriteTraits)            
	for slot, item in pairs(AzeriteItems) do
		if not item:IsItemEmpty() then
			local itemLoc = item:GetItemLocation()
			-- Azerite Empower
			if slot ~= 2 and AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then
				local tierInfos = AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
				for _, tierInfo in pairs(tierInfos) do
					for _, powerId in pairs(tierInfo.azeritePowerIDs) do
						if AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerId) then
							local spellIDAzerite = GetSpellInfo(C_AzeriteEmpoweredItem.GetPowerInfo(powerId).spellID)
							if not AzeriteTraits[spellIDAzerite] then
								AzeriteTraits[spellIDAzerite] = 1
							else
								AzeriteTraits[spellIDAzerite] = AzeriteTraits[spellIDAzerite] + 1
							end                                    
						end
					end
				end
			end
			-- Azerite Essence
			if slot == 2 then 
				AzeriteEssences.Update() 
			end 
		end
	end       
end

-- Azerite Empower
Listener:Add("AzeriteTraits_Events", "PLAYER_ENTERING_WORLD", AzeriteTraitsUpdate)
Listener:Add("AzeriteTraits_Events", "PLAYER_EQUIPMENT_CHANGED", AzeriteTraitsUpdate)
Listener:Add("AzeriteTraits_Events", "SPELLS_CHANGED", AzeriteTraitsUpdate)


-- Azerite Empower / Azerite Essence
function AzeriteRank(spellID)
	local spellName = GetSpellInfo(spellID)
    local rank = AzeriteTraits[spellName] or (AzeriteEssences.Total[spellName] and AzeriteEssences.Total[spellName].Rank)
    return rank and rank or 0
end

-- Azerite Essence
if AzeriteEssence then	
	Listener:Add("AzeriteTraits_Events", "AZERITE_ESSENCE_CHANGED", AzeriteEssences.Update)
	Listener:Add("AzeriteTraits_Events", "AZERITE_ESSENCE_UPDATE", AzeriteEssences.Update) 
	Listener:Add("AzeriteTraits_Events", "AZERITE_ESSENCE_ACTIVATED", AzeriteEssences.Update)
	Listener:Add("AzeriteTraits_Events", "AZERITE_ESSENCE_ACTIVATION_FAILED", AzeriteEssences.Update)
end 

function AzeriteEssenceGet(spellID)
	-- @return table with all available information
	return AzeriteEssences.Total[GetSpellInfo(spellID)]
end 

function AzeriteEssenceGetMajor()
	-- @return table with all available information or nil 
	return AzeriteEssences.Major
end 

function AzeriteEssenceHasMajor(spellID)
	-- @return boolean 
	if AzeriteEssences.Major then 
		if AzeriteEssences.Major.spellID == spellID then 
			return true 
		else 
			local spellName = GetSpellInfo(spellID)
			if AzeriteEssences.Major.spellName == spellName then 
				return true 
			end 
		end 
	end 
	return false 
end 

function AzeriteEssenceIsMajorUseable() 
	-- @return boolean 
	if AzeriteEssences.Major and AzeriteEssences.Major.spellID then 
		return not AzeriteEssences.IsPassive[AzeriteEssences.Major.spellName] and not AzeriteEssences.IsPassive[AzeriteEssences.Major.Name]
	end 
	return false 
end 

function AzeriteEssenceHasMinor(spellID)
	-- @return boolean 
	if (AzeriteEssences.MinorOne and AzeriteEssences.MinorOne.spellID == spellID) or (AzeriteEssences.MinorTwo and AzeriteEssences.MinorTwo.spellID == spellID) then 
		return true 
	else 
		local spellName = GetSpellInfo(spellID)
		if (AzeriteEssences.MinorOne and AzeriteEssences.MinorOne.spellName == spellName) or (AzeriteEssences.MinorTwo and AzeriteEssences.MinorTwo.spellName == spellName) then 
			return true 
		end 
	end 
	return false 
end 