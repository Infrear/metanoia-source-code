-- SimpleAI.lua
local RPS = game:GetService("ReplicatedStorage")
local Storage = RPS:WaitForChild("ClientStorage")
local SkillLibrary = require(Storage.Info.SkillLibrary)

local SimpleAI = {}

function SimpleAI.GetDecision(striker, fightTable)
	-- 1. Pick a random skill from striker's list
	local availableSkills = ((striker.Skills and #striker.Skills > 0) and striker.Skills) or {"Attack"}
	local chosenSkillName = availableSkills[math.random(1, #availableSkills)]
	local skillData = SkillLibrary.GetSkill(chosenSkillName)

	-- 2. Determine potential targets based on skill type
	local targets = {}
	local potentialTargets = {}

	if skillData.TargetType == "Enemies" then
		-- AI assumes Players are the enemies
		potentialTargets = fightTable.PlayerFighters
	elseif skillData.TargetType == "Any" then
		potentialTargets = fightTable.AllFighters
	elseif skillData.TargetType == "Allies" then
		potentialTargets = fightTable.EnemyFighters
	elseif skillData.TargetType == "Self" then
		table.insert(targets, striker)
	end

	-- 3. Selection Logic
	if #potentialTargets > 0 then
		if skillData.TargetAmt and skillData.TargetAmt == "All" then -- chekced library for this flag
			targets = potentialTargets
		else
			-- Pick one random target from the valid group
			table.insert(targets, potentialTargets[math.random(1, #potentialTargets)])
		end
	end

	-- 4. Map targets to AllFighters indices for the Server Manager
	local targetIndices = {}
	for _, targetObj in ipairs(targets) do
		local idx = table.find(fightTable.AllFighters, targetObj)
		if idx then table.insert(targetIndices, idx) end
	end
	
	return {
		Action = "Skill",
		Skill = chosenSkillName,
		TargetIndices = targetIndices -- Updated to plural
	}
end

return SimpleAI