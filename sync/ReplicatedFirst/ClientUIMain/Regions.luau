-- ============================================================
-- Regions (ModuleScript — main processor)
-- Detects region entry/exit and dispatches to all submodules:
--   • RegionLighting  — lighting, atmosphere, gravity, ambience
--   • CityLife        — walker NPCs, car traffic (future), city sounds
--   • TerrainLoader   — decorative terrain asset streaming
--   • DreamWorld      — dream-specific layered effects
--
-- PlanetSystem is attached to RegionLighting but is DISABLED
-- by default — set it up and enable it only if you need it.
--
-- REGION SETUP IN STUDIO:
--   Place trigger parts inside workspace.REGIONS.Outlining.[RegionName]
--   Add Attributes to that folder:
--     LightingPreset  (string) — key into Lightings module
--     Gravity         (number) — workspace.Gravity override
--     IsDreamWorld    (bool)   — routes through DreamWorld.onEnterRegion
--     IsCityRegion    (bool)   — routes through CityLife.onEnter
--     WalkerModelName (string) — NPCWalker model name in workspace.NPCWALKERS
--     AmbientSoundId  (string) — rbxassetid:// for city ambient loop
--     TerrainAssets   (string) — comma-separated asset names in ClientStorage.TerrainAssets
--     Ambience        (bool)   — enable random ambience shifting for this region
--
-- REGION CONFIG TABLE (alternative to Attributes — set via regionConfig below)
--   For complex setups, define the config table directly in this file.
--   Attributes on the workspace model take precedence over the table.
-- ============================================================

-- Constants
local FADE_DURATION  = 1
local MOVE_DURATION  = 2.5
local ORIGIN_POSITION = UDim2.new(0.425, 0, 0.722, 0)
local POSITION_OFFSET = Vector2.new(0, 0.05)

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS  = game:GetService("TweenService")

-- Dependencies
local Storage    = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)
local richText   = require(Storage.Modules:WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("RichText"))
local Regions    = workspace:WaitForChild("REGIONS")

local plr = game.Players.LocalPlayer
repeat wait() until plr.Character ~= nil
local char      = plr.Character
local hum       = char:WaitForChild("Humanoid")
local hrp       = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui       = playerGUI:WaitForChild("OverworldUI")
local frame    = ui:WaitForChild("Regions")
local textArea = frame:WaitForChild("TextArea")
local textObject   = nil
local currentRegion = nil
local currentRegionName = nil

-- ── Submodules ───────────────────────────────────────────────
local RegionLighting = require(script:WaitForChild("RegionLighting"))
local CityLife       = require(script:WaitForChild("CityLife"))
local TerrainLoader  = require(script:WaitForChild("TerrainLoader"))
local DreamWorld     = require(script:WaitForChild("DreamWorld"))

-- ── PlanetSystem (DISABLED BY DEFAULT) ───────────────────────
-- To enable: set PlanetSystem.enabled = true, then call
-- PlanetSystem.init(planetDefs, options) in your game init script.
-- RegionLighting.attachPlanetSystem(PlanetSystem) wires it in.
local PlanetSystem = require(script.RegionLighting:WaitForChild("PlanetSystem"))
-- PlanetSystem.enabled = false  ← already the default inside PlanetSystem.lua
RegionLighting.attachPlanetSystem(PlanetSystem)
-- To turn on planets:
--   PlanetSystem.enabled = true
--   PlanetSystem.init({ Mars = { Core = Vector3.new(...), Gravity = ..., Lighting = lightings.Mars } })

-- ── TweenInfos ───────────────────────────────────────────────
local TIS = {
	[1] = TweenInfo.new(FADE_DURATION),
	[2] = TweenInfo.new(
		MOVE_DURATION,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0, false, 0
	),
}

