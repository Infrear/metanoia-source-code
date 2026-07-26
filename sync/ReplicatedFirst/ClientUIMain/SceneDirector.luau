-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependencies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local head = char:WaitForChild("Head")
local playerGUI = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local Storage = RPS:WaitForChild("ClientStorage")
local temp = RPS:WaitForChild("ClientTemp")
local Transport = require(script.Parent:WaitForChild("Interactables").TransportService)
local ScreenHandler = require(script.Parent:WaitForChild("ScreenChangeHandler"))
local NPCM = require(script.Parent:WaitForChild("Interactables"):WaitForChild("NPCs"))
local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))
local overworldCamToggleEffectsEv = Storage.Events:WaitForChild("Standard"):WaitForChild("ToggleOverworldCamStuff")
local thirdPersonCamStuff = Storage.Events:WaitForChild("Standard"):WaitForChild("Toggle3rdPersonRegCamStuff")
local AnimationManager2 = char:WaitForChild("States"):WaitForChild("AnimationManager2")
local UITriggers = require(script:WaitForChild("UITriggers"))
local VFXFunctions = require(script:WaitForChild("VFXFunctions"))

-- Local Variables
local TWEEN_TIME = 1.5 -- Adjust speed here

local excludeParams = RaycastParams.new()
excludeParams.IgnoreWater = true
excludeParams.FilterType = Enum.RaycastFilterType.Exclude
excludeParams.RespectCanCollide = true

local inf = math.huge
local QUERY_POINT_CAST_LIMIT = 64

-- Init
local SceneDirector = {}

-- Global Variables
SceneDirector.CurrentSceneFolder = nil
SceneDirector.CurrentConfig = nil
SceneDirector.CurrentProps = nil
SceneDirector.TempProps = nil
SceneDirector.BarsOpen = false

-- Handy ones to pass down?
SceneDirector.CameraHandler = CameraHandler
SceneDirector.RelativeCameraOffset = nil

-- Variables i think
SceneDirector.PreloadedAnimations = {}
SceneDirector.PausedAnimations = {}

-- Local Functtions
local function tweenModelPos(model, info, CF, positionOnly)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPivot()

	local con1
	con1 = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		if positionOnly then
			model:PivotTo(CFrame.new(CFrameValue.Value.Position) * model:GetPivot().Rotation)
			--model:PivotTo(model:GetPivot().Rotation + CFrameValue.Value.Position) try this later!
		else
			model:PivotTo(CFrameValue.Value)
		end
	end)

	local TE = TS:Create(CFrameValue, info, {Value = CF})
	TE:Play()

	local con2
	con2 = TE.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		CFrameValue:Destroy()
	end)
	return TE
end

local function tweenModelSize(model, info, Size)
	local NumberValue = Instance.new("NumberValue")
	NumberValue.Value = model:GetScale()

	local con1
	con1 = NumberValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:ScaleTo(NumberValue.Value)
	end)

	local TE = TS:Create(NumberValue, info, {Value = Size})
	TE:Play()

	local con2
	con2 = TE.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		NumberValue:Destroy()
	end)
	return TE
end

local function getTotalTransparency(part: BasePart)
	return 1 - (1 - part.Transparency) * (1 - part.LocalTransparencyModifier)
end

local function canOcclude(part: BasePart)
	return getTotalTransparency(part) < 0.25
		and part.CanCollide
		and not part:IsA("TrussPart")
		and not part:IsDescendantOf(char)
end

-- Same idea as Popper's queryPoint: pierce through non-occluding parts
-- (transparent, non-collide, part of your own character) instead of
-- stopping on the very first thing the ray touches.
local function queryPoint(origin: Vector3, unitDir: Vector3, dist: number): number
	local excludeList = {char}
	local target = origin + unitDir * dist
	local movingOrigin = origin
	local numPierced = 0

	repeat
		excludeParams.FilterDescendantsInstances = excludeList
		local result = workspace:Raycast(movingOrigin, target - movingOrigin, excludeParams)
		if not result then
			return inf
		end

		numPierced += 1

		if numPierced >= QUERY_POINT_CAST_LIMIT or canOcclude(result.Instance) then
			return (result.Position - origin).Magnitude
		end

		table.insert(excludeList, result.Instance)
		movingOrigin = result.Position - unitDir * 1e-3
	until false
end

