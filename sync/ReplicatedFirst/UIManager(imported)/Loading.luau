-- Services
local RPS = game:GetService("ReplicatedStorage")
local RPF = game:GetService("ReplicatedFirst")
local TS = game:GetService("TweenService")
local CP = game:GetService("ContentProvider")

-- Dependancies
local Storage = nil
local keySettings = nil

local plr = game.Players.LocalPlayer
local playerGUI = nil
local ProgressCircle = nil
local images = nil

local ui = nil
local frame = nil
local Left = nil
local Right = nil
local TextLabel = nil
local ImageLabel = nil

local event = nil

local TIS = {
	TweenInfo.new(
		1.85,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	),
	TweenInfo.new(
		0.75,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	),
	TweenInfo.new( -- slow pulse
		1.5, -- Duration of each pulse (in seconds)
		Enum.EasingStyle.Sine, -- Easing style (smooth pulse)
		Enum.EasingDirection.Out, -- Easing direction (starting from low to high)
		-1, -- Loop count (-1 means infinite loop)
		true, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),
	TweenInfo.new( -- quick pulse
		0.5, -- Duration of each pulse (in seconds)
		Enum.EasingStyle.Sine, -- Easing style (smooth pulse)
		Enum.EasingDirection.Out, -- Easing direction (starting from low to high)
		0, -- Loop count (-1 means infinite loop)
		false, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),
	TweenInfo.new( -- tint removal
		1.5, -- Duration of each pulse (in seconds)
		Enum.EasingStyle.Quad, -- Easing style (smooth pulse)
		Enum.EasingDirection.Out, -- Easing direction (starting from low to high)
		0, -- Loop count (-1 means infinite loop)
		false, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),
	TweenInfo.new( -- quick pulse appear
		0.35, -- Duration of each pulse (in seconds)
		Enum.EasingStyle.Sine, -- Easing style (smooth pulse)
		Enum.EasingDirection.Out, -- Easing direction (starting from low to high)
		0, -- Loop count (-1 means infinite loop)
		true, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),
}

-- Variables
local TES = {}
local LoadCircle3 = nil

-- Constants
local DEFAULTS = {
	LeftStart = UDim2.new(-0.35, 0, 0.5, 0),
	RightStart = UDim2.new(1.35, 0, 0.5, 0),
	LeftEnd = UDim2.new(0.55, 0, 0.5, 0),
	RightEnd = UDim2.new(0.45, 0, 0.5, 0),
	ImageStartSize = UDim2.new(0.5, 0, 0.4, 0),
	ImagePulseAmt = Vector2.new(0.05, 0.05),
	ImageOGTP = 0,
	ImageTPAmt = 0.6,
	FrameStartTint = 1,
}

local texts = {
	{"Game_Assets_SurvivorHUD", 1},
	{"Game_Assets_Physics", 0.5},
	{"Game_Assets_Maps", 1.65},
	{"World_Assets_Builds", 1.25},
	{"World_Assets_Environment", 2},
	--{"Visual_Assets_Audio", 1},
	{"Visual_Assets_Images", 1},
	{"Visual_Assets_Special_Effects", 1},
	{"Visual_Assets_Text_Files", 1},
	{"Wrapping things up", 2},
}

-- Initialization
local loading = {}

-- Global Variables
loading.Ready = Instance.new("BindableEvent")
loading.isLoading = false

-- Local Variables
local function startUpCircle()
	-- Delete old one if exists
	if LoadCircle3 then
		LoadCircle3:Destroy()
		LoadCircle3 = nil
	end

	-- New progress circle
	LoadCircle3 = ProgressCircle.new({BGColor = Color3.fromRGB(35, 35, 40), Position = UDim2.new(0.5, 0, 0.695, 0), Parent = frame, Transparency = 0, Zindex = 11})
	LoadCircle3.Color = Color3.new(1, 1, 1)
	LoadCircle3.BGRoundness = 0.1
	LoadCircle3.AnchorPoint = Vector2.new(0.5, 0.5) -- By default the anchor point is (0, 1) set it to (0, 0) if you need to
	LoadCircle3.Thickness = 0.15
	LoadCircle3.CircleSize = 0.5
	LoadCircle3.Transparency = 1
	--LoadCircle3.Instance.Parent = game.Players.LocalPlayer.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Frame")
	LoadCircle3:Animate("InfSpin3")
	
	-- Tween in
	for alpha = 1, 0, -0.05 do
		if LoadCircle3 then
			LoadCircle3.Transparency = alpha
			task.wait()
		else
			break
		end
	end
end

local function stopCircle()
	if LoadCircle3 then
		for alpha = 0, 1, 0.05 do
			if LoadCircle3 then
				LoadCircle3.Transparency = alpha
				task.wait()
			else
				return
			end
		end
		LoadCircle3:Destroy()
		LoadCircle3 = nil
	end
end



