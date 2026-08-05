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

local adminInfo  =  require(Storage.Info.AdminInfo)
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
-- (Removed handleRingVisuals as Visuals are client side now)

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

local function EndBattle(fightTable, victor)
	for i, plrTab in ipairs(fightTable.PlayersInvolved) do
		CombatReplicator:FireClient(plrTab.PlayerObject, "endBattle", victor)
		
		-- DISTRIBUTE REWARDS
		if victor == "Players" then
			local plrData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).PlayerData[plrTab.PlayerObject]
			if plrData then
				-- 1. Battle Points (BP)
				local bpReward = 100 -- Example flat rate, scale later based on enemy level
				plrData.Data.BattlePoints:Increase(bpReward)
				
				-- 2. Persona EXP
				local expReward = 50 -- Example flat rate
				local activeP = plrData.Data.PersonaStock:GetActivePersona()
				if activeP then
					activeP:AddExp(expReward)
					plrData.Data.PersonaStock:UpdateActivePersona(activeP)
				end
				
				-- 3. Elo Boost (Simple implementation)
				if plrData.Data.Global.Data.Elo then
					plrData.Data.Global.Data.Elo.Rating += 10
					plrData.Data.Global.Changed:Fire("Global", "EloUpdate", plrData.Data.Global.Data.Elo)
				end
			end
		end
	end
end

local function CheckWinCondition(fightTable)
	local enemiesDead = true
	for _, f in ipairs(fightTable.EnemyFighters) do
		if f.HP > 0 then enemiesDead = false break end
	end
	
	local playersDead = true
	for _, f in ipairs(fightTable.PlayerFighters) do
		if f.HP > 0 then playersDead = false break end
	end
	
	if enemiesDead then
		EndBattle(fightTable, "Players")
		return true
	elseif playersDead then
		EndBattle(fightTable, "Enemies")
		return true
	end
	
	return false
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
	
	if not hasSkill then 
		if attacker.PlayerOwner then
			if table.find(adminInfo.Admins, attacker.PlayerOwner.Name) then
				warn(attacker.PlayerOwner.Name .. " bypassed usage of unauthorized skills with admin permissions!")
			else
				return warn(attacker.PlayerOwner.Name .. " tried to use unauthorized skill!") 
			end
		else
			-- NPC Bypass (Since their KnownSkills are handled by AI)
			hasSkill = true
		end
	end
	
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
	
	if attacker.BatonBoost then
		baseDamage = baseDamage * 1.5 -- Baton pass 50% damage boost
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

		-- CombatStoryline "GolemEnraged" beat -- fires once per battle (not once per golem) the
		-- first time any Golem crosses half HP, so multiple golems enraging doesn't spam the line
		if target.ModelName == "Golem" and not fightTable.GolemEnrageFired and target.HP > 0 and target.HP <= target.MaxHP * 0.5 then
			fightTable.GolemEnrageFired = true
			for _, plrTab in ipairs(fightTable.PlayersInvolved) do
				CombatReplicator:FireClient(plrTab.PlayerObject, "storylineEvent", {EventName = "GolemEnraged"})
			end
		end
		
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
	
	if CheckWinCondition(fightTable) then
		return -- Battle ended
	end
	
	-- Clear temporary baton pass boosts
	if attacker.BatonBoost then
		attacker.BatonBoost = false
	end
	
	if CRITCOUNTER >= 1 then
		print("CRITICAL HIT! ONE MORE!")
		if attacker.PlayerOwner then
			CombatReplicator:FireClient(attacker.PlayerOwner, "promptBatonPass", {fightTable = fightTable})
			local con, recieved = nil, false
			con = CombatReplicator.OnServerEvent:Connect(function(plr, action, targetFighterIndex)
				if plr == attacker.PlayerOwner and action == "batonPass" then
					recieved = { targetIndex = targetFighterIndex }
					if con then con:Disconnect() end
				end
			end)
			
			local timer = 0
			local limit = #fightTable.PlayersInvolved > 1 and combatSettings.PlayerActionTimeLimit or 9999
			while not recieved and timer < limit do
				timer += task.wait(0.5)
				if not attacker.PlayerOwner then break end
			end
			
			if recieved and recieved.targetIndex then
				local targetFighter = fightTable.AllFighters[recieved.targetIndex]
				if targetFighter then
					targetFighter.BatonBoost = true -- Stat boost flag for next hit
					fightTable.BonusTurnFighter = targetFighter
					CombatManager.NextTurn(fightTable)
					return
				end
			end
		end
		
		-- Default to self if no baton pass target selected or AI
		fightTable.BonusTurnFighter = attacker
		CombatManager.NextTurn(fightTable)
	else
		-- NORMAL TURN ROTATION
		fightTable.BonusTurnFighter = nil
		CurrentTurnIndex = (CurrentTurnIndex % #fightTable.AllFighters) + 1
		CombatManager.NextTurn(fightTable)
	end
end

function CombatManager.InitializeBattle(splitParticipants, centerCFrame, storylineConfig) -- start the combat loop
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
	-- optional CombatStoryline config (see FightHudIndicators.CombatStoryline) -- rides along in
	-- fightTable exactly like everything else here, so it reaches the client for free through the
	-- existing "start" FireClient below, no separate remote needed
	tab.StorylineConfig = storylineConfig
	
	-- Formation Spot Mapping
	for i, f in ipairs(tab.PlayerFighters) do
		f.FormationSpot = i
	end
	for i, f in ipairs(tab.EnemyFighters) do
		f.FormationSpot = i
	end
	
	local FormationCalculator = require(Storage.Modules.Mine.FormationCalculator)
	table.insert(Fights, tab)
	if centerCFrame then
		FormationCalculator.CalculateFormations(tab, centerCFrame)
	end
	
	if #tab.PlayersInvolved == 1 then
		tab.SpeedMultiplier = tab.PlayersInvolved[1].PlayerObject:GetAttribute("CurrentCombatSpeedMultiplier") or 1 
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
	
	-- Play Entrance Animations concurrently
	for i, plrTab in ipairs(tab.PlayersInvolved) do
		CombatReplicator:FireClient(plrTab.PlayerObject, "entranceAnimations", {fightTable = tab})
	end
	
	-- Wait for each involved player's client to actually finish their entrance sequence (scrub
	-- transition, cloning fighters in, loading animations, the camera walk-in) instead of guessing a
	-- fixed time -- a fixed guess doesn't know how much THIS fight needs to load (more fighters/heavier
	-- assets like an NPC ally's persona-summon = longer), which was cutting the walk-in camera off
	-- early whenever the real setup took longer than the guess. Capped with a timeout so one
	-- stuck/laggy/disconnected client can't hang the whole fight for everyone else.
	local pendingEntranceAcks = {}
	for _, plrTab in ipairs(tab.PlayersInvolved) do
		pendingEntranceAcks[plrTab.PlayerObject] = true
	end

	local entranceAckCon
	entranceAckCon = CombatReplicator.OnServerEvent:Connect(function(plr, action)
		if action == "entranceComplete" then
			pendingEntranceAcks[plr] = nil
		end
	end)

	local ENTRANCE_TIMEOUT = 8
	local waited = 0
	
	local function checkPendingPlayers()
		for plr, _ in pairs(pendingEntranceAcks) do
			if not plr.Parent then -- Player disconnected
				pendingEntranceAcks[plr] = nil
			end
		end
		return next(pendingEntranceAcks) ~= nil
	end
	while checkPendingPlayers() do
		if #tab.PlayersInvolved > 1 and waited >= ENTRANCE_TIMEOUT then
			break
		end
		task.wait(0.1)
		waited += 0.1
	end
	entranceAckCon:Disconnect()

	CombatManager.NextTurn(tab)
