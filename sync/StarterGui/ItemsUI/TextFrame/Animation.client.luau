local TextFrame = script.Parent
local ItemsUI = TextFrame.Parent

local SparkleSound = TextFrame:FindFirstChild("Sparkle")

local Letters = {
	TextFrame:FindFirstChild("I_Label"),
	TextFrame:FindFirstChild("T_Label"),
	TextFrame:FindFirstChild("E_Label"),
	TextFrame:FindFirstChild("M_Label")
}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Animation settings
local GRADIENT_SPEED = 0.5
local BOUNCE_SCALE = 1.6
local ORIGINAL_SCALE = 1
local BOUNCE_DURATION = 0.3
local BOUNCE_INTERVAL = 4
local DELAY_PER_LETTER = 0.15

local COLOR_PURPLE = Color3.fromRGB(128, 0, 128)
local COLOR_BLACK = Color3.fromRGB(0, 0, 0)

for _, Letter in ipairs(Letters) do
	if not Letter:FindFirstChildOfClass("UIScale") then
		local UIScale = Instance.new("UIScale")
		UIScale.Scale = ORIGINAL_SCALE
		UIScale.Parent = Letter
	end
end

-- Function to lerp between purple and black
local function GetGradientColor(progress)
	return COLOR_PURPLE:Lerp(COLOR_BLACK, progress)
end

local function BounceLetter(letter)
	local UIScale = letter:FindFirstChildOfClass("UIScale")
	if not UIScale then return end

	-- Tween to larger scale
	local TweenInfoGrow = TweenInfo.new(
		BOUNCE_DURATION / 2, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	)

	local GrowTween = TweenService:Create(UIScale, TweenInfoGrow, {Scale = BOUNCE_SCALE})
	GrowTween:Play()
	GrowTween.Completed:Wait()

	-- Tween back to original scale
	local TweenInfoShrink = TweenInfo.new(
		BOUNCE_DURATION / 2, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.In
	)

	local ShrinkTween = TweenService:Create(UIScale, TweenInfoShrink, {Scale = ORIGINAL_SCALE})
	ShrinkTween:Play()
	ShrinkTween.Completed:Wait()
end

-- Constant purple to black gradient animation
task.spawn(function()
	local StartTime = tick()

	RunService.RenderStepped:Connect(function()
		local Elapsed = tick() - StartTime

		-- Apply gradient constantly
		for i, Letter in ipairs(Letters) do
			local LetterProgress = (i - 1) / (#Letters - 1)

			-- Create a wave effect
			local Wave = (math.sin(Elapsed * GRADIENT_SPEED + LetterProgress * math.pi * 2) + 1) / 2
			Letter.TextColor3 = GetGradientColor(Wave)
		end
	end)
end)

-- Bounce animation cycle
task.spawn(function()
	while true do

		if SparkleSound and ItemsUI.Enabled then
			SparkleSound:Play()
		end

		for i, Letter in ipairs(Letters) do
			task.spawn(function()
				task.wait(DELAY_PER_LETTER * (i - 1))
				BounceLetter(Letter)
			end)
		end

		task.wait(BOUNCE_INTERVAL)
	end
end)