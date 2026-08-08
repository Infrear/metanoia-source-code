-- SeventhHeaven: Angel's light-based finisher. A portal tears open above the target (dynamically
-- scaled up via a tween-driven Size-sequence helper, not a static resize), a couple of clouds
-- drift in around it, then several stone pillars crash down from the portal at staggered times,
-- each landing with a slight crooked lean. Every landing triggers a burst + light flash +
-- screenshake, capped with one larger finishing flash as the portal closes.
--
-- Params:
--   cf            : CFrame -- ground position the pillars converge on (typically under the target)
--   physicalModel : Model  -- the target being hit (currently unused -- kept for parity with other
--                            attack VFX)
--
-- NOTE ON SCREENSHAKE: this module drives workspace.CurrentCamera directly with a simple additive
-- RenderStepped shake for standalone testing. In Metanoia, if CameraHandler already owns camera
-- control (e.g. SetToRig), prefer calling its shake function instead of this one so they don't
-- fight over CFrame each frame.

local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local Assets = game:GetService("ReplicatedStorage").ClientStorage.Effects.Combat.MoveParticles.SeventhHeaven

local PORTAL_HEIGHT = 65 -- studs above cf that the portal opens at
local PORTAL_OPEN_DURATION = 1.25
local PORTAL_SCALE = 15 -- portal's native particle sizes are tiny (2-5.5 studs) -- scale way up

