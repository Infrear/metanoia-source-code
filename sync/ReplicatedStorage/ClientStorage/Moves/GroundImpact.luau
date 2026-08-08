-- GroundImpact: a melee earth slam. The caster punches the ground slightly ahead, triggering 
-- a massive smoke bomb shroud and anime-style charge-up. After a short delay, it sends 
-- a directional cone (2 lines) of erupting earth toward the target, followed by massive 
-- endpoint shockwaves at the exact end of each line.
--
-- This module is built using curated particle structures, drawing from Punch VFX and
-- High tier vfx structures in the workspace, alongside repurposed MeteorSmash elements.

--Services
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local Storage = RPS:WaitForChild("ClientStorage")
local Combat = Storage.Effects.Combat
local Env = Storage.Effects.Environment
local RockAssets = Combat.MoveParticles.RockMoveAssets
local RockModule = require(Storage.Modules["Open Source"].VFX.RockPunch.PunchRock)

-- New sources from workspace
local SamplePieces = workspace:FindFirstChild("SAMPLE PIECES TO USE")
local PunchVFX = SamplePieces and SamplePieces:FindFirstChild("Punch VFX")
local HighTierVFX = SamplePieces and SamplePieces:FindFirstChild("High tier vfx structure references")

-- color palette
local DUST_COLOR = Color3.fromRGB(180, 175, 165)
local DIRT_COLOR = Color3.fromRGB(80, 70, 60)
local GRAVEL_COLOR = Color3.fromRGB(110, 105, 100)

-- rock eruption params
local ERUPTION_SPACING = 3.5 -- distance between the parallel lines
local ERUPTION_START_SIZE = 0.8
local ERUPTION_END_SIZE = 4.0
local ERUPTION_NUM_ROCKS = 24
local ERUPTION_START_DIST = 1
local ERUPTION_POPUP_TIME = 0.25 -- total time for the rocks to reach the end
local ERUPTION_LIFETIME = 2.5
local RETRACT_DURATION = 1.0

-- timing
local SHROUD_DURATION = 1.5 -- "smoke bomb for a second or two"
local ENDPOINT_BURST_DELAY = ERUPTION_POPUP_TIME

-- screenshake params
local SHAKE_SLAM_DURATION = 0.5
local SHAKE_SLAM_AMP = 0.2
local SHAKE_END_DURATION = 0.4
local SHAKE_END_AMP = 0.35

local ROCK_NAMES = {"lightrock1", "lightrock2", "lightrock3", "darkrock1", "darkrock2"}

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

local function extractEmitter(sourceEmitters, name, targetParent, scaleFactor)
	local src
	if typeof(sourceEmitters) == "Instance" then
		for _, desc in ipairs(sourceEmitters:GetDescendants()) do
			if desc:IsA("ParticleEmitter") and desc.Name == name then
				src = desc
				break
			end
		end
	end
	
	if src then
		local clone = src:Clone()
		clone.Enabled = false
		if scaleFactor and scaleFactor ~= 1 then
			scaleEmitter(clone, scaleFactor)
		end
		clone.Parent = targetParent
		return clone
	end
	return nil
end

