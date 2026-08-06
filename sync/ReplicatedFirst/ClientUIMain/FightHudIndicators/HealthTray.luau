--[[
	HealthTray
	-----------
	Drives CombatOverlays.Holder["Healthbar Tray"] -- one compact row per party member (you +
	allies), Persona-style: small portrait, HP number, thin color-coded bar underneath.

	Usage:
		HealthTray.Init(fightTable)                          -- call once, right when a battle starts
		HealthTray.Update(fighterInstance, currentHP, maxHP)  -- call whenever a party member's HP changes
		HealthTray.Clear()                                    -- call on battle end / cleanup
]]

-- Services
local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")

-- Dependencies
local plr = PLRS.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local Storage = RPS:WaitForChild("ClientStorage")
local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings
local AnimsManager = require(script.Parent.Parent.GUIMaster.Animations)

local HealthTray = {}

-- SETTINGS
HealthTray.TweenEarly = true -- if true, healthbars bounce in immediately behind the transition; if false, they wait for the scrub-out
HealthTray._hasPlayedIntro = false

local function getOverlaysGui()
	return plrGui:FindFirstChild("CombatOverlays") or plrGui:WaitForChild("SkillsMenu")
end

local trayFrame
local rows = {} -- keyed by fighter.Instance

local BAR_COLORS = {
	High = Color3.fromRGB(120, 235, 180),
	Mid  = Color3.fromRGB(255, 214, 100),
	Low  = Color3.fromRGB(255, 95, 95),
}

local function colorForFraction(frac)
	if frac > 0.5 then return BAR_COLORS.High
	elseif frac > 0.2 then return BAR_COLORS.Mid
	else return BAR_COLORS.Low end
end

-- Cancels any in-flight tweens for a specific fighter row to prevent overlapping glitches.
local function cancelTweens(entry)
	if not entry or not entry.TES then return end
	for key, tween in pairs(entry.TES) do
		if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end
	table.clear(entry.TES)
end

local function bindRefs()
	if trayFrame and trayFrame.Parent then return end
	local holder = getOverlaysGui():WaitForChild("Holder")
	trayFrame = holder:WaitForChild("Healthbar Tray")

	-- keep it transparent -- layout container, not visible panel
	trayFrame.BackgroundTransparency = 1

	if not trayFrame:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = trayFrame
	end
end

