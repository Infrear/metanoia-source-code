local rps = game:GetService("ReplicatedStorage")
local rs = game:GetService("RunService")

local storage = rps:WaitForChild("ClientStorage")
local effects = storage:WaitForChild("Effects")
	
--declaring the variables needed
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
--parts needed for the effect
local lfoot = character:WaitForChild("LeftFoot")
local rfoot = character:WaitForChild("RightFoot")
--getting the particle effects
local cpart1, cpart2 = Instance.new("Part"), Instance.new("Part")
cpart1.Anchored = true
cpart2.Anchored = true
cpart1.Parent = workspace.PARTICLES
cpart2.Parent = workspace.PARTICLES
cpart1.Size = Vector3.new(0.1,0.1,0.1)
cpart2.Size = Vector3.new(0.1,0.1,0.1)
--making the particles not visible
cpart1.Transparency = 1
cpart2.Transparency = 1
cpart1.CanCollide = false
cpart2.CanCollide = false

local con = nil
local lastTick = tick()

local ef1 = effects.Environment.Earth.RippleWalk.Attachment2:Clone()
ef1.Parent = cpart1
local ef3 = effects.Environment.Earth.RippleWalk.Attachment2:Clone()
ef3.Parent = cpart2

--checking if the humanoid is running 
humanoid.Running:Connect(function(speed)
	if speed > 5 then
		if con then con:Disconnect() end
		lastTick = tick()
		con = rs.RenderStepped:Connect(function()
			if (tick() - lastTick) >= 0.1 then
				--if humanoid and humanoid.Parent and humanoid:GetState() == Enum.HumanoidStateType.Running and humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air and humanoid.FloorMaterial ~= Enum.Material.Water then
				local p1, p2 = rfoot.Position, lfoot.Position
				task.wait(0.1)
				cpart1.Position = p1
				cpart2.Position = p2
				--end
				lastTick = tick()
			end
		end)
		ef1.Ripple2.Enabled  = true
		ef3.Ripple2.Enabled  = true

	else
		if con then con:Disconnect() end
		ef1.Ripple2.Enabled  = false
		ef3.Ripple2.Enabled  = false

	end
end)

--we disable the effect if the user is jumping
humanoid.Jumping:Connect(function(isjumping)
	if isjumping then
		if con then con:Disconnect() end
		ef1.Ripple2.Enabled  = false
		ef3.Ripple2.Enabled  = false
	end
end)
