-- Services
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")

-- Dependencies
local plr = PLRS.LocalPlayer
local cam = workspace.CurrentCamera

local Storage = RPS:WaitForChild("ClientStorage")
local CombatReplicator = Storage.Events.Remotes.ReplicateCombat
local WaitForInput = script.Parent:WaitForChild("WaitForInput")
local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)

local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings

local CameraManager = {}

-- Global Variables
CameraManager.CurrentMode = "None" -- "Idle", "Focus", "Cutscene"
CameraManager.OrbitAngle = 0
CameraManager.CenterPoint = Vector3.new(0, 0, 0)
CameraManager.Connections = {}
CameraManager.Binds = {}

CameraManager.IdlePhase = 4 -- 1: Orbit, 2: Pan A, 3: Pan B
CameraManager.PhaseTimer = 0
CameraManager.CurrentMaxTime = (25/gameSettings.CombatSettings.CombatSpeedMultiplier)

CameraManager.LastCCSM = plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1
CameraManager.CurrentRig = nil

CameraManager.TransitionTimer = 0
CameraManager.IsTransitioning = false
CameraManager.Transitioned = false

CameraManager.Settings = {
	InstantTransitions = true, -- Toggle this to true for "Snappy" cuts
	LerpWeight = 0.04,
	PanSpeed = 0.12
}

CameraManager.OffsetPresets = {
	SkillMenu = {
		NegativeOffset = true,
		RotOffset = CFrame.Angles(math.rad(-20), math.rad(15), math.rad(-8)),
		--PosOffset = Vector3.new(0, 25, 0)
		CFOffset = CFrame.new(-2, 8, 10)
	},
}

CameraManager.BASE_TIS = {
	["Base Zoom"] = TweenInfo.new(
		0.8/gameSettings.CombatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quint
	),
	["Mid Zoom"] = TweenInfo.new(
		3/gameSettings.CombatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quint
	),
	["Slow Zoom"] = TweenInfo.new(
		7.5/gameSettings.CombatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quint
	),
}

CameraManager.TIS = {}
for i, v in pairs(CameraManager.BASE_TIS) do
	CameraManager.TIS[i] = TweenInfo.new(
		v.Time/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1),
		v.EasingStyle,
		v.EasingDirection,
		v.RepeatCount,
		v.Reverses,
		v.DelayTime
	)
end

CameraManager.TES = {}

