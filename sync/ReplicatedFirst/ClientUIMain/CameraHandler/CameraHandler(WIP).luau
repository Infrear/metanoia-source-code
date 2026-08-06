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

-- ============================================================================================
-- MOVE CAMERA SYSTEM
-- ============================================================================================
-- Highly customizable per-move camera architecture. Each move's camera config lives at
-- skill.CameraInfo.MoveCamera = {In = {...}, Out = {...}} in SkillLibrary.
--
-- In / Out phases: In = wind-up/setup, Out = impact/follow-through. Each phase is independently
-- typed as either "Procedural" (camera follows a point -- a spell particle, the target, etc) or
-- "AnimationObject" (camera rides a physical animation played on a cloned CamRig).
--
-- Hybrid fallback: Out is entirely optional. Enemies sit at different spots on the battlefield,
-- so a static rig animation rarely makes sense for the impact beat -- if Out is omitted,
-- PlayMoveCamera automatically falls back to a procedural focus-on-target tween instead.
--
-- Global default: if a move has no CameraInfo.MoveCamera at all, PlayMoveCamera just calls the
-- standard static CameraManager.FocusOn view, same as every move before this system existed --
-- fully backwards compatible, nothing about existing moves needs to change.
--
-- Dummy example move (Rig-based In, Procedural Out) -- see SkillLibrary for where this would live:
--
--   CameraInfo = {
--       CameraTime = 4.2,
--       AttackTime = 2.6,
--       MoveCamera = {
--           In = {
--               Type = "AnimationObject",
--               RigName = "CamRig",                    -- looked up under Storage.Animations.Camera.Rigs
--               AnimationId = "rbxassetid://00000000",  -- the wind-up camera move, authored relative to a caster at the origin
--               PlaybackSpeed = 1,
--           },
--           Out = {
--               Type = "Procedural",
--               FollowPoint = "Target",     -- "Caster" / "Target" / an Instance (e.g. a spell VFX attachment) / a function
--               Snappiness = 0.22,          -- per-frame lerp weight -- higher = snaps to the point faster
--               Delay = 0.05,               -- seconds to wait before this phase starts moving
--               StopAtPoint = false,        -- false = keep following for the whole phase; true = ease to the point once, then hold
--           },
--       },
--   }
--
-- Call it from combat like: CameraManager.PlayMoveCamera(skillData.CameraInfo.MoveCamera, casterInstance, targetInstance, windupDuration, attackDuration)

local moveCameraToken = nil -- bumped every PlayMoveCamera call so a stale phase's bind/wait bails cleanly instead of fighting a newer one

-- Resolves a FollowPoint/LookAt reference into a world Vector3. Accepts: "Caster"/"Target"
-- (resolved against the instances passed to PlayMoveCamera), a BasePart/Attachment/Model
-- Instance (e.g. a moving spell particle), a plain Vector3, or a function returning any of those
-- (for fully custom/dynamic follow points).
local function resolveMoveCameraPoint(pointRef, casterInstance, targetInstance)
	if typeof(pointRef) == "function" then
		return resolveMoveCameraPoint(pointRef(), casterInstance, targetInstance)
	elseif pointRef == "Caster" then
		return casterInstance and casterInstance:GetPivot().Position
	elseif pointRef == "Target" then
		return targetInstance and targetInstance:GetPivot().Position
	elseif typeof(pointRef) == "Vector3" then
		return pointRef
	elseif typeof(pointRef) == "Instance" then
		if pointRef:IsA("Attachment") then
			return pointRef.WorldPosition
		elseif pointRef:IsA("BasePart") then
			return pointRef.Position
		elseif pointRef:IsA("Model") then
			return pointRef:GetPivot().Position
		end
	end
	return nil
end

-- Procedural phase: camera lerps toward (and optionally keeps following) a moving point.
-- "Snappiness" is just the per-frame lerp weight -- higher snaps closer to the point each frame,
-- lower trails behind it more loosely. StopAtPoint = true means ease to the point once and hold
-- there instead of continuing to track it for the rest of the phase.
local function runProceduralMovePhase(phaseConfig, casterInstance, targetInstance, duration, myToken)
	unbindAllBinds()
	cam.CameraType = Enum.CameraType.Scriptable

	local followSpeed = phaseConfig.Snappiness or phaseConfig.FollowSpeed or 0.15

	if phaseConfig.Delay and phaseConfig.Delay > 0 then
		task.wait(phaseConfig.Delay / combatSettings.CombatSpeedMultiplier)
	end
	if moveCameraToken ~= myToken then return end

	local startTime = os.clock()
	local reachedStopPoint = false

	RS:BindToRenderStep("MoveCameraProcedural", Enum.RenderPriority.Camera.Value, function()
		if moveCameraToken ~= myToken then
			RS:UnbindFromRenderStep("MoveCameraProcedural")
			return
		end

		local elapsed = os.clock() - startTime
		if elapsed >= (duration or 999) or (phaseConfig.StopAtPoint and reachedStopPoint) then
			RS:UnbindFromRenderStep("MoveCameraProcedural")
			return
		end

		local point = resolveMoveCameraPoint(phaseConfig.FollowPoint or "Target", casterInstance, targetInstance)
		if point then
			local lookPoint = phaseConfig.LookAt and resolveMoveCameraPoint(phaseConfig.LookAt, casterInstance, targetInstance) or point
			local desiredPos = phaseConfig.OffsetFromPoint and (point + phaseConfig.OffsetFromPoint) or point
			local desiredCF = CFrame.new(desiredPos, lookPoint)

			cam.CFrame = cam.CFrame:Lerp(desiredCF, followSpeed)

			if phaseConfig.StopAtPoint and (cam.CFrame.Position - desiredCF.Position).Magnitude < (phaseConfig.StopThreshold or 0.5) then
				reachedStopPoint = true
			end
		end
	end)
	CameraManager.Binds["MoveCameraProcedural"] = {Service = RS}

	if phaseConfig.StopAtPoint then
		local waited = 0
		while not reachedStopPoint and waited < (duration or 5) and moveCameraToken == myToken do
			task.wait(0.05)
			waited += 0.05
		end
	else
		task.wait(duration or 0)
	end

	if CameraManager.Binds["MoveCameraProcedural"] then
		RS:UnbindFromRenderStep("MoveCameraProcedural")
		CameraManager.Binds["MoveCameraProcedural"] = nil
	end
