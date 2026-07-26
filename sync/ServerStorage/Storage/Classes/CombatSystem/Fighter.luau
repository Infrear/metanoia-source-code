-- Initialization
local Fighter = {}
Fighter.__index = Fighter

-- Global Functions
function Fighter.new(model, personaData, playerOwner) -- declaration
	local self = setmetatable({}, Fighter)

	self.Instance = model
	self.ActivePersona = personaData.ActivePersona
	self.StoredPersonas = personaData.StoredPersonas or {personaData.ActivePersona}
	self.PlayerOwner = playerOwner
	self.MaxHP = self.ActivePersona.Stats.EN * 20
	self.HP = self.MaxHP
	self.MaxSP = self.ActivePersona.Stats.MA * 10
	self.SP = self.MaxSP
	self.Skills = ((personaData and personaData.ActivePersona) and personaData.ActivePersona.KnownSkills) or {}

	self.Status = "Normal" -- "Normal", "Down" or "Dizzy" 
	self.TurnActive = false

	return self
end

function Fighter:TakeImpact(damage, element) -- deals damage to the fighter
	local affinity = self.ActivePersona.Affinities[element] or 1

	if affinity == -1 then
		-- weakness hit logic
		self.HP -= (damage * 1.5)
		self.Status = "Down"
		return "WEAK" 
	elseif affinity == 0 then
		return "NULL"
		-- Add logic for Resist, Drain, Repel here
	else
		--print(self.HP)
		self.HP -= damage
		--print(self.Instance.Name .. " took " .. damage .. " damage!")
		--print(self.HP)
		return "HIT"
	end
end

return Fighter