-- telegraph: stars pop in on a dome above the target, thin light lines rush from each star
-- inward to the point the portal will open at, then everything collapses into one small flash
-- right before the portal itself starts tearing open. this is the "something's coming" beat.
-- (bumped up across the board -- wasn't reading as prominent enough at the old sizes)
local TELEGRAPH_STAR_COUNT = 9
local TELEGRAPH_DOME_RADIUS = 26
local TELEGRAPH_SPAWN_STAGGER = 0.05 -- max random delay before each star pops in
local TELEGRAPH_LINE_ARRIVE_DURATION = 0.14 -- how fast a line's width ramps up once the star appears
local TELEGRAPH_LINE_RUSH_DURATION = 0.35 -- how long the line takes to collapse inward toward the portal point
local TELEGRAPH_SETTLE_DELAY = 0.85 -- pause after the last line arrives before the converge flash + portal open
local TELEGRAPH_LINE_WIDTH = 1.1
local TELEGRAPH_CONVERGE_FLASH_SCALE = 1.6
local TELEGRAPH_GLINT_SCALE = 0.7
local TELEGRAPH_STAR_LIGHT_BRIGHTNESS = 3
local TELEGRAPH_STAR_LIGHT_RANGE = 14
local TELEGRAPH_CONVERGE_LIGHT_BRIGHTNESS = 8
local TELEGRAPH_CONVERGE_LIGHT_RANGE = 30

-- punch + rim glow that plays right as the portal starts tearing open, on top of the Back/Out
-- scale tween (which already overshoots past PORTAL_SCALE and settles back on its own)
local PORTAL_PUNCH_FLASH_SCALE = 1.1
local PORTAL_RIM_FADE_IN_DURATION = 0.35
local PORTAL_RIM_BRIGHTNESS = 6
local PORTAL_RIM_RANGE = 40

local CLOUD_COUNT = 5
local CLOUD_FADE_DURATION = 0.5
local CLOUD_RADIUS = 10
local CLOUD_SWIRL_DURATION = 1.4 -- clouds swirl inward + grow over this window before settling
local CLOUD_SWIRL_SPEED = 2.0 -- radians/sec
local CLOUD_START_RADIUS_MULT = 2.4 -- clouds start this many times further out than their resting radius
local CLOUD_START_SCALE = 0.16 -- tiny when they first pop in
local CLOUD_END_SCALE = 0.65 -- grown size once they've swirled into place
local CLOUD_END_SCALE_VARIANCE = 0.15
local CLOUD_BOB_AMPLITUDE = 1.5 -- studs of vertical float
local CLOUD_BOB_SPEED_MIN = 0.8 -- rad/sec
local CLOUD_BOB_SPEED_MAX = 1.4

local PILLAR_COUNT = 8
local PILLAR_STAGGER = 0.15 -- gap between each pillar's fall start
local FIRST_PILLAR_DELAY = 0.35 -- after the portal starts opening
local PILLAR_FALL_DURATION = 0.4
local PILLAR_SCATTER_RADIUS = 30
local PILLAR_LEAN_MIN = 4 -- degrees
local PILLAR_LEAN_MAX = 11

-- stretch on the way down (anticipation), squash on impact, then settle back to normal size with
-- a bouncy overshoot -- all on top of the existing CFrame fall/lean tween
local PILLAR_STRETCH_Y = 1.3 -- Y scale at the peak of the fall
local PILLAR_STRETCH_XZ = 0.85 -- X/Z scale at the peak of the fall (keeps it from looking too fat)
local PILLAR_SQUASH_Y = 0.55 -- Y scale at the instant of impact
local PILLAR_SQUASH_XZ = 1.25 -- X/Z scale at the instant of impact
local PILLAR_SQUASH_DURATION = 0.12
local PILLAR_SETTLE_DURATION = 0.3 -- bouncy settle back to original size after the squash

-- how long a pillar sits landed before it bounce-shrinks away, and how that shrink plays out
local PILLAR_HOLD_DURATION = 0.9
local PILLAR_SHRINK_DURATION = 0.4
local PILLAR_SHRINK_TARGET = 0.04 -- fraction of original size it shrinks to before vanishing

-- short cracks of light radiating out along the ground from each pillar impact
local GROUND_CRACK_COUNT = 3
local GROUND_CRACK_LENGTH_MIN = 3
local GROUND_CRACK_LENGTH_MAX = 6
local GROUND_CRACK_DURATION = 0.35

local BURST_SCALE = 1.4
local IMPACT_SHINY_SCALE = 2.2
local IMPACT_SHINY_VARIANCE = 0.4 -- +/- random variance applied per pillar so impacts don't look identical
local IMPACT_SPARK_SCALE = 1.2 -- layered on top of the star/line burst for pillar landings
local IMPACT_SPARK_VARIANCE = 0.25
local FINALE_SHINY_SCALE = 5
local TELEGRAPH_BURST_SCALE = 1.3 -- star/line burst reused at the telegraph's convergence point

local SHAKE_PER_PILLAR = 0.18
local SHAKE_FINALE = 0.45

-- brief full-screen whiteout synced with the finale shake
local FINALE_WHITEOUT_PEAK_ALPHA = 0.7 -- background transparency at the peak of the flash (lower = brighter)
local FINALE_WHITEOUT_IN_DURATION = 0.08
local FINALE_WHITEOUT_OUT_DURATION = 0.35
local FINALE_CLOUD_FADE_OFFSET = 0.1 -- clouds start dissipating this long after the portal starts closing

local HOLY_COLOR_CORE = Color3.fromRGB(255, 255, 235)
local HOLY_COLOR_EDGE = Color3.fromRGB(255, 225, 140)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}

local function recolorEmitter(e)
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, HOLY_COLOR_CORE),
		ColorSequenceKeypoint.new(1, HOLY_COLOR_EDGE),
	})
end

-- Smoothly rescales a ParticleEmitter's Size sequence over time via TweenService, by bridging a
-- NumberValue and rebuilding the Size sequence (scaled from its ORIGINAL authored keypoints) every
-- time the bridge changes. Lets us "grow" or "shrink" a whole particle structure smoothly instead
-- of only being able to snap-scale it once.
local function tweenEmitterScale(e, fromScale, toScale, tweenInfo)
	local originalKps = {}
	for _, kp in ipairs(e.Size.Keypoints) do
		table.insert(originalKps, {kp.Time, kp.Value, kp.Envelope})
	end

	local bridge = Instance.new("NumberValue")
	bridge.Value = fromScale
	local conn
	conn = bridge:GetPropertyChangedSignal("Value"):Connect(function()
		local scale = bridge.Value
		local kps = {}
		for _, data in ipairs(originalKps) do
			table.insert(kps, NumberSequenceKeypoint.new(data[1], data[2] * scale, data[3] * scale))
		end
		e.Size = NumberSequence.new(kps)
	end)

	local tween = TS:Create(bridge, tweenInfo, {Value = toScale})
	tween.Completed:Once(function()
		conn:Disconnect()
		bridge:Destroy()
	end)
	tween:Play()
	return tween
