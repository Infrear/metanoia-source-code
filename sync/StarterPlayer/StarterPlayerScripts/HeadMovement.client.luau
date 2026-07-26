local runService = game:GetService("RunService")
local playerService = game:GetService("Players")

local headHorFactor = 1
local headVerFactor = .6
local bodyHorFactor = .5
local bodyVerFactor = .4
local updateSpeed = .5 / 2

local plr = playerService.LocalPlayer
local cam = workspace.CurrentCamera
local mouse = plr:GetMouse()

local char = plr.Character or plr.CharacterAdded:wait()
local hum = char:WaitForChild("Humanoid")
local isR6 = hum.RigType == Enum.HumanoidRigType.R6
local head = char:WaitForChild("Head")
local root = char:WaitForChild("HumanoidRootPart")
	local torso = isR6 and char:WaitForChild("Torso") or char:WaitForChild("UpperTorso")
local neck = isR6 and torso.Neck or head.Neck
local waist = not isR6 and torso.Waist

local neckC0 = neck.C0
local waistC0 = not isR6 and waist.C0
neck:SetAttribute("OGC0", neckC0)

neck.MaxVelocity = 1/3

runService.RenderStepped:Connect(function ()

	if torso and head and ((isR6 and neck) or (neck and waist)) and cam.CameraSubject == hum then

		local camCF = cam.CFrame
		local headCF = head.CFrame

		local torsoLV = torso.CFrame.lookVector

		local dist = (headCF.Position - camCF.Position).magnitude
		local diff = headCF.Y - camCF.Y

		local asinDiffDist = math.asin(diff / dist)
		local headCross = ((headCF.Position - camCF.Position).Unit:Cross(torsoLV)).Y

		if isR6 then
			neck.C0 = neck.C0:lerp(neckC0 * CFrame.Angles(-1 * asinDiffDist * headVerFactor, 0, -1 * headCross * headHorFactor), updateSpeed)
		else
			neck.C0 = neck.C0:lerp(neckC0 * CFrame.Angles(asinDiffDist * headVerFactor, -1 * headCross * headHorFactor, 0), updateSpeed)
			--waist.C0 = waist.C0:lerp(waistC0 * CFrame.Angles(asinDiffDist * bodyVerFactor, -1 * headCross * bodyHorFactor, 0), updateSpeed)
		end

	end
end)