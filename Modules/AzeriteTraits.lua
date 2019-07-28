local Action = Action 

local pairs, ipairs, wipe = pairs, ipairs, wipe
local GetSpellInfo = Action.GetSpellInfo
local ItemSlots = { 1, 2, 3, 5 }

local AzeriteEmpoweredItem = _G.C_AzeriteEmpoweredItem
local AzeriteTraits = {}

local AzeriteEssence = _G.C_AzeriteEssence
local AzeriteEssences = { Total = {} }
local FindSpellOverrideByID = FindSpellOverrideByID

if AzeriteEssence then 
	AzeriteEssences.IsPassive = {
		-- Checking by spellID which converts to spellName (it's more stable than ID because ID can be changed by Rank and Spec)
		-- Vision of Perfection
		[Spell:CreateFromSpellID(299368):GetSpellName()] = true, 
		-- Conflict and Strife
		[Spell:CreateFromSpellID(304017):GetSpellName()] = true, 
	}
	AzeriteEssences.IsTalentPvP = {
		-- Death Knight: Unholy Command (Blood)
		[202727] = true,
		-- Death Knight: Chill Streak (Frost)
		[204160] = true,
		-- Death Knight: Necrotic Strike (Unholy)
		[223829] = true,
		-- Demon Hunter: Demonic Origins (Vengance)
		[235893] = true,
		-- Demon Hunter: Cleansed by Flame (Havoc)
		[205625] = true,
		-- Druid: Thorns (Balance / Feral)
		[236696] = true,
		-- Druid: Sharpened Claws (Guardian)
		[202110] = true,
		-- Druid: Overgrowth (Restoration)
		[203651] = true,
		-- Hunter: Hi-Explosive Trap (Beast Mastery / Marksmanship / Survival)
		[236776] = true,
		-- Mage: Temporal Shield (Arcane / Frost / Fire)
		[198111] = true,
		-- Monk: Hot Trub (Brewmaster)
		[202126] = true,
		-- Monk: Way of the Crane (Mistweaver)
		[216113] = true,
		-- Monk: Reverse Harm (Windwalker)
		[287771] = true,
		-- Paladin: Divine Favor (Holy)
		[210294] = true,
		-- Paladin: Steed of Glory (Protection)
		[199542] = true,
		-- Paladin: Unbound Freedom (Retribution)
		[199325] = true,
		-- Priest: Premonition (Discipline)
		[209780] = true,
		-- Priest: Holy Ward (Holy)
		[213610] = true,
		-- Priest: Void Shift (Shadow)
		[108968] = true,
		-- Rogue: Maneuverability (Assassination / Outlaw / Subtlety)
		[197000] = true,
		-- Shaman: Lightning Lasso (Elemental)
		[204437] = true,
		-- Shaman: Thundercharge (Enhancement)
		[204366] = true,
		-- Shaman: Ancestral Gift (Restoration)
		[290254] = true,
		-- Warlock: Endless Affliction (Affliction)
		[305391] = true,
		-- Warlock: Nether Ward (Demonology)
		[212295] = true,
		-- Warlock: Demon Armor (Destruction)
		[285933] = true,
		-- Warrior: Sharpen Blade (Arms)
		[198817] = true,
		-- Warrior: Battle Trance (Fury)
		[213857] = true,
		-- Warrior: Thunderstruck (Protection)
		[199045] = true,		
	}
end 

function AzeriteEssences.GetInfo(milestone) 	
	local essenceID = AzeriteEssence.GetMilestoneEssence(milestone.ID) 	
	if essenceID then 
		local spellInfo = AzeriteEssence.GetMilestoneSpell(milestone.ID)
		local info = AzeriteEssence.GetEssenceInfo(essenceID)
		if info and spellInfo then 
			local spellID = FindSpellOverrideByID(spellInfo)    
			local temp = {
				spellID = spellID,
				spellName = Action.GetSpellInfo(spellID),
				essenceID = essenceID,							-- same info.ID
				milestoneID = milestone.ID,
				requiredLevel = milestone.requiredLevel,
				slot = milestone.slot, 							-- selected position in AzeriteEssenceUI
				--canUnlock = milestone.canUnlock,				-- bullshit
				Name = info.name, 								-- Name of Essence (not a spell) 
				Rank = info.rank, 
				Unlocked = info.unlocked, 						-- or milestone.unlocked?
				Valid = info.valid, 							-- what is it? (boolean)
				Icon = info.icon,
			}
			return temp 
		end 
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
		return not AzeriteEssences.IsPassive[AzeriteEssences.Major.spellName] 
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

function AzeriteEssenceConflictandStrife(spellID)
	-- @return boolean 
	-- Note: Using in Env.PvPTalentLearn to return properly learned PvP talent if it's not selected in TalentUI
	if AzeriteEssenceHasMajor(304017) then 
		return AzeriteEssences.IsTalentPvP[spellID]
	end 
	return false 
end 