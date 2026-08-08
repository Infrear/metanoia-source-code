-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local PersonaData = require(Storage.Classes.PersonaClientSide:WaitForChild("PersonaData"))
local Moves = Storage.Moves

-- Initialization
local SkillLibrary = {}

local ElementIcons = {
	[PersonaData.Elements.EARTH]       = "rbxassetid://1",
	[PersonaData.Elements.LIGHT]       = "rbxassetid://1",
	[PersonaData.Elements.FLORA]       = "rbxassetid://1",
	[PersonaData.Elements.FAUNA]       = "rbxassetid://1",
	[PersonaData.Elements.DARKNESS]    = "rbxassetid://CurseIconID",
	[PersonaData.Elements.INSECT]      = "rbxassetid://1",
	[PersonaData.Elements.DRAGON]      = "rbxassetid://1",
	[PersonaData.Elements.SPIRIT]      = "rbxassetid://PsyIconID",
	[PersonaData.Elements.ALIEN]       = "rbxassetid://NukeIconID",
	[PersonaData.Elements.WARRIOR]     = "rbxassetid://1",
	[PersonaData.Elements.FLAME]       = "rbxassetid://138662774",
	[PersonaData.Elements.OCEAN]       = "rbxassetid://IceIconID",
	[PersonaData.Elements.AKHET]       = "rbxassetid://1",
	[PersonaData.Elements.ELECTRICITY] = "rbxassetid://952717632",
	[PersonaData.Elements.PHYSICAL]    = "rbxassetid://PhysIconID",
}

SkillLibrary.PreloadedVFXFunctions = {}
local function preloadFunction(v)
	if typeof(v) == 'Instance' then 
		if v:IsA("ModuleScript") then
			SkillLibrary.PreloadedVFXFunctions[v.Name] = require(v)
		elseif v:IsA("Folder") then
			for i, v in pairs(v:GetChildren()) do
				preloadFunction(v)
			end
		end
	end
end

preloadFunction(Moves)

-- Skill Dictionary
SkillLibrary.List = {
	["Agi"] = {
		Name = "Agi", -- Name of ability
		TargetType = "Enemies", -- "Enemies", "Allies" "Any" or "Self"
		TargetAmt = "All", -- "All", 1, 2, 3, etc. 
		Element = PersonaData.Elements.FLAME,
		CostType = "SP", -- "SP or HP"
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Flame damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.LavaBomb,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
			MultiAttackCamType = "All At Once", -- "All At Once" or "Individual"
		}
	},
	["Bufu"] = {
		Name = "Bufu",
		Element = PersonaData.Elements.OCEAN,
		TargetType = "Enemies",
		CostType = "SP",
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Ocean damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
		}
	},
	["Garu"] = {
		Name = "Garu",
		Element = PersonaData.Elements.SPIRIT,
		TargetType = "Enemies",
		CostType = "SP",
		Cost = 3,
		Power = 1.2,
		Description = "Light Spirit damage to one foe.",
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
		VFXMod = SkillLibrary.PreloadedVFXFunctions.WarriorMultiSlash,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
		}
	},
	["Zio"] = {
		Name = "Zio",
		Element = PersonaData.Elements.ELECTRICITY,
		TargetType = "Enemies",
		TargetAmt = "All",
		CostType = "HP", --SP
		Cost = 4,
		Power = 1.2,
		Description = "Deals light Electricity damage to 1 foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.Lightning,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
			MultiAttackCamType = "Individual",
		}
	},
	["Light Strike"] = {
		Name = "Light Strike",
		Element = PersonaData.Elements.LIGHT,
		TargetType = "Enemies",
		TargetAmt = 1,
		CostType = "SP",
		Cost = 5,
		Power = 5,
		Description = "Light Light damage to one foes.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.WarriorMultiSlash,
		CameraInfo = { CameraTime = 2.5, AttackTime = 2 }
	},
	["Seventh Heaven"] = {
		Name = "Seventh Heaven",
		Element = PersonaData.Elements.LIGHT,
		TargetType = "Enemies",
		TargetAmt = "All",
		CostType = "SP",
		Cost = 5,
		Power = 1.3,
		Description = "Light Light damage to all foes.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.SeventhHeaven,
		CameraInfo = { 
			CameraTime = 5, 
			AttackTime = 4,
			MultiAttackCamType = "All At Once"
		}
	},
	["Spirit Heal"] = {
		Name = "Spirit Heal",
		Element = PersonaData.Elements.SPIRIT,
		TargetType = "Allies",
		TargetAmt = 1,
		CostType = "SP",
		Cost = 6,
		Power = 1.0,
		Description = "Heals an ally.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.LeafVortex,
		CameraInfo = { CameraTime = 1.8, AttackTime = 1 }
	},
	["Flora Breeze"] = {
		Name = "Flora Breeze",
		Element = PersonaData.Elements.FLORA,
		TargetType = "Enemies",
		TargetAmt = 1,
		CostType = "SP",
		Cost = 4,
		Power = 1.2,
		Description = "Light Flora damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.LeafVortex,
		CameraInfo = { CameraTime = 1.8, AttackTime = 1 }
	},
	["Ground Smash"] = {
		Name = "Ground Smash",
		Element = PersonaData.Elements.EARTH,
		TargetType = "Enemies",
		TargetAmt = "All",
		CostType = "HP",
		Cost = 8,
		Power = 10,
		Description = "Heavy Earth damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.GroundImpact,
		CameraInfo = {
			CameraTime = 3.85,
			AttackTime = 2.5,
			MultiAttackCamType = "All At Once", -- "All At Once" or "Individual"
		}
	},
	["Alien Laser"] = {
		Name = "Alien Laser",
		Element = PersonaData.Elements.ALIEN,
		TargetType = "Enemies",
		TargetAmt = 1,
		CostType = "SP",
		Cost = 5,
		Power = 1.4,
		Description = "Alien damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.AlienLazer,
		CameraInfo = { CameraTime = 3.85, AttackTime = 2.5 }
	},
	["Rock Hurl"] = {
		Name = "Rock Hurl",
		Element = PersonaData.Elements.EARTH,
		TargetType = "Enemies",
		TargetAmt = 1,
		CostType = "SP",
		Cost = 5,
		Power = 10,
		Description = "Alien damage to one foe.",
		VFXMod = SkillLibrary.PreloadedVFXFunctions.StoneHurl,
		VFXParams = {"CasterCFrame", "TargetModel"},
		CameraInfo = { CameraTime = 1.5, AttackTime = 1 }
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