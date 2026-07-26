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
local statusUpdEv = Storage.Events.Remotes.StatusUpdateEvent
local statusEffects = require(Storage.Info.StatusEffects)

local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("StatusIndicator")
local gridLayout = nil

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[2] = TweenInfo.new(
		0.65,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		-1,
		true
	),
	[3] = TweenInfo.new(
		0.65,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
}

-- Local Variables
local Tweens = {}
local uTweens = {}
local evs = {}
local GTweens = {}
local GMode = "small"

-- Constants
local BUTTON_FADE_DURATION = 2

-- Initialization
local itemindicator = {}

-- Local Functions
local function updGrid()
	if gridLayout then
		local tween = nil
		if #frame:GetChildren() - 2 > 3 and GMode == "big" then
			GMode = "small"
			tween = TS:Create(gridLayout, TIS[3], {CellPadding = script:WaitForChild("UIGridLayout").CellPadding, CellSize = script:WaitForChild("UIGridLayout").CellSize})
		elseif #frame:GetChildren() - 2 <= 3 and GMode == "small" then
			--print("changed")
			GMode = "big"
			tween = TS:Create(gridLayout, TIS[3], {CellPadding = UDim2.new(0, 0, 0, 0), CellSize = UDim2.new(script:WaitForChild("UIGridLayout").CellSize.X.Scale*2, 0, script:WaitForChild("UIGridLayout").CellSize.Y.Scale*2, 0)})
		else
			return
		end
		if GTweens then
			for i, v in pairs(GTweens) do
				if v.PlaybackState == Enum.PlaybackState.Playing then
					v:Cancel()
				end
			end
		end
		table.insert(GTweens, tween)
		tween:Play()
	end
end

local function runUrgent(button, start)
	if start then
		if uTweens[button] then
			for i, v in pairs(uTweens[button]) do
				if v.PlaybackState == Enum.PlaybackState.Playing then
					v:Cancel()
				end
			end
		else
			uTweens[button] = {}
		end
		button.Img.Size = UDim2.new(1, 0, 1, 0)
		button.Img.ImageColor3 = Color3.new(1, 1, 1)
		local tween = TS:Create(button.Img, TIS[2], {Size = UDim2.new(1.25, 0, 1.25, 0), ImageColor3 = Color3.new(1, 0, 0)})
		table.insert(uTweens[button], tween)
		tween:Play()
	else
		if uTweens[button] then
			for i, v in pairs(uTweens[button]) do
				v:Cancel()
			end
		end
		button.Img.Size = UDim2.new(1, 0, 1, 0)
		button.Img.ImageColor3 = Color3.new(1, 1, 1)
	end
end

local function tweenInButtonStatuses(newStatus, add, tim, urgent)
	local found = frame:FindFirstChild(newStatus)
	
	if add and not found then -- create object
		local button = found or script:WaitForChild("Elot"):Clone()
		button.Name = newStatus
		button.LayoutOrder = statusEffects[newStatus].Priority
		
		evs[button] = evs[button] or Instance.new("BindableEvent")
		
		--print(item)
		--print(found)
		local imageLabel, textlabel1 = button.Img, button.Textlabel
		imageLabel.Image = statusEffects[newStatus].Image
		
		if statusEffects[newStatus].Timed and tim then
			textlabel1.Visible = true
			local wo, w = math.modf(tim)
			if w ~= 0 then
				textlabel1.Text = math.round(tim*10)/10
			else
				textlabel1.Text = tim..".0"
			end
		else
			textlabel1.Visible = false
		end

		button.Parent = frame
		
		if urgent then
			runUrgent(button, urgent.Start)
		end
	elseif not add and found then -- remove object
		local button = found
		
		local imageLabel, textlabel1 = button.Img, button.Textlabel
		imageLabel.Image = statusEffects[newStatus].Image

		
		local fadeTweenInfo = TweenInfo.new(BUTTON_FADE_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		local fadeProperties = {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}

		local imageFadeTween = TS:Create(imageLabel, fadeTweenInfo, { ImageTransparency = 1 })

		local text1FadeTween = TS:Create(textlabel1, fadeTweenInfo, { TextTransparency = 1 })


		Tweens[button] = {imageFadeTween, text1FadeTween}
		imageFadeTween:Play()
		text1FadeTween:Play()
		
		local con1, con2
		
		con1 = evs[button].Event:Connect(function()
			con2:Disconnect()
			con1:Disconnect()
			if imageFadeTween then
				imageFadeTween:Cancel()
			end
		end)
		
		con2 = imageFadeTween.Completed:Connect(function()
			con1:Disconnect()
			con2:Disconnect()
			if evs[button] then
				evs[button]:Destroy()
			end
			button:Destroy()
		end)
		if button:GetAttribute("Urgent") then
			runUrgent(button, false)
		end
	elseif add and found then -- add time to existing object
		local button = found
		if found.Img.ImageTransparency > 0 then
			for i, v in pairs(Tweens) do
				if v.PlaybackState == Enum.PlaybackState.Playing then
					v:Cancel()
				end
			end


			local imageLabel, textlabel1 = button.Img, button.Textlabel
			imageLabel.Image = statusEffects[newStatus].Image

			imageLabel.ImageTransparency = script.Elot.Img.ImageTransparency
			textlabel1.TextTransparency = script.Elot.Textlabel.TextTransparency
		end

		if evs[button] then
			evs[button]:Fire()
		end
		if urgent then
			runUrgent(button, urgent.Start)
		end
	end
	--end)()
end

-- Global Functions
function itemindicator.setup()
	frame:ClearAllChildren()

	local aspctR = script:FindFirstChildOfClass("UIAspectRatioConstraint"):Clone()
	aspctR.Parent = frame
	
	gridLayout = script:FindFirstChildOfClass("UIGridLayout"):Clone()
	gridLayout.Parent = frame

	statusUpdEv.OnClientEvent:Connect(tweenInButtonStatuses)
	
	frame.ChildAdded:Connect(function(d)
		updGrid()
	end)
	
	frame.ChildRemoved:Connect(function(d)
		updGrid()
	end)
	
	-- auto connect
	local hungry = false
	local hhungry = false
	local thirsty = false
	local hthirsty = false
	hum:GetAttributeChangedSignal("Hunger"):Connect(function()
		local nval = (hum:GetAttribute("Hunger") <= 20)
		local hnval = (hum:GetAttribute("Hunger") <= 0)
		if hungry ~= nval or hhungry ~= hnval then
			tweenInButtonStatuses("Hunger", nval, nil, {["Start"] = hnval})
		end
		hungry = nval
		hhungry = hnval
	end)
	
	hum:GetAttributeChangedSignal("Thirst"):Connect(function()
		local nval = (hum:GetAttribute("Thirst") <= 20)
		local hnval = (hum:GetAttribute("Thirst") <= 0)
		if thirsty ~= nval or hthirsty ~= hnval then
			tweenInButtonStatuses("Thirst", nval, nil, {["Start"] = hnval})
		end
		thirsty = nval
		hthirsty = hnval
	end)
end

return itemindicator
