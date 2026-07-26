-- Services
local RS = game:GetService("RunService")

-- Dependancies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

--local RootJoint = hrp.RootJoint

local mouse = plr:GetMouse()

-- Initialization
local Tilt = {}

-- Variables
local defaultC1 = char:WaitForChild("LowerTorso"):WaitForChild("Root").C1
local relbow = char:WaitForChild("RightLowerArm"):WaitForChild("RightElbow")
local lelbow = char:WaitForChild("LeftLowerArm"):WaitForChild("LeftElbow")
local tiltZ = 0
local tiltX = 0
local maxTilt = 0.2
local tiltSpeed = 0.02

-- Local Functions
local function Lerp(a, b, c)
	return a + (b - a) * c
end

-- Global Functions
function Tilt.Bind()
	return RS.RenderStepped:Connect(function()
		local lTors = char:WaitForChild("LowerTorso")
		local movementVector = hrp.CFrame:vectorToObjectSpace(hrp.Velocity/math.max(hum.WalkSpeed,0.01))
		tiltZ = math.clamp(Lerp(tiltZ, movementVector.X,tiltSpeed),-maxTilt,maxTilt)
		--tiltX = math.clamp(Lerp(tiltX, math.abs(math.clamp(movementVector.Z,-1,0)),0.1),0,0.25)
		--Instance.new("Motor6D").Transform
		--lTors:WaitForChild("Root").C1 = defaultC1*CFrame.Angles(tiltX,0,tiltZ)
		lTors:WaitForChild("Root").C1 = defaultC1*CFrame.Angles(tiltX,0,tiltZ)
	end)
end

return Tilt