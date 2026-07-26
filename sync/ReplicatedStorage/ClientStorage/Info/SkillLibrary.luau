-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local PersonaData = require(Storage.Classes.PersonaClientSide:WaitForChild("PersonaData"))
local Moves = Storage.Moves

-- Initialization
local SkillLibrary = {}

local ElementIcons = {
	[PersonaData.Elements.PHYSICAL] = "rbxassetid://PhysIconID",
	[PersonaData.Elements.FIRE]     = "rbxassetid://138662774",
	[PersonaData.Elements.ICE]      = "rbxassetid://IceIconID",
	[PersonaData.Elements.ELEC]     = "rbxassetid://952717632",
	[PersonaData.Elements.WIND]     = "rbxassetid://WindIconID",
	[PersonaData.Elements.PSY]      = "rbxassetid://PsyIconID",
	[PersonaData.Elements.NUCLEAR]  = "rbxassetid://NukeIconID",
	[PersonaData.Elements.BLESS]    = "rbxassetid://BlessIconID",
	[PersonaData.Elements.CURSE]    = "rbxassetid://CurseIconID",
}

SkillLibrary.PreloadedVFXFunctions = {}
for i, v in pairs(Moves:GetChildren()) do
	SkillLibrary.PreloadedVFXFunctions[v.Name] = require(v)
end

-- Skill Dictionary
SkillLibrary.List = {
	["Agi"] = {
		Name = "Agi", -- Name of ability
		TargetType = "Enemies", -- "Enemies", "Allies" "Any" or "Self"
		TargetAmt = "All", -- "All", 1, 2, 3, etc. 
		Element = PersonaData.Elements.FIRE,
		CostType = "SP", -- "SP or HP"
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Fire damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
			MultiAttackCamType = "All At Once", -- "All At Once" or "Individual"
		}
		--VFXModExtraParameters = <-- add this in later if needed
	},
	["Bufu"] = {
		Name = "Bufu",
		Element = PersonaData.Elements.ICE,
		TargetType = "Enemies",
		CostType = "SP",
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Ice damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
		}
	},
	["Garu"] = {
		Name = "Garu",
		Element = PersonaData.Elements.WIND,
		TargetType = "Enemies",
		CostType = "SP",
		Cost = 3,
		Power = 1.2,
		Description = "Light Wind damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
		}
	},
	["Cleave"] = {
		Name = "Cleave",
		Element = PersonaData.Elements.PHYSICAL,
		TargetType = "Enemies",
		CostType = "HP",
		Cost = 7,
		Power = 1.5,
		Description = "Light Physical damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
		}
	},
	["Zio"] = {
		Name = "Zio",
		Element = PersonaData.Elements.ELEC,
		TargetType = "Enemies",
		TargetAmt = "All",
		CostType = "HP", --SP
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Elec damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
			MultiAttackCamType = "Individual",
		}
	}
}


-- Public Functions
function SkillLibrary.GetSkill(name) -- Retrieves skill data with dynamic icon injection
	local skill = SkillLibrary.List[name]
	if skill then
		-- inject the icon dynamically based on the element
		skill.Icon = ElementIcons[skill.Element] or "rbxassetid://DefaultIconID"
	end
	return skill
end

return SkillLibrary