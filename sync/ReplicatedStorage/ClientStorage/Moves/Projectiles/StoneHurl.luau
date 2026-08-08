-- StoneHurl: an earth-themed lobbed projectile.
-- A heavy rock tears up from the ground at the caster, arcs high through the air with
-- tumbling rotation and a dust trail, then slams into the target with a devastating impact.
--
-- This module is built using curated particle structures, explicitly extracting only specific
-- emitters (like wind circles, ground dirt, rocks, and flashes) rather than dumping raw prefabs.

--Services
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local Storage = RPS:WaitForChild("ClientStorage")
local Combat = Storage.Effects.Combat
local RockAssets = Combat.MoveParticles.RockMoveAssets
local RockModule = require(Storage.Modules["Open Source"].VFX.RockPunch.PunchRock)

-- color palette
local ROCK_COLOR_LIGHT = Color3.fromRGB(163, 162, 165)
local ROCK_COLOR_DARK = Color3.fromRGB(80, 80, 85)
local DUST_COLOR = Color3.fromRGB(180, 175, 165)

-- flight tuning (higher arc than LavaBomb)
local BASE_FLIGHT_DURATION = 0.55
local FLIGHT_DURATION_PER_STUD = 0.014
local MIN_FLIGHT_DURATION = 0.45
local MAX_FLIGHT_DURATION = 1.4

local BASE_APEX_HEIGHT = 10
local APEX_HEIGHT_PER_STUD = 0.35
local MAX_APEX_HEIGHT = 35

-- rock body
local ROCK_RADIUS = 1.8
local GROW_IN_FRACTION = 0.15
local APEX_SIZE_BUMP = 0.25

-- impact screenshake
local IMPACT_LINGER = 3
local SHAKE_DURATION = 0.4
local SHAKE_AMPLITUDE = 0.2
local SHAKE_ROT_AMPLITUDE = 0.4

-- pick a random custom rock mesh from RockMoveAssets
local ROCK_NAMES = {"lightrock1", "lightrock2", "lightrock3", "darkrock1", "darkrock2"}

--local charRayParams = RaycastParams.new()
--charRayParams.FilterType = Enum.RaycastFilterType.Exclude
--charRayParams.FilterDescendantsInstances = {workspace.SCRIPTING, workspace.BOUNDS, workspace.CAMERAS, workspace.NPCWALKERS, workspace.PARTICLES}

local floorRayParams = RaycastParams.new()
floorRayParams.FilterType = Enum.RaycastFilterType.Include
floorRayParams.FilterDescendantsInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}

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

-- Helper to safely grab an emitter from a folder, clone it, disable it, and optionally scale it
local function extractEmitter(sourceEmitters, name, targetParent, scaleFactor)
	local src
	if typeof(sourceEmitters) == "Instance" then
		-- search descendants if passed a folder/part
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

local function sizeMultiplierAt(s)
	local growIn = math.clamp(s / GROW_IN_FRACTION, 0, 1)
	growIn = 1 - (1 - growIn) ^ 3
	local bump = 1 + APEX_SIZE_BUMP * math.sin(math.pi * s)
	return growIn * bump
end

------------------------------------------------------------------------
-- UPTEAR: rock tears from ground at caster
------------------------------------------------------------------------
local function playUptear(originCFrame)
	local spawnPos = originCFrame.Position
	local rayResult = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), floorRayParams)
	if rayResult then
		spawnPos = rayResult.Position
	end
	
	local anchor = Instance.new("Part")
	anchor.Name = "StoneHurlUptear"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = CFrame.new(spawnPos) * originCFrame.Rotation
	anchor.Parent = workspace.PARTICLES
	
	local att = Instance.new("Attachment")
	att.Parent = anchor

	-- Curated uptear particles
	local glow = extractEmitter(RockAssets.ImpactEffects, "glow(1)", att, 0.7)
	local dust = extractEmitter(RockAssets.StylizedSmoke, "Smoke1", att, 1.2)
	local crack1 = extractEmitter(RockAssets.FloorCrack, "Floor1", att, 1.0)
	local crack2 = extractEmitter(RockAssets.FloorCrack, "Floor2", att, 1.0)
	
	if dust then dust.Color = ColorSequence.new(DUST_COLOR) end

	-- Emit!
	if glow then glow:Emit(1) end
	if dust then dust:Emit(5) end
	if crack1 then crack1:Emit(1) end
	if crack2 then crack2:Emit(2) end

	-- Tiny burst of gravel using PunchRock
	task.spawn(function()
		RockModule.Punch(
			originCFrame.Position + Vector3.new(0, 2, 0),
			originCFrame.LookVector,
			Vector3.new(0, -50, 0),
			120, -- angle
			3, -- lines
			6, -- distance
			0.4, -- startsize
			0.9, -- endsize
			6, -- numrocks
			1.5, -- lifetime
			1, -- startdist
			0.05, -- popuptime
			0.6 -- retracttime
		)
	end)

	task.delay(3.5, function()
		if anchor.Parent then anchor:Destroy() end
	end)

	return 0.4 -- delay before launching the rock
