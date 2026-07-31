-- ============================================================
-- ShopService (ModuleScript — ServerScriptService or required by server Script)
-- Handles all server-side shop logic:
--   • Shop registration and instance management
--   • Buy / Sell / Service transactions
--   • Rotating inventory refresh (per-shop timers)
--   • Story/quest flag gating
--   • Pity system tracking (for Gacha)
--   • RemoteFunction bridge to ShopClient
--
-- REMOTES (expected in ReplicatedStorage.ShopRemotes):
--   ShopOpen    (RemoteFunction)  — client requests to open a shop
--   ShopBuy     (RemoteFunction)  — client requests to buy item/service
--   ShopSell    (RemoteFunction)  — client requests to sell item
--   ShopPull    (RemoteFunction)  — client requests a gacha pull
--   ShopGetStock (RemoteFunction) — client requests current rotating stock
--
-- TODO: replace PlayerInventory calls with your actual inventory module
-- TODO: replace PlayerData calls with your actual data store
-- ============================================================

-- Services
local RPS    = game:GetService("ReplicatedStorage")
local PLRS   = game:GetService("Players")
local RS     = game:GetService("RunService")

-- Dependencies
local ShopData = require(RPS:WaitForChild("ClientStorage"):WaitForChild("Info"):WaitForChild("ShopData"))