local function buildRow(fighter, index)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. tostring(index)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(0, 92, 1, 0)
	row.LayoutOrder = index
	row.Parent = trayFrame

	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.Position = UDim2.new(0, 0, 1.5, 0)
	inner.Parent = row

	local portrait = Instance.new("ImageLabel")
	portrait.Name = "Portrait"
	portrait.BackgroundTransparency = 1
	portrait.Size = UDim2.new(0, 28, 0, 28)
	portrait.Position = UDim2.new(0, 0, 0.5, 0)
	portrait.AnchorPoint = Vector2.new(0, 0.5)
	portrait.Image = fighter.PortraitId or ""
	portrait.ScaleType = Enum.ScaleType.Fit
	portrait.Parent = inner

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = portrait

	local placeholderIcon = Instance.new("ImageLabel")
	placeholderIcon.Name = "PlaceholderIcon"
	placeholderIcon.BackgroundTransparency = 1
	placeholderIcon.Size = UDim2.new(0, 14, 0, 14)
	placeholderIcon.Position = UDim2.new(0, -4, 0, -4)
	placeholderIcon.Image = "rbxassetid://0" -- placeholder
	placeholderIcon.Parent = portrait

	local infoHolder = Instance.new("Frame")
	infoHolder.Name = "Info"
	infoHolder.BackgroundTransparency = 1
	infoHolder.Size = UDim2.new(1, -34, 1, 0)
	infoHolder.Position = UDim2.new(0, 34, 0, 0)
	infoHolder.Parent = inner

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.BackgroundTransparency = 1
	hpLabel.Size = UDim2.new(1, 0, 0.55, 0)
	hpLabel.Position = UDim2.new(0, 0, 0, 0)
	hpLabel.TextXAlignment = Enum.TextXAlignment.Left
	hpLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.TextColor3 = Color3.fromRGB(255, 215, 120) -- gold accent
	local initHP = fighter.HP or fighter.MaxHP or 100
	hpLabel.Text = tostring(initHP)
	hpLabel.Parent = infoHolder

	local floatingLabel = Instance.new("TextLabel")
	floatingLabel.Name = "FloatingLabel"
	floatingLabel.BackgroundTransparency = 1
	floatingLabel.Size = UDim2.new(1, 0, 0, 0)
	floatingLabel.Position = UDim2.new(0, 0, -0.4, 0)
	floatingLabel.TextXAlignment = Enum.TextXAlignment.Left
	floatingLabel.TextYAlignment = Enum.TextYAlignment.Center
	floatingLabel.TextScaled = true
	floatingLabel.Font = Enum.Font.GothamBlack
	floatingLabel.TextTransparency = 1
	floatingLabel.Visible = false
	floatingLabel.Parent = infoHolder

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	barBg.BackgroundTransparency = 0.25
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, 0, 0.18, 0)
	barBg.Position = UDim2.new(0, 0, 0.82, 0)
	barBg.AnchorPoint = Vector2.new(0, 1)
	barBg.Parent = infoHolder

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = barBg

	-- Secondary trailing bar (red/yellow decay bar underneath main fill)
	local barTrail = Instance.new("Frame")
	barTrail.Name = "BarTrail"
	barTrail.BorderSizePixel = 0
	barTrail.Size = UDim2.new(1, 0, 1, 0)
	barTrail.BackgroundColor3 = Color3.fromRGB(235, 75, 75)
	barTrail.ZIndex = 1
	barTrail.Parent = barBg

	local trailCorner = Instance.new("UICorner")
	trailCorner.CornerRadius = UDim.new(1, 0)
	trailCorner.Parent = barTrail

	-- Main health bar
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = BAR_COLORS.High
	barFill.ZIndex = 2
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	-- SP Bar
	local spBarBg = Instance.new("Frame")
	spBarBg.Name = "SPBarBg"
	spBarBg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	spBarBg.BackgroundTransparency = 0.25
	spBarBg.BorderSizePixel = 0
	spBarBg.Size = UDim2.new(1, 0, 0.1, 0)
	spBarBg.Position = UDim2.new(0, 0, 1, 0)
	spBarBg.AnchorPoint = Vector2.new(0, 1)
	spBarBg.Parent = infoHolder

	local spBgCorner = Instance.new("UICorner")
	spBgCorner.CornerRadius = UDim.new(1, 0)
	spBgCorner.Parent = spBarBg

	local spBarFill = Instance.new("Frame")
	spBarFill.Name = "SPBarFill"
	spBarFill.BorderSizePixel = 0
	spBarFill.Size = UDim2.new(1, 0, 1, 0)
	spBarFill.BackgroundColor3 = Color3.fromRGB(80, 150, 255) -- SP Blue
	spBarFill.Parent = spBarBg

	local spFillCorner = Instance.new("UICorner")
	spFillCorner.CornerRadius = UDim.new(1, 0)
	spFillCorner.Parent = spBarFill

	return {
		Row = row,
		Inner = inner,
		HPLabel = hpLabel,
		BarFill = barFill,
		BarTrail = barTrail,
		FloatingLabel = floatingLabel,
		MaxHP = fighter.MaxHP or 1,
		CurrentHP = initHP,
		TES = {},
		ActiveFloatingValue = 0,
		FloatingToken = nil,
	}
end

function HealthTray.Init(fightTable)
	bindRefs()
	HealthTray.Clear()

	local list = fightTable and fightTable.PlayerFighters or {}
	for i, fighter in ipairs(list) do
		if fighter.Instance then
			local entry = buildRow(fighter, i)
			rows[fighter.Instance] = entry

			local inner = entry.Row:FindFirstChild("Inner")
			if inner then
				inner.Position = UDim2.new(0, 0, 1.5, 0) -- Ensure it starts hidden
			end
		end
	end

	HealthTray._hasPlayedIntro = false
	if HealthTray.TweenEarly then
		HealthTray.PlayIntro()
	end
end

function HealthTray.PlayIntro()
	if HealthTray._hasPlayedIntro then return end
	HealthTray._hasPlayedIntro = true

	local i = 1
	for _, entry in pairs(rows) do
		local inner = entry.Row:FindFirstChild("Inner")
		if inner then
			task.delay((i * 0.08) / combatSettings.CombatSpeedMultiplier, function()
				local t = TS:Create(inner, TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 0, 0, 0)
				})
				t:Play()
			end)
		end
		i += 1
	end
