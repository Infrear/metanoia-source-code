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
local itemAddedEv = Storage.Events.Remotes.ItemAddedEvent

local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("ItemIndicator")

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
}
local Tweens = {}

-- Constants
local BUTTON_WIDTH = 0.8
local BUTTON_HEIGHT = 0.05
local BUTTON_SPACING = 5
local BUTTON_FADE_DELAY = 2.5
local BUTTON_FADE_DURATION = 2

-- Initialization
local itemindicator = {}

-- Local Functions
local function tweenInButtonItems(item, amtAdded)
	--print(item)
	--print(amtAdded)
	if not itemInfo[item] then return end
	if amtAdded == 0 then return end
	-- Check if a button with the same item text already exists
	local positive = amtAdded >= 0
	local found = frame:FindFirstChild(item)
	if found and found:GetAttribute("Positive") ~= positive then
		found = nil
	end
	
	local button = found or script:WaitForChild("Blot"):Clone()
	button.Name = item

	local origAmt = amtAdded
	if found then
		found:SetAttribute("Positive", positive)
		found:SetAttribute("Amount", (amtAdded + found:GetAttribute("Amount")))
		origAmt = button:GetAttribute("Amount")
		if Tweens[found] then
			for i, v in pairs(Tweens[found]) do
				v:Cancel()
			end
		end
	else
		button:SetAttribute("Amount", amtAdded)
		button:SetAttribute("Positive", positive)
	end

	--print(item)
	--print(found)
	local imageLabel, textlabel1 = button.Img, button.Textlabel
	imageLabel.Image = itemInfo[item].Image

	--button.Text = "+"..item.."x"..amtAdded
	
	if positive then
		textlabel1.Text = "+"..origAmt.." "..item
	else
		textlabel1.Text = origAmt.." "..item
	end

	button.Parent = frame
	imageLabel.ImageTransparency = script.Blot.Img.ImageTransparency
	textlabel1.TextTransparency = script.Blot.Textlabel.TextTransparency
	task.wait(BUTTON_FADE_DELAY)
	if button:GetAttribute("Amount") ~= origAmt then
		return
	end
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

	for i, v in pairs(fadeProperties) do
		button[i] = script.Blot[i]
	end
	local buttonFadeTween = TS:Create(button, fadeTweenInfo, fadeProperties)
	buttonFadeTween:Play()
	table.insert(Tweens[button], buttonFadeTween)

	local con
	con = buttonFadeTween.Completed:Connect(function()
		con:Disconnect()
		if button:GetAttribute("Amount") == origAmt then
			button:Destroy()
		end
	end)
end

-- Global Functions
function itemindicator.setup()
	frame:ClearAllChildren()

	local listLayout = script:FindFirstChildOfClass("UIListLayout"):Clone()
	listLayout.Parent = frame

	itemAddedEv.OnClientEvent:Connect(tweenInButtonItems)
end

return itemindicator
