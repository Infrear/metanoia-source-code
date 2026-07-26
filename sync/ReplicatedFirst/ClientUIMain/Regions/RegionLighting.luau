-- ============================================================
-- RegionLighting (ModuleScript — child of Regions)
-- Handles all lighting, atmosphere, post-effects, and gravity
-- transitions when the player enters a region.
--
-- LIGHTING DATA FORMAT (set via workspace.REGIONS.Outlining.[RegionName] Attributes):
--   Attribute "LightingPreset" = string key into the Lightings module
--   Attribute "Gravity"        = number (default 196.2)
--   Attribute "IsDreamWorld"   = bool (routes to DreamWorld mixer)
--
-- Post-processing effects (Bloom, ColorCorrection, DepthOfField, SunRays)
-- are stored as children of Lighting service and tweened in/out.
-- ============================================================

-- Services
local TS  = game:GetService("TweenService")
local LT  = game:GetService("Lighting")
local RPS = game:GetService("ReplicatedStorage")

-- Dependencies
local Storage  = RPS:WaitForChild("ClientStorage")
local lightings = require(Storage:WaitForChild("Info"):WaitForChild("Lightings"))

-- TweenInfos
local TI_SLOW = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TI_FAST = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

-- Default lighting fallback — used when a region has no preset
-- Mirrors your Defaults table from SpacePlanetGameLighting
local DEFAULTS = {
	Lighting = {
		Ambient           = Color3.fromRGB(75, 75, 75),
		OutdoorAmbient    = Color3.fromRGB(103, 103, 103),
		Brightness        = 4,
		ClockTime         = 15.338,
		FogEnd            = 100000,
		FogColor          = Color3.fromRGB(192, 192, 192),
		ExposureCompensation = 0,
		EnvironmentDiffuseScale = 1,
		EnvironmentSpecularScale  = 1,
	},
	Atmosphere = {
		Color   = Color3.fromRGB(79, 137, 199),
		Decay   = Color3.fromRGB(117, 162, 202),
		Density = 0.312,
		Glare   = 0.68,
		Haze    = 0.41,
	},
	Bloom = {
		Intensity = 0.15,
		Size      = 24,
		Threshold = 2,
	},
	ColorCorrection = {
		Brightness = 0.1,
		Contrast   = 0.1,
		Saturation = 0.5,
		TintColor  = Color3.fromRGB(255, 255, 255),
	},
	SunRays = {
		Intensity = 0.055,
		Spread    = 274,
	},
	DepthOfField = nil, -- disabled by default
	Gravity = 196.2,
}

-- ── Active tween tracker so we can cancel mid-transition ────
local activeTweens = {}

local function cancelActive()
	for _, tw in ipairs(activeTweens) do
		if tw.PlaybackState == Enum.PlaybackState.Playing then tw:Cancel() end
	end
	activeTweens = {}
end

local function tween(target, info, props)
	local tw = TS:Create(target, info, props)
	table.insert(activeTweens, tw)
	tw:Play()
	return tw
end

-- ── Lighting service properties that can be tweened directly ─
local TWEENEABLE_LT_PROPS = {
	"Ambient", "OutdoorAmbient", "Brightness", "ClockTime",
	"FogEnd", "FogColor", "ExposureCompensation",
	"EnvironmentalDiffuseScale", "EnvironmentSpecularScale",
}

local function applyLighting(preset)
	if not preset then preset = DEFAULTS end
	cancelActive()

	-- Tween Lighting service properties
	local ltProps = {}
	for _, propName in ipairs(TWEENEABLE_LT_PROPS) do
		if preset.Lighting and preset.Lighting[propName] ~= nil then
			ltProps[propName] = preset.Lighting[propName]
		elseif DEFAULTS.Lighting[propName] ~= nil then
			ltProps[propName] = DEFAULTS.Lighting[propName]
		end
	end
	if next(ltProps) then tween(LT, TI_SLOW, ltProps) end

	-- Atmosphere
	local atmo = LT:FindFirstChildOfClass("Atmosphere")
	if atmo and (preset.Atmosphere or DEFAULTS.Atmosphere) then
		local a = preset.Atmosphere or DEFAULTS.Atmosphere
		tween(atmo, TI_SLOW, {
			Color   = a.Color   or DEFAULTS.Atmosphere.Color,
			Decay   = a.Decay   or DEFAULTS.Atmosphere.Decay,
			Density = a.Density or DEFAULTS.Atmosphere.Density,
			Glare   = a.Glare   or DEFAULTS.Atmosphere.Glare,
			Haze    = a.Haze    or DEFAULTS.Atmosphere.Haze,
		})
	end

	-- Post-effects: Bloom, ColorCorrection, SunRays, DepthOfField
	local function applyEffect(className, data, defaultData)
		local fx = LT:FindFirstChildOfClass(className)
		if not fx then return end
		local d = data or defaultData
		if not d then
			-- disable by making threshold very high / intensity 0
			return
		end
		tween(fx, TI_FAST, d)
	end

	applyEffect("BloomEffect",          preset.Bloom,           DEFAULTS.Bloom)
	applyEffect("ColorCorrectionEffect", preset.ColorCorrection, DEFAULTS.ColorCorrection)
	applyEffect("SunRaysEffect",         preset.SunRays,         DEFAULTS.SunRays)

	-- DepthOfField — only tween if preset provides one; otherwise remove
	local dof = LT:FindFirstChildOfClass("DepthOfFieldEffect")
	if preset.DepthOfField then
		if not dof then
			dof = Instance.new("DepthOfFieldEffect", LT)
		end
		tween(dof, TI_FAST, preset.DepthOfField)
	elseif dof then
		-- fade out FocusDistance to effectively disable blur, then remove
		tween(dof, TI_FAST, { FarIntensity = 0, NearIntensity = 0 })
	end

	-- Gravity
	local gravity = (preset.Gravity ~= nil) and preset.Gravity or DEFAULTS.Gravity
	workspace.Gravity = gravity
