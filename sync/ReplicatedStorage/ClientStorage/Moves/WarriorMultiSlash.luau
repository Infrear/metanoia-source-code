-- Services
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local Storage = RPS:WaitForChild("ClientStorage")
local WarriorAssets = Storage.Effects.Combat.MoveParticles.Warrior

-- pure light/spirit warrior colors (bright gold/yellow)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_GOLD = Color3.fromRGB(255, 220, 80)
local COLOR_YELLOW = Color3.fromRGB(255, 240, 150)

-- phase timings
local CASTER_SLASH_OFFSET = CFrame.new(0, 0.25, -2.5)
local FLURRY_START_DELAY = 0.15
local FINISHER_DELAY = 0.85

-- screen shake parameters
local SHAKE_DURATION = 0.45
local SHAKE_AMPLITUDE = 0.35 -- studs (slightly higher for pure shockwave feel)
local SHAKE_ROT_AMPLITUDE = 0.6 -- degrees

-- 8-slash rapid sequence pattern (the anchors are placed here, and the attachment offsets will swing wide)
local SLASH_PATTERN = {
	{ yaw = -65,  pitch = 15,  roll = 10,  offset = Vector3.new(-0.5, 0.2, 0.2),  delay = 0.00 },
	{ yaw = 60,   pitch = -10, roll = -15, offset = Vector3.new(0.5, 0.5, -0.1),  delay = 0.08 },
	{ yaw = 0,    pitch = 5,   roll = 45,  offset = Vector3.new(0, -0.2, 0.5),    delay = 0.16 },
	{ yaw = -90,  pitch = 25,  roll = -20, offset = Vector3.new(-0.2, 0.5, -0.4), delay = 0.24 },
	{ yaw = 90,   pitch = -20, roll = 30,  offset = Vector3.new(0.1, 0.4, 0.1),   delay = 0.32 },
	{ yaw = 45,   pitch = 40,  roll = 90,  offset = Vector3.new(0.4, 0.8, 0.3),   delay = 0.40 },
	{ yaw = -45,  pitch = -30, roll = -45, offset = Vector3.new(-0.3, 0.3, 0.9),  delay = 0.48 },
	{ yaw = 180,  pitch = 10,  roll = 0,   offset = Vector3.new(0, -0.1, -0.2),   delay = 0.56 },
}

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

local function scaleEmitter(e, factor)
	local kps = {}
	for _, kp in ipairs(e.Size.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * factor, kp.Envelope * factor))
	end
	e.Size = NumberSequence.new(kps)
	e.Speed = NumberRange.new(e.Speed.Min * factor, e.Speed.Max * factor)
end

local function scaleVFXSystem(inst, factor)
	for _, e in ipairs(getAllEmitters(inst)) do
		scaleEmitter(e, factor)
	end
end

local function recolorEmitter(e)
	-- pure light logic: force all elements into a bright gold/white spectrum
	local name = e.Name:lower()
	if name:find("black") or name:find("dark") or name:find("smoke") then
		-- convert dark elements into soft glowing aura instead of deleting them
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLOR_GOLD),
			ColorSequenceKeypoint.new(1, COLOR_WHITE)
		})
		-- lower transparency so they don't block out the core
		local tkps = {}
		for _, kp in ipairs(e.Transparency.Keypoints) do
			table.insert(tkps, NumberSequenceKeypoint.new(kp.Time, math.min(1, kp.Value + 0.5), kp.Envelope))
		end
		e.Transparency = NumberSequence.new(tkps)
	else
		-- standard pure light gradient (white core -> bright yellow/gold)
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLOR_WHITE),
			ColorSequenceKeypoint.new(0.5, COLOR_YELLOW),
			ColorSequenceKeypoint.new(1, COLOR_GOLD)
		})
	end

	-- maximum glow for spirit vibe
	e.LightEmission = 1.0 
end

local function recolorVFXSystem(inst)
	for _, e in ipairs(getAllEmitters(inst)) do
		recolorEmitter(e)
	end
end

local function makeGhostPart(name, cf)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame = cf
	part.Parent = workspace.PARTICLES
	return part
end

local function burstEmit(inst, defaultCount)
	for _, e in ipairs(getAllEmitters(inst)) do
		e.Enabled = false
		local count = defaultCount or 8
		if e.Name:find("black") then
			count = math.floor(count * 0.5) -- emit fewer of the converted smoke elements
		end
		e:Emit(count)
	end
end

