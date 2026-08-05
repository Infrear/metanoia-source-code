-- Summon VFX module. Called once when a persona begins its summon sequence (same moment the
-- base/crest mesh FX starts growing), so it can layer in extra effects (particles, sounds, light
-- flashes, etc.) on top.
--
-- "Slam" -- a quick charge & strike beam: a small sky burst above the spawn point, a beam that
-- slams down to the ground, an impact burst + rippling floor swirl, then a clean fade. Same shape
-- as the Chargu/BeamStrike cutscene effect (SceneDirector.VFXFunctions), and reuses its exact
-- lightning/glow/streak/floor-ring textures, but re-authored at persona scale instead of that
-- effect's environment scale (Chargu's own top attachment sits ~258 studs up -- way too large here).
--
-- Params:
--   spawnCFrame  : CFrame  -- where the persona is materializing (already offset per-persona via
--                            PersonaSpawnVFXOffset)
--   personaModel : Model   -- the persona's own rig (currently hidden/tiny while the mesh FX plays;
--                            do not rely on its Size mid-effect, it's driven separately)
--   targetSize   : Vector3 -- the persona's real, full-scale extents (use for scaling any effect parts)
--   growDuration : number  -- seconds the base/crest mesh FX takes to grow to full size, for timing
--                            this effect to land in sync

local TS = game:GetService("TweenService")

local Storage = game:GetService("ReplicatedStorage").ClientStorage

