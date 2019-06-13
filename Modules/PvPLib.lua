-- Version 2.2
local TMW = TMW
local CNDT = TMW.CNDT
local Env = CNDT.Env

local tableexist, pairs, tostring = tableexist, pairs, tostring
local IsInRaid, IsInGroup = IsInRaid, IsInGroup

local RequestBattlefieldScoreData, GetNumArenaOpponentSpecs, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers, GetSpellInfo, GetItemCooldown = 
RequestBattlefieldScoreData, GetNumArenaOpponentSpecs, GetNumArenaOpponents, GetNumBattlefieldScores, GetNumGroupMembers, Action.GetSpellInfo, GetItemCooldown

local UnitAttackSpeed, UnitPowerType, UnitClass, UnitGUID, UnitPower, UnitIsUnit, UnitIsPlayer, UnitExists, UnitInRange, UnitCreatureType, UnitName = 
UnitAttackSpeed, UnitPowerType, UnitClass, UnitGUID, UnitPower, UnitIsUnit, UnitIsPlayer, UnitExists, UnitInRange, UnitCreatureType, UnitName 

local GetSpecialization, GetSpecializationInfo = GetSpecialization, GetSpecializationInfo 

specNameToRole = {}
for i = 1, GetNumClasses() do
	local _, class, classID = GetClassInfo(i)
	specNameToRole[class] = {}

	for j = 1, GetNumSpecializationsForClassID(classID) do
		local specID, spec, desc, icon = GetSpecializationInfoForClassID(classID, j)
		specNameToRole[class][spec] = specID
	end
end
Env.ModifiedUnitSpecs = {}
local SPECS = CNDT:GetModule("Specs")
function SPECS:UpdateUnitSpecs()
	if Env.UnitSpecs and next(Env.UnitSpecs) then
		wipe(Env.UnitSpecs)	
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end
	
	if next(Env.ModifiedUnitSpecs) then 
		wipe(Env.ModifiedUnitSpecs)
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end

	if Env.Zone == "arena" then
		for i = 1, Env.PvPCache["Group_EnemySize"] do
			local unit = "arena" .. i

			local name, server = UnitName(unit)
			if name and name ~= UNKNOWN then
				local specID = GetArenaOpponentSpec(i)
				name = name .. (server and "-" .. server or "")
				if Env.UnitSpecs then 
					Env.UnitSpecs[name] = specID
				end 
				Env.ModifiedUnitSpecs[name] = specID
				--print(Env.ModifiedUnitSpecs[name])
			end
		end

		TMW:Fire("TMW_UNITSPEC_UPDATE")
	elseif Env.Zone == "pvp" then
		for i = 1, Env.PvPCache["Group_EnemySize"] do
			local name, _, _, _, _, _, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
			if name then
				local specID = specNameToRole[classToken][talentSpec]
				if Env.UnitSpecs then 
					Env.UnitSpecs[name] = specID
				end 
				Env.ModifiedUnitSpecs[name] = specID
			end
		end
		
		TMW:Fire("TMW_UNITSPEC_UPDATE")
	end
end
SPECS:RegisterEvent("UNIT_NAME_UPDATE",   "UpdateUnitSpecs")
SPECS:RegisterEvent("ARENA_OPPONENT_UPDATE", "UpdateUnitSpecs")
SPECS:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateUnitSpecs")
SPECS:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateUnitSpecs")
SPECS.PrepareUnitSpecEvents = TMW.NULLFUNC

