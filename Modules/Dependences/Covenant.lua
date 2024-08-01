------------------------------------------------------------------------------------------------
-- Covenant is special written lib to provide API for soul binds, follower and covenant
-- This library does nothing if not exist required API and all returns will be unvalid
------------------------------------------------------------------------------------------------
local _G, type, pairs, ipairs, error, string = 
	  _G, type, pairs, ipairs, error, string 

local len 								= string.len
local wipe 								= _G.wipe 

local TMW 								= _G.TMW

local A 								= _G.Action 
local Print								= A.Print
local Listener							= A.Listener
local TimerSetRefreshAble				= A.TimerSetRefreshAble

local Lib 								= _G.LibStub:NewLibrary("Covenant", 3)

if not Lib then 
	if A.BuildToC >= 90001 then 
		Print("[Error] Covenant - Library wasn't initialized")
	end 
	return 
end 

-------------------------------------------------------------------------------
-- Locals
-------------------------------------------------------------------------------
local SoulbindViewer					-- loads on demand
local UIParentLoadAddOn					= _G.UIParentLoadAddOn
local GetSpellName 						= _G.C_Spell and _G.C_Spell.GetSpellName or _G.GetSpellInfo
local Data 								= {}
local Nodes								= {}

local C_Covenants						= _G.C_Covenants
local GetActiveCovenantID, GetCovenantData 
if C_Covenants then 
	GetActiveCovenantID					= C_Covenants.GetActiveCovenantID
	GetCovenantData						= C_Covenants.GetCovenantData
end 

local C_Soulbinds						= _G.C_Soulbinds
local GetActiveSoulbindID, GetSoulbindData
if C_Soulbinds then 
	GetActiveSoulbindID					= C_Soulbinds.GetActiveSoulbindID
	GetSoulbindData						= C_Soulbinds.GetSoulbindData
end 

local function OnWipe()
	local typeV
	for k, v in pairs(Lib) do 
		typeV = type(v)
		if typeV == "table" then 
			wipe(v)
		elseif typeV ~= "function" and k ~= "useDebug" then 
			Lib[k] = nil 
		end 
	end 
end

local function OnUpdateCovenant()
	Lib.covenantID = GetActiveCovenantID()
	
	local covenantData = GetCovenantData(Lib.covenantID)
	if covenantData then
		Lib.covenantID = covenantData.ID			
		Lib.covenantName = covenantData.textureKit
	end 
end 

