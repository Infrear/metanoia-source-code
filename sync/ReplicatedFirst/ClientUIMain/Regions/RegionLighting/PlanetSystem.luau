-- ============================================================
-- PlanetSystem (ModuleScript — child of RegionLighting)
-- Handles planet proximity transitions (atmosphere, skybox, gravity,
-- visible planet replicas) ported from SpacePlanetGameLighting.
--
-- !! TURNOFFABLE !!
-- Set PlanetSystem.enabled = false before calling init() to
-- completely skip all planet logic. No Heartbeat runs, nothing loads.
-- This is the first thing checked everywhere — safe to leave off.
--
-- SETUP:
--   PlanetSystem.init(planetDefs, options)
--   planetDefs = {
--     PlanetName = {
--       Core    = Vector3,        -- world center of the planet
--       Gravity = number,
--       Lighting = lightings.Key, -- key into Lightings module
--     }, ...
--   }
--   options = {
--     CloudCoverMultiplier = number,   -- default 0.001/8.75
--     SpaceThreshold       = number,   -- default 1.15
--     SpaceLighting        = lightings.Space,
--   }
-- ============================================================

-- Services
local RS  = game:GetService("RunService")
local TS  = game:GetService("TweenService")
local LT  = game:GetService("Lighting")
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")

local TI_SLOW = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TI_FAST = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local PlanetSystem = {}

-- !! Set to false to disable ALL planet logic at zero cost !!
PlanetSystem.enabled = false

-- ── Internal state ───────────────────────────────────────────
local heartbeatConn    = nil
local planetDefs       = {}
local spaceLighting    = nil
local hrp              = nil
local lastZone         = nil   -- 0 = surface, 1 = upper-atmo, 2 = space
local CLOUD_MULT       = 0.001 / 8.75
local SPACE_THRESH     = 1.15
local DEFAULT_GRAVITY  = 196.2

-- ── Helpers ──────────────────────────────────────────────────

local function lerp(a, b, t) return a + (b - a) * t end

local function tw(target, info, props)
	TS:Create(target, info, props):Play()
end

local function updateAtmosphere(a)
	local atmo = LT:FindFirstChildOfClass("Atmosphere")
	if not atmo or not a then return end
	tw(atmo, TI_SLOW, {
		Color   = a.Color,
		Decay   = a.Decay,
		Haze    = a.Haze,
		Glare   = a.Glare,
		Density = a.Density,
	})
end

local function updateBloom(b)
	local bloom = LT:FindFirstChildOfClass("BloomEffect")
	if not bloom or not b then return end
	tw(bloom, TI_FAST, {
		Intensity = b.Intensity,
		Size      = b.Size,
		Threshold = b.Threshold,
	})
end

local function updateCloudsAndClock(cover, density, clockTime)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then tw(clouds, TI_SLOW, { Cover = cover, Density = density }) end
	tw(LT, TI_SLOW, { ClockTime = clockTime })
end

-- Show/hide planet model replicas in workspace.VisiblePlanets
local function showPlanet(name, def)
	local vis = workspace:FindFirstChild("VisiblePlanets")
	if not vis then return end
	if vis:FindFirstChild(name) then return end -- already shown

	local planetStorage = Storage:FindFirstChild("SpaceStuff")
		and Storage.SpaceStuff:FindFirstChild("Planets")
	if not planetStorage then return end

	local src = planetStorage:FindFirstChild(name)
	if not src then return end
	local replica = src:FindFirstChild(name)
	if not replica then return end

	replica:PivotTo(CFrame.new(def.Core))
	local clone = replica:Clone()
	clone.Name  = name
	clone.Parent = vis
end

local function clearVisiblePlanets()
	local vis = workspace:FindFirstChild("VisiblePlanets")
	if not vis then return end
	for _, v in ipairs(vis:GetChildren()) do v:Destroy() end
end

local function handlePlanetTransition(name, def, isInSpace)
	local planetStorage = Storage:FindFirstChild("SpaceStuff")
		and Storage.SpaceStuff:FindFirstChild("Planets")

	if isInSpace then
		-- Clone the Space skybox into Lighting if not already there
		if not LT:FindFirstChild("Space") then
			local spaceSrc = Storage:FindFirstChild("SpaceStuff")
				and Storage.SpaceStuff:FindFirstChild("Space")
				and Storage.SpaceStuff.Space:FindFirstChild("Space")
			if spaceSrc then spaceSrc:Clone().Parent = LT end
		end
		showPlanet(name, def)
	else
		clearVisiblePlanets()
		-- Apply planet surface atmosphere
		local lt = def.Lighting
		if lt then updateAtmosphere(lt.Atmosphere) end
		-- Remove space sky
		if LT:FindFirstChild("Space") then LT.Space:Destroy() end
		-- Swap skybox
		local existingSky = LT:FindFirstChildOfClass("Sky")
		if existingSky then existingSky:Destroy() end
		if planetStorage then
			local planetFolder = planetStorage:FindFirstChild(name)
			local sky = planetFolder and planetFolder:FindFirstChildOfClass("Sky")
			if sky then sky:Clone().Parent = LT end
		end
	end