-- ── Per-region config table ───────────────────────────────────
-- Override or supplement Attributes here for complex region setups.
-- Attributes on the workspace model take precedence.
-- Format matches the Attributes described above.
local regionConfig = {
	-- Example:
	-- ["Kakaran Village"] = {
	--   LightingPreset   = "VillageDay",
	--   Gravity          = 196.2,
	--   IsCityRegion     = true,
	--   WalkerModelName  = "NPCWalker_Village",
	--   AmbientSoundId   = "rbxassetid://1234567890",
	--   TerrainAssets    = { "VillageProps", "VillageTrees" },
	--   Ambience         = { IntervalMin=6, IntervalMax=12, BloomRange={0.1,0.3} },
	-- },
	-- ["DreamArena"] = {
	--   LightingPreset = "DreamBase",
	--   IsDreamWorld   = true,
	--   Gravity        = 100,
	-- },
}

-- ── Variables ────────────────────────────────────────────────
local TES  = {}
local cons = {}
local ev   = Instance.new("BindableEvent")

-- ── Initialization ───────────────────────────────────────────
local regions      = {}
regions.Ready      = Instance.new("BindableEvent")
regions.DreamWorld = DreamWorld   -- expose for external use (e.g. WobblyScreen path)

-- ============================================================
-- INTERNAL: Region Data Resolution
-- Merges workspace Attributes with the regionConfig table.
-- Attributes take precedence over config table values.
-- ============================================================

local function resolveRegionData(regionModel, regionName)
	local cfg  = regionConfig[regionName] or {}
	local data = {}

	-- Helper: read attribute with config fallback
	local function get(key, default)
		local v = regionModel:GetAttribute(key)
		return (v ~= nil) and v or (cfg[key] ~= nil and cfg[key] or default)
	end

	data.LightingPreset    = get("LightingPreset",   nil)
	data.Gravity           = get("Gravity",           nil)
	data.IsDreamWorld      = get("IsDreamWorld",      false)
	data.IsCityRegion      = get("IsCityRegion",      false)
	data.WalkerModelName   = get("WalkerModelName",   nil)
	data.WalkerModelNames  = cfg.WalkerModelNames      -- array; attribute version not supported
	data.AmbientSoundId    = get("AmbientSoundId",    nil)
	data.Ambience          = cfg.Ambience              -- complex table — config only

	-- TerrainAssets: support comma-separated string attribute OR table in config
	local terrainAttr = regionModel:GetAttribute("TerrainAssets")
	if terrainAttr then
		data.TerrainAssets = {}
		for name in terrainAttr:gmatch("[^,]+") do
			table.insert(data.TerrainAssets, name:match("^%s*(.-)%s*$"))
		end
	else
		data.TerrainAssets = cfg.TerrainAssets
	end
	data.TerrainParent = get("TerrainParent", "TERRAIN")

	return data
end

-- ============================================================
-- INTERNAL: Region Entry / Exit
-- ============================================================

local function onRegionEnter(regionModel, regionName)
	local data = resolveRegionData(regionModel, regionName)

	-- 1. Lighting (always runs)
	RegionLighting.applyForRegion(regionModel, data)

	-- 2. Dream World layer (runs on top of lighting if flagged)
	if data.IsDreamWorld then
		DreamWorld.onEnterRegion(regionName, data)
		-- Tag character so WalkEffects knows to use cloud surface
		char:SetAttribute("SurfaceEffect", "Cloud")
	end

	-- 3. City Life (NPCs, sounds)
	if data.IsCityRegion then
		CityLife.onEnter(regionName, data)
	end

	-- 4. Terrain loading
	if data.TerrainAssets and #data.TerrainAssets > 0 then
		TerrainLoader.load(regionName, data)
	end
end

local function onRegionLeave(regionModel, regionName)
	local data = resolveRegionData(regionModel, regionName)

	-- Dream World
	if data.IsDreamWorld then
		DreamWorld.onLeaveRegion(regionName)
		char:SetAttribute("SurfaceEffect", nil)
	end

	-- City Life
	if data.IsCityRegion then
		CityLife.onLeave(regionName, data)
	end

	-- Terrain
	if data.TerrainAssets and #data.TerrainAssets > 0 then
		TerrainLoader.unload(regionName)
	end

	-- Restore default lighting when leaving any region
	-- (next region entry will override this immediately if entering another)
	RegionLighting.applyDefaults()
