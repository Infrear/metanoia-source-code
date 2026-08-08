-- LavaBomb: a summoning flash + smoke windup, then a fireball lobbed from caster to target in a
-- fast, weighted parabola -- quick to launch, brief hang near the apex, then drops in hard --
-- followed by a splash impact.
--
-- Reuses existing Fire assets: Explosy (already character-scale, used as-is for the impact's
-- central burst) and MeteorSmash's ground debris/shockwave emitters (rescaled down from their
-- ~90-200 stud environmental size to a persona-splash radius). The windup uses two custom
-- textures: a summoning star (single flash-and-spin) and a crackfire smoke puff.
--
-- Params:
--   originCFrame  : CFrame -- where the fireball launches from (the caster)
--   targetCFrame  : CFrame -- where it's aimed / lands (the opponent)
--   physicalModel : Model  -- the target being hit (currently unused -- kept for parity with
--                            other attack VFX, and for future use e.g. sizing the splash to
--                            their hitbox)

local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local Storage = RPS:WaitForChild("ClientStorage")
local FireFolder = Storage.Effects.Environment.Fire

local STAR_TEXTURE = "rbxassetid://96021849887652"
local SMOKE_TEXTURE = "rbxassetid://81210178948069"

local STAR_LIFETIME = 1.5
local SMOKE_LIFETIME = 0.9

-- Windup phase offsets, each measured from the moment playWindup() is called:
local FIRE_BUILDUP_DURATION = 0.6 -- slow flame ramps up over this long before it erupts
local EXPLOSION_SCALE = 0.65 -- smaller than the impact's Explosy burst, so it doesn't steal the finale
local SMOKE_DELAY = 0.15 -- gap between the explosion and the crackfire smoke blooming
local STAR_LEAD = 0.35 -- gap between smoke starting and the star flash + ball launch firing together

local BASE_FLIGHT_DURATION = 0.45
local FLIGHT_DURATION_PER_STUD = 0.012
local MIN_FLIGHT_DURATION = 0.4
local MAX_FLIGHT_DURATION = 1.3

local BASE_APEX_HEIGHT = 6
local APEX_HEIGHT_PER_STUD = 0.25
local MAX_APEX_HEIGHT = 26

local BALL_RADIUS = 1.1
local GROW_IN_FRACTION = 0.12 -- fraction of the flight spent popping in from size 0
local APEX_SIZE_BUMP = 0.35 -- extra size at the apex, tapering back down toward landing
local SPLASH_SCALE = 0.13 -- shrink factor applied to MeteorSmash's ~90-200 stud emitters
local IMPACT_LINGER = 3 -- seconds before the impact clones get cleaned up

local function getAllEmitters(inst, bucket)
	bucket = bucket or {}
	if inst:IsA("ParticleEmitter") then
		table.insert(bucket, inst)
	else
		for _, child in ipairs(inst:GetChildren()) do
			getAllEmitters(child, bucket)
		end
	end
	return bucket
end

local function setEmittersEnabled(inst, enabled)
	if inst:IsA("ParticleEmitter") then
		inst.Enabled = enabled
	else
		for _, child in ipairs(inst:GetChildren()) do
			setEmittersEnabled(child, enabled)
		end
	end
end

-- Rescales a ParticleEmitter's Size keypoints and Speed range by `factor`, keeping its authored
-- curve shape/timing intact -- lets us reuse MeteorSmash's big environmental emitters at
-- persona-splash scale without hand-redoing every keypoint.
local function scaleEmitter(e, factor)
	local kps = {}
	for _, kp in ipairs(e.Size.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * factor, kp.Envelope * factor))
	end
	e.Size = NumberSequence.new(kps)
	e.Speed = NumberRange.new(e.Speed.Min * factor, e.Speed.Max * factor)
end

