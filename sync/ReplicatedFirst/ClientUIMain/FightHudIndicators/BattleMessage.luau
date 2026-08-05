--[[
	BattleMessage
	--------------
	Drives the passive top-right "Nice! The enemy's down!" style banner (Persona-style) that lives
	at CombatOverlays.Holder.Message (TextboxImg > TextFrame > TextLabel, plus a CharImg portrait).
	No input required -- it just pulses in place and fades itself out after a duration.

	Usage:
		BattleMessage.Show("Nice! The enemy's down!", "rbxassetid://12345", 2.5)
		BattleMessage.Show("Golem used Rock Smash!") -- charImage/duration are optional

	Calling Show() again while one is already up cancels the old one cleanly (no leftover tweens).
]]

local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")

local plr = PLRS.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local Storage = RPS:WaitForChild("ClientStorage")
local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings

local AnimsManager = require(script.Parent.Parent.GUIMaster.Animations)

local BattleMessage = {}

-- CombatOverlays is the pending rename of SkillsMenu -- check both so this doesn't break
-- the moment the rename happens (or before it does)
local function getOverlaysGui()
	return plrGui:FindFirstChild("CombatOverlays") or plrGui:WaitForChild("SkillsMenu")
end

local messageFrame, textboxImg, textFrame, textLabel, charImg

local function bindRefs()
	if messageFrame and messageFrame.Parent then return end
	local holder = getOverlaysGui():WaitForChild("Holder")
	messageFrame = holder:WaitForChild("Message")
	textboxImg = messageFrame:WaitForChild("TextboxImg")
	textFrame = textboxImg:WaitForChild("TextFrame")
	textLabel = textFrame:WaitForChild("TextLabel")
	charImg = messageFrame:WaitForChild("CharImg")
end

-- UIScale drives the pulse so TextboxImg + CharImg scale together around the frame, instead of
-- fighting each other's independent Size properties
local function getScaleObj()
	local existing = messageFrame:FindFirstChildOfClass("UIScale")
	if existing then return existing end
	local s = Instance.new("UIScale")
	s.Scale = 1
	s.Parent = messageFrame
	return s
end

local PULSE_TWEEN_INFO = TweenInfo.new(
	0.55/combatSettings.CombatSpeedMultiplier,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1, -- loop forever until we :Cancel() it
	true -- reverses back down, so it breathes in/out rather than snapping
)

local activeToken = nil -- bumped every Show() call so old coroutines/tweens know to bail

function BattleMessage.Show(text, charImageId, duration)
	bindRefs()

	local myToken = {}
	activeToken = myToken

	-- kill anything still running from a previous call
	local scaleObj = getScaleObj()
	for _, t in ipairs(TS:GetTweens()) do
		if t.Instance == scaleObj or t.Instance == textboxImg or t.Instance == charImg then
			t:Cancel()
		end
	end

	textLabel.Text = text or ""
	if charImageId then
		charImg.Image = charImageId
	end

	scaleObj.Scale = 0.6
	textboxImg.ImageTransparency = 1
	charImg.ImageTransparency = 1
	messageFrame.Visible = true

	-- Entrance: punch in with a quick overshoot-feeling fade + scale-up
	local inTween = TS:Create(scaleObj, AnimsManager.STIS.FadeInMid or AnimsManager.STIS.FadeIn, {Scale = 1})
	inTween:Play()
	TS:Create(textboxImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 0}):Play()
	TS:Create(charImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 0}):Play()
	inTween.Completed:Wait()

	if activeToken ~= myToken then return end -- a newer Show() call took over while we waited

	-- Continuous gentle breathing pulse until dismissed
	local pulseTween = TS:Create(scaleObj, PULSE_TWEEN_INFO, {Scale = 1.08})
	pulseTween:Play()

	task.delay((duration or 2.5)/combatSettings.CombatSpeedMultiplier, function()
		if activeToken ~= myToken then return end -- superseded, let the newer one own cleanup

		pulseTween:Cancel()

		local outTween = TS:Create(scaleObj, AnimsManager.STIS.FadeIn, {Scale = 0.7})
		outTween:Play()
		TS:Create(textboxImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 1}):Play()
		TS:Create(charImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 1}):Play()
		outTween.Completed:Wait()

		if activeToken == myToken then
			messageFrame.Visible = false
			activeToken = nil
		end
	end)
end

-- Immediately dismiss whatever's showing (e.g. if the player does something that should
-- interrupt it), skipping the rest of its duration
function BattleMessage.Dismiss()
	if not activeToken then return end
	activeToken = nil
	if messageFrame then
		messageFrame.Visible = false
	end
end

return BattleMessage
