-- AlienLazer: a charging crackling energy gather → horizontal beam strike from caster to target →
-- beam holds while the contact point drifts organically around the target → dissipates.
--
-- Follows VFXTwo's proven beam-slam pattern (collapse beam widths to 0, slam attachment from
-- origin to destination, bounce widths open, hold, fade) but oriented horizontally (caster →
-- target) instead of vertically (sky → ground).
--
-- All emitters cloned from existing assets, never built from scratch:
--   Charge:  elec (crackling lightning), Anime.Charge-01 (energy gather), FlashStars.Medium
--   Beam:    Chargu(smaller) beams recolored green/purple, LightningExplode burst
--   Contact: Lightning.Hit impact particles, Anime.Lighting-03 contact lightning
--   Fade:    FlashStars.Light exit flash
--
-- Params:
--   originCFrame : CFrame -- where the laser fires from (caster)
--   targetModel  : Model  -- what gets hit (inclusion raycast locks onto this)

--Services
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local Storage = RPS:WaitForChild("ClientStorage")
local Combat = Storage.Effects.Combat
local AlienAssets = Combat.MoveParticles.AlienLazerAssets
local LightningFolder = Storage.Effects.Environment.Lightning

-- alien palette
local ALIEN_GREEN = Color3.fromRGB(30, 255, 90)
local ALIEN_PURPLE = Color3.fromRGB(160, 40, 255)
local ALIEN_CORE = Color3.fromRGB(200, 255, 220) -- bright white-green core
local ALIEN_BLACK = Color3.fromRGB(10, 5, 15)

-- phase timing
local CHARGE_DURATION = 1.0
local SLAM_DURATION = 0.15
local BOUNCE_DURATION = 0.25
local HOLD_DURATION = 1.2
local FADE_DURATION = 0.5
local SHAKE_DURATION = 0.35
local SHAKE_AMPLITUDE = 0.15 -- studs
local SHAKE_ROT_AMPLITUDE = 0.3 -- degrees

-- drift parameters (perlin noise wandering)
local DRIFT_RADIUS = 2.5
local DRIFT_SPEED = 0.8
local DRIFT_SEED = math.random(0, 10000)

local MAX_BEAM_RANGE = 200

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}

-- helpers
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

local function scaleEmitter(e, factor)
	local kps = {}
	for _, kp in ipairs(e.Size.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * factor, kp.Envelope * factor))
	end
	e.Size = NumberSequence.new(kps)
	e.Speed = NumberRange.new(e.Speed.Min * factor, e.Speed.Max * factor)
end

-- recolor all ParticleEmitters under an instance to a single color
local function recolorEmitters(inst, color)
	for _, e in ipairs(getAllEmitters(inst)) do
		e.Color = ColorSequence.new(color)
	end
end

-- recolor all Beams under an instance
local function recolorBeams(inst, color)
	for _, desc in ipairs(inst:GetDescendants()) do
		if desc:IsA("Beam") then
			desc.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ALIEN_CORE),
				ColorSequenceKeypoint.new(0.3, color),
				ColorSequenceKeypoint.new(1, color),
			})
		end
	end
end

-- make a Part invisible and non-interactive
local function ghostPart(part)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

-- build a NumberSequence with the same keypoint timing but all values set to `value`
local function fadeSequenceTo(seq, value)
	local kps = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, value, kp.Envelope))
	end
	return NumberSequence.new(kps)
end

