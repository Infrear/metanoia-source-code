-- Guard VFX module. Called once when a fighter guards. Sample/placeholder effect (a quick shield
-- flash using safe built-in primitives) until a real asset gets dropped in here -- swap this out, or
-- add more named modules alongside it later if different personas/characters want different guard FX
-- (same lookup-by-name pattern as SummonVFX, just not built out yet since there's only one for now).
--
-- Params:
--   fighterInstance : Model  -- the guarding fighter's rig
return function(fighterInstance)
	local TS = game:GetService("TweenService")

	local root = fighterInstance:FindFirstChild("HumanoidRootPart") or fighterInstance.PrimaryPart
	if not root then return end

	local size = fighterInstance:GetExtentsSize()
	local diameter = math.max(size.X, size.Z) * 1.6

	-- Expanding shield ring
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.ForceField
	ring.Color = Color3.fromRGB(120, 180, 255)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(0.2, diameter * 0.3, diameter * 0.3)
	ring.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.1
	ring.Parent = workspace.PARTICLES

	TS:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, diameter, diameter),
		Transparency = 1,
	}):Play()

	-- Quick blue flash light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(140, 190, 255)
	light.Range = diameter * 1.5
	light.Brightness = 4
	light.Parent = ring
	TS:Create(light, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = 0}):Play()

	task.delay(0.5, function()
		ring:Destroy()
	end)
end
