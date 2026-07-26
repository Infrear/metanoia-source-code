--local isrun = char.Stats.Running
workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled

-- Services
local UIS = game:GetService("UserInputService")
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local combatSettings = require(Storage.Info.CombatSettings)
local keySettings = require(Storage.Info.KeybindsMaster)
local combatReplicator = Storage.Events.Remotes.ReplicateCombat
local overworldCamEffectsToggleEv = Storage.Events.Standard.ToggleOverworldCamStuff

local plr = game.Players.LocalPlayer
local char = plr.Character
local hum = char:WaitForChild("Humanoid")
local isR6 = hum.RigType == Enum.HumanoidRigType.R6
local head = char:WaitForChild("Head")
local hrp = char:FindFirstChild("HumanoidRootPart")
local torso = isR6 and char:WaitForChild("Torso") or char:WaitForChild("UpperTorso")
local neck = isR6 and torso.Neck or head.Neck

local mouse = plr:GetMouse()
local cam = game.Workspace.Camera

local Start = {FieldOfView = 90}
local End = {FieldOfView = 65}
cam.FieldOfView = End.FieldOfView

--local dashbut = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MobileInter").Dash
--local dodgebut = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MobileInter").Dodge
--local runbut = game.Players.LocalPlayer.PlayerGui.MobileInter.Run


local Tilt = require(script:WaitForChild("Tilt"))
local Run = require(script:WaitForChild("Run"))
local FlameDash = require(script:WaitForChild("FlameDash"))
local ShiftLock = require(script:WaitForChild("ShiftLock"))
local Climb = require(script:WaitForChild("Climb"))
local RunModule = require(script:WaitForChild("Run"))

-- Variables
local ever = nil
local running = true
local locked = false
local holded = false
local climbing = false

local cons = {}

local TIS = {
	--[[local TI]][1] = TweenInfo.new(
		1, 
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
	--[[local TIM]][5] = TweenInfo.new(
		1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false
	),
	--[[local TIMC]][6] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		true
	),
}

table.insert(cons, Tilt.Bind())

-- Connections
UIS.InputBegan:Connect(function(input, gP)
	if input.UserInputType == Enum.UserInputType.Keyboard  then
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift and not gP then
			Run.Sprint()
		elseif input.KeyCode == Enum.KeyCode.Q then
			FlameDash.Start()
			--print("started")
			--if can_dash == true and char:GetAttribute("Stamina") - 15 >= 1  then
			--	can_dash = false
			--local pos = hrp.CFrame * CFrame.fromEulerAnglesXYZ(math.rad(270), 0, 0)
			--game.ReplicatedStorage.Assets["Remote Events"].Skiller:FireServer("Dash", nil, pos)
			--		game.ReplicatedStorage.Assets["Remote Events"].SetAttrib:FireServer("Stamina", char:GetAttribute("Stamina") - 15) 
			--	local coro = coroutine.create(function()  
			--		humanoid.Sit = false
			--		game.ReplicatedStorage.Assets["Remote Events"].PlayAnim:FireServer(humanoid:WaitForChild("Animator"), BackDash)
			--		local i = Instance.new("BodyPosition")
			--		i.MaxForce = Vector3.new(1000000, 0, 1000000)
			--		i.P = 100000
			--		i.D = 2000
			--		i.Position = (hrp.CFrame * CFrame.new(0, 0, 17.5)).Position 
			--		i.Parent = hrp
			--		coroutine.wrap(function()
			--			wait(0.25)
			--			i:Destroy() 
			--		end)()
			--		makeWinds(6)
			--	end)
			--	coroutine.resume(coro)
			--	wait(1)
			--	can_dash = true
			--end
		elseif input.KeyCode == Enum.KeyCode.C then
			if not Climb.climbing then
				Climb.start()
			else
				Climb.stop()
				climbing = false
			end
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			ShiftLock.Toggle()
		end
	end
end)

UIS.InputEnded:Connect(function(input, gP)
	if input.UserInputType == Enum.UserInputType.Keyboard and not gP then
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			Run.Walk()
		elseif input.KeyCode == Enum.KeyCode.Q then
			FlameDash.Stop()
		end
	end
end)

overworldCamEffectsToggleEv.Event:Connect(function(toggle, stationary)
	if toggle ~= nil then
		plr.PlayerScripts.Camera.MotionBlur.Enabled = toggle
		--plr.PlayerScripts.Camera["TSC v1"]:SetAttribute("EnabledScript", toggle)
		if toggle then
			ShiftLock.ReActivate()
			if stationary then
				Run.ReActivate()
			end
		else
			ShiftLock.DeActivate()
			if stationary then
				Run.DeActivate(nil, stationary)
			end
		end
	end
end)


overworldCamEffectsToggleEv.Event:Connect(function(toggle)
	if toggle ~= nil then
		plr.PlayerScripts.HeadMovement.Enabled = toggle
		if (not toggle) and neck:GetAttribute("OGC0") then
			neck.C0 = neck:GetAttribute("OGC0")
		end
	end
end)

--RS.RenderStepped:Connect(function()
	--Climb.start()
--end)