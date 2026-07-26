-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependencies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local Storage = RPS:WaitForChild("ClientStorage")
local CienematicBarsUI = playerGUI:WaitForChild("CutsceneBars")
local topEdge, bottomEdge = CienematicBarsUI:WaitForChild("Holder"):WaitForChild("TopEdge"),  CienematicBarsUI:WaitForChild("Holder"):WaitForChild("BottomEdge")
local ScreenHandler = require(script.Parent.Parent:WaitForChild("ScreenChangeHandler"))
local edgeEv = Instance.new("BindableEvent", script)

local TIS = {
	CienematicClose = TweenInfo.new(
		2.5, 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out
	)
}

-- Local Variables
local edgeTEs = {}
local edgeCon = nil

-- Init
local uiTriggers = {}

-- Local Functions
-- Emit particles from a single ParticleEmitter or all emitters inside a part/model.
local function emitOnInstance(inst, count)
	count = count or 25
	if inst:IsA("ParticleEmitter") then
		if inst:GetAttribute("EmitDelay") and inst:GetAttribute("EmitDelay") > 0 then
			coroutine.wrap(function()
				task.wait(inst:GetAttribute("EmitDelay"))
				inst:Emit(inst:GetAttribute("EmitCount") or count)
			end)()
		else
			inst:Emit(inst:GetAttribute("EmitCount") or count)
		end
	else
		for _, child in pairs(inst:GetChildren()) do
			emitOnInstance(child, count)
		end
	end
end

-- Clone every child of a source folder/model onto a target BasePart or Model.
-- Returns a list of clones so the caller can clean them up.
local function cloneEffectsOnto(sourceFolder, target, emitCount)
	local clones = {}
	local attachTo = (target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildOfClass("BasePart"))) or target
	for _, effect in ipairs(sourceFolder:GetChildren()) do
		local clone = effect:Clone()
		clone.Parent = attachTo
		emitOnInstance(clone, emitCount)
		table.insert(clones, clone)
	end
	return clones
end

-- Global Functions
--[[
	Plays particle effects from a folder in Storage.Effects.
	Required fields:
	  EffectPath   – dot-separated path under Storage.Effects
	               e.g. "Combat.Explosion"
	  EmitCount    – (optional, default 5) particles per emitter
	Optional attachment:
	  PropName     – name of a prop in `props`
	  PartName     – (optional) named descendant of that prop
	               if omitted the effect parents to the prop root / primary part
	  WorldCF      – CFrame; used when no PropName given (floating VFX)
	  Async        – (default true) don't block the timeline
	  Lifetime     – seconds before clones are destroyed (default 2)
--]]
uiTriggers.SimpleVFX = function(step, super)
	-- Resolve the source effect folder
	local effectFolder = Storage.Effects
	for _, part in ipairs(step.EffectPath:split(".")) do
		effectFolder = effectFolder:FindFirstChild(part)
		if not effectFolder then
			warn("SceneDirector VFX: could not find path segment '" .. part .. "' in Effects")
			break
		end
	end

	if effectFolder then
		local emitCount = step.EmitCount or 5
		local lifetime  = step.Lifetime  or 2
		local async     = (step.Async ~= false) -- default true

		local function runVFX()
			local clones = {}

			if step.PropName then
				-- Attach to a prop (or a specific part within it)
				local target = super.ResolveProp(super.CurrentProps, step.PropName, step.PartName)
				if target and not step.UsePart then
					clones = cloneEffectsOnto(effectFolder, target, emitCount)
				elseif step.UsePart then
					local clone = effectFolder:Clone()
					clone.Parent = workspace.PARTICLES
					clone.CFrame = target:GetPivot()
					table.insert(clones, clone)
					emitOnInstance(clone)
				else
					warn("SceneDirector VFX: prop '" .. step.PropName .. "' not found")
				end
			elseif step.WorldCF then
				-- Floating effect: spawn an Attachment at a world position
				local anchor = step.UsePart and effectFolder or Instance.new("Folder")
				anchor.Anchored = true
				anchor.CanCollide = false
				anchor.Transparency = 1

				if not step.UsePart then
					anchor.Size = Vector3.new(0.1, 0.1, 0.1)
				end
				anchor.CFrame = (step.WorldCF) * ((not step.IgnoreSceneOffset) and super.CurrentConfig and super.CurrentConfig.SceneOffset) or CFrame.new(0, 0, 0)
				anchor.Parent = workspace.PARTICLES

				if not step.UsePart then
					clones = cloneEffectsOnto(effectFolder, anchor, emitCount)
				else
					emitOnInstance(anchor)
				end
				table.insert(clones, anchor) -- destroy anchor with the rest
			else
				warn("SceneDirector VFX: provide PropName or WorldCF")
			end

			task.wait(lifetime)
			for _, clone in ipairs(clones) do
				if clone and clone.Parent then
					clone:Destroy()
				end
			end
		end

		if async then
			coroutine.wrap(runVFX)()
		else
			runVFX()
		end
	end
end