end

function CombatManager.NextTurn(fightTable) -- handle logic for current turn
	--task.wait(0.5) -- idk if i need this
	local currentStriker = fightTable.BonusTurnFighter or fightTable.AllFighters[CurrentTurnIndex]
	
	for i, plrTab in ipairs(fightTable.PlayersInvolved) do
		if not currentStriker.PlayerOwner or plrTab.PlayerObject ~= currentStriker.PlayerOwner then
			CombatReplicator:FireClient(plrTab.PlayerObject, "turnStartUpdate", {
				fighterData = currentStriker,
			})
		end
	end
	
	if fightTable.BonusTurnFighter and not fightTable.BonusTurnFighter.PlayerOwner then
		print("BATON PASS TRIGGERED TO NPC! Thinking...")
		task.wait(1.5) -- "Think" for a second before attacking
	end
	
	if currentStriker.PlayerOwner then
		CombatReplicator:FireClient(currentStriker.PlayerOwner, "yourTurn", {fightTable = fightTable, fighterData = currentStriker})
		print("WAITING FOR ACTION FROM: " .. currentStriker.PlayerOwner.Name)
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
			if recieved.TargetIndices then
				for _, idx in ipairs(recieved.TargetIndices) do
					if fightTable.AllFighters[idx] then
						table.insert(targetObjects, fightTable.AllFighters[idx])
					end
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
		print("AI'S TURN: " .. (currentStriker.ModelName or "NPC"))
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