-- Local Functions
local function unbindAllBinds()
	for i, v in pairs(CameraManager.TES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	
	for i, v in pairs(CameraManager.Binds) do
		if v.Service == RS then
			v.Service:UnbindFromRenderStep(i)
		end
		CameraManager.Binds[i] = nil
	end
	if #CameraManager.Binds > 0 then
		CameraManager.Binds = {}
	end
end

function CameraManager.Circle(focalPoint, force, targetInstance) -- Added targetInstance parameter
	if CameraManager.CurrentMode ~= "Idle" or force then
		CameraManager.CurrentMode = "Idle"
		CameraManager.IsTransitioning = true -- Start the smooth transition
		CameraManager.TransitionTimer = 0
		unbindAllBinds()

		local center = focalPoint or CameraManager.CenterPoint
		local lastIdlePhase = CameraManager.IdlePhase

		RS:BindToRenderStep('IntermissionRotate', Enum.RenderPriority.Camera.Value, function(dt)
			CameraManager.PhaseTimer += dt

			-- Phase Switching Logic (Updated to 4 phases)
			if CameraManager.PhaseTimer >= (CameraManager.CurrentMaxTime/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1) then
				CameraManager.PhaseTimer = 0
				CameraManager.IdlePhase = (CameraManager.IdlePhase % 4) + 1 -- Now cycles through 4 phases

				if CameraManager.IdlePhase == 1 then
					-- "Jump" the orbit angle so it's fresh
					CameraManager.OrbitAngle += math.rad(math.random(45, 135))
					CameraManager.CurrentMaxTime = (8/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1) -- Orbit longer
				elseif CameraManager.IdlePhase == 4 then
					-- The new hover phase
					CameraManager.CurrentMaxTime = (25/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1) -- Look at character for 3 seconds
				else
					CameraManager.CurrentMaxTime = (6/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1) -- Pan shorter
				end
			end

			-- rig orientation: LookVector points from player TOWARD enemies
			-- so -LookVector = behind player, +LookVector = toward enemy side
			local rigCF = CameraManager.CurrentRig and CameraManager.CurrentRig:GetPivot() or CFrame.new(center)
			local right   = rigCF.RightVector
			local forward = rigCF.LookVector
			local up      = Vector3.new(0, 1, 0)

			if CameraManager.IdlePhase == 1 then
				-- MODE 1: THE ORBIT (arena-relative ellipse)
				CameraManager.OrbitAngle += dt * 0.12
				local localX = math.cos(CameraManager.OrbitAngle) * 15
				local localY = 5 + (math.sin(tick()) * 1) -- slight vertical bobbing
				local localZ = math.sin(CameraManager.OrbitAngle) * 50
				local worldOffset = right * localX + up * localY + forward * (-localZ)
				targetCF = CFrame.new(center + worldOffset, center)

			elseif CameraManager.IdlePhase == 2 then
				-- MODE 2: PAN behind the player team (arena-relative)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				-- behind player = -forward, panning left-to-right
				local startPos = center + right * (-15) + up * 8  + forward * (-20)
				local endPos   = center + right * ( 15) + up * 12 + forward * (-20)
				local currentPos = startPos:Lerp(endPos, alpha)
				targetCF = CFrame.new(currentPos, center)

			elseif CameraManager.IdlePhase == 3 then
				-- MODE 3: PAN from the enemy side, looking back at team (arena-relative)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				-- enemy side = +forward
				local startPos = center + right * ( 20) + up * 10 + forward * 15
				local endPos   = center + right * (-20) + up * 6  + forward * 15
				local currentPos = startPos:Lerp(endPos, alpha)
				targetCF = CFrame.new(currentPos, center)

			elseif CameraManager.IdlePhase == 4 then
				-- MODE 4: HOVER / SLIDE behind the rig (arena-relative)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				center = CameraManager.CurrentRig and CameraManager.CurrentRig:GetPivot().Position or center
				-- behind player, offset slightly right and above
				local anchorOffset = right * 5 + up * 3.5 + forward * (-12.5)
				local startCF = CFrame.new(center + anchorOffset, center)
				-- slide along rig's right axis
				local endCF = startCF * CFrame.new(15, 0, 0)
				local currentPos = startCF:Lerp(endCF, alpha)
				targetCF = currentPos
			end

			if CameraManager.IsTransitioning or CameraManager.Transitioned then
				CameraManager.TransitionTimer += dt
				-- Smoothly lerp from wherever the camera was (Focus position) to the Orbit
				cam.CFrame = cam.CFrame:Lerp(targetCF, 0.06) 

				if CameraManager.IsTransitioning then
					CameraManager.PhaseTimer = 0
					CameraManager.IsTransitioning = false
				end

				if not CameraManager.Transitioned then
					CameraManager.Transitioned = true
				elseif (CameraManager.Transitioned and CameraManager.IdlePhase ~= lastIdlePhase) then
					CameraManager.Transitioned = false
				end
			else
				-- SETTINGS-BASED LOGIC (Only runs after transition is done)
				if CameraManager.Settings.InstantTransitions then
					cam.CFrame = targetCF
				else
					cam.CFrame = cam.CFrame:Lerp(targetCF, CameraManager.Settings.LerpWeight)
				end
			end
		end)

		CameraManager.Binds["IntermissionRotate"] = { Service = RS }
	end
end

function CameraManager.Initialize(participants, manualCenter)
	--print(participants)
	-- Calculate Center: Average of all fighters
	unbindAllBinds()
	if manualCenter then
		CameraManager.CenterPoint = manualCenter
	else
		local totalPos = Vector3.new(0, 0, 0)
		for _, fighter in ipairs(participants) do
			totalPos += fighter.Instance:GetPivot().Position
		end
		CameraManager.CenterPoint = totalPos / #participants
	end
	
	cam.CameraType = Enum.CameraType.Scriptable
	cam.Focus = CFrame.new(CameraManager.CenterPoint)
	
	-- Stream in the area around the focal point.
	if workspace.StreamingEnabled then
		plr:RequestStreamAroundAsync(CameraManager.CenterPoint)
	end
	
	-- DEBUG CENTER MARKER
	local existingMarker = workspace:FindFirstChild("DebugCenterMarker")
	if existingMarker then existingMarker:Destroy() end
	local marker = Instance.new("Part")
	marker.Name = "DebugCenterMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.5, 4, 4)
	marker.Color = Color3.new(1, 0, 0)
	marker.Material = Enum.Material.Neon
	marker.Anchored = true
	marker.CanCollide = false
	marker.CFrame = CFrame.new(CameraManager.CenterPoint) * CFrame.Angles(0, 0, math.rad(90))
	marker.Parent = workspace
	
	--CameraManager.Circle()
end

-- enemyPOV: if true, places the camera on the player-team side of the target, looking outward
-- (i.e. the camera sees the target from behind the player, like an "enemy watching the hero" shot)
-- originInstance: if provided (during an attack), places the camera along the axis from the attacker to the target.
function CameraManager.FocusOn(targetInstance, zoomIn, offsetPreset, extraOffset, TIName, enemyPOV, originInstance)
	unbindAllBinds()
	
	if CameraManager.LastCCSM ~= plr:GetAttribute("CurrentCombatSpeedMultiplier") then
		CameraManager.LastCCSM = plr:GetAttribute("CurrentCombatSpeedMultiplier")
		for i, v in pairs(CameraManager.BASE_TIS) do
			CameraManager.TIS[i] = TweenInfo.new(
				v.Time/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1),
				v.EasingStyle,
				v.EasingDirection,
				v.RepeatCount,
				v.Reverses,
				v.DelayTime
			)
		end
	end
	
	CameraManager.CurrentMode = "Focus"
	local offset = nil
	if typeof(zoomIn) == 'number' then -- can be a number to specifiy zoom, or true or false to zoom in
		offset = zoomIn
	else
		offset = zoomIn and 8 or 15
	end
		
	local targetPos = targetInstance:GetPivot().Position
	
	local camPos = nil 
	if offsetPreset then
		local forwardAxis = targetInstance:GetPivot().LookVector
		local offsetDir = offsetPreset.OffsetDirection or "LookVector"
		-- Use the rig's true forward axis instead of the character's local one so the camera isn't crooked
		if offsetDir == "LookVector" and CameraManager.CurrentRig then
			forwardAxis = CameraManager.CurrentRig:GetPivot().LookVector
		elseif offsetDir == "RightVector" and CameraManager.CurrentRig then
			forwardAxis = CameraManager.CurrentRig:GetPivot().RightVector
		end
		
		camPos = targetPos + (((offsetPreset.NegativeOffset and -1 or 1) * forwardAxis) * offset) + Vector3.new(0, 2, 0) + (offsetPreset.PosOffset or Vector3.new())
	else
		local toTargetUnit
		if originInstance then
			-- Attack camera: Frame the shot along the line from the Attacker to the Target.
			-- (origin - targetPos) points from the Target backwards to the Attacker,
			-- placing the camera on the Attacker's side (an over-the-shoulder POV).
			local toOrigin = originInstance:GetPivot().Position - targetPos
			toTargetUnit = toOrigin.Magnitude > 0.01 and toOrigin.Unit or Vector3.new(0, 0, 1)
		else
			-- Target selection / Turn Start camera: 
			-- By using the negative LookVector, we ensure the camera is ALWAYS placed on the Player's side
			-- of the arena (behind players, in front of enemies), giving a perfect over-the-shoulder view.
			toTargetUnit = CameraManager.CurrentRig and -CameraManager.CurrentRig:GetPivot().LookVector or Vector3.new(0, 0, 1)
		end
		
		-- flip direction when enemyPOV: camera sits on enemy side looking back at player team
		local dirMult = enemyPOV and -1 or 1
		-- height scales with zoom offset to prevent looking up from the floor
		camPos = targetPos + (toTargetUnit * offset * dirMult) + Vector3.new(0, math.max(8, offset * 0.35), 0)
	end
	
	local finalCF = ((offsetPreset and offsetPreset.BaseOffset) or CFrame.new(camPos, targetPos)) * (offsetPreset and offsetPreset.RotOffset or CFrame.new()) * (offsetPreset and offsetPreset.CFOffset or CFrame.new())
	--cam.CFrame = finalCF * (extraOffset or CFrame.new())

	CameraManager.TES[1] = TS:Create(cam, CameraManager.TIS[TIName or "Base Zoom"], {
		CFrame = finalCF * (extraOffset or CFrame.new())
	})
	CameraManager.TES[1]:Play()

	--task.delay(2, function()
	--	if CameraManager.CurrentMode == "Focus" then CameraManager.CurrentMode = "Idle" end
	--end)
