-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")       -- needed for sprite sheet animation loops
local CPV = game:GetService("ContentProvider") -- needed for preloading sprite sheet images

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local richText = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("RichText"))
local keySettings = require(Storage.Info.KeybindsMaster)
local itemInfo = require(Storage.Info.ItemInfo)
local npcIndex = require(Storage.Info.NPCIndex)
local npcRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("NPCRem")
local questRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("QuestRem")
local getData = Storage:WaitForChild("Functions").Remotes.GetData
local clientSideNPCActions = require(script:WaitForChild("ClientSideNPCActions"))

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local ui = playerGUI:WaitForChild("GlobalUI")
local mainFrames = ui:WaitForChild("Chatbars")
local charbar = mainFrames:WaitForChild("CharChatbar")
local defbar = mainFrames:WaitForChild("CharChatbar") -- TODO: swap to real "DefChatbar" once the text-only bar is built; currently aliased to charbar
local thinkbar = mainFrames:WaitForChild("ThinkChatbar")
local personFrame = mainFrames:WaitForChild("Person")
local blackoutFrame = mainFrames:WaitForChild("Blackout")

-- -------------------------------------------------------------
-- SPRITE SHEET CONFIGS
-- Each bar that has an animated background needs an entry here.
-- Migrated from the standalone CHARCHATBAR.lua / THINKCHATBAR.lua scripts.
-- -------------------------------------------------------------
local SPRITE_CONFIGS = {

	-- -- CharChatbar / DefChatbar (shared, 4-frame loop) ----------
	-- Originally lived in CHARCHATBAR.lua
	charbar = {
		imageIds = {
			"rbxassetid://95784555515684", -- Sheet/Frame 1
			"rbxassetid://91539151062124", -- Sheet/Frame 2
			"rbxassetid://70481368199592",
			"rbxassetid://114304388232724",
		},
		rows       = 4,
		columns    = 1,
		framerate  = 6.5,
		-- NOTE: ClipsDescendants is intentionally left off on charbar's Warper (matching original)
		clipsDescendants = true,
	},

	-- -- ThinkChatbar (13-frame loop) -----------------------------
	-- Originally lived in THINKCHATBAR.lua
	thinkbar = {
		imageIds = {
			"rbxassetid://86801110940977", -- Sheet/Frame 1
			"rbxassetid://108611113429707", -- Sheet/Frame 2
			"rbxassetid://92144776076705",
			"rbxassetid://105151257844841",
			"rbxassetid://86675731186120",
			"rbxassetid://98678114742850",
			"rbxassetid://121048558085161",
			"rbxassetid://92672005904719",
			"rbxassetid://119421558123567",
			"rbxassetid://100927456221602",
			"rbxassetid://118238382883601",
			"rbxassetid://138686564772207",
			"rbxassetid://123664535045304",
			-- add new frames here; framerate auto-adjusts via the formula below
		},
		rows      = 5,
		columns   = 3,
		-- framerate formula from original: (frames / 49) * 24
		-- computed at runtime inside InitSpriteSheet so adding frames stays automatic
		framerate = nil, -- set dynamically
		clipsDescendants = true,
	},

	-- -- DefChatbar (TODO: text-only bar, no character portrait) --
	-- For now this is a copy of the charbar config since defbar = charbar.
	-- When DefChatbar gets its own UI element, add its own imageIds / layout here.
	defbar = nil, -- TODO: fill in once DefChatbar is a real separate UI element
}

-- -------------------------------------------------------------
-- SPRITE SHEET RUNTIME STATE
-- One state table per bar so they can animate independently.
-- -------------------------------------------------------------
local spriteState = {}   -- spriteState[barName] = { innerFrame, currentFrame, lastTick, conn }

-- -------------------------------------------------------------
-- SPRITE SHEET HELPERS
-- -------------------------------------------------------------

-- Builds the ImageLabel grid inside a bar's Secondary.Warper.
-- Mirrors GenerateGridFunction() from the original scripts.
local function buildSpriteGrid(warper, cfg)
	-- wipe any previous grid (e.g. on re-init)
	local existing = warper:FindFirstChild("GridContainer")
	if existing then existing:Destroy() end

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "GridContainer"
	innerFrame.BackgroundTransparency = 1
	innerFrame.Size = UDim2.new(cfg.columns, 0, cfg.rows, 0)
	innerFrame.Parent = warper

	for i, id in ipairs(cfg.imageIds) do
		local row = math.ceil(i / cfg.columns)
		local col = i - ((row - 1) * cfg.columns)
		local img = Instance.new("ImageLabel")
		img.Name  = "Frame_" .. i
		img.Image = id
		img.BackgroundTransparency = 1
		img.Size     = UDim2.new(1 / cfg.columns, 0, 1 / cfg.rows, 0)
		img.Position = UDim2.new((col - 1) / cfg.columns, 0, (row - 1) / cfg.rows, 0)
		img.Parent   = innerFrame
	end

	return innerFrame
end

-- Connects a RenderStepped loop that scrolls the grid like the original UpdateAnimation().
-- Returns the connection so it can be disconnected if the bar is hidden.
local function connectSpriteLoop(barName, warper, innerFrame, cfg)
	-- disconnect any existing loop for this bar first
	if spriteState[barName] and spriteState[barName].conn then
		spriteState[barName].conn:Disconnect()
	end

	local frameCount = #cfg.imageIds
	-- dynamic framerate: if cfg.framerate is nil, use the think-bar formula
	local fps = cfg.framerate or ((frameCount / 49) * 24)

	spriteState[barName] = {
		innerFrame   = innerFrame,
		currentFrame = 1,
		lastTick     = tick(),
		conn         = nil,
	}
	local state = spriteState[barName]

	state.conn = RS.RenderStepped:Connect(function()
		if tick() - state.lastTick < 1 / fps then return end
		state.currentFrame += 1
		if state.currentFrame > frameCount then state.currentFrame = 1 end

		local row = math.ceil(state.currentFrame / cfg.columns)
		local col = state.currentFrame - ((row - 1) * cfg.columns)
		-- scroll the inner frame to reveal the correct cell
		innerFrame.Position = UDim2.new(-(col - 1), 0, -(row - 1), 0)
		state.lastTick = tick()
	end)

	return state.conn
