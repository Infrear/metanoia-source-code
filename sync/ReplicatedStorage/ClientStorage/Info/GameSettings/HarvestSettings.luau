-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

return {
	PICKUP_DISTANCE_THRESHOLD = {
		["default"] = 8.5, -- Adjust the distance threshold for showing the pickup button
		["builds"] = 7.5,
		["bush"] = 6.5, -- Adjust the distance threshold for showing the pickup button
	},
	HARVEST_STATS = {
		-- Trees
		["Darkwood Tree"] = {
			Health = {200, 300},
			DropsPerHit = {
				{
					Name = "Logs", 
					Amount = {5, 10}, 
					Chance = {1, 2}},
				{
					Name = "Leaves", 
					Amount = {1, 3},  -- min 1, max 3
					Chance = {1, 5}}, -- 1 in 5 (20% chance)
			},
		},
		-- Rocks
		["Basic Rock"] = {
			Health = {200, 300},
			DropsPerHit = {
				{
					Name = "Rocks", 
					Amount = {2, 3}, 
					Chance = {1, 2}},
				{
					Name = "Titanium", 
					Amount = {1, 6}, 
					Chance = {1, 3}}, 
			},
		},
		-- Bushes
		["Common Bush"] = {
			DropsPerHit = {
				{
					Name = "Sticks", 
					Amount = {2, 4}, 
					Chance = {1, 1}},
				{
					Name = "Leaves", 
					Amount = {4, 8}, 
					Chance = {1, 1}},
				{
					Name = "Ancient Mushroom", 
					Amount = {1, 1}, 
					Chance = {1, 50}},
				{
					Name = "Purple Berries", 
					Amount = {1, 6}, 
					Chance = {1, 2}}, 
				{
					Name = "Moss Spores",
					Amount = {1, 10},
					Chance = {1, 2}, -- 1/7
				}
			},
		},
	},
}