end

-- Rescales a ParticleEmitter's Size keypoints and Speed range by a constant factor in one shot --
-- for one-off bursts that don't need to animate growing/shrinking over time.
local function scaleEmitter(e, factor)
	local kps = {}
	for _, kp in ipairs(e.Size.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * factor, kp.Envelope * factor))
	end
	e.Size = NumberSequence.new(kps)
	e.Speed = NumberRange.new(e.Speed.Min * factor, e.Speed.Max * factor)
end

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

local function screenShake(duration, magnitude)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local startTime = os.clock()
	local conn
	conn = RS.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			conn:Disconnect()
			return
		end
		local falloff = 1 - (elapsed / duration)
		local offset = Vector3.new(
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2,
			(math.random() - 0.5) * 2
		) * magnitude * falloff
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

local function spawnBurst(position, scale)
	local burst = Assets.StarLineBurstTemplate:Clone()
	burst.CFrame = CFrame.new(position)
	burst.Parent = workspace.PARTICLES
	for _, e in ipairs(getAllEmitters(burst)) do
		recolorEmitter(e)
		scaleEmitter(e, scale)
		e.Enabled = false
		e:Emit(20)
	end
	task.delay(0.6, function()
		burst:Destroy()
	end)
end

local function spawnShinyFlash(position, scale)
	local burst = Assets.ShinyTemplate:Clone()
	burst.CFrame = CFrame.new(position)
	burst.Parent = workspace.PARTICLES
	for _, e in ipairs(getAllEmitters(burst)) do
		recolorEmitter(e)
		scaleEmitter(e, scale)
		e.Enabled = false
		e:Emit(20)
	end
	task.delay(0.6, function()
		burst:Destroy()
	end)
end

-- the ground-impact spark burst ("SparkImpactTemplate", pulled in from the workspace scratch
-- folder). layered on top of the star/line burst for pillar landings -- adds grounded debris/shard
-- energy that the star/line effect alone doesn't have. left uncolored since the source emitters
-- already carry their own authored spark colors.
local function spawnSparkImpact(position, scale)
	local spark = Assets.SparkImpactTemplate:Clone()
	spark.CFrame = CFrame.new(position)
	spark.Parent = workspace.PARTICLES
	for _, e in ipairs(getAllEmitters(spark)) do
		scaleEmitter(e, scale)
		local emitCount = math.max(3, math.floor(e.Rate))
		e.Enabled = false
		e:Emit(emitCount)
	end
	task.delay(1, function()
		spark:Destroy()
	end)
end

-- makes a tiny, invisible, anchored anchor part to hang a beam attachment off of. beams need a
-- basepart to parent their attachments to, we don't want any visible/collidable geometry for it.
local function makeAnchorPart(position)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace.PARTICLES
	return anchor
end

-- short lines of light radiating outward along the ground from an impact point, tied visually back
-- to the telegraph's sky lines so the move has one consistent "light lines" motif top to bottom
local function spawnGroundCracks(position, count)
	local centerAnchor = makeAnchorPart(position)
	for i = 1, count do
		task.spawn(function()
			local angle = (i / count) * math.pi * 2 + math.random() * 0.6
			local length = GROUND_CRACK_LENGTH_MIN + math.random() * (GROUND_CRACK_LENGTH_MAX - GROUND_CRACK_LENGTH_MIN)
			local tipPos = position + Vector3.new(math.cos(angle) * length, 0.05, math.sin(angle) * length)
			local tipAnchor = makeAnchorPart(position) -- starts collapsed at the center, then tweens outward

			local centerAtt = Instance.new("Attachment")
			centerAtt.Parent = centerAnchor
			local tipAtt = Instance.new("Attachment")
			tipAtt.Parent = tipAnchor

			local crack = Instance.new("Beam")
			crack.Attachment0 = centerAtt
			crack.Attachment1 = tipAtt
			crack.Width0 = 0.35
			crack.Width1 = 0.05
			crack.FaceCamera = true
			crack.LightEmission = 1
			crack.LightInfluence = 0
			crack.Color = ColorSequence.new(HOLY_COLOR_CORE, HOLY_COLOR_EDGE)
			crack.Transparency = NumberSequence.new(0.1)
			crack.Parent = centerAnchor

			TS:Create(tipAnchor, TweenInfo.new(GROUND_CRACK_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = CFrame.new(tipPos)}):Play()
			task.wait(GROUND_CRACK_DURATION)
			TS:Create(crack, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Width0 = 0, Width1 = 0}):Play()
			task.wait(0.2)
			tipAnchor:Destroy()
		end)
	end
	task.delay(GROUND_CRACK_DURATION + 0.3, function()
		centerAnchor:Destroy()
	end)
