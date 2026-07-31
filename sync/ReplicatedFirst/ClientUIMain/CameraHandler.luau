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

			local targetCF
			
			--print(CameraManager.IdlePhase)
			--print(CameraManager.CurrentMaxTime)
			
			if CameraManager.IdlePhase == 1 then
				-- MODE 1: THE ORBIT
				CameraManager.OrbitAngle += dt * 0.12
				local offset = Vector3.new(
					math.cos(CameraManager.OrbitAngle) * 15, 
					5 + (math.sin(tick()) * 1), -- Slight vertical bobbing
					math.sin(CameraManager.OrbitAngle) * 50
				)
				targetCF = CFrame.new(center + offset, center)

			elseif CameraManager.IdlePhase == 2 then
				-- MODE 2: LINEAR PAN (Side A to B)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				local startPos = center + Vector3.new(-15, 8, 20)
				local endPos = center + Vector3.new(15, 12, 20)

				local currentPos = startPos:Lerp(endPos, alpha)
				targetCF = CFrame.new(currentPos, center)

			elseif CameraManager.IdlePhase == 3 then
				-- MODE 3: LINEAR PAN (Side B to A, different angle)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				local startPos = center + Vector3.new(20, 10, -15)
				local endPos = center + Vector3.new(-20, 6, -15)

				local currentPos = startPos:Lerp(endPos, alpha)
				targetCF = CFrame.new(currentPos, center)

			elseif CameraManager.IdlePhase == 4 then
				-- MODE 4: LINEAR PAN (Side B to A, different angle)
				local alpha = ((CameraManager.PhaseTimer / CameraManager.CurrentMaxTime)/gameSettings.CombatSettings.CombatSpeedMultiplier) / (plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)
				center = CameraManager.CurrentRig and CameraManager.CurrentRig:GetPivot().Position or center
				local startPos = CFrame.new(center + Vector3.new(5, 3.5, 12.5), center)
				local endPos = startPos * CFrame.new(15, 0, 0)

				local currentPos = startPos:Lerp(endPos, alpha)
				targetCF = currentPos --CFrame.new(currentPos, center)
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
	--CameraManager.Circle()
end

function CameraManager.FocusOn(targetInstance, zoomIn, offsetPreset, extraOffset, TIName)
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
		camPos = targetPos + (((offsetPreset.NegativeOffset and -1 or 1) * targetInstance:GetPivot()[offsetPreset.OffsetDirection or "LookVector"]) * offset) + Vector3.new(0, 2, 0) + (offsetPreset.PosOffset or Vector3.new())
	else
		camPos = targetPos + (targetInstance:GetPivot().LookVector * offset) + Vector3.new(0, 2, 0)
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

return CameraManager