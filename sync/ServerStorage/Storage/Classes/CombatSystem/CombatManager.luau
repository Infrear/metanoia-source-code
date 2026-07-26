-- Services
local SS = game:GetService("ServerStorage")
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local PLRS = game:GetService("Players")

-- Dependencies
local SStorage = SS:WaitForChild("Storage")
local Storage = RPS:WaitForChild("ClientStorage")
local SCRP = workspace:WaitForChild("SCRIPTING")
local CombatSystem = script.Parent
local CombatReplicator = Storage.Events.Remotes.ReplicateCombat
local SimpleAI = require(Storage.Modules.Mine.SimpleAI)
local SkillLibrary = require(Storage.Info.SkillLibrary)

local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings

local SkillLibrary = require(Storage.Info.SkillLibrary)
local CombatManager = {}

-- Local Variables
local Fights = {}
local ActiveRing = nil
local SpinConnection = nil
local CurrentTurnIndex = 1

-- Local Functions
local function handleRingVisuals(fighter) -- handles the selection ring behavior
	if SpinConnection then SpinConnection:Disconnect() end
	if ActiveRing then ActiveRing:Destroy() end
	
	local ringTemplate = Storage.Effects.Combat.Ring
	ActiveRing = ringTemplate:Clone()
	ActiveRing.Parent = fighter.Instance

	SpinConnection = RS.Heartbeat:Connect(function()
		if ActiveRing then
			ActiveRing:PivotTo(ActiveRing:GetPivot() * CFrame.Angles(0, math.rad(2), 0))
			local floorCF = fighter.Instance:FindFirstChild("LeftFoot") and CFrame.new(fighter.Instance:GetPivot().X, (fighter.Instance:FindFirstChild("LeftFoot"):GetPivot().Y), fighter.Instance:GetPivot().Z)  or (fighter.Instance:GetPivot() * CFrame.new(0, -2.8, 0))
			ActiveRing:PivotTo(CFrame.new(floorCF.Position) * (ActiveRing:GetPivot() - ActiveRing:GetPivot().Position))
		end
	end)
end

local function replicateAction(fightTable, attackerData, targets, skillName, damage, results, oldHealths, kshot, atkType, wUp)
	for i, plrTab in ipairs(fightTable.PlayersInvolved) do
		CombatReplicator:FireClient(plrTab.PlayerObject, "attackUpdate", {
			fightTable = fightTable, 
			fighterData = attackerData,
			targets = targets,
			skill = skillName,
			damage = damage,
			results = results, -- "NORMAL", "WEAK", "RESIST", etc.
			oldHealths = oldHealths,
			killshot = kshot,-- [[or target.HP - damage <= 0,]] --> dont need this anymore cause we already calculated the new health
			attackType = atkType,
			windUp = wUp,
		})
	end
end

