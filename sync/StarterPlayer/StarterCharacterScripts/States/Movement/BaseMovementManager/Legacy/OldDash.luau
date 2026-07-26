-- Services
local RPS = game:GetService("ReplicatedStorage")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local ForDash = Storage.Animations.Movement:WaitForChild("ForDash")
local BackDash = Storage.Animations.Movement:WaitForChild("BackDash")

local plr = game.Players.LocalPlayer
local char = plr.Character
local hrp = char:FindFirstChild("HumanoidRootPart")

local SoundManager = require(plr:WaitForChild("PlayerScripts"):WaitForChild("Audio"):WaitForChild("SoundManager"))
local group = SoundManager.CreateSoundGroup("DashSounds", {Storage.Sounds.Movement.Dash})
SoundManager.SetVolume(5, "DashSounds")

local DashTime = 0.2
local DashPower = 50
local DashCooldown = 2

-- Initialization
local Dash = {}

-- Variables
local canDash = true

-- Global Functions
function Dash.Dash()
	if canDash then
		local bv = Instance.new("BodyVelocity")
		bv.Parent = hrp
		bv.P = 1250
		
		--print("played")
		SoundManager.PlaySoundGroup("DashSounds")
		
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Velocity = hrp.CFrame.LookVector * DashPower

		canDash = false
		DBS:AddItem(bv, DashTime)
		
		for i, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") then
				local at0 = Instance.new("Attachment", v)
				at0.Orientation = Vector3.new(-90, 0, 0)
				at0.Position = Vector3.new(0, 0.5, 0)
				
				local at1 = Instance.new("Attachment", v)
				at1.Orientation = Vector3.new(-90, 0, 0)
				at1.Position = Vector3.new(0, -0.5, 0)
				
				local trail = Instance.new("Trail", v)
				trail.Attachment0 = at0
				trail.Attachment1 = at1
				trail.Lifetime = 0.1
				
				DBS:AddItem(at0, DashCooldown)
				DBS:AddItem(at1, DashCooldown)
				DBS:AddItem(trail, 0.5)
			end
		end
		task.wait(DashCooldown)
		canDash = true
	end
end

return Dash