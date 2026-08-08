-- Initialization
local Fighter = {}
Fighter.__index = Fighter

-- Global Functions
function Fighter.new(model, personaData, playerOwner) -- declaration
	local self = setmetatable({}, Fighter)

	if typeof(model) == "string" then
		self.ModelName = model
		self.Instance = nil
	else
		self.Instance = model
	end
	
	self.ID = game:GetService("HttpService"):GenerateGUID(false)
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
	self.Guarding = false -- true from the moment they guard until their own next turn starts

	return self
end

function Fighter:TakeImpact(damage, element) -- deals damage to the fighter
	local affinity = self.ActivePersona.Affinities[element] or 1
	local wasGuarding = self.Guarding
	local guardBroke = false

	if wasGuarding then
		-- A weakness hit, or anything hefty enough (>=30% of max HP before the guard reduction),
		-- breaks the guard outright: it still gets the halved damage this one time, but Guarding ends
		-- immediately instead of lasting the rest of the enemy phase, and the client shows the shield
		-- actually shattering (Shield-Break-01) instead of just absorbing the hit (Generic-Block-Hit).
		guardBroke = (affinity == -1) or (damage >= self.MaxHP * 0.3)
		damage *= 0.5
		if guardBroke then
			self.Guarding = false
		end
	end

	if affinity == -1 then
		-- weakness hit logic
		self.HP -= (damage * 1.5)
		self.Status = "Down"
		return wasGuarding and "GUARD_BREAK" or "WEAK"
	elseif affinity == 0 then
		return "NULL"
		-- Add logic for Resist, Drain, Repel here
	else
		--print(self.HP)
		self.HP -= damage
		--print(self.Instance.Name .. " took " .. damage .. " damage!")
		--print(self.HP)
		if wasGuarding then
			return guardBroke and "GUARD_BREAK" or "BLOCKED"
		end
		return "HIT"
	end
end

return Fighter