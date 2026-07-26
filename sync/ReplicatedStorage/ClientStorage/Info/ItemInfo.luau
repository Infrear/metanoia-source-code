-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)
--local Tools = Storage:WaitForChild("Tools")
--local Resources = Tools:WaitForChild("Resources")
--local Items = Tools:WaitForChild("Items")
--local Weapons = Tools:WaitForChild("Weapons")
--local Armor = Tools:WaitForChild("Armor")
--local Builds = Tools:WaitForChild("Builds")

tools = {
	-- Weapons
	["Katana"] = {
		Image = "",
		Description = "1",
		--Obj = Weapons:WaitForChild("Katana"),
		Rarity = "Rare",
		Stackable = false,
		--AnimationPack = Storage:WaitForChild("Animations").AnimationPacks.Sword,
		ToolFunction = "Melee Combat",
		
		Durability = 150,
		Cooldown = 0.25
	},
	["Basic Sword"] = {
		Image = "rbxassetid://12340852494",
		Description = "A basic sword given to you at the start",
		--Obj = Weapons:WaitForChild("Basic Sword"),
		Rarity = "Rare",
		Stackable = false,
		--AnimationPack = Storage:WaitForChild("Animations").AnimationPacks.Sword,
		ToolFunction = "Melee Combat",
		
		--RepAnim = Storage:WaitForChild("Animations").RepAnims.LogHold
		Cooldown = 0.45
	},
	---
	
	-- Resources
	["Sticks"] = {
		Image = "rbxassetid://12340853013",
		Description = "A light compact resource good for making smaller items",
		--Obj = Resources:WaitForChild("Sticks"),
		Rarity = "Basic",
		Stackable = 96,
		--AnimationPack = "Default",
		ToolFunction = "Melee Combat",
	},
	["Rocks"] = {
		Image = "rbxassetid://12340395262",
		Description = "A heavy, durable resource found in caves or in the overworld",
		--Obj = Resources:WaitForChild("Rocks"),
		Rarity = "Basic",
		Stackable = 96,
		--AnimationPack = "Default",
		ToolFunction = "Ranged Combat",
		
		MixColor = Color3.new(0.3, 0.3, 0.3),
		MixMaterial = Enum.Material.Rock,
		MixTransparency = 0,
	},
	---
	
	-- Builds
	["Makeshift Campfire"] = {
		Image = "rbxassetid://595268981",
		Description = "A simple campfire for basic cooking needs and heating",
		--Obj = Builds:WaitForChild("Clipboard"),
		Rarity = "Rare",
		Stackable = 96,
		--AnimationPack = "Default",
		ToolFunction = "Build",
		
		--RepAnim = Storage:WaitForChild("Animations").RepAnims.ClipboardHold,
	},
	---
	
	-- Armor
	["Boleite Helm"] = {
		Image = "rbxassetid://13117154432",
		Description = "not a hat",
		--Obj = Armor:WaitForChild("Boleite Helm"),
		Rarity = "Scripting",
		Stackable = false,
		--AnimationPack = "Default",
		ToolFunction = "Armor",
		
		WearPosition = 1,
		Durability = 100,
	},
}

return tools