--game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game:GetService("UserInputService").MouseIconEnabled = false

local lchar = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage:WaitForChild("Info").KeybindsMaster)

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local hrp = char:WaitForChild("HumanoidRootPart")

local cursorImg = playerGUI:WaitForChild("Cursor"):WaitForChild("Cursor"):WaitForChild("ImageLabel")

local mouse = plr:GetMouse()

-- Constants
local MouseSettings = {
	["Button Growth"] = 0.5,
	["Button Shrink"] = 0.2,
	["Button Growth/Shrink Speed"] = 0.05
}
local TIS = {
	["Grow"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	),
	["Shrink"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	)
}

local RESISTANCE = 0.5

-- Local Variables
local cimgs = {}

-- Local functions
local function recolorCursor(color: Color3)
	for i, v in pairs(cimgs) do
		v.ImageColor3 = Color3.new(1, 1, 1):Lerp(color, 1 - RESISTANCE)	
	end	
end

local function setupMouseStuff()
	local defaultSize = cursorImg.Size
	local currentTween = nil
	local clickTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale + MouseSettings["Button Growth"], 0, defaultSize.Y.Scale + MouseSettings["Button Growth"], 0)})
	local shrinkTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale - MouseSettings["Button Shrink"], 0, defaultSize.Y.Scale - MouseSettings["Button Shrink"], 0)})
	local defaultTween = TS:Create(cursorImg, TIS["Shrink"], {Size = defaultSize})

	mouse.Move:Connect(function()
		cursorImg.Parent.Position = UDim2.new(0, mouse.X, 0, mouse.Y)



		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			recolorCursor(Color3.new(0.141176, 0.00784314, 0.905882))
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			recolorCursor(Color3.new(1, 0, 0))
		else
			local pos = UDim2.new(0, mouse.X, 0, mouse.Y)
			local guisAtPosition = playerGUI:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

			for _, gui in ipairs(guisAtPosition) do
				if gui:IsA("TextBox") then
					recolorCursor(Color3.new(1, 1, 0))
					return	
				elseif gui:IsA("TextButton") or gui:IsA("ImageButton") then
					recolorCursor(Color3.new(0, 0.6, 1))
					return
				end
			end

			recolorCursor(Color3.new(1, 1, 1))
		end
	end)

	UIS.InputBegan:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 then
			--print("down")
			recolorCursor(Color3.new(0.141176, 0.00784314, 0.905882))
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = clickTween
			currentTween:Play()
		elseif inputType == mouse2 then
			recolorCursor(Color3.new(1, 0, 0))
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = shrinkTween
			currentTween:Play()
		end
	end)

	UIS.InputEnded:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 or inputType == mouse2 then
			--print("up")
			recolorCursor(Color3.new(1, 1, 1))
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = defaultTween
			currentTween:Play()
		end
	end)

	--UIS.InputBegan:Connect(function(input, gP)
	--	local inputType = input.UserInputType
	--	local touch = Enum.UserInputType.Touch
	--	local mouse1 = Enum.UserInputType.MouseButton1
	--	if inputType == touch or inputType == mouse1 and (not clickTween or clickTween.PlaybackState ~= Enum.PlaybackState.Playing) then
	--		-- tween the cursor's size
	--		clickTween:Play()
	--		local con 
	--		con = clickTween.Completed:Connect(function()
	--			con:Disconnect()
	--			cursorImg.Size = defaultSize
	--		end)
	--	end
	--end)
end

cursorImg.Parent.ImageData.Event:Connect(function(newImg)
	table.insert(cimgs, newImg)
end)

playerGUI:WaitForChild("Cursor").Enabled = true
setupMouseStuff()