-- Helper to safely clone all emitters from an attachment/folder
local function extractAllFrom(source, targetParent, scaleFactor)
	if not source then return end
	for _, child in ipairs(source:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			local clone = child:Clone()
			clone.Enabled = false
			if scaleFactor and scaleFactor ~= 1 then
				scaleEmitter(clone, scaleFactor)
			end
			clone.Parent = targetParent
		end
	end
end

local function recolorToEarth(inst)
	if inst:IsA("ParticleEmitter") then
		local seq = inst.Color
		if inst.Name:match("Smoke") or inst.Name:match("Dust") then
			inst.Color = ColorSequence.new(DUST_COLOR)
		else
			inst.Color = ColorSequence.new(DIRT_COLOR)
		end
	end
	if inst:IsA("PointLight") then
		inst.Enabled = false
	end
	for _, child in ipairs(inst:GetChildren()) do
		recolorToEarth(child)
	end
end

local function playScreenShake(duration, amplitude)
	local shakeConn
	local shakeStart = tick()
	local cam = workspace.CurrentCamera
	shakeConn = RS.RenderStepped:Connect(function()
		local elapsed = tick() - shakeStart
		if elapsed > duration then
			shakeConn:Disconnect()
			return
		end
		local decay = 1 - (elapsed / duration)
		local amp = amplitude * decay
		local rotAmp = math.rad((amplitude * 2) * decay)
		cam.CFrame = cam.CFrame * CFrame.new(
			(math.random() - 0.5) * 2 * amp,
			(math.random() - 0.5) * 2 * amp,
			(math.random() - 0.5) * 2 * amp
		) * CFrame.Angles(
			(math.random() - 0.5) * 2 * rotAmp,
			(math.random() - 0.5) * 2 * rotAmp,
			0
		)
	end)
end

------------------------------------------------------------------------
-- PHASE 1: SLAM (CHARGE-UP SHROUD)
------------------------------------------------------------------------
local function playSlam(slamCFrame)
	local slamPos = slamCFrame.Position
	
	-- Raycast down to find exactly where the floor is
	local rayparams = RaycastParams.new()
	rayparams.FilterType = Enum.RaycastFilterType.Include
	rayparams.FilterDescendantsInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}
	local groundResult = workspace:Raycast(slamPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), rayparams)
	if groundResult then
		slamPos = groundResult.Position
	end
	
	local anchor = Instance.new("Part")
	anchor.Name = "GroundImpactSlam"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = CFrame.new(slamPos)
	anchor.Parent = workspace.PARTICLES

	local att = Instance.new("Attachment")
	att.Parent = anchor

	-- Extract the massive SlashSmoke the user requested
	local slashSmoke = nil
	local smokeDark = nil
	if PunchVFX and PunchVFX:FindFirstChild("HitFX") then
		local hitFX = PunchVFX.HitFX
		if hitFX:FindFirstChild("Punch") then
			slashSmoke = extractEmitter(hitFX.Punch, "SlashSmoke", att, 4.5) -- super massive scale
			if slashSmoke then 
				slashSmoke.Color = ColorSequence.new(DUST_COLOR)
				slashSmoke.Lifetime = NumberRange.new(2, 3)
			end
			
			smokeDark = extractEmitter(hitFX.Punch, "SmokeDark", att, 4.0)
			if smokeDark then
				smokeDark.Color = ColorSequence.new(DUST_COLOR)
				smokeDark.Lifetime = NumberRange.new(2, 3)
			end
		end
	end

	-- Extract Anime Charge-01 particles
	if HighTierVFX and HighTierVFX:FindFirstChild("Anime") then
		local charge = HighTierVFX.Anime:FindFirstChild("Charge-01")
		if charge and charge:FindFirstChild("Main") then
			-- clone all the charge energy particles
			extractAllFrom(charge.Main, att, 2.0) -- make charge-up bigger too
		end
		
		local bigCrack = HighTierVFX.Big:FindFirstChild("Big-Crack-01")
		if bigCrack and bigCrack:FindFirstChild("Main") then
			extractAllFrom(bigCrack.Main, att, 0.4) -- shrink huge crack to persona scale
		end
	end
	
	-- Extract rocks kicking up
	local gravel = extractEmitter(RockAssets.ImpactEffects, "rocks(14", att, 1.5)
	
	-- Emit the shroud!
	for _, emitter in ipairs(att:GetChildren()) do
		if emitter:IsA("ParticleEmitter") then
			if emitter.Name == "SlashSmoke" then
				emitter:Emit(80) -- way more emission
			elseif emitter.Name == "SmokeDark" then
				emitter:Emit(50)
			elseif emitter.Name == "rocks(14" then
				emitter:Emit(25)
			else
				-- charge particles & cracks
				emitter:Emit(15)
			end
		end
	end

	playScreenShake(SHAKE_SLAM_DURATION, SHAKE_SLAM_AMP)

	task.delay(SHROUD_DURATION + 2, function()
		if anchor.Parent then anchor:Destroy() end
	end)