end

-- AnimationObject phase: since move animations are authored relative to wherever the caster
-- happens to be standing, the CamRig gets teleported to the caster's position/orientation before
-- the animation plays -- then it's the exact same follow mechanism as CameraManager.SetToRig.
local function runRigMovePhase(phaseConfig, casterInstance, duration, myToken)
	unbindAllBinds()

	local rigTemplate = phaseConfig.RigTemplate or (Storage.Animations.Camera.Rigs:FindFirstChild(phaseConfig.RigName or "CamRig"))
	if not rigTemplate then
		warn("[CameraManager] MoveCamera AnimationObject phase: no rig template found (RigName='" .. tostring(phaseConfig.RigName) .. "')")
		return
	end

	local rig = rigTemplate:Clone()
	rig.Parent = workspace:FindFirstChild("SCRIPTING") or workspace
	rig:PivotTo(casterInstance:GetPivot())

	local animController = rig:FindFirstChildOfClass("AnimationController")
	local animator = animController and animController:FindFirstChildOfClass("Animator")

	if not animator or not phaseConfig.AnimationId then
		warn("[CameraManager] MoveCamera AnimationObject phase: missing Animator on rig or no AnimationId given")
		rig:Destroy()
		return
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = phaseConfig.AnimationId

	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action

	CameraManager.SetToRig(rig)
	track:Play(0, 1, phaseConfig.PlaybackSpeed or 1)

	local playedDuration = duration or (track.Length / (phaseConfig.PlaybackSpeed or 1))
	task.wait(playedDuration / combatSettings.CombatSpeedMultiplier)

	if moveCameraToken == myToken and track.IsPlaying then
		track:Stop(0.1)
		task.wait(0.15)
	end

	rig:Destroy()
end

local function runMoveCameraPhase(phaseConfig, casterInstance, targetInstance, duration, myToken)
	if not phaseConfig then return end

	if phaseConfig.Type == "AnimationObject" then
		runRigMovePhase(phaseConfig, casterInstance, duration, myToken)
	elseif phaseConfig.Type == "Procedural" then
		runProceduralMovePhase(phaseConfig, casterInstance, targetInstance, duration, myToken)
	else
		warn("[CameraManager] Unknown MoveCamera phase Type: " .. tostring(phaseConfig.Type))
	end
end

-- Main entry point.
--   moveCameraConfig: skill.CameraInfo.MoveCamera (nil is fine -- falls back to the standard
--                     static FocusOn view, the same camera behavior every move had before this)
--   casterInstance / targetInstance: what "Caster"/"Target" resolve to for phases that reference them
--   inDuration / outDuration: seconds for each phase. Leave nil on an AnimationObject phase to just
--                     let the clip's own Length (scaled by PlaybackSpeed) decide how long it runs
function CameraManager.PlayMoveCamera(moveCameraConfig, casterInstance, targetInstance, inDuration, outDuration)
	local myToken = {}
	moveCameraToken = myToken

	if not moveCameraConfig then
		-- Global default: no specialized config for this move at all
		CameraManager.FocusOn(targetInstance or casterInstance, 12.5)
		return
	end

	if moveCameraConfig.In then
		runMoveCameraPhase(moveCameraConfig.In, casterInstance, targetInstance, inDuration, myToken)
	end
	if moveCameraToken ~= myToken then return end

	if moveCameraConfig.Out then
		runMoveCameraPhase(moveCameraConfig.Out, casterInstance, targetInstance, outDuration, myToken)
	else
		-- Hybrid fallback -- see header comment
		CameraManager.FocusOn(targetInstance or casterInstance, 10, nil, nil, "Base Zoom")
		if outDuration and moveCameraToken == myToken then
			task.wait(outDuration / combatSettings.CombatSpeedMultiplier)
		end
	end
end

-- Lets combat code bail a move's camera sequence early (e.g. the target died mid-animation)
-- without waiting out the rest of a phase's duration
function CameraManager.CancelMoveCamera()
	moveCameraToken = nil
end

return CameraManager