--- ============================ CONTENT ============================
local AuraList = {
    -- CC SCHOOL TYPE 
    Magic = {
        118, -- Polymorph
        605, -- Mind Control                
        9484, -- Shackle Undead
        2637, -- Hibernate
        20066, -- Repentance          
        5782, -- Fear
        3355, -- Freezing Trap
        209790, -- Freezing Arrow (hunter pvp)        
        6358, -- Seduction
        82691, -- Ring of Frost                          
        198909, -- Song of Chi-ji (mistweaver monk talent)
        5484, -- Howl of Terror
        6789, -- Mortal Coil
        87204, -- Sin and Punishment
        8122, -- Psychic Scream
        31661, -- Dragon's Breath
        105421, -- Bliding light (paladin talent)
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        15487, -- Silence        
        31935, -- Avenger's Shield
        199683, -- Last Word
        47476, -- Strangulate
        31117, -- Unstable Affliction
        853, -- Hammer of Justice
        64044, -- Psychic Horror
        30283, -- Shadowfury
        117526, -- Binding Shot
        118905, -- Static Charge
        179057, -- Chaos Nova
        205630, -- Illidan's Grasp (demon hunter)
        226943, -- Mind Bomb
        209749, -- Faerie Swarm (Moonkin Disarm) 
        204399, -- Earthfury (enhancement shaman pvp talent)
        217832, -- Imprison
        286349, -- Gladiator's Maledict
    },
    MagicRooted = {
        233395, -- Frozen Center (DK PvP Frost)    
        339, -- Entangling Roots
        122, -- Frost Nova
        102359, -- Mass Entanglement
        96294, -- Chains of Ice
        183218, -- Retri's -70%
    }, 
    Curse = {
        51514, -- Hex   
        -- Warlock BFA
        12889, -- Curse of Tongues
        17227, -- Curse of Weakness
        199954, -- Curse of Fragility
    },
    Disease = {
        196782, -- Outbreak (5 sec infecting dot)
        191587, -- Outbreak (21+ sec dot)
        58180, -- Infected Wounds (Feral slow)
        -- [Blood Plague] 
        -- [Frost Fever]
    },
    Poison = {
        19386, -- Wyvern Sting
        202933, -- Spider Sting   
        202797, -- Viper Sting
        202900, -- Scorpid Sting
    },
    Physical = {
        115078, -- Paralysis
        6770, -- Sap
        107079, -- Quaking Palm
        207685, -- Sigil of Misery (Havoc Demon hunter)
        5246, -- Intimidating Shout
        99, -- Incapacitating Roar
        1776, -- Gouge
        2094, -- Blind
        186387, -- Bursting Shot (hunter marks ability)
        213691, -- Scatter Shot (hunter pvp talent)
        25, -- Stun
        1833, -- Cheap Shot
        408, -- Kidney Shot
        5211, -- Mighty Bash
        24394, -- Intimidation
        89766, -- Axe Toss
        108194, -- Asphyxiate (DK)        
        118345, -- Pulverize
        119381, -- Leg Sweep
        132168, -- Shockwave
        132169, -- Storm Bolt
        163505, -- Rake
        199804, -- Between the Eyes
        203123, -- Maim
        236025, -- Enraged Maim
        204399, -- Earthfury (enhancement shaman pvp talent)           
        47481, -- Gnaw (DK pet)
        212332, -- Smash (DK transformation pet)
        -- 207167, -- Blinding Sleet (is it physical ? )
        207777, -- Dismantle
        236077, -- Disarm        
        233759, -- Grapple Weapon
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
    },
    -- CC CONTROL TYPE
    CrowdControl = {
        118, -- Polymorph
        --6770, -- Sap
        --605, -- Mind Control
        20066, -- Repentance
        --51514, -- Hex (also 211004, 210873, 211015, 211010)
        --9484, -- Shackle Undead
        --5782, -- Fear
        --33786, -- Cyclone
        --3355, -- Freezing Trap
        --209790, -- Freezing Arrow (hunter pvp)
        710, -- Banish
        --6358, -- Seduction
        --2094, -- Blind
        --19386, -- Wyvern Sting
        --82691, -- Ring of Frost
        --115078, -- Paralysis
        --115268, -- Mesmerize
        --107079, -- Quaking Palm
        --207685, -- Sigil of Misery (Havoc Demon hunter)
        --198909, -- Song of Chi-ji (mistweaver monk talent)
        6789, -- Mortal Coil
    },
    Incapacitated = {
        99, -- Incapacitating Roar
        3355, -- Freezing Trap
        209790, -- Freezing Arrow (hunter pvp)
        6770, -- Sap
        118, -- Polymorph
        115268, -- Mesmerize
        51514, -- Hex (also 211004, 210873, 211015, 211010)
        20066, -- Repentance
        200196, -- Holy Word: Chastise
        82691, -- Ring of Frost
        1776, -- Gouge
        6358, -- Seduction
        19386, -- Wyvern Sting
        115078, -- Paralysis
        31661, -- Dragon's Breath
        107079, -- Quaking Palm
        198909, -- Song of Chi-ji (mistweaver monk talent)
        203126, -- Maim (with blood trauma feral pvp talent)
    },
    Disoriented = {
        2094, -- Blind
        31661, -- Dragon's Breath
        105421, -- Bliding light (paladin talent)
        186387, -- Bursting Shot (hunter marks ability)
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        207167, -- Blinding Sleet (dk talent)
        213691, -- Scatter Shot (hunter pvp talent)
        207685, -- Sigil of Misery (Havoc Demon hunter)
        198909, -- Song of Chi-ji (mistweaver monk talent)
    },    
    Fear = {
        5782, -- Fear
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        8122, -- Psychic Scream
        87204, -- Sin and Punishment
        207685, -- Sigil of Misery (Havoc Demon hunter)
    },
    Charmed = {
        605, -- Mind Control                  
        9484, -- Shackle Undead
    },
    Sleep = {
        2637, -- Hibernate
    },
    Stuned = {
        47481, -- Gnaw (DK pet)
        212332, -- Smash (DK transformation pet)
        108194, -- Asphyxiate (DK)
        5211, -- Mighty Bash (Druid)
        117526, -- Binding Shot (Hunter)
        19577, -- Intimidation (Hunter by pet)
        119381, -- Leg Sweep (Monk)
        30283, -- Shadowfury (Warlock)
        89766, -- Axe Toss (Warlock pet)
        118905, -- Static Charge (Shaman)
        179057, -- Chaos Nova (DH)
        853, -- Hammer of Justice (Paladin)
        1833, -- Cheap Shot (Rogue)
        408, -- Kidney Shot (Rogue)
        199804, -- Between the Eyes (Rogue)
        132168, -- Shockwave (Warrior)
        132169, -- Storm Bolt (Warrior)
        163505, -- Rake
        203123, -- Maim
        64044, -- Psychic Horror (SPriest)        
    },
    PhysStuned = {
        108194, -- Asphyxiate (DK)
        5211, -- Mighty Bash (Druid)
        19577, -- Intimidation (Hunter by pet)
        119381, -- Leg Sweep (Monk)
        89766, -- Axe Toss (Warlock pet)
        1833, -- Cheap Shot (Rogue)
        408, -- Kidney Shot (Rogue)
        199804, -- Between the Eyes (Rogue)
        132168, -- Shockwave (Warrior)
        132169, -- Storm Bolt (Warrior)
        163505, -- Rake
        203123, -- Maim
    },
    Silenced = {
        15487, -- Silence        
        1330, -- Garrote - Silence
        31935, -- Avenger's Shield
        78675, -- Solar Beam
        202933, -- Spider Sting
        199683, -- Last Word
        47476, -- Strangulate
        31117, -- Unstable Affliction
        204490, -- Sigil of Silence
    },
    Disarmed = {
        207777, -- Dismantle
        236077, -- Disarm        
        233759, -- Grapple Weapon
        209749, -- Faerie Swarm
    }, 
    Rooted = {
        339, -- Entangling Roots Dispel able 
        235963, -- Entangling Roots NO Dispel able
        122, -- Frost Nova
        33395, -- Freeze (frost mage water elemental)
        45334, -- Immobilized (wild charge, bear form)
        53148, -- Charge        
        64695, -- Earthgrab
        91807, -- Shambling Rush (DK ghoul)
        102359, -- Mass Entanglement
        105771, -- Charge
        116706, -- Disable
        157997, -- Ice Nova (frost mage talent)    
        190927, -- harpoon (survival hunter)
        199042, -- Thunderstruck (Warrior PVP)
        -- 200108, -- Ranger's Net (Hunter talent) (REMOVED)
        201158, -- Super Sticky Tar (Expert Trapper, Hunter talent, Tar Trap effect)
        204085, -- Deathchill (DK PVP)
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
        228600, -- glacial spike (frost mage talent) 
        233395, -- Frozen Center (DK PvP Frost)  
        183218, -- Retri's -70%
    },  
    Slowed = {
        116, -- Frostbolt
        120, -- Cone of Cold
        2120, -- Flamestrike
        6343, -- Thunder Clap
        1715, -- Hamstring
        3409, -- Crippling Poison
        3600, -- Earthbind
        5116, -- Concussive Shot
        12544, -- Frost Armor
        7992, -- Slowing Poison
        26679, -- Deadly Throw
        35346, -- Warp Time
        44614, -- Flurry
        45524, -- Chains of Ice
        50259, -- Dazed (Wild Charge, druid talent, cat form)
        50433, -- Ankle Crack
        51490, -- Thunderstorm
        61391, -- Typhoon
        12323, -- Piercing Howl
        13810, -- Ice Trap
        15407, -- Mind Flay
        31589, -- Slow
        58180, -- Infected Wounds
        102793, -- Ursol's Vortex
        116095, -- Disable
        121253, -- Keg Smash
        123586, -- Flying Serpent Kick
        135299, -- Tar Trap
        147732, -- Frostbrand Attack
        157981, -- Blast Wave
        160065, -- Tendon Rip
        160067, -- Web Spray
        169733, -- Brutal Bash
        183218, -- Hand of Hindrance
        185763, -- Pistol Shot
        190780, -- Frost Breath (dk frost artifact ability)
        191397, -- Bestial Cunning
        194279, -- Caltrops
        194858, -- Dragonsfire Grenade
        195645, -- Wing Clip
        196840, -- Frost Shock
        198813, -- Vengeful Retreat
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205021, -- Ray of Frost (frost mage talent)
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206755, -- Ranger's Net
        206760, -- Night Terrors
        206930, -- Heart Strike
        208278, -- Debilitating Infestation (DK unholy talent)
        209786, -- Goremaw's Bite
        211793, -- Remorseless Winter
        211831, -- Abomination's Might
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        222775, -- Strike from the Shadows
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
        248744, -- Shiv
        198145, -- System Shock
    },
    MagicSlowed = {
        116, -- Frostbolt
        120, -- Cone of Cold       
        3600, -- Earthbind
        12544, -- Frost Armor
        44614, -- Flurry
        61391, -- Typhoon
        123586, -- Flying Serpent Kick
        147732, -- Frostbrand Attack
        183218, -- Hand of Hindrance
        190780, -- Frost Breath (dk frost artifact ability)
        196840, -- Frost Shock
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206760, -- Night Terrors
        209786, -- Goremaw's Bite
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
    },
    BreakAble = {
        118, -- Polymorph
        6770, -- Sap 
        20066, -- Repentance
        51514, -- Hex
        2637, -- Hibernate
        5782, -- Fear
        3355, -- Freezing Trap
        209790, -- Freezing Arrow
        6358, -- Seduction
        2094, -- Blind
        19386, -- Wyvern Sting
        82691, -- Ring of Frost
        115078, -- Paralysis        
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        6789, -- Mortal Coil
        8122, -- Psychic Scream
        99, -- Incapacitating Roar
        1776, -- Gouge
        31661, -- Dragon's Breath
        105421, -- Blinding Light
        186387, -- Bursting Shot
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        207167, -- Blinding Sleet
        213691, -- Scatter Shot        
        217832, -- Imprison
        236025, -- Enraged Maim
        207685, -- Sigil of Misery (Havoc Demon hunter)
        226943, -- Mind Bomb
        -- Rooted CC
        339, -- Entagle Roots
        212638, -- tracker's net (hunter PvP )
        102359, -- Mass Entanglement
        122, -- Frost Nova
        233395, -- Frozen Center (DK PvP Frost)
        107079, -- Quaking Palm
    },
    -- Imun Specific Buffs 
    FearImun = {
        212704, -- The Beast Within (Hunter BM PvP)
        287081, -- Lichborne
        8143, -- Tremor Totem 
    },
    StunImun = {
        48792, -- Icebound Fortitude
        6615, -- Free Action (Human)
        1953, -- Blink (micro buff)
        287081, -- Lichborne
    },        
    Freedom = {
        1044, -- Blessing of Freedom
        48265, -- Death's Advance
        287081, -- Lichborne
        212552, -- Wraith Walk
        227847, -- Bladestorm
        53271, -- Master's Call    
        116841, -- Tiger's Lust
        216113, -- Way of the Crane (Monk TT PvP)
    },
    TotalImun = {
        642, -- Divine Shield
        45438, -- Ice Block
        186265, -- Aspect of Turtle     
        215769, -- Spirit of Redemption
    },
    DamagePhysImun = {
        1022, -- Blessing of Protection
        188499, -- Blade Dance 
        196555, -- Netherwalk
    },    
    DamageMagicImun = {    -- When we can't totally damage    
        31224, -- Cloak of Shadows
        -- 710, -- Banish (can skip not often usable)
        204018, -- Blessing of Spellwarding    
        196555, -- Netherwalk
    }, 
    CCTotalImun = {
        213610, -- Holy Ward
        227847, -- Bladestorm    
    },     
    CCMagicImun = {
        31224, -- Cloak of Shadows
        204018, -- Blessing of Spellwarding    
        48707, -- Anti-Magic Shell    
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    }, 
    Reflect = {            -- Only to cancel reflect effect  
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    }, 
    KickImun = { -- Imun Silence too
        209584, -- Zen Focus Tea (Monk TT PvP)
        221703, -- Casting Circle (Warlock PvP)
        196762, -- Inner Focus
        289657, -- Holy Word: Concentration (Holy Priest PvP)
    },
    -- Purje 
    ImportantPurje = {
        1022, -- Blessing of Protection
        79206, -- Spiritwalker's Grace
        190319, -- Combustion 
        10060, -- Power Infusion
        12042, -- Arcane Power 
        12472, -- Icy Veins
        213610, -- Holy Ward
        198111, -- Temporal Shield
        210294, -- Divine Favor 
        212295, -- Nether Ward
        271466, -- Luminous Barrier
    },
    SecondPurje = {
        1044, -- Blessing of Freedom        
        -- We need purje druid only in bear form 
        33763, -- Lifebloom
        774, -- Rejuvenation
        155777, -- Rejuvenation (Germination)
        48438, -- Wild Growth    
        8936, -- Regrow 
        289318, -- Mark of the Wild
    },
    PvEPurje = {
        197797, 210662, 211632, 209033, 198745, 194615, 282098,
    },
    -- Speed 
    Speed = {
        2983, -- Sprint
        2379, -- Speed
        2645, -- Ghost Wolf
        7840, -- Swim Speed
        36554, -- Shadowstep
        54861, -- Nitro Boosts
        58875, -- Spirit Walk
        65081, -- Body and Soul
        68992, -- Darkflight
        85499, -- Speed of Light
        87023, -- Cauterize
        61684, -- Dash
        77761, -- Stampeding Roar
        108843, -- Blazing Speed
        111400, -- Burning Rush
        116841, -- Tiger's Lust
        118922, -- Posthaste
        119085, -- Chi Torpedo
        121557, -- Angelic Feather
        137452, -- Displacer Beast
        137573, -- Burst of Speed
        192082, -- Wind Rush (shaman wind rush totem talent)
        196674, -- Planewalker (warlock artifact trait)
        197023, -- Cut to the chase (rogue pvp talent)
        199407, -- Light on your feet (mistweaver monk artifact trait)
        201233, -- whirling kicks (windwalaker monk pvp talent)
        201447, -- Ride the wind (windwalaker monk pvp talent)
        209754, -- Boarding Party (rogue pvp talent)
        210980, -- Focus in the light (holy priest artifact trait)
        213177, -- swift as a coursing river (brewmaster artifact trait)
        214121, -- Body and Mind (priest talent)
        215572, -- Frothing Berserker (warrior talent)
        231390, -- Trailblazer (hunter talent)
        186257, -- Aspect of the Cheetah
        204475, -- Windburst (marks hunter artifact ability)        
    },
    -- Deff 
    DeffBuffsMagic = {
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender 
        871, -- Shield Wall
        118038, -- Die by the Sword 
        104773, -- Unending Resolve        
        108271, -- Astral Shift
        6940, -- Blessing of Sacrifice
        31224, -- Cloak of Shadows
        48707, -- Anti-Magic Shell    
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        122278, -- Dampen Harm 
        61336, -- Survival Instincts
        45182, -- Cheating Death
        204018, -- Blessing of Spellwarding
        196555, -- Netherwalk
        206803, -- Rain from Above
    }, 
    DeffBuffs = {        
        76577, -- Smoke Bomb
        53480, -- Road of Sacriface
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender        
        871, -- Shield Wall
        118038, -- Die by the Sword        
        104773, -- Unending Resolve
        6940, -- Blessing of Sacrifice
        108271, -- Astral Shift
        5277, -- Evasion
        102342, -- Ironbark
        -- 1022, -- Blessing of Protection
        74001, -- Combat Readiness
        -- 31224, -- Cloak of Shadows
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        -- 48792, -- Icebound Fortitude
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        -- 498, -- Divine Protection
        -- 157913, -- Evanesce
        115203, -- Fortifying Brew
        22812, -- Barkskin
        122278, -- Dampen Harm        
        61336, -- Survival Instincts
        45182, -- Cheating Death
        198589, -- Blur    
        196555, -- Netherwalk
        243435, -- Fortifying Brew
        206803, -- Rain from Above
    },    
    -- Damage buffs / debuffs
    Rage = {
        18499, -- Berserker Rage
        184361, -- Enrage
    }, 
    DamageBuffs = {        
        51690, -- Killing Spree
        -- 79140, -- Vendetta (debuff)
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        19574, -- Bestial Wrath
        -- 193530, -- Aspect of the Wild (small burst)
        266779, -- Coordinated Assault
        193526, -- Trueshot
        -- 5217, -- Tiger's Fury (small burst)
        106951, -- Berserk 
        102560, -- Incarnation: Chosen of Elune
        102543, -- Incarnation: King of the Jungle
        190319, -- Combustion 
        12042, -- Arcane Power                
        12472, -- Icy Veins
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy 
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar        
        114050, -- Ascendance
        113858, -- Dark Soul: Instability
        267217, -- Nether Portal
        113860, -- Dark Soul: Misery
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    DamageBuffs_Melee = {        
        51690, -- Killing Spree
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        266779, -- Coordinated Assault
        106951, -- Berserk 
        102543, -- Incarnation: King of the Jungle
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy 
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar        
        114050, -- Ascendance
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    BurstHaste = {
        90355, -- Ancient Hysteria
        146555, -- Drums of Rage
        178207, -- Drums of Fury
        230935, -- Drums of the Mountain
        2825, -- Bloodlust
        80353, -- Time Warp
        160452, -- Netherwinds
        32182, -- Heroism
    },
    -- SOME SPECIAL
    DamageDeBuffs = {
        79140, -- Vendetta (debuff)
        115080, -- Touhc of Death (debuff)
        122470, -- KARMA
    }, 
    Flags = {
        156621, -- Alliance flag
        23333,  -- Horde flag 
        34976,  -- Netherstorm Flag
        121164, -- Orb of Power
    }, 
    -- Cast Bars
    Reshift = {
        {118, 45}, -- Polymorph (45 coz of blink available)
        {20066, 30}, -- Repentance 
        {51514, 30}, -- Hex 
        {19386, 40}, -- Wyvern Sting
    },
    Premonition = {
        {113724, 30}, -- Ring of Frost 
        {118, 45}, -- Polymorph (45 coz of blink available while cast)
        {20066, 30}, -- Repentance 
        {51514, 30}, -- Hex 
        {19386, 40}, -- Wyvern Sting
        {5782, 30}, -- Fear 
    },
    CastBarsCC = {
        113724, -- Ring of Frost
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control   
    },
    AllPvPKickCasts = {    
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control 
        982, -- Revive Pet 
        32375, -- Mass Dispel 
        203286, -- Greatest Pyroblast
        116858, -- Chaos Bolt 
        20484, -- Rebirth
        203155, -- Sniper Shot 
        47540, -- Penance
        596, -- Prayer of Healing
        2060, -- Heal
        2061, -- Flash Heal
        32546, -- Binding Heal                        (priest, holy)
        33076, -- Prayer of Mending
        64843, -- Divine Hymn
        120517, -- Halo                                (priest, holy/disc)
        186263, -- Shadow Mend
        194509, -- Power Word: Radiance
        265202, -- Holy Word: Salvation                (priest, holy)
        289666, -- Greater Heal                        (priest, holy)
        740, -- Tranquility
        8936, -- Regrowth
        48438, -- Wild Growth
        289022, -- Nourish                             (druid, restoration)
        1064, -- Chain Heal
        8004, -- Healing Surge
        73920, -- Healing Rain
        77472, -- Healing Wave
        197995, -- Wellspring                          (shaman, restoration)
        207778, -- Downpour                            (shaman, restoration)
        19750, -- Flash of Light
        82326, -- Holy Light
        116670, -- Vivify
        124682, -- Enveloping Mist
        191837, -- Essence Font
        209525, -- Soothing Mist
        227344, -- Surging Mist                        (monk, mistweaver)
    },    
}
local ItemList = {
	-- Categories
    ["DPS"] = {
        [165806] = true, -- Sinister Gladiator's Maledict
    },
    ["DEFF"] = {
        [165056] = true, -- Sinister Gladiator's Emblem
        [161675] = true, -- Dread Gladiator's Emblem
        [159618] = true, -- Mchimba's Ritual Bandages (Tank Item)
    },
    ["MISC"] = {
        [159617] = true, -- Lustrous Golden Plumage 
    },
}

local function PseudoClass(methods)
    local Class = setmetatable({ extend = methods }, {
            __call = function(self, ...)
				self:New(...)
				return self.extend				 
            end,
    })
	setmetatable(Class.extend, { __index = Class })
    return Class
end

local Cache = {
	bufer = {},
	newEl = function(self, interval, keyArg, func, ...)
		local obj = {
			t = TMW.time + (interval or 0) + 0.001,  -- Add small delay to make sure what it's not previous corroute  
			v = { func(...) },   
		}        
		self.bufer[func][keyArg] = obj
		return unpack(obj.v)
	end,
	Wrap = function(this, func, name)
		if not this.bufer[func] then 
			this.bufer[func] = setmetatable({}, { __mode == "kv" })
		end 	
   		return function(...)     
	        local arg = {...} 
			local keyArg = arg[1][name] or ""
			if name == "UnitID" and arg[1][name] then 
				keyArg = UnitGUID(arg[1][name])	or ""	
			end 
	        for i = 2, #arg do
	            keyArg = keyArg .. tostring(arg[i])            
	        end 
	              
	        if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then
	            return this:newEl(arg[1].Refresh, keyArg, func, ...)
	        else
	            return unpack(this.bufer[func][keyArg].v)
	        end
        end        
    end,
}

--- PvP_Events Cache 
--- TODO: Rename or make local after rewrite first 5 released profiles
Env.PvPCache = {}
local Misc = {
	ClassIsMelee = {
        ["WARRIOR"] = true,
        ["PALADIN"] = true,
        ["HUNTER"] = false,
        ["ROGUE"] = true,
        ["PRIEST"] = false,
        ["DEATHKNIGHT"] = true,
        ["SHAMAN"] = false,
        ["MAGE"] = false,
        ["WARLOCK"] = false,
        ["MONK"] = true,
        ["DRUID"] = false,
        ["DEMONHUNTER"] = true,
    },
    Specs = {
        ["MELEE"] = {251, 252, 577, 103, 255, 269, 70, 259, 260, 261, 263, 71, 72},
        ["RANGE"] = {102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
        ["HEALER"] = {105, 270, 65, 256, 257, 264},
        ["TANK"] = {250, 581, 104, 268, 66, 73},
        ["DAMAGER"] = {251, 252, 577, 103, 255, 269, 70, 259, 260, 261, 263, 71, 72, 102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267},
    },
    ArrayEnemy = {        
        ["HEALER"] = "EnemyHealerUnitID",
        ["TANK"] = "EnemyTankUnitID",
        ["DAMAGER"] = "EnemyDamagerUnitID",
        ["DAMAGER_MELEE"] = "EnemyDamagerUnitID_Melee",
        ["DAMAGER_RANGE"] = "EnemyDamagerUnitID_Range",        
    },    
    ArrayFriendly = {        
        ["HEALER"] = "FriendlyHealerUnitID",
        ["TANK"] = "FriendlyTankUnitID",
        ["DAMAGER"] = "FriendlyDamagerUnitID",    
    },
}

--- ============================= CORE ==============================
function Env.GetAuraList(key)
    return AuraList[key]
end 

function Env.GetItemList(ket)
    return ItemList[key]
end 

local Items = TMW:GetItems("13; 14")
Env.Item = PseudoClass({
	IsForbidden = { 
		-- Crest of Pa'ku
		[165581] = true, 
	},
	IsDPS = Cache:Wrap(function(self)       
			local ID = Items[self.Slot]:GetID() or 0
	        return not ItemList["DEFF"][ID] 
	end, "Slot"),
	IsDEFF = Cache:Wrap(function(self)       
			local ID = Items[self.Slot]:GetID() or 0
	        return not ItemList["DPS"][ID] 
	end, "Slot"),
	IsUsable = Cache:Wrap(function(self) 
			local ID = Items[self.Slot]:GetID() or 0
			local start, duration, enable = Items[self.Slot]:GetCooldown()
	        return enable ~= 0 and (duration == 0 or duration - (TMW.time - start) <= 0.02) and Items[self.Slot]:GetEquipped() and not self.IsForbidden[ID] 
	end, "Slot"),	
	GetID = Cache:Wrap(function(self)   			
	        return Items[self.Slot]:GetID() or 0
	end, "Slot"),	
})
function Env.Item:New(Slot, Refresh)
	self.Slot = Slot == 13 and 1 or Slot == 14 and 2 or Slot 
    self.Refresh = Refresh or 0.1
end 

Env.Unit = PseudoClass({
	IsBoss = Cache:Wrap(function(self)       
	        return Env.UNITBoss(self.UnitID) 
	end, "UnitID"),
	IsEnemy = Cache:Wrap(function(self)       
	        return Env.UNITEnemy(self.UnitID)
	end, "UnitID"),
	IsHealer = Cache:Wrap(function(self)       
	        if Env.Unit(self.UnitID):IsEnemy() then
				return (Env.PvPCache["EnemyHealerUnitID"] and Env.PvPCache["EnemyHealerUnitID"][self.UnitID]) or Env.UNITSpec(self.UnitID, Misc.Specs["HEALER"])  
			else 
				return (Env.PvPCache["FriendlyHealerUnitID"] and Env.PvPCache["FriendlyHealerUnitID"][self.UnitID]) or Env.UNITRole(self.UnitID, "HEALER")
			end 
	end, "UnitID"),
	IsTank = Cache:Wrap(function(self)       
	        if Env.Unit(self.UnitID):IsEnemy() then
				return (Env.PvPCache["EnemyTankUnitID"] and Env.PvPCache["EnemyTankUnitID"][self.UnitID]) or Env.UNITSpec(self.UnitID, Misc.Specs["TANK"])  
			else 
				return (Env.PvPCache["FriendlyTankUnitID"] and Env.PvPCache["FriendlyTankUnitID"][self.UnitID]) or Env.UNITRole(self.UnitID, "TANK")
			end 
	end, "UnitID"),
	IsTanking = Cache:Wrap(function(self, otherunit)  
			local ThreatThreshold = ThreatThreshold or 2
			local ThreatSituation = UnitThreatSituation(self.UnitID, otherunit)
			return ThreatSituation and ThreatSituation >= ThreatThreshold or UnitIsUnit(self.UnitID, otherunit .. "target") or false	       
	end, "UnitID"),
	IsMelee = Cache:Wrap(function(self)       
	        if Env.Unit(self.UnitID):IsEnemy() then
				return (Env.PvPCache["EnemyDamagerUnitID_Melee"] and Env.PvPCache["EnemyDamagerUnitID_Melee"][self.UnitID]) or Env.UNITSpec(self.UnitID, Misc.Specs["MELEE"])  
			elseif Env.UNITRole(self.UnitID, "DAMAGER") or Env.UNITRole(self.UnitID, "TANK") then 
				local _, uClass = UnitClass(self.UnitID)
				if uClass == "HUNTER" then 
					return 
					(
						SpellCounter(self.UnitID, 186270) > 0 or -- Raptor Strike
						SpellCounter(self.UnitID, 259387) > 0 or -- Mongoose Bite
						SpellCounter(self.UnitID, 190925) > 0 or -- Harpoon
						SpellCounter(self.UnitID, 259495) > 0    -- Firebomb
					)
				elseif uClass == "SHAMAN" then 
					local _, offhand = UnitAttackSpeed(self.UnitID)
					return offhand ~= nil                    
				elseif uClass == "DRUID" then 
					local _, power = UnitPowerType(self.UnitID)
					return power == "ENERGY" or power == "FURY"
				else 
					return Misc.ClassIsMelee[uClass]
				end 
			end 
	end, "UnitID"),
	DeBuffCyclone = Cache:Wrap(function(self)
		return Env.DeBuffs(self.UnitID, 33786)
	end, "UnitID"),
	HasDeBuffs = Cache:Wrap(function(self, key, caster)
        local value, duration = 0, 0
        if Env.Unit(self.UnitID):DeBuffCyclone() > 0 then 
            value, duration = -1, -1
        else
            value, duration = Env.SortDeBuffs(self.UnitID, ((type(key) == "string" and AuraList[key]) or key), caster) 
        end    
        return value, duration   
    end, "UnitID"),
	HasBuffs = Cache:Wrap(function(self, key, caster)
	        local value, duration = 0, 0
	        if Env.Unit(self.UnitID):DeBuffCyclone() > 0 then 
	            value, duration = -1, -1
	        else
	            value, duration = Env.Buffs(self.UnitID, ((type(key) == "string" and AuraList[key]) or key), caster) 
	        end         
	        return value, duration
	end, "UnitID"),
	HasFlags = Cache:Wrap(function(self)
	        return Env.Unit(self.UnitID):HasBuffs({156621, 156618, 34976}) > 0 or Env.Unit(self.UnitID):HasDeBuffs(121177) > 0 
	end, "UnitID"),
	GetRange = Cache:Wrap(function(self)
	        return Env.UNITRange(self.UnitID)  
	end, "UnitID"),
	WithOutKarmed = Cache:Wrap(function(self)
	        local value = true -- Default as without always
			if Env.Unit(self.UnitID):IsEnemy() then
				if Env.PvPCache["Group_FriendlySize"] and Env.PvPCache["Group_FriendlySize"] > 0 and Env.Unit(self.UnitID):HasBuffs(122470) > 0 then 
					value = false
					for i = 1, Env.PvPCache["Group_FriendlySize"] do
						local member = Env.PvPCache["Group_FriendlyType"] .. i
						if Env.Unit(member):HasDeBuffs(25771) >= 20 then -- Forbearance
							value = true 
							break 
						end                     
					end        
				end
			else
				if Env.PvPCache["Group_EnemySize"] and Env.PvPCache["Group_EnemySize"] > 0 and Env.Unit(self.UnitID):HasBuffs(122470) > 0 then 
					value = false
					for i = 1, Env.PvPCache["Group_EnemySize"] do
						local arena = Env.PvPCache["Group_EnemySize"] .. i
						if Env.Unit(arena):HasDeBuffs(25771) >= 20 then -- Forbearance
							value = true 
							break 
						end                     
					end        
				end
			end  
			return value
	end, "UnitID"),
	IsFocused = Cache:Wrap(function(self, specs, burst, deffensive, range)
			local value = false -- Default
			if Env.Unit(self.UnitID):IsEnemy() then
				if tableexist(Env.PvPCache["FriendlyDamagerUnitID"]) then     
					for k, member in pairs(Env.PvPCache["FriendlyDamagerUnitID"]) do 
						if UnitIsUnit(member .. "target", self.UnitID) 
						and (not specs or (specs == "MELEE" and Env.Unit(member):IsMelee()))
						and (not burst or Env.Unit(member):HasBuffs("DamageBuffs") > 2) 
						and (not deffensive or Env.Unit(self.UnitID):HasBuffs("DeffBuffs") < 2)
						and (not range or Env.Unit(member):GetRange() <= range) then 
							value = true 
							break 
						end
					end 
				end
			else
				if tableexist(Env.PvPCache["EnemyDamagerUnitID"]) then 
					-- TYPES AND ROLES
					specs = Misc.Specs[specs] or specs or false
					for k, arena in pairs(Env.PvPCache["EnemyDamagerUnitID"]) do
						if UnitIsUnit(arena .. "target", self.UnitID) 
						and (not specs or Env.UNITSpec(arena, specs))
						and (not burst or Env.Unit(arena):HasBuffs("DamageBuffs") > 2) 
						and (not deffensive or Env.Unit(self.UnitID):HasBuffs("DeffBuffs") < 2)
						and (not range or Env.Unit(arena):GetRange() <= range) then 
							value = true 
							break
						end
					end 
				end
			end 
	        return value 
	end, "UnitID"),
	IsExecuted = Cache:Wrap(function(self)
			local value = false -- Default is not available to be executed
			if Env.Unit(self.UnitID):IsEnemy() then
				value = TimeToDieX(self.UnitID, 20) <= Env.GCD() + Env.CurrentTimeGCD()
			else
				if tableexist(Env.PvPCache["EnemyDamagerUnitID_Melee"]) and TimeToDieX(self.UnitID, 20) <= Env.GCD() + Env.CurrentTimeGCD() then
					for k, arena in pairs(Env.PvPCache["EnemyDamagerUnitID_Melee"]) do 
						if Env.UNITSpec(arena, {71, 72}) and UnitIsUnit(arena .. "target", self.UnitID) and UnitPower(arena) >= 20 and (self.UnitID ~= "player" or Env.Unit(arena):GetRange() < 7) then 
							value = true 
							break
						end
					end
				end
			end 
	        return value
	end, "UnitID"),
	UseBurst = Cache:Wrap(function(self, pBurst)
			local unit = self.UnitID
			local value = false
			if Env.Unit(unit):IsEnemy() then
				value = UnitIsPlayer(unit) and 
				(
					Env.Zone == "none" or 
					TimeToDieX(unit, 25) <= Env.GCD() * 4 or
					(
						Env.Unit(unit):IsHealer() and 
						(
							(
								CombatTime(unit) > 5 and 
								TimeToDie(unit) <= 10 and 
								Env.Unit(unit):HasBuffs("DeffBuffs") == 0                      
							) or
							Env.Unit(unit):HasDeBuffs("Silenced") >= Env.GCD() * 2 or 
							Env.Unit(unit):HasDeBuffs("Stuned") >= Env.GCD() * 2                         
						)
					) or 
					Env.Unit(unit):IsFocused(nil, true) or 
					Env.EnemyTeam("HEALER"):GetCC() >= Env.GCD() * 3 or
					(
						pBurst and 
						Env.Unit("player", 1):HasBuffs("DamageBuffs") >= Env.GCD() * 3
					)
				)       
			elseif Env.IamHealer then 
				-- For HealingEngine as Healer
				value = UnitIsPlayer(unit) and 
				(
					Env.Unit(unit):IsExecuted() or
					(
						Env.Unit(unit):HasFlags() and                                         
						CombatTime(unit) > 0 and 
						getRealTimeDMG(unit) > 0 and 
						TimeToDie(unit) <= 14 and 
						(
							TimeToDie(unit) <= 8 or 
							Env.Unit(unit):HasBuffs("DeffBuffs") < 1                         
						)
					) or 
					(
						Env.Unit(unit):IsFocused(nil, true) and 
						(
							TimeToDie(unit) <= 10 or 
							Env.UNITHP(unit) <= 70
						)
					) 
				)                   
			end 
	        return value 
	end, "UnitID"),
	UseDeff = Cache:Wrap(function(self)
	        return 
			(
				Env.Unit(self.UnitID):IsFocused(nil, true) or 
				(
					TimeToDie(self.UnitID) < 8 and 
					Env.Unit(self.UnitID):IsFocused() 
				) or 
				Env.Unit(self.UnitID):HasDeBuffs("DamageDeBuffs") > 5 or 
				Env.Unit(self.UnitID):IsExecuted()
			) 			
	end, "UnitID"),
	IsTotem = Cache:Wrap(function(self)
			local cType = UnitCreatureType(self.UnitID)
			return
			(
				cType and 
				(
					cType == "Totem" or 
					cType == "Tótem" or 
					cType == "Totém" or 
					cType == "Тотем" or 
					cType == "토템" or 
					cType == "图腾" or 
					cType == "圖騰"
				)
			) or false  	       	
	end, "UnitID"),
	InCC = Cache:Wrap(function(self)
			local value = Env.Unit(self.UnitID):DeBuffCyclone()
			if value == 0 then 
				for _, NAME in pairs({"Silenced", "Stuned", "Sleep", "Charmed", "Fear", "Disoriented", "Incapacitated", "CrowdControl"}) do 
					value = Env.Unit(self.UnitID):HasDeBuffs(NAME)
					if value > 0 then 
						break
					end 
				end 
			end	    
			return value 
	end, "UnitID"),
})
function Env.Unit:New(UnitID, Refresh)
	self.UnitID = UnitID
	self.Refresh = Refresh or 0.05
end

Env.EnemyTeam = PseudoClass({
	GetUnitID = Cache:Wrap(function(self, range)
			local value = "none" 
			if tableexist(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) then 
				for k, arena in pairs(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) do
					if not Env.UNITDead(arena) and (not range or Env.Unit(arena):GetRange() <= range) then 
						value = arena 
						break 
					end 
				end 
			end 
	        return value 
	end, "ROLE"),
	-- Some functions has second returnment "unitid" whose conditions was passed
	GetCC = Cache:Wrap(function(self, spells)
			local value, arena = 0, "none"
			if tableexist(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) then 
				for _, arena in pairs(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) do
					if spells then 
						value = Env.Unit(arena):HasDeBuffs(spells) 
					elseif (self.ROLE ~= "HEALER" or not UnitIsUnit(arena, "target")) then 
						-- Hex, Cyclone, Wyvern Sting, Sleep 
						value = Env.Unit(arena):HasDeBuffs({51514, 33786, 19386, 2637}) 
						if value > 0 then                         
							break 
						else  
							for _, types in pairs({"Stuned", "Silenced", "Fear", "CrowdControl", "Incapacitated", "Disoriented", "Charmed"}) do 
								value = Env.Unit(arena):HasDeBuffs(types)
								if value > 0 then                                 
									break 
								end                     
							end 
						end
					end 
					if value > 0 then                                 
						break 
					end  
				end             
			end 
	        return value, arena 
	end, "ROLE"),
	GetBuffs = Cache:Wrap(function(self, Buffs, range)
			local value, arena = 0, "none"
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) then 
				for _, arena in pairs(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) do
					if (not range or Env.Unit(arena):GetRange() <= range) then
						value = Env.Unit(arena):HasBuffs(Buffs)                     
					end 
					if value > 0 then 
						break
					end
				end 
			elseif tableexist(Env.PvPCache["Group_EnemySize"]) then
				for i = 1, Env.PvPCache["Group_EnemySize"] do
					arena = "arena" .. i
					if (not range or Env.Unit(arena):GetRange() <= range) then
						value = Env.Unit(arena):HasBuffs(Buffs)                     
					end 
					if value > 0 then 
						break
					end         
				end  
			end  
	        return value, arena 
	end, "ROLE"),
	GetDeBuffs = Cache:Wrap(function(self, DeBuffs, range)
			local value, arena = 0, "none"
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) then 
				for _, arena in pairs(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) do
					if (not range or Env.Unit(arena):GetRange() <= range) then
						value = Env.Unit(arena):HasDeBuffs(DeBuffs)                     
					end 
					if value > 0 then 
						break
					end
				end 
			elseif tableexist(Env.PvPCache["Group_EnemySize"]) then
				for i = 1, Env.PvPCache["Group_EnemySize"] do
					arena = "arena" .. i
					if (not range or Env.Unit(arena):GetRange() <= range) then
						value = Env.Unit(arena):HasDeBuffs(DeBuffs)                     
					end 
					if value > 0 then 
						break
					end         
				end  
			end   
	        return value, arena 
	end, "ROLE"),
	IsBreakAble = Cache:Wrap(function(self, range)
			local value, arena = false, "none"
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) then 
				for _, arena in pairs(Env.PvPCache[Misc.ArrayEnemy[self.ROLE]]) do
					if not UnitIsUnit(arena, "target") and (not range or Env.Unit(arena):GetRange() <= range) and Env.Unit(arena):HasDeBuffs("BreakAble") > 0 then
						value = true 
						break
					end 
				end 
			else
				for refference, arena in pairs(GetActiveUnitPlates("enemy")) do               
					if UnitIsPlayer(arena) and not UnitIsUnit("target", arena) and (not range or Env.Unit(arena):GetRange() <= range) and Env.Unit(arena):HasDeBuffs("BreakAble") > 0 then
						value = true 
						break
					end            
				end  
			end 
	        return value, arena 
	end, "ROLE"),
	IsTauntPetAble = Cache:Wrap(function(self, spellID)
			local value, pet = false, "none"
			if tableexist(Env.PvPCache["Group_EnemySize"]) then
				for i = 1, 3 do                
					pet = "arenapet" .. i 
					if UnitExists(pet) and (not spellID or Env.SpellInRange(pet, spellID)) then 
						value = true 
						break 
					end              
				end  
			end
	        return value, pet 
	end, "ROLE"),
	IsReshiftAble = Cache:Wrap(function(self, offset)
			local value, arena = false, "none"
			if tableexist(Env.PvPCache["Group_EnemySize"]) then  
				if not offset then offset = 0.05 end
				for i = 1, Env.PvPCache["Group_EnemySize"] do 
					arena = "arena" .. i
					local _, left, _, _, spellNAME = Env.CastTime(nil, arena)
					if left > 0 and left <= Env.CurrentTimeGCD() + Env.GCD() + offset then 
						for i = 1, #AuraList["Reshift"] do 
							if GetSpellInfo(AuraList["Reshift"][i][1]) == spellNAME and Env.Unit(arena):GetRange() <= AuraList["Reshift"][i][2] and not Env.Unit("player"):IsFocused("MELEE") then 
								value = true 
								break
							end
						end
					end
					if value then 
						break
					end
				end
			end 
	        return value, arena 
	end, "ROLE"), 
	IsPremonitionAble = Cache:Wrap(function(self, offset)
			local value, arena = false, "none"
			if tableexist(Env.PvPCache["Group_EnemySize"]) then  
				if not offset then offset = 0.05 end
				for i = 1, Env.PvPCache["Group_EnemySize"] do 
					arena = "arena" .. i
					local _, left, _, _, spellNAME = Env.CastTime(nil, arena)
					if left > 0 and left <= Env.GCD() + offset then 
						for i = 1, #AuraList["Premonition"] do 
							if GetSpellInfo(AuraList["Premonition"][i][1]) == spellNAME and Env.Unit(arena):GetRange() <= AuraList["Premonition"][i][2] then 
								value = true 
								break
							end
						end
					end
					if value then 
						break
					end
				end
			end  
	        return value, arena
	end, "ROLE"),
})
function Env.EnemyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.125             
end

