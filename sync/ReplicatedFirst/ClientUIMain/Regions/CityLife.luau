-- ============================================================
-- CityLife (ModuleScript — child of Regions)
-- Orchestrates everything that makes a city region feel alive:
-- pedestrian walkers, (future) car traffic, ambient sounds, etc.
--
-- Sub-submodules are required here by path.
-- WalkerOrchestrator is a sibling script — require it by name.
--
-- REGION DATA FORMAT (set via Attribute or regionConfig table):
--   CityEnabled        = bool    — is this a city region?
--   WalkerModelName    = string  — name of NPCWalker Model in workspace.NPCWALKERS
--   CarSystemEnabled   = bool    — (future) enable car traffic
--   AmbientSoundId     = string  — optional looping ambient sound
-- ============================================================

-- Services
local RPS  = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")

-- WalkerOrchestrator lives as a sibling ModuleScript under the same parent
-- Require it lazily so the module loads even if WalkerOrchestrator isn't present
local WalkerOrchestrator = nil
local walkerOk, walkerErr = pcall(function()
	WalkerOrchestrator = require(script:WaitForChild("WalkerOrchestrator", 3))
end)
if not walkerOk then
	warn("CityLife: WalkerOrchestrator not found — walker features disabled. " .. tostring(walkerErr))
end

-- ── Internal state ───────────────────────────────────────────
local activeStreets = {}  -- [walkerModelName] = walkerModel  (currently loaded)
local ambientSounds = {}  -- [regionName] = Sound instance

-- ── Helpers ──────────────────────────────────────────────────

local function findWalkerModel(modelName)
	local container = workspace:FindFirstChild("NPCWALKERS")
	if not container then
		warn("CityLife: workspace.NPCWALKERS not found")
		return nil
	end
	return container:FindFirstChild(modelName)
end

local function loadAmbientSound(regionName, soundId)
	if not soundId then return end
	if ambientSounds[regionName] then return end -- already playing
	local sound = Instance.new("Sound")
	sound.SoundId   = soundId
	sound.Looped     = true
	sound.Volume     = 0.4
	sound.RollOffMaxDistance = 0 -- ambient, not positional
	sound.Name       = "CityAmbient_" .. regionName
	sound.Parent     = workspace
	sound:Play()
	ambientSounds[regionName] = sound
end

local function stopAmbientSound(regionName)
	local sound = ambientSounds[regionName]
	if sound then
		sound:Stop()
		sound:Destroy()
		ambientSounds[regionName] = nil
	end
end

-- ============================================================
-- MODULE
-- ============================================================
local CityLife = {}

-- Called when the player ENTERS a city region
-- regionName = string key
-- cityData   = { WalkerModelName=string, AmbientSoundId=string, ... }
function CityLife.onEnter(regionName, cityData)
	if not cityData then return end

	-- ── Load walker street ───────────────────────────────────
	local walkerModelName = cityData.WalkerModelName
	if walkerModelName and WalkerOrchestrator then
		local walkerModel = findWalkerModel(walkerModelName)
		if walkerModel then
			-- loadStreet flood-fills NPCs immediately (for city entry loading screens)
			WalkerOrchestrator.loadStreet(walkerModel)
			activeStreets[walkerModelName] = walkerModel
		else
			warn("CityLife: WalkerModel '" .. walkerModelName .. "' not found in NPCWALKERS")
		end
	end

	-- ── Multiple walker streets (array support) ──────────────
	-- cityData.WalkerModelNames = { "Street_A", "Street_B" }
	if cityData.WalkerModelNames and WalkerOrchestrator then
		for _, name in ipairs(cityData.WalkerModelNames) do
			local walkerModel = findWalkerModel(name)
			if walkerModel then
				WalkerOrchestrator.loadStreet(walkerModel)
				activeStreets[name] = walkerModel
			end
		end
	end

	-- ── Ambient sound ────────────────────────────────────────
	loadAmbientSound(regionName, cityData.AmbientSoundId)

	-- ── TODO: CarSystem.onEnter(regionName, cityData) ────────
	-- When you build the car system, add it as a sibling module
	-- and call it here exactly like WalkerOrchestrator above.
	-- local CarSystem = require(script.Parent.CarSystem)
	-- CarSystem.loadRoads(cityData.RoadModelName)
end

-- Called when the player LEAVES a city region
function CityLife.onLeave(regionName, cityData)
	if not cityData then return end

	-- ── Unload walker streets ────────────────────────────────
	local function unloadStreet(name)
		local walkerModel = activeStreets[name]
		if walkerModel and WalkerOrchestrator then
			WalkerOrchestrator.unloadStreet(walkerModel)
		end
		activeStreets[name] = nil
	end

	if cityData.WalkerModelName then
		unloadStreet(cityData.WalkerModelName)
	end
	if cityData.WalkerModelNames then
		for _, name in ipairs(cityData.WalkerModelNames) do
			unloadStreet(name)
		end
	end

	-- ── Ambient sound ────────────────────────────────────────
	stopAmbientSound(regionName)

	-- ── TODO: CarSystem.onLeave(regionName, cityData) ────────
end

-- Unload all active city systems (e.g. on teleport / game cleanup)
function CityLife.unloadAll()
	for name, walkerModel in pairs(activeStreets) do
		if WalkerOrchestrator then
			WalkerOrchestrator.unloadStreet(walkerModel)
		end
		activeStreets[name] = nil
	end
	for regionName in pairs(ambientSounds) do
		stopAmbientSound(regionName)
	end
end

return CityLife