-- Same idea as Popper's queryViewport: sweep the 4 near-plane corners
-- toward the target, not just a single center ray, and take the closest
-- (most restrictive) hit distance.
local function queryViewport(origin: Vector3, targetCFrame: CFrame, dist: number): number
	local fov = math.rad(cam.FieldOfView)
	local viewport = cam.ViewportSize
	local ar = viewport.X / viewport.Y

	local projY = 2 * math.tan(fov / 2)
	local projX = ar * projY

	local fX = targetCFrame.RightVector
	local fY = targetCFrame.UpVector
	local fZ = (targetCFrame.Position - origin).Unit

	local nearPlaneZ = cam.NearPlaneZ

	local limit = inf
	for viewX = 0, 1 do
		local worldX = fX * ((viewX - 0.5) * projX)
		for viewY = 0, 1 do
			local worldY = fY * ((viewY - 0.5) * projY)
			local corner = origin + nearPlaneZ * (worldX + worldY)

			local pointLimit = queryPoint(corner, fZ, dist)
			if pointLimit < limit then
				limit = pointLimit
			end
		end
	end

	return limit
end

local function getOcclusionAdjustedCFrame(originPoint: Vector3, targetCFrame: CFrame): CFrame
	local direction = targetCFrame.Position - originPoint
	local dist = direction.Magnitude
	if dist <= 0.1 then
		return targetCFrame
	end

	local safeDist = queryViewport(originPoint, targetCFrame, dist)
	safeDist = math.clamp(math.min(safeDist, dist), 0.5, dist)

	-- Slide back along the SAME line, keep the SAME rotation. No normal-push.
	local safePosition = originPoint + direction.Unit * safeDist
	return CFrame.new(safePosition) * (targetCFrame - targetCFrame.Position)
end

-- Global Functions
-- Resolves a named prop or a descendant part within it.
-- propName    → the top-level prop name inside `props` (e.g. "Heli")
-- partName    → optional; a named descendant of that prop (e.g. "Cockpit")
function SceneDirector.ResolveProp(props, propName, partName)
	local prop = props:FindFirstChild(propName)
	if not prop then return nil end
	if partName then
		return prop:FindFirstChild(partName, true) -- recursive search
	end
	return prop
end