Env.FriendlyTeam = PseudoClass({
	GetUnitID = Cache:Wrap(function(self, range)
			local value = "none" 
			if tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for k, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) and not Env.UNITDead(member) and (not range or Env.Unit(member):GetRange() <= range) then 
						value = member 
						break 
					end 
				end 
			end 
	        return value 
	end, "ROLE"),
	GetCC = Cache:Wrap(function(self, spells)
			local value = 0
			if tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do    
					-- Here is no need UnitInRange
					if spells then 
						value = Env.Unit(member):HasDeBuffs(spells) 
					else
						-- Hex, Cyclone, Wyvern Sting, Sleep 
						value = Env.Unit(member):HasDeBuffs({51514, 33786, 19386, 2637}) 
						if value > 0 then                         
							break 
						else  
							for _, types in pairs({"Stuned", "Silenced", "Fear", "CrowdControl", "Incapacitated", "Disoriented", "Charmed"}) do 
								value = Env.Unit(member):HasDeBuffs(types)
								if value > 0 then                                 
									break 
								end                     
							end 
						end
					end 
					if value > 0 then                                 
						break 
					end                   
				end             
			end
	        return value 
	end, "ROLE"),
	GetBuffs = Cache:Wrap(function(self, Buffs, range, iSource)
			local value = 0
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) and (not range or Env.Unit(member):GetRange() <= range) then
						value = Env.Unit(member):HasBuffs(Buffs, iSource)     
						if value > 0 then 
							break
						end
					end                 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if UnitInRange(member) and (not range or Env.Unit(member):GetRange() <= range) then
						value = Env.Unit(member):HasBuffs(Buffs, iSource)     
						if value > 0 then 
							break
						end  
					end                       
				end  
			end
	        return value 
	end, "ROLE"),
	GetDeBuffs = Cache:Wrap(function(self, DeBuffs, range)
			local value = 0
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) and (not range or Env.Unit(member):GetRange() <= range) then
						value = Env.Unit(member):HasDeBuffs(DeBuffs, iSource)     
						if value > 0 then 
							break
						end
					end 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if UnitInRange(member) and (not range or Env.Unit(member):GetRange() <= range) then
						value = Env.Unit(member):HasDeBuffs(DeBuffs, iSource) 
						if value > 0 then 
							break
						end                     
					end                        
				end  
			end 
	        return value 
	end, "ROLE"),
	GetTTD = Cache:Wrap(function(self, count, seconds)
			local value = false
			local counter =  0
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) and TimeToDie(member) <= seconds then
						counter = counter + 1     
						if counter >= count then 
							value = true
							break
						end
					end 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if UnitInRange(member) and TimeToDie(member) <= seconds then
						counter = counter + 1     
						if counter >= count then 
							value = true
							break
						end
					end                        
				end  
			end
	        return value 
	end, "ROLE"),
	AverageTTD = Cache:Wrap(function(self)
			local value, members = 0, 0
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) then                     
						value = value + TimeToDie(member)
						members = members + 1
					end 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if UnitInRange(member) then                     
						value = value + TimeToDie(member)
						members = members + 1
					end                    
				end  
			end  
			if members > 0 then 
				value = value / members
			end 
	        return value 
	end, "ROLE"),	
	MissedBuffs = Cache:Wrap(function(self, spells, iSource)
			local value = false
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if UnitInRange(member) and not Env.UNITDead(member) and Env.Unit(member):HasBuffs(spells, iSource) == 0 then
						value = true 
						break
					end 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if UnitInRange(member) and not Env.UNITDead(member) and Env.Unit(member):HasBuffs(spells, iSource) == 0 then
						value = true 
						break
					end                        
				end  
			end
	        return value, member 
	end, "ROLE"),
	HealerIsFocused = Cache:Wrap(function(self, burst, deffensive, range)
			local value = false
			if tableexist(Env.PvPCache[Misc.ArrayFriendly["HEALER"]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly["HEALER"]]) do
					if UnitInRange(member) and Env.Unit(member):IsFocused(nil, burst, deffensive, range) then
						value = true 
						break                    
					end 
				end 
			end  
	        return value, member 
	end, "ROLE"),
	ArcaneTorrentMindControl = Cache:Wrap(function(self)
			local value = false
			if self.ROLE and tableexist(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) then 
				for _, member in pairs(Env.PvPCache[Misc.ArrayFriendly[self.ROLE]]) do
					if Env.Unit(member):HasBuffs(605) > 0 and Env.Unit(member):GetRange() <= 8 then
						value = true 
						break
					end 
				end 
			elseif tableexist(Env.PvPCache["Group_FriendlySize"]) then
				for i = 1, Env.PvPCache["Group_FriendlySize"] do
					local member = Env.PvPCache["Group_FriendlyType"] .. i
					if Env.Unit(member):HasBuffs(605) > 0 and Env.Unit(member):GetRange() <= 8 then
						value = true 
						break
					end                        
				end  
			end 
	        return value, member 
	end, "ROLE"),
})
function Env.FriendlyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.125                      
end

