-- Initialization
local PersonaData = {}
PersonaData.__index = PersonaData

-- Global Variables 
PersonaData.Elements = {
	EARTH = "Earth",
	LIGHT = "Light",
	FLORA = "Flora",
	FAUNA = "Fauna",
	DARKNESS = "Darkness",
	INSECT = "Insect",
	DRAGON = "Dragon",
	SPIRIT = "Spirit",
	ALIEN = "Alien",
	WARRIOR = "Warrior",
	FLAME = "Flame",
	OCEAN = "Ocean",
	AKHET = "Akhet",
	ELECTRICITY = "Electricity",
	PHYSICAL = "Physical"
}

PersonaData.BasePersonas = {
	["Angel"] = {
		Stats = { ST = 4, MA = 6, EN = 4, AG = 6, LU = 5 },
		KnownSkills = { "Light Strike", "Spirit Heal", "Seventh Heaven"}, -- placeholder skills
		Affinities = {
			[PersonaData.Elements.LIGHT] = 2,
			[PersonaData.Elements.SPIRIT] = 2,
			[PersonaData.Elements.DARKNESS] = -1,
		}
	},
	["Balloon"] = {
		Stats = { ST = 2, MA = 5, EN = 5, AG = 7, LU = 6 },
		KnownSkills = { "Flora Breeze", "Spirit Heal" },
		Affinities = {
			[PersonaData.Elements.FLORA] = 2,
			[PersonaData.Elements.SPIRIT] = 1,
			[PersonaData.Elements.FLAME] = -1,
		}
	},
	["Golem"] = {
		SpawnOffset = CFrame.new(-5, 0, 10),
		Stats = { ST = 8, MA = 2, EN = 9, AG = 2, LU = 4 },
		KnownSkills = { "Ground Smash", "Alien Laser" },
		Affinities = {
			[PersonaData.Elements.EARTH] = 2,
			[PersonaData.Elements.ALIEN] = 1,
			[PersonaData.Elements.FLORA] = -1,
			[PersonaData.Elements.OCEAN] = -1,
		}
	}
}

-- Global Functions 
function PersonaData.new(name, stats, affinities, skills, level, exp) -- Declaration
	local self = setmetatable({}, PersonaData)

	self.Name = name or "Angel"
	self.Level = level or 1
	self.Exp = exp or 0
	
	local base = PersonaData.BasePersonas[self.Name] or PersonaData.BasePersonas["Angel"]

	self.Stats = stats or {
		ST = base.Stats.ST, 
		MA = base.Stats.MA, 
		EN = base.Stats.EN, 
		AG = base.Stats.AG, 
		LU = base.Stats.LU  
	}
	self.KnownSkills = skills or table.clone(base.KnownSkills)
	
	-- affinity ratings: 1 = neutral, 0 = null, -1 = weak, 2 = resist, 3 = drain, 4 = repel
	self.Affinities = affinities or table.clone(base.Affinities)

	return self
end

function PersonaData.fromData(data)
	if not data then return PersonaData.new() end
	return PersonaData.new(
		data.Name,
		data.Stats,
		data.Affinities,
		data.KnownSkills or data.Skills,
		data.Level,
		data.Exp
	)
end

function PersonaData:Serialize()
	return {
		Name = self.Name,
		Level = self.Level,
		Exp = self.Exp,
		Stats = self.Stats,
		Affinities = self.Affinities,
		Skills = self.KnownSkills
	}
end

function PersonaData:AddExp(amount)
	self.Exp += amount
	-- Simple level up logic (e.g. 100 * level exp needed)
	local expNeeded = self.Level * 100
	while self.Exp >= expNeeded do
		self.Exp -= expNeeded
		self.Level += 1
		-- Increase a random stat on level up
		local statKeys = {"ST", "MA", "EN", "AG", "LU"}
		local randomStat = statKeys[math.random(1, #statKeys)]
		self.Stats[randomStat] += 1
		expNeeded = self.Level * 100
	end
end

return PersonaData