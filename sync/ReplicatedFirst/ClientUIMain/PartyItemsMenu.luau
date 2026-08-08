--[[
	PartyItemsMenu
	----------------
	The merged "party & items" screen: StarterGui.PartyItemsGui, dark obsidian/gold to match
	SlotSelectGui, using the roster-card layout (portrait, level, HP/SP bars) borrowed from your
	ItemsUI SquadFrame mockup, plus the item grid + detail panel from ItemsMenu.

	Click a teammate or your own (bigger) card to see their details. Click the small persona
	thumbnail on any card's portrait corner to see THAT character's persona details instead.
	Click an item to select it -- once both an item and a character are selected, the action
	button becomes "GIVE TO <name>" and fires onUseItem when clicked.

	Usage:
		PartyItemsMenu.Open({
			Items = {
				{ItemId = "Apple", Name = "Apple", Image = "rbxassetid://...", Description = "Restores a little HP.", Rarity = "Basic", Quantity = 3},
			},
			Player = {
				Name = "You", Level = 12, HP = 80, MaxHP = 100, SP = 30, MaxSP = 40,
				Portrait = "rbxassetid://...",
				Persona = {Name = "Angel", Image = "rbxassetid://...", Description = "...", Rarity = "Rare"},
			},
			Teammates = {
				{Name = "Timmy", Level = 8, HP = 40, MaxHP = 50, SP = 10, MaxSP = 10,
				 Portrait = "rbxassetid://...",
				 Persona = {Name = "Balloon", Image = "rbxassetid://...", Description = "..."}},
			},
		}, function(itemId, targetName)
			print("give", itemId, "to", targetName)
		end)

		PartyItemsMenu.Close()

	Every field on every entry is optional and degrades gracefully -- Persona, Portrait,
	Description, Rarity, Quantity can all be omitted.
]]

local TS = game:GetService("TweenService")
local PLRS = game:GetService("Players")

local plr = PLRS.LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")

local ClientUIMain = script.Parent
local AnimsManager = require(ClientUIMain.GUIMaster.Animations)

local PartyItemsMenu = {}

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
local COL_CARD = Color3.fromRGB(26, 26, 40)
local COL_CARD_HOVER = Color3.fromRGB(36, 33, 48)

local function rarityColor(rarity)
	return (rarity and RARITY_COLORS[rarity]) or COL_STROKE_IDLE
end

local gui, backdrop, panel, closeButton
local itemsGrid, itemCardTemplate
local playerCard, teamList, teammateTemplate
local detail, detailKindTag, detailIcon, detailIconStroke, detailName, detailSubtitle, detailDesc, actionButton

local function bindRefs()
	if gui and gui.Parent then return end
	gui = plrGui:WaitForChild("PartyItemsGui")
	backdrop = gui:WaitForChild("Backdrop")
	panel = backdrop:WaitForChild("Panel")
	closeButton = panel.TitleBar:WaitForChild("CloseButton")

	local body = panel:WaitForChild("Body")

	local itemsCol = body:WaitForChild("ItemsColumn")
	itemsGrid = itemsCol:WaitForChild("Grid")
	itemCardTemplate = itemsGrid:WaitForChild("ItemCardTemplate")

	local rosterCol = body:WaitForChild("RosterColumn")
	playerCard = rosterCol.PlayerArea:WaitForChild("PlayerCard")
	teamList = rosterCol:WaitForChild("TeamList")
	teammateTemplate = teamList:WaitForChild("TeammateCardTemplate")

	detail = body:WaitForChild("Detail")
	detailKindTag = detail:WaitForChild("KindTag")
	detailIcon = detail:WaitForChild("Icon")
	detailIconStroke = detailIcon:WaitForChild("AccentStroke")
	detailName = detail:WaitForChild("NameLabel")
	detailSubtitle = detail:WaitForChild("SubtitleLabel")
	detailDesc = detail:WaitForChild("DescriptionLabel")
	actionButton = detail:WaitForChild("ActionButton")

	closeButton.MouseButton1Click:Connect(function() PartyItemsMenu.Close() end)
	backdrop.MouseButton1Click:Connect(function() PartyItemsMenu.Close() end)
	panel.Active = true
end

-- ============== state ==============
local activeItemCards = {}
local activeTeammateCards = {}
local selectedItemButton, selectedItemData = nil, nil
local selectedCharButton, selectedCharName = nil, nil
local currentOnUse = nil
local actionButtonConn = nil

local function setCardSelected(button, selected, isBig)
	local stroke = button:FindFirstChild("SelectStroke")
	if not stroke then return end
	if isBig then
		-- the player's card is always gold-stroked (it's already "its own area") -- selection
		-- just thickens it further
		TS:Create(stroke, AnimsManager.STIS.FadeIn, {Thickness = selected and 3 or 2}):Play()
	else
		TS:Create(stroke, AnimsManager.STIS.FadeIn, {
			Color = selected and COL_GOLD or COL_STROKE_IDLE,
			Thickness = selected and 2.5 or 1.5,
		}):Play()
	end
