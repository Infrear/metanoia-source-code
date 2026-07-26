-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

return {
	HealthRegen = {
		Amt = 1,
		Step = 1,
		Chilltime = 5,
		MinThirstStat = 20,
		MinHungerStat = 20,
	}
}
