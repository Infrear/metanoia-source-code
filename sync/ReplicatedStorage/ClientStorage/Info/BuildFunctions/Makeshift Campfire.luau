---- Services
--local RPS = game:GetService("ReplicatedStorage")
--local RS = game:GetService("RunService")
--local PLRS = game:GetService("Players")
--local DBS = game:GetService("Debris")

---- Dependancies
--local Storage = RPS:WaitForChild("ClientStorage")
--local odm = nil
--local plr = game.Players.LocalPlayer
--if not plr then
--	odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
--end
--local Importer = require(Storage.Importer)
--local Builds = Storage:WaitForChild("Builds")
--local itemInfo = require(Storage:WaitForChild("Info"):WaitForChild("ItemInfo"))
--local foodCrafting = require(Storage:WaitForChild("Info"):WaitForChild("CraftingIndex"):WaitForChild("Food"))
--local buildInfo = require(Storage:WaitForChild("Info"):WaitForChild("BuildInfo"))
--local forceOpenUI = Storage:WaitForChild("Events"):WaitForChild("Standard"):WaitForChild("ForceOpenUI")
--local cons = {}

---- Local Functions
--local function checkForBurnables(stuff)
--	local food, fuel = nil, nil
--	for i, v in pairs(stuff) do
--		if v.Amount <= 0 then continue end
--		if itemInfo[i].ToolFunction == "Food" then
--			food = i
--			if food and fuel then
--				return food, fuel
--			end
--		elseif itemInfo[i].ToolFunction == "Fuel" then
--			fuel = i
--			if food and fuel then
--				return food, fuel
--			end
--		end
--	end
--	return food, fuel
--end

--local function findRecipe(food, difficulty)
--	for i, v in pairs(foodCrafting) do
--		if v.Difficulty > difficulty or #v.Materials > 1 or v.Materials[1].Name ~= food then continue end
--		return v, i
--	end
--end

return {
	UIType = "Inventory",
	
	OnInteractClient = function(plr, station)
		--local foundEv = station:WaitForChild("UpdateUI", 5)
		--if foundEv then
		--	forceOpenUI:Fire("StoreInventory", station)
		--	foundEv:FireServer(station)
		--end
	end,
	
	OnPlaceServer = function(station)
		--cons[station] = {}
		
		--local running = false
		
		--local function runBurn(food, fuel)
		--	station.Base.Attachment.Fire.Enabled = true
		--	station.Base.Attachment.Fire2.Enabled = true
		--	station.Base.CSmoke.Enabled = true
		--	station:SetAttribute("Running", true)
		--	running = true
			
		--	local newChange, newChange2 = false, false
		--	local con, con2 = nil
		--	local recipe, result = findRecipe(food, buildInfo[station.Name].CookSkill)
		--	--print(recipe)
		--	con = odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Changed.Event:Connect(function()
		--		if not recipe or not (odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food].Amount >= recipe.Materials[1].AmountNeeded and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0) then
		--			con:Disconnect()
		--			newChange = true
		--		end
		--	end)
		--	while not newChange and station and recipe and (odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food].Amount >= recipe.Materials[1].AmountNeeded and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0) do
		--		for i = 1, (buildInfo[station.Name].MakeTime or 10) * 10 do
		--			if newChange then break end
		--			task.wait(0.1)
		--		end
		--		if newChange then break end
		--		if (odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][food].Amount >= recipe.Materials[1].AmountNeeded and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0) and recipe then
		--			--print("we good!")
		--			odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory:RemoveItem(food, recipe.Materials[1].AmountNeeded)
		--			odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory:RemoveItem(fuel, 1)
		--			odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory:AddItem(result, recipe.Stack)
		--		end
		--	end 
		--	if con then con:Disconnect() end
			
		--	if not newChange then
		--		con2 = odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Changed.Event:Connect(function()
		--			if not (odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0) or (select(1, checkForBurnables(odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1]))) then
		--				con2:Disconnect()
		--				newChange2 = true
		--			end
		--		end)
		--		while not newChange2 and station and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0 do
		--			for i = 1, (buildInfo[station.Name].MakeTime or 10) * 10 do
		--				if newChange2 then break end
		--				task.wait(0.1)
		--			end
		--			if newChange2 then break end
		--			if not newChange2 and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel] and odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1][fuel].Amount > 0 then
		--				--print("we good!")
		--				odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory:RemoveItem(fuel, 1)
		--			end
		--		end
		--	end
		--	if con2 then con2:Disconnect() end
			
		--	local food, fuel = checkForBurnables(odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1])
		--	if fuel then
		--		runBurn(food, fuel)
		--	else
		--		running = false
		--		station.Base.Attachment.Fire.Enabled = false
		--		station.Base.Attachment.Fire2.Enabled = false
		--		station.Base.CSmoke.Enabled = false
		--		station:SetAttribute("Running", false)
		--	end
		--end
		
		--table.insert(cons[station], odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Changed.Event:Connect(function()
		--	local food, fuel = checkForBurnables(odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1])
		--	if fuel and not running then
		--		runBurn(food, fuel)
		--	end
		--end))
		
		--local food, fuel = checkForBurnables(odm.BuildTable.BuildsData[odm.BuildTable.Builds[station].ID].Inventory.Data[1])
		--if fuel and not running then
		--	runBurn(food, fuel)
		--end
	end,
	
	OnDestroy = function(station)
		--for i, v in pairs(cons[station]) do
		--	v:Disconnect()
		--end
	end,
}