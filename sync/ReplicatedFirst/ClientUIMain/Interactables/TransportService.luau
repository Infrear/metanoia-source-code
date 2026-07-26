-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local transportRem = Storage:WaitForChild("Events"):WaitForChild("Standard"):WaitForChild("TransportBindable")
local cameraService = require(script.Parent:WaitForChild("CameraService"))
local TELEPORTS = workspace:WaitForChild("TELEPORTS")
local CAMERAS = workspace:WaitForChild("CAMERAS")

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- TransportService
local TransportService = {}

local function resolveCamera(destinationPart, destinationPartName)
	return destinationPart:GetAttribute("Camera") and CAMERAS:FindFirstChild(destinationPart:GetAttribute("Camera"))
		or CAMERAS:FindFirstChild(destinationPartName)
end

local function resolveShakeConfig(destinationPart, override)
	if override then return override end
	if destinationPart:GetAttribute("ShakeEnabled") then
		return {
			Enabled = true,
			Intensity = destinationPart:GetAttribute("ShakeIntensity"),
			Frequency = destinationPart:GetAttribute("ShakeFrequency"),
		}
	end
	return nil
end

-- opts = { SkipFade = bool, Shake = { Enabled, Intensity, Frequency } }
function TransportService.Teleport(destinationPartName, opts) --> in the future handle this stuff on the server with anticheats and stuff
	opts = opts or {}
	local destinationPart = TELEPORTS:FindFirstChild(destinationPartName)
	if not destinationPart then return end

	-- 1. Fade Out
	if not opts.SkipFade then
		transportRem:Fire("In", "Scrub")
		task.wait(1)
	end

	-- 2. Move Player
	if destinationPart and char then
		plr.Character:PivotTo(destinationPart.CFrame + Vector3.new(0, 3, 0))
	end

	local found = resolveCamera(destinationPart, destinationPartName)
	local camDuration = destinationPart:GetAttribute("CameraTime")

	if found then
		if cam.CameraType == Enum.CameraType.Custom then
			cameraService.RelativeCameraOffset = hrp.CFrame:ToObjectSpace(cam.CFrame)
		end
		cameraService.EnablePersonaCam(found, camDuration, {
			Shake = resolveShakeConfig(destinationPart, opts.Shake)
		})
	else
		cameraService.ToggleFreeCam(true)
		-- do the tween to camera here probably im guessing? but its already being done so make sure that we actually did grab position NEW SCRIPTER NOTE
	end

	task.wait()

	-- 3. Fade In
	if not opts.SkipFade then
		transportRem:Fire("Out")
	end
end

--------------------------------------------------------------------------------
-- Zone-based entry/exit (touch triggers) — for cases like walking onto a
-- bridge, where the player moves themselves and only the camera changes.
-- No PivotTo. No fade unless opts.UseFade is explicitly set.
--------------------------------------------------------------------------------

-- opts = { UseFade = bool, Shake = { Enabled, Intensity, Frequency } }
function TransportService.EnterZone(destinationPartName, opts)
	opts = opts or {}
	local destinationPart = TELEPORTS:FindFirstChild(destinationPartName)
	if not destinationPart then return end

	if opts.UseFade then
		transportRem:Fire("In", "Scrub")
		task.wait(1)
	end

	local found = resolveCamera(destinationPart, destinationPartName)
	if not found then return end

	local camDuration = destinationPart:GetAttribute("CameraTime") -- usually nil -> continuous hold, exited manually

	if cam.CameraType == Enum.CameraType.Custom then
		--print("setting og")
		--print(hrp.CFrame:ToObjectSpace(cam.CFrame))
		cameraService.RelativeCameraOffset = hrp.CFrame:ToObjectSpace(cam.CFrame)
	end
	cameraService.ToggleFreeCam(false)
	--task.wait()

	cameraService.EnablePersonaCam(found, camDuration, {
		Shake = resolveShakeConfig(destinationPart, opts.Shake)
	})

	if opts.UseFade then
		transportRem:Fire("Out")
	end
end

-- opts = { UseFade = bool }
function TransportService.ExitZone(destinationPartName, opts)
	local destinationPart = TELEPORTS:FindFirstChild(destinationPartName)
	if not destinationPart then return end

	local found = resolveCamera(destinationPart, destinationPartName)
	if not found then return end
	
	opts = opts or {}

	if opts.UseFade then
		transportRem:Fire("In", "Scrub")
		task.wait(1)
	end

	
	cameraService.ReturnFromPersonaCam(function()
		if opts.UseFade then
			transportRem:Fire("Out")
		end
	end, found)
end

return TransportService