-- Constants
-- Define animation parameters
--local SCALE_TARGET = Vector2.new(0.345, 0.115) -- The final scale of the text
local FADE_DURATION = 1 -- The duration of the fading effect in seconds
local MOVE_DURATION = 2.5 -- The duration of the motion effect in seconds
local ORIGIN_POSITION = UDim2.new(0.425, 0, 0.722, 0)
local POSITION_OFFSET = Vector2.new(0, 0.05)
--local MOVEMENT_AMPLITUDE = 5 -- The maximum displacement for the motion effect

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)
local richText = require(Storage.Modules:WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("RichText"))
local Regions = workspace:WaitForChild("REGIONS")

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("Regions")
--local textLabel = frame:WaitForChild("TextLabel")
local textArea = frame:WaitForChild("TextArea")
local textObject = nil
local currentRegion = nil

local TIS = {
	[1] = TweenInfo.new(
		FADE_DURATION
	),
	[2] = TweenInfo.new( 
		MOVE_DURATION, 
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out, 
		0, 
		false, 
		0
	),
}

-- Variables
local TES = {}
local cons = {}
local ev = Instance.new("BindableEvent")

-- Initialization
local regions = {}

-- Global Variables
regions.Ready = Instance.new("BindableEvent")

-- Local Functions
-- Function to animate the text
local function animateText(txt)
	ev:Fire()
	--print("start")
	if TES[textArea] then -- stop other tweens
		for i, v in pairs(TES[textArea]) do
			if i ~= textArea then
				if v[1].PlaybackState == Enum.PlaybackState.Playing then
					v[1]:Cancel()	
				end
				i[v[2]] = v[3]
			else
				if v.PlaybackState == Enum.PlaybackState.Playing then
					v:Cancel()	
				end
				textArea.Position = ORIGIN_POSITION
			end
		end
	end
	
	TES[textArea] = {}
	
	-- do nice text stuff
	local text = "<AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=.5><Color=White>"..txt
	textObject = richText:New(textArea, text, {ContainerHorizontalAlignment = "Right"--[[Center]]}, false)

	-- Run the animation
	--print("ran")
	local oldTextObject = textObject
	textObject:Animate(true)
	local toContinue = true
	local con
	con = ev.Event:Connect(function()
		toContinue = false
		if con then
			con:Disconnect()
		end
	end)
	task.wait(1.5) -- wait before more
	if con then 
		con:Disconnect()
	end
	if not toContinue then oldTextObject:Hide() return end
	for i, v in pairs(textArea:GetDescendants()) do
		if v:IsA("TextLabel") then
			local tween = TS:Create(v, TIS[1], {TextTransparency = 1})
			TES[textArea][v] = {tween, "TextTransparency", v.TextTransparency}
			tween:Play()
		end
	end
	TES[textArea][textArea] = TS:Create(textArea, TIS[1], {Position = UDim2.new(ORIGIN_POSITION.X.Scale + POSITION_OFFSET.X, 0, ORIGIN_POSITION.Y.Scale + POSITION_OFFSET.Y, 0)})
	TES[textArea][textArea]:Play()
end


-- Global Functions
function regions.setup()
	-- Call the animation function when the player enters a new region
	-- You can trigger this based on your game's logic (e.g., a player enters a certain area)
	--animateText("Kakran Village")

	-- add method to detect when bump into part, detect the parent, and animate the text of the parent's name
	-- Define the region models and their corresponding names
	local regionModels = {
		["Kakaran Village"] = [[game.Workspace.KakaranVillage]], -- Replace "KakaranVillage" with the actual name of the region model
		["Amaro Forest"] = [[game.Workspace.AmaroForest]], -- Replace "AmaroForest" with the actual name of the region model
		-- Add more regions and their corresponding models as needed
	}
	table.clear(regionModels)
	for i, v in pairs(Regions.Outlining:GetChildren()) do
		regionModels[v.Name] = v 
	end
	
	-- Detect when the humanoid enters a region
	hrp.Touched:Connect(function(part)
		for regionName, regionModel in pairs(regionModels) do
			if part:IsDescendantOf(regionModel) and regionModel ~= currentRegion then
				-- Animate the text with the name of the region
				currentRegion = regionModel
				animateText(regionName)
				break -- Exit the loop after finding the matching region
			end
		end
	end)	
end

return regions