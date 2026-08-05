-- Constants
local KEYS = {
	INVENTORY_KEY = "Inventory",
	CHARACTER_KEY = "Character",
	STATS_KEY = "Stats",
	MONEY_KEY = "Money", -- This is for the Wallet (Yen)
	GLOBAL_KEY = "Global",
	CALENDAR_KEY = "Calendar",
	SOCIAL_STATS_KEY = "SocialStats",
	CONFIDANTS_KEY = "Confidants",
	PERSONA_STOCK_KEY = "PersonaStock",
	BP_KEY = "BattlePoints",
}

-- Services
local SS = game:GetService("ServerStorage")
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local PLRS = game:GetService("Players")

-- Dependencies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local CStorage = RPS:WaitForChild("ClientStorage")
local Storage = SS:WaitForChild("Storage")
local Importer = require(Storage:WaitForChild("Importer"))
local ListenerEvents = CStorage:WaitForChild("Events"):WaitForChild("QuestListeners")

local resourceChangedEv = ListenerEvents:WaitForChild("ResourceChanged")
local toolMainEv = CStorage:WaitForChild("Events"):WaitForChild("Standard"):WaitForChild("ToolChangeEv")
local dataEv = CStorage:WaitForChild("Functions"):WaitForChild("Remotes"):WaitForChild("GetData")
local slotEv = CStorage:WaitForChild("Functions"):WaitForChild("Remotes"):WaitForChild("SetSlots")
local charEv = CStorage:WaitForChild("Functions"):WaitForChild("Remotes"):WaitForChild("SetChar")
local statsUpdated = CStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("StatsUpdated")
local dataUpdEv = CStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("DataUpdated")
local itemAddedEv = CStorage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("ItemAddedEvent")
local PlayerData = Importer:ImportScript(Storage:WaitForChild("Classes"):WaitForChild("BaseClasses"):WaitForChild("PlayerData"))

-- Profile / Slot selection events
local function getOrCreateRemote(parent, name, isFunction)
	local r = parent:FindFirstChild(name)
	if not r then
		r = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
		r.Name = name
		r.Parent = parent
	end
	return r
end
local getProfileDataEv = getOrCreateRemote(CStorage.Functions.Remotes, "GetProfileData", true)
local selectSlotEv = getOrCreateRemote(CStorage.Functions.Remotes, "SelectSlot", true)

local DSS = game:GetService("DataStoreService")
local ProfileStore = DSS:GetDataStore("PlayerProfiles1.69.93")

-- Local Functions
function tablesAreEqual(table1, table2)
	if #table1 ~= #table2 then
		return false
	end

	for k, v in pairs(table1) do
		if table2[k] ~= v then
			return false
		end
	end

	return true
end

-- Connections
PLRS.PlayerAdded:Connect(function(plr)
	-- On join, we DON'T initialize PlayerData immediately. 
	-- We wait for the client to request slots and select one.
	plr.CharacterAdded:Connect(function(char)
		char.Parent = workspace.CHARACTERS
	end)
end)

getProfileDataEv.OnServerInvoke = function(plr)
	-- Fetch the player's profile data (which contains slot metadata)
	local profileData = nil
	local success, err = pcall(function()
		profileData = ProfileStore:GetAsync("Profile_"..plr.UserId)
	end)
	if not success then
		warn("Failed to load profile for "..plr.Name..": "..tostring(err))
	end
	
	-- Return default if empty
	if not profileData then
		profileData = {
			Slots = {
				["1"] = { Created = false, Playtime = 0, Level = 1 },
				["2"] = { Created = false, Playtime = 0, Level = 1 },
				["3"] = { Created = false, Playtime = 0, Level = 1 },
			},
			LastPlayedSlot = "1"
		}
	end
	
	return profileData
end

