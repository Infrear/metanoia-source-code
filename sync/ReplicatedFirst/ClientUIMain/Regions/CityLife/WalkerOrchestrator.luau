-- ============================================================
-- WalkerOrchestrator (ModuleScript)
-- Manages all NPCWalker objects in the map.
-- One centralized RenderStepped loop handles ghost simulation,
-- screen-frustum culling, movement, animation, transparency,
-- idle stops, bidirectional walking, and multi-path support.
--
-- HOW TO SET UP AN NPCWalker IN STUDIO:
--   See the README block at the bottom of this file.
-- ============================================================

-- Services
local RPS  = game:GetService("ReplicatedStorage")
local RS   = game:GetService("RunService")
local PLRS = game:GetService("Players")
local TS   = game:GetService("TweenService")

-- Dependencies
local plr  = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local cam  = workspace.CurrentCamera

local Storage = RPS:WaitForChild("ClientStorage")
local Temp    = RPS:WaitForChild("ClientTemp")

-- Folder in workspace holding all NPCWalker model objects
local WALKER_CONTAINER = workspace:WaitForChild("NPCWALKERS")

-- Folder in ReplicatedStorage holding NPC model templates
-- Sub-folders = types (e.g. "Civilian"), each holds NPC models
local NPC_TEMPLATES = Storage:WaitForChild("NPCWalkerTemplates")

-- ============================================================
-- GLOBAL CONSTANTS
-- ============================================================
local WAYPOINT_REACH_DIST     = 2.5   -- studs to count a waypoint as "reached"
local TRANSPARENCY_TWEEN_TIME = 0.3
-- Hysteresis margins prevent edge-of-screen flickering:
--   GHOST_TO_REAL: how many px INSIDE the viewport a ghost must be before un-ghosting (generous)
--   REAL_TO_GHOST: how many px OUTSIDE the viewport a real NPC must be before ghosting (tight)
--   GHOST_FRAMES_NEEDED: consecutive on-screen frames required to exit ghost mode
local GHOST_TO_REAL_MARGIN   = 25    -- px inside viewport required to un-ghost
local REAL_TO_GHOST_MARGIN   = 50    -- px outside viewport before ghosting kicks in
local GHOST_TRACKING_ENABLED = true

-- ============================================================
-- MODULE
-- ============================================================
local walkerOrchestrator = {}

-- ============================================================
-- SHARED STATE
-- ============================================================
local activeWalkers = {}  -- [walkerModel] = true
local npcPool       = {}  -- [walkerModel] = { available={}, inUse={} }
local cachedCfg     = {}  -- [walkerModel] = cfg table (read once from attributes)
local cachedPaths   = {}  -- [walkerModel] = { {Part,...}, {Part,...} } (all Waypoints_ folders)
local cachedTemplates = {} -- [walkerModel] = { Model, ... }
local spawnTimers   = {}  -- [walkerModel] = elapsed seconds since last spawn
local activeNPCs    = {}  -- flat array of NPC state tables (see spawnNPC)
local TES = {}

-- ============================================================
-- ATTRIBUTE DEFAULTS
-- Builders override these via the Attribute panel on the NPCWalker model
-- ============================================================
local ATTR_DEFAULTS = {
	WalkSpeed             = 8,      -- studs / sec
	MaxActive             = 6,      -- max NPCs alive on this path at once
	SpawnInterval         = 3,      -- seconds between trickle-spawns
	MaxSpawnDistance      = 500,    -- studs; beyond this, don't spawn at all
	MaxExistDistance      = 35,    -- studs; beyond this, NPC ghosts (no PivotTo)
	TransparencyNearDist  = 6,      -- studs; start fading NPC out below this
	TransparencyFarDist   = 12,     -- studs; fully visible above this
	UseRandomIdle         = false,  -- enable random periodic stops
	RandomIdleChance      = 0.003,  -- per-frame probability of stopping while walking
	RandomIdleMinTime     = 2,      -- minimum idle duration in seconds
	RandomIdleMaxTime     = 5,      -- maximum idle duration in seconds
	UseStopSpots          = false,  -- enable builder-placed stop-spot Parts
	StopSpotDuration      = 3,      -- seconds to pause at each stop spot
	TypeFilter            = "All",  -- NPC type sub-folder(s), comma-separated or "All"
	SpawnSpread           = 15,     -- random XZ offset at spawn (studs)
	WalkSide              = "Right",-- "Right" or "Left" � which side of the path
	ForceSide             = false,  -- if true, ignore path geometry and always apply offset
	WalkSideOffset        = 10,     -- studs offset from waypoint centerline
	WalkBothDirections    = true,  -- if true, half NPCs walk forward, half walk reversed
}

-- ============================================================
-- HELPERS
-- ============================================================

local function attr(model, name, default)
	local v = model:GetAttribute(name)
	return (v ~= nil) and v or default
end