end

local function updateActionButton()
	if actionButtonConn then
		actionButtonConn:Disconnect()
		actionButtonConn = nil
	end

	if selectedItemData and selectedCharName and currentOnUse then
		actionButton.Text = "GIVE TO " .. string.upper(selectedCharName)
		actionButton.Visible = true
		actionButtonConn = actionButton.MouseButton1Click:Connect(function()
			currentOnUse(selectedItemData.ItemId, selectedCharName)
		end)
	else
		actionButton.Visible = false
	end
end

local function showItemDetail(itemData)
	detailKindTag.Text = "ITEM"
	detailIcon.Image = itemData.Image or ""
	detailIconStroke.Color = rarityColor(itemData.Rarity)
	detailName.Text = itemData.Name or itemData.ItemId or ""
	detailSubtitle.Text = itemData.Rarity and string.upper(itemData.Rarity) or ""
	detailSubtitle.TextColor3 = rarityColor(itemData.Rarity)
	detailDesc.Text = itemData.Description or ""
	updateActionButton()
end

local function showCharDetail(kindLabel, charData)
	detailKindTag.Text = kindLabel
	detailIcon.Image = charData.Portrait or ""
	detailIconStroke.Color = COL_GOLD
	detailName.Text = charData.Name or ""
	detailSubtitle.Text = charData.Level and ("LV " .. tostring(charData.Level)) or ""
	detailSubtitle.TextColor3 = COL_GOLD

	local hpLine = (charData.HP and charData.MaxHP) and ("HP " .. tostring(charData.HP) .. "/" .. tostring(charData.MaxHP)) or nil
	local spLine = (charData.SP and charData.MaxSP) and ("SP " .. tostring(charData.SP) .. "/" .. tostring(charData.MaxSP)) or nil
	local lines = {}
	if hpLine then table.insert(lines, hpLine) end
	if spLine then table.insert(lines, spLine) end
	detailDesc.Text = table.concat(lines, "\n")

	updateActionButton()
end

local function showPersonaDetail(personaData)
	if not personaData then return end
	detailKindTag.Text = "PERSONA"
	detailIcon.Image = personaData.Image or ""
	detailIconStroke.Color = rarityColor(personaData.Rarity)
	detailName.Text = personaData.Name or ""
	detailSubtitle.Text = personaData.Rarity and string.upper(personaData.Rarity) or ""
	detailSubtitle.TextColor3 = rarityColor(personaData.Rarity)
	detailDesc.Text = personaData.Description or ""
	-- viewing a persona doesn't change the item-assignment target, but the action button context
	-- (if an item + character are already picked) should stay visible/usable underneath
	if selectedItemData and selectedCharName and currentOnUse then
		updateActionButton()
	else
		actionButton.Visible = false
	end
end

local function selectItemCard(button, itemData)
	if selectedItemButton and selectedItemButton ~= button then
		local prevStroke = selectedItemButton:FindFirstChild("RarityStroke")
		if prevStroke then TS:Create(prevStroke, AnimsManager.STIS.FadeIn, {Thickness = 1.5}):Play() end
	end
	selectedItemButton = button
	selectedItemData = itemData
	local stroke = button:FindFirstChild("RarityStroke")
	if stroke then TS:Create(stroke, AnimsManager.STIS.FadeIn, {Thickness = 2.5}):Play() end
	showItemDetail(itemData)
end

local function selectCharCard(button, isBig, kindLabel, charData)
	if selectedCharButton and selectedCharButton ~= button then
		local wasBig = selectedCharButton == playerCard
		setCardSelected(selectedCharButton, false, wasBig)
	end
	selectedCharButton = button
	selectedCharName = charData.Name
	setCardSelected(button, true, isBig)
	showCharDetail(kindLabel, charData)
end

