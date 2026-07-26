-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)
local Tools = Storage:WaitForChild("Tools")

-- Constants
local BuildTypes = {
	"Special", -- free placement like tables or desks
	"Base", -- pretty much floors
	"Wall", -- walls and doors
	"Support", -- pillars and support objects
	"Transport", -- stairs, elevators and ladders
	"Commercial" -- commercial chores stuff like sinks, showers, beds
}

local Stations = {
	Garage = {
		MaxDist = 175
	}
}

return {
	["Wood Base"] = {
		Health = 100,
		BuildType = "Base",
		BuildTime = 0,
	},
	["Duney"] = {
		Health = 2750,
		BuildType = "Special",
		BuildTime = 300,
		VehicleStats = {
			MaxDistanceFromStation = Stations.Garage,
		}
	},
	["Composition Desk"] = {
		Health = 450,
		BuildType = "Special",
		BuildTime = 0,
		StoreMax = 3,
	},
	["Wooden Box"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 0,
		
		NeedsInventory = true,
		InventoryType = "Basic",
	},
	["Makeshift Campfire"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
		
		NeedsInventory = true,
		InventoryType = "Basic",
		
		MakeTime = 5,
		CompatibleItems = {"Food", "Fuel"},
		CookSkill = 1,

		TempEffect = {
			5,
			"Heat",
		},
		TempRadius = 30,
		StoreMax = 3,
	},
	["Mixing Pot"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
		
		NeedsInventory = true,
		GridlockedInventory = true,
		InventoryType = "Gridded",
		ProgressEffect = true,
		ReservedSlots = 1,
		
		MakeTime = 5,
		StoreMax = 4,
	},
	
	["Biofuel Synthesizer"] = {
		Health = 2500,
		BuildType = "Special",
		BuildTime = 5,

		NeedsInventory = true,
		GridlockedInventory = true,
		InventoryType = "Gridded",
		ProgressEffect = true,
		ReservedSlots = 1,

		MakeTime = 5,
		StoreMax = 4,
	},
	["Hydroponic Storage Pod"] = {
		Health = 1000,
		BuildType = "Special",
		BuildTime = 0,

		NeedsInventory = true,
		InventoryType = "Basic",
	},
	["Lab Sink"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
		MaxInteractDist = 10,
		
		BGUIProperties = {
			ScaleFactor = 0.35,
			PositionOffset = Vector3.new(3, -3, 0)
		}
	},
	["Castor Plant(Rinicus communis)"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
	},
	["Moss Rock"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
	},
	["Moss Plant(Bryophyta)"] = {
		Health = 250,
		BuildType = "Special",
		BuildTime = 5,
	},
}