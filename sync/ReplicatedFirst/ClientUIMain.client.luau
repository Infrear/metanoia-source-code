-- Services
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")

-- Dependencies
local plr = PLRS.LocalPlayer
repeat wait() until plr.Character
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local hrp = char:WaitForChild("HumanoidRootPart")

local mouse = plr:GetMouse()
local cam = workspace:WaitForChild("Camera")

local Storage = RPS:WaitForChild("ClientStorage")
local Scenes = Storage:WaitForChild("Scenes")
local loadedEv = Storage.Events:WaitForChild("Standard"):WaitForChild("LoadingDone")
local overworldCamToggleEffectsEv = Storage.Events:WaitForChild("Standard"):WaitForChild("ToggleOverworldCamStuff")
local harsherOverworldCamToggleEffectsEv = Storage.Events:WaitForChild("Standard"):WaitForChild("ToggleOverworldHarsherEffects")
local thirdPersonCamStuff = Storage.Events:WaitForChild("Standard"):WaitForChild("Toggle3rdPersonRegCamStuff")
local CombatReplicator = Storage.Events.Remotes.ReplicateCombat
local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings

local KeySettings = require(Storage.Info.KeybindsMaster)
local WaitForInput = script:WaitForChild("WaitForInput")
local SkillLibrary = require(Storage.Info.SkillLibrary)
local InputHandler = require(script:WaitForChild("InputHandler"))
local GUIMaster = require(script:WaitForChild("GUIMaster"))
local CameraHandler = require(script:WaitForChild("CameraHandler"))
local SceneDirector = require(script:WaitForChild("SceneDirector"))
local ScreenChangeHandler = require(script:WaitForChild("ScreenChangeHandler"))
local Maestro = require(script:WaitForChild("CombatCienematics"))
local FightHudIndicators = require(script:WaitForChild("FightHudIndicators"))
local slotSelect = require(script:WaitForChild("SlotSelect"))
local ChoiceManager = require(script:WaitForChild("ChoiceManager"))
local cursorImg = playerGUI:WaitForChild("Cursor"):WaitForChild("Cursor"):WaitForChild("ImageLabel")

-- Local Variables
local cons = {}
local ready = false
local doneLoading = false
local skipping = false

local interactables = nil
local quests = nil
local regions = nil

-- Constants
local MouseSettings = {
	["Button Growth"] = 0.5,
	["Button Shrink"] = 0.2,
	["Button Growth/Shrink Speed"] = 0.05
}
local TIS = {
	["Grow"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	),
	["Shrink"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	)
}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {workspace.NPCS, workspace.PERSONAS, workspace.SCRIPTING, workspace.BOUNDS, workspace.CAMERAS, workspace.NPCWALKERS, workspace.CHARACTERS, workspace.PARTICLES}

-- Local Functions
local function dictfind(tab, instKey)
	for i, v in ipairs(tab) do
		if v.Instance == instKey then
			return i
		end
	end
	return nil
end

local function checkPlatform()
	local lastInput = UIS:GetLastInputType()

	if lastInput == Enum.UserInputType.Touch then
		return "Mobile"
	elseif lastInput == Enum.UserInputType.Gamepad1 or
		lastInput == Enum.UserInputType.Gamepad2 or
		lastInput == Enum.UserInputType.Gamepad3 or
		lastInput == Enum.UserInputType.Gamepad4 then
		return "Console"
	elseif lastInput == Enum.UserInputType.Keyboard or
		lastInput == Enum.UserInputType.MouseButton1 or
		lastInput == Enum.UserInputType.MouseMovement then
		return "Keyboard"
	else
		return "Keyboard" -- Handle edge cases or unsupported inputs
	end
end

