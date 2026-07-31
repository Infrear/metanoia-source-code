-- ============================================================
-- ShopClient (ModuleScript — StarterPlayerScripts or required by ClientUIMain)
-- Handles the client side of ALL shop interactions:
--   • Proximity prompt / door / examine / dialogue / cutscene entry
--   • Fetches stock from server
--   • Routes to the correct ShopGUI layout
--   • Handles buy/sell/pull RemoteFunction calls
--   • Manages shop NPC/object wiring in the world
--
-- DEPENDENCIES (mark TODO where not yet built):
--   ShopGUI          — the actual GUI renderer (sibling module)
--   ShopData         — item/shop definitions
--   ScreenHandler    — your fade in/out module      [TODO: already exists]
--   DialogueSystem   — your NPCM / dialogue module  [TODO: already exists as NPCM]
--   SceneDirector    — your cutscene module         [TODO: already exists]
--   ProximityPrompts — your prompt setup            [TODO: already exists]
-- ============================================================

-- Services
local RPS  = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local UIS  = game:GetService("UserInputService")
local TS   = game:GetService("TweenService")

-- Dependencies
local plr       = PLRS.LocalPlayer
local char      = plr.Character or plr.CharacterAdded:Wait()
local hrp       = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")

local Storage   = RPS:WaitForChild("ClientStorage")
local ShopData  = require(Storage:WaitForChild("Info"):WaitForChild("ShopData"))

-- TODO: replace with your actual module paths
local ScreenHandler  = require(script.Parent:WaitForChild("ScreenChangeHandler"))
local DialogueSystem = require(script.Parent:WaitForChild("Interactables"):WaitForChild("NPCs"))
local SceneDirector  = require(script.Parent:WaitForChild("SceneDirector"))

local ShopGUI = require(script:WaitForChild("ShopGUI"))

-- Remotes
local ShopRemotes = RPS:WaitForChild("ShopRemotes")
local RF_Open     = ShopRemotes:WaitForChild("ShopOpen")
local RF_Buy      = ShopRemotes:WaitForChild("ShopBuy")
local RF_Sell     = ShopRemotes:WaitForChild("ShopSell")
local RF_Pull     = ShopRemotes:WaitForChild("ShopPull")

-- ============================================================
-- MODULE
-- ============================================================
local ShopClient = {}

-- ── State ────────────────────────────────────────────────────
local isShopOpen    = false
local currentShopId = nil

-- ============================================================
-- ENTRY SEQUENCES
-- Each function handles one EntryType and ultimately calls
-- ShopClient.open(shopId) when the entry is complete.
-- ============================================================

-- ── PROMPT entry — proximity prompt opens slide panel ────────
local function setupPromptEntry(shopId, anchorPart)
	local cfg = ShopData.Shops[shopId]
	if not anchorPart then
		warn("ShopClient: setupPromptEntry — no anchorPart for '" .. shopId .. "'")
		return
	end

	-- TODO: use your existing ProximityPrompt system if you prefer
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style           = Enum.ProximityPromptStyle.Custom
	prompt.ActionText      = "Browse"
	prompt.ObjectText      = cfg.DisplayName
	prompt.HoldDuration    = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent          = anchorPart

	prompt.Triggered:Connect(function()
		ShopClient.open(shopId)
	end)
end

-- ── DIALOGUE entry — NPC dialogue first, then shop opens ─────
local function setupDialogueEntry(shopId, npcModel)
	local cfg = ShopData.Shops[shopId]
	if not npcModel then
		warn("ShopClient: setupDialogueEntry — no NPC model for '" .. shopId .. "'")
		return
	end

	local anchorPart = npcModel:FindFirstChild("HumanoidRootPart")
		or npcModel:FindFirstChildWhichIsA("BasePart")

	-- TODO: use your existing ProximityPrompt system
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style           = Enum.ProximityPromptStyle.Custom
	prompt.ActionText      = "Talk"
	prompt.ObjectText      = cfg.DisplayName
	prompt.HoldDuration    = 0.4
	prompt.RequiresLineOfSight = false
	prompt.Parent          = anchorPart

	prompt.Triggered:Connect(function()
		-- Run NPC dialogue first
		-- TODO: replace with your actual DialogueSystem call
		local dialogueFolder = RPS:FindFirstChild("Dialogues")
			and RPS.Dialogues:FindFirstChild(cfg.NPCDialogueId)

		if dialogueFolder then
			-- DialogueSystem.runNPC opens your chat UI and yields until done
			DialogueSystem.runNPC(npcModel, dialogueFolder, cfg.DisplayName)
		end

		-- Open the shop after dialogue finishes
		ShopClient.open(shopId)
	end)