--- ========================== FUNCTIONAL ===========================
--- Note: [required] unit, [optional, always table] spells, [optional, number] range 
function Env.MultiCast(unit, spells, range)
    -- 1: Total CastTime, 2: Current CastingTime Left, 3: Current CastingTime Percent (from 0% as start til 100% as finish)
    -- 4: SpellID and 5: SpellName
    local total, tleft, pleft, id, spellname = 0, 0, 0, 0, 0
    if unit and (not range or Env.Unit(unit):GetRange() <= range) then
        local query = (type(spells) == "table" and spells) or AuraList.CastBarsCC               
        for i = 1, #query do 
            total, tleft, pleft, id, spellname = Env.CastTime(query[i], unit)
            if tleft > 0 then 
                break
            end 
        end         
    end    
    return total, tleft, pleft, id, spellname
end

-- UNIT Moving (out or in) 
local MoveCache = {}
local function addToMove(GUID, unitID, mode)
	local range = select(2, Env.UNITRange(unitID))
	MoveCache[unitID] = {
		["in"] = {
			["MovingTimeStamp"] = TMW.time,
			["MovingRangeStamp"] = range,
			["MovingSnapshot"] = mode == "in" and 1 or 0,
			["MovingCache"] = false,
			["MovingGUID"] = GUID,
		},
		["out"] = {
			["MovingTimeStamp"] = TMW.time,
			["MovingRangeStamp"] = range,
			["MovingSnapshot"] = mode == "out" and 1 or 0,
			["MovingCache"] = false,
			["MovingGUID"] = GUID,
		},
	}
