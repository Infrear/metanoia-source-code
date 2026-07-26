-- ============================================================
-- WalkEffects (LocalScript — child of StarterCharacterScripts)
-- Modular foot particle system. Different surface types and
-- region tags drive different effects.
--
-- HOW TO ADD A NEW SURFACE TYPE:
--   1. Add an entry to SURFACE_EFFECTS keyed by Enum.Material name
--      OR by a custom region tag (see regionOverride below).
--   2. Effects are loaded from ClientStorage.Effects.Environment.[Key]
--
-- The DustWalk setup you had before is preserved exactly —
-- it's now just one entry in SURFACE_EFFECTS.
-- ============================================================

-- Services
local RS   = game:GetService("RunService")
local PLRS = game:GetService("Players")
local RPS  = game:GetService("ReplicatedStorage")

-- Dependencies
local char = script.Parent.Parent.Parent
local plr  = PLRS:GetPlayerFromCharacter(char)
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")
local lfoot = char:WaitForChild("LeftFoot")
local rfoot = char:WaitForChild("RightFoot")

local Storage = RPS:WaitForChild("ClientStorage")
local effects = Storage:WaitForChild("Effects")

-- ── Surface effect config ────────────────────────────────────
-- Each entry: { path = "Environment.Key.ef", minSpeed = number }
-- path is dot-separated from effects folder
-- minSpeed = speed threshold to enable (your original was 17.2)
local SURFACE_EFFECTS = {
	-- Default / earth surface (your original DustWalk)
	Default = {
		path     = "Environment.Earth.DustWalk.ef",
		minSpeed = 17.2,
	},
	-- Dream World cloud surface
	Cloud = {
		path     = "Environment.DreamWorld.CloudStep.ef",
		minSpeed = 5,   -- lower threshold — clouds react to slower movement too
	},
	-- Sand (example — add the asset and uncomment)
	-- Sand = {
	--   path     = "Environment.Sand.SandKick.ef",
	--   minSpeed = 15,
	-- },
}

-- ── Helpers ──────────────────────────────────────────────────

-- Resolve dot-separated path under effects folder
local function resolvePath(dotPath)
	local node = effects
	for segment in dotPath:gmatch("[^%.]+") do
		node = node and node:FindFirstChild(segment)
	end
	return node
end

-- Clone an effect onto a foot part; returns the clone or nil
local function attachEffect(foot, src)
	if not src then return nil end
	local clone = src:Clone()
	clone.Enabled = false
	clone.Parent  = foot
	return clone
end

-- ── Active effect state ──────────────────────────────────────
-- We keep one set of foot emitters per surface type active at once.
-- On surface change we swap them.

local leftEmitters  = {}   -- [effectKey] = ParticleEmitter on lfoot
local rightEmitters = {}   -- [effectKey] = ParticleEmitter on rfoot
local currentKey    = nil

-- Load all configured effects upfront (they stay disabled until needed)
for key, cfg in pairs(SURFACE_EFFECTS) do
	local src = resolvePath(cfg.path)
	if src then
		leftEmitters[key]  = attachEffect(lfoot, src)
		rightEmitters[key] = attachEffect(rfoot, src)
	else
		warn("WalkEffects: effect not found at path '" .. cfg.path .. "' for key '" .. key .. "'")
	end
end

local function setKey(key)
	if key == currentKey then return end

	-- Disable old
	if currentKey then
		if leftEmitters[currentKey]  then leftEmitters[currentKey].Enabled  = false end
		if rightEmitters[currentKey] then rightEmitters[currentKey].Enabled = false end
	end
	currentKey = key
end

local function setEnabled(enabled)
	if not currentKey then return end
	if leftEmitters[currentKey]  then leftEmitters[currentKey].Enabled  = enabled end
	if rightEmitters[currentKey] then rightEmitters[currentKey].Enabled = enabled end
end

-- ── Surface detection ────────────────────────────────────────
-- Poll FloorMaterial + optional region attribute to pick correct key

local function getSurfaceKey()
	-- Check if the player has a region tag that overrides material
	-- Set Attribute "SurfaceEffect" = "Cloud" on the character when in DreamWorld
	local regionOverride = char:GetAttribute("SurfaceEffect")
	if regionOverride and SURFACE_EFFECTS[regionOverride] then
		return regionOverride
	end

	local mat = hum.FloorMaterial
	if mat == Enum.Material.Air then return nil end

	-- Map Roblox materials to effect keys (extend as needed)
	if mat == Enum.Material.Sand or mat == Enum.Material.Sandstone then
		return SURFACE_EFFECTS.Sand and "Sand" or "Default"
	end
	-- Default fallback
	return "Default"
end

-- ── Running / jumping connections (mirrors original exactly) ─

hum.Running:Connect(function(speed)
	local key = getSurfaceKey()
	if not key then setEnabled(false) return end

	local cfg = SURFACE_EFFECTS[key]
	setKey(key)
	setEnabled(speed > (cfg.minSpeed or 17.2))
end)

hum.Jumping:Connect(function(isJumping)
	if isJumping then setEnabled(false) end
end)

-- Re-enable on land if still running
hum:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	if hum.FloorMaterial ~= Enum.Material.Air then
		local speed = hrp.AssemblyLinearVelocity.Magnitude
		local key   = getSurfaceKey()
		if key then
			local cfg = SURFACE_EFFECTS[key]
			setKey(key)
			setEnabled(speed > (cfg.minSpeed or 17.2))
		end
	end
end)