end

------------------------------------------------------------------------
-- FLIGHT: parabolic flight with trail and dust
------------------------------------------------------------------------
local function playFlight(origin, target)
	local horizontalDist = (Vector3.new(target.X, 0, target.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
	local flightDuration = math.clamp(BASE_FLIGHT_DURATION + horizontalDist * FLIGHT_DURATION_PER_STUD, MIN_FLIGHT_DURATION, MAX_FLIGHT_DURATION)
	local apexHeight = math.min(BASE_APEX_HEIGHT + horizontalDist * APEX_HEIGHT_PER_STUD, MAX_APEX_HEIGHT)

	-- pick a random custom rock mesh
	local rockName = ROCK_NAMES[math.random(1, #ROCK_NAMES)]
	local rockTemplate = RockAssets:FindFirstChild(rockName)

	local rock
	if rockTemplate and rockTemplate:IsA("MeshPart") then
		rock = rockTemplate:Clone()
		rock.Name = "StoneHurlRock"
		rock.Anchored = true
		rock.CanCollide = false
		rock.CanQuery = false
		rock.CanTouch = false
		rock.Size = Vector3.new(0.01, 0.01, 0.01)
		rock.CFrame = CFrame.new(origin)
		rock.Parent = workspace.PARTICLES
	else
		-- fallback to a basic part if mesh not found
		rock = Instance.new("Part")
		rock.Name = "StoneHurlRock"
		rock.Shape = Enum.PartType.Ball
		rock.Material = Enum.Material.Slate
		rock.Color = ROCK_COLOR_LIGHT
		rock.Size = Vector3.new(0.01, 0.01, 0.01)
		rock.Anchored = true
		rock.CanCollide = false
		rock.CanQuery = false
		rock.CanTouch = false
		rock.CFrame = CFrame.new(origin)
		rock.Parent = workspace.PARTICLES
	end

	-- Trail setup
	local trailAtt0 = Instance.new("Attachment")
	trailAtt0.Position = Vector3.new(0, 0, ROCK_RADIUS * 0.8)
	trailAtt0.Parent = rock
	local trailAtt1 = Instance.new("Attachment")
	trailAtt1.Position = Vector3.new(0, 0, -ROCK_RADIUS * 0.8)
	trailAtt1.Parent = rock

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAtt0
	trail.Attachment1 = trailAtt1
	trail.Lifetime = 0.35
	trail.MinLength = 0
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 195, 185)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 125, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 55, 50)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	trail.Parent = rock

	-- Persistent dust trail riding the rock (leaves a dusty wake)
	local dustAtt = Instance.new("Attachment")
	dustAtt.Parent = rock
	local flightDust = extractEmitter(RockAssets.StylizedSmoke, "Smoke1", dustAtt, 1.2)
	if flightDust then
		flightDust.Color = ColorSequence.new(DUST_COLOR)
		flightDust.Enabled = true -- Active for flight
		flightDust.Rate = 12
		flightDust.Lifetime = NumberRange.new(0.4, 0.8)
		flightDust.Speed = NumberRange.new(0, 2)
	end

	-- tumble rotation per frame
	local tumbleAxis = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit
	local tumbleSpeed = math.random(300, 600)

	-- parabolic flight
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
		local baseCF
		if delta.Magnitude > 0.01 then
			baseCF = CFrame.lookAt(pos, pos + delta)
		else
			baseCF = CFrame.new(pos)
		end
		rock.CFrame = baseCF * CFrame.fromAxisAngle(tumbleAxis, math.rad(tumbleSpeed * elapsed))
		prevPos = pos

		local sizeMult = sizeMultiplierAt(s)
		local r = ROCK_RADIUS * 2 * sizeMult
		rock.Size = Vector3.new(r, r * 1.2, r)
	end

	-- clean stop
	if flightDust then flightDust.Enabled = false end

	rock:Destroy()
end

------------------------------------------------------------------------
-- IMPACT: curated slam burst
------------------------------------------------------------------------
local function playImpact(impactPos, landPos)
	local impactCF = CFrame.new(impactPos)
	local landCF = CFrame.new(landPos)
	local anchor = Instance.new("Part")
	anchor.Name = "StoneHurlImpact"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = impactCF
	anchor.Parent = workspace.PARTICLES
	

	local floorAnchor = Instance.new("Part")
	floorAnchor.Name = "StoneHurlFloor"
	floorAnchor.Anchored = true
	floorAnchor.CanCollide = false
	floorAnchor.CanQuery = false
	floorAnchor.CanTouch = false
	floorAnchor.Transparency = 1
	floorAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	floorAnchor.CFrame = landCF
	floorAnchor.Parent = workspace.PARTICLES

	local att = Instance.new("Attachment")
	att.Parent = anchor
	
	local att2 = Instance.new("Attachment")
	att2.Parent = floorAnchor

	-- Extract ONLY what we need for a clean, hard earth impact.
	-- We explicitly search ImpactEffects for these specific emitters.
	-- `wind circle` (rbxassetid://13520691450 is a clean ring).
	local shockwave = nil
	for _, desc in ipairs(RockAssets.ImpactEffects:GetDescendants()) do
		if desc:IsA("ParticleEmitter") and desc.Name == "wind circle" and desc.Texture:match("13520691450") then
			shockwave = extractEmitter(desc, "wind circle", att, 1.2)
			break
		end
	end
	-- Fallback if exact texture isn't found
	if not shockwave then shockwave = extractEmitter(RockAssets.ImpactEffects, "wind circle", att, 1.2) end

	local groundDirt = extractEmitter(RockAssets.ImpactEffects, "ground1", att2, 1.5)
	local gravel = extractEmitter(RockAssets.ImpactEffects, "rocks(14", att, 1.5)
	local flash = extractEmitter(RockAssets.ImpactEffects, "flash(1", att, 1.3)
	local darkShards = extractEmitter(RockAssets.ImpactEffects, "BLACKSHARDS", att, 1.0)
	
	local dustCloud = extractEmitter(RockAssets.StylizedSmoke, "Smoke1", att, 2.5)
	if dustCloud then dustCloud.Color = ColorSequence.new(DUST_COLOR) end

	local crack1 = extractEmitter(RockAssets.FloorCrack, "Floor1", att2, 1.5)
	local crack2 = extractEmitter(RockAssets.FloorCrack, "Floor2", att2, 1.5)

	-- Emit specific counts
	if shockwave then shockwave:Emit(2) end
	if groundDirt then groundDirt:Emit(10) end
	if gravel then gravel:Emit(25) end
	if flash then flash:Emit(2) end
	if darkShards then darkShards:Emit(8) end
	if dustCloud then dustCloud:Emit(15) end
	if crack1 then crack1:Emit(1) end
	if crack2 then crack2:Emit(2) end

	-- Exploding heavy chunks via AssemblyLinearVelocity
	for i = 1, 6 do
		local chunkName = ROCK_NAMES[math.random(1, #ROCK_NAMES)]
		local chunkTemplate = RockAssets:FindFirstChild(chunkName)
		if chunkTemplate then
			local chunk = chunkTemplate:Clone()
			chunk.Name = "ExplosionChunk"
			chunk.Anchored = false
			chunk.CanCollide = true
			chunk.CanQuery = false
			chunk.CanTouch = false
			local chunkScale = math.random(5, 12) / 10
			chunk.Size = Vector3.new(chunkScale, chunkScale * 1.1, chunkScale)
			chunk.CFrame = CFrame.new(impactPos + Vector3.new(0, 1, 0)) * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, 0)
			chunk.Parent = anchor

			local angle = math.random() * math.pi * 2
			local outSpeed = math.random(20, 45)
			local upSpeed = math.random(15, 35)
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

			task.delay(1.5 + math.random() * 0.5, function()
				if chunk.Parent then
					chunk.Anchored = true
					local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
					TS:Create(chunk, fadeInfo, {Transparency = 1, Size = chunk.Size * 0.3}):Play()
					task.delay(0.7, function()
						chunk:Destroy()
					end)
				end
			end)
		end
	end
	
	-- Big ground rupture via PunchRock
	task.spawn(function()
		RockModule.Punch(
			impactPos + Vector3.new(0, 3, 0), -- origin
			Vector3.new(0, 0, 1), -- direction (spreads out via 360 angle)
			Vector3.new(0, -50, 0),
			360, -- angle
			5, -- lines
			15, -- distance
			1, -- startsize
			3, -- endsize
			20, -- numrocks
			2.5, -- lifetime
			2, -- startdist
			0.02, -- popuptime
			1.0 -- retracttime
		)
	end)

	-- screen shake
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

	task.wait(IMPACT_LINGER)
	anchor:Destroy()
	floorAnchor:Destroy()
end

------------------------------------------------------------------------
-- MAIN
------------------------------------------------------------------------
return function(attackParams)
	local originCFrame = attackParams.CasterCFrame * CFrame.new(0, 0, -6)
	local targetCFrame = attackParams.TargetCFrame
	local physicalModel = attackParams.TargetModel
	coroutine.wrap(function()
		local targetPos = targetCFrame.Position
		local landPos = (targetCFrame * CFrame.new(0, -15, 0)).Position -- fallback
		
		--local charResult = workspace:Raycast(targetPos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), charRayParams)
		local floorResult = workspace:Raycast(targetPos + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), floorRayParams)
		
		--if charResult then
		if floorResult and (targetPos - floorResult.Position).Magnitude <= 25 then
			landPos = floorResult.Position
		end
		--elseif floorResult then
		--	landPos = floorResult.Position
		--end

		-- phase 1: uptear
		local launchDelay = playUptear(originCFrame)
		task.wait(launchDelay)

		-- phase 2: flight
		playFlight(originCFrame.Position, targetPos)

		-- phase 3: impact
		playImpact(targetPos, landPos)
	end)()
end