local function pulseImage(img, tinted)
	if not img then return end
	if TES[ImageLabel] then
		if TES[ImageLabel].PlaybackState == Enum.PlaybackState.Playing then
			TES[ImageLabel]:Cancel()
			TES[ImageLabel] = nil
		end
	end

	ImageLabel.Size = DEFAULTS.ImageStartSize
	ImageLabel.Image = img
	
	if TES[frame.FTint] then
		if TES[frame.FTint].PlaybackState == Enum.PlaybackState.Playing then
			TES[frame.FTint]:Cancel()
			TES[frame.FTint] = nil
		end
	end
	frame.FTint.BackgroundTransparency = DEFAULTS.FrameStartTint
	TES[frame.FTint] = TS:Create(frame.FTint, TIS[5], {BackgroundTransparency = 1})
	TES[frame.FTint]:Play()
	
	if not tinted then
		ImageLabel.Tint.Image = ""
		ImageLabel.Tint.ImageTransparency = 1
		TES[ImageLabel] = TS:Create(ImageLabel, TIS[3], {Size = UDim2.new(DEFAULTS.ImageStartSize.X.Scale + DEFAULTS.ImagePulseAmt.X, 0, DEFAULTS.ImageStartSize.Y.Scale + DEFAULTS.ImagePulseAmt.Y, 0), ImageTransparency = DEFAULTS.ImageTPAmt})
		TES[ImageLabel]:Play()
	else
		if TES[ImageLabel.Tint] then
			if TES[ImageLabel.Tint].PlaybackState == Enum.PlaybackState.Playing then
				TES[ImageLabel.Tint]:Cancel()
				TES[ImageLabel.Tint] = nil
			end
		end
		ImageLabel.Tint.Image = tinted
		ImageLabel.Tint.ImageTransparency = 0
		ImageLabel.ImageTransparency = 0
		ImageLabel.ImageTransparency = 0
		
		TES[ImageLabel.Tint] = TS:Create(ImageLabel.Tint, TIS[5], {ImageTransparency = 1})
		TES[ImageLabel] = TS:Create(ImageLabel, TIS[6], {Size = UDim2.new(DEFAULTS.ImageStartSize.X.Scale + DEFAULTS.ImagePulseAmt.X, 0, DEFAULTS.ImageStartSize.Y.Scale + DEFAULTS.ImagePulseAmt.Y, 0)})
		
		TES[ImageLabel.Tint]:Play()
		TES[ImageLabel]:Play()
		
		local newEv = Instance.new("BindableEvent")
		local con1, con2 = nil
		local canContinue = true
		con1 = event.Event:Connect(function()
			con1:Disconnect()
			con2:Disconnect()
			canContinue = false
			newEv:Fire()
		end)
		con2 = TES[ImageLabel].Completed:Connect(function()
			--print("donned")
			con1:Disconnect()
			con2:Disconnect()
			newEv:Fire()
		end)
		newEv.Event:Wait()
		newEv:Destroy()
		if not canContinue then return end
		
		TES[ImageLabel] = TS:Create(ImageLabel, TIS[3], {Size = UDim2.new(DEFAULTS.ImageStartSize.X.Scale + DEFAULTS.ImagePulseAmt.X, 0, DEFAULTS.ImageStartSize.Y.Scale + DEFAULTS.ImagePulseAmt.Y, 0), ImageTransparency = DEFAULTS.ImageTPAmt})
		TES[ImageLabel]:Play()
	end
end

local function stopPulse()
	if TES[ImageLabel] then
		if TES[ImageLabel].PlaybackState == Enum.PlaybackState.Playing then
			TES[ImageLabel]:Cancel()
			TES[ImageLabel] = nil
		end
	end
	if TES[ImageLabel.Tint] then
		if TES[ImageLabel.Tint].PlaybackState == Enum.PlaybackState.Playing then
			TES[ImageLabel.Tint]:Cancel()
			TES[ImageLabel.Tint] = nil
		end
	end
	
	-- flash a bit
	ImageLabel.Tint.ImageTransparency = 0.35
	ImageLabel.ImageTransparency = DEFAULTS.ImageOGTP
	
	TES[ImageLabel] = TS:Create(ImageLabel, TIS[4], {Size = UDim2.new(DEFAULTS.ImageStartSize.X.Scale + (DEFAULTS.ImagePulseAmt.X*2), 0, DEFAULTS.ImageStartSize.Y.Scale + (DEFAULTS.ImagePulseAmt.Y*2), 0), ImageTransparency = DEFAULTS.ImageTPAmt})
	TES[ImageLabel]:Play()

	local con = nil
	local canContinue = true
	con = event.Event:Connect(function()
		con:Disconnect()
		canContinue = false
	end)
	task.wait(2.5)
	if con then
		con:Disconnect()
	end
	if not canContinue then return end
	TES[ImageLabel] = nil
	
	task.wait(0.1)

	for alpha = ImageLabel.ImageTransparency, 1, 0.025 do
		if not TES[ImageLabel] then
			ImageLabel.ImageTransparency = alpha
			ImageLabel.Tint.ImageTransparency = math.clamp(0.35 + alpha, 0, 1)
			--print(ImageLabel.Tint.ImageTransparency)
			task.wait()
		else
			return
		end
	end
	if not TES[ImageLabel] then
		ImageLabel.ImageTransparency = 1
		ImageLabel.Tint.ImageTransparency = 1
	end
