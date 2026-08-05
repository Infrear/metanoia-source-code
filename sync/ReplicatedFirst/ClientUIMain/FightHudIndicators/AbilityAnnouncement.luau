--[[
	AbilityAnnouncement
	---------------------
	Big shake-effect panel for calling out abilities/passives/events mid-fight, e.g.:
		"Auntie Earth: All friendly Flora and Fauna heal 10% of their health every round"
	Uses your existing RichText module (Storage.Modules."Open Source".GUI.RichText) to render/animate
	the text itself, plus a panel-level camera-shake-style jitter on top for impact.

	This is the STRUCTURAL piece -- ready to call, but nothing in combat calls it yet (per your
	note you'll wire up the actual triggers later). Auto-builds its own panel under
	CombatOverlays.Holder the first time it's used, since you haven't built one in Studio yet --
	feel free to grab "AbilityPanel" afterwards and restyle it by hand like you did Message/HealthTray,
	the code below only touches Size/Position/Text/Transparency, never recreates it if it already exists.

	Usage:
		AbilityAnnouncement.Show("Auntie Earth: All friendly Flora and Fauna heal 10% of their health every round")
		AbilityAnnouncement.Show("SUPER MOVE!", {Duration = 3, ShakeIntensity = 6, TextProps = {AnimateStyle = "Wiggle"}})
]]

local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local PLRS = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")

local plr = PLRS.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local Storage = RPS:WaitForChild("ClientStorage")
local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings
local AnimsManager = require(script.Parent.Parent.GUIMaster.Animations)
local richText = require(Storage.Modules:WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("RichText"))

local AbilityAnnouncement = {}

local function getOverlaysGui()
	return plrGui:FindFirstChild("CombatOverlays") or plrGui:WaitForChild("SkillsMenu")
end

local panel, textFrame
local basePosition
local currentRichTextObj = nil
local activeToken = nil

local function buildPanel()
	local holder = getOverlaysGui():WaitForChild("Holder")
	local existing = holder:FindFirstChild("AbilityPanel")
	if existing then
		panel = existing
		textFrame = panel:FindFirstChild("TextArea") or panel
		basePosition = panel.Position
		return
	end

	panel = Instance.new("Frame")
	panel.Name = "AbilityPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.4, 0)
	panel.Size = UDim2.new(0.7, 0, 0.14, 0)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.ZIndex = 20
	panel.Visible = false
	panel.Parent = holder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 214, 110) -- gold accent, matching your established style
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = panel

	textFrame = Instance.new("Frame")
	textFrame.Name = "TextArea"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(0.92, 0, 0.8, 0)
	textFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	textFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	textFrame.ZIndex = 21
	textFrame.Parent = panel

	basePosition = panel.Position
end

local function shakeLoop(token, intensity, duration)
	local startTime = os.clock()
	while activeToken == token and (os.clock() - startTime) < duration do
		local dx = (math.random() - 0.5) * 2 * intensity
		local dy = (math.random() - 0.5) * 2 * intensity
		panel.Position = basePosition + UDim2.new(0, dx, 0, dy)
		RS.Heartbeat:Wait()
	end
	if activeToken == token then
		panel.Position = basePosition
	end
end

function AbilityAnnouncement.Show(text, config)
	config = config or {}
	if not panel then buildPanel() end

	local myToken = {}
	activeToken = myToken

	if currentRichTextObj then
		pcall(function() currentRichTextObj:Hide() end)
		currentRichTextObj = nil
	end

	panel.Visible = true
	panel.Position = basePosition
	panel.BackgroundTransparency = 1
	local stroke = panel:FindFirstChildOfClass("UIStroke")

	-- Fade the panel chrome in
	TS:Create(panel, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 0.15}):Play()
	if stroke then
		TS:Create(stroke, AnimsManager.STIS.FadeIn, {Transparency = 0}):Play()
	end

	-- Render + animate the text via your RichText module
	currentRichTextObj = richText:New(textFrame, text, config.TextProps or {
		ContainerHorizontalAlignment = "Center",
		ContainerVerticalAlignment = "Center",
	})
	coroutine.wrap(function()
		currentRichTextObj:Show()
	end)()

	-- Panel-level shake for impact (independent of RichText's own per-character animation)
	coroutine.wrap(function()
		shakeLoop(myToken, config.ShakeIntensity or 4, config.ShakeDuration or 0.4)
	end)()

	task.delay((config.Duration or 3)/combatSettings.CombatSpeedMultiplier, function()
		if activeToken ~= myToken then return end

		local outTween = TS:Create(panel, AnimsManager.STIS.FadeOut, {BackgroundTransparency = 1})
		outTween:Play()
		if stroke then
			TS:Create(stroke, AnimsManager.STIS.FadeOut, {Transparency = 1}):Play()
		end
		if currentRichTextObj then
			pcall(function() currentRichTextObj:Hide() end)
		end
		outTween.Completed:Wait()

		if activeToken == myToken then
			panel.Visible = false
			activeToken = nil
		end
	end)
end

function AbilityAnnouncement.Dismiss()
	if not activeToken then return end
	activeToken = nil
	if currentRichTextObj then
		pcall(function() currentRichTextObj:Hide() end)
	end
	if panel then panel.Visible = false end
end

return AbilityAnnouncement