selectSlotEv.OnServerInvoke = function(plr, slotId)
	if odm.PlayerData[plr] then
		-- Already selected a slot, or re-selecting
		if odm.PlayerData[plr].Data then
			odm.PlayerData[plr].Data:SaveData()
		end
	end
	
	-- Save class setups passing the player and slotId
	odm.PlayerData[plr] = {
		Data = PlayerData.new(plr, KEYS, tostring(slotId)),
		Update = Instance.new("BindableEvent"),
	}
	print("Slot "..tostring(slotId).." selected for "..plr.Name)
	--print(odm.PlayerData[plr].Data)

	-- Connect changed to inventory
	odm.PlayerData[plr].Data.Inventory.Changed.Event:Connect(function(item, changed)
		dataUpdEv:FireClient(plr, "Inventory", item, changed)
		itemAddedEv:FireClient(plr, item, changed)
		resourceChangedEv:Fire(plr, item, odm.PlayerData[plr].Data.Inventory.Data[1][item].Amount)
	end)

	odm.PlayerData[plr].Data.Global.Changed.Event:Connect(function(section, changeType, changed1, changed2)
		dataUpdEv:FireClient(plr, "Global -"..section, changeType, changed1, changed2)
	end)

	odm.PlayerData[plr].Data.Euros.Changed.Event:Connect(function(amtChanged)
		dataUpdEv:FireClient(plr, "Wallet", "Update", amtChanged, odm.PlayerData[plr].Yen.Data)
	end)

	odm.PlayerData[plr].Data.Calendar.Changed.Event:Connect(function(type, newData)
		dataUpdEv:FireClient(plr, "Calendar", type, newData)
	end)

	odm.PlayerData[plr].Data.SocialStats.Changed.Event:Connect(function(statName, updateType, value)
		dataUpdEv:FireClient(plr, "SocialStats", statName, updateType, value)
	end)

	odm.PlayerData[plr].Data.Confidants.Changed.Event:Connect(function(npc, updateType, value)
		dataUpdEv:FireClient(plr, "Confidants", npc, updateType, value)
	end)

	odm.PlayerData[plr].Data.PersonaStock.Changed.Event:Connect(function(updateType, pDataObj)
		dataUpdEv:FireClient(plr, "PersonaStock", updateType, pDataObj)
	end)
	
	-- Note: CharacterRemoving connection is now safely isolated to when they actually have data
	if not plr:GetAttribute("HasCharacterRemovingConnection") then
		plr:SetAttribute("HasCharacterRemovingConnection", true)
		plr.CharacterRemoving:Connect(function(char)
			if odm.PlayerData[plr] and odm.PlayerData[plr].Data and char:GetPivot() then
				odm.PlayerData[plr].Data.Character:UpdateCharacterCFrame(char:GetPivot())
			end
		end)
	end
	
	-- Update profile metadata (e.g. mark slot as created)
	pcall(function()
		ProfileStore:UpdateAsync("Profile_"..plr.UserId, function(oldProfile)
			local prof = oldProfile or {
				Slots = {
					["1"] = { Created = false, Playtime = 0, Level = 1 },
					["2"] = { Created = false, Playtime = 0, Level = 1 },
					["3"] = { Created = false, Playtime = 0, Level = 1 },
				}
			}
			prof.LastPlayedSlot = tostring(slotId)
			if prof.Slots[tostring(slotId)] then
				prof.Slots[tostring(slotId)].Created = true
			end
			return prof
		end)
	end)
	
	return true
end

PLRS.PlayerRemoving:Connect(function(plr)
	if odm.PlayerData[plr].Data then
		odm.PlayerData[plr].Data:SaveData()
	end
end)

game:BindToClose(function()
	if not RS:IsStudio() then
		local players = PLRS:GetPlayers()
		for _, player in pairs(players) do
			player:Kick("This server is shutting down")    
		end
		while true do
			wait()
		end
	else
		wait(1)
		--wait(5)
		-- NOTE TO RENABLE FOR LATER
	end
end)

dataEv.OnServerInvoke = function(plr, look, outside) -- grabbing data for clients
	if not outside then
		local data = odm.PlayerData[plr].Data
		--print(data)
		--print(data[look])
		return data[look]
	else
		local foundID = odm.BuildTable.Builds[outside].ID
		if not foundID then return end

		local data = odm.BuildTable.BuildsData[foundID]
		if not data then return end

		return data[look]
	end
end

slotEv.OnServerInvoke = function(plr, slotData, barData, armorData, equipped)
	--print(slotData)
	--print(barData)
	local oldEquipped = nil
	for i, v in pairs(odm.PlayerData[plr].Data.Inventory.Data[3]) do
		if v.Equipped then
			oldEquipped = v
		end
	end
	--print(barData)
	odm.PlayerData[plr].Data.Inventory.Data[2] = slotData
	odm.PlayerData[plr].Data.Inventory.Data[3] = barData

	for i, v in pairs(armorData) do
		if odm.PlayerData[plr].Data.Inventory.Data[4][i] then
			if not tablesAreEqual(v.Path, odm.PlayerData[plr].Data.Inventory.Data[4][i].Path) or v.Name ~= odm.PlayerData[plr].Data.Inventory.Data[4][i].Name then
				print(armorData)
				toolMainEv:Fire(plr, "Aquip", v.Name)
			end
		else
			toolMainEv:Fire(plr, "Aquip", v.Name)
		end
	end

	for i, v in pairs(odm.PlayerData[plr].Data.Inventory.Data[4]) do
		if not armorData[i] then
			toolMainEv:Fire(plr, "Unaquip", v.Name)
		end
	end

	odm.PlayerData[plr].Data.Inventory.Data[4] = armorData
	--print(odm.PlayerData[plr].Data.Inventory.Data[4])

	--print(oldEquipped)
	--print(equipped)
	-- do shi here

	--print(equipped)
	--print(oldEquipped)
	if equipped and oldEquipped then
		if not tablesAreEqual(oldEquipped.Path, equipped.Path) or oldEquipped.Name ~= equipped.Name then
			toolMainEv:Fire(plr, "Equip", equipped.Name)
		end
	end
	if equipped ~= oldEquipped then
		if oldEquipped == nil and equipped then
			toolMainEv:Fire(plr, "Equip", equipped.Name)
		elseif equipped == nil then
			toolMainEv:Fire(plr, "Unequip")
		end
	end
end

charEv.OnServerInvoke = function(plr, charData)
	-- check that data is possible first for hackers or sum
	odm.PlayerData[plr].Data.Character:UpdateCharacterData(charData)
end


--dataUpdEv:FireClient()