end

local function loadTexts(sequence)
	local divTime = 15/#(sequence or texts)
	local count = 1

	TextLabel.Text = ""
	TextLabel.Visible = true
	for i, v in pairs(sequence or texts) do
		for i = 1, 5 do
			if count == #(sequence or texts) then 
				if i % 2 == 0 then
					TextLabel.Text = v[1]..".."
				else
					TextLabel.Text = v[1].."..."
				end
			else
				if i % 2 == 0 then
					TextLabel.Text = "Loading "..v[1]..".."
				else
					TextLabel.Text = "Loading "..v[1].."..."
				end
			end
			--local LTE = TS:Create(ui.ackG.Main, TIS[2], {Size = UDim2.new(1, 0, ui.ackG.Main.Size.Y.Scale, 0)})
			--LTE:Play()
			wait((divTime / 5) * (v[2] or v))
			--ui.ackG.Main.Size = UDim2.new(0, 0, ui.ackG.Main.Size.Y.Scale, 0)
		end
		count += 1
	end
	TextLabel.Visible = false
end

-- Global Functions
function loading.tweenInCover()
	if TES[Left] then
		if TES[Left].PlaybackState == Enum.PlaybackState.Playing then
			TES[Left]:Cancel()
		end
	end
	if TES[Right] then
		if TES[Right].PlaybackState == Enum.PlaybackState.Playing then
			TES[Right]:Cancel()
		end
	end

	TES[Left] = TS:Create(Left, TIS[1], {Position = DEFAULTS.LeftEnd})
	TES[Right] = TS:Create(Right, TIS[1], {Position = DEFAULTS.RightEnd})
	TES[Left]:Play()
	TES[Right]:Play()
end

function loading.tweenOutCover()
	if TES[Left] then
		if TES[Left].PlaybackState == Enum.PlaybackState.Playing then
			TES[Left]:Cancel()
		end
	end
	if TES[Right] then
		if TES[Right].PlaybackState == Enum.PlaybackState.Playing then
			TES[Right]:Cancel()
		end
	end

	TES[Left] = TS:Create(Left, TIS[1], {Position = DEFAULTS.LeftStart})
	TES[Right] = TS:Create(Right, TIS[1], {Position = DEFAULTS.RightStart})
	TES[Left]:Play()
	TES[Right]:Play()
end

function loading.load(image, tinted)
	if loading.isLoading then return end
	event:Fire()
	loading.isLoading = true
	coroutine.wrap(function()
		startUpCircle()
	end)()
	loading.tweenInCover()
	pulseImage(image, tinted)
	--if typeof(tim) == "number" then
	--	task.wait(tim) 
	--elseif typeof(tim) == "string" and tim == "gameLoad" then
	--	repeat task.wait(0.1) until CP.AssetQueue > 0 
	--end
end

function loading.stop()
	stopPulse()
	coroutine.wrap(function()
		stopCircle()
	end)()
	repeat wait() until not LoadCircle3
	loading.tweenOutCover()
	loading.isLoading = false
end

function loading.setup(skip)
	-- Remove the default loading screen
	RPF:RemoveDefaultLoadingScreen()
	
	-- load in depedancies
	Storage = RPS:WaitForChild("ClientStorage")
	keySettings = require(Storage.Info.KeybindsMaster)
	
	playerGUI = plr:WaitForChild("PlayerGui")
	ProgressCircle = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("CircularProgress")) -- Rounded Circular Progress module
	images = require(Storage:WaitForChild("Info"):WaitForChild("Images")) -- Rounded Circular Progress module

	ui = playerGUI:WaitForChild("LoadingScreen")
	frame = ui:WaitForChild("MainFrame")
	Left = frame.Cover:WaitForChild("Left")
	Right = frame.Cover:WaitForChild("Right")
	TextLabel = frame:WaitForChild("TextLabel")
	ImageLabel = frame:WaitForChild("ImageLabel")
	
	event = Instance.new("BindableEvent")
	
	-- reset everything
	Left.Position = DEFAULTS.LeftEnd
	Right.Position = DEFAULTS.RightEnd
	TextLabel.Visible = false
	ImageLabel.ImageTransparency = DEFAULTS.ImageOGTP
	ImageLabel.Tint.ImageTransparency = 1
	
	-- start loading
	loading.load(images.Logos.GameLogo, images.Logos.TintedGameLogo)
	
	-- do loading stuff
	repeat task.wait(0.1) --[[print(CP.RequestQueueSize) print(game:IsLoaded())]] until skip or (CP.RequestQueueSize <= 0 and game:IsLoaded())
	--local assets = {}
	--for i, v in pairs(Storage.Animations:GetDescendants()) do
	--	if v:IsA("Animation") then
	--		table.insert(assets, v)
	--	end
	--end
	--CP:PreloadAsync(assets)
	if not skip then
		-- buffer
		loadTexts()
		
		-- stop loading
		--loading.stop()
	else
		task.wait(0.5)
	end
	
	-- ur done
	--print("loaded everything")
	loading.Ready:Fire()
end

return loading