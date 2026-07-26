-- ============================================================
-- DreamWorld (ModuleScript — child of Regions or standalone)
-- Manages everything that makes the Dream World feel alive:
--   • Drifting background clouds (folder-based, parallax speeds)
--   • Breathing bob tweens on arena cloud platforms
--   • Ambient particle wind via GlobalWind
--   • Dream-specific lighting layer that mixes with region base
--   • Ambience shifting (repeating random lighting nudges)
--   • Gravity override for floating feel
--   • Public hooks for WobblyScreen and CloudDropOnStep scripts
--
-- The dream world coexists with Regions — when the player enters
-- a DreamWorld region, Regions fires DreamWorld.onEnterRegion()
-- which layers dream lighting on top of the base region preset.
-- ============================================================

-- Services
local RS  = game:GetService("RunService")
local TS  = game:GetService("TweenService")
local LT  = game:GetService("Lighting")
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local floatables = workspace:WaitForChild("RESOURCES"):WaitForChild("dreamworld"):WaitForChild("floatables")

local plr  = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

plr.CharacterAdded:Connect(function(newChar)
	char = newChar
	hrp  = newChar:WaitForChild("HumanoidRootPart")
end)

-- ── TweenInfos ───────────────────────────────────────────────
local TI_BOB     = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local TI_DRIFT   = nil  -- built per-cloud with random duration
local TI_LIGHT   = TweenInfo.new(2,   Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TI_FAST    = TweenInfo.new(0.4, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)

local rParams = RaycastParams.new()
--rParams.FilterType = Enum.RaycastFilterType.Exclude
--rParams.FilterDescendantsInstances = {char}
rParams.FilterType = Enum.RaycastFilterType.Include
rParams.FilterDescendantsInstances = {floatables}

-- ── Dream lighting preset (layered ON TOP of region base) ───
-- These values are mixed in when the player is in a DreamWorld region.
-- Adjust to taste; they'll blend with whatever the region set first.
local DREAM_LIGHTING_LAYER = {
	Bloom = {
		Intensity = 0.6,
		Size      = 30,
		Threshold = 1.2,
	},
	ColorCorrection = {
		Brightness = 0.1,
		Contrast   = 0.1,
		Saturation = 0.5,
		TintColor  = Color3.fromRGB(255, 255, 255), 
	},
	--ColorCorrection = {
	--	Brightness = 0.05,
	--	Contrast   = 0.05,
	--	Saturation = 0.7,
	--	TintColor  = Color3.fromRGB(220, 210, 255), -- soft lavender tint
	--},
	DepthOfField = {
		FarIntensity    = 0.4,
		NearIntensity   = 0,
		FocusDistance   = 130.24,
		InFocusRadius   = 30,
	},
	Atmosphere = {
		Color   = Color3.fromRGB(79, 137, 199),
		Decay   = Color3.fromRGB(117, 162, 202),
		Density = 0.312,
		Offset = 0.25,
		Haze    = 0.68,
		Glare   = 0.41,
	},
	--Atmosphere = {
	--	Color   = Color3.fromRGB(180, 170, 220),
	--	Decay   = Color3.fromRGB(100, 90, 160),
	--	Density = 0.15,
	--	Haze    = 2,
	--	Glare   = 4,
	--},
	Gravity  = 25,   -- floaty, not zero
	ClockTime = 14,   -- bright afternoon-ish
}

-- Ambience config for the Dream World
-- Random shifts keep the environment feeling alive
local DREAM_AMBIENCE = {
	IntervalMin      = 5,
	IntervalMax      = 12,
	BloomRange       = { 0.4, 0.9 },
	BrightnessRange  = { 0.1, 0.15 },
	SaturationRange  = { 0.5, 0.9 },
	ClockRange       = { 13.5, 15.5 },  -- subtle time drift during day
}

-- ── Internal state ───────────────────────────────────────────
local active          = false    -- is the player currently in the dream world?
local driftConns      = {}       -- RenderStepped connections for cloud drift
local bobTweens       = {}       -- active bob tweens on platforms
local ambienceConn    = nil
local globalWindActive = false

-- ============================================================
-- CLOUD DRIFTING
-- All models in workspace.DreamClouds.Background are drifted.
-- Sub-folders ("Layer1", "Layer2") get different speeds for parallax.
-- ============================================================

local DRIFT_AXIS = Vector3.new(1, 0, 0)  -- drift along X; change to Z if needed
local DRIFT_RESET_DIST = 300             -- studs from origin before wrapping

local function resolveInstance(currentInstance, furthestDescendant)
	if currentInstance.Parent.Parent.Parent == furthestDescendant then
		return currentInstance
	else
		local model = currentInstance:FindFirstAncestorWhichIsA("Model")
		if model and model.Parent.Parent.Parent == furthestDescendant then
			return model
		end
		return nil
	end
end

local function driftCloudFolder(folder, speed)
	local conn = RS.Heartbeat:Connect(function(dt)
		if not folder or not folder.Parent then return end
		for _, cloud in ipairs(folder:GetChildren()) do
			if cloud:IsA("Model") or cloud:IsA("BasePart") then
				local cur = cloud:IsA("Model") and cloud:GetPivot() or cloud.CFrame
				local newCF = cur * CFrame.new(DRIFT_AXIS * speed * dt)
				-- Wrap: if drifted too far, reset to opposite side
				if math.abs(newCF.Position.X) > DRIFT_RESET_DIST then
					newCF = CFrame.new(
						-math.sign(newCF.Position.X) * DRIFT_RESET_DIST,
						newCF.Position.Y,
						newCF.Position.Z
					) * CFrame.fromEulerAnglesXYZ(newCF:ToEulerAnglesXYZ())
				end
				if cloud:IsA("Model") then cloud:PivotTo(newCF)
				else cloud.CFrame = newCF end
			end
		end
	end)
	table.insert(driftConns, conn)
end

-- ============================================================
-- GLOBAL WIND (affects ParticleEmitters with WindAffectsDrag)
-- ============================================================

local function setGlobalWind(enabled)
	if enabled then
		workspace.GlobalWind = Vector3.new(1000, 0, 2)
		globalWindActive = true
	else
		workspace.GlobalWind = Vector3.new(0, 0, 0)
		globalWindActive = false
	end
end

-- ============================================================
-- AMBIENCE SHIFTING
-- ============================================================

local function stopAmbience()
	if ambienceConn then
		ambienceConn:Disconnect()
		ambienceConn = nil
	end
end

local function startAmbience()
	stopAmbience()
	local elapsed  = 0
	local nextShift = math.random(DREAM_AMBIENCE.IntervalMin, DREAM_AMBIENCE.IntervalMax)

	ambienceConn = RS.Heartbeat:Connect(function(dt)
		if not active then return end
		elapsed += dt
		if elapsed < nextShift then return end
		elapsed   = 0
		nextShift = math.random(DREAM_AMBIENCE.IntervalMin, DREAM_AMBIENCE.IntervalMax)

		local bloom = LT:FindFirstChildOfClass("BloomEffect")
		if bloom and DREAM_AMBIENCE.BloomRange then
			local lo, hi = DREAM_AMBIENCE.BloomRange[1], DREAM_AMBIENCE.BloomRange[2]
			TS:Create(bloom, TI_LIGHT, { Intensity = lo + math.random() * (hi - lo) }):Play()
		end

		local cc = LT:FindFirstChildOfClass("ColorCorrectionEffect")
		if cc then
			if DREAM_AMBIENCE.BrightnessRange then
				local lo, hi = DREAM_AMBIENCE.BrightnessRange[1], DREAM_AMBIENCE.BrightnessRange[2]
				TS:Create(cc, TI_LIGHT, { Brightness = lo + math.random() * (hi - lo) }):Play()
			end
			if DREAM_AMBIENCE.SaturationRange then
				local lo, hi = DREAM_AMBIENCE.SaturationRange[1], DREAM_AMBIENCE.SaturationRange[2]
				TS:Create(cc, TI_LIGHT, { Saturation = lo + math.random() * (hi - lo) }):Play()
			end
		end

		if DREAM_AMBIENCE.ClockRange then
			local lo, hi = DREAM_AMBIENCE.ClockRange[1], DREAM_AMBIENCE.ClockRange[2]
			TS:Create(LT, TI_LIGHT, { ClockTime = lo + math.random() * (hi - lo) }):Play()
		end
	end)
end

-- ============================================================
-- LIGHTING LAYER
-- Applied on top of whatever the region base lighting set.
-- ============================================================

local function applyDreamLighting()
	local bloom = LT:FindFirstChildOfClass("BloomEffect")
	if bloom then
		TS:Create(bloom, TI_LIGHT, DREAM_LIGHTING_LAYER.Bloom):Play()
	end

	local cc = LT:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		TS:Create(cc, TI_LIGHT, DREAM_LIGHTING_LAYER.ColorCorrection):Play()
	end

	-- DepthOfField — create if needed
	local dof = LT:FindFirstChildOfClass("DepthOfFieldEffect")
	if not dof then dof = Instance.new("DepthOfFieldEffect", LT) end
	TS:Create(dof, TI_LIGHT, DREAM_LIGHTING_LAYER.DepthOfField):Play()

	local atmo = LT:FindFirstChildOfClass("Atmosphere")
	if atmo then
		TS:Create(atmo, TI_LIGHT, DREAM_LIGHTING_LAYER.Atmosphere):Play()
	end

	workspace.Gravity = DREAM_LIGHTING_LAYER.Gravity
	TS:Create(LT, TI_LIGHT, { ClockTime = DREAM_LIGHTING_LAYER.ClockTime }):Play()
end

local function removeDreamLighting()
	-- DepthOfField fade out then destroy
	local dof = LT:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		local tw = TS:Create(dof, TI_FAST, { FarIntensity = 0, NearIntensity = 0 })
		tw.Completed:Connect(function() if dof and dof.Parent then dof:Destroy() end end)
		tw:Play()
	end
	-- Other lighting will be re-applied by RegionLighting for the new region
end

-- ============================================================
-- PUBLIC API
-- ============================================================
local DreamWorld = {}

-- Called by Regions when entering a DreamWorld-tagged region.
-- Base region lighting has already been applied by RegionLighting;
-- we layer dream visuals on top.
function DreamWorld.onEnterRegion(regionName, regionData)
	active = true
	applyDreamLighting()
	setGlobalWind(true)
	startAmbience()
	print("DreamWorld: entered region '" .. regionName .. "'")
end

-- Called by Regions when leaving a DreamWorld-tagged region.
function DreamWorld.onLeaveRegion(regionName)
	active = false
	removeDreamLighting()
	stopAmbience()
	setGlobalWind(false)
	workspace.Gravity = 196.2 -- restore default
	print("DreamWorld: left region '" .. regionName .. "'")
end

-- ── Hooks for WobblyScreen.lua ───────────────────────────────
-- WobblyScreen polls this to know if wobble should be active.
function DreamWorld.isActive() return active end

-- ── Hooks for CloudDropOnStep.lua ────────────────────────────
-- Returns current platform under the player (if any) and its base Y.
-- CloudDropOnStep polls this to find what to dip.
function DreamWorld.getPlatformUnder()
	if not active then return nil end

	-- Simple raycast downward from HRP
	local origin    = hrp.Position
	local result    = workspace:Raycast(
		origin,
		Vector3.new(0, -5, 0),
		rParams  -- default; cloud platforms should be CanCollide
	)
	
	if not result then return nil end

	---- Check if the hit part belongs to a platform
	--for _, platform in ipairs(platforms:GetChildren()) do
	--	if result.Instance:IsDescendantOf(platform) or result.Instance == platform then
	--print(resolveInstance(result.Instance, floatables))
			return resolveInstance(result.Instance, floatables)
		--end
	--end
end

return DreamWorld