-------------------------------------------------------------------------------------
-- AzeriteTraits is special written lib for The Action but can be used for any others
-- addons if will be replaced "A." and "TMW." API by regular provided from game 
-------------------------------------------------------------------------------------
local TMW 								= TMW 
local A 								= Action 
local Listener							= A.Listener
local Lib 								= LibStub:NewLibrary("AzeriteTraits", 4)

if not Lib or not A or not TMW then 
	if A then 
		A.Print("[Error] AzeriteTraits - Library wasn't initialized")
	else
		print("[Error] AzeriteTraits - wasn't initialized by Action (or TMW) and Library")
	end 
	
	return 
end 

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_HealingEngine, A_HealingEngineMembersALL, A_GetSpellDescription, ActiveUnitPlates

Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "ADDON_LOADED", function(addonName)
	if addonName == ACTION_CONST_ADDON_NAME then 
		A_Unit							= A.Unit
		A_HealingEngine					= A.HealingEngine
		A_HealingEngineMembersALL		= A_HealingEngine.GetMembersAll()
		A_GetSpellDescription			= A.GetSpellDescription
		ActiveUnitPlates				= A.MultiUnits:GetActiveUnitPlates()
		
		Listener:Remove("ACTION_EVENT_AZERITE_TRAITS", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

local _G, pairs, ipairs		 			= 
	  _G, pairs, ipairs	 
	  
local wipe								= _G.wipe	  

local Enum								= _G.Enum
local Item								= _G.Item
local Spell								= _G.Spell	 
local FindSpellOverrideByID 			= _G.FindSpellOverrideByID
local AzeriteEmpoweredItem 				= _G.C_AzeriteEmpoweredItem
local AzeriteEssence 					= _G.C_AzeriteEssence
local GetSpellInfo						= _G.GetSpellInfo

local Data 								= {
	InventorySlots 						= { 1, 2, 3, 5 },
	Ranks 								= {},
	Essences 							= {
		Total 							= {},
		-- Also will be created if relative slot is used:
		-- Major	= {},
		-- MinorOne	= {},
		-- MinorTwo = {},
	},	
} 

local DataInventorySlots				= Data.InventorySlots
local DataRanks							= Data.Ranks
local DataEssences						= Data.Essences

local A_GetSpellInfo
local function GetInfoSpell(spellID)
	if not A_GetSpellInfo then 
		A_GetSpellInfo = A.GetSpellInfo
		return (A_GetSpellInfo and A_GetSpellInfo(spellID)) or GetSpellInfo(spellID)
	else
		return A_GetSpellInfo(spellID)
	end 
end 

local AzeriteEmpoweredItemIsHeartOfAzerothEquipped, AzeriteEmpoweredItemIsAzeriteEmpoweredItem, AzeriteEmpoweredItemGetAllTierInfo, AzeriteEmpoweredItemIsPowerSelected, AzeriteEmpoweredItemGetPowerInfo
if AzeriteEmpoweredItem then 
	AzeriteEmpoweredItemIsHeartOfAzerothEquipped,  AzeriteEmpoweredItemIsAzeriteEmpoweredItem,  AzeriteEmpoweredItemGetAllTierInfo,  AzeriteEmpoweredItemIsPowerSelected,  AzeriteEmpoweredItemGetPowerInfo = 
	AzeriteEmpoweredItem.IsHeartOfAzerothEquipped, AzeriteEmpoweredItem.IsAzeriteEmpoweredItem, AzeriteEmpoweredItem.GetAllTierInfo, AzeriteEmpoweredItem.IsPowerSelected, AzeriteEmpoweredItem.GetPowerInfo
end 

-------------------------------------------------------------------------------
-- Constances (spellID to assign or create actions, taken lowest ID)
-------------------------------------------------------------------------------
Lib.CONST = {
	--[[ Essences Used by All Roles - Passive]]
	VisionofPerfection			= 299368,
	ConflictandStrife			= 304017,
	--[[ Essences Used by All Roles - Active]]
	ConcentratedFlame 			= 295373, 
	WorldveinResonance			= 295186, 
	RippleinSpace				= 302731, 
	MemoryofLucidDreams			= 298357, 
	--[[ Tank ]]
	AzerothsUndyingGift			= 293019, 
	AnimaofDeath				= 294926, 
	AegisoftheDeep				= 298168, 
	EmpoweredNullBarrier		= 295746, 
	SuppressingPulse			= 293031, 
	--[[ Healer ]]
	Refreshment					= 296197, 
	Standstill					= 296094, 
	LifeBindersInvocation		= 293032, 
	OverchargeMana				= 296072, 
	VitalityConduit				= 296230, 
	--[[ Damager ]]
	FocusedAzeriteBeam			= 295258, 
	GuardianofAzeroth			= 295840, 
	BloodoftheEnemy				= 297108, 
	PurifyingBlast				= 295337, 
	TheUnboundForce				= 298452, 
}

-------------------------------------------------------------------------------
-- Azerite Essences - Major and Minor
-------------------------------------------------------------------------------
local AzeriteEssenceGetMilestoneEssence, AzeriteEssenceGetMilestoneSpell, AzeriteEssenceGetEssenceInfo, AzeriteEssenceGetMilestones, EnumAzeriteEssence
if AzeriteEssence then 
	AzeriteEssenceGetMilestoneEssence, 	AzeriteEssenceGetMilestoneSpell,  AzeriteEssenceGetEssenceInfo,  AzeriteEssenceGetMilestones,  EnumAzeriteEssence =
	AzeriteEssence.GetMilestoneEssence, AzeriteEssence.GetMilestoneSpell, AzeriteEssence.GetEssenceInfo, AzeriteEssence.GetMilestones, Enum.AzeriteEssence
	DataEssences.GetMajorBySpellNameOnENG = {
		-- Taken lowest Azerite Essence ID
		--[[ Essences Used by All Roles - Passive]] 
		-- Vision of Perfection
		[Spell:CreateFromSpellID(Lib.CONST.VisionofPerfection):GetSpellName()] 			= "Vision of Perfection", 
		-- Conflict and Strife
		[Spell:CreateFromSpellID(Lib.CONST.ConflictandStrife):GetSpellName()] 			= "Conflict and Strife", 		
		--[[ Essences Used by All Roles - Active]]
		[Spell:CreateFromSpellID(Lib.CONST.ConcentratedFlame):GetSpellName()] 			= "Concentrated Flame",
		[Spell:CreateFromSpellID(Lib.CONST.WorldveinResonance):GetSpellName()] 			= "Worldvein Resonance",
		[Spell:CreateFromSpellID(Lib.CONST.RippleinSpace):GetSpellName()] 				= "Ripple in Space", 
		[Spell:CreateFromSpellID(Lib.CONST.MemoryofLucidDreams):GetSpellName()] 		= "Memory of Lucid Dreams",
		--[[ Tank ]]
		[Spell:CreateFromSpellID(Lib.CONST.AzerothsUndyingGift):GetSpellName()] 		= "Azeroth's Undying Gift",
		[Spell:CreateFromSpellID(Lib.CONST.AnimaofDeath):GetSpellName()] 				= "Anima of Death",
		[Spell:CreateFromSpellID(Lib.CONST.AegisoftheDeep):GetSpellName()] 				= "Aegis of the Deep",
		[Spell:CreateFromSpellID(Lib.CONST.EmpoweredNullBarrier):GetSpellName()] 		= "Empowered Null Barrier",
		[Spell:CreateFromSpellID(Lib.CONST.SuppressingPulse):GetSpellName()] 			= "Suppressing Pulse", 
		--[[ Healer ]]
		[Spell:CreateFromSpellID(Lib.CONST.Refreshment):GetSpellName()] 				= "Refreshment", 
		[Spell:CreateFromSpellID(Lib.CONST.Standstill):GetSpellName()] 					= "Standstill", 
		[Spell:CreateFromSpellID(Lib.CONST.LifeBindersInvocation):GetSpellName()] 		= "Life-Binder's Invocation", 
		[Spell:CreateFromSpellID(Lib.CONST.OverchargeMana):GetSpellName()] 				= "Overcharge Mana", 
		[Spell:CreateFromSpellID(Lib.CONST.VitalityConduit):GetSpellName()] 			= "Vitality Conduit", 
		--[[ Damager ]]
		[Spell:CreateFromSpellID(Lib.CONST.FocusedAzeriteBeam):GetSpellName()] 			= "Focused Azerite Beam", 
		[Spell:CreateFromSpellID(Lib.CONST.GuardianofAzeroth):GetSpellName()] 			= "Guardian of Azeroth", 
		[Spell:CreateFromSpellID(Lib.CONST.BloodoftheEnemy):GetSpellName()] 			= "Blood of the Enemy", 
		[Spell:CreateFromSpellID(Lib.CONST.PurifyingBlast):GetSpellName()] 				= "Purifying Blast", 
		[Spell:CreateFromSpellID(Lib.CONST.TheUnboundForce):GetSpellName()] 			= "The Unbound Force", 
	}
	DataEssences.IsPassive = {
		-- Checking by spellID which converts to spellName (it's more stable than ID because ID can be changed by Rank and Spec)
		-- Vision of Perfection
		[Spell:CreateFromSpellID(Lib.CONST.VisionofPerfection):GetSpellName()] 			= true, 
		-- Conflict and Strife
		[Spell:CreateFromSpellID(Lib.CONST.ConflictandStrife):GetSpellName()]	 		= true, 
	}
	DataEssences.IsTalentPvP = {
		-- Death Knight: Unholy Command (Blood)
		[Spell:CreateFromSpellID(202727):GetSpellName()] 	= true,
		[202727] 											= true,
		-- Death Knight: Chill Streak (Frost)
		[Spell:CreateFromSpellID(204160):GetSpellName()] 	= true,
		[204160]											= true,
		-- Death Knight: Necrotic Strike (Unholy)
		[Spell:CreateFromSpellID(223829):GetSpellName()] 	= true,
		[223829]											= true,
		-- Demon Hunter: Demonic Origins (Vengance)
		[Spell:CreateFromSpellID(235893):GetSpellName()] 	= true,
		[235893]											= true,
		-- Demon Hunter: Cleansed by Flame (Havoc)
		[Spell:CreateFromSpellID(205625):GetSpellName()]	= true,
		[205625] 											= true,
		-- Druid: Thorns (Balance / Feral)
		[Spell:CreateFromSpellID(236696):GetSpellName()]	= true,
		[236696] 											= true,
		-- Druid: Sharpened Claws (Guardian)
		[Spell:CreateFromSpellID(202110):GetSpellName()]	= true,
		[202110] 											= true,
		-- Druid: Overgrowth (Restoration)
		[Spell:CreateFromSpellID(203651):GetSpellName()]	= true,
		[203651] 											= true,
		-- Hunter: Hi-Explosive Trap (Beast Mastery / Marksmanship / Survival)
		[Spell:CreateFromSpellID(236776):GetSpellName()]	= true,
		[236776] 											= true,
		-- Mage: Temporal Shield (Arcane / Frost / Fire)
		[Spell:CreateFromSpellID(198111):GetSpellName()]	= true,
		[198111] 											= true,
		-- Monk: Hot Trub (Brewmaster)
		[Spell:CreateFromSpellID(202126):GetSpellName()]	= true,
		[202126] 											= true,
		-- Monk: Way of the Crane (Mistweaver)
		[Spell:CreateFromSpellID(216113):GetSpellName()]	= true,
		[216113] 											= true,
		-- Monk: Reverse Harm (Windwalker)
		[Spell:CreateFromSpellID(287771):GetSpellName()]	= true,
		[287771] 											= true,
		-- Paladin: Divine Favor (Holy)
		[Spell:CreateFromSpellID(210294):GetSpellName()]	= true,
		[210294] 											= true,
		-- Paladin: Steed of Glory (Protection)
		[Spell:CreateFromSpellID(199542):GetSpellName()]	= true,
		[199542] 											= true,
		-- Paladin: Unbound Freedom (Retribution)
		[Spell:CreateFromSpellID(199325):GetSpellName()]	= true,
		[199325] 											= true,
		-- Priest: Premonition (Discipline)
		[Spell:CreateFromSpellID(209780):GetSpellName()]	= true,
		[209780] 											= true,
		-- Priest: Holy Ward (Holy)
		[Spell:CreateFromSpellID(213610):GetSpellName()]	= true,
		[213610] 											= true,
		-- Priest: Void Shift (Shadow)
		[Spell:CreateFromSpellID(108968):GetSpellName()]	= true,
		[108968] 											= true,
		-- Rogue: Maneuverability (Assassination / Outlaw / Subtlety)
		[Spell:CreateFromSpellID(197000):GetSpellName()]	= true,
		[197000] 											= true,
		-- Shaman: Lightning Lasso (Elemental)
		[Spell:CreateFromSpellID(204437):GetSpellName()]	= true,
		[204437] 											= true,
		-- Shaman: Thundercharge (Enhancement)
		[Spell:CreateFromSpellID(204366):GetSpellName()]	= true,
		[204366] 											= true,
		-- Shaman: Ancestral Gift (Restoration)
		[Spell:CreateFromSpellID(290254):GetSpellName()]	= true,
		[290254] 											= true,
		-- Warlock: Endless Affliction (Affliction)
		[Spell:CreateFromSpellID(305391):GetSpellName()]	= true,
		[305391] 											= true,
		-- Warlock: Nether Ward (Demonology)
		[Spell:CreateFromSpellID(212295):GetSpellName()]	= true,
		[212295] 											= true,
		-- Warlock: Demon Armor (Destruction)
		[Spell:CreateFromSpellID(285933):GetSpellName()]	= true,
		[285933] 											= true,
		-- Warrior: Sharpen Blade (Arms)
		[Spell:CreateFromSpellID(198817):GetSpellName()]	= true,
		[198817] 											= true,
		-- Warrior: Battle Trance (Fury)
		[Spell:CreateFromSpellID(213857):GetSpellName()]	= true,
		[213857] 											= true,
		-- Warrior: Thunderstruck (Protection)
		[Spell:CreateFromSpellID(199045):GetSpellName()]	= true,
		[199045] 											= true,		
	}
end 

function DataEssences.GetInfo(milestone) 
	-- @return table (all info about milestone) or nil
	local essenceID 	= AzeriteEssenceGetMilestoneEssence(milestone.ID) 	
	if essenceID then 
		local spellInfo = AzeriteEssenceGetMilestoneSpell(milestone.ID)
		local info 		= AzeriteEssenceGetEssenceInfo(essenceID)
		if info and spellInfo then 
			local spellID = FindSpellOverrideByID(spellInfo)    
			local temp = {
				spellID = spellID,
				spellName = GetInfoSpell(spellID),
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

function DataEssences.Update() 
	-- Updates Major (1) and Minor (2) slots  
	DataEssences.Major 		= nil
	DataEssences.MinorOne 	= nil 
	DataEssences.MinorTwo 	= nil
	wipe(DataEssences.Total)
	
	if AzeriteEssence and AzeriteEmpoweredItemIsHeartOfAzerothEquipped() then
		local milestones = AzeriteEssenceGetMilestones()
		for i, milestone in ipairs(milestones) do
			-- Enumerates each milestone with output table 'milestone' with keys: ID, requiredLevel, canUnlock, unlocked, slot
			if milestone.slot == EnumAzeriteEssence.MainSlot then
				DataEssences.Major = DataEssences.GetInfo(milestone)
				if DataEssences.Major then 
					DataEssences.Total[DataEssences.Major.spellName] = DataEssences.Major 
				end 
			elseif milestone.slot == EnumAzeriteEssence.PassiveOneSlot then 
				DataEssences.MinorOne = DataEssences.GetInfo(milestone)
				if DataEssences.MinorOne then 
					DataEssences.Total[DataEssences.MinorOne.spellName] = DataEssences.MinorOne 
				end 
			elseif milestone.slot == EnumAzeriteEssence.PassiveTwoSlot then 
				DataEssences.MinorTwo = DataEssences.GetInfo(milestone)
				if DataEssences.MinorTwo then 
					DataEssences.Total[DataEssences.MinorTwo.spellName] = DataEssences.MinorTwo 
				end
			end
			
			-- Break 
			if DataEssences.Major and DataEssences.MinorOne and DataEssences.MinorTwo then 
				break 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local AzeriteItems 
function Data.OnEvent()  	
	if not AzeriteItems then 
		AzeriteItems = {}
		for i = 1, #DataInventorySlots do
			AzeriteItems[DataInventorySlots[i]] = Item:CreateFromEquipmentSlot(DataInventorySlots[i])
		end
		Listener:Remove("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_LOGIN")
	end 
	
	wipe(DataRanks)    
	
	for slot, item in pairs(AzeriteItems) do
		if not item:IsItemEmpty() then
			local itemLoc = item:GetItemLocation()
			
			-- Azerite Empower
			if slot ~= 2 and AzeriteEmpoweredItemIsAzeriteEmpoweredItem(itemLoc) then
				local tierInfos = AzeriteEmpoweredItemGetAllTierInfo(itemLoc)
				for _, tierInfo in pairs(tierInfos) do
					for _, powerId in pairs(tierInfo.azeritePowerIDs) do
						if AzeriteEmpoweredItemIsPowerSelected(itemLoc, powerId) then
							local spellName = GetInfoSpell(AzeriteEmpoweredItemGetPowerInfo(powerId).spellID)							
							if not DataRanks[spellName] then
								DataRanks[spellName] = 1
							else
								DataRanks[spellName] = DataRanks[spellName] + 1
							end                                    
						end
					end
				end
			end
			
			-- Azerite Essence
			if slot == 2 then 
				DataEssences.Update() 
			end 
		end
	end       
end

-- Azerite Empower
Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_ENTERING_WORLD", 					Data.OnEvent)
Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_EQUIPMENT_CHANGED", 				Data.OnEvent)
Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_SPECIALIZATION_CHANGED", 			Data.OnEvent)
Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "SPELLS_CHANGED", 							Data.OnEvent)
Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "PLAYER_LOGIN", 							Data.OnEvent)

-- Azerite Essence
if AzeriteEssence then	
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_CHANGED", 				DataEssences.Update)
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_UPDATE", 				DataEssences.Update) 
	Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_ACTIVATED", 			DataEssences.Update)
	--Listener:Add("ACTION_EVENT_AZERITE_TRAITS", "AZERITE_ESSENCE_ACTIVATION_FAILED", 	DataEssences.Update)
end 

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
function Lib:GetRank(spellID)
	-- @return number (0 - not existed or not selected)
	-- Note: Shared for both Azerite Empower and Azerite Essence
	local spellName = GetInfoSpell(spellID)
    local rank 		= DataRanks[spellName] or (DataEssences.Total[spellName] and DataEssences.Total[spellName].Rank)
    return rank and rank or 0
end 

function Lib:EssenceGet(spellID)
	-- @return table (with all available information about total essences in use) or nil
	return DataEssences.Total[GetInfoSpell(spellID)]
end 

function Lib:EssenceGetMajor()
	-- @return table (with all available information about Major slot) or nil 
	return DataEssences.Major
end 

function Lib:EssenceGetMajorBySpellNameOnENG(spellName)
	-- @return string (ENGLISH localization of equal spellName) or nil
	return DataEssences.GetMajorBySpellNameOnENG[spellName]
end 

function Lib:EssenceIsMajorUseable(spellID) 
	-- @return boolean 
	if DataEssences.Major and DataEssences.Major.spellID then 
		return not DataEssences.IsPassive[DataEssences.Major.spellName] and not DataEssences.IsPassive[DataEssences.Major.Name] and (not spellID or self:EssenceHasMajor(spellID))
	end 
end 

function Lib:EssenceHasMajor(spellID)
	-- @return boolean 
	-- Note: Search by localized spellName, essenceName or spellID 
	if DataEssences.Major then 
		if DataEssences.Major.spellID == spellID then 
			return true 
		else 
			local spellName = GetInfoSpell(spellID)
			if DataEssences.Major.spellName == spellName or DataEssences.Major.Name == spellName then 
				return true 
			end 
		end 
	end 
end 

function Lib:EssenceHasMinor(spellID)
	-- @return boolean 
	-- Note: Search by localized spellName, essenceName or spellID 
	if (DataEssences.MinorOne and DataEssences.MinorOne.spellID == spellID) or (DataEssences.MinorTwo and DataEssences.MinorTwo.spellID == spellID) then 
		return true 
	else 
		local spellName = GetInfoSpell(spellID)
		if (DataEssences.MinorOne and (DataEssences.MinorOne.spellName == spellName or DataEssences.MinorOne.Name == spellName)) or (DataEssences.MinorTwo and (DataEssences.MinorTwo.spellName == spellName or DataEssences.MinorTwo.Name == spellName)) then 
			return true 
		end 
	end  
end 

function Lib:EssencePredictHealing(MajorSpellNameENG, spellID, unitID, VARIATION)
	-- @return boolean (if can be used without overheal), number (amount of health restoring, in some cases it's percent @percent / in some clear numeric amount @direct)
	
	-- Exception penalty for low level units / friendly boss
    local UnitLvL = A_Unit(unitID):GetLevel()
    if (UnitLvL <= 0 or (UnitLvL > 0 and UnitLvL < A_Unit("player"):GetLevel() - 10)) and MajorSpellNameENG ~= "Anima of Death" and MajorSpellNameENG ~= "Vitality Conduit" then
        return true, 0
    end     
    
    -- Header
    local variation 		= (VARIATION and (VARIATION / 100)) or 1      
    local total 			= 0
    local DMG 				= A_Unit(unitID):GetDMG()
	local HPS 				= A_Unit(unitID):GetHEAL()     
    local HealthDeficit 	= -1 
        
    -- Spells
    if MajorSpellNameENG == "Concentrated Flame" then  
		-- @direct
		HealthDeficit	 	= A_Unit(unitID):HealthDeficit()		
		-- Multiplier (resets on 4th stack, each stack +100%)
		local multiplier 	= A_Unit(unitID):HasBuffsStacks(295378, true) + 1				
		local amount 		= A_GetSpellDescription(spellID)[1] * multiplier
		
		-- Additional +75% over next 6 sec 
		local additional = 0
		if self:GetRank(spellID) >= 2 then
			additional = amount * 0.75 * multiplier + (HPS * 6) - (DMG * 6)
		end 
		
        total = (amount + additional) * variation           
    end
	
	if MajorSpellNameENG == "Anima of Death" then 
		-- @percent 
		local HP		= A_Unit(unitID):HealthPercent()
		HealthDeficit 	= 100 - HP
			
		-- Passing (in case if something went wrong with nameplates)
		if not ActiveUnitPlates then 
			if HP > 80 then 
				return false, 0
			else
				return true, 0
			end 
		end 
		
		local rank 		= self:GetRank(spellID)
		-- HP in percent heal per unit 
		local hpperunit = rank >= 3 and 10 or 5
		-- HP limit (on which stop query)
		local hplimit 	= rank >= 3 and 50 or 25		
		local totalmobs = 0
		for _, unit in pairs(ActiveUnitPlates) do
			if A_Unit(unit):GetRange() <= 8 then
				totalmobs = totalmobs + 1
				total = totalmobs * hpperunit * variation 
				if total >= hplimit then                
					break            
				end        
			end
		end 	
	end 

	if MajorSpellNameENG == "Refreshment" then 
		local maxUnitHP 	= A_Unit(unitID):HealthMax()
		-- @direct
		HealthDeficit 		= maxUnitHP - A_Unit(unitID):Health()  
		-- The Well of Existence do search by name, TMW will do rest work 
		local amount 		= A_Unit("player"):AuraTooltipNumber(296136, "HELPFUL") 
		
		if amount < maxUnitHP * 0.15 then 
			-- Do nothing if it heal lower than 15% on a unit
			return false, 0				
		elseif amount >= maxUnitHP and A_Unit(unitID):HealthPercent() < 70 then 
			-- Or if we reached cap (?) 
			return true, 0 
		end 
		
		total = amount * variation
	end 
	
	if MajorSpellNameENG == "Vitality Conduit" then 
		-- @AoE 
		local amount 		= A_GetSpellDescription(spellID)[1]
		total 				= amount * variation
		
		local validMembers 	= A_HealingEngine.GetMinimumUnits(1, 5)
		if validMembers < 2 then 
			validMembers 	= 2
		end 
		
		local totalMembers 	= 0 
		if #A_HealingEngineMembersALL > 0 and validMembers >= 2 then 
			for i = 1, #A_HealingEngineMembersALL do
				if A_HealingEngineMembersALL[i].MHP - A_HealingEngineMembersALL[i].AHP >= total then
					totalMembers = totalMembers + 1
				end
				if totalMembers >= validMembers then 
					return true, total * totalMembers
				end 
			end
		end
		
		return false, total * totalMembers
	end 
	
	return HealthDeficit >= total, total
end   

function Lib:IsLearnedByConflictandStrife(spell)
	-- @return boolean (if spellName or spellID is learned by Major PvP essence)
	if self:EssenceHasMajor(self.CONST.ConflictandStrife) then -- Get 'Conflict and Strife' localized name 
		return DataEssences.IsTalentPvP[spell]
	end 	
end 

-------------------------------------------------------------------------------
-- Debug
-------------------------------------------------------------------------------
--[[ Example:
-- Get info (@table or @nil) about specified essence by spellID which converts to localized name  
/dump LibStub("AzeriteTraits"):EssenceGet(1245336)
-- Get info (@table or @nil) about Major 
/dump LibStub("AzeriteTraits"):EssenceGetMajor()
]]