--[[
	Plays a "charge & strike" beam effect: explosive sky burst, a beam that
	shoots down from the sky point to the ground point, a floor swirl that
	lingers, then a clean dissipate.

	Required fields:
	  EffectPath – dot-separated path under Storage.Effects, e.g. "Combat.Chargu"
	             Expects (all optional): TopParticles (Attachment), 
	             BottomParticles (Attachment), FloorEffectSwirl (Attachment),
	             one or more Beam instances bridging Top/Bottom attachments.

	Attachment (same as SimpleVFX): PropName / PartName, or WorldCF

	Timing fields (all optional, seconds):
	  SkyBurstDelay   – wait before the sky burst fires        (default 0)
	  SlamDelay       – wait after burst before the slam starts (default 0.15)
	  SlamDuration    – time for the beam to travel top->bottom (default 0.25)
	  BounceDuration  – time for the width "pop" tween          (default 0.35)
	  Lifetime        – how long the effect holds/lingers       (default 2)
	  FadeDuration    – fade-out length                         (default 1)
	  SkyBurstCount / ImpactCount – particles per emitter for each burst
	  Async           – (default true) don't block the timeline
--]]
uiTriggers.BeamStrike = function(step, super)
	local effectFolder = Storage.Effects
	for _, part in ipairs(step.EffectPath:split(".")) do
		effectFolder = effectFolder:FindFirstChild(part)
		if not effectFolder then
			warn("SceneDirector BeamStrike: could not find path segment '" .. part .. "' in Effects")
			return
		end
	end

	local skyBurstDelay  = step.SkyBurstDelay  or 0
	local slamDelay      = step.SlamDelay      or 0.15
	local slamDuration   = step.SlamDuration   or 0.25
	local bounceDuration = step.BounceDuration or 0.35
	local lifetime       = step.Lifetime       or 2
	local fadeDuration   = step.FadeDuration   or 1
	local async          = (step.Async ~= false)

	-- Recursively enable/disable every ParticleEmitter under an instance.
	-- Needed because everything in Storage sits Enabled = true with a live
	-- Rate, so a naive clone would start spewing the instant it's parented.
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

	-- Build a NumberSequence with the same keypoint timing as `seq` but every
	-- keypoint's value replaced, so TweenService has a matching envelope to
	-- interpolate against.
	local function fadeSequenceTo(seq, value)
		local kps = {}
		for _, kp in ipairs(seq.Keypoints) do
			table.insert(kps, NumberSequenceKeypoint.new(kp.Time, value, kp.Envelope))
		end
		return NumberSequence.new(kps)
	end

	local function runBeamStrike()
		-- Resolve target CFrame / prop
		local targetCF
		local attachTo
		if step.PropName then
			local target = super.ResolveProp(super.CurrentProps, step.PropName, step.PartName)
			if not target then
				warn("SceneDirector BeamStrike: prop '" .. step.PropName .. "' not found")
				return
			end
			targetCF = target:GetPivot()
			-- Attachments can only live on BaseParts, so if we got a Model,
			-- drop down to its PrimaryPart / first BasePart.
			attachTo = target:IsA("BasePart") and target
				or (target.PrimaryPart or target:FindFirstChildOfClass("BasePart"))
		elseif step.WorldCF then
			targetCF = step.WorldCF
			if super.CurrentConfig and super.CurrentConfig.SceneOffset and not step.IgnoreSceneOffset then
				targetCF = super.CurrentConfig.SceneOffset * targetCF
			end
		else
			warn("SceneDirector BeamStrike: provide PropName or WorldCF")
			return
		end

		local clone = effectFolder:Clone()
		clone.Parent = workspace.PARTICLES

		local top    = clone:FindFirstChild("TopParticles")
		local bottom = clone:FindFirstChild("BottomParticles")
		local floor  = clone:FindFirstChild("FloorEffectSwirl")

		local anchor = attachTo
		if not anchor then
			anchor = Instance.new("Part")
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(0.1, 0.1, 0.1)
			anchor.CFrame = targetCF
			anchor.Parent = clone
		end

		for _, inst in ipairs(clone:GetChildren()) do
			if inst:IsA("Attachment") then
				inst.Parent = anchor
			end
		end

		-- Kill every emitter's live Rate immediately, same frame as the clone,
		-- before we ever yield with task.wait.
		setEmittersEnabled(clone, false)

		-- Collect every Beam so multiple strands all get the same treatment.
		local beams = {}
		for _, inst in ipairs(clone:GetDescendants()) do
			if inst:IsA("Beam") then
				table.insert(beams, inst)
			end
		end

		-- Register original widths, then collapse to 0 so the "bounce" tween
		-- has somewhere to bounce from.
		local beamData = {}
		local movedAttachments = {}
		for _, beam in ipairs(beams) do
			local w0, w1 = beam.Width0, beam.Width1
			beam.Width0, beam.Width1 = 0, 0
			beam.Enabled = false

			-- Figure out which end is "top" (higher Y) and which is the
			-- "bottom" end we'll slam downward.
			local att0, att1 = beam.Attachment0, beam.Attachment1
			local topAtt, bottomAtt
			if att0 and att1 then
				if att0.Position.Y >= att1.Position.Y then
					topAtt, bottomAtt = att0, att1
				else
					topAtt, bottomAtt = att1, att0
				end
			end

			table.insert(beamData, {beam = beam, w0 = w0, w1 = w1, topAtt = topAtt, bottomAtt = bottomAtt})

			-- Snap the bottom attachment up to the top attachment's position
			-- (only once per attachment, in case multiple beams share one).
			if bottomAtt and topAtt and not movedAttachments[bottomAtt] then
				movedAttachments[bottomAtt] = bottomAtt.Position
				bottomAtt.Position = topAtt.Position
			end
		end

		task.wait(skyBurstDelay)

		-- 1) Explosive sky burst
		if top then
			setEmittersEnabled(top, true)
			getAllEmitters(top) -- ensure descendants too
			for _, e in ipairs(getAllEmitters(top)) do
				e:Emit(step.SkyBurstCount or 30)
			end
		end

		task.wait(slamDelay)

		-- 2) Beam slams down: bottom attachment travels from the top point
		--    to its resting position, beams re-enable and bounce up to width.
		local slamInfo   = TweenInfo.new(slamDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
		local bounceInfo = TweenInfo.new(bounceDuration, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

		for bottomAtt, originalPos in pairs(movedAttachments) do
			TS:Create(bottomAtt, slamInfo, {Position = originalPos}):Play()
		end

		for _, data in ipairs(beamData) do
			data.beam.Enabled = true
			TS:Create(data.beam, bounceInfo, {Width0 = data.w0, Width1 = data.w1}):Play()
		end

		task.wait(math.max(slamDuration, bounceDuration))

		-- 3) Impact — floor swirl + bottom burst
		if bottom then
			setEmittersEnabled(bottom, true)
			for _, e in ipairs(getAllEmitters(bottom)) do
				e:Emit(step.ImpactCount or 25)
			end
		end
		if floor then
			setEmittersEnabled(floor, true)
		end

		-- 4) Hold, like a chargeup beam
		task.wait(lifetime)

		-- 5) Dissipate — stop spawning, tween everything down smoothly
		setEmittersEnabled(clone, false)

		local fadeInfo = TweenInfo.new(fadeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

		for _, data in ipairs(beamData) do
			TS:Create(data.beam, fadeInfo, {Width0 = 0, Width1 = 0}):Play()
		end

		if floor then
			for _, e in ipairs(getAllEmitters(floor)) do
				-- Check if the Size property is a NumberSequence
				if typeof(e.Size) == "NumberSequence" then
					--print(e)
					-- Create a temporary NumberValue to bridge the tween
					local sizeBridge = Instance.new("NumberValue")
					local startValue = e.Size.Keypoints[1].Value
					local targetValue = fadeSequenceTo(e.Size, 0).Keypoints[1].Value

					sizeBridge.Value = startValue

					-- Update the emitter's NumberSequence every frame the value changes
					local connection
					connection = sizeBridge.Changed:Connect(function(newValue)
						if e and e.Parent then
							e.Size = NumberSequence.new(newValue)
						else
							connection:Disconnect()
						end
					end)

					-- Create and play the tween on the bridge value
					local t = TS:Create(sizeBridge, fadeInfo, {Value = targetValue})
					t.Completed:Once(function()
						connection:Disconnect()
						sizeBridge:Destroy()
					end)
					t:Play()
				else
					-- Fallback for regular numbers/Vector3 (like MeshParts or standard Parts)
					TS:Create(e, fadeInfo, {Size = fadeSequenceTo(e.Size, 0)}):Play()
				end
			end
		end

		if top then
			for _, e in ipairs(getAllEmitters(floor)) do
				-- Check if the Size property is a NumberSequence
				if typeof(e.Transparency) == "NumberSequence" then
					--print(e)
					-- Create a temporary NumberValue to bridge the tween
					local sizeBridge = Instance.new("NumberValue")
					local startValue = e.Transparency.Keypoints[1].Value
					local targetValue = fadeSequenceTo(e.Transparency, 1).Keypoints[1].Value

					sizeBridge.Value = startValue

					-- Update the emitter's NumberSequence every frame the value changes
					local connection
					connection = sizeBridge.Changed:Connect(function(newValue)
						if e and e.Parent then
							e.Transparency = NumberSequence.new(newValue)
						else
							connection:Disconnect()
						end
					end)

					-- Create and play the tween on the bridge value
					local t = TS:Create(sizeBridge, fadeInfo, {Value = targetValue})
					t.Completed:Once(function()
						connection:Disconnect()
						sizeBridge:Destroy()
					end)
					t:Play()
				else
					-- Fallback for regular numbers/Vector3 (like MeshParts or standard Parts)
					TS:Create(e, fadeInfo, {Transparency = fadeSequenceTo(e.Transparency, 1)}):Play()
				end
			end
		end

		task.wait(fadeDuration)
		clone:Destroy()
	end

	if async then
		coroutine.wrap(runBeamStrike)()
	else
		runBeamStrike()
	end
end

return uiTriggers
