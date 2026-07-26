local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Templates = ReplicatedStorage:WaitForChild("PromptTemplates")

-- // MAPPINGS (From original code)
local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxView.png",
	[Enum.KeyCode.ButtonStart] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLB.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRB.png",
	[Enum.KeyCode.ButtonL2] = "rbxasset://textures/ui/Controls/xboxLT.png",
	[Enum.KeyCode.ButtonR2] = "rbxasset://textures/ui/Controls/xboxRT.png",
	[Enum.KeyCode.ButtonL3] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR3] = "rbxasset://textures/ui/Controls/xboxRS.png",
	[Enum.KeyCode.Thumbstick1] = "rbxasset://textures/ui/Controls/xboxLSDirectional.png",
	[Enum.KeyCode.Thumbstick2] = "rbxasset://textures/ui/Controls/xboxRSDirectional.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

-- // TWEEN INFO
local BloopTI = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SlowTI = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MidTI = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FastTI = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FastTIBack = TweenInfo.new(0.15/2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

-- // Local Variables
--local test = 1

-- // RADIAL PROGRESS GENERATION
local function createProgressBarGradient(parent, leftSide)
	local frame = Instance.new("Frame")
	-- CHANGE: Set width to 0.51 (51%) instead of 0.5
	frame.Size = UDim2.fromScale(0.51, 1) 

	-- CHANGE: Shift the right side slightly left to ensure the overlap is centered
	frame.Position = UDim2.fromScale(leftSide and 0 or 0.49, 0)

	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Parent = parent

	local image = Instance.new("ImageLabel")
	image.Name = "FillImage"
	image.BackgroundTransparency = 1
	-- Keep image size at 2 (since it's filling a 0.5ish container)
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(leftSide and 0 or -1, 0)
	image.Image = "rbxassetid://107883673811681"
	image.ImageColor3 = Color3.fromRGB(191, 0, 255)-- = Color3.fromRGB(10, 120, 239) -- Change color here
	image.ImageTransparency = 0.999
	image.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.501, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = leftSide and 180 or 0
	gradient.Parent = image

	return gradient
end

local function createCircularProgressBar(bartype)
	local bar = Instance.new("Frame")
	bar.Name = "CircularProgressBar"
	bar.Size = (bartype == "square" and UDim2.fromScale(1, 0)) or UDim2.fromScale(1, 1) -- Fill the key icon parent
	bar.AnchorPoint = (bartype == "square" and Vector2.new(0.5, 1)) or Vector2.new(0.5, 0.5)
	bar.Position = (bartype == "square" and UDim2.fromScale(0.5, 1)) or UDim2.fromScale(0.5, 0.5)
	bar.BackgroundTransparency = (bartype == "square" and 0) or 1
	bar.BorderSizePixel = 0

	local gradient1, gradient2 = nil, nil
	if bartype == "circle" then
		gradient1 = createProgressBarGradient(bar, true)
		gradient2 = createProgressBarGradient(bar, false)
	elseif bartype == "square" then
		bar.ZIndex = 9
		bar.BackgroundColor3 = Color3.fromRGB(191, 0, 255)
	end
	
	local progress = Instance.new("NumberValue")
	progress.Name = "Progress"
	progress.Parent = bar
	
	progress.Changed:Connect(function(value)
		if bartype == "circle" then
			local angle = math.clamp(value * 360, 0, 360)
			gradient1.Rotation = math.clamp(angle, 180, 360)
			gradient2.Rotation = math.clamp(angle, 0, 180)
		elseif bartype == "square" then
			bar.Size = UDim2.fromScale(bar.Size.X.Scale, value)
		end
	end)

	return bar
end

-- // ICON FACTORY (Handles Button Image/Text logic)
local function setupKeyIcon(parent, prompt, inputType)
	-- Clear existing icons in the parent if any
	for _, v in pairs(parent:GetChildren()) do
		if v:IsA("ImageLabel") or v:IsA("TextLabel") then v:Destroy() end
	end

	local icon = nil
	local loadMethod = "circle"
	--if test == 1 then
	--	inputType = Enum.ProximityPromptInputType.Keyboard
	--elseif test == 2 then
	--	inputType = Enum.ProximityPromptInputType.Touch
	--elseif test == 3 then
	--	inputType = Enum.ProximityPromptInputType.Gamepad
	--elseif test == 4 then
	--	inputType = Enum.ProximityPromptInputType.Gamepad
	--end
	--if test < 4 then
	--test +=1
	--else
	--	test = 1
	--end
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		if GamepadButtonImage[prompt.GamepadKeyCode] then
			icon = Instance.new("ImageLabel")
			icon.Image = GamepadButtonImage[prompt.GamepadKeyCode]
			icon.Size = UDim2.fromScale(0.6, 0.6)
		end
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		icon = Instance.new("ImageLabel")
		icon.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
		icon.Size = UDim2.fromScale(0.8, 0.8)
	else
		-- Keyboard Logic
		local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		local buttonTextImage = KeyboardButtonImage[prompt.KeyboardKeyCode] or KeyboardButtonIconMapping[buttonTextString]

		if buttonTextImage then
			icon = Instance.new("ImageLabel")
			icon.Image = buttonTextImage
			icon.Size = UDim2.fromScale(1, 1)
		else
			local text = KeyCodeToTextMapping[prompt.KeyboardKeyCode] or buttonTextString
			icon = Instance.new("TextLabel")
			icon.Text = text
			icon.Font = Enum.Font.GothamBold
			icon.TextColor3 = Color3.new(1, 1, 1)
			icon.Size = UDim2.fromScale(0.6, 0.6)
			icon.TextScaled = true
		end
		
		-- change to square
		parent.Parent.ImageTransparency = 1
		parent.Parent.BackgroundColor3 = Color3.new(1, 1, 1)
		parent.Parent.BackgroundTransparency = 0
		parent.Parent.Position = UDim2.fromScale(parent.Parent.Position.X.Scale - 0.011, parent.Parent.Position.Y.Scale + 0.053)
		--parent.Parent.Size = UDim2.fromScale(parent.Parent.Size.X.Scale * 0.8, parent.Parent.Size.Y.Scale * 0.8)

		parent.ImageTransparency = 1
		parent.BackgroundColor3 = Color3.new()
		parent.BackgroundTransparency = 0
		parent.Position = UDim2.fromScale(0.5, 0.5)
		parent.Size = UDim2.fromScale(0.875, 0.875)
		loadMethod = "square"
	end

	if icon then
		icon.Name = "InputIcon"
		icon.BackgroundTransparency = 1
		--icon.Size = UDim2.fromScale(0.6, 0.6) -- Adjust based on how it fits your frame
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.ZIndex = parent.ZIndex + 1
		icon.Parent = parent
	end
	
	return loadMethod
end

-- // MAIN HANDLER
local function onPromptShown(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then return end

	local templateName = prompt.ActionText 
	local sourceTemplate = Templates:FindFirstChild(templateName) or Templates:FindFirstChild("Examine")

	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts") or Instance.new("ScreenGui", PlayerGui)
	screenGui.Name = "ProximityPrompts"

	local promptUI = Instance.new("BillboardGui")
	promptUI.Name = "PersonaPrompt"
	promptUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	promptUI.AlwaysOnTop = true
	promptUI.Size = UDim2.fromScale(7.5, 4)
	promptUI.Adornee = prompt.Parent

	local holder = sourceTemplate:Clone()
	holder.Name = "Holder"
	holder.Size = UDim2.fromScale(0, 0)
	holder.Parent = promptUI

	-- Update Object Text
	local label = holder:FindFirstChild("ObjectText", true) 
	-- Path: holder.Secondary.F1.TFrame.ObjectText (via recursive find)
	if label then label.Text = prompt.ObjectText end

	-- Handle Key Icon and Progress Bar
	local keyIconParent = holder:FindFirstChild("Outer", true) and holder.Secondary.Outer.Inner
	local progressValue = nil
	local bartype = "circle"

	if keyIconParent then
		bartype = setupKeyIcon(keyIconParent, prompt, inputType)
		
		if prompt.HoldDuration > 0 then
			local circleBar = createCircularProgressBar(bartype)
			circleBar.Parent = keyIconParent.Parent
			progressValue = circleBar.Progress
		end
	end

	-- Animations
	promptUI.Parent = screenGui
	TweenService:Create(holder, BloopTI, {Size = UDim2.fromScale(1, 1)}):Play()

	-- Input Logic
	local currentTween = nil
	local currentTween2 = nil
	local currentImgTweens = {}
	local holdBegan, holdEnded--, trig
	if progressValue then
		holdBegan = prompt.PromptButtonHoldBegan:Connect(function()
			if progressValue and progressValue.Parent then
				if bartype == "circle" then
					-- Fade the fill images IN
					if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then currentTween:Cancel() end
					for _, img in pairs(progressValue.Parent:GetDescendants()) do
						if img:IsA("ImageLabel") then
							if currentImgTweens[img] and currentImgTweens[img].PlaybackState == Enum.PlaybackState.Playing then currentImgTweens[img]:Cancel() end

							currentImgTweens[img] = TweenService:Create(img, FastTI, {ImageTransparency = 0})
							currentImgTweens[img]:Play()
						end
					end


					--if trig then 
					--	trig:Disconnect()
					--end
					--trig = currentTween.Completed:Connect(function()
					--	if trig then trig:Disconnect() end
					--	if progressValue >= 1 then
					--		currentTween2 = TweenService:Create(holder.UIScale, FastTIBack, {Scale = 1.15})
					--		currentTween2:Play()
					--		currentTween2.Completed:Wait()
					--		currentTween = TweenService:Create(holder.UIScale, FastTI, {Scale = 0})
					--		currentTween:Play()
					--	end
					--end)
				elseif bartype == "square" then
					if currentImgTweens[progressValue.Parent] and currentImgTweens[progressValue.Parent].PlaybackState == Enum.PlaybackState.Playing then currentImgTweens[progressValue.Parent]:Cancel() end

					currentImgTweens[progressValue.Parent] = TweenService:Create(progressValue.Parent, FastTI, {BackgroundTransparency = 0})
					currentImgTweens[progressValue.Parent]:Play()
				end
				currentTween = TweenService:Create(progressValue, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Value = 1})
				currentTween:Play()
				currentTween2 = TweenService:Create(holder.UIScale, FastTI, {Scale = 1.15})
				currentTween2:Play()
			end
		end)
		holdEnded = prompt.PromptButtonHoldEnded:Connect(function()
			if progressValue and progressValue.Parent then
				if bartype == "circle" then
					if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then currentTween:Cancel() end
					for _, img in pairs(progressValue.Parent:GetDescendants()) do
						if img:IsA("ImageLabel") then
							if currentImgTweens[img] and currentImgTweens[img].PlaybackState == Enum.PlaybackState.Playing then currentImgTweens[img]:Cancel() end

							currentImgTweens[img] = TweenService:Create(img, MidTI, {ImageTransparency = 0.999})
							currentImgTweens[img]:Play()
						end
					end
					currentTween = TweenService:Create(progressValue, MidTI, {Value = 0})
					currentTween:Play()
					currentTween2 = TweenService:Create(holder.UIScale, FastTI, {Scale = 1})
					currentTween2:Play()
				elseif bartype == "square" then
					if currentImgTweens[progressValue.Parent] and currentImgTweens[progressValue.Parent].PlaybackState == Enum.PlaybackState.Playing then currentImgTweens[progressValue.Parent]:Cancel() end

					currentImgTweens[progressValue.Parent] = TweenService:Create(progressValue.Parent, MidTI, {BackgroundTransparency = 0.999})
					currentImgTweens[progressValue.Parent]:Play()
				end
				currentTween = TweenService:Create(progressValue, MidTI, {Value = 0})
				currentTween:Play()
				currentTween2 = TweenService:Create(holder.UIScale, FastTI, {Scale = 1})
				currentTween2:Play()
			end
		end)
	end
	holdBegan = prompt.Triggered:Connect(function()
		currentTween2 = TweenService:Create(holder.UIScale, FastTIBack, {Scale = 1.5})
		currentTween2:Play()
		currentTween2.Completed:Wait()
		currentTween = TweenService:Create(holder.UIScale, FastTI, {Scale = 0})
		currentTween:Play()
	end)
	-- Cleanup
	prompt.PromptHidden:Wait()
	if holdBegan then
		holdBegan:Disconnect()
	end
	if holdEnded then
		holdEnded:Disconnect()
	end
	--if trig then 
	--	trig:Disconnect()
	--end
	local out = TweenService:Create(holder, FastTI, {Size = UDim2.fromScale(0, 0)})
	out:Play()
	out.Completed:Wait()
	promptUI:Destroy()
end

ProximityPromptService.PromptShown:Connect(onPromptShown)