end

--local frame = bar:WaitForChild("Frame")
--local tframe = bar:WaitForChild("Title")
--local label = frame:WaitForChild("TextLabel") 
--local arrow = frame:WaitForChild("Arrow")
--local accept = frame:WaitForChild("Accept")
--local decline = frame:WaitForChild("Decline")

-- Constants
--local HOVER_SETTINGSb = {
--	RotateForwardSpeed = 0.55,
--	RotateBackSpeed = 1.5,
--	OGPosition = UDim.new(0, 1),
--	PositionAddition = UDim2.new(0, 0, 0.085, 0),
--}
local defaultBarLength = 0.05
local BAR_SETTINGS = {
	[charbar] = {
		OGSecSize = charbar.Secondary.Size,
		OGImgPos = charbar.CharacterVPF.Position,
		OGImgTransparency = charbar.CharacterVPF.ImageTransparency,
		OGArrowSize = charbar.Secondary.ContentFrame.Arrow.Size,
		OGArrowRotation = charbar.Secondary.ContentFrame.Arrow.Rotation,
	},
	[defbar] = {
		OGSecSize = defbar.Secondary.Size,
		OGImgPos = defbar.CharacterVPF.Position,
		OGImgTransparency = defbar.CharacterVPF.ImageTransparency,
		OGArrowSize = defbar.Secondary.ContentFrame.Arrow.Size,
		OGArrowRotation = defbar.Secondary.ContentFrame.Arrow.Rotation,
	},
	[thinkbar] = {
		OGSecSize = thinkbar.Secondary.Size,
		--OGImgPos = thinkbar.Secondary.Position,
		--OGImgTransparency = thinkbar.CharacterVPF.ImageTransparency,
		OGArrowSize = thinkbar.Secondary.ContentFrame.Arrow.Size,
		OGArrowRotation = thinkbar.Secondary.ContentFrame.Arrow.Rotation,
	},

	-- Add these into your BAR_SETTINGS table:
	ChoiceNormalOutlineColor = Color3.fromRGB(255, 255, 255), -- Solid White
	ChoiceNormalInColor      = Color3.fromRGB(0, 0, 0),       -- Solid Black
	ChoiceNormalTextColor    = Color3.fromRGB(255, 255, 255), -- Solid White

	ChoiceHoverOutlineColor  = Color3.fromRGB(0, 0, 0),       -- Black
	ChoiceHoverOutlineTrans  = 0.5,                           -- Slightly Transparent
	ChoiceHoverInColor       = Color3.fromRGB(255, 255, 255), -- Solid White
	ChoiceHoverTextColor     = Color3.fromRGB(0, 0, 0),       -- Solid Black

	ChoiceHoverScale         = 1.025,                          -- 5% scale up on hover
	ChoiceClickFlashScale    = 1.15,                          -- 12% grow on click
	ChoiceSettleScale        = 0.98,                          -- Shrink slightly when settled
	ChoiceClickFlashColor    = Color3.fromRGB(255, 255, 210), -- Yellowish-White flash

	ChoiceFloatSpeed         = 3,                           -- Sway speed
	ChoiceFloatAmpX          = 5,                             -- Horizontal sway pixels
	ChoiceFloatAmpY          = 8,                             -- Vertical sway pixels

	ArrowChange = 0.05,

	OGLineTransparency = 0.1,
	
	PersonStartOut = UDim2.fromScale(1.5, 1),
	PersonEndIn = UDim2.fromScale(0.825, 1),
	
	BlackoutChatTransparency = 0.45
}

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	),
	frameFadeIn = TweenInfo.new(
		0.225
	),
	frameFadeOut = TweenInfo.new(
		0.15,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	frameSlowOut = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Elastic,
		Enum.EasingDirection.In
	),
	frameGlideIn = TweenInfo.new(
		0.45,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	),
	frameVelIn = TweenInfo.new(
		0.185,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	),
	arrowUpNDown = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
		---1
	),
	quickFadeIn = TweenInfo.new(
		0.05,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	quickFadeOut = TweenInfo.new(
		0.025,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	whiteOut = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		0,
		true
	),
	choiceFadeIn = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	choiceFadeOut = TweenInfo.new(
		0.2,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
}

-- Local Variables
local bt1, bt2 = nil, nil
local generalTES = {}
local generalCons = {}
local latestTextObject = nil

-- Initialization
local NPCM = {}
NPCM.currentNPC = nil

-- Local Functions
-- -------------------------------------------------------------
-- PRELOAD + INIT  (call once at startup)
--
-- WHY THREE PASSES + A FORCED RENDER:
--
-- Pass 1 - Build grids into the live UI tree.
--   Labels must be parented into PlayerGui for PreloadAsync to mean anything.
--
-- Pass 2 - PreloadAsync on those exact parented labels.
--   Gets textures into RAM. BUT Roblox's renderer culls invisible UI, so if
--   Secondary.Visible = false the GPU never actually uploads the texture.
--   PreloadAsync alone is not enough when the ancestor is hidden.
--
-- Pass 3 - Force a real render by briefly making each bar visible.
--   We set Secondary.Visible = true, Secondary.Size to its real OG size,
--   wait one RenderStepped (one actual drawn frame), then hide everything
--   again. That single rendered frame locks the textures into GPU memory.
--   This is the same reason CombatCienematics never flashes - its Warper
--   is already visible in the HUD before any dialogue runs.
--
-- Pass 4 - Start animation loops now that GPU cache is guaranteed warm.
-- -------------------------------------------------------------
local function initSpriteSheets()
	local allParentedLabels = {}
	local builtBars = {} -- { barName, barObj, warper, innerFrame, cfg }

	-- Pass 1: build all grids into the live UI tree
	for barName, cfg in pairs(SPRITE_CONFIGS) do
		if not cfg then continue end

		-- IMPORTANT: defbar == charbar right now, skip to avoid a double grid
		if barName == "defbar" then continue end -- TODO: remove once DefChatbar is its own element

		local barObj = (barName == "charbar" and charbar)
			or (barName == "thinkbar" and thinkbar)

		local warper = barObj.Secondary:FindFirstChild("Warper")
		if not warper then
			warn("NPCs: no Warper found inside " .. barName .. ".Secondary - skipping sprite init")
			continue
		end

		warper.ClipsDescendants = cfg.clipsDescendants
		warper.Size = warper.Size -- preserve original size

		local innerFrame = buildSpriteGrid(warper, cfg)

		for _, label in ipairs(innerFrame:GetChildren()) do
			if label:IsA("ImageLabel") then
				table.insert(allParentedLabels, label)
			end
		end

		table.insert(builtBars, { barName = barName, barObj = barObj, warper = warper, innerFrame = innerFrame, cfg = cfg })
	end

	-- Pass 2: PreloadAsync - gets textures into RAM
	if #allParentedLabels > 0 then
		CPV:PreloadAsync(allParentedLabels)
	end

	
	for _, entry in ipairs(builtBars) do
	end
	
	-- Pass 3: FORCE a real GPU upload by briefly rendering each bar fully visible.
	-- PreloadAsync alone won't push to GPU if the ancestor chain is invisible.
	-- We show the bar for exactly one rendered frame then immediately hide it again.
	-- This happens during the loading screen so the player never sees it.
	for _, entry in ipairs(builtBars) do
		local bar = entry.barObj
		local secondary = bar.Secondary

		-- Snapshot current state so we can restore it exactly
		local wasSecondaryVisible = BAR_SETTINGS[bar] and BAR_SETTINGS[bar].OGSecSize or secondary.Size
		local wasSecondarySize    = secondary.Size
		local wasBarVisible       = bar.Visible
		
		-- Pass 4: start animation loops - GPU is warm, no flash possible
		connectSpriteLoop(entry.barName, entry.warper, entry.innerFrame, entry.cfg)
		


		-- Force everything in the ancestor chain to be visible and sized
		bar.Visible       = true
		secondary.Visible = true

		-- Yield until the renderer has actually drawn this frame
		-- RenderStepped fires BEFORE rendering; PostSimulation/Heartbeat fires AFTER.
		-- We wait two Heartbeats to guarantee at least one full render cycle completes.
		game:GetService("RunService").Heartbeat:Wait()
		game:GetService("RunService").Heartbeat:Wait()
		task.wait(3)

		-- Restore hidden state - player still sees nothing (loading screen is up)
		--bar.Visible       = wasBarVisible
		--secondary.Visible = false
		secondary.Size    = wasSecondarySize
	end

end

local function countDict(dict)
	local count = 0
	for i, v in pairs(dict) do
		count += 1
	end
	return count
end 

local function fadeInFrame(bar, cvp)
	if bt1 then
		if bt1.PlaybackState == Enum.PlaybackState.Playing then
			bt1:Cancel()
		end
	end
	if bt2 then
		if bt2.PlaybackState == Enum.PlaybackState.Playing then
			bt2:Cancel()
		end
	end
	if bar:FindFirstChild("CharacterVPF") and cvp then
		bar.CharacterVPF.Visible = true
		bt2 = TS:Create(bar.CharacterVPF, TIS.frameFadeIn, {Position = BAR_SETTINGS[bar].OGImgPos, ImageTransparency = BAR_SETTINGS[bar].OGImgTransparency})
		bt2:Play()
		bt2.Completed:Wait()
	end
	bar.Secondary.Visible = true
	bt1 = TS:Create(bar.Secondary, cvp and TIS.frameFadeOut or TIS.quickFadeIn, {Size = BAR_SETTINGS[bar].OGSecSize})

	return bt1--, bt2
end

local function fadeOutFrame(bar, fullOut)
	if bt1 then
		if bt1.PlaybackState == Enum.PlaybackState.Playing then
			bt1:Cancel()
		end
	end
	if bt2 then
		if bt2.PlaybackState == Enum.PlaybackState.Playing then
			bt2:Cancel()
		end
	end

	if bar:FindFirstChild("CharacterVPF") and fullOut then
		bar.CharacterVPF.Visible = true
		bt2 = TS:Create(bar.CharacterVPF, TIS.frameFadeOut, {Position = UDim2.fromScale(BAR_SETTINGS[bar].OGImgPos.X.Scale - 0.1, BAR_SETTINGS[bar].OGImgPos.Y.Scale), ImageTransparency = 1})
		bt2:Play()
	end
	bar.Secondary.Visible = true
	bt1 = TS:Create(bar.Secondary, fullOut and TIS.frameFadeOut or TIS.quickFadeOut, {Size = fullOut and UDim2.fromScale(0, 0) or UDim2.fromScale(BAR_SETTINGS[bar].OGSecSize.X.Scale * 0.915, BAR_SETTINGS[bar].OGSecSize.Y.Scale * 0.915)})
	--bt2 = TS:Create(bar.Chatbar2, TIS.frameFadeOut, {ImageTransparency = 1})

	return bt1--, bt2
end

function lineMessage(text, duration, newLabel--[[, continued]])
	-- Rich text Wind Waker example: -- https://youtu.be/CY3ghdwL9W4?t=4m34s	https://twitter.com/Defaultio/status/903138250054709248

	--print("texting")
	if not newLabel then return end
	--local textObject = richText:New(label, text, {Font = "Cartoon"})--, AnimateStyle = "Wiggle", AnimateStepFrequency = 1, AnimateStyleTime = 7, AnimateStyleNumPeriods = 10})
	latestTextObject = richText:New(newLabel, text, {Font = (newLabel and newLabel.Font.Name), ContainerHorizontalAlignment = "Left", ContainerVerticalAlignment = "Center", AnimateStyleTime = 7})--, AnimateStyle = "Wiggle", AnimateStepFrequency = 1, AnimateStyleTime = 7, AnimateStyleNumPeriods = 10})

	local ccon 

	ccon = UIS.InputBegan:Connect(function(inp, gP)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
			ccon:Disconnect()
			ccon = nil
			if latestTextObject then
				latestTextObject:Show()
			end
		end
	end)

	latestTextObject:Animate(true)

	if ccon then
		ccon:Disconnect()
	end

	--task.wait(1)

	-- too lazy to script ??
	--print(text)
	--task.wait(duration + 0.5)

	--This is the animation example:
	--local textSequence = {{Text = "This text is about to be <Color=Green><AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=2>wiggly<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1.5>\nIt can also be <Color=Red><AnimateStyle=Fade><AnimateStepFrequency=1><AnimateStyleTime=0.5>fadey <Img=Eggplant>fadey<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1>\n<AnimateStyle=Rainbow><AnimateStyleTime=2>Or rainbow!!! :O<Img=Thinking><AnimateStyle=/><AnimateStyleTime=/><AnimateYield=1>\n<AnimateStyle=Swing><AnimateStyleTime=3>Make custom animations! <Img=Eggplant>", Delay = 10}}

	--This is a text justification example:
	--local textSequence = {{Text = "Have you ever <Color=Red>thought<Color=/><AnimateStepFrequency=1><AnimateStepTime=0.4> . . .<AnimateStepFrequency=/><AnimateStepTime=/><AnimateYield=1><ContainerHorizontalAlignment=Center>\n<TextScale=0.5><AnimateStyle=Rainbow><AnimateStyleTime=2.5><Img=Thinking><AnimateStyle=/><TextScale=/><AnimateYield=3><ContainerHorizontalAlignment=Right>\n<Color=Green><AnimateStyle=Spin><AnimateStyleTime=1.5>Wow<AnimateStyle=/><Color=/>!", Delay = 10}}
	--task.wait(duration)
	--task.wait()
