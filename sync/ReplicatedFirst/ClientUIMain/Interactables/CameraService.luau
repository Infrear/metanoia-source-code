-- Services
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local PLRS = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RPS = game:GetService("ReplicatedStorage")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local overworldCamToggleEffectsEv = Storage.Events:WaitForChild("Standard"):WaitForChild("ToggleOverworldCamStuff")
local harsherOverworldCamToggleEffectsEv = Storage.Events:WaitForChild("Standard"):WaitForChild("ToggleOverworldHarsherEffects")

local plr = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local head = char:WaitForChild("Head")
local cam = workspace.CurrentCamera

-- Initialization
local CameraService = {}

-- Global Variables
CameraService.RelativeCameraOffset = nil -- hrp.CFrame:ToObjectSpace(cam.CFrame)

-- Local Variables
local camConnection = nil     -- persona-cam hold loop (continuous mode)
local returnConnection = nil  -- occlusion-based tween-back loop
local shakeConnection = nil
local isFreeCam = false
local TE = nil

-- Constants (all obsolete as of right now)
local LERP_SPEED = 0.01 -- How "tight"/delayed the parallax follow is
local MAX_OFFSET = 5    -- How much the camera "shifts" with the player
local RETURN_LERP_SPEED = 0.015
local RETURN_SNAP_DIST = 0.05
local MAX_RETURN_DURATION = 2.25 -- 1.5 seconds maximum for the camera to return

