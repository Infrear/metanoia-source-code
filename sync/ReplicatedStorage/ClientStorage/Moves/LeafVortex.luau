-- LeafVortex: a swirling vortex of glowing green energy blades with tumbling leaves caught in the
-- spin, capped off with a shockwave release. Built on the "Slashes-01" reference structure (flat
-- particles spinning in place via near-zero Speed + huge RotSpeed + VelocityPerpendicular, rather
-- than manually scripted orbit paths for the blade layer) recolored green/yellow-green, with a
-- second layer duped onto a tilted attachment for depth. Leaves are real MeshParts ("Simple Leaf")
-- orbiting on scripted paths with individual tumble + color variety. The release burst reuses
-- Shield-Break-01, recolored to match.
--
-- Params:
--   cf            : CFrame -- where the vortex forms (typically the target's position on hit)
--   physicalModel : Model  -- the target being hit (currently unused -- kept for parity with other
--                            attack VFX)

local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local VortexAssets = game:GetService("ReplicatedStorage").ClientStorage.Effects.Combat.MoveParticles.LeafVortex

local SWIRL_DURATION = 0.85 -- how long the blades spin + leaves orbit before fading out
local RELEASE_DELAY = 0.65 -- when the shockwave burst fires, relative to swirl start
local FADE_DURATION = 0.4

local LEAF_COUNT = 7
local LEAF_MIN_RADIUS = 2.2
local LEAF_MAX_RADIUS = 4.2
local LEAF_ORBIT_SPEED_MIN = 3 -- radians/sec
local LEAF_ORBIT_SPEED_MAX = 5.5
local LEAF_SCALE = 0.35 -- "Simple Leaf" is ~4.7 studs long natively -- shrink to hand-sized

local LEAF_COLORS = {
	Color3.fromRGB(60, 140, 40), -- dark green
	Color3.fromRGB(120, 200, 60), -- light green
	Color3.fromRGB(210, 200, 50), -- yellow
	Color3.fromRGB(190, 70, 40), -- red-orange accent
}

local VORTEX_COLOR_CORE = Color3.fromRGB(220, 255, 140) -- bright yellow-green
local VORTEX_COLOR_EDGE = Color3.fromRGB(60, 200, 70) -- deep green

local function recolorEmitter(e)
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, VORTEX_COLOR_CORE),
		ColorSequenceKeypoint.new(1, VORTEX_COLOR_EDGE),
	})
end

return function(attackParams)
	local cf = attackParams.TargetCFrame
	local physicalModel = attackParams.TargetModel
	coroutine.wrap(function()
		-- === Blade swirl + ground wind + cracks, recolored green ============================
		local slashes = VortexAssets.SlashesBase:Clone()
		slashes.Transparency = 1 -- the reference Part itself is a visible gray block by default
		slashes.CFrame = cf
		slashes.Parent = workspace.PARTICLES

		local mainAtt = slashes:FindFirstChild("Main")
		if mainAtt then
			local slashesEmitter = mainAtt:FindFirstChild("Slashes1")
			if slashesEmitter then recolorEmitter(slashesEmitter) end
		end
		local bottomAtt = slashes:FindFirstChild("Bottom")
		if bottomAtt then
			local windEmitter = bottomAtt:FindFirstChild("Wind1")
			if windEmitter then recolorEmitter(windEmitter) end
		end

		-- A second blade layer on its own tilted attachment (not just a clone on the same
		-- attachment -- that would just double the same ring) -- counter-spinning, for depth.
		local slashesLayer2 = nil
		if mainAtt then
			local main2Att = Instance.new("Attachment")
			main2Att.Name = "Main2"
			main2Att.CFrame = mainAtt.CFrame * CFrame.Angles(math.rad(35), math.rad(20), 0)
			main2Att.Parent = slashes
			mainAtt.Slashes1.Rate = 10
			
			slashesLayer2 = mainAtt.Slashes1:Clone()
			slashesLayer2.RotSpeed = NumberRange.new(-950, -950)
			slashesLayer2.Rate = 15
			recolorEmitter(slashesLayer2)
			slashesLayer2.Parent = main2Att
		end

		-- === Leaves: real MeshParts orbiting on scripted paths ===============================
		local leaves = {}
		for i = 1, LEAF_COUNT do
			local leaf = VortexAssets.LeafMesh:Clone()
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.CanQuery = false
			leaf.CanTouch = false
			leaf.Size = leaf.Size * LEAF_SCALE
			leaf.Color = LEAF_COLORS[((i - 1) % #LEAF_COLORS) + 1]
			leaf.Parent = workspace.PARTICLES
			table.insert(leaves, {
				part = leaf,
				baseSize = leaf.Size,
				radius = LEAF_MIN_RADIUS + math.random() * (LEAF_MAX_RADIUS - LEAF_MIN_RADIUS),
				height = -0.5 + math.random() * 3,
				speed = LEAF_ORBIT_SPEED_MIN + math.random() * (LEAF_ORBIT_SPEED_MAX - LEAF_ORBIT_SPEED_MIN),
				phase = math.random() * math.pi * 2,
				tumbleAxis = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5).Unit,
				tumbleSpeed = 200 + math.random() * 300,
			})
		end

		-- === Drive the leaf orbit and fire the release burst partway through =================
		local elapsed = 0
		local releaseFired = false
		local release = nil
		while elapsed < SWIRL_DURATION do
			local dt = RS.Heartbeat:Wait()
			elapsed = elapsed + dt

			for _, data in ipairs(leaves) do
				local angle = data.phase + elapsed * data.speed
				local bob = math.sin(elapsed * 3 + data.phase) * 0.3
				local pos = cf.Position + Vector3.new(math.cos(angle) * data.radius, data.height + bob, math.sin(angle) * data.radius)
				local tumble = CFrame.fromAxisAngle(data.tumbleAxis, math.rad(data.tumbleSpeed * elapsed))
				data.part.CFrame = CFrame.new(pos) * tumble
			end

			if not releaseFired and elapsed >= RELEASE_DELAY then
				releaseFired = true
				release = VortexAssets.ReleaseBurst:Clone()
				release.Transparency = 1
				release.CanCollide = false
				release.CFrame = cf
				release.Parent = workspace.PARTICLES
				for _, e in ipairs(release.Main:GetChildren()) do
					if e:IsA("ParticleEmitter") then
						recolorEmitter(e)
						e.Enabled = false
						e:Emit(14)
					end
				end
			end
		end

		-- === Fade out: stop the blade/wind emitters, tween leaves down, cleanup ==============
		if mainAtt then
			mainAtt.Slashes1.Enabled = false
		end
		if slashesLayer2 then
			slashesLayer2.Enabled = false
		end
		if bottomAtt then
			bottomAtt.Wind1.Enabled = false
		end

		for _, data in ipairs(leaves) do
			TS:Create(data.part, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Transparency = 1,
				Size = data.baseSize * 0.4,
			}):Play()
		end

		task.wait(FADE_DURATION + 0.6)
		slashes:Destroy()
		for _, data in ipairs(leaves) do
			data.part:Destroy()
		end
		if release then
			release:Destroy()
		end
	end)()
end