function SceneDirector.PerformStep(step)
	-- /////////// SETUP /////////// 
	if step.Action == "Setup" then
		SceneDirector.CurrentProps, SceneDirector.TempProps = Instance.new("Folder"), Instance.new("Folder")
		SceneDirector.CurrentProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_Props"
		SceneDirector.CurrentProps.Parent = workspace.SCENES
		SceneDirector.TempProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_TempProps"
		SceneDirector.TempProps.Parent = temp

		SceneDirector.CurrentSceneFolder.Props:Clone().Parent = SceneDirector.TempProps
		SceneDirector.CurrentSceneFolder.NPCs:Clone().Parent = SceneDirector.TempProps

		hrp.Anchored = (step.MC_ANCHORED == true)
		overworldCamToggleEffectsEv:Fire(false, true)
		thirdPersonCamStuff:Fire(false)
		AnimationManager2.ToggleAllOverworldAnims:Invoke(false)
		
		cam.CameraType = Enum.CameraType.Scriptable -- not sure this stuff is necessary anymore since we're using the new integrated cam system so remove for now but just keep commmented
		cam.CameraType = Enum.CameraType.Custom

		-- 1. Calculate and save the EXACT relative offset from the player's current position/rotation
		-- This uses Object Space, storing where the camera is relative to the root part
		SceneDirector.RelativeCameraOffset = hrp.CFrame:ToObjectSpace(cam.CFrame)
		
		local camRig = SceneDirector.TempProps.NPCs:FindFirstChild("CamRig")
		if camRig then

			CameraHandler.CurrentMode = "Cutscene"
			CameraHandler.SetToRig(camRig)
		end

		-- Preload animations
		for _, animationTab in pairs(SceneDirector.CurrentConfig.Animations) do
			local subject = (animationTab.Subject == char and char)
				or (SceneDirector.TempProps.Props:FindFirstChild(animationTab.Subject)
					or SceneDirector.TempProps.NPCs:FindFirstChild(animationTab.Subject))
			local animManager = subject
				and (subject:FindFirstChildOfClass("Humanoid")
					or subject:FindFirstChildOfClass("AnimationController"))
			local animator = animManager and (animManager:FindFirstChildOfClass("Animator") or Instance.new("Animator", animManager))
			animator.PreferLodEnabled = not not animationTab.SavePerformanceAnim

			if subject and (animManager or animator) then
				if not SceneDirector.PreloadedAnimations[subject] then
					SceneDirector.PreloadedAnimations[subject] = {}
				end
				for _, animationName in ipairs(animationTab.AnimationNames) do
					if SceneDirector.CurrentSceneFolder.Animations:FindFirstChild(animationName) then
						local animObj = SceneDirector.CurrentSceneFolder.Animations[animationName]
						local animTrack = (animator and animator:LoadAnimation(animObj))
							or (animManager and animManager:LoadAnimation(animObj))

						-- Poll until asset is loaded (max 2 s)
						local timeout = 0
						while animTrack.Length == 0 and timeout < 2 do
							timeout += task.wait()
						end

						SceneDirector.PreloadedAnimations[subject][animationName] = animTrack
					end
				end
			end
		end

		-- Move StarterProps into the live props folder
		for _, v in pairs(step.StarterProps) do
			local found = SceneDirector.TempProps:FindFirstChild(v.Name)
			or SceneDirector.TempProps.Props:FindFirstChild(v.Name)
				or SceneDirector.TempProps.NPCs:FindFirstChild(v.Name)
			if found then
				if v.StartingCF or found:GetAttribute("StartingCF") then
					found:PivotTo((v.StartingCF or found:GetAttribute("StartingCF")) * (SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0))
				end
				found.Parent = SceneDirector.CurrentProps
			end
		end


		if SceneDirector.CurrentSceneFolder.Locations:FindFirstChild("PlayerStartCF") then
			char:PivotTo((SceneDirector.CurrentSceneFolder.Locations.PlayerStartCF.Value) * (SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0))
		end

		task.wait()
		local old = cam.CFrame
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = SceneDirector.CurrentSceneFolder.Locations:FindFirstChild("CamStartCF")
			and (SceneDirector.CurrentSceneFolder.Locations.CamStartCF.Value) * (SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0) or old

		task.wait(0.5)
		ScreenHandler.LoadOut()

		-- /////////// ADD PROP ///////////
	elseif step.Action == "Add Props" then
		if not SceneDirector.TempProps then
			SceneDirector.CurrentProps, SceneDirector.TempProps = Instance.new("Folder"), Instance.new("Folder")
			SceneDirector.CurrentProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_Props"
			SceneDirector.CurrentProps.Parent = workspace.SCENES
			SceneDirector.TempProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_TempProps"
			SceneDirector.TempProps.Parent = temp
			SceneDirector.CurrentSceneFolder.Props:Clone().Parent = SceneDirector.TempProps
			SceneDirector.CurrentSceneFolder.NPCs:Clone().Parent = SceneDirector.TempProps
		end


		-- Move StarterProps into the live props folder
		for _, v in pairs(step.PropsToAdd) do
			local found = SceneDirector.TempProps:FindFirstChild(v.Name)
				or SceneDirector.TempProps.Props:FindFirstChild(v.Name)
				or SceneDirector.TempProps.NPCs:FindFirstChild(v.Name)
			if found then
				if v.StartingCF or found:GetAttribute("StartingCF") then
					found:PivotTo((step.CF or v.StartingCF or found:GetAttribute("StartingCF")) * ((not step.IgnoreSceneOffset) and SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0))
				end
				found.Parent = SceneDirector.CurrentProps
			end
		end


		-- /////////// ANIMATION ///////////
	elseif step.Action == "Animation" then
		for _, animationTab in ipairs(step.Targets) do
			local subject = (animationTab.Subject == char and char)
				or (SceneDirector.CurrentProps:FindFirstChild(animationTab.Subject))
			if subject and SceneDirector.PreloadedAnimations[subject]
				and SceneDirector.PreloadedAnimations[subject][animationTab.AnimationName] then

				local animTrack = SceneDirector.PreloadedAnimations[subject][animationTab.AnimationName]
				local paused = false
				local cons = {}

				if animationTab.EventSteps then
					for i, eventStep in ipairs(animationTab.EventSteps) do
						table.insert(cons, animTrack:GetMarkerReachedSignal(eventStep.SignalName):Once(function()
							for i2, step in ipairs(eventStep.Steps) do
								SceneDirector.PerformStep(step)
							end
						end))
					end
				end

				if animationTab.Pause then
					if not SceneDirector.PausedAnimations[subject] then
						SceneDirector.PausedAnimations[subject] = {}
					end

					SceneDirector.PausedAnimations[subject][animationTab.AnimationName] = animTrack
					table.insert(cons, animTrack:GetMarkerReachedSignal(animationTab.Pause.SignalName):Once(function()
						animTrack:AdjustSpeed(0)
						if animationTab.Pause.PauseAll then
							for _, subTracks in pairs(SceneDirector.PreloadedAnimations) do
								for _, track in pairs(subTracks) do
									if track ~= animTrack and track.IsPlaying then
										track:AdjustSpeed(0)
									end
								end
							end
						end
						paused = true
					end))
				end

				if animationTab.InstaPause then
					-- Play the animation, then pause on the first frame
					animTrack:Play()
					animTrack.TimePosition = 0
					animTrack:AdjustSpeed(0)
					--print("instapaused")
				elseif animationTab.Stop then
					animTrack:Stop(animationTab.StopInfo and table.unpack(animationTab.StopInfo))
					for i, v in pairs(cons) do
						v:Disconnect()
					end
				elseif animationTab.WaitForPause then
					if animationTab.Unpause then
						animTrack:AdjustSpeed(1)
						animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								--animTrack:AdjustSpeed(0)
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								local epsilon = math.max(animTrack.Length * 0.0001, 0.001) --Something small enough that it's not truly at the end, causing a reset
								animTrack.TimePosition = animTrack.Length - epsilon 
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end)
					else
						animTrack:Play(animationTab.PlayInfo and table.unpack(animationTab.PlayInfo))
						table.insert(cons, animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								local epsilon = math.max(animTrack.Length * 0.0001, 0.001) --Something small enough that it's not truly at the end, causing a reset
								animTrack.TimePosition = animTrack.Length - epsilon 
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end))
					end
					repeat task.wait() until paused
				elseif animationTab.WaitForCompletion and not animationTab.Pause then
					if animationTab.Unpause then
						animTrack:AdjustSpeed(1)
						animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								local epsilon = math.max(animTrack.Length * 0.0001, 0.001) --Something small enough that it's not truly at the end, causing a reset
								animTrack.TimePosition = animTrack.Length - epsilon 
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end)
					else
						animTrack:Play(animationTab.PlayInfo and table.unpack(animationTab.PlayInfo))
						animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								local epsilon = math.max(animTrack.Length * 0.0001, 0.001) --Something small enough that it's not truly at the end, causing a reset
								animTrack.TimePosition = animTrack.Length - epsilon 
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end)
					end
					animTrack.Stopped:Wait()
				else
					if animationTab.Unpause then
						animTrack:AdjustSpeed(1)
						animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								animTrack.TimePosition = animTrack.Length - .000001 --Something small enough that it's not truly at the end, causing a reset
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end)
					else
						animTrack:Play(animationTab.PlayInfo and table.unpack(animationTab.PlayInfo))
						table.insert(cons, animTrack.Stopped:Once(function()
							if animationTab.FreezeOnCompletion then
								animTrack:Play(0, 1, 0) --Will restart the track at the beginning, fadeIn 0 so it immediately has appropriate weight, speed 0, so that it pauses
								animTrack.TimePosition = animTrack.Length - .000001 --Something small enough that it's not truly at the end, causing a reset
							end
							for i, v in pairs(cons) do
								v:Disconnect()
							end
						end))
					end
				end
			end
		end

		-- /////////// DIALOGUE ///////////
	elseif step.Action == "Dialogue" then
		if SceneDirector.CurrentSceneFolder.Dialogues:FindFirstChild(step.Dialogue) then
			NPCM.runNPC(
				step.Speaker and SceneDirector.CurrentProps:FindFirstChild(step.Speaker) or nil,
				SceneDirector.CurrentSceneFolder.Dialogues:FindFirstChild(step.Dialogue),
				step.DisplayName
			)
		end

		-- /////////// FUNCTION ///////////
	elseif step.Action == "Function" then
		if step.Async then
			coroutine.wrap(step.Function)(SceneDirector.CurrentProps)
		else
			step.Function(SceneDirector.CurrentProps)
		end

		-- /////////// CAMERA ///////////
	elseif step.Action == "Camera" then
		-- move the cam to SceneDirector.CurrentSceneFolder.Locations[step.Target] or play camera animation
		if step.Properties then
			for i, v in pairs(step.Properties) do
				workspace.CurrentCamera[i] = v
			end
		end

		-- /////////// VFX ///////////
	elseif step.Action == "VFX" then
		if VFXFunctions[step.VFXFunction or "SimpleVFX"] then
			if step.Async then
				coroutine.wrap(VFXFunctions[step.VFXFunction or "SimpleVFX"])(step, SceneDirector)
			else
				VFXFunctions[step.VFXFunction or "SimpleVFX"](step, SceneDirector)
			end
		end
		--]]

		-- /////////// MOVE ///////////
		--[[
			Moves or tweens a prop (or a specific part within it).
			Required fields:
			  PropName   – prop inside `props`
			  TargetCF   – destination CFrame (standard move)
			              OR ignored when UsePivot = true (see below)
			Optional:
			  PartName   – named descendant to move instead of the whole prop
			  Instant    – (default false) skip animation, move immediately
			  Delay      – seconds to wait before the move begins
			  Duration   – animation time in seconds (default 1)
			  EasingStyle / EasingDirection – Enum values (default Quad/Out)
			  Async      – (default false) if true, don't block the timeline
 
			UsePivot mode — rotate around a part's own pivot point:
			  UsePivot   = true
			  Axis       = "X" | "Y" | "Z"  (default "Y")
			  AngleDeg   = target angle in degrees (e.g. 90 to open a hatch)
			  Speed      = degrees per second (default 90); used when Duration
			               is not set. If Duration IS set, speed is derived from it.
			  TargetCF is ignored in this mode.
		--]]
	elseif step.Action == "Move" then
		local async = (step.Async == true)

		-- Easing alpha given normalised t ∈ [0,1]
		local function applyEasing(t, style, direction)
			local function easeIn(t2)
				if style == Enum.EasingStyle.Linear then return t2
				elseif style == Enum.EasingStyle.Sine  then return 1 - math.cos(t2 * math.pi / 2)
				elseif style == Enum.EasingStyle.Quad  then return t2 * t2
				elseif style == Enum.EasingStyle.Cubic then return t2 * t2 * t2
				elseif style == Enum.EasingStyle.Quart then return t2 ^ 4
				elseif style == Enum.EasingStyle.Quint then return t2 ^ 5
				else return t2 * t2 end
			end
			local function easeOut(t2) return 1 - easeIn(1 - t2) end
			if direction == Enum.EasingDirection.In then return easeIn(t)
			elseif direction == Enum.EasingDirection.Out then return easeOut(t)
			else return t < 0.5 and easeIn(t * 2) / 2 or 0.5 + easeOut(t * 2 - 1) / 2
			end
		end

		local target = nil
		local function runMove(stepInfo)
			if stepInfo.Delay and stepInfo.Delay > 0 then
				task.wait(stepInfo.Delay)
			end
			if (step.PropName ~= char) and ((stepInfo.PropName) or ((not target) and (step.PropName))) then
				target = SceneDirector.ResolveProp(SceneDirector.CurrentProps, stepInfo.PropName or step.PropName, stepInfo.PartName or step.PartName)
			elseif step.PropName == char then
				target = step.PropName
			end
			if not target then
				warn("SceneDirector Move: prop '" .. tostring(stepInfo.PropName or step.PropName) .. "' not found")
				return
			end

			local targetCF = stepInfo.isOffset and (target:GetPivot() * stepInfo.TargetCF) or stepInfo.TargetCF

			-- ── UsePivot mode: angle accumulator around the pivot ──────
			-- Mirrors the pattern:
			--   local rotated = part:GetPivot() * CFrame.Angles(math.rad(angle), 0, 0)
			--   part:PivotTo(rotated)
			-- The pivot's WORLD POSITION stays locked; only orientation changes.
			if stepInfo.UsePivot then
				local axis     = stepInfo.Axis or "Y"
				local maxAngle = stepInfo.AngleDeg or 90
				local speed    = stepInfo.Duration
					and (maxAngle / stepInfo.Duration) -- derive speed from duration
					or  (stepInfo.Speed or 90)         -- else use explicit speed

				local style     = stepInfo.EasingStyle     or Enum.EasingStyle.Quad
				local direction = stepInfo.EasingDirection or Enum.EasingDirection.Out
				local totalTime = maxAngle / speed

				-- Capture the pivot base ONCE — all frames rotate from this origin
				local baseCF    = target:GetPivot()
				local elapsed   = 0

				if stepInfo.Instant then
					local function makeAngleCF(deg)
						local r = math.rad(deg)
						if axis == "X" then return CFrame.Angles(r, 0, 0)
						elseif axis == "Z" then return CFrame.Angles(0, 0, r)
						else return CFrame.Angles(0, r, 0) end
					end
					target:PivotTo(baseCF * makeAngleCF(maxAngle))
					if stepInfo.HideOnFinish then
						SceneDirector.PerformStep(
							{ 
								Action = "Hide Props",
								PropsToHide = {target.Name}, 
							}
						)
					end
					return
				end

				local RS = game:GetService("RunService")
				local done = false
				local conn
				conn = RS.Heartbeat:Connect(function(dt)
					elapsed += dt
					local t     = math.clamp(elapsed / totalTime, 0, 1)
					local alpha = applyEasing(t, style, direction)
					local deg   = maxAngle * alpha

					local angleCF
					if axis == "X" then angleCF = CFrame.Angles(math.rad(deg), 0, 0)
					elseif axis == "Z" then angleCF = CFrame.Angles(0, 0, math.rad(deg))
					else angleCF = CFrame.Angles(0, math.rad(deg), 0) end

					target:PivotTo(baseCF * angleCF)

					if t >= 1 then
						conn:Disconnect()
						done = true
					end
				end)
				
				if not async then
					repeat task.wait() until done
				end

				-- ── Instant move (non-pivot) ───────────────────────────────
			elseif stepInfo.Instant then
				if target:IsA("Model") then
					target:PivotTo((targetCF) * (((((not stepInfo.IgnoreSceneOffset) and (not stepInfo.isOffset)) or ((not step.IgnoreSceneOffset) and ((not step.isOffset) and (not stepInfo.isOffset)))) and SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0)))
				else
					target.CFrame = (targetCF) * (((((not stepInfo.IgnoreSceneOffset) and (not stepInfo.isOffset)) or ((not step.IgnoreSceneOffset) and ((not step.isOffset) and (not stepInfo.isOffset)))) and SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0))
				end

				-- ── TweenService: Model with PrimaryPart ──────────────────
			elseif target:IsA("Model") then
				local duration  = stepInfo.Duration       or 1
				local style     = stepInfo.EasingStyle     or Enum.EasingStyle.Quad
				local direction = stepInfo.EasingDirection or Enum.EasingDirection.Out
				local primary   = target.PrimaryPart
				--warn("SceneDirector Move: model '" .. target.Name .. "' has no PrimaryPart")
				local TE = tweenModelPos(target, TweenInfo.new(duration, style, direction), (targetCF) * (((((not stepInfo.IgnoreSceneOffset) and (not stepInfo.isOffset)) or ((not step.IgnoreSceneOffset) and ((not step.isOffset) and (not stepInfo.isOffset)))) and SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0)), stepInfo.PositionOnly)

				if not async then TE.Completed:Wait() end
				
				-- ── TweenService: plain BasePart ──────────────────────────
			else
				local duration  = stepInfo.Duration       or 1
				local style     = stepInfo.EasingStyle     or Enum.EasingStyle.Quad
				local direction = stepInfo.EasingDirection or Enum.EasingDirection.Out
				local TE = TS:Create(target, TweenInfo.new(duration, style, direction), { CFrame = (targetCF) * (((((not stepInfo.IgnoreSceneOffset) and (not stepInfo.isOffset)) or ((not step.IgnoreSceneOffset) and ((not step.isOffset) and (not stepInfo.isOffset)))) and SceneDirector.CurrentConfig and SceneDirector.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0))})
				TE:Play()
				if not async then TE.Completed:Wait() end
			end

			if stepInfo.HideOnFinish then
				SceneDirector.PerformStep(
					{ 
						Action = "Hide Props",
						PropsToHide = {target.Name}, 
					}
				)
			end
		end

		if not step.Moves then
			if async then
				coroutine.wrap(runMove)(step)
			else
				runMove(step)
			end
		else
			if async then
				coroutine.wrap(function()
					for i, v in pairs(step.Moves) do 
						if v.Async then
							coroutine.wrap(runMove)(v)
						else
							runMove(v)
						end 
					end
				end)()
			else
				for i, v in pairs(step.Moves) do 
					if v.Async then
						coroutine.wrap(runMove)(v)
					else
						runMove(v)
					end 
				end
			end
		end
		
		-- /////////// SPIN ///////////
		--[[
			Continuously spins a part or model until the scene ends. OR spins model to target angle
			Required fields:
			  PropName   – top-level prop in `props`
			Optional:
			  PartName   – named descendant BasePart to spin (CFrame mode)
			  ModelName  – named descendant Model to spin via PivotTo
			  UsePivot   – (bool) rotate the prop itself around its pivot;
			               use this when you have no PartName/ModelName and
			               just want the whole prop to spin at its pivot point
			  Axis       – "X" | "Y" | "Z"  (default "Y")
			  Speed      – degrees per second (default 720, or auto-calculated from TargetAngle ÷ Duration if both are given and Speed is omitted)
			  Async      – should almost always be true (default true)
			  
			  OR
			  
			  Duration
			  TargetAngle
 
			Priority: ModelName > PartName > UsePivot > prop root pivot
		--]]
	elseif step.Action == "Spin" then
		local axis  = step.Axis  or "Y"
		local speed = step.Speed or (
			(step.TargetAngle ~= nil and step.Duration ~= nil)
				and (step.TargetAngle / step.Duration)
				or 720
		)
		local async = (step.Async ~= false)

		local function runSpin()
			local prop = step.PropName == char or SceneDirector.CurrentProps:FindFirstChild(step.PropName)
			if not prop then
				warn("SceneDirector Spin: prop '" .. tostring(step.PropName) .. "' not found")
				return
			end

			local target     = nil
			local pivotModel = nil

			if step.ModelName then
				pivotModel = prop:FindFirstChild(step.ModelName, true)
				if not pivotModel then
					warn("SceneDirector Spin: ModelName '" .. step.ModelName .. "' not found inside '" .. step.PropName .. "'")
					return
				end
			elseif step.PartName then
				target = prop:FindFirstChild(step.PartName, true)
				if not target or not target:IsA("BasePart") then
					warn("SceneDirector Spin: PartName '" .. step.PartName .. "' not found or not a BasePart")
					return
				end
			else
				pivotModel = prop
			end

			local function angleDelta(rad)
				if axis == "X" then return CFrame.Angles(rad, 0, 0)
				elseif axis == "Z" then return CFrame.Angles(0, 0, rad)
				else return CFrame.Angles(0, rad, 0) end
			end

			local function applyDelta(rad)
				if pivotModel or step.UsePivot then
					local m = pivotModel or target
					m:PivotTo(m:GetPivot() * angleDelta(rad))
				else
					target.CFrame = target.CFrame * angleDelta(rad)
				end
			end

			if step.TargetAngle ~= nil or step.Duration ~= nil then
				-- ── Finite spin ──────────────────────────────────────────────
				-- TargetAngle: spin until we've accumulated that many degrees
				--   (can exceed 360 for multiple rotations, e.g. 540 = 1.5 turns)
				-- Duration:    spin for that many seconds at `speed` deg/s
				--   Both together → whichever limit is hit first stops the spin
				local totalDeg = step.TargetAngle  -- nil = no angle cap
				local maxTime  = step.Duration      -- nil = no time cap

				local accumulated = 0
				local elapsed     = 0

				while plr:GetAttribute("InCutscene") do
					local dt  = task.wait()
					elapsed   = elapsed + dt

					-- How many degrees can we move this frame?
					local moveDeg = speed * dt

					if totalDeg ~= nil then
						local remaining = totalDeg - accumulated
						if moveDeg >= remaining then
							-- Last frame: snap exactly to target and stop
							applyDelta(math.rad(remaining))
							break
						end
					end

					if maxTime ~= nil and elapsed >= maxTime then
						-- Time ran out mid-frame: apply partial step then stop
						local overshot = elapsed - maxTime
						local clampedDeg = moveDeg - (speed * overshot)
						applyDelta(math.rad(math.max(clampedDeg, 0)))
						break
					end

					applyDelta(math.rad(moveDeg))
					accumulated = accumulated + moveDeg
				end
			else
				-- ── Continuous spin (original behaviour) ─────────────────────
				while plr:GetAttribute("InCutscene") do
					local dt  = task.wait()
					applyDelta(math.rad(speed) * dt)
				end
			end
		end

		if async then
			coroutine.wrap(runSpin)()
		else
			runSpin()
		end
	elseif step.Action == "UI_Trigger" then
		if UITriggers[step.Name] then
			if step.Async and ((not step.Data) or (not step.Data.WaitForInput)) then
				coroutine.wrap(UITriggers[step.Name])(step)
			else
				UITriggers[step.Name](step)

				--if step.Name == "ScrollingCredits" then
				if step.Data and step.Data.WaitForInput then -- also temporary
					task.wait(3)
				end
			end
		--end
		
		-- [[TEMPORARY UNTIL UI STUFF IS IMPLEMENTED
		elseif not step.Async or (step.Data and step.Data.WaitForInput) then
			--if step.Name == "ScrollingCredits" then
			if step.Data and step.Data.WaitForInput then
				task.wait(3)
			end
		end
		--]]
		
	elseif step.Action == "Hide Props" then
		if not SceneDirector.TempProps then
			SceneDirector.CurrentProps, SceneDirector.TempProps = Instance.new("Folder"), Instance.new("Folder")
			SceneDirector.CurrentProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_Props"
			SceneDirector.CurrentProps.Parent = workspace.SCENES
			SceneDirector.TempProps.Name = SceneDirector.CurrentSceneFolder.Name .. "_TempProps"
			SceneDirector.TempProps.Parent = temp
			SceneDirector.CurrentSceneFolder.Props:Clone().Parent = SceneDirector.TempProps
			SceneDirector.CurrentSceneFolder.NPCs:Clone().Parent = SceneDirector.TempProps
		end
		
		for i, v in pairs(step.PropsToHide) do
			local found = SceneDirector.CurrentProps:FindFirstChild(v)
			if found then
				found.Parent = SceneDirector.TempProps
			end
		end
	end
