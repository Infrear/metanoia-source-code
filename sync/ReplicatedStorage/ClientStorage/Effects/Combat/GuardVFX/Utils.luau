-- Shared helpers for the GuardVFX modules -- both wrap the same "clone a simple particle-Part
-- template, weld it to the fighter, emit, clean up" pattern used by every effect in
-- Storage.Effects.Combat.GuardParticles (each is a single Part + a "Main" Attachment full of
-- ParticleEmitters -- same safe shape SceneDirector's SimpleVFX expects).
local Utils = {}

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
Utils.GetAllEmitters = getAllEmitters

-- Welds a clone of `template` to fighterInstance's HumanoidRootPart so it follows them around (idle
-- sway, repositioning, etc.) rather than sitting fixed in world space. Returns the clone.
function Utils.AttachToFighter(template, fighterInstance, offset, startOn)
	local hrp = fighterInstance:FindFirstChild("HumanoidRootPart") or fighterInstance.PrimaryPart
	if not hrp then return nil end

	local clone = template:Clone()
	clone.Anchored = false
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.CFrame = hrp.CFrame * (offset or CFrame.new())
	if not startOn then
		Utils.SetRate(clone, 0)
		Utils.SetLooping(clone, false)
	end
	clone.Parent = workspace.PARTICLES

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = clone
	weld.Parent = clone

	return clone
end

-- Fires every emitter under `inst` once, then destroys `inst` after everything's had time to finish
-- (longest emitter Lifetime + a small buffer).
function Utils.EmitAndDestroy(inst, emitCount)
	local emitters = getAllEmitters(inst)
	local longestLifetime = 1
	for _, e in ipairs(emitters) do
		e.Enabled = true
		local maxLife = e.Lifetime.Max or 1
		if maxLife > longestLifetime then longestLifetime = maxLife end
		e:Emit(e:GetAttribute("EmitCount") or emitCount or 20)
	end
	task.delay(longestLifetime + 0.3, function()
		if inst then inst:Destroy() end
	end)
end

-- Enables every emitter under `inst` so it emits continuously (for a persistent effect like a shield
-- that should stay up while guarding).
function Utils.SetLooping(inst, enabled)
	for _, e in ipairs(getAllEmitters(inst)) do
		e.Enabled = enabled
	end
end

function Utils.SetRate(inst, rate)
	for _, e in ipairs(getAllEmitters(inst)) do
		e.Rate = rate
	end
end

return Utils