-- Size multiplier over the course of the flight (s = 0..1): a fast eased pop-in over the first
-- GROW_IN_FRACTION of the flight, then a sine bump that grows the ball toward the apex (s=0.5)
-- and shrinks it back down toward landing -- the "velocity-like" scale up/down through the arc.
local function sizeMultiplierAt(s)
	local growIn = math.clamp(s / GROW_IN_FRACTION, 0, 1)
	growIn = 1 - (1 - growIn) ^ 3 -- ease-out cubic, snappy pop rather than a linear ramp
	local bump = 1 + APEX_SIZE_BUMP * math.sin(math.pi * s)
	return growIn * bump
end

-- Summoning windup, four phases, each timed relative to when playWindup() is called:
--   1. A small fire slowly builds (Rate ramps 0 -> full over FIRE_BUILDUP_DURATION)
--   2. It erupts into a (smaller) explosion once the buildup finishes
--   3. Crackfire smoke blooms shortly after the explosion
--   4. The summoning star flashes at the same moment the fireball actually launches
-- Returns the total delay (seconds) the caller should wait before launching the ball, so the
-- star flash and the launch always land together even if the phase timings above are retuned.
local function playWindup(originCFrame)
	local anchor = Instance.new("Part")
	anchor.Name = "LavaBombWindup"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = originCFrame
	anchor.Parent = workspace.PARTICLES

	-- Phase 1: slow fire buildup -- Flames' emitters cloned in with Rate zeroed out, then eased
	-- up to their authored Rate over FIRE_BUILDUP_DURATION so the flame visibly grows in density.
	local buildupAtt = Instance.new("Attachment")
	buildupAtt.Parent = anchor

	local buildupEmitters = {}
	for _, name in ipairs({"Base", "Sparks", "Keeper", "Smoke"}) do
		local emitterSrc = FireFolder.Flames.Attachment:FindFirstChild(name)
		if emitterSrc then
			local clone = emitterSrc:Clone()
			local targetRate = clone.Rate
			clone.Rate = 0
			clone.Enabled = true
			clone.Parent = buildupAtt
			table.insert(buildupEmitters, {emitter = clone, targetRate = targetRate})
		end
	end
	for _, data in ipairs(buildupEmitters) do
		TS:Create(data.emitter, TweenInfo.new(FIRE_BUILDUP_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Rate = data.targetRate}):Play()
	end

	-- Phase 2: explosion, right as the buildup finishes -- reuses Explosy (same asset as the
	-- final impact) but scaled down so it reads as "casting," not the actual hit.
	task.delay(FIRE_BUILDUP_DURATION, function()
		if not anchor.Parent then return end
		for _, data in ipairs(buildupEmitters) do
			data.emitter.Enabled = false
		end

		local explosion = FireFolder.Explosy:Clone()
		explosion.CFrame = originCFrame
		explosion.Parent = workspace.PARTICLES
		for _, e in ipairs(getAllEmitters(explosion)) do
			scaleEmitter(e, EXPLOSION_SCALE)
			e.Enabled = true
			e:Emit(12)
		end
		task.delay(0.35, function()
			if explosion.Parent then
				setEmittersEnabled(explosion, false)
			end
		end)
		task.delay(2, function()
			explosion:Destroy()
		end)
	end)

	-- Phase 3: crackfire smoke, blooming shortly after the explosion
	local smokeOffset = FIRE_BUILDUP_DURATION + SMOKE_DELAY
	local smokeAtt = Instance.new("Attachment")
	smokeAtt.Parent = anchor
	task.delay(smokeOffset, function()
		if not anchor.Parent then return end
		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "SummonSmoke"
		smoke.Texture = SMOKE_TEXTURE
		smoke.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		smoke.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		smoke.FlipbookFramerate = NumberRange.new(8, 10)
		smoke.Rate = 0
		smoke.Enabled = false
		smoke.LightEmission = 0.15
		smoke.Color = ColorSequence.new(Color3.fromRGB(255, 140, 90))
		smoke.Lifetime = NumberRange.new(SMOKE_LIFETIME, SMOKE_LIFETIME * 1.2)
		smoke.Speed = NumberRange.new(1, 2.5)
		smoke.SpreadAngle = Vector2.new(25, 25)
		smoke.RotSpeed = NumberRange.new(-40, 40)
		smoke.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 3.5),
			NumberSequenceKeypoint.new(1, 4.5),
		})
		smoke.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.6, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
		smoke.Parent = smokeAtt
		smoke:Emit(4)
	end)

	-- Phase 4: summoning star, timed to flash at the same instant the ball launches
	local starOffset = smokeOffset + STAR_LEAD
	task.delay(starOffset, function()
		if not anchor.Parent then return end
		local starAtt = Storage.Effects.Combat.FlashStars.Medium:Clone()
		local star = starAtt.ParticleEmitter
		star.Texture = STAR_TEXTURE
		star.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		star.FlipbookMode = Enum.ParticleFlipbookMode.OneShot -- one full star
		star.Rate = 0
		star.Enabled = false
		star.LightEmission = 1
		star.Color = ColorSequence.new(Color3.fromRGB(255, 200, 140))
		star.Lifetime = NumberRange.new(STAR_LIFETIME, STAR_LIFETIME)
		star.Speed = NumberRange.new(0, 0)
		star.RotSpeed = NumberRange.new(200, 200)
		star.Orientation = Enum.ParticleOrientation.FacingCamera
		starAtt.Parent = anchor
		star.Parent = starAtt
		star:Emit(1)
	end)

	local cleanupTime = math.max(FIRE_BUILDUP_DURATION + 2.5, starOffset + STAR_LIFETIME, smokeOffset + SMOKE_LIFETIME * 1.2) + 0.15
	task.delay(cleanupTime, function()
		anchor:Destroy()
	end)

	return starOffset
