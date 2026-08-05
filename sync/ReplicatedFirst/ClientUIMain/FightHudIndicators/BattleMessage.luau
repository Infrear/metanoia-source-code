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
local TES = {}

-- CombatOverlays is the pending rename of SkillsMenu -- check both so this doesn't break
-- the moment the rename happens (or before it does)
local function getOverlaysGui()
	return plrGui:FindFirstChild("CombatOverlays") or plrGui:WaitForChild("SkillsMenu")
end

local messageFrame, textboxImg, textFrame, textLabel, charImg
local baseSize = nil
local textboxImgBaseSize = nil

local function bindRefs()
	if messageFrame and messageFrame.Parent then return end
	local holder = getOverlaysGui():WaitForChild("Holder")
	messageFrame = holder:WaitForChild("Message")
	textboxImg = messageFrame:WaitForChild("TextboxImg")
	textFrame = textboxImg:WaitForChild("TextFrame")
	textLabel = textFrame:WaitForChild("TextLabel")
	charImg = messageFrame:WaitForChild("CharImg")
	
	if not baseSize then
		baseSize = messageFrame.Size
		textboxImgBaseSize = textboxImg.Size
	end
end

local PULSE_TWEEN_INFO = TweenInfo.new(
	0.145/combatSettings.CombatSpeedMultiplier,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	0, -- single pulse, we handle loops manually now
	true -- reverses back down
)

local activeToken = nil -- bumped every Show() call so old coroutines/tweens know to bail

function BattleMessage.Show(text, charImageId, duration)
	bindRefs()

	local myToken = {}
	activeToken = myToken

	-- kill anything still running from a previous call
	for _, t in pairs(TES) do
		if t.Instance == messageFrame or t.Instance == textboxImg or t.Instance == charImg then
			t:Cancel()
		end
	end

	textLabel.Text = text or ""
	if charImageId then
		charImg.Image = charImageId
	end

	-- wide and flat initial state
	messageFrame.Size = UDim2.new(
		baseSize.X.Scale * 1.5, baseSize.X.Offset * 1.5,
		baseSize.Y.Scale * 0.1, baseSize.Y.Offset * 0.1
	)
	textboxImg.ImageTransparency = 1
	charImg.ImageTransparency = 1
	messageFrame.Visible = true

	-- Entrance: bounce in from wide/flat to regular
	TES[messageFrame] = TS:Create(messageFrame, TweenInfo.new(0.4/combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = baseSize})
	TES[messageFrame]:Play()
	TES[textboxImg] = TS:Create(textboxImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 0})
	TES[textboxImg]:Play()
	TES[charImg] = TS:Create(charImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 0})
	TES[charImg]:Play()
	TES[messageFrame].Completed:Wait()

	if activeToken ~= myToken then return end -- a newer Show() call took over while we waited

	-- Ensure textboxImg starts at its normal size before custom pulsing begins
	textboxImg.Size = textboxImgBaseSize
	
	-- Custom irregular pulsing loop on just the textboxImg
	coroutine.wrap(function()
		local targetPulseSize = UDim2.fromScale(
			textboxImgBaseSize.X.Scale * 1.035,
			textboxImgBaseSize.Y.Scale * 1
		)
		
		while activeToken == myToken do
			-- Faster, random intervals (0.5 to 1.2 seconds)
			task.wait((math.random(1, 5)/2.5) / 10 / combatSettings.CombatSpeedMultiplier)
			if activeToken ~= myToken then break end
			
			local pulses = math.random(1, 2)
			for i = 1, pulses do
				if activeToken ~= myToken then break end
				
				local pulseTween = TS:Create(textboxImg, PULSE_TWEEN_INFO, {Size = targetPulseSize})
				TES[textboxImg] = pulseTween
				pulseTween:Play()
				pulseTween.Completed:Wait()
				
				if i < pulses and activeToken == myToken then
					task.wait(0.1 / combatSettings.CombatSpeedMultiplier) -- short gap between double-pulses
				end
			end
		end
	end)()

	task.delay((duration or 4.0)/combatSettings.CombatSpeedMultiplier, function()
		if activeToken ~= myToken then return end -- superseded, let the newer one own cleanup

		TES[messageFrame]:Cancel()

		TES[messageFrame] = TS:Create(messageFrame, AnimsManager.STIS.FadeIn, {
			Size = UDim2.new(baseSize.X.Scale * 0.7, baseSize.X.Offset * 0.7, baseSize.Y.Scale * 0.7, baseSize.Y.Offset * 0.7)
		})
		TES[messageFrame]:Play()
		TES[textboxImg] = TS:Create(textboxImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 1})
		TES[textboxImg]:Play()
		TES[charImg] = TS:Create(charImg, AnimsManager.STIS.FadeIn, {ImageTransparency = 1})
		TES[charImg]:Play()
		TES[messageFrame].Completed:Wait()

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