end

-- lets a landed pillar sit for a beat, then bounce-shrinks it down to nothing and cleans it up,
-- instead of just popping it out of existence
local function shrinkAndDestroyPillar(pillar)
	task.delay(PILLAR_HOLD_DURATION, function()
		if not pillar or not pillar.Parent then return end
		local originalSize = pillar.Size
		local shrinkTween = TS:Create(
			pillar,
			TweenInfo.new(PILLAR_SHRINK_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = originalSize * PILLAR_SHRINK_TARGET}
		)
		shrinkTween.Completed:Once(function()
			if pillar and pillar.Parent then
				pillar:Destroy()
			end
		end)
		shrinkTween:Play()
	end)
end

-- brief full-screen whiteout flash on top of everything, synced with the finale screenshake to sell
-- the ultimate-move weight. cheap ScreenGui frame, cleans itself up after fading back out.
local function screenWhiteoutFlash()
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SeventhHeavenWhiteout"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui

	gui.Parent = playerGui

	local inTween = TS:Create(frame, TweenInfo.new(FINALE_WHITEOUT_IN_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = FINALE_WHITEOUT_PEAK_ALPHA})
	inTween.Completed:Once(function()
		local outTween = TS:Create(frame, TweenInfo.new(FINALE_WHITEOUT_OUT_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1})
		outTween.Completed:Once(function()
			gui:Destroy()
		end)
		outTween:Play()
	end)
	inTween:Play()
end