------------------------------------------------------------------------
-- PHASE 1: CHARGE
------------------------------------------------------------------------
local function playCharge(anchor, originCFrame)
	-- crackling electricity (cloned from elec, recolored)
	local elecClone = AlienAssets.Elec:Clone()
	ghostPart(elecClone)
	elecClone.CFrame = originCFrame * CFrame.new(0, 0, -6)
	elecClone.Anchored = true
	elecClone.Parent = workspace.PARTICLES

	-- recolor all lightning emitters to alien green/purple alternating
	local elecEmitters = getAllEmitters(elecClone)
	for i, e in ipairs(elecEmitters) do
		e.Color = ColorSequence.new(i % 2 == 0 and ALIEN_GREEN or ALIEN_PURPLE)
		e.Rate = e.Rate * 1.5 -- boost density for charge feel
	end

	-- energy gather (Charge-01 structure)
	local chargeClone = AlienAssets.Charge:Clone()
	ghostPart(chargeClone)
	chargeClone.CFrame = originCFrame
	chargeClone.Parent = workspace.PARTICLES
	-- recolor to alien green, keep core white
	for _, e in ipairs(getAllEmitters(chargeClone)) do
		if e.Name == "Core1" then
			e.Color = ColorSequence.new(ALIEN_CORE)
		else
			e.Color = ColorSequence.new(ALIEN_GREEN)
		end
	end

	-- pulsing PointLight
	local chargeLight = Instance.new("PointLight")
	chargeLight.Color = ALIEN_GREEN
	chargeLight.Range = 20
	chargeLight.Brightness = 0
	chargeLight.Parent = anchor
	TS:Create(chargeLight, TweenInfo.new(CHARGE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true), {Brightness = 5}):Play()

	-- at 70% through charge, fire LightningExplode for a crackling surge
	task.delay(CHARGE_DURATION * 0.7, function()
		if not anchor.Parent then return end
		local leBurst = Combat.LightningExplode:Clone()
		ghostPart(leBurst)
		leBurst.CFrame = originCFrame
		leBurst.Parent = workspace.PARTICLES
		recolorEmitters(leBurst, ALIEN_GREEN)
		for _, e in ipairs(getAllEmitters(leBurst)) do
			e:Emit(8)
		end
		task.delay(1.5, function()
			leBurst:Destroy()
		end)
	end)

	-- at charge end, flash star
	task.delay(CHARGE_DURATION * 0.95, function()
		if not anchor.Parent then return end
		local starAtt = Combat.FlashStars.Medium:Clone()
		local star = starAtt:FindFirstChildOfClass("ParticleEmitter")
		if star then
			star.Color = ColorSequence.new(ALIEN_GREEN)
			star.Enabled = false
		end
		starAtt.Parent = anchor
		if star then star:Emit(1) end
	end)

	-- return cleanup data
	return {elecClone = elecClone, chargeClone = chargeClone, chargeLight = chargeLight}
end

