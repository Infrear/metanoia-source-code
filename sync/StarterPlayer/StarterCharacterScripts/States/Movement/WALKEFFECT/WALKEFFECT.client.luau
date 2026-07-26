local rps = game:GetService("ReplicatedStorage")

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
local ef1 = effects.Environment.Earth.DustWalk.ef:Clone()
ef1.Enabled = false
ef1.Parent = rfoot
local ef3 = effects.Environment.Earth.DustWalk.ef:Clone()
ef3.Enabled = false
ef3.Parent = lfoot

--checking if the humanoid is running 
humanoid.Running:Connect(function(speed)
	if speed > 17.2 then
		ef1.Enabled  = true
		ef3.Enabled  = true
		
		--print(speed)
	else
		ef1.Enabled  = false
		ef3.Enabled  = false
		
	end
end)

--we disable the effect if the user is jumping
humanoid.Jumping:Connect(function(isjumping)
	if isjumping then
		ef1.Enabled  = false
		ef3.Enabled  = false
	end
end)