end

-- ============================================================
-- INTERNAL: Region Name Text Animation
-- Preserved exactly from original Regions.lua
-- ============================================================

local function animateText(txt)
	ev:Fire()
	if TES[textArea] then
		for i, v in pairs(TES[textArea]) do
			if i ~= textArea then
				if v[1].PlaybackState == Enum.PlaybackState.Playing then
					v[1]:Cancel()
				end
				i[v[2]] = v[3]
			else
				if v.PlaybackState == Enum.PlaybackState.Playing then
					v:Cancel()
				end
				textArea.Position = ORIGIN_POSITION
			end
		end
	end

	TES[textArea] = {}

	local text = "<AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=.5><Color=White>" .. txt
	textObject  = richText:New(textArea, text, { ContainerHorizontalAlignment = "Right" }, false)

	local oldTextObject = textObject
	textObject:Animate(true)
	local toContinue = true
	local con
	con = ev.Event:Connect(function()
		toContinue = false
		if con then con:Disconnect() end
	end)
	task.wait(1.5)
	if con then con:Disconnect() end
	if not toContinue then oldTextObject:Hide() return end

	for _, v in ipairs(textArea:GetDescendants()) do
		if v:IsA("TextLabel") then
			local tween = TS:Create(v, TIS[1], { TextTransparency = 1 })
			TES[textArea][v] = { tween, "TextTransparency", v.TextTransparency }
			tween:Play()
		end
	end
	TES[textArea][textArea] = TS:Create(textArea, TIS[1], {
		Position = UDim2.new(
			ORIGIN_POSITION.X.Scale + POSITION_OFFSET.X, 0,
			ORIGIN_POSITION.Y.Scale + POSITION_OFFSET.Y, 0
		)
	})
	TES[textArea][textArea]:Play()
end

-- ============================================================
-- GLOBAL FUNCTIONS
-- ============================================================

function regions.setup()
	-- Build region model map from workspace
	local regionModels = {}
	for _, v in ipairs(Regions.Outlining:GetChildren()) do
		regionModels[v.Name] = v
	end

	-- Detect entry via Touched
	hrp.Touched:Connect(function(part)
		for regionName, regionModel in pairs(regionModels) do
			if part:IsDescendantOf(regionModel) and regionModel ~= currentRegion then
				-- Leave previous region
				if currentRegion and currentRegionName then
					onRegionLeave(currentRegion, currentRegionName)
				end

				currentRegion     = regionModel
				currentRegionName = regionName

				-- Animate name text
				animateText(regionName)

				-- Fire all submodule handlers
				onRegionEnter(regionModel, regionName)
				break
			end
		end
	end)

	-- NOTE: Exit detection via Touched alone is unreliable (TouchEnded can miss).
	-- For robust exit detection, use a Part with CanCollide=false + TouchEnded
	-- OR poll hrp position against region bounds each Heartbeat.
	-- For now, entering a new region automatically triggers leave on the old one (above).
	-- If you need explicit "no region" detection, add a Heartbeat poll here.
end

-- Manual triggers for external systems (e.g. city loading screens)
function regions.triggerEnter(regionName)
	local regionModels = {}
	for _, v in ipairs(Regions.Outlining:GetChildren()) do
		regionModels[v.Name] = v
	end
	local model = regionModels[regionName]
	if model then
		if currentRegion and currentRegionName then
			onRegionLeave(currentRegion, currentRegionName)
		end
		currentRegion     = model
		currentRegionName = regionName
		onRegionEnter(model, regionName)
	end
end

function regions.triggerLeave()
	if currentRegion and currentRegionName then
		onRegionLeave(currentRegion, currentRegionName)
		currentRegion     = nil
		currentRegionName = nil
	end
end

return regions