local function OnUpdateSoulbind(isInitial)
	Lib.soulBindID = GetActiveSoulbindID()
	
	if Lib.soulBindID and Lib.soulBindID > 0 then 
		local soulbindData = GetSoulbindData(Lib.soulBindID) -- not static!
		-- covenantID 		- @number
		-- ID				- @number equal to soulbindID
		-- cvarIndex		- @number
		-- description		- @string localized
		-- modelSceneData	- @table 
		-- { 
		--		creatureDisplayInfo = @number, 
		--		modelSceneActorID = @number
		-- }
		-- name				- @string localized 
		-- resetData		- @table 
		-- { 
		--	currencyCosts = 
		--	{
		--		currencyID = @number,
		--		quantity = @number 
		--	}, 
		--	goldCost = @number 
		-- }
		-- textureKit 		- @string english
		-- tree				- @table 
		-- { 
		--		editable = @boolean, 
		--		nodes = 
		--		{
		--			{
		--				ID = @number, 
		--				column = @number, 
		--				conduitID = @number,
		--				conduitRank = @number, 
		--				icon = @number,
		--				parentNodeIDs = 
		--				{
		--					[1] = @number,
		--					[2] = @number,
		--					...
		--				},
		--				row = @number,
		--				spellID = @number, 
		--				state = @number
		--			},
		--			... 
		--		}
		-- }
		-- unlocked			- @boolean 
		
		-- Get follower and his soulbind
		if not isInitial and soulbindData.unlocked then 
			-- Get follower 
			Lib.followerID = soulbindData.ID 
			Lib.followerName = soulbindData.textureKit
			
			-- Get available nodes
			for _, node in ipairs(soulbindData.tree.nodes) do 
				Nodes[node.ID] = node.spellID or 0
			end 
			
			if not SoulbindViewer then 
				-- While currently here is not found any API to get understand what exactly node is selected we will use this, may be as temporary solution
				-- soulbindData.tree.nodes returns 'state' which means exact this statement however returns are different for each node, therefore its not possible to understand if node selected or not  
				UIParentLoadAddOn("Blizzard_Soulbinds")
				SoulbindViewer = _G.SoulbindViewer					
			end
			
			-- Get learned soulbind contained spell 
			if SoulbindViewer then 
				local needClose
				if not SoulbindViewer:IsVisible() then -- and not SoulbindViewer.Tree.nodeFrames -- lib v3: Supposed to fix issue when nodeTree didn't update on second follower				
					SoulbindViewer:Open()
					needClose = true 
				end 
				
				if SoulbindViewer.Tree.nodeFrames then -- and SoulbindViewer.Tree:HasSelectedNodes()
					local spellID, spellName
					for nodeID, nodeFrame in pairs(SoulbindViewer.Tree.nodeFrames) do
						if nodeFrame:IsSelected() and Nodes[nodeID] then
							-- nodeFrame.node.spellID
							-- nodeFrame.node.ID 
							spellID = Nodes[nodeID]
							if spellID ~= 0 then 
								spellName = GetSpellName(spellID)
								if spellName then 
									Data[spellName] = true 
								else 
									error("[Error] Covenant - Library couldn't get spellName from spellID: " .. (spellID or "nil"))
								end 
								
								Data[spellID] = true 
								Data[nodeID] = true 
							end 
						end 
					end 
				end
				
				if needClose then 
					SoulbindViewer.CloseButton:Click()							
				end 
			end 						
		end 
		
		TMW:Fire("TMW_ACTION_SOUL_BINDS_UPDATED")
	end 
end 

local function OnUpdate()
	-- Clears previous all info
	OnWipe()
	
	-- Get covenant
	OnUpdateCovenant()	
	
	-- Get soulbind of the covenant through his follower(if possible)
	OnUpdateSoulbind()
	
	-- Debug 
	if Lib.useDebug then 
		Print("[Debug] Covenant Library - start")
		
		Print("[Debug] Covenant Library - learned Soul Binds (spellID)") 
		for spellID in pairs(Data) do 
			if type(spellID) == "number" and len(spellID) > 4 then 
				Print("[Debug] Covenant Library has " .. spellID .. " (" .. (GetSpellName(spellID) or "nil") .. ")")
			end 
		end 
		
		Print("[Debug] Covenant Library - learned Soul Binds (spellName)") 
		for spellName in pairs(Data) do 
			if type(spellName) == "string" then 
				Print("[Debug] Covenant Library has " .. spellName)
			end 
		end

		Print("[Debug] Covenant Library - learned Soul Binds (nodeID)") 
		for nodeID in pairs(Data) do 
			if type(nodeID) == "number" and len(nodeID) <= 4 then 
				Print("[Debug] Covenant Library has " .. nodeID)
			end 
		end 		
		
		Print("[Debug] Covenant Library - end")
	end 
	
	-- Callback 
	TMW:Fire("TMW_ACTION_COVENANT_LIB_UPDATED")
end 