end 

function Env.UNITMoving(unitID, mode) 
	local unitspeed = Env.UNITCurrentSpeed(unitID) 
	local result = false 
	if unitspeed > 0 then 
        if unitspeed == Env.UNITCurrentSpeed("player") then 
            result = true 
        else						
			local GUID = UnitGUID(unitID)
			if not MoveCache[unitID] or MoveCache[unitID][mode]["MovingGUID"] ~= GUID then
				addToMove(GUID, unitID, mode) 
				return result 
			end 
			
			if TMW.time - MoveCache[unitID][mode]["MovingTimeStamp"] > 0.25 then 
                local range = Env.LibRangeCheck:GetRange(unitID) 
                MoveCache[unitID][mode]["MovingTimeStamp"] = TMW.time     			-- Reset
                if range ~= MoveCache[unitID][mode]["MovingRangeStamp"] then 		-- Make snapshot only if range has been changed
                    if mode == "out" then 
                        if range > MoveCache[unitID][mode]["MovingRangeStamp"] then 
                            MoveCache[unitID][mode]["MovingSnapshot"] = MoveCache[unitID][mode]["MovingSnapshot"] + 1
                        else 
                            MoveCache[unitID][mode]["MovingSnapshot"] = MoveCache[unitID][mode]["MovingSnapshot"] - 1
                        end
                    else 
                        if range < MoveCache[unitID][mode]["MovingRangeStamp"] then 
                            MoveCache[unitID][mode]["MovingSnapshot"] = MoveCache[unitID][mode]["MovingSnapshot"] + 1 
                        else 
                            MoveCache[unitID][mode]["MovingSnapshot"] = MoveCache[unitID][mode]["MovingSnapshot"] - 1
                        end
                    end                
                    MoveCache[unitID][mode]["MovingRangeStamp"] = range     		-- Reset
                    if MoveCache[unitID][mode]["MovingSnapshot"] >= 3 then   
                        result = true
                        MoveCache[unitID][mode]["MovingCache"] = result        		-- Save in Cache                    
                        MoveCache[unitID][mode]["MovingSnapshot"] = 2       		-- Reset  
                    else 
                        result = false
                        MoveCache[unitID][mode]["MovingCache"] = result    
                    end
                else 
                    result = MoveCache[unitID][mode]["MovingCache"] 
                end                               
            else                                                     				-- Cache
                result = MoveCache[unitID][mode]["MovingCache"]    
            end
		end  
	end 
	return result 