-- Public Functions
function CombatManager.ExecuteSkill(attacker, targets, skillName, fightTable) -- processes a skill attack
	local skill = SkillLibrary.GetSkill(skillName)
	if not skill then return end

	-- 1. SERVER VALIDATION
	-- Does the Persona actually own this skill?
	local hasSkill = false
	for _, s in ipairs(attacker.Skills) do
		if s == skillName then hasSkill = true break end
	end
	if not hasSkill then return warn(attacker.Instance.Name .. " tried to use unauthorized skill!") end
	
	-- 2. COST VALIDATION --> implement this on the client eventually so we dont just yield the game for regular players
	if skill.CostType == "SP" then
		if attacker.SP < skill.Cost then return warn("Insufficient SP") end
		attacker.SP -= skill.Cost
	else
		--attacker.HP -= (attacker.MaxHP * skill.Cost)
		-- treat the '7' in your library as '7%'
		local deduction = attacker.MaxHP * (skill.Cost / 100)
		if attacker.HP <= deduction then return warn("Insufficient HP") end
		attacker.HP -= deduction
	end
	
	-- 3. VALIDATE TARGET
	if targets and attacker.PlayerOwner then
		local isValid = false

		if skill.TargetType == "Enemies" then
			local good = true
			-- Check if the target is in the enemy list
			for _, enemy in ipairs(targets) do
				if not table.find(fightTable.EnemyFighters, enemy) then isValid = false break end
			end
			isValid = good
		elseif skill.TargetType == "Allies" then
			local good = true
			-- Check if the target is in the player/ally list
			for _, ally in ipairs(targets) do
				if not table.find(fightTable.PlayerFighters, ally) then isValid = false break end
			end
			isValid = good
		elseif skill.TargetType == "Any" then
			-- Everyone is a valid target
			isValid = true
		elseif skill.TargetType == "Self" then
			-- Target must be the attacker
			if attacker == targets[1] then 
				isValid = true 
			else 
				return warn("Self-targeting skill used on another fighter!") 
			end
		end

		if not isValid then
			return warn("Invalid target selection for skill type: " .. skill.TargetType)
		end
	end

	-- calculate damage based on type
	local baseDamage = 0	
	if skill.Element == "Physical" then
		baseDamage = attacker.ActivePersona.Stats.ST * skill.Power
	else
		baseDamage = attacker.ActivePersona.Stats.MA * skill.Power
	end

	local results, oldHealths, kShots = {}, {}, {}
	local CRITCOUNTER = 0
	local camType = (SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.MultiAttackCamType) or "Individual"
	local windUp = true
	
	for i, target in pairs(targets) do
		-- apply impact & check for weakness
		local oldHealth = target.HP
		local result = target:TakeImpact(baseDamage, skill.Element)
		results[target] = result
		oldHealths[oldHealth] = oldHealth
		
		if result == "WEAK" then CRITCOUNTER += 1 end
		
		local kShot = target.HP <= 0
		kShots[target] = kShot
		
		if camType == "Individual" then
			replicateAction(fightTable, attacker, {target}, skillName, baseDamage, {target = result}, {target = oldHealth}, {target = kShot}, "Skill", windUp)
			if kShot then
				task.wait(((SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.KillShotTime) or combatSettings.KILLSHOT_DELAY/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
			end
		
			-- process result
			--print((POST_MOVE_DELAY/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
			if windUp then
				windUp = false
				task.wait((((SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.WindupTime) or combatSettings.WIND_UP_DELAY)/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
			end
			task.wait((((SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.CameraTime) or combatSettings.POST_MOVE_DELAY)/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
		end
	end
	
	if camType == "All At Once" then --> maybe implement a killshot handling here for if all enemies are gone
		replicateAction(fightTable, attacker, targets, skillName, baseDamage, results, oldHealths, kShots, "Skill", true)
		task.wait((((SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.WindupTime) or combatSettings.WIND_UP_DELAY)/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
		task.wait((((SkillLibrary.List[skillName].CameraInfo and SkillLibrary.List[skillName].CameraInfo.CameraTime) or combatSettings.POST_MOVE_DELAY)/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier)
	end
	
	if CRITCOUNTER >= 1 then
		print("CRITICAL HIT! ONE MORE!")
		-- WE DO NOT INCREMENT THE TURN INDEX SO THE SAME FIGHTER GOES AGAIN
		CombatManager.NextTurn(fightTable)
	else
		-- NORMAL TURN ROTATION
		CurrentTurnIndex = (CurrentTurnIndex % #fightTable.AllFighters) + 1
		CombatManager.NextTurn(fightTable)
	end
end

function CombatManager.InitializeBattle(splitParticipants) -- start the combat loop
	local fullParticipants = {}
	for i, v in pairs(splitParticipants) do
		if i == "PlayersInvolved" then continue end
		for i2, v2 in pairs(v) do
			table.insert(fullParticipants, v2)
		end
	end
	table.sort(fullParticipants, function(a, b)
		return a.ActivePersona.Stats.AG > b.ActivePersona.Stats.AG
	end)

	local tab = {
		PlayersInvolved = {},
		AllFighters = {},
		PlayerFighters = {},
		EnemyFighters = {},
	}
	
	tab.PlayersInvolved = splitParticipants.PlayersInvolved
	tab.AllFighters = fullParticipants
	tab.PlayerFighters = splitParticipants.PlayerFighters
	tab.EnemyFighters = splitParticipants.EnemyFighters
	local fightIndex = tostring(#Fights + 1)
	table.insert(Fights, tab)
	
	if #tab.PlayersInvolved == 1 then
		tab.SpeedMultiplier = tab.PlayersInvolved[1].PlayerObject:GetAttribute("CurrentCombatSpeedMultiplier") or 1 --> implement ui for this later lowk, but the code is already fully integrated
	end
	
	CurrentTurnIndex = 1
	for i, plrTab in ipairs(tab.PlayersInvolved) do-- Inside your script
		local plr = plrTab.PlayerObject
		local char = plr.Character
		if plr and char then
			local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = 0
					hum.JumpPower = 0
					hum.JumpHeight = 0
				end
			local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
			if root then
				--root.Anchored = true
			end
		end

		CombatReplicator:FireClient(plrTab.PlayerObject, "start", {fightTable = tab, fighterData = plrTab.FighterObject})
	end
	
	task.wait(3.15)
	CombatManager.NextTurn(tab)
end

function CombatManager.NextTurn(fightTable) -- handle logic for current turn
	--task.wait(0.5) -- idk if i need this
	local currentStriker = fightTable.AllFighters[CurrentTurnIndex]
	handleRingVisuals(currentStriker)
	for i, plrTab in ipairs(fightTable.PlayersInvolved) do
		if not currentStriker.PlayerOwner or plrTab.PlayerObject ~= currentStriker.PlayerOwner then
			CombatReplicator:FireClient(plrTab.PlayerObject, "turnStartUpdate", {
				fighterData = currentStriker,
			})
		end
	end
	
	if currentStriker.PlayerOwner then
		CombatReplicator:FireClient(currentStriker.PlayerOwner, "yourTurn", {fightTable = fightTable, fighterData = currentStriker})
		print("WAITING FOR ACTION FROM: " .. currentStriker.Instance.Name)
		local con, recieved = nil, false
		con = CombatReplicator.OnServerEvent:Connect(function(plr, action, skill, targetIndices, speed)
			if plr == currentStriker.PlayerOwner then
				recieved = {
					Action = action,
					Skill = skill,
					TargetIndices = targetIndices, -- Now a table {1, 3, etc}
					Speed = speed,
				}
				if con then con:Disconnect() end
			end
		end)
		
		-- Handling Time Limits and Execution
		local timer = 0
		local limit = #fightTable.PlayersInvolved > 1 and combatSettings.PlayerActionTimeLimit or 9999
		
		while not recieved and timer < limit do
			timer += task.wait(0.5)
			if not currentStriker.PlayerOwner then break end -- Handle disconnects
		end

		if recieved then
			-- 1. Apply Speed Multipliers
			if recieved.Speed then
				local clampedSpeed = math.clamp(recieved.Speed, combatSettings.MinPlayerCombatSpeedMultplier, combatSettings.MaxPlayerCombatSpeedMultplier)
				currentStriker.PlayerOwner:SetAttribute("CurrentCombatSpeedMultiplier", clampedSpeed)
				fightTable.SpeedMultiplier = clampedSpeed
			end

			-- 2. Convert indices back to Fighter Objects
			local targetObjects = {}
			for _, idx in ipairs(recieved.TargetIndices) do
				if fightTable.AllFighters[idx] then
					table.insert(targetObjects, fightTable.AllFighters[idx])
				end
			end
			
			-- 3. Execute
			CombatReplicator:FireClient(currentStriker.PlayerOwner, "turnStartUpdate", { fighterData = currentStriker })
			CombatManager.ExecuteSkill(currentStriker, targetObjects, recieved.Skill, fightTable)
		else
			-- 4. Default Timeout Action
			print("TIMEOUT: Defaulting to auto-attack")
			CombatReplicator:FireClient(currentStriker.PlayerOwner, "turnEnded")
			CombatManager.ExecuteSkill(currentStriker, {fightTable.EnemyFighters[1]}, "Cleave", fightTable)
		end
	else
		-- do ai stuff
		print("AI'S TURN: " .. currentStriker.Instance.Name)
		task.wait((combatSettings.AI_THINK_TIME/combatSettings.CombatSpeedMultiplier) / fightTable.SpeedMultiplier) -- simulate thinking
		local decision = SimpleAI.GetDecision(currentStriker, fightTable)

		print("AI DECIDED: " .. decision.Skill .. " ON TARGET " .. decision.TargetIndices[1])
		
		if decision.Action == "Skill" then
			-- Convert the AI's numerical indices into Fighter Objects
			local targets = {}
			for _, idx in ipairs(decision.TargetIndices) do
				local fighter = fightTable.AllFighters[idx]
				if fighter then
					table.insert(targets, fighter)
				end
			end

			-- Now pass the whole targets table to your ExecuteSkill function
			CombatManager.ExecuteSkill(currentStriker, targets, decision.Skill, fightTable)
		end
	end
	
	--CombatManager.ExecuteSkill(currentStriker, currentStriker, "Agi") -- testing, but u shouldnt be able to hit yourself
	
	-- ACTION IMPLEMENTATION PLANNED
	--[[
		1. PLAYER INPUT:
		   FIRE A REMOTE TO THE CLIENT TO SHOW THE SELECTION CIRCLE UI (SKILLS, ITEMS, ETC).
		   WAIT FOR THE CLIENT TO SEND BACK THE SELECTED SKILL AND TARGET.
		
		2. AI DECISION:
		   IF Fighter.IsPlayer == FALSE, RUN A SIMPLE AI THAT PICKS A RANDOM SKILL.
		   EVENTUALLY, UPGRADE AI TO TARGET KNOWN WEAKNESSES.
		
		3. CAMERA TWEENS:
		   USE tweenModel LOGIC TO SNAP THE CAMERA TO THE CURRENT STRIKER'S FACE 
		   BEFORE THEY ATTACK, JUST LIKE THE PERSONA 5 CUT-INS.
	]]
	--CombatManager.NextTurn()
end

return CombatManager