local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")

local plr = game.Players.LocalPlayer
local CStorage = RPS:WaitForChild("ClientStorage")
local Remotes = CStorage:WaitForChild("Functions"):WaitForChild("Remotes")
local getProfileDataEv = Remotes:WaitForChild("GetProfileData")
local selectSlotEv = Remotes:WaitForChild("SelectSlot")

local SlotSelect = {}

local AURA_COLORS = {
	Dormant      = Color3.fromRGB(150, 150, 162),
	Awakened     = Color3.fromRGB(93, 201, 133),
	Resonant     = Color3.fromRGB(96, 165, 235),
	Sovereign    = Color3.fromRGB(163, 97, 235),
	Transcendent = Color3.fromRGB(247, 213, 115),
}
local COL_STROKE_IDLE = Color3.fromRGB(70, 70, 85)
local COL_GOLD = Color3.fromRGB(201, 168, 76)

local selecting = false
local slotSelected = false

local gui, backdrop, content, slotContainer

local function formatEuros(n)
	n = math.floor(n or 0)
	local s = tostring(n)
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return formatted
end

local function formatPlaytimeShort(seconds)
	seconds = seconds or 0
	local hrs = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	if hrs > 0 then
		return hrs .. "h " .. mins .. "m"
	end
	return mins .. "m"
end

local function startGlowPulse(playtimeRow)
	local layers = {}
	for _, layer in ipairs(layers) do
		local lbl, baseTrans, peakTrans, duration = layer[1], layer[2], layer[3], layer[4]
		local tween = TS:Create(
			lbl,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{TextTransparency = peakTrans}
		)
		tween:Play()
	end
end

local function selectSlot(slotId)
	if selecting then return end
	selecting = true

	local fadeTween = TS:Create(content, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
	fadeTween:Play()
	fadeTween.Completed:Wait()

	local ok, err = pcall(function()
		selectSlotEv:InvokeServer(slotId)
	end)
	if not ok then
		warn("[SlotSelect] SelectSlot failed: " .. tostring(err))
	end

	task.wait(0.1)
	gui.Enabled = false
	selecting = false
	slotSelected = true
end

local function buildCard(slotId, slotData)
	local card = slotContainer:FindFirstChild("Slot" .. slotId)
	if not card then return end

	local created = slotData and slotData.Created
	local auraVal = card.AuraRow.Value
	local eurosVal = card.EurosRow.Value
	local personaVal = card.PersonaRow.Value
	local levelVal = card.LevelTag.Value
	local playtimeRow = card.PlaytimeRow
	local button = card.SelectButton

	if created then
		local euros = slotData.Euros or 0
		local personas = slotData.Personas or 0
		local aura = slotData.Aura or "Dormant"
		local level = slotData.Level or 1
		local playtime = slotData.Playtime or 0
		local playtimeText = formatPlaytimeShort(playtime)

		eurosVal.Text = "₭" .. formatEuros(euros)
		personaVal.Text = tostring(personas) .. "/12"
		auraVal.Text = aura
		auraVal.TextColor3 = AURA_COLORS[aura] or AURA_COLORS.Dormant
		levelVal.Text = "LV." .. level
		playtimeRow.Value.Text = playtimeText
		button.TextLabel.Text = "PLAY"
	else
		eurosVal.Text = "—"
		personaVal.Text = "—"
		auraVal.Text = "None"
		auraVal.TextColor3 = AURA_COLORS.Dormant
		levelVal.Text = "LV.1"
		playtimeRow.Value.Text = "—"
		button.TextLabel.Text = "NEW GAME"
	end

	startGlowPulse(playtimeRow)

	button.MouseButton1Click:Connect(function()
		selectSlot(slotId)
	end)

	local scaleObj = card:FindFirstChildOfClass("UIScale")
	if not card:GetAttribute("OgScale") then
		card:SetAttribute("OgScale", scaleObj.Scale)
	end
	local ogScale = card:GetAttribute("OgScale")
	local stroke = card:FindFirstChildOfClass("UIStroke")
	
	card.MouseEnter:Connect(function()
		TS:Create(scaleObj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = ogScale * 1.035}):Play()
		if stroke then
			TS:Create(stroke, TweenInfo.new(0.18), {Transparency = 0, Color = COL_GOLD}):Play()
		end
	end)
	card.MouseLeave:Connect(function()
		TS:Create(scaleObj, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = ogScale}):Play()
		if stroke then
			TS:Create(stroke, TweenInfo.new(0.18), {Transparency = 0.5, Color = COL_STROKE_IDLE}):Play()
		end
	end)

	button.MouseButton1Down:Connect(function()
		if scaleObj then
			TS:Create(scaleObj, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Scale = ogScale * 0.97}):Play()
		end
	end)
	button.MouseButton1Up:Connect(function()
		if scaleObj then
			TS:Create(scaleObj, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = ogScale * 1.055}):Play()
		end
	end)
end

local function playEntrance()
	content.GroupTransparency = 1
	TS:Create(content, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()

	local cards = {}
	for _, c in ipairs(slotContainer:GetChildren()) do
		if c:IsA("CanvasGroup") then table.insert(cards, c) end
	end
	table.sort(cards, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

	for i, card in ipairs(cards) do
		local originalPos = card.Position
		card.Position = originalPos + UDim2.new(0, 0, 0.06, 0)
		card.GroupTransparency = 1

		task.delay((i - 1) * 0.1, function()
			TS:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = originalPos,
				GroupTransparency = 0,
			}):Play()
		end)
	end
end

function SlotSelect.setup()
	gui = plr.PlayerGui:WaitForChild("SlotSelectGui")
	backdrop = gui:WaitForChild("Backdrop")
	content = backdrop:WaitForChild("Content")
	slotContainer = content:WaitForChild("SlotContainer")

	local ok, profileData = pcall(function()
		return getProfileDataEv:InvokeServer()
	end)

	local slots = (ok and profileData and profileData.Slots) or {}

	for i = 1, 3 do
		buildCard(tostring(i), slots[tostring(i)])
	end

	gui.Enabled = true
	playEntrance()

	while not slotSelected do
		task.wait(0.1)
	end
end

return SlotSelect