end

--- ========================== LOS SYSTEM ===========================
--- When GCD is ready only
local InLOS, LOSUnit, InLOSCache = dynamic_array(2), nil, {}
Listener:Add('PvP_Events_Logs', "COMBAT_LOG_EVENT_UNFILTERED", function()
        -- Reset LOS for unit if spell has been casted on him        
        if LOSCheck then
            local _, event, _, SourceGUID, _,_,_, DestGUID = CombatLogGetCurrentEventInfo()
            if event == "SPELL_CAST_SUCCESS" and SourceGUID == UnitGUID("player") and next(InLOSCache) then 
                for k, v in pairs(InLOSCache) do
                    if v and (DestGUID == UnitGUID(v) or DestGUID == v) then
                        InLOS[v]["unit_time"] = nil
                        InLOS[v]["unit_LOS"] = nil
                        InLOSCache[v] = nil -- Remove from query cache already lost units
                        if LOSUnit == v then 
                            LOSUnit = nil
                        end
                    end 
                end                 
            end            
        end
end)

Listener:Add('PvP_Events_UI', "UI_ERROR_MESSAGE", function(...)
        if LOSCheck and ... == 50 and LOSUnit and not InLOS[LOSUnit]["unit_LOS"] and InLOS[LOSUnit]["unit_time"] and TMW.time >= InLOS[LOSUnit]["unit_time"] then
            local skip_timer = 3.5
            -- Fix for HealingEngine on targets by GUID 
            if not string.find(LOSUnit, "party") 
            and not string.find(LOSUnit, "raid") 
            and not string.find(LOSUnit, "arena") then
                -- Check that current target is still same unit which should be checked for los 
                if UnitGUID("target") ~= LOSUnit then 
                    return -- skip
                end
                if Env.Zone == "arena" then 
                    skip_timer = 2 
                else 
                    skip_timer = 8.5
                end 
            end
            InLOS[LOSUnit]["unit_LOS"] = TMW.time + skip_timer -- Skip
            InLOSCache[LOSUnit] = LOSUnit  
            LOSUnit = nil -- Now we can check another unit 
        end
end)