end

local function bindChoice(btn)
	-- 1. Safely disconnect old script connections
	if generalCons[btn] then
		for _, conn in ipairs(generalCons[btn]) do
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			end
		end
		generalCons[btn] = nil
	end

	-- Helper to cancel running tweens on an object
	local function stopTween(obj)
		if obj and generalTES[obj] then
			if generalTES[obj].PlaybackState == Enum.PlaybackState.Playing then
				generalTES[obj]:Cancel()
			end
			generalTES[obj] = nil
		end
	end

	-- Locate child elements
	local inImage = btn:FindFirstChild("InImage")
	local sinker = inImage and inImage:FindFirstChild("Sinker")
	local label = (inImage and sinker and sinker:FindFirstChild("SampleText")) or btn:FindFirstChild("SampleText")

	stopTween(btn)
	stopTween(inImage)
	stopTween(label)

	-- 2. Attribute Checks & Auto-Assignment
	if not btn:GetAttribute("OGSize") then
		btn:SetAttribute("OGSize", btn.Size)
	end
	if not btn:GetAttribute("OGPosition") then
		btn:SetAttribute("OGPosition", btn.Position)
	end

	local ogSize = btn:GetAttribute("OGSize")
	local ogPosition = btn:GetAttribute("OGPosition")

	-- Reset button transforms & state to Unselected Defaults
	btn.Size = ogSize
	btn.Position = ogPosition
	btn.ImageColor3 = BAR_SETTINGS.ChoiceNormalOutlineColor
	btn.ImageTransparency = 0

	if inImage then
		inImage.ImageColor3 = BAR_SETTINGS.ChoiceNormalInColor
		inImage.ImageTransparency = 0
	end

	if label then
		label.TextColor3 = BAR_SETTINGS.ChoiceNormalTextColor
		label.TextTransparency = 0
	end

	-- 3. Passive Floating Animation Setup
	local isFloating = true
	local isClicked = false
	local floatSeed = math.random() * 100 -- Prevents buttons swaying in identical sync

	local floatConn = RS.RenderStepped:Connect(function()
		if isFloating and not isClicked then
			local t = tick()
			local speed = BAR_SETTINGS.ChoiceFloatSpeed
			local offsetX = math.sin(t * speed + floatSeed) * BAR_SETTINGS.ChoiceFloatAmpX
			local offsetY = math.cos(t * speed * 0.8 + floatSeed) * BAR_SETTINGS.ChoiceFloatAmpY

			btn.Position = ogPosition + UDim2.new(0, offsetX, 0, offsetY)
		end
	end)

	-- 4. Hover State (Selected)
	local mouseEnterConn = sinker.MouseEnter:Connect(function()
		if isClicked then return end
		isFloating = false -- Freeze in current floated position

		stopTween(btn)
		stopTween(inImage)
		stopTween(label)

		local scale = BAR_SETTINGS.ChoiceHoverScale
		local targetHoverSize = UDim2.new(
			ogSize.X.Scale * scale, ogSize.X.Offset,
			ogSize.Y.Scale * scale, ogSize.Y.Offset
		)

		generalTES[btn] = TS:Create(btn, TIS.quickFadeIn, {
			Size = targetHoverSize,
			ImageColor3 = BAR_SETTINGS.ChoiceHoverOutlineColor,
			ImageTransparency = BAR_SETTINGS.ChoiceHoverOutlineTrans
		})
		generalTES[btn]:Play()

		if inImage then
			generalTES[inImage] = TS:Create(inImage, TIS.choiceFadeIn, {
				ImageColor3 = BAR_SETTINGS.ChoiceHoverInColor,
				ImageTransparency = 0
			})
			generalTES[inImage]:Play()
		end

		if label then
			generalTES[label] = TS:Create(label, TIS.choiceFadeIn, {
				TextColor3 = BAR_SETTINGS.ChoiceHoverTextColor,
				TextTransparency = 0
			})
			generalTES[label]:Play()
		end
	end)

	-- 5. Unhover State (Deselected)
	local mouseLeaveConn = sinker.MouseLeave:Connect(function()
		if isClicked then return end

		stopTween(btn)
		stopTween(inImage)
		stopTween(label)

		generalTES[btn] = TS:Create(btn, TIS.quickFadeOut, {
			Size = ogSize,
			ImageColor3 = BAR_SETTINGS.ChoiceNormalOutlineColor,
			ImageTransparency = 0
		})
		generalTES[btn]:Play()

		if inImage then
			generalTES[inImage] = TS:Create(inImage, TIS.choiceFadeOut, {
				ImageColor3 = BAR_SETTINGS.ChoiceNormalInColor,
				ImageTransparency = 0
			})
			generalTES[inImage]:Play()
		end

		if label then
			generalTES[label] = TS:Create(label, TIS.choiceFadeOut, {
				TextColor3 = BAR_SETTINGS.ChoiceNormalTextColor,
				TextTransparency = 0
			})
			generalTES[label]:Play()
		end

		isFloating = true -- Resume floating
	end)

	-- 6. Click Sequence Method
	local function playClickAnim()
		isClicked = true
		isFloating = false

		stopTween(btn)
		stopTween(inImage)
		stopTween(label)

		-- Stage 1: Expand & Flash Yellowish White
		local flashScale = BAR_SETTINGS.ChoiceClickFlashScale
		local flashSize = UDim2.new(
			ogSize.X.Scale * flashScale, ogSize.X.Offset,
			ogSize.Y.Scale * flashScale, ogSize.Y.Offset
		)
		local flashColor = BAR_SETTINGS.ChoiceClickFlashColor

		local flashTween = TS:Create(btn, TIS.quickFadeIn, {
			Size = flashSize,
			ImageColor3 = flashColor,
			ImageTransparency = 0
		})
		flashTween:Play()

		if inImage then
			TS:Create(inImage, TIS.quickFadeIn, {
				ImageColor3 = flashColor,
				ImageTransparency = 0
			}):Play()
		end

		if label then
			TS:Create(label, TIS.quickFadeIn, {
				TextColor3 = flashColor,
				TextTransparency = 0
			}):Play()
		end

		--flashTween.Completed:Wait()

		---- Stage 2: Settle back & shrink slightly into selected mix
		--local settleScale = BAR_SETTINGS.ChoiceSettleScale
		--local settleSize = UDim2.new(
		--	ogSize.X.Scale * settleScale, ogSize.X.Offset,
		--	ogSize.Y.Scale * settleScale, ogSize.Y.Offset
		--)

		--TS:Create(btn, TIS.quickFadeOut, {
		--	Size = settleSize,
		--	ImageColor3 = BAR_SETTINGS.ChoiceHoverOutlineColor,
		--	ImageTransparency = BAR_SETTINGS.ChoiceHoverOutlineTrans
		--}):Play()

		--if inImage then
		--	TS:Create(inImage, TIS.quickFadeOut, {
		--		ImageColor3 = BAR_SETTINGS.ChoiceHoverInColor,
		--		ImageTransparency = 0
		--	}):Play()
		--end

		--if textLabel then
		--	TS:Create(textLabel, TIS.quickFadeOut, {
		--		TextColor3 = BAR_SETTINGS.ChoiceHoverTextColor,
		--		TextTransparency = 0
		--	}):Play()
		--end
	end

	-- Store connections inside generalCons table
	generalCons[btn] = { floatConn, mouseEnterConn, mouseLeaveConn }

	return generalCons[btn], playClickAnim
