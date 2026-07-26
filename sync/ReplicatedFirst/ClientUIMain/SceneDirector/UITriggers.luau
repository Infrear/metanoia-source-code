-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependencies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local Storage = RPS:WaitForChild("ClientStorage")
local CienematicBarsUI = playerGUI:WaitForChild("CutsceneBars")
local topEdge, bottomEdge = CienematicBarsUI:WaitForChild("Holder"):WaitForChild("TopEdge"),  CienematicBarsUI:WaitForChild("Holder"):WaitForChild("BottomEdge")
local ScreenHandler = require(script.Parent.Parent:WaitForChild("ScreenChangeHandler"))
local edgeEv = Instance.new("BindableEvent", script)

local TIS = {
	CienematicClose = TweenInfo.new(
		2.5, 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out
	)
}

-- Local Variables
local edgeTEs = {}
local edgeCon = nil

-- Init
local uiTriggers = {}

-- Global Variables
uiTriggers.BarsOpen = false

-- Global Functions
uiTriggers.CienematicBars = function(step)
	local stopped = false

	edgeEv:Fire()
	if edgeCon then
		edgeCon:Disconnect()
	end
	edgeCon = edgeEv.Event:Once(function()
		stopped = true
	end)
	
	if step.Delay then
		task.wait(step.Delay)
	end

	if stopped then return end
	
	if edgeTEs[topEdge] then
		if edgeTEs[topEdge].PlaybackState == Enum.PlaybackState.Playing then
			edgeTEs[topEdge]:Cancel()
		end
	end
	if edgeTEs[bottomEdge] then
		if edgeTEs[bottomEdge].PlaybackState == Enum.PlaybackState.Playing then
			edgeTEs[bottomEdge]:Cancel()
		end
	end
	if step.Open then
		uiTriggers.BarsOpen = true
		edgeTEs[topEdge] = TS:Create(topEdge, TIS.CienematicClose, {Position = UDim2.fromScale(topEdge.Position.X.Scale, 0)})
		edgeTEs[bottomEdge] = TS:Create(bottomEdge, TIS.CienematicClose, {Position = UDim2.fromScale(bottomEdge.Position.X.Scale, 1)})
	else
		uiTriggers.BarsOpen = false
		edgeTEs[topEdge] = TS:Create(topEdge, TIS.CienematicClose, {Position = UDim2.fromScale(topEdge.Position.X.Scale, -0.25)})
		edgeTEs[bottomEdge] = TS:Create(bottomEdge, TIS.CienematicClose, {Position = UDim2.fromScale(bottomEdge.Position.X.Scale, 1.25)})
	end
	edgeTEs[topEdge]:Play()
	edgeTEs[bottomEdge]:Play()
	
	if edgeCon then edgeCon:Disconnect() end
end

uiTriggers.SimpleFade = function(step)
	if step.Delay then
		task.wait(step.Delay)
	end

	if step.In then
		ScreenHandler.LoadIn("Scrub", true)
	else
		ScreenHandler.LoadOut()
	end
end

return uiTriggers