end

-- ── DOOR entry — player walks through a trigger part ─────────
local function setupDoorEntry(shopId, doorPart)
	if not doorPart then
		warn("ShopClient: setupDoorEntry — no door part for '" .. shopId .. "'")
		return
	end

	doorPart.Touched:Connect(function(part)
		if not part:IsDescendantOf(char) then return end
		if isShopOpen then return end

		-- Fade out → open shop → fade back in is handled inside open()
		ShopClient.open(shopId)
	end)
end

-- ── EXAMINE entry — click/examine an object ───────────────────
local function setupExamineEntry(shopId, objectPart)
	local cfg = ShopData.Shops[shopId]
	if not objectPart then
		warn("ShopClient: setupExamineEntry — no object for '" .. shopId .. "'")
		return
	end

	-- TODO: use your existing ProximityPrompt system
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style           = Enum.ProximityPromptStyle.Custom
	prompt.ActionText      = "Examine"
	prompt.ObjectText      = cfg.DisplayName
	prompt.HoldDuration    = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent          = objectPart

	prompt.Triggered:Connect(function()
		ShopClient.open(shopId)
	end)
end

-- ── CUTSCENE entry — plays a cutscene, then shop opens ───────
local function setupCutsceneEntry(shopId, triggerPart)
	local cfg = ShopData.Shops[shopId]
	if not triggerPart then return end

	local played    = false  -- only play the intro cutscene once per session
	local anchorPart = triggerPart:FindFirstChildWhichIsA("BasePart") or triggerPart

	-- TODO: use your existing ProximityPrompt system
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style           = Enum.ProximityPromptStyle.Custom
	prompt.ActionText      = "Enter"
	prompt.ObjectText      = cfg.DisplayName
	prompt.HoldDuration    = 0
	prompt.Parent          = anchorPart

	prompt.Triggered:Connect(function()
		if not played then
			played = true
			-- TODO: replace with your SceneDirector.Play call
			local scenes = RPS:FindFirstChild("Scenes")
			local scene  = scenes and scenes:FindFirstChild(cfg.CutsceneId)
			if scene then
				SceneDirector.Play(scene)
			end
		end
		-- Open shop immediately after cutscene (SceneDirector.Play yields until done)
		ShopClient.open(shopId)
	end)
end

-- ============================================================
-- ENTRY DISPATCHER
-- Routes a shopId + world object to the correct setup function
-- ============================================================

-- Call this for each shop object you place in the world.
-- obj = the Model, Part, or NPC that represents this shop in workspace
function ShopClient.wire(shopId, obj)
	local cfg = ShopData.Shops[shopId]
	if not cfg then
		warn("ShopClient.wire: unknown shopId '" .. shopId .. "'")
		return
	end

	local entryType = cfg.EntryType

	if entryType == "prompt" then
		local part = obj:IsA("BasePart") and obj
			or obj:FindFirstChildWhichIsA("BasePart")
		setupPromptEntry(shopId, part)

	elseif entryType == "dialogue" then
		setupDialogueEntry(shopId, obj)

	elseif entryType == "door" then
		local part = obj:IsA("BasePart") and obj
			or obj:FindFirstChild("DoorTrigger")
			or obj:FindFirstChildWhichIsA("BasePart")
		setupDoorEntry(shopId, part)

	elseif entryType == "examine" then
		local part = obj:IsA("BasePart") and obj
			or obj:FindFirstChildWhichIsA("BasePart")
		setupExamineEntry(shopId, part)

	elseif entryType == "cutscene" then
		setupCutsceneEntry(shopId, obj)

	else
		warn("ShopClient.wire: unknown EntryType '" .. tostring(entryType) .. "'")
	end