end

-- ── Main per-frame adjustment ────────────────────────────────
local function adjustEffects()
	if not hrp then return end

	-- Sort planets by distance
	local distances = {}
	for name, def in pairs(planetDefs) do
		table.insert(distances, {
			name     = name,
			distance = (hrp.Position - def.Core).Magnitude,
			def      = def,
		})
	end
	if #distances == 0 then return end
	table.sort(distances, function(a, b) return a.distance < b.distance end)

	local nearest  = distances[1]
	local cloudCov = nearest.distance * CLOUD_MULT

	local zone = (cloudCov > SPACE_THRESH and 2)
		or (cloudCov > 0.85 and 1)
		or 0

	local changed = (zone ~= lastZone)
	lastZone = zone

	if cloudCov >= 0.15 and cloudCov < SPACE_THRESH then
		local pl    = nearest.def
		local lt    = pl.Lighting
		local adjCover   = lerp(lt and lt.Clouds and lt.Clouds.Cover   or 0.45, 1.1, cloudCov)
		local adjDensity = lerp(lt and lt.Clouds and lt.Clouds.Density or 0,   1.1, cloudCov)

		-- Get planet clocktime
		local planetStorage = Storage:FindFirstChild("SpaceStuff")
			and Storage.SpaceStuff:FindFirstChild("Planets")
		local ptFolder  = planetStorage and planetStorage:FindFirstChild(nearest.name)
		local clockSrc  = ptFolder and ptFolder:FindFirstChild("Clocktime")
		local clockTime = (cloudCov < 0.85 and clockSrc and clockSrc.Value) or 10

		updateCloudsAndClock(adjCover, adjDensity, clockTime)

		if cloudCov >= 0.85 then
			updateAtmosphere({
				Color   = lt and lt.Atmosphere and lt.Atmosphere.Color,
				Decay   = lt and lt.Atmosphere and lt.Atmosphere.Decay,
				Haze    = cloudCov * 10,
				Glare   = cloudCov * 10,
				Density = lt and lt.Atmosphere and lt.Atmosphere.Density,
			})
			if changed then updateBloom({ Intensity = 10, Size = 60, Threshold = 0.5 }) end
		else
			clearVisiblePlanets()
			handlePlanetTransition(nearest.name, nearest.def, false)
			if changed then
				workspace.Gravity = nearest.def.Gravity or DEFAULT_GRAVITY
				local bloom = lt and lt.PostEffects and lt.PostEffects.BloomEffect
				if bloom then updateBloom(bloom) end
			end
		end

	elseif cloudCov > SPACE_THRESH and changed then
		clearVisiblePlanets()
		for i = 1, math.min(6, #distances) do
			handlePlanetTransition(distances[i].name, distances[i].def, true)
		end
		workspace.Gravity = 0

		if spaceLighting then
			updateCloudsAndClock(
				spaceLighting.Clouds and spaceLighting.Clouds.Cover   or 0,
				spaceLighting.Clouds and spaceLighting.Clouds.Density or 0,
				spaceLighting.Lighting and spaceLighting.Lighting.ClockTime or 0
			)
			updateAtmosphere(spaceLighting.Atmosphere)
			local bfx = spaceLighting.PostEffects and spaceLighting.PostEffects.BloomEffect
			if bfx then updateBloom(bfx) end
		end
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function PlanetSystem.init(defs, options)
	-- If disabled, do absolutely nothing
	if not PlanetSystem.enabled then
		print("PlanetSystem: disabled — skipping init")
		return
	end

	local plr = PLRS.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")

	-- Refresh HRP on respawn
	plr.CharacterAdded:Connect(function(newChar)
		hrp = newChar:WaitForChild("HumanoidRootPart")
	end)

	planetDefs   = defs or {}
	spaceLighting = options and options.SpaceLighting
	CLOUD_MULT   = (options and options.CloudCoverMultiplier) or CLOUD_MULT
	SPACE_THRESH = (options and options.SpaceThreshold)       or SPACE_THRESH

	adjustEffects() -- run once immediately

	heartbeatConn = RS.Heartbeat:Connect(adjustEffects)
	print("PlanetSystem: running with " .. #(function()
		local t = {} for k in pairs(planetDefs) do t[#t+1] = k end return t
	end)() .. " planet(s)")
end

function PlanetSystem.stop()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	lastZone = nil
	print("PlanetSystem: stopped")
end

-- Hook called by RegionLighting when region changes (optional extra behavior)
function PlanetSystem.onRegionChanged(regionModel, regionData)
	if not PlanetSystem.enabled then return end
	-- Future: per-region planet overrides can go here
end

return PlanetSystem