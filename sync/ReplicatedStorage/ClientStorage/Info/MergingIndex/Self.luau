-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)
local Builds = Storage:WaitForChild("Tools")
local Vehicles = Storage:WaitForChild("Vehicles")

return {
	["Logs"] = {
		CraftingTime = 0.75 ,
		Materials = {
			{
				Name = "Sticks",
				AmountNeeded = 5,
			},
		},
		Stack = 1,
		Order = 1,
	},
	["Makeshift Campfire"] = {
		CraftingTime = 4,
		Materials = {
			{
				Name = "Logs",
				AmountNeeded = 4,
			},
			{
				Name = "Rocks",
				AmountNeeded = 6,
			},
		},
		Stack = 1,
		Order = 2,
	},
	["Plant Goop"] = {
		CraftingTime = 0.25 ,
		Materials = {
			{
				Name = "Leaves",
				AmountNeeded = 3,
			},
		},
		Stack = 3,
		Order = 3,
	},
	["Composition Desk"] = {
		CraftingTime = 5 ,
		Materials = {
			{
				Name = "Logs",
				AmountNeeded = 25,
			},
			{
				Name = "Rocks",
				AmountNeeded = 15,
			},
			{
				Name = "Titanium",
				AmountNeeded = 5,
			},
		},
		Stack = 1,
		Order = 4,
	},
	--["Biofuel Synthesizer"] = {
	--	CraftingTime = 5 ,
	--	Materials = {
	--		{
	--			Name = "Logs",
	--			AmountNeeded = 15,
	--		},
	--		{
	--			Name = "Titanium",
	--			AmountNeeded = 10,
	--		},
	--	},
	--	Stack = 1,
	--	Order = 4,
	--},
	["Wooden Box"] = {
		CraftingTime = 3.5 ,
		Materials = {
			{
				Name = "Logs",
				AmountNeeded = 10,
			},
			{
				Name = "Sticks",
				AmountNeeded = 5,
			},
		},
		Stack = 1,
		Order = 5,
	},
}