return function(spawnCFrame, personaModel, targetSize, growDuration)
	print("spawn vfx 2!")
	--local effectFolder = Storage.Effects.Combat["Chargu(smaller)"]

	--local skyBurstDelay  = 0
	--local slamDelay      = 0.15
	--local slamDuration   = 0.25
	--local bounceDuration = 0.35
	--local lifetime       = 2
	--local fadeDuration   = 1

	---- Recursively enable/disable every ParticleEmitter under an instance.
	---- Needed because everything in Storage sits Enabled = true with a live
	---- Rate, so a naive clone would start spewing the instant it's parented.
	--local function setEmittersEnabled(inst, enabled)
	--	if inst:IsA("ParticleEmitter") then
	--		inst.Enabled = enabled
	--	else
	--		for _, child in ipairs(inst:GetChildren()) do
	--			setEmittersEnabled(child, enabled)
	--		end
	--	end
	--end

	--local function getAllEmitters(inst, bucket)
	--	bucket = bucket or {}
	--	if inst:IsA("ParticleEmitter") then
	--		table.insert(bucket, inst)
	--	else
	--		for _, child in ipairs(inst:GetChildren()) do
	--			getAllEmitters(child, bucket)
	--		end
	--	end
	--	return bucket
	--end

	---- Build a NumberSequence with the same keypoint timing as `seq` but every
	---- keypoint's value replaced, so TweenService has a matching envelope to
	---- interpolate against.
	--local function fadeSequenceTo(seq, value)
	--	local kps = {}
	--	for _, kp in ipairs(seq.Keypoints) do
	--		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, value, kp.Envelope))
	--	end
	--	return NumberSequence.new(kps)
	--end

	--local targetCF = spawnCFrame

	--local clone = effectFolder:Clone()
	--clone.Parent = workspace.PARTICLES

	--local top    = clone:FindFirstChild("TopParticles")
	--local bottom = clone:FindFirstChild("BottomParticles")
	--local floor  = clone:FindFirstChild("FloorEffectSwirl")

	--local anchor = Instance.new("Part")
	--anchor.Anchored = true
	--anchor.CanCollide = false
	--anchor.Transparency = 1
	--anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	--anchor.CFrame = targetCF
	--anchor.Parent = clone

	--for _, inst in ipairs(clone:GetChildren()) do
	--	if inst:IsA("Attachment") then
	--		inst.Parent = anchor
	--	end
	--end

	---- Kill every emitter's live Rate immediately, same frame as the clone,
	---- before we ever yield with task.wait.
	--setEmittersEnabled(clone, false)

	---- Collect every Beam so multiple strands all get the same treatment.
	--local beams = {}
	--for _, inst in ipairs(clone:GetDescendants()) do
	--	if inst:IsA("Beam") then
	--		table.insert(beams, inst)
	--	end
	--end

	---- Register original widths, then collapse to 0 so the "bounce" tween
	---- has somewhere to bounce from.
	--local beamData = {}
	--local movedAttachments = {}
	--for _, beam in ipairs(beams) do
	--	local w0, w1 = beam.Width0, beam.Width1
	--	beam.Width0, beam.Width1 = 0, 0
	--	beam.Enabled = false

	--	-- Figure out which end is "top" (higher Y) and which is the
	--	-- "bottom" end we'll slam downward.
	--	local att0, att1 = beam.Attachment0, beam.Attachment1
	--	local topAtt, bottomAtt
	--	if att0 and att1 then
	--		if att0.Position.Y >= att1.Position.Y then
	--			topAtt, bottomAtt = att0, att1
	--		else
	--			topAtt, bottomAtt = att1, att0
	--		end
	--	end

	--	table.insert(beamData, {beam = beam, w0 = w0, w1 = w1, topAtt = topAtt, bottomAtt = bottomAtt})

	--	-- Snap the bottom attachment up to the top attachment's position
	--	-- (only once per attachment, in case multiple beams share one).
	--	if bottomAtt and topAtt and not movedAttachments[bottomAtt] then
	--		movedAttachments[bottomAtt] = bottomAtt.Position
	--		bottomAtt.Position = topAtt.Position
	--	end
	--end

	--task.wait(skyBurstDelay)

	---- 1) Explosive sky burst
	--if top then
	--	setEmittersEnabled(top, true)
	--	getAllEmitters(top) -- ensure descendants too
	--	for _, e in ipairs(getAllEmitters(top)) do
	--		e:Emit(2)
	--	end
	--end

	--task.wait(slamDelay)

	---- 2) Beam slams down: bottom attachment travels from the top point
	----    to its resting position, beams re-enable and bounce up to width.
	--local slamInfo   = TweenInfo.new(slamDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	--local bounceInfo = TweenInfo.new(bounceDuration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

	--for bottomAtt, originalPos in pairs(movedAttachments) do
	--	TS:Create(bottomAtt, slamInfo, {Position = originalPos}):Play()
	--end

	--for _, data in ipairs(beamData) do
	--	data.beam.Enabled = true
	--	TS:Create(data.beam, bounceInfo, {Width0 = data.w0, Width1 = data.w1}):Play()
	--end

	--task.wait(math.max(slamDuration, bounceDuration))

	---- 3) Impact — floor swirl + bottom burst
	--if bottom then
	--	setEmittersEnabled(bottom, true)
	--	for _, e in ipairs(getAllEmitters(bottom)) do
	--		e:Emit(2)
	--	end
	--end
	--if floor then
	--	setEmittersEnabled(floor, true)
	--end

	---- 4) Hold, like a chargeup beam
	--task.wait(lifetime)

	---- 5) Dissipate — stop spawning, tween everything down smoothly
	--setEmittersEnabled(clone, false)

	--local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	--for _, data in ipairs(beamData) do
	--	TS:Create(data.beam, fadeInfo, {Width0 = 0, Width1 = 0}):Play()
	--end

	--if floor then
	--	for _, e in ipairs(getAllEmitters(floor)) do
	--		-- Check if the Size property is a NumberSequence
	--		if typeof(e.Size) == "NumberSequence" then
	--			--print(e)
	--			-- Create a temporary NumberValue to bridge the tween
	--			local sizeBridge = Instance.new("NumberValue")
	--			local startValue = e.Size.Keypoints[1].Value
	--			local targetValue = fadeSequenceTo(e.Size, 0).Keypoints[1].Value

	--			sizeBridge.Value = startValue

	--			-- Update the emitter's NumberSequence every frame the value changes
	--			local connection
	--			connection = sizeBridge.Changed:Connect(function(newValue)
	--				if e and e.Parent then
	--					e.Size = NumberSequence.new(newValue)
	--				else
	--					connection:Disconnect()
	--				end
	--			end)

	--			-- Create and play the tween on the bridge value
	--			local t = TS:Create(sizeBridge, fadeInfo, {Value = targetValue})
	--			t.Completed:Once(function()
	--				connection:Disconnect()
	--				sizeBridge:Destroy()
	--			end)
	--			t:Play()
	--		else
	--			-- Fallback for regular numbers/Vector3 (like MeshParts or standard Parts)
	--			TS:Create(e, fadeInfo, {Size = fadeSequenceTo(e.Size, 0)}):Play()
	--		end
	--	end
	--end

	--if top then
	--	for _, e in ipairs(getAllEmitters(floor)) do
	--		-- Check if the Size property is a NumberSequence
	--		if typeof(e.Transparency) == "NumberSequence" then
	--			--print(e)
	--			-- Create a temporary NumberValue to bridge the tween
	--			local sizeBridge = Instance.new("NumberValue")
	--			local startValue = e.Transparency.Keypoints[1].Value
	--			local targetValue = fadeSequenceTo(e.Transparency, 1).Keypoints[1].Value

	--			sizeBridge.Value = startValue

	--			-- Update the emitter's NumberSequence every frame the value changes
	--			local connection
	--			connection = sizeBridge.Changed:Connect(function(newValue)
	--				if e and e.Parent then
	--					e.Transparency = NumberSequence.new(newValue)
	--				else
	--					connection:Disconnect()
	--				end
	--			end)

	--			-- Create and play the tween on the bridge value
	--			local t = TS:Create(sizeBridge, fadeInfo, {Value = targetValue})
	--			t.Completed:Once(function()
	--				connection:Disconnect()
	--				sizeBridge:Destroy()
	--			end)
	--			t:Play()
	--		else
	--			-- Fallback for regular numbers/Vector3 (like MeshParts or standard Parts)
	--			TS:Create(e, fadeInfo, {Transparency = fadeSequenceTo(e.Transparency, 1)}):Play()
	--		end
	--	end
	--end

	--task.wait(fadeDuration)
	--clone:Destroy()
end