local function setupMouseStuff()
	local defaultSize = cursorImg.Size
	local currentTween = nil
	local clickTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale + MouseSettings["Button Growth"], 0, defaultSize.Y.Scale + MouseSettings["Button Growth"], 0)})
	local shrinkTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale - MouseSettings["Button Shrink"], 0, defaultSize.Y.Scale - MouseSettings["Button Shrink"], 0)})
	local defaultTween = TS:Create(cursorImg, TIS["Shrink"], {Size = defaultSize})

	mouse.Move:Connect(function()
		cursorImg.Parent.Position = UDim2.new(0, mouse.X, 0, mouse.Y)



		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			cursorImg.BackgroundColor3 = Color3.new(0.141176, 0.00784314, 0.905882)
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			cursorImg.BackgroundColor3 = Color3.new(1, 0, 0)
		else
			local pos = UDim2.new(0, mouse.X, 0, mouse.Y)
			local guisAtPosition = playerGUI:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

			for _, gui in ipairs(guisAtPosition) do
				if gui:IsA("TextButton") or gui:IsA("ImageButton") then
					cursorImg.BackgroundColor3 = Color3.new(0, 0.6, 1)
					return
				end
			end

			cursorImg.BackgroundColor3 = Color3.new(1, 1, 1)
		end
	end)

	UIS.InputBegan:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 then
			--print("down")
			cursorImg.BackgroundColor3 = Color3.new(0.141176, 0.00784314, 0.905882)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = clickTween
			currentTween:Play()
		elseif inputType == mouse2 then
			cursorImg.BackgroundColor3 = Color3.new(1, 0, 0)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = shrinkTween
			currentTween:Play()
		end
	end)

	UIS.InputEnded:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 or inputType == mouse2 then
			--print("up")
			cursorImg.BackgroundColor3 = Color3.new(1, 1, 1)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = defaultTween
			currentTween:Play()
		end
	end)

	--UIS.InputBegan:Connect(function(input, gP)
	--	local inputType = input.UserInputType
	--	local touch = Enum.UserInputType.Touch
	--	local mouse1 = Enum.UserInputType.MouseButton1
	--	if inputType == touch or inputType == mouse1 and (not clickTween or clickTween.PlaybackState ~= Enum.PlaybackState.Playing) then
	--		-- tween the cursor's size
	--		clickTween:Play()
	--		local con 
	--		con = clickTween.Completed:Connect(function()
	--			con:Disconnect()
	--			cursorImg.Size = defaultSize
	--		end)
	--	end
	--end)
end

local function setupUIs()
	playerGUI:WaitForChild("Interactables").Enabled = false
	playerGUI:WaitForChild("GlobalUI").Enabled = false
	playerGUI:WaitForChild("SkillsMenu").Enabled = false
	playerGUI:WaitForChild("SlotSelectGui").Enabled = true
	if playerGUI:FindFirstChild("Idk Nova u can name this") then
		playerGUI:FindFirstChild("Idk Nova u can name this").Enabled = false
	end

	ScreenChangeHandler.Initialize()
	if checkPlatform() ~= "Mobile" then
		playerGUI:WaitForChild("Cursor").Enabled = true
	end
	
	for i, v in pairs(GUIMaster.UIs) do
		if v.Open == false and v.Object and (v.Object:IsA("ScreenGui") or v.Object:IsA("BillboardGui")) then
			if v.OpenAnimationInfo then
				if v.OpenAnimationInfo.Reset then
					v.OpenAnimationInfo.Reset(v.Object)
				elseif v.OpenAnimationInfo.OutFunction then
					v.OpenAnimationInfo.OutFunction(v.Object)
				end
			elseif (v.Object:IsA("ScreenGui") or v.Object:IsA("BillboardGui")) then
				v.Enabled = false
			end
		end
	end
	
	-- For later loading screen
	--[[coroutine.wrap(function()
		loading.setup(skipping)
	end)()

	coroutine.wrap(function()
		local con = nil
		con = loading.Ready.Event:Connect(function()
			con:Disconnect()
			doneLoading = true
		end)
	end)()
	print("ok")]]--

	script.Parent = playerGUI
	

	slotSelect = require(script:WaitForChild("SlotSelect"))
	interactables = require(script:WaitForChild("Interactables"))
	quests = require(script:WaitForChild("Quests"))
	regions = require(script:WaitForChild("Regions"))

	playerGUI:WaitForChild("GlobalUI").Enabled = true
	playerGUI:WaitForChild("OverworldUI").Enabled = true

	interactables.setup()
	slotSelect.setup()
	regions.setup()
	task.wait(0.25)
	quests.setup()

	--task.wait(1.25) -- buffer
	--repeat wait() until doneLoading

	--task.desynchronize()
	setupMouseStuff()
	--task.synchronize()

	playerGUI:WaitForChild("OverworldUI").Enabled = true
	playerGUI:WaitForChild("Interactables").Enabled = true
	--if checkPlatform() ~= "Mobile" then
	--	plr.PlayerScripts.Camera["TSC v1"].Enabled = true
	--end
	--if not skipping then
	--	task.wait(2)
	--end
	--loading.tweenOutCover()
	--task.wait(7)
	--Loop = false
	
	--SceneDirector.Play(Scenes.Scene_DreamWorldIntro, true)
