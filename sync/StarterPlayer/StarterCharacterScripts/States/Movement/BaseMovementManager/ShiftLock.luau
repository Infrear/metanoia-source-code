-- Services
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

-- Dependancies
local plr = game.Players.LocalPlayer
local char = plr.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local mouse = plr:GetMouse()
local Climb = require(script.Parent:WaitForChild("Climb"))
--local Fall = require(script.Parent:WaitForChild("Fall"))

-- Local Variables
local TE = nil

-- Initialization
local ShiftLock = {}

-- Global Variables
ShiftLock.Locked = false
ShiftLock.PreDeactivationLock = nil
ShiftLock.Toggled = Instance.new("BindableEvent")
ShiftLock.Inactive = false

-- Constants
local defaultOffset = Vector3.new(0.8,0.5,0)
local shiftedOffset = defaultOffset + Vector3.new(2.3, 0, 0)
local TI = TweenInfo.new(
	0.85,
	Enum.EasingStyle.Back, -- ELASTIC or Back
	Enum.EasingDirection.Out
)

hum.CameraOffset = defaultOffset
local tween

-- Global Functions
function ShiftLock.Lock()
	--print("locking")
	--ShiftLock.Locked = RS.RenderStepped:Connect(function()
	--local RootPos, MousePos = hrp.Position, mouse.Hit.Position
	--hrp.CFrame = CFrame.new(RootPos, Vector3.new(MousePos.X, RootPos.Y, MousePos.Z))
	--end) 

	ShiftLock.Locked = true
	--hum.CameraOffset = shiftedOffset -- I assume this is about the right camera offset.
	hum.AutoRotate = false --Disable the automatic rotation since we are the ones setting it.

	if TE and TE.PlaybackState == Enum.PlaybackState.Playing then
		TE:Cancel()
	end
	TE = TS:Create(hum, TI, {CameraOffset = shiftedOffset}) -- I assume this is about the right camera offset.
	TE:Play() 

	local oldClimbStatus = Climb.climbing
	RS:BindToRenderStep("ShiftLock", Enum.RenderPriority.Character.Value, function()
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter --Set the mouse to center every frame.
		local newClimbStatus = Climb.climbing or hum:GetAttribute("Ragdolled") or hum.Health <= 0
		if not newClimbStatus then
			if oldClimbStatus ~= newClimbStatus then 
				ShiftLock.Locked = true
				if hum.CameraOffset ~= shiftedOffset and (not (TE and TE.PlaybackState ~= Enum.PlaybackState.Playing)) then
					TE = TS:Create(hum, TI, {CameraOffset = shiftedOffset}) -- I assume this is about the right camera offset.
					TE:Play() 
				end
				hum.AutoRotate = false --Disable the automatic rotation since we are the ones setting it.
			end
			local _, y = workspace.CurrentCamera.CFrame.Rotation:ToEulerAnglesYXZ() --Get the angles of the camera
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0,y,0) --Set the root part to the camera's rotation
		else
			if oldClimbStatus ~= newClimbStatus then 
				if hum.CameraOffset ~= defaultOffset and (not (TE and TE.PlaybackState ~= Enum.PlaybackState.Playing)) then
					TE = TS:Create(hum, TI, {CameraOffset = defaultOffset}) -- I assume this is about the right camera offset.
					TE:Play() 
				end
				--hum.CameraOffset = defaultOffset --Move the camera back to normal.
				UIS.MouseBehavior = Enum.MouseBehavior.Default -- Let the mouse move freely
				hum.AutoRotate = true --Let the humanoid handle the camera rotations again.
				ShiftLock.Locked = false
			end
		end	
		oldClimbStatus = newClimbStatus
	end)
end

function ShiftLock.Unlock()
	--ever:Disconnect()
	--ShiftLock.Locked = nil
	if TE and TE.PlaybackState == Enum.PlaybackState.Playing then
		TE:Cancel()
	end
	TE = TS:Create(hum, TI, {CameraOffset = defaultOffset}) --Move the camera back to normal.
	TE:Play() 
	--hum.CameraOffset = defaultOffset --Move the camera back to normal.

	RS:UnbindFromRenderStep("ShiftLock") -- Allow mouse to move freely.
	UIS.MouseBehavior = Enum.MouseBehavior.Default -- Let the mouse move freely
	hum.AutoRotate = true --Let the humanoid handle the camera rotations again.
	ShiftLock.Locked = false
end

function ShiftLock.Toggle()
	if ShiftLock.Inactive then return end
	if not ShiftLock.Locked then
		ShiftLock.Lock()
	else
		ShiftLock.Unlock()
	end
	ShiftLock.Toggled:Fire()
end

function ShiftLock.DeActivate(forceLock)
	if not ShiftLock.Inactive then
		ShiftLock.Inactive = true
		if ShiftLock.Locked then
			ShiftLock.PreDeactivationLock = true
		end
		
		if not forceLock then
			ShiftLock.Unlock()
		else
			ShiftLock.Lock()
		end
	end
end

function ShiftLock.ReActivate(forceLock)
	if ShiftLock.Inactive then
		ShiftLock.Inactive = false
		if ShiftLock.PreDeactivationLock and (forceLock == nil or forceLock == true) then
			ShiftLock.Lock()
		elseif forceLock == false then
			ShiftLock.Unlock()
		end
		ShiftLock.PreDeactivationLock = nil
	end
end

return ShiftLock