end

-- Auto-wire all shop objects found in workspace.SHOPS
-- Expects each child to have an Attribute "ShopId" matching a ShopData.Shops key
function ShopClient.wireAll()
	local container = workspace:FindFirstChild("SHOPS")
	if not container then
		warn("ShopClient.wireAll: workspace.SHOPS not found")
		return
	end
	for _, obj in ipairs(container:GetChildren()) do
		local shopId = obj:GetAttribute("ShopId")
		if shopId then
			ShopClient.wire(shopId, obj)
		end
	end
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

function ShopClient.open(shopId)
	if isShopOpen then return end
	isShopOpen    = true
	currentShopId = shopId

	local cfg = ShopData.Shops[shopId]
	if not cfg then
		warn("ShopClient.open: unknown shopId '" .. shopId .. "'")
		isShopOpen = false
		return
	end

	-- Fade out using your ScreenHandler before loading
	-- TODO: adjust to match your actual ScreenHandler API
	ScreenHandler.LoadIn("Scrub", true)
	task.wait(0.4)

	-- Fetch stock from server
	local stockData = RF_Open:InvokeServer(shopId)

	if not stockData then
		warn("ShopClient.open: server returned no stock for '" .. shopId .. "'")
		ScreenHandler.LoadOut()
		isShopOpen = false
		return
	end

	if stockData.gated then
		-- TODO: show "locked" UI with RequiredFlag message
		ScreenHandler.LoadOut()
		isShopOpen = false
		return
	end

	-- Route to the correct GUI layout based on shop type
	ScreenHandler.LoadOut()
	ShopGUI.open(shopId, cfg, stockData, {
		onBuy     = ShopClient.requestBuy,
		onSell    = ShopClient.requestSell,
		onPull    = ShopClient.requestPull,
		onService = ShopClient.requestService,
		onClose   = ShopClient.close,
	})
end

function ShopClient.close()
	if not isShopOpen then return end
	ShopGUI.close(currentShopId)
	isShopOpen    = false
	currentShopId = nil
end

-- ============================================================
-- TRANSACTION REQUESTS
-- Called by ShopGUI buttons — fire to server, handle response
-- ============================================================

function ShopClient.requestBuy(shopId, itemId, qty)
	local result = RF_Buy:InvokeServer(shopId, itemId, qty or 1)
	if result.ok then
		ShopGUI.onBuySuccess(shopId, itemId, qty, result.finalPrice)
	else
		ShopGUI.onTransactionError(result.err)
	end
	return result
end

function ShopClient.requestSell(shopId, itemId, qty)
	local result = RF_Sell:InvokeServer(shopId, itemId, qty or 1)
	if result.ok then
		ShopGUI.onSellSuccess(shopId, itemId, qty, result.payout)
	else
		ShopGUI.onTransactionError(result.err)
	end
	return result
end

function ShopClient.requestPull(shopId)
	local result = RF_Pull:InvokeServer(shopId)
	if result.ok then
		ShopGUI.onPullResult(shopId, result)
	else
		ShopGUI.onTransactionError(result.err)
	end
	return result
end

function ShopClient.requestService(shopId, serviceId)
	-- Services use the same RF_Buy remote with a service flag
	local result = RF_Buy:InvokeServer(shopId, "_service_" .. serviceId, 1)
	if result.ok then
		ShopGUI.onServiceSuccess(shopId, serviceId)
	else
		ShopGUI.onTransactionError(result.err)
	end
	return result
end

-- ============================================================
-- INIT
-- ============================================================

function ShopClient.init()
	plr.CharacterAdded:Connect(function(newChar)
		char = newChar
		hrp  = newChar:WaitForChild("HumanoidRootPart")
	end)

	ShopGUI.init(playerGUI)
	ShopClient.wireAll()

	-- Close shop on character death
	plr.CharacterAdded:Connect(function()
		if isShopOpen then ShopClient.close() end
	end)

	print("ShopClient: initialized")
end

return ShopClient