end

-- Global Functions
function NPCM.runNPC(npcObject, givenDialogue, displayName, overrideDilog) -- dialogueName and displayName is optional if you have an npc model
	if NPCM.currentNPC or (not ((givenDialogue and ((typeof(givenDialogue) == 'string' and npcIndex[givenDialogue]) or (((typeof(givenDialogue) == 'Instance') and (givenDialogue:IsA("ModuleScript")))))) or ((npcObject and npcObject:GetAttribute("NPCType") and npcIndex[npcObject.Name])))) then return end

	if not displayName and npcObject then
		displayName = npcObject.Name
	end

	local npcInfo = (givenDialogue and (typeof(givenDialogue) == 'string' and npcIndex[givenDialogue]) or ((((typeof(givenDialogue) == 'Instance') and (givenDialogue:IsA("ModuleScript")))) and require(givenDialogue))) or (displayName and npcIndex[displayName])

	if latestTextObject then
		latestTextObject:Hide()
	end

	NPCM.currentNPC = npcObject
	NPCM.IsActive = true
	local options = {}

	for i, v in pairs(generalTES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	generalTES = {}

	for i, v in pairs(generalCons) do
		if typeof(v) == 'RBXScriptConnection' then
			v:Disconnect()
		elseif typeof(v) == 'table' then
			for i2, v2 in pairs(v) do
				if typeof(v2) == 'RBXScriptConnection' then
					v2:Disconnect()
				end
			end
		end
	end
	generalCons = {}


	npcRem:FireServer("start", displayName)

	local Data = nil
	pcall(function()
		Data = getData:InvokeServer("Global")
	end)
	if not Data then return end

	local npcData = Data.Data.NPCData
	local npcType = npcObject and npcObject:GetAttribute("NPCType") or nil
	local hum = npcObject and npcObject:FindFirstChildOfClass("Humanoid") or nil

	local questData = Data.Data.Quests
	local dilogs = npcInfo.Dialogues
	local dilog = dilogs.First

	if displayName and not overrideDilog then
		if npcType == "Quest" and countDict(questData.Current) >= 2 and (not (npcData[displayName] and (npcData[displayName] ~= "First") and npcData[displayName].QuestSequenceIndex and npcData[displayName].QuestSequenceIndex >= 1)) then
			dilog = dilogs["2manyquests"] or npcIndex.TooManyQuestsDefaultDialouge
		elseif npcData[displayName] then
			dilog = dilogs[npcData[displayName].Behavior] or dilogs.First
		end
	end

	local latestV = nil
	local latestAlt = false
	local nextDialogue = nil

	local bar = nil
	local secondary = nil
	local tframe = nil
	local content = nil
	local label = nil
	local arrow = nil
	local te1 = nil
	local first = true

	local playingAnims = {}
	if npcInfo.OpenAnimation then
		local found = Storage.Animations.Actions:FindFirstChild(npcInfo.OpenAnimation, true)
		if found and hum then
			local animtrac = hum:LoadAnimation(found)
			animtrac:Play(found:GetAttribute("FadeTime") or 0.45)
			table.insert(playingAnims, animtrac)
		end
	end





	for i, v in ipairs(dilog) do
		latestAlt = false
		latestV = v
		--




		if v.TextboxType == "Character Speaking" then
			bar = charbar
			tframe = bar.Secondary.TitleFrame
		elseif v.TextboxType == "Thinking" then
			bar = thinkbar
			tframe = nil
		else
			bar = defbar
			tframe = bar.Secondary.TitleFrame
		end

		secondary = bar:FindFirstChild("Secondary")
		content = secondary.ContentFrame
		label = content.SampleText
		arrow = content.Arrow

		label.Text = ""
		bar.Visible = true
		

		if tframe and first then
			tframe.TextLabel.Text = ""

			tframe.TextLabel.Text = npcInfo.DisplayName and npcInfo.DisplayName.Text or displayName or ""
			tframe.TextLabel.TextColor3 = npcInfo.DisplayName and npcInfo.DisplayName.Color or Color3.new(0)
		end

		te1 = fadeInFrame(bar, first or v.FadeInCharacter)
		te1:Play()
		--Storage.Animations.Actions.Talking
		if v.Animation then
			local found = Storage.Animations.Actions:FindFirstChild(v.Animation, true)
			if found and hum then
				local animtrac = hum:LoadAnimation(found)
				animtrac:Play(found:GetAttribute("FadeTime") or 1)
				table.insert(playingAnims, animtrac)
			end
		end
		task.wait(te1.TweenInfo.Time)
		--frame.Visible = true

		local lastOption = options[i - 1]

		local canAlt = false
		if v.AltText and v.AltText.Condition then
			local past = tonumber(v.AltText.Condition.Past) or lastOption
			local ans = v.AltText.Condition.Answer

			canAlt = options[past] == ans
			latestAlt = options[past] == ans
		end

		lineMessage(canAlt and v.AltText.Text or v.Text, nil, label)


		if v.NameChange and v.NameChange.Text and tframe then
			tframe.TextLabel.Text = v.NameChange.Text
			tframe.TextLabel.TextColor3 = v.NameChange.Color or Color3.new(0)
		end

		local canContinue = false
		local myCon, myCon2
		if v.QuestFinished and displayName then
			questRem:FireServer("questRemove", displayName)
		end
		if not v.Specialty then
			arrow.Size = BAR_SETTINGS[bar].OGArrowSize
			arrow.Visible = true
			generalTES[arrow] = TS:Create(arrow, TIS.arrowUpNDown, {Size = UDim2.fromScale(BAR_SETTINGS[bar].OGArrowSize.X.Scale - 0.15, BAR_SETTINGS[bar].OGArrowSize.Y.Scale - 0.15)})
			generalTES[arrow]:Play()

			myCon = UIS.InputBegan:Connect(function(inp, gP)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
					canContinue = true
				end
			end)
			table.insert(generalCons, myCon)

			if generalCons[arrow] then
				generalCons[arrow]:Disconnect()
			end
			local function arrowshi()
				if generalCons[arrow] then
					generalCons[arrow]:Disconnect()
				end
				arrow.Rotation = BAR_SETTINGS[bar].OGArrowRotation + math.random(-5, 25)
				arrow.Size = BAR_SETTINGS[bar].OGArrowSize
				generalTES[arrow] = TS:Create(arrow, TIS.arrowUpNDown, {Size = UDim2.fromScale(BAR_SETTINGS[bar].OGArrowSize.X.Scale - 0.15, BAR_SETTINGS[bar].OGArrowSize.Y.Scale - 0.15)})
				generalTES[arrow]:Play()

				generalCons[arrow] = generalTES[arrow].Completed:Connect(function()
					arrowshi()
				end)
			end
			generalCons[arrow] = generalTES[arrow].Completed:Connect(function()
				arrowshi()
			end)
		else
			if string.sub(v.Specialty, 1, 3) == "Y/N" or v.Specialty == "Options" then
				-- 1. Determine Option Labels
				local choiceNames = {}
				if string.sub(v.Specialty, 1, 3) == "Y/N" then
					choiceNames[1] = (v.ButtonOptionNames and v.ButtonOptionNames[1]) or "Yeah"
					choiceNames[2] = (v.ButtonOptionNames and v.ButtonOptionNames[2]) or "Nah"
				else
					-- Full choice array for general "Options"
					choiceNames = v.ButtonOptionNames or {"Option 1", "Option 2"}
				end

				-- 2. Setup Container & Clear Old Dynamic Option Buttons
				-- (Adjust OptionsContainer / OptionTemplate paths to match your UI hierarchy)
				local optionsContainer = personFrame:FindFirstChild("Options") 
				local optionTemplate = optionsContainer and script:FindFirstChild("OptionTemplate")

				if optionsContainer and optionTemplate then
					optionsContainer.Visible = true
					for _, child in ipairs(optionsContainer:GetChildren()) do
						if child:IsA("GuiObject") and child ~= optionTemplate then
							-- Disconnect connections before destroying
							if generalCons[child] then
								for _, conn in ipairs(generalCons[child]) do conn:Disconnect() end
								generalCons[child] = nil
							end
							child:Destroy()
						end
					end
				end
				
				local protected = {}
				
				-- 3. Spawn Buttons & Bind Interactions
				for idx, choiceText in ipairs(choiceNames) do
					local btn

					if optionsContainer and optionTemplate then
						-- Clone dynamic option button
						btn = optionTemplate:Clone()
						btn.Name = "Option_" .. idx
						btn.Visible = true
						btn.Parent = optionsContainer
					else
						-- Fallback: If you have pre-placed option frames in Studio (e.g., Option1, Option2)
						btn = optionsContainer:FindFirstChild("Option" .. idx)
					end
					
					if not btn then continue end
					protected[btn] = true

					-- Update button Label Text
					local sinker =  btn.InImage:FindFirstChild("Sinker") or btn.InImage:FindFirstChildOfClass("TextButton")
					local label = sinker:FindFirstChild("SampleText") or sinker:FindFirstChildOfClass("TextLabel")
					if label then
						label.Text = choiceText
					end

					-- Bind Choice Buttons
					local fold, playClickAnim = bindChoice(btn)

					table.insert(fold, sinker.MouseButton1Click:Connect(function()
						-- 1. Disable options container to block double inputs
						if optionsContainer then
							for _, child in ipairs(optionsContainer:GetChildren()) do
								if child:IsA("GuiObject") then 
									local sinker = child.InImage:FindFirstChildOfClass("TextButton")
									sinker.Active = false
								end
							end
						end

						-- 2. Play Click Flash & Freeze Animation
						playClickAnim()

						-- 3. Sub-Specialty Actions (Quests / Actions triggered by Option 1 on Y/N)
						local specialtySub2 = string.sub(v.Specialty, 5)
						if idx == 1 then
							if specialtySub2 == "Quest" and displayName then
								questRem:FireServer("questRequest", displayName)
								if v.Action then
									questRem:FireServer("actionRequest", displayName, v.Action.Name, v.Action.Parameters and table.unpack(v.Action.Parameters))
									if npcObject then clientSideNPCActions.Run(v.Action.Name, npcObject, v.Action.Parameters) end -- NEW
								end
							elseif specialtySub2 == "Action" then
								questRem:FireServer("actionRequest", displayName, v.Action)
								if npcObject then clientSideNPCActions.Run(v.Action.Name, npcObject, v.Action.Parameters) end
							elseif specialtySub2 == "ServerAction" then
								questRem:FireServer(
									"actionRequest", 
									displayName or ((typeof(givenDialogue) == 'string' and givenDialogue) or (typeof(givenDialogue) == 'Instance' and givenDialogue.Name)), 
									v.Action.Name, 
									v.Action.Parameters and table.unpack(v.Action.Parameters)
								)
							end
						end


						-- 5. Store Selection
						if string.sub(v.Specialty, 1, 3) == "Y/N" then
							options[i] = (idx == 1 and 'accepted') or 'declined'
						else
							options[i] = choiceText
						end
						
						coroutine.wrap(function()
							if generalTES[personFrame] and generalTES[personFrame].PlaybackState == Enum.PlaybackState.Playing then
								generalTES[personFrame]:Cancel()
							end
							generalTES[personFrame] = TS:Create(personFrame, TIS.frameSlowOut, {Position = BAR_SETTINGS.PersonStartOut})
							generalTES[personFrame]:Play()
							if generalTES[blackoutFrame] and generalTES[personFrame].PlaybackState == Enum.PlaybackState.Playing then
								generalTES[blackoutFrame]:Cancel()
							end
							generalTES[blackoutFrame] = TS:Create(blackoutFrame, TIS.frameVelIn, {BackgroundTransparency = 1})
							generalTES[blackoutFrame]:Play()
						end)()
						
						task.wait(0.5)
						canContinue = true
					end))
				end
				if generalTES[personFrame] and generalTES[personFrame].PlaybackState == Enum.PlaybackState.Playing then
					generalTES[personFrame]:Cancel()
				end
				generalTES[personFrame] = TS:Create(personFrame, TIS.frameVelIn, {Position = BAR_SETTINGS.PersonEndIn})
				generalTES[personFrame]:Play()
				
				if generalTES[blackoutFrame] and generalTES[personFrame].PlaybackState == Enum.PlaybackState.Playing then
					generalTES[blackoutFrame]:Cancel()
				end
				generalTES[blackoutFrame] = TS:Create(blackoutFrame, TIS.frameGlideIn, {BackgroundTransparency = BAR_SETTINGS.BlackoutChatTransparency})
				generalTES[blackoutFrame]:Play()
				
				for i, v in pairs(optionsContainer:GetChildren()) do
					if v:IsA("ImageLabel") then
						if not protected[v] then
							v:Destroy()
						end
					end
				end
			end
		end

		repeat wait() until canContinue

		if myCon then
			myCon:Disconnect()
			myCon = nil
		end

		--if generalCons[accept] then
		--	for i, v in pairs(generalCons[accept]) do
		--		v:Disconnect()
		--	end
		--	generalCons[accept] = nil
		--end
		--if generalCons[decline] then
		--	for i, v in pairs(generalCons[decline]) do
		--		v:Disconnect()
		--	end
		--	generalCons[decline] = nil
		--end

		if generalCons[arrow] then
			generalCons[arrow]:Disconnect()
		end
		if generalTES[arrow] then
			if generalTES[arrow].PlaybackState == Enum.PlaybackState.Playing then
				generalTES[arrow]:Cancel()
			end
		end
		--if generalTES[accept] then
		--	if generalTES[accept].PlaybackState == Enum.PlaybackState.Playing then
		--		generalTES[accept]:Cancel()
		--	end
		--end
		--if generalTES[decline] then
		--	if generalTES[decline].PlaybackState == Enum.PlaybackState.Playing then
		--		generalTES[decline]:Cancel()
		--	end
		--end

		--arrow.Visible = false

		--accept.Visible = false
		--accept.Whiteout.BackgroundTransparency = 1
		--decline.Visible = false
		--decline.Whiteout.BackgroundTransparency = 1
		if (dilog[i + 1] and (dilog[i + 1].TextboxType ~= dilog[i].TextboxType)) and latestTextObject then
			latestTextObject:Hide()
		end
		te1 = fadeOutFrame(bar, (dilog[i + 1] and (dilog[i + 1].TextboxType ~= dilog[i].TextboxType or dilog[i + 1].FadeInCharacter)) or i == #dilog)
		te1:Play()
		te1.Completed:Wait()
		first = false
	end 

	if dilog.NextDialogue then
		if dilog.NextDialogue.Condition then
			local past = tonumber(dilog.NextDialogue.Condition.Past)
			local ans = dilog.NextDialogue.Condition.Answer
			--print(past)
			--print(ans)

			nextDialogue = (options[past] == ans and dilog.NextDialogue.Dialogue)
		else
			nextDialogue = dilog.NextDialogue.Dialogue
		end
	end

	if displayName and tframe then
		npcRem:FireServer("end", displayName, (((latestAlt) and latestV.AltText.NextDialogue)) or nextDialogue or nil)
	end

	for i, v in pairs(generalTES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	generalTES = {}

	for i, v in pairs(generalCons) do
		if typeof(v) == 'RBXScriptConnection' then
			v:Disconnect()
		elseif typeof(v) == 'table' then
			for i2, v2 in pairs(v) do
				if typeof(v2) == 'RBXScriptConnection' then
					v2:Disconnect()
				end
			end
		end
	end
	generalCons = {}


	--arrow.Visible = false

	--accept.Visible = false
	--accept.Whiteout.BackgroundTransparency = 1
	--accept.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	--accept.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	--decline.Visible = false
	--decline.Whiteout.BackgroundTransparency = 1
	--decline.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	--decline.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	label.Text = ""

	if latestTextObject then
		latestTextObject:Hide()
	end
	if tframe then
		--tframe.Visible = false
		tframe.TextLabel.Text = ""
	end

	for _, anim in ipairs(playingAnims) do
		anim:Stop()
	end
	NPCM.currentNPC = nil
	NPCM.IsActive = false
end

function NPCM.setup()
	--bar.Visible = false

	-- Preload all sprite sheet images and start animation loops.
	-- Runs in a coroutine so setup() returns immediately and doesn't
	-- block the caller while ContentProvider yields.
	-- IMPORTANT: initSpriteSheets() must run before any chatbar opens,
	-- so call NPCM.setup() early (e.g. in your top-level LocalScript init).

	defbar.CharacterVPF.Visible = true
	-- preloading
	for bar, v in pairs(BAR_SETTINGS) do
		if typeof(bar) == 'Instance' and bar:IsA("Frame") then
			bar.Visible = true
			bar.Secondary.Visible = true
			bar.Secondary.Size    = UDim2.fromScale(0.0001, 0.0001)

			bar.Secondary.ContentFrame.SampleText.Text = ""
			--bar.Secondary.Size = UDim2.fromScale(0, 0)
		end
	end
	--
	
	defbar.CharacterVPF.Position = UDim2.fromScale(BAR_SETTINGS[defbar].OGImgPos.X.Scale - 0.1, BAR_SETTINGS[defbar].OGImgPos.Y.Scale)
	defbar.CharacterVPF.ImageTransparency = 1

	personFrame.Position = BAR_SETTINGS.PersonStartOut
	
	coroutine.wrap(initSpriteSheets)()

	--charbar.Size = UDim2.fromScale(0, 0)
	--thinkbar.Size = UDim2.fromScale(0, 0)
	--frame:WaitForChild("SampleText"):Destroy()
	--frame:WaitForChild("TextLabel").Visible = true

	--bar.Size = UDim2.new(BAR_SETTINGS.OGSize.X.Scale * 0.85, 0, BAR_SETTINGS.OGSize.Y.Scale * 0.85, 0)
	--bar.BackgroundTransparency = 1
	--bar.Chatbar2.ImageTransparency = 1
	--for i = 1, 5 do
	--	local line = mainFrame:FindFirstChild("Line"..tostring(i))
	--	if line then
	--		line.BackgroundTransparency = 1
	--	end
	--end
	--frame.Visible = false
	--arrow.Visible = false

	--accept.Visible = false
	--accept.Whiteout.BackgroundTransparency = 1
	--accept.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	--accept.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	--decline.Visible = false
	--decline.Whiteout.BackgroundTransparency = 1
	--decline.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	--decline.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	--arrow.Position = BAR_SETTINGS.OGArrowPos
	--label.Text = ""
	--tframe.Visible = false
	--tframe.TextLabel.Text = ""

	npcRem.OnClientEvent:Connect(function(dialogueObj, dialogueName, displayName)
		if (dialogueName and npcIndex[dialogueName]) or npcIndex[dialogueObj.Name] then
			NPCM.runNPC(dialogueObj, dialogueName, displayName)
		end
	end)
end

return NPCM