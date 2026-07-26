-- Constants
local defaultBarLength = 0.05

local HOVER_SETTINGS = {
	RotateForwardSpeed = 0.35,
	RotateBackSpeed = 0.35,
	RotationAddition = 45,
	OGSize = UDim2.new(0.885, 0, 0.885, 0),
	OGPosition = UDim2.new(0.5, 0, 0.5, 0),
	SizeAddition = UDim2.new(0.015, 0, 0.015, 0),
	PositionAddition = UDim2.new(0, 0, 0.085, 0),
	--OGColor = Color3.new(0.45098, 0.45098, 0.45098),
	OGColor = Color3.fromRGB(255, 255, 255),
	HoverColor = Color3.new(0.756863, 0.756863, 0.862745)
}

--local HOVER_SETTINGSb = {
--	RotateForwardSpeed = 0.55,
--	RotateBackSpeed = 1.5,
--	OGPosition = UDim.new(0, 1),
--	PositionAddition = UDim2.new(0, 0, 0.085, 0),
--}

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)
local itemInfo = require(Storage.Info.ItemInfo)

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")

local vp = require(script:WaitForChild("Viewport"))
local invDataStorer = require(playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"))
local clientUpdEv = playerGUI:WaitForChild("UIManager"):WaitForChild("Events"):WaitForChild("UpdInv")
local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Avatar"):WaitForChild("Background")
local box1 = frame:WaitForChild("SBackground")
local box2 = frame:WaitForChild("VBackground")
local vport = box2:WaitForChild("ViewportFrame")
local getData = Storage:WaitForChild("Functions").Remotes.GetData
local statsUpdated = Storage.Events.Remotes:WaitForChild("StatsUpdated")
local craftRunning = false

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	),
	["Hover"] = TweenInfo.new(
		HOVER_SETTINGS.RotateForwardSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
}
local HOVER_TES = {}
local HOVER_cons = {}

-- Initialization
local you = {}
--you.armorSlots = {}

-- Local Functions

local function closeUp(button)
	if HOVER_TES[button] then
		if HOVER_TES[button][1] then
			if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
				HOVER_TES[button][1]:Cancel()
			end
		end
		if HOVER_TES[button][2] then
			if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
				HOVER_TES[button][2]:Cancel()
			end
		end
	end
	HOVER_TES[button] = {}

	HOVER_TES[button][1] = TS:Create(button.UIStroke, TIS.Hover, {Transparency = 1, Thickness = 0})
	HOVER_TES[button][1]:Play()

	--HOVER_TES[button][2] = TS:Create(button.Img, TIS.Hover, {Size = HOVER_SETTINGS.OGSize,  Position = HOVER_SETTINGS.OGPosition})
	--HOVER_TES[button][2]:Play()

	button.Add.Visible = false
	button.Ind.Visible = false
end

local function bindBar(button)
	button.UIStroke.Transparency = 1
	button.UIStroke.Thickness = 0

	button.Add.Visible = false
	button.Ind.Visible = false
	
	HOVER_cons[button] = {}
	HOVER_cons[button][1] = button.MouseEnter:Connect(function()
		--print(Crafts)
		--print(canCraft(button, Crafts[button].Materials))
		--if not canCraft(button, Crafts[button].Materials) then return end
		if HOVER_TES[button] then
			if HOVER_TES[button][1] then
				if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][1]:Cancel()
				end
			end
			if HOVER_TES[button][2] then
				if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][2]:Cancel()
				end
			end
		end
		HOVER_TES[button] = {}


		HOVER_TES[button][1] = TS:Create(button.UIStroke, TIS.Hover, {Transparency = 0, Thickness = 2.3})
		HOVER_TES[button][1]:Play()

		--HOVER_TES[button][2] = TS:Create(button.Img, TIS.Hover, {Size = HOVER_SETTINGS.OGSize + HOVER_SETTINGS.SizeAddition,  Position = HOVER_SETTINGS.OGPosition + HOVER_SETTINGS.PositionAddition})
		--HOVER_TES[button][2]:Play()
		
		button.Add.Visible = true
		button.Ind.Visible = true
	end)


	HOVER_cons[button][2] = button.MouseLeave:Connect(function()
		closeUp(button)
	end)
end

--function you.updArmor(gotData)
--	if not gotData then return end
	
--	for i, v in pairs(box2:GetChildren()) do
--		if v:IsA("TextButton") and gotData[v.Name] then
--			print(v)
--			print(v.Name)
--		end
--	end
--end

function you.updStats(gotData)
	if not gotData then return end
	box1.Levelline.Levelbar.Size = UDim2.new(1 * (gotData.Data[1].Exp/gotData.Data[1].MaxExp), 0, box1.Levelline.Levelbar.Size.Y.Scale, 0)
	 
	box2.Level.Text = "Level"..tostring(gotData.Data[1].Level)
	
	for i, v in pairs(box1.Bars:GetChildren()) do
		if v:IsA("Frame") and box1.Tags:FindFirstChild(v.Name) then
			local foundamount = gotData.Data[2][v.Name] or 0
			v.Size = UDim2.new(v.Size.X.Scale, 0, (0.75 *(foundamount/50)) + 0.5, 0)
			v.Ind.Text = "("..tostring(foundamount)..")"
		end
	end
end

-- Global Functions
function you.setup()
	vp.start(char, vport)
	
	statsUpdated.OnClientEvent:Connect(you.updStats)
	you.updStats(getData:InvokeServer("Stats"))

	for i, v in pairs(box1.Bars:GetChildren()) do
		if v:IsA("Frame") and box1.Tags:FindFirstChild(v.Name) then
			bindBar(v)
		end
	end
end

return you