local function getWalkerCfg(walkerModel)
	if cachedCfg[walkerModel] then return cachedCfg[walkerModel] end
	local cfg = {}
	for k, default in pairs(ATTR_DEFAULTS) do
		cfg[k] = attr(walkerModel, k, default)
	end
	cfg.DefaultSpawn = walkerModel:WaitForChild("SpawnZone", 10)
	cfg.DefaultDespawn = walkerModel:WaitForChild("DespawnZone", 10)
	cachedCfg[walkerModel] = cfg
	return cfg
end

-- Returns all available waypoint path arrays for a walker.
-- Looks for Folder children whose name starts with "Waypoints".
-- Each path is a numerically sorted array of Parts.
-- Falls back to a single "Waypoints" folder if no prefixed folders exist.
local function getPaths(walkerModel)
	if cachedPaths[walkerModel] then return cachedPaths[walkerModel] end

	local paths = {}
	for _, child in ipairs(walkerModel:GetChildren()) do
		if child:IsA("Folder") and child.Name:sub(1, 9) == "Waypoints" then
			local parts = child:GetChildren()
			table.sort(parts, function(a, b)
				local na, nb = tonumber(a.Name), tonumber(b.Name)
				if na and nb then return na < nb end
				return a.Name < b.Name
			end)
			local tab = {
				SpawnZone = child:FindFirstChild("SpawnZone") or cachedCfg[walkerModel].DefaultSpawn,
				DespawnZone = child:FindFirstChild("DespawnZone") or cachedCfg[walkerModel].DefaultDespawn,
				Parts = parts,
			}
			if #parts > 0 then
				table.insert(paths, tab)
			end
		end
	end

	if #paths == 0 then
		warn("WalkerOrchestrator: '" .. walkerModel.Name .. "' has no Waypoints folder(s)")
	end

	cachedPaths[walkerModel] = paths
	return paths
end