-- the sky telegraph: pops stars in around a dome above the target, fires a thin light line from
-- each star that rushes inward and collapses toward the point the portal is about to open at, then
-- caps it with one small converge flash. yields until the whole beat is done, so callers can just
-- call this before opening the portal and the timing falls into place.
local function spawnTelegraph(groundPos, portalPos)
	local convergeAnchor = makeAnchorPart(portalPos)
	local convergeAtt = Instance.new("Attachment")
	convergeAtt.Parent = convergeAnchor

	local telegraphParts = {convergeAnchor}
	local remaining = TELEGRAPH_STAR_COUNT

	for i = 1, TELEGRAPH_STAR_COUNT do
		task.spawn(function()
			task.wait(math.random() * TELEGRAPH_SPAWN_STAGGER * TELEGRAPH_STAR_COUNT)

			-- random point on the upper dome above the target
			local theta = math.random() * math.pi * 2
			local phi = math.rad(20 + math.random() * 50)
			local starPos = groundPos + Vector3.new(
				math.cos(theta) * math.sin(phi) * TELEGRAPH_DOME_RADIUS,
				PORTAL_HEIGHT * (0.55 + math.random() * 0.45),
				math.sin(theta) * math.sin(phi) * TELEGRAPH_DOME_RADIUS
			)

			local starAnchor = makeAnchorPart(starPos)
			table.insert(telegraphParts, starAnchor)

			-- small glint where the star pops in, plus a brief point light so it actually reads as a
			-- "star" and not just a particle puff
			local glint = Assets.ShinyTemplate:Clone()
			glint.Transparency = 1
			glint.CanCollide = false
			glint.CFrame = CFrame.new(starPos)
			glint.Parent = workspace.PARTICLES
			for _, e in ipairs(getAllEmitters(glint)) do
				recolorEmitter(e)
				scaleEmitter(e, TELEGRAPH_GLINT_SCALE)
				e.Enabled = false
				e:Emit(2)
			end

			local starLight = Instance.new("PointLight")
			starLight.Color = HOLY_COLOR_CORE
			starLight.Range = TELEGRAPH_STAR_LIGHT_RANGE
			starLight.Brightness = 0
			starLight.Parent = glint
			local starLightIn = TS:Create(starLight, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = TELEGRAPH_STAR_LIGHT_BRIGHTNESS})
			starLightIn.Completed:Once(function()
				TS:Create(starLight, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Brightness = 0}):Play()
			end)
			starLightIn:Play()

			task.delay(1, function()
				glint:Destroy()
			end)

			local starAtt = Instance.new("Attachment")
			starAtt.Parent = starAnchor

			local beam = Instance.new("Beam")
			beam.Attachment0 = starAtt
			beam.Attachment1 = convergeAtt
			beam.Width0 = 0
			beam.Width1 = 0
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Color = ColorSequence.new(HOLY_COLOR_CORE, HOLY_COLOR_EDGE)
			beam.Transparency = NumberSequence.new(0.15)
			beam.Parent = starAnchor

			-- line snaps into existence at the star end first
			TS:Create(beam, TweenInfo.new(TELEGRAPH_LINE_ARRIVE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Width0 = TELEGRAPH_LINE_WIDTH}):Play()
			task.wait(TELEGRAPH_LINE_ARRIVE_DURATION)
			-- then the star end collapses shut while the converge end thickens slightly, reading as the
			-- line getting "sucked" inward toward the portal point
			TS:Create(beam, TweenInfo.new(TELEGRAPH_LINE_RUSH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Width0 = 0, Width1 = TELEGRAPH_LINE_WIDTH * 0.25}):Play()

			remaining -= 1
		end)
	end

	-- wait out the full spawn stagger + arrive + rush window so we don't cut lines off mid-flight
	task.wait(TELEGRAPH_SPAWN_STAGGER * TELEGRAPH_STAR_COUNT + TELEGRAPH_LINE_ARRIVE_DURATION + TELEGRAPH_LINE_RUSH_DURATION + TELEGRAPH_SETTLE_DELAY)

	spawnShinyFlash(portalPos, TELEGRAPH_CONVERGE_FLASH_SCALE)
	spawnBurst(portalPos, TELEGRAPH_BURST_SCALE)

	local convergeLight = Instance.new("PointLight")
	convergeLight.Color = HOLY_COLOR_CORE
	convergeLight.Range = TELEGRAPH_CONVERGE_LIGHT_RANGE
	convergeLight.Brightness = 0
	convergeLight.Parent = convergeAnchor
	local convergeLightIn = TS:Create(convergeLight, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = TELEGRAPH_CONVERGE_LIGHT_BRIGHTNESS})
	convergeLightIn.Completed:Once(function()
		TS:Create(convergeLight, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Brightness = 0}):Play()
	end)
	convergeLightIn:Play()

	for _, part in ipairs(telegraphParts) do
		task.delay(0.5, function()
			part:Destroy()
		end)
	end
end

