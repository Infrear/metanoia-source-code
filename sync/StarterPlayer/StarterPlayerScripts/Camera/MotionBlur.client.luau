-- Services
local RS = game:GetService("RunService")
local blurAmt = 30
local MAX_JUMP = 0.35 -- clamps runaway spikes from hard camera cuts/teleports

local cam = workspace.CurrentCamera
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = cam

local last = cam.CFrame.LookVector
local skipNextDelta = false

local function rebind(newCam)
	cam = newCam
	if not (blur and blur.Parent) then
		blur = Instance.new("BlurEffect")
	end
	blur.Parent = cam
	last = cam.CFrame.LookVector
	skipNextDelta = true -- the camera swap itself isn't real rotation
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	rebind(workspace.CurrentCamera)
end)

local CameraBlur = {}

-- Call this from CameraService/BridgeCameraService/SceneDirector right before
-- any hard, instantaneous cam.CFrame = ... assignment (not a tween), so this
-- script doesn't mistake the jump for real rotation.
function CameraBlur.SuppressNextFrame()
	skipNextDelta = true
end

RS.Heartbeat:Connect(function()
	if not blur or blur.Parent == nil then
		blur = Instance.new("BlurEffect", cam)
	end

	local currentLook = cam.CFrame.LookVector

	if skipNextDelta then
		skipNextDelta = false
		last = currentLook
		blur.Size = 0
		return
	end

	local mag = math.min((currentLook - last).Magnitude, MAX_JUMP)
	blur.Size = mag * blurAmt
	last = currentLook
end)

return CameraBlur