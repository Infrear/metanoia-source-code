-- Summon VFX module. Called once when a persona begins its summon sequence (same moment the
-- base/crest mesh FX starts growing), so it can layer in extra effects (particles, sounds, light
-- flashes, etc.) on top.
--
-- "Descending Light" -- a charge-and-strike beam effect: a burst at the top, a beam that slams down
-- to the spawn point, a floor swirl that lingers, then a clean dissipate. Reuses the same technique
-- as SceneDirector.VFXFunctions.BeamStrike (same proven beam-collapse/bounce/fade approach), pointed
-- at Storage.Effects.Combat.Chargu -- NOT "Chargu(smaller)", which is a differently-structured asset
-- (raw numbered attachments, no TopParticles/BottomParticles/FloorEffectSwirl) meant for something
-- else entirely.
--
-- Chargu is authored at big cutscene scale (its TopParticles attachment sits ~258 studs above
-- BottomParticles, meant for a beam falling out of the sky onto a whole scene). That's rescaled down
-- here to persona scale based on targetSize before it ever plays, rather than trying to shrink the
-- part itself (Attachment.Position doesn't scale with a part's Size property -- it has to be scaled
-- directly).
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

-- Recursively enable/disable every ParticleEmitter under an instance. Needed because everything in
-- Storage sits Enabled = true with a live Rate, so a naive clone would start spewing the instant
-- it's parented.
local function setEmittersEnabled(inst, enabled)
	if inst:IsA("ParticleEmitter") then
		inst.Enabled = enabled
	else
		for _, child in ipairs(inst:GetChildren()) do
			setEmittersEnabled(child, enabled)
		end
	end
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

-- Build a NumberSequence with the same keypoint timing as `seq` but every keypoint's value replaced,
-- so TweenService has a matching envelope to interpolate against.
local function fadeSequenceTo(seq, value)
	local kps = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, value, kp.Envelope))
	end
	return NumberSequence.new(kps)
end

return function(spawnCFrame, personaModel, targetSize, growDuration)
	local effectFolder = Storage.Effects.Combat["Chargu(smaller)"]

	-- Timing -- kept snappy so this lands comfortably within the mesh FX's grow window
	local skyBurstDelay  = 0
	local slamDelay       = 0.12
	local slamDuration    = 0.2
	local bounceDuration  = 0.3
	local lifetime         = math.max((growDuration or 1) - 0.5, 0.4)
	local fadeDuration     = 0.6
	local skyBurstCount    = 20
	local impactCount      = 25

	local clone = effectFolder:Clone()
	clone.Parent = workspace.PARTICLES

	local top    = clone:FindFirstChild("TopParticles")
	local bottom = clone:FindFirstChild("BottomParticles")
	local floor  = clone:FindFirstChild("FloorEffectSwirl")

	-- Rescale the attachment spread from cutscene scale down to persona scale, based on the original
	-- asset's own proportions (top sits ~258 studs above origin on the source asset)
	if top and bottom then
		local desiredTopHeight = math.max(targetSize.Y * 1.8, 3)
		local originalTopHeight = math.abs(top.Position.Y)
		local scaleFactor = originalTopHeight > 0 and (desiredTopHeight / originalTopHeight) or 1
		top.Position = top.Position * scaleFactor
		bottom.Position = bottom.Position * scaleFactor
	end
	if floor then
		floor.Position = Vector3.new(0, 0, 0)
	end

	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.CFrame = spawnCFrame
	anchor.Parent = clone

	for _, inst in ipairs(clone:GetChildren()) do
		if inst:IsA("Attachment") then
			inst.Parent = anchor
		end
	end

	-- Kill every emitter's live Rate immediately, same frame as the clone, before we ever yield
	setEmittersEnabled(clone, false)

	-- Collect every Beam so all 5 strands get the same treatment
	local beams = {}
	for _, inst in ipairs(clone:GetDescendants()) do
		if inst:IsA("Beam") then
			table.insert(beams, inst)
		end
	end

	-- Register original widths, then collapse to 0 so the "bounce" tween has somewhere to bounce from
	local beamData = {}
	local movedAttachments = {}
	for _, beam in ipairs(beams) do
		local w0, w1 = beam.Width0, beam.Width1
		beam.Width0, beam.Width1 = 0, 0
		beam.Enabled = false

		local att0, att1 = beam.Attachment0, beam.Attachment1
		local topAtt, bottomAtt
		if att0 and att1 then
			if att0.Position.Y >= att1.Position.Y then
				topAtt, bottomAtt = att0, att1
			else
				topAtt, bottomAtt = att1, att0
			end
		end

		table.insert(beamData, {beam = beam, w0 = w0, w1 = w1})

		if bottomAtt and topAtt and not movedAttachments[bottomAtt] then
			movedAttachments[bottomAtt] = bottomAtt.Position
			bottomAtt.Position = topAtt.Position
		end
	end

	task.wait(skyBurstDelay)

	-- 1) Explosive sky burst at the top
	if top then
		setEmittersEnabled(top, true)
		for _, e in ipairs(getAllEmitters(top)) do
			e:Emit(e:GetAttribute("EmitCount") or skyBurstCount)
		end
	end

	task.wait(slamDelay)

	-- 2) Beam slams down: bottom attachment travels from the top point to its resting position,
	-- beams re-enable and bounce up to width
	local slamInfo   = TweenInfo.new(slamDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local bounceInfo = TweenInfo.new(bounceDuration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

	for att, originalPos in pairs(movedAttachments) do
		TS:Create(att, slamInfo, {Position = originalPos}):Play()
	end

	for _, data in ipairs(beamData) do
		data.beam.Enabled = true
		TS:Create(data.beam, bounceInfo, {Width0 = data.w0, Width1 = data.w1}):Play()
	end

	task.wait(math.max(slamDuration, bounceDuration))

	-- 3) Impact -- floor swirl + bottom burst
	if bottom then
		setEmittersEnabled(bottom, true)
		for _, e in ipairs(getAllEmitters(bottom)) do
			e:Emit(e:GetAttribute("EmitCount") or impactCount)
		end
	end
	if floor then
		setEmittersEnabled(floor, true)
	end

	-- 4) Hold, like a chargeup beam
	task.wait(lifetime)

	-- 5) Dissipate -- stop spawning, tween everything down smoothly
	setEmittersEnabled(clone, false)

	local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

	for _, data in ipairs(beamData) do
		TS:Create(data.beam, fadeInfo, {Width0 = 0, Width1 = 0}):Play()
	end

	if floor then
		for _, e in ipairs(getAllEmitters(floor)) do
			if typeof(e.Size) == "NumberSequence" then
				TS:Create(e, fadeInfo, {Size = fadeSequenceTo(e.Size, 0)}):Play()
			end
			if typeof(e.Transparency) == "NumberSequence" then
				TS:Create(e, fadeInfo, {Transparency = fadeSequenceTo(e.Transparency, 1)}):Play()
			end
		end
	end

	task.wait(fadeDuration)
	clone:Destroy()
end
