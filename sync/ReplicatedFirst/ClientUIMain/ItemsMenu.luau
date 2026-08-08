--[[
	ItemsMenu
	----------
	Sleek dark-mode item grid, matching the SlotSelectGui obsidian/gold aesthetic (same background
	color, same gold accent, same stroke color). Auto-built in Studio at StarterGui.ItemsMenuGui --
	restyle it by hand like you do with your other GUIs, this module only ever touches
	Text/Image/Color/Transparency/Position on it, never recreates it.

	Usage:
		ItemsMenu.Open({
			{ItemId = "Apple", Name = "Apple", Image = "rbxassetid://...", Description = "Restores a little HP.", Rarity = "Basic", Quantity = 3},
			{ItemId = "Berry", Name = "Berry", Image = "rbxassetid://...", Description = "Cures poison.", Rarity = "Rare", Quantity = 1},
		}, function(itemId)
			print("used", itemId)
		end)

		ItemsMenu.Close()

	The onUse callback is optional -- omit it (or pass nil) for a browse-only/read-only menu (no
	USE button shows). Item fields Rarity/Quantity/Description/Image are all optional too, this
	degrades gracefully without them.
]]

local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")

local plr = PLRS.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local ClientUIMain = script.Parent
local AnimsManager = require(ClientUIMain.GUIMaster.Animations)

local ItemsMenu = {}

-- Reuses your established Aura tier colors where an item's Rarity matches one of those names,
-- and falls back to a simpler common-sense tier set otherwise -- covers both naming schemes
-- until items settle on one.
local RARITY_COLORS = {
	Dormant      = Color3.fromRGB(150, 150, 162),
	Awakened     = Color3.fromRGB(93, 201, 133),
	Resonant     = Color3.fromRGB(96, 165, 235),
	Sovereign    = Color3.fromRGB(163, 97, 235),
	Transcendent = Color3.fromRGB(247, 213, 115),

	Basic     = Color3.fromRGB(150, 150, 162),
	Common    = Color3.fromRGB(150, 150, 162),
	Rare      = Color3.fromRGB(96, 165, 235),
	Epic      = Color3.fromRGB(163, 97, 235),
	Legendary = Color3.fromRGB(247, 213, 115),
}
local COL_STROKE_IDLE = Color3.fromRGB(70, 70, 85)
local COL_GOLD = Color3.fromRGB(201, 168, 76)

local function rarityColor(rarity)
	return (rarity and RARITY_COLORS[rarity]) or COL_STROKE_IDLE
end

local gui, backdrop, panel, closeButton, grid, cardTemplate
local detail, detailIcon, detailIconStroke, detailName, detailRarity, detailDesc, useButton

local function bindRefs()
	if gui and gui.Parent then return end
	gui = plrGui:WaitForChild("ItemsMenuGui")
	backdrop = gui:WaitForChild("Backdrop")
	panel = backdrop:WaitForChild("Panel")
	closeButton = panel.TitleBar:WaitForChild("CloseButton")
	local body = panel:WaitForChild("Body")
	grid = body:WaitForChild("Grid")
	cardTemplate = grid:WaitForChild("ItemCardTemplate")
	detail = body:WaitForChild("Detail")
	detailIcon = detail:WaitForChild("Icon")
	detailIconStroke = detailIcon:WaitForChild("RarityStroke")
	detailName = detail:WaitForChild("NameLabel")
	detailRarity = detail:WaitForChild("RarityLabel")
	detailDesc = detail:WaitForChild("DescriptionLabel")
	useButton = detail:WaitForChild("UseButton")

	closeButton.MouseButton1Click:Connect(function() ItemsMenu.Close() end)
	backdrop.MouseButton1Click:Connect(function() ItemsMenu.Close() end)
	-- Frame isn't Active by default, so clicks on blank panel space (not on a button) would
	-- otherwise fall through to the backdrop underneath and close the menu
	panel.Active = true
end

local activeCards = {}
local currentOnUse = nil
local selectedCard = nil
local useButtonConn = nil