function GetLOS(unit) -- Physical button call   
    if LOSCheck and TMW.GCD == 0 and (not InLOS[unit]["unit_LOS"] or TMW.time >= InLOS[unit]["unit_LOS"]) and (not InLOS[unit]["unit_time"] or TMW.time >= InLOS[unit]["unit_time"]) then 
        LOSUnit = unit
        InLOS[unit]["unit_time"] = TMW.time + 0.3 --start time (0.3 delay added to skip wrong event from another key)
        InLOS[unit]["unit_LOS"] = nil --reset skip time since now we need again check if he's in los
        InLOSCache[unit] = nil -- Remove from query cache already lost units
    end
end

function Env.InLOS(unit)
    return LOSCheck and InLOS[unit]["unit_LOS"] and TMW.time < InLOS[unit]["unit_LOS"]
end

--- ============================ EVENTS =============================
local function GroupZoneUpdate() 	
	if next(Env.PvPCache) then 
		wipe(Env.PvPCache)
	end                                  
	
	-- Enemy                
	if Env.Zone == "arena" then 
		Env.PvPCache["Group_EnemySize"] = GetNumArenaOpponents() --GetNumArenaOpponentSpecs()                
	elseif Env.Zone == "pvp" then
		RequestBattlefieldScoreData()                
		Env.PvPCache["Group_EnemySize"] = GetNumBattlefieldScores()                 
	else
		Env.PvPCache["Group_EnemySize"] = 0 
	end
	-- Get all enemy healers/tanks/damagers
	Env.PvPCache["EnemyHealerUnitID"] = {} 
	Env.PvPCache["EnemyTankUnitID"] = {} 
	Env.PvPCache["EnemyDamagerUnitID"] = {} 
	Env.PvPCache["EnemyDamagerUnitID_Melee"] = {} 
	Env.PvPCache["EnemyDamagerUnitID_Range"] = {} 
	if Env.PvPCache["Group_EnemySize"] > 0 then                
		for i = 1, Env.PvPCache["Group_EnemySize"] do 
			local arena = "arena" .. i
			if Env.Unit(arena):IsHealer() then 
				Env.PvPCache["EnemyHealerUnitID"][arena] = arena
			elseif Env.Unit(arena):IsTank() then 
				Env.PvPCache["EnemyTankUnitID"][arena] = arena
			else
				Env.PvPCache["EnemyDamagerUnitID"][arena] = arena
				if Env.Unit(arena):IsMelee() then 
					Env.PvPCache["EnemyDamagerUnitID_Melee"][arena] = arena
				else 
					Env.PvPCache["EnemyDamagerUnitID_Range"][arena] = arena
				end                        
			end
		end   
	end          
	
	-- Friendly
	Env.PvPCache["Group_FriendlySize"] = GetNumGroupMembers()
	if IsInRaid() then
		Env.PvPCache["Group_FriendlyType"] = "raid"
	elseif IsInGroup() then
		Env.PvPCache["Group_FriendlyType"] = "party"    
	else 
		Env.PvPCache["Group_FriendlyType"] = "none"
	end                
	-- Get our healers/tanks/damagers
	Env.PvPCache["FriendlyHealerUnitID"] = {} 
	Env.PvPCache["FriendlyTankUnitID"] = {} 
	Env.PvPCache["FriendlyDamagerUnitID"] = {}  
	Env.PvPCache["FriendlyMeleeUnitID"] = {}
	Env.PvPCache["FriendlyMeleeCounter"] = 0
	if Env.PvPCache["Group_FriendlyType"] ~= "none" then 
		for i = 1, Env.PvPCache["Group_FriendlySize"] do 
			local member = Env.PvPCache["Group_FriendlyType"] .. i            
			if not UnitIsUnit(member, "player") then 
				if Env.Unit(member):IsHealer() then 
					Env.PvPCache["FriendlyHealerUnitID"][member] = member
				elseif Env.Unit(member):IsTank() then  
					Env.PvPCache["FriendlyTankUnitID"][member] = member
					Env.PvPCache["FriendlyMeleeCounter"] = Env.PvPCache["FriendlyMeleeCounter"] + 1
				else 
					Env.PvPCache["FriendlyDamagerUnitID"][member] = member
					if Env.Unit(member):IsMelee() then 
						Env.PvPCache["FriendlyMeleeUnitID"][member] = member
						Env.PvPCache["FriendlyMeleeCounter"] = Env.PvPCache["FriendlyMeleeCounter"] + 1
					end 
				end
			end
		end 
	end