end
return function(attackParams)
	local originCFrame = attackParams.CasterCFrame
	local targetCFrame = attackParams.TargetCFrame
	local physicalModel = attackParams.TargetModel
	coroutine.wrap(function()
		local launchDelay = playWindup(originCFrame)
		task.wait(launchDelay)

		local origin = originCFrame.Position
		local target = targetCFrame.Position

		local horizontalDist = (Vector3.new(target.X, 0, target.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
		local flightDuration = math.clamp(BASE_FLIGHT_DURATION + horizontalDist * FLIGHT_DURATION_PER_STUD, MIN_FLIGHT_DURATION, MAX_FLIGHT_DURATION)
		local apexHeight = math.min(BASE_APEX_HEIGHT + horizontalDist * APEX_HEIGHT_PER_STUD, MAX_APEX_HEIGHT)

		-- === Fireball body =================================================================
		local ball = Instance.new("Part")
		ball.Name = "LavaBombBall"
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.Neon
		ball.Color = Color3.fromRGB(255, 90, 20)
		ball.Size = Vector3.new(0.01, 0.01, 0.01)
		ball.Anchored = true
		ball.CanCollide = false
		ball.CanQuery = false
		ball.CanTouch = false
		ball.CFrame = CFrame.new(origin)
		ball.Parent = workspace.PARTICLES

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 140, 60)
		light.Range = 18
		light.Brightness = 3
		light.Parent = ball

		local trailAtt0 = Instance.new("Attachment")
		trailAtt0.Position = Vector3.new(0, 0, BALL_RADIUS * 0.9)
		trailAtt0.Parent = ball
		local trailAtt1 = Instance.new("Attachment")
		trailAtt1.Position = Vector3.new(0, 0, -BALL_RADIUS * 0.9)
		trailAtt1.Parent = ball

		local trail = Instance.new("Trail")
		trail.Attachment0 = trailAtt0
		trail.Attachment1 = trailAtt1
		trail.Lifetime = 0.3
		trail.MinLength = 0
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 120)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 90, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 10, 5)),
		})
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		trail.Parent = ball

		-- Small continuous fire/ember trail riding the ball -- cloned straight from Explosy,
		-- already character-scale, no rescaling needed.
		local rideAtt = Instance.new("Attachment")
		rideAtt.Parent = ball
		for _, name in ipairs({"Fire", "Sparks"}) do
			local src = FireFolder.Explosy.Attachment:FindFirstChild(name)
			if src then
				local clone = src:Clone()
				clone.Enabled = true
				clone.Parent = rideAtt
			end
		end

		-- === Flight: fast up, weighted drop, size tracking the arc ==========================
		-- Horizontal motion is linear; vertical motion is a parabola through (origin, apex,
		-- target) -- naturally fastest at launch and at landing, slowest at the apex. Ball size
		-- pops in fast at launch, then grows toward the apex and shrinks back down toward impact.
		local elapsed = 0
		local prevPos = origin
		while elapsed < flightDuration do
			local dt = RS.Heartbeat:Wait()
			elapsed = math.min(elapsed + dt, flightDuration)
			local s = elapsed / flightDuration

			local xz = origin:Lerp(target, s)
			local y = origin.Y + (target.Y - origin.Y) * s + 4 * apexHeight * s * (1 - s)
			local pos = Vector3.new(xz.X, y, xz.Z)

			local delta = pos - prevPos
			if delta.Magnitude > 0.01 then
				ball.CFrame = CFrame.lookAt(pos, pos + delta)
			else
				ball.CFrame = CFrame.new(pos)
			end
			prevPos = pos

			local sizeMult = sizeMultiplierAt(s)
			ball.Size = Vector3.new(BALL_RADIUS, BALL_RADIUS, BALL_RADIUS) * 2 * sizeMult
			light.Range = 18 * sizeMult
			light.Brightness = 3 * sizeMult
		end

		ball:Destroy()

		-- === Impact: splash ==================================================================
		local impactCF = CFrame.new(target)
		local impactFolder = Instance.new("Folder")
		impactFolder.Name = "LavaBombImpact"
		impactFolder.Parent = workspace.PARTICLES

		-- Central fire burst -- Explosy is already the right scale for a character-sized hit.
		local explosy = FireFolder.Explosy:Clone()
		explosy.CFrame = impactCF
		explosy.Parent = impactFolder
		setEmittersEnabled(explosy, true)
		for _, e in ipairs(getAllEmitters(explosy)) do
			e:Emit(16)
		end
		task.delay(0.4, function()
			if explosy.Parent then
				setEmittersEnabled(explosy, false)
			end
		end)

		-- Ground debris / shockwave -- MeteorSmash's Ground + Bits emitters, rescaled down from
		-- their ~90-200 stud environmental size to a persona-splash radius.
		local impactAnchor = Instance.new("Part")
		impactAnchor.Anchored = true
		impactAnchor.CanCollide = false
		impactAnchor.CanQuery = false
		impactAnchor.CanTouch = false
		impactAnchor.Transparency = 1
		impactAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
		impactAnchor.CFrame = impactCF
		impactAnchor.Parent = impactFolder

		local ground = FireFolder.MeteorSmash.Ground:Clone()
		ground.Parent = impactAnchor
		local bits = FireFolder.MeteorSmash.Bits:Clone()
		bits.Parent = impactAnchor

		local groundLight = ground:FindFirstChildOfClass("PointLight")
		if groundLight then
			groundLight.Range = 16
			groundLight.Brightness = 4
		end

		for _, e in ipairs(getAllEmitters(ground)) do
			scaleEmitter(e, SPLASH_SCALE)
			e.Enabled = false
			e:Emit(12)
		end
		for _, e in ipairs(getAllEmitters(bits)) do
			scaleEmitter(e, SPLASH_SCALE)
			e.Enabled = false
			e:Emit(12)
		end

		task.wait(IMPACT_LINGER)
		impactFolder:Destroy()
	end)()
end