local TIS = {
	Into = TweenInfo.new(
		1.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
}

--------------------------------------------------------------------------------
-- Occlusion (Popper-style, same system from SceneDirector)
--------------------------------------------------------------------------------
local excludeParams = RaycastParams.new()
excludeParams.IgnoreWater = true
excludeParams.FilterType = Enum.RaycastFilterType.Exclude
excludeParams.RespectCanCollide = true

local inf = math.huge
local QUERY_POINT_CAST_LIMIT = 64

local function getTotalTransparency(part: BasePart)
	return 1 - (1 - part.Transparency) * (1 - part.LocalTransparencyModifier)
end

local function canOcclude(part: BasePart)
	return getTotalTransparency(part) < 0.25
		and part.CanCollide
		and not part:IsA("TrussPart")
		and not part:IsDescendantOf(char)
end

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
	local safePosition = originPoint + direction.Unit * safeDist
	return CFrame.new(safePosition) * (targetCFrame - targetCFrame.Position)
end

--------------------------------------------------------------------------------
-- Wind / shake — additive, doesn't replace the base CFrame calc
--------------------------------------------------------------------------------
local function stopShake()
	if shakeConnection then
		shakeConnection:Disconnect()
		shakeConnection = nil
	end
end

local function startShake(getBaseCFrame, shakeConfig)
	stopShake()
	if not shakeConfig or not shakeConfig.Enabled then return end

	local intensity = shakeConfig.Intensity or 0.4
	local frequency = shakeConfig.Frequency or 1.5
	local seed = math.random() * 1000
	local startTime = os.clock()

	shakeConnection = RS.RenderStepped:Connect(function()
		local t = (os.clock() - startTime) * frequency
		local nx = math.noise(t, seed)
		local ny = math.noise(t, seed + 100)
		local nz = math.noise(t, seed + 200)

		local shakeOffset = Vector3.new(nx, ny * 0.6, nz) * intensity
		local shakeRot = CFrame.Angles(
			math.rad(ny * intensity * 1.5),
			math.rad(nx * intensity * 1.5),
			math.rad(nz * intensity * 0.5)
		)

		cam.CFrame = getBaseCFrame() * CFrame.new(shakeOffset) * shakeRot
	end)
end

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------
local function stopHold(anchorPart)
	if TE and TE[1] == anchorPart and TE[2] and TE[2].PlaybackState == Enum.PlaybackState.Playing then
		TE[2]:Cancel()
	end
	if camConnection then
		camConnection:Disconnect()
		camConnection = nil
	end
end

local function stopReturn()
	if returnConnection then
		returnConnection:Disconnect()
		returnConnection = nil
	end
end

-- Global Functions
function CameraService.ToggleFreeCam(state)
	isFreeCam = state
	--overworldCamToggleEffectsEv:Fire(state, false)
	harsherOverworldCamToggleEffectsEv:Fire(state)
	if isFreeCam then
		stopHold()
		stopReturn()
		stopShake()
		cam.CameraType = Enum.CameraType.Custom
	end
end

-- Cancels an in-progress return tween — e.g. player re-enters a touch zone
-- while the camera is still easing back to normal.
function CameraService.CancelReturn()
	stopReturn()
	stopShake()
end

function CameraService.IsReturning(): boolean
	return returnConnection ~= nil
end

-- config = { Shake = { Enabled, Intensity, Frequency } }
function CameraService.EnablePersonaCam(anchorPart, duration, config)
	if isFreeCam then return end
	config = config or {}

	-- If re-triggered while a return-tween was mid-flight, cancel it instead
	-- of letting it fight the new shot.
	stopReturn()
	stopHold()

	if not duration or duration <= 0 then
		-- ── Transition Setup ──────────────────────────────────────────
		local startCF = cam.CFrame
		local startTime = tick()
		local blendDuration = 1.35 -- Set this to match your old TIS.Into duration
		local easeStyle = Enum.EasingStyle.Cubic
		local easeDirection = Enum.EasingDirection.Out
		-- ──────────────────────────────────────────────────────────────

		local oldcf = nil
		local function baseCFrame()
			-- 1. Calculate the ideal target (Persona Logic)
			local relativePos = (char:GetPivot().Position - anchorPart.Position).Unit * MAX_OFFSET
			local targetCFrame = CFrame.lookAt(anchorPart.Position + (relativePos * 0.2), char:GetPivot().Position)

			local targetWithLerp
			if oldcf then
				targetWithLerp = oldcf:Lerp(targetCFrame, LERP_SPEED)
			else
				targetWithLerp = targetCFrame
			end
			oldcf = targetWithLerp

			-- 2. Apply the transition blend if we are still entering the shot
			local alpha = math.clamp((tick() - startTime) / blendDuration, 0, 1)
			
			if alpha < 1 then
				local easedAlpha = TS:GetValue(alpha, easeStyle, easeDirection)
				return startCF:Lerp(targetWithLerp, easedAlpha)
			else
				-- Once alpha hits 1, just return the standard parallax CFrame
				return targetWithLerp
			end
		end

		if config.Shake and config.Shake.Enabled then
			-- Because the blend is built into baseCFrame, the shake wrapper
			-- will naturally include the smooth ease-in!
			startShake(baseCFrame, config.Shake)
		else
			cam.CameraType = Enum.CameraType.Scriptable
			
			-- Simply bind it. No need to wait for a Tween to finish anymore.
			camConnection = RS.RenderStepped:Connect(function()
				cam.CFrame = baseCFrame()
			end)
		end
	else
		cam.CameraType = Enum.CameraType.Scriptable
		local relativePos = (char:GetPivot().Position - anchorPart.Position).Unit * MAX_OFFSET
		local targetCFrame = CFrame.lookAt(anchorPart.Position + (relativePos * 0.2), char:GetPivot().Position)
		cam.CFrame = targetCFrame

		if config.Shake and config.Shake.Enabled then
			startShake(function() return targetCFrame end, config.Shake)
		end

		coroutine.wrap(function()
			task.wait(duration)
			CameraService.ReturnFromPersonaCam(anchorPart)
		end)()
	end
end

local function forceCameraZoomDistance(distance: number)
	local originalMin, originalMax = plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance
	plr.CameraMinZoomDistance = distance
	plr.CameraMaxZoomDistance = distance
	task.wait() -- let BaseCamera's PropertyChangedSignal handler actually clamp currentSubjectDistance
	plr.CameraMinZoomDistance = originalMin
	plr.CameraMaxZoomDistance = originalMax
end
-- Tweens the camera back to the saved player-relative offset using the
-- shared occlusion system, recomputed every frame since the character may
-- still be moving. Holds its connection in `returnConnection` so callers
-- (e.g. a touch zone) can cancel/restart it if the player re-enters mid-tween.
function CameraService.ReturnFromPersonaCam(onComplete, anchorPart)
	stopShake()
	stopHold()
	stopReturn()

	if not CameraService.RelativeCameraOffset then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		isFreeCam = true
		harsherOverworldCamToggleEffectsEv:Fire(true)
		return
	end

	-- Record the exact time the return sequence started
	--local startTime = os.clock()

	--returnConnection = RS.RenderStepped:Connect(function()
	--	cam.CameraType = Enum.CameraType.Scriptable
	--	local idealTargetCFrame = hrp.CFrame * CameraService.RelativeCameraOffset
	--	local safeTargetCFrame = getOcclusionAdjustedCFrame(head.Position, idealTargetCFrame)

	--	-- 1. Calculate linear progress [0.0 to 1.0]
	--	local timeElapsed = os.clock() - startTime
	--	local t = math.clamp(timeElapsed / MAX_RETURN_DURATION, 0, 1)

	--	-- 2. Apply Quadratic Ease-Out formula
	--	-- Manual Math: 1 - (1 - t)^2
	--	local easedT = 1 - (1 - t) ^ 2

	--	-- Roblox Alternative (identical result):
	--	-- local easedT = TweenService:GetValue(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	--	-- 3. Ramp up the lerp speed according to the eased factor
	--	local dynamicLerpSpeed = RETURN_LERP_SPEED + (1 - RETURN_LERP_SPEED) * easedT

	--	cam.CFrame = cam.CFrame:Lerp(safeTargetCFrame, dynamicLerpSpeed)

	--	local closeEnough = (cam.CFrame.Position - safeTargetCFrame.Position).Magnitude < RETURN_SNAP_DIST

		-- 4. Complete if close enough or reached 100% time
		--if closeEnough or t >= 1 then
			stopReturn()
			cam:SetAttribute("CameraResumeBlend", true)
			cam:SetAttribute("CameraResumeBlendDuration", 0.6)
			cam:SetAttribute("CameraResumeBlendEaseStyle", "Exponential")
			cam:SetAttribute("CameraResumeBlendEaseDirection", "Out")
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum
			harsherOverworldCamToggleEffectsEv:Fire(true)
			isFreeCam = true

			if onComplete then onComplete() end
		--end
	--end)
end

return CameraService