end

function CameraManager.SetToRig(rigModel)
	CameraManager.CurrentMode = "Cutscene"
	CameraManager.CurrentRig = rigModel
	
	-- This "locks" the camera to your Rig's CameraPart every single frame
	RS:BindToRenderStep("RigCam", Enum.RenderPriority.Camera.Value + 1, function()
		if CameraManager.CurrentMode == "Cutscene" and CameraManager.CurrentRig then
			cam.CFrame = CameraManager.CurrentRig.CameraPart.CFrame
		else
			-- If we switch back to Idle or Focus, stop following the rig
			RS:UnbindFromRenderStep("RigCam")
		end
	end)
	CameraManager.Binds["RigCam"] = {Service = RS}
end

function CameraManager.Stop(sendBacktoHuman)
	CameraManager.CurrentMode = "None"
	RS:UnbindFromRenderStep('IntermissionRotate')
	for i, v in pairs(CameraManager.Connections) do
		v:Disconnect()
	end
	unbindAllBinds()
	
	if sendBacktoHuman then
		cam.CameraSubject = plr.Character.Humanoid
		cam.CameraType = Enum.CameraType.Follow
		cam.CameraType = Enum.CameraType.Custom
	end
end

function CameraManager.BattleIntroPunch()
	-- Pokemon-style beat for the moment a fight kicks off: a quick zoom OUT (FOV widens, reads as the
	-- camera whipping back) immediately followed by a snappier zoom IN that overshoots past normal and
	-- eases back -- the overshoot is what gives it that dynamic, velocity-driven punch instead of a
	-- flat linear zoom. Runs before the scrub transition covers the screen and before any of the heavy
	-- fighter cloning/animation loading starts.
	unbindAllBinds()
	cam.CameraType = Enum.CameraType.Scriptable

	local baseFOV = cam.FieldOfView
	if baseFOV <= 1 then baseFOV = 70 end -- guard against catching it mid some other 0/1 FOV tween
	local pulledBackFOV = baseFOV + 45
	local punchedInFOV = baseFOV - 25

	local outTween = TS:Create(cam, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = pulledBackFOV})
	outTween:Play()
	outTween.Completed:Wait()

	local inTween = TS:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {FieldOfView = punchedInFOV})
	inTween:Play()
	inTween.Completed:Wait()

	local settleTween = TS:Create(cam, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FieldOfView = baseFOV})
	settleTween:Play()
	settleTween.Completed:Wait()
end


return CameraManager