end

------------------------------------------------------------------------
-- PHASE 2: ERUPTION
------------------------------------------------------------------------
local function playEruption(slamPosLeft, slamPosRight, direction, distance)
	local function fireLine(startPos)
		task.spawn(function()
			RockModule.Punch(
				startPos + Vector3.new(0, 3, 0),
				direction,
				Vector3.new(0, -50, 0),
				0, -- 0 angle
				1, -- 1 line
				distance,
				ERUPTION_START_SIZE,
				ERUPTION_END_SIZE,
				ERUPTION_NUM_ROCKS,
				ERUPTION_LIFETIME,
				ERUPTION_START_DIST,
				ERUPTION_POPUP_TIME,
				RETRACT_DURATION
			)
		end)

		-- Rolling dust trail along the line
		local dustSegments = 6
		for i = 1, dustSegments do
			task.delay(ERUPTION_POPUP_TIME * (i - 1) / dustSegments, function()
				local frac = i / dustSegments
				local dustPos = startPos + direction * (distance * frac) + Vector3.new(0, 0.5, 0)
				
				local anchor = Instance.new("Part")
				anchor.Anchored = true
				anchor.Transparency = 1
				anchor.CanCollide = false
				anchor.CanQuery = false
				anchor.CanTouch = false
				anchor.Size = Vector3.new(0.1, 0.1, 0.1)
				anchor.CFrame = CFrame.new(dustPos)
				anchor.Parent = workspace.PARTICLES
				
				local att = Instance.new("Attachment")
				att.Parent = anchor
				
				local smoke = extractEmitter(Env.Fire.MeteorSmash, "GroundSmoke", att, 0.15 + (0.2 * frac))
				if smoke then
					smoke.Color = ColorSequence.new(DUST_COLOR)
					smoke.Speed = NumberRange.new(5, 15)
					smoke:Emit(3)
				end
				
				task.delay(1.5, function()
					if anchor.Parent then anchor:Destroy() end
				end)
			end)
		end
	end

	fireLine(slamPosLeft)
	fireLine(slamPosRight)
end