local function playScreenShake()
	local shakeConn
	local shakeStart = os.clock()
	local cam = workspace.CurrentCamera
	shakeConn = RS.RenderStepped:Connect(function()
		local elapsed = os.clock() - shakeStart
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
end

------------------------------------------------------------------------
-- PHASES
------------------------------------------------------------------------

local function playCasterWindupAndSlash(casterCF, targetPos)
	local anchor = makeGhostPart("WarriorCasterStrike", casterCF)

	local wind = WarriorAssets["Wind-01"]:Clone()
	wind.CFrame = casterCF * CFrame.new(0, -2, 0)
	wind.Parent = anchor
	recolorVFXSystem(wind)
	scaleVFXSystem(wind, 0.7)
	burstEmit(wind, 6)

	task.delay(0.05, function()
		local flatTarget = Vector3.new(targetPos.X, casterCF.Position.Y, targetPos.Z)
		local lookCF = CFrame.lookAt(casterCF.Position, flatTarget)
		local slashCF = lookCF * CASTER_SLASH_OFFSET

		local slash = WarriorAssets.WarriorSlashPrototype:Clone()
		slash.CFrame = CFrame.new(0, 2, 3) -- dynamic spread offset
		slash.Parent = anchor
		recolorVFXSystem(slash)
		burstEmit(slash, 8)
	end)

	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

local function playFlurryHit(cf, scale, offsetOverride)
	local anchor = makeGhostPart("WarriorFlurryHit", cf)

	-- dynamic spread slash
	local slash = WarriorAssets.WarriorSlashPrototype:Clone()
	slash.CFrame = offsetOverride or CFrame.new(0, 2, 3) -- applies the cool outward random arc effect
	slash.Parent = anchor
	if scale and scale ~= 1 then
		scaleVFXSystem(slash, scale)
	end
	recolorVFXSystem(slash)
	burstEmit(slash, 7)

	-- shattering light hit instead of electric spark
	local lightShatter = WarriorAssets["Shiny-01"]:Clone()
	local shatterAtt = lightShatter:FindFirstChild("Main")
	if shatterAtt then
		shatterAtt.CFrame = CFrame.new()
		shatterAtt.Parent = anchor
		recolorVFXSystem(shatterAtt)
		scaleVFXSystem(shatterAtt, 0.8)
		burstEmit(shatterAtt, 6)
	end

	task.delay(1.0, function()
		anchor:Destroy()
	end)
end

local function playFinisher(targetCF)
	local anchor = makeGhostPart("WarriorFinisher", targetCF)

	-- 1. dual intersecting slashes (massive arcs)
	local slash1CF = targetCF * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(45))
	local slash2CF = targetCF * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-45))
	
	task.spawn(playFlurryHit, slash1CF, 2.2, CFrame.new(0, 3, 5))
	task.spawn(playFlurryHit, slash2CF, 2.2, CFrame.new(0, 3, 5))

	-- 2. pure light horizontal shockwave ring
	local ring = WarriorAssets["Slashes-01"]:Clone()
	ring.CFrame = targetCF * CFrame.new(0, 0.5, 0)
	ring.Parent = anchor
	recolorVFXSystem(ring)
	scaleVFXSystem(ring, 1.8)
	burstEmit(ring, 12)

	-- 3. shattering air/forcefield break
	local shatter = WarriorAssets["ForceField-Break-01"]:Clone()
	local shatterAtt = shatter:FindFirstChild("Main")
	if shatterAtt then
		shatterAtt.CFrame = CFrame.new(0, 1, 0)
		shatterAtt.Parent = anchor
		recolorVFXSystem(shatterAtt)
		scaleVFXSystem(shatterAtt, 1.5)
		burstEmit(shatterAtt, 10)
	end

	-- 4. piercing shoot-01 light pulse
	local pulse = WarriorAssets["Shoot-01"]:Clone()
	local pulseAtt = pulse:FindFirstChild("Main")
	if pulseAtt then
		pulseAtt.CFrame = CFrame.new(0, 1, 0)
		pulseAtt.Parent = anchor
		recolorVFXSystem(pulseAtt)
		scaleVFXSystem(pulseAtt, 1.4)
		burstEmit(pulseAtt, 12)
	end

	-- 5. impact frame flash
	local flash = WarriorAssets.blackflashimpact:Clone()
	-- since it's an attachment, we parent to anchor directly if it has no child attachment, or parent its attachment
	if flash:IsA("Attachment") then
		flash.CFrame = CFrame.new(0, 1, 0)
		flash.Parent = anchor
		recolorVFXSystem(flash)
		scaleVFXSystem(flash, 1.5)
		burstEmit(flash, 3)
	else
		local flashAtt = flash:FindFirstChild("Attachment") or flash:FindFirstChild("Main")
		if flashAtt then
			flashAtt.CFrame = CFrame.new(0, 1, 0)
			flashAtt.Parent = anchor
			recolorVFXSystem(flashAtt)
			scaleVFXSystem(flashAtt, 1.5)
			burstEmit(flashAtt, 3)
		end
	end

	-- brilliant light flash
	local pLight = Instance.new("PointLight")
	pLight.Color = COLOR_WHITE
	pLight.Range = 35
	pLight.Brightness = 12
	pLight.Parent = anchor

	TS:Create(pLight, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = 0, Range = 0}):Play()
	playScreenShake()

	task.delay(2.5, function()
		anchor:Destroy()
	end)
end

------------------------------------------------------------------------
-- MAIN INTERFACE
------------------------------------------------------------------------
return function(attackParams)
	local casterCFrame = attackParams.CasterCFrame
	local targetModel = attackParams.TargetModel
	coroutine.wrap(function()
		local targetHRP = targetModel:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end
		local targetPos = targetHRP.Position

		-- step 1: pure light windup and strike
		playCasterWindupAndSlash(casterCFrame, targetPos)

		-- step 2: flurry of dynamic-offset slashes orbiting target
		task.wait(FLURRY_START_DELAY)
		
		for _, step in ipairs(SLASH_PATTERN) do
			task.delay(step.delay, function()
				if not targetHRP.Parent then return end
				local currentTargetCF = targetHRP.CFrame
				-- anchor part gets precisely positioned at the angle
				local slashCF = currentTargetCF 
					* CFrame.new(step.offset) 
					* CFrame.Angles(math.rad(step.pitch), math.rad(step.yaw), math.rad(step.roll))
				-- the attachment inside will be offset by 0,2,3 for a wide arc!
				playFlurryHit(slashCF, 1.0)
			end)
		end

		-- step 3: the shattering light finisher
		task.wait(FINISHER_DELAY)
		if targetHRP.Parent then
			playFinisher(targetHRP.CFrame)
		end
	end)()
end