end

-- ── Ambience Shifting ────────────────────────────────────────
-- Periodically nudges lighting values for a living, breathing feel.
-- Runs only when enabled via startAmbience / stopAmbience.
-- Each shift picks random targets within the preset's allowed range.

local ambienceConn   = nil
local ambienceActive = false

local function stopAmbience()
	ambienceActive = false
	if ambienceConn then
		ambienceConn:Disconnect()
		ambienceConn = nil
	end
end

-- ambienceCfg = {
--   IntervalMin  = 4,    -- seconds between shifts
--   IntervalMax  = 9,
--   BloomRange   = { 0.1, 0.4 },      -- [min, max] for Intensity
--   BrightnessRange = { -0.05, 0.05 },
--   TintRange    = nil,  -- optional: {Color3 low, Color3 high}
-- }
local function startAmbience(ambienceCfg)
	stopAmbience()
	if not ambienceCfg then return end
	ambienceActive = true

	local RS = game:GetService("RunService")
	local elapsed = 0
	local nextShift = math.random(
		(ambienceCfg.IntervalMin or 4),
		(ambienceCfg.IntervalMax or 9)
	)

	ambienceConn = RS.Heartbeat:Connect(function(dt)
		if not ambienceActive then return end
		elapsed += dt
		if elapsed < nextShift then return end
		elapsed = 0
		nextShift = math.random(
			(ambienceCfg.IntervalMin or 4),
			(ambienceCfg.IntervalMax or 9)
		)

		-- Shift bloom intensity
		local bloom = LT:FindFirstChildOfClass("BloomEffect")
		if bloom and ambienceCfg.BloomRange then
			local lo, hi = ambienceCfg.BloomRange[1], ambienceCfg.BloomRange[2]
			tween(bloom, TI_SLOW, { Intensity = lo + math.random() * (hi - lo) })
		end

		-- Shift brightness
		local cc = LT:FindFirstChildOfClass("ColorCorrectionEffect")
		if cc and ambienceCfg.BrightnessRange then
			local lo, hi = ambienceCfg.BrightnessRange[1], ambienceCfg.BrightnessRange[2]
			tween(cc, TI_SLOW, { Brightness = lo + math.random() * (hi - lo) })
		end

		-- Shift saturation
		if cc and ambienceCfg.SaturationRange then
			local lo, hi = ambienceCfg.SaturationRange[1], ambienceCfg.SaturationRange[2]
			tween(cc, TI_SLOW, { Saturation = lo + math.random() * (hi - lo) })
		end

		-- Shift clock time (subtle day progression)
		if ambienceCfg.ClockRange then
			local lo, hi = ambienceCfg.ClockRange[1], ambienceCfg.ClockRange[2]
			tween(LT, TI_SLOW, { ClockTime = lo + math.random() * (hi - lo) })
		end
	end)
end

-- ============================================================
-- MODULE
-- ============================================================
local RegionLighting = {}

-- PlanetSystem is optionally attached here if enabled
RegionLighting._planetSystem = nil

function RegionLighting.attachPlanetSystem(planetMod)
	RegionLighting._planetSystem = planetMod
end

-- Called by Regions when the player enters a new region.
-- regionModel = the workspace region Model
-- regionData  = { LightingPreset=string, Gravity=number, Ambience=table, IsDreamWorld=bool }
function RegionLighting.applyForRegion(regionModel, regionData)
	-- Resolve lighting preset
	local presetKey = regionData and regionData.LightingPreset
	local preset    = (presetKey and lightings[presetKey]) or DEFAULTS

	-- If this is a dream world region, mix in DreamWorld overrides
	if regionData and regionData.IsDreamWorld then
		-- DreamWorld module handles its own lighting blend; we still apply
		-- base region preset first so its values are the floor
		applyLighting(preset)
		-- DreamWorld.applyLighting() will layer on top — called separately
	else
		applyLighting(preset)
	end

	-- Gravity override
	if regionData and regionData.Gravity then
		workspace.Gravity = regionData.Gravity
	end

	-- Ambience shifting
	stopAmbience()
	if regionData and regionData.Ambience then
		startAmbience(regionData.Ambience)
	end

	-- Planet system hook (only fires if planet system is enabled)
	if RegionLighting._planetSystem and RegionLighting._planetSystem.enabled then
		RegionLighting._planetSystem.onRegionChanged(regionModel, regionData)
	end
end

function RegionLighting.applyDefaults()
	applyLighting(DEFAULTS)
	stopAmbience()
end

function RegionLighting.stopAmbience()
	stopAmbience()
end

return RegionLighting