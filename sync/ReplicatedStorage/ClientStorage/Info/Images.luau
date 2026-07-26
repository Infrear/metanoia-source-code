-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

return {
	Logos = {
		GroupLogo = "rbxassetid://14268859286",
		GameLogo = "rbxassetid://14268859286",
		TintedGroupLogo = "rbxassetid://14269097252",
		TintedGameLogo = "rbxassetid://14269097252",
	},
	
	Chats = {
		Interact = "rbxassetid://13991903369",
		Pickup = "rbxassetid://13886974920",
		Talk = "http://www.roblox.com/asset/?id=11707615313"
	}
}