if C_Covenants and C_Soulbinds then 
	TMW:RegisterSelfDestructingCallback("TMW_ACTION_ENTERING", 					 		function()
		UIParentLoadAddOn("Blizzard_Soulbinds")
		SoulbindViewer = _G.SoulbindViewer	
	
		-- "Tome of the Tranquil Mind" doesn't work at the moment for swap soul binds
		-- Handler after close 
		local function RunUpdate()
			if not SoulbindViewer:IsVisible() then 
				OnUpdate()
			end 
		end 
		SoulbindViewer:HookScript("OnHide", function(self)			
			TimerSetRefreshAble("ACTION_EVENT_SOULBINDS", 0.5, RunUpdate)
		end)
		
		-- Handler on covenant chosen
		Listener:Add("ACTION_EVENT_SOULBINDS", "COVENANT_CHOSEN", function()			
			TimerSetRefreshAble("ACTION_EVENT_SOULBINDS", 0.5, OnUpdate)
		end)
		
		-- Handler on follower chosen
		-- lib v3: Supposed to fix issue when nodeTree didn't update on second follower
		Listener:Add("ACTION_EVENT_SOULBINDS", "GARRISON_FOLLOWER_ADDED", function()			
			TimerSetRefreshAble("ACTION_EVENT_SOULBINDS", 0.5, OnUpdate)
		end)		
		
		-- Initialization login
		OnUpdateCovenant()
		OnUpdateSoulbind(true)								-- not necessary to pass the 'true' here but I prefer don't fail with code without enough tests
		if Lib.soulBindID ~= 0 and Lib.covenantID ~= 0 then -- avoid throw error "You are not in a required covenant."
			SoulbindViewer:Open()
			SoulbindViewer:Hide()
		elseif Lib.covenantID ~= 0 then 					-- IMPORTANT! Don't remove otherwise it will cause fail for InstallButtons function on initial login 
			-- Callback 
			TMW:Fire("TMW_ACTION_COVENANT_LIB_UPDATED")
		end 
		
		-- Signal RegisterSelfDestructingCallback to unregister
		return true 
	end)	
end 

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
Lib.useDebug		= false -- shows print in-chat every time when library doing update soul binds / covenant swap
Lib.Data	 		= Data 	-- [spellID, spellName, nodeID] = true, information of learned SPELL contain nodes i.e. Soul Binds
Lib.Nodes	 		= Nodes -- [nodeID] = spellID or 0, information of available nodeIDs (0 if it's conduit)
-- Lib available keys:
-- .soulbindID		- @number for internal use

-- .covenantID		- @number or nil, possible IDs:
-- 	1 is Kyrian
-- 	2 is Venthyr
-- 	3 is NightFae
-- 	4 is Necrolord

-- .covenantName	- @string or nil, possible names: 
--	Kyrian|Venthyr|NightFae|Necrolord


-- .followerID		- @number or nil, possible IDs:
-- 	for Kyrian:
--		7 is Pelagos
--		13 is Kleia
--		18 is Mikanikos
--	for Venthyr:
--		8 is Nadjia
--		9 is Theotar
--		3 is Draven
-- 	for NightFae: 
--		1 is Niya
--		2 is Dreamweaver
-- 		6 is Korayn
--	for Necrolord:
--		4 is Marileth
--		5 is Emeni
--		10 is Heirmir


-- .followerName	- @string or nil, possible names:
-- 	for Kyrian: 	Pelagos|Kleia|Mikanikos
--	for Venthyr: 	Nadjia|Theotar|Draven
-- 	for NightFae: 	Niya|Dreamweaver|Korayn
-- 	for Necrolord: 	Marileth|Emeni|Heirmir

function Lib:IsLoaded()
	-- @return boolean 
	return A.BuildToC >= 90001 and A.BuildToC < 100001 and C_Covenants and C_Soulbinds and true 
end

function Lib:GetCovenant()
	-- @return number, string or nil 
	-- Returns covenantID, covenantName (english)
	return self.covenantID, self.covenantName
end

function Lib:GetFollower()
	-- @return number, string or nil
	-- Returns followerID, followerName (english)
	return self.followerID, self.followerName
end

function Lib:HasSoulbind(soulBind)
	-- @return boolean 
	-- @usage Lib:HasSoulbind(spellName|spellID|nodeID)
	-- Returns true if its learned in the tree of the active follower
	return Data[soulBind]
end 