end

function HealthTray.Update(fighterInstance, currentHP, maxHP)
	local entry = rows[fighterInstance]
	if not entry then return end

	if maxHP then
		entry.MaxHP = maxHP
	end

	local oldHP = entry.CurrentHP
	local newHP = math.max(0, math.floor(currentHP))
	entry.CurrentHP = newHP

	local oldFrac = entry.MaxHP > 0 and math.clamp(oldHP / entry.MaxHP, 0, 1) or 0
	local newFrac = entry.MaxHP > 0 and math.clamp(newHP / entry.MaxHP, 0, 1) or 0
	local delta = newHP - oldHP

	-- cancel any active in-flight tweens on this row to avoid race conditions
	cancelTweens(entry)

	if delta < 0 then
		-- DAMAGE VISUALS
		-- 1. Dynamic stacking floating text
		if entry.FloatingLabel.Visible and entry.FloatingLabel.TextTransparency < 0.9 then
			entry.ActiveFloatingValue = entry.ActiveFloatingValue + delta
		else
			entry.ActiveFloatingValue = delta
		end

		local fl = entry.FloatingLabel
		fl.Text = tostring(entry.ActiveFloatingValue)
		fl.TextColor3 = Color3.fromRGB(255, 75, 75)
		fl.Visible = true
		fl.TextTransparency = 0
		fl.Size = UDim2.new(1, 0, 0, 0) -- start squashed flat

		local bounceTI = TweenInfo.new(0.35 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local bounceTween = TS:Create(fl, bounceTI, {Size = UDim2.new(1, 0, 0.45, 0)})
		entry.TES[fl] = bounceTween
		bounceTween:Play()

		-- auto-fadeout timer token
		local token = {}
		entry.FloatingToken = token
		task.delay(1.2 / combatSettings.CombatSpeedMultiplier, function()
			if entry.FloatingToken == token then
				local fadeTI = TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local fadeTween = TS:Create(fl, fadeTI, {TextTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
				entry.TES[fl] = fadeTween
				fadeTween:Play()
				fadeTween.Completed:Wait()
				if entry.FloatingToken == token then
					fl.Visible = false
					entry.ActiveFloatingValue = 0
				end
			end
		end)

		-- 2. HP label text and red color flash
		entry.HPLabel.Text = tostring(newHP)
		entry.HPLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		local textFlashTI = TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local textFlashTween = TS:Create(entry.HPLabel, textFlashTI, {TextColor3 = Color3.fromRGB(255, 215, 120)})
		entry.TES[entry.HPLabel] = textFlashTween
		textFlashTween:Play()

		-- 3. Main bar drops instantly & flashes white
		entry.BarFill.Size = UDim2.new(newFrac, 0, 1, 0)
		entry.BarFill.BackgroundColor3 = Color3.new(1, 1, 1)
		local fillFlashTI = TweenInfo.new(0.3 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fillFlashTween = TS:Create(entry.BarFill, fillFlashTI, {BackgroundColor3 = colorForFraction(newFrac)})
		entry.TES[entry.BarFill] = fillFlashTween
		fillFlashTween:Play()

		-- 4. Secondary trailing bar decays slowly behind main bar
		entry.BarTrail.Size = UDim2.new(oldFrac, 0, 1, 0)
		local trailTI = TweenInfo.new(0.6 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local trailTween = TS:Create(entry.BarTrail, trailTI, {Size = UDim2.new(newFrac, 0, 1, 0)})
		entry.TES[entry.BarTrail] = trailTween
		trailTween:Play()

		-- 5. Violent UI frame shake & scale bounce
		local inner = entry.Inner
		inner.Size = UDim2.new(0.9, 0, 0.9, 0)
		local innerTI = TweenInfo.new(0.35 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local innerTween = TS:Create(inner, innerTI, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
		entry.TES[inner] = innerTween
		innerTween:Play()

	elseif delta > 0 then
		-- HEAL VISUALS
		-- 1. Dynamic stacking floating text
		if entry.FloatingLabel.Visible and entry.FloatingLabel.TextTransparency < 0.9 then
			entry.ActiveFloatingValue = entry.ActiveFloatingValue + delta
		else
			entry.ActiveFloatingValue = delta
		end

		local fl = entry.FloatingLabel
		fl.Text = "+" .. tostring(entry.ActiveFloatingValue)
		fl.TextColor3 = Color3.fromRGB(100, 245, 150)
		fl.Visible = true
		fl.TextTransparency = 0
		fl.Size = UDim2.new(1, 0, 0, 0)

		local bounceTI = TweenInfo.new(0.35 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		local bounceTween = TS:Create(fl, bounceTI, {Size = UDim2.new(1, 0, 0.45, 0)})
		entry.TES[fl] = bounceTween
		bounceTween:Play()

		-- auto-fadeout timer token
		local token = {}
		entry.FloatingToken = token
		task.delay(1.2 / combatSettings.CombatSpeedMultiplier, function()
			if entry.FloatingToken == token then
				local fadeTI = TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local fadeTween = TS:Create(fl, fadeTI, {TextTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
				entry.TES[fl] = fadeTween
				fadeTween:Play()
				fadeTween.Completed:Wait()
				if entry.FloatingToken == token then
					fl.Visible = false
					entry.ActiveFloatingValue = 0
				end
			end
		end)

		-- 2. HP label text and green color flash
		entry.HPLabel.Text = tostring(newHP)
		entry.HPLabel.TextColor3 = Color3.fromRGB(120, 245, 160)
		local textFlashTI = TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local textFlashTween = TS:Create(entry.HPLabel, textFlashTI, {TextColor3 = Color3.fromRGB(255, 215, 120)})
		entry.TES[entry.HPLabel] = textFlashTween
		textFlashTween:Play()

		-- 3. Main bar & trail fill smoothly + white flash
		entry.BarFill.BackgroundColor3 = Color3.new(1, 1, 1)
		local fillFlashTI = TweenInfo.new(0.3 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fillFlashTween = TS:Create(entry.BarFill, fillFlashTI, {BackgroundColor3 = colorForFraction(newFrac)})
		entry.TES[entry.BarFill] = fillFlashTween
		fillFlashTween:Play()

		local fillSizeTI = TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fillSizeTween = TS:Create(entry.BarFill, fillSizeTI, {Size = UDim2.new(newFrac, 0, 1, 0)})
		entry.TES[entry.BarFill] = fillSizeTween
		fillSizeTween:Play()

		local trailSizeTween = TS:Create(entry.BarTrail, fillSizeTI, {Size = UDim2.new(newFrac, 0, 1, 0)})
		entry.TES[entry.BarTrail] = trailSizeTween
		trailSizeTween:Play()

		-- 4. UI frame scale pulse & float upward
		local inner = entry.Inner
		inner.Size = UDim2.new(1.08, 0, 1.08, 0)
		inner.Position = UDim2.new(0, 0, -0.15, 0)
		local floatTI = TweenInfo.new(0.45 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local floatTween = TS:Create(inner, floatTI, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
		entry.TES[inner] = floatTween
		floatTween:Play()

		-- 5. Floating heart icon
		local heart = Instance.new("ImageLabel")
		heart.Name = "HealHeart"
		heart.BackgroundTransparency = 1
		heart.Size = UDim2.new(0, 16, 0, 16)
		heart.Position = UDim2.new(0.5, -8, 0.5, -8)
		heart.Image = "rbxassetid://6031094678"
		heart.ImageColor3 = Color3.fromRGB(100, 245, 150)
		heart.ZIndex = 5
		heart.Parent = inner

		local heartTI = TweenInfo.new(0.6 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local heartTween = TS:Create(heart, heartTI, {Position = UDim2.new(0.5, -8, -0.5, 0), ImageTransparency = 1})
		entry.TES[heart] = heartTween
		heartTween:Play()
		heartTween.Completed:Once(function()
			heart:Destroy()
		end)
	else
		-- No HP change -- baseline update
		entry.HPLabel.Text = tostring(newHP)
		entry.BarFill.Size = UDim2.new(newFrac, 0, 1, 0)
		entry.BarTrail.Size = UDim2.new(newFrac, 0, 1, 0)
		entry.BarFill.BackgroundColor3 = colorForFraction(newFrac)
	end
end

function HealthTray.Clear()
	for _, entry in pairs(rows) do
		cancelTweens(entry)
		if entry.Row then entry.Row:Destroy() end
	end
	rows = {}
end

return HealthTray