end 
Listener:Add('PvP_Events', "UPDATE_INSTANCE_INFO", GroupZoneUpdate)                
Listener:Add('PvP_Events', "GROUP_ROSTER_UPDATE", GroupZoneUpdate) 
Listener:Add('PvP_Events', "ARENA_OPPONENT_UPDATE", GroupZoneUpdate) 
Listener:Add('PvP_Events', "PLAYER_ENTERING_WORLD", GroupZoneUpdate) 
Listener:Add('PvP_Events', "PLAYER_LOGIN", GroupZoneUpdate)

Listener:Add('PvP_Events_Wipe', 'PLAYER_REGEN_ENABLED', function()    
		-- Reset Moving 
		wipe(MoveCache)
		-- Reset LOS 
		wipe(InLOS)
		wipe(InLOSCache)
end)

Listener:Add('PvP_Events_Wipe', 'PLAYER_REGEN_DISABLED', function() 
		-- Do not reset Moving here because we should know movement vector before combat
		-- Reset LOS 
		wipe(InLOS)
		wipe(InLOSCache)
end)

--- ===================== 2.0 REFFERENCE (OLD) ======================
-- Remaping for profiles until Monk release
function Env.Potion(itemID)
	local start, duration, enable = GetItemCooldown(itemID)
	-- Enable will be 0 for things like a potion that was used in combat 
	if enable ~= 0 and (duration == 0 or duration - (TMW.time - start) == 0)  then
        return true
    end    
    return false 
end 
Env.PvP = {
	Unit = Env.Unit,
	EnemyTeam = Env.EnemyTeam,
	FriendlyTeam = Env.FriendlyTeam,
	MultiCast = Env.MultiCast,
}
function Env.PvP.GetAuraList(key)
    return AuraList[key]
end 
function Env.PvP.GetItemList(ket)
    return ItemList[key]
end 
--- ===================== 1.0 REFFERENCE (OLD) ======================
function Env.PvPKarma(unit) 
    -- True: Is not applied / False: Applied
    return Env.Unit(unit):WithOutKarmed()
end
function Env.PvPDeBuffs(unit, spells)    
    return Env.Unit(unit):HasDeBuffs(spells)
end
function Env.PvPBuffs(unit, spells) 
    return Env.Unit(unit):HasBuffs(spells)     
end
-- DamagerBurst
function Env.PvPUseBurst(unit, Assist, EnemyHealerInCC)
    return Env.Unit(unit or "target"):UseBurst()              
end
function Env.PvPNeedDeff(unit)
    return Env.Unit(unit or "player"):UseDeff()
end
function Env.PvPTargeting(unit)
    return Env.Unit(unit):IsFocused()
end
function Env.PvPTargeting_Melee(unit, burst)   
    return Env.Unit(unit):IsFocused(Misc.Specs["MELEE"])
end
function Env.PvPTargeting_BySpecs(array, specs, unit, range, burst)
    return Env.Unit(unit):IsFocused(specs, burst, nil, range)
end
function Env.PvPExecuteRisk(unit)
    return Env.Unit(unit):IsExecuted()
end
-- Helper
function Env.PvPEnemyUsedBurst(range) 
    return Env.EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", range ~= "arena" and range or nil)
end
function Env.PvPEnemyBurst(unit, checkdeff)
    if unit == "HEALER" then
        return Env.FriendlyTeam(unit):HealerIsFocused(true, checkdeff)
    else 
        return Env.Unit(unit):IsFocused(nil, true, checkdeff)
    end 
end
function Env.PvPEnemyHealerID()
    return Env.EnemyTeam("HEALER"):GetUnitID()
end
function Env.PvPFriendlyHealerID()
    return Env.FriendlyTeam("HEALER"):GetUnitID()
end
function Env.PvPEnemyHealerInRange(range)
    local unit = Env.EnemyTeam("HEALER"):GetUnitID(range)
    return (unit ~= "none" and unit) or false
end
function Env.PvPEnemyHealerInCC(duration)
    if not duration then duration = 3 end
    return Env.EnemyTeam("HEALER"):GetCC() >= duration
end
function Env.PvPFriendlyHealerInCC(duration)
    if not duration then duration = 3 end;    
    return Env.FriendlyTeam("HEALER"):GetCC() >= duration
end
function Env.Get_PvPFriendlyHealerInCC()  
    return Env.FriendlyTeam("HEALER"):GetCC()
end
function Env.Get_PvPFriendlyHealerInCC_DeBuffs(id, range)  
    local DURATION, UNIT = Env.FriendlyTeam("HEALER"):GetDeBuffs(id, range)
    return DURATION, UNIT
end
function Env.PvPUnitIsHealer(unit)
    return Env.Unit(unit):IsHealer() 
end
function Env.PvPEnemyIsHealer(unit)
    return Env.Unit(unit):IsHealer() 
end
function Env.PvPEnemyIsMelee(unit)
    return Env.Unit(unit):IsMelee() 
end
function Env.PvPUnitIsMelee(unit)
    return Env.Unit(unit):IsMelee() 
end
function Env.PvPAssist() 
    return Env.Unit("target"):IsFocused(nil, true)
end 
-- BreakAble 
function Env.PvPBreakAble(range) 
    return Env.EnemyTeam():IsBreakAble(range) 
end
-- Taunt 
function Env.PvPTauntPet(id)
    return Env.EnemyTeam():IsTauntPetAble(id) 
end 
-- Raid/Group
function Env.CheckRaidDeBuffs(id)
    return Env.FriendlyTeam():GetDeBuffs(id) > 0   
end
function Env.CheckRaidTTD(count, seconds)
    if not count then count = 1 end
    if not seconds then seconds = 4 end   
    return Env.FriendlyTeam():GetTTD(count, seconds) 
end
function Env.ArcaneTorrentMindControl()
    return Env.FriendlyTeam():GetBuffs(605, 8) > 0 
end
-- CastBars
function Env.PvPCatchReshift(offset)
    return Env.EnemyTeam():IsReshiftAble(offset) 
end
function Env.PvPMultiCast(unit, spells, range)
    local total, tleft, pleft, id, spellname = Env.MultiCast(unit, spells, range)   
    return total, tleft, pleft, id, spellname
end