local SS = game:GetService("ServerStorage")
local odm = require(SS:WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local PersonaData = require(RPS:WaitForChild("ClientStorage"):WaitForChild("Classes"):WaitForChild("PersonaClientSide"):WaitForChild("PersonaData"))

-- Remotes — expected to already exist in ReplicatedStorage
local ShopRemotes   = RPS:WaitForChild("ShopRemotes")
local RF_Open       = ShopRemotes:WaitForChild("ShopOpen")       -- RemoteFunction
local RF_Buy        = ShopRemotes:WaitForChild("ShopBuy")        -- RemoteFunction
local RF_Sell       = ShopRemotes:WaitForChild("ShopSell")       -- RemoteFunction
local RF_Pull       = ShopRemotes:WaitForChild("ShopPull")       -- RemoteFunction
local RF_GetStock   = ShopRemotes:WaitForChild("ShopGetStock")   -- RemoteFunction

-- ============================================================
-- MODULE
-- ============================================================
local ShopService = {}

-- ── Internal state ───────────────────────────────────────────
-- registeredShops[shopId] = { config, currentRotating, rotationTimestamp, ... }
local registeredShops = {}

-- pityTrackers[plr][shopId] = { pullCount, lastRareAt }
local pityTrackers = {}

-- ============================================================
-- HELPERS
-- ============================================================

local function getItem(itemId)
	return ShopData.Items[itemId]
end

local function getShopConfig(shopId)
	return ShopData.Shops[shopId]
end

-- Get a player's currency balance
local function getCurrency(plr)
	local pData = odm.PlayerData[plr]
	return pData and pData.Data.Euros.Data or 0
end

-- Add/subtract currency
local function modifyCurrency(plr, amount)
	local pData = odm.PlayerData[plr]
	if not pData then return end
	if amount > 0 then
		pData.Data.Euros:Increase(amount)
	elseif amount < 0 then
		pData.Data.Euros:Decrease(-amount)
	end
end

-- Check a story/quest flag on the player
local function hasFlag(plr, flagName)
	if not flagName then return true end
	-- fallback to attribute or check quests
	return plr:GetAttribute(flagName) == true
end

-- Add item to player inventory
local function addItem(plr, itemId, qty)
	qty = qty or 1
	local pData = odm.PlayerData[plr]
	if pData then
		pData.Data.Inventory:AddItem(itemId, qty)
	end
	return true
end

-- Remove item from player inventory
local function removeItem(plr, itemId, qty)
	qty = qty or 1
	local pData = odm.PlayerData[plr]
	if pData then
		pData.Data.Inventory:RemoveItem(itemId, qty)
	end
	return true
end

-- Get item quantity in player inventory
local function getItemQty(plr, itemId)
	local pData = odm.PlayerData[plr]
	if pData and pData.Data.Inventory.Data[1][itemId] then
		return pData.Data.Inventory.Data[1][itemId].Amount
	end
	return 0
end

-- ============================================================
-- ROTATING INVENTORY
-- ============================================================

local ROTATION_INTERVALS = {
	daily     = 24 * 60 * 60,   -- seconds
	hourly    = 60 * 60,
	ondungeon = nil,             -- manual trigger, not time-based
}

-- Pick N random items from a pool (no duplicates)
local function pickRotatingItems(pool, slots)
	if #pool == 0 or slots == 0 then return {} end
	local shuffled = table.clone(pool)
	-- Fisher-Yates shuffle
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	local result = {}
	for i = 1, math.min(slots, #shuffled) do
		table.insert(result, shuffled[i])
	end
	return result
end

local function shouldRotate(shopState)
	local cfg = shopState.config
	if not cfg.RotationInterval or cfg.RotationSlots == 0 then return false end
	if cfg.RotationInterval == "ondungeon" then return false end

	local interval = ROTATION_INTERVALS[cfg.RotationInterval]
		or (tonumber(cfg.RotationInterval) and tonumber(cfg.RotationInterval) * 60)
	if not interval then return false end

	return (os.time() - (shopState.lastRotation or 0)) >= interval
end

local function rotateShop(shopId)
	local state = registeredShops[shopId]
	if not state then return end
	local cfg = state.config
	state.currentRotating = pickRotatingItems(cfg.RotatingStock or {}, cfg.RotationSlots or 0)
	state.lastRotation    = os.time()
	-- Reset per-slot quantities for limited rotating stock
	state.rotatingQty = {}
	for _, itemId in ipairs(state.currentRotating) do
		local item = getItem(itemId)
		state.rotatingQty[itemId] = item and item.RotatingQty or nil  -- nil = unlimited
	end
end

-- ============================================================
-- SHOP REGISTRATION
-- ============================================================

-- Called at server startup (or dynamically when a shop NPC is loaded)
-- shopId = key in ShopData.Shops
function ShopService.register(shopId)
	if registeredShops[shopId] then return end  -- already registered

	local cfg = getShopConfig(shopId)
	if not cfg then
		warn("ShopService.register: unknown shopId '" .. shopId .. "'")
		return
	end

	-- Build fixed stock quantity tracker
	-- nil = unlimited; number = limited stock
	local fixedQty = {}
	for itemId, qty in pairs(cfg.FixedStock or {}) do
		fixedQty[itemId] = qty  -- nil means unlimited
	end

	registeredShops[shopId] = {
		config          = cfg,
		fixedQty        = fixedQty,
		currentRotating = {},
		rotatingQty     = {},
		lastRotation    = 0,
	}

	-- Initial rotation
	rotateShop(shopId)

	print("ShopService: registered '" .. shopId .. "' (" .. cfg.Type .. ")")
end

-- Register all shops defined in ShopData at once
function ShopService.registerAll()
	for shopId in pairs(ShopData.Shops) do
		ShopService.register(shopId)
	end
end

-- ============================================================
-- TRANSACTION CORE
-- ============================================================

-- Returns { ok=bool, err=string, finalPrice=number }
local function validateBuy(plr, shopId, itemId, qty)
	qty = qty or 1

	local state = registeredShops[shopId]
	if not state then return { ok = false, err = "ShopNotFound" } end

	local cfg  = state.config
	local item = getItem(itemId)
	if not item then return { ok = false, err = "ItemNotFound" } end

	-- Unbuyable items (e.g. The World card)
	if item.Unbuyable then return { ok = false, err = "ItemUnavailable" } end

	-- Story gate check
	if not hasFlag(plr, cfg.RequiredFlag) then
		return { ok = false, err = "RequirementNotMet" }
	end

	-- Is the item in this shop's stock?
	local inFixed    = cfg.FixedStock and cfg.FixedStock[itemId] ~= nil
	local inRotating = false
	for _, rid in ipairs(state.currentRotating) do
		if rid == itemId then inRotating = true break end
	end
	if not inFixed and not inRotating then
		return { ok = false, err = "ItemNotInStock" }
	end

	-- Quantity check (limited stock)
	if inFixed and state.fixedQty[itemId] ~= nil then
		if state.fixedQty[itemId] < qty then
			return { ok = false, err = "InsufficientStock" }
		end
	end
	if inRotating and state.rotatingQty[itemId] ~= nil then
		if state.rotatingQty[itemId] < qty then
			return { ok = false, err = "InsufficientStock" }
		end
	end

	-- Stack limit check
	if item.StackLimit then
		local owned = getItemQty(plr, itemId)
		if owned + qty > item.StackLimit then
			return { ok = false, err = "StackLimitReached" }
		end
	end

	-- Price calculation
	local basePrice  = item.Price * (cfg.Markup or 1)
	local finalPrice = math.floor(basePrice * qty)

	-- Currency check
	if getCurrency(plr) < finalPrice then
		return { ok = false, err = "InsufficientFunds" }
	end

	return { ok = true, finalPrice = finalPrice, inFixed = inFixed, inRotating = inRotating }
end

function ShopService.buyItem(plr, shopId, itemId, qty)
	qty = qty or 1
	local result = validateBuy(plr, shopId, itemId, qty)
	if not result.ok then return result end

	local state = registeredShops[shopId]

	-- Deduct currency
	modifyCurrency(plr, -result.finalPrice)

	-- Give item
	addItem(plr, itemId, qty)

	-- Decrement limited stock
	if result.inFixed and state.fixedQty[itemId] ~= nil then
		state.fixedQty[itemId] -= qty
	end
	if result.inRotating and state.rotatingQty[itemId] ~= nil then
		state.rotatingQty[itemId] -= qty
	end

	-- Quest event hook — TODO: fire to your quest/achievement system
	-- QuestService.onItemPurchased(plr, itemId, qty)

	print(string.format("ShopService: %s bought %dx %s from %s for %d",
		plr.Name, qty, itemId, shopId, result.finalPrice))

	return { ok = true, finalPrice = result.finalPrice }
end

function ShopService.sellItem(plr, shopId, itemId, qty)
	qty = qty or 1
	local state = registeredShops[shopId]
	if not state then return { ok = false, err = "ShopNotFound" } end

	local cfg  = state.config
	local item = getItem(itemId)
	if not item then return { ok = false, err = "ItemNotFound" } end

	if not cfg.SellEnabled then return { ok = false, err = "SellNotAllowed" } end
	if item.SellPrice == 0  then return { ok = false, err = "ItemNotSellable" } end

	-- Inventory check
	if getItemQty(plr, itemId) < qty then
		return { ok = false, err = "InsufficientItems" }
	end

	local payout = math.floor(item.SellPrice * (cfg.SellMultiplier or 0.5) * qty)

	removeItem(plr, itemId, qty)
	modifyCurrency(plr, payout)

	return { ok = true, payout = payout }
end

-- ── Service purchase (e.g. pharmacy Full Recovery) ───────────
function ShopService.buyService(plr, shopId, serviceId)
	local state = registeredShops[shopId]
	if not state then return { ok = false, err = "ShopNotFound" } end

	local cfg = state.config
	local service = nil
	for _, s in ipairs(cfg.Services or {}) do
		if s.ServiceId == serviceId then service = s break end
	end
	if not service then return { ok = false, err = "ServiceNotFound" } end

	if getCurrency(plr) < service.Price then
		return { ok = false, err = "InsufficientFunds" }
	end

	modifyCurrency(plr, -service.Price)

	-- TODO: route to your combat/character service system
	-- CharacterService.applyService(plr, serviceId)

	return { ok = true }
end

-- ── Fortune purchase ─────────────────────────────────────────
function ShopService.buyFortune(plr, shopId, fortuneId)
	local state = registeredShops[shopId]
	if not state then return { ok = false, err = "ShopNotFound" } end

	local cfg = state.config
	local fortune = nil
	for _, f in ipairs(cfg.Fortunes or {}) do
		if f.Id == fortuneId then fortune = f break end
	end
	if not fortune then return { ok = false, err = "FortuneNotFound" } end

	if getCurrency(plr) < fortune.Price then
		return { ok = false, err = "InsufficientFunds" }
	end

	modifyCurrency(plr, -fortune.Price)

	-- Apply fortune effect
	-- TODO: route to your buff/world effect system
	-- BuffService.applyFortune(plr, fortune.Effect)

	return { ok = true, fortune = fortune }
end

-- ── Gacha pull ───────────────────────────────────────────────
local function weightedPick(pool)
	local totalWeight = 0
	for _, entry in ipairs(pool) do totalWeight += entry.weight end
	local roll = math.random() * totalWeight
	local acc  = 0
	for _, entry in ipairs(pool) do
		acc += entry.weight
		if roll <= acc then return entry.id end
	end
	return pool[#pool].id
end

function ShopService.gachaPull(plr, shopId)
	local state = registeredShops[shopId]
	if not state then return { ok = false, err = "ShopNotFound" } end

	local cfg = state.config
	if cfg.Type ~= "Gacha" then return { ok = false, err = "NotGacha" } end

	local cost = cfg.PullCost or 300
	if getCurrency(plr) < cost then return { ok = false, err = "InsufficientFunds" } end

	-- Init pity tracker for this player/shop
	if not pityTrackers[plr] then pityTrackers[plr] = {} end
	if not pityTrackers[plr][shopId] then
		pityTrackers[plr][shopId] = { pullCount = 0, lastRareAt = 0 }
	end
	local pity = pityTrackers[plr][shopId]
	pity.pullCount += 1

	-- Pity override: if pullCount - lastRareAt >= GuaranteedAt, force a rare+ item
	local forceRare = (pity.pullCount - pity.lastRareAt) >= (cfg.GuaranteedAt or 10)

	local wonItemId
	if forceRare then
		-- Pick from the rarest items in the pool (weight <= 10)
		local rarePool = {}
		for _, entry in ipairs(cfg.PullPool) do
			if entry.weight <= 10 then table.insert(rarePool, entry) end
		end
		wonItemId     = #rarePool > 0 and weightedPick(rarePool) or weightedPick(cfg.PullPool)
		pity.lastRareAt = pity.pullCount
	else
		wonItemId = weightedPick(cfg.PullPool)
		-- Check if we won a rare naturally
		local item = getItem(wonItemId)
		if item and (item.Rarity or 1) >= 3 then
			pity.lastRareAt = pity.pullCount
		end
	end

	modifyCurrency(plr, -cost)

	local itemDef = getItem(wonItemId)
	if itemDef and itemDef.Tags and table.find(itemDef.Tags, "persona") then
		local newPersona = PersonaData.new(itemDef.Name, itemDef.Stats, itemDef.Affinities, itemDef.Skills, 1, 0)
		odm.PlayerData[plr].Data.PersonaStock:AddPersona(newPersona)
	else
		addItem(plr, wonItemId, 1)
	end

	return {
		ok        = true,
		itemId    = wonItemId,
		pullCount = pity.pullCount,
		pityLeft  = math.max(0, (cfg.GuaranteedAt or 10) - (pity.pullCount - pity.lastRareAt)),
	}
end

-- ============================================================
-- STOCK QUERY (client calls this to build the shop UI)
-- Returns the full stock list the client needs to render
-- ============================================================

function ShopService.getStock(plr, shopId)
	local state = registeredShops[shopId]
	if not state then return nil end
	local cfg = state.config

	-- Gate check
	if not hasFlag(plr, cfg.RequiredFlag) then
		return { gated = true, requiredFlag = cfg.RequiredFlag }
	end

	-- Check rotation refresh
	if shouldRotate(state) then rotateShop(shopId) end

	local fixedItems = {}
	for itemId in pairs(cfg.FixedStock or {}) do
		local item = getItem(itemId)
		if item and not item.Unbuyable then
			table.insert(fixedItems, {
				itemId   = itemId,
				item     = item,
				qty      = state.fixedQty[itemId],   -- nil = unlimited
				price    = math.floor(item.Price * (cfg.Markup or 1)),
			})
		end
	end

	local rotatingItems = {}
	for _, itemId in ipairs(state.currentRotating) do
		local item = getItem(itemId)
		if item and not item.Unbuyable then
			table.insert(rotatingItems, {
				itemId   = itemId,
				item     = item,
				qty      = state.rotatingQty[itemId],
				price    = math.floor(item.Price * (cfg.Markup or 1)),
				rotating = true,
			})
		end
	end

	return {
		shopId        = shopId,
		config        = cfg,
		fixedItems    = fixedItems,
		rotatingItems = rotatingItems,
		currency      = getCurrency(plr),
		services      = cfg.Services,
		fortunes      = cfg.Fortunes,
		pullCost      = cfg.PullCost,
		pityLeft      = pityTrackers[plr] and pityTrackers[plr][shopId]
			and math.max(0,
				(cfg.GuaranteedAt or 10)
				- (pityTrackers[plr][shopId].pullCount - pityTrackers[plr][shopId].lastRareAt)
			) or cfg.GuaranteedAt,
	}
end

-- ============================================================
-- DUNGEON HOOK — call after a dungeon run to refresh "ondungeon" shops
-- TODO: wire to your dungeon completion event
-- ============================================================

function ShopService.onDungeonComplete()
	for shopId, state in pairs(registeredShops) do
		if state.config.RotationInterval == "ondungeon" then
			rotateShop(shopId)
			print("ShopService: rotated '" .. shopId .. "' post-dungeon")
		end
	end
end

-- ============================================================
-- PERIODIC ROTATION TICK
-- Runs on the server every minute and rotates shops whose
-- time interval has elapsed.
-- ============================================================

local function tickRotations()
	for shopId, state in pairs(registeredShops) do
		if shouldRotate(state) then
			rotateShop(shopId)
			print("ShopService: auto-rotated '" .. shopId .. "'")
		end
	end
end

-- Start the rotation ticker
task.spawn(function()
	while true do
		task.wait(60)  -- check every minute
		tickRotations()
	end
end)

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

RF_Open.OnServerInvoke = function(plr, shopId)
	-- ShopClient asked to open a shop — return stock data
	-- (Entry sequence / UI is fully client-side; server just validates and supplies data)
	return ShopService.getStock(plr, shopId)
end

RF_Buy.OnServerInvoke = function(plr, shopId, itemId, qty)
	return ShopService.buyItem(plr, shopId, itemId, qty or 1)
end

RF_Sell.OnServerInvoke = function(plr, shopId, itemId, qty)
	return ShopService.sellItem(plr, shopId, itemId, qty or 1)
end

RF_Pull.OnServerInvoke = function(plr, shopId)
	return ShopService.gachaPull(plr, shopId)
end

RF_GetStock.OnServerInvoke = function(plr, shopId)
	return ShopService.getStock(plr, shopId)
end

-- Clean up pity data on player leave
PLRS.PlayerRemoving:Connect(function(plr)
	pityTrackers[plr] = nil
end)

return ShopService
