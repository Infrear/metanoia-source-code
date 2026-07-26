-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local ForDash = Storage.Animations.Movement:WaitForChild("ForDash")
local BackDash = Storage.Animations.Movement:WaitForChild("BackDash")
local DashAnim = Storage.Animations.Movement:WaitForChild("FlameDash")

local plr = game.Players.LocalPlayer
local char = plr.Character
local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChild("Humanoid")
local cam = workspace.Camera

local movementReplicator = Storage.Events.Remotes.ReplicateMovement

local dashAnim = hum:WaitForChild("Animator"):LoadAnimation(DashAnim)
local bv, bg = nil, nil

local DashTime = 0.2
local DashPower = 50
local DashCooldown = 2

local TI = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- Initialization
local FlameDash = {}

-- Variables
local canDash = true
local dashing = false

-- Global Functions
function FlameDash.Start()
	if not canDash then return end
	canDash = false
	dashing = true
	bv = Instance.new("BodyVelocity")
	bv.Parent = hrp
	bv.P = 1250

	local power = Instance.new("NumberValue")
	power.Value = DashPower + 250

	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity--[[, bg.CFrame]] = hrp.CFrame.LookVector * power.Value

	--for i, v in pairs(effect:GetChildren()) do
	--	if v:IsA("ParticleEmitter") then
	--		v:Emit(1)
	--	end
	--end

	--hum.PlatformStand = true

	dashAnim:Play()
	movementReplicator:FireServer("FlameDash", true)

	coroutine.wrap(function()
		task.wait()
		local TE = TS:Create(power, TI, {Value = DashPower})
		TE:Play()
	end)()
	local con
	con = RS.RenderStepped:Connect(function()
		if bv then
			--bv.Velocity = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector).LookVector * power.Value
			--hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
			bv.Velocity = hrp.CFrame.LookVector * power.Value
		end
	end)
	repeat wait() until not dashing
	con:Disconnect()
	task.wait(DashCooldown)
	canDash = true
	--print("reset")
end

function FlameDash.Stop()
	movementReplicator:FireServer("FlameDash", false)
	if dashAnim.IsPlaying then
		dashAnim:Stop()
	end
	dashing = false
	if bv then
		bv:Destroy()
		bv = nil
	end
	if bg then
		bg:Destroy()
		bg = nil
	end
	--hum.PlatformStand = false
end

return FlameDash