end

function SceneDirector.Play(sceneFolder, subsequentScene, preScene)
	--NPCM.setup()
	if not sceneFolder then return warn("No scene folder provided.") end
	plr:SetAttribute("InCutscene", true)
	SceneDirector.CurrentSceneFolder = sceneFolder
	SceneDirector.CurrentConfig = require(SceneDirector.CurrentSceneFolder.Config)
	SceneDirector.CurrentProps = nil
	SceneDirector.TempProps = nil

	table.clear(SceneDirector.PreloadedAnimations)
	table.clear(SceneDirector.PausedAnimations)

	-- 1. Initial Fade
	if not preScene then
		ScreenHandler.LoadIn("Scrub", true)
	end
	task.wait(1)

	-- 2. Iterate through the Timeline
	local testing = false
	local testIntervals = {{10, 13}, {15, "end"}}
	local essentialStart = 1
	local essentialEnd = 5
	
	if not testing then
		for _, step in ipairs(SceneDirector.CurrentConfig.Timeline) do
			SceneDirector.PerformStep(step)
		end
	else
		for i = essentialStart, essentialEnd do
			SceneDirector.PerformStep(SceneDirector.CurrentConfig.Timeline[i])
		end
		
		for i2, testIntervals in ipairs(testIntervals) do
			if not testIntervals[2] then
				SceneDirector.PerformStep(SceneDirector.CurrentConfig.Timeline[testIntervals[1]])
			else
				local fin = testIntervals[2]
				if fin == "end" then
					fin = #SceneDirector.CurrentConfig.Timeline
				end

				for i = testIntervals[1], fin do
					SceneDirector.PerformStep(SceneDirector.CurrentConfig.Timeline[i])
				end
			end
		end
	end


	if not SceneDirector.CurrentConfig.Settings.NoExitTransition then
		ScreenHandler.LoadIn("Scrub", true)
		task.wait(1)
	end
	if SceneDirector.CurrentConfig.CleanupFunction then
		SceneDirector.CurrentConfig.CleanupFunction(SceneDirector)
	end

	if SceneDirector.CurrentConfig.Settings.TweenCamBack then
		hrp.Anchored = false
		AnimationManager2.ToggleAllOverworldAnims:Invoke(true)
		task.wait(1.5)

		cam.CameraType = Enum.CameraType.Scriptable
		local idealTargetCFrame = hrp.CFrame * SceneDirector.RelativeCameraOffset
		local safeTargetCFrame = getOcclusionAdjustedCFrame(head.Position, idealTargetCFrame)

		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tweenBack = TS:Create(cam, tweenInfo, {CFrame = safeTargetCFrame})
		tweenBack:Play()
		tweenBack.Completed:Wait()

		cam:SetAttribute("CameraResumeBlend", true)
		cam:SetAttribute("CameraResumeBlendDuration", 0.4)
		
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum

		-- only NOW hand control back to mouselook
		overworldCamToggleEffectsEv:Fire(true, true)
		thirdPersonCamStuff:Fire(true)
		if SceneDirector.CurrentConfig.PostTweenCamBackFunction then
			SceneDirector.CurrentConfig.PostTweenCamBackFunction(SceneDirector)
		end
	end
	
	for i, v in pairs(SceneDirector.PreloadedAnimations) do
		for i2, v2 in pairs(v) do
			if v2.IsPlaying then
				v2:Stop()
			end
		end
	end
	for i, v in pairs(SceneDirector.PausedAnimations) do
		for i2, v2 in pairs(v) do
			if v2.IsPlaying then
				v2:Stop()
			end
		end
	end
	SceneDirector.CurrentProps:Destroy()
	SceneDirector.TempProps:Destroy()
	--CameraHandler.Stop(true)
	if (not subsequentScene) and (not SceneDirector.CurrentConfig.Settings.TweenCamBack) then
		overworldCamToggleEffectsEv:Fire(true, true)
		thirdPersonCamStuff:Fire(true)
		AnimationManager2.ToggleAllOverworldAnims:Invoke(true)
	end
	task.wait(1)
	if (not subsequentScene) and (not SceneDirector.CurrentConfig.Settings.NoExitTransition) then
		ScreenHandler.LoadOut()
		plr:SetAttribute("InCutscene", false)
	end
	if SceneDirector.CurrentConfig.Settings.CloseBarsOnCompletion and UITriggers.BarsOpen then
		SceneDirector.PerformStep(
			{
				Action = "UI_Trigger",
				Name = "CienematicBars",
				--Delay = 1.5,
				Open = false,
				Async = true,
			}
		)
	end
end

return SceneDirector