local TweenService = game:GetService("TweenService")

-- UI References
local ItemsUI = script.Parent.Parent
local SquadFrame = script.Parent
local LeaderFrame = SquadFrame.LeaderFrame
local SquadNameLabel = LeaderFrame:FindFirstChild("SquadName")

local AllBoxes = {
	SquadFrame.LeaderFrame,
	SquadFrame.MemberOneFrame,
	SquadFrame.MemberTwoFrame,
	SquadFrame.MemberThreeFrame
}

-- Animation Settings
local SLIDE_DURATION = 0.8
local FADE_DELAY = 0.1
local PULSE_INTERVAL = 1.5
local PULSE_SCALE = 1.15
local SHINE_INTERVAL = 3
local SHINE_DURATION = 1.2

-- Position Settings
local OFF_SCREEN_POSITION = UDim2.new(-0.4, 0, 0.307, 0)
local ON_SCREEN_POSITION = UDim2.new(-0.005, 0, 0.307, 0)

-- Initialize UIScale for pulse effect
local function InitializePulseEffect()
	if SquadNameLabel and not SquadNameLabel:FindFirstChildOfClass("UIScale") then
		local UIScale = Instance.new("UIScale")
		UIScale.Scale = 1
		UIScale.Parent = SquadNameLabel
	end
end

-- Initialize shine gradient effect
local function InitializeShineEffect()
	if not SquadNameLabel then return end

	local ShineGradient = Instance.new("UIGradient")
	ShineGradient.Name = "ShineGradient"
	ShineGradient.Rotation = 0

	local ColorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	ShineGradient.Color = ColorSequence
	ShineGradient.Offset = Vector2.new(-1.5, 0)
	ShineGradient.Parent = SquadNameLabel
end

-- Store original transparencies for all visible boxes
local function StoreOriginalTransparencies(VisibleBoxes)
	local OriginalTransparencies = {}

	for _, Box in ipairs(VisibleBoxes) do
		OriginalTransparencies[Box] = {}
		OriginalTransparencies[Box].BackgroundTransparency = Box.BackgroundTransparency
		Box.BackgroundTransparency = 1

		for _, Descendant in ipairs(Box:GetDescendants()) do
			OriginalTransparencies[Descendant] = {}

			if Descendant:IsA("GuiObject") then
				OriginalTransparencies[Descendant].BackgroundTransparency = Descendant.BackgroundTransparency
				Descendant.BackgroundTransparency = 1
			end

			if Descendant:IsA("TextLabel") or Descendant:IsA("TextButton") then
				OriginalTransparencies[Descendant].TextTransparency = Descendant.TextTransparency
				Descendant.TextTransparency = 1
			end

			if Descendant:IsA("ImageLabel") or Descendant:IsA("ImageButton") then
				OriginalTransparencies[Descendant].ImageTransparency = Descendant.ImageTransparency
				Descendant.ImageTransparency = 1
			end
		end
	end

	return OriginalTransparencies
end

-- Get all visible boxes
local function GetVisibleBoxes()
	local VisibleBoxes = {}

	for _, Box in ipairs(AllBoxes) do
		if Box.Visible then
			table.insert(VisibleBoxes, Box)
		end
	end

	return VisibleBoxes
end

-- Fade in a single box with its descendants
local function FadeInBox(Box, OriginalTransparencies)
	local TweenInfoFade = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	)

	local FadeTween = TweenService:Create(Box, TweenInfoFade, {
		BackgroundTransparency = OriginalTransparencies[Box].BackgroundTransparency
	})
	FadeTween:Play()

	for _, Descendant in ipairs(Box:GetDescendants()) do
		if Descendant:IsA("GuiObject") and OriginalTransparencies[Descendant].BackgroundTransparency then
			TweenService:Create(Descendant, TweenInfoFade, {
				BackgroundTransparency = OriginalTransparencies[Descendant].BackgroundTransparency
			}):Play()
		end

		if (Descendant:IsA("TextLabel") or Descendant:IsA("TextButton")) and OriginalTransparencies[Descendant].TextTransparency then
			TweenService:Create(Descendant, TweenInfoFade, {
				TextTransparency = OriginalTransparencies[Descendant].TextTransparency
			}):Play()
		end

		if (Descendant:IsA("ImageLabel") or Descendant:IsA("ImageButton")) and OriginalTransparencies[Descendant].ImageTransparency then
			TweenService:Create(Descendant, TweenInfoFade, {
				ImageTransparency = OriginalTransparencies[Descendant].ImageTransparency
			}):Play()
		end
	end
