-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

return {
	["HarvestSettings"] = require(script:WaitForChild("HarvestSettings")),
	["CombatSettings"] = require(script:WaitForChild("CombatSettings")),
	["StatSettings"] = require(script:WaitForChild("StatSettings")),
	["BuildingSettings"] = require(script:WaitForChild("BuildingSettings"))
	
}