------------------------------------------------------------------------
-- PHASE 3: ENDPOINT BURST
------------------------------------------------------------------------
local function playEndpointBurst(endPos)
	-- Verify ground position
	local rayparams = RaycastParams.new()
	rayparams.FilterType = Enum.RaycastFilterType.Include
	rayparams.FilterDescendantsInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}
	local groundResult = workspace:Raycast(endPos + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0), rayparams)
	if groundResult then
		endPos = groundResult.Position
	end

	local impactCF = CFrame.new(endPos)
	local anchor = Instance.new("Part")
	anchor.Name = "GroundImpactEndpoint"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = impactCF
	anchor.Parent = workspace.PARTICLES

	local att = Instance.new("Attachment")
	att.Parent = anchor

	-- Repurpose MeteorSmash!
	local msGround = Env.Fire.MeteorSmash.Ground:Clone()
	msGround.Parent = anchor
	local msBits = Env.Fire.MeteorSmash.Bits:Clone()
	msBits.Parent = anchor

	-- Rescale and Recolor
	local splashScale = 0.16 -- slightly smaller since there are two
	recolorToEarth(msGround)
	recolorToEarth(msBits)

	for _, e in ipairs(getAllEmitters(msGround)) do
		scaleEmitter(e, splashScale)
		e.Enabled = false
		e:Emit(10)
	end
	for _, e in ipairs(getAllEmitters(msBits)) do
		scaleEmitter(e, splashScale)
		e.Enabled = false
		e:Emit(12)
	end

	-- Add RockMoveAssets elements
	local gravel = extractEmitter(RockAssets.ImpactEffects, "rocks(14", att, 1.5)
	local crack1 = extractEmitter(RockAssets.FloorCrack, "Floor1", att, 1.5)
	local crack2 = extractEmitter(RockAssets.FloorCrack, "Floor2", att, 1.5)

	if gravel then gravel:Emit(15) end
	if crack1 then crack1:Emit(1) end
	if crack2 then crack2:Emit(2) end

	-- Exploding physical chunks
	for i = 1, 3 do
		local chunkName = ROCK_NAMES[math.random(1, #ROCK_NAMES)]
		local chunkTemplate = RockAssets:FindFirstChild(chunkName)
		if chunkTemplate then
			local chunk = chunkTemplate:Clone()
			chunk.Name = "SlamChunk"
			chunk.Anchored = false
			chunk.CanCollide = true
			chunk.CanQuery = false
			local chunkScale = math.random(5, 12) / 10
			chunk.Size = Vector3.new(chunkScale, chunkScale * 1.1, chunkScale)
			chunk.CFrame = CFrame.new(endPos + Vector3.new(0, 1, 0)) * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, 0)
			chunk.Parent = anchor

			local angle = math.random() * math.pi * 2
			local outSpeed = math.random(15, 30)
			local upSpeed = math.random(20, 45)
			chunk.AssemblyLinearVelocity = Vector3.new(
				math.cos(angle) * outSpeed,
				upSpeed,
				math.sin(angle) * outSpeed
			)
			chunk.AssemblyAngularVelocity = Vector3.new(
				(math.random() - 0.5) * 15,
				(math.random() - 0.5) * 15,
				(math.random() - 0.5) * 15
			)

			task.delay(1.2 + math.random() * 0.5, function()
				if chunk.Parent then
					chunk.Anchored = true
					TS:Create(chunk, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1, Size = chunk.Size * 0.3}):Play()
					task.delay(0.7, function() chunk:Destroy() end)
				end
			end)
		end
	end

	task.delay(3.5, function()
		if anchor.Parent then anchor:Destroy() end
	end)
end

------------------------------------------------------------------------
-- MAIN
------------------------------------------------------------------------
return function(attackParams)
	local casterCFrame = attackParams.CasterCFrame
	local targetModel = attackParams.TargetModel
	coroutine.wrap(function()
		local targetPos = targetModel:GetBoundingBox().Position
		local originalPos = casterCFrame.Position
		
		-- Direction toward target
		local direction = (Vector3.new(targetPos.X, originalPos.Y, targetPos.Z) - originalPos)
		if direction.Magnitude < 0.1 then
			direction = casterCFrame.LookVector
		else
			direction = direction.Unit
		end

		-- Offset the slam position to be just in front of the caster
		local slamPos = originalPos + direction * 4.5
		-- Calculate precise distance from the new slamPos to the target
		local distanceToTarget = (Vector3.new(targetPos.X, slamPos.Y, targetPos.Z) - slamPos).Magnitude
		-- Give it a minimum distance so it doesn't break if standing directly on target
		distanceToTarget = math.max(distanceToTarget, 5)

		local slamCFrame = CFrame.new(slamPos, slamPos + direction)
		
		-- Calculate parallel start points
		local rightVec = slamCFrame.RightVector
		local slamPosLeft = slamPos - rightVec * (ERUPTION_SPACING / 2)
		local slamPosRight = slamPos + rightVec * (ERUPTION_SPACING / 2)
		
		-- Phase 1: Massive Shroud Charge-up
		playSlam(slamCFrame)
		
		-- Wait out the shroud duration before erupting!
		task.wait(SHROUD_DURATION)

		-- Phase 2: Eruption (two parallel lines)
		playEruption(slamPosLeft, slamPosRight, direction, distanceToTarget)
		task.wait(ENDPOINT_BURST_DELAY)

		-- Phase 3: Endpoint bursts
		local exactEndPosLeft = slamPosLeft + direction * distanceToTarget
		local exactEndPosRight = slamPosRight + direction * distanceToTarget
		playEndpointBurst(exactEndPosLeft)
		playEndpointBurst(exactEndPosRight)
		
		playScreenShake(SHAKE_END_DURATION, SHAKE_END_AMP)
	end)()
end
