-- Initialization
local PersonaData = {}
PersonaData.__index = PersonaData

-- Global Variables 
PersonaData.Elements = {
	PIERCE = "Physical",
	SLASH = "Physical",
	PHYSICAL = "Physical",
	FIRE = "Fire",
	ICE = "Ice",
	ELEC = "Elec",
	WIND = "Wind",
	PSY = "Psy",
	NUCLEAR = "Nuclear",
	BLESS = "Bless",
	CURSE = "Curse"
}

-- Global Functions 
function PersonaData.new(name, stats, affinities, skills, level, exp) -- Declaration
	local self = setmetatable({}, PersonaData)

	self.Name = name or "Angel"
	self.Level = level or 1
	self.Exp = exp or 0
	self.Stats = stats or {
		ST = 5, -- strength -> physical damage 
		MA = 5, -- magic -> elemental damage 
		EN = 5, -- endurance -> defense 
		AG = 5, -- agility -> accuracy/evasion/turn order 
		LU = 5  -- luck -> crit rate/ailment chance 
	}
	--print(self.Stats)
	self.KnownSkills = skills or { --> just for testing, personas wont have all skills to start obv
		"Zio", 
		"Agi", 
		"Garu", 
		"Cleave"
	}
	
	-- affinity ratings: 1 = neutral, 0 = null, -1 = weak, 2 = resist, 3 = drain, 4 = repel
	self.Affinities = affinities or { -- example btw
		[PersonaData.Elements.PHYSICAL] = 1,
		[PersonaData.Elements.FIRE] = 1,
		[PersonaData.Elements.ICE] = -1, -- weak to ice 
		[PersonaData.Elements.ELEC] = 1,
		[PersonaData.Elements.WIND] = 1,
		[PersonaData.Elements.BLESS] = 2, -- resists bless
		[PersonaData.Elements.CURSE] = 0, -- nulls Curse
	}

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