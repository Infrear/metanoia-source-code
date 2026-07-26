-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")

local plr = game.Players.LocalPlayer
local char = plr.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local AM = script.Parent.Parent.Parent:WaitForChild("AnimationManager2")

local cam = game.Workspace.Camera

local sprintCamStart = {FieldOfView = 90}
local sprintCamEnd = {FieldOfView = 70}
local baseWalkSpeed = 10*0.628
local baseRunSpeed = 18

local TIS = {
	--[[local TI]][1] = TweenInfo.new(
		1.15, 
		Enum.EasingStyle.Back, 
		Enum.EasingDirection.Out 
	),
	--[[local TI]][1.1] = TweenInfo.new(
		0.75, 
		Enum.EasingStyle.Back, 
		Enum.EasingDirection.Out 
	),
	--[[local TIX]][2] = TweenInfo.new(
		3,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false
	),
	--[[local TIX2]][3] = TweenInfo.new(
		0.725,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false
	),
	--[[local TIF]][4] = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false
	),
	[5] = TweenInfo.new(
		0.85,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In,
		0,
		false
	),
	[6] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false
	),
}
--local dashbut = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MobileInter").Dash
--local dodgebut = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MobileInter").Dodge
--local runbut = game.Players.LocalPlayer.PlayerGui.MobileInter.Run

-- Variables
local TE1, TE2 = nil, nil

-- Initialization
local Run = {}

-- Global Variables
Run.Running = false

-- Local Functions
function makeWinds(amt)
	coroutine.wrap(function()
		local ctab = {}
		for o = 1, amt do
			local clone = Storage.Effects.Movement.WindParticle:Clone()
			clone.CFrame = hrp.CFrame * CFrame.new(math.random(-10, 10), math.random(-5, 5), -5)
			clone.Parent = char
			clone.CFrame = hrp.CFrame * CFrame.new(math.random(-10, 10), math.random(-5, 5), -5)

			local tweeniee2 = TS:Create(clone, TIS[4], {Transparency = 0.25})
			tweeniee2:Play()
			tweeniee2.Completed:Wait(0.3)

			local tweeniee3 = TS:Create(clone, TIS[3], {Transparency = 1})
			local tweeniee = TS:Create(clone, TIS[2], {Position = clone.Position + clone.CFrame.LookVector * 5})

			tweeniee:Play()
			tweeniee3:Play()
			table.insert(ctab, clone)
			task.wait(0.05)
		end
		for i, v in pairs(ctab) do
			task.wait(0.5)
			v:Destroy()
		end
		table.clear(ctab)	
	end)	()
end

-- Global Functions
function Run.Sprint()
	if Run.Inactive then return end
	--AM.run.RunAnim.AnimationId = "rbxassetid://12009955005"
	--AM.Update:Fire()
	Run.Running = true

	local speed = baseRunSpeed --[[+ (plr.Qualities.Agility.Points.Value * 1.5) * 2.25]]
	if TE1 ~= nil then
		if TE1.PlaybackState == Enum.PlaybackState.Playing then
			TE1:Cancel()
		end
	end
	if TE2 ~= nil then
		if TE2.PlaybackState == Enum.PlaybackState.Playing then
			TE2:Cancel()
		end
	end
	TE1 = TS:Create(cam, --[[TIS[1]]TIS[1], sprintCamStart)
	TE1:Play()
	TE2 = TS:Create(hum, TIS[5], {WalkSpeed = speed})
	TE2:Play()
	
	if Run.Inactive then return end

	repeat
		wait()
		--makeWinds(2)
	until Run.Running == false --[[or char:GetAttribute("Stamina") <= 0]]
	
	if Run.Inactive then return end

	if TE1 ~= nil then
		if TE1.PlaybackState == Enum.PlaybackState.Playing then
			TE1:Cancel()
		end
	end
	if TE2 ~= nil then
		if TE2.PlaybackState == Enum.PlaybackState.Playing then
			TE2:Cancel()
		end
	end
	speed =  baseWalkSpeed --[[+ (plr.Qualities.Agility.Points.Value * 1.5) / 2.25]]
	if Run.Inactive then return end
	TE1 = TS:Create(cam, --[[TIS[1]]TIS[1.1], sprintCamEnd)
	TE1:Play()
	TE2 = TS:Create(hum, TIS[6], {WalkSpeed = speed})
	TE2:Play()

	--task.wait(1.75)
end

function Run.Walk()
	if Run.Inactive then return end
	--AM.run.RunAnim.AnimationId = "rbxassetid://12011334591"
	--AM.Update:Fire()
	Run.Running = false
	--if Run.Running then
	--	Run.Running = false
	--	game.ReplicatedStorage:WaitForChild("Assets")["Remote Events"].SetVal:FireServer(isrun, false)
	--end
end

function Run.DeActivate(tween, stationary)
	if not Run.Inactive then
		Run.Inactive = true
		local speed = stationary and 0 or baseWalkSpeed --[[+ (plr.Qualities.Agility.Points.Value * 1.5) / 2.25]]
		if TE1 ~= nil then
			if TE1.PlaybackState == Enum.PlaybackState.Playing then
				TE1:Cancel()
			end
		end
		if TE2 ~= nil then
			if TE2.PlaybackState == Enum.PlaybackState.Playing then
				TE2:Cancel()
			end
		end
		if tween ~= false and not stationary then
			TE1 = TS:Create(cam, --[[TIS[1]]TIS[1.1], sprintCamEnd):Play()
			TE2 = TS:Create(hum, TIS[6], {WalkSpeed = speed}):Play()
		elseif stationary then
			hum.WalkSpeed = speed
		end
	end
end

function Run.ReActivate()
	if Run.Inactive then
		local speed = baseWalkSpeed --[[+ (plr.Qualities.Agility.Points.Value * 1.5) / 2.25]]
		Run.Inactive = false
	end
end

hum.WalkSpeed = baseWalkSpeed --[[+ (plr.Qualities.Agility.Points.Value * 1.5) / 2.25]]

return Run