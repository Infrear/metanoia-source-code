local Module = {}
local RE = game:GetService("ReplicatedStorage"):WaitForChild("ClientStorage"):WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("Physics")
local PS = game:GetService("PhysicsService")

Module.Check = function(t)
	for _,v in pairs({"LeftWrist","RightWrist","LeftAnkle","RightAnkle", "Grip", "Grasp"}) do
		if v == t then return false end
	end
	return true
end

Module.Ragdoll = function(char,bool)
	return
	--local plr = game.Players:GetPlayerFromCharacter(char)
	--if char.Humanoid.Health~=0 and ((char:FindFirstChild'LowerTorso'and not char.LowerTorso.Root.Enabled)or (char:FindFirstChild'Torso'and not char.Torso.Neck.Enabled)) and not bool then
	--	RE:FireClient(plr,false)
	--	for _,v in pairs(char:GetDescendants()) do
	--		if v:IsA'Motor6D' and v.Name ~= "Grip" and v.Name ~= "Grasp" then
	--			v.Enabled = true
	--		elseif v:IsA'BallSocketConstraint' then
	--			v.Enabled = false
	--		end
	--	end
	--else
	--	RE:FireClient(plr,true)
	--	for _,v in pairs(char:GetDescendants()) do
	--		if v:IsA'Motor6D'and Module.Check(v.Name)then
	--			v.Enabled = false
	--		elseif v:IsA'BallSocketConstraint' then
	--			v.Enabled = true
	--		elseif v.Name=="Head"then
	--			local b = Instance.new("BodyVelocity",char.Head)
	--			b.Velocity = Vector3.new(math.random(-10,10),0,math.random(-10,10))
	--			task.spawn(function()
	--				wait(.1)
	--				b:Destroy()
	--			end)
	--		end
	--	end
	--end
end

Module.Bot = function(bot)
	task.spawn(function()
		local H = bot.Humanoid
		bot.HumanoidRootPart:SetNetworkOwner(nil)
		if bot:FindFirstChild'HumanoidRootPart'and H.Health~=0 and bot:FindFirstChild'LowerTorso' and bot.LowerTorso.Root.Enabled==true then
			H:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
			H:ChangeState(Enum.HumanoidStateType.Ragdoll)
			for _,v in pairs(H:GetPlayingAnimationTracks())do v:Stop(0)end
			bot.Animate.Disabled = true
			
			for _,v in pairs(bot:GetDescendants()) do
				if v:IsA'Motor6D'and Module.Check(v.Name) then
					v.Enabled = false
				elseif v:IsA'BallSocketConstraint' then
					v.Enabled = true
				end
			end
			wait(10)

			bot.Animate.Disabled = false
			H:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
			H:ChangeState(Enum.HumanoidStateType.GettingUp)

			for _,v in pairs(bot:GetDescendants()) do
				if v:IsA'Motor6D' then
					v.Enabled = true
				elseif v:IsA'BallSocketConstraint' then
					v.Enabled = false
				end
			end
		end
	end)
end

Module.Joints = function(c)
	return
	--c.Humanoid.BreakJointsOnDeath = false
	--c.Humanoid.RequiresNeck = false
	--for _,v in pairs(c:GetDescendants()) do
	--	if v:IsA("Motor6D")and Module.Check(v.Name)then
	--		local b = Instance.new("BallSocketConstraint",v.Parent)
	--		local a0,a1 = Instance.new("Attachment"),Instance.new("Attachment")
	--		a0.Parent,a1.Parent = v.Part0,v.Part1
	--		b.Attachment0,b.Attachment1 = a0,a1
	--		a0.CFrame,a1.CFrame = v.c0,v.c1
	--		b.LimitsEnabled = true
	--		b.TwistLimitsEnabled = true
	--		b.Enabled = false
	--	elseif v:IsA'BasePart' then
	--		PS:SetPartCollisionGroup(v,"A")
	--		if v.Name == "HumanoidRootPart" then
	--			PS:SetPartCollisionGroup(v,"B")
	--		elseif v.Name=="Head"then
	--			v.CanCollide = true
	--		end
	--	end
	--end
end

return Module