-- Pick a random path array from the walker's available paths
local function pickPath(walkerModel)
	local paths = getPaths(walkerModel)
	if #paths == 0 then return nil end
	return paths[math.random(1, #paths)]
end

-- Get all NPC templates for a TypeFilter string
local function getTemplates(walkerModel)
	if cachedTemplates[walkerModel] then return cachedTemplates[walkerModel] end

	local cfg = getWalkerCfg(walkerModel)
	local typeFilter = cfg.TypeFilter
	local templates = {}

	if typeFilter == "All" then
		for _, folder in ipairs(NPC_TEMPLATES:GetChildren()) do
			for _, model in ipairs(folder:GetChildren()) do
				table.insert(templates, model)
			end
		end
	else
		for _, typeName in ipairs(typeFilter:split(",")) do
			typeName = typeName:match("^%s*(.-)%s*$") -- trim whitespace
			local folder = NPC_TEMPLATES:FindFirstChild(typeName)
			if folder then
				for _, model in ipairs(folder:GetChildren()) do
					table.insert(templates, model)
				end
			end
		end
	end

	cachedTemplates[walkerModel] = templates
	return templates
end

local function pickTemplate(templates)
	if #templates == 0 then return nil end
	return templates[math.random(1, #templates)]
end

-- -- Transparency helpers -------------------------------------

local function setNPCTransparency(npcModel, t)
	for _, part in ipairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Main" then
			if TES[part] and TES[part].PlaybackState == Enum.PlaybackState.Playing then
				TES[part]:Cancel()
			end
			part.Transparency = t
			for i, dec in pairs(part:GetChildren()) do
				if dec:IsA("Decal") then
					if TES[dec] and TES[dec].PlaybackState == Enum.PlaybackState.Playing then
						TES[dec]:Cancel()
					end
					dec.Transparency = t
				end
			end
		end
	end
end

local function tweenNPCTransparency(npcModel, targetTrans, duration)
	duration = duration or TRANSPARENCY_TWEEN_TIME
	for _, part in ipairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Main" then
			if TES[part] and TES[part].PlaybackState == Enum.PlaybackState.Playing then
				TES[part]:Cancel()
			end

			TES[part] = TS:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = targetTrans }
			)
			TES[part]:Play()
			for i, dec in pairs(part:GetChildren()) do
				if dec:IsA("Decal") then
					if TES[dec] and TES[dec].PlaybackState == Enum.PlaybackState.Playing then
						TES[dec]:Cancel()
					end
					TES[dec] = TS:Create(
						dec,
						TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = targetTrans }
					)
					TES[dec]:Play()
				end
			end
		end
	end
end

-- -- Screen frustum helpers ------------------------------------
-- Two separate checks with different margins create hysteresis:
-- an NPC must be clearly ON-screen to un-ghost, but must be clearly
-- OFF-screen to start ghosting. This prevents edge-flicker.

-- Returns true if worldPos is well inside the viewport (used for ghost→real).
local function isWellOnScreen(worldPos)
	local screenPos, onScreen = cam:WorldToScreenPoint(worldPos)

	-- If Z is negative, the object is behind the camera (flips on screen)
	if not onScreen or screenPos.Z < 0 then 
		return false 
	end
	local vp = cam.ViewportSize

	return screenPos.X >= GHOST_TO_REAL_MARGIN and 
		screenPos.X <= vp.X - GHOST_TO_REAL_MARGIN and 
		screenPos.Y >= GHOST_TO_REAL_MARGIN and 
		screenPos.Y <= vp.Y - GHOST_TO_REAL_MARGIN
end

local function isClearlyOffScreen(worldPos)
	local screenPos, onScreen = cam:WorldToScreenPoint(worldPos)

	-- If it's officially off-screen OR behind the camera, it's clearly off screen
	if not onScreen or screenPos.Z < 0 then 
		return true 
	end

	local vp = cam.ViewportSize

	return screenPos.X < -REAL_TO_GHOST_MARGIN or 
		screenPos.X > vp.X + REAL_TO_GHOST_MARGIN or 
		screenPos.Y < -REAL_TO_GHOST_MARGIN or 
		screenPos.Y > vp.Y + REAL_TO_GHOST_MARGIN
end

-- ============================================================
-- ANIMATION CONTROLLER DRIVER
-- AnimationController NPCs have no Humanoid so we manage
-- all tracks manually. Expects model.Animations folder with
-- named Animation objects (Walk, Idle, etc.)
-- ============================================================

local function loadAnimations(npcModel)
	local controller = npcModel:FindFirstChildOfClass("AnimationController")
	if not controller then
		warn("WalkerOrchestrator: '" .. npcModel.Name .. "' has no AnimationController")
		return nil
	end
	local animator = controller:FindFirstChildOfClass("Animator")
		or Instance.new("Animator", controller)

	local animFolder = npcModel:FindFirstChild("Animations")
	if not animFolder then
		warn("WalkerOrchestrator: '" .. npcModel.Name .. "' has no Animations folder")
		return nil
	end

	local tracks = {}
	for _, animObj in ipairs(animFolder:GetChildren()) do
		if animObj:IsA("Animation") then
			local track = animator:LoadAnimation(animObj)
			track.Priority = Enum.AnimationPriority.Core
			tracks[animObj.Name] = track
		end
	end
	return tracks
end

local function playAnim(animTracks, trackName)
	if not animTracks then return end
	local target = animTracks[trackName]
	if not target or target.IsPlaying then return end
	for name, track in pairs(animTracks) do
		if name ~= trackName and track.IsPlaying then
			track:Stop(0.2)
		end
	end
	target:Play(0.2)
end

local function stopAllAnims(npcModel)
	local controller = npcModel:FindFirstChildOfClass("AnimationController")
	local animator   = controller and controller:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

-- ============================================================
-- NPC POOL
-- ============================================================

local function initPool(walkerModel)
	if npcPool[walkerModel] then return end
	npcPool[walkerModel] = { available = {}, inUse = {} }

	-- Pre-generate MaxActive clones upfront to avoid spawn spikes
	local cfg       = getWalkerCfg(walkerModel)
	local templates = getTemplates(walkerModel)
	local npcFolder = walkerModel:FindFirstChild("NPCs")
		or Instance.new("Folder", walkerModel)
	npcFolder.Name  = "NPCs"

	for _ = 1, cfg.MaxActive do
		local template = pickTemplate(templates)
		if not template then break end
		local clone = template:Clone()
		setNPCTransparency(clone, 1)
		clone.Parent = npcFolder
		table.insert(npcPool[walkerModel].available, clone)
	end
end

local function acquireNPC(walkerModel)
	local pool = npcPool[walkerModel]
	local npcModel

	if #pool.available > 0 then
		npcModel = table.remove(pool.available)
	else
		-- Pool exhausted � clone one more as a safety fallback
		local templates = getTemplates(walkerModel)
		local template  = pickTemplate(templates)
		if not template then return nil end
		npcModel = template:Clone()
		local npcFolder = walkerModel:FindFirstChild("NPCs")
		npcModel.Parent = npcFolder or walkerModel
	end

	setNPCTransparency(npcModel, 1)
	table.insert(pool.inUse, npcModel)
	return npcModel
end

local function releaseNPC(walkerModel, npcModel)
	local pool = npcPool[walkerModel]
	if not pool then return end
	for i, v in ipairs(pool.inUse) do
		if v == npcModel then
			table.remove(pool.inUse, i)
			break
		end
	end
	setNPCTransparency(npcModel, 1)
	stopAllAnims(npcModel)
	table.insert(pool.available, npcModel)
end

local function destroyPool(walkerModel)
	local pool = npcPool[walkerModel]
	if not pool then return end
	for _, npc in ipairs(pool.inUse)     do npc:Destroy() end
	for _, npc in ipairs(pool.available) do npc:Destroy() end
	npcPool[walkerModel] = nil
end

-- ============================================================
-- NPC STATE SCHEMA (comment reference)
-- ============================================================
--[[
  {
    npcModel      : Model
    walkerModel   : Model
    waypoints     : { Part }     -- chosen path, sorted
    waypointIndex : number       -- current target index
    reversed      : bool         -- true = walking from end ? start
    animTracks    : table
    cfg           : table
    spreadXZ      : Vector2      -- per-NPC random offset baked at spawn
    isIdle        : bool
    idleTimer     : number
    stopSpots     : { Part }
    nextStopIndex : number
    currentTrans  : number       -- last applied transparency (debounce)
    isGhost       : bool         -- true = not on screen, running ghost sim
    ghostCF       : CFrame       -- simulated CFrame updated every frame
  }
--]]

-- ============================================================
-- GHOST SIMULATION
-- When an NPC is off-screen OR beyond MaxExistDistance we don't
-- call PivotTo (expensive). Instead we advance a ghostCF purely
-- in math � no Roblox physics involvement.
-- When the NPC re-enters the visible zone we apply ghostCF once
-- and fade back in.
-- ============================================================

-- Advance the ghost CFrame by one dt step along the path.
-- Mirrors the real movement logic exactly, including reversed direction and side offset.
local function stepGhostCF(s, dt)
	local waypoints = s.waypoints
	local cfg       = s.cfg

	-- Check path completion the same way real movement does (direction-aware)
	local finished = s.reversed
		and (s.waypointIndex < 1)
		or  (s.waypointIndex > #waypoints)

	if finished then
		s.ghostFinished = true
		return s.ghostCF
	end

	local wp    = waypoints[s.waypointIndex]
	local wpPos = (CFrame.new(wp.Position) * CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position

	-- Mirror real movement's prevIdx logic: look back at where we came FROM
	-- so path direction and side offset match the real NPC exactly.
	local prevIdx = s.reversed
		and math.min(s.waypointIndex + 1, #waypoints)
		or  math.max(s.waypointIndex - 1, 1)

	local prevWPPos = (CFrame.new(waypoints[prevIdx].Position)
		* CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position

	local pathDir = (wpPos - prevWPPos)

	-- At the very start prevIdx == waypointIndex, so look ahead instead
	if pathDir.Magnitude < 0.01 then
		local nextIdx = s.reversed
			and math.max(s.waypointIndex - 1, 1)
			or  math.min(s.waypointIndex + 1, #waypoints)
		local nextWPPos = (CFrame.new(waypoints[nextIdx].Position)
			* CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position
		pathDir = (nextWPPos - wpPos)
	end

	if pathDir.Magnitude > 0.01 then
		pathDir = pathDir.Unit
	else
		pathDir = Vector3.new(0, 0, -1)
	end

	local sideMultiplier = (cfg.WalkSide == "Left") and -1 or 1
	--if s.reversed then sideMultiplier = -sideMultiplier end <-- holy shit you fried me :sob

	local rightVec  = pathDir:Cross(Vector3.new(0, 1, 0)).Unit
	local offsetPos = wpPos + rightVec * (cfg.WalkSideOffset * sideMultiplier)

	-- Keep ghost at the same Y as its last known position
	local currentPos = s.ghostCF.Position
	offsetPos = Vector3.new(offsetPos.X, currentPos.Y, offsetPos.Z)

	local toWP   = offsetPos - currentPos
	local dist2D = Vector2.new(toWP.X, toWP.Z).Magnitude

	if dist2D < WAYPOINT_REACH_DIST then
		-- Advance in the correct direction (reversed counts DOWN)
		s.waypointIndex += s.reversed and -1 or 1
	else
		local moveDir = Vector3.new(toWP.X, 0, toWP.Z).Unit
		local newPos  = currentPos + moveDir * cfg.WalkSpeed * dt
		s.ghostCF     = CFrame.lookAt(newPos, newPos + moveDir)
	end

	return s.ghostCF
end

-- ============================================================
-- SPAWNING
-- ============================================================

local function spawnNPC(walkerModel, walkerCfg, reversed)
	local pathTab = pickPath(walkerModel)
	
	local spawnZone = pathTab[reversed and "DespawnZone" or "SpawnZone"]
	if not spawnZone then
		warn("WalkerOrchestrator: '" .. walkerModel.Name .. "' missing SpawnZone/DespawnZone")
		return
	end

	local npcModel = acquireNPC(walkerModel)
	if not npcModel then return end

	local root = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Main")
	if not root then releaseNPC(walkerModel, npcModel) return end

	local spread   = walkerCfg.SpawnSpread
	local spreadX  = math.random(-spread, spread)
	local spreadZ  = math.random(-spread, spread)
	local spawnCF  = spawnZone.CFrame * CFrame.new(spreadX, 0, spreadZ)
	--npcModel:PivotTo(spawnCF)

	-- Pick a random path from the available Waypoints_ folders
	local waypoints = pathTab.Parts
	if not waypoints or #waypoints == 0 then
		releaseNPC(walkerModel, npcModel)
		return
	end

	-- Reversed walkers start at the last waypoint index and count down
	local startIndex = reversed and #waypoints or 1

	-- Collect stop spots
	local stopSpots = {}
	if walkerCfg.UseStopSpots then
		local spotsFolder = walkerModel:FindFirstChild("StopSpots")
		if spotsFolder then
			stopSpots = spotsFolder:GetChildren()
			table.sort(stopSpots, function(a, b)
				local na, nb = tonumber(a.Name), tonumber(b.Name)
				if na and nb then return na < nb end
				return a.Name < b.Name
			end)
		end
	end

	local state = {
		npcModel      = npcModel,
		walkerModel   = walkerModel,
		waypoints     = waypoints,
		waypointIndex = startIndex,
		reversed      = reversed,
		cfg           = walkerCfg,
		spreadXZ      = Vector2.new(spreadX, spreadZ),
		isIdle        = false,
		idleTimer     = 0,
		stopSpots     = stopSpots,
		nextStopIndex = 1,
		currentTrans  = 0,
		isGhost       = false,
		ghostCF       = spawnCF,
		ghostFinished = false,
		spawned = false,
		spawnCF = spawnCF,
		ghostSpawned = false,
	}

	if GHOST_TRACKING_ENABLED then
		state.ghostTracker = Instance.new("Part", workspace.PARTICLES)
		state.ghostTracker.Size = Vector3.new(1,1,1)
		state.ghostTracker.Anchored = true
		state.ghostTracker.Transparency = 1
		state.ghostTracker.CanCollide = false
		state.ghostTracker.Name = "GhostTracker_" .. walkerModel.Name
		state.ghostTracker.Color = Color3.new(1, 0, 0)
		state.ghostTracker.Material = Enum.Material.Neon
		state.ghostTracker.Shape = Enum.PartType.Ball
	end
	table.insert(activeNPCs, state)
end

-- ============================================================
-- MAIN UPDATE LOOP
-- ============================================================

local function updateNPCs(dt)
	local hrpPos   = hrp.Position
	local hrpPos2D = Vector2.new(hrpPos.X, hrpPos.Z)

	-- -- Per-walker: spawning ---------------------------------
	for walkerModel in pairs(activeWalkers) do
		local cfg  = getWalkerCfg(walkerModel)
		local dist = (walkerModel:GetPivot().Position - hrpPos).Magnitude

		-- Count active NPCs for this walker
		local count = 0
		for _, s in ipairs(activeNPCs) do
			if s.walkerModel == walkerModel then count += 1 end
		end

		if dist <= cfg.MaxSpawnDistance then
			spawnTimers[walkerModel] = (spawnTimers[walkerModel] or 0) + dt
			if spawnTimers[walkerModel] >= cfg.SpawnInterval and count < cfg.MaxActive then
				spawnTimers[walkerModel] = 0

				-- Bidirectional: alternate which direction new spawns get
				-- We track how many reversed vs forward are active to keep it balanced
				if cfg.WalkBothDirections then
					local fwdCount, revCount = 0, 0
					for _, s in ipairs(activeNPCs) do
						if s.walkerModel == walkerModel then
							if s.reversed then revCount += 1 else fwdCount += 1 end
						end
					end
					spawnNPC(walkerModel, cfg, revCount < fwdCount)
				else
					spawnNPC(walkerModel, cfg, false)
				end
			end
		else
			-- Out of MaxSpawnDistance � ghost everything, no full release
			-- They'll be cleaned up naturally as they finish their paths
			for _, s in ipairs(activeNPCs) do
				if s.walkerModel == walkerModel and not s.isGhost then
					s.isGhost = true
					setNPCTransparency(s.npcModel, 1)
				end
			end
			spawnTimers[walkerModel] = 0
		end
	end
	
	-- -- Per-NPC: ghost sim, movement, transparency -----------
	for i = #activeNPCs, 1, -1 do
		local s   = activeNPCs[i]
		local npc = s.npcModel
		if not npc or not npc.Parent then
			table.remove(activeNPCs, i)
			continue
		end

		local cfg  = s.cfg
		local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Main")
		if not root then continue end

		local npcPos      = s.isGhost and s.ghostCF.Position or root.Position
		local distToPlayer = (npcPos - hrpPos).Magnitude
		local npcPos2D    = Vector2.new(npcPos.X, npcPos.Z)

		-- -- Decide: ghost or real ----------------------------
		-- Hysteresis: ghosts need isWellOnScreen to un-ghost (strict, inside viewport).
		-- Real NPCs need isClearlyOffScreen to ghost (lenient, well outside viewport).
		-- Parentheses are explicit to avoid Lua and/or precedence surprises.
		local beyondExist = (distToPlayer > cfg.MaxExistDistance)

		local shouldGhost
		if s.isGhost then
			-- Currently a ghost: only un-ghost if well inside the screen AND close enough
			shouldGhost = beyondExist or (not isWellOnScreen(npcPos))
		else
			-- Currently real: only ghost if clearly off-screen OR too far away
			shouldGhost = beyondExist or isClearlyOffScreen(npcPos)
		end
		
		if shouldGhost and not s.isGhost then
			-- Transition INTO ghost � hide the model, keep simulating position
			s.isGhost  = true
			s.ghostCF  = root.CFrame
			if GHOST_TRACKING_ENABLED then
				s.ghostTracker.CFrame = s.ghostCF
				s.ghostTracker.Transparency = 0
			end
			setNPCTransparency(npc, 1)
			-- Stop animating while ghosted to save cost
			stopAllAnims(npc)
			if not s.spawned then
				s.ghostSpawned = true
				s.ghostCF = s.spawnCF -- make sure ghosts that dont get rendered at spawn start at the right spot
			end

		elseif not shouldGhost and s.isGhost then
			--print("outtaGhost")
			-- Transition OUT of ghost � snap model to where the ghost simulated
			s.isGhost = false
			--print("oldpos:", npc:GetPivot().Position, "newpos:", s.ghostCF.Position)
			--print("xdiff:", npc:GetPivot().Position.X - s.ghostCF.Position.X, "zdiff:", npc:GetPivot().Position.Z - s.ghostCF.Position.Z)
			if GHOST_TRACKING_ENABLED then
				s.ghostTracker.Transparency = 1
			end
			
			npc:PivotTo(s.ghostCF)
			tweenNPCTransparency(npc, 0, 0.4)
			playAnim(s.animTracks, s.isIdle and "Idle" or "Walk")
		end

		-- -- Ghost path simulation (runs even off-screen) -----
		if s.isGhost then
			stepGhostCF(s, dt)
			if GHOST_TRACKING_ENABLED then
				s.ghostTracker.CFrame = s.ghostCF
			end

			-- Ghost finished path � release to pool
			if s.ghostFinished then
				releaseNPC(s.walkerModel, npc)
				table.remove(activeNPCs, i)
				if GHOST_TRACKING_ENABLED then
					s.ghostTracker:Destroy()
				end
			end
			continue -- skip all real-world updates below
		end
		

		-- -- Everything below only runs for on-screen NPCs ----

		-- Ghost sim still advances the CFrame even for real NPCs
		-- so the two stay in sync (ghost is used when we switch back)
		s.ghostCF = root.CFrame
		--s.ghostTracker.CFrame = s.ghostCF

		-- -- Proximity transparency ---------------------------
		local targetTrans
		local distToPlayer2D = (npcPos2D - hrpPos2D).Magnitude
		if distToPlayer2D <= cfg.TransparencyNearDist then
			targetTrans = 1
		elseif distToPlayer2D >= cfg.TransparencyFarDist then
			targetTrans = 0
		else
			local t = (distToPlayer2D - cfg.TransparencyNearDist)
				/ (cfg.TransparencyFarDist - cfg.TransparencyNearDist)
			targetTrans = 1 - t
		end
		if math.abs(targetTrans - s.currentTrans) > 0.05 then
			tweenNPCTransparency(npc, targetTrans)
			s.currentTrans = targetTrans
		end

		-- -- Idle tick ----------------------------------------
		if s.isIdle then
			s.idleTimer -= dt
			if s.idleTimer <= 0 then
				s.isIdle = false
				playAnim(s.animTracks, "Walk")
			else
				continue
			end
		end

		-- -- Random idle --------------------------------------
		if cfg.UseRandomIdle and math.random() < cfg.RandomIdleChance then
			s.isIdle    = true
			s.idleTimer = cfg.RandomIdleMinTime
				+ math.random() * (cfg.RandomIdleMaxTime - cfg.RandomIdleMinTime)
			playAnim(s.animTracks, "Idle")
			continue
		end

		-- -- Movement -----------------------------------------
		local waypoints = s.waypoints

		-- Check path completion (direction-aware)
		local finished = s.reversed
			and (s.waypointIndex < 1)
			or  (s.waypointIndex > #waypoints)

		if finished then
			tweenNPCTransparency(npc, 1, 0.4)
			task.delay(0.45, function()
				releaseNPC(s.walkerModel, npc)
			end)
			table.remove(activeNPCs, i)
			continue
		end

		local wp    = waypoints[s.waypointIndex]
		local wpPos = (CFrame.new(wp.Position)
			* CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position

		-- Calculate direction based on the segment we are CURRENTLY traversing
		-- (Looking back at the previous waypoint, rather than ahead at the next)
		local prevIdx = s.reversed
			and math.min(s.waypointIndex + 1, #waypoints)
			or  math.max(s.waypointIndex - 1, 1)

		local prevWP = waypoints[prevIdx]
		local prevWPPos = (CFrame.new(prevWP.Position)
			* CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position

		local pathDir = (wpPos - prevWPPos)

		-- If we are at the very start of the path and prev == current, look ahead instead
		if pathDir.Magnitude < 0.01 then
			local nextIdx = s.reversed
				and math.max(s.waypointIndex - 1, 1)
				or  math.min(s.waypointIndex + 1, #waypoints)

			local nextWPPos = (CFrame.new(waypoints[nextIdx].Position)
				* CFrame.new(s.spreadXZ.X, 0, s.spreadXZ.Y)).Position
			pathDir = (nextWPPos - wpPos)
		end

		-- Final fallback: Use the NPC's current LookVector to prevent snapping to global North
		if pathDir.Magnitude > 0.01 then 
			pathDir = pathDir.Unit
		else 
			pathDir = root.CFrame.LookVector 
		end

		local sideMultiplier = (cfg.WalkSide == "Left") and -1 or 1
		--if s.reversed then sideMultiplier = -sideMultiplier end

		local rightVec  = pathDir:Cross(Vector3.new(0, 1, 0)).Unit
		local offsetPos = wpPos + rightVec * (cfg.WalkSideOffset * sideMultiplier)
		offsetPos = Vector3.new(offsetPos.X, npcPos.Y, offsetPos.Z)

		-- -- Stop spots ---------------------------------------
		if cfg.UseStopSpots and #s.stopSpots > 0 then
			local spot = s.stopSpots[s.nextStopIndex]
			if spot then
				local spotDist = Vector3.new(npcPos.X, spot.Position.Y, npcPos.Z)
				- spot.Position
				if spotDist.Magnitude < WAYPOINT_REACH_DIST then
					s.isIdle        = true
					s.idleTimer     = cfg.StopSpotDuration
					s.nextStopIndex = (s.nextStopIndex % #s.stopSpots) + 1
					playAnim(s.animTracks, "Idle")
					root.CFrame = CFrame.lookAt(npcPos, npcPos + spot.CFrame.LookVector)
					continue
				end
			end
		end

		-- -- Step toward waypoint -----------------------------
		local toWP   = offsetPos - npcPos
		local dist2D = Vector2.new(toWP.X, toWP.Z).Magnitude

		if dist2D < WAYPOINT_REACH_DIST then
			-- Advance (or retreat for reversed)
			s.waypointIndex += s.reversed and -1 or 1
		else
			-- Only PivotTo when on-screen � this is the expensive call
			if not s.spawned then
				s.spawned = true
				if not s.ghostSpawned then
					npc:PivotTo(s.spawnCF)
				end

				s.animTracks = loadAnimations(npc)
				playAnim(s.animTracks, "Walk")
				tweenNPCTransparency(npc, 0, 0.5)
			else
				local moveDir = Vector3.new(toWP.X, 0, toWP.Z).Unit
				local newPos  = npcPos + moveDir * cfg.WalkSpeed * dt

				-- 1. Where the NPC SHOULD face
				local targetCF = CFrame.lookAt(newPos, newPos + moveDir)

				-- 2. Where the NPC CURRENTLY faces (moved to the new walking position)
				-- Using .Rotation strips the positional data from the root's CFrame
				local currentCF = CFrame.new(newPos) * root.CFrame.Rotation

				-- 3. Calculate how much to turn this frame based on delta time
				-- You can add TurnSpeed to your walker config, or default it to something like 10
				local turnSpeed = cfg.TurnSpeed or 12 
				local lerpAlpha = math.min(turnSpeed * dt, 1)

				-- 4. Smoothly interpolate between the current rotation and target rotation
				local finalCF = currentCF:Lerp(targetCF, lerpAlpha)

				-- Only PivotTo when on-screen � this is the expensive call
				npc:PivotTo(finalCF)
			end
		end
	end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- loadStreet: immediately flood-fill a walker to MaxActive NPCs.
-- Call this when a city-entry loading screen fires so NPCs
-- appear all at once instead of trickling in with lag spikes.
function walkerOrchestrator.loadStreet(walkerModel)
	if not walkerModel or not walkerModel:GetAttribute("IsNPCWalker") then return end

	activeWalkers[walkerModel] = true
	initPool(walkerModel)
	
	local cfg   = getWalkerCfg(walkerModel)
	local count = 0
	for _, s in ipairs(activeNPCs) do
		if s.walkerModel == walkerModel then count += 1 end
	end

	local toSpawn = cfg.MaxActive - count
	for k = 1, toSpawn do
		local reversed = cfg.WalkBothDirections and (k % 2 == 0)
		spawnNPC(walkerModel, cfg, reversed)
	end
	
	spawnTimers[walkerModel] = 0
end

-- unloadStreet: release all NPCs on a walker back to the pool immediately.
-- Call this when the player leaves an area so the street cleans up fast.
function walkerOrchestrator.unloadStreet(walkerModel)
	if not walkerModel then return end
	for i = #activeNPCs, 1, -1 do
		local s = activeNPCs[i]
		if s.walkerModel == walkerModel then
			setNPCTransparency(s.npcModel, 1)
			releaseNPC(walkerModel, s.npcModel)
			table.remove(activeNPCs, i)
		end
	end
	spawnTimers[walkerModel] = 0
end

-- -- Init -----------------------------------------------------
function walkerOrchestrator.init(autoSetup)
	if autoSetup then
		for _, walkerModel in ipairs(WALKER_CONTAINER:GetChildren()) do
			if walkerModel:IsA("Model") and walkerModel:GetAttribute("IsNPCWalker") then
				activeWalkers[walkerModel] = true
				initPool(walkerModel)
				spawnTimers[walkerModel] = 0
			end
		end

		WALKER_CONTAINER.ChildAdded:Connect(function(child)
			if child:IsA("Model") and child:GetAttribute("IsNPCWalker") then
				activeWalkers[child] = true
				initPool(child)
				spawnTimers[child] = 0
			end
		end)

		WALKER_CONTAINER.ChildRemoved:Connect(function(child)
			if activeWalkers[child] then
				activeWalkers[child]  = nil
				cachedCfg[child]      = nil
				cachedPaths[child]    = nil
				cachedTemplates[child]= nil
				spawnTimers[child]    = nil
				destroyPool(child)
			end
		end)
	end
	
	plr.CharacterAdded:Connect(function(newChar)
		char = newChar
		hrp  = newChar:WaitForChild("HumanoidRootPart")
	end)

	RS.RenderStepped:Connect(updateNPCs)

	print("WalkerOrchestrator: initialized with "
		.. #WALKER_CONTAINER:GetChildren() .. " walker(s)")
end


return walkerOrchestrator

--[[
================================================================
NPCWalker STUDIO SETUP GUIDE
================================================================

MODEL STRUCTURE  (Model named anything, with IsNPCWalker = true):

  NPCWalker_MainStreet  (Model)
  |
  |-- [Attributes]
  |    IsNPCWalker          = true          REQUIRED
  |    WalkSpeed            = 8
  |    MaxActive            = 6
  |    SpawnInterval        = 3
  |    MaxSpawnDistance     = 500
  |    MaxExistDistance     = 200
  |    TransparencyNearDist = 6
  |    TransparencyFarDist  = 12
  |    UseRandomIdle        = false
  |    RandomIdleChance     = 0.003
  |    RandomIdleMinTime    = 2
  |    RandomIdleMaxTime    = 5
  |    UseStopSpots         = false
  |    StopSpotDuration     = 3
  |    TypeFilter           = "All"    -- or "Civilian,Guard"
  |    SpawnSpread          = 15
  |    WalkSide             = "Right"  -- "Right" or "Left"
  |    WalkSideOffset       = 10
  |    WalkBothDirections   = false    -- true = NPCs walk both ways
  |
  |-- SpawnZone   (Part)  invisible, where forward NPCs appear
  |-- DespawnZone (Part)  invisible, where forward NPCs vanish
  |                       ALSO used as spawn for reversed NPCs
  |
  |-- Waypoints        (Folder)  single path � name Parts "1","2","3"...
  |-- Waypoints_B      (Folder)  optional second path (same naming)
  |-- Waypoints_C      (Folder)  optional third path, etc.
  |   NPCs pick a random Waypoints_ folder on spawn and keep it.
  |
  |-- StopSpots  (Folder, optional � UseStopSpots must be true)
       Parts named anything; NPC pauses and faces part's LookVector
  
NPC TEMPLATE STRUCTURE (ReplicatedStorage/ClientStorage/NPCWalkerTemplates):

  NPCWalkerTemplates
  +-- Civilian  (Folder � the "type")
      +-- Civilian_A  (Model)
          +-- HumanoidRootPart  (BasePart)
          +-- [R15 body parts + welds]
          +-- AnimationController
          |    +-- Animator
          +-- Animations  (Folder)
               +-- Walk  (Animation)
               +-- Idle  (Animation)

PUBLIC API:
  walkerOrchestrator.init()                    call once at startup
  walkerOrchestrator.loadStreet(walkerModel)   flood-fill instantly (city entry)
  walkerOrchestrator.unloadStreet(walkerModel) release all instantly (city exit)

GHOST SYSTEM:
  NPCs beyond MaxExistDistance OR off the player's screen don't get
  PivotTo called � they simulate their position in pure math (ghostCF).
  When they come back on-screen they snap to the ghost position and fade in.
  This cuts PivotTo calls to only what the player can actually see.

BIDIRECTIONAL WALKING (WalkBothDirections = true):
  Forward NPCs  spawn at SpawnZone,   walk waypoints 1 -> N.
  Reversed NPCs spawn at DespawnZone, walk waypoints N -> 1.
  Both walk on the RIGHT side relative to their travel direction.
================================================================
--]]