end

local LocalFightersMap = {}
local LocalClonedFighters = {}
local ActiveGuardShields = {} -- [fighterInstance] = the persistent Shield-01 VFX instance while they're guarding

local ActiveRing = nil
local SpinConnection = nil

local function getFloorYForRing(x, y, z)
	local rayOrigin = Vector3.new(x, y + 10, z)
	local rayDirection = Vector3.new(0, -50, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	return y - 2.8 
end

local function handleRingVisuals(fighter) -- handles the selection ring behavior
	if SpinConnection then SpinConnection:Disconnect() end
	if ActiveRing then ActiveRing:Destroy() end
	
	local ringTemplate = Storage:FindFirstChild("Effects") and Storage.Effects:FindFirstChild("Combat") and Storage.Effects.Combat:FindFirstChild("Ring")
	if not ringTemplate then
		ringTemplate = Storage:FindFirstChild("Visuals") and Storage.Visuals:FindFirstChild("CombatRing")
	end
	
	if not ringTemplate then return end
	
	ActiveRing = ringTemplate:Clone()
	ActiveRing.Parent = fighter.Instance

	SpinConnection = RS.Heartbeat:Connect(function()
		if ActiveRing and fighter and fighter.Instance then
			ActiveRing:PivotTo(ActiveRing:GetPivot() * CFrame.Angles(0, math.rad(2), 0))
			
			local pivot = fighter.Instance:GetPivot()
			local floorY = getFloorYForRing(pivot.X, pivot.Y, pivot.Z)
			
			local floorCF = CFrame.new(pivot.X, floorY + 0.1, pivot.Z)
			
			ActiveRing:PivotTo(CFrame.new(floorCF.Position) * (ActiveRing:GetPivot() - ActiveRing:GetPivot().Position))
		end
	end)
end

-- Connections
CombatReplicator.OnClientEvent:Connect(function(action, data)
	-- On "start", Maestro.InitiateBattle owns the whole sequence (intro punch, transition, cloning
	-- fighters in, loading animations, reveal) so it can control the order start to finish. For every
	-- other action, fighters are already cloned/mapped, so this generic block just resolves references.
	if action ~= "start" and data and data.fightTable then
		-- If some other action's data arrives while "start" is still mid-sequence (punch/transition/
		-- cloning inside Maestro.InitiateBattle, which now runs in its own coroutine per firing), wait
		-- for it to finish instead of racing ahead. That race was the actual bug: this block would
		-- find/claim a fighter (like Timmy, an existing NPC) in LocalFightersMap first without
		-- positioning them, then InitiateBattle's own cloning loop would see the ID already claimed
		-- and skip positioning them entirely -- commenting out the cloning here didn't fix the race,
		-- it just meant nothing ever positioned them.
		if not Maestro.BattleReady then
			repeat task.wait() until Maestro.BattleReady
		end

		for _, f in ipairs(data.fightTable.AllFighters) do
			if not f.Instance then
				if not LocalFightersMap[f.ID] then
					local existing = workspace.NPCS:FindFirstChild(f.ModelName)
					if existing then
						LocalFightersMap[f.ID] = existing
					else
						local template = Storage.Personas:FindFirstChild(f.ModelName) or Storage.NPCs:FindFirstChild(f.ModelName)
						local newInst = template and template:Clone() or Instance.new("Model")
						newInst.Name = "Enemy_" .. (f.ModelName or "Unknown")
						newInst.Parent = workspace.PERSONAS
						LocalFightersMap[f.ID] = newInst
						table.insert(LocalClonedFighters, newInst)
					end
					
					local prompt = LocalFightersMap[f.ID]:FindFirstChild("HumanoidRootPart") and LocalFightersMap[f.ID].HumanoidRootPart:FindFirstChild("ProximityPrompt") or LocalFightersMap[f.ID]:FindFirstChild("ProximityPrompt")
					if prompt then
						if prompt.Enabled then
							prompt:SetAttribute("WasEnabled", prompt:GetAttribute("WasEnabled") or prompt.Enabled)
							prompt.Enabled = false
						end
					end
					if f.SpawnCFrame then
						LocalFightersMap[f.ID]:PivotTo(f.SpawnCFrame)
					end
				end
				f.Instance = LocalFightersMap[f.ID]
			end
		end
		
		-- Due to Roblox network serialization, PlayerFighters and EnemyFighters are different memory objects than AllFighters.
		if data.fightTable.PlayerFighters then
			for _, f in ipairs(data.fightTable.PlayerFighters) do
				if not f.Instance then f.Instance = LocalFightersMap[f.ID] end
			end
		end
		if data.fightTable.EnemyFighters then
			for _, f in ipairs(data.fightTable.EnemyFighters) do
				if not f.Instance then f.Instance = LocalFightersMap[f.ID] end
			end
		end
	end
	
	if data and data.fighterData and not data.fighterData.Instance then
		data.fighterData.Instance = LocalFightersMap[data.fighterData.ID]
	end
	if data and data.targets then
		for _, t in ipairs(data.targets) do
			if not t.Instance then
				t.Instance = LocalFightersMap[t.ID]
			end
		end
	end

	if action == "start" then -- MAYBE LATER BETTER OPTIMIZATION BY PUTTING HEAVY STUFF TO DO HERE/SETUP ONCE THROUGHOUT THE FIGHT
		overworldCamToggleEffectsEv:Fire(false, true)
		harsherOverworldCamToggleEffectsEv:Fire(false)
		thirdPersonCamStuff:Fire(false)
		local camRig = Storage.Animations.Camera.Rigs.CamRig:Clone()
		camRig.PrimaryPart.Anchored = true
		camRig.Parent = workspace.SCRIPTING
		camRig:PivotTo(CFrame.new(0, 0, 0)) -- Start at origin
		
		script:SetAttribute("CurrentCamRig", camRig.Name) -- store reference if needed, or just let Maestro handle it
		_G.CombatCamRig = camRig -- Quick global access for entranceAnimations
		
		FightHudIndicators.Init()
		playerGUI:WaitForChild("SkillsMenu").Enabled = true
		
		Maestro.InitiateBattle(char, camRig, data.fightTable, char:GetPivot(), LocalFightersMap, LocalClonedFighters)
		
	elseif action == "guardUpdate" then
		-- Persistent Shield-01 effect while guarding -- tracked per-fighter so it can be cleanly
		-- removed later (either faded out normally when their guard ends, or destroyed abruptly and
		-- replaced with the break burst if a hit shatters it -- see attackUpdate/turnStartUpdate below)
		if data.fighterData and data.fighterData.Instance then
			local existingShield = ActiveGuardShields[data.fighterData.Instance]
			if existingShield then
				existingShield:Destroy()
				ActiveGuardShields[data.fighterData.Instance] = nil
			end

			local guardVFXFolder = Storage.Effects.Combat:FindFirstChild("GuardVFX")
			local defaultFn = guardVFXFolder and guardVFXFolder:FindFirstChild("Default")
			if defaultFn then
				local vfxOk, shieldInstance = pcall(require(defaultFn), data.fighterData.Instance)
				if vfxOk and shieldInstance then
					ActiveGuardShields[data.fighterData.Instance] = shieldInstance
				elseif not vfxOk then
					warn("[ClientUIMain] guard VFX error: " .. tostring(shieldInstance))
				end
			end
		end

	elseif action == "endBattle" then
		for _, inst in ipairs(LocalClonedFighters) do
			if inst then inst:Destroy() end
		end
		table.clear(LocalFightersMap)
		table.clear(LocalClonedFighters)
		
		if SpinConnection then SpinConnection:Disconnect() end
		if ActiveRing then ActiveRing:Destroy() end

		FightHudIndicators.CombatStoryline.OnBattleEnd()
		FightHudIndicators.CombatStoryline.WaitForClear()
		FightHudIndicators.CombatStoryline.Cleanup()
		FightHudIndicators.HealthTray.Clear()

	elseif action == "storylineEvent" then
		-- Server-fired custom CombatStoryline beats (e.g. "GolemEnraged" when a golem crosses its
		-- HP threshold) -- see CombatManager.ExecuteSkill for where these get fired
		FightHudIndicators.CombatStoryline.FireEvent(data.EventName)
		
	elseif action == "promptBatonPass" then
		-- Prompt the Baton Pass UI
		if GUIMaster.PromptBatonPass then
			GUIMaster.PromptBatonPass(data.fightTable)
		else
			-- Fallback: auto-pass to Timmy if he exists, otherwise self
			local targetIdx = nil
			for i, f in ipairs(data.fightTable.AllFighters) do
				if f.IsNPC then targetIdx = i break end
			end
			CombatReplicator:FireServer("batonPass", targetIdx)
		end
		
	elseif action == "swapUpdate" then
		-- free tray swap — play summon visual and refresh skills menu
		local fighterObj = data.fighterData
		if fighterObj and fighterObj.Instance then
			-- CUSTOM SWITCH ANIMATION PLACEHOLDER — for now uses the summon cinematic
			-- REPLACE THIS WITH A LIGHTER SWAP ANIM LATER
			Maestro.SummonPersona(fighterObj.Instance, fighterObj.ActivePersona.Name)
			
			-- if it's our fighter, refresh skills menu with new persona's skills
			if GUIMaster.CurrentFighterData and GUIMaster.CurrentFighterData.ID == fighterObj.ID then
				GUIMaster.CurrentFighterData = fighterObj
				-- refresh the skills menu if it's open
				if GUIMaster.UIs.SkillsMenu.Open then
					ChoiceManager.ToggleSkillMenu("Skills", fighterObj.ActivePersona.Name, fighterObj.Skills, true)
				end
			end
		end

	elseif action == "turnStartUpdate" then -- AND HERE KEEP THE UI STUFF
		CameraHandler.FocusOn(data.fighterData.Instance, 12.5)
		
		-- Ring Visuals
		handleRingVisuals(data.fighterData)

		-- If this fighter had an active guard shield and their Guarding flag is now false (server
		-- clears it right as their own turn starts), their guard ended normally -- fade/remove the
		-- shield. A BROKEN guard (from a hit) is handled separately in attackUpdate and won't still
		-- be tracked here by the time this fires.
		if data.fighterData and data.fighterData.Instance then
			local shield = ActiveGuardShields[data.fighterData.Instance]
			if shield and not data.fighterData.Guarding then
				local TS_ = game:GetService("TweenService")
				for _, desc in ipairs(shield:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then desc.Enabled = false end
				end
				TS_:Create(shield, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1}):Play()
				task.delay(0.5, function()
					if shield then shield:Destroy() end
				end)
				ActiveGuardShields[data.fighterData.Instance] = nil
			end
		end
		
	elseif action == "attackUpdate" then --- THIS IS WHERE THE FIGHTER DATA IS SENT TO THE CLIENT LIKE MAYBE WHEN A FIGHTER MAKES A MOVE I WANNA DISPLAY ON THE SCREEN

		-- 1. Camera focuses on attacker (or general area if multiple targets)
		-- We pass the whole target table to Maestro so it can decide how to position
		local speedMult = (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
		-- BUG FIX: Check if Skill exists in library before indexing CameraInfo
		local skillData = SkillLibrary.List[data.skill]
		
		-- [TESTING]: Show the ability announcement for any skill so we can test the UI!
		--if data.attackType == "Skill" and skillData then
		--	local fighterName = data.fighterData.DisplayName or data.fighterData.Instance.Name
		--	local skillDisplayName = skillData.Name or data.skill
		--	FightHudIndicators.AbilityAnnouncement.Show(fighterName .. " uses " .. skillDisplayName .. "!", {Duration = 2.5, ShakeIntensity = 3})
		--end
			
		-- Per-move camera config (see CameraHandler MOVE CAMERA SYSTEM) -- nil for any move that
		-- hasn't opted in, in which case every FocusOn call below stays exactly as it always was
		local moveCameraConfig = skillData and skillData.CameraInfo and skillData.CameraInfo.MoveCamera

		if data.windUp then
			coroutine.wrap(function()
				local isEnemy = dictfind(data.fightTable.EnemyFighters, data.fighterData.Instance)
				-- pass the total effective speed factor through so the windup's internal timing
				-- (holding the persona's Attack1 anim) actually scales with combat speed too
				Maestro.CienemateWindUp(char, data.attackType, data.fighterData, data.targets, isEnemy, combatSettings.CombatSpeedMultiplier * speedMult)
			end)()

			-- Wait for "Attack" windup
			local windupDuration = (((skillData.CameraInfo and skillData.CameraInfo.WindupTime) or combatSettings.WIND_UP_DELAY)/combatSettings.CombatSpeedMultiplier) / speedMult

			if moveCameraConfig and moveCameraConfig.In then
				-- Runs alongside the windup wait below (not instead of it) so CienemateWindUp's
				-- animation timing is completely untouched -- this only changes what the camera does
				coroutine.wrap(function()
					CameraHandler.RunMoveCameraPhase(moveCameraConfig.In, data.fighterData.Instance, data.targets[1] and data.targets[1].Instance, windupDuration)
				end)()
			end

			task.wait(windupDuration)
		end
		---- 2. Camera focuses on targets
		-- If multiple targets, we focus on the first one or you could use CameraHandler.Circle(center)
		if moveCameraConfig and moveCameraConfig.Out then
			-- Mirrors the same total duration the fallback FocusOn path below would've waited for,
			-- so a move opting into MoveCamera doesn't change the overall pacing of its own attack
			local outDuration = (0.75 / gameSettings.CombatSettings.CombatSpeedMultiplier) / speedMult
			if skillData and skillData.CameraInfo and skillData.CameraInfo.AttackTime then
				outDuration = math.max(outDuration, skillData.CameraInfo.AttackTime / gameSettings.CombatSettings.CombatSpeedMultiplier / speedMult)
			end
			coroutine.wrap(function()
				CameraHandler.RunMoveCameraPhase(moveCameraConfig.Out, data.fighterData.Instance, data.targets[1] and data.targets[1].Instance, outDuration)
			end)()
		elseif #data.targets == 1  then
			CameraHandler.FocusOn(data.targets[1].Instance, 27.5, nil, nil, nil, nil, data.fighterData.Instance)

		elseif skillData and skillData.CameraInfo and skillData.CameraInfo.MultiAttackCamType == "All At Once" then
			-- For multi-target, we focus on the group or the middle-most target
			CameraHandler.FocusOn(data.targets[math.ceil(#data.targets/2)].Instance, 35, nil, nil, nil, nil, data.fighterData.Instance) -- later make and us e amethod for finding the instance with the middlemost position, or an avevrage of all
		else
			CameraHandler.FocusOn(data.targets[1].Instance, 27.5, nil, nil, nil, nil, data.fighterData.Instance)
		end

		task.wait((0.75 / gameSettings.CombatSettings.CombatSpeedMultiplier) / speedMult)

		coroutine.wrap(function()
			Maestro.CienemateMove(char, data.attackType, data.skill, data.fighterData, data.targets)
		end)()
		
		if skillData and skillData.CameraInfo and skillData.CameraInfo.AttackTime then
			local waitTime = (skillData.CameraInfo.AttackTime - (0.75 / gameSettings.CombatSettings.CombatSpeedMultiplier) / speedMult)
			if waitTime > 0 then task.wait(waitTime) end
		end
		
		-- 3. Show Damage, Hearts, and One More for ALL targets
		local showedOneMore = false
		for i, target in ipairs(data.targets) do
			local targetResult = data.results[i]
			local targetOldHealth = data.oldHealths[i]

			-- Create Damage Popup for this specific target
			coroutine.wrap(function()
				-- We pass a modified data table so the UI knows which specific result to show
				local individualData = {
					target = target,
					result = targetResult,
					damage = data.damage -- Assuming base damage is sent
				}
				GUIMaster.CreateDamagePopup(target.Instance, individualData)
			end)()
			
			if target.Instance then
				task.delay(0.15, function() -- slight delay so popup appears first
					FightHudIndicators.HealthTray.Update(target.Instance, target.HP, target.MaxHP)
				end)
			end

			-- Update Heart/Health bar for this specific target
			if targetOldHealth then
				GUIMaster.MoveHeart(
					target, 
					targetOldHealth / target.MaxHP, 
					(0.85 / gameSettings.CombatSettings.CombatSpeedMultiplier) / speedMult
				)
			end

			-- Guard block/break VFX
			if (targetResult == "BLOCKED" or targetResult == "GUARD_BREAK") and target.Instance then
				local guardVFXFolder = Storage.Effects.Combat:FindFirstChild("GuardVFX")
				if targetResult == "BLOCKED" then
					local blockFn = guardVFXFolder and guardVFXFolder:FindFirstChild("BlockHit")
					if blockFn then
						local vfxOk, vfxErr = pcall(require(blockFn), target.Instance)
						if not vfxOk then warn("[ClientUIMain] block VFX error: " .. tostring(vfxErr)) end
					end
				elseif targetResult == "GUARD_BREAK" then
					-- Guard broke -- kill the persistent shield immediately (no fade, it just shattered)
					-- and play the break burst in its place
					local shield = ActiveGuardShields[target.Instance]
					if shield then
						shield:Destroy()
						ActiveGuardShields[target.Instance] = nil
					end
					local breakFn = guardVFXFolder and guardVFXFolder:FindFirstChild("ShieldBreak")
					if breakFn then
						local vfxOk, vfxErr = pcall(require(breakFn), target.Instance)
						if not vfxOk then warn("[ClientUIMain] shield break VFX error: " .. tostring(vfxErr)) end
					end
				end
			end

			-- Check if any hit was a weakness (or broke a guard, which server-side also grants the
			-- bonus turn for -- see CombatManager's CRITCOUNTER check) to trigger the "One More" UI
			if (targetResult == "WEAK" or targetResult == "GUARD_BREAK") and not showedOneMore then
				showedOneMore = true
				coroutine.wrap(function()
					task.wait((0.5 / gameSettings.CombatSettings.CombatSpeedMultiplier) / speedMult)
					GUIMaster.ShowOneMore()
				end)()
			end
		end
	elseif action == "yourTurn" then -- THEN HERE THE USUAL UI STUFF
		CameraHandler.Circle()
		GUIMaster.CanBatonPass = data.canBatonPass
		local c1 = GUIMaster.InitializeUI(char, data.fightTable, data.fighterData)
		if c1 then
			local c2 = InputHandler.InitializeInput()--playerFighters[1].Instance)
		end
	elseif action == "turnEnded" then -- AND HERE KEEP THE UI STUFF
		GUIMaster.CloseAllBattleUIs()
		InputHandler.Stop()
		print("Turn ended!")
	elseif action == "end" then -- AND HERE DO ALL THE BIG CLEANUP STUFF WHEN A FIGHT ENDS
		GUIMaster.CloseAllBattleUIs()
		InputHandler.Stop()
		Maestro.Cleanup()
		if SpinConnection then SpinConnection:Disconnect() end
		if ActiveRing then ActiveRing:Destroy() end
		print("Combat ended!")
		overworldCamToggleEffectsEv:Fire(true, true)
		harsherOverworldCamToggleEffectsEv:Fire(true)
		thirdPersonCamStuff:Fire(true)
	end
end)

WaitForInput.Event:Connect(function(action, skill, targetIndex)
	InputHandler.Stop()
	GUIMaster.CloseAllBattleUIs()
	--print("Turn ended!")
	CombatReplicator:FireServer(action, skill, targetIndex, plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
end)

-- Loose Threads
UIS.MouseIconEnabled = false
task.wait(1.5)
setupUIs()
--print("confirmed")
ready = true