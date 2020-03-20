--- 
local DateTime 														= "20.03.2020"
---
local TMW 															= TMW
local Env 															= TMW.CNDT.Env
local strlowerCache  												= TMW.strlowerCache
local TMWdb

local StdUi 														= LibStub("StdUi"):NewInstance()
local LibDBIcon	 													= LibStub("LibDBIcon-1.0")
local LSM 															= LibStub("LibSharedMedia-3.0")
	  LSM:Register(LSM.MediaType.STATUSBAR, "Flat", [[Interface\Addons\TheAction\Media\Flat]])

local pcall, ipairs, pairs, type, assert, error, setfenv, tostringall, tostring, tonumber, getmetatable, setmetatable, loadstring, next, select, _G, coroutine, table, math, string, hooksecurefunc, wipe, 	   safecall,    debugprofilestop = 
	  pcall, ipairs, pairs, type, assert, error, setfenv, tostringall, tostring, tonumber, getmetatable, setmetatable, loadstring, next, select, _G, coroutine, table, math, string, hooksecurefunc, wipe, TMW.safecall, _G.debugprofilestop_SAFE
	   
local tinsert														= table.insert 
local tremove														= table.remove 
local huge	 														= math.huge
local math_abs														= math.abs
local math_floor													= math.floor
local strgsub 														= string.gsub	
local strformat 													= string.format
local strjoin	 													= string.join  
local strupper 														= string.upper

local GetRealmName, GetExpansionLevel, GetNumSpecializationsForClassID, GetSpecializationInfo, GetSpecialization, GetFramerate, GetMouseFocus, GetLocale, GetBindingFromClick, GetItemSpell, GetSpellInfo, GetSpellAvailableLevel, GetNumMacros, GetMacroInfo, GetMacroIcons = 
	  GetRealmName, GetExpansionLevel, GetNumSpecializationsForClassID, GetSpecializationInfo, GetSpecialization, GetFramerate, GetMouseFocus, GetLocale, GetBindingFromClick, GetItemSpell, GetSpellInfo, GetSpellAvailableLevel, GetNumMacros, GetMacroInfo, GetMacroIcons
	  
local UnitName, UnitClass, UnitRace, UnitLevel, UnitExists, UnitIsUnit, UnitGUID, UnitAura, UnitPower = 
	  UnitName, UnitClass, UnitRace, UnitLevel, UnitExists, UnitIsUnit, UnitGUID, UnitAura, UnitPower	  
	    
local GameLocale 													= GetLocale()	
-- Mexico is used esES
if GameLocale == "esMX" then 
	GameLocale = "esES"
end 
local DEFAULT_CHAT_FRAME											= _G.DEFAULT_CHAT_FRAME
local UIParent														= _G.UIParent
local C_UI															= _G.C_UI
local Spell															= _G.Spell 	  								-- ObjectAPI/Spell.lua
local FindSpellBookSlotBySpellID 									= _G.FindSpellBookSlotBySpellID	   
local AzeriteEssence 												= _G.C_AzeriteEssence
local CreateFrame 													= _G.CreateFrame	
local PlaySound														= _G.PlaySound	  
local InCombatLockdown												= _G.InCombatLockdown
local CombatLogGetCurrentEventInfo									= _G.CombatLogGetCurrentEventInfo
local IsControlKeyDown												= _G.IsControlKeyDown
local CopyTable														= _G.CopyTable

_G.Action 															= LibStub("AceAddon-3.0"):NewAddon("Action", "AceEvent-3.0") 
Env.Action 															= _G.Action
local Action 														= _G.Action 
Action.PlayerRace 													= select(2, UnitRace("player"))
Action.PlayerClassName, Action.PlayerClass, Action.PlayerClassID  	= UnitClass("player")

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, round

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------
-- Note: L (@table localized with current language of interface), CL (@string current selected language of interface), GameLocale (@string game language default), Localization (@table clear with all locales)
local CL, L = "enUS"
local Localization = {
	[GameLocale] = {},
	enUS = {			
		NOSUPPORT = "this profile is not supported ActionUI yet",	
		DEBUG = "|cffff0000[Debug] Error Identification: |r",			
		ISNOTFOUND = "is not found!",			
		CREATED = "created",
		YES = "Yes",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selected",
		RESET = "Reset",
		RESETED = "Reseted",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro already existed!|r",
		MACROLIMIT = "|cffff0000Can't create macro, you reached limit. You need to delete at least one macro!|r",	
		MACROINCOMBAT = "|cffff0000Can't create macro in combat. You need to leave combat!|r",
		GLOBALAPI = "API Global: ",
		RESIZE = "Resize",
		RESIZE_TOOLTIP = "Click-and-drag to resize",
		CLOSE = "Close",
		APPLY = "Apply",
		SLASH = {
			LIST = "List of slash commands:",
			OPENCONFIGMENU = "shows config menu",
			HELP = "shows help info",
			QUEUEHOWTO = "macro (toggle) for sequence system (Queue), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			QUEUEEXAMPLE = "example of Queue usage",
			BLOCKHOWTO = "macro (toggle) for disable|enable any actions (Blocker), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			BLOCKEXAMPLE = "example of Blocker usage",
			RIGHTCLICKGUIDANCE = "Most elements are left and right click-able. Right click will create macro toggle so you can consider the above suggestion",				
			INTERFACEGUIDANCE = "UI explains:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] relative for CURRENT selected specialization",
			INTERFACEGUIDANCEALLSPECS = "[All specs] relative for your ALL available character specializations",
			INTERFACEGUIDANCEGLOBAL = "[Global] relative for ALL your account, ALL characters, ALL specializations",
			ATTENTION = "|cffff0000PAY ATTENTION|r functional of Action available only for profiles released after 31.05.2019. The old profile will be updated for this system in future",		
			TOTOGGLEBURST = "to toggle Burst Mode",
			TOTOGGLEMODE = "to toggle PvP / PvE",
			TOTOGGLEAOE = "to toggle AoE",
		},
		TAB = {
			RESETBUTTON = "Reset settings",
			RESETQUESTION = "Are you sure?",
			SAVEACTIONS = "Save Actions settings",
			SAVEINTERRUPT = "Save Interrupt Lists",
			SAVEDISPEL = "Save Auras Lists",
			SAVEMOUSE = "Save Cursor Lists",
			SAVEMSG = "Save MSG Lists",
			LUAWINDOW = "LUA Configure",
			LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need to use Action. for anything that have it\n\nIf you want to remove already default code you will need to write 'return true' without quotes instead of remove them all",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Close LUA Configuration before add",
			FIXLUABEFOREADD = "You need to fix errors in LUA Configuration before to add",
			RIGHTCLICKCREATEMACRO = "RightClick: Create macro",
			NOTHING = "Profile has no configuration for this tab",
			HOW = "Apply:",
			HOWTOOLTIP = "Global: All account, all characters and all specializations",
			GLOBAL = "Global",
			ALLSPECS = "To all specializations of the character",
			THISSPEC = "To the current specialization of the character",			
			KEY = "Key:",
			CONFIGPANEL = "'Add' Configuration",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Each spec] Primary",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Forcing a profile to switch to another mode\n(especially useful when the War Mode is ON)\n\nRightClick: Create macro", 
				PVEPVPRESETTOOLTIP = "Reset manual toggle to auto select",
				CHANGELANGUAGE = "Switch language",
				CHARACTERSECTION = "Character Section",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "If the target is empty, but you are in combat, it will return the nearest enemy\nThe switcher works in the same way if the target has immunity in PvP\n\nRightClick: Create macro",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Heart of Azeroth",
				RACIAL = "Racial spell",
				STOPCAST = "Stop casting",
				SYSTEMSECTION = "System Section",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ATTENTION: This option causes delay of 0.3s + current spinning gcd\nif unit being checked it is located in a lose (for example, behind a box at arena)\nYou must also enable the same setting in Advanced Settings\nThis option blacklists unit which in a lose and\nstops providing actions to it for N seconds\n\nRightClick: Create macro",
				HEALINGENGINEPETS = "HealingEngine pets",
				HEALINGENGINEPETSTOOLTIP = "Include in target select player's pets and calculate for heal them\n\nRightClick: Create macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Will stop harmful damage on enemies\nIf they have CC such as Polymorph\nIt doesn't cancel auto attack!\n\nRightClick: Create macro",
				ALL = "All",
				RAID = "Raid",
				TANK = "Only Tanks",
				DAMAGER = "Only Damage Dealers",
				HEALER = "Only Healers",
				HEALINGENGINETOOLTIP = "This option relative for unit selection on healers\nAll: Everyone member\nRaid: Everyone member without tanks\n\nRightClick: Create macro\nIf you would like set fix toggle state use argument in (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",				
				DBM = "DBM Timers",
				DBMTOOLTIP = "Tracking pull timers and some specific events such as trash incoming.\nThis feature is not availble for all the profiles!\n\nRightClick: Create macro",
				FPS = "FPS Optimization",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Increases frames per second by increasing the dynamic dependency\nframes of the refresh cycle (call) of the rotation cycle\n\nYou can also manually set the interval following a simple rule:\nThe larger slider then more FPS, but worse rotation update\nToo high value can cause unpredictable behavior!\n\nRightClick: Create macro",					
				PVPSECTION = "PvP Section",
				REFOCUS = "Return previous saved @focus\n(arena1-3 units only)\nIt recommended against invisibility classes\n\nRightClick: Create macro",
				RETARGET = "Return previous saved @target\n(arena1-3 units only)\nIt recommended against hunters with 'Feign Death' and any unforeseen target drops\n\nRightClick: Create macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Burst Mode",
				BURSTTOOLTIP = "Everything - On cooldown\nAuto - Boss or Players\nOff - Disabled\n\nRightClick: Create macro\nIf you would like set fix toggle state use argument in (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Abyssal Healing Potion",
				HEALTHSTONETOOLTIP = "Set percent health (HP)\n\nRightClick: Create macro",
				COLORTITLE = "Color Picker",
				COLORUSE = "Use custom color",
				COLORUSETOOLTIP = "Switcher between default and custom colors",
				COLORELEMENT = "Element",
				COLOROPTION = "Option",
				COLORPICKER = "Picker",
				COLORPICKERTOOLTIP = "Click to open setup window for your selected 'Element' > 'Option'\nRight mouse button to move opened window",
				FONT = "Font",
				NORMAL = "Normal",
				DISABLED = "Disabled",
				HEADER = "Header",
				SUBTITLE = "Subtitle",
				TOOLTIP = "Tooltip",
				BACKDROP = "Backdrop",
				PANEL = "Panel",
				SLIDER = "Slider",
				HIGHLIGHT = "Highlight",
				BUTTON = "Button",
				BUTTONDISABLED = "Button Disabled",
				BORDER = "Border",
				BORDERDISABLED = "Border Disabled",	
				PROGRESSBAR = "Progress Bar",
				COLOR = "Color",
				BLANK = "Blank",
				SELECTTHEME = "Select Ready Theme",
				THEMEHOLDER = "choose theme",
				BLOODYBLUE = "Bloody Blue",
				PAUSECHECKS = "[All specs] Rotation doesn't work if:",
				VEHICLE = "InVehicle",
				VEHICLETOOLTIP = "Example: Catapult, Firing gun",
				DEADOFGHOSTPLAYER = "You're dead",
				DEADOFGHOSTTARGET = "Target is dead",
				DEADOFGHOSTTARGETTOOLTIP = "Exception enemy hunter if he selected as primary target",
				MOUNT = "IsMounted",
				COMBAT = "Out of combat", 
				COMBATTOOLTIP = "If You and Your target out of combat. Invisible is exception\n(while stealthed this condition will skip)",
				SPELLISTARGETING = "SpellIsTargeting",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heroic Leap, Freezing Trap",
				LOOTFRAME = "LootFrame",
				EATORDRINK = "Is Eating or Drinking",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Hide display rotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Hides the group, which is usually at the\ncenter bottom of the screen",
				DISABLEBLACKBACKGROUND = "Hide black background", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Hides the black background in the upper left corner\nATTENTION: This can cause unpredictable behavior!",
				DISABLEPRINT = "Hide print",
				DISABLEPRINTTOOLTIP = "Hides chat notifications from everything\nATTENTION: This will also hide [Debug] Error Identification!",
				DISABLEMINIMAP = "Hide icon on minimap",
				DISABLEMINIMAPTOOLTIP = "Hides minimap icon of this UI",
				DISABLEPORTRAITS = "Hide class portrait",
				DISABLEROTATIONMODES = "Hide rotation modes",
				DISABLESOUNDS = "Disable sounds",
				HIDEONSCREENSHOT = "Hide on screenshot",
				HIDEONSCREENSHOTTOOLTIP = "During the screenshot hides all TellMeWhen\nand Action frames, and then shows them back",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Queue",
				ENABLED = "Enabled",
				NAME = "Name",
				DESC = "Note",
				ICON = "Icon",
				SETBLOCKER = "Set\nBlocker",
				SETBLOCKERTOOLTIP = "This will block selected action in rotation\nIt will never use it\n\nRightClick: Create macro",
				SETQUEUE = "Set\nQueue",
				SETQUEUETOOLTIP = "This will queue action in rotation\nIt will use it as soon as it possible\n\nRightClick: Create macro\nYou can pass additional conditions in created macro for queue\nSuch as on which unit to use (UnitID is key), example: { Priority = 1, UnitID = 'player' }\nYou can find acceptable keys with description in the function 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blocked: |r",
				UNBLOCKED = "|cff00ff00Unblocked: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Queued Total: ",
				KEYTOOLTIP = "Use this key in MSG tab",
				ISFORBIDDENFORBLOCK = "is forbidden for blocker!",
				ISFORBIDDENFORQUEUE = "is forbidden for queue!",
				ISQUEUEDALREADY = "is already existing in queue!",
				QUEUED = "|cff00ff00Queued: |r",
				QUEUEREMOVED = "|cffff0000Removed from queue: |r",
				QUEUEPRIORITY = " has priority #",
				QUEUEBLOCKED = "|cffff0000can't be queued because SetBlocker blocked it!|r",
				SELECTIONERROR = "|cffff0000You didn't selected row!|r",
				AUTOHIDDEN = "[All specs] AutoHide unavailable actions",
				AUTOHIDDENTOOLTIP = "Makes Scroll Table smaller and clear by visual hide\nFor example character class has few racials but can use one, this option will hide others racials\nJust for comfort view",
				CHECKSPELLLVL = "[All specs] Check required spell level",
				CHECKSPELLLVLTOOLTIP = "All spells which is not available by character level will be blocked\nThey will be updated every time with level up",
				CHECKSPELLLVLERROR = "Already initialized!",
				CHECKSPELLLVLERRORMAXLVL = "You're at MAX possible level!",
				CHECKSPELLLVLMACRONAME = "CheckSpellLevel",
				LUAAPPLIED = "LUA code was applied to ",
				LUAREMOVED = "LUA was removed from ",
			},
			[4] = {
				HEADBUTTON = "Interrupts",	
				HEADTITLE = "Profile Interrupts",					
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				CONFIGPANEL = "'Add Interrupt' Configuration",
				INTERRUPTFRONTSTRINGTITLE = "Select list:",
				INTERRUPTTOOLTIP = "[Main] for units @target/@mouseover/@targettarget\n[Heal] for units @arena1-3 (healing)\n[PvP] for units @arena1-3 (crowdcontrol)\n\nYou can set different timings for [Heal] and [PvP] (not in this UI)",
				INPUTBOXTITLE = "Write spell:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): clear text and remove focus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Search by name or ID",
				TARGETMOUSEOVERLIST = "[Main] List",
				TARGETMOUSEOVERLISTTOOLTIP = "Unchecked: will interrupt ANY cast randomly\nChecked: will interrupt only specified custom list for @target/@mouseover/@targettarget\nNote: in PvP will fixed interrupt that list if enabled, otherwise only healers if they will die in less than 3-4 sec!\n\n@mouseover/@targettarget are optional and depend on toggles in spec tab\n\nRightClick: Create macro",
				KICKTARGETMOUSEOVER = "[Main] Interrupts\nEnabled",					
				KICKTARGETMOUSEOVERTOOLTIP = "Unchecked: @target/@mouseover unit interrupts don't work\nChecked: @target/@mouseover unit interrupts will work\n\nRightClick: Create macro",					
				KICKHEALONLYHEALER = "[Heal] Only healers",					
				KICKHEALONLYHEALERTOOLTIP = "Unchecked: list will valid for any enemy unit specialization\n(e.g. Ench, Elem, SP, Retri)\nChecked: list will valid only for enemy healers\n\nRightClick: Create macro",
				KICKHEAL = "[Heal] List",
				KICKHEALPRINT = "[Heal] List of Interrupts",
				KICKHEALTOOLTIP = "Unchecked: @arena1-3 [Heal] custom list don't work\nChecked: @arena1-3 [Heal] custom list will work\n\nRightClick: Create macro",
				KICKPVP = "[PvP] List",
				KICKPVPPRINT = "[PvP] List of Interrupts",
				KICKPVPTOOLTIP = "Unchecked: @arena1-3 [PvP] custom list don't work\nChecked: @arena1-3 [PvP] custom list will work\n\nRightClick: Create macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Checked: will interrupt only accordingly to logic established in profile lua configuration. Example:\n1) Chain control on your healer\n2) Someone friendly (or you) has Burst buffs >4 sec\n3) Someone will die in less than 8 sec\n4) Your (or @target) HP going to execute phase\nUnchecked: will interrupt this list always without any kind of logic\n\nNote: Cause high CPU demand\nRightClick: Create macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Add Interrupt",					
				ADDERROR = "|cffff0000You didn't specify anything in 'Write spell' or spell is not found!|r",
				ADDTOOLTIP = "Add spell from 'Write spell'\neditbox to current selected list",
				REMOVE = "Remove Interrupt",
				REMOVETOOLTIP = "Remove selected spell in scroll table row from the current list",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec] Checkbox Configuration",
				USEDISPEL = "Use Dispel",
				USEPURGE = "Use Purge",
				USEEXPELENRAGE = "Expel Enrage",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Category:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel diseases",
				CURSE = "Dispel curses",
				MAGIC = "Dispel magic",
				MAGICMOVEMENT = "Dispel magic slow/roots",
				PURGEFRIENDLY = "Purge friendly",
				PURGEHIGH = "Purge enemy (high priority)",
				PURGELOW = "Purge enemy (low priority)",
				ENRAGE = "Expel Enrage",	
				BLESSINGOFPROTECTION = "Blessing of Protection",
				BLESSINGOFFREEDOM = "Blessing of Freedom",
				BLESSINGOFSACRIFICE = "Blessing of Sacrifice",
				BLESSINGOFSANCTUARY = "Blessing of Sanctuary",
				ROLE = "Role",
				ID = "ID",
				NAME = "Name",
				DURATION = "Duration\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icon",					
				ROLETOOLTIP = "Your role to use it",
				DURATIONTOOLTIP = "React on aura if the duration of the aura is longer (>) of the specified seconds\nIMPORTANT: Auras without duration such as 'Divine favor'\n(Light Paladin) must be 0. This means that the aura is present!",
				STACKSTOOLTIP = "React on aura if it has more or equal (>=) specified stacks",									
				BYID = "Use ID\ninstead Name",
				BYIDTOOLTIP = "By ID must be checking ALL spells\nwhich have same name, but assume different auras\nsuch as 'Unstable Affliction'",					
				CANSTEALORPURGE = "Only if can\nsteal or purge",					
				ONLYBEAR = "Only if unit\nin 'Bear form'",									
				CONFIGPANEL = "'Add Aura' Configuration",
				ANY = "Any",
				HEALER = "Healer",
				DAMAGER = "Tank|Damager",
				ADD = "Add Aura",					
				REMOVE = "Remove Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Mouse Interaction",
				USETITLE = "[Each spec] Buttons Config:",
				USELEFT = "Use Left click",
				USELEFTTOOLTIP = "This using macro /target mouseover which is not itself click!\n\nRightClick: Create macro",
				USERIGHT = "Use Right click",
				LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nIf you use LUA in Category 'GameToolTip' then thisunit is not valid\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need use Action. for anything that have it\n\nIf you want to remove already default code you will need write 'return true' without quotes instead of remove all",							
				BUTTON = "Click",
				NAME = "Name",
				LEFT = "Left click",
				RIGHT = "Right click",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "If enabled then will check @mouseover on type 'Totem' for given name\nAlso prevent click in situation if your @target already has there any totem",				
				INPUTTITLE = "Enter the name of the object (localized!)", 
				INPUT = "This entry is case non sensitive",
				ADD = "Add",
				REMOVE = "Remove",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "spirit link totem",
				HEALINGTIDETOTEM = "healing tide totem",
				CAPACITORTOTEM = "capacitor totem",					
				SKYFURYTOTEM = "skyfury totem",					
				ANCESTRALPROTECTIONTOTEM = "ancestral protection totem",					
				COUNTERSTRIKETOTEM = "counterstrike totem",
				EXPLOSIVES = "explosives",
				-- Optional totems
				TREMORTOTEM = "tremor totem",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "wind rush totem",
				EARTHBINDTOTEM = "earthbind totem",
				-- GameToolTips
				ALLIANCEFLAG = "alliance flag",
				HORDEFLAG = "horde flag",
				NETHERSTORMFLAG = "netherstorm flag",
				ORBOFPOWER = "orb of power",
			},
			[7] = {
				HEADTITLE = "Message System",
				USETITLE = "[Each spec]",
				MSG = "MSG System",
				MSGTOOLTIP = "Checked: working\nUnchecked: not working\n\nRightClick: Create macro",
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Preventing by repeated message deletion from queue system\nE.g. possible spam macro without being removed\n\nRightClick: Create macro",
				MACRO = "Macro for your group:",
				MACROTOOLTIP = "This is what should be sent to the group chat to trigger the assigned action on the specified key\nTo address the action to a specific unit, add them to the macro or leave it as it is for the appointment in Single/AoE rotation\nSupported: raid1-40, party1-2, player, arena1-3\nONLY ONE UNIT FOR ONE MESSAGE!\n\nYour companions can use macros as well, but be careful, they must be loyal to this!\nDON'T LET THE MACRO TO UNIMINANCES AND PEOPLE NOT IN THE THEME!",
				KEY = "Key",
				KEYERROR = "You did not specify a key!",
				KEYERRORNOEXIST = "key does not exist!",
				KEYTOOLTIP = "You must specify a key to bind the action\nYou can extract the key in the 'Actions' tab",
				MATCHERROR = "this given name already matches, use another!",				
				SOURCE = "The name of the person who said",					
				WHOSAID = "Who said",
				SOURCETOOLTIP = "This is optional. You can leave it blank (recommended)\nIf you want to configure it, the name must be exactly the same as in the chat group",
				NAME = "Contains a message",
				ICON = "Icon",
				INPUT = "Enter a phrase for the system message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "You have not entered a phrase!",
				INPUTTOOLTIP = "The phrase will be triggered on any match in the group chat (/party)\nIt's not case sensitive\nContains patterns, this means that a phrase written by someone with the combination of the words raid, party, arena, party or player\nadaptates the action to the desired meta slot\nYou don’t need to set the listed patterns here, they are used as an addition to the macro\nIf the pattern is not found, then slots for Single and AoE rotations will be used",				
			},
		},
	},
	ruRU = {
		NOSUPPORT = "данный профиль еще не поддерживает ActionUI",
		DEBUG = "|cffff0000[Debug] Идентификатор ошибки: |r",			
		ISNOTFOUND = "не найдено!",				
		CREATED = "создан",
		YES = "Да",
		NO = "Нет",	
		TOGGLEIT = "Переключить",
		SELECTED = "Выбрано",
		RESET = "Сброс",
		RESETED = "Сброшено",
		MACRO = "Макрос",
		MACROEXISTED = "|cffff0000Макрос уже существует!|r",
		MACROLIMIT = "|cffff0000Не удается создать макрос, вы достигли лимита. Удалите хотя бы один макрос!|r",
		MACROINCOMBAT = "|cffff0000Не удается создать макрос в бою. Вы должны выйти из боя!|r",
		GLOBALAPI = "API Глобальное: ",	
		RESIZE = "Изменить размер",
		RESIZE_TOOLTIP = "Чтобы изменить размер, нажмите и тащите",	
		CLOSE = "Закрыть",
		APPLY = "Применить",
		SLASH = {
			LIST = "Список слеш команд:",
			OPENCONFIGMENU = "открыть конфиг меню",
			HELP = "помощь и информация",
			QUEUEHOWTO = "макрос (переключатель) для системы очередности (Очередь), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			QUEUEEXAMPLE = "пример использования Очереди",
			BLOCKHOWTO = "макрос (переключатель) для отключения|включения любых действий (Блокировка), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			BLOCKEXAMPLE = "пример использования Блокировки",
			RIGHTCLICKGUIDANCE = "Большинство элементов кликабельны левой и правой кнопкой мышки. Правая кнопка мышки создаст макрос, так что вы можете не брать во внимание выше изложенную подсказку",						
			INTERFACEGUIDANCE = "UI пояснения:",
			INTERFACEGUIDANCEEACHSPEC = "[Каждый спек] относится к ТЕКУЩЕЙ выбранной специализации",
			INTERFACEGUIDANCEALLSPECS = "[Все спеки] относится ко ВСЕМ доступным на персонаже специализациям",
			INTERFACEGUIDANCEGLOBAL = "[Глобально] относится к ВСЕМУ вашему аккаунту, к ВСЕМ персонажам, к ВСЕМ специализациям",
			ATTENTION = "|cffff0000ОБРАТИТЕ ВНИМАНИЕ|r функционал Action доступен лишь для профилей вышедших после 31.05.2019. Предыдущие профиля будут обновлены для этой системы в будущем",		
			TOTOGGLEBURST = "чтобы переключить Режим Бурстов",
			TOTOGGLEMODE = "чтобы переключить PvP / PvE",
			TOTOGGLEAOE = "чтобы переключить AoE",
		},
		TAB = {
			RESETBUTTON = "Сбросить настройки",
			RESETQUESTION = "Вы точно уверены?",
			SAVEACTIONS = "Сохранить настройки Действий",
			SAVEINTERRUPT = "Сохранить Списки Прерываний",
			SAVEDISPEL = "Сохранить Списки Аур",
			SAVEMOUSE = "Сохранить Списки Курсора",
			SAVEMSG = "Сохранить Списки MSG",
			LUAWINDOW = "LUA Конфигурация",
			LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true' без кавычек,\nвместо простого удаления",	
			BRACKETMATCH = "Закрывать Скобки",
			CLOSELUABEFOREADD = "Закройте LUA Конфигурацию прежде чем добавлять",
			FIXLUABEFOREADD = "Исправьте ошибки в LUA Конфигурации прежде чем добавлять",
			RIGHTCLICKCREATEMACRO = "Правая кнопка мышки: Создать макрос",
			NOTHING = "Профиль не имеет конфигурации для этой вкладки",
			HOW = "Применить:",
			HOWTOOLTIP = "Глобально: Весь аккаунт, все персонажи и все спеки",
			GLOBAL = "Глобально",
			ALLSPECS = "Ко всем специализациям персонажа",
			THISSPEC = "К текущей специализации персонажа",			
			KEY = "Ключ:",	
			CONFIGPANEL = "'Добавить' Конфигурация",
			[1] = {
				HEADBUTTON = "Общее",
				HEADTITLE = "[Каждый спек] Основное",					
				PVEPVPTOGGLE = "PvE / PvP Ручной Переключатель",
				PVEPVPTOGGLETOOLTIP = "Принудительно переключить профиль в другой режим\n(особенно полезно при включенном Режиме Войны)\n\nПравая кнопка мышки: Создать макрос", 
				PVEPVPRESETTOOLTIP = "Сброс ручного переключателя в автоматический выбор",
				CHANGELANGUAGE = "Смена языка",
				CHARACTERSECTION = "Секция Персонажа",
				AUTOTARGET = "Авто Цель",
				AUTOTARGETTOOLTIP = "Если цель пуста, но вы в бою, то вернет ближайшего противника в цель\nАналогично работает свитчер если в PvP цель имеет иммунитет\n\nПравая кнопка мышки: Создать макрос",					
				POTION = "Зелье",
				HEARTOFAZEROTH = "Сердце Азерота",
				RACIAL = "Расовая способность",
				STOPCAST = "Стоп кастить",
				SYSTEMSECTION = "Секция Систем",
				LOSSYSTEM = "LOS Система",
				LOSSYSTEMTOOLTIP = "ВНИМАНИЕ: Эта опция вызывает задержку 0.3сек + тек. крутящийся гкд\nесли проверяемый юнит находится в лосе (например за столбом на арене)\nВы также должны включить такую же настройку в Advanced Settings\nДанная опция заносит в черный список проверяемого юнита\nи перестает на N секунд предоставлять к нему действия если юнит в лосе\n\nПравая кнопка мышки: Создать макрос",
				HEALINGENGINEPETS = "HealingEngine питомцы",
				HEALINGENGINEPETSTOOLTIP = "Включить в выбор цели питомцев игроков и калькулировать исцеление на них\n\nПравая кнопка мышки: Создать макрос",
				STOPATBREAKABLE = "Стоп урон на ломающемся контроле",
				STOPATBREAKABLETOOLTIP = "Остановит вредоносный урон по врагам\nЕсли у них есть CC, например, Превращение\nЭто не отменяет автоатаку!\n\nПравая кнопка мышки: Создать макрос",
				ALL = "Все",
				RAID = "Рейд",
				TANK = "Только Танки",
				DAMAGER = "Только Дамагеры",
				HEALER = "Только Хилеры",					
				HEALINGENGINETOOLTIP = "Эта опция отвечает за выбор участников группы или рейда если вы играете хилером\nВсе: Каждый участник\nРейд: Каждый участник исключая танков\n\nПравая кнопка мышки: Создать макрос\nЕсли вы предпочитаете фиксированное состояние, то используйте аргумент (АРГУМЕНТ): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",				
				DBM = "DBM Таймеры",
				DBMTOOLTIP = "Отслеживает пулл таймер и некоторые спец. события такие как 'след.треш'.\nЭта опция доступна не для всех профилей!\n\nПравая кнопка мышки: Создать макрос",
				FPS = "FPS Оптимизация",
				FPSSEC = " (сек)",
				FPSTOOLTIP = "AUTO: Повышение кадров в секунду за счет увеличения в динамической зависимости\nкадров интервала обновления (вызова) цикла ротации\n\nВы также можете вручную задать интервал следуя простому правилу:\nЧем больше ползунок, тем больше кадров, но хуже обновление ротации\nСлишком высокое значение может вызвать непредсказуемое поведение!\n\nПравая кнопка мышки: Создать макрос",					
				PVPSECTION = "Секция PvP",
				REFOCUS = "Возвращать предыдущий сохраненный @focus (arena1-3 юниты только)\nРекомендуется против классов с невидимостью\n\nПравая кнопка мышки: Создать макрос",
				RETARGET = "Возвращать предыдущий сохраненный @target (arena1-3 юниты только)\nРекомендуется против Охотников с 'Притвориться мертвым'\nи(или) при любых непредвиденных сбросов цели\n\nПравая кнопка мышки: Создать макрос",
				TRINKETS = "Аксессуары",
				TRINKET = "Аксессуар",
				BURST = "Режим Бурстов",
				BURSTTOOLTIP = "Everything - По доступности способности\nAuto - Босс или Игрок\nOff - Выключено\n\nПравая кнопка мышки: Создать макрос\nЕсли вы предпочитаете фиксированное состояние, то\nиспользуйте аргумент (АРГУМЕНТ): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Камень здоровья | Глуб-вод. леч. зелье",
				HEALTHSTONETOOLTIP = "Выставить процент своего здоровья при котором использовать\n\nПравая кнопка мышки: Создать макрос",
				COLORTITLE = "Палитра Цветов",
				COLORUSE = "Использовать пользовательский цвет",
				COLORUSETOOLTIP = "Переключатель между стандартными и пользовательскими цветами",
				COLORELEMENT = "Элемент",
				COLOROPTION = "Опция",
				COLORPICKER = "Выбиратель цвета",
				COLORPICKERTOOLTIP = "Нажмите, чтобы открыть окно настройки для выбранного 'Элемент' > 'Параметр'\nПравая кнопка мыши, чтобы переместить открытое окно",
				FONT = "Шрифт",
				NORMAL = "Нормальный",
				DISABLED = "Отключенный",
				HEADER = "Заголовок",
				SUBTITLE = "Подзаголовок",
				TOOLTIP = "Подсказка",
				BACKDROP = "Фон",
				PANEL = "Панель",
				SLIDER = "Ползунок",
				HIGHLIGHT = "Подсветка",
				BUTTON = "Кнопка",
				BUTTONDISABLED = "Кнопка Отключенная",
				BORDER = "Бордюр",
				BORDERDISABLED = "Бордюр Отключенный",	
				PROGRESSBAR = "Индикатор",
				COLOR = "Цвет",
				BLANK = "Пустая",
				SELECTTHEME = "Выбрать Готовую Тему",
				THEMEHOLDER = "выбрать тему",
				BLOODYBLUE = "Кроваво-Синий",
				PAUSECHECKS = "[Все спеки] Ротация не работает если:",
				VEHICLE = "В спец.транспорте",
				VEHICLETOOLTIP = "Например: Катапульта, Обстреливающая пушка",
				DEADOFGHOSTPLAYER = "Вы мертвы",
				DEADOFGHOSTTARGET = "Цель мертва",
				DEADOFGHOSTTARGETTOOLTIP = "Исключение вражеский Охотник если выбран в качестве цели",
				MOUNT = "Вы на\nтранспорте",
				COMBAT = "Не в бою", 
				COMBATTOOLTIP = "Если Вы и Ваша цель не в бою. Исключение незаметность\n(будучи в скрытости это условие не работает)",
				SPELLISTARGETING = "Курсор ожидает клик",
				SPELLISTARGETINGTOOLTIP = "Например: Снежная Буря, Героический прыжок, Замораживающая ловушка",
				LOOTFRAME = "Открыто окно добычи\n(лута)",		
				EATORDRINK = "Вы Пьете или Едите",
				MISC = "Разное:",
				DISABLEROTATIONDISPLAY = "Скрыть отображение\nротации",
				DISABLEROTATIONDISPLAYTOOLTIP = "Скрывает группу, которая обычно в\nцентральной нижней части экрана",
				DISABLEBLACKBACKGROUND = "Скрыть черный фон", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Скрывает черный фон в левом верхнем углу\nВНИМАНИЕ: Это может вызвать непредсказуемое поведение!",
				DISABLEPRINT = "Скрыть печать",
				DISABLEPRINTTOOLTIP = "Скрывает уведомления этого UI в чате\nВНИМАНИЕ: Это также скрывает [Debug] Идентификатор ошибки!",
				DISABLEMINIMAP = "Скрыть значок на миникарте",
				DISABLEMINIMAPTOOLTIP = "Скрывает значок этого UI",
				DISABLEPORTRAITS = "Скрыть классовый портрет",
				DISABLEROTATIONMODES = "Скрыть режимы ротации",
				DISABLESOUNDS = "Отключить звуки",
				HIDEONSCREENSHOT = "Скрывать на скриншоте",
				HIDEONSCREENSHOTTOOLTIP = "Во время скриншота прячет все фреймы TellMeWhen\nи Action, а после показывает их обратно",
			},			
			[3] = {
				HEADBUTTON = "Действия",
				HEADTITLE = "Блокировка | Очередь",
				ENABLED = "Включено",
				NAME = "Название",
				DESC = "Заметка",
				ICON = "Значок",
				SETBLOCKER = "Установить\nБлокировку",
				SETBLOCKERTOOLTIP = "Это заблокирует выбранное действие в ротации\nЭто никогда не будет использовано\n\nПравая кнопка мыши: Создать макрос", 
				SETQUEUE = "Установить\nОчередь",
				SETQUEUETOOLTIP = "Это поставит действие в очередь ротации\nЭто использует действие по первой доступности\n\nПравая кнопка мыши: Создать макрос\nВы можете передать дополнительные условия в созданном макросе для очереди\nТакие как на какой цели использовать (UnitID является ключом), например: { Priority = 1, UnitID = 'player' }\nВы можете найти ключи с описанием в функции 'Action:SetQueue' (Action.lua)", 
				BLOCKED = "|cffff0000Заблокировано: |r",
				UNBLOCKED = "|cff00ff00Разблокировано: |r",
				KEY = "[Ключ: ",
				KEYTOTAL = "[Суммарно Очереди: ",
				KEYTOOLTIP = "Используйте этот ключ во вкладке MSG",
				ISFORBIDDENFORBLOCK = "запрещен для установки в блокировку!",
				ISFORBIDDENFORQUEUE = "запрещен для установки в очередь!",
				ISQUEUEDALREADY = "уже в состоит в очереди!",
				QUEUED = "|cff00ff00Установлен в очередь: |r",
				QUEUEREMOVED = "|cffff0000Удален из очереди: |r",
				QUEUEPRIORITY = " имеет приоритет #",
				QUEUEBLOCKED = "|cffff0000не может быть поставлен в очередь поскольку установлена блокировка!|r",
				SELECTIONERROR = "|cffff0000Вы не выбрали строку!|r",
				AUTOHIDDEN = "[Все спеки] АвтоСкрытие недоступных действий",
				AUTOHIDDENTOOLTIP = "Делает прокручивающейся список меньше и чистее за счет визуального скрытия\nНапример, класс персонажа имеет несколько расовых способностей, но может использовать лишь одну, эта опция скроет остальные\nПросто для удобства просмотра",
				CHECKSPELLLVL = "[Все спеки] Проверять необходимый уровень способности",
				CHECKSPELLLVLTOOLTIP = "Все способности которые не доступны по уровню персонажа будут заблокированы\nОни будут обновляться каждый раз по достижению нового уровня",					
				CHECKSPELLLVLERROR = "Уже инициализировано!",
				CHECKSPELLLVLERRORMAXLVL = "Вы на МАКСИМАЛЬНО возможном уровне!",
				CHECKSPELLLVLMACRONAME = "Проверять Уровень Способностей",
				LUAAPPLIED = "LUA код был добавлен к ",
				LUAREMOVED = "LUA код был удален из ",
			},
			[4] = {
				HEADBUTTON = "Прерывания",	
				HEADTITLE = "Прерывания Профиля",					
				ID = "ID",
				NAME = "Название",
				ICON = "Значок",
				CONFIGPANEL = "'Добавить Прерывание' Конфигурация",
				INTERRUPTFRONTSTRINGTITLE = "Выберите список:",	
				INTERRUPTTOOLTIP = "[Main] для @target/@mouseover/@targettarget\n[Heal] для @arena1-3 (исцеляющие)\n[PvP] для @arena1-3 (контроль)\n\nВы можете выставить тайминги для [Heal] и [PvP] (не в этом UI)",
				INPUTBOXTITLE = "Введите способность:",
				INPUTBOXTOOLTIP = "ESCAPE (ESC): стереть текст и убрать фокус ввода",
				SEARCH = "Поиск по имени или ID",
				INTEGERERROR = "Целочисленное переполнение при попытке ввода > 7 чисел", 
				TARGETMOUSEOVERLIST = "[Main] Список",
				TARGETMOUSEOVERLISTTOOLTIP = "НЕ включено: будет прерывать ЛЮБОЙ каст случайно\nВключено: будет прерывать только из этого списка для @target/@mouseover/@targettarget\nПримечание: в PvP принудительно будет прерывать этот список если включено, или только хилеров за 3-4 сек до смерти!\n\n@mouseover/@targettarget являются опциональными и зависят от переключателей во вкладке специализации\n\nПравая кнопка мыши: Создать макрос",					
				KICKTARGETMOUSEOVER = "[Main] Прерывания\nвключены",					
				KICKTARGETMOUSEOVERTOOLTIP = "НЕ включено: @target/@mouseover/@targetarget юнит прерывания не работают\nВключено: @target/@mouseover/@targettarget юнит прерывания будут работать\n\nПравая кнопка мыши: Создать макрос",					
				KICKHEALONLYHEALER = "[Heal] Только\nлекарей",				
				KICKHEALONLYHEALERTOOLTIP = "НЕ включено: список будет валидным для любых специализаций вражеского юнита\nНапример: Энх, Элем, Ретрик, ШП\nВключено: список будет валидным только для вражеских хилеров\n\nПравая кнопка мыши: Создать макрос",
				KICKHEAL = "[Heal] Список",
				KICKHEALPRINT = "[Heal] Список Прерываний",
				KICKHEALTOOLTIP = "НЕ включено: @arena1-3 [Heal] список не работает\nВключено: @arena1-3 [Heal] список будет работать\n\nПравая кнопка мыши: Создать макрос",						
				KICKPVP = "[PvP] Список",
				KICKPVPPRINT = "[PvP] Список Прерываний",
				KICKPVPTOOLTIP = "НЕ включено: @arena1-3 [PvP] список не работает\nВключено: @arena1-3 [PvP] список будет работать\n\nПравая кнопка мыши: Создать макрос",	
				KICKPVPONLYSMART = "[PvP] УМНЫЙ",					
				KICKPVPONLYSMARTTOOLTIP = "Включено: будет прерывать только по логике заложенной в профиле на lua конфигурации. Например:\n1) Цепочку контроля по своему лекарю\n2) Кто-либо из союзников в бурстах >4 сек\n3) Кто-либо из союзников может умереть меньше чем за 8 сек\n4) Вы (или @target) здоровье близко к смертельной фазе\nНЕ включено: будет прерывать этот список всегда без какой либо логики\n\nЗаметка: Вызывает высокое потребление CPU\nПравая кнопка мыши: Создать макрос",					
				USEKICK = "Киком",
				USECC = "СС",
				USERACIAL = "Расовой",
				ADD = "Добавить Прерывание",
				ADDERROR = "|cffff0000Вы ничего не указали в 'Введите способность'\nили способность не найдена!|r",				
				ADDTOOLTIP = "Добавить способность из поля ввода 'Введите способность' в текущий выбранный список",					
				REMOVE = "Удалить Прерывание",
				REMOVETOOLTIP = "Удалить выбранную способность в прокручивающейся таблице из текущего списка",					
			},
			[5] = { 
				HEADBUTTON = "Ауры",					
				USETITLE = "[Каждый спек] Конфигурация чекбоксов",
				USEDISPEL = "Использовать Диспел",
				USEPURGE = "Использовать Пурж",
				USEEXPELENRAGE = "Снимать Исступления",
				HEADTITLE = "[Глобально] Диспел | Пурж | Исступление",	
				MODE = "Режим:",
				CATEGORY = "Категория:",
				POISON = "Диспел ядов",
				DISEASE = "Диспел болезней",
				CURSE = "Диспел проклятий",
				MAGIC = "Диспел магического",
				MAGICMOVEMENT = "Диспел магич. замедлений/рут",
				PURGEFRIENDLY = "Пурж союзников",
				PURGEHIGH = "Пурж врагов (высокий приоритет)",
				PURGELOW = "Пурж врагов (низкий приоритет)",
				ENRAGE = "Снятие исступлений",
				BLESSINGOFPROTECTION = "Благословение защиты",
				BLESSINGOFFREEDOM = "Благословение cвободы",
				BLESSINGOFSACRIFICE = "Благословение жертвенности",
				BLESSINGOFSANCTUARY = "Благословение святилища",	
				ROLE = "Роль",
				ID = "ID",
				NAME = "Название",
				DURATION = "Длитель-\nность >",
				STACKS = "Стаки\n >=",
				ICON = "Значок",
				ROLETOOLTIP = "Ваша роль для использования этого",
				DURATIONTOOLTIP = "Реагировать если продолжительность ауры больше (>) указанных секунд\nВНИМАНИЕ: Ауры без продолжительности такие как 'Божественное одобрение'\n(Свет Паладин) должны быть 0. Это значит аура присутствует!",
				STACKSTOOLTIP = "Реагировать если кол-во ауры (стаки) больше (>=) указанных",					
				BYID = "Использовать ID\nвместо Имени",
				BYIDTOOLTIP = "По ID должны проверяться ВСЕ способности, которые имеют\nодинаковое имя, но подразумевают разные ауры.\nТакие как 'Нестабильное колдовство'",					
				CANSTEALORPURGE = "Только если можно\nукрасть или спуржить",					
				ONLYBEAR = "Только если юнит\nв 'Облике медведя'",									
				CONFIGPANEL = "'Добавить Ауру' Конфигурация",
				ANY = "Любая",
				HEALER = "Лекарь",
				DAMAGER = "Танк|Урон",
				ADD = "Добавить Ауру",					
				REMOVE = "Удалить Ауру",				
			},				
			[6] = {
				HEADBUTTON = "Курсор",
				HEADTITLE = "Взаимодействие Мышки",		
				USETITLE = "[Каждый спек] Конфигурация кнопок:",
				USELEFT = "Использовать Левый щелчок",
				USELEFTTOOLTIP = "Используется макрос /target mouseover это не является самим щелчком!\n\nПравая кнопка мыши: Создать макрос",
				USERIGHT = "Использовать Правый щелчок",
				LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nЕсли вы используете LUA в категории 'GameToolTip' тогда thisunit не имеет никакого значения\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true'без кавычек,\nвместо простого удаления",														
				BUTTON = "Щелчок",
				NAME = "Название",
				LEFT = "Левый щелчок",
				RIGHT = "Правый щелчок",
				ISTOTEM = "Является тотемом",
				ISTOTEMTOOLTIP = "Если включено, то будет проверять @mouseover на тип 'Тотем' для данного имени\nТакже предотвращает клик в случае если в @target уже есть какой-либо тотем",
				INPUTTITLE = "Введите название объекта (на русском!)", 
				INPUT = "Этот ввод является не чувствительным к регистру",
				ADD = "Добавить",
				REMOVE = "Удалить",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "тотем духовной связи",
				HEALINGTIDETOTEM = "тотем целительного прилива",
				CAPACITORTOTEM = "тотем конденсации",					
				SKYFURYTOTEM = "тотем небесной ярости",					
				ANCESTRALPROTECTIONTOTEM = "тотем защиты предков",					
				COUNTERSTRIKETOTEM = "тотем контрудара",
				EXPLOSIVES = "взрывчатка",
				-- Optional totems
				TREMORTOTEM = "тотем трепета",
				GROUNDINGTOTEM = "тотем заземления",
				WINDRUSHTOTEM = "тотем ветряного порыва",
				EARTHBINDTOTEM = "тотем оков земли",
				-- GameToolTips
				ALLIANCEFLAG = "флаг альянса",
				HORDEFLAG = "флаг орды",
				NETHERSTORMFLAG = "флаг пустоверти",
				ORBOFPOWER = "сфера могущества",
			},
			[7] = {
				HEADTITLE = "Система Сообщений",
				USETITLE = "[Каждый спек]",
				MSG = "MSG Система",				
				MSGTOOLTIP = "Включено: работает\nНЕ включено: не работает\n\nПравая кнопка мыши: Создать макрос",
				DISABLERETOGGLE = "Блокировать снятие очереди",
				DISABLERETOGGLETOOLTIP = "Предотвращает повторным сообщением удаление из системы очереди\nИными словами позволяет спамить макрос без риска быть снятым\n\nПравая кнопка мыши: Создать макрос",
				MACRO = "Макрос для вашей группы:",
				MACROTOOLTIP = "Это то, что должно посылаться в чат группы для срабатывания назначенного действия по заданному ключу\nЧтобы адресовать действие к конкретному юниту допишите их в макрос или оставьте как есть для назначения в Single/AoE ротацию\nПоддерживаются: raid1-40, party1-2, player, arena1-3\nТОЛЬКО ОДИН ЮНИТ ЗА ОДНО СООБЩЕНИЕ!\n\nВаши напарники могут использовать макрос также, но осторожно, они должны быть лояльны к этому!\nНЕ ДАВАЙТЕ МАКРОС НЕЗНАКОМЦАМ И ЛЮДЯМ НЕ В ТЕМЕ!",
				KEY = "Ключ",
				KEYERROR = "Вы не указали ключ!",
				KEYERRORNOEXIST = "ключ не существует!",
				KEYTOOLTIP = "Вы должны указать ключ, чтобы привязать действие\nВы можете извлечь ключ во вкладке 'Действия'",
				MATCHERROR = "данное имя уже совпадает, используйте другое!",
				SOURCE = "Имя сказавшего",	
				WHOSAID = "Кто сказал",
				SOURCETOOLTIP = "Это опционально. Вы можете оставить это пустым (рекомендуется)\nВ случае если вы хотите настроить это, то имя должно быть точно таким же как в группе чата",
				NAME = "Содержит в сообщении",
				ICON = "Значок",
				INPUT = "Введите фразу для системы сообщений",
				INPUTTITLE = "Фраза",
				INPUTERROR = "Вы не ввели фразу!",
				INPUTTOOLTIP = "Фраза будет срабатывать на любое совпадение в чате группы (/party)\nЯвляется не чувствительным к регистру\nСодержит патерны, это означает, что сказанная кем-то фраза с комбинацией слов raid, party, arena, party или player\nпереназначит действие на нужный мета слот\nВам не нужно задавать перечисленные патерны здесь, они используются как приписка к макросу\nЕсли патерн не найден, то будут использоваться слоты для Single и AoE ротаций",
			},
		},
	},
	deDE = {			
		NOSUPPORT = "das Profil wird bisher nicht unterstützt",	
		DEBUG = "|cffff0000[Debug] Identifikationsfehler: |r",			
		ISNOTFOUND = "nicht gefunden!",			
		CREATED = "erstellt",
		YES = "Ja",
		NO = "Nein",
		TOGGLEIT = "Wechsel",
		SELECTED = "Ausgewählt",
		RESET = "Zurücksetzen",
		RESETED = "Zurückgesetzt",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro bereits vorhanden!|r",
		MACROLIMIT = "|cffff0000Makrolimit erreicht, lösche vorher eins!|r",
		MACROINCOMBAT = "|cffff0000Im Kampf kann kein Makro erstellt werden. Du musst aus dem Kampf herauskommen!|r",		
		GLOBALAPI = "API Global: ",
		RESIZE = "Größe ändern",
		RESIZE_TOOLTIP = "Click-und-bewege um die Größe zu ändern",
		CLOSE = "Schließen",
		APPLY = "Anwenden",
		SLASH = {
			LIST = "Liste der Slash-Befehle:",
			OPENCONFIGMENU = "Menü Öffnen",
			HELP = "Zeigt dir die Hilfe an",
			QUEUEHOWTO = "Makro (Toggle) für Sequenzsystem (Queue), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			QUEUEEXAMPLE = "Beispiel für das Sequenzsystem",
			BLOCKHOWTO = "Makro (Umschalten) zum Deaktivieren | Aktivieren beliebiger Aktionen (Blocker), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			BLOCKEXAMPLE = "Beispiel zum Deaktivierungssystem",
			RIGHTCLICKGUIDANCE = "Die meisten Elemente können mit der linken und rechten Maustaste angeklickt werden. Durch Klicken mit der rechten Maustaste wird ein Makrowechsel erstellt, sodass Sie sich nicht um das obige Hilfehandbuch kümmern müssen",				
			INTERFACEGUIDANCE = "UI erklrüngen7:",
			INTERFACEGUIDANCEEACHSPEC = "[Jede Klasse] Spezifiziert für deine jetzige Skillung",
			INTERFACEGUIDANCEALLSPECS = "[Alle Klassen] Spezifiziert für alle Skillungen deines Characters",
			INTERFACEGUIDANCEGLOBAL = "[Global] Spezifiziert für alle auf deinem Account, Alle Charaktere, Alle Skillungen",
			ATTENTION = "|cffff0000TAKE ATTENTION|r Funktionsumfang von Action nur für Profile verfügbar, die nach dem 31.05.2019 veröffentlicht wurden. Das alte Profil würde zukünftig für dieses System aktualisiert",
			TOTOGGLEBURST = "um den Burst-Modus umzuschalten",
			TOTOGGLEMODE = "PvP / PvE umschalten",
			TOTOGGLEAOE = "um AoE umzuschalten",			
		},
		TAB = {
			RESETBUTTON = "Einstellungen zurücksetzten",
			RESETQUESTION = "Bist du dir SICHER?",
			SAVEACTIONS = "Einstellungen Speichern",
			SAVEINTERRUPT = "Speicher Unterbrechungsliste",
			SAVEDISPEL = "Speicher Auraliste",
			SAVEMOUSE = "Speicher Cursorliste",
			SAVEMSG = "Speicher Nachrichtrenliste",
			LUAWINDOW = "LUA Einstellung",
			LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nCode muss einen booleschen Rückgabewert (true) haben, um Bedingungen zu verarbeiten\nDieser Code hat setfenv, was bedeutet, dass Sie Action. nicht benötigen. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Vor dem Adden LUA Konfiguration schließen!",
			FIXLUABEFOREADD = "LUA Fehler beheben bevor du es hinzufügst",
			RIGHTCLICKCREATEMACRO = "Rechtsklick: Erstelle macro",
			NOTHING = "Keine Konfiguration für das Profil",
			HOW = "Bestätigen:",
			HOWTOOLTIP = "Global: Alle Accounrs, alle Charaktere und alle Skillungen",
			GLOBAL = "Global",
			ALLSPECS = "Für alle Skillungen auf diesen Charakter",
			THISSPEC = "Für die jetzige Skillung auf dem Charakter",			
			KEY = "Schlüssel:",
			CONFIGPANEL = "Konfiguration Hinzufügen",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Jede Skillung] Primär",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Erzwingen, dass ein Profil in einen anderen Modus wechselt\n(besonders nützlich, wenn der Kriegsmodus aktiviert ist)\n\nRechtsklick: Makro erstellen", 
				PVEPVPRESETTOOLTIP = "Manuelle Umschaltung auf automatische Auswahl zurücksetzen",
				CHANGELANGUAGE = "Sprache wechseln",
				CHARACTERSECTION = "Character Fenster",
				AUTOTARGET = "Automatisches Ziel",
				AUTOTARGETTOOLTIP = "Wenn kein Ziel vorhanden, Sie sich jedoch in einem Kampf befinden, wird der nächste Feind ausgewählt.\nDer Umschalter funktioniert auf die gleiche Weise, wenn das Ziel Immunität gegen PvP hat.\n\nRechtsklick: Makro erstellen",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Herz von Azeroth",
				RACIAL = "Rassenfähigkeit",
				STOPCAST = "Hör auf zu gießen",
				SYSTEMSECTION = "Systemmenu",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ACHTUNG: Diese Option führt zu einer Verzögerung von 0,3 s + der aktuellen Spinning-GCD.\nwenn überprüft wird, ob sich die Einheit in Sichtweite befindet (z. B. hinter einer Box in der Arena).\nDiese Option muss auch in den erweiterten Einstellungen aktiviert werden a lose und\nunterbricht die Bereitstellung von Aktionen für N Sekunden\n\nRechtsklick: Makro erstellen",
				HEALINGENGINEPETS = "Heileinstellung für Begleiter",
				HEALINGENGINEPETSTOOLTIP = "Füge die Begleiter des ausgewählten Spielers zum Ziel hinzu und berechne sie, um sie zu heilen.\n\nRechtsklick: Makro erstellen",
				STOPATBREAKABLE = "Stoppt den Schaden bei Zerbrechlichkeit",
				STOPATBREAKABLETOOLTIP = "Verhindert schädlichen Schaden bei Feinden\nWenn sie CC wie Polymorph haben\nDer automatische Angriff wird nicht abgebrochen!\n\nRechtsklick: Makro erstellen",
				ALL = "Alle",
				RAID = "Raid",
				TANK = "Nur Tanks",
				DAMAGER = "Nur Damagers",
				HEALER = "Nur Healers",
				HEALINGENGINETOOLTIP = "Diese Option bezieht sich auf die Einheitenauswahl bei Heilern.\nAlle: Alle Mitglieder\nGezahlt: Alle Mitglieder ohne Tanks\n\nRechtsklick: Makro erstellen\nWenn Sie das Argument für die Verwendung des Status zum Festlegen des Umschaltens in (ARG) festlegen möchten: 'ALL', 'RAID'. , 'TANK', 'HEILER', 'DAMAGER'",
				DBM = "DBM Timers",
				DBMTOOLTIP = "Verfolgen von Pull-Timern und bestimmten Ereignissen, z. B. eingehendem Thrash.\nDiese Funktion ist nicht für alle Profile verfügbar!\n\nKlicken mit der rechten Maustaste: Makro erstellen",
				FPS = "FPS Optimierungen",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Erhöht die Frames pro Sekunde durch Erhöhen der dynamischen Abhängigkeit.\nFrames des Aktualisierungszyklus (Aufruf) des Rotationszyklus\n\nSie können das Intervall auch nach einer einfachen Regel manuell einstellen:\nDer größere Schieberegler als mehr FPS, aber schlechtere Rotation Update\nZu hoher Wert kann zu unvorhersehbarem Verhalten führen!\n\nRechtsklick: Makro erstellen",					
				PVPSECTION = "PvP Einstellungen",
				REFOCUS = "Vorheriges gespeichertes @focus zurückgeben\n(nur Arena1-3-Einheiten)\nEs wird für Unsichtbarkeitsklassen empfohlen\n\nRechtsklick: Makro erstellen",
				RETARGET = "Vorheriges gespeichertes @Ziel zurückgeben\n(nur Arena1-3-Einheiten)\nEs wird gegen Jäger mit 'Totstellen' und unvorhergesehenen Zielabwürfen empfohlen\n\nRechtsklick: Makro erstellen",
				TRINKETS = "Schmuckstücke",
				TRINKET = "Schmuck",
				BURST = "Burst Modus",
				BURSTTOOLTIP = "Alles - Auf Abklingzeit\nAuto - Boss oder Spieler\nAus - Deaktiviert\nRechtsklick: Makro erstellen\nWenn Sie einen festen Umschaltstatus festlegen möchten, verwenden Sie das Argument in (ARG): 'Alles', 'Auto', 'Aus'",					
				HEALTHSTONE = "Gesundheitsstein | Abyssischer Heiltrank",
				HEALTHSTONETOOLTIP = "Wann der GeSu benutzt werden soll!\n\nRechtsklick: Makro erstellen",
				COLORTITLE = "Farbwähler",
				COLORUSE = "Verwenden Sie eine benutzerdefinierte Farbe",
				COLORUSETOOLTIP = "Wechseln Sie zwischen Standard- und benutzerdefinierten Farben",
				COLORELEMENT = "Element",
				COLOROPTION = "Möglichkeit",
				COLORPICKER = "Auswahl",
				COLORPICKERTOOLTIP = "Klicken Sie hier, um das Setup-Fenster für das ausgewählte 'Element'> 'Option' zu öffnen\nRechte Maustaste zum Verschieben des geöffneten Fensters",
				FONT = "Schriftart",
				NORMAL = "Normal",
				DISABLED = "Deaktiviert",
				HEADER = "Header",
				SUBTITLE = "Untertitel",
				TOOLTIP = "Tooltip",
				BACKDROP = "Hintergrund",
				PANEL = "Panel",
				SLIDER = "Schieberegler",
				HIGHLIGHT = "Markieren",
				BUTTON = "Taste",
				BUTTONDISABLED = "Taste Deaktiviert",
				BORDER = "Rand",
				BORDERDISABLED = "Rand Deaktiviert",	
				PROGRESSBAR = "Fortschrittsanzeige",
				COLOR = "Farbe",
				BLANK = "Leer",
				SELECTTHEME = "Wählen Sie Bereites Thema",
				THEMEHOLDER = "Thema wählen",
				BLOODYBLUE = "Blutiges Blau",
				PAUSECHECKS = "[Jede Klasse] Rota funktioniert nicht wenn:",
				VEHICLE = "Im Fahrzeug",
				VEHICLETOOLTIP = "Beispiel: Katapult, Pistole abfeuern",
				DEADOFGHOSTPLAYER = "Wenn du Tot bist",
				DEADOFGHOSTTARGET = "Das Ziel Tot ist",
				DEADOFGHOSTTARGETTOOLTIP = "Ausnahme feindlicher Jäger, wenn er als Hauptziel ausgewählt ist",
				MOUNT = "Aufgemounted",
				COMBAT = "Nicht im Kampf", 
				COMBATTOOLTIP = "Wenn Sie und Ihr Ziel außerhalb des Kampfes sind. Unsichtbar ist eine Ausnahme.\n(Wenn diese Bedingung getarnt ist, wird sie übersprungen.)",
				SPELLISTARGETING = "Fähigkeit dich im Ziel hat",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heldenhafter Sprung, Eiskältefalle",
				LOOTFRAME = "Beutefenster",
				EATORDRINK = "Isst oder trinkt",
				MISC = "Verschiedenes:",		
				DISABLEROTATIONDISPLAY = "Verstecke Rotationsanzeige",
				DISABLEROTATIONDISPLAYTOOLTIP = "Blendet die Gruppe aus, die sich normalerweise im unteren Bereich des Bildschirms befindet",
				DISABLEBLACKBACKGROUND = "Verstecke den schwarzen Hintergrund", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Verbirgt den schwarzen Hintergrund in der oberen linken Ecke.\nACHTUNG: Dies kann zu unvorhersehbarem Verhalten führen!",
				DISABLEPRINT = "Verstecke Text",
				DISABLEPRINTTOOLTIP = "Verbirgt Chat-Benachrichtigungen vor allem\nACHTUNG: Dadurch wird auch die [Debug] -Fehleridentifikation ausgeblendet!",
				DISABLEMINIMAP = "Verstecke Minimap Symbol",
				DISABLEMINIMAPTOOLTIP = "Blendet das Minikartensymbol dieser Benutzeroberfläche aus",
				DISABLEPORTRAITS = "Klassenporträt ausblenden",
				DISABLEROTATIONMODES = "Drehmodi ausblenden",
				DISABLESOUNDS = "Sounds deaktivieren",
				HIDEONSCREENSHOT = "Auf dem Screenshot verstecken",
				HIDEONSCREENSHOTTOOLTIP = "Während des Screenshots werden alle TellMeWhen\nund Action frames ausgeblendet und anschließend wieder angezeigt",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Warteschleife",
				ENABLED = "Aktiviert",
				NAME = "Name",
				DESC = "Notiz",
				ICON = "Icon",
				SETBLOCKER = "Set\n Blocker",
				SETBLOCKERTOOLTIP = "Dadurch wird die ausgewählte Aktion in der Rotation blockiert.\nSie wird niemals verwendet.\n\nRechtsklick: Makro erstellen",
				SETQUEUE = "Set\n Warteschleife",
				SETQUEUETOOLTIP = "Der nächste Spell wird in die Warteschleife gessetzt\n Er wird benutzt sobald es möglich ist\n\nRechtsklick: Makro erstellen\nWie auf welchem Gerät zu verwenden (UnitID ist Schlüssel), zum beispiel: { Priority = 1, UnitID = 'player' }\nSie können akzeptable Schlüssel mit Beschreibung in der Funktion finden 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blockiert: |r",
				UNBLOCKED = "|cff00ff00Freigestellt: |r",
				KEY = "[Schlüssel: ",
				KEYTOTAL = "[Warteschlangensumme: ",
				KEYTOOLTIP = "Benutze den Schlüssel im MSG Fenster", 
				ISFORBIDDENFORBLOCK = "Verboten für die Blocker!",
				ISFORBIDDENFORQUEUE = "Verboten für die Warteschleife!",
				ISQUEUEDALREADY = "Schon in der Warteschleife drin!",
				QUEUED = "|cff00ff00Eingereiht: |r",
				QUEUEREMOVED = "|cffff0000Entfernt aus der Warteschleife: |r",
				QUEUEPRIORITY = " hat Priorität #",
				QUEUEBLOCKED = "|cffff0000Kann nicht eingereiht werden das der Spell geblockt ist!|r",
				SELECTIONERROR = "|cffff0000Du hast nichts ausgewählt!|r",
				AUTOHIDDEN = "[Alle Spezialisierungen] Nicht verfügbare Aktionen automatisch ausblenden",
				AUTOHIDDENTOOLTIP = "Verkleinern Sie die Bildlauftabelle und löschen Sie sie durch visuelles Ausblenden\nZum Beispiel hat die Charakterklasse nur wenige Rassen, kann aber eine verwenden. Diese Option versteckt andere Rassen\nNur zur Komfortsicht",
				CHECKSPELLLVL = "[Alle Spezialisierungen] Überprüfe den vorrausgesetzten Spell Level",
				CHECKSPELLLVLTOOLTIP = "Alle Zaubersprüche, die auf Charakterebene nicht verfügbar sind, werden blockiert.\nSie werden jedes Mal mit einer höheren Stufe aktualisiert",
				CHECKSPELLLVLERROR = "Schon installiert!",
				CHECKSPELLLVLERRORMAXLVL = "Max Level erreicht!",
				CHECKSPELLLVLMACRONAME = "Spell Level überprüfen",
				LUAAPPLIED = "LUA-Code wurde angewendet auf ",
				LUAREMOVED = "LUA-Code wurde gelöscht von ",
			},
			[4] = {
				HEADBUTTON = "Unterbrechungen",	
				HEADTITLE = "Profile Unterbrechungen",				
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				CONFIGPANEL = "'Unterbrechungen hinzufügen' Menu",
				INTERRUPTFRONTSTRINGTITLE = "Liste auswählen:",
				INTERRUPTTOOLTIP = "[Main] für Einheiten @target/@mouseover/@targettarget\n [Heilung] für Einheiten @arena1-3 (Heilung)\n [PvP] für Einheiten @arena1-3 (crowdcontrol)\n\n Du kannst verschiedene Zeiten für [Heilung] und [PvP] (nicht in dem UI)",
				INPUTBOXTITLE = "Spell eintragen:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): Lösch den Text und entferne den Fokus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Suche nach Name oder SpellID",
				TARGETMOUSEOVERLIST = "[Main] List",
				TARGETMOUSEOVERLISTTOOLTIP = "Deaktiviert: unterbricht JEGLICHE Zauber nach dem Zufallsprinzip.\nÜberprüft: unterbricht nur die angegebene benutzerdefinierte Liste für @ target / @ mouseover / @ targettarget.\nHinweis: Im PvP wird die Unterbrechung dieser Liste behoben, wenn sie aktiviert ist. 4 Sek.!\n\n@ mouseover / @ targettarget sind optional und hängen von den Optionen auf der Registerkarte spec ab.\n\nRechtsklick: Create macro",
				KICKTARGETMOUSEOVER = "[Main] Unterbrechungen\n Aktiviert",				
				KICKTARGETMOUSEOVERTOOLTIP = "Deaktiviert: @target/@mouseover Einheit Unterbrechen funktioniert nicht\nAktiviert: @target/@mouseover Einheiten Unterbrechen funktioniert \n\n Rechtsklick: Create macro",					
				KICKHEALONLYHEALER = "[Heilung] Nur Heiler",					
				KICKHEALONLYHEALERTOOLTIP = "Deaktiviert: Die Liste gilt für alle Spezialisierungen feindlicher Einheiten\n(e.g. Ench, Elem, SP, Retri)\n Aktiviert: Liste gilt nur für feindliche Heiler\n\n Rechtsklick: Create macro",
				KICKHEAL = "[Heilung] Liste",
				KICKHEALPRINT = "[Heilung] Liste der Unterbrechungen",
				KICKHEALTOOLTIP = "Deaktiviert: @arena1-3 [Heilung] Benutzerlist funktioniert nicht\nChecked: @arena1-3 [Heilung] Benutzerliste funktioniert\n\nRechtsklick: Create macro",
				KICKPVP = "[PvP] Liste",
				KICKPVPPRINT = "[PvP] Liste der Unterbrechungen",
				KICKPVPTOOLTIP = "Deaktiviert: @arena1-3 [PvP] Benutzerlist funktioniert nicht\nChecked: @arena1-3 [PvP] Benutzerliste funktioniert \n\n Rechtsklick: Create macro",	
				KICKPVPONLYSMART = "[PvP] Einfach",
				KICKPVPONLYSMARTTOOLTIP = "Aktiviert: wird nur durch logische Aktionen in der profil lua konfiguration unterbrochen. Beispiel:\n1) CC Kette auf deinen Heiler \n2) Dein partner (oder du) hat seinen Burst Aktiv >4 sec\n3) Wenn jemand in weniger als 8 Sekunden stirbt\n4) Dein (oder @target) HP kommt in die execute Phase\n Deaktiviert: Wird alles mögliche ohne Logik unterbrechen von deiner Liste\n\nNote: Hohe CPU Auslastung\nRightClick: Create macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Rassisch",
				ADD = "Unterbrechung hinzufügen",					
				ADDERROR = "|cffff0000Du hast in 'Zauberspell' nichts angegeben, oder der Zauber wurde nicht gefunden!|r",
				ADDTOOLTIP = "Füge Fähigkeit von 'Zauberspell'\n Zu deiner Liste",
				REMOVE = "Entferne Unterbrechung",
				REMOVETOOLTIP = "Entfernt markierten Spell von deiner Liste",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Jede Klasse] Checkbox Configuration",
				USEDISPEL = "Benutze Dispel",
				USEPURGE = "Benutze Purge",
				USEEXPELENRAGE = "Entferne Enrage",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Kategorie:",
				POISON = "Dispel Gifte",
				DISEASE = "Dispel Krankheiten",
				CURSE = "Dispel Flüche",
				MAGIC = "Dispel Magische Effekte",
				MAGICMOVEMENT = "Dispel Magische verlangsamungen/festhalten",
				PURGEFRIENDLY = "Purge Partner",
				PURGEHIGH = "Purge Gegner (Hohe Priorität)",
				PURGELOW = "Purge Gegner (Geringe Priorität)",
				ENRAGE = "Entferne Enrage",	
				BLESSINGOFPROTECTION = "Segen des Schutzes",
				BLESSINGOFFREEDOM = "Segen der Freiheit",
				BLESSINGOFSACRIFICE = "Segen der Opferung",
				BLESSINGOFSANCTUARY = "Segen des Refugiums",	
				ROLE = "Rolle",
				ID = "ID",
				NAME = "Name",
				DURATION = "Dauer\n >",
				STACKS = "Stapel\n >=",
				ICON = "Symbol",					
				ROLETOOLTIP = "Deine Rolle, es zu benutzen",
				DURATIONTOOLTIP = "Reagiere auf Aura, wenn die Dauer der Aura länger (>) als die angegebenen Sekunden ist.\nWICHTIG: Auren ohne Dauer wie 'Göttliche Gunst'\n(Lichtpaladin) müssen 0 sein. Dies bedeutet, dass die Aura vorhanden ist!",
				STACKSTOOLTIP = "Reagiere auf Aura, wenn es mehr oder gleiche (>=) spezifizierte Stapel hat",									
				BYID = "Benutze ID\nAnstatt Name",
				BYIDTOOLTIP = "Nach ID müssen ALLE Rechtschreibungen\nüberprüft werden, die den gleichen Namen haben, aber unterschiedliche Auren annehmen, z. B. 'Instabiles Gebrechen'",					
				CANSTEALORPURGE = "Nur wenn ich\n Klauen oder Entfernen kann",					
				ONLYBEAR = "Nur wenn der Gegner\nin 'Bär Form'ist",									
				CONFIGPANEL = "'Aura hinzufügen' Menü",
				ANY = "Jeder",
				HEALER = "Heiler",
				DAMAGER = "Tank|Damager",
				ADD = "Aura hinzufügen",					
				REMOVE = "Aura entfernen",					
			},				
			[6] = {
				HEADBUTTON = "Zeiger",
				HEADTITLE = "Maus Interaktion",
				USETITLE = "[Jede Klasse] Tasten Menü:",
				USELEFT = "Benutze Links Klick",
				USELEFTTOOLTIP = "Dies erfolgt mit einem Makro / Ziel-Mouseover, bei dem es sich nicht um einen Klick handelt!\n\nRechtsklick: Makro erstellen",
				USERIGHT = "Benutze Rechts Klick",
				LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nWenn Sie in der Kategorie 'GameToolTip' LUA verwenden, ist diese Einheit ungültig.\nCode muss eine boolesche Rückgabe (trifft zu) für die Verarbeitung von Bedingungen haben Verwenden Sie Action. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",							
				BUTTON = "Klick",
				NAME = "Name",
				LEFT = "Linkklick",
				RIGHT = "Rechtsklick",
				ISTOTEM = "im Totem",
				ISTOTEMTOOLTIP = "Wenn diese Option aktiviert ist, wird @mouseover auf 'Totem' für die Art des Totems überprüft.\nVermeiden Sie auch, dass Sie in eine Situation klicken, in der Ihr @target bereits ein Totem enthält",				
				INPUTTITLE = "Geben Sie den Namen des Objekts ein (localized!)", 
				INPUT = "Dieser Eintrag unterscheidet nicht zwischen Groß- und Kleinschreibung",
				ADD = "Hinzufügen",
				REMOVE = "Entfernen",
				-- GlobalFactory default name preset in lower case!				
				SPIRITLINKTOTEM = "totem der geistverbindung",
				HEALINGTIDETOTEM = "totem der heilungsflut",
				CAPACITORTOTEM = "totem der energiespeicherung",					
				SKYFURYTOTEM = "totem des himmelszorns",					
				ANCESTRALPROTECTIONTOTEM = "totem des schutzes der ahnen",					
				COUNTERSTRIKETOTEM = "totem des gegenschlags",
				EXPLOSIVES = "sprengstoff",
				-- Optional totems
				TREMORTOTEM = "totem des erdstoßes",
				GROUNDINGTOTEM = "totem der erdung",
				WINDRUSHTOTEM = "totem des windsturms",
				EARTHBINDTOTEM = "totem der erdbindung",
				-- GameToolTips
				ALLIANCEFLAG = "siegesflagge der allianz",
				HORDEFLAG = "siegesflagge der horde",
				NETHERSTORMFLAG = "nethersturmflagge",
				ORBOFPOWER = "kugel der macht",                                    
			},
			[7] = {
				HEADTITLE = "Nachrichten System",
				USETITLE = "[Jede Klasse]",
				MSG = "MSG System",
				MSGTOOLTIP = "Aktiviert: Funktioniert \nDeaktiviert: Funktioniert nicht\n\nRightClick: Create macro",
				DISABLERETOGGLE = "Warteschlange entfernen",
				DISABLERETOGGLETOOLTIP = "Verhindert durch wiederholtes Löschen von Nachrichten aus dem Warteschlangensystem\nE.g. Mögliches Spam-Makro, ohne entfernt zu werden\n\nRechtsklick: Makro erstellen",
				MACRO = "Macro für deine Gruppe:",
				MACROTOOLTIP = "Dies sollte an den Gruppenchat gesendet werden, um die zugewiesene Aktion auf der angegebenen Taste auszulösen.\nUm die Aktion an eine bestimmte Einheit zu richten, fügen Sie sie dem Makro hinzu oder lassen Sie sie unverändert, wie sie für den Termin in der Einzel- / AoE-Rotation vorgesehen ist.\nUnterstützt : raid1-40, party1-2, player, arena1-3\nNUR EINE EINHEIT FÜR EINE NACHRICHT!\n\nIhre Gefährten können auch Makros verwenden, aber seien Sie vorsichtig, sie müssen dem treu bleiben!\nLASSEN SIE DAS NICHT MAKRO ZU UNIMINANZEN UND MENSCHEN NICHT IM THEMA!",
				KEY = "Taste",
				KEYERROR = "Du hast keine Taste ausgewählt!",
				KEYERRORNOEXIST = "Taste existiert nicht!",
				KEYTOOLTIP = "Sie müssen eine Taste zum auswählen der Aktion angeben.\nSie können die Taste auf der Registerkarte 'Aktionen' finden",
				MATCHERROR = "Der name ist bereits vorhanden, bitte nimm einen anderen!",				
				SOURCE = "Der Name der Person, die das gesagt hat",					
				WHOSAID = "Wer es sagt",
				SOURCETOOLTIP = "Dies ist optional. Du kannst dieses Feld leer lassen (empfohlen).\nWenn du es konfigurieren möchtest, muss der Name exakt mit dem in der Chatgruppe übereinstimmen",
				NAME = "Enthält eine Nachricht",
				ICON = "Symbol",
				INPUT = "Gib einen Text für das Nachrichtensystem ein",
				INPUTTITLE = "Text",
				INPUTERROR = "Du hast keinen Text angegeben!",
				INPUTTOOLTIP = "Der Text wird ausgelöst sobald einer aus deiner Gruppe im Gruppenchat schreibt (/party)\nEr ist nicht Groß geschrieben\n Enthält Muster, das heisst der Text, die von jemandem mit der Kombination der Wörter Schlachtzug, Party, Arena, Party oder Spieler gesprochen wird, passt die Aktion an den gewünschten Meta-Slot an.\nDie hier aufgeführten Muster müssen nicht festgelegt werden Wird das Muster nicht gefunden, werden Slots für Single- und AoE-Rotationen verwendet",				
			},
		},
	},
	frFR = {			
		NOSUPPORT = "ce profil n'est pas encore supporté par ActionUI",	
		DEBUG = "|cffff0000[Debug] Identification d'erreur : |r",			
		ISNOTFOUND = "n'est pas trouvé!",			
		CREATED = "créé",
		YES = "Oui",
		NO = "Non",
		TOGGLEIT = "Basculer ON/OFF",
		SELECTED = "Selectionné",
		RESET = "Réinitialiser",
		RESETED = "Remis à zéro",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La macro existe déjà !|r",
		MACROLIMIT = "|cffff0000Impossible de créer la macro, vous avez atteint la limite. Vous devez supprimer au moins une macro!|r",
		MACROINCOMBAT = "|cffff0000Impossible de créer une macro en combat. Vous devez quitter le combat!|r",		
		GLOBALAPI = "API Globale: ",
		RESIZE = "Redimensionner",
		RESIZE_TOOLTIP = "Cliquer et faire glisser pour redimensionner",
		CLOSE = "Fermer",
		APPLY = "Appliquer",
		SLASH = {
			LIST = "Liste des commandes slash:",
			OPENCONFIGMENU = "Voir le menu de configuration",
			HELP = "Voir le menu d'aide",
			QUEUEHOWTO = "macro (toggle) pour la séquence système (Queue), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			QUEUEEXAMPLE = "exemple d'utilisation de Queue(file d'attende)",
			BLOCKHOWTO = "macro (toggle) pour désactiver|activer n'importe quelles actions (Blocker-Blocage), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			BLOCKEXAMPLE = "exemple d'usage Blocker (Blocage)",
			RIGHTCLICKGUIDANCE = "Vous pouvez faire un clic droit ou gauche sur la plupart des éléments. Un clicque droit va créer la macro toggle donc ne vous souciez pas de laide au dessus",				
			INTERFACEGUIDANCE = "Explications de l'UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] concernant votre spécialisation ACTUELLE",
			INTERFACEGUIDANCEALLSPECS = "[All specs] concernant TOUTES les spécialisations de votre personnage",
			INTERFACEGUIDANCEGLOBAL = "[Global] concernant TOUT vos compte, TOUT vos personnage et TOUTES vos spécialisations",
			ATTENTION = "|cffff0000FAIS ATTENTION|r Les fonction de ActionUI est disponible uniquement pour les profiles publié après le 31.05.2019. Les anciens profiles seront mise à jour pour ce système",	
			TOTOGGLEBURST = "pour basculer en mode rafale",
			TOTOGGLEMODE = "pour basculer PvP / PvE",
			TOTOGGLEAOE = "pour basculer en zone d'effet (AoE)",			
		},
		TAB = {
			RESETBUTTON = "Réinitiliser les paramètres",
			RESETQUESTION = "Êtes-vous sûr?",
			SAVEACTIONS = "Sauvegarder les paramètres d'Actions",
			SAVEINTERRUPT = "Sauvegarder la liste d'interruption",
			SAVEDISPEL = "Sauvergarder la liste d'auras",
			SAVEMOUSE = "Sauvergarder la liste de Curseur",
			SAVEMSG = "Sauvergarder La liste MSG",
			LUAWINDOW = "Configuration LUA",
			LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
			BRACKETMATCH = "Repérage des paires de\nparenthèse", 
			CLOSELUABEFOREADD = "Fermer la configuration LUA avant de l'ajouter",
			FIXLUABEFOREADD = "Vous devez corriger les erreurs dans la configuration LUA avant de l'ajouter",
			RIGHTCLICKCREATEMACRO = "Clique droit : Créer la macro",
			NOTHING = "Le profile n'a pas de configuration pour cette onglet",
			HOW = "Appliquer:",
			HOWTOOLTIP = "Globale: Tous les comptes, tous les personnages et toutes les spécialisations",
			GLOBAL = "Globale",
			ALLSPECS = "Pour toutes les spécialisations de votre personnage",
			THISSPEC = "Pour la spécialisation actuelle de votre personnage",			
			KEY = "Touche:",
			CONFIGPANEL = "'Ajouter' Configuration",
			[1] = {
				HEADBUTTON = "Générale",	
				HEADTITLE = "[Each spec] Primary",
				PVEPVPTOGGLE = "PvE / PvP basculement manuelle",
				PVEPVPTOGGLETOOLTIP = "Focer un profile a basculer dans l'autre mode (PVE/PVP)\n(Utile avec le mode de guerre activé)\n\nClique Droit : Créer la macro", 
				PVEPVPRESETTOOLTIP = "Réinitialiser le basculemant en automatique",
				CHANGELANGUAGE = "Changer la langue",
				CHARACTERSECTION = "Section du personnage",
				AUTOTARGET = "Ciblage Automatique",
				AUTOTARGETTOOLTIP = "Si vous n'avez pas de cible, mais que vous êtes en combat, il va choisir la cible la plus proche\n Le basculement fonctionne de la même manière si la cible est immunisé en PVP\n\nClique droit : Créer la macro",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Coeur d'Azeroth",
				RACIAL = "Sort raciaux",
				STOPCAST = "Arrêtez le casting",
				SYSTEMSECTION = "Section système",
				LOSSYSTEM = "Système LOS",
				LOSSYSTEMTOOLTIP = "ATTENTION: Cette option cause un delai de 0.3s + votre gcd en cours\nSi la cible verifié n'est pas dans la ligne de vue (par exemple, derrière une boite en arène) \nVous devez aussi activer ce paramètre dans les paramètres avancés\nCette option blacklistes l'unité qui n'est pas à vue et\narrête d'effectuer des actions sur elle pendant N secondes\n\nClique droit : Créer la macro",
				HEALINGENGINEPETS = "HealingEngine familiers",
				HEALINGENGINEPETSTOOLTIP = "Inclut les familier des joueurs et calcule les soins pour eux\n\nClique droit : Créer la macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Arrêtera les dégâts sur les ennemis\nSi ils ont un CC tel que Polymorph\nIl n'annule pas l'attaque automatique!\n\nClique droit : Créer la macro",
				ALL = "Tout",
				RAID = "Raid",
				TANK = "Tanks seulement",
				DAMAGER = "DPS seulement",
				HEALER = "Heal seulement",
				HEALINGENGINETOOLTIP = "Cette option concerne les cible pour les heals\nTout: Tout les membres\nRaid: Tous les membres sauf les tanks\n\nClique droit : Créer la macro\nSi vous voulez régler comment bascule le ciblage des cible utiliser l'argumment (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",
				DBM = "Timeur DBM",
				DBMTOOLTIP = "Suit les timeur de pull and certain événement spécifique comme l'arrivé de trash.\nCette fonction n'est pas disponible pour tout les profiles!\n\nClique droit : Créer la macro",
				FPS = "FPS Optimisation",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO:  Augmente les images par seconde en augmentant la dépendance dynamique\nimage du cycle de rafraichisement (call) du cycle de rotation\n\nVous pouvez régler manuellement l'intervalle en suivant cette règle simple:\nPlus le slider est grand plus vous avez de FPS, mais pire sera la mise à jour de la rotation\nUne valeur trop élevée peut entraîner un comportement imprévisible!\n\nClique droit : Créer la macro",
				PVPSECTION = "Section PvP",
				REFOCUS = "Remet le @focus sauvé précédemment\n(Uniquement pour les cibles arena1-3)\nCela est recommandé pour les cible qui ont un sort d'invicibilité\n\nClique droit : Créer la macro",
				RETARGET = "Remet le @target sauvé précédemment\n(Uniquement pour les cibles arena1-3)\nCela est recommander contre les chasseurs avec 'Feindre la mort' et les perte de cible imprévu\n\nClique droit : Créer la macro",
				TRINKETS = "Bijoux",
				TRINKET = "Bijou",
				BURST = "Mode Burst",
				BURSTTOOLTIP = "Tout - On cooldown\nAuto - Boss or Joueur\nOff - Désactiver\n\nClique droit : Créer la macro\nSi vous voulez régler comment bascule les cooldowns utiliser l'argumment (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Pierre de soin | Potion de soins abyssale",
				HEALTHSTONETOOLTIP = "Choisisez le pourcentage de vie (HP)\n\nClique droit : Créer la macro",
				COLORTITLE = "Pipette à couleurs",
				COLORUSE = "Utiliser une couleur personnalisée",
				COLORUSETOOLTIP = "Commutateur entre les couleurs par défaut et les couleurs personnalisées",
				COLORELEMENT = "Élément",
				COLOROPTION = "Option",
				COLORPICKER = "Sélecteur",
				COLORPICKERTOOLTIP = "Cliquez pour ouvrir la fenêtre de configuration de votre 'Élément' > 'Option' sélectionné\nBouton droit de la souris pour déplacer la fenêtre ouverte",
				FONT = "Police de caractère",
				NORMAL = "Ordinaire",
				DISABLED = "Désactivé",
				HEADER = "Entête",
				SUBTITLE = "Sous-titre",
				TOOLTIP = "Info-bulle",
				BACKDROP = "Toile de fond",
				PANEL = "Panneau",
				SLIDER = "Glissière",
				HIGHLIGHT = "Surligner",
				BUTTON = "Bouton",
				BUTTONDISABLED = "Bouton Désactivé",
				BORDER = "Frontière",
				BORDERDISABLED = "Frontière Désactivé",	
				PROGRESSBAR = "Barre de progression",
				COLOR = "Couleur",
				BLANK = "Vide",
				SELECTTHEME = "Sélectionnez le thème prêt",
				THEMEHOLDER = "choisissez le thème",
				BLOODYBLUE = "Sanglant Bleu",
				PAUSECHECKS = "[ALL specs] La rotation ne fonction pas, si:",
				VEHICLE = "EnVéhicule",
				VEHICLETOOLTIP = "Exemple: Catapulte, ...",
				DEADOFGHOSTPLAYER = "Vous êtes mort!",
				DEADOFGHOSTTARGET = "Votre cible est morte",
				DEADOFGHOSTTARGETTOOLTIP = "Exception des chasseurs ennemi si il est en cible principale",
				MOUNT = "EnMonture",
				COMBAT = "Hors de combat", 
				COMBATTOOLTIP = "Si vous et votre cible êtes hors de combat. L'invicibilité cause une exception\n(Quand vous êtes camouflé, cette condition est ignoré)",
				SPELLISTARGETING = "Ciblage d'un sort",
				SPELLISTARGETINGTOOLTIP = "Exemple: Blizzard, Bond héroïque, Piège givrant",
				LOOTFRAME = "Fenêtre du butin",
				EATORDRINK = "Est-ce que manger ou boire",
				MISC = "Autre:",		
				DISABLEROTATIONDISPLAY = "Cacher l'affichage de la\nrotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Cacher le groupe, qui se trouve par défaut\n en bas au centre de l'écran",
				DISABLEBLACKBACKGROUND = "Cacher le fond noir", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Cacher le fond noir dans le coin en haut à gauche\nATTENTION: Cela peut entraîner un comportement imprévisible de la rotation!",
				DISABLEPRINT = "Cacher les messages chat",
				DISABLEPRINTTOOLTIP = "Cacher toutes les notification du chat\nATTENTION: Cela cache aussi les message de [Debug] Identification d'erreur!",
				DISABLEMINIMAP = "Cacher l'icone de la minimap",
				DISABLEMINIMAPTOOLTIP = "Cacher l'icone de la minmap de cette interface",
				DISABLEPORTRAITS = "Masquer le portrait de classe",
				DISABLEROTATIONMODES = "Masquer les modes de rotation",
				DISABLESOUNDS = "Désactiver les sons",
				HIDEONSCREENSHOT = "Masquer sur la capture d'écran",
				HIDEONSCREENSHOTTOOLTIP = "Pendant la capture d'écran, tous les cadres TellMeWhen\net Action sont masqués, puis rediffusés",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocage | File d'attente",
				ENABLED = "Activer",
				NAME = "Nom",
				DESC = "Note",
				ICON = "Icone",
				SETBLOCKER = "Activer\nBloquer",
				SETBLOCKERTOOLTIP = "Cela bloque l'action sélectionné dans la rotation\nElle ne sera jamais utiliser\n\nClique droit: Créer la macro",
				SETQUEUE = "Activer\nQueue(file d'attente)",
				SETQUEUETOOLTIP = "Cela met l'action en queue dans la rotation\nElle sera utilisé le plus tôt possible\n\nClique droit: Créer la macro\nVous pouvez passer des conditions supplémentaires dans la macro créée pour la file d'attente\nComme sur quelle unité utiliser (UnitID est la clé), exemple: { Priority = 1, UnitID = 'player' }\nVous pouvez trouver des clés acceptables avec une description dans la fonction 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqué: |r",
				UNBLOCKED = "|cff00ff00Débloqué: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Total de la file d'attente: ",
				KEYTOOLTIP = "Utiliser ce mot clef dans l'onglet MSG",
				ISFORBIDDENFORBLOCK = "est indertit pour la file bloquer!",
				ISFORBIDDENFORQUEUE = "est indertit pour la file d'attente!",
				ISQUEUEDALREADY = "est déjà dans la file d'attente!",
				QUEUED = "|cff00ff00Mise en attente: |r",
				QUEUEREMOVED = "|cffff0000Retirer de la file d'attente: |r",
				QUEUEPRIORITY = " est prioritaire #",
				QUEUEBLOCKED = "|cffff0000ne peut être mise en attente car le blocage est activé!|r",
				SELECTIONERROR = "|cffff0000Vous n'avez pas sélectionné de ligne!|r",
				AUTOHIDDEN = "[All specs] Masquer automatiquement les actions non disponibles",
				AUTOHIDDENTOOLTIP = "Rendre la table de défilement plus petite et claire en masquant visuellement\nPar exemple, la classe de personnage a peu de caractères raciaux, mais peut en utiliser un. Cette option masquera les autres caractères raciaux\nJuste pour le confort vue",
				CHECKSPELLLVL = "[All specs] Vérifier le niveau du sort",
				CHECKSPELLLVLTOOLTIP = "Tout les sort qui ne sont pas disponible par le personnage à cause de son level seront bloqué\nCela se met à jour à chaque fois que vous gagnez un niveau",
				CHECKSPELLLVLERROR = "Déjà initialisé!",
				CHECKSPELLLVLERRORMAXLVL = "Vous êtes au niveau MAX!",
				CHECKSPELLLVLMACRONAME = "VérifierNiveauSort",
				LUAAPPLIED = "Le code LUA a été appliqué à",
				LUAREMOVED = "Le code LUA a été retiré de",
			},
			[4] = {
				HEADBUTTON = "Interruptions",	
				HEADTITLE = "Profile pour les Interruptions",					
				ID = "ID",
				NAME = "Nom du sort",
				ICON = "Icone",
				CONFIGPANEL = "Configuration 'Ajouter une interuption'",
				INTERRUPTFRONTSTRINGTITLE = "Sélectionner une liste:",
				INTERRUPTTOOLTIP = "[Principal] pour les cibles en @target/@mouseover/@targettarget\n[Heal] pour les cibles @arena1-3 (healing)\n[PvP] pour les cibles @arena1-3 (Contrôle de foule)\n\nVous pouvez mettre différents timeur pour [Heal] et [PvP] (pas dans cette interface)",
				INPUTBOXTITLE = "Ajouter un sort:",					
				INPUTBOXTOOLTIP = "ECHAP (ESC): supprimer texte and focus",
				INTEGERERROR = "Plus de 7 chiffres ont été rentré", 
				SEARCH = "Recherche par nom ou ID",
				TARGETMOUSEOVERLIST = "[Principale] Liste",
				TARGETMOUSEOVERLISTTOOLTIP = "Décoché: cela va interrompre N'IMPORTE quel sort\nCoché: Cela va interrompre uniquement les sort de cette liste sur @target/@mouseover/@targettarget\nNote: en PvP seul les sort de la liste PvP sera interrompu, par ailleurs si votre cible est un heal seul les sort de le liste [Heal] seront interrompu si la cible meurent dans les 3-4 sec!\n\n@mouseover/@targettarget sont optionel et dépend de l'option choisi dans l'onglet spécialisation\n\nClique droit : Créer la macro",
				KICKTARGETMOUSEOVER = "[Principale] Interruptions",					
				KICKTARGETMOUSEOVERTOOLTIP = "Décoché: Les interuptions sur les cibles @target/@mouseover ne fonctionnent pas\nCoché: Les interruptiond sur les cibles @target/@mouseover fonctionnent\n\nClique droit : Créer la macro",					
				KICKHEALONLYHEALER = "[Heal] Heal seulement",					
				KICKHEALONLYHEALERTOOLTIP = "Décoché: La liste sera valide pour ni'mporte quel spécialisation ennemis\n(e.g. Amélio, Elem, SP, Ret)\nCoché: La liste ne fonctionnera que sur les heals ennemis\n\nClique droit : Créer la macro",
				KICKHEAL = "[Heal] Liste",
				KICKHEALPRINT = "[Heal] Liste des Interruptions",
				KICKHEALTOOLTIP = "Décoché: @arena1-3 [Heal] la liste ne fontionne pas\nCoché: @arena1-3 [Heal] La liste fonctionne\n\nClique droit : Créer la macro",
				KICKPVP = "[PvP] Liste",
				KICKPVPPRINT = "[PvP] Liste des Interruptions",
				KICKPVPTOOLTIP = "Décoché: @arena1-3 [PvP] la liste ne fontionne pas\nCoché: @arena1-3 [PvP] La liste fonctionne\n\nClique droit : Créer la macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Coché: interrompera seulement en suivant la logic établi dans le profile LUA. Exemple:\n1) Enchaînement de contrôle sur votre heal\n2) Quelqu'un d'amical (ou vous) avait des buffs de Burst >4 sec\n3) Quelqu'un va mourir en moins de 8 sec\n4) Vous (ou @target) HP rentre en phase d'execution \nDécoché: va interrompre les sorts de la liste sans aucune sorte de logique\n\nNote: Cause une demande élevée sur le CPU\nClique droit : Créer la macro",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Ajouter une Interruption",					
				ADDERROR = "|cffff0000Vous n'avez rien préciser dans 'Ajouter un sort' ou le sort n'est pas trouvé!|r",
				ADDTOOLTIP = "Ajouter un sort depuis 'Ajouter un sort'\nDe la boite de texte à votre liste actuelle",
				REMOVE = "Retirer Interruption",
				REMOVETOOLTIP = "Retire le sort sélectionné de votre liste actuelle",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec] Configuration Checkbox",
				USEDISPEL = "Utiliser Dispel",
				USEPURGE = "Utiliser Purge",
				USEEXPELENRAGE = "Supprimer Enrage",
				HEADTITLE = "[Global] Dispel | Purge | Enrage",
				MODE = "Mode:",
				CATEGORY = "Catégorie:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel maladie",
				CURSE = "Dispel malédiction",
				MAGIC = "Dispel magique",
				MAGICMOVEMENT = "Dispel magique ralentissement/roots",
				PURGEFRIENDLY = "Purge amical",
				PURGEHIGH = "Purge ennemie (priorité haute)",
				PURGELOW = "Purge ennemie (priorité basse)",
				ENRAGE = "Supprimer Enrage",	
				BLESSINGOFPROTECTION = "Bénédiction de protection",
				BLESSINGOFFREEDOM = "Bénédiction de liberté",
				BLESSINGOFSACRIFICE = "Bénédiction de sacrifice",
				BLESSINGOFSANCTUARY = "Bénédiction de sanctuaire",	
				ROLE = "Role",
				ID = "ID",
				NAME = "Nom",
				DURATION = "Durée\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icône",					
				ROLETOOLTIP = "Rôle pour l'utiliser",
				DURATIONTOOLTIP = "Réagit à l'aura si la durée de l'aura est plus grande (>) que le temps spécifié en secondes\nIMPORTANT: les auras sans durée comme 'Faveur divine'\n(Paladin Sacrée) doivent être à 0. Cela signifie que l'aura est présente!",
				STACKSTOOLTIP = "Réagit à l'aura si le nombre de stack est plus grand ou égale (>=) au nombre de stacks spécifié",									
				BYID = "Utiliser l'ID\nplutôt que le nom",
				BYIDTOOLTIP = "Par ID, TOUT les sorts qui ont le même\nnom seront vérifier, mais qui sont des auras différentes\ncomme 'Affliction Instable'",					
				CANSTEALORPURGE = "Seulement si vous pouvez\nvolé ou purge",					
				ONLYBEAR = "Seulement si la cible\nest en 'Forme d'ours'",									
				CONFIGPANEL = " Configuration 'Ajouter une Aura'",
				ANY = "N'importe lequel",
				HEALER = "Heal",
				DAMAGER = "Tank|Dps",
				ADD = "Ajouter Aura",					
				REMOVE = "Retirer Aura",					
			},				
			[6] = {
				HEADBUTTON = "Curseur",
				HEADTITLE = "Interaction Souris",
				USETITLE = "[Each spec] Cougiration des Bouttons:",
				USELEFT = "Utiliser Clique Gauche",
				USELEFTTOOLTIP = "Cette macro utilise le survol de la souris pas bessoin de clique!\n\nClique droit : Créer la macro",
				USERIGHT = "Utiliser Clique Droit",
				LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nSi vous utiliser le code LUA dans la catégorie 'GameToolTip' alors 'thisunit' n'est pas valide\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
				BUTTON = "Cliquer",
				NAME = "Nom",
				LEFT = "Clique Gauche",
				RIGHT = "Clique Droit",
				ISTOTEM = "EstunTotem",
				ISTOTEMTOOLTIP = "Si activer cela va donner le nom si votre souris survol un totem\nAussi empêche de clic dans le cas où votre cible a déjà un totem",				
				INPUTTITLE = "Entrée le nom d'un objet (localisé!)", 
				INPUT = "Ce texte est case insensitive",
				ADD = "Ajouter",
				REMOVE = "Retirer",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem de lien d'esprit",
				HEALINGTIDETOTEM = "totem de marée de soins",
				CAPACITORTOTEM = "totem condensateur",					
				SKYFURYTOTEM = "totem fureur-du-ciel",					
				ANCESTRALPROTECTIONTOTEM = "totem de protection ancestrale",					
				COUNTERSTRIKETOTEM = "totem de réplique",
				EXPLOSIVES = "explosifs",
				-- Optional totems
				TREMORTOTEM = "totem de séisme",
				GROUNDINGTOTEM = "totem de glèbe",
				WINDRUSHTOTEM = "totem de bouffée de vent",
				EARTHBINDTOTEM = "totem de lien terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "drapeau de l’alliance",
				HORDEFLAG = "drapeau de la horde",
				NETHERSTORMFLAG = "drapeau de raz-de-néant",
				ORBOFPOWER = "orbe de puissance",
			},
			[7] = {
				HEADTITLE = "Système de Message",
				USETITLE = "[Each spec]",
				MSG = "Système MSG ",
				MSGTOOLTIP = "Coché: fonctionne\nDécoché: ne fonctionne pas\n\nClique droit : Créer la macro",
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Préviens la répétition de retrait de message de la file d'attente\nE.g. Possible de spam la macro sans que le message soit retirer\n\nClique droit : Créer la macro",
				MACRO = "Macro pour votre groupe:",
				MACROTOOLTIP = "C’est ce qui doit être envoyé au groupe de discussion pour déclencher l’action assignée sur le mot clé spécifié\nPour adresser l'action à une unité spécifique, ajoutez-les à la macro ou laissez-la telle quelle pour l'affecter à la rotation Single/AoE.\nPris en charge: raid1-40, party1-2, player, arena1-3\nUNE SEULE UNITÉ POUR UN MESSAGE!\n\nVos compagnons peuvent aussi utiliser des macros, mais attention, ils doivent être fidèles à cela!\nNE PAS LAISSER LA MACRO AUX GENS N'UTILISANT PAS CE GENRE DE PROGRAMME (RISQUE DE REPORT)!",
				KEY = "Mot clef",
				KEYERROR = "Vous n'avez pas spécifié de mot clef!",
				KEYERRORNOEXIST = "Le mot clef n'existe pas!",
				KEYTOOLTIP = "Vous devez spécifier un mot clef pour lier à une action\nVous pouvez extraire un mot clef depuis l'onglet 'Actions'",
				MATCHERROR = "le nom existe déjà, utiliser un autre!",				
				SOURCE = "Le nom de la personne à qui le dire",					
				WHOSAID = "À qui le dire",
				SOURCETOOLTIP = "Ceci est optionel. Vous pouvez le liasser vide (recommandé)\nVous pouvez le configurer, le nom doit être le même quecelui du groupe de discussion",
				NAME = "Contiens un message",
				ICON = "Icône",
				INPUT = "Entrée une phrase pour le systéme de message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "Vous n'avez pas rentré de phrase!",
				INPUTTOOLTIP = "La phrase sera déclenchée sur toute correspondance dans le chat de groupe (/party)\nCe n’est pas sensible à la casse\nContient des patterns, ce qui signifie que si la phrase est dite par des personne dans le chat raid, arène, groupe ou  par un joueur\ncela adapte l'action en fonction du groupe qui l'a dis\nVous n'avez pas besoin de préciser les pattern, ils sont utilisés comme un ajout à la macro\nSi le pattern n'est pas trouvé, les macros pour la rotation Single et AoE seront utilisé",				
			},
		},
	},
	itIT = {			
		NOSUPPORT = "questo profilo non supporta ancora ActionUI",	
		DEBUG = "|cffff0000[Debug] Identificativo di Errore: |r",			
		ISNOTFOUND = "non trovato!",			
		CREATED = "creato",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selezionato",
		RESET = "Riavvia",
		RESETED = "Riavviato",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La Macro esiste gia!|r",
		MACROLIMIT = "|cffff0000Non posso creare la macro, hai raggiunto il limite. Devi cancellare almeno una macro!|r",
		MACROINCOMBAT = "|cffff0000Impossibile creare macro in combattimento. Devi lasciare il combattimento!|r",		
		GLOBALAPI = "API Globale: ",
		RESIZE = "Ridimensiona",
		RESIZE_TOOLTIP = "Seleziona e tracina per ridimensionare",
		CLOSE = "Vicino",
		APPLY = "Applicare",
		SLASH = {
			LIST = "Lista comandi:",
			OPENCONFIGMENU = "mostra il menu di configurazione",
			HELP = "mostra info di aiuto",
			QUEUEHOWTO = "macro (toggle) per il sistema di coda (Coda), la TABLENAME é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			QUEUEEXAMPLE = "esempio per uso della Coda",
			BLOCKHOWTO = "macro (toggle) per disabilitare|abilitare le azioni (Blocco), é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			BLOCKEXAMPLE = "esempio per uso del Blocker",
			RIGHTCLICKGUIDANCE = "La maggior parte degli elementi sono pulsanti cliccabili sinistro e destro del mouse. Il pulsante destro del mouse creerà una macro, in modo che tu non possa tener conto del suggerimento di cui sopra",				
			INTERFACEGUIDANCE = "spiegazioni UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Spec Corrente] si riferisce alla CORRENTE specializzazione",
			INTERFACEGUIDANCEALLSPECS = "[Spec Tutte] si applica a TUTTE le specializzazioni di un personaggio.",
			INTERFACEGUIDANCEGLOBAL = "[Spec Globale] si applica GLOBALMENTE al tuo account TUTTI i personaggi TUTTE le specializzazioni.",
			ATTENTION = "|cffff0000FAI ATTENZIONE|r La funzionalità Action è disponibile solo per i profili rilasciati dopo il 31.05.2019. I profili precedenti verranno aggiornati in futuro.",			
			TOTOGGLEBURST = "per attivare / disattivare la modalità Burst",
			TOTOGGLEMODE = "per attivare / disattivare PvP / PvE",
			TOTOGGLEAOE = "per attivare / disattivare AoE",
		},
		TAB = {
			RESETBUTTON = "Riavvia settaggi",
			RESETQUESTION = "Sei sicuro?",
			SAVEACTIONS = "Salva settaggi Actions",
			SAVEINTERRUPT = "Salva liste Interruzioni",
			SAVEDISPEL = "Salva liste Auree",
			SAVEMOUSE = "Salva liste cursori",
			SAVEMSG = "Salva liste MSG",
			LUAWINDOW = "Configura LUA",
			LUATOOLTIP = "Per fare riferimento all unità da controllare, usa il nome senza virgolette \nIl codice deve avere un valore(true) per funzionare \nIl codice ha setfenv, significa che non devi usare Action. \n\nSe vuoi rimpiazzare il codice predefinito, devi rimpiazzare con un 'return true' senza virgolette, \n invece di cancellarlo",
			BRACKETMATCH = "Verifica parentesi",
			CLOSELUABEFOREADD = "Chiudi la configurazione LUA prima di aggiungere",
			FIXLUABEFOREADD = "Devi correggere gli errori nella configurazione LUA prima di aggiungere",
			RIGHTCLICKCREATEMACRO = "Pulsanmte destro: Crea macro",
			NOTHING = "Il profilo non ha una configuration per questo tab",
			HOW = "Applica:",
			HOWTOOLTIP = "Global: Tutto account, tutti i personaggi e tutte le specializzazioni",
			GLOBAL = "Globale",
			ALLSPECS = "A tutte le specializzazioni di un personaggio",
			THISSPEC = "Alla specializzazione corrente del personaggio",			
			KEY = "Chiave:",
			CONFIGPANEL = "'Aggiungi' Configurazione",
			[1] = {
				HEADBUTTON = "Generale",	
				HEADTITLE = "[Spec Tutte] Primaria",
				PVEPVPTOGGLE = "PvE / PvP interruttore manuale",
				PVEPVPTOGGLETOOLTIP = "Forza il cambio di un profilo\n(utile quando Modalitá guerra é attiva)\n\nTastodestro: Crea macro", 
				PVEPVPRESETTOOLTIP = "Resetta interruttore manuale - auto",
				CHANGELANGUAGE = "Cambia Lingua",
				CHARACTERSECTION = "Seleziona personaggio",
				AUTOTARGET = "Bersaglio automatico",
				AUTOTARGETTOOLTIP = "Se il bersaglio non é selezionato e sei in combattimento, ritorna il nemico piú vicino\nInterruttore funziona nella stesso modo se il bersaglio selezionato é immune|non in PvP\n\nTastodestro: Crea macro",					
				POTION = "Pozione",
				HEARTOFAZEROTH = "Cuore di Azeroth",
				RACIAL = "Abilitá Raziale",
				STOPCAST = "Smetti di lanciare",
				SYSTEMSECTION = "Area systema",
				LOSSYSTEM = "Sistema di linea di vista [LOS]",
				LOSSYSTEMTOOLTIP = "ATTENZIONE: Questa opzione causa un ritardo di 0.3s + piu tempo del sistema di recupero globale [srg]\nse il bersaglio é in los (per esempio dietro una cassa in arena)\nDevi anche abilitare lo stesso settaggio in Settaggi Avanzati\nQuesta opzione mette in blacklists bersagli fuori los e\nferma le azioni verso il bersaglio per N secondio\n\nTastodestro: Crea macro",
				HEALINGENGINEPETS = "Logica di cure per pet",
				HEALINGENGINEPETSTOOLTIP = "include nella selezione dei bersagli  i pets dei giocatori e considera la loro cura \n\nTastodestro: Crea macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Fermerà i danni dannosi ai nemici\nSe hanno CC come Polymorph\nNon annulla l'attacco automatico!\n\nTastodestro: Crea macro",
				ALL = "Tutti",
				RAID = "Raid",
				TANK = "Solo Tank",
				DAMAGER = "Solo Danno",
				HEALER = "Solo Curatori",
				HEALINGENGINETOOLTIP = "Opzione per la selezione bersagli per i curatori\nTutti: Tutti i membri\nRaid: Tutti i membri ma non i tank\n\nTastodestro: Crea macro\nSe desideri utilizzare specifici attributi per il bersaglio usa in (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",
				DBM = "Timers DBM",
				DBMTOOLTIP = "Tiene traccia dei timer di avvio combattimento e alcuni eventi specific tipo patrol in arrivo.\nQuesta funzionalitá é disponibile per tutti i profili!\n\nTastodestro: Crea macro",
				FPS = "Ottimizzazione FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Aumenta i frames per second incrementando la dipendenza dinamica\ndei frames del ciclo di refresh (call) della rotazione\n\nPuoi settare manualmente l'intervallo seguendo questa semplice regola:\nPiú é altop lo slider piú é l'FPS, ma peggiore sará l'update della rotazione\nValori troppo alti possono portare a risultati imprevedibili!\n\nTastodestro: Crea macro",					
				PVPSECTION = "Sezione PvP",
				REFOCUS = "Identifica il focus precedente @focus\n(solo arena unitá 1-3)\nraccomandato contro le classi con capacitá di invisibilitá\n\nTastodestro: Crea macro",
				RETARGET = "Identifica il bersaglio precedente @target\n(solo arena unitá 1-3)\nraccomandato contro cacciatori con capacitá 'Morte Fasulla' e altre abilitá che deselezionano il bersaglio\n\nTastodestro: Crea macro",
				TRINKETS = "Ninnolo",
				TRINKET = "Ninnoli",
				BURST = "Modalitá raffica",
				BURSTTOOLTIP = "Utilizza Tutto - appena esce dal coll down\nAuto - Boss o Giocatore\nOff - Disabilitata\n\nTastodestro: Crea macro\nSe desidere utilizzare specifici attributi utilizza in (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Pozione di Cura Abissale",
				HEALTHSTONETOOLTIP = "Seta la percentuale di vita (HP)\n\nTastodestro: Crea macro",
				COLORTITLE = "Color Picker",
				COLORUSE = "Usa colore personalizzato",
				COLORUSETOOLTIP = "Commutazione tra colori predefiniti e personalizzati",
				COLORELEMENT = "Elemento",
				COLOROPTION = "Opzione",
				COLORPICKER = "Picker",
				COLORPICKERTOOLTIP = "Fare clic per aprire la finestra di configurazione per 'Elemento' selezionato > 'Opzione'\nTasto destro del mouse per spostare la finestra aperta",
				FONT = "Font",
				NORMAL = "Normale",
				DISABLED = "Disabilitato",
				HEADER = "Intestazione",
				SUBTITLE = "Sottotitolo",
				TOOLTIP = "Tooltip",
				BACKDROP = "Fondale",
				PANEL = "Pannello",
				SLIDER = "Slider",
				HIGHLIGHT = "Evidenziare",
				BUTTON = "Pulsante",
				BUTTONDISABLED = "Pulsante Disabilitato",
				BORDER = "Confine",
				BORDERDISABLED = "Confine Disabilitato",	
				PROGRESSBAR = "Barra di avanzamento",
				COLOR = "Colore",
				BLANK = "Vuoto",
				SELECTTHEME = "Seleziona Tema pronto",
				THEMEHOLDER = "scegli il tema",
				BLOODYBLUE = "Sanguinoso Blu",
				PAUSECHECKS = "[All specs] Rotation doesn't work if:",
				VEHICLE = "NelVeicolo",
				VEHICLETOOLTIP = "Esempio: Catapulta, Cannone",
				DEADOFGHOSTPLAYER = "Sei Morto",
				DEADOFGHOSTTARGET = "Il bersaglio é morto",
				DEADOFGHOSTTARGETTOOLTIP = "Eccezione il cacciatore bersaglio se é selezionato come bersaglio primario",
				MOUNT = "ACavallo",
				COMBAT = "Non in combattimento", 
				COMBATTOOLTIP = "Se tu e il tuo bersaglio siete non in combattimento. l' invisibile non viene considerato\n(quando invisibile questa condizione viene non valutata|saltata)",
				SPELLISTARGETING = "IncantesimoHaBersaglio",
				SPELLISTARGETINGTOOLTIP = "Esembio: Tormento, Balzo eroico, Trappola congelante",
				LOOTFRAME = "Bottino",
				EATORDRINK = "Sta mangiando o bevendo",
				MISC = "Varie:",		
				DISABLEROTATIONDISPLAY = "Nascondi|Mostra la rotazione",
				DISABLEROTATIONDISPLAYTOOLTIP = "Nasconde il gruppo, che generalmente siu trova al\ncentro in basso dello schermo",
				DISABLEBLACKBACKGROUND = "Nascondi lo sfondo nero", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Nasconde lo sfondo nero nell'angolo in alto a sinistra dello schermo\nATTENZIONE: puo causare comportamenti anomali della applicazione!",
				DISABLEPRINT = "Nascondi|Stampa",
				DISABLEPRINTTOOLTIP = "Nasconde notifice di chat per tutto\nATTENZIONE: Questa opzione nasconde anche le notifiche [Debug] Identificazione errori!",
				DISABLEMINIMAP = "Nasconde icona nella minimap",
				DISABLEMINIMAPTOOLTIP = "Nasconde l'icona di questa UI dalla minimappa",
				DISABLEPORTRAITS = "Nascondi ritratto di classe",
				DISABLEROTATIONMODES = "Nascondi le modalità di rotazione",
				DISABLESOUNDS = "Disabilita i suoni",
				HIDEONSCREENSHOT = "Nascondi sullo screenshot",
				HIDEONSCREENSHOTTOOLTIP = "Durante lo screenshot nasconde tutti i frame TellMeWhen\ne Action, quindi li mostra di nuovo",
			},
			[3] = {
				HEADBUTTON = "Azioni",
				HEADTITLE = "Blocco | Coda",
				ENABLED = "Abilitato",
				NAME = "Nome",
				DESC = "Nota",
				ICON = "Icona",
				SETBLOCKER = "Setta\nBlocco",
				SETBLOCKERTOOLTIP = "Blocca l'azione selezionata da esser eseguta nella rotazione\nNon verrá usata in nessuna condizione\n\nTastodestro: Crea macro",
				SETQUEUE = "Set\nCoda",
				SETQUEUETOOLTIP = "Accoda l'azione selezionata alla rotazione\nUtilizza l'azione appena é possibile\n\nTastodestro: Crea macro\nPuoi passare ulteriori condizioni nella macro creata per la coda\nCome ad esempio quale unit utilizzare (UnitID è chiave), esempio: { Priority = 1, UnitID = 'player' }\nÈ possibile trovare chiavi accettabili con descrizione nella funzione 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloccato: |r",
				UNBLOCKED = "|cff00ff00Sbloccato: |r",
				KEY = "[Chiave: ",
				KEYTOTAL = "[Totale coda: ",
				KEYTOOLTIP = "Usa questa chiave nel tab MSG",
				ISFORBIDDENFORBLOCK = "non può esser messo in blocco!",
				ISFORBIDDENFORQUEUE = "non può esser messo in coda!",
				ISQUEUEDALREADY = "esiste giá nella coda!",
				QUEUED = "|cff00ff00Nella Coda: |r",
				QUEUEREMOVED = "|cffff0000Rimosso dalla Coda: |r",
				QUEUEPRIORITY = " ha prioritá #",
				QUEUEBLOCKED = "|cffff0000non può essere in Coda perché é giá bloccato!|r",
				SELECTIONERROR = "|cffff0000Non hai selezionato una riga!|r",
				AUTOHIDDEN = "[All specs] Nascondi automaticamente le azioni non disponibili",
				AUTOHIDDENTOOLTIP = "Rende la Tabella di Scorrimento più piccola e chiara per nascondere l'immagine\nAd esempio, la classe personaggio ha poche razze ma può usarne una, questa opzione nasconderà altre razze\nSolo per una visione confortevole",
				CHECKSPELLLVL = "[All specs] Verifica il livello richiesto",
				CHECKSPELLLVLTOOLTIP = "Tutti gli spell non disponibilit dat il livello del personaggio sono bloccati\nTorneranno disponibili non appena il personaggio raggiunge il livello richiesto",
				CHECKSPELLLVLERROR = "Giá inizializzato!",
				CHECKSPELLLVLERRORMAXLVL = "Sel al livello MAX possibile!",
				CHECKSPELLLVLMACRONAME = "VerificaLivello",
				LUAAPPLIED = "LUA code é applicato a ",
				LUAREMOVED = "LUA code é rimosso da ",
			},
			[4] = {
				HEADBUTTON = "Interruzioni",	
				HEADTITLE = "Profile per le interruzioni",					
				ID = "ID",
				NAME = "Nome",
				ICON = "Icona",
				CONFIGPANEL = "'Aggiungi Interruzione' Configurazione",
				INTERRUPTFRONTSTRINGTITLE = "Seleziona lista:",
				INTERRUPTTOOLTIP = "[Principale] per bersagli @target/@mouseover/@targettarget\n[Cura] per bersagli @arena1-3 (curatore)\n[PvP] per bersagli @arena1-3 (Controllo bersagli)\n\nPuoi settare differenti timer per [Cura] and [PvP] (non un questa UI)",
				INPUTBOXTITLE = "Srivi Incantesimo :",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): cancella incantesimo e rimuove il focus",
				INTEGERERROR = "Errore Integer overflow > tentativo di memorizzare piú di 7 numeri", 
				SEARCH = "Cerca per nome o ID ",
				TARGETMOUSEOVERLIST = "[Principale] Lista",
				TARGETMOUSEOVERLISTTOOLTIP = "Non selezionato: interroperá QUALSIASI incantesimo a caso\nSelezionato: interromperá solo scecifiche liste se @target/@mouseover/@targettarget\nNota: in PvP interromperá gli spell della lista se selezionato, altrimeti solo healers se moriranno in meno di 3-4 sec!\n\n@mouseover/@targettarget sono opzionali e dipendono dalle selezioni fatte nella sezione spec\n\nTastodestro: Crea macro",
				KICKTARGETMOUSEOVER = "[Principale] Interruzioni\nAbilitato",					
				KICKTARGETMOUSEOVERTOOLTIP = "Non selezionato: @target/@mouseover le interruzioni non funzionano\nSelezionato: @target/@mouseover le interruzioni funzionano\n\nTastodestro: Crea macro",					
				KICKHEALONLYHEALER = "[Cura] Solo curatori",					
				KICKHEALONLYHEALERTOOLTIP = "Non selezionato: la lista sará valida per ogni specializzazione del bersaglio\n(e.g. Ench, Elem, SP, Retri)\nSelezionato: la lista sará valida solo per i bersagli curatori\n\nTastodestro: Crea macro",
				KICKHEAL = "[Cura] Lista",
				KICKHEALPRINT = "[Cura] Lista delle interruzioni",
				KICKHEALTOOLTIP = "Non selezionato: @arena1-3 [Cura] lista custom non attiva\nSelezionato: @arena1-3 [Cura] lista custom attiva\n\nTastodestro: Crea macro",
				KICKPVP = "[PvP] Lista",
				KICKPVPPRINT = "[PvP] Lista delle interruzioni",
				KICKPVPTOOLTIP = "Non selezionato: @arena1-3 [PvP] lista custom non attiva\nSelezionato: @arena1-3 [PvP] lista custom attiva\n\nTastodestro: Crea macro",	
				KICKPVPONLYSMART = "[PvP] SMART",
				KICKPVPONLYSMARTTOOLTIP = "Selezionato: interompe seguendo la logica definita nella configurazione del profilo. Esempio:\n1) Controllo a catena sul curatore\n2) Bersaglio amico (o tu) ha il raffica di buff con tempo residuo >4 sec\n3) Qualcuno muore in meno di 8 sec\n4) I punti vita tuoi (o @target) vengono considerati\nnon selezionato: interrompe sempre gli incantesimi nella lista senza ulteriori logiche\n\nNota: può causare un alto uso della CPU\nTastodestro: Crea macro",
				USEKICK = "Calcio",
				USECC = "CC",
				USERACIAL = "Razziale",
				ADDERROR = "|cffff0000Non hai specificato niente in 'Scrivi Incantesimo' o l'incantesimo non é stato trovato!|r",
				ADD = "Aggiungi Interruzione",					
				ADDTOOLTIP = "Aggiungi incantesimo indicato in 'Scrivi Incantesimo'\nalla lista selezionata",
				REMOVE = "Rimuovi Interruzione",
				REMOVETOOLTIP = "Rimuovi l'incantesimo alla riga selezionata della lista",
			},
			[5] = { 	
				HEADBUTTON = "Auree",					
				USETITLE = "[Each spec] Configurazione",
				USEDISPEL = "Usa Dissoluzione",
				USEPURGE = "Usa Epurazione",
				USEEXPELENRAGE = "Usa Enrage",
				HEADTITLE = "[Globale] Dissoluzione | Epurazione | Enrage",
				MODE = "Modo:",
				CATEGORY = "Categoria:",
				POISON = "Dissolvi Veleni",
				DISEASE = "Dissolvi Malattie",
				CURSE = "Dissolvi Maledizioni",
				MAGIC = "Dissolvi Magia",
				MAGICMOVEMENT = "Dissolvi magia rallentamento/radici",
				PURGEFRIENDLY = "Epura amico",
				PURGEHIGH = "Epura nemico (alta prioritá)",
				PURGELOW = "Epura nemico  (bassa prioritá)",
				ENRAGE = "Expel Enrage",	
				BLESSINGOFPROTECTION = "Benedizione della Protezione",
				BLESSINGOFFREEDOM = "Benedizione della Libertà",
				BLESSINGOFSACRIFICE = "Benedizione del Sacrificio",
				BLESSINGOFSANCTUARY = "Benedizione del Santuario",	
				ROLE = "Ruolo",
				ID = "ID",
				NAME = "Nome",
				DURATION = "Durata\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icona",					
				ROLETOOLTIP = "Il tuo ruolo per usarla",
				DURATIONTOOLTIP = "Reazione all'aura se la durata é maggiore di (>) secondi specificati\nIMPORTANTE: Auree senza una durata come 'Favore Divino'\n(Paladino della luce) devono essere a 0. Questo indica che l'aura é presente!",
				STACKSTOOLTIP = "Reazione all'aura se la durata é maggiore o eguale a (>=) degli stack specificati",									
				BYID = "Utilizza ID\ninvece del nome",
				BYIDTOOLTIP = "L'ID deve testare TUTTE gli incantesimi\nche hanno lo stesso nome, ma hanno diversi livelli\ncome 'Afflizione Instabile'",					
				CANSTEALORPURGE = "Solo se può\nrubare o epurare",					
				ONLYBEAR = "Solo se bersaglio\nin 'Forma D'Orso'",									
				CONFIGPANEL = "'Aggiungi Aura' Configurazione",
				ANY = "Qualsiasi",
				HEALER = "Curatore",
				DAMAGER = "Tank|Danno",
				ADD = "Aggiungi Aura",					
				REMOVE = "Rimuovi Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursore",
				HEADTITLE = "Interazione con mouse",
				USETITLE = "[Spec Corrente] Configurazione pulsanti:",
				USELEFT = "Utilizza click sinistro",
				USELEFTTOOLTIP = "Utilizza macro /target mouseover che non é un click!\n\nTastodestro: Crea macro",
				USERIGHT = "Utilizza click destro",
				LUATOOLTIP = "Per fare riferimento all'unitá da controllare, utilizza 'thisunit' senza virgolette\nSe usi LUA nella categoria 'GameToolTip' questa unitaá non é allora valida\nIl codice deve avere un ritorno logico (vero) perche sia attivato\nQuesto codice ha setfenv questo significa che non hai bisogno di usare Action.\n\nSe vuoi rimuovere il codice predefinito, devi scrivere 'return true' senza virgolette\ninvece di una semplice eliminazione",							
				BUTTON = "Click",
				NAME = "Nome",
				LEFT = "Click sinistro",
				RIGHT = "Click Destro",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "Se abilitato, controlla @mouseover per il tipo 'Totem' con il nome specificato\nPreviene anche il cast nel caso il totem @target sia giá presente",				
				INPUTTITLE = "inserisci il nome dell'oggetto (nella lingua di gioco!)", 
				INPUT = "Questo inserimento non é influenzato da maiuscole|minuscole",
				ADD = "Aggiungi",
				REMOVE = "Rimuovi",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem del collegamento spirituale",
				HEALINGTIDETOTEM = "totem della marea curativa",
				CAPACITORTOTEM = "totem della condensazione elettrica",					
				SKYFURYTOTEM = "totem della furia del cielo",					
				ANCESTRALPROTECTIONTOTEM = "totem del risveglio ancestrale",					
				COUNTERSTRIKETOTEM = "totem del controassalto",
				EXPLOSIVES = "esplosivi",
				-- Optional totems
				TREMORTOTEM = "totem del tremore",
				GROUNDINGTOTEM = "totem dell'adescamento magico",
				WINDRUSHTOTEM = "totem del soffio di vento",
				EARTHBINDTOTEM = "totem del vincolo terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "bandiera dell'alleanza",
				HORDEFLAG = "bandiera dell'orda",
				NETHERSTORMFLAG = "bandiera di landa fatua",
				ORBOFPOWER = "globo del potere",
			},
			[7] = {
				HEADTITLE = "Messaggio di sistema",
				USETITLE = "[Spec Corrente]",
				MSG = "MSG Sistema",
				MSGTOOLTIP = "Selezionato: attivo\nNon selezionato: non attivo\n\nTastodestro: Crea macro",
				DISABLERETOGGLE = "Blocca Coda Rimuovi",
				DISABLERETOGGLETOOLTIP = "Previeni l'eliminazione di un incantesimo dalla coda con un messaggio ripetuto\nEsempio, consente di inviare una macro spam senza rischiare eliminazioni non volute\n\nTastodestro: Crea macro",
				MACRO = "Macro per il tuo gruppo:",
				MACROTOOLTIP = "Questo è ciò che dovrebbe alla chat di gruppo per attivare l'azione assegnata ad una chiave specifica\nPer indirizzare un'azione a una unitá specifica, aggiungerlo alla macro o lasciala così com'è per l'utilizzo in rotazione singola/AoE\nSupportati: raid1-40, party1-2, giocatore, arena1-3\nSOLO UN'UNITÀ PER MESSAGGIO!\n\nI tuoi compagni possono usare anche loro macro, ma fai attenzione, devono essere macro allineate!",
				KEY = "Chiave",
				KEYERROR = "Non hai specificato una chiave!",
				KEYERRORNOEXIST = "la chiave non esite!",
				KEYTOOLTIP = "Devi specificare una chiave per vincolare l'azione\nPuoi verificare|leggere lachiave nel Tab 'Azioni'",
				MATCHERROR = "il nome che stai usando esiste giá, usane un altro!",				
				SOURCE = "Il nomme della persona che ha detto",
				WHOSAID = "Che ha detto",
				SOURCETOOLTIP = "Opzionale. Puoi lasciarlo vuoto (raccomndato)\nSe vuoi configurarlo, il nome deve essere esattamente lo stesso indicato nella chat del gruppo",
				NAME = "Contiene un messaggio",
				ICON = "Icona",
				INPUT = "Inserire una frase da usare come messaggio di sistema",
				INPUTTITLE = "Frase",
				INPUTERROR = "Non hai inserito una frase!",
				INPUTTOOLTIP = "La frase verrà attivata in corrispondenza ai riscontri nella chat di gruppo(/party)\nNon é sensibile alle maiuscole\nIdentifica pattern, ciò significa che una frase scritta in chat con la combinazione delle parole raid, party, arena, party o giocatore\nattiva l'azione nel meta slot desiderato\nNon hai bisogno di impostare i pattern elencati, sono usati on top alla macro\nIf non trova nessun pattern, allora verra usato lo slot per rotazione Singola e ad area",				
			},
		},
	},
	esES = {			
		NOSUPPORT = "No soportamos este perfil ActionUI todavía",	
		DEBUG = "|cffff0000[Debug] Error identificado: |r",			
		ISNOTFOUND = "no encontrado!",			
		CREATED = "creado",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Cambiar",
		SELECTED = "Seleccionado",
		RESET = "Reiniciar",
		RESETED = "Reiniciado",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro ya existe!|r",
		MACROLIMIT = "|cffff0000No se puede crear la macro, límite alcanzado. Debes borrar al menos una macro!|r",
		MACROINCOMBAT = "|cffff0000No se puede crear macro en combate. Necesitas salir del combate!|r",
		GLOBALAPI = "API Global: ",
		RESIZE = "Redimensionar",
		RESIZE_TOOLTIP = "Click-y-arrastrar para redimensionar",
		CLOSE = "Cerca",
		APPLY = "Aplicar",
		SLASH = {
			LIST = "Lista de comandos:",
			OPENCONFIGMENU = "Mostrar menú de configuración",
			HELP = "Mostrar ayuda",
			QUEUEHOWTO = "macro (toggle) para sistema de secuencia (Cola), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			QUEUEEXAMPLE = "ejemplo de uso de Cola",
			BLOCKHOWTO = "macro (toggle) para deshabilitar|habilitar cualquier acción (Blocker), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			BLOCKEXAMPLE = "ejemplo de uso de Blocker",
			RIGHTCLICKGUIDANCE = "La mayoría de elementos son usables con el botón izquierdo y derecho del ratón. El botón derecho del ratón creará un macro toggle por lo que puedes considerar la sugerencia anterior",				
			INTERFACEGUIDANCE = "Explicación de la UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] relativa a la ACTUAL especialización seleccionada",
			INTERFACEGUIDANCEALLSPECS = "[All specs] relativa a TODAS las especializaciones disponibles de tus personajes",
			INTERFACEGUIDANCEGLOBAL = "[Global] relativa a toda tu cuenta, TODOS los personajes, TODAS las especializaciones",
			ATTENTION = "|cffff0000ATENCIÓN|r Acción funcional solo para perfiles creados después del 31.05.2019. Los perfiles antiguos serán actualizados para este sistema en el futuro",			
			TOTOGGLEBURST = "para alternar el modo de ráfaga",
			TOTOGGLEMODE = "para alternar PvP / PvE",
			TOTOGGLEAOE = "para alternar AoE",
		},
		TAB = {
			RESETBUTTON = "Reiniciar ajustes",
			RESETQUESTION = "¿Estás seguro?",
			SAVEACTIONS = "Guardar ajustes de Acciones",
			SAVEINTERRUPT = "Guardar Lista de Interrupciones",
			SAVEDISPEL = "Guardar Lista de Auras",
			SAVEMOUSE = "Guardar Lista de Cursor",
			SAVEMSG = "Guardar Lista de Mensajes",
			LUAWINDOW = "Configurar LUA",
			LUATOOLTIP = "Para referirse a la unidad de comprobación, usa 'thisunit' sin comillas\nEl código debe tener retorno boolean (true) para procesar las condiciones\nEste código tiene setfenv que significa lo que no necesitas usar Action. para cualquier cosa que tenga it\n\nSi quieres borrar un codigo default necesitas escribir 'return true' sin comillas en vez de removerlo todo",
			BRACKETMATCH = "Correspondencia de corchetes",
			CLOSELUABEFOREADD = "Cerrar las configuración de LUA antes de añadir",
			FIXLUABEFOREADD = "Debes arreglas los errores en la Configuración de LUA antes de añadir",
			RIGHTCLICKCREATEMACRO = "ClickDerecho: Crear macro",
			NOTHING = "El Perfil no tiene configuración para este apartado",
			HOW = "Aplicar:",
			HOWTOOLTIP = "Global: Todas las cuentas, personajes y especializaciones",
			GLOBAL = "Global",
			ALLSPECS = "Para todas las especializaciones del personaje",
			THISSPEC = "Para la especialización actual del personaje",			
			KEY = "Tecla:",
			CONFIGPANEL = "'Añadir' Configuración",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Each spec] Primaria",
				PVEPVPTOGGLE = "PvE / PvP Mostrar Manual",
				PVEPVPTOGGLETOOLTIP = "Forzar un perfil a cambiar a otro modo\n(especialmente útil cuando el War Mode está ON)\n\nClickDerecho: Crear macro", 
				PVEPVPRESETTOOLTIP = "Reiniciar mostrar manual a selección automática",
				CHANGELANGUAGE = "Cambiar idioma",
				CHARACTERSECTION = "Sección de Personaje",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "Si el target está vacío, pero estás en combate, devolverá el que esté más cerca\nEl cambiador funciona de la misma manera si el target tiene inmunidad en PvP\n\nClickDerecho: Crear macro",					
				POTION = "Poción",
				HEARTOFAZEROTH = "Corazón de Azeroth",
				RACIAL = "Habilidad Racial",
				STOPCAST = "Deja de lanzar",
				SYSTEMSECTION = "Sección del sistema",
				LOSSYSTEM = "Sistema LOS",
				LOSSYSTEMTOOLTIP = "ATENCIÓN: Esta opción causa un delay de 0.3s + un giro actual de gcd\nsi la unidad está siendo comprobada esta se localizará como pérdida (por ejemplo, detrás de una caja en la arena)\nDebes también habilitar las mismas opciones en Opciones Avanzadas\nEsta opción pone en una lista negra la unidad con perdida y\n deja de producir acciones a esta durante N segundos\n\nClickDerecho: Crear macro",
				HEALINGENGINEPETS = "Motor de Curación para Pets",
				HEALINGENGINEPETSTOOLTIP = "Incluída en el target de las pets del jugador y calcula para curarles\n\nClickDerecho: Crear macro",
				STOPATBREAKABLE = "Detener el daño en el descanso",
				STOPATBREAKABLETOOLTIP = "Detendrá el daño dañino en los enemigos\nSi tienen CC como Polymorph\nNo cancela el ataque automático!\n\nClickDerecho: Crear macro",
				ALL = "Todo",
				RAID = "Raid",
				TANK = "Solo Tanques",
				DAMAGER = "Solo Damage Dealers",
				HEALER = "Solo Healers",
				HEALINGENGINETOOLTIP = "Esta opción relativa a selección de unidad en curación\nTodo: todos los miembros\nRaid: Todos los miembros sin tanques\n\nClickDerecho: Crear macro\nSi quieres establecer el estado de conmutación fija usa el argumento en (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",
				DBM = "Tiempos DBM",
				DBMTOOLTIP = "Rastrea tiempos de pull y algunos eventos específicos como la basura que pueda venir.\nEsta característica no está disponible para todos los perfiles!\n\nClickDerecho: Crear macro",
				FPS = "Optimización de FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Incrementa los frames por segundo aumentando la dependencia dinámica\nframes del ciclo de recarga (llamada) del ciclo de rotación\n\nTambién puedes establecer manualmente el intervalo siguiendo una regla simple:\nCuanto mayor sea el desplazamiento, mayor las FPS, pero peor actualización de rotación\nUn valor demasiado alto puede causar un comportamiento impredecible!\n\nClickDerecho: Crear macro",					
				PVPSECTION = "Sección PvP",
				REFOCUS = "Devuelve el guardado anterior @focus\n(arena1-3 unidades solamente)\nEs recomendable contra clases con invisibilidad\n\nClickDerecho: Crear macro",
				RETARGET = "Devuelve el guardado anterior @target\n(arena1-3 unidades solamente)\nEs recomendable contra cazadores con 'Feign Death' and cualquier objetivo imprevisto cae\n\nClickDerecho: Crear macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Modo Bursteo",
				BURSTTOOLTIP = "Todo - En cooldown\nAuto - Boss o Jugadores\nOff - Deshabilitado\n\nClickDerechohabilitado\n\nClickDerecho: Crear macro\nSi quieres establecer el estado de conmutación fija usa el argumento en (ARG): 'Everything', 'Auto', 'Off'",					
				HEALTHSTONE = "Healthstone | Poción de sanación abisal",
				HEALTHSTONETOOLTIP = "Establecer porcentaje de vida (HP)\n\nClickDerecho: Crear macro",
				COLORTITLE = "Selector de color",
				COLORUSE = "Usar color personalizado",
				COLORUSETOOLTIP = "Cambiar entre colores predeterminados y personalizados",
				COLORELEMENT = "Elemento",
				COLOROPTION = "Opción",
				COLORPICKER = "Recogedor",
				COLORPICKERTOOLTIP = "Haga clic para abrir la ventana de configuración para su 'Elemento'> 'Opción' seleccionado\nBotón derecho del mouse para mover la ventana abierta",
				FONT = "Fuente",
				NORMAL = "Normal",
				DISABLED = "Discapacitado",
				HEADER = "Encabezamiento",
				SUBTITLE = "Subtitular",
				TOOLTIP = "Información sobre herramientas",
				BACKDROP = "Fondo",
				PANEL = "Panel",
				SLIDER = "Control deslizante",
				HIGHLIGHT = "Realce",
				BUTTON = "Botón",
				BUTTONDISABLED = "Botón Discapacitado",
				BORDER = "Frontera",
				BORDERDISABLED = "Frontera Discapacitado",	
				PROGRESSBAR = "Barra de progreso",
				COLOR = "Color",
				BLANK = "Blanco",
				SELECTTHEME = "Seleccionar Tema Listo",
				THEMEHOLDER = "escoge un tema",
				BLOODYBLUE = "Sangriento Azul",
				PAUSECHECKS = "[All specs] La rotación no funciona si:",
				VEHICLE = "En Vehículo",
				VEHICLETOOLTIP = "Ejemplo: Catapulta, arma de fuego",
				DEADOFGHOSTPLAYER = "Estás muerto",
				DEADOFGHOSTTARGET = "El Target está muerto",
				DEADOFGHOSTTARGETTOOLTIP = "Excepción a enemigo hunter if seleccionó como objetivo principal",
				MOUNT = "En montura",
				COMBAT = "Fuera de comabte", 
				COMBATTOOLTIP = "Si tu y tu target estáis fuera de combate. Invisible es una excepción\n(mientras te mantengas en sigilo esta condición se omitirá)",
				SPELLISTARGETING = "Hechizo está apuntando",
				SPELLISTARGETINGTOOLTIP = "Ejemplo: Blizzard, Salto heroico, Trampa de congelación",
				LOOTFRAME = "Frame de botín",
				EATORDRINK = "Está comiendo o bebiendo",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Esconder mostrar rotación",
				DISABLEROTATIONDISPLAYTOOLTIP = "Esconder el grupo, que está ubicado normalmente en la\nparte inferior central de la pantalla",
				DISABLEBLACKBACKGROUND = "Esconder fondo negro", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Esconder el fondo negro en la esquina izquierda\nATENCIÓN: Esto puede causar comportamientos impredecibles!",
				DISABLEPRINT = "Esconder impresión",
				DISABLEPRINTTOOLTIP = "Esconder notificaciones de chat de todo\nATENCIÓN: Esto también esconderá [Debug] Error Identificado!",
				DISABLEMINIMAP = "Esconder icono en el minimapa",
				DISABLEMINIMAPTOOLTIP = "Esconder icono de esta UI en el minimapa",
				DISABLEPORTRAITS = "Ocultar retrato de clase",
				DISABLEROTATIONMODES = "Ocultar modos de rotación",
				DISABLESOUNDS = "Desactivar sonidos",
				HIDEONSCREENSHOT = "Ocultar en captura de pantalla",
				HIDEONSCREENSHOTTOOLTIP = "Durante la captura de pantalla, se ocultan todos los cuadros de TellMeWhen\ny Action, y luego se muestran de nuevo",
			},
			[3] = {
				HEADBUTTON = "Acciones",
				HEADTITLE = "Bloquear | Cola",
				ENABLED = "Activado",
				NAME = "Nombre",
				DESC = "Nota",
				ICON = "Icono",
				SETBLOCKER = "Establecer\nBloquear",
				SETBLOCKERTOOLTIP = "Esto bloqueará la acción seleccionada en la rotación\nNunca la usará\n\nClickDerecho: Crear macro",
				SETQUEUE = "Establecer\nCola",
				SETQUEUETOOLTIP = "Pondrá la acción en la cola de rotación\nLo usará lo antes posible\n\nClickDerecho: Crear macro\nPuede pasar condiciones adicionales en la macro creada para la cola\nComo en qué unit usar (UnitID es la clave), ejemplo: { Priority = 1, UnitID = 'player' }\nPuede encontrar claves aceptables con descripción en la función 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqueado: |r",
				UNBLOCKED = "|cff00ff00Desbloqueado: |r",
				KEY = "[Tecla: ",
				KEYTOTAL = "[Cola Total: ",
				KEYTOOLTIP = "Usa esta tecla en la pestaña MSG",
				ISFORBIDDENFORBLOCK = "está prohibido ponerlo en bloquear!",
				ISFORBIDDENFORQUEUE = "está prohibido ponerlo en cola!",
				ISQUEUEDALREADY = "ya existe en la cola!",
				QUEUED = "|cff00ff00Cola: |r",
				QUEUEREMOVED = "|cffff0000Borrado de la cola: |r",
				QUEUEPRIORITY = " tiene prioridad #",
				QUEUEBLOCKED = "|cffff0000no puede añadirse a la cola porque SetBlocker lo ha bloqueado!|r",
				SELECTIONERROR = "|cffff0000No has seleccionado una fila!|r",
				AUTOHIDDEN = "[All specs] AutoOcultar acciones no disponibles",
				AUTOHIDDENTOOLTIP = "Hace que la tabla de desplazamiento sea más pequeña y clara ocultándola visualmente\nPor ejemplo, el tipo de personaje tiene pocos racials pero puede usar uno, esta opción hará que se escondan los demás raciales\nPara que sea más cómodo visualmente",				
				CHECKSPELLLVL = "[All specs] Comprueba el nivel requerido de la habilidad",
				CHECKSPELLLVLTOOLTIP = "Todas las habilidades que no estén disponibles por el nivel del personaje serán bloqueadas\nSerán actualizadas cada vez que se sube de nivel",
				CHECKSPELLLVLERROR = "Ya inicializado!",
				CHECKSPELLLVLERRORMAXLVL = "Estás al MÁXIMO nivel posible!",
				CHECKSPELLLVLMACRONAME = "Comprueba el nivel de la habilidad",
				LUAAPPLIED = "El código LUA ha sido aplicado a ",
				LUAREMOVED = "El código LUA ha sido removido de ",
			},
			[4] = {
				HEADBUTTON = "Interrupciones",	
				HEADTITLE = "Perfil de Interrupciones",					
				ID = "ID",
				NAME = "Nombre",
				ICON = "Icono",
				CONFIGPANEL = "'Añadir Interrupción' Configuración",
				INTERRUPTFRONTSTRINGTITLE = "Seleccionar lista:",
				INTERRUPTTOOLTIP = "[Main] para unidades @target/@mouseover/@targettarget\n[Heal] para unidades @arena1-3 (healing)\n[PvP] para unidades @arena1-3 (controlmultitud)\n\nPuedes establecer diferentes tiempos para [Heal] y [PvP] (no en esta UI)",
				INPUTBOXTITLE = "Escribir habilidad:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): limpiar texto y borrar focus",
				INTEGERERROR = "Desbordamiento de enteros intentando almacenar > 7 números", 
				SEARCH = "Buscar por nombre o ID",
				TARGETMOUSEOVERLIST = "[Main] Lista",
				TARGETMOUSEOVERLISTTOOLTIP = "Desmarcado: interrumpirá CUALQUIER cast de forma aleatoria\nMarcado: interrumpirá solamente la lista específica de @target/@mouseover/@targettarget\nNota: en PvP se solucionará la interrupción de esa lista si está habilitado, de otra manera solo healers si mueren en menos de 3-4 segundos!\n\n@mouseover/@targettarget son opcionales y dependen de si están activados en la seccion spec\n\nClickDerecho: Crear macro",
				KICKTARGETMOUSEOVER = "[Main] Interrupciones\nHabilitado",					
				KICKTARGETMOUSEOVERTOOLTIP = "Desmarcado: @target/@mouseover interrupciones de la unidad no funcionan\nMarcado: @target/@mouseover interrupciones de la unidad funcionan\n\nClickDerecho: Crear macro",					
				KICKHEALONLYHEALER = "[Heal] Solo healers",					
				KICKHEALONLYHEALERTOOLTIP = "Desmarcado: lista válida para cualquier especialización de la unidad enemiga\n(e.g. Ench, Elem, SP, Retri)\nMarcado: lista solo válida para enemigos healers\n\nClickDerecho: Crear macro",
				KICKHEAL = "[Heal] Lista",
				KICKHEALPRINT = "[Heal] Lista of Interrupciones",
				KICKHEALTOOLTIP = "Desmarcado: @arena1-3 [Heal] lista personalizada no funcionará\nChecked: @arena1-3 [Heal] lista personalizada funcionará\n\nClickDerecho: Crear macro",
				KICKPVP = "[PvP] Lista",
				KICKPVPPRINT = "[PvP] Lista de Interrupciones",
				KICKPVPTOOLTIP = "Desmarcado: @arena1-3 [PvP] lista personalizada no funcionará\nChecked: @arena1-3 [PvP] lista personalizada funcionará\n\nClickDerecho: Crear macro",	
				KICKPVPONLYSMART = "[PvP] INTELIGENTE",
				KICKPVPONLYSMARTTOOLTIP = "Marcado: interrumpirá solamente acorden a la lógica establecida en la configuración del perfil lua. Ejemplo:\n1) Chain control en tu healer\n2) Alguien amigo (o tu) teneis buffs de Burst > 4 segundos\n3) Alguien morirá en menos de 8 segundos\n4) Tu (o @target) HP va a ejecutar la fase\nDesmarcado: interrumpirá esta lista siempre sin ningún tipo de lógica\n\nNota: Causa una demanda alta de la CPU\nClickDerecho: Crear macro",
				USEKICK = "Patada",
				USECC = "CC",
				USERACIAL = "Racial",
				ADD = "Añadir Interrupción",					
				ADDERROR = "|cffff0000No has especificado nada en 'Escribir Habilidad' o la habilidad no ha sido encontrada!|r",
				ADDTOOLTIP = "Añade habilidad del 'Escribir Habilidad'\n edita el cuadro a la lista seleccionada actual",
				REMOVE = "Borrar Interrupción",
				REMOVETOOLTIP = "Borra la habilidad seleccionada de la fila de la lista actual",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec] Configuración de Caja",
				USEDISPEL = "Usar Dispel",
				USEPURGE = "Usar Purga",
				USEEXPELENRAGE = "Expel Enrague",
				HEADTITLE = "[Global] Dispel | Purga | Enrague",
				MODE = "Modo:",
				CATEGORY = "Categoría:",
				POISON = "Dispelea venenos",
				DISEASE = "Dispelea enfermedades",
				CURSE = "Dispelea maldiciones",
				MAGIC = "Dispelea magias",
				MAGICMOVEMENT = "Dispelea relentizaciones/raíces",
				PURGEFRIENDLY = "Purgar amigo",
				PURGEHIGH = "Purgar enemigo (prioridad alta)",
				PURGELOW = "Purgar enemigo (prioridad baja)",
				ENRAGE = "Expel Enrague",
				BLESSINGOFPROTECTION = "Bendición de Protección",
				BLESSINGOFFREEDOM = "Bendición de Libertad",
				BLESSINGOFSACRIFICE = "Bendición de Sacrificio",
				BLESSINGOFSANCTUARY = "Bendición de santuario",	
				ROLE = "Rol",
				ID = "ID",
				NAME = "Nombre",
				DURATION = "Duración\n >",
				STACKS = "Marcas\n >=",
				ICON = "Icono",					
				ROLETOOLTIP = "Tu rol para usar",
				DURATIONTOOLTIP = "Reacciona al aura si la duración de esta es mayor (>) de los segundos especificados\nIMPORTANTE: Auras sin duración como 'favor divido'\n(sanazión de Paladin) debe ser 0. Esto significa que el aura está presente!",
				STACKSTOOLTIP = "Reacciona al aura si tiene más o igual (>=) marcas especificadas",									
				BYID = "usar ID\nen vez de Nombre",
				BYIDTOOLTIP = "Por ID debe comprobar TODAS las habilidades\ncon el mismo nombre, pero asumir diferentes auras\ncomo 'Afliccion inestable'",					
				CANSTEALORPURGE = "Solo si puedes\nrobar o purgar",					
				ONLYBEAR = "Solo si la unidad está\nen 'Forma de oso'",									
				CONFIGPANEL = "'Añadir Aura' Configuración",
				ANY = "Cualquiera",
				HEALER = "Healer",
				DAMAGER = "Tanque|Dañador",
				ADD = "Añadir Aura",					
				REMOVE = "Borrar Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Interacción del ratón",
				USETITLE = "[Each spec] Configuración de botones:",
				USELEFT = "Usar click izquierdo",
				USELEFTTOOLTIP = "Estás usando macro /target mouseover lo que no significa click!\n\nClickDerecho: Crear macro",
				USERIGHT = "Usar click derecho",
				LUATOOLTIP = "Para referirse a la unidad seleccionada, usa 'thisunit' sin comillas\nSi usas LUA en Categoría 'GameToolTip' entonces thisunit no es válido\nEl código debe tener boolean return (true) para procesar las condiciones\nEste código tiene setfenv que significa que no necesitas usar Action. para ninguna que lo tenga\n\nSi quieres borrar el codigo por defecto necesitarás escribir 'return true' sin comillas en vez de borrarlo todo",							
				BUTTON = "Click",
				NAME = "Nombre",
				LEFT = "Click izquierdo",
				RIGHT = "Click Derecho",
				ISTOTEM = "Es Totem",
				ISTOTEMTOOLTIP = "Si está activado comprobará @mouseover en tipo 'Totem' para el nombre dado\nTambién prevendrá click en situaciones si tu @target ya tiene algún totem",				
				INPUTTITLE = "Escribe el nombre del objeto (localizado!)", 
				INPUT = "Esta entrada no puede escribirse en mayúsculas",
				ADD = "Añadir",
				REMOVE = "Borrar",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "tótem enlace de espíritu",
				HEALINGTIDETOTEM = "tótem de marea de sanación",
				CAPACITORTOTEM = "tótem capacitador",					
				SKYFURYTOTEM = "tótem furia del cielo",					
				ANCESTRALPROTECTIONTOTEM = "tótem de protección ancestral",					
				COUNTERSTRIKETOTEM = "tótem de golpe de contraataque",
				EXPLOSIVES = "explosivos",
				-- Optional totems
				TREMORTOTEM = "tótem de tremor",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "tótem de carga de viento",
				EARTHBINDTOTEM = "tótem nexo terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "bandera de la alianza",
				HORDEFLAG = "bandera de la horda",
				NETHERSTORMFLAG = "bandera de la tormenta abisal",
				ORBOFPOWER = "orbe de poder",
			},
			[7] = {
				HEADTITLE = "Mensaje del Sistema",
				USETITLE = "[Each spec]",
				MSG = "Sistema de MSG",
				MSGTOOLTIP = "Marcado: funcionando\nDesmarcado: sin funcionar\n\nClickDerecho: Crear macro",
				DISABLERETOGGLE = "Bloquear borrar cola",
				DISABLERETOGGLETOOLTIP = "Prevenir la repetición de mensajes borrados de la cola del sistema\nE.j. Posible spam de macro sin ser removida\n\nClickDerecho: Crear macro",
				MACRO = "Macro para tu grupo:",
				MACROTOOLTIP = "Esto es lo que debe ser enviado al chat de grupo para desencadenar la acción asignada en la tecla específica\nPara direccionar la acción específica de la unidad, añádelos al macro o déjalo tal como está en la rotación Single/AoE\nSoportado: raid1-40, party1-2, player, arena1-3\nSOLO UNA UNIDAD POR MENSAJE!\n\nTus compañeros pueden usar macros también, pero ten cuidado, deben ser leales a esto!\n NO DES ESTA MACRO A LA GENTE QUE NO LE PUEDA GUSTAR QUE USES BOT!",
				KEY = "Tecla",
				KEYERROR = "No has especificado una tecla!",
				KEYERRORNOEXIST = "La tecla no existe!",
				KEYTOOLTIP = "Debes especificar una tecla para bindear la acción\nPuedes extraer la tecla en el apartado 'Acciones'",
				MATCHERROR = "Este nombre ya coincide, usa otro!",				
				SOURCE = "El nombre de la personaje que dijo",					
				WHOSAID = "Quien dijo",
				SOURCETOOLTIP = "Esto es opcional. Puede dejarlo en blanco (recomendado)\nSi quieres configurarlo, el nombre debe ser exactamente el mismo al del chat de grupo",
				NAME = "Contiene un mensaje",
				ICON = "Icono",
				INPUT = "Escribe una frase para el sistema de mensajes",
				INPUTTITLE = "Frase",
				INPUTERROR = "No has escrito una frase!",
				INPUTTOOLTIP = "La frase aparecerá en cualquier coincidencia del chat de grupo (/party)\nNo se distingue entre mayúsculas y minúsculas\nContiene patrones, significa que la frase escrita por alguien con la combinación de palabras de raid, party, arena, party o player\nse adapta la acción a la meta slot deseada\nNo necesitas establecer los patrones listados aquí, se utilizan como un añadido a la macro\nSi el patrón no es encontrado, los espacios para las rotaciones Single y AoE serán usadas",				
			},
		},
	},
}
do 
	local function CreateRoutineToENG(t, mirror)
		-- This need to prevent any text blanks caused by missed keys 
		for k, v in pairs(t) do 
			if k ~= "enUS" and type(v) == "table" then 
				local index = Localization[k] and mirror or mirror[k]
				setmetatable(v, { __index = index })
				CreateRoutineToENG(v, index)
			end 
		end 
	end 
	CreateRoutineToENG(Localization, Localization.enUS)
end 

function Action.GetLocalization()
	-- @return table localized with current language of interface 
	CL = TMWdb and TMWdb.global.ActionDB and TMWdb.global.ActionDB.InterfaceLanguage ~= "Auto" and Localization[TMWdb.global.ActionDB.InterfaceLanguage] and TMWdb.global.ActionDB.InterfaceLanguage or next(Localization[GameLocale]) and GameLocale or "enUS"
	L = Localization[CL]
	return L
end 

function Action.GetCL()
	-- @return string (Current locale language of the UI)
	return CL 
end 

-------------------------------------------------------------------------------
-- DB: Database
-------------------------------------------------------------------------------
Action.Enum = {}
Action.Data = {	
	ProfileUI = {},
	ProfileDB = {},
	ProfileEnabled = {
		["[GGL] Test"] 		= false,
		["[GGL] Template"] 	= false,
	},
	DefaultProfile = {
		["WARRIOR"] 		= "[GGL] Warrior",
		["PALADIN"] 		= "[GGL] Paladin",
		["HUNTER"] 			= "[GGL] Hunter",
		["ROGUE"] 			= "[GGL] Rogue",
		["PRIEST"] 			= "[GGL] Priest",
		["SHAMAN"] 			= "[GGL] Shaman",
		["MAGE"] 			= "[GGL] Mage",
		["WARLOCK"] 		= "[GGL] Warlock",
		["MONK"] 			= "[GGL] Monk",
		["DRUID"] 			= "[GGL] Druid",
		["DEATHKNIGHT"] 	= "[GGL] Death Knight",
		["DEMONHUNTER"] 	= "[GGL] Demon Hunter",
		["BASIC"]			= "[GGL] Basic",
	},
	-- UI template config  
	theme = {
		off 				= "|cffff0000OFF|r",
		on 					= "|cff00ff00ON|r",
		dd = {
			width 			= 125,
			height 			= 25,
		},
	},
	-- Color
    C = {
		-- Standart 
        ["GREEN"] 			= "ff00ff00",
        ["RED"] 			= "ffff0000d",
        ["BLUE"] 			= "ff0900ffd",        
        ["YELLOW"]	 		= "ffffff00d",
        ["PINK"] 			= "ffff00ffd",
        ["LIGHT BLUE"] 		= "ff00ffffd",
		-- Nicely
		["LIGHTRED"]        = "ffff6060d",
		["TORQUISEBLUE"]	= "ff00C78Cd",
		["SPRINGGREEN"]	  	= "ff00FF7Fd",
		["GREENYELLOW"]   	= "ffADFF2Fd",
		["PURPLE"]		    = "ffDA70D6d",
		["GOLD"]            = "ffffcc00d",
		["GOLD2"]			= "ffFFC125d",
		["GREY"]            = "ff888888d",
		["WHITE"]           = "ffffffffd",
		["SUBWHITE"]        = "ffbbbbbbd",
		["MAGENTA"]         = "ffff00ffd",
		["ORANGEY"]		    = "ffFF4500d",
		["CHOCOLATE"]		= "ffCD661Dd",
		["CYAN"]            = "ff00ffffd",
		["IVORY"]			= "ff8B8B83d",
		["LIGHTYELLOW"]	    = "ffFFFFE0d",
		["SEXGREEN"]		= "ff71C671d",
		["SEXTEAL"]		    = "ff388E8Ed",
		["SEXPINK"]		    = "ffC67171d",
		["SEXBLUE"]		    = "ff00E5EEd",
		["SEXHOTPINK"]	    = "ffFF6EB4d",		
    },
    -- Queue List
    Q = {},
	-- Timers
	T = {},
	-- Toggle Cache 
	TG = {},
	-- Auras 
	Auras = {},
}

local ActionDataDefaultProfile 										= Action.Data.DefaultProfile
local ActionDatatheme 												= Action.Data.theme
local ActionDataQ 													= Action.Data.Q
local ActionDataT 													= Action.Data.T
local ActionDataTG													= Action.Data.TG
local ActionDataAuras												= Action.Data.Auras
local ActionHasRunningDB

-- Templates
-- Important: Default LUA overwrite problem was fixed by additional LUAVER key, however [3] "QLUA" and "LUA" was leaved and only 'Reset Settings' can clear it 
-- TMWdb.profile.ActionDB DefaultBase
local Factory = {
	-- Special keys: 
	-- PLAYERSPEC will convert to available spec on character 
	-- ISINTERRUPT will swap ID to locale Name as key and create formated table 
	-- ISCURSOR will swap key localized Name from Localization table and create formated table 
	[1] = {
		CheckVehicle = true, 
		CheckDeadOrGhost = true, 
		CheckDeadOrGhostTarget = false,
		CheckMount = false, 
		CheckCombat = false, 
		CheckSpellIsTargeting = true, 
		CheckLootFrame = true, 	
		CheckEatingOrDrinking = true,
		DisableRotationDisplay = false,
		DisableBlackBackground = false,
		DisablePrint = false,
		DisableMinimap = false,
		DisableClassPortraits = false,
		DisableRotationModes = false,
		DisableSounds = true,
		HideOnScreenshot = true,		
		ColorPickerUse = false,
		ColorPickerElement = "backdrop",
		ColorPickerOption = "panel",
		ColorPickerConfig = { 
			-- All tables must be empty
			font = {
				color = {
					normal = {},
					disabled = {},
					header = {},
					subtitle = {}, 	-- custom (not implement in StdUi)
					tooltip = {},	-- custom (not implement in StdUi)
				},
			},
			backdrop = {
				panel = {},
				slider = {},
				highlight = {},
				button = {},
				buttonDisabled = {},
				border = {},
				borderDisabled = {},
			},
			progressBar = {
				color = {},					
			},
			highlight = {
				color = {},
				blank = {},
			},
		},					
		PLAYERSPEC = {
			AutoTarget = true, 
			Potion = true, 
			HeartOfAzeroth = true,
			Racial = true,	
			StopCast = true,
			DBM = true,
			["LOSCheck"] = _G.LOSCheck ~= nil and _G.LOSCheck or false, 
			["HE_Toggle"] = _G.HE_Toggle ~= nil and _G.HE_Toggle or "ALL",
			["HE_Pets"] = _G.HE_Pets ~= nil and _G.HE_Pets or true,	
			StopAtBreakAble = false,			
			FPS = -0.01, 	
			Trinkets = {
				[1] = true, 
				[2] = true, 
			},
			Burst = "Auto",
			HealthStone = 20, 
			ReFocus = true, 
			ReTarget = true, 			
		},
	}, 
	[3] = {			
		AutoHidden = true,
		CheckSpellLevel = false,
		PLAYERSPEC = {			
			disabledActions = {},
			luaActions = {},
			QluaActions = {},
		},
	},
	[4] = {
		BlackList = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		PvETargetMouseover = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		PvPTargetMouseover = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		Heal = {
			[GameLocale] = {	
				ISINTERRUPT = true,
				-- Priest
				[47540] = "Penance",
				[596] = "Prayer of Healing",
				[2060] = "Heal",
				[2061] = "Flash Heal",
				[32546] = "Binding Heal",
				[33076] = "Prayer of Mending",
				[64843] = "Divine Hymn",
				[120517] = "Halo",
				[186263] = "Shadow Mend",
				[194509] = "Power Word: Radiance",
				[265202] = "Holy Word: Salvation",
				[289666] = "Greater Heal",
				-- Druid
				[740] = "Tranquility",
				[8936] = "Regrowth",
				[289022] = "Nourish",
				[48438] = "Wild Growth",
				-- Shaman
				[188070] = "Healing Surge",
				[1064] = "Chain Heal",
				[73920] = "Healing Rain",
				[77472] = "Healing Wave",
				[197995] = "Wellspring",
				[207778] = "Downpour",
				-- Paladin
				[19750] = "Flash of Light",
				[82326] = "Holy Light",
				-- Monk
				[116670] = "Vivify",
				[124682] = "Enveloping Mist",
				[191837] = "Essence Font",
				[227344] = "Surging Mist",
				[115175] = "Soothing Mist",	
			},			
		},
		PvP = {
			[GameLocale] = {
				ISINTERRUPT = true,
				[113724] = "Ring of Frost",
				[118] = "Pollymorph",
				[605] = "Mind Control",
				[982] = "Revive pet",
				[5782] = "Fear",
				[20066] = "Repitance",
				[51514] = "Hex",
				[33786] = "Cyclone",
				[32375] = "Mass dispel",				
				[12051] = "Evocation",
				[20484] = "Rebirth",
				-- On choice
				[258925] = "Fel Barrage",
				[198013] = "Eye Beam",
				[339] = "Roots",
			},	
		},	
		PLAYERSPEC = {
			TargetMouseoverList = false,
			KickHealOnlyHealers = false, 
			KickPvPOnlySmart = false,
			KickTargetMouseover = true, 
			KickHeal = true, 
			KickPvP = true, 		
		},
	},
	[5] = {
		PLAYERSPEC = {
			UseDispel = true,			
			UsePurge = true,
			UseExpelEnrage = true,
			-- DispelPurgeEnrageRemap func will push needed keys here 
		},
	},
	[6] = {
		PLAYERSPEC = {
			UseLeft = true,
			UseRight = true,
			PvE = {
				UnitName = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["EXPLOSIVES"]] = { isTotem = true, Button = "LEFT", LUA = [[return InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7]] },
					},
				},
				GameToolTip = {
					[GameLocale] = {
						ISCURSOR = true,
					},
				},
			},
			PvP = {
				UnitName = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["SPIRITLINKTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["HEALINGTIDETOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["CAPACITORTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["SKYFURYTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["ANCESTRALPROTECTIONTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["COUNTERSTRIKETOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["TREMORTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["GROUNDINGTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["WINDRUSHTOTEM"]] = { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["EARTHBINDTOTEM"]] = { isTotem = true, Button = "LEFT" },
					}, 
				},
				GameToolTip = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["ALLIANCEFLAG"]] = { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["HORDEFLAG"]] = { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["NETHERSTORMFLAG"]] = { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["ORBOFPOWER"]] = { Button = "RIGHT" },
					},
				},
			},
		},
	},
	[7] = {
		PLAYERSPEC = {
			MSG_Toggle = true,
			DisableReToggle = false,
			msgList = {},
		},
	},
}

-- TMWdb.global.ActionDB DefaultBase
local GlobalFactory = {	
	InterfaceLanguage = "Auto",	
	minimap = {},
	[5] = {		
		PvE = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
				-- Seduction
				[270920] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				return PlayerClass ~= "MAGE" ]] },
			},
			PurgeHigh = {
				-- 8.2 Mechagon: Defensive Countermeasure
				[297133] = { canStealOrPurge = true, byID = true },	
				-- 8.2 Mechagon: Enlarge
				[301629] = { canStealOrPurge = true, dur = 3, byID = true },	
				-- 8.1 Dungeon: Bone Shield
				[266201] = { canStealOrPurge = true, byID = true },	
				-- 8.1 Dungeon: Swiftness
				[276265] = { canStealOrPurge = true, stack = 3, byID = true },	
				-- 8.0.1 Dungeon: Reanimated Bones
				[274210] = { canStealOrPurge = true, byID = true },					
				-- 8.0.1 Dungeon: Detect Thoughts
				[268375] = { canStealOrPurge = true, byID = true },	
				-- 8.0.1 Dungeon: Earth Shield
				[268709] = { canStealOrPurge = true, byID = true },	
				-- Gilded Claws
				[255579] = { canStealOrPurge = true, dur = 7 },		
				-- Gathered Souls
				[254974] = { canStealOrPurge = true },
				-- Healing Balm
				[257397] = { canStealOrPurge = true },
				-- Bound by Shadow
				[269935] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				return PlayerClass ~= "MAGE" ]] },
				-- Induce Regeneration
				[270901] = { canStealOrPurge = true, dur = 7 },
				-- Tidal Surge
				[267977] = { canStealOrPurge = true, dur = 10, LUAVER = 2, LUA = [[ -- Only if we're Mage
				return PlayerClass == "MAGE" ]] },
				-- Mending Rapids
				[268030] = { canStealOrPurge = true, dur = 4 },
				-- Watertight Shell
				[256957] = { canStealOrPurge = true },
				-- Bolstering Shout
				[275826] = { canStealOrPurge = true, dur = 2 },
				-- Electrified Scales
				[272659] = { canStealOrPurge = true, dur = 2 },
				-- Embryonic Vigor
				[269896] = { canStealOrPurge = true },
				-- Accumulate Charge
				[265912] = { canStealOrPurge = true, stack = 3 },
				-- Tectonic Barrier
				[263215] = { canStealOrPurge = true },
				-- Azerite Injection
				[262947] = { canStealOrPurge = true },
				-- Overcharge
				[262540] = { canStealOrPurge = true },
				-- Watery Dome
				[258153] = { canStealOrPurge = true },
				-- Gift of G'huun
				[265091] = { canStealOrPurge = true },
				-- Soul Fetish
				[278551] = { canStealOrPurge = true },				
				-- Mythic: Arcane Blitz
				[197797] = { canStealOrPurge = true, dur = 3 },
				-- Unstable Flux
				[210662] = { canStealOrPurge = true, dur = 3 },
				-- Brand of the Legion
				[211632] = { canStealOrPurge = true, dur = 3 },
				-- Fortification
				[209033] = { canStealOrPurge = true, dur = 3 },
				-- Protective Light
				[198745] = { canStealOrPurge = true, dur = 3 },
				-- Sea Legs
				[194615] = { canStealOrPurge = true, dur = 1 },
				-- Gift of Wind
				[282098] = { canStealOrPurge = true, dur = 1 },					
			},
			PurgeLow = {
				-- 8.0.1 Tol Dagor: Inner Flames
				[258938] = { canStealOrPurge = true, byID = true },	
				-- Dino Might
				[256849] = { canStealOrPurge = true },
				-- Induce Regeneration
				[270901] = { canStealOrPurge = true },
				-- Tidal Surge
				[267977] = { canStealOrPurge = true, dur = 3, LUAVER = 2, LUA = [[ -- Only if we're Mage
				return PlayerClass == "MAGE" ]] },
				-- Consuming Void
				[276767] = { canStealOrPurge = true },
				-- Spirited Defense
				[265368] = { canStealOrPurge = true },
			},
			Poison = {
				-- 8.3 Heartpiercer Venom
				[316506] = { byID = true, dur = 0.5 },
				-- 8.3 Mind-Numbing Toxin
				[314593] = { byID = true },
				-- 8.3 Volatile Rupture
				[314467] = { byID = true, dur = 1.49 },
				-- Venomfang Strike
				[252687] = {},
				-- Poisoning Strike
				[257436] = { stack = 3 },
				-- Hidden Blade
				[270865] = {},
				-- Embalming Fluid 
				[271564] = { stack = 3 },
				-- Poison Barrage 
				[270507] = {},
				-- Neurotoxin 
				[273563] = { dur = 1.49 },
				-- Cytotoxin 
				[267027] = { stack = 2 },
				-- Venomous Spit
				[272699] = {},
				-- Widowmaker Toxin
				[269298] = { stack = 2 }, 
				-- Stinging Venom
				[275836] = { stack = 5 },    
				-- Crippling Shiv
				[257777] = { dur = 1.49 },
			},
			Disease = {
				-- 8.3 Lingering Nausea
				[250372] = { byID = true, dur = 1.49 },
				-- 8.3 Crippling Pestilence
				[314406] = { byID = true, dur = 1.49 },
				-- 8.2 Mechagon - Consuming Slime
				[300659] = {},
				-- 8.2 Mechagon - Gooped
				[298124] = {},
				-- 8.2 Mechagon - Suffocating Smog
				[300650] = {},
				-- 8.0.1 Severing Serpent
				[264520] = { byID = true },
				-- 8.0.1 Infected Thorn
				[264050] = { byID = true, dur = 1.49 },
				-- Infected Wound
				[258323] = { stack = 1 },
				-- Plague Step
				[257775] = {},
				-- Wretched Discharge
				[267763] = {},
				-- Plague 
				[269686] = {},
				-- Festering Bite
				[263074] = {},
				-- Decaying Mind
				[278961] = {},
				-- Decaying Spores
				[259714] = {},
				-- Decaying Spores
				[273226] = { byID = true, stack = 2 },
				-- Rotting Wounds
				[272588] = { byID = true },
			}, 
			Curse = {
				-- Unstable Hex
				--[252781] = {}, -- recommended: don't dispel 						
				-- Wracking Pain
				[250096] = {},
				-- Pit of Despair
				[276031] = { dur = 1 },
				-- Hex 
				[270492] = {},
				-- Cursed Slash
				[257168] = { stack = 2 },
				-- Withering Curse
				[252687] = { stack = 2 },				
			},
			Magic = {	
				-- 8.3 Wildfire
				[253562] = { byID = true, dur = 1.49 },
				-- 8.3 Heart of Darkness
				[307645] = { byID = true, dur = 1.49 },
				-- 8.3 Annihilation
				[310224] = { byID = true, stack = 8 },
				-- 8.3 Recurring Nightmare
				[312486] = { byID = true, stack = 1 },
				-- 8.3 Corrupted Mind
				[313400] = { byID = true },
				-- 8.3 Mind Flay
				[314592] = { byID = true, dur = 1.49 },
				-- 8.3 Cascading Terror
				[314483] = { dur = 1.49  },
				-- 8.3 Unleashed Insanity
				[310361] = { byID = true, dur = 1.49 },
				-- 8.3 Psychic Scream
				[308375] = { byID = true, dur = 1 },
				-- 8.3 Void Buffet
				[297315] = { byID = true, dur = 1.49 },
				-- 8.2 Mechagon - Blazing Chomp
				[294929] = { byID = true },
				-- 8.2 Mechagon - Shrink
				[299572] = { byID = true },
				-- 8.2 Mechagon - Arcing Zap
				[294195] = { byID = true },
				-- 8.2 Mechagon - Discom-BOMB-ulator
				[285460] = { byID = true },
				-- 8.2 Mechagon - Flaming Refuse
				[294180] = { byID = true },
				-- 8.2 Mechagon -  Capacitor Discharge
				[295168] = { byID = true },
				-- 8.2 Queen Azshara - Arcane Burst
				[303657] = { byID = true, dur = 10 },
				-- 8.2 Za'qul - Dread
				[292963] = { byID = true },
				-- 8.2 Za'qul - Shattered Psyche
				[295327] = { byID = true },
				-- 8.2 Radiance of Azshara - Arcane Bomb
				-- [296746] = { byID = true }, -- need predict unit position to dispel only when they are out of raid 
				-- 8.0.1 Toad Blight
				[265352] = { byID = true, dur = 0.5 },
				-- 8.0.1 Freezing Trap
				[278468] = { byID = true, dur = 1.5 },
				-- 8.0.1 Frost Shock
				[270499] = { byID = true, dur = 1.5 },
				-- The Restless Cabal - Promises of Power 
				[282562] = { byID = true, stack = 3 },				
				-- Jadefire Masters - Searing Embers
				[286988] = { byID = true },
				-- Conclave of the Chosen - Mind Wipe
				[285878] = { byID = true },
				-- Lady Jaina - Grasp of Frost
				[287626] = { byID = true },
				-- Lady Jaina - Hand of Frost
				[288412] = { byID = true },
				-- Whispers of Power
				[267034] = { stack = 4 },
				-- Whispers of Power
				[267037] = { stack = 4 },
				-- Righteous Flames
				[258917] = { byID = true },
				-- Suppression Fire
				[258864] = { byID = true },
				-- Molten Gold
				[255582] = {},
				-- Terrifying Screech
				[255041] = {},
				-- Terrifying Visage
				[255371] = {},
				-- Oiled Blade
				[257908] = {},
				-- Choking Brine
				[264560] = {},
				-- Electrifying Shock
				[268233] = { LUAVER = 1, LUA = [[ 
					-- Skips Mechagon - Mechagon Island, boss: Naeno Megacrash
					return ZoneID ~= 1490
				]] },
				-- Touch of the Drowned 
				[268322] = { LUAVER = 2, LUA = [[ -- if no party member is afflicted by Mental Assault (268391)
				return FriendlyTeam():GetDeBuffs(268391) == 0 ]] },
				-- Mental Assault 
				[268391] = {},
				-- Wicked Assault
				[266265] = { dur = 1.5 },
				-- Explosive Void
				[269104] = {},
				-- Choking Waters
				[272571] = {},
				-- Putrid Waters
				[274991] = {},
				-- Flame Shock 
				[268013] = { LUAVER = 2, LUA = [[ -- if no party member is afflicted by Snake Charm (268008)
				return FriendlyTeam():GetDeBuffs(268008) == 0 ]] },
				-- Snake Charm
				[268008] = {},
				-- Brain Freeze
				[280605] = { dur = 1.49 },
				-- Transmute: Enemy to Goo
				[268797] = {},
				-- Chemical Burn
				[259856] = {},
				-- Debilitating Shout
				[258128] = {},
				-- Torch Strike 
				[265889] = { stack = 2 },
				-- Fuselighter 
				[257028] = {},
				-- Death Bolt 
				[272180] = {},
				-- Putrid Blood
				[269301] = { stack = 2 },
				-- Grasping Thorns
				[263891] = {},
				-- Fragment Soul
				[264378] = {},
				-- Putrid Waters
				[275014] = { LUAVER = 2, LUA = [[ -- Don't dispel self
				return not UnitIsUnit("player", thisunit) ]] },
				-- Legion: Touch of Corruption
				[209469] = { byID = true },				
			}, 
			MagicMovement = {
			},
			Enrage = {
				-- Fanatic's Rage
				[255824] = { dur = 8 },
				-- Bestial Wrath
				[257476] = {},
				-- Ancestral Fury
				[269976] = {},
				-- Warcry
				[265081] = {},
				-- Wicked Frenzy
				[266209] = {},
			},
			BlessingofProtection = {
			},
			BlessingofFreedom = {
			},
			BlessingofSacrifice = {
			},
			BlessingofSanctuary = {
			},
		},
		PvP = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
			},
			PurgeHigh = {
				-- Paladin: Blessing of Protection
				[1022] = { dur = 1 },
				-- Paladin: Divine Favor 
				[210294] = { dur = 0 },
				-- Priest: Power Infusion
				[10060] = { dur = 4 },
				-- Priest: Holy Ward
				[213610] = { dur = 3 },
				-- Priest: Luminous Barrier
				[271466] = { dur = 0 },
				-- Shaman: Spiritwalker's Grace
				[79206] = { dur = 1 },
				-- Mage: Combustion
				[190319] = { dur = 4 },
				-- Mage: Arcane Power
				[12042] = { dur = 4 },
				-- Mage: Icy Veins
				[12472] = { dur = 4 },
				-- Mage: Temporal Shield
				[198111] = { dur = 0 },
				-- Warlock: Nether Ward
				[212295] = { dur = 1 },
				-- Moment of Glory
				[311203] = { dur = 0 },
			},
			PurgeLow = {
				-- Paladin: Blessing of Freedom  
				[1044] = { dur = 1.5 },
				-- Druid: Lifebloom
				[33763] = { dur = 0, onlyBear = true },
				-- Druid: Rejuvenation
				[774] = { dur = 0, onlyBear = true },
				-- Druid: Germination
				[155777] = { dur = 0, onlyBear = true },
				-- Druid: Wild Growth 
				[48438] = { dur = 0, onlyBear = true },
				-- Druid: Regrow
				[8936] = { dur = 0, onlyBear = true },
				-- Druid: Mark of the Wild
				[289318] = { dur = 0, onlyBear = true },
			},
			Poison = {
				-- Hunter: Wyvern Sting
				[19386] = { dur = 0 },
				-- Hunter: Spider Sting 
				[202933] = { dur = 1 },
				-- Hunter: Viper Sting
				[202797] = { dur = 3 },
				-- Hunter: Scorpid Sting
				[202900] = { dur = 1.5 },				
			},
			Disease = {
				-- Druid: Infected Wounds
				[58180] = { role = "DAMAGER", dur = 0 },
				-- Death Knight: Outbreak (5 sec dot)
				[196782] = { dur = 0 },
				-- Death Knight: Outbreak (21 sec dot)
				[191587] = { role = "DAMAGER", dur = 18 },
			},
			Curse = {
				-- Shaman: Hex 
				[51514] = { dur = 1 },
				-- Warlock: Curse of Tongues
				[12889] = { dur = 3 },
				-- Warlock: Curse of Weakness
				[17227] = { dur = 3 },
				-- Warlock: Curse of Fragility
				[199954] = { dur = 3 },
			},
			Magic = {
				-- Paladin: Repentance
				[20066] = { dur = 1.5 },
				-- Paladin: Bliding light
				[105421] = { dur = 1.5 },
				-- Paladin: Avenger's Shield
				[31935] = { dur = 1.5 },
				-- Paladin: Hammer of Justice
				[853] = { dur = 0 },
				-- Hunter: Freezing Trap
				[3355] = { dur = 1.5 },
				-- Hunter: Freezing Trap
				[278468] = { byID = true, dur = 1.5 },
				-- Hunter: Freezing Arrow 
				[209790] = { dur = 1.5 },
				-- Hunter: Binding Shot
				[117526] = { dur = 1 },
				-- Priest: Mind Control 
				[605] = { dur = 0 },
				-- Priest: Psychic Scream
				[8122] = { dur = 1.5 },
				-- Priest: Shackle Undead 
				[9484] = { dur = 1 },
				-- Priest: Silence
				[15487] = { dur = 1 },
				-- Priest: Last Word
				[199683] = { dur = 1 },
				-- Priest: Psychic Horror
				[64044] = { dur = 0 },
				-- Priest: Mind Bomb
				[226943] = { dur = 0 },
				-- Priest: Holy word: Chastise
				[200200] = { dur = 0 }, 
				-- Shaman: Static Charge
				[118905] = { dur = 0 },
				-- Shaman: Earthfury
				[204399] = { dur = 0 },
				-- Mage: Polymorph 
				[118] = { dur = 1.5 },
				-- Mage: Ring of Frost
				[82691] = { dur = 1.5 },
				-- Mage: Dragon's Breath
				[31661] = { dur = 1.5 },														
				-- Warlock: Fear 
				[5782] = { dur = 1.5 },
				-- Warlock: Seduction
				[6358] = { dur = 1.5 },	
				-- Warlock: Howl of Terror
				[5484] = { dur = 1.5 },
				-- Warlock: Mortal Coil
				[6789] = { dur = 1 },
				-- Warlock: Sin and Punishment
				[87204] = { dur = 1 },
				-- Warlock: Unstable Affliction
				[31117] = { dur = 1, byID = true },
				-- Warlock: Shadowfury
				[30283] = { dur = 1 },
				-- Warlock: Summon Infernal
				[22703] = { dur = 1.4 },
				-- Monk: Song of Chi-ji
				[198909] = { dur = 1.5 },
				-- Monk: Incendiary brew
				[202274] = { dur = 1.5 },
				-- Druid: Hibernate 
				[2637] = { dur = 1.5 },
				-- Druid: Faerie Swarm
				[209749] = { dur = 0 },	
				-- Demon Hunter: Chaos Nova
				[179057] = { dur = 0 },
				-- Demon Hunter: Illidan's Grasp
				[205630] = { dur = 0, byID = true },
				-- Demon Hunter: Imprison
				[217832] = { dur = 0, byID = true },
				-- Demon Hunter: Metamorphosis
				[200166] = { dur = 1.4, byID = true }, 
				-- Demon Hunter: Fel Eruption
				[211881] = { dur = 0 },
				-- Death Knight: Strangulate
				[47476] = { dur = 1 },				
				-- Misc: Gladiator's Maledict
				[286349] = { dur = 0 },
			},
			MagicMovement = {
				-- Paladin: Hand of Hindrance
				[183218] = { dur = 1 },
				-- Mage: Frost Nova 
				[122] = { dur = 1 },
				-- Druid: Mass Entanglement
				[102359] = { dur = 1 },
				-- Druid: Entangling Roots
				[339] = { dur = 1, byID = true },
				-- Death Knight: Frozen Center
				[233395] = { dur = 1 },
			},
			Enrage = {
				-- Berserker Rage
				[18499] = { dur = 1 },
				-- Enrage
				[184361] = { dur = 1 },
			},
			BlessingofProtection = {
			},
			BlessingofFreedom = {
			},
			BlessingofSacrifice = {
			},
			BlessingofSanctuary = {
			},
		},
	},
}

local GlobalFactoryErased = {
	-- The table which holds all keys which must be erased from actual db, must be [key] = true construct
	[5] = {
		PvE = {
			Magic = {
				-- Reap Soul
				[288388] = true, -- old 
				-- 8.3 Grasping Tendrils
				[315176] = true, -- wrong ID
				-- 8.3 Annihilation
				[306982] = true, -- wrong ID 							
			},
		},
	},
}

-- Table controlers 	
local function tMerge(default, new, special, nonexistremove)
	-- Forced push all keys new > default 
	-- if special true will replace/format special keys 
	local result = {}
	
	for k, v in pairs(default) do 
		if type(v) == "table" then 
			if special and k == "PLAYERSPEC" then
				local classID = Action.PlayerClassID or select(3, UnitClass("player"))
				for i = 1, GetNumSpecializationsForClassID(classID) do 
					result[GetSpecializationInfo(i)] = tMerge(v, v, special, nonexistremove) 
				end	
			elseif special and v.ISINTERRUPT then 
				result[k] = {}
				for ID in pairs(v) do
					if type(ID) == "number" then 												
						result[k][GetSpellInfo(ID)] = { Enabled = true, ID = ID, useKick = true, useCC = true, useRacial = true } -- Spell:CreateFromSpellID(ID):GetSpellName()
					end 
				end
			elseif special and v.ISCURSOR then 
				result[k] = {}
				for KeyLocale, Val in pairs(v) do 					
					if type(Val) == "table" then 				
						result[k][KeyLocale] = { Enabled = true, Button = Val.Button, isTotem = Val.isTotem, LUA = Val.LUA } 
					end 
				end 
			elseif new[k] ~= nil then 
				result[k] = tMerge(v, new[k], special, nonexistremove)
			else
				result[k] = tMerge(v, v, special, nonexistremove)
			end 
		elseif new[k] ~= nil then 
			result[k] = new[k]
		elseif not nonexistremove then  	
			result[k] = v				
		end 
	end 
	
	if new ~= default then 
		for k, v in pairs(new) do 
			if type(v) == "table" then 
				result[k] = tMerge(type(result[k]) == "table" and result[k] or v, v, special, nonexistremove)
			else 
				result[k] = v
			end 
		end 
	end
	
	return result
end

local function tCompare(default, new, upkey, skip)
	local result = {}
	
	if (new == nil or next(new) == nil) and default ~= nil then 
		result = tMerge(result, default)		
	else 		
		if default ~= nil then 
			for k, v in pairs(default) do
				if not skip and new[k] ~= nil then 
					if type(v) == "table" then 
						result[k] = tCompare(v, new[k], k)
					elseif type(v) == type(new[k]) then 
						-- Overwrite default LUA specified in profile (default) even if user made custom (new), doesn't work for [3] "QLUA" and "LUA" 
						if k == "LUA" and default.LUAVER ~= nil and default.LUAVER ~= new.LUAVER then 							
							result[k] = v
							Action.Print(L["DEBUG"] .. (upkey or "") .. " (LUA) " .. " " .. L["RESETED"]:lower())
						elseif k == "LUAVER" then 
							result[k] = v  
						else 
							result[k] = new[k]
						end 					 	
					elseif new[k] ~= nil then 
						result[k] = v
					end 
				else
					result[k] = v 
				end			
			end 
		end 
		
		for k, v in pairs(new) do 
			if type(v) == "table" then 	
				result[k] = tCompare(result[k], v, k, true)		
			elseif result[k] == nil then 
				result[k] = v
			--else 
				-- Debugs keys which has been updated by default 
				--Action.Print(L["DEBUG"] .. "tCompare key: " .. k .. "  upkey: " .. (upkey or ""))				
			end	
		end 
	end 				
	
	return result 
end

local function tEraseKeys(default, new)
	-- Cleans in 'default' table keys which persistent in 'new' table 
	if new then 
		for k, v in pairs(new) do 
			if default[k] then 
				if type(v) == "table" then 
					if not v.enabled then 
						tEraseKeys(default[k], v)
					end 
				else 
					default[k] = nil 
					Action.Print(L.DEBUG .. L.TAB[5].HEADBUTTON .. " " .. GetSpellInfo(k) .. " " .. L.RESETED:lower())
				end 
			end
		end 
	end 
	return default
end 

-- TMWdb.global.ActionDB[5] -> TMWdb.profile.ActionDB[5]
local function DispelPurgeEnrageRemap()
	-- Note: This function should be called every time when [5] "Auras" in UI has been changed or shown
	-- Creates localization on keys and put them into profile db relative spec 
	wipe(ActionDataAuras)
	for Mode, Mode_v in pairs(TMWdb.global.ActionDB[5]) do 
		if not ActionDataAuras[Mode] then 
			ActionDataAuras[Mode] = {}
		end 
		for Category, Category_v in pairs(Mode_v) do 			
			if not ActionDataAuras[Mode][Category] then 
				ActionDataAuras[Mode][Category] = {} 
			end 
			for SpellID, v in pairs(Category_v) do 
				local Name = GetSpellInfo(SpellID) -- Spell:CreateFromSpellID(SpellID):GetSpellName()	
				ActionDataAuras[Mode][Category][Name] = { 
					ID = SpellID, 
					Name = Name, 
					Enabled = true,
					Role = v.role or "ANY",
					Dur = v.dur or 0,
					Stack = v.stack or 0,
					byID = v.byID,
					canStealOrPurge = v.canStealOrPurge,
					onlyBear = v.onlyBear,
					LUA = v.LUA,
				} 
				if v.enabled ~= nil then 
					ActionDataAuras[Mode][Category][Name].Enabled = v.enabled 
				end 
			end 			 
		end 
	end 
	-- Creates relative to each specs which can dispel or purje anyhow
	local UnitAuras = {
		-- Restor Druid 
		[ACTION_CONST_DRUID_RESTORATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Balance
		[ACTION_CONST_DRUID_BALANCE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,	
					ActionDataAuras.PvE.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,		
					ActionDataAuras.PvP.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Feral
		[ACTION_CONST_DRUID_FERAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Poison,	
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Poison,						
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Guardian
		[ACTION_CONST_DRUID_GUARDIAN] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,	
					ActionDataAuras.PvE.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Arcane
		[ACTION_CONST_MAGE_ARCANE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Fire
		[ACTION_CONST_MAGE_FIRE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Frost
		[ACTION_CONST_MAGE_FROST] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Mistweaver
		[ACTION_CONST_MONK_MISTWEAVER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
			},
		},
		-- Windwalker
		[ACTION_CONST_MONK_WINDWALKER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,					
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,					
				},
			},
		},
		-- Brewmaster
		[ACTION_CONST_MONK_BREWMASTER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,					
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,					
				},
			},
		},
		-- Holy Paladin
		[ACTION_CONST_PALADIN_HOLY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,	
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvE.BlessingofSacrifice,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,	
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvP.BlessingofSacrifice,
				},
			},
		},
		-- Protection Paladin
		[ACTION_CONST_PALADIN_PROTECTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvE.BlessingofSacrifice,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvP.BlessingofSacrifice,
				},
			},
		},
		-- Retirbution Paladin
		[ACTION_CONST_PALADIN_RETRIBUTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSanctuary = { 
					ActionDataAuras.PvE.BlessingofSanctuary,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSanctuary = { 
					ActionDataAuras.PvP.BlessingofSanctuary,
				},
			},
		},
		-- Discipline Priest 
		[ACTION_CONST_PRIEST_DISCIPLINE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Magic,
					ActionDataAuras.PvE.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Magic,
					ActionDataAuras.PvP.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		}, 
		-- Holy Priest 
		[ACTION_CONST_PRIEST_HOLY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Magic,
					ActionDataAuras.PvE.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Magic,
					ActionDataAuras.PvP.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		}, 
		-- Shadow Priest 
		[ACTION_CONST_PRIEST_SHADOW] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Disease,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Disease,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Elemental
		[ACTION_CONST_SHAMAN_ELEMENTAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Enhancement
		[ACTION_CONST_SHAMAN_ENCHANCEMENT] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Restoration
		[ACTION_CONST_SHAMAN_RESTORATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Affliction
		[ACTION_CONST_WARLOCK_AFFLICTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Demonology
		[ACTION_CONST_WARLOCK_DEMONOLOGY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Destruction
		[ACTION_CONST_WARLOCK_DESTRUCTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Assassination
		[ACTION_CONST_ROGUE_ASSASSINATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Outlaw
		[ACTION_CONST_ROGUE_OUTLAW] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Subtlety 
		[ACTION_CONST_ROGUE_SUBTLETY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Beast Mastery
		[ACTION_CONST_HUNTER_BEASTMASTERY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Marksmanship
		[ACTION_CONST_HUNTER_MARKSMANSHIP] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Survival
		[ACTION_CONST_HUNTER_SURVIVAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Havoc
        [ACTION_CONST_DEMONHUNTER_HAVOC] = {
            PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
                Dispel = {                    
                    ActionDataAuras.PvE.Magic,                    
                },
                PurgeFriendly = {
                    ActionDataAuras.PvE.PurgeFriendly,
                },
                PurgeHigh = {
                    ActionDataAuras.PvE.PurgeHigh,
                },
                PurgeLow = {
                    ActionDataAuras.PvE.PurgeLow,
                },
            },
            PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
                Dispel = {                    
                    ActionDataAuras.PvP.Magic,                    
                },
                PurgeFriendly = {
                    ActionDataAuras.PvP.PurgeFriendly,
                },
                PurgeHigh = {
                    ActionDataAuras.PvP.PurgeHigh,
                },
                PurgeLow = {
                    ActionDataAuras.PvP.PurgeLow,
                },
            },
        },
	}
	-- Insert to profile db generated above 
	if not ActionDataAuras.DisableCheckboxes then 
		ActionDataAuras.DisableCheckboxes = {}
	end 	
	for specID in pairs(TMWdb.profile.ActionDB[5]) do 
		if UnitAuras[specID] then 
			ActionDataAuras.DisableCheckboxes[specID] = { UseDispel = true, UsePurge = true, UseExpelEnrage = true }
			for Mode, Mode_v in pairs(UnitAuras[specID]) do 
				for Category, Category_v in pairs(Mode_v) do 
					if not TMWdb.profile.ActionDB[5][specID][Mode] then 
						TMWdb.profile.ActionDB[5][specID][Mode] = {}
					end 
					if not TMWdb.profile.ActionDB[5][specID][Mode][Category] then 
						TMWdb.profile.ActionDB[5][specID][Mode][Category] = {}
					end 

					-- Always to reset
					if TMWdb.profile.ActionDB[5][specID][Mode][Category][GameLocale] then 
						wipe(TMWdb.profile.ActionDB[5][specID][Mode][Category][GameLocale])
					else 
						TMWdb.profile.ActionDB[5][specID][Mode][Category][GameLocale] = {}
					end 
				
					if Category:match("Dispel") then 
						ActionDataAuras.DisableCheckboxes[specID].UseDispel = false 
					elseif Category:match("Purge") then 
						ActionDataAuras.DisableCheckboxes[specID].UsePurge = false 
					elseif Category:match("Enrage") then 	
						ActionDataAuras.DisableCheckboxes[specID].UseExpelEnrage = false 
					end		
					for i = 1, #Category_v do 
						for k, v in pairs(Category_v[i]) do 
							TMWdb.profile.ActionDB[5][specID][Mode][Category][GameLocale][k] = v
						end 
					end 
				end 	
			end
			 
			for Checkbox, v in pairs(ActionDataAuras.DisableCheckboxes[specID]) do 
				if v then 
					TMWdb.profile.ActionDB[5][specID][Checkbox] = not v
				end 
			end 				
		end 		
	end 
end

-- TODO: Remove modules (old name "TMW Global Snippets")
local function GlobalsRemap()
	Action.PlayerSpec, Action.PlayerSpecName = GetSpecializationInfo(GetSpecialization())
	TMW:Fire("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED")	-- For MultiUnits to initialize CLEU and other purposes to be sure what variables was updated properly 
	TMW:Fire("TMW_ACTION_DEPRECATED")						-- TODO: Remove 
	if Action.PlayerSpec and TMWdb and TMWdb.profile.ActionDB then 
		_G.HE_Toggle = TMWdb.profile.ActionDB[1][Action.PlayerSpec].HE_Toggle ~= "ALL" and TMWdb.profile.ActionDB[1][Action.PlayerSpec].HE_Toggle or nil
		_G.HE_Pets = TMWdb.profile.ActionDB[1][Action.PlayerSpec].HE_Pets	
		if TMWdb.profile.ActionDB[1].DisableBlackBackground then 
			Action.BlackBackgroundSet(not TMWdb.profile.ActionDB[1].DisableBlackBackground)
		end 
	end 
end

-------------------------------------------------------------------------------
-- UI: Containers
-------------------------------------------------------------------------------
local tabFrame, strOnlyBuilder, macroFrame
local function ConvertSpellNameToID(spellName)
	local Name, _, _, _, _, _, ID = GetSpellInfo(spellName)
	if not Name then 
		for i = 1, 350000 do 
			Name, _, _, _, _, _, ID = GetSpellInfo(i) -- Action.GetSpellInfo(i)
			if Name ~= nil and Name ~= "" and Name == spellName then 
				return ID
			end 
		end 
	end 
	return ID 
end 
ConvertSpellNameToID = TMW:MakeSingleArgFunctionCached(ConvertSpellNameToID)
local function GetTableKeyIdentify(action)
	-- Using to link key in DB
	if not action.TableKeyIdentify then 
		action.TableKeyIdentify = strOnlyBuilder(action.SubType, action.ID, action.Desc, action.Color)
	end 
	return action.TableKeyIdentify
end
local function ShowTooltip(parent, show, ID, Type)
	if show then
		if ID == nil or Type == "SwapEquip" then  
			GameTooltip:Hide()
			return 
		end
		GameTooltip:SetOwner(parent)
		if Type == "Trinket" or Type == "Potion" or Type == "Item" then 
			GameTooltip:SetItemByID(ID) 
		else
			GameTooltip:SetSpellByID(ID)
		end 
	else
		GameTooltip:Hide()
	end
end
local function LayoutSpace(parent)
	-- Util for EasyLayout to create "space" in row since it support only elements
	return StdUi:Subtitle(parent, '')
end 
local function GetWidthByColumn(parent, col, offset)
	-- Util for EasyLayout to provide correctly width for dropdown menu since lib has bug to properly resize it 
	local left = parent.layout.padding.left
	local right = parent.layout.padding.right
	local width = parent:GetWidth() - parent.layout.padding.left - parent.layout.padding.right
	local gutter = parent.layout.gutter
	local columns = parent.layout.columns
	return (width / (columns / col)) - 2 * gutter + (offset or 0)
end 
local function GetAnchor(tab, spec)
	-- Uses for EasyLayout (only resizer / comfort remap)
	if tab.name == 1 or tab.name == 2 then 
		return tab.childs[spec].scrollChild
	else 
		return tab.childs[spec]
	end  
end 
local function GetKids(tab, spec)
	-- Uses for EasyLayout (resizer / toggles)
	if tab.name == 1 or tab.name == 2 then 
		return tab.childs[spec].scrollChild:GetChildrenWidgets()
	else 
		return tab.childs[spec]:GetChildrenWidgets()
	end  
end 
local function CreateResizer(parent)
	if not TMW or parent.resizer then return end 
	-- Pre Loading options if case if first time it failed 
	if TMW.Classes.Resizer_Generic == nil then 
		TMW:LoadOptions()
	end 	
	local frame = {}
	frame.resizer = TMW.Classes.Resizer_Generic:New(parent)
	frame.resizer:Show()
	frame.resizer.y_min = parent:GetHeight()
	frame.resizer.x_min = parent:GetWidth()
	if TELLMEWHEN_VERSIONNUMBER  >= 87302 then 
		frame.resizer.resizeButton.module.IsEnabled = true 
	end 
	TMW:TT(frame.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
	return frame
end 
local function CraftMacro(Name, Macro, perCharacter, QUESTIONMARK, leaveNewLine)
	if InCombatLockdown() then 
		Action.Print(L["MACROINCOMBAT"])
		return 
	end 
		
	if not macroFrame then 
		macroFrame = _G.MacroFrame		
	end
	
	if macroFrame and macroFrame:IsVisible() then 
		MacroFrame.CloseButton:Click()
	end 
	
	local numglobal, numperchar = GetNumMacros()	
	local NumMacros = perCharacter and numperchar or numglobal
	if (perCharacter and NumMacros >= MAX_CHARACTER_MACROS) or (not perCharacter and NumMacros >= MAX_ACCOUNT_MACROS) then 
		Action.Print(L["MACROLIMIT"])
		GameMenuButtonMacros:Click()
		return 
	end 
	
	Name = strgsub(Name, "\n", " ")
	for i = 1, MAX_CHARACTER_MACROS + MAX_ACCOUNT_MACROS do 
		if GetMacroInfo(i) == Name then 
			Action.Print(Name .. " - " .. L["MACROEXISTED"])
			GameMenuButtonMacros:Click()
			return 
		end 
	end 
	
	CreateMacro(Name, QUESTIONMARK and "INV_MISC_QUESTIONMARK" or GetMacroIcons()[1], not leaveNewLine and strgsub(Macro, "\n", " ") or Macro, perCharacter and 1 or nil)			
	Action.Print(L["MACRO"] .. " " .. Name .. " " .. L["CREATED"] .. "!")
	GameMenuButtonMacros:Click()
end
Action.CraftMacro = CraftMacro
local function GetActionTableByKey(key)
	-- @return table or nil 
	-- Note: Returns table object which can be used to pass methods by specified key 
	if Action[Action.PlayerSpec] and Action[Action.PlayerSpec][key] then 
		return Action[Action.PlayerSpec][key]
	elseif Action[key] and type(Action[key]) == "table" and Action[key].Type and Action[key].ID and Action[key].Desc then 
		return Action[key]
	end 
end 

-------------------------------------------------------------------------------
-- UI: ColorPicker - Container
-------------------------------------------------------------------------------
local ColorPicker 						= {
	Themes								= {
		BloodyBlue						= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["r"] = 1,
					["g"] = 0.8313725490196078,
					["b"] = 0.788235294117647,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.8117647058823529,
						["r"] = 0.3294117647058824,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.7803921568627451,
						["g"] = 0.6078431372549019,
						["r"] = 0.4549019607843137,
					},
					["disabled"] = {
						["a"] = 1,
						["b"] = 0.1843137254901961,
						["g"] = 0.1843137254901961,
						["r"] = 0.1843137254901961,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.9137254901960784,
						["r"] = 0.1058823529411765,
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 0.7803921568627451,
						["g"] = 0.6078431372549019,
						["r"] = 0.4549019607843137,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["r"] = 1,
					["g"] = 0,
					["b"] = 0.1803921568627451,
				},
				["blank"] = {
					["a"] = 0,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.8,
					["r"] = 0,
					["g"] = 0.01568627450980392,
					["b"] = 0.1098039215686275,
				},
				["highlight"] = {
					["a"] = 0.5,
					["r"] = 0.192156862745098,
					["g"] = 0.4823529411764706,
					["b"] = 0.4980392156862745,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0.2627450980392157,
					["g"] = 0.01176470588235294,
					["b"] = 0.04313725490196078,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.1294117647058823,
					["g"] = 0.00392156862745098,
					["b"] = 0.01568627450980392,
				},
				["buttonDisabled"] = {
					["a"] = 1,
					["r"] = 0.07058823529411765,
					["g"] = 0.0196078431372549,
					["b"] = 0.02352941176470588,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0.09411764705882353,
					["g"] = 0.1098039215686275,
					["b"] = 0.1058823529411765,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0.02352941176470588,
					["g"] = 0.03529411764705882,
					["b"] = 0.1490196078431373,
				},
			},
		},
		Orhell 							= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["r"] = 1,
					["g"] = 0.9,
					["b"] = 0,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["r"] = 0.5450980392156862,
						["g"] = 0,
						["b"] = 0.00392156862745098,
					},
					["subtitle"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.2823529411764706,
						["b"] = 0,
					},
					["disabled"] = {
						["a"] = 1,
						["r"] = 0.55,
						["g"] = 0.55,
						["b"] = 0.55,
					},
					["tooltip"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.07450980392156863,
						["b"] = 0,
					},
					["header"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.3529411764705882,
						["b"] = 0,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["r"] = 1,
					["g"] = 0.9,
					["b"] = 0,
				},
				["blank"] = {
					["a"] = 0,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.35,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["highlight"] = {
					["a"] = 0.5,
					["r"] = 0.4,
					["g"] = 0.4,
					["b"] = 0,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.2,
					["g"] = 0,
					["b"] = 0.03137254901960784,
				},
				["buttonDisabled"] = {
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0.4,
					["g"] = 0.4,
					["b"] = 0.4,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0.15,
					["g"] = 0.15,
					["b"] = 0.15,
				},
			},
		},
		Bubblegum 						= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["b"] = 0,
					["g"] = 0.9,
					["r"] = 1,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 0.5411764705882353,
						["g"] = 0.392156862745098,
						["r"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.6862745098039216,
						["g"] = 1,
						["r"] = 0.3254901960784314,
					},
					["disabled"] = {
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 0,
						["g"] = 0.8196060657501221,
						["r"] = 0.9999977946281433,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 0.5411764705882353,
						["g"] = 0.392156862745098,
						["r"] = 1,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["b"] = 0.9529411764705882,
					["g"] = 0.9764705882352941,
					["r"] = 1,
				},
				["blank"] = {
					["a"] = 0,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.6,
					["b"] = 0.06666666666666667,
					["g"] = 0.06666666666666667,
					["r"] = 0.06666666666666667,
				},
				["highlight"] = {
					["a"] = 0.5,
					["b"] = 0,
					["g"] = 0.4,
					["r"] = 0.4,
				},
				["border"] = {
					["a"] = 1,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["b"] = 0.2980392156862745,
					["g"] = 0.2352941176470588,
					["r"] = 0.192156862745098,
				},
				["buttonDisabled"] = {
					["a"] = 1,
					["b"] = 0.15,
					["g"] = 0.15,
					["r"] = 0.15,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
				["slider"] = {
					["a"] = 1,
					["b"] = 0.15,
					["g"] = 0.15,
					["r"] = 0.15,
				},
			},
		},
		DreamyPurple 					= {
			["progressBar"] = {
				["color"] = {
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["r"] = 0.803921568627451,
						["g"] = 0.3882352941176471,
						["b"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["r"] = 0.5411764705882353,
						["g"] = 0,
						["b"] = 0.7137254901960784,
					},
					["disabled"] = {
					},
					["tooltip"] = {
						["a"] = 1,
						["r"] = 0.8705882352941177,
						["g"] = 0.2509803921568627,
						["b"] = 1,
					},
					["header"] = {
						["a"] = 1,
						["r"] = 0.792156862745098,
						["g"] = 0,
						["b"] = 0.5529411764705883,
					},
				},
			},
			["highlight"] = {
				["color"] = {
				},
				["blank"] = {
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.56,
					["r"] = 0.09803921568627451,
					["g"] = 0,
					["b"] = 0.1568627450980392,
				},
				["highlight"] = {
				},
				["border"] = {
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.3450980392156863,
					["g"] = 0,
					["b"] = 0.4627450980392157,
				},
				["buttonDisabled"] = {
				},
				["borderDisabled"] = {
				},
				["slider"] = {
				},
			},
		},
		HotTomato						= {
			["progressBar"] = {
				["color"] = {
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 1,
						["r"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.9921568627450981,
						["g"] = 1,
						["r"] = 0.996078431372549,
					},
					["disabled"] = {
						["a"] = 1,
						["b"] = 0,
						["g"] = 0,
						["r"] = 0,
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 1,
						["r"] = 1,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.9803921568627451,
						["r"] = 0.9921568627450981,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.79,
					["r"] = 1,
					["g"] = 0.01568627450980392,
					["b"] = 0,
				},
				["blank"] = {
					["a"] = 0.82,
					["r"] = 0.9294117647058824,
					["g"] = 0.9294117647058824,
					["b"] = 0.9294117647058824,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.36,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0.5843137254901961,
				},
				["highlight"] = {
					["a"] = 1,
					["r"] = 1,
					["g"] = 1,
					["b"] = 1,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.07450980392156863,
					["g"] = 0.07450980392156863,
					["b"] = 0.07450980392156863,
				},
				["buttonDisabled"] = {
					["a"] = 0.97,
					["r"] = 0.5686274509803921,
					["g"] = 0,
					["b"] = 0,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
		},
	},
	Cache 								= {}, 										-- Stores default StdUi colors 	
	StdUiObjects						= CopyTable(Factory[1].ColorPickerConfig),	-- Stores objects as key and function as value. It doesn't cache 'highlight' because his data receives with real time by OnEnter handler
	strupperCache 						= setmetatable({}, {
		--__mode = "kv",
		__index = function(t, i)
			if not i then return end
			local o
			if type(i) == "number" then
				o = i
			else
				o = strupper(i)
			end
			t[i] = o
			return o
		end,
		__call = function(t, i)
			return t[i]
		end,
	}),
	tReplaceRGBA						= function(self, inT, fromT)
		-- @return nil 
		-- Replaces values for equal keys in 'inT' table from 'fromT' table without create new 
		for k, v in pairs(fromT) do 
			inT[k] = v
		end 
	end,
	tEqualRGBA							= function(self, x, y)
		-- @return boolean 
		return x.r == y.r and x.g == y.g and x.b == y.b and x.a == y.a
	end,
	tFindByOption						= function(self, t, option)
		-- @return table or nil 
		-- Usage: 
		-- 't' table in which do search i.e. StdUi.config[element]
		-- 'option' string i.e. StdUi.config[element][option] or StdUi.config[element] > color > normal (option)
		if t[option] then 
			return t[option]
		else 
			for k, v in pairs(t) do 
				if type(v) == "table" then  
					return self:tFindByOption(v, option)
				end 
			end 
		end 
	end,
	HasRGBA								= function(self, t)
		return t.r and t.g and t.b and t.a and true  
	end,
	MakeCache 							= function(self)
		if not next(self.Cache) then 
			local function CopyStdUiColors(toT, fromT, checkT)
				for k, v in pairs(fromT) do 
					if type(v) == "table" then 
						if self:HasRGBA(v) then 
							toT[k] = CopyTable(v)
						elseif checkT[k] then 
							toT[k] = {}
							CopyStdUiColors(toT[k], v, checkT[k])
						end 
					end 
				end 
			end 
			CopyStdUiColors(self.Cache, StdUi.config, Factory[1].ColorPickerConfig)
		end 
	end,
	MakeColors 							= function(self, t, element)
		-- Used for everything
		-- @usage: ColorPicker:MakeColors([t, element])
		-- Note: 
		--		 't' is manual color table i.e. self.Cache to reset 
		-- 		 'element' is a first level passthrough key i.e. font (element) > color > normal (option)
		for k, v in pairs(t or TMWdb.profile.ActionDB[1].ColorPickerConfig) do 
			if self:HasRGBA(v) then 			
				self:MakeOn(element, k, v)
			elseif next(v) then 
				self:MakeColors(v, element or k)
			end 			 
		end 
	end,	
	SetElementsIn						= function(self, t)
		-- @return t 
		-- Formates 't' table to create dropdown 'Element'
		if #t > 0 then 
			wipe(t)
		end 
		
		for k in pairs(Factory[1].ColorPickerConfig) do 
			local upLetters = self.strupperCache[k]			
			t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
		end 
		
		return t
	end,
	SetOptionsIn						= function(self, t, element, search)
		-- @return t 
		-- Formates 't' table to create dropdown 'Option'
		-- @usage: ColorPicker:SetOptionsIn(t, element) 
		if not search and #t > 0 then 
			wipe(t)
		end 
		
		for k, v in pairs(search or Factory[1].ColorPickerConfig[element]) do 
			if not next(v) or self:HasRGBA(v) then 
				local upLetters = self.strupperCache[k]
				t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
			else 
				self:SetOptionsIn(t, element, v)
			end 
		end 
		
		return t
	end,
	SetThemesIn							= function(self, t)
		-- @return t 
		-- Formates 't' table to create dropdown 'Theme'
		if #t > 0 then 
			wipe(t)
		end 
		
		for k in pairs(self.Themes) do 
			local upLetters = self.strupperCache[k]			
			t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
		end 
		
		return t
	end,
	ResetColors							= function(self)
		-- Used for everything 
		self:MakeColors(self.Cache)
		self.wasChanged = nil 
	end, 
	MakeOn								= function(self, element, option, t)
		-- Used for target apply to custom 
		-- @usage: ColorPicker:MakeOn(element, option[, t])
		local tStdUiConfig 		= self:tFindByOption(StdUi.config[element], option)
		local tCurrentConfig 	= t or self:tFindByOption(TMWdb.profile.ActionDB[1].ColorPickerConfig[element], option)
		
		if self:HasRGBA(tCurrentConfig) and not self:tEqualRGBA(tStdUiConfig, tCurrentConfig) then 
			self:tReplaceRGBA(tStdUiConfig, tCurrentConfig)
			
			-- Refresh already created frames 
			local objects = self:tFindByOption(self.StdUiObjects[element], option)
			if objects and next(objects) then 
				for obj, method in pairs(objects) do 										
					obj[method](obj, tStdUiConfig.r, tStdUiConfig.g, tStdUiConfig.b, tStdUiConfig.a)
					
					-- Refresh highlight 
					obj.origBackdropBorderColor = nil 
					if obj.target then 
						obj.target.origBackdropBorderColor = nil 
					end 					
				end 
			end 
			
			self.wasChanged = true
		end 
	end,
	ResetOn								= function(self, element, option)
		-- Used for target reset to default 
		-- @usage: ColorPicker:ResetOn(element, option)		
		self:MakeOn(element, option, self:tFindByOption(self.Cache[element], option))
	end,
	Initialize							= function(self)
		self:MakeCache()
		if Action.GetToggle(1, "ColorPickerUse") then 
			self:MakeColors()
		elseif self.wasChanged then 
			self:ResetColors()
		end 
		
		-- Fix StdUi bug with tab buttons, they become in disabled state 
		if tabFrame then 
			local selectedTab = tabFrame:GetSelectedTab()
			for _, tab in ipairs(tabFrame.tabs) do
				if tab.button and selectedTab ~= tab then
					tab.button:Enable()
				end 
			end 
		end 
	end,
}

do 
	-- Inserts in StdUi.config missed but required parts 
	local f = CreateFrame("Frame")
	f.subtitle = f:CreateFontString(nil, StdUi.config.font.strata, "GameFontNormal")
	local r, g, b = f.subtitle:GetTextColor()
	StdUi.config.font.color.subtitle 	= { r = r, g = g, b = b, a = 1 }
	StdUi.config.font.color.tooltip 	= { r = r, g = g, b = b, a = 1 } -- Equal to 'subtitle'

	function StdUi:Subtitle(parent, text, inherit)
		-- This is special envelope indicates that created fontString is subtitle
		local fs = StdUi:FontString(parent, text, inherit)
		if fs.SetTextColor then 
			if not ColorPicker.StdUiObjects.font.color.subtitle[fs] then 
				ColorPicker.StdUiObjects.font.color.subtitle[fs] = "SetTextColor"
			end 
			local c = StdUi.config.font.color.subtitle
			fs:SetTextColor(c.r, c.g, c.b, c.a)
		end 
		return fs 
	end 
end 

hooksecurefunc(StdUi, "SetTextColor", function(self, fontString, colorType)
	if fontString.SetTextColor then 
		colorType = colorType or "normal"	
		if colorType == "disabled" then 
			-- Remove from all enabled objects  	
			for k, v in pairs(ColorPicker.StdUiObjects.font.color) do 
				if k ~= colorType then 
					v[fontString] = nil 
				end 
			end 							
		else 
			-- Remove from all disabled objects  
			ColorPicker.StdUiObjects.font.color[colorType][fontString] 	= nil 
		end 
		
		if colorType == "header" then 
			-- Remove doubles 
			ColorPicker.StdUiObjects.font.color.normal[fontString] 		= nil 	
		end 
		
		if not ColorPicker.StdUiObjects.font.color[colorType][fontString] then 			
			ColorPicker.StdUiObjects.font.color[colorType][fontString] 	= "SetTextColor"
		end 	
	end 
end)

hooksecurefunc(StdUi, "HighlightButtonTexture", function(self, button)
	hooksecurefunc(button, "SetHighlightTexture", function(self, texObj)
		if texObj then 
			if not ColorPicker.StdUiObjects.highlight.color[texObj] then 
				ColorPicker.StdUiObjects.highlight.color[texObj] = "SetColorTexture"
			end 
		elseif self.highlightTexture then 
			ColorPicker.StdUiObjects.highlight.color[self.highlightTexture] = nil 
		end 
	end)
end)

hooksecurefunc(StdUi, "ApplyBackdrop", function(self, frame, type, border, insets)
	local isProgressBar = type == nil and border == nil and insets == nil and frame:GetObjectType() == "StatusBar"
	
	if isProgressBar then 
		if not ColorPicker.StdUiObjects.progressBar.color[frame] then 
			ColorPicker.StdUiObjects.progressBar.color[frame] 		= "SetStatusBarColor"
		end 
	else 		
		type 	= type 	 or "button"
		border 	= border or "border"
	
		if type == "buttonDisabled" or border == "borderDisabled" then 
			-- Remove from all enabled objects  	
			ColorPicker.StdUiObjects.backdrop.button[frame] 		= nil 	
			ColorPicker.StdUiObjects.backdrop.border[frame] 		= nil 	
		else 
			-- Remove from all disabled objects 
			ColorPicker.StdUiObjects.backdrop.buttonDisabled[frame] = nil 
			ColorPicker.StdUiObjects.backdrop.borderDisabled[frame] = nil 
		end 
		
		if not ColorPicker.StdUiObjects.backdrop[type][frame] then 
			ColorPicker.StdUiObjects.backdrop[type][frame]	 		= "SetBackdropColor"
		end 
		
		if not ColorPicker.StdUiObjects.backdrop[border][frame] then 
			ColorPicker.StdUiObjects.backdrop[border][frame]  		= "SetBackdropBorderColor"
		end 	
	end 
end)

hooksecurefunc(StdUi, "FrameTooltip", function(self, owner)
	-- StdUi v3 added a lot of bugs with tooltips, this code supposed to fix them 
	owner.stdUiTooltip:SetParent(UIParent)
	owner.stdUiTooltip:SetFrameStrata("TOOLTIP")
	owner.stdUiTooltip:SetClampedToScreen(true)
	local fs = owner.stdUiTooltip.text
	local _, oldHeight = fs:GetFont()
	fs:SetFontSize(oldHeight * 1.2) -- Retail used 1.2
	
	-- This is part of Color Picker 
	if not ColorPicker.StdUiObjects.font.color.tooltip[fs] then 
		ColorPicker.StdUiObjects.font.color.tooltip[fs] = "SetTextColor"
		local c = StdUi.config.font.color.tooltip
		fs:SetTextColor(c.r, c.g, c.b, c.a)
	end 
end)

-------------------------------------------------------------------------------
-- UI: LUA - Container
-------------------------------------------------------------------------------
local Functions = {}
local FormatedLuaCode = setmetatable({}, { __index = function(t, luaCode)
	t[luaCode] = setmetatable({}, { __index = function(tbl, thisunit)
		tbl[thisunit] = luaCode:gsub("thisunit", '"' .. thisunit .. '"') 
		return tbl[thisunit]
    end })
	return t[luaCode]
end })
local function GetCompiledFunction(luaCode, thisunit)
	local func, err
	luaCode = FormatedLuaCode[luaCode][thisunit or ""] 
	if Functions[luaCode] then
		return Functions[luaCode]
	end	

	func, err = loadstring(luaCode)
	
	if func then
		setfenv(func, setmetatable(Action, { __index = _G }))
		Functions[luaCode] = func
	end	
	return func, err
end
local function RunLua(luaCode, thisunit)
	if not luaCode or luaCode == "" then 
		return true 
	end 
	
	local func = GetCompiledFunction(luaCode, thisunit)
	return func and func()
end
local function CreateLuaEditor(parent, title, w, h, editTT)
	-- @return frame which is simular between WeakAura and TellMeWhen (if IndentationLib loaded, otherwise without effects like colors and tabulations)
	local LuaWindow = StdUi:Window(parent, w, h, title)
	LuaWindow:SetShown(false)
	LuaWindow:SetFrameStrata("DIALOG")
	LuaWindow:SetMovable(false)
	LuaWindow:EnableMouse(false)
	StdUi:GlueAfter(LuaWindow, Action.MainUI, 0, 0)	
	
	LuaWindow.UseBracketMatch = StdUi:Checkbox(LuaWindow, L["TAB"]["BRACKETMATCH"])
	StdUi:GlueTop(LuaWindow.UseBracketMatch, LuaWindow, 15, -15, "LEFT")
	
	LuaWindow.LineNumber = StdUi:Subtitle(LuaWindow, "")
	LuaWindow.LineNumber:SetFontSize(14)
	StdUi:GlueTop(LuaWindow.LineNumber, LuaWindow, 0, -30)
	
	local widget = StdUi:MultiLineBox(LuaWindow, 100, 5, "") 
	widget.editBox.stdUi = StdUi
	widget.scrollFrame.stdUi = StdUi
	LuaWindow.EditBox = widget.editBox
	LuaWindow.EditBox:SetText("")
	LuaWindow.EditBox.panel:SetBackdropColor(0, 0, 0, 1)
	StdUi:GlueAcross(LuaWindow.EditBox.panel, LuaWindow, 5, -50, -5, 5)
	
	if editTT then 
		StdUi:FrameTooltip(LuaWindow.EditBox, editTT, nil, "TOPLEFT", "TOPLEFT")
	end 	
	
	-- The indention lib overrides GetText, but for the line number
	-- display we need the original, so save it here
	LuaWindow.EditBox.GetOriginalText = LuaWindow.EditBox.GetText
	-- ForAllIndentsAndPurposes
	if IndentationLib then
		-- Monkai   
		local theme = {		
			["Table"] = "|c00ffffff",
			["Arithmetic"] = "|c00f92672",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c00f92672",
			["Special"] = "|c0066d9ef",
			["Keyword"] =  "|c00f92672",
			["Comment"] = "|c0075715e",
			["Number"] = "|c00ae81ff",
			["String"] = "|c00e6db74"
		}
  
		local color_scheme = { [0] = "|r" }
		color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
		color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
		color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

		color_scheme["..."] = theme["Table"]
		color_scheme["{"] = theme["Table"]
		color_scheme["}"] = theme["Table"]
		color_scheme["["] = theme["Table"]
		color_scheme["]"] = theme["Table"]

		color_scheme["+"] = theme["Arithmetic"]
		color_scheme["-"] = theme["Arithmetic"]
		color_scheme["/"] = theme["Arithmetic"]
		color_scheme["*"] = theme["Arithmetic"]
		color_scheme[".."] = theme["Arithmetic"]

		color_scheme["=="] = theme["Relational"]
		color_scheme["<"] = theme["Relational"]
		color_scheme["<="] = theme["Relational"]
		color_scheme[">"] = theme["Relational"]
		color_scheme[">="] = theme["Relational"]
		color_scheme["~="] = theme["Relational"]

		color_scheme["and"] = theme["Logical"]
		color_scheme["or"] = theme["Logical"]
		color_scheme["not"] = theme["Logical"]
		
		IndentationLib.enable(LuaWindow.EditBox, color_scheme, 4)		
	end 
	
	-- Bracket Matching
	LuaWindow.EditBox:SetScript("OnChar", function(self, char)		
		if not IsControlKeyDown() and LuaWindow.UseBracketMatch:GetChecked() then 
			if char == "(" then
				LuaWindow.EditBox:Insert(")")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "{" then
				LuaWindow.EditBox:Insert("}")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "[" then
				LuaWindow.EditBox:Insert("]")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			end	
		end 
	end)
		
	-- Update Line Number 
	LuaWindow.EditBox:HookScript("OnCursorChanged", function() 
		local cursorPosition = LuaWindow.EditBox:GetCursorPosition()
		local next = -1
		local line = 0
		while (next and cursorPosition >= next) do
			next = LuaWindow.EditBox.GetOriginalText(LuaWindow.EditBox):find("[\n]", next + 1)
			line = line + 1
		end
		LuaWindow.LineNumber:SetText(line)
	end)	
	
	-- Set manual black color (if enabled custom Color Picker)
	LuaWindow.EditBox:HookScript("OnShow", function(self)
		if Action.GetToggle(1, "ColorPickerUse") then 
			self.panel:SetBackdropColor(0, 0, 0, 1)
		end 
	end)
	
	-- Close handlers 		
	LuaWindow.closeBtn:SetScript("OnClick", function(self) 
		LuaWindow.LineNumber:SetText(nil)
		local Code = LuaWindow.EditBox:GetText()
		local CodeClear = Code:gsub("[\r\n\t%s]", "")		
		if CodeClear ~= nil and CodeClear:len() > 0 then 
			-- Check user mistakes with quotes on thisunit 
			if Code:find("'thisunit'") or Code:find('"thisunit"') then 				
				LuaWindow.EditBox.LuaErrors = true	
				error("thisunit must be without quotes!")
				return
			end 
		
			-- Check syntax on errors
			local func, err = GetCompiledFunction(Code)
			if not func then 				
				LuaWindow.EditBox.LuaErrors = true	
				error(err or "Unexpected error in GetCompiledFunction function - Code exists in table but 'err' become 'nil'")
				return
			end 
			
			-- Check game API on errors
			local success, errorMessage = pcall(func)
			if not success then  					
				LuaWindow.EditBox.LuaErrors = true		
				error(errorMessage)
				return
			end 		
			
			LuaWindow.EditBox.LuaErrors = nil 
		else 
			LuaWindow.EditBox.LuaErrors = nil
			LuaWindow.EditBox:SetText("")
		end 
		self:GetParent():Hide()
	end)
	
	LuaWindow:SetScript("OnHide", function(self)
		self.closeBtn:Click() 
	end)
	
	LuaWindow.EditBox:SetScript("OnEscapePressed", function() 
		LuaWindow.closeBtn:Click() 
	end)
	
	return LuaWindow
end 

-- [3] LUA API 
function Action:GetLUA()
	return TMWdb.profile.ActionDB[3][Action.PlayerSpec].luaActions[GetTableKeyIdentify(self)] 
end

function Action:SetLUA(luaCode)
	TMWdb.profile.ActionDB[3][Action.PlayerSpec].luaActions[GetTableKeyIdentify(self)] = luaCode
end 

function Action:RunLua(thisunit)
	return RunLua(self:GetLUA(), thisunit)
end

-- [3] QLUA API 
function Action:GetQLUA()
	return TMWdb.profile.ActionDB[3][Action.PlayerSpec].QluaActions[GetTableKeyIdentify(self)] 
end

function Action:SetQLUA(luaCode)
	TMWdb.profile.ActionDB[3][Action.PlayerSpec].QluaActions[GetTableKeyIdentify(self)] = luaCode
end 

function Action:RunQLua(thisunit)
	return RunLua(self:GetQLUA(), thisunit)
end

-------------------------------------------------------------------------------
-- UI: API
-------------------------------------------------------------------------------
-- [1] Mode 
function Action.ToggleMode()
	Action.IsLockedMode = true
	Action.IsInPvP = not Action.IsInPvP	
	Action.Print(L["SELECTED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
	TMW:Fire("TMW_ACTION_MODE_CHANGED")
end 

-- [1] Burst 
function Action.ToggleBurst(fixed, between)
	local Current = Action.GetToggle(1, "Burst")
	
	local set
	if between and fixed ~= between then 	
		if Current == fixed then 
			set = between
		else 
			set = fixed
		end 
	end 
	
	if Current ~= "Off" then 		
		ActionDataTG.Burst = Current
		Current = "Off"
	elseif ActionDataTG.Burst == nil then  
		Current = "Everything"
		ActionDataTG.Burst = Current
	else
		Current = ActionDataTG.Burst
	end 			
	
	Action.SetToggle({1, "Burst", L["TAB"][1]["BURST"] .. ": "}, set or fixed or Current)	
end 

function Action.BurstIsON(unitID)	
	-- @return boolean
	-- Note: This function is cached
	local Current = Action.GetToggle(1, "Burst")
	
	if Current == "Auto" then  
		local unit = unitID or "target"
		return Action.Unit(unitID):IsPlayer() or Action.Unit(unitID):IsBoss()
	elseif Current == "Everything" then 
		return true 
	end 		
	
	return false 			
end 

-- [1] Racial 
function Action.RacialIsON(self)
	-- @usage Action.RacialIsON() or Action:RacialIsON()
	-- @return boolea
	return Action.GetToggle(1, "Racial") and (not self or self:IsExists())
end 

-- [1] HealingEngine 
local tempToggleHE = {1, "HE_Toggle", "HealingEngine: "}
function Action.ToggleHE(fixed)
	local Current = Action.GetToggle(1, "HE_Toggle")
	if Current == "ALL" then 		
		Current = "RAID"
	elseif Current == "RAID" then  
		Current = "TANK"
	elseif Current == "TANK" then 
		Current = "DAMAGER"
	elseif Current == "DAMAGER" then 
		Current = "HEALER"
	else 
		Current = "ALL"
	end 		
	Action.SetToggle(tempToggleHE, fixed or Current)	
end 

-- [1] ReTarget // ReFocus
local Re = {
	Units = { "arena1", "arena2", "arena3" },
	-- Textures 
	target = {
		["arena1"] = ACTION_CONST_PVP_TARGET_ARENA1,
		["arena2"] = ACTION_CONST_PVP_TARGET_ARENA2,
		["arena3"] = ACTION_CONST_PVP_TARGET_ARENA3,
	},
	focus = {
		["arena1"] = ACTION_CONST_PVP_FOCUS_ARENA1,
		["arena2"] = ACTION_CONST_PVP_FOCUS_ARENA2,
		["arena3"] = ACTION_CONST_PVP_FOCUS_ARENA3,
	},	
	-- OnEvent 
	PLAYER_TARGET_CHANGED = function(self)
		if (Action.Zone == "arena" or Action.Zone == "pvp") then 			
			if UnitExists("target") then 
				Action.LastTargetIsExists = true 
				for i = 1, #self.Units do
					if UnitIsUnit("target", self.Units[i]) then 
						Action.LastTargetUnitID = self.Units[i]
						Action.LastTargetTexture = self.target[Action.LastTargetUnitID]
					end 
				end 
			else
				Action.LastTargetIsExists = false 
			end 
		end 		
	end,	
	PLAYER_FOCUS_CHANGED = function(self)
		if (Action.Zone == "arena" or Action.Zone == "pvp") then 
			if UnitExists("focus") then 
				Action.LastFocusIsExists = true 
				for i = 1, #self.Units do 
					if UnitIsUnit("focus", self.Units[i]) then 
						Action.LastFocusUnitID = self.Units[i]
						Action.LastFocusTexture = self.focus[Action.LastFocusUnitID]
					end 
				end 
			else
				Action.LastFocusIsExists = false 
			end 
		end 
	end,
	Wipe			= function(self)
		Action.LastTargetIsExists	= nil
		Action.LastTargetUnitID 	= nil 
		Action.LastTargetTexture 	= nil 
		Action.LastFocusIsExists 	= nil 
		Action.LastFocusUnitID 		= nil
		Action.LastFocusTexture 	= nil		
	end,
	Reset 			= function(self)		
		Action.Listener:Remove("ACTION_EVENT_RE", 		"PLAYER_TARGET_CHANGED")
		Action.Listener:Remove("ACTION_EVENT_RE", 		"PLAYER_FOCUS_CHANGED")
		self:Wipe()
	end,
	Initialize		= function(self)
		if Action.GetToggle(1, "ReTarget") then 
			Action.Listener:Add(   "ACTION_EVENT_RE", 	"PLAYER_TARGET_CHANGED", function() self:PLAYER_TARGET_CHANGED() end)
			self:PLAYER_TARGET_CHANGED()
		else 
			Action.Listener:Remove("ACTION_EVENT_RE", 	"PLAYER_TARGET_CHANGED")
			Action.LastTargetIsExists	= nil
			Action.LastTargetUnitID 	= nil 
			Action.LastTargetTexture 	= nil 			
		end 
		
		if Action.GetToggle(1, "ReFocus") then 
			Action.Listener:Add(   "ACTION_EVENT_RE", 	"PLAYER_FOCUS_CHANGED",  function() self:PLAYER_FOCUS_CHANGED()  end)
			self:PLAYER_FOCUS_CHANGED()
		else 
			Action.Listener:Remove("ACTION_EVENT_RE", 	"PLAYER_FOCUS_CHANGED")
			Action.LastFocusIsExists 	= nil 
			Action.LastFocusUnitID 		= nil
			Action.LastFocusTexture 	= nil			
		end 	
	end,
}

-- [1] LOS System (Line of Sight)
local LineOfSight = {
	Cache 			= setmetatable({}, { __mode = "kv" }),
	Timer			= 5,	
	NamePlateFrame	= setmetatable({}, { __index = function(t, i)
		if _G["NamePlate" .. i] then 
			t[i] = _G["NamePlate" .. i]
			return t[i]
		end 
	end }),
	-- Functions
	UnitInLOS 		= function(self, unitID, unitGUID)		
		if Action.IsInitialized and not Action.GetToggle(1, "LOSCheck") then  -- TODO: Remove Action.IsInitialized (old profiles)
			return false 
		end 

		if not UnitIsUnit("target", unitID) and A_Unit(unitID):IsNameplateAny() then 
			-- Not valid for @target
			for i = 1, huge do 
				if not self.NamePlateFrame[i] then 
					break 
				elseif self.NamePlateFrame[i].UnitFrame.unitExists and UnitIsUnit(self.NamePlateFrame[i].UnitFrame.unit, unitID) then
					return self.NamePlateFrame[i].UnitFrame:GetEffectiveAlpha() <= 0.4				
				end 
			end 
		else 
			local GUID = unitGUID or UnitGUID(unitID)
			return GUID and self.Cache[GUID] and TMW.time < self.Cache[GUID]
		end 
	end,
	Wipe 			= function(self)
		-- Physical reset 
		self.PhysicalUnitID 	= nil
		self.PhysicalUnitGUID	= nil	
		self.PhysicalUnitWait 	= nil
	end,
	Reset 			= function(self)		
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"UI_ERROR_MESSAGE")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"COMBAT_LOG_EVENT_UNFILTERED")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_ENABLED")
		Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_DISABLED")
		self:Wipe()
	end,
	-- OnEvent
	UI_ERROR_MESSAGE = function(self, ...)
		if (Action.IsInitialized or LOSCheck) and select(2, ...) == ACTION_CONST_SPELL_FAILED_LINE_OF_SIGHT then   -- TODO: Remove Action.IsInitialized and LOSCheck (old profiles)
			if self.PhysicalUnitID and TMW.time >= self.PhysicalUnitWait then 
				local SkipTimer = self.Timer
				-- Fix for HealingEngine
				if Action.IamHealer and self.PhysicalUnitID == "target" and self.PhysicalUnitGUID == UnitGUID(self.PhysicalUnitID) then 
					if Action.Zone == "arena" then 
						SkipTimer = 3 
					else 
						SkipTimer = 9
					end 
				end 

				if self.PhysicalUnitGUID then 
					self.Cache[self.PhysicalUnitGUID] = TMW.time + SkipTimer
				else 
					local GUID = UnitGUID(self.PhysicalUnitID)
					if GUID then 
						self.Cache[GUID] = TMW.time + SkipTimer
					end 
				end 
				
				self:Wipe()
				return
			end 

			if Action.IsInitialized and Action.IamHealer and Action.IsUnitEnemy("targettarget") then -- TODO: Remove Action.IsInitialized (old profiles)
				self.Cache[UnitGUID("targettarget")] = TMW.time + self.Timer
			end 
		end 	
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
		if Action.IsInitialized or LOSCheck then -- TODO: Remove Action.IsInitialized and LOSCheck (old profiles)
			local _, event, _, SourceGUID, _,_,_, DestGUID = CombatLogGetCurrentEventInfo()	
			if event == "SPELL_CAST_SUCCESS" and self.Cache[DestGUID] and SourceGUID and SourceGUID == UnitGUID("player") then 
				self.Cache[DestGUID] = nil 
				if self.PhysicalUnitID and DestGUID == (self.PhysicalUnitGUID or UnitGUID(self.PhysicalUnitID)) then 
					self:Wipe()
				end 
			end 	
		end 
	end,
	Initialize		= function(self, isLaunchOLD) -- TODO: Remove isLaunchOLD (old profiles)
		if isLaunchOLD or Action.GetToggle(1, "LOSCheck") then 	
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "UI_ERROR_MESSAGE", 				function(...) self:UI_ERROR_MESSAGE(...) 			end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "COMBAT_LOG_EVENT_UNFILTERED", 	function(...) self:COMBAT_LOG_EVENT_UNFILTERED(...) end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_ENABLED", 			function() 	  wipe(self.Cache)						end)
			Action.Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_DISABLED", 		function() 	  wipe(self.Cache)						end)
		else 			
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "UI_ERROR_MESSAGE")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "COMBAT_LOG_EVENT_UNFILTERED")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_ENABLED")
			Action.Listener:Remove("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_DISABLED")		
			wipe(self.Cache)	
		end 
	end,
}

function Action.SetTimerLOS(timer)
	-- Sets timer for non @target units to skip during 'timer' (seconds) after message receive
	LineOfSight.Timer = timer 
end 

function Action.UnitInLOS(unitID, unitGUID)
	-- @return boolean
	return LineOfSight:UnitInLOS(unitID, unitGUID)
end 

function GetLOS(unitID) 
	-- External physical button use 
	if (not Action.IsInitialized and LOSCheck) or (Action.IsInitialized and Action.GetToggle(1, "LOSCheck")) then -- TODO: Remove LOSCheck (old profiles)		
		if not Action.IsActiveGCD() and (not LineOfSight.PhysicalUnitID or TMW.time > LineOfSight.PhysicalUnitWait) and (unitID ~= "target" or not LineOfSight.PhysicalUnitWait or TMW.time > LineOfSight.PhysicalUnitWait + 1) and not Action.UnitInLOS(unitID) then 
			LineOfSight.PhysicalUnitID = unitID
			if unitID == "target" then 
				LineOfSight.PhysicalUnitGUID = UnitGUID(unitID)
			end 
			-- 0.3 seconds is how much time need wait before start trigger message because if make it earlier it can trigger message from another unit  
			LineOfSight.PhysicalUnitWait = TMW.time + 0.3 
		end 
	end 
end 

-- [1] HideOnScreenshot
local ScreenshotHider = {
	HiddenFrames	  = {},
	-- OnEvent 
	OnStart			  = function(self)
		if Action.IsInitialized then 
			-- TellMeWhen 
			for i = 1, huge do 
				local FrameName = "TellMeWhen_Group" .. i
				if _G[FrameName] then 
					if _G[FrameName]:IsShown() then 
						tinsert(self.HiddenFrames, FrameName)
						_G[FrameName]:Hide()
					end 
				else 
					break 
				end 
			end 	
			
			-- UI 
			if Action.MainUI and Action.MainUI:IsShown() then 
				tinsert(self.HiddenFrames, "MainUI")
				Action.ToggleMainUI()
			end 
			
			if Action.MinimapIsShown() then 
				tinsert(self.HiddenFrames, "Minimap")
				Action.ToggleMinimap(false)
			end 
			
			if Action.BlackBackgroundIsShown() then 
				tinsert(self.HiddenFrames, "BlackBackground")
				Action.BlackBackgroundSet(false)
			end 
		end 
	end,
	OnStop			  = function(self)
		if #self.HiddenFrames > 0 then 
			for i = 1, #self.HiddenFrames do 
				if self.HiddenFrames[i] == "MainUI" then 
					Action.ToggleMainUI()
				elseif self.HiddenFrames[i] == "Minimap" then 
					Action.ToggleMinimap(true)
				elseif self.HiddenFrames[i] == "BlackBackground" then 
					Action.BlackBackgroundSet(true)	
				elseif _G[self.HiddenFrames[i]] then 
					_G[self.HiddenFrames[i]]:Show()
				end 
			end 
			
			wipe(self.HiddenFrames)
		end 	
	end,
	-- UI 
	Initialize 		 = function(self, toggle)
		if toggle then 
			Action.Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_STARTED", 	function() self:OnStart() end)
			Action.Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_FAILED", 	function() self:OnStop()  end)
			Action.Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_SUCCEEDED", 	function() self:OnStop()  end)
		else 
			Action.Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_STARTED"		)
			Action.Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_FAILED"		)
			Action.Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_SUCCEEDED"	)
			self:OnStop()
		end 
	end,
	Reset			= function(self)
		self:Initialize()
	end,
}

-- [2] AoE toggle through Ctrl+Left Click on main picture 
local tempAoE = {2, "AoE"}
function Action.ToggleAoE()
	Action.SetToggle(tempAoE)
end 

-- [3] SpellLevel (skipping unknown spells by character level)
local SpellLevel = { 
	Blocked 		= {},
	Wipe			= function(self)
		Action.Listener:Remove("ACTION_EVENT_SPELLLEVEL", 	"PLAYER_LEVEL_UP")
		Action.Listener:Remove("ACTION_EVENT_SPELLLEVEL", 	"PLAYER_SPECIALIZATION_CHANGED")
		wipe(self.Blocked)
		self.Initialized = nil
		self.PlayerLVL 	 = nil 
		self.PlayerSpec  = nil	
		TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")
	end,
	Reset 			= function(self, isSwapProfile)	
		if not isSwapProfile and Action.GetToggle(3, "CheckSpellLevel") then 
			Action.SetToggle({3, "CheckSpellLevel", L["TAB"][3]["CHECKSPELLLVL"] .. ": "}, false)
		end 
		self:Wipe()
	end,
	Update			= function(self, ...)
		if self.Initialized then
			local lvl = ... or UnitLevel("player")
			if lvl and (lvl ~= self.PlayerLVL or Action.PlayerSpec ~= self.PlayerSpec) then 
				self.PlayerLVL, self.PlayerSpec  = lvl, Action.PlayerSpec	

				if self.PlayerLVL >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] then 
					Action.Print(L["DEBUG"] .. L["TAB"][3]["CHECKSPELLLVLERRORMAXLVL"])
					self:Reset()
					return 
				end 
				
				wipe(self.Blocked)
				
				for k, v in pairs(Action[Action.PlayerSpec]) do 
					if type(v) == "table" and v.Type == "Spell" then 
						local book, slot = BOOKTYPE_SPELL,  FindSpellBookSlotBySpellID(v.ID, false)  

						if not slot then 
							book, slot 	 = BOOKTYPE_PET, 	FindSpellBookSlotBySpellID(v.ID, true)
						end 
						
						if slot then 
							local AvailableLevel = GetSpellAvailableLevel(slot, book)
							
							if AvailableLevel and AvailableLevel > self.PlayerLVL then 
								self.Blocked[v.ID] = true 
							end 
						end
					end 
				end 
				
				TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")
			end
		end 	
	end,
	Initialize		= function(self, isLaunch)		
		if Action[Action.PlayerSpec] and UnitLevel("player") < MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] then 			
			if isLaunch then 
				TMWdb.profile.ActionDB[3].CheckSpellLevel = true 
			else 
				Action.SetToggle({3, "CheckSpellLevel", L["TAB"][3]["CHECKSPELLLVL"] .. ": "})
			end 
			
			local toggle = Action.GetToggle(3, "CheckSpellLevel") 
			if toggle then 
				if not self.Initialized then 		
					self.Initialized = true
					Action.Listener:Add("ACTION_EVENT_SPELLLEVEL", "PLAYER_LEVEL_UP", 				function(...) 	self:Update(...) 	end)
					Action.Listener:Add("ACTION_EVENT_SPELLLEVEL", "PLAYER_SPECIALIZATION_CHANGED", function() 		self:Update() 		end)
					if isLaunch then 
						Action.Print(L["TAB"][3]["CHECKSPELLLVL"] .. ": ", toggle)
					end 
					self:Update()
				elseif not isLaunch then  
					Action.Print(L["DEBUG"] .. L["TAB"][3]["CHECKSPELLLVLERROR"])
				end 
			elseif self.Initialized then 	
				self:Wipe()
			end 
		elseif self.Initialized then 	
			self:Wipe()
		end 		
	end,
}

function Action:IsBlockedBySpellLevel()
	-- @return boolean
	return SpellLevel.Initialized and SpellLevel.Blocked[self.ID]
end 

-- [3] SetBlocker 
function Action:IsBlocked()
	-- @return boolean 
	return TMWdb.profile.ActionDB[3][Action.PlayerSpec].disabledActions[GetTableKeyIdentify(self)] == true
end

function Action:SetBlocker()
	-- Sets block on action
	-- Note: /run Action[Action.PlayerSpec].WordofGlory:SetBlocker()
	if self.BlockForbidden and not self:IsBlocked() then 
		Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORBLOCK"])
        return 		
	end 
	
	local Notification 
	local Identify = GetTableKeyIdentify(self)
	if self:IsBlocked() then 
		TMWdb.profile.ActionDB[3][Action.PlayerSpec].disabledActions[Identify] = nil 
		Notification = L["TAB"][3]["UNBLOCKED"] .. self:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]"		
	else 
		TMWdb.profile.ActionDB[3][Action.PlayerSpec].disabledActions[Identify] = true
		Notification = L["TAB"][3]["BLOCKED"] .. self:Link() .. " " ..  L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]"
	end 
    Action.Print(Notification)
	
	if Action.MainUI then 
		local spec = Action.PlayerSpec .. CL	
		local ScrollTable = tabFrame.tabs[3].childs[spec].ScrollTable
		for i = 1, #ScrollTable.data do 
			if Identify == GetTableKeyIdentify(ScrollTable.data[i]) then 
				if self:IsBlocked() then 
					ScrollTable.data[i].Enabled = "False"
				else 
					ScrollTable.data[i].Enabled = "True"
				end								 			
			end 
		end		
		ScrollTable:ClearSelection() 
	end 
end

function Action.MacroBlocker(key)
	-- Sets block on action with avoid lua errors for non exist key
	local object = GetActionTableByKey(key)
	if not object then 
		Action.Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetBlocker()
end

-- [3] SetQueue (Queue System)
local Queue = {
	Temp 						= {
		SilenceON				= { Silence = true },
		SilenceOFF				= { Silence = false },
	},
	Reset 						= function(self)
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "ACTIVE_TALENT_GROUP_CHANGED")		
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_SPECIALIZATION_CHANGED")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED")	
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_TALENT_UPDATE")
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED")	
		Action.Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD")	
		TMW:UnregisterCallback("TMW_ACTION_MODE_CHANGED", function() self:OnEventToReset() end,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET")
	end, 
	IsThisMeta 					= function(self, meta)
		return (not ActionDataQ[1].MetaSlot and (meta == 3 or meta == 4)) or ActionDataQ[1].MetaSlot == meta
	end, 
	IsInterruptAbleChannel 		= {
		-- Monk MW: Smoothing Mist 
		[115175]				= true,
	},
	-- Events
	UNIT_SPELLCAST_SUCCEEDED 	= function(self, ...)
		local source, _, spellID = ...
		if (source == "player" or source == "pet") and ActionDataQ[1] and ActionDataQ[1].Type == "Spell" and Action.GetSpellInfo(spellID) == ActionDataQ[1]:Info() then 			
			getmetatable(ActionDataQ[1]).__index:SetQueue(self.Temp.SilenceON)
		end 	
	end,
	BAG_UPDATE_COOLDOWN			= function(self)
		if ActionDataQ[1] and ActionDataQ[1].Type ~= "Spell" and ActionDataQ[1].Type ~= "SwapEquip" then 
			local start, duration, enable = ActionDataQ[1].Item:GetCooldown()
			if duration and math_abs(TMW.time - start) <= 2 then 
				getmetatable(ActionDataQ[1]).__index:SetQueue(self.Temp.SilenceON)
				return 
			end 
			-- For things like a potion that was used in combat and the cooldown hasn't yet started counting down
			if enable == 0 and ActionDataQ[1].Type ~= "Trinket" then 
				getmetatable(ActionDataQ[1]).__index:SetQueue(self.Temp.SilenceON)
			end 
		end 	
	end,
	ITEM_UNLOCKED				= function(self)
		if ActionDataQ[1] and ActionDataQ[1].Type == "SwapEquip" then 
			getmetatable(ActionDataQ[1]).__index:SetQueue(self.Temp.SilenceON)
		end 
	end, 	
	OnEventToResetNoCombat 		= function(self, isSilenced)
		-- ByPass wrong reset events by equip swap during combat
		if Action.Unit("player"):CombatTime() == 0 then 
			self:OnEventToReset(isSilenced)
		end 
	end, 
	OnEventToReset 				= function(self, isSilenced)
		if #ActionDataQ > 0 then 
			for i = #ActionDataQ, 1, -1 do 
				if ActionDataQ[i] and ActionDataQ[i].Queued then 
					getmetatable(ActionDataQ[i]).__index:SetQueue((isSilenced and self.Temp.SilenceON) or self.Temp.SilenceOFF)
				end 
			end 		
		end 
		wipe(ActionDataQ) 
		self:Reset()
	end, 
}

function Action:QueueValidCheck()
	-- @return boolean
	-- Note: This thing does mostly tasks but still causing some issues with certain spells which should be blacklisted or avoided through another way (ideally) 
	-- Example of issue: Monk can set Queue for Resuscitate while has @target an enemy and it will true because it will set to variable "player" which is also true and correct!
	-- Why "player"? Coz while @target an enemy you can set queue of supportive spells for "self" and if they will be used on enemy then they will be applied on "player" 	
	local isCastingName, _, _, _, castID, isChannel = Action.Unit("player"):IsCasting()
	if (not isCastingName or isCastingName ~= self:Info()) and (not isChannel or Queue.IsInterruptAbleChannel[castID]) then
		if self.Type == "SwapEquip" or self.isStance then 
			return true 
		elseif not self:HasRange() then 
			return self:AbsentImun(self.UnitID, self.AbsentImunQueueCache)	-- Well at least will do something, better than nothing 
		else 
			local isHarm 	= self:IsHarmful()
			local unitID 	= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and ((isHarm and "target") or (not Action.IamHealer and "player"))) or "target"
			self.UnitID		= unitID
			-- IsHelpful for Item under testing phase
			-- unitID 		= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and (((isHarm or self:IsHelpful()) and "target") or (not Action.IamHealer and "player"))) or "target"
			
			if isHarm then 
				return Action.Unit(unitID):IsEnemy() and self:IsInRange(unitID) and self:AbsentImun(unitID, self.AbsentImunQueueCache)
			else 
				return UnitIsUnit(unitID, "player") or (self:IsInRange(unitID) and self:AbsentImun(unitID))
			end 
		end 
	end 
	return false 
end 

function Action.CancelAllQueue()
	Queue:OnEventToReset(true)
end 

function Action.CancelAllQueueForMeta(meta)
	local index 			= #ActionDataQ 
	if index > 0 then 
		for i = index, 1, -1 do 
			if (not ActionDataQ[i].MetaSlot and (meta == 3 or meta == 4)) or ActionDataQ[i].MetaSlot == meta then 
				getmetatable(ActionDataQ[i]).__index:SetQueue(Queue.Temp.SilenceON)
			end 
		end 
	end 
end 

function Action.IsQueueRunning()
	-- @return boolean 
	return #ActionDataQ > 0
end 

function Action.IsQueueRunningAuto()
	-- @return boolean 	
	local index = #ActionDataQ
	return index > 0 and (ActionDataQ[index].Auto or ActionDataQ[1].Auto)
end 

function Action.IsQueueReady(meta)
	-- @return boolean
	local index = #ActionDataQ
    if index > 0 and Queue:IsThisMeta(meta) then 		
		local self = ActionDataQ[1]
		if self.Auto and self.Start and TMW.time - self.Start > (ActionDataQueueAutoResetTimer or 10) then 
			Queue:OnEventToReset()
			return false 
		end 	
        if self.Type == "Spell" or self.Type == "Trinket" or self.Type == "Potion" or self.Type == "Item" then -- Note: Equip, Count, Existance of action already checked in Action:SetQueue 
			if self.UnitID == "player" or self:QueueValidCheck() then 
				return self:IsUsable(self.ExtraCD) and (not self.PowerCustom or UnitPower("player", self.PowerType) >= (self.PowerCost or 0)) and (self.Auto or self:RunQLua(self.UnitID))   
			end
		elseif self.Type == "SwapEquip" then 
			return not Action.Player:IsSwapLocked() and (self.Auto or self:RunQLua(self.UnitID)) and (not self.isCP or Action.Player:ComboPoints("target") >= (self.CP or 1))  
        else 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"])          
			getmetatable(self).__index:SetQueue()
        end 
    end 
    return false 
end 

function Action:IsBlockedByQueue()
	-- @return boolean 
	return 	not self.QueueForbidden and 
			#ActionDataQ > 0 and 
			self.Type == ActionDataQ[1].Type and 
			( not ActionDataQ[1].PowerType or self.PowerType == ActionDataQ[1].PowerType ) and 
			( not ActionDataQ[1].PowerCost or UnitPower("player", self.PowerType) < ActionDataQ[1].PowerCost )
end

function Action:IsQueued()
	-- @return boolean 
    return self.Queued
end 

function Action:SetQueue(args) 
	-- Sets queue on action 
	-- Note: /run Action[Action.PlayerSpec].WordofGlory:SetQueue()
	-- QueueAuto: Action:SetQueue({ Silence = true, Priority = 1 }) just sometimes simcraft use it in some place
	--[[@usage: args (table)
	 	Optional: 
			PowerType (number) custom offset 														(passing conditions to func IsQueueReady)
			PowerCost (number) custom offset 														(passing conditions to func IsQueueReady)
			ExtraCD (number) custom offset															(passing conditions to func IsQueueReady)
			Silence (boolean) if true don't display print 
			UnitID (string) specified for spells usually to check their for range on certain unit 	(passing conditions to func QueueValidCheck)
			Value (boolean) sets custom fixed statement for queue
			Priority (number) put in specified priority 
			MetaSlot (number) usage for MSG system to set queue on fixed position 
			Auto (boolean) usage to skip RunQLua 
	]]
	-- Check validance 
	if not self.Queued and not self:IsExists() then  
		Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"]) 
		return 
	end 
	
	local printKey 	= self.Desc .. (self.Color or "") 
		  printKey	= (printKey ~= "" and (" " .. L["TAB"][3]["KEY"] .. printKey .. "]")) or ""
	
	local args = args or {}	
	local Identify = GetTableKeyIdentify(self)
	if self.QueueForbidden or (self.isStance and Action.Player:IsStance(self.isStance)) or ((self.Type == "Trinket" or self.Type == "Item") and not GetItemSpell(self.ID)) then 
		if not args.Silence then 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. printKey)
		end  
		return 
	-- Let for user allow run blocked actions whenever he wants, anyway why not 
	--elseif self:IsBlocked() and not self.Queued then 
		--if not args.Silence then 
			--Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"] .. printKey)
		--end 
        --return 
	end
	
	if args.Value ~= nil and self.Queued == args.Value then 
		if not args.Silence then 
			Action.Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISQUEUEDALREADY"] .. printKey)
		end 
		return 
	end 
	
	if args.Value ~= nil then 
		self.Queued = args.Value 
	else 
		self.Queued = not self.Queued
	end 
	
	local priority = (args.Priority and (args.Auto or not Action.IsQueueRunningAuto()) and (args.Priority > #ActionDataQ + 1 and #ActionDataQ + 1 or args.Priority)) or #ActionDataQ + 1	
    if not args.Silence then		
		if self.Queued then 
			Action.Print(L["TAB"][3]["QUEUED"] .. self:Link() .. L["TAB"][3]["QUEUEPRIORITY"] .. priority .. ". " .. L["TAB"][3]["KEYTOTAL"] .. #ActionDataQ + 1 .. "]")
		else
			Action.Print(L["TAB"][3]["QUEUEREMOVED"] .. self:Link() .. printKey)
		end 
    end 
    
	if not self.Queued then 
		for i = #ActionDataQ, 1, -1 do 
			if GetTableKeyIdentify(ActionDataQ[i]) == Identify then 
				tremove(ActionDataQ, i)
				if #ActionDataQ == 0 then 
					Queue:Reset()
					return 
				end 				
			end 
		end 
		return
	end 
    
	-- Do nothing if it does in spam with always true as insert to queue list 	
	if args.Value and #ActionDataQ > 0 then 
		for i = #ActionDataQ, 1, -1 do
			if GetTableKeyIdentify(ActionDataQ[i]) == Identify then 
				return
			end 
		end 
	end
    tinsert(ActionDataQ, priority, setmetatable({ UnitID = args.UnitID, MetaSlot = args.MetaSlot, Auto = args.Auto, Start = TMW.time }, { __index = self }))

	if args.PowerType then 
		-- Note: we set it as true to use in function Action.IsQueueReady()
		ActionDataQ[priority].PowerType = args.PowerType   	
		ActionDataQ[priority].PowerCustom = true
	end	
	if args.PowerCost then 
		ActionDataQ[priority].PowerCost = args.PowerCost
		ActionDataQ[priority].PowerCustom = true
	end 		 	
	if args.ExtraCD then
		ActionDataQ[priority].ExtraCD = args.ExtraCD 
	end 	
		
    Action.Listener:Add("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED", 		function(...) Queue:UNIT_SPELLCAST_SUCCEEDED(...) 	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN", 			function() 	  Queue:BAG_UPDATE_COOLDOWN() 		  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "ACTIVE_TALENT_GROUP_CHANGED", 	function() 	  Queue:OnEventToReset() 			  	end)	
    Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_SPECIALIZATION_CHANGED", 	function() 	  Queue:OnEventToReset() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED", 			function() 	  Queue:OnEventToReset() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_TALENT_UPDATE", 			function() 	  Queue:OnEventToReset() 			  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED", 		function() 	  Queue:OnEventToResetNoCombat() 	  	end)
	Action.Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD", 			function() 	  Queue:OnEventToReset() 			  	end)
	TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", 							function() 	  Queue:OnEventToReset() 				end,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET")
end

function Action.MacroQueue(key, args)
	-- Sets queue on action with avoid lua errors for non exist key
	local object = GetActionTableByKey(key)
	if not object then 
		Action.Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetQueue(args)
end

-- [4] Interrupts
function Action.InterruptIsON(list)
	-- @return boolean 	
	-- Note: list 	("TargetMouseover", "PvP", "Heal")
	return TMWdb.profile.ActionDB[4][Action.PlayerSpec]["Kick" .. list]
end 

function Action.InterruptIsBlackListed(unitID, spellName)
	-- @return boolean (Kick, CC, Racial)
	local blackListed = TMWdb.profile.ActionDB[4].BlackList[GameLocale][spellName]
	if blackListed and blackListed.Enabled then 
		local luaCode = blackListed.LUA or nil
		if RunLua(luaCode, unitID) then 
			return blackListed.useKick, blackListed.useCC, blackListed.useRacial
		end 
	end 
end 

function Action.InterruptEnabled(list, spellName)
	-- @return boolean 
	-- Note: list ("PvETargetMouseover", "PvPTargetMouseover", "PvP", "Heal")
	return TMWdb.profile.ActionDB[4][list][GameLocale][spellName] and TMWdb.profile.ActionDB[4][list][GameLocale][spellName].Enabled
end 

local function SmartInterrupt()
	-- Note: This function is cached 
	local HealerInCC = not Action.IamHealer and Action.FriendlyTeam("HEALER"):GetCC() or 0
	return (HealerInCC > 0 and HealerInCC < Action.GetGCD() + Action.GetCurrentGCD()) or Action.FriendlyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4 or Action.Unit("player"):HasBuffs("DamageBuffs") > 4 or Action.FriendlyTeam():GetTTD(1, 8) or Action.Unit("target"):IsExecuted() or Action.Unit("player"):IsExecuted() or Action.EnemyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4
end 
local ConcatenationStr = {
	[true] = "PvPTargetMouseover",
	[false] = "PvETargetMouseover",
}

function Action.InterruptIsValid(unitID, list, ignoreToggle)
	-- @return boolean (Kick, CC, Racial)
	-- Note: list 	("TargetMouseover", "PvP", "Heal")
	-- list as "PvETargetMouseover" and "PvPTargetMouseover" must be always "TargetMouseover"
	
	-- ATTENTION
	-- This thing doesn't check random interval and as well distance with imun to kick
	
	if ignoreToggle or Action.InterruptIsON(list) then 	
		local spellName = Action.Unit(unitID):IsCasting()
		if spellName then 
			local bl_useKick, bl_useCC, bl_useRacial = Action.InterruptIsBlackListed(unitID, spellName)
			if list == "TargetMouseover" then 
				list = ConcatenationStr[Action.IsInPvP]
			end 	

			local Interrupt = TMWdb.profile.ActionDB[4][list][GameLocale][spellName]
			local luaCode = Interrupt and Interrupt.LUA or nil
			
			local r_useKick, r_useCC, r_useRacial
			
			if list:match("TargetMouseover") then
				if (not Action.GetToggle(4, "TargetMouseoverList") and (not Action.IsInPvP or (Action.Unit(unitID):IsHealer() and Action.Unit(unitID):TimeToDie() < 6))) or (Action.InterruptEnabled(list, spellName) and RunLua(luaCode, unitID)) then 
					if Interrupt then 
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = Interrupt.useKick
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = Interrupt.useCC
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = Interrupt.useRacial
						end 
						
						return r_useKick, r_useCC, r_useRacial
					else
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = true
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = true
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = true
						end 
						
						return r_useKick, r_useCC, r_useRacial
					end 
				end 
			elseif list == "Heal" then 
				if Action.InterruptEnabled(list, spellName) and (not Action.GetToggle(4, "KickHealOnlyHealers") or Action.Unit(unitID):IsHealer()) and RunLua(luaCode, unitID) then 
					if Interrupt then 
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = Interrupt.useKick
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = Interrupt.useCC
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = Interrupt.useRacial
						end 
						
						return r_useKick, r_useCC, r_useRacial
					else
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = true
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = true
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = true
						end 
						
						return r_useKick, r_useCC, r_useRacial
					end 
				end 
			elseif list == "PvP" then 
				if Action.InterruptEnabled(list, spellName) and (not Action.GetToggle(4, "KickPvPOnlySmart") or SmartInterrupt()) and RunLua(luaCode, unitID) then 
					if Interrupt then 
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = Interrupt.useKick
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = Interrupt.useCC
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = Interrupt.useRacial
						end 
						
						return r_useKick, r_useCC, r_useRacial
					else
						if bl_useKick ~= nil then 
							r_useKick = not bl_useKick
						else
							r_useKick = true
						end 
						
						if bl_useCC ~= nil then 
							r_useCC = not bl_useCC
						else
							r_useCC = true
						end 
						
						if bl_useRacial ~= nil then 
							r_useRacial = not bl_useRacial
						else
							r_useRacial = true
						end 
						
						return r_useKick, r_useCC, r_useRacial
					end 
				end 
			end
		end 
	end 
	return false, false, false
end 

-- [5] Auras
-- Note: Toggles  ("UseDispel", "UsePurge", "UseExpelEnrage")  
--		 Category ("Dispel", "MagicMovement", "PurgeFriendly", "PurgeHigh", "PurgeLow", "Enrage", "BlackList", 
--																												"BlessingofProtection", "BlessingofFreedom", "BlessingofSacrifice", "BlessingofSanctuary")	-- only Paladin ( BlessingofSacrifice is Prot/Holy, BlessingofSanctuary	is Retribution )
function Action.AuraIsON(Toggle)
	-- @return boolean 
	return (type(Toggle) == "boolean" and Toggle == true) or TMWdb.profile.ActionDB[5][Action.PlayerSpec][Toggle]
end 

function Action.AuraGetCategory(Category)
	-- @return table or nil (if not found category in certain Mode), string or (Filter)
	--[[ table basic structure:
		[Name] = { ID, Name, Enabled, Role, Dur, Stack, byID, canStealOrPurge, onlyBear, LUA }
		-- Look DispelPurgeEnrageRemap about table create 
	]]
	local Mode = Action.IsInPvP and "PvP" or "PvE"
	local Filter = "HARMFUL"
	if Category:match("Purge") or Category:match("Enrage") then 
		Filter = "HELPFUL"
	elseif Category:match("BlackList") then 
		Filter = Filter .. " HELPFUL"
	end 
	
	if TMWdb.profile.ActionDB[5][Action.PlayerSpec][Mode] and TMWdb.profile.ActionDB[5][Action.PlayerSpec][Mode][Category] then 
		return TMWdb.profile.ActionDB[5][Action.PlayerSpec][Mode][Category][GameLocale], Filter
	end 
	
	if ActionDataAuras[Mode] then 
		return ActionDataAuras[Mode][Category], Filter
	end 
	
	return nil, Filter	
end

function Action.AuraIsBlackListed(unitID)
	-- @return boolean 
	local Aura, Filter = Action.AuraGetCategory("BlackList")
	if Aura and next(Aura) then 
		local _, Name, count, duration, expirationTime, canStealOrPurge, id
		for i = 1, huge do 
			Name, _, count, _, duration, expirationTime, _, canStealOrPurge, _, id = UnitAura(unitID, i, Filter)
			if Name then
				if Aura[Name] and Aura[Name].Enabled and (Aura[Name].Role == "ANY" or (Aura[Name].Role == "HEALER" and Action.IamHealer) or (Aura[Name].Role == "DAMAGER" and not Action.IamHealer)) and (not Aura[Name].byID or id == Aura[Name].ID) then 
					local Dur = expirationTime == 0 and huge or expirationTime - TMW.time
					if Dur > Aura[Name].Dur and (Aura[Name].Stack == 0 or count >= Aura[Name].Stack) and (not Aura[Name].canStealOrPurge or canStealOrPurge == true) and (not Aura[Name].onlyBear or Action.Unit(unitID):HasBuffs(5487) > 0) and RunLua(Aura[Name].LUA, unitID) then
						return true
					end 
				end 
			else
				break 
			end 
		end 
	end 
	return false 
end 

function Action.AuraIsValid(unitID, Toggle, Category)
	-- @return boolean 
	if Category ~= "BlackList" and Action.AuraIsON(Toggle) then 
		local Aura, Filter = Action.AuraGetCategory(Category)
		if Aura and not Action.AuraIsBlackListed(unitID) then 
			local _, Name, count, duration, expirationTime, canStealOrPurge, id
			for i = 1, huge do			
				Name, _, count, _, duration, expirationTime, _, canStealOrPurge, _, id = UnitAura(unitID, i, Filter)
				if Name then					
					if Aura[Name] and Aura[Name].Enabled and (Aura[Name].Role == "ANY" or (Aura[Name].Role == "HEALER" and Action.IamHealer) or (Aura[Name].Role == "DAMAGER" and not Action.IamHealer)) and (not Aura[Name].byID or id == Aura[Name].ID) then 					
						local Dur = expirationTime == 0 and huge or expirationTime - TMW.time
						if Dur > Aura[Name].Dur and (Aura[Name].Stack == 0 or count >= Aura[Name].Stack) and (not Aura[Name].canStealOrPurge or canStealOrPurge == true) and (not Aura[Name].onlyBear or Action.Unit(unitID):HasBuffs(5487) > 0) and RunLua(Aura[Name].LUA, unitID) then
							return true
						end 
					end 
				else
					break 
				end 
			end 
		end
	end 
	return false 
end

-- [6] Cursor 
function Action.CursorInit()
	if not Action.IsGameTooltipInitializated then
		local function OnEvent(self)
			if Action.IsInitialized and Action[Action.PlayerSpec] then 
				local UseLeft = Action.GetToggle(6, "UseLeft")
				local UseRight = Action.GetToggle(6, "UseRight")
				if UseLeft or UseRight then 
					local M = Action.IsInPvP and "PvP" or "PvE"
					local ObjectName = UnitName("mouseover")
					if ObjectName then 		
						-- UnitName 
						ObjectName = ObjectName:lower()
						local UnitNameKey = TMWdb.profile.ActionDB[6][Action.PlayerSpec][M]["UnitName"][GameLocale][ObjectName]
						if UnitNameKey and UnitNameKey.Enabled and ((UnitNameKey.Button == "LEFT" and UseLeft) or (UnitNameKey.Button == "RIGHT" and UseRight)) and (not UnitNameKey.isTotem or Action.Unit("mouseover"):IsTotem() and not Action.Unit("target"):IsTotem()) and RunLua(UnitNameKey.LUA, "mouseover") then 
							Action.GameTooltipClick = UnitNameKey.Button
							return
						end 
					elseif self:IsShown() and self:GetEffectiveAlpha() >= 1 then 			
						-- GameTooltip 
						local focus = GetMouseFocus() 
						if focus and not focus:IsForbidden() and focus:GetName() == "WorldFrame" then
							local GameTooltipTable = TMWdb.profile.ActionDB[6][Action.PlayerSpec][M]["GameToolTip"][GameLocale]
							if next(GameTooltipTable) then 						
								local Regions = { self:GetRegions() }
								for i = 1, #Regions do 					
									local region = Regions[i]							
									if region and region:GetObjectType() == "FontString" then 
										local text = region:GetText() 								
										if text then 
											text = text:lower()
											local GameTooltipKey = GameTooltipTable[text]
											if GameTooltipKey and GameTooltipKey.Enabled and ((GameTooltipKey.Button == "LEFT" and UseLeft) or (GameTooltipKey.Button == "RIGHT" and UseRight)) and (not GameTooltipKey.isTotem or Action.Unit("mouseover"):IsTotem() and not Action.Unit("target"):IsTotem()) and RunLua(GameTooltipKey.LUA, "mouseover") then 								
												Action.GameTooltipClick = GameTooltipKey.Button
												return 									
											end 
										end 
									end 
								end 
							end 
						end 
					end
				end 
				Action.GameTooltipClick = nil 	
			end 				
		end
		
		-- PRE
		GameTooltip:HookScript("OnShow", OnEvent)
		-- POST
		GameTooltip:RegisterEvent("CURSOR_UPDATE")
		GameTooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		GameTooltip:HookScript("OnEvent", function(self, event) 
			if Action.GameTooltipClick and (event == "CURSOR_UPDATE" or (event == "UPDATE_MOUSEOVER_UNIT" and not UnitExists("mouseover"))) and self:IsShown() and self:GetEffectiveAlpha() >= 1 then  			
				Action.GameTooltipClick = nil	
				self:Hide()
			end 
		end)		
		GameTooltip:HookScript("OnTooltipCleared", function(self)
			if self:IsShown() then 
				OnEvent(self)
			else 
				Action.GameTooltipClick = nil 
			end 
		end)		
		
		Action.IsGameTooltipInitializated = true 
	end 
end 

-- [7] MSG System (Message)
--[[
local CompareUnitIDwithUnitName(unitID, unitName)
	local name, server = UnitName(unitID)
	if unitID == "player" then 
		server = GetRealmName():gsub(" ", "")
	end 
	local fullname = name .. "-" .. server 
	return fullname == unitName
end 
]]

local MSG = {
	units = { "raid%d+", "party%d+", "arena%d+", "player", "target", "focus" },
	group = { 
		{ u = "player", meta = 3 	}, 
		{ u = "raid1", 	meta = 6 	}, 
		{ u = "raid2", 	meta = 7	}, 
		{ u = "raid3", 	meta = 8	}, 
		{ u = "party1", meta = 7 	}, 
		{ u = "party2", meta = 8	}, 
		--{ u = "party3", meta = 8	},
	}, -- Retail has index started from 7 to 8 which provide to support party1-2 (party3 is only Classic)
	arena = {
		{ u = "arena1", meta = 6 	}, 
		{ u = "arena2", meta = 7	}, 
		{ u = "arena3", meta = 8	}, 	
	},
	set = {},
}	
local function UpdateChat(...)
	if not Action.IsInitialized then 
		return 
	end 
	
	local msgList = Action.GetToggle(7, "msgList")
	if not msgList or next(msgList) == nil then 
		return 
	end 
	
	local msg, sname  = ... 
	msg = msg:lower()
	for Name, v in pairs(msgList) do 
		if v.Enabled and msg:match(Name) and (not v.Source or v.Source == sname) then 
			local Obj = Action[Action.PlayerSpec][v.Key] 
			if Obj and (not Action.GetToggle(7, "DisableReToggle") or not Obj:IsQueued()) then  							
				wipe(MSG.set)
				local unit
				
				for j = 1, #MSG.units do 
					unit = msg:match(MSG.units[j])
					if unit then 
						break
					end 
				end 
					
				--[[
				if not v.Source then 
					for j = 1, #MSG.units do 
						unit = msg:match(MSG.units[j])
						if unit then 
							break
						end 
					end 
				else 
					if CompareUnitIDwithUnitName("player", sname) then 
						unit = "player"
					elseif CompareUnitIDwithUnitName("target", sname) then
						unit = "target"
					else 
						for j = 1, Action.TeamCache.Friendly.Size do 
							local cUnit = Action.TeamCache.Friendly.Type .. j 
							if CompareUnitIDwithUnitName(cUnit, sname) then
								unit = cUnit
								break 
							end 
						end 
						
						if not unit then 
							for j = 1, Action.TeamCache.Enemy.Size do 
								local cUnit = Action.TeamCache.Enemy.Type .. j 
								if CompareUnitIDwithUnitName(cUnit, sname) then
									unit = cUnit
									break 
								end 
							end 					
						end 
					end 
				end
				]]			
				
				if unit then 
					if RunLua(v.LUA, unit) then 
						-- Note: Regarding "player" unit here is a lot of profiles which don't support slot 6 and mostly 6 slot is valid for healer which has different @target always [Affected Retail only]
						-- Since damager / tank always has @target an enemy then "player" will be applied even if spell will be launched in slot 3-4 
						if unit:match("raid") or unit:match("party") then 		
							if MSG.group[unit] then 
								MSG.set.Unit = unit
								MSG.set.MetaSlot = MSG.group[unit].meta 							
								Action.MacroQueue(v.Key, MSG.set)
							else 
								for j = 1, #MSG.group do 
									if UnitIsUnit(unit, MSG.group[j].u) then 	
										if MSG.group[j].u == "player" then 
											MSG.set.MetaSlot = Action.IamHealer and 6 or nil -- Update it if spec (retail) has been changed
										else 
											MSG.set.MetaSlot = MSG.group[j].meta											
										end 
										MSG.set.Unit = MSG.group[j].u
										Action.MacroQueue(v.Key, MSG.set)							
										break 
									end 
								end 			
							end 
						elseif unit:match("arena") then
							if MSG.arena[unit] then 
								MSG.set.Unit = unit
								MSG.set.MetaSlot = MSG.arena[unit].meta 							
								Action.MacroQueue(v.Key, MSG.set)
							end 
						elseif unit == "player" then 
							MSG.set.Unit = "player"
							Action.MacroQueue(v.Key, MSG.set) 
						else 
							MSG.set.Unit = unit 
							Action.MacroQueue(v.Key, MSG.set)
						end 
					end 
				else
					if v.LUA ~= nil and v.LUA ~= "" and Obj:HasRange() then 
						unit = ((Obj:IsHarmful() or (Obj:IsHelpful() and (Obj.Type == "Spell" or Action.IamHealer))) and "target") or (Obj.Type ~= "Spell" and ((not Action.IamHealer and "player") or "target")) or "player"
					end 
				
					if RunLua(v.LUA, unit or "target") then
						MSG.set.Unit = unit -- or "target"
						Action.MacroQueue(v.Key, MSG.set)
					end 
				end	
			end 
		end        
    end 
end 

function Action.ToggleMSG(isLaunch)
	if not isLaunch and Action.IsInitialized then 
		Action.SetToggle({7, "MSG_Toggle", L["TAB"][7]["MSG"] .. " : "})
	end
	
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
	Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")	
	
	if Action.GetToggle(7, "MSG_Toggle") then 
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY", 			UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER", 	UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID", 			UpdateChat)
		Action.Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER", 	UpdateChat)
	end 	
	
	if Action.MainUI and Action.Data.ProfileUI and Action.Data.ProfileUI[7] and Action.Data.ProfileUI[7][Action.PlayerSpec] and next(Action.Data.ProfileUI[7][Action.PlayerSpec]) then 
		local spec = Action.PlayerSpec .. CL
		local tab = tabFrame.tabs[7]
		if tab and tab.childs[spec] then 
			local anchor = GetAnchor(tab, spec)
			local kids = GetKids(tab, spec)
			for _, child in ipairs(kids) do 				
				if child.Identify and child.Identify.Toggle == "DisableReToggle" then 
					if Action.GetToggle(7, "MSG_Toggle") then 
						child:Enable()
					else 
						child:Disable()
					end 
					break 
				end 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- UI: Toggles
-------------------------------------------------------------------------------
function Action.SetToggle(arg, custom)
	-- @usage: Action.SetToggle({ tab.name (@number), key (@string ActionDB), text (@string optional for Print), silence (@boolean optional for Print) }, custom (@any value to set - optional))
	if not TMWdb.profile.ActionDB then 
		Action.Print(TMWdb:GetCurrentProfile() .. "  " .. L["NOSUPPORT"])
		return
	end 
	
	local bool 
	local n, toggle, text, silence = arg[1], arg[2], arg[3], arg[4]
	if TMWdb.global.ActionDB[toggle] ~= nil then 
		if custom ~= nil then 
			TMWdb.global.ActionDB[toggle] = custom
		else 
			TMWdb.global.ActionDB[toggle] = not TMWdb.global.ActionDB[toggle]
		end 
		
		bool = TMWdb.global.ActionDB[toggle] 		
	elseif Factory[n] and Factory[n][toggle] ~= nil then 
		if custom ~= nil then 
			TMWdb.profile.ActionDB[n][toggle] = custom 
		else 
			TMWdb.profile.ActionDB[n][toggle] = not TMWdb.profile.ActionDB[n][toggle]	
		end 
		
		bool = TMWdb.profile.ActionDB[n][toggle] 
	elseif TMWdb.profile.ActionDB[n] == nil or TMWdb.profile.ActionDB[n][Action.PlayerSpec] == nil or TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle] == nil then
		if not silence then 
			Action.Print(L["DEBUG"] .. (n or "") .. " " .. (toggle or "") .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle")
		end
		return 
	else 
		if custom ~= nil then 
			if type(custom) == "table" then 
				for k, v in pairs(custom) do
					if TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] ~= nil and type(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k]) == type(v) then 
						TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = v
						
						if not silence and text then 
							Action.Print(text .. " " .. k .. ": ", TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k])
						end 
					else
						if not silence then 
							Action.Print(L["DEBUG"] .. (n or "") .. " " .. (toggle or "") .. " " .. (k or "") .. " = " .. tostring(v) .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle")
						end
					end 
				end 
			else 
				TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle] = custom 	
			end 
		elseif type(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]) == "table" then 
			-- Usually only for Dropdown in multi. Logic is simply:
			-- 1 Create (or refresh) cache of all instances in DB if any is ON (true or with value), then turn all OFF if anything was ON. 
			-- 2 Or if all OFF then:
			-- 2.1 If no cache (means all was OFF) then make ON all (next time it will repeat 1 step to create cache)
			-- 2.2 If cache exist then turn ON from cache 
			-- /run TMWdb.profile.ActionDB[1][Action.PlayerSpec].Trinkets.Cache = nil		
			local anyIsON = false
			for k, v in pairs(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]) do 
				if TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] and k ~= "Cache" and not anyIsON then 
					TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle].Cache = {}								
					for k1, v1 in pairs(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]) do 
						if k1 ~= "Cache" then 
							TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle].Cache[k1] = v1
						end
					end										
					anyIsON = true 
					break 
				end 
			end 
			
			if anyIsON then 
				for k, v in pairs(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]) do
					if TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] and k ~= "Cache" then 
						--if custom ~= nil then	
							--TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = custom 
						--else 
							TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = not v
						--end 
						
						if not silence and text then 
							Action.Print(text .. " " .. k .. ": ", TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k])
						end 
					end 
				end 
			elseif TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle].Cache then 			
				for k, v in pairs(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle].Cache) do	
					if k ~= "Cache" then 
						TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = v	
						if not silence and text then 
							Action.Print(text .. " " .. k .. ": ", TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k])
						end
					end
				end 
			else 
				for k, v in pairs(TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]) do
					if k ~= "Cache" then 
						--if custom ~= nil then 
							--TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = custom 
						--else 
							TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k] = not v
						--end 
						
						if not silence and text then 
							Action.Print(text .. " " .. k .. ": ", TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle][k])
						end		
					end
				end 				
			end 
		else 
			TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle] = not TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]			 			
		end
		bool = TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle] 
	end 
	
	if toggle == "HE_Toggle" or toggle == "HE_Pets" then 
		GlobalsRemap()
	end 
	
	if toggle == "ReFocus" or toggle == "ReTarget" then 
		Re:Initialize()
	end 
	
	if toggle == "LOSCheck" then 
		LineOfSight:Initialize()
	end 
	
	if text and type(bool) ~= "table" then 
		local boolprint = bool
		if type(bool) == "number" and bool < 0 then 			
			if toggle ~= "FPS" then 
				boolprint = "|cffff0000OFF|r"
			else 
				boolprint = "|cff00ff00AUTO|r"
			end 
		end 
		if toggle == "HE_Toggle" then 
			boolprint = L["TAB"][1][bool]
		end 
		
		if not silence then
			Action.Print(text, boolprint)
		end 
	end

	-- Fires callback for AoE to display DogTag
	if n == 1 and toggle == "Burst" then 
		TMW:Fire("TMW_ACTION_BURST_CHANGED")
		TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 
	elseif n == 2 and strlowerCache[toggle] == "aoe" then 
		TMW:Fire("TMW_ACTION_AOE_CHANGED")
		TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED") -- Taste's callback 
	end 		
	
	if Action.MainUI then 		
		local spec = Action.PlayerSpec .. CL
		local tab = tabFrame.tabs[n]
		if tab and tab.childs[spec] then 
			local anchor = GetAnchor(tab, spec)
			local kids = GetKids(tab, spec)
			for _, child in ipairs(kids) do 				
				if child.Identify and child.Identify.Toggle == toggle then 
					-- SetValue not uses here because it will trigger OnValueChanged which we don't need in case of performance optimization
					if child.Identify.Type == "Checkbox" then
						if n == 4 then 
							-- Exception to trigger OnValueChanged callback 
							child:SetChecked(bool)
						else 
							child.isChecked = bool 
							if child.isChecked then
								child.checkedTexture:Show()
							else 
								child.checkedTexture:Hide()
							end							
						end
					elseif child.Identify.Type == "Dropdown" then						
						if child.multi then 
							local SetVal = {}
							for i = 1, #child.optsFrame.scrollChild.items do 													
								child.optsFrame.scrollChild.items[i].isChecked = TMWdb.profile.ActionDB[tab.name][Action.PlayerSpec][toggle][i]								
								if child.optsFrame.scrollChild.items[i].isChecked then 
									child.optsFrame.scrollChild.items[i].checkedTexture:Show()
									tinsert(SetVal, child.optsFrame.scrollChild.items[i].value)
								else 
									child.optsFrame.scrollChild.items[i].checkedTexture:Hide()										
								end 
							end 							
							child.value = SetVal
							child:SetText(child:FindValueText(SetVal))
						else 
							child.value = bool
							if toggle == "HE_Toggle" then 
								child:SetText(L["TAB"][1][bool])
							else 
								child:SetText(child:FindValueText(bool))
							end
						end 
					elseif child.Identify.Type == "Slider" then							
						child:SetValue(bool) 
					end 
					return  
				end
			end 	
		end		
	end 		 	
end 	

function Action.GetToggle(n, toggle)
	-- @usage: Action.GetToggle(tab.name (@number), key (@string ActionDB))
	if not ActionHasRunningDB then 		
		if toggle == "FPS" then
			return 0.05 -- TMWdb.global.Interval
		end 
		if toggle == "DisableMinimap" or toggle == "DisableRotationDisplay" or toggle == "DisableClassPortraits" then 
			return true
		end 
		if toggle == "CheckSpellLevel" then 
			return 
		end 
		Action.Print(TMWdb:GetCurrentProfile() .. " - Toggle: [" .. (n or "") .. "] " .. toggle .. " " .. (L and L["NOSUPPORT"] or ""), nil, true)
		return
	end 
	
	local bool 
	if TMWdb.global.ActionDB[toggle] ~= nil then 	
		bool = TMWdb.global.ActionDB[toggle] 		
	elseif Factory[n] and Factory[n][toggle] ~= nil then 	
		bool = TMWdb.profile.ActionDB[n][toggle] 
	elseif TMWdb.profile.ActionDB[n] and TMWdb.profile.ActionDB[n][Action.PlayerSpec] then 
		if toggle == "HeartOfAzeroth" then 
			bool = AzeriteEssence and TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle]
		else 
			bool = TMWdb.profile.ActionDB[n][Action.PlayerSpec][toggle] 
		end 
	end 
	
	return bool	
end 	

function Action.ToggleMinimap(state)
	if Action.Minimap then 
		if type(state) == "nil" then 
			if Action.IsInitialized then 
				Action.SetToggle({1, "DisableMinimap", L["TAB"][1]["DISABLEMINIMAP"] .. " : "})
			end
			if Action.GetToggle(1, "DisableMinimap") then 
				LibDBIcon:Hide("ActionUI")
			else 
				LibDBIcon:Show("ActionUI")
			end 
		else
			if state then 
				LibDBIcon:Show("ActionUI")
			else 
				LibDBIcon:Hide("ActionUI")
			end 
		end 
	end 
end 

function Action.MinimapIsShown()
	-- @return boolean 
	return LibDBIcon.objects["ActionUI"] and LibDBIcon.objects["ActionUI"]:IsShown()
end 

function Action.ToggleMainUI()
	if not Action.PlayerSpec or (not Action.MainUI and not Action.IsInitialized) then 
		return 
	end 
	local specID, specName = Action.PlayerSpec, Action.PlayerSpecName 
	local spec = specID .. CL
	if Action.MainUI then 	
		if Action.MainUI:IsShown() then 
			Action.MainUI:SetShown(not Action.MainUI:IsShown())
			return
		else 
			Action.MainUI:SetShown(not Action.MainUI:IsShown())	
			Action.MainUI.PDateTime:SetText(TMWdb:GetCurrentProfile() .. "\n" .. (Action.Data.ProfileUI.DateTime or ""))			
		end 
	else 
		Action.MainUI = StdUi:Window(UIParent, 540, 640, "The Action")
		Action.MainUI.titlePanel.label:SetFontSize(20)
		Action.MainUI.default_w = Action.MainUI:GetWidth()
		Action.MainUI.default_h = Action.MainUI:GetHeight()
		Action.MainUI.titlePanel:SetPoint("TOP", 0, -20)
		Action.MainUI:SetFrameStrata("HIGH")
		Action.MainUI:SetPoint("CENTER")
		Action.MainUI:SetShown(true) 
		Action.MainUI:RegisterEvent("BARBER_SHOP_OPEN")
		Action.MainUI:RegisterEvent("BARBER_SHOP_CLOSE")		
		Action.MainUI:SetScript("OnEvent", function(self, event, ...)
			if (event == "BARBER_SHOP_OPEN" or event == "BARBER_SHOP_CLOSE") and Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
				
		Action.MainUI:EnableKeyboard(true)
		Action.MainUI:SetPropagateKeyboardInput(true)
		--- Catches the game menu bind just before it fires.
		Action.MainUI:SetScript("OnKeyDown", function (self, Key)				
				if GetBindingFromClick(Key) == "TOGGLEGAMEMENU" and Action.MainUI:IsShown() then 
					Action.ToggleMainUI()
				end 
		end)
		--- Disallows closing the dialogs once the game menu bind is processed.
		hooksecurefunc("ToggleGameMenu", function()			
			if Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)	
		--- Catches shown (aka clicks) on default "?" GameMenu 
		Action.MainUI.GameMenuFrame = CreateFrame("Frame", nil, _G["GameMenuFrame"])
		Action.MainUI.GameMenuFrame:SetScript("OnShow", function()
			if Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
		
		Action.MainUI.PDateTime = StdUi:Subtitle(Action.MainUI, TMWdb:GetCurrentProfile() .. "\n" .. (Action.Data.ProfileUI.DateTime or ""))
		Action.MainUI.PDateTime:SetJustifyH("RIGHT")
		Action.MainUI.GDateTime = StdUi:Subtitle(Action.MainUI, L["GLOBALAPI"] .. DateTime)	
		Action.MainUI.GDateTime:SetJustifyH("RIGHT")
		StdUi:GlueBefore(Action.MainUI.PDateTime, Action.MainUI.closeBtn, -5, 0)
		StdUi:GlueBelow(Action.MainUI.GDateTime, Action.MainUI.PDateTime, 0, 0, "RIGHT")
		
		Action.MainUI.AllReset = StdUi:Button(Action.MainUI, 100, 35, L["TAB"]["RESETBUTTON"])
		StdUi:ButtonAutoWidth(Action.MainUI.AllReset)
		StdUi:GlueTop(Action.MainUI.AllReset, Action.MainUI, 10, -10, "LEFT")
		Action.MainUI.AllReset:SetScript('OnClick', function()
			Action.MainUI.ResetQuestion:SetShown(not Action.MainUI.ResetQuestion:IsShown())
		end)
		
		Action.MainUI.ResetQuestion = StdUi:Window(Action.MainUI, 350, 250, L["TAB"]["RESETQUESTION"])
		Action.MainUI.ResetQuestion:SetPoint("CENTER")
		Action.MainUI.ResetQuestion:SetFrameStrata("TOOLTIP")
		Action.MainUI.ResetQuestion:SetFrameLevel(50)
		Action.MainUI.ResetQuestion:SetBackdropColor(0, 0, 0, 1)
		Action.MainUI.ResetQuestion:SetMovable(false)
		Action.MainUI.ResetQuestion:SetShown(false)
		Action.MainUI.ResetQuestion:SetScript("OnDragStart", nil)
		Action.MainUI.ResetQuestion:SetScript("OnDragStop", nil)
		Action.MainUI.ResetQuestion:SetScript("OnReceiveDrag", nil)
		
		Action.MainUI.CheckboxSaveActions = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEACTIONS"], 250)
		Action.MainUI.CheckboxSaveInterrupt = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEINTERRUPT"], 250)			
		Action.MainUI.CheckboxSaveDispel = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEDISPEL"], 250)
		Action.MainUI.CheckboxSaveMouse	= StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEMOUSE"], 250)	
		Action.MainUI.CheckboxSaveMSG = StdUi:Checkbox(Action.MainUI.ResetQuestion, L["TAB"]["SAVEMSG"], 250)
		
		Action.MainUI.Yes = StdUi:Button(Action.MainUI.ResetQuestion, 150, 35, L["YES"])		
		StdUi:GlueBottom(Action.MainUI.Yes, Action.MainUI.ResetQuestion, 20, 20, "LEFT")
		Action.MainUI.Yes:SetScript("OnClick", function()
			local ProfileSave, GlobalSave = {}, {}
			if Action.MainUI.CheckboxSaveActions:GetChecked() then 
				ProfileSave[3] = {}
				for k, v in pairs(TMWdb.profile.ActionDB[3]) do 
					if type(k) == "number" then
						ProfileSave[3][k] = v					
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveInterrupt:GetChecked() then 
				ProfileSave[4] = {}
				for k, v in pairs(TMWdb.profile.ActionDB[4]) do 
					if type(k) ~= "number" then 
						ProfileSave[4][k] = v
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveDispel:GetChecked() then 
				GlobalSave[5] = {}
				for k, v in pairs(TMWdb.global.ActionDB[5]) do					
					GlobalSave[5][k] = v					
				end
			end 
			if Action.MainUI.CheckboxSaveMouse:GetChecked() then 	
				ProfileSave[6] = {}
				for k, v in pairs(TMWdb.profile.ActionDB[6]) do
					if type(k) == "number" then 
						ProfileSave[6][k] = v
					end 
				end
			end 
			if Action.MainUI.CheckboxSaveMSG:GetChecked() then 	
				ProfileSave[7] = {}
				for k, v in pairs(TMWdb.profile.ActionDB[7]) do
					if type(k) == "number" then 	
						if not ProfileSave[7][k] then 
							ProfileSave[7][k] = {}
						end 
						ProfileSave[7][k].msgList = v.msgList						
					end 
				end
			end 
			wipe(TMWdb.global.ActionDB)
			wipe(TMWdb.profile.ActionDB)
			if next(ProfileSave) or #ProfileSave > 0 then 
				TMWdb.profile.ActionDB = ProfileSave				
			end 
			if next(GlobalSave) or #GlobalSave > 0 then 
				TMWdb.global.ActionDB = GlobalSave
			end
			C_UI.Reload()	
		end)
		
		Action.MainUI.No = StdUi:Button(Action.MainUI.ResetQuestion, 150, 35, L["NO"])
		StdUi:GlueBottom(Action.MainUI.No, Action.MainUI.ResetQuestion, -20, 20, "RIGHT")
		Action.MainUI.No:SetScript("OnClick", function()
			Action.MainUI.ResetQuestion:Hide()
		end)			

		StdUi:GlueBottom(Action.MainUI.CheckboxSaveActions, Action.MainUI.ResetQuestion, 20, 30 + Action.MainUI.Yes:GetHeight(), "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveInterrupt, Action.MainUI.CheckboxSaveActions, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveDispel, Action.MainUI.CheckboxSaveInterrupt, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveMouse, Action.MainUI.CheckboxSaveDispel, 0, 10, "LEFT")
		StdUi:GlueAbove(Action.MainUI.CheckboxSaveMSG, Action.MainUI.CheckboxSaveMouse, 0, 10, "LEFT")
		
		tabFrame = StdUi:TabPanel(Action.MainUI, nil, nil, {
			{
				name = 1,
				title = L["TAB"][1]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 2,
				title = spec,
				childs = {},
			},
			{
				name = 3,
				title = L["TAB"][3]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 4,
				title = L["TAB"][4]["HEADBUTTON"],	
				childs = {},		
			},
			{
				name = 5,
				title = L["TAB"][5]["HEADBUTTON"],		
				childs = {},
			},
			{
				name = 6,
				title = L["TAB"][6]["HEADBUTTON"],		
				childs = {},
			},			
			{
				name = 7,
				title = "MSG",	
				childs = {},
			},
		})
		StdUi:GlueAcross(tabFrame, Action.MainUI, 10, -50, -10, 10)
		tabFrame.container:SetPoint('TOPLEFT', tabFrame.buttonContainer, 'BOTTOMLEFT', 0, 0)
		tabFrame.container:SetPoint('TOPRIGHT', tabFrame.buttonContainer, 'BOTTOMRIGHT', 0, 0)	
		
		-- Create resizer		
		Action.MainUI.resizer = CreateResizer(Action.MainUI)
		if Action.MainUI.resizer then 			
			function Action.MainUI.UpdateResize() 
				tabFrame:EnumerateTabs(function(tab)
					for spec in pairs(tab.childs) do						
						local specCL = strgsub(spec, "%d", "")
						if tab.childs[spec] and specCL == CL then									
							-- Easy Layout (main)
							local anchor = GetAnchor(tab, spec)							
							if anchor.layout then 
								anchor:DoLayout()
							end	
						
							local kids = GetKids(tab, spec)
							for _, child in ipairs(kids) do								
								-- EasyLayout (additional)
								if child.layout then 
									child:DoLayout()
								end 	
								-- Dropdown 
								if child.dropTex then 
									-- EasyLayout will resize button so we can don't care
									-- Resize scroll "panel" (container) 
									child.optsFrame:SetWidth(child:GetWidth())
									-- Resize scroll "lines" (list grid)
									for i = 1, #child.optsFrame.scrollChild.items do 
										child.optsFrame.scrollChild.items[i]:SetWidth(child:GetWidth())									
									end 									
								end 
								-- ScrollTable
								if child.data and child.columns then 
									for i = 1, #child.columns do 										
										if child.columns[i].index == "Name" then
											-- Column by Name resize
											child.columns[i].width = round(child.columns[i].defaultwidth + (Action.MainUI:GetWidth() - Action.MainUI.default_w), 0)
											child:SetColumns(child.columns)	
											-- Row resize
											child.numberOfRows = child.defaultrows.numberOfRows + round((Action.MainUI:GetHeight() - Action.MainUI.default_h) / child.defaultrows.rowHeight, 0)
											child:SetDisplayRows(child.numberOfRows, child.defaultrows.rowHeight)
											break 
										end 
									end
									break
								end 
							end 						
						end 						
					end 
				end)
			end 
			Action.MainUI:HookScript("OnSizeChanged", Action.MainUI.UpdateResize)
			-- I don't know how to fix layout overleap problem caused by resizer after hide, so I did some trick through this:
			-- If you have a better idea let me know 
			Action.MainUI:HookScript("OnHide", function(self) 
				Action.MainUI.RememberTab = tabFrame.selected 
				tabFrame:SelectTab(tabFrame.tabs[1].name)		
				Action.MainUI.UpdateResize()
			end)
			Action.MainUI:HookScript("OnShow", function(self)
				if Action.MainUI.RememberTab then 
					tabFrame:SelectTab(tabFrame.tabs[Action.MainUI.RememberTab].name)
				end 				
				Action.MainUI.UpdateResize()
				TMW:TT(self.resizer.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
			end)
		end 
	end 
	
	if not Action.GetToggle(1, "DisableSounds") then 
		PlaySound(5977)
	end 
	
	tabFrame:EnumerateTabs(function(tab)
		for k in pairs(tab.childs) do
			if k ~= spec then 
				tab.childs[k]:Hide()
			end 
		end		
		if tab.childs[spec] then 
			tab.childs[spec]:Show()			
			return
		end  
		if tab.name == 1 or tab.name == 2 then 
			tab.childs[spec] = StdUi:ScrollFrame(tab.frame, tab.frame:GetWidth(), tab.frame:GetHeight()) 			
			tab.childs[spec]:SetAllPoints()
			tab.childs[spec]:Show()			
		else 
			tab.childs[spec] = StdUi:Frame(tab.frame) 
			tab.childs[spec]:SetAllPoints()		
			tab.childs[spec]:Show()
		end
		
		local anchor = GetAnchor(tab, spec)
		
		local UI_Title = StdUi:Subtitle(anchor, tab.title)
		UI_Title:SetFont(UI_Title:GetFont(), 15)
        StdUi:GlueTop(UI_Title, anchor, 0, -10)
		if not StdUi.config.font.color.yellow then 
			local colored = { UI_Title:GetTextColor() }
			StdUi.config.font.color.yellow = { r = colored[1], g = colored[2], b = colored[3], a = colored[4] }
		end 
		
		local UI_Separator = StdUi:Subtitle(anchor, '')
        StdUi:GlueBelow(UI_Separator, UI_Title, 0, -5)
		
		-- We should leave "OnShow" handlers because user can swap language, otherwise in performance case better remove it 		
		if tab.name == 1 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget
			StdUi:InitWidget(anchor)
			
			StdUi:EasyLayout(anchor, { padding = { top = 40, right = 10 + 20 } }) -- { padding = { top = 40 } })	
			
			local PvEPvPToggle = StdUi:Button(anchor, GetWidthByColumn(anchor, 5.5), ActionDatatheme.dd.height, L["TOGGLEIT"])
			PvEPvPToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			PvEPvPToggle:SetScript('OnClick', function(self, button, down)
				if button == "LeftButton" then 
					Action.ToggleMode()
				elseif button == "RightButton" then 
					CraftMacro("PvEPvPToggle", [[/run Action.ToggleMode()]])	
				end 
			end)
			StdUi:FrameTooltip(PvEPvPToggle, L["TAB"][tab.name]["PVEPVPTOGGLETOOLTIP"], nil, "TOPRIGHT", true)
			PvEPvPToggle.FontStringTitle = StdUi:Subtitle(PvEPvPToggle, L["TAB"][tab.name]["PVEPVPTOGGLE"])
			StdUi:GlueAbove(PvEPvPToggle.FontStringTitle, PvEPvPToggle)					
			
			local PvEPvPresetbutton = StdUi:SquareButton(anchor, PvEPvPToggle:GetHeight(), PvEPvPToggle:GetHeight(), "DELETE")
			PvEPvPresetbutton:SetScript('OnClick', function()
				Action.IsLockedMode = false
				Action.IsInPvP = Action:CheckInPvP()	
				Action.Print(L["RESETED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
				TMW:Fire("TMW_ACTION_MODE_CHANGED")
			end)
			StdUi:FrameTooltip(PvEPvPresetbutton, L["TAB"][tab.name]["PVEPVPRESETTOOLTIP"], nil, "TOPRIGHT", true)	
			StdUi:GlueAfter(PvEPvPresetbutton, PvEPvPToggle, 0, 0)

			local InterfaceLanguages = {
				{ text = "Auto", value = "Auto" },	
			}
			for Language in pairs(Localization) do 
				tinsert(InterfaceLanguages, { text = Language, value = Language })
			end 
			anchor.InterfaceLanguage = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, InterfaceLanguages)         
			anchor.InterfaceLanguage:SetValue(TMWdb.global.ActionDB.InterfaceLanguage)
			anchor.InterfaceLanguage.OnValueChanged = function(self, val)                				
				TMWdb.global.ActionDB.InterfaceLanguage = val				
				Action.GetLocalization()						
				Action.MainUI.AllReset.text:SetText(L["TAB"]["RESETBUTTON"])
				StdUi:ButtonAutoWidth(Action.MainUI.AllReset)
				Action.MainUI.GDateTime:SetText(L["GLOBALAPI"] .. DateTime)
				Action.MainUI.ResetQuestion.titlePanel.label:SetText(L["TAB"]["RESETQUESTION"])
				Action.MainUI.Yes.text:SetText(L["YES"])
				Action.MainUI.No.text:SetText(L["NO"])
				Action.MainUI.CheckboxSaveActions:SetText(L["TAB"]["SAVEACTIONS"])
				Action.MainUI.CheckboxSaveInterrupt:SetText(L["TAB"]["SAVEINTERRUPT"])
				Action.MainUI.CheckboxSaveDispel:SetText(L["TAB"]["SAVEDISPEL"])
				Action.MainUI.CheckboxSaveMouse:SetText(L["TAB"]["SAVEMOUSE"])
				Action.MainUI.CheckboxSaveMSG:SetText(L["TAB"]["SAVEMSG"])
				
				if StdUi.colorPickerFrame then 
					StdUi.colorPickerFrame.okButton.text:SetText(L["APPLY"])
					StdUi.colorPickerFrame.cancelButton.text:SetText(L["CLOSE"])
					StdUi.colorPickerFrame.resetButton.text:SetText(L["RESET"])
				end 
				
				tabFrame.tabs[1].title = L["TAB"][1]["HEADBUTTON"]
				tabFrame.tabs[3].title = L["TAB"][3]["HEADBUTTON"]
				tabFrame.tabs[4].title = L["TAB"][4]["HEADBUTTON"]
				tabFrame.tabs[5].title = L["TAB"][5]["HEADBUTTON"]
				tabFrame.tabs[6].title = L["TAB"][6]["HEADBUTTON"]			
				tabFrame:DrawButtons()							
				spec = specID .. CL	
				for i = 1, #tabFrame.tabs do
					local tab = tabFrame.tabs[i]
					if tab and tab.childs[spec] then -- don't touch tab.childs[spec]
						if i == 3 then 		
							if tab.childs[spec] and tab.childs[spec].ScrollTable then -- in case if profile is Basic without created actions 
								local ScrollTable = tab.childs[spec].ScrollTable -- don't touch tab.childs[spec]
								for index = 1, #ScrollTable.data do 								
									if ScrollTable.data[index]:IsBlocked() then 
										ScrollTable.data[index].Enabled = "False"
									else 
										ScrollTable.data[index].Enabled = "True"
									end								
								end
								ScrollTable:ClearSelection()	
							end 
						else 
							-- Redraw statement by Identify if that langue frame is already drawed							
							local kids = GetKids(tab, spec)
							for _, child in ipairs(kids) do 				
								if child.Identify and child.Identify.Toggle then 
									-- SetValue not uses here because it will trigger OnValueChanged which we don't need in case of performance optimization
									if child.Identify.Type == "Checkbox" then
										child.isChecked = Action.GetToggle(i, child.Identify.Toggle)
										if child.isChecked then
											child.checkedTexture:Show()
										else 
											child.checkedTexture:Hide()
										end
									elseif child.Identify.Type == "Dropdown" then						
										if child.multi then 
											local SetVal = {}
											for item = 1, #child.optsFrame.scrollChild.items do 													
												child.optsFrame.scrollChild.items[item].isChecked = Action.GetToggle(i, child.Identify.Toggle)[item]								
												if child.optsFrame.scrollChild.items[item].isChecked then 
													child.optsFrame.scrollChild.items[item].checkedTexture:Show()
													tinsert(SetVal, child.optsFrame.scrollChild.items[item].value)
												else 
													child.optsFrame.scrollChild.items[item].checkedTexture:Hide()										
												end 
											end 							
											child.value = SetVal
											child:SetText(child:FindValueText(SetVal))
										else 
											child.value = Action.GetToggle(i, child.Identify.Toggle)
											--child.text:SetText(child.value)
											child.text:SetText(child:FindValueText(child.value))
										end 
									elseif child.Identify.Type == "Slider" then							
										child:SetValue(Action.GetToggle(i, child.Identify.Toggle)) 
									end 								  
								end
							end 	
						end
					end
				end		
				Action.ToggleMainUI()
				Action.ToggleMainUI()	
			end			
			anchor.InterfaceLanguage.Identify = { Type = "Dropdown", Toggle = "InterfaceLanguage" }
			anchor.InterfaceLanguage.FontStringTitle = StdUi:Subtitle(anchor.InterfaceLanguage, L["TAB"][tab.name]["CHANGELANGUAGE"])
			StdUi:GlueAbove(anchor.InterfaceLanguage.FontStringTitle, anchor.InterfaceLanguage)
			anchor.InterfaceLanguage.text:SetJustifyH("CENTER")															
			
			local AutoTarget = StdUi:Checkbox(anchor, L["TAB"][tab.name]["AUTOTARGET"])	
			AutoTarget:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].AutoTarget)	
			AutoTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoTarget:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].AutoTarget = not TMWdb.profile.ActionDB[tab.name][specID].AutoTarget	
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].AutoTarget)	
					Action.Print(L["TAB"][tab.name]["AUTOTARGET"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].AutoTarget)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["AUTOTARGET"], [[/run Action.SetToggle({]] .. tab.name .. [[, "AutoTarget", "]] .. L["TAB"][tab.name]["AUTOTARGET"] .. [[: "})]])	
				end 
			end)
			AutoTarget.Identify = { Type = "Checkbox", Toggle = "AutoTarget" }			
			StdUi:FrameTooltip(AutoTarget, L["TAB"][tab.name]["AUTOTARGETTOOLTIP"], nil, "TOPRIGHT", true)		
			AutoTarget.FontStringTitle = StdUi:Subtitle(AutoTarget, L["TAB"][tab.name]["CHARACTERSECTION"])
			StdUi:GlueAbove(AutoTarget.FontStringTitle, AutoTarget)
			
			local Potion = StdUi:Checkbox(anchor, L["TAB"][tab.name]["POTION"])		
			Potion:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].Potion)
			Potion:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Potion:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].Potion = not TMWdb.profile.ActionDB[tab.name][specID].Potion
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].Potion)	
					Action.Print(L["TAB"][tab.name]["POTION"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].Potion)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["POTION"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Potion", "]] .. L["TAB"][tab.name]["POTION"] .. [[: "})]])	
				end 
			end)
			Potion.Identify = { Type = "Checkbox", Toggle = "Potion" }	
			StdUi:FrameTooltip(Potion, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			
			local HeartOfAzeroth = StdUi:Checkbox(anchor, L["TAB"][tab.name]["HEARTOFAZEROTH"])		
			HeartOfAzeroth:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].HeartOfAzeroth)
			HeartOfAzeroth:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HeartOfAzeroth:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 	
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].HeartOfAzeroth = not TMWdb.profile.ActionDB[tab.name][specID].HeartOfAzeroth
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].HeartOfAzeroth)	
						Action.Print(L["TAB"][tab.name]["HEARTOFAZEROTH"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].HeartOfAzeroth)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEARTOFAZEROTH"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HeartOfAzeroth", "]] .. L["TAB"][tab.name]["HEARTOFAZEROTH"] .. [[: "})]])	
					end 
				end
			end)
			HeartOfAzeroth.Identify = { Type = "Checkbox", Toggle = "HeartOfAzeroth" }		
			StdUi:FrameTooltip(HeartOfAzeroth, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			if not AzeriteEssence then 
				HeartOfAzeroth:Disable()
			end 

			local Racial = StdUi:Checkbox(anchor, L["TAB"][tab.name]["RACIAL"])			
			Racial:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].Racial)
			Racial:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Racial:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].Racial = not TMWdb.profile.ActionDB[tab.name][specID].Racial
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].Racial)	
					Action.Print(L["TAB"][tab.name]["RACIAL"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].Racial)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["RACIAL"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Racial", "]] .. L["TAB"][tab.name]["RACIAL"] .. [[: "})]])	
				end 
			end)
			Racial.Identify = { Type = "Checkbox", Toggle = "Racial" }
			StdUi:FrameTooltip(Racial, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	

			local StopCast = StdUi:Checkbox(anchor, L["TAB"][tab.name]["STOPCAST"])			
			StopCast:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].StopCast)
			StopCast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopCast:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].StopCast = not TMWdb.profile.ActionDB[tab.name][specID].StopCast
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].StopCast)	
					Action.Print(L["TAB"][tab.name]["STOPCAST"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].StopCast)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["STOPCAST"], [[/run Action.SetToggle({]] .. tab.name .. [[, "StopCast", "]] .. L["TAB"][tab.name]["STOPCAST"] .. [[: "})]])	
				end 
			end)
			StopCast.Identify = { Type = "Checkbox", Toggle = "StopCast" }
			StdUi:FrameTooltip(StopCast, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			
			local ReTarget = StdUi:Checkbox(anchor, "ReTarget")			
			ReTarget:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].ReTarget)
			ReTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			ReTarget:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].ReTarget = not TMWdb.profile.ActionDB[tab.name][specID].ReTarget
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].ReTarget)	
					Action.Print("ReTarget" .. ": ", TMWdb.profile.ActionDB[tab.name][specID].ReTarget)	
					Re:Initialize()
				elseif button == "RightButton" then 
					CraftMacro("ReTarget", [[/run Action.SetToggle({]] .. tab.name .. [[, "ReTarget", "]] .. "ReTarget" .. [[: "})]])	
				end 
			end)
			ReTarget.Identify = { Type = "Checkbox", Toggle = "ReTarget" }
			StdUi:FrameTooltip(ReTarget, L["TAB"][tab.name]["RETARGET"], nil, "TOPRIGHT", true)
			ReTarget.FontStringTitle = StdUi:Subtitle(ReTarget, L["TAB"][tab.name]["PVPSECTION"])
			StdUi:GlueAbove(ReTarget.FontStringTitle, ReTarget)			

			local ReFocus = StdUi:Checkbox(anchor, "ReFocus")
			ReFocus:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].ReFocus)
			ReFocus:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			ReFocus:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].ReFocus = not TMWdb.profile.ActionDB[tab.name][specID].ReFocus
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].ReFocus)	
					Action.Print("ReFocus" .. ": ", TMWdb.profile.ActionDB[tab.name][specID].ReFocus)
					Re:Initialize()					
				elseif button == "RightButton" then 
					CraftMacro("ReFocus", [[/run Action.SetToggle({]] .. tab.name .. [[, "ReFocus", "]] .. "ReFocus" .. [[: "})]])	
				end 
			end)
			ReFocus.Identify = { Type = "Checkbox", Toggle = "ReFocus" }
			StdUi:FrameTooltip(ReFocus, L["TAB"][tab.name]["REFOCUS"], nil, "TOPRIGHT", true)				
			
			local LosSystem = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOSSYSTEM"])
			LosSystem:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].LOSCheck)
			LosSystem:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			LosSystem:SetScript('OnClick', function(self, button, down)	
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].LOSCheck = not TMWdb.profile.ActionDB[tab.name][specID].LOSCheck
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].LOSCheck)	
					Action.Print(L["TAB"][tab.name]["LOSSYSTEM"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].LOSCheck)
					LineOfSight:Initialize()	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["LOSSYSTEM"], [[/run Action.SetToggle({]] .. tab.name .. [[, "LOSCheck", "]] .. L["TAB"][tab.name]["LOSSYSTEM"] .. [[: "})]])	
				end 
			end)
			LosSystem.Identify = { Type = "Checkbox", Toggle = "LOSCheck" }				
			StdUi:FrameTooltip(LosSystem, L["TAB"][tab.name]["LOSSYSTEMTOOLTIP"], nil, "TOPLEFT", true)
			LosSystem.FontStringTitle = StdUi:Subtitle(LosSystem, L["TAB"][tab.name]["SYSTEMSECTION"])
			StdUi:GlueAbove(LosSystem.FontStringTitle, LosSystem)								
			
			local DBMFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DBM"])
			DBMFrame:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].DBM)
			DBMFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DBMFrame:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 	
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].DBM = not TMWdb.profile.ActionDB[tab.name][specID].DBM
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].DBM)					
						Action.Print(L["TAB"][tab.name]["DBM"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].DBM)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["DBM"], [[/run Action.SetToggle({]] .. tab.name .. [[, "DBM", "]] .. L["TAB"][tab.name]["DBM"] .. [[: "})]])	
					end 
				end
			end)
			DBMFrame.Identify = { Type = "Checkbox", Toggle = "DBM" }
			DBMFrame:SetScript("OnShow", function()
				if not DBM then 
					DBMFrame:Disable()
				else 
					DBMFrame:Enable()
				end 
			end)
			if not DBM then 
				DBMFrame:Disable()
			end 
			StdUi:FrameTooltip(DBMFrame, "Deadly Boss Mods\n" .. L["TAB"][tab.name]["DBMTOOLTIP"], nil, "TOPLEFT", true)
			
			local HE_PetsFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["HEALINGENGINEPETS"])		
			HE_PetsFrame:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].HE_Pets)
			HE_PetsFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HE_PetsFrame:SetScript('OnClick', function(self, button, down)	
				if not self.isDisabled then 				
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].HE_Pets = not TMWdb.profile.ActionDB[tab.name][specID].HE_Pets
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].HE_Pets)	
						HE_Pets = TMWdb.profile.ActionDB[tab.name][specID].HE_Pets
						Action.Print(L["TAB"][tab.name]["HEALINGENGINEPETS"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].HE_Pets)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEALINGENGINEPETS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HE_Pets", "]] .. L["TAB"][tab.name]["HEALINGENGINEPETS"] .. [[: "})]])	
					end 
				end 
			end)
			HE_PetsFrame.Identify = { Type = "Checkbox", Toggle = "HE_Pets" }			
			HE_PetsFrame:SetScript("OnShow", function()
				if not Action.IamHealer then 
					HE_PetsFrame:Disable()
				else 
					HE_PetsFrame:Enable()
				end 
			end)
			if not Action.IamHealer then
				HE_PetsFrame:Disable()
			end 
			StdUi:FrameTooltip(HE_PetsFrame, L["TAB"][tab.name]["HEALINGENGINEPETSTOOLTIP"], nil, "TOPLEFT", true)
			
			local HE_ToggleFrame = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), 20, {
				{ text = L["TAB"][tab.name]["ALL"], value = "ALL" },
				{ text = L["TAB"][tab.name]["RAID"], value = "RAID" },				
				{ text = L["TAB"][tab.name]["TANK"], value = "TANK" },
				{ text = L["TAB"][tab.name]["DAMAGER"], value = "DAMAGER" },
				{ text = L["TAB"][tab.name]["HEALER"], value = "HEALER" },
			})		          
			HE_ToggleFrame:SetValue(TMWdb.profile.ActionDB[tab.name][specID].HE_Toggle)
			HE_ToggleFrame.OnValueChanged = function(self, val)                
				TMWdb.profile.ActionDB[tab.name][specID].HE_Toggle = val 
				GlobalsRemap()
				Action.Print("HealingEngine" .. ": ", L["TAB"][tab.name][TMWdb.profile.ActionDB[tab.name][specID].HE_Toggle])
			end
			HE_ToggleFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HE_ToggleFrame:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro("HealingEngine", [[/run Action.ToggleHE()]])	
					end
				end 
			end)	
			HE_ToggleFrame:SetScript("OnShow", function()
				if not Action.IamHealer then 
					HE_ToggleFrame:Disable()
				else 
					HE_ToggleFrame:Enable()
				end 
			end)				
			if not Action.IamHealer then
				HE_ToggleFrame:Disable()
			end 
			HE_ToggleFrame.Identify = { Type = "Dropdown", Toggle = "HE_Toggle" }
			StdUi:FrameTooltip(HE_ToggleFrame, L["TAB"][tab.name]["HEALINGENGINETOOLTIP"], nil, "TOPLEFT", true)
			HE_ToggleFrame.FontStringTitle = StdUi:Subtitle(HE_ToggleFrame, "HealingEngine")
			StdUi:GlueAbove(HE_ToggleFrame.FontStringTitle, HE_ToggleFrame)	
			HE_ToggleFrame.text:SetJustifyH("CENTER")	

			local StopAtBreakAble = StdUi:Checkbox(anchor, L["TAB"][tab.name]["STOPATBREAKABLE"], 50)			
			StopAtBreakAble:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].StopAtBreakAble)
			StopAtBreakAble:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopAtBreakAble:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].StopAtBreakAble = not TMWdb.profile.ActionDB[tab.name][specID].StopAtBreakAble
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].StopAtBreakAble)	
						Action.Print(L["TAB"][tab.name]["STOPATBREAKABLE"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].StopAtBreakAble)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["STOPATBREAKABLE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "StopAtBreakAble", "]] .. L["TAB"][tab.name]["STOPATBREAKABLE"] .. [[: "})]])	
					end 
				end 
			end)
			StopAtBreakAble.Identify = { Type = "Checkbox", Toggle = "StopAtBreakAble" }
			StdUi:FrameTooltip(StopAtBreakAble, L["TAB"][tab.name]["STOPATBREAKABLETOOLTIP"], nil, "TOPLEFT", true)	
			
			local FPS = StdUi:Slider(anchor, GetWidthByColumn(anchor, 5.8), ActionDatatheme.dd.height, TMWdb.profile.ActionDB[tab.name][specID].FPS, false, -0.01, 1.5)
			FPS:SetPrecision(2)
			FPS:SetScript('OnMouseUp', function(self, button, down)
					if button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["FPS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "FPS", "]] .. L["TAB"][tab.name]["FPS"] .. [[: "}, ]] .. TMWdb.profile.ActionDB[tab.name][specID].FPS .. [[)]])	
					end					
			end)		
			FPS.Identify = { Type = "Slider", Toggle = "FPS" }		
			FPS.OnValueChanged = function(self, value)
				if value < 0 then 
					value = -0.01
				end 
				TMWdb.profile.ActionDB[tab.name][specID].FPS = value
				FPS.FontStringTitle:SetText(L["TAB"][tab.name]["FPS"] .. ": |cff00ff00" .. (value < 0 and "AUTO" or (value .. L["TAB"][tab.name]["FPSSEC"])))
			end
			StdUi:FrameTooltip(FPS, L["TAB"][tab.name]["FPSTOOLTIP"], nil, "TOPRIGHT", true)	
			FPS.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tab.name]["FPS"] .. ": |cff00ff00" .. (TMWdb.profile.ActionDB[tab.name][specID].FPS < 0 and "AUTO" or (TMWdb.profile.ActionDB[tab.name][specID].FPS .. L["TAB"][tab.name]["FPSSEC"])))
			StdUi:GlueAbove(FPS.FontStringTitle, FPS)					
			
			local Trinkets = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, {
				{ text = L["TAB"][tab.name]["TRINKET"] .. " 1", value = 1 },
				{ text = L["TAB"][tab.name]["TRINKET"] .. " 2", value = 2 },
			}, nil, true)
			Trinkets:SetPlaceholder(" -- " .. L["TAB"][tab.name]["TRINKETS"] .. " -- ") 
			for i = 1, #Trinkets.optsFrame.scrollChild.items do 
				Trinkets.optsFrame.scrollChild.items[i]:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].Trinkets[i])
			end 			
			Trinkets.OnValueChanged = function(self, value)			
				for i = 1, #self.optsFrame.scrollChild.items do 					
					if TMWdb.profile.ActionDB[tab.name][specID].Trinkets[i] ~= self.optsFrame.scrollChild.items[i]:GetChecked() then
						TMWdb.profile.ActionDB[tab.name][specID].Trinkets[i] = self.optsFrame.scrollChild.items[i]:GetChecked()
						Action.Print(L["TAB"][tab.name]["TRINKET"] .. " " .. i .. ": ", TMWdb.profile.ActionDB[tab.name][specID].Trinkets[i])
					end 				
				end 				
			end				
			Trinkets:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Trinkets:SetScript('OnClick', function(self, button, down)
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["TRINKETS"], [[/run Action.SetToggle({]] .. tab.name .. [[, "Trinkets", "]] .. L["TAB"][tab.name]["TRINKET"] .. [[ "})]])	
					end
			end)		
			Trinkets.Identify = { Type = "Dropdown", Toggle = "Trinkets" }			
			Trinkets.FontStringTitle = StdUi:Subtitle(Trinkets, L["TAB"][tab.name]["TRINKETS"])
			StdUi:FrameTooltip(Trinkets, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Trinkets.FontStringTitle, Trinkets)
			Trinkets.text:SetJustifyH("CENTER")			
						
			local Burst = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, {
				{ text = "Everything", value = "Everything" },
				{ text = "Auto", value = "Auto" },				
				{ text = "Off", value = "Off" },
			})		          
			Burst:SetValue(TMWdb.profile.ActionDB[tab.name][specID].Burst)
			Burst.OnValueChanged = function(self, val)                
				TMWdb.profile.ActionDB[tab.name][specID].Burst = val 
				TMW:Fire("TMW_ACTION_BURST_CHANGED")
				TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 
				if val ~= "Off" then 
					ActionDataTG["Burst"] = val
				end 
				Action.Print(L["TAB"][tab.name]["BURST"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].Burst)
			end
			Burst:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Burst:SetScript('OnClick', function(self, button, down)
					if button == "LeftButton" then 
						self:ToggleOptions()
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["BURST"], [[/run Action.ToggleBurst()]])	
					end
			end)		
			Burst.Identify = { Type = "Dropdown", Toggle = "Burst" }	
			StdUi:FrameTooltip(Burst, L["TAB"][tab.name]["BURSTTOOLTIP"], nil, "TOPLEFT", true)
			Burst.FontStringTitle = StdUi:Subtitle(Burst, L["TAB"][tab.name]["BURST"])
			StdUi:GlueAbove(Burst.FontStringTitle, Burst)	
			Burst.text:SetJustifyH("CENTER")				

			local HealthStone = StdUi:Slider(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, TMWdb.profile.ActionDB[tab.name][specID].HealthStone, false, -1, 100)	
			HealthStone:SetScript('OnMouseUp', function(self, button, down)
					if button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["HEALTHSTONE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "HealthStone", "]] .. L["TAB"][tab.name]["HEALTHSTONE"] .. [[: "}, ]] .. TMWdb.profile.ActionDB[tab.name][specID].HealthStone .. [[)]])	
					end					
			end)		
			HealthStone.Identify = { Type = "Slider", Toggle = "HealthStone" }		
			HealthStone.OnValueChanged = function(self, value)
				local value = math_floor(value) 
				TMWdb.profile.ActionDB[tab.name][specID].HealthStone = value
				self.FontStringTitle:SetText(L["TAB"][tab.name]["HEALTHSTONE"] .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value >= 100 and "|cff00ff00AUTO|r" or value))
			end
			StdUi:FrameTooltip(HealthStone, L["TAB"][tab.name]["HEALTHSTONETOOLTIP"], nil, "TOPLEFT", true)	
			HealthStone.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tab.name]["HEALTHSTONE"] .. ": |cff00ff00" .. (TMWdb.profile.ActionDB[tab.name][specID].HealthStone < 0 and "|cffff0000OFF|r" or TMWdb.profile.ActionDB[tab.name][specID].HealthStone >= 100 and "|cff00ff00AUTO|r" or TMWdb.profile.ActionDB[tab.name][specID].HealthStone))
			StdUi:GlueAbove(HealthStone.FontStringTitle, HealthStone)
			
			local Color 		= { 
				Title 			= StdUi:Subtitle(anchor, L["TAB"][tab.name]["COLORTITLE"]),
				Elements 		= {}, 	-- Stores static array like table for 'Element' dropdown 
				Options 		= {},	-- Stores dynamic array like table for 'Option' dropdown depends on 'Element' choice
				Themes			= {},	-- Stores static array like table for 'Theme' dropdown
				SetupStates 	= function(self)
					-- Switches between enabled and disabled 
					if not TMWdb.profile.ActionDB[tab.name].ColorPickerUse then -- don't touch
						self.Picker:Disable()
						self.Element:Disable()
						self.Option:Disable()
						self.Theme:Disable()	
						self.ThemeApplyButton:Disable()
						-- Set back manual custom backdrop color 
						Action.MainUI.ResetQuestion:SetBackdropColor(0, 0, 0, 1)
					else
						self.Picker:Enable()
						self.Element:Enable()
						self.Option:Enable()
						self.Theme:Enable()
						self.Theme:OnValueChanged(self.Theme:GetValue()) -- to enable 'ThemeApplyButton' if necessary
						self:SetupPicker()
					end 					
				end,	
				SetupPicker		= function(self)
					local e, o	= self.Element:GetValue(), self.Option:GetValue()
					local c 	= ColorPicker:tFindByOption(StdUi.config[e], o)		
					
					-- Switches color of checkbox 
					self.Picker:SetColor(c)
					-- Switches color of Color Frame 
					if StdUi.colorPickerFrame and StdUi.colorPickerFrame:IsVisible() then 
						StdUi.colorPickerFrame:SetColorRGBA(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
						StdUi.colorPickerFrame.oldTexture:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
					end 					
				end,					
			}				
			
			Color.Title:SetAllPoints()			
			Color.Title:SetJustifyH('MIDDLE')
			Color.Title:SetFontSize(14)

			Color.UseColor = StdUi:Checkbox(anchor, L["TAB"][tab.name]["COLORUSE"])
			Color.UseColor:SetChecked(TMWdb.profile.ActionDB[tab.name].ColorPickerUse)
			Color.UseColor.OnValueChanged = function(self, state, value)
				TMWdb.profile.ActionDB[tab.name].ColorPickerUse = state		
				Action.Print(L["TAB"][tab.name]["COLORTITLE"] .. " - " .. L["TAB"][tab.name]["COLORUSE"] .. ": ", state)
				ColorPicker:Initialize()
				Color:SetupStates()

				-- Hide color frame 
				if self.stdUi.colorPickerFrame and self.stdUi.colorPickerFrame:IsVisible() then 
					self.stdUi.colorPickerFrame:Hide()
				end 
			end	
			Color.UseColor.Identify = { Type = "Checkbox", Toggle = "ColorPickerUse" }
			StdUi:FrameTooltip(Color.UseColor, L["TAB"][tab.name]["COLORUSETOOLTIP"], nil, "TOPRIGHT", true)
			
			Color.Picker = StdUi:ColorInput(anchor, L["TAB"][tab.name]["COLORPICKER"])
			Color.Picker.prevRGBA = {} -- Stores previous state of color with alpha (associative table)
			Color.Picker.okCallback = function(cpf)
				wipe(Color.Picker.prevRGBA)
				Color.Picker:SetColor(cpf:GetColor())
				
				Color.currentTheme = nil 
				if Color.ThemeApplyButton.isDisabled then 
					local currentTheme = Color.Theme:GetValue()
					if ColorPicker.Themes[currentTheme] then 
						Color.ThemeApplyButton:Enable()
					end
				end
			end 
			Color.Picker.cancelCallback	= function()
				if next(Color.Picker.prevRGBA) then 
					Color.Picker:SetColor(Color.Picker.prevRGBA)
					wipe(Color.Picker.prevRGBA)
				end 
			end
			Color.Picker:HookScript("OnClick", function(self)
				if self.isDisabled then 
					return 
				end 
				
				if not self.stdUi.colorPickerFrame.isModified then 
					-- Make move able  
					self.stdUi.colorPickerFrame:SetMovable(true)
					self.stdUi.colorPickerFrame:EnableMouse(true)
					self.stdUi.colorPickerFrame:RegisterForDrag("RightButton")
					self.stdUi.colorPickerFrame:SetScript("OnDragStart", self.stdUi.colorPickerFrame.StartMoving)
					self.stdUi.colorPickerFrame:SetScript("OnDragStop", function(this)
						this:StopMovingOrSizing()
						this.xOfs, this.yOfs = select(4, this:GetPoint())
					end)
					self.stdUi.colorPickerFrame:SetClampedToScreen(true)
					
					-- Create reset button 
					self.stdUi.colorPickerFrame.resetButton = StdUi:Button(self.stdUi.colorPickerFrame, self.stdUi.colorPickerFrame.cancelButton:GetWidth(), self.stdUi.colorPickerFrame.cancelButton:GetHeight(), L["RESET"])
					self.stdUi.colorPickerFrame.resetButton:RegisterForClicks("LeftButtonUp")
					self.stdUi.colorPickerFrame.resetButton:SetScript("OnClick", function(this, button, down)
						if not this.isDisabled then
							local e, o = TMWdb.profile.ActionDB[tab.name].ColorPickerElement, TMWdb.profile.ActionDB[tab.name].ColorPickerOption -- don't touch 
							ColorPicker:ResetOn(e, o)	
							self.stdUi.colorPickerFrame:SetColor(ColorPicker:tFindByOption(ColorPicker.Cache[e], o))							
						end 
					end)
					StdUi:GlueAbove(self.stdUi.colorPickerFrame.resetButton, self.stdUi.colorPickerFrame.cancelButton, 0, 5)
										
					-- Since StdUi used as new instance hooksecurefunc doesn't work on thigs used directly inside lib
					-- Add to StdUiObjects OK / Cancel buttons   
					self.stdUi:ApplyBackdrop(self.stdUi.colorPickerFrame.okButton)					
					self.stdUi:SetTextColor(self.stdUi.colorPickerFrame.okButton.text, "normal")
					self.stdUi.colorPickerFrame.okButton.text:SetText(L["APPLY"])
					self.stdUi:ApplyBackdrop(self.stdUi.colorPickerFrame.cancelButton)					
					self.stdUi:SetTextColor(self.stdUi.colorPickerFrame.cancelButton.text, "normal")
					self.stdUi.colorPickerFrame.cancelButton.text:SetText(L["CLOSE"])									
					
					-- Create hook to hide with main UI
					Action.MainUI:HookScript("OnHide", function(this)
						if self.stdUi.colorPickerFrame:IsVisible() then 
							self.stdUi.colorPickerFrame:Hide()
						end 
					end)
					
					self.stdUi.colorPickerFrame.isModified = true
				end 								
				
				if not self.isLocalHooked then 
					-- Just part of code to make in real time view changes 
					self.temp = {} -- Temporary table for r,g,b,a since StdUi has recreate table return for :GetColor			
					
					self.stdUi.colorPickerFrame:HookScript("OnColorSelect", function(this)
						if this:IsVisible() then 
							self.temp.r, self.temp.g, self.temp.b, self.temp.a = this:GetColorRGBA()
							self:OnValueChanged(self.temp)					
						end 
					end)
					
					self.isLocalHooked 	= true 
				end 
				
				self.stdUi.colorPickerFrame.okCallback = self.okCallback
				self.stdUi.colorPickerFrame.cancelCallback = self.cancelCallback
				-- Remember previous color + alpha states 
				if not next(self.prevRGBA) then  
					self.prevRGBA.r, self.prevRGBA.g, self.prevRGBA.b, self.prevRGBA.a = self.color.r or 1, self.color.g or 1, self.color.b or 1, self.color.a or 1
				end 
				
				-- Move to saved last position 
				if self.stdUi.colorPickerFrame.xOfs and self.stdUi.colorPickerFrame.yOfs then 
					self.stdUi.colorPickerFrame:SetPoint("CENTER", self.stdUi.colorPickerFrame.xOfs, self.stdUi.colorPickerFrame.yOfs)
				end 
			end)
			Color.Picker.OnValueChanged = function(self, v)  
				if not self.isDisabled then 
					local e, o 			= Color.Element:GetValue(), Color.Option:GetValue()
					local t 			= ColorPicker:tFindByOption(TMWdb.profile.ActionDB[tab.name].ColorPickerConfig[e], o)
					t.r, t.g, t.b, t.a 	= v.r, v.g, v.b, v.a
					ColorPicker:MakeOn(e, o, v)										
				end 
			end
			-- We don't use Identify here since pointless with dropdowns 
			StdUi:FrameTooltip(Color.Picker, L["TAB"][tab.name]["COLORPICKERTOOLTIP"], nil, "TOPLEFT", true)
			
			Color.Element = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, ColorPicker:SetElementsIn(Color.Elements))		
			Color.Element:SetValue(TMWdb.profile.ActionDB[tab.name].ColorPickerElement)
			Color.Element.OnValueChanged = function(self, val)      
				TMWdb.profile.ActionDB[tab.name].ColorPickerElement = val 
				Action.Print(L["TAB"][tab.name]["COLORTITLE"] .. " - " .. L["TAB"][tab.name]["COLORELEMENT"] .. ": ", val)				
				
				-- Change table structure for 'Option' dropdown and resize height
				Color.Option:SetOptions(ColorPicker:SetOptionsIn(Color.Options, val))				
				
				-- Refresh current selection if it's not equal 
				-- Note: We must do this instead of fixed set because :SetValue will always fire print 
				local current_value = Color.Option:GetValue()
				local equal_value 
				for _, v in ipairs(Color.Options) do 
					if current_value == v.value then 
						equal_value = true 
						break 
					end 
				end 
				if not equal_value then 
					Color.Option:SetValue(Color.Options[1].value)
					--Color:SetupPicker() -- will be fired through OnValueChanged of 'Option' dropdown 
				else 
					Color:SetupPicker()
				end 								
			end
			Color.Element:RegisterForClicks("LeftButtonUp")
			Color.Element:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Element.Identify = { Type = "Dropdown", Toggle = "ColorPickerElement" }	
			Color.Element.FontStringTitle = StdUi:Subtitle(Color.Element, L["TAB"][tab.name]["COLORELEMENT"])
			StdUi:GlueAbove(Color.Element.FontStringTitle, Color.Element)	
			Color.Element.text:SetJustifyH("CENTER")	
			
			Color.Option = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 6), ActionDatatheme.dd.height, ColorPicker:SetOptionsIn(Color.Options, Color.Element:GetValue()))		
			Color.Option:SetValue(TMWdb.profile.ActionDB[tab.name].ColorPickerOption)
			Color.Option.OnValueChanged = function(self, val)                
				TMWdb.profile.ActionDB[tab.name].ColorPickerOption = val 				
				Action.Print(L["TAB"][tab.name]["COLORTITLE"] .. " - " .. L["TAB"][tab.name]["COLOROPTION"] .. ": ", TMWdb.profile.ActionDB[tab.name].ColorPickerOption)
				
				-- Refresh RGBA of checkbox and color frame
				Color:SetupPicker()
			end
			Color.Option:RegisterForClicks("LeftButtonUp")
			Color.Option:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Option.Identify = { Type = "Dropdown", Toggle = "ColorPickerOption" }	
			Color.Option.FontStringTitle = StdUi:Subtitle(Color.Option, L["TAB"][tab.name]["COLOROPTION"])
			StdUi:GlueAbove(Color.Option.FontStringTitle, Color.Option)	
			Color.Option.text:SetJustifyH("CENTER")
			
			Color.Theme = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, 9), ActionDatatheme.dd.height, ColorPicker:SetThemesIn(Color.Themes))	
			Color.Theme:SetPlaceholder(L["TAB"][tab.name]["THEMEHOLDER"])
			Color.Theme.OnValueChanged = function(self, val) 
				if not self.isDisabled then 
					if Color.currentTheme == val then 
						if not Color.ThemeApplyButton.isDisabled then 
							Color.ThemeApplyButton:Disable()
						end 
					else
						if Color.ThemeApplyButton.isDisabled then 
							Color.ThemeApplyButton:Enable()
						end 
					end 
				end 
			end
			Color.Theme:RegisterForClicks("LeftButtonUp")
			Color.Theme:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Theme.FontStringTitle = StdUi:Subtitle(Color.Theme, L["TAB"][tab.name]["SELECTTHEME"])
			StdUi:GlueAbove(Color.Theme.FontStringTitle, Color.Theme)	
			Color.Theme.text:SetJustifyH("CENTER")
			
			Color.ThemeApplyButton = StdUi:Button(anchor, GetWidthByColumn(anchor, 2), ActionDatatheme.dd.height, L["APPLY"])
			Color.ThemeApplyButton:RegisterForClicks("LeftButtonUp")
			Color.ThemeApplyButton:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 		
					local currentTheme = Color.Theme:GetValue()
					if ColorPicker.Themes[currentTheme] then 						
						-- Apply selected theme 
						ColorPicker:MakeColors(ColorPicker.Themes[currentTheme])

						-- Save selected theme to db 
						TMWdb.profile.ActionDB[tab.name].ColorPickerConfig = tMerge(TMWdb.profile.ActionDB[tab.name].ColorPickerConfig, ColorPicker.Themes[currentTheme])
						
						-- Refresh rest  
						Color:SetupPicker()
						wipe(Color.Picker.prevRGBA)
						Color.currentTheme = currentTheme
						self:Disable()						
					end 
				end 
			end)
			Color.ThemeApplyButton:Disable()
			
			Color:SetupStates()
			Color:SetupPicker()						

			local PauseChecksPanel = StdUi:PanelWithTitle(anchor, tab.frame:GetWidth() - 30, 250, L["TAB"][tab.name]["PAUSECHECKS"])
			StdUi:GlueTop(PauseChecksPanel.titlePanel, PauseChecksPanel, 0, -5)
			PauseChecksPanel.titlePanel.label:SetFontSize(14)
			StdUi:EasyLayout(PauseChecksPanel, { padding = { top = PauseChecksPanel.titlePanel.label:GetHeight() + 10 } })	

			local CheckVehicle = StdUi:Checkbox(anchor, L["TAB"][tab.name]["VEHICLE"])			
			CheckVehicle:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckVehicle)
			function CheckVehicle:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckVehicle = not TMWdb.profile.ActionDB[tab.name].CheckVehicle		
				Action.Print(L["TAB"][tab.name]["VEHICLE"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckVehicle)
			end	
			CheckVehicle.Identify = { Type = "Checkbox", Toggle = "CheckVehicle" }
			StdUi:FrameTooltip(CheckVehicle, L["TAB"][tab.name]["VEHICLETOOLTIP"], nil, "BOTTOMRIGHT", true)				
			
			local CheckDeadOrGhost = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DEADOFGHOSTPLAYER"])	
			CheckDeadOrGhost:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhost)
			function CheckDeadOrGhost:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhost = not TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhost		
				Action.Print(L["TAB"][tab.name]["DEADOFGHOSTPLAYER"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhost)
			end		
			CheckDeadOrGhost.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhost" }
			
			local CheckDeadOrGhostTarget = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DEADOFGHOSTTARGET"])
			CheckDeadOrGhostTarget:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhostTarget)
			function CheckDeadOrGhostTarget:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhostTarget = not TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhostTarget
				Action.Print(L["TAB"][tab.name]["DEADOFGHOSTTARGET"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckDeadOrGhostTarget)
			end	
			CheckDeadOrGhostTarget.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhostTarget" }
			StdUi:FrameTooltip(CheckDeadOrGhostTarget, L["TAB"][tab.name]["DEADOFGHOSTTARGETTOOLTIP"], nil, "BOTTOMLEFT", true)						

			local CheckCombat = StdUi:Checkbox(anchor, L["TAB"][tab.name]["COMBAT"])	
			CheckCombat:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckCombat)
			function CheckCombat:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckCombat = not TMWdb.profile.ActionDB[tab.name].CheckCombat	
				Action.Print(L["TAB"][tab.name]["COMBAT"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckCombat)
			end	
			CheckCombat.Identify = { Type = "Checkbox", Toggle = "CheckCombat" }
			StdUi:FrameTooltip(CheckCombat, L["TAB"][tab.name]["COMBATTOOLTIP"], nil, "BOTTOMRIGHT", true)		

			local CheckMount = StdUi:Checkbox(anchor, L["TAB"][tab.name]["MOUNT"])
			CheckMount:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckMount)
			function CheckMount:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckMount = not TMWdb.profile.ActionDB[tab.name].CheckMount
				Action.Print(L["TAB"][tab.name]["MOUNT"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckMount)
			end	
			CheckMount.Identify = { Type = "Checkbox", Toggle = "CheckMount" }			

			local CheckSpellIsTargeting = StdUi:Checkbox(anchor, L["TAB"][tab.name]["SPELLISTARGETING"])		
			CheckSpellIsTargeting:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckSpellIsTargeting)
			function CheckSpellIsTargeting:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckSpellIsTargeting = not TMWdb.profile.ActionDB[tab.name].CheckSpellIsTargeting
				Action.Print(L["TAB"][tab.name]["SPELLISTARGETING"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckSpellIsTargeting)
			end	
			CheckSpellIsTargeting.Identify = { Type = "Checkbox", Toggle = "CheckSpellIsTargeting" }
			StdUi:FrameTooltip(CheckSpellIsTargeting, L["TAB"][tab.name]["SPELLISTARGETINGTOOLTIP"], nil, "BOTTOMRIGHT", true)	

			local CheckLootFrame = StdUi:Checkbox(anchor, L["TAB"][tab.name]["LOOTFRAME"])
			CheckLootFrame:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckLootFrame)
			function CheckLootFrame:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckLootFrame = not TMWdb.profile.ActionDB[tab.name].CheckLootFrame	
				Action.Print(L["TAB"][tab.name]["LOOTFRAME"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckLootFrame)
			end	
			CheckLootFrame.Identify = { Type = "Checkbox", Toggle = "CheckLootFrame" }	

			local CheckEatingOrDrinking = StdUi:Checkbox(anchor, L["TAB"][tab.name]["EATORDRINK"])
			CheckEatingOrDrinking:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckEatingOrDrinking)
			function CheckEatingOrDrinking:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].CheckEatingOrDrinking = not TMWdb.profile.ActionDB[tab.name].CheckEatingOrDrinking	
				Action.Print(L["TAB"][tab.name]["EATORDRINK"] .. ": ", TMWdb.profile.ActionDB[tab.name].CheckEatingOrDrinking)
			end	
			CheckEatingOrDrinking.Identify = { Type = "Checkbox", Toggle = "CheckEatingOrDrinking" }	
			
			local Misc = StdUi:Header(PauseChecksPanel, L["TAB"][tab.name]["MISC"])
			Misc:SetAllPoints()			
			Misc:SetJustifyH('MIDDLE')
			Misc:SetFontSize(14)
			
			local DisableRotationDisplay = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEROTATIONDISPLAY"])
			DisableRotationDisplay:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableRotationDisplay)
			function DisableRotationDisplay:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisableRotationDisplay = not TMWdb.profile.ActionDB[tab.name].DisableRotationDisplay		
				Action.Print(L["TAB"][tab.name]["DISABLEROTATIONDISPLAY"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisableRotationDisplay)
			end				
			DisableRotationDisplay.Identify = { Type = "Checkbox", Toggle = "DisableRotationDisplay" }
			StdUi:FrameTooltip(DisableRotationDisplay, L["TAB"][tab.name]["DISABLEROTATIONDISPLAYTOOLTIP"], nil, "BOTTOMRIGHT", true)	
			
			local DisableBlackBackground = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEBLACKBACKGROUND"])
			DisableBlackBackground:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableBlackBackground)
			function DisableBlackBackground:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisableBlackBackground = not TMWdb.profile.ActionDB[tab.name].DisableBlackBackground	
				Action.Print(L["TAB"][tab.name]["DISABLEBLACKBACKGROUND"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisableBlackBackground)
				Action.BlackBackgroundSet(not TMWdb.profile.ActionDB[tab.name].DisableBlackBackground)
			end				
			DisableBlackBackground.Identify = { Type = "Checkbox", Toggle = "DisableBlackBackground" }
			StdUi:FrameTooltip(DisableBlackBackground, L["TAB"][tab.name]["DISABLEBLACKBACKGROUNDTOOLTIP"], nil, "BOTTOMLEFT", true)	

			local DisablePrint = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEPRINT"])
			DisablePrint:SetChecked(TMWdb.profile.ActionDB[tab.name].DisablePrint)
			function DisablePrint:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisablePrint = not TMWdb.profile.ActionDB[tab.name].DisablePrint		
				Action.Print(L["TAB"][tab.name]["DISABLEPRINT"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisablePrint, true)
			end				
			DisablePrint.Identify = { Type = "Checkbox", Toggle = "DisablePrint" }
			StdUi:FrameTooltip(DisablePrint, L["TAB"][tab.name]["DISABLEPRINTTOOLTIP"], nil, "BOTTOMRIGHT", true)

			local DisableMinimap = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEMINIMAP"])
			DisableMinimap:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableMinimap)
			function DisableMinimap:OnValueChanged(self, state, value)
				Action.ToggleMinimap()
			end				
			DisableMinimap.Identify = { Type = "Checkbox", Toggle = "DisableMinimap" }
			StdUi:FrameTooltip(DisableMinimap, L["TAB"][tab.name]["DISABLEMINIMAPTOOLTIP"], nil, "BOTTOMLEFT", true)	
						
			local DisableClassPortraits = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEPORTRAITS"])
			DisableClassPortraits:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableClassPortraits)
			function DisableClassPortraits:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisableClassPortraits = not TMWdb.profile.ActionDB[tab.name].DisableClassPortraits		
				Action.Print(L["TAB"][tab.name]["DISABLEPORTRAITS"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisableClassPortraits)
			end				
			DisableClassPortraits.Identify = { Type = "Checkbox", Toggle = "DisableClassPortraits" }	

			local DisableRotationModes = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLEROTATIONMODES"])
			DisableRotationModes:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableRotationModes)
			function DisableRotationModes:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisableRotationModes = not TMWdb.profile.ActionDB[tab.name].DisableRotationModes		
				Action.Print(L["TAB"][tab.name]["DISABLEROTATIONMODES"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisableRotationModes)
			end				
			DisableRotationModes.Identify = { Type = "Checkbox", Toggle = "DisableRotationModes" }	
			
			local DisableSounds = StdUi:Checkbox(anchor, L["TAB"][tab.name]["DISABLESOUNDS"])
			DisableSounds:SetChecked(TMWdb.profile.ActionDB[tab.name].DisableSounds)
			function DisableSounds:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].DisableSounds = not TMWdb.profile.ActionDB[tab.name].DisableSounds		
				Action.Print(L["TAB"][tab.name]["DISABLESOUNDS"] .. ": ", TMWdb.profile.ActionDB[tab.name].DisableSounds)
			end				
			DisableSounds.Identify = { Type = "Checkbox", Toggle = "DisableSounds" }

			local HideOnScreenshot = StdUi:Checkbox(anchor, L["TAB"][tab.name]["HIDEONSCREENSHOT"])
			HideOnScreenshot:SetChecked(TMWdb.profile.ActionDB[tab.name].HideOnScreenshot)
			function HideOnScreenshot:OnValueChanged(self, state, value)
				TMWdb.profile.ActionDB[tab.name].HideOnScreenshot = not TMWdb.profile.ActionDB[tab.name].HideOnScreenshot
				ScreenshotHider:Initialize(TMWdb.profile.ActionDB[tab.name].HideOnScreenshot)
			end				
			HideOnScreenshot.Identify = { Type = "Checkbox", Toggle = "HideOnScreenshot" }
			StdUi:FrameTooltip(HideOnScreenshot, L["TAB"][tab.name]["HIDEONSCREENSHOTTOOLTIP"], nil, "BOTTOMLEFT", true)	
			
			local GlobalOverlay = anchor:AddRow()					
			GlobalOverlay:AddElement(PvEPvPToggle, { column = 5.35 })			
			GlobalOverlay:AddElement(LayoutSpace(anchor), { column = 0.65 })			
			GlobalOverlay:AddElement(anchor.InterfaceLanguage, { column = 6 })			
			anchor:AddRow({ margin = { top = 10 } }):AddElements(ReTarget, Trinkets, { column = "even" })			
			anchor:AddRow():AddElements(ReFocus, Burst, { column = "even" })			
			local SpecialRow = anchor:AddRow()
			SpecialRow:AddElement(FPS, { column = 5.9 })
			SpecialRow:AddElement(LayoutSpace(anchor), { column = 0.1 })
			SpecialRow:AddElement(HealthStone, { column = 6 })
			anchor:AddRow({ margin = { top = 10 } }):AddElements(AutoTarget, LosSystem, { column = "even" })
			anchor:AddRow({ margin = { top = -5 } }):AddElements(Potion, DBMFrame, { column = "even" })			
			anchor:AddRow({ margin = { top = -5 } }):AddElements(HeartOfAzeroth, HE_PetsFrame, { column = "even" })
			anchor:AddRow():AddElements(Racial, HE_ToggleFrame, { column = "even" })	
			anchor:AddRow():AddElements(StopCast, StopAtBreakAble, { column = "even" })	
			anchor:AddRow():AddElements(Color.Title, { column = "even" })	
			anchor:AddRow({ margin = { top = -10 } }):AddElements(Color.UseColor, Color.Picker, { column = "even" })	
			anchor:AddRow():AddElements(Color.Element, Color.Option, { column = "even" })	
			local ThemeRow = anchor:AddRow({ margin = { top = 5 }})
			ThemeRow:AddElement(Color.Theme, { column = 9 })
			ThemeRow:AddElement(Color.ThemeApplyButton, { column = 3})
			anchor:AddRow():AddElement(PauseChecksPanel)		
			PauseChecksPanel:AddRow({ margin = { top = 10 } }):AddElements(CheckSpellIsTargeting, CheckLootFrame, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckVehicle, CheckDeadOrGhost, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckMount, CheckDeadOrGhostTarget, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckCombat, CheckEatingOrDrinking, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -15 } }):AddElement(Misc)		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableRotationDisplay, DisableBlackBackground, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisablePrint, DisableMinimap, { column = "even" })			
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableClassPortraits, DisableRotationModes, { column = "even" })		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableSounds, HideOnScreenshot, { column = "even" })	
			PauseChecksPanel:DoLayout()		
			-- Add empty space for scrollframe after all elements 
			anchor:AddRow():AddElement(LayoutSpace(anchor), { column = 12 })	
			--anchor:AddRow():AddElement(LayoutSpace(anchor), { column = 12, margin = { top = 10 } })	
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			
		
			anchor:DoLayout()		
		end 
		
		if tab.name == 2 then 	
            UI_Title:SetText(specName)			
			tab.title = specName
			tabFrame:DrawButtons()	
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget
			StdUi:InitWidget(anchor)
			
			if not Action.Data.ProfileUI or not Action.Data.ProfileUI[tab.name] or not Action.Data.ProfileUI[tab.name][specID] or not next(Action.Data.ProfileUI[tab.name][specID]) then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 				

			local options = Action.Data.ProfileUI[tab.name][specID].LayoutOptions
			if options then 
				if not options.padding then 
					options.padding = {}
				end 
				
				if not options.padding.top then 
					options.padding.top = 40 
				end 	

				-- Cut out scrollbar 
				if not options.padding.right then 
					options.padding.right = 10 + 20
				elseif options.padding.right < 20 then 
					options.padding.right = options.padding.right + 20
				end 
			end 			
			
			StdUi:EasyLayout(anchor, options or { padding = { top = 40, right = 10 + 20 } })			
			for row = 1, #Action.Data.ProfileUI[tab.name][specID] do 
				local SpecRow = anchor:AddRow(Action.Data.ProfileUI[tab.name][specID][row].RowOptions)	
				for element = 1, #Action.Data.ProfileUI[tab.name][specID][row] do 
					local config = Action.Data.ProfileUI[tab.name][specID][row][element]	
					
					local db_InterfaceLanguage = TMWdb and TMWdb.global.ActionDB and TMWdb.global.ActionDB.InterfaceLanguage
					local CL = (config.L and (db_InterfaceLanguage and db_InterfaceLanguage ~= "Auto" and config.L[db_InterfaceLanguage] and db_InterfaceLanguage or config.L[GameLocale] and GameLocale)) or "enUS"
					local CTT = (config.TT and (db_InterfaceLanguage and db_InterfaceLanguage ~= "Auto" and config.TT[db_InterfaceLanguage] and db_InterfaceLanguage or config.TT[GameLocale] and GameLocale)) or "enUS"					
					
					local obj					
					if config.E == "Label" then 
						obj = StdUi:Label(anchor, config.L.ANY or config.L[CL], config.S or 14)
					elseif config.E == "Header" then 
						obj = StdUi:Header(anchor, config.L.ANY or config.L[CL])
						obj:SetAllPoints()			
						obj:SetJustifyH("MIDDLE")						
						obj:SetFontSize(config.S or 14)	
					elseif config.E == "Button" then 
						obj = StdUi:Button(anchor, GetWidthByColumn(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][specID][row])), config.H or 20, config.L.ANY or config.L[CL])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)
							if not self.isDisabled then 
								config.OnClick(self, button, down) 
							end 
						end)
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						--obj.FontStringTitle = StdUi:Subtitle(obj, config.L.ANY or config.L[CL])
						--StdUi:GlueAbove(obj.FontStringTitle, obj)
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Checkbox" then 						
						obj = StdUi:Checkbox(anchor, config.L.ANY or config.L[CL])
						obj:SetChecked(TMWdb.profile.ActionDB[tab.name][specID][config.DB])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)	
							if not self.isDisabled then 	
								if button == "LeftButton" then 
									TMWdb.profile.ActionDB[tab.name][specID][config.DB] = not TMWdb.profile.ActionDB[tab.name][specID][config.DB]
									self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID][config.DB])	
									if strlowerCache[self.Identify.Toggle] == "aoe" then 
										TMW:Fire("TMW_ACTION_AOE_CHANGED")
										TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED") -- Taste's callback 
									end 
									Action.Print((config.L.ANY or config.L[CL]) .. ": ", TMWdb.profile.ActionDB[tab.name][specID][config.DB])	
								elseif button == "RightButton" and config.M then 
									CraftMacro( config.L.ANY or config.L[CL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tab.name) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. (config.M.Value or "nil") .. [[)]]), 1 )	
								end 
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Dropdown" then
						-- Get formated by localization in OT
						local FormatedOT 
						for p = 1, #config.OT do 
							if type(config.OT[p].text) == "table" then 
								FormatedOT = {}
								for j = 1, #config.OT do 
									if type(config.OT[j].text) ~= "table" then 
										FormatedOT[#FormatedOT + 1] = config.OT[j]
									else
										local OT = db_InterfaceLanguage and db_InterfaceLanguage ~= "Auto" and config.OT[j].text[db_InterfaceLanguage] and db_InterfaceLanguage or config.OT[j].text[GameLocale] and GameLocale or "enUS"
										FormatedOT[#FormatedOT + 1] = { text = config.OT[j].text.ANY or config.OT[j].text[OT], value = config.OT[j].value }
									end 
								end
								break 
							end 
						end 
						obj = StdUi:Dropdown(anchor, GetWidthByColumn(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][specID][row])), config.H or 20, FormatedOT or config.OT, nil, config.MULT)
						if config.SetPlaceholder then 
							obj:SetPlaceholder(config.SetPlaceholder.ANY or config.SetPlaceholder[CL])
						end 
						if config.MULT then 
							for i = 1, #obj.optsFrame.scrollChild.items do 
								obj.optsFrame.scrollChild.items[i]:SetChecked(TMWdb.profile.ActionDB[tab.name][specID][config.DB][i])
							end
							obj.OnValueChanged = function(self, value)			
								for i = 1, #self.optsFrame.scrollChild.items do 					
									if TMWdb.profile.ActionDB[tab.name][specID][config.DB][i] ~= self.optsFrame.scrollChild.items[i]:GetChecked() then
										TMWdb.profile.ActionDB[tab.name][specID][config.DB][i] = self.optsFrame.scrollChild.items[i]:GetChecked()
										Action.Print((config.L.ANY or config.L[CL]) .. " " .. i .. ": ", TMWdb.profile.ActionDB[tab.name][specID][config.DB][i])
									end 				
								end 				
							end
						else 
							obj:SetValue(TMWdb.profile.ActionDB[tab.name][specID][config.DB])
							obj.OnValueChanged = function(self, val)                
								TMWdb.profile.ActionDB[tab.name][specID][config.DB] = val 
								if (config.isNotEqualVal and val ~= config.isNotEqualVal) or (config.isNotEqualVal == nil and val ~= "Off" and val ~= "OFF" and val ~= 0) then 
									ActionDataTG[config.DB] = val
								end 
								Action.Print((config.L.ANY or config.L[CL]) .. ": ", TMWdb.profile.ActionDB[tab.name][specID][config.DB])
							end
						end 
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)
							if not self.isDisabled then 
								if button == "LeftButton" then 
									self:ToggleOptions()
								elseif button == "RightButton" and config.M then 
									CraftMacro( config.L.ANY or config.L[CL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tab.name) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. (config.M.Value or (not config.MULT and obj:GetValue() and ([["]] .. obj:GetValue() .. [["]])) or "nil") .. [[)]]), 1 )								
								end
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						obj.FontStringTitle = StdUi:Subtitle(obj, config.L.ANY or config.L[CL])
						obj.FontStringTitle:SetJustifyH("CENTER")
						obj.text:SetJustifyH("CENTER")
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)	
						if config.isDisabled then 
							obj:Disable()
						end 
					elseif config.E == "Slider" then	
						obj = StdUi:Slider(anchor, math_floor(12 / #Action.Data.ProfileUI[tab.name][specID][row]), config.H or 20, TMWdb.profile.ActionDB[tab.name][specID][config.DB], false, config.MIN or -1, config.MAX or 100)	
						if config.Precision then 
							obj:SetPrecision(config.Precision)
						end
						if config.M then 
							obj:SetScript("OnMouseUp", function(self, button, down)
									if button == "RightButton" then 
										CraftMacro( config.L.ANY or config.L[CL], [[/run Action.SetToggle({]] .. tab.name .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[CL]) .. [[: "}, ]] .. TMWdb.profile.ActionDB[tab.name][specID][config.DB] .. [[)]], 1 )	
									end					
							end)
						end 
						local function ONOFF(value)
							if config.ONLYON then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value >= config.MAX and "|cff00ff00AUTO|r" or value)
							elseif config.ONLYOFF then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value)
							elseif config.ONOFF then 
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value >= config.MAX and "|cff00ff00AUTO|r" or value)
							else
								return (config.L.ANY or config.L[CL]) .. ": |cff00ff00" .. value .. "|r"
							end 
						end 
						obj.OnValueChanged = function(self, value)
							if not config.Precision then 
								value = math_floor(value) 
							elseif value < 0 then 
								value = config.MIN or -1
							end
							TMWdb.profile.ActionDB[tab.name][specID][config.DB] = value
							self.FontStringTitle:SetText(ONOFF(value))
						end
						obj.Identify = { Type = config.E, Toggle = config.DB }						
						obj.FontStringTitle = StdUi:Subtitle(obj, ONOFF(TMWdb.profile.ActionDB[tab.name][specID][config.DB]))
						obj.FontStringTitle:SetJustifyH("CENTER")						
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[CTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)						
					elseif config.E == "LayoutSpace" then	
						obj = LayoutSpace(anchor)
					end 
					
					local margin = config.ElementOptions and config.ElementOptions.margin or { top = 10 } 					
					SpecRow:AddElement(obj, { column = math_floor(12 / #Action.Data.ProfileUI[tab.name][specID][row]), margin = margin })
				end
			end
			
			-- Add some empty space after all elements 
			if #Action.Data.ProfileUI[tab.name][specID] > 12 then 
				for row = 1, 2 do 
					local SpecRow = anchor:AddRow()		
					local obj = LayoutSpace(anchor)
					SpecRow:AddElement(obj, { column = 12, margin = { top = 10 } })
				end 
			end 
			
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			

			anchor:DoLayout()	
		end 
		
		if tab.name == 3 then 
			if not Action[specID] then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 50 } })	
			local QLuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height - 3, "QLUA")
			QLuaButton.FontStringLUA = StdUi:Subtitle(QLuaButton, ActionDatatheme.off)
			local QLuaEditor = CreateLuaEditor(tab.childs[spec], "QUEUE " .. L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height - 3, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, ActionDatatheme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Key = StdUi:SimpleEditBox(tab.childs[spec], 150, ActionDatatheme.dd.height, "")							
			
			local hasdata = {}
			local function OnPairs(k, v, ToggleAutoHidden)
				if type(v) == "table" and not v.Hidden and v.Type and v.ID and v.Desc then  
					local Enabled = "True"
					if v:IsBlocked() then 
						Enabled = "False"
					end 
					
					local isShown = true 
					-- AutoHidden unavailable 
					if ToggleAutoHidden and v.ID ~= ACTION_CONST_PICKPOCKET then 								
						if v.Type == "SwapEquip" then 
							if not v:IsExists() then 
								isShown = false 
							end 
						elseif v.Type == "Spell" then 															
							if not v:IsExists() or v:IsBlockedBySpellLevel() then 
								isShown = false 
							end 
						else 
							if v.Type == "Trinket" then 
								if not v:GetEquipped() then 
									isShown = false 
								end 
							else 
								if v:GetCount() <= 0 or not v:GetEquipped() then 
									isShown = false 
								end 
							end								
						end 
					end 
					
					if isShown then 
						tinsert(hasdata, setmetatable({ 
							Enabled = Enabled, 				
							Name = v:Info(),
							Icon = v:Icon(),
							TableKeyName = k,
						}, { __index = Action[Action.PlayerSpec][k] or Action }))
					end 
				end
			end 
			local function ScrollTableActionsData()
				wipe(hasdata)
				local ToggleAutoHidden = Action.GetToggle(tab.name, "AutoHidden")
				if Action[Action.PlayerSpec] then 					
					for k, v in pairs(Action[Action.PlayerSpec]) do 
						OnPairs(k, v, ToggleAutoHidden)
					end
				end 
				for k, v in pairs(Action) do 
					OnPairs(k, v, ToggleAutoHidden)
				end
				return hasdata
			end
			local function ScrollTableUpdateData()
				local fspec = Action.PlayerSpec .. CL
				
				tab.childs[fspec].ScrollTable:SetData(ScrollTableActionsData())
				tab.childs[fspec].ScrollTable:SortData(tab.childs[fspec].ScrollTable.SORTBY)
			end 	
			local function ScrollTableUpdateSelection()
				local fspec = Action.PlayerSpec .. CL
				
				local index = tab.childs[fspec].ScrollTable:GetSelection()
				if not index then 
					Key:SetText("")
					Key:ClearFocus() 
				else 
					local data = tab.childs[fspec].ScrollTable:GetRow(index)
					if data then 
						if data.TableKeyName ~= Key:GetText() then 
							Key:SetText(data.TableKeyName)
						end 
					else 
						Key:SetText("")
						Key:ClearFocus() 
					end 
				end 
			end 
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					local luaCode = rowData:GetLUA() or ""
					LuaEditor.EditBox:SetText(luaCode)
					if luaCode and luaCode ~= "" then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 
					
					local QluaCode = rowData:GetQLUA() or ""
					QLuaEditor.EditBox:SetText(QluaCode)
					if QluaCode and QluaCode ~= "" then 
						QLuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						QLuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 					
					
					Key:SetText(rowData.TableKeyName)
					Key:ClearFocus()
					
					if columnData.index == "Enabled" then
						rowData:SetBlocker()
						tab.childs[spec].ScrollTable:ClearSelection()
					end 
				end 				
			end 
						
			tab.childs[spec].ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
                {
                    name = L["TAB"][tab.name]["ENABLED"],
                    width = 70,
                    align = "LEFT",
                    index = "Enabled",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "True" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "False" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = "ID",
                    width = 70,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 197,
					defaultwidth = 197,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["DESC"],
                    width = 90,
                    align = "LEFT",
                    index = "Desc",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)    							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)   							
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 15, 25)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						tab.childs[spec].ScrollTable.SORTBY = columnIndex
						Key:ClearFocus()	
					end	
				end, 
			}
			tab.childs[spec].ScrollTable:RegisterEvents(nil, headerEvents)
			tab.childs[spec].ScrollTable.SORTBY = 3
			tab.childs[spec].ScrollTable.defaultrows = { numberOfRows = tab.childs[spec].ScrollTable.numberOfRows, rowHeight = tab.childs[spec].ScrollTable.rowHeight }
            tab.childs[spec].ScrollTable:EnableSelection(true)  
			tab.childs[spec].ScrollTable:SetScript("OnShow", function(self)			
				ScrollTableUpdateData()
				ScrollTableUpdateSelection()
			end)
			
			-- AutoHidden update ScrollTable events 
			local EVENTS = {
				["UNIT_PET"] 						= true,
				--["PLAYER_LEVEL_UP"]				= true,
				["ACTIVE_TALENT_GROUP_CHANGED"]		= true,
				["BAG_UPDATE_DELAYED"]				= true,
				["PLAYER_EQUIPMENT_CHANGED"]		= true,
				["UI_INFO_MESSAGE"]					= true,
			}
			local function OnCallback()
				local fspec = Action.PlayerSpec .. CL
				if tab.childs[fspec].ScrollTable:IsVisible() and TMW.time ~= tab.childs[fspec].ScrollTable.ts and Action.GetToggle(tab.name, "AutoHidden") then 
					tab.childs[fspec].ScrollTable.ts = TMW.time
					ScrollTableUpdateData()
					ScrollTableUpdateSelection()
				end 
			end 
			
			local function EventsAndCallbacksInit() 
				if Action.GetToggle(tab.name, "AutoHidden") then 
					-- Registers events 
					for k in pairs(EVENTS) do 
						tab.childs[spec].ScrollTable:RegisterEvent(k)
					end 
					
					-- Registers callback (SpellLevel)
					TMW:RegisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", OnCallback, "TMW_ACTION_SPELL_BOOK_CHANGED_ACTIONS_TAB")
				else 
					-- Unregisters events 
					for k in pairs(EVENTS) do 
						tab.childs[spec].ScrollTable:UnregisterEvent(k)
					end 
					
					-- Unregisters callback 
					TMW:UnregisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", OnCallback, "TMW_ACTION_SPELL_BOOK_CHANGED_ACTIONS_TAB")
				end 
			end 	
			EventsAndCallbacksInit() 
			tab.childs[spec].ScrollTable.ts = 0
			tab.childs[spec].ScrollTable:SetScript("OnEvent", function(self, event, ...)
				if self:IsVisible() and TMW.time ~= self.ts and Action.GetToggle(tab.name, "AutoHidden") and EVENTS[event] then 
					self.ts = TMW.time
					
					-- Update ScrollTable 
					-- If pet has been gone or summoned or swaped
					if event == "UNIT_PET" then 
						if ... == "player" then 						
							ScrollTableUpdateData()
						end 
					-- If war mode has been changed 
					elseif event == "UI_INFO_MESSAGE" then 
						if Action.UI_INFO_MESSAGE_IS_WARMODE(...) then 
							ScrollTableUpdateData()
						end
					-- If items/talents have been updated 
					else 		
						ScrollTableUpdateData()
					end 
					
					ScrollTableUpdateSelection()
				end  
			end)
			
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then
				ScrollTableUpdateData()
				ScrollTableUpdateSelection()
			end 
					
			Key:SetJustifyH("CENTER")
			Key.FontString = StdUi:Subtitle(Key, L["TAB"]["KEY"]) 
			Key:SetScript("OnTextChanged", function(self)
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					return
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)						
					if data and data.TableKeyName ~= self:GetText() then 
						self:SetText(data.TableKeyName)
					end 
				end 
            end)
			Key:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)	
			StdUi:GlueAbove(Key.FontString, Key)		
			StdUi:FrameTooltip(Key, L["TAB"][tab.name]["KEYTOOLTIP"], nil, "TOP", true)			
			
			local AutoHidden = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["AUTOHIDDEN"])		
			AutoHidden:SetChecked(TMWdb.profile.ActionDB[tab.name].AutoHidden)
			AutoHidden:RegisterForClicks("LeftButtonUp")
			AutoHidden.ToggleTable = {tab.name, "AutoHidden", L["TAB"][tab.name]["AUTOHIDDEN"] .. ": "}
			AutoHidden:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 
						Action.SetToggle(self.ToggleTable)
						ScrollTableUpdateData()
						ScrollTableUpdateSelection()	
						EventsAndCallbacksInit()
					end 
				end 
			end)
			AutoHidden.Identify = { Type = "Checkbox", Toggle = "AutoHidden" }
			StdUi:FrameTooltip(AutoHidden, L["TAB"][tab.name]["AUTOHIDDENTOOLTIP"], nil, "TOP", true)	
			
			local CheckSpellLevel = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["CHECKSPELLLVL"])		
			CheckSpellLevel:SetChecked(TMWdb.profile.ActionDB[tab.name].CheckSpellLevel)
			CheckSpellLevel:RegisterForClicks("LeftButtonUp")
			CheckSpellLevel:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 	
						SpellLevel:Initialize()
						ScrollTableUpdateData()
					end 
				end 
			end)
			CheckSpellLevel:SetScript("OnShow", function(self)
				if UnitLevel("player") >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] then 
					if self.isChecked then 
						self:Click("LeftButton")
					end 
					self:Disable()
				else 
					self:Enable()
				end 
			end)
			CheckSpellLevel.Identify = { Type = "Checkbox", Toggle = "CheckSpellLevel" }
			StdUi:FrameTooltip(CheckSpellLevel, L["TAB"][tab.name]["CHECKSPELLLVLTOOLTIP"], nil, "TOP", true)		
			
			local SetBlocker = StdUi:Button(tab.childs[spec], tab.childs[spec]:GetWidth() / 2 - 22, 30, L["TAB"][tab.name]["SETBLOCKER"])
			SetBlocker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetBlocker:SetScript("OnClick", function(self, button, down)
				local spec = specID .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)
					if button == "LeftButton" then 
						data:SetBlocker()						
					elseif button == "RightButton" then 						
						CraftMacro("Block: " .. data.TableKeyName, [[#showtooltip ]] .. data:Info() .. "\n" .. [[/run Action.MacroBlocker("]] .. data.TableKeyName .. [[")]], 1, true, true)	
					end
				end 
			end)			         
            StdUi:FrameTooltip(SetBlocker, L["TAB"][tab.name]["SETBLOCKERTOOLTIP"], nil, "TOPRIGHT", true)
			
			local SetQueue = StdUi:Button(tab.childs[spec], tab.childs[spec]:GetWidth() / 2 - 22, 30, L["TAB"][tab.name]["SETQUEUE"])
			SetQueue:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetQueue:SetScript("OnClick", function(self, button, down)
				local spec = specID .. CL
				local index = tab.childs[spec].ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
				else 
					local data = tab.childs[spec].ScrollTable:GetRow(index)
					if data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not GetItemSpell(data.ID)) then 
						Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"])
					-- I decided unlocked Queue for blocked actions
					--elseif data:IsBlocked() and not data.Queued then 
						--Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"])
					else
						if button == "LeftButton" then 	
							Action.MacroQueue(data.TableKeyName, { Priority = 1 })							
						elseif button == "RightButton" then 						
							CraftMacro("Queue: " .. data.TableKeyName, [[#showtooltip ]] .. data:Info() .. "\n" .. [[/run Action.MacroQueue("]] .. data.TableKeyName .. [[", { Priority = 1 })]], 1, true, true)	
						end
					end 
				end 
			end)			         
            StdUi:FrameTooltip(SetQueue, L["TAB"][tab.name]["SETQUEUETOOLTIP"], nil, "TOPLEFT", true)		
			
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(tab.childs[spec].ScrollTable)
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(Key)
			tab.childs[spec]:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(AutoHidden)
			tab.childs[spec]:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(CheckSpellLevel)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(SetBlocker, SetQueue, { column = "even" })
			tab.childs[spec]:DoLayout()
			
			-- Action LUA 
			LuaButton:SetScript("OnClick", function()		
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
					return 
				end 
				
				if not LuaEditor:IsShown() then 
					local fspec = specID .. CL
					local index = tab.childs[fspec].ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
					else 				
						LuaEditor:Show()
					end 
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(LuaButton, SetQueue, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, 0, 0)

			LuaEditor:HookScript("OnHide", function(self)
				local fspec = specID .. CL
				local index = tab.childs[fspec].ScrollTable:GetSelection()
				local data = index and tab.childs[fspec].ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = GetTableKeyIdentify(data)
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetLUA() ~= luaCode
					
					data:SetLUA(luaCode)
					if data:GetLUA() then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
						if isChanged then 
							Action.Print(L["TAB"][tab.name]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)	
						if isChanged then 
							Action.Print(L["TAB"][tab.name]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)
			
			-- Queue LUA
			QLuaButton:SetScript("OnClick", function()		
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
					return 
				end 
				
				if not QLuaEditor:IsShown() then 
					local fspec = specID .. CL
					local index = tab.childs[fspec].ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tab.name]["SELECTIONERROR"]) 
					else 		
						local data = tab.childs[fspec].ScrollTable:GetRow(index)
						if not data:GetQLUA() and (data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not GetItemSpell(data.ID))) then 
							Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. " " .. L["TAB"][3]["KEY"] .. data.TableKeyName .. "]")
						else 
							QLuaEditor:Show()
						end 
					end 
				else 
					QLuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(QLuaButton, LuaButton, 0, 0)
			StdUi:GlueLeft(QLuaButton.FontStringLUA, QLuaButton, 0, 0)

			QLuaEditor:HookScript("OnHide", function(self)
				local fspec = specID .. CL
				local index = tab.childs[fspec].ScrollTable:GetSelection()
				local data = index and tab.childs[fspec].ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = GetTableKeyIdentify(data)
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetQLUA() ~= luaCode
					
					data:SetQLUA(luaCode)
					if data:GetQLUA() then 
						QLuaButton.FontStringLUA:SetText(ActionDatatheme.on)
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tab.name]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						QLuaButton.FontStringLUA:SetText(ActionDatatheme.off)	
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tab.name]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)			
			
			hooksecurefunc(tab.childs[spec].ScrollTable, "ClearSelection", function()				
				LuaEditor.EditBox:SetText("")
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
				end 
				
				QLuaEditor.EditBox:SetText("")
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
				end 				
			end)
		end 
		
		if tab.name == 4 then					
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])			

			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 50 } })
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 145, L["TAB"][tab.name]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local KickHealOnlyHealers = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKHEALONLYHEALER"])
			local KickPvPOnlySmart = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKPVPONLYSMART"]) 
			local KickHeal = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKHEAL"])
			local KickPvP = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKPVP"])			
			local KickTargetMouseover = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["KICKTARGETMOUSEOVER"])
			local useKick = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEKICK"])
			local useCC = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USECC"])
			local useRacial = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USERACIAL"])
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["SEARCH"])
			local How = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], value = "GLOBAL" },				
				{ text = L["TAB"]["ALLSPECS"], value = "ALLSPECS" },
			}, "ALLSPECS")
			local TargetMouseoverList = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["TARGETMOUSEOVERLIST"])
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, ActionDatatheme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, ActionDatatheme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Add = StdUi:Button(tab.childs[spec], InputBox:GetWidth(), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], InputBox:GetWidth(), 25, L["TAB"][tab.name]["REMOVE"])					
			local InterruptUnits = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), ActionDatatheme.dd.height, {
				{ text = "BlackList", value = "BlackList" },
				{ text = "[Main]PvE: @target / @mouseover / @targettarget", value = "PvETargetMouseover" },
				{ text = "[Main]PvP: @target / @mouseover / @targettarget", value = "PvPTargetMouseover" },				
				{ text = "[Heal] @arena1-3", value = "Heal" },				
				{ text = "[PvP] @arena1-3", value = "PvP" },
			}, (Action.IsInPvP and "PvP" or "PvE") .. "TargetMouseover")	
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 
					InputBox:SetNumber(rowData.ID)
					InputBox.val = rowData.ID 
					InputBox:ClearFocus()					
					useKick:SetChecked(		(columnData.index == "useKickIndex" 	and not rowData.useKick) 	or (columnData.index ~= "useKickIndex" 		and rowData.useKick)	)
					useCC:SetChecked(		(columnData.index == "useCCIndex" 		and not rowData.useCC) 		or (columnData.index ~= "useCCIndex" 		and rowData.useCC)		)
					useRacial:SetChecked(	(columnData.index == "useRacialIndex" 	and not rowData.useRacial) 	or (columnData.index ~= "useRacialIndex" 	and rowData.useRacial)	)
					if columnData.index == "useKickIndex" or columnData.index == "useCCIndex" or columnData.index == "useRacialIndex" then 
						Action.Print(Action.GetSpellLink(rowData.ID) .. " " .. columnData.name .. ": ", not rowData[columnData.index:gsub("Index", "")])
						Add:Click()
						tab.childs[spec].RefferenceScrollTable:ClearSelection()
					end 
				end 				
			end 
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
                {
                    name = L["TAB"][tab.name]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 172,
					defaultwidth = 172,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnClick = OnClickCell,
					},
                },
                {
                    name = L["TAB"][tab.name]["USEKICK"],
                    width = 65,
                    align = "CENTER",
                    index = "useKickIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["USECC"],
                    width = 65,
                    align = "CENTER",
                    index = "useCCIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["USERACIAL"],
                    width = 65,
                    align = "CENTER",
                    index = "useRacialIndex",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return { r = 0, g = 1, b = 0, a = 1 }
                        end
                        if value == "OFF" then
                            return { r = 1, g = 0, b = 0, a = 1 }
                        end
                    end,
					events = {
						OnClick = OnClickCell,
					},
                },
				{
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, "Spell")       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 9, 25)			
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						InputBox:ClearFocus()	
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)	
			-- For refference
			tab.childs[spec].RefferenceScrollTable = ScrollTable
			
			local function Reset()
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(ActionDatatheme.off)	
				useKick:SetChecked(false)
				useCC:SetChecked(false)
				useRacial:SetChecked(false)
			end 
			local function ScrollTableInterruptData(InterruptUnits)
				local data = {}
				for k, v in pairs(TMWdb.profile.ActionDB[4][InterruptUnits][GameLocale]) do 
					if v.Enabled then 
						local useKickIndex, useCCIndex, useRacialIndex = v.useKick, v.useCC, v.useRacial
						useKickIndex 	= useKickIndex 		and "ON" or "OFF"
						useCCIndex 		= useCCIndex 		and "ON" or "OFF"
						useRacialIndex 	= useRacialIndex 	and "ON" or "OFF"
						tinsert(data, setmetatable({ 									
								Name 			= k,
								Icon 			= select(3, Action.GetSpellInfo(v.ID)),	
								useKickIndex 	= useKickIndex,
								useCCIndex 		= useCCIndex,
								useRacialIndex 	= useRacialIndex,
							}, {__index = v}))
					end 
				end
				return data
			end
			local function ScrollTableUpdate()
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableInterruptData(InterruptUnits:GetValue()))					
				ScrollTable:SortData(ScrollTable.SORTBY)			
			end 	
			local function CheckboxsUpdate()				
				local val = InterruptUnits:GetValue()			
				
				if val == "BlackList" then 
					-- TargetMouseover
					if not KickTargetMouseover.isDisabled then KickTargetMouseover:Disable() end 
					if not TargetMouseoverList.isDisabled then TargetMouseoverList:Disable() end 
					-- Heal
					if not KickHeal.isDisabled then KickHeal:Disable() end 
					if not KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Disable() end
					-- PvP 
					if not KickPvP.isDisabled then KickPvP:Disable() end 
					if not KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Disable() end 
					-- Disable use checkboxs
					useKick:SetChecked(false)
					useCC:SetChecked(false)
					useRacial:SetChecked(false)
					if not useKick.isDisabled then useKick:Disable() end 
					if not useCC.isDisabled then useCC:Disable() end 
					if not useRacial.isDisabled then useRacial:Disable() end 
				else 
					-- Enable use checkboxs 
					if useKick.isDisabled then useKick:Enable() end 
					if useCC.isDisabled then useCC:Enable() end 
					if useRacial.isDisabled then useRacial:Enable() end 
				end 
				
				if val:match("TargetMouseover") then 
					if KickTargetMouseover.isDisabled then KickTargetMouseover:Enable() end
					if Action.InterruptIsON("TargetMouseover") then 
						if TargetMouseoverList.isDisabled then TargetMouseoverList:Enable() end 
					elseif not TargetMouseoverList.isDisabled then 
						TargetMouseoverList:Disable()
					end 
				else 
					if not KickTargetMouseover.isDisabled then KickTargetMouseover:Disable() end 
					if not TargetMouseoverList.isDisabled then TargetMouseoverList:Disable() end 
				end
				
				if val == "Heal" then 
					if KickHeal.isDisabled then KickHeal:Enable() end 
					if Action.InterruptIsON(val) then
						if KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Enable() end 
					elseif not KickHealOnlyHealers.isDisabled then 
						KickHealOnlyHealers:Disable()						
					end 
				else 
					if not KickHeal.isDisabled then KickHeal:Disable() end 
					if not KickHealOnlyHealers.isDisabled then KickHealOnlyHealers:Disable() end
				end 
				
				if val == "PvP" then 
					if KickPvP.isDisabled then KickPvP:Enable() end 
					if Action.InterruptIsON(val) then
						if KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Enable() end
					elseif not KickPvPOnlySmart.isDisabled then  
						KickPvPOnlySmart:Disable()
					end 
				else 
					if not KickPvP.isDisabled then KickPvP:Disable() end 
					if not KickPvPOnlySmart.isDisabled then KickPvPOnlySmart:Disable() end 
				end
				
			end 		
			
			InterruptUnits.OnValueChanged = function(self, val)   
				ScrollTableUpdate()	
				CheckboxsUpdate()				
			end	
			StdUi:FrameTooltip(InterruptUnits, L["TAB"][tab.name]["INTERRUPTTOOLTIP"], nil, "TOP", true)		
			InterruptUnits.FontStringTitle = StdUi:Subtitle(InterruptUnits, L["TAB"][tab.name]["INTERRUPTFRONTSTRINGTITLE"])
			StdUi:GlueAbove(InterruptUnits.FontStringTitle, InterruptUnits)	
			InterruptUnits.text:SetJustifyH("CENTER")			

			Add:SetScript("OnClick", function(self, button, down)	
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local SpellID = InputBox.val
				local Name = Action.GetSpellInfo(SpellID)	
				if not SpellID or Name == nil or Name == "" or SpellID <= 1 then 
					Action.Print(L["TAB"][tab.name]["ADDERROR"]) 
				else 
					local InterruptList = InterruptUnits:GetValue()
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					
					local Kick, CC, Racial = useKick:GetChecked(), useCC:GetChecked(), useRacial:GetChecked()
					
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] and profile.ActionDB[tab.name][InterruptList] and profile.ActionDB[tab.name][InterruptList][GameLocale] then 	
								profile.ActionDB[tab.name][InterruptList][GameLocale][Name] = { Enabled = true, ID = SpellID, Name = Name, LUA = CodeLua, useKick = Kick, useCC = CC, useRacial = Racial }
							end 
						end 					
					elseif HowTo == "ALLSPECS" then 
						TMWdb.profile.ActionDB[tab.name][InterruptList][GameLocale][Name] = { Enabled = true, ID = SpellID, Name = Name, LUA = CodeLua, useKick = Kick, useCC = CC, useRacial = Racial }
					end 					

					ScrollTableUpdate()	
					InputBox:ClearFocus()
					InputBox:SetText("")
					InputBox.val = ""
					-- Clear checkboxs 
					useKick:SetChecked(false)
					useCC:SetChecked(false)
					useRacial:SetChecked(false)
				end 
			end)          
            StdUi:FrameTooltip(Add, L["TAB"][tab.name]["ADDTOOLTIP"], nil, "TOPRIGHT", true)		
		
			Remove:SetScript("OnClick", function(self, button, down)
				Reset()
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local InterruptList = InterruptUnits:GetValue()					
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] and profile.ActionDB[tab.name][InterruptList] and profile.ActionDB[tab.name][InterruptList][GameLocale] then 
								if Factory[tab.name][InterruptList][GameLocale][data.ID] and profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] then 
									profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name].Enabled = false
								else 
									profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] = nil
								end 														
							end 
						end 
					elseif HowTo == "ALLSPECS" then 
						if Factory[tab.name][InterruptList][GameLocale][data.ID] then 
							TMWdb.profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name].Enabled = false
						else 
							TMWdb.profile.ActionDB[tab.name][InterruptList][GameLocale][data.Name] = nil
						end 	
					end 
					ScrollTableUpdate()					
				end 
			end)           
            StdUi:FrameTooltip(Remove, L["TAB"][tab.name]["REMOVETOOLTIP"], nil, "TOPLEFT", true)				
								
            InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""
							self:SetNumber(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][tab.name]["INTEGERERROR"]) 
							return 
						end 
						ShowTooltip(self, true, self.val, "Spell") 
					else 
						ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = ConvertSpellNameToID(text)
							ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                ShowTooltip(self, false)
				Add:Click()                
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                ShowTooltip(self, false)
				self.val = ""
				self:SetNumber("")
				self:ClearFocus() 
            end)			
			InputBox:HookScript("OnHide", function(self)
				ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tab.name]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][tab.name]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)		

			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:Subtitle(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)	
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)				
			
			KickPvP:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickPvP)
			KickPvP:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickPvP:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].KickPvP = not TMWdb.profile.ActionDB[tab.name][specID].KickPvP	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickPvP)	
						Action.Print(L["TAB"][tab.name]["KICKPVPPRINT"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].KickPvP)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKPVPPRINT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickPvP", "]] .. L["TAB"][tab.name]["KICKPVPPRINT"] .. [[: "})]])	
					end 
				end 
			end)
			KickPvP.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickPvP.Identify = { Type = "Checkbox", Toggle = "KickPvP" }				
			StdUi:FrameTooltip(KickPvP, L["TAB"][tab.name]["KICKPVPTOOLTIP"], nil, "TOPRIGHT", true)	
			
			KickHeal:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickHeal)
			KickHeal:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickHeal:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].KickHeal = not TMWdb.profile.ActionDB[tab.name][specID].KickHeal	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickHeal)	
						Action.Print(L["TAB"][tab.name]["KICKHEALPRINT"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].KickHeal)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKHEALPRINT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickHeal", "]] .. L["TAB"][tab.name]["KICKHEALPRINT"] .. [[: "})]])	
					end 
				end
			end)
			KickHeal.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickHeal.Identify = { Type = "Checkbox", Toggle = "KickHeal" }					
			StdUi:FrameTooltip(KickHeal, L["TAB"][tab.name]["KICKHEALTOOLTIP"], nil, "TOP", true)				
			
			TargetMouseoverList:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].TargetMouseoverList)	
			TargetMouseoverList:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			TargetMouseoverList:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].TargetMouseoverList = not TMWdb.profile.ActionDB[tab.name][specID].TargetMouseoverList	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].TargetMouseoverList)	
						Action.Print(L["TAB"][tab.name]["TARGETMOUSEOVERLIST"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].TargetMouseoverList)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["TARGETMOUSEOVERLIST"], [[/run Action.SetToggle({]] .. tab.name .. [[, "TargetMouseoverList", "]] .. L["TAB"][tab.name]["TARGETMOUSEOVERLIST"] .. [[: "})]])	
					end 
				end
			end)
			TargetMouseoverList.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()				
			end
			TargetMouseoverList.Identify = { Type = "Checkbox", Toggle = "TargetMouseoverList" }			
			StdUi:FrameTooltip(TargetMouseoverList, L["TAB"][tab.name]["TARGETMOUSEOVERLISTTOOLTIP"], nil, "TOPLEFT", true)	
			
			KickPvPOnlySmart:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickPvPOnlySmart)
			KickPvPOnlySmart:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickPvPOnlySmart:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].KickPvPOnlySmart = not TMWdb.profile.ActionDB[tab.name][specID].KickPvPOnlySmart	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickPvPOnlySmart)	
						Action.Print(L["TAB"][tab.name]["KICKPVPONLYSMART"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].KickPvPOnlySmart)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKPVPONLYSMART"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickPvPOnlySmart", "]] .. L["TAB"][tab.name]["KICKPVPONLYSMART"] .. [[: "})]])	
					end 
				end 
			end)
			KickPvPOnlySmart.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickPvPOnlySmart.Identify = { Type = "Checkbox", Toggle = "KickPvPOnlySmart" }						
			StdUi:FrameTooltip(KickPvPOnlySmart, L["TAB"][tab.name]["KICKPVPONLYSMARTTOOLTIP"], nil, "TOPRIGHT", true)												

			KickHealOnlyHealers:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickHealOnlyHealers)
			KickHealOnlyHealers:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickHealOnlyHealers:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].KickHealOnlyHealers = not TMWdb.profile.ActionDB[tab.name][specID].KickHealOnlyHealers	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickHealOnlyHealers)	
						Action.Print(L["TAB"][tab.name]["KICKHEALONLYHEALER"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].KickHealOnlyHealers)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKHEALONLYHEALER"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickHealOnlyHealers", "]] .. L["TAB"][tab.name]["KICKHEALONLYHEALER"] .. [[: "})]])	
					end
				end 
			end)
			KickHealOnlyHealers.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()
			end
			KickHealOnlyHealers.Identify = { Type = "Checkbox", Toggle = "KickHealOnlyHealers" }				
			StdUi:FrameTooltip(KickHealOnlyHealers, L["TAB"][tab.name]["KICKHEALONLYHEALERTOOLTIP"], nil, "TOP", true)		

			KickTargetMouseover:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickTargetMouseover)
			KickTargetMouseover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			KickTargetMouseover:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then
					InputBox:ClearFocus()
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].KickTargetMouseover = not TMWdb.profile.ActionDB[tab.name][specID].KickTargetMouseover	
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].KickTargetMouseover)	
						Action.Print(L["TAB"][tab.name]["KICKTARGETMOUSEOVER"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].KickTargetMouseover)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["KICKTARGETMOUSEOVER"], [[/run Action.SetToggle({]] .. tab.name .. [[, "KickTargetMouseover", "]] .. L["TAB"][tab.name]["KICKTARGETMOUSEOVER"] .. [[: "})]])	
					end 
				end
			end)
			KickTargetMouseover.OnValueChanged = function(self, state, val)
				CheckboxsUpdate()				
			end
			KickTargetMouseover.Identify = { Type = "Checkbox", Toggle = "KickTargetMouseover" }			
			StdUi:FrameTooltip(KickTargetMouseover, L["TAB"][tab.name]["KICKTARGETMOUSEOVERTOOLTIP"], nil, "TOPLEFT", true)
			          		
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				CheckboxsUpdate()
				Reset()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
				CheckboxsUpdate()
				Reset()
			end 
						
			tab.childs[spec]:AddRow({ margin = { top = -8, left = -15, right = -15 } }):AddElement(InterruptUnits)
			tab.childs[spec]:AddRow({ margin = { top = 15, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -20, left = -10, right = -10 } }):AddElements(KickPvPOnlySmart, KickHealOnlyHealers, KickTargetMouseover, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = -10, left = -10, right = -10 } }):AddElements(KickPvP, KickHeal, TargetMouseoverList, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:AddRow({ margin = { top = -10, left = -10, right = -10 } }):AddElements(useKick, useCC, useRacial, { column = "even" })
			ConfigPanel:DoLayout()		
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()

			ResetConfigPanel:SetScript("OnClick", Reset)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")			
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
				else 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				end 
			end)
		end 
		
		if tab.name == 5 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])							
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 10 } })
			
			local function GetCategory()
				local cct = {		
					{ text = "BlackList", value = "BlackList" },
					{ text = L["TAB"][tab.name]["POISON"], value = "Poison" },				
					{ text = L["TAB"][tab.name]["DISEASE"], value = "Disease" },
					{ text = L["TAB"][tab.name]["CURSE"], value = "Curse" },				
					{ text = L["TAB"][tab.name]["MAGIC"], value = "Magic" },
					{ text = L["TAB"][tab.name]["MAGICMOVEMENT"], value = "MagicMovement" },				
					{ text = L["TAB"][tab.name]["PURGEFRIENDLY"], value = "PurgeFriendly" },
					{ text = L["TAB"][tab.name]["PURGEHIGH"], value = "PurgeHigh" },				
					{ text = L["TAB"][tab.name]["PURGELOW"], value = "PurgeLow" },
					{ text = L["TAB"][tab.name]["ENRAGE"], value = "Enrage" },				
				}
				if Action.PlayerClass == "PALADIN" then 
					tinsert(cct, { text = L["TAB"][tab.name]["BLESSINGOFPROTECTION"], value = "BlessingofProtection" })
					tinsert(cct, { text = L["TAB"][tab.name]["BLESSINGOFFREEDOM"], value = "BlessingofFreedom" })
					tinsert(cct, { text = L["TAB"][tab.name]["BLESSINGOFSACRIFICE"], value = "BlessingofSacrifice" })
					tinsert(cct, { text = L["TAB"][tab.name]["BLESSINGOFSANCTUARY"], value = "BlessingofSanctuary" })
				end 
				return cct
			end 
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 50, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseDispel = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEDISPEL"])
			local UsePurge = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEPURGE"])	
			local UseExpelEnrage = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USEEXPELENRAGE"])
			local Mode = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), ActionDatatheme.dd.height, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), ActionDatatheme.dd.height, GetCategory(), "Magic")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 140, L["TAB"][tab.name]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { gutter = 0, padding = { top = 40 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, ActionDatatheme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, ActionDatatheme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Role = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tab.name]["ANY"], value = "ANY" },				
				{ text = L["TAB"][tab.name]["HEALER"], value = "HEALER" },
				{ text = L["TAB"][tab.name]["DAMAGER"], value = "DAMAGER" },
			}, "ANY")
			local Duration = StdUi:EditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, 0)
			local Stack = StdUi:NumericBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, 0)			
			local ByID = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["BYID"])
			local canStealOrPurge = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["CANSTEALORPURGE"])	
			local onlyBear = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["ONLYBEAR"])	
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12, 15), 20, L["TAB"][4]["SEARCH"])						
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["REMOVE"])

			local function ClearAllEditBox(clearInput)
				if clearInput then 
					InputBox:SetNumber("")
				end
				InputBox:ClearFocus()
				Duration:ClearFocus()
				Stack:ClearFocus()
			end 
			
			-- [ScrollTable] BEGIN			
			local function ShowCellTooltip(parent, show, data)
				if show == "Hide" then 
					GameTooltip:Hide()
				else 
					GameTooltip:SetOwner(parent)				
					if show == "Role" then
						GameTooltip:SetText(L["TAB"][tab.name]["ROLETOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Dur" then 
						GameTooltip:SetText(L["TAB"][tab.name]["DURATIONTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Stack" then 
						GameTooltip:SetText(L["TAB"][tab.name]["STACKSTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)					
					end 
				end
			end 
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 
					Role:SetValue(rowData.Role)
					Duration:SetNumber(rowData.Dur)
					Stack:SetNumber(rowData.Stack)
					ByID:SetChecked(rowData.byID)
					canStealOrPurge:SetChecked(rowData.canStealOrPurge)
					onlyBear:SetChecked(rowData.onlyBear)
					InputBox:SetNumber(rowData.ID)					
					ClearAllEditBox()
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["ROLE"],
                    width = 70,
                    align = "LEFT",
                    index = "RoleLocale",
                    format = "string",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Role")   							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")    							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number", 
					events = {                        
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 167,
					defaultwidth = 167,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["DURATION"],
                    width = 80,
                    align = "LEFT",
                    index = "Dur",
                    format = "number",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Dur")   							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide") 							
                        end,
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["STACKS"],
                    width = 50,
                    align = "LEFT",
                    index = "Stack",
                    format = "number", 
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Stack")      						
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")  							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, "Spell")  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 7, 30)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						ClearAllEditBox()	
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 3
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				DispelPurgeEnrageRemap()
				local CategoryValue = Category:GetValue()
				local ModeValue = Mode:GetValue()
				local data = {}
				for k, v in pairs(ActionDataAuras[ModeValue][CategoryValue]) do 
					if v.Enabled then 
						v.Icon = select(3, Action.GetSpellInfo(v.ID))
						v.RoleLocale = L["TAB"][tab.name][v.Role]
						tinsert(data, v)
					end 
				end
				return data
			end 
			local function ScrollTableUpdate()
				ClearAllEditBox(true)
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END 
			
			UseDispel:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseDispel)
			UseDispel:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseDispel:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].UseDispel = not TMWdb.profile.ActionDB[tab.name][specID].UseDispel
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseDispel)	
						Action.Print(L["TAB"][tab.name]["USEDISPEL"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].UseDispel)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEDISPEL"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseDispel", "]] .. L["TAB"][tab.name]["USEDISPEL"] .. [[: "})]])	
					end
				end 
			end)
			UseDispel.Identify = { Type = "Checkbox", Toggle = "UseDispel" }
			StdUi:FrameTooltip(UseDispel, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			if not ActionDataAuras.DisableCheckboxes[specID] or ActionDataAuras.DisableCheckboxes[specID].UseDispel then 
				UseDispel:Disable()
			end 
	
			UsePurge:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UsePurge)
			UsePurge:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UsePurge:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].UsePurge = not TMWdb.profile.ActionDB[tab.name][specID].UsePurge
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UsePurge)	
						Action.Print(L["TAB"][tab.name]["USEPURGE"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].UsePurge)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEPURGE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UsePurge", "]] .. L["TAB"][tab.name]["USEPURGE"] .. [[: "})]])	
					end 
				end
			end)
			UsePurge.Identify = { Type = "Checkbox", Toggle = "UsePurge" }
			StdUi:FrameTooltip(UsePurge, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOP", true)	
			if not ActionDataAuras.DisableCheckboxes[specID] or ActionDataAuras.DisableCheckboxes[specID].UsePurge then 
				UsePurge:Disable()
			end 			

			UseExpelEnrage:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseExpelEnrage)
			UseExpelEnrage:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseExpelEnrage:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].UseExpelEnrage = not TMWdb.profile.ActionDB[tab.name][specID].UseExpelEnrage
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseExpelEnrage)	
						Action.Print(L["TAB"][tab.name]["USEEXPELENRAGE"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].UseExpelEnrage)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["USEEXPELENRAGE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseExpelEnrage", "]] .. L["TAB"][tab.name]["USEEXPELENRAGE"] .. [[: "})]])	
					end 
				end
			end)
			UseExpelEnrage.Identify = { Type = "Checkbox", Toggle = "UseExpelEnrage" }	
			StdUi:FrameTooltip(UseExpelEnrage, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)	
			if not ActionDataAuras.DisableCheckboxes[specID] or ActionDataAuras.DisableCheckboxes[specID].UseExpelEnrage then 
				UseExpelEnrage:Disable()
			end 
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:Subtitle(Mode, L["TAB"][tab.name]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", ClearAllEditBox)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:Subtitle(Category, L["TAB"][tab.name]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", ClearAllEditBox)
								
			Role.text:SetJustifyH("CENTER")
			Role.FontStringTitle = StdUi:Subtitle(Role, L["TAB"][tab.name]["ROLE"])
			Role:HookScript("OnClick", ClearAllEditBox)			
			StdUi:FrameTooltip(Role, L["TAB"][tab.name]["ROLETOOLTIP"], nil, "TOPRIGHT", true)
			StdUi:GlueAbove(Role.FontStringTitle, Role)	
			
			Duration:SetJustifyH("CENTER")
			Duration:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Duration:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Duration:SetScript("OnTextChanged", function(self)
				local val = self:GetText():gsub("[^%d%.]", "")
				self:SetNumber(val)
			end)
			Duration:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()				
				if text == nil or text == "" or not text:find("%d") or text:sub(1, 1) == "." or (text:len() > 1 and text:sub(1, 1) == "0" and not text:find("%.")) then 
					self:SetNumber(0)
				elseif text:sub(-1) == "." then 
					self:SetNumber(text:gsub("%.", ""))
				end 
			end)
			local Font = strgsub(strgsub(L["TAB"][tab.name]["DURATION"], "\n", ""), "-", "")
			Duration.FontStringTitle = StdUi:Subtitle(Duration, Font)			
			StdUi:FrameTooltip(Duration, L["TAB"][tab.name]["DURATIONTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(Duration.FontStringTitle, Duration)	
						
            Stack:SetMaxValue(1000)
            Stack:SetMinValue(0)
			Stack:SetJustifyH("CENTER")
			Stack:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Stack:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Stack:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()	
				if text == nil or text == "" then 
					self:SetNumber(0)
				end 
			end)
			local Font = strgsub(L["TAB"][tab.name]["STACKS"], "\n", "")
			Stack.FontStringTitle = StdUi:Subtitle(Stack, Font)			
			StdUi:FrameTooltip(Stack, L["TAB"][tab.name]["STACKSTOOLTIP"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Stack.FontStringTitle, Stack)						
													
			StdUi:FrameTooltip(ByID, L["TAB"][tab.name]["BYIDTOOLTIP"], nil, "BOTTOMRIGHT", true)	
			ByID:HookScript("OnClick", ClearAllEditBox)			
			canStealOrPurge:HookScript("OnClick", ClearAllEditBox)						
			onlyBear:HookScript("OnClick", ClearAllEditBox)
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""
							self:SetNumber(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][4]["INTEGERERROR"]) 
							return 
						end 
						ShowTooltip(self, true, self.val, "Spell") 
					else 
						ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = ConvertSpellNameToID(text)
							ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                ShowTooltip(self, false)
				Add:Click()				              
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                ShowTooltip(self, false)
				InputBox:ClearFocus()
            end)
			InputBox:HookScript("OnHide", function(self)
				ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][4]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local SpellID = InputBox.val
				local Name = Action.GetSpellInfo(SpellID)	
				if not SpellID or Name == nil or Name == "" or SpellID <= 1 then 
					Action.Print(L["TAB"][4]["ADDERROR"]) 
				else
					local M = Mode:GetValue()
					local C = Category:GetValue()
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					-- Prevent overwrite by next time loading if user applied own changes 
					local LUAVER 
					if TMWdb.global.ActionDB[tab.name][M][C][SpellID] then 
						LUAVER = TMWdb.global.ActionDB[tab.name][M][C][SpellID].LUAVER 
					end 
									
					TMWdb.global.ActionDB[tab.name][M][C][SpellID] = { 
						ID = SpellID, 
						Name = Name, 
						enabled = true,
						role = Role:GetValue(),
						dur = round(tonumber(Duration:GetNumber()), 3) or 0,
						stack = Stack:GetNumber() or 0,
						byID = ByID:GetChecked(),
						canStealOrPurge = canStealOrPurge:GetChecked(),
						onlyBear = onlyBear:GetChecked(),
						LUA = CodeLua,
						LUAVER = LUAVER,
					}
					ScrollTableUpdate()						
				end 
			end)         
            StdUi:FrameTooltip(Add, L["TAB"][4]["ADDTOOLTIP"], nil, "TOPRIGHT", true)		

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)	
					if GlobalFactory[tab.name][Mode:GetValue()][Category:GetValue()][data.ID] then 
						TMWdb.global.ActionDB[tab.name][Mode:GetValue()][Category:GetValue()][data.ID].enabled = false						
					else 
						TMWdb.global.ActionDB[tab.name][Mode:GetValue()][Category:GetValue()][data.ID] = nil
					end 					
					ScrollTableUpdate()					
				end 
			end)            
            StdUi:FrameTooltip(Remove, L["TAB"][4]["REMOVETOOLTIP"], nil, "TOPLEFT", true)							          
				
			tab.childs[spec]:AddRow({ margin = { top = -4, left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(UseDispel, UsePurge, UseExpelEnrage, { column = "even" })
			UsePanel:DoLayout()	
			tab.childs[spec]:AddRow({ margin = { top = -5 } }):AddElement(UI_Title)			
			tab.childs[spec]:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			tab.childs[spec]:AddRow({ margin = { top = 18, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)
			ConfigPanel:AddRow():AddElements(Role, Duration, Stack, { column = "even" })						
			ConfigPanel:AddRow({ margin = { top = -10 } }):AddElements(ByID, canStealOrPurge, onlyBear, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = 5 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			UI_Title:SetJustifyH("CENTER")
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				Role:SetValue("ANY")
				Duration:SetNumber(0)
				Stack:SetNumber(0)
				ByID:SetChecked(false)
				canStealOrPurge:SetChecked(false)
				onlyBear:SetChecked(false)
				InputBox.val = ""
				InputBox:SetNumber("")					
				ClearAllEditBox()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
				else 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				end 
			end)
		end 
		
		if tab.name == 6 then 	
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, tab.childs[spec], 0, -5)			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 50, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseLeft = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USELEFT"])
			local UseRight = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["USERIGHT"])
			local Mode = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), ActionDatatheme.dd.height, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 6, 15), ActionDatatheme.dd.height, {				
				{ text = "UnitName", value = "UnitName" },				
				{ text = "GameToolTip", value = "GameToolTip" },
			}, "UnitName")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 95, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, ActionDatatheme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, ActionDatatheme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"][tab.name]["LUATOOLTIP"])
			local Button = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tab.name]["LEFT"], value = "LEFT" },				
				{ text = L["TAB"][tab.name]["RIGHT"], value = "RIGHT" },		
			}, "LEFT")
			local isTotem = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["ISTOTEM"])				
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["INPUT"])		
			local How = StdUi:Dropdown(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], value = "GLOBAL" },				
				{ text = L["TAB"]["ALLSPECS"], value = "ALLSPECS" },
				{ text = L["TAB"]["THISSPEC"], value = "THISSPEC" },
			}, "THISSPEC")	
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tab.name]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 
					Button:SetValue(rowData.Button)
					isTotem:SetChecked(rowData.isTotem)
					InputBox:SetNumber(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["BUTTON"],
                    width = 120,
                    align = "LEFT",
                    index = "ButtonLocale",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 357,
					defaultwidth = 357,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
            }, 12, 20)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						InputBox:ClearFocus()
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				isTotem:SetChecked(false)
				local CategoryValue = Category:GetValue()								
				local ModeValue = Mode:GetValue()
				local data = {}
				for k, v in pairs(TMWdb.profile.ActionDB[tab.name][specID][ModeValue][CategoryValue][GameLocale]) do 
					if v.Enabled then 
						tinsert(data, setmetatable({ 
								Name = k, 				
								ButtonLocale = L["TAB"][tab.name][v.Button],
							}, {__index = v}))
					end 
				end			
				return data
			end 
			local function ScrollTableUpdate()
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END 
			
			UseLeft:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseLeft)
			UseLeft:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseLeft:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].UseLeft = not TMWdb.profile.ActionDB[tab.name][specID].UseLeft
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseLeft)	
					Action.Print(L["TAB"][tab.name]["USELEFT"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].UseLeft)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["USELEFT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseLeft", "]] .. L["TAB"][tab.name]["USELEFT"] .. [[: "})]])	
				end				
			end)
			UseLeft.Identify = { Type = "Checkbox", Toggle = "UseLeft" }
			StdUi:FrameTooltip(UseLeft, L["TAB"][tab.name]["USELEFTTOOLTIP"], nil, "TOPRIGHT", true)
			
			UseRight:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseRight)
			UseRight:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseRight:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					TMWdb.profile.ActionDB[tab.name][specID].UseRight = not TMWdb.profile.ActionDB[tab.name][specID].UseRight
					self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].UseRight)	
					Action.Print(L["TAB"][tab.name]["USERIGHT"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].UseRight)	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["USERIGHT"], [[/run Action.SetToggle({]] .. tab.name .. [[, "UseRight", "]] .. L["TAB"][tab.name]["USERIGHT"] .. [[: "})]])	
				end				
			end)
			UseRight.Identify = { Type = "Checkbox", Toggle = "UseRight" }
			StdUi:FrameTooltip(UseRight, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:Subtitle(Mode, L["TAB"][5]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:Subtitle(Category, L["TAB"][5]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
								
			Button.text:SetJustifyH("CENTER")
			Button:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)			
			
			StdUi:FrameTooltip(isTotem, L["TAB"][tab.name]["ISTOTEMTOOLTIP"], nil, "BOTTOMLEFT", true)	
			isTotem:HookScript("OnClick", function(self)
				if not self.isDisabled then 
					InputBox:ClearFocus()
				end 
			end)	
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function()
				InputBox:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tab.name]["INPUTTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:Subtitle(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)	
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tab.name]["INPUTTITLE"]) 
				else					
					Name = Name:lower()
					local M = Mode:GetValue()
					local C = Category:GetValue()					
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] then 
								for SPEC_ID in pairs(profile.ActionDB[tab.name]) do
									-- Prevent overwrite by next time loading if user applied own changes 
									local LUAVER 
									if profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] then 
										LUAVER = profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name].LUAVER 
									end 
									
									profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] = { 
										Enabled = true,
										Button = Button:GetValue(),
										isTotem = isTotem:GetChecked(),
										LUA = CodeLua,
										LUAVER = LUAVER,
									}
								end 
							end 
						end 					
					elseif HowTo == "ALLSPECS" then 
						for SPEC_ID in pairs(TMWdb.profile.ActionDB[tab.name]) do 
							-- Prevent overwrite by next time loading if user applied own changes 
							local LUAVER 
							if TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] then 
								LUAVER = TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name].LUAVER 
							end 
									
							TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] = { 
								Enabled = true,
								Button = Button:GetValue(),
								isTotem = isTotem:GetChecked(),
								LUA = CodeLua,
								LUAVER = LUAVER,
							}
						end 
					else 
						-- Prevent overwrite by next time loading if user applied own changes 
						local LUAVER 
						if TMWdb.profile.ActionDB[tab.name][specID][M][C][GameLocale][Name] then 
							LUAVER = TMWdb.profile.ActionDB[tab.name][specID][M][C][GameLocale][Name].LUAVER 
						end 
							
						TMWdb.profile.ActionDB[tab.name][specID][M][C][GameLocale][Name] = { 
							Enabled = true,
							Button = Button:GetValue(),
							isTotem = isTotem:GetChecked(),
							LUA = CodeLua,
							LUAVER = LUAVER,
						}
					end 
					ScrollTableUpdate()						
				end 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					local M = Mode:GetValue()
					local C = Category:GetValue()	
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tab.name] then 
								for SPEC_ID in pairs(profile.ActionDB[tab.name]) do
									if profile.ActionDB[tab.name][SPEC_ID] and profile.ActionDB[tab.name][SPEC_ID][M] and profile.ActionDB[tab.name][SPEC_ID][M][C] and profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale] then 
										if Factory[tab.name].PLAYERSPEC[M][C][GameLocale][Name] and profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] then 
											profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name].Enabled = false
										else 
											profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] = nil
										end 
									end 
								end 
							end 
						end 					  
					elseif HowTo == "ALLSPECS" then
						for SPEC_ID in pairs(TMWdb.profile.ActionDB[tab.name]) do 
							if Factory[tab.name].PLAYERSPEC[M][C][GameLocale][Name] and TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] then 
								TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name].Enabled = false 
							else 
								TMWdb.profile.ActionDB[tab.name][SPEC_ID][M][C][GameLocale][Name] = nil
							end 
						end 
					else 
						if Factory[tab.name].PLAYERSPEC[M][C][GameLocale][Name] then 
							TMWdb.profile.ActionDB[tab.name][specID][M][C][GameLocale][Name].Enabled = false
						else 
							TMWdb.profile.ActionDB[tab.name][specID][M][C][GameLocale][Name] = nil
						end 
					end 
					ScrollTableUpdate()					
				end 
			end)            							          
				
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(UseLeft, UseRight, { column = "even" })
			UsePanel:DoLayout()						
			tab.childs[spec]:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			tab.childs[spec]:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -20, left = -15, right = -15 } }):AddElements(Button, isTotem, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				isTotem:SetChecked(false)
				InputBox:SetNumber("")					
				InputBox:ClearFocus()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
				else 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				end 
			end)		
		end 
		
		if tab.name == 7 then 
			if not Action.Data.ProfileUI or not Action.Data.ProfileUI[tab.name] or not Action.Data.ProfileUI[tab.name][specID] or not next(Action.Data.ProfileUI[tab.name][specID]) then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 		
			UI_Title:SetText(L["TAB"][tab.name]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, tab.childs[spec], 0, -5)			
			StdUi:EasyLayout(tab.childs[spec], { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(tab.childs[spec], tab.childs[spec]:GetWidth() - 30, 50, L["TAB"][tab.name]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local MSG_Toggle = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["MSG"])
			local DisableReToggle = StdUi:Checkbox(tab.childs[spec], L["TAB"][tab.name]["DISABLERETOGGLE"])
			local ScrollTable 
			local Macro = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12), 20, "")	
			local ConfigPanel = StdUi:PanelWithTitle(tab.childs[spec], GetWidthByColumn(tab.childs[spec], 12, 30), 100, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(13)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(tab.childs[spec], 70, ActionDatatheme.dd.height, L["RESET"])
			local LuaButton = StdUi:Button(tab.childs[spec], 50, ActionDatatheme.dd.height, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, ActionDatatheme.off)
			local LuaEditor = CreateLuaEditor(tab.childs[spec], L["TAB"]["LUAWINDOW"], Action.MainUI.default_w, Action.MainUI.default_h, L["TAB"]["LUATOOLTIP"])						
			local Key = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local Source = StdUi:SimpleEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local InputBox = StdUi:SearchEditBox(tab.childs[spec], GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tab.name]["INPUT"])			
			local Add = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["ADD"])
			local Remove = StdUi:Button(tab.childs[spec], GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
					else 
						LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
					end 
					Macro:SetText(rowData.Name and "/party " .. rowData.Name or "")
					Macro:ClearFocus()										
					Key:SetText(rowData.Key)
					Key:ClearFocus()
					Source:SetText(rowData.Source or "")
					Source:ClearFocus()
					InputBox:SetText(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 
			ScrollTable = StdUi:ScrollTable(tab.childs[spec], {
				{
                    name = L["TAB"][tab.name]["KEY"],
                    width = 100,
                    align = "LEFT",
                    index = "Key",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tab.name]["NAME"],
                    width = 207,
					defaultwidth = 207,
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["WHOSAID"],
                    width = 120,
                    align = "LEFT",
                    index = "Source",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tab.name]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 14, 20)			
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						Macro:ClearFocus()					
						Key:ClearFocus()
						Source:ClearFocus()
						InputBox:ClearFocus()						
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local function ScrollTableData()
				local data = {}
				for k, v in pairs(TMWdb.profile.ActionDB[tab.name][specID].msgList) do 
					if v.Enabled then 
						if Action[specID][v.Key] then 
							tinsert(data, setmetatable({
								Enabled = v.Enabled,
								Key = v.Key,
								Source = v.Source or "",
								LUA = v.LUA,
								Name = k, 								
								Icon = Action[specID][v.Key]:Icon(),
							}, {__index = Action[specID][v.Key]}))
						else 
							v = nil 
						end 
					end 
				end			
				return data
			end 
			local function ScrollTableUpdate()
				Macro:ClearFocus()				
				Key:ClearFocus()
				Source:ClearFocus()
				InputBox:ClearFocus()				
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- If we had return back to this tab then handler will be skipped 
			if Action.MainUI.RememberTab == tab.name then 
				ScrollTableUpdate()
			end
			-- [ScrollTable] END
			
			MSG_Toggle:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].MSG_Toggle)
			MSG_Toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			MSG_Toggle:SetScript("OnClick", function(self, button, down)	
				Macro:ClearFocus()	
				Key:ClearFocus()
				Source:ClearFocus()				
				InputBox:ClearFocus()
				if button == "LeftButton" then 
					Action.ToggleMSG()	
				elseif button == "RightButton" then 
					CraftMacro(L["TAB"][tab.name]["MSG"], [[/run Action.ToggleMSG()]])	
				end				
			end)
			MSG_Toggle.Identify = { Type = "Checkbox", Toggle = "MSG_Toggle" }
			StdUi:FrameTooltip(MSG_Toggle, L["TAB"][tab.name]["MSGTOOLTIP"], nil, "TOPRIGHT", true)
			
			DisableReToggle:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].DisableReToggle)
			DisableReToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableReToggle:SetScript("OnClick", function(self, button, down)	
				Macro:ClearFocus()	
				Key:ClearFocus()
				Source:ClearFocus()				
				InputBox:ClearFocus()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						TMWdb.profile.ActionDB[tab.name][specID].DisableReToggle = not TMWdb.profile.ActionDB[tab.name][specID].DisableReToggle
						self:SetChecked(TMWdb.profile.ActionDB[tab.name][specID].DisableReToggle)	
						Action.Print(L["TAB"][tab.name]["DISABLERETOGGLE"] .. ": ", TMWdb.profile.ActionDB[tab.name][specID].DisableReToggle)	
					elseif button == "RightButton" then 
						CraftMacro(L["TAB"][tab.name]["DISABLERETOGGLE"], [[/run Action.SetToggle({]] .. tab.name .. [[, "DisableReToggle", "]] .. L["TAB"][tab.name]["DISABLERETOGGLE"] .. [[: "})]])	
					end		
				end 
			end)
			DisableReToggle.Identify = { Type = "Checkbox", Toggle = "DisableReToggle" }
			StdUi:FrameTooltip(DisableReToggle, L["TAB"][tab.name]["DISABLERETOGGLETOOLTIP"], nil, "TOPLEFT", true)
			DisableReToggle:SetScript("OnShow", function(self) 
				if not MSG_Toggle:GetChecked() then 
					self:Disable()
				end 
			end)
			if not MSG_Toggle:GetChecked() then 
				DisableReToggle:Disable()
			end 
			
			Macro:SetScript("OnTextChanged", function(self)
				local index = ScrollTable:GetSelection()				
				if not index then 
					return
				else 
					local data = ScrollTable:GetRow(index)					
					if data then 
						local thisname = "/party " .. data.Name 
						if thisname ~= self:GetText() then 
							self:SetText(thisname)
						end 
					end 
				end 
            end)
			Macro:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Macro:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)						
			Macro:SetJustifyH("CENTER")
			Macro.FontString = StdUi:Subtitle(Macro, L["TAB"][tab.name]["MACRO"])
			StdUi:GlueAbove(Macro.FontString, Macro) 
			StdUi:FrameTooltip(Macro, L["TAB"][tab.name]["MACROTOOLTIP"], nil, "TOP", true)			
			
			Key:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Key:SetJustifyH("CENTER")
			Key.FontString = StdUi:Subtitle(Key, L["TAB"][tab.name]["KEY"])
			StdUi:GlueAbove(Key.FontString, Key)	
			StdUi:FrameTooltip(Key, L["TAB"][tab.name]["KEYTOOLTIP"], nil, "TOPRIGHT", true)	

			Source:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Source:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Source:SetJustifyH("CENTER")
			Source.FontString = StdUi:Subtitle(Source, L["TAB"][tab.name]["SOURCE"])
			StdUi:GlueAbove(Source.FontString, Source)	
			StdUi:FrameTooltip(Source, L["TAB"][tab.name]["SOURCETOOLTIP"], nil, "TOPLEFT", true)

			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tab.name]["INPUTTITLE"])						
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			StdUi:FrameTooltip(InputBox, L["TAB"][tab.name]["INPUTTOOLTIP"], nil, "TOP", true)			
			
			Add:SetScript("OnClick", function(self, button, down)		
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tab.name]["INPUTERROR"]) 
					return 
				end 
				
				local TableKey = Key:GetText()
				if TableKey == nil or TableKey == "" then 
					Action.Print(L["TAB"][tab.name]["KEYERROR"]) 
					return 
				elseif not Action[specID][TableKey] then 
					Action.Print(TableKey .. " " .. L["TAB"][tab.name]["KEYERRORNOEXIST"]) 
					return 
				end 				
			
				Name = Name:lower()	
				for k, v in pairs(TMWdb.profile.ActionDB[tab.name][specID].msgList) do 
					if v.Enabled and Name:match(k) and Name ~= k then 
						Action.Print(Name .. " " .. L["TAB"][tab.name]["MATCHERROR"]) 
						return 
					end
				end 
				
				local SourceName = Source:GetText()
				if SourceName == "" then 
					SourceName = nil
				end 				
				
				local CodeLua = LuaEditor.EditBox:GetText()
				if CodeLua == "" then 
					CodeLua = nil 
				end 
				
				-- Prevent overwrite by next time loading if user applied own changes 
				local LUAVER 
				if TMWdb.profile.ActionDB[tab.name][specID].msgList[Name] then 
					LUAVER = TMWdb.profile.ActionDB[tab.name][specID].msgList[Name].LUAVER
				end 

				TMWdb.profile.ActionDB[tab.name][specID].msgList[Name] = { 
					Enabled = true,
					Key = TableKey,
					Source = SourceName,
					LUA = CodeLua,
					LUAVER = LUAVER,
				}
 
				ScrollTableUpdate()										 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)		
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					if Action.Data.ProfileDB[tab.name][specID].msgList[Name] then 
						TMWdb.profile.ActionDB[tab.name][specID].msgList[Name].Enabled = false							
					else 
						TMWdb.profile.ActionDB[tab.name][specID].msgList[Name] = nil	
					end 					
					ScrollTableUpdate()					
				end 
			end)            							          
				
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(MSG_Toggle, DisableReToggle, { column = "even" })
			UsePanel:DoLayout()								
			tab.childs[spec]:AddRow({ margin = { top = 10, left = -15, right = -15 } }):AddElement(ScrollTable)
			tab.childs[spec]:AddRow({ margin = { left = -15, right = -15 } }):AddElement(Macro)
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElements(Key, Source, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			tab.childs[spec]:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			tab.childs[spec]:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				Macro:SetText("")
				Macro:ClearFocus()	
				Key:SetText("")
				Key:ClearFocus()
				Source:SetText("")
				Source:ClearFocus()
				InputBox:SetText("")
				InputBox:ClearFocus()				
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.on)
				else 
					LuaButton.FontStringLUA:SetText(ActionDatatheme.off)
				end 
			end)							
		end 		
		
		if Action.MainUI.resizer then 
			Action.MainUI.UpdateResize()
		end 
	end)		
end

-------------------------------------------------------------------------------
-- Debug  
-------------------------------------------------------------------------------
function Action.Print(text, bool, ignore)
	if not ignore and TMWdb and TMWdb.profile.ActionDB and TMWdb.profile.ActionDB[1] and TMWdb.profile.ActionDB[1].DisablePrint then 
		return 
	end 
    DEFAULT_CHAT_FRAME:AddMessage(strjoin(" ", "|cff00ccffAction:|r", text .. (bool ~= nil and tostring(bool) or "")))
end

function Action.PrintHelpToggle()
	Action.Print("|cff00cc66Shift+LeftClick|r " .. L["SLASH"]["TOTOGGLEBURST"])
	Action.Print("|cff00cc66Ctrl+LeftClick|r " .. L["SLASH"]["TOTOGGLEMODE"])
	Action.Print("|cff00cc66Alt+LeftClick|r " .. L["SLASH"]["TOTOGGLEAOE"])
end 

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
local HealerSpecs = {
	[ACTION_CONST_DRUID_RESTORATION]	= true, 
	[ACTION_CONST_MONK_MISTWEAVER] 		= true, 
	[ACTION_CONST_PALADIN_HOLY]  		= true, 
	[ACTION_CONST_PRIEST_DISCIPLINE] 	= true, 
	[ACTION_CONST_PRIEST_HOLY] 			= true, 
	[ACTION_CONST_SHAMAN_RESTORATION] 	= true, 
}
local RangerSpecs = {
	--[ACTION_CONST_PALADIN_HOLY] 		= true,
	[ACTION_CONST_HUNTER_BEASTMASTERY]	= true,
	[ACTION_CONST_HUNTER_MARKSMANSHIP]	= true,
	--[ACTION_CONST_PRIEST_DISCIPLINE]	= true,
	--[ACTION_CONST_PRIEST_HOLY]		= true,
	[ACTION_CONST_PRIEST_SHADOW]		= true,
	[ACTION_CONST_SHAMAN_ELEMENTAL]		= true,
	--[ACTION_CONST_SHAMAN_RESTORATION]	= true,
	[ACTION_CONST_MAGE_ARCANE]			= true,
	[ACTION_CONST_MAGE_FIRE]			= true,
	[ACTION_CONST_MAGE_FROST]			= true,
	[ACTION_CONST_WARLOCK_AFFLICTION]	= true,
	[ACTION_CONST_WARLOCK_DEMONOLOGY]	= true,	
	[ACTION_CONST_WARLOCK_DESTRUCTION]	= true,	
	--[ACTION_CONST_MONK_MISTWEAVER]	= true,	
	[ACTION_CONST_DRUID_BALANCE]		= true,	
	--[ACTION_CONST_DRUID_RESTORATION]	= true,	
}
function Action:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	Action.PlayerSpec, Action.PlayerSpecName = GetSpecializationInfo(GetSpecialization()) 
    Action.IamHealer = HealerSpecs[Action.PlayerSpec]
	Action.IamRanger = Action.IamHealer or RangerSpecs[Action.PlayerSpec]
	Action.IamMelee  = not Action.IamRanger

	TMW:Fire("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED")	-- For MultiUnits to initialize CLEU and other purposes to be sure what variables was updated properly 
	TMW:Fire("TMW_ACTION_DEPRECATED")						-- TODO: Remove 
	
	if TMW.time == self.PLAYER_SPECIALIZATION_CHANGED_TIMESTAMP or (event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player") or not Action.PlayerSpec then
		return
	end
	
	if Action.IsInitialized then 
		if Action.MainUI then 
			if Action.MainUI:IsShown() then 
				Action.ToggleMainUI()
				Action.ToggleMainUI()
			end 
			-- Refresh title of spec 
			tabFrame.tabs[2].title = Action.PlayerSpecName
			tabFrame:DrawButtons()	
		end 
		-- I use this as reinit some things since all my db attached to each spec I have to reinit (or turn off) saved settings from another spec	
		GlobalsRemap()	
		Re:Initialize()
		LineOfSight:Initialize()
		SpellLevel:Initialize(true)
		
		-- Unregister from old interface MSG events and use new ones 
		Action.ToggleMSG(true)
	end 
	
	self.PLAYER_SPECIALIZATION_CHANGED_TIMESTAMP = TMW.time 
end
Action:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Action:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED")
Action:RegisterEvent("PLAYER_LOGIN", 				"PLAYER_SPECIALIZATION_CHANGED")
Action:RegisterEvent("PLAYER_ENTERING_WORLD", 		"PLAYER_SPECIALIZATION_CHANGED")
Action:RegisterEvent("UPDATE_INSTANCE_INFO", 		"PLAYER_SPECIALIZATION_CHANGED")
hooksecurefunc(TMW, "InitializeDatabase", function()
	if not TMWdb then 
		TMWdb = TMW.db
	end 
end)

local OnInitialize
function OnInitialize()	
	-- This function calls only if TMW finished EVERYTHING load
	-- This will initialize ActionDB for current profile by Action.Data.ProfileUI > Action.Data.ProfileDB (which in profile snippet)
	if not TMWdb then 
		TMWdb = TMW.db
	end 
	local profile = TMWdb:GetCurrentProfile()
	
	Action.IsInitialized = nil	
	Action.IsGGLprofile = profile:match("GGL") and true or false  	-- Don't remove it because this is validance for HealingEngine   
	Action.IsBasicProfile = profile == "[GGL] Basic"
	Action.CurrentProfile = profile
	TMW:Fire("TMW_ACTION_DEPRECATED")								-- TODO: Remove 
	
	----------------------------------
	-- TMW CORE SNIPPETS FIX
	----------------------------------	
	-- Finally owner of TMW fixed it in 8.6.6
	if TELLMEWHEN_VERSIONNUMBER < 86603 and not Action.IsInitializedSnippetsFix then 
		-- TMW owner has trouble with ICON and GROUP PRE SETUP, he trying :setup() frames before lua snippets would be loaded 
		-- Yeah he has callback ON PROFILE to run it but it's POST handler which triggers AFTER :setup() and it cause errors for nil objects (coz they are in snippets :D which couldn't be loaded before frames)
		local function OnProfileFix()
			if not TMW.Initialized or not TMW.InitializedDatabase then
				return
			end		
			
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMWdb.profile.CodeSnippets) do
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and not TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end						      
		end	
		TMW:RegisterCallback("TMW_GLOBAL_UPDATE", OnProfileFix, "TMW_SNIPPETS_FIX")	
		Action.IsInitializedSnippetsFix = true 
	end 	
	
	----------------------------------
	-- Register Localization
	----------------------------------	
	Action.GetLocalization()
	
	----------------------------------
	-- Profile Manipulation
	----------------------------------	
	-- Load default profile if current profile is generated as default
	local defaultprofile = UnitName("player") .. " - " .. GetRealmName()
	if profile == defaultprofile then 
		local AllProfiles = TMWdb.profiles
		if AllProfiles then 
			if ActionDataDefaultProfile[Action.PlayerClass] and AllProfiles[ActionDataDefaultProfile[Action.PlayerClass]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMWdb:SetProfile(ActionDataDefaultProfile[Action.PlayerClass])
				return
			end		
		
			if AllProfiles[ActionDataDefaultProfile["BASIC"]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMWdb:SetProfile(ActionDataDefaultProfile["BASIC"])
				return 
			end 	
		end 
	end 		
		
	-- Check if profile support Action
	if not Action.Data.ProfileEnabled[profile] then 
		LineOfSight:Initialize(true)	-- TODO: Remove (old profiles)
		if TMWdb.profile.ActionDB then 
			TMWdb.profile.ActionDB = nil
			Action.Print("|cff00cc66" .. profile .. " - profile.ActionDB|r " .. L["RESETED"]:lower())
		end 			
		if Action.Minimap and LibDBIcon then 
			LibDBIcon:Hide("ActionUI")
		end 
		Queue:OnEventToReset()
		wipe(Action.Data.ProfileUI)
		wipe(Action.Data.ProfileDB)		
		return 
	end 	 
	
	-- Action.Data.ProfileUI > Action.Data.ProfileDB creates template to merge in Factory after
	if next(Action.Data.ProfileUI) or #Action.Data.ProfileUI > 0 then 
		wipe(Action.Data.ProfileDB)
		-- Prevent developer's by mistake sensitive wrong assigns 
		local ReMap = {
			["mouseover"] = "mouseover",
			["targettarget"] = "targettarget", 
			["aoe"] = "AoE",
		}
		for i, i_value in pairs(Action.Data.ProfileUI) do
			if ( i == 2 or i == 7 ) and type(i) == "number" and type(i_value) == "table" then 	-- get tab 
				for specID in pairs(i_value) do 												-- get spec in tab 	
					if not Action.Data.ProfileDB[i] then 
						Action.Data.ProfileDB[i] = {}
					end 
					if not Action.Data.ProfileDB[i][specID] then 
						Action.Data.ProfileDB[i][specID] = {}
					end 				
					if i == 2 then 																-- tab [2] for toggles 					
						for row = 1, #Action.Data.ProfileUI[i][specID] do 						-- get row for spec in tab 						
							for element = 1, #Action.Data.ProfileUI[i][specID][row] do 			-- get element in row for spec in tab 
								local DB = Action.Data.ProfileUI[i][specID][row][element].DB 
								if ReMap[strlowerCache[DB]] then 
									Action.Data.ProfileUI[i][specID][row][element].DB = ReMap[strlowerCache[DB]]
									DB = ReMap[strlowerCache[DB]]
								end 
								
								local DBV = Action.Data.ProfileUI[i][specID][row][element].DBV
								if DB ~= nil and DBV ~= nil then 								-- if default value for DB inside UI 
									Action.Data.ProfileDB[i][specID][DB] = DBV
								end 
							end						
						end
					elseif i == 7 then 															-- tab [7] for MSG 	
						if not Action.Data.ProfileDB[i][specID].msgList then 
							Action.Data.ProfileDB[i][specID].msgList = {}
						end 	
						
						for Name, Val in pairs(i_value[specID]) do 
							Action.Data.ProfileDB[i][specID].msgList[Name] = Val
						end 
					end
				end 
			end 
		end 
	end 	
		
	-- profile	
	if not TMWdb.profile.ActionDB then 
		Action.Print("|cff00cc66ActionDB.profile|r " .. L["CREATED"])		
	end	
	TMWdb.profile.ActionDB = tCompare(tMerge(Factory, Action.Data.ProfileDB, true), TMWdb.profile.ActionDB) 
		
	-- global
	if not TMWdb.global.ActionDB then 		
		Action.Print("|cff00cc66ActionDB.global|r " .. L["CREATED"])
	end
	TMWdb.global.ActionDB = tEraseKeys(tCompare(GlobalFactory, TMWdb.global.ActionDB), GlobalFactoryErased)
	
	-- to avoid lua errors with calls GetToggle 	
	ActionHasRunningDB = true 
	
	----------------------------------
	-- All remaps and additional sort DB 
	----------------------------------		
	-- Note: These functions must be call whenever relative settings in UI has been changed in their certain places!
	GlobalsRemap() 			 -- by profile to _G.
	DispelPurgeEnrageRemap() -- [5] by global to profile
	
	----------------------------------	
	-- Welcome Notification
	----------------------------------	
    Action.Print(L["SLASH"]["LIST"])
	Action.Print("|cff00cc66/action|r - "  .. L["SLASH"]["OPENCONFIGMENU"])
	Action.Print("|cff00cc66/action help|r - " .. L["SLASH"]["HELP"])		
	TMW:UnregisterCallback("TMW_SAFESETUP_COMPLETE", OnInitialize, "ACTION_TMW_SAFESETUP_COMPLETE")

	----------------------------------	
	-- Initialization
	----------------------------------	
	-- Initialization ColorPicker 
	ColorPicker:Initialize()
	
	-- Initialization ReTarget ReFocus 
	Re:Initialize()
	
	-- Initialization ScreenshotHider
	ScreenshotHider:Initialize(Action.GetToggle(1, "HideOnScreenshot"))
	
	-- Initialization LOS System
	LineOfSight:Initialize()
	
	-- Initialization SpellLevel if it was selected in db or player level lower than MAX on this expansion	
	SpellLevel:Initialize(true)
	
	-- Initialization Cursor hooks 
	Action.CursorInit()
	
	-- Unregister from old interface MSG events and use new ones 
	Action.ToggleMSG(true)

	-- Initialization Cached functions 
	if not Action.IsInitializedCachedFunctions then 
		SmartInterrupt 						= Action.MakeFunctionCachedStatic(SmartInterrupt)		
		strOnlyBuilder						= Action.strOnlyBuilder
		Action.IsInitializedCachedFunctions = true 
	end 
	
	-- Minimap 
	if not Action.Minimap and LibDBIcon then 
		local ldbObject = {
			type = "launcher",
			icon = ACTION_CONST_AUTOTARGET, 
			label = "ActionUI",
			OnClick = function(self, button)
				Action.ToggleMainUI()
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("ActionUI")
			end,
		}
		LibDBIcon:Register("ActionUI", ldbObject, TMWdb.global.ActionDB.minimap)
		LibDBIcon:Refresh("ActionUI", TMWdb.global.ActionDB.minimap)
		Action.Minimap = true 
		Action.ToggleMinimap()
	else
		Action.ToggleMinimap()
	end 
		
	-- Modified update engine of TMW core with additional FPS Optimization	
	if not Action.IsInitializedModifiedTMW and TMW then do
		-- [[ REMAP ]]
		local IconsToUpdate = TMW.IconsToUpdate
		local GroupsToUpdate = TMW.GroupsToUpdate	
		local Locked, Time, FPS, Framerate
		-- 
	
		local LastUpdate = 0
		local updateInProgress, shouldSafeUpdate
		local start 
		-- Assume in combat unless we find out otherwise.
		local inCombatLockdown = 1

		-- Limit in milliseconds for each OnUpdate cycle.
		local CoroutineLimit = 50
		
		TMW:RegisterEvent("UNIT_FLAGS", function(event, unit)
				if unit == "player" then
					inCombatLockdown = InCombatLockdown()
				end
		end)	
		
		local function checkYield()
				if inCombatLockdown and debugprofilestop() - start > CoroutineLimit then
					TMW:Debug("OnUpdate yielded early at %s", Time)

					coroutine.yield()
				end
		end	
		
		-- This is the main update engine of TMW.
		local function OnUpdate()
			while true do
				TMW:UpdateGlobals()
				Locked = TMW.Locked	-- custom 
				Time = TMW.time 	-- custom

				if updateInProgress then
					-- If the previous update cycle didn't finish (updateInProgress is still true)
					-- then we should enable safecalling icon updates in order to prevent catastrophic failure of the whole addon
					-- if only one icon or icon type is malfunctioning.
					if not shouldSafeUpdate then
						TMW:Debug("Update error detected. Switching to safe update mode!")
						shouldSafeUpdate = true
					end
				end
				updateInProgress = true
				
				TMW:Fire("TMW_ONUPDATE_PRE", Time, Locked)
				-- FPS Optimization
				FPS = Action.GetToggle(1, "FPS")
				if not FPS or FPS < 0 then 
					Framerate = GetFramerate() or 0
					if Framerate > 0 and Framerate < 100 then
						FPS = (100 - Framerate) / 900
						if FPS < 0.04 then 
							FPS = 0.04
						end 
					else
						FPS = 0.03
					end					
				end 				
				TMW.UPD_INTV = FPS + 0.001					
			
				if LastUpdate <= Time - TMW.UPD_INTV then
					LastUpdate = Time
					if TMW.profilingEnabled and TellMeWhen_CpuProfileDialog:IsShown() then 
						TMW:CpuProfileReset()
					end 

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_PRE", Time, Locked)
					
					if Locked then
						for i = 1, #GroupsToUpdate do
							-- GroupsToUpdate only contains groups with conditions
							local group = GroupsToUpdate[i]
							local ConditionObject = group and group.ConditionObject -- Fix for default engine 
							if ConditionObject and (ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < Time) then
								ConditionObject:Check()

								if inCombatLockdown then checkYield() end
							end
						end
				
						if shouldSafeUpdate then
							for i = 1, #IconsToUpdate do
								local icon = IconsToUpdate[i]
								safecall(icon.Update, icon)
								if inCombatLockdown then checkYield() end
							end
						else
							for i = 1, #IconsToUpdate do
								--local icon = IconsToUpdate[i]
								IconsToUpdate[i]:Update()

								-- inCombatLockdown check here to avoid a function call.
								if inCombatLockdown then checkYield() end
							end
						end
					end

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_POST", Time, Locked)
				end

				updateInProgress = nil
				
				if inCombatLockdown then checkYield() end

				TMW:Fire("TMW_ONUPDATE_POST", Time, Locked)

				coroutine.yield()
			end
		end 

		local Coroutine 
		function TMW:OnUpdate()
			start = debugprofilestop()			
			
			if not Coroutine or coroutine.status(Coroutine) == "dead" then
				if Coroutine then
					TMW:Debug("Rebirthed OnUpdate coroutine at %s", TMW.time)
				end
				
				Coroutine = coroutine.create(OnUpdate)
			end
			
			assert(coroutine.resume(Coroutine))
		end

		local function UnlockExtremelyInterval(forced)
			if Action.IsInitialized or forced then 
				local PREV_INTERVAL = TMWdb.global.Interval 
				TMWdb.global.Interval = 0
				TMW:Update()
				TMWdb.global.Interval = PREV_INTERVAL
			end 
		end
		
		TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", function() UnlockExtremelyInterval(true) end) 
		
		local isIconEditorHooked
		hooksecurefunc(TMW, "LockToggle", function() 
			if not isIconEditorHooked then 
				TellMeWhen_IconEditor:HookScript("OnHide", function() 
					if TMW.Locked then 
						UnlockExtremelyInterval()						
					end 
				end)
				isIconEditorHooked = true
			end
			if TMW.Locked then 
				UnlockExtremelyInterval()
			end 			
		end)			
		
		-- Loading options 
		if TMW.Classes.Resizer_Generic == nil then 
			TMW:LoadOptions()
		end 		
		
		Action.IsInitializedModifiedTMW = true 
	end end 
			
	-- Make frames work able 
	TMW:Fire("TMW_ACTION_IS_INITIALIZED_PRE")
	Action.IsInitialized = true 
	TMW:Fire("TMW_ACTION_IS_INITIALIZED")	
end

function Action:OnInitialize()	
	----------------------------------
	-- Remap
	----------------------------------
	A_Unit 	= Action.Unit	-- Unit.lua
	round 	= _G.round		-- Tools.lua
	----------------------------------
	-- Register Slash Commands
	----------------------------------
	local function SlashCommands(input) 
		if not L then return end -- If we trying show UI before DB finished load locales 
		local profile = TMWdb:GetCurrentProfile()
		if not Action.Data.ProfileEnabled[profile] then 
			Action.Print(profile .. " " .. L["NOSUPPORT"])
			return 
		end 
		if not input or #input > 0 then 
			-- without checks for another options for /action since right now only "help" enough even if user did wrong input 
			Action.Print(L["SLASH"]["LIST"])
			Action.Print("|cff00cc66/action|r - " .. L["SLASH"]["OPENCONFIGMENU"])
			Action.Print('|cff00cc66/run Action.MacroQueue("TABLE_NAME")|r - ' .. L["SLASH"]["QUEUEHOWTO"])
			Action.Print('|cff00cc66/run Action.MacroQueue("WordofGlory")|r - ' .. L["SLASH"]["QUEUEEXAMPLE"])		
			Action.Print('|cff00cc66/run Action.MacroBlocker("TABLE_NAME")|r - ' .. L["SLASH"]["BLOCKHOWTO"])
			Action.Print('|cff00cc66/run Action.MacroBlocker("FelRush")|r - ' .. L["SLASH"]["BLOCKEXAMPLE"])	
			Action.Print(L["SLASH"]["RIGHTCLICKGUIDANCE"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCE"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCEEACHSPEC"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCEALLSPECS"])
			Action.Print(L["SLASH"]["INTERFACEGUIDANCEGLOBAL"])
			Action.Print(L["SLASH"]["ATTENTION"])
		else 
			Action.ToggleMainUI()
		end 
	end 	
	SLASH_ACTION1 = "/action"
	SlashCmdList.ACTION = SlashCommands	
	----------------------------------
	-- Register ActionDB defaults
	----------------------------------	
	local function OnSwap(event, profileEvent, arg2, arg3)
		if not TMWdb then 
			TMWdb = TMW.db
		end 
				
		Action.IsInitialized = nil
		if ActionHasRunningDB then 
			-- SpellLevel
			SpellLevel:Reset(true)
			-- ReFocus // ReTarget 
			Re:Reset()
			-- ScreenshotHider
			ScreenshotHider:Reset()
			-- LOSInit 
			LineOfSight:Reset()
			-- ToggleMSG 
			Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
			Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")
			Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
			Action.Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")	
		end 
		
		ActionHasRunningDB = nil 
		
		-- Turn off everything 
		if Action.MainUI and Action.MainUI:IsShown() then 
			Action.ToggleMainUI()
		end
		
		-- TMW has wrong condition which prevent run already running snippets and it cause issue to refresh same variables as example, so let's fix this 
		-- Note: Can cause issues if there loops, timers, frames or hooks 	
		if profileEvent == "OnProfileChanged" then
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMWdb.profile.CodeSnippets) do
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end
			
			-- Wipe childs otherwise it will cause bug what changed profile will use frames by previous profile 
			if Action.MainUI then 
				tabFrame:EnumerateTabs(function(tab)
					if tab.childs then 
						for k in pairs(tab.childs) do
							tab.childs[k]:Hide() 
						end	
						wipe(tab.childs)
					end
				end)
			end 
		end 		
		OnInitialize()		
		TMW:Fire("TMW_ACTION_ON_PROFILE_POST") -- Callback for HybridProfile.lua (don't remove in future)
	end
	TMW:RegisterCallback("TMW_ON_PROFILE", OnSwap)
	TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", OnInitialize, "ACTION_TMW_SAFESETUP_COMPLETE")	
end