end

-- Main slide animation
local function PlaySlideAnimation()
	SquadFrame.Position = OFF_SCREEN_POSITION

	local VisibleBoxes = GetVisibleBoxes()
	local OriginalTransparencies = StoreOriginalTransparencies(VisibleBoxes)

	local TweenInfoSlide = TweenInfo.new(
		SLIDE_DURATION,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	)

	local SlideTween = TweenService:Create(SquadFrame, TweenInfoSlide, {Position = ON_SCREEN_POSITION})
	SlideTween:Play()

	for i, Box in ipairs(VisibleBoxes) do
		task.spawn(function()
			task.wait(FADE_DELAY * (i - 1))
			FadeInBox(Box, OriginalTransparencies)
		end)
	end
end

-- Heartbeat pulse effect
local function StartPulseEffect()
	if not SquadNameLabel then return end

	task.spawn(function()
		while true do
			task.wait(PULSE_INTERVAL)

			if ItemsUI.Enabled and LeaderFrame.Visible then
				local UIScale = SquadNameLabel:FindFirstChildOfClass("UIScale")
				if not UIScale then continue end

				-- First beat
				local TweenInfoBeat1 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local Beat1Tween = TweenService:Create(UIScale, TweenInfoBeat1, {Scale = PULSE_SCALE})
				Beat1Tween:Play()
				Beat1Tween.Completed:Wait()

				local TweenInfoReturn1 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local Return1Tween = TweenService:Create(UIScale, TweenInfoReturn1, {Scale = 1})
				Return1Tween:Play()
				Return1Tween.Completed:Wait()

				task.wait(0.1)

				-- Second beat
				local TweenInfoBeat2 = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local Beat2Tween = TweenService:Create(UIScale, TweenInfoBeat2, {Scale = PULSE_SCALE})
				Beat2Tween:Play()
				Beat2Tween.Completed:Wait()

				local TweenInfoReturn2 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local Return2Tween = TweenService:Create(UIScale, TweenInfoReturn2, {Scale = 1})
				Return2Tween:Play()
			end
		end
	end)
end

-- Shine gradient effect
local function StartShineEffect()
	if not SquadNameLabel then return end

	local ShineGradient = SquadNameLabel:FindFirstChild("ShineGradient")
	if not ShineGradient then return end

	task.spawn(function()
		while true do
			task.wait(SHINE_INTERVAL)

			if ItemsUI.Enabled and LeaderFrame.Visible then
				ShineGradient.Offset = Vector2.new(-1.5, 0)

				local TweenInfoShine = TweenInfo.new(
					SHINE_DURATION,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.InOut
				)

				local ShineTween = TweenService:Create(ShineGradient, TweenInfoShine, {Offset = Vector2.new(1.5, 0)})
				ShineTween:Play()
			end
		end
	end)
end

-- Initialize all effects
InitializePulseEffect()
InitializeShineEffect()

-- Start continuous effects
StartPulseEffect()
StartShineEffect()

-- Listen for when ItemsUI is enabled
ItemsUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if ItemsUI.Enabled then
		PlaySlideAnimation()
	end
end)

-- Play animation if UI is already enabled
if ItemsUI.Enabled then
	task.wait(0.1)
	PlaySlideAnimation()
end