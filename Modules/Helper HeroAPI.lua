local TMW = TMW 
local CNDT = TMW.CNDT 
local Env = CNDT.Env

HeroRotation		= HeroRotation or {}
local Cache 		= HeroCache
local HL 			= HeroLib
local HR 			= HeroRotation 
local Spell 		= HL and HL.Spell
local Item 			= HL and HL.Item

local Action 		= Action
local pairs, loadstring =		
	  pairs, loadstring
	  
-------------------------------------------------------------------------------
-- Core 
-------------------------------------------------------------------------------	  
function Action:HeroCreate() 
	-- @return table, table or nil 
	-- Convert from Action to Hero Spells and Items
	if HL then 
		local S, I = {}, {}
		for k, v in pairs(self) do 
			if v.Type:match("Spell") or v.SubType == "HeartOfAzeroth" then 
				S[k] = Spell(v.ID)
				-- Push identificator for 'The Action'
				S[k].KEY = k
			end 
			
			if v.Type:match("Item") or v.Type == "Potion" or v.Type == "Trinket" then 
				I[k] = Item(v.ID)
				-- Push identificator for 'The Action'
				I[k].KEY = k
			end 
		end 
		return S, I
	end 	 
end 

local IsHooked = {}
function Action.HeroSetHook(objects, metas)
	-- @usage
	--[[
		Action.HeroSetHook({
			S.Brew,
			S.Guard,
		}, 
		{
			[3] = "TellMeWhen_Group4_Icon3",
			[4] = "TellMeWhen_Group4_Icon4",
		})
	]]
	-- Sets hook on call HR.Cast and HR.CastSuggested functions with relative frame for texture show 
	for i = 1, #objects do 
		IsHooked[objects[i].KEY] = metas
	end 
end 

function Action.HeroSetHookAllTable(tabl, metas)
	-- @usage 
	--[[
		Action.HeroSetHookAllTable(S, {
			[3] = "TellMeWhen_Group4_Icon3",
			[4] = "TellMeWhen_Group4_Icon4",
		})
	]]
	-- Does same as Action.HeroSetHook but it takes all from direct table
	for _, v in pairs(tabl) do 
		IsHooked[v.KEY] = metas
	end 
end 

-------------------------------------------------------------------------------
-- Remap 
-------------------------------------------------------------------------------	  
local Dummy = function() return true end 
local ObjKey = function(Object)
	if Action.IsInitialized and Object and Object.KEY and IsHooked[Object.KEY] then 
		for meta, frame in pairs(IsHooked[Object.KEY]) do
			if Action[Env.PlayerSpec] and Action[Env.PlayerSpec][meta] and Action[Env.PlayerSpec][Object.KEY] then 
				Action[Env.PlayerSpec][Object.KEY]:Show(loadstring("return " .. frame)())
				-- /run local a = assert(loadstring("return TellMeWhen_Group4_Icon4"))(); print(a)
				-- /dump loadstring("return TellMeWhen_Group4_Icon4")()
			end 
		end 
	end 
	
	return true 
end 

local CachedCast = HR.Cast or Dummy
function HR.Cast(Object, OffGCD, DisplayStyle)
	if CachedCast(Object, OffGCD, DisplayStyle) then 
		ObjKey(Object)
		return true 
	end 
end 

local CachedCastSuggested = HR.CastSuggested or Dummy
function HR.CastSuggested(Object)
	if CachedCastSuggested(Object) then 
		ObjKey(Object)
		return true 
	end 
end 

-- Get if the CDs are enabled.
function HR.CDsON(unit)
	if Action.IsInitialized then 
		local unit = unit or "target"
		return Action.BurstIsON(unit)
	end 
	
	return HeroRotationCharDB.Toggles[1]
end

-- Get if the AoE is enabled.
function HR.AoEON()
	if Action.IsInitialized then 
		return Action.GetToggle(2, "AoE")
	end 
	
	return HeroRotationCharDB.Toggles[2]
end

if HL then 
	local Spell = HL.Spell
	local Item = HL.Item
	
	-- Connect it with 'The Action' by SetBlocker, SetQueue and custom LUA (+ toggles for Potion, Trinkets, HeartOfAzeroth)
	local function ActionAPI(Object)
		return not Action.IsInitialized or (Action[Env.PlayerSpec] and Action[Env.PlayerSpec][Object.KEY] and Action[Env.PlayerSpec][Object.KEY]:IsReady())
	end 
	
	-- Spells 
	local CachedSpellIsCastable = Spell.IsCastable
	function Spell:IsCastable(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsCastable(self, Range, AoESpell, ThisUnit)
	end

	local CachedSpellIsCastableP = Spell.IsCastableP
	function Spell:IsCastableP(Range, AoESpell, ThisUnit, BypassRecovery, Offset)
		return ActionAPI(self) and CachedSpellIsCastableP(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
	end
	
	local CachedSpellIsReady = Spell.IsReady
	function Spell:IsReady(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReady(self, Range, AoESpell, ThisUnit)
	end
	
	local CachedSpellIsReadyP = Spell.IsReadyP
	function Spell:IsReadyP(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReadyP(self, Range, AoESpell, ThisUnit)
	end
	
	-- Items 
	local CachedItemIsReady = Item.IsReady
	function Item:IsReady()
		return ActionAPI(self) and CachedItemIsReady(self)
	end
end 