------------------------------------------------------------------------
-- PHASE 2: BEAM STRIKE
------------------------------------------------------------------------
local function playBeamStrike(anchor, originCFrame, targetPos)
	-- clone Chargu(smaller) for its 5 beams
	local charguClone = Combat["Chargu(smaller)"]:Clone()
	charguClone.Parent = workspace.PARTICLES
	ghostPart(charguClone)

	-- reparent attachments onto our anchor
	local bottom = charguClone:FindFirstChild("BottomParticles")
	local top = charguClone:FindFirstChild("TopParticles")
	local floor = charguClone:FindFirstChild("FloorEffectSwirl")

	-- for the horizontal laser: bottom = origin (caster), top = target
	-- reposition attachments to be close to the anchor
	if bottom then bottom.Position = Vector3.zero end
	if top then top.Position = Vector3.zero end -- starts collapsed at origin, will slam to target

	-- move attachments onto the anchor part
	for _, inst in ipairs(charguClone:GetChildren()) do
		if inst:IsA("Attachment") then
			inst.Parent = anchor
		end
	end

	-- kill all emitters immediately (we drive them manually)
	setEmittersEnabled(charguClone, false)
	-- we DO want the floor swirl on the ground!
	if floor then
		local casterPos = originCFrame.Position
		local floorPos = (originCFrame * CFrame.new(0, -15, 0)).Position -- fallback

		local rayResult = workspace:Raycast(casterPos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), rayParams)
		if rayResult and (casterPos - rayResult.Position).Magnitude <= 25 then
			floorPos = rayResult.Position
		end

		floor.Position = anchor.CFrame:PointToObjectSpace(floorPos + Vector3.new(0, 0.1, 0))
		recolorEmitters(floor, ALIEN_GREEN)
	end

	-- recolor beams to alien green/purple
	recolorBeams(charguClone, ALIEN_GREEN)
	-- recolor beam emitters (top/bottom particles)
	if top then recolorEmitters(top, ALIEN_GREEN) end
	if bottom then recolorEmitters(bottom, ALIEN_PURPLE) end

	-- collect beams
	local beams = {}
	for _, desc in ipairs(charguClone:GetDescendants()) do
		if desc:IsA("Beam") then
			table.insert(beams, desc)
		end
	end

	-- collapse beam widths to 0, store originals
	local beamData = {}
	for _, beam in ipairs(beams) do
		local w0, w1 = beam.Width0, beam.Width1
		beam.Width0 = 0
		beam.Width1 = 0
		beam.Enabled = false
		table.insert(beamData, {beam = beam, w0 = w0, w1 = w1})
	end

	-- compute target offset in anchor local space
	local targetLocal = anchor.CFrame:PointToObjectSpace(targetPos)

	-- slam: top attachment moves from origin (0,0,0) to target position
	local slamInfo = TweenInfo.new(SLAM_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local bounceInfo = TweenInfo.new(BOUNCE_DURATION, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

	if top then
		TS:Create(top, slamInfo, {Position = targetLocal}):Play()
	end

	-- enable beams and bounce widths open
	for _, data in ipairs(beamData) do
		data.beam.Enabled = true
		TS:Create(data.beam, bounceInfo, {Width0 = data.w0 * 0.6, Width1 = data.w1 * 0.6}):Play()
	end

	-- impact particles at target
	local hitClone = LightningFolder.Hit:Clone()
	ghostPart(hitClone)
	hitClone.CFrame = CFrame.new(targetPos)
	hitClone.Parent = workspace.PARTICLES
	recolorEmitters(hitClone, ALIEN_GREEN)
	setEmittersEnabled(hitClone, false)

	local floorPos = (originCFrame * CFrame.new(0, -15, 0)).Position -- fallback

	local rayResult = workspace:Raycast(targetPos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), rayParams)
	if rayResult and (targetPos - rayResult.Position).Magnitude <= 25 then
		floorPos = rayResult.Position
	end

	local floorAnchor = Instance.new("Part")
	floorAnchor.Name = "StoneHurlFloor"
	floorAnchor.Anchored = true
	floorAnchor.CanCollide = false
	floorAnchor.CanQuery = false
	floorAnchor.CanTouch = false
	floorAnchor.Transparency = 1
	floorAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	floorAnchor.CFrame = CFrame.new(floorPos)
	floorAnchor.Parent = workspace.PARTICLES

	local att2 = Instance.new("Attachment")
	att2.Parent = floorAnchor

	-- delay impact particles to land with the slam
	task.delay(SLAM_DURATION * 0.8, function()
		for _, e in ipairs(getAllEmitters(hitClone)) do
			if e.Name == "Crack" or e.Name == "Ground" or e.Name == "Smoke" then 
				e.Parent = att2
				e:Emit(12)
			else
				e:Emit(12)
			end
		end
	end)

	-- emit burst particles at caster
	if bottom then
		setEmittersEnabled(bottom, true)
		for _, e in ipairs(getAllEmitters(bottom)) do
			e:Emit(15)
		end
		task.delay(0.3, function()
			if bottom.Parent then setEmittersEnabled(bottom, false) end
		end)
	end

	if floor then
		setEmittersEnabled(floor, true)
		for _, e in ipairs(getAllEmitters(floor)) do
			e:Emit(15)
		end
		task.delay(0.3, function()
			if floor.Parent then setEmittersEnabled(floor, false) end
		end)
	end

	-- screen shake (local only)
	local shakeConn
	local shakeStart = tick()
	local cam = workspace.CurrentCamera
	shakeConn = RS.RenderStepped:Connect(function()
		local elapsed = tick() - shakeStart
		if elapsed > SHAKE_DURATION then
			shakeConn:Disconnect()
			return
		end
		local decay = 1 - (elapsed / SHAKE_DURATION)
		local amp = SHAKE_AMPLITUDE * decay
		local rotAmp = math.rad(SHAKE_ROT_AMPLITUDE * decay)
		local ox = (math.random() - 0.5) * 2 * amp
		local oy = (math.random() - 0.5) * 2 * amp
		local oz = (math.random() - 0.5) * 2 * amp
		local rx = (math.random() - 0.5) * 2 * rotAmp
		local ry = (math.random() - 0.5) * 2 * rotAmp
		cam.CFrame = cam.CFrame * CFrame.new(ox, oy, oz) * CFrame.Angles(rx, ry, 0)
	end)

	return {
		charguClone = charguClone,
		hitClone = hitClone,
		beamData = beamData,
		topAtt = top,
		bottomAtt = bottom,
		shakeConn = shakeConn,
	}
end

------------------------------------------------------------------------
-- PHASE 3: CONTACT DRIFT
------------------------------------------------------------------------
local function playContactDrift(anchor, beamStrikeData, originCFrame, targetModel)
	local topAtt = beamStrikeData.topAtt
	local hitClone = beamStrikeData.hitClone

	-- set up contact lightning (Lighting-03 clone)
	local contactClone = AlienAssets.ContactLightning:Clone()
	ghostPart(contactClone)
	contactClone.Parent = workspace.PARTICLES
	recolorEmitters(contactClone, ALIEN_GREEN)

	-- also clone the inner Lightning particles from Environment.Lightning
	local innerLightning = LightningFolder.Lightning.Lightning
	local innerClone = innerLightning:Clone()
	ghostPart(innerClone)
	innerClone.Parent = workspace.PARTICLES
	recolorEmitters(innerClone, ALIEN_PURPLE)

	-- enable contact emitters
	setEmittersEnabled(contactClone, true)
	setEmittersEnabled(innerClone, true)

	-- set up inclusion raycast
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {targetModel}

	local targetCenter = targetModel:GetBoundingBox().Position
	local att0Pos = (originCFrame * CFrame.new(0, 0, -6)).Position
	local seed = DRIFT_SEED

	-- drift loop — perlin noise wandering
	local elapsed = 0
	while elapsed < HOLD_DURATION do
		local dt = RS.Heartbeat:Wait()
		elapsed = elapsed + dt

		local t = elapsed * DRIFT_SPEED
		local dx = math.noise(t, 0, seed) * DRIFT_RADIUS
		local dz = math.noise(0, t, seed) * DRIFT_RADIUS
		local dy = math.noise(t, t, seed) * DRIFT_RADIUS * 0.3

		-- update target center in case model moved
		local modelCF = targetModel:GetBoundingBox()
		targetCenter = modelCF.Position

		local driftPos = targetCenter + Vector3.new(dx, dy, dz)

		-- inclusion raycast from caster toward drift position
		local dir = (driftPos - att0Pos)
		if dir.Magnitude > 0.01 then
			local result = workspace:Raycast(att0Pos, dir.Unit * MAX_BEAM_RANGE, rayParams)
			local hitPos = result and result.Position or driftPos

			-- update top attachment (beam endpoint) in anchor local space
			if topAtt and topAtt.Parent then
				topAtt.Position = anchor.CFrame:PointToObjectSpace(hitPos)
			end

			-- move contact effects to hit position
			if contactClone.Parent then
				contactClone.CFrame = CFrame.new(hitPos)
			end
			if innerClone.Parent then
				innerClone.CFrame = CFrame.new(hitPos)
			end
			if hitClone and hitClone.Parent then
				hitClone.CFrame = CFrame.new(hitPos)
			end
		end
	end

	-- stop contact emitters
	setEmittersEnabled(contactClone, false)
	setEmittersEnabled(innerClone, false)

	return {contactClone = contactClone, innerClone = innerClone}
end

------------------------------------------------------------------------
-- PHASE 4: DISSIPATE
------------------------------------------------------------------------
local function playDissipate(anchor, beamStrikeData, contactData, chargeData, targetPos)
	local fadeInfo = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	-- fade beam widths to 0
	for _, data in ipairs(beamStrikeData.beamData) do
		TS:Create(data.beam, fadeInfo, {Width0 = 0, Width1 = 0}):Play()
	end

	-- stop all emitters
	if beamStrikeData.charguClone.Parent then
		setEmittersEnabled(beamStrikeData.charguClone, false)
	end

	-- final flash at target
	local exitFlash = Combat.FlashStars.Light:Clone()
	local exitStar = exitFlash:FindFirstChildOfClass("ParticleEmitter")
	if exitStar then
		exitStar.Color = ColorSequence.new(ALIEN_GREEN)
		exitStar.Enabled = false
	end
	exitFlash.Parent = anchor
	if exitStar then exitStar:Emit(1) end

	-- fade charge light
	if chargeData.chargeLight and chargeData.chargeLight.Parent then
		TS:Create(chargeData.chargeLight, fadeInfo, {Brightness = 0}):Play()
	end

	task.wait(FADE_DURATION)

	-- cleanup everything
	if beamStrikeData.charguClone.Parent then beamStrikeData.charguClone:Destroy() end
	if beamStrikeData.hitClone and beamStrikeData.hitClone.Parent then beamStrikeData.hitClone:Destroy() end
	if chargeData.elecClone.Parent then chargeData.elecClone:Destroy() end
	if chargeData.chargeClone.Parent then chargeData.chargeClone:Destroy() end
	if contactData.contactClone.Parent then contactData.contactClone:Destroy() end
	if contactData.innerClone.Parent then contactData.innerClone:Destroy() end
	if beamStrikeData.shakeConn then beamStrikeData.shakeConn:Disconnect() end
	anchor:Destroy()
end

------------------------------------------------------------------------
-- MAIN
------------------------------------------------------------------------
return function(attackParams)
	local originCFrame = attackParams.CasterCFrame
	local targetModel = attackParams.TargetModel
	coroutine.wrap(function()
		-- anchor part at caster position — all attachments parent here
		local anchor = Instance.new("Part")
		anchor.Name = "AlienLazerAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.CFrame = originCFrame * CFrame.new(0, 0, -6)
		anchor.Parent = workspace.PARTICLES

		-- resolve target position
		local targetPos = targetModel:GetBoundingBox().Position

		-- phase 1: charge
		local chargeData = playCharge(anchor, originCFrame)
		task.wait(CHARGE_DURATION)

		-- cleanup charge visuals (elec + charge energy stop)
		setEmittersEnabled(chargeData.elecClone, false)
		setEmittersEnabled(chargeData.chargeClone, false)

		-- phase 2: beam strike
		local beamStrikeData = playBeamStrike(anchor, originCFrame, targetPos)
		task.wait(math.max(SLAM_DURATION, BOUNCE_DURATION))

		-- phase 3: contact drift
		local contactData = playContactDrift(anchor, beamStrikeData, originCFrame, targetModel)

		-- phase 4: dissipate
		playDissipate(anchor, beamStrikeData, contactData, chargeData, targetPos)
	end)()
end