return function(attackParams)
	local cf = attackParams.TargetCFrame
	local physicalModel = attackParams.TargetModel
	coroutine.wrap(function()
		local groundPos = cf.Position
		local rayResult = workspace:Raycast(groundPos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), rayParams)
		if rayResult then
			groundPos = rayResult.Position
		end
		
		local portalCF = CFrame.new(groundPos + Vector3.new(0, PORTAL_HEIGHT, 0))

		-- === sky telegraph: stars + converging light lines signal the attack is incoming ======
		spawnTelegraph(groundPos, portalCF.Position)

		-- === Portal opens ====================================================================
		-- quick punch flash right at the tear point, plus a rim glow that ramps in alongside the
		-- scale tween (Back/Out already overshoots past PORTAL_SCALE and settles -- this just adds
		-- light to sell the "tear" rather than a smooth fade in)
		spawnShinyFlash(portalCF.Position, PORTAL_PUNCH_FLASH_SCALE)

		local portal = Assets.PortalTemplate:Clone()
		portal.Transparency = 1
		portal.CanCollide = false
		portal.CFrame = portalCF
		portal.Parent = workspace.PARTICLES

		local rimLight = Instance.new("PointLight")
		rimLight.Color = HOLY_COLOR_CORE
		rimLight.Range = PORTAL_RIM_RANGE
		rimLight.Brightness = 0
		rimLight.Parent = portal
		TS:Create(rimLight, TweenInfo.new(PORTAL_RIM_FADE_IN_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = PORTAL_RIM_BRIGHTNESS}):Play()

		local portalEmitters = getAllEmitters(portal)
		for _, e in ipairs(portalEmitters) do
			recolorEmitter(e)
			e.Enabled = true
			tweenEmitterScale(e, 0.15, PORTAL_SCALE, TweenInfo.new(PORTAL_OPEN_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		end

		-- === Clouds swirl in from further out, growing and floating as they settle =============
		local clouds = {}
		local cloudSwirlData = {}
		for i = 1, CLOUD_COUNT do
			local cloud = Assets.CloudMesh:Clone()
			cloud.Anchored = true
			cloud.CanCollide = false
			cloud.CanQuery = false
			cloud.CanTouch = false
			cloud.Color = Color3.fromRGB(255, 250, 235)
			cloud.Transparency = 1

			local baseAngle = (i / CLOUD_COUNT) * math.pi * 2
			local finalRadius = CLOUD_RADIUS + math.random() * 3
			local startRadius = finalRadius * CLOUD_START_RADIUS_MULT
			local baseHeight = PORTAL_HEIGHT - 3 + math.random() * 4

			local originalMeshSize = cloud.Size
			cloud.Size = originalMeshSize * CLOUD_START_SCALE
			local endScale = CLOUD_END_SCALE + math.random() * CLOUD_END_SCALE_VARIANCE

			local startPos = groundPos + Vector3.new(math.cos(baseAngle) * startRadius, baseHeight, math.sin(baseAngle) * startRadius)
			cloud.CFrame = CFrame.new(startPos)
			cloud.Parent = workspace.PARTICLES

			table.insert(clouds, cloud)
			table.insert(cloudSwirlData, {
				cloud = cloud,
				baseAngle = baseAngle,
				startRadius = startRadius,
				finalRadius = finalRadius,
				baseHeight = baseHeight,
				bobPhase = math.random() * math.pi * 2,
				bobSpeed = CLOUD_BOB_SPEED_MIN + math.random() * (CLOUD_BOB_SPEED_MAX - CLOUD_BOB_SPEED_MIN),
			})

			TS:Create(cloud, TweenInfo.new(CLOUD_FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0.35}):Play()
			TS:Create(cloud, TweenInfo.new(CLOUD_SWIRL_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = originalMeshSize * endScale}):Play()
		end

		-- swirl inward toward the resting radius over CLOUD_SWIRL_DURATION (eased so it slows into
		-- place rather than snapping to a stop), then keep a gentle up/down float going indefinitely.
		-- disconnected explicitly before the clouds are destroyed in the finale.
		local swirlStart = os.clock()
		local swirlConn
		swirlConn = RS.RenderStepped:Connect(function()
			local now = os.clock()
			local elapsed = now - swirlStart
			local swirlT = math.clamp(elapsed / CLOUD_SWIRL_DURATION, 0, 1)
			local easedT = 1 - (1 - swirlT) ^ 3 -- ease-out cubic: fast at first, settles gently
			for _, data in ipairs(cloudSwirlData) do
				if data.cloud.Parent then
					local angle = data.baseAngle + elapsed * CLOUD_SWIRL_SPEED
					local radius = data.startRadius + (data.finalRadius - data.startRadius) * easedT
					local bob = math.sin(now * data.bobSpeed + data.bobPhase) * CLOUD_BOB_AMPLITUDE
					local pos = groundPos + Vector3.new(math.cos(angle) * radius, data.baseHeight + bob, math.sin(angle) * radius)
					data.cloud.CFrame = CFrame.new(pos)
				end
			end
		end)

		-- === Pillars crash down, staggered, each slightly crooked ============================
		task.wait(FIRST_PILLAR_DELAY)
		for i = 1, PILLAR_COUNT do
			task.spawn(function()
				local pillarAngle = math.random() * math.pi * 2
				local pillarRadius = math.random() * PILLAR_SCATTER_RADIUS
				local landXZ = Vector3.new(math.cos(pillarAngle) * pillarRadius, 0, math.sin(pillarAngle) * pillarRadius)

				local pillar = Assets.PillarMesh:Clone()
				pillar.Anchored = true
				pillar.CanCollide = false
				pillar.CanQuery = false
				pillar.Parent = workspace.PARTICLES

				local origSize = pillar.Size

				local leanAxisAngle = math.random() * math.pi * 2
				local leanAxis = Vector3.new(math.cos(leanAxisAngle), 0, math.sin(leanAxisAngle))
				local leanAmount = math.rad(PILLAR_LEAN_MIN + math.random() * (PILLAR_LEAN_MAX - PILLAR_LEAN_MIN))
				local sinkIn = 0.6 -- studs sunk into the ground for a "crashed in" look

				local restPos = groundPos + landXZ + Vector3.new(0, origSize.Y / 2 - sinkIn, 0)
				local restCFrame = CFrame.new(restPos) * CFrame.fromAxisAngle(leanAxis, leanAmount)
				local startCFrame = CFrame.new(restPos + Vector3.new(0, PORTAL_HEIGHT + 5, 0)) * CFrame.fromAxisAngle(leanAxis, leanAmount)

				pillar.CFrame = startCFrame

				local fallTween = TS:Create(pillar, TweenInfo.new(PILLAR_FALL_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {CFrame = restCFrame})
				-- stretches tall/thin on the way down (anticipation), synced with the fall duration
				TS:Create(pillar, TweenInfo.new(PILLAR_FALL_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Size = Vector3.new(origSize.X * PILLAR_STRETCH_XZ, origSize.Y * PILLAR_STRETCH_Y, origSize.Z * PILLAR_STRETCH_XZ),
				}):Play()

				fallTween.Completed:Once(function()
					local impactPos = restPos - Vector3.new(0, origSize.Y / 2 - sinkIn, 0)
					local impactScale = IMPACT_SHINY_SCALE + (math.random() * 2 - 1) * IMPACT_SHINY_VARIANCE
					spawnBurst(impactPos, BURST_SCALE)
					spawnShinyFlash(restPos, impactScale)
					local sparkScale = IMPACT_SPARK_SCALE + (math.random() * 2 - 1) * IMPACT_SPARK_VARIANCE
					spawnSparkImpact(impactPos, sparkScale)
					spawnGroundCracks(impactPos, GROUND_CRACK_COUNT)
					screenShake(SHAKE_PER_PILLAR, 0.35)

					-- squash flat on impact, then bounce back out past normal size and settle
					local squashTween = TS:Create(pillar, TweenInfo.new(PILLAR_SQUASH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Vector3.new(origSize.X * PILLAR_SQUASH_XZ, origSize.Y * PILLAR_SQUASH_Y, origSize.Z * PILLAR_SQUASH_XZ),
					})
					squashTween.Completed:Once(function()
						if not pillar.Parent then return end
						TS:Create(pillar, TweenInfo.new(PILLAR_SETTLE_DURATION, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = origSize}):Play()
					end)
					squashTween:Play()

					-- hold timer starts here, once it's actually landed, not from the moment it was thrown
					shrinkAndDestroyPillar(pillar)
				end)
				fallTween:Play()
			end)
			task.wait(PILLAR_STAGGER)
		end

		-- === Finale: bigger flash + burst, screen whiteout, portal closes then clouds dissipate ==
		task.wait(PILLAR_FALL_DURATION + 0.15)
		spawnShinyFlash(groundPos + Vector3.new(0, 3, 0), FINALE_SHINY_SCALE)
		spawnBurst(groundPos, BURST_SCALE * 1.6)
		screenShake(SHAKE_FINALE, 0.6)
		screenWhiteoutFlash()

		for _, e in ipairs(portalEmitters) do
			tweenEmitterScale(e, PORTAL_SCALE, 0.1, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
		end
		-- clouds start dissipating slightly after the portal begins closing rather than in the exact
		-- same frame, so the close doesn't read as two mirrored tweens firing at once
		task.delay(FINALE_CLOUD_FADE_OFFSET, function()
			for _, cloud in ipairs(clouds) do
				if cloud.Parent then
					TS:Create(cloud, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1}):Play()
				end
			end
		end)

		task.wait(0.8)
		swirlConn:Disconnect()
		portal:Destroy()
		for _, cloud in ipairs(clouds) do
			cloud:Destroy()
		end
	end)()
end
