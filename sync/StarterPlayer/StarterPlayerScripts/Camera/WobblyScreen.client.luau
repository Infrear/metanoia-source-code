-- ============================================================
-- WobblyScreen (LocalScript — separate child of StarterCharacterScripts
--                or StarterPlayerScripts)
-- Applies a subtle, continuous wobble to the camera when the
-- player is in the Dream World. Polls DreamWorld.isActive().
--
-- The wobble is a low-amplitude sine wave on camera roll + a
-- slight FOV pulse. Both are additive offsets, not replacements,
-- so they work with any camera mode (including custom cameras).
--
-- TUNING:
--    ROLL_AMPLITUDE   — max roll in degrees (keep under 3)
--    ROLL_SPEED       — how fast it oscillates
--    FOV_AMPLITUDE    — max FOV change (keep under 4)
--    FOV_SPEED        — how fast FOV pulses
-- ============================================================

-- Services
local RS   = game:GetService("RunService")
local PLRS = game:GetService("Players")
local RPS  = game:GetService("ReplicatedStorage")

-- Dependencies
local plr = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local cam = workspace.CurrentCamera

-- Require DreamWorld — adjust path to match your hierarchy
-- Assumes DreamWorld is under the same script parent as Regions
local Storage = RPS:WaitForChild("ClientStorage")
local DreamWorld = require(plr.PlayerGui:WaitForChild("ClientUIMain"):WaitForChild("Regions"):WaitForChild("DreamWorld"))
local harshOverworldCamEffectsToggleEv = Storage:WaitForChild("Events"):WaitForChild("Standard"):WaitForChild("ToggleOverworldHarsherEffects")

-- ── Tuning ───────────────────────────────────────────────────
local ROLL_AMPLITUDE = 1.5    -- degrees
local ROLL_SPEED     = 0.4    -- cycles per second
local FOV_AMPLITUDE  = 2.5    -- degrees
local FOV_SPEED      = 0.25   -- cycles per second
local FADE_SPEED     = 0.04   -- how fast the effect fades in/out (alpha per frame)

-- ── State ────────────────────────────────────────────────────
local elapsed   = 0
local alpha     = 0           -- 0 = no wobble, 1 = full wobble
local baseFOV   = cam.FieldOfView

-- ── Connection References ────────────────────────────────────
local fovConnection = nil
local renderConnection = nil

-- ── Connection Setup Function ────────────────────────────────
local function startWobbleEffect()
	-- Prevent duplicate loops if already running
	if renderConnection or fovConnection then return end

	fovConnection = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		-- Track base FOV so we don't drift it permanently
		if math.abs(cam.FieldOfView - baseFOV) > FOV_AMPLITUDE + 1 then
			baseFOV = cam.FieldOfView
		end
	end)

	renderConnection = RS.RenderStepped:Connect(function(dt)
		elapsed += dt

		-- Fade alpha in/out smoothly
		local target = (DreamWorld.isActive()) and 1 or 0
		alpha = alpha + (target - alpha) * math.min(FADE_SPEED * 60 * dt, 1)

		if alpha < 0.01 then
			-- Restore exactly and stop processing
			cam.FieldOfView = baseFOV
			return
		end

		-- Roll offset — additive CFrame rotation around the look axis
		local rollDeg = math.sin(elapsed * ROLL_SPEED * math.pi * 2) * ROLL_AMPLITUDE * alpha
		local rollRad = math.rad(rollDeg)

		-- Apply roll by rotating the camera CFrame around its own look vector
		local cf = cam.CFrame
		local origin   = cf.Position
		local lookVec  = cf.LookVector
		local rollCF   = CFrame.fromAxisAngle(lookVec, rollRad)
		cam.CFrame     = CFrame.new(origin) * rollCF * (cf - cf.Position)

		-- FOV pulse
		local fovOffset = math.sin(elapsed * FOV_SPEED * math.pi * 2) * FOV_AMPLITUDE * alpha
		cam.FieldOfView = baseFOV + fovOffset
	end)
end

local function stopWobbleEffect()
	-- 1. Sever the listeners completely from game memory
	if fovConnection then
		fovConnection:Disconnect()
		fovConnection = nil
	end
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	-- 2. Instantly reset parameters to pristine defaults
	cam.FieldOfView = baseFOV

	-- Strips away any rotational roll/tilt offset left over by the loop
	local cf = cam.CFrame
	cam.CFrame = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector)

	-- Reset state variables
	alpha = 0
	elapsed = 0
end

-- Initialize the effect on startup
startWobbleEffect()

-- ── Toggle Event Listener ────────────────────────────────────
harshOverworldCamEffectsToggleEv.Event:Connect(function(toggle)
	if toggle then
		startWobbleEffect()
	else
		stopWobbleEffect()
	end
end)