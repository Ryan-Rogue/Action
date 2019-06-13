--------------------------------------
-- №1: Create snippet 
--------------------------------------
-- Go to /tmw > LUA Snippets > Profile (left side) > "+"

--------------------------------------
-- №2: Set profile defaults 
--------------------------------------
-- To make more clearer recommended create Action.Data.ProfileEnabled and Action.Data.ProfileUI in standalone profile snippet 
-- Each profile creation starts from this:
Action.Data.ProfileEnabled[TMW.db:GetCurrentProfile()] = true -- this indicates to use Action all components and make him initializated 
--[[ 
Action.Data.ProfileUI table where you have to set UI elements with DB (DataBase) variables and their default presets
This table can be omited however then [2] and [7] will display 'Profile has no configuration for this tab.'
Structure (example with all supported elemenets):	
	tab.name should be exactly relative tab number, supported [2] (for spec tab) and [7] (for MSG tab), replace it by these numbers in [] brackets
		PLAYERSPEC should be exactly specID number, so replace it in [] brackets 
			if tab.name is [2] 
			(optional) LayoutOptions is a special table which can be used to configure layout position through keys: { columns = *number*, gutter = *number*, padding = { top = *number*, right = *number*, left = *number* } }
				(optional) RowOptions is a special table which can be used to configure specified row position through keys: { margin = { top = *number*, right = *number*, left = *number*, bottom = *number* } }
					E is type of Element, supported: "Label", "Header", "Checkbox", "Dropdown", "Slider", "LayoutSpace"
					L is localization table which supported ANY as key (usually for things such as GetSpellInfo)
					DB is name of key for SavedVariables in DataBase, supported: "Checkbox", "Dropdown", "Slider" 
					DBV is default value if key wasn't existed before, it also using for 'Reset Settings', supported: "Checkbox", "Dropdown", "Slider" 
					(optional) S is text size, supported: "Label", "Header"
					(optional) TT is ToolTip localization table which supported ANY as key (usually for things such as GetSpellInfo), if omited and M exist then will display localized by main core text - "RightClick: create macro"
					(optional) M is Macro which is table with keys 2 ways: { Custom = *string* } or { Value = *any*, TabN = *number*, Print = *string* }
					(optional) H is Height of element *number*, supported: "Dropdown", "Slider"
					(optional) isDisabled is boolean, supported: "Checkbox", "Dropdown"
					OT is OptionTable, supported: "Dropdown". Keys: { { text = *string*, value = *string* or *number* }, { same }, {}, {} }
					(optional) SetPlaceholder is localization table of the text for Dropdown if he hasn't anything selected, supported: "Dropdown"
					(optional) MULT is boolean which if it's true then Dropdown will has multiselector 
					(optional) isNotEqualVal (only if MULT is false or omited ) is custom value of Dropdown which shouldn't be recorded into Cache, otherwise it's ~= "Off", ~= "OFF" and ~= 0
					(optional) MIN (default -1), supported: "Slider"
					(optional) MAX (default 100), supported: "Slider"
					(optional) Precision custom step, supported: "Slider"
			if tab.name is [7]
			["phrase"] - This is key which is string phase which will match a message written in /party chat. MUST BE IN LOWER CASE!
			["phrase"] = { Enabled = "@boolean (always true)", Key = "@string (from Action[PLAYERSPEC] table)", Source = "@nil or @string (who said phrase, if same server then probably no need add server after)", LUA = "@nil or @string in [[]] brackets" },			
]]	
-- Template with all available things to use 
Action.Data.ProfileUI = {
	[2] = {													-- Config UI for [2] tab (spec tab) 
		[PLAYERSPEC] = { 									-- MUST BE REPLACED BY SPECID in [] brackets 
			-- Template
			LayoutOptions = { padding = { top = 40 } }, 	-- Optional
			-- Row Template
			{
				RowOptions = { margin = { top = -15 } }, 	-- Optional
				-- Elements Template
				{},
				{},
				{},
				-- OR Element 
				{},
			},			
			-- Element Template
			-- ALL Required: E (@string, element type, L (@table, locale) 				
			{ 	-- Optional: S (@number, text size)
				E = "Label", 
				L = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				S = 14 or nil,
			},						
			{	-- Optional: S (@number, text size)
				E = "Header",
				L = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				S = 14 or nil,
			},
			{ 	-- Required: DB (@string, Action.Data.ProfileDB), DBV (@any, Action.Data.ProfileDB)
				-- Optional: TT (@table, tooltip locale), M (@table, look above), isDisabled (@boolean)
				E = "Checkbox",
				DB = "toggle",
				DBV = *any*,
				L = { 
					ANY = Action.GetSpellInfo(17) .. " (%)",
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				TT = { 
					ANY = Action.GetSpellInfo(17) .. " (% HP)",
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				M = { -- must exist or macro will not be created 
					Custom = "/run Action.ToggleTest()", -- all below is not valid if Custom key noted
					-- Otherwise it will structure like 
					-- /run Action.SetToggle({[tab.name], Action.Data.ProfileUI[tab.name][spec].DB, Action.Data.ProfileUI[tab.name][spec].L[CL] .. ": "}, Action.Data.ProfileUI[tab.name][spec].M.Value)
					-- CraftMacro(L[CL], macro above, 1) -- 1 means perCharacter
					Value = "Auto" or nil, -- can be nil 
					-- Very Very Optional, no idea why it will need in the future however.. 
					TabN = 2 or nil,								
					Print = "textPrintSomething: " or nil,								
				},
				isDisabled = true or nil,
			},
			{ 	-- Required: DB (@string, Action.Data.ProfileDB), DBV (@any, Action.Data.ProfileDB), OT (@table, option table same as StdUi)
				-- Optional: H (@number, height default 20), TT (@table, tooltip locale), M (@table, look above), MULT (@bolean, multiselector like Trinkets), isNotEqualVal (@any), SetPlaceholder (@table, localization of the space to display when dropdown has not selected anything), isDisabled (@boolean)
				E = "Dropdown", 														
				H = 20 or nil,
				OT = {
					{ text = "one", value = 1 },
					{ text = "two", value = 2 },
				},
				MULT = false or nil,
				isNotEqualVal = *any*, -- only if MULT is false or omited 
				DB = "toggle",
				DBV = *any*,	
				SetPlaceholder = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				L = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				TT = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				M = {
				},	
				isDisabled = false or nil, 
			},
			{ 	-- Required: DB (@string, Action.Data.ProfileDB), DBV (@any, Action.Data.ProfileDB),OT (@table, option table same as StdUi)
				-- Optional: H (@number, height default 20), TT (@table, tooltip locale), M (@table, look above), MIN (@number, default -1), MAX (@number, default 100), Precision (@number, custom steps)
				E = "Slider", 													
				H = 20 or nil,
				MIN = -1, 
				MAX = 100,							
				DB = "toggle",
				DBV = *any*,
				L = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				TT = { 
					enUS = "ENG", 
					ruRU = "RUS", 
				}, 
				M = {
				},
				Precision = 2 or nil, 
			},
			{	-- Just add empty space in row whenever it need
				E = "LayoutSpace",
			},
		}, 
	},
	[7] = {
		[PLAYERSPEC] = {
			["kick"] = { Enabled = true, Key = "Interrupt", Source = "UserName-UserServerIfItsDifferent" or nil, LUA = [[ return UnitLevel("player") >= 120 ]] or nil },
		},
	},
} 
-- This and all below recommended create in each specialization profile snippet
-- Apply general GGL API 
local TMW = TMW 
local CNDT = TMW.CNDT 
local Env = CNDT.Env -- or local E = CNDT.Env -- which is more shorter 
-- Now we need create actions (spells, items) and put them into APL (Action Priority List), default it uses Action table, so we link it here 
local Action = Action
--[[
-- Here is constructor template with all available options
-- PLAYERSPEC should be replaced by specID like (Rogue Outlaw): [260]
-- First assign custom key like POWS which will be used to refference in this table 
-- Then you need assign specific table through function Action.Create
--		Arguments (they are always in table {}):
--			Required: Type, ID, Color (Color valid only if Type is Spell|SpellSingleColor|Item|ItemSingleColor)
--			Optional: Desc (use this if need set Rank on action or if same ID already uses, this is also displays in UI as Note in ScrollTable), QueueForbidden (boolean if need prevent cause by user set Queue on action), Texture (acceptable by spellID|itemID)
--			{ Type = "Spell|SpellSingleColor|Trinket|Potion|HeartOfAzeroth|Item|ItemSingleColor", ID = "@number", Color = "@string key which can be found in Action.Data.C (you can add custom colors or use own hex)", Desc = "@string", QueueForbidden = "@boolean", Texture = "@number" }
Action[PLAYERSPEC] = {
	POWS = Action.Create({ Type = "Spell", ID = 17}),
	PetKick = Action.Create({ Type = "Spell", ID = 47482, Color = "RED", Desc = "RED" }),  
	POWS_Rank2 = Action.Create({ Type = "SpellSingleColor", ID = 17, Color = "BLUE", Desc = "Rank2" }), 
	TrinketTest = Action.Create({ Type = "Trinket", ID = 122530, QueueForbidden = true }),
	TrinketTest2 = Action.Create({ Type = "Trinket", ID = 159611, QueueForbidden = true }),	
	PotionTest = Action.Create({ Type = "Potion", ID = 142117, QueueForbidden = true }),
	-- Mix will use action with ID 2983 as itself Rogue's Sprint but it will display Power Word: Shield with applied over color "LIGHT BLUE" and UI will displays Note with "Test", also Queue system will not run Queue with this action
	Sprint = Action.Create({ Type = "SpellSingleColor", ID = 2983, QueueForbidden = true, Desc = "Test", Color = "LIGHT BLUE", Texture = 17}),
	-- More examples 
	NimbleBrew = Action.Create({ Type = "Item", ID = 137648, Color = "RED" }),
}
-- Now we starting build itself APL for each meta slot, about meta slots you can find at site in guides/development
-- META should be replaced by meta slot (number). In short: 
-- 1 - Kick, 2 - CC, 3 - Single Rotation, 4 - AoE Rotation, 5 - Trinket, 6 - Passive (@player, @raid1, @arena1), 7 - Passive (@raid2, @party1, @arena2 sometimes additional START), 8 - Passive (@raid3, @party2, @arena3 sometimes additional START)
]]
-- I prefer make it shorter and it will help prevent mistakes and confuse, so we will better set this:
local A = setmetatable(Action[PLAYERSPEC], { __index = Action })
-- You should put here locals before create A[PLAYERSPEC][META] = function(icon) or they wouldn't be linked 
local function Test() 
	return "TestThing" 
end 
A[PLAYERSPEC][META] = function(icon)                                    				-- icon should be used by TMW conditions > Lua and argument icon is thisobj. Example of LUA conditions usage in /tmw : Action.Rotation(thisobj)  
	-- You no need here check pause or queue because this is already will be checked before execute all below:
	if 																				-- if not blocked and not in queue (e.g. not ready as CD / not in range / not enough safe cap power / never use in queue / queue is empty)															
		A.POWS:IsReady("target") and 												-- required ("target" can be nil if no need unit check for custom LUA)									
		Env.SpellCD(A.POWS.ID) == 0 and 
		Env.SpellInRange("target", A.POWS.ID) and 
		Test() == "TestThing"
	then 																			-- the normalized view of earlier existed API                                            	
        return A.POWS:Show(icon)        											-- must return true to show frame since :show has return true I can and will wirte in one string this
    end 
end 		
-- /tmw and apply code for always shown frame at the left upper corner by "Conditions" > "LUA (Advanced)"
-- Once created there will reference for all specs but work exactly with which is active
-- Action.Rotation(META, thisobj)
-- Use these keys to create racials 
local KeyByRace = {
	Worgen = "Darkflight",
	VoidElf = "SpatialRift",
	NightElf = "Shadowmeld",
	LightforgedDraenei = "LightsJudgment",
	KulTiran = "Haymaker",
	Human = "EveryManforHimself",
	Gnome = "EscapeArtist",
	Dwarf = "Stoneform",
	Draenei = "GiftoftheNaaru",
	DarkIronDwarf = "Fireblood",
	Pandaren = "QuakingPalm",
	ZandalariTroll = "Regeneratin",
	Scourge = "WilloftheForsaken",
	Troll = "Berserking",
	Tauren = "WarStomp",
	Orc = "BloodFury",
	Nightborne = "ArcanePulse",
	MagharOrc = "AncestralCall",
	HighmountainTauren = "BullRush",
	BloodElf = "ArcaneTorrent",
	Goblin = "RocketJump",
}
--------------------------------------
-- №3: Working example 
--------------------------------------
local TMW = TMW 
local CNDT = TMW.CNDT 
local E = CNDT.Env
local Action = Action
Action.Data.ProfileEnabled[TMW.db:GetCurrentProfile()] = true
Action.Data.ProfileUI = {	
	DateTime = "v1.2a (01.01.2850)",
	[2] = {
		[260] = { 						
			{
				{	
					E = "Header",
					L = { 
						enUS = "HEADER", 
						ruRU = "ЗАГОЛОВОК", 
					}, 
					S = 14,
				},
			},					
			{							
				{
					E = "Checkbox", 
					DB = "Feint",
					DBV = true,
					L = { 
						enUS = "Use Feint", 
						ruRU = "Использовать Фейнт", 
					}, 
					TT = { 
						enUS = "Enable to use", 
						ruRU = "Включает для использования", 
					}, 
					M = {},
				},
				{
					E = "Checkbox", 
					DB = "Shiv",
					DBV = false,
					L = { 
						enUS = "Enable Shiv", 
						ruRU = "Разблокировать шивку", 
					}, 
					TT = { 
						enUS = "Enable to use", 
						ruRU = "Включает для использования", 
					}, 
					M = {},
				},
			},
			{
				{
					E = "Dropdown", 														
					H = 20,
					OT = {
						{ text = "Leap", value = 1 },
						{ text = "Blink", value = 2 },
						{ text = "Portal", value = 3 }
					},
					MULT = true,
					--isNotEqualVal = *any*, -- only if MULT is false or omited 
					DB = "DropdownMult",
					DBV = {
						[1] = true,
						[2] = true,
						[3] = true,
					}, 
					SetPlaceholder = { 
						enUS = "-- DropdownMult --", 
						ruRU = "-- Выпадающий список --", 
					}, 
					L = { 
						enUS = "DropdownMult Config", 
						ruRU = "ВыпадающийСписок Конфиг", 
					}, 
					TT = { 
						enUS = "ToolTip Mult", 
						ruRU = "ТулТипа мульта", 
					}, 
					M = {},									
				},
				{
					E = "Checkbox", 
					DB = "CKnoMacro",
					DBV = true,
					L = { 
						enUS = "CKnoMacro", 
						ruRU = "ЧекБокс без макро", 
					}, 
					TT = { 
						enUS = "English ToolTip", 
						ruRU = "Русский тултип", 
					}, 
				},
			},
			{
				{
					E = "Checkbox", 
					DB = "ShortCK",
					DBV = true,
					L = { 
						enUS = "Short checkBox", 
						ruRU = "Короткий бокс", 
					}, 
				},
				{
					E = "Dropdown", 														
					H = 20,
					OT = {
						{ text = "Simcraft", value = "Simcraft" },
						{ text = "Custom", value = "Custom" },
						{ text = "Off", value = "Off" }
					},
					MULT = false,
					--isNotEqualVal = *any*, -- only if MULT is false or omited 
					DB = "DropdownSingle",
					DBV = "Simcraft",
					L = { 
						enUS = "Dropdown SINGLE", 
						ruRU = "Выпадающий ОДИНОЧ.", 
					}, 
					TT = { 
						enUS = "ToolTip SINGLE", 
						ruRU = "ТулТипа ОДИНОЧ.", 
					}, 
					M = {
						Custom = [[/run Toggle()]],
					},
				},
			},
			{
				{	
					E = "Label",
					L = { 
						enUS = "Label", 
						ruRU = "Метка", 
					}, 
				},							
				{
					E = "Slider", 													
					H = 20,
					MIN = -1, 
					MAX = 100,							
					DB = "Slidertoggle",
					DBV = 40,
					L = { 
						enUS = "Slider Example", 
						ruRU = "Ползунок Пример", 
					}, 
					TT = { 
						enUS = "Slider ToolTip", 
						ruRU = "Ползунок ТулТип", 
					}, 
					M = {
					},
				},
			},
			{
				{
					E = "LayoutSpace",
				},	
				{
					E = "Slider", 													
					H = 20,
					MIN = -1, 
					MAX = 100,							
					DB = "Sliderwithspace",
					DBV = 10,
					L = { 
						enUS = "Slider Example2", 
						ruRU = "Ползунок Пример2", 
					}, 
					TT = { 
						enUS = "Slider ToolTip222", 
						ruRU = "Ползунок ТулТип222", 
					}, 
					M = {
					},
				},							
			},
			{
				{
					E = "Checkbox", 
					DB = "ASDASD",
					DBV = true,
					L = { 
						enUS = "asdasd", 
						ruRU = "asdfsdfg", 
					},
				},
			},
		},
	},
	[7] = {
		[260] = { 
			["kick"] = { Enabled = true, Key = "POWS" },
		},
	},
}
--[[ Action.Data.ProfileUI will create this Action.Data.ProfileDB, you can set Action.Data.ProfileDB like this instead point DB and DBV actually, but if both up then Action.Data.ProfileUI will overwrite Action.Data.ProfileDB
Action.Data.ProfileDB = {
	[2] = {
		[260] = { 
			Feint = true, 
			Shiv = false, 
			CKnoMacro = true,
			ShortCK = true,
			DropdownMult = {
				[1] = true,
				[2] = true,
				[3] = true,
			},
			DropdownSingle = "Simcraft",
			Slidertoggle = 40,
			Sliderwithspace = 10,
			Personalskhf = "unkas",
		},
	},
}
]]
Action[260] = {
	POWS = Action.Create({ Type = "Spell", ID = 17 }),
	POWS_Rank2 = Action.Create({ Type = "SpellSingleColor", ID = 17, Color = "BLUE", Desc = "Rank2" }),
	FrostBolt = Action.Create({ Type = "Spell", ID = 116, Desc = "DMG" }),
	Guard = Action.Create({ Type = "Spell", ID = 115295 }),
	TrinketTest = Action.Create({ Type = "Trinket", ID = 122530 }),
	TrinketTest2 = Action.Create({ Type = "Trinket", ID = 159611 }),	
	PotionTest = Action.Create({ Type = "Potion", ID = 142117 }),  
	PotionTest2 = Action.Create({ Type = "Potion", ID = 127835 }),  	
	PetKick = Action.Create({ Type = "Spell", ID = 47482, Color = "RED", Desc = "RED" }),                                          	 
	Sprint = Action.Create({ Type = "SpellSingleColor", ID = 2983, QueueForbidden = true, Desc = "Test", Color = "LIGHT BLUE", Texture = 17 }),
	NimbleBrew = Action.Create({ Type = "Item", ID = 137648, Color = "RED" }),
}
local A = setmetatable(Action[260], { __index = Action })
local function Test() 
	return true
end 
local TestVar = 5
A[260][3] = function(icon)                          
	if A.POWS:IsReady("target") and E.SpellUsable(A.POWS.ID) and E.SpellInRange("target", A.POWS.ID) and Test() and TestVar == 5 then 																			                                           	
        return A.POWS:Show(icon)        		
    end 																
end 
-- /tmw and apply code for always shown frame by "Conditions" > "LUA (Advanced)"
-- Once created there will reference for all specs but work exactly with which is active
-- Action.Rotation(thisobj)