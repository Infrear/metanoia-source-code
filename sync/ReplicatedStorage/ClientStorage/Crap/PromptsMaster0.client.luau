local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Templates = ReplicatedStorage:WaitForChild("PromptTemplates")

-- Tween Settings
local BloopTI = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FastTI = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getScreenGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

-- Radial Progress Logic (From your provided example)
local function setupRadialProgress(keyFrame)
	local progress = Instance.new("NumberValue")
	progress.Name = "ProgressValue"
	progress.Parent = keyFrame

	-- Assuming your 'Key' frame has the UIGradients for radial fill
	-- If not, you can use your createProgressBarGradient function here
	local grad1 = keyFrame:FindFirstChild("LeftGradient", true)
	local grad2 = keyFrame:FindFirstChild("RightGradient", true)

	progress.Changed:Connect(function(value)
		local angle = math.clamp(value * 360, 0, 360)
		if grad1 then grad1.Rotation = math.clamp(angle, 180, 360) end
		if grad2 then grad2.Rotation = math.clamp(angle, 0, 180) end
	end)

	return progress
end

local function onPromptShown(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then return end

	-- 1. Identify Template
	local templateName = prompt.ActionText -- "Examine", "Talk", or "Go"
	local sourceTemplate = Templates:FindFirstChild(templateName) or Templates:FindFirstChild("Examine")

	local promptUI = Instance.new("BillboardGui")
	promptUI.Name = "PersonaPrompt"
	promptUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	promptUI.AlwaysOnTop = true
	promptUI.Size = UDim2.fromScale(7.5, 4) -- Adjust based on your UI size
	promptUI.Adornee = prompt.Parent

	local holder = sourceTemplate:Clone()
	holder.Name = "Holder"
	holder.Size = UDim2.fromScale(0, 0) -- Start at 0 for the pop-in
	holder.Parent = promptUI

	-- 2. Update Dynamic Text
	local label = holder.Secondary:FindFirstChild("ObjectText", true)
	if label then
		label.Text = prompt.ObjectText or " "
	end

	-- 3. Handle Progress Bar
	local progressValue = nil
	if prompt.HoldDuration > 0 then
		local keyIcon = holder.Secondary.Outer.Inner:FindFirstChild("Key", true)
		print(keyIcon)
		if keyIcon then
			progressValue = setupRadialProgress(keyIcon)
		end
	end

	-- 4. Animations
	local inTween = TweenService:Create(holder, BloopTI, {Size = UDim2.fromScale(1, 1)})

	promptUI.Parent = getScreenGui()
	inTween:Play()

	-- Input Connections
	local holdBegan = prompt.PromptButtonHoldBegan:Connect(function()
		if progressValue then
			TweenService:Create(progressValue, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), {Value = 1}):Play()
		end
		TweenService:Create(holder, FastTI, {Size = UDim2.fromScale(1.1, 1.1)}):Play()
	end)

	local holdEnded = prompt.PromptButtonHoldEnded:Connect(function()
		if progressValue then
			TweenService:Create(progressValue, FastTI, {Value = 0}):Play()
		end
		TweenService:Create(holder, FastTI, {Size = UDim2.fromScale(1, 1)}):Play()
	end)

	-- Cleanup
	prompt.PromptHidden:Wait()
	holdBegan:Disconnect()
	holdEnded:Disconnect()

	local outTween = TweenService:Create(holder, FastTI, {Size = UDim2.fromScale(0, 0)})
	outTween:Play()
	outTween.Completed:Wait()
	promptUI:Destroy()
end

ProximityPromptService.PromptShown:Connect(onPromptShown)