-- ============== card builders ==============
local function wireRosterCard(button, isBig, kindLabel, charData)
	local portrait = button:WaitForChild("Portrait")
	local fallbackIcon = portrait:WaitForChild("FallbackIcon")
	fallbackIcon.Image = charData.Portrait or ""

	local info = button:WaitForChild("Info")
	info.NameLabel.Text = charData.Name or ""
	info.LevelLabel.Text = charData.Level and tostring(charData.Level) or ""

	if charData.HP and charData.MaxHP then
		local frac = charData.MaxHP > 0 and math.clamp(charData.HP / charData.MaxHP, 0, 1) or 0
		info.HPOuter.HPInner.Size = UDim2.new(frac, 0, 1, 0)
		local hpLabel = info.HPOuter:FindFirstChild("HPLabel")
		if hpLabel then hpLabel.Text = tostring(charData.HP) .. "/" .. tostring(charData.MaxHP) end
	end
	if charData.SP and charData.MaxSP then
		local frac = charData.MaxSP > 0 and math.clamp(charData.SP / charData.MaxSP, 0, 1) or 0
		info.SPOuter.SPInner.Size = UDim2.new(frac, 0, 1, 0)
		local spLabel = info.SPOuter:FindFirstChild("SPLabel")
		if spLabel then spLabel.Text = tostring(charData.SP) .. "/" .. tostring(charData.MaxSP) end
	end

	local personaThumb = portrait:WaitForChild("PersonaThumb")
	if charData.Persona then
		personaThumb.Image = charData.Persona.Image or ""
		personaThumb.Visible = true
		personaThumb.MouseButton1Click:Connect(function()
			showPersonaDetail(charData.Persona)
		end)
	else
		personaThumb.Visible = false
	end

	button.MouseButton1Click:Connect(function()
		selectCharCard(button, isBig, kindLabel, charData)
	end)

	if not isBig then
		button.MouseEnter:Connect(function()
			if selectedCharButton ~= button then
				TS:Create(button, AnimsManager.STIS.FadeIn, {BackgroundColor3 = COL_CARD_HOVER}):Play()
			end
		end)
		button.MouseLeave:Connect(function()
			if selectedCharButton ~= button then
				TS:Create(button, AnimsManager.STIS.FadeIn, {BackgroundColor3 = COL_CARD}):Play()
			end
		end)
	end
end

local function buildItemCard(itemData, index)
	local card = itemCardTemplate:Clone()
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
		if selectedItemButton ~= card then
			TS:Create(card, AnimsManager.STIS.FadeIn, {BackgroundColor3 = COL_CARD_HOVER}):Play()
		end
	end)
	card.MouseLeave:Connect(function()
		if selectedItemButton ~= card then
			TS:Create(card, AnimsManager.STIS.FadeIn, {BackgroundColor3 = COL_CARD}):Play()
		end
	end)
	card.MouseButton1Click:Connect(function()
		selectItemCard(card, itemData)
	end)

	card.Parent = itemsGrid
	table.insert(activeItemCards, card)
end

local function clearDynamicCards()
	for _, card in ipairs(activeItemCards) do card:Destroy() end
	activeItemCards = {}
	for _, card in ipairs(activeTeammateCards) do card:Destroy() end
	activeTeammateCards = {}
	selectedItemButton, selectedItemData = nil, nil
	selectedCharButton, selectedCharName = nil, nil
end

-- ============== public API ==============
function PartyItemsMenu.Open(data, onUse)
	bindRefs()
	clearDynamicCards()
	currentOnUse = onUse

	detailKindTag.Text = ""
	detailName.Text = ""
	detailSubtitle.Text = ""
	detailDesc.Text = "Select an item, teammate, or persona to see details here."
	detailIcon.Image = ""
	detailIconStroke.Color = COL_STROKE_IDLE
	actionButton.Visible = false

	if data.Player then
		wireRosterCard(playerCard, true, "YOU", data.Player)
	end

	for i, teammateData in ipairs(data.Teammates or {}) do
		local card = teammateTemplate:Clone()
		card.Name = "Teammate_" .. tostring(i)
		card.Visible = true
		card.LayoutOrder = i
		wireRosterCard(card, false, "TEAMMATE", teammateData)
		card.Parent = teamList
		table.insert(activeTeammateCards, card)
	end

	for i, itemData in ipairs(data.Items or {}) do
		buildItemCard(itemData, i)
	end

	gui.Enabled = true
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.new(0.8, 0, 0.76, 0)
	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	backdrop.BackgroundTransparency = 1

	TS:Create(backdrop, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 0.45}):Play()
	TS:Create(panel, AnimsManager.STIS.FadeInMid or AnimsManager.STIS.FadeIn, {
		BackgroundTransparency = 0,
		Size = UDim2.new(0.86, 0, 0.82, 0),
	}):Play()
	if panelStroke then
		TS:Create(panelStroke, AnimsManager.STIS.FadeIn, {Transparency = 0}):Play()
	end
end

function PartyItemsMenu.Close()
	if not gui or not gui.Enabled then return end

	if actionButtonConn then
		actionButtonConn:Disconnect()
		actionButtonConn = nil
	end

	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	local outTween = TS:Create(panel, AnimsManager.STIS.FadeIn, {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.8, 0, 0.76, 0),
	})
	outTween:Play()
	TS:Create(backdrop, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 1}):Play()
	if panelStroke then
		TS:Create(panelStroke, AnimsManager.STIS.FadeIn, {Transparency = 1}):Play()
	end
	outTween.Completed:Wait()

	if gui then gui.Enabled = false end
	clearDynamicCards()
	currentOnUse = nil
end

return PartyItemsMenu