local function showDetail(itemData)
	detailIcon.Image = itemData.Image or ""
	detailIconStroke.Color = rarityColor(itemData.Rarity)
	detailName.Text = itemData.Name or itemData.ItemId or ""
	detailRarity.Text = itemData.Rarity and string.upper(itemData.Rarity) or ""
	detailRarity.TextColor3 = rarityColor(itemData.Rarity)
	detailDesc.Text = itemData.Description or ""

	if useButtonConn then
		useButtonConn:Disconnect()
		useButtonConn = nil
	end

	if currentOnUse then
		useButton.Visible = true
		useButtonConn = useButton.MouseButton1Click:Connect(function()
			currentOnUse(itemData.ItemId)
		end)
	else
		useButton.Visible = false
	end
end

local function selectCard(card, itemData)
	if selectedCard and selectedCard ~= card then
		local prevStroke = selectedCard:FindFirstChild("RarityStroke")
		if prevStroke then
			TS:Create(prevStroke, AnimsManager.STIS.FadeIn, {Thickness = 1.5}):Play()
		end
	end
	selectedCard = card
	local stroke = card:FindFirstChild("RarityStroke")
	if stroke then
		TS:Create(stroke, AnimsManager.STIS.FadeIn, {Thickness = 2.5}):Play()
	end
	showDetail(itemData)
end

local function buildCard(itemData, index)
	local card = cardTemplate:Clone()
	card.Name = "Card_" .. tostring(index)
	card.Visible = true
	card.LayoutOrder = index

	local icon = card:WaitForChild("Icon")
	icon.Image = itemData.Image or ""
	local stroke = card:WaitForChild("RarityStroke")
	stroke.Color = rarityColor(itemData.Rarity)

	local qtyBadge = icon:WaitForChild("QtyBadge")
	if itemData.Quantity and itemData.Quantity > 1 then
		qtyBadge.Text = "x" .. tostring(itemData.Quantity)
		qtyBadge.Visible = true
	else
		qtyBadge.Visible = false
	end

	card:WaitForChild("NameLabel").Text = itemData.Name or itemData.ItemId or ""

	card.MouseEnter:Connect(function()
		if selectedCard ~= card then
			TS:Create(card, AnimsManager.STIS.FadeIn, {BackgroundColor3 = Color3.fromRGB(36, 33, 48)}):Play()
		end
	end)
	card.MouseLeave:Connect(function()
		if selectedCard ~= card then
			TS:Create(card, AnimsManager.STIS.FadeIn, {BackgroundColor3 = Color3.fromRGB(26, 26, 40)}):Play()
		end
	end)
	card.MouseButton1Click:Connect(function()
		selectCard(card, itemData)
	end)

	card.Parent = grid
	table.insert(activeCards, card)
	return card
end

local function clearCards()
	for _, card in ipairs(activeCards) do
		card:Destroy()
	end
	activeCards = {}
	selectedCard = nil
end

function ItemsMenu.Open(items, onUse)
	bindRefs()
	clearCards()

	currentOnUse = onUse
	useButton.Visible = false
	detailName.Text = ""
	detailRarity.Text = ""
	detailDesc.Text = "Select an item to see its details."
	detailIcon.Image = ""
	detailIconStroke.Color = COL_STROKE_IDLE

	for i, itemData in ipairs(items or {}) do
		buildCard(itemData, i)
	end

	gui.Enabled = true
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.new(0.56, 0, 0.66, 0)
	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	backdrop.BackgroundTransparency = 1

	TS:Create(backdrop, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 0.45}):Play()
	TS:Create(panel, AnimsManager.STIS.FadeInMid or AnimsManager.STIS.FadeIn, {
		BackgroundTransparency = 0,
		Size = UDim2.new(0.62, 0, 0.72, 0),
	}):Play()
	if panelStroke then
		TS:Create(panelStroke, AnimsManager.STIS.FadeIn, {Transparency = 0}):Play()
	end

	if items and items[1] then
		selectCard(activeCards[1], items[1])
	end
end

function ItemsMenu.Close()
	if not gui or not gui.Enabled then return end

	if useButtonConn then
		useButtonConn:Disconnect()
		useButtonConn = nil
	end

	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	local outTween = TS:Create(panel, AnimsManager.STIS.FadeIn, {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.56, 0, 0.66, 0),
	})
	outTween:Play()
	TS:Create(backdrop, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 1}):Play()
	if panelStroke then
		TS:Create(panelStroke, AnimsManager.STIS.FadeIn, {Transparency = 1}):Play()
	end
	outTween.Completed:Wait()

	if gui then
		gui.Enabled = false
	end
	clearCards()
	currentOnUse = nil
end

return ItemsMenu
