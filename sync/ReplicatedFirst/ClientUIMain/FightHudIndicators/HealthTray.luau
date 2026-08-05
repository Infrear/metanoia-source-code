--[[
	HealthTray
	-----------
	Drives CombatOverlays.Holder["Healthbar Tray"] -- one compact row per party member (you +
	allies), Persona-style: small portrait, HP number, thin color-coded bar underneath. The tray
	frame itself is just a layout container -- per your note, it stays visually transparent, all
	the actual "chrome" comes from the reference-style bars/text this builds inside it.

	Usage:
		HealthTray.Init(fightTable)                          -- call once, right when a battle starts
		HealthTray.Update(fighterInstance, currentHP, maxHP)  -- call whenever a party member's HP changes
		HealthTray.Clear()                                    -- call on battle end / cleanup

	fightTable.PlayerFighters is expected to look like what CombatManager already sends down:
	a list of fighter tables, each with at least .Instance, and ideally .DisplayName / .MaxHP /
	.CurrentHP / .PortraitId if you have them -- all optional, this degrades gracefully without them.
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

local HealthTray = {}

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

local function bindRefs()
	if trayFrame and trayFrame.Parent then return end
	local holder = getOverlaysGui():WaitForChild("Holder")
	trayFrame = holder:WaitForChild("Healthbar Tray")

	-- keep it transparent per your note -- this is a layout container, not a visible panel
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
	hpLabel.TextColor3 = Color3.fromRGB(255, 215, 120) -- gold, matching your established accent
	-- Fighter objects use .HP, not .CurrentHP (that field doesn't exist on the real Fighter class --
	-- this was always falling through to MaxHP, showing "full health" even after damage until Update
	-- actually got called, which it never was -- see the attackUpdate wiring in ClientUIMain now)
	hpLabel.Text = tostring(fighter.HP or fighter.MaxHP or "--")
	hpLabel.Parent = infoHolder

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	barBg.BackgroundTransparency = 0.25
	barBg.BorderSizePixel = 0
	barBg.Size = UDim2.new(1, 0, 0.25, 0)
	barBg.Position = UDim2.new(0, 0, 1, 0)
	barBg.AnchorPoint = Vector2.new(0, 1)
	barBg.Parent = infoHolder

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = BAR_COLORS.High
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	return {
		Row = row,
		HPLabel = hpLabel,
		BarFill = barFill,
		MaxHP = fighter.MaxHP or 1,
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
				task.delay((i * 0.08) / combatSettings.CombatSpeedMultiplier, function()
					local t = TS:Create(inner, TweenInfo.new(0.4 / combatSettings.CombatSpeedMultiplier, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Position = UDim2.new(0, 0, 0, 0)
					})
					t:Play()
				end)
			end
		end
	end
end

function HealthTray.Update(fighterInstance, currentHP, maxHP)
	local entry = rows[fighterInstance]
	if not entry then return end

	if maxHP then
		entry.MaxHP = maxHP
	end

	local frac = entry.MaxHP > 0 and math.clamp(currentHP / entry.MaxHP, 0, 1) or 0
	entry.HPLabel.Text = tostring(math.max(0, math.floor(currentHP)))

	TS:Create(entry.BarFill, AnimsManager.STIS.FadeIn, {
		Size = UDim2.new(frac, 0, 1, 0),
		BackgroundColor3 = colorForFraction(frac),
	}):Play()
end

function HealthTray.Clear()
	for _, entry in pairs(rows) do
		if entry.Row then entry.Row:Destroy() end
	end
	rows = {}
end

return HealthTray
