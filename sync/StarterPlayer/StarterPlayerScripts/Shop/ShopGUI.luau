-- ============================================================
-- ShopGUI (ModuleScript — child of ShopClient)
-- Renders and manages all shop UI.
-- One data pipeline, multiple swappable layout skins.
--
-- DESIGN LANGUAGE:
--   • Midnight obsidian base (#0D0D1A)
--   • Gold trim (#C9A84C) for prices, headers, borders
--   • Arcana purple (#6B3FA0) for magic/aura items
--   • Tarot card flip animation on shop header open
--   • Soft lavender text (#D4CFEE) for descriptions
--   • Each layout skin is a function that builds the UI tree
--
-- LAYOUT TYPES:
--   GeneralStore   — shelf grid, fast tab switching
--   Armory         — two-column list with stat comparison panel
--   Boutique       — mannequin preview with equip toggle
--   AuraParlor     — character preview with live aura VFX
--   CardShop       — full tarot card flip reveal per item
--   SkillShop      — spell tome grid with skill preview
--   Pharmacy       — list + service button panel
--   PawnShop       — combined buy/sell two-tab layout
--   Restaurant     — menu card layout with time-of-day filter
--   MusicShop      — record shelf with preview play button
--   FortuneParlor  — reading card spread layout
--   Gacha          — capsule machine with pull animation
--
-- All layouts share:
--   • Header with arcana card flip
--   • Currency display (live update on purchase)
--   • Close button
--   • Toast notifications for buy/sell/error results
-- ============================================================

-- Services
local TS   = game:GetService("TweenService")
local UIS  = game:GetService("UserInputService")
local RPS  = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependencies
local ShopData = require(RPS:WaitForChild("ClientStorage"):WaitForChild("Info"):WaitForChild("ShopData"))

local plr = PLRS.LocalPlayer

-- ── Design tokens ────────────────────────────────────────────
local COLORS = {
	Base        = Color3.fromRGB(13,  13,  26),    -- #0D0D1A obsidian
	Panel       = Color3.fromRGB(20,  18,  40),    -- slightly lighter panel
	Gold        = Color3.fromRGB(201, 168, 76),    -- #C9A84C
	Purple      = Color3.fromRGB(107, 63,  160),   -- #6B3FA0
	TextPrimary = Color3.fromRGB(212, 207, 238),   -- #D4CFEE lavender
	TextDim     = Color3.fromRGB(130, 120, 160),
	Green       = Color3.fromRGB(80,  200, 120),   -- success
	Red         = Color3.fromRGB(220, 80,  80),    -- error
	Rarity      = {
		[1] = Color3.fromRGB(160, 160, 160),  -- Common: grey
		[2] = Color3.fromRGB(100, 180, 100),  -- Uncommon: green
		[3] = Color3.fromRGB(80,  120, 220),  -- Rare: blue
		[4] = Color3.fromRGB(160, 80,  220),  -- Epic: purple
		[5] = Color3.fromRGB(240, 180, 50),   -- Legendary: gold
	},
}

local FONTS = {
	Header  = Enum.Font.GothamBold,
	Body    = Enum.Font.Gotham,
	Mono    = Enum.Font.RobotoMono,
}

-- TweenInfos
local TI_FAST   = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.4,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.8,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_SPRING = TweenInfo.new(0.6,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_CARD   = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

-- ============================================================
-- MODULE
-- ============================================================
local ShopGUI = {}

-- ── State ────────────────────────────────────────────────────
local playerGUI     = nil
local activeShopGui = nil   -- the ScreenGui currently shown
local activeShopId  = nil
local callbacks     = {}    -- { onBuy, onSell, onPull, onService, onClose }
local toastQueue    = {}
local toastActive   = false

-- ============================================================
-- SHARED UI HELPERS
-- ============================================================

local function makeFrame(parent, size, pos, color, transparency)
	local f = Instance.new("Frame")
	f.Size              = size or UDim2.fromScale(1, 1)
	f.Position          = pos  or UDim2.fromScale(0, 0)
	f.BackgroundColor3  = color or COLORS.Base
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel   = 0
	f.Parent            = parent
	return f
end

local function makeLabel(parent, text, size, pos, color, fontSize, font, alignment)
	local l = Instance.new("TextLabel")
	l.Size              = size or UDim2.fromScale(1, 0.1)
	l.Position          = pos  or UDim2.fromScale(0, 0)
	l.Text              = text or ""
	l.TextColor3        = color or COLORS.TextPrimary
	l.TextSize          = fontSize or 16
	l.Font              = font or FONTS.Body
	l.BackgroundTransparency = 1
	l.TextXAlignment    = alignment or Enum.TextXAlignment.Left
	l.RichText          = true
	l.Parent            = parent
	return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor, fontSize)
	local b = Instance.new("TextButton")
	b.Size             = size or UDim2.fromOffset(120, 36)
	b.Position         = pos  or UDim2.fromScale(0, 0)
	b.Text             = text or "Button"
	b.TextColor3       = textColor or COLORS.Base
	b.BackgroundColor3 = bgColor or COLORS.Gold
	b.TextSize         = fontSize or 15
	b.Font             = FONTS.Header
	b.BorderSizePixel  = 0
	b.AutoButtonColor  = false
	b.Parent           = parent

	-- Hover glow effect
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = b

	b.MouseEnter:Connect(function()
		TS:Create(b, TI_FAST, { BackgroundColor3 = COLORS.Gold:Lerp(Color3.new(1,1,1), 0.15) }):Play()
	end)
	b.MouseLeave:Connect(function()
		TS:Create(b, TI_FAST, { BackgroundColor3 = bgColor or COLORS.Gold }):Play()
	end)

	return b
end

local function makeImage(parent, assetId, size, pos)
	local i = Instance.new("ImageLabel")
	i.Image             = assetId or ""
	i.Size              = size or UDim2.fromScale(1, 1)
	i.Position          = pos  or UDim2.fromScale(0, 0)
	i.BackgroundTransparency = 1
	i.ScaleType         = Enum.ScaleType.Fit
	i.Parent            = parent
	return i
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or COLORS.Gold
	s.Thickness = thickness or 1.5
	s.Parent    = parent
end

-- ============================================================
-- ARCANA CARD FLIP HEADER
-- The signature element: each shop's header is a tarot card
-- that flips from back to front when the shop opens.
-- Uses a fake 3D flip by scaling X 1→0 (back hidden) then
-- swapping the image and scaling 0→1 (face revealed).
-- ============================================================

local function playCardFlip(cardContainer, backId, faceId, onDone)
	local backImg = makeImage(cardContainer, backId, UDim2.fromScale(1, 1))
	local faceImg = makeImage(cardContainer, faceId, UDim2.fromScale(1, 1))
	faceImg.Visible = false

	-- Phase 1: scale X from 1 → 0 (squish to nothing, hiding the back)
	local squish = TS:Create(backImg, TI_CARD, { Size = UDim2.new(0, 0, 1, 0), Position = UDim2.fromScale(0.5, 0) })
	squish:Play()
	squish.Completed:Connect(function()
		backImg.Visible  = false
		faceImg.Visible  = true
		faceImg.Size     = UDim2.new(0, 0, 1, 0)
		faceImg.Position = UDim2.fromScale(0.5, 0)

		-- Phase 2: scale X from 0 → 1 (expand to reveal the face)
		TS:Create(faceImg, TI_CARD, {
			Size     = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
		}):Play()

		if onDone then task.delay(TI_CARD.Time, onDone) end
	end)
end

-- ============================================================
-- TOAST NOTIFICATIONS
-- Queued system — one at a time, slide in from the right
-- ============================================================

local function showToast(message, color)
	table.insert(toastQueue, { message = message, color = color or COLORS.Green })
	if not toastActive then
		task.spawn(function()
			while #toastQueue > 0 do
				toastActive = true
				local entry = table.remove(toastQueue, 1)

				local toast = makeFrame(playerGUI:FindFirstChild("ShopGUI_Active"),
					UDim2.fromOffset(260, 44),
					UDim2.new(1, 20, 0.88, 0),  -- starts off-screen right
					entry.color)
				addCorner(toast, 6)
				makeLabel(toast, entry.message,
					UDim2.fromScale(1, 1),
					UDim2.fromScale(0, 0),
					Color3.new(1, 1, 1), 14, FONTS.Body,
					Enum.TextXAlignment.Center)

				-- Slide in
				TS:Create(toast, TI_SPRING, {
					Position = UDim2.new(1, -280, 0.88, 0)
				}):Play()
				task.wait(2)
				-- Slide out
				TS:Create(toast, TI_MED, {
					Position = UDim2.new(1, 20, 0.88, 0)
				}):Play()
				task.wait(TI_MED.Time + 0.1)
				toast:Destroy()
			end
			toastActive = false
		end)
	end
end

-- ============================================================
-- SHARED SHOP CHROME
-- Builds the container, header, close button, currency bar.
-- Returns { gui, contentArea, currencyLabel }
-- All layouts are built inside contentArea.
-- ============================================================

local function buildChrome(shopId, cfg)
	local gui = Instance.new("ScreenGui")
	gui.Name             = "ShopGUI_Active"
	gui.IgnoreGuiInset   = true
	gui.ResetOnSpawn     = false
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	gui.Enabled          = true
	gui.Parent           = playerGUI

	-- Backdrop (semi-transparent dark overlay)
	local backdrop = makeFrame(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0),
		Color3.new(0, 0, 0), 0.45)

	-- Main panel — centered, 70% width, 80% height
	local panel = makeFrame(gui,
		UDim2.fromScale(0.70, 0.82),
		UDim2.fromScale(0.15, 0.09),
		COLORS.Panel)
	addCorner(panel, 12)
	addStroke(panel, COLORS.Gold, 1.5)

	-- Header bar
	local header = makeFrame(panel,
		UDim2.new(1, 0, 0, 60),
		UDim2.fromScale(0, 0),
		COLORS.Base)
	addCorner(header, 12)

	-- Arcana card (left of header) — flips on open
	local cardContainer = makeFrame(header,
		UDim2.fromOffset(44, 56),
		UDim2.new(0, 8, 0.5, -28),
		Color3.new(0, 0, 0), 1)

	-- Shop display name
	local titleLabel = makeLabel(header,
		cfg.DisplayName,
		UDim2.new(1, -120, 1, 0),
		UDim2.fromOffset(64, 0),
		COLORS.Gold, 22, FONTS.Header,
		Enum.TextXAlignment.Left)

	-- Currency display (top right of header)
	local currencyLabel = makeLabel(header,
		"₡ 0",
		UDim2.fromOffset(140, 36),
		UDim2.new(1, -150, 0.5, -18),
		COLORS.Gold, 18, FONTS.Mono,
		Enum.TextXAlignment.Right)

	-- Close button
	local closeBtn = makeButton(header, "✕",
		UDim2.fromOffset(36, 36),
		UDim2.new(1, -44, 0.5, -18),
		COLORS.Red, Color3.new(1, 1, 1), 18)
	closeBtn.MouseButton1Click:Connect(function()
		if callbacks.onClose then callbacks.onClose() end
	end)

	-- Content area (below header)
	local contentArea = makeFrame(panel,
		UDim2.new(1, 0, 1, -60),
		UDim2.fromOffset(0, 60),
		Color3.new(0, 0, 0), 1)

	-- Animate panel slide in
	panel.Position = UDim2.fromScale(0.15, 1.2)
	TS:Create(panel, TI_SPRING, {
		Position = UDim2.fromScale(0.15, 0.09)
	}):Play()

	-- Play arcana card flip
	local arcanaVisuals = ShopData.ArcanaVisuals
	local backId  = "rbxassetid://CARD_BACK"  -- generic card back
	local faceId  = cfg.ArcanaCard or backId
	task.spawn(function()
		task.wait(0.3)  -- wait for panel slide
		playCardFlip(cardContainer, backId, faceId)
	end)

	return { gui = gui, contentArea = contentArea, currencyLabel = currencyLabel, panel = panel }
end

-- ============================================================
-- ITEM CARD BUILDER
-- Used by most layouts to render a single item entry.
-- ============================================================

local function buildItemCard(parent, itemData, shopId, isRotating)
	local item     = itemData.item
	local price    = itemData.price
	local qty      = itemData.qty
	local itemId   = itemData.itemId
	local rarity   = item.Rarity or 1

	local card = makeFrame(parent,
		UDim2.new(1, -12, 0, 72),
		nil,
		Color3.fromRGB(28, 24, 52))
	addCorner(card, 8)
	addStroke(card, COLORS.Rarity[rarity], 1)

	-- Icon
	local icon = makeImage(card, item.Icon,
		UDim2.fromOffset(56, 56),
		UDim2.new(0, 8, 0.5, -28))

	-- Name
	makeLabel(card, item.Name,
		UDim2.new(1, -130, 0, 22),
		UDim2.fromOffset(72, 8),
		COLORS.TextPrimary, 15, FONTS.Header)

	-- Description (dimmed)
	makeLabel(card,
		item.Description,
		UDim2.new(1, -130, 0, 28),
		UDim2.fromOffset(72, 30),
		COLORS.TextDim, 11, FONTS.Body)

	-- Rarity badge
	local rarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
	makeLabel(card,
		rarityNames[rarity] or "Common",
		UDim2.fromOffset(80, 16),
		UDim2.new(0, 72, 0, 54),
		COLORS.Rarity[rarity], 10, FONTS.Mono)

	-- Rotating badge
	if isRotating then
		local badge = makeLabel(card, "◈ ROTATING",
			UDim2.fromOffset(80, 16),
			UDim2.new(1, -152, 0, 6),
			COLORS.Purple, 9, FONTS.Mono)
	end

	-- Price (right side)
	makeLabel(card, "₡ " .. tostring(price),
		UDim2.fromOffset(90, 22),
		UDim2.new(1, -100, 0.5, -22),
		COLORS.Gold, 16, FONTS.Mono,
		Enum.TextXAlignment.Right)

	-- Stock indicator
	if qty ~= nil then
		makeLabel(card, "Stock: " .. tostring(qty),
			UDim2.fromOffset(80, 18),
			UDim2.new(1, -100, 0.5, 2),
			qty <= 3 and COLORS.Red or COLORS.TextDim, 11, FONTS.Mono,
			Enum.TextXAlignment.Right)
	end

	-- Buy button
	local buyBtn = makeButton(card, "Buy",
		UDim2.fromOffset(70, 30),
		UDim2.new(1, -78, 0.5, -15),
		COLORS.Gold, COLORS.Base, 14)

	buyBtn.MouseButton1Click:Connect(function()
		if callbacks.onBuy then
			callbacks.onBuy(shopId, itemId, 1)
		end
	end)

	return card
end

-- ============================================================
-- LAYOUT: GENERAL STORE
-- Shelf grid with tab switching between fixed and rotating stock
-- ============================================================

local function layoutGeneralStore(contentArea, shopId, stockData)
	-- Tab bar
	local tabBar = makeFrame(contentArea,
		UDim2.new(1, 0, 0, 36),
		UDim2.fromScale(0, 0),
		COLORS.Base)

	local tabAll = makeButton(tabBar, "All Items",
		UDim2.fromOffset(100, 32),
		UDim2.fromOffset(8, 2),
		COLORS.Gold, COLORS.Base, 13)

	local tabRotating = makeButton(tabBar, "◈ Today",
		UDim2.fromOffset(100, 32),
		UDim2.fromOffset(116, 2),
		COLORS.Purple, Color3.new(1,1,1), 13)

	-- Scroll frame for items
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size              = UDim2.new(1, 0, 1, -44)
	scroll.Position          = UDim2.fromOffset(0, 44)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLORS.Gold
	scroll.BorderSizePixel   = 0
	scroll.CanvasSize        = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent            = contentArea

	local itemList = makeFrame(scroll, UDim2.fromScale(1, 0), UDim2.fromScale(0, 0), Color3.new(0,0,0), 1)
	itemList.AutomaticSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding       = UDim.new(0, 6)
	listLayout.Parent        = itemList
	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop    = UDim.new(0, 8)
	listPad.PaddingLeft   = UDim.new(0, 6)
	listPad.PaddingRight  = UDim.new(0, 6)
	listPad.Parent        = itemList

	local function populateList(fixed, rotating)
		for _, child in ipairs(itemList:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		for _, itemData in ipairs(fixed) do
			buildItemCard(itemList, itemData, shopId, false)
		end
		for _, itemData in ipairs(rotating) do
			buildItemCard(itemList, itemData, shopId, true)
		end
	end

	populateList(stockData.fixedItems, stockData.rotatingItems)

	tabAll.MouseButton1Click:Connect(function()
		populateList(stockData.fixedItems, stockData.rotatingItems)
	end)
	tabRotating.MouseButton1Click:Connect(function()
		populateList({}, stockData.rotatingItems)
	end)
end

-- ============================================================
-- LAYOUT: CARD SHOP
-- Each card gets a dramatic tarot-card flip reveal on hover
-- ============================================================

local function layoutCardShop(contentArea, shopId, stockData)
	local allItems = {}
	for _, d in ipairs(stockData.fixedItems)    do table.insert(allItems, d) end
	for _, d in ipairs(stockData.rotatingItems) do table.insert(allItems, d) end

	-- Card grid
	local grid = makeFrame(contentArea, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(0,0,0), 1)
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize    = UDim2.fromOffset(120, 170)
	gridLayout.CellPadding = UDim2.fromOffset(12, 12)
	gridLayout.Parent      = grid
	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop  = UDim.new(0, 16)
	gridPad.PaddingLeft = UDim.new(0, 16)
	gridPad.Parent      = grid

	for _, itemData in ipairs(allItems) do
		local item   = itemData.item
		local itemId = itemData.itemId

		-- Card face-down container
		local cardFrame = makeFrame(grid,
			UDim2.fromOffset(120, 170),
			nil, Color3.fromRGB(20, 16, 36))
		addCorner(cardFrame, 10)
		addStroke(cardFrame, COLORS.Purple, 1.5)

		-- Card back image (shown by default)
		local arcanaVis = item.CardArcana and ShopData.ArcanaVisuals[item.CardArcana]
		local backImg = makeImage(cardFrame, "rbxassetid://CARD_BACK",
			UDim2.fromScale(1, 1))
		local faceImg = makeImage(cardFrame, arcanaVis and arcanaVis.Face or item.Icon,
			UDim2.fromScale(1, 1))
		faceImg.Visible = false

		-- Price shown at bottom
		local priceLabel = makeLabel(cardFrame,
			"₡ " .. tostring(itemData.price),
			UDim2.new(1, 0, 0, 20),
			UDim2.new(0, 0, 1, -22),
			COLORS.Gold, 12, FONTS.Mono,
			Enum.TextXAlignment.Center)

		local revealed = false
		cardFrame.MouseEnter:Connect(function()
			if revealed then return end
			revealed = true
			playCardFlip(cardFrame, "rbxassetid://CARD_BACK",
				arcanaVis and arcanaVis.Face or item.Icon)
		end)

		-- Click on revealed card = buy prompt
		cardFrame.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if not revealed then return end
			if callbacks.onBuy then
				callbacks.onBuy(shopId, itemId, 1)
			end
		end)
	end
end

-- ============================================================
-- LAYOUT: AURA PARLOR
-- Character preview pane + aura list with live VFX preview
-- ============================================================

local function layoutAuraParlor(contentArea, shopId, stockData)
	-- Left: character preview viewport (TODO: hook to AuraSystem.preview)
	local previewPane = makeFrame(contentArea,
		UDim2.fromScale(0.4, 1),
		UDim2.fromScale(0, 0),
		Color3.fromRGB(10, 8, 22))
	addStroke(previewPane, COLORS.Purple, 1)

	makeLabel(previewPane, "AURA PREVIEW",
		UDim2.fromScale(1, 0.06),
		UDim2.fromScale(0, 0),
		COLORS.TextDim, 11, FONTS.Mono,
		Enum.TextXAlignment.Center)

	-- TODO: instantiate a ViewportFrame here with a clone of the player's character
	-- and call AuraSystem.previewOnViewport(viewportFrame, auraVFXKey) on hover
	local vpLabel = makeLabel(previewPane,
		"[Character Preview]\nHover an aura to preview",
		UDim2.fromScale(0.8, 0.3),
		UDim2.fromScale(0.1, 0.35),
		COLORS.TextDim, 13, FONTS.Body,
		Enum.TextXAlignment.Center)

	-- Right: aura list
	local listPane = makeFrame(contentArea,
		UDim2.fromScale(0.58, 1),
		UDim2.fromScale(0.42, 0),
		Color3.new(0,0,0), 1)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLORS.Purple
	scroll.BorderSizePixel = 0
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.Parent = listPane

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent  = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = scroll

	local allItems = {}
	for _, d in ipairs(stockData.fixedItems)    do table.insert(allItems, d) end
	for _, d in ipairs(stockData.rotatingItems) do table.insert(allItems, d) end

	for _, itemData in ipairs(allItems) do
		local item   = itemData.item
		local auraVFX = item.AuraVFX
		local card = buildItemCard(scroll, itemData, shopId, false)

		-- Hover preview
		card.MouseEnter:Connect(function()
			-- TODO: AuraSystem.previewOnViewport(vpFrame, auraVFX)
			vpLabel.Text = string.format("[%s]\n%s",
				item.Name, item.Description)
		end)
		card.MouseLeave:Connect(function()
			vpLabel.Text = "[Character Preview]\nHover an aura to preview"
		end)
	end
end

-- ============================================================
-- LAYOUT: GACHA / CAPSULE
-- Pull button, pity counter, reveal animation
-- ============================================================

local function layoutGacha(contentArea, shopId, stockData)
	-- Capsule machine visual (centered)
	local centerPane = makeFrame(contentArea, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0),
		Color3.new(0,0,0), 1)

	makeLabel(centerPane, "THE CAPSULE",
		UDim2.fromScale(1, 0.08),
		UDim2.fromScale(0, 0.04),
		COLORS.Gold, 26, FONTS.Header,
		Enum.TextXAlignment.Center)

	-- Pity counter
	local pityLabel = makeLabel(centerPane,
		"Pity: " .. tostring(stockData.pityLeft or "?") .. " pulls until rare+",
		UDim2.fromScale(0.6, 0.05),
		UDim2.fromScale(0.2, 0.13),
		COLORS.TextDim, 13, FONTS.Mono,
		Enum.TextXAlignment.Center)

	-- Cost label
	makeLabel(centerPane,
		"₡ " .. tostring(stockData.pullCost or 300) .. " per pull",
		UDim2.fromScale(0.4, 0.05),
		UDim2.fromScale(0.3, 0.82),
		COLORS.Gold, 15, FONTS.Mono,
		Enum.TextXAlignment.Center)

	-- Result display area
	local resultFrame = makeFrame(centerPane,
		UDim2.fromOffset(180, 220),
		UDim2.fromScale(0.5, 0.22),
		Color3.fromRGB(20, 16, 36))
	resultFrame.AnchorPoint = Vector2.new(0.5, 0)
	resultFrame.Position    = UDim2.fromScale(0.5, 0.22)
	addCorner(resultFrame, 12)
	addStroke(resultFrame, COLORS.Purple, 2)

	local resultIcon = makeImage(resultFrame, "", UDim2.fromScale(0.6, 0.55),
		UDim2.fromScale(0.2, 0.05))
	local resultName = makeLabel(resultFrame, "???",
		UDim2.fromScale(1, 0.15),
		UDim2.fromScale(0, 0.62),
		COLORS.TextPrimary, 16, FONTS.Header,
		Enum.TextXAlignment.Center)
	local resultRarity = makeLabel(resultFrame, "",
		UDim2.fromScale(1, 0.12),
		UDim2.fromScale(0, 0.78),
		COLORS.TextDim, 12, FONTS.Mono,
		Enum.TextXAlignment.Center)

	-- Pull button
	local pullBtn = makeButton(centerPane, "PULL  ◈",
		UDim2.fromOffset(180, 48),
		UDim2.fromScale(0.5, 0.87),
		COLORS.Purple, Color3.new(1,1,1), 18)
	pullBtn.AnchorPoint = Vector2.new(0.5, 0)

	pullBtn.MouseButton1Click:Connect(function()
		pullBtn.Active = false
		-- Flash the result frame
		TS:Create(resultFrame, TI_FAST, { BackgroundColor3 = COLORS.Purple }):Play()
		task.wait(0.15)
		TS:Create(resultFrame, TI_MED, { BackgroundColor3 = Color3.fromRGB(20, 16, 36) }):Play()

		if callbacks.onPull then
			local result = callbacks.onPull(shopId)
			if result and result.ok then
				local wonItem = ShopData.Items[result.itemId]
				if wonItem then
					resultIcon.Image  = wonItem.Icon
					resultName.Text   = wonItem.Name
					local rarity = wonItem.Rarity or 1
					local rarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
					resultRarity.Text       = rarityNames[rarity]
					resultRarity.TextColor3 = COLORS.Rarity[rarity]
					-- Bounce the result frame
					TS:Create(resultFrame, TI_SPRING, {
						Size = UDim2.fromOffset(196, 236)
					}):Play()
					task.delay(0.6, function()
						TS:Create(resultFrame, TI_FAST, { Size = UDim2.fromOffset(180, 220) }):Play()
					end)
					-- Update pity
					pityLabel.Text = "Pity: " .. tostring(result.pityLeft) .. " pulls until rare+"
				end
			end
		end
		pullBtn.Active = true
	end)
end

-- ============================================================
-- LAYOUT: FORTUNE PARLOR
-- Card spread layout, each fortune is a face-down card to flip
-- ============================================================

local function layoutFortuneParlor(contentArea, shopId, stockData)
	makeLabel(contentArea, "Draw your fortune.",
		UDim2.fromScale(1, 0.08),
		UDim2.fromScale(0, 0.04),
		COLORS.TextDim, 14, FONTS.Body,
		Enum.TextXAlignment.Center)

	local fortunes = stockData.fortunes or {}
	local spread   = makeFrame(contentArea, UDim2.fromScale(1, 0.65), UDim2.fromScale(0, 0.15),
		Color3.new(0,0,0), 1)

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize    = UDim2.fromOffset(150, 200)
	gridLayout.CellPadding = UDim2.fromOffset(20, 0)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = spread

	for _, fortune in ipairs(fortunes) do
		local cardF = makeFrame(spread, UDim2.fromOffset(150, 200), nil,
			Color3.fromRGB(15, 12, 28))
		addCorner(cardF, 10)
		addStroke(cardF, COLORS.Gold, 1.5)

		local backImg = makeImage(cardF, "rbxassetid://CARD_BACK",
			UDim2.fromScale(1, 0.75))
		local faceImg = makeImage(cardF, fortune.Icon,
			UDim2.fromScale(1, 0.75))
		faceImg.Visible = false

		local nameLabel = makeLabel(cardF, "???",
			UDim2.fromScale(1, 0.12),
			UDim2.new(0, 0, 0.76, 0),
			COLORS.TextDim, 13, FONTS.Header,
			Enum.TextXAlignment.Center)

		local priceLabel = makeLabel(cardF, "",
			UDim2.fromScale(1, 0.10),
			UDim2.new(0, 0, 0.88, 0),
			COLORS.Gold, 13, FONTS.Mono,
			Enum.TextXAlignment.Center)

		local revealed = false
		cardF.MouseEnter:Connect(function()
			if revealed then return end
			revealed = true
			playCardFlip(cardF, "rbxassetid://CARD_BACK", fortune.Icon, function()
				nameLabel.Text  = fortune.DisplayName
				priceLabel.Text = "₡ " .. tostring(fortune.Price)
			end)
		end)

		cardF.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if not revealed then return end
			if callbacks.onService then
				callbacks.onService(shopId, fortune.Id)
			end
		end)
	end
end

-- ============================================================
-- LAYOUT ROUTER
-- Maps shop Type → layout builder function
-- ============================================================

local LAYOUTS = {
	GeneralStore  = layoutGeneralStore,
	Armory        = layoutGeneralStore,   -- same shelf grid; stat comparison panel TODO
	Boutique      = layoutGeneralStore,   -- TODO: mannequin preview
	AuraParlor    = layoutAuraParlor,
	CardShop      = layoutCardShop,
	SkillShop     = layoutGeneralStore,   -- TODO: skill preview panel
	Pharmacy      = layoutGeneralStore,   -- TODO: service buttons
	PawnShop      = layoutGeneralStore,   -- TODO: sell tab
	Restaurant    = layoutGeneralStore,   -- TODO: menu card + time filter
	MusicShop     = layoutGeneralStore,   -- TODO: BGM preview button
	FortuneParlor = layoutFortuneParlor,
	Gacha         = layoutGacha,
}

-- ============================================================
-- PUBLIC API
-- ============================================================

function ShopGUI.init(gui)
	playerGUI = gui
end

function ShopGUI.open(shopId, cfg, stockData, cbs)
	-- Close any existing shop UI first
	ShopGUI.close()

	callbacks    = cbs or {}
	activeShopId = shopId

	-- Build chrome (container, header, close btn, currency)
	local chrome = buildChrome(shopId, cfg)
	activeShopGui = chrome.gui

	-- Update currency display
	chrome.currencyLabel.Text = "₡ " .. tostring(stockData.currency or 0)

	-- Build the layout inside contentArea
	local layoutFn = LAYOUTS[cfg.Type] or layoutGeneralStore
	layoutFn(chrome.contentArea, shopId, stockData)
end

function ShopGUI.close(shopId)
	if activeShopGui then
		local panel = activeShopGui:FindFirstChildWhichIsA("Frame")
		if panel then
			TS:Create(panel, TI_MED, {
				Position = UDim2.fromScale(0.15, 1.2)
			}):Play()
		end
		task.delay(TI_MED.Time + 0.05, function()
			if activeShopGui then
				activeShopGui:Destroy()
				activeShopGui = nil
			end
		end)
	end
	activeShopId = nil
	callbacks    = {}
end

-- ── Transaction feedback callbacks ───────────────────────────

function ShopGUI.onBuySuccess(shopId, itemId, qty, price)
	local item = ShopData.Items[itemId]
	showToast("Bought " .. (item and item.Name or itemId) .. " for ₡" .. tostring(price), COLORS.Green)
end

function ShopGUI.onSellSuccess(shopId, itemId, qty, payout)
	local item = ShopData.Items[itemId]
	showToast("Sold for ₡" .. tostring(payout), COLORS.Purple)
end

function ShopGUI.onPullResult(shopId, result)
	-- handled inline by the Gacha layout
end

function ShopGUI.onServiceSuccess(shopId, serviceId)
	showToast("Service applied!", COLORS.Green)
end

function ShopGUI.onTransactionError(errCode)
	local messages = {
		InsufficientFunds   = "Not enough ₡.",
		StackLimitReached   = "You can't carry any more of that.",
		InsufficientStock   = "Out of stock.",
		InsufficientItems   = "You don't have enough of that.",
		SellNotAllowed      = "This shop doesn't buy items.",
		ItemUnavailable     = "This item can't be purchased.",
		RequirementNotMet   = "You haven't unlocked this yet.",
	}
	showToast(messages[errCode] or ("Error: " .. tostring(errCode)), COLORS.Red)
end

return ShopGUI
