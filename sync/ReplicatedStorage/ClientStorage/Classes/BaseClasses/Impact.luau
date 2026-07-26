-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")
local DBRS = game:GetService("Debris")

-- Constants

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

local Invisipart = Importer:ImportScript(Storage.Classes.BaseClasses.Invisipart)

local ImpactStorage = Instance.new("Folder", workspace)
ImpactStorage.Name = "ImpactStorage"

-- Initialization
local Impact = {}
Impact.__index = Impact

-- Private Functions
local function generateFloat(imp, pt, cf, dir, hum)
	
	-- find and create attatchments
	local at1 = Instance.new("Attachment", pt)
	at1.Name = "ImpactAt1"

	-- create diff types of impacts
	local v
	if imp.Type == "Linear" then
		--print("new lin")
		v = Instance.new("LinearVelocity")
		v.Name = "ImpactV"
		table.insert(imp.CoreObjects.Velocities, v)
		
		v.Attachment0 = at1
		--v.Attachment1 = at0
		-- Switch to World space to avoid orientation conflicts
		v.RelativeTo = Enum.ActuatorRelativeTo.World --Enum.ActuatorRelativeTo.Attachment1
		
		
		-- Avoid math.huge on characters; use a high finite number
		-- 100,000 is usually enough to move a character reliably
		v.MaxForce = 100000 --math.huge
		
		--task.wait(3)
		-- Ensure the direction is a World vector
		-- If 'dir' is intended to be relative to the attacker, 
		-- calculate it as: cf.VectorToWorldSpace(dir)
		v.VectorVelocity = dir * imp.Speed * 50 --1 -- Adjust multiplier as needed
		
		v.Parent = pt
		
		--task.wait(imp.Duration)
		----task.wait(10)
		--v:Destroy()
		--at1:Destroy()
		
		task.delay(imp.Duration, function()
			if v and v.Parent then v:Destroy() end
			if at1 and at1.Parent then at1:Destroy() end
		end)
	end

	-- setup tweens
	--local calcSpeed = 10 / imp.Speed
	--local TI = TweenInfo.new(
	--	calcSpeed,
	--	Enum.EasingStyle.Linear,
	--	Enum.EasingDirection.In
	--)

	--coroutine.wrap(function()
	--	local stopped = false
	--	local con
	--	con = TE.Completed:Connect(function()
	--		con:Disconnect()
	--		v.VectorVelocity = Vector3.zero
	--		v:Destroy()
	--		at1:Destroy()
	--		imp.PlaybackState = TE.PlaybackState
	--		stopped = true
	--	end)

	--	if stopped then return end

	--	task.wait(calcSpeed + 5)

	--	con:Disconnect()
	--	TE:Cancel()
	--	imp.PlaybackState = TE.PlaybackState
	--end)()
	
	---- wait some
	--task.wait(math.clamp((imp.Duration - (calcSpeed*2)), 0, math.huge))

	---- closing tween
	--local TE2 = TS:Create(v, TI, {VectorVelocity = Vector3.zero})
	--TE2:Play()
	--imp.Wait = TE2.Completed
	--imp.PlaybackState = TE2.PlaybackState
	--imp.TBase = imp.TBase
	
	--coroutine.wrap(function()
	--	if hum then
	--		local mag = (cf.Position - pt.Position).Magnitude
	--		hum:TakeDamage(imp.Damage / ((mag * imp.Strength) / 5))
	--	end
	--	local stopped = false
	--	local con 
	--	con = TE.Completed:Connect(function()
	--		con:Disconnect()
	--		v.VectorVelocity = Vector3.zero
	--		v:Destroy()
	--		at1:Destroy()
	--		imp.PlaybackState = TE.PlaybackState
	--		stopped = true
	--	end)

	--	if stopped then return end

	--	task.wait(calcSpeed + 5)

	--	con:Disconnect()
	--	TE2:Cancel()
	--	v.VectorVelocity = Vector3.zero
	--	v:Destroy()
	--	at1:Destroy()
	--	imp.PlaybackState = TE.PlaybackState
	--end)()
	imp.CoreEvent:Fire()
end

local function generateLock(imp, pt, cf, dir, hum)	
	-- find and create attatchments
	local at0, at1 = imp.detectPart:FindFirstChild("ImpactAt0"), Instance.new("Attachment", pt)
	at1.Name = "ImpactAt1"

	-- create diff types of impacts
	local v1, v2
	if imp.Type == "LinearLock" then
		--print("did shi")
		--print("new lin")
		v1, v2 = Instance.new("AlignPosition"), Instance.new("AlignOrientation")
		v1.Name, v2.Name = "ImpactV", "ImpactV"
		v1.Responsiveness, v2.Responsiveness = 10 * imp.Speed, 10 * imp.Speed 
		table.insert(imp.CoreObjects.Velocities, v1)
		table.insert(imp.CoreObjects.Velocities, v2)
		v1.Attachment0, v2.Attachment0 = at1, at1
		--v1.Attachment1, v2.Attachment1 = at0, at0
		

		v1.MaxVelocity, v2.MaxTorque = math.huge, math.huge
		v1.MaxForce, v2.MaxAngularVelocity = math.huge, math.huge
		v1.Mode, v2.Mode = Enum.PositionAlignmentMode.OneAttachment, Enum.OrientationAlignmentMode.OneAttachment
		--task.wait(3)
		v1.Position, v2.CFrame = dir.Position, (dir - dir.Position)
		v1.Parent, v2.Parent = pt, pt

		task.wait(imp.Duration)
		--task.wait(10)
		v1:Destroy() v2:Destroy()
		at1:Destroy()
	end
	
	imp.CoreEvent:Fire()
end

local function generateHit(imp, pt, cf, dir, hum)
	local dire = nil
	if dir then
		dire = (cf.LookVector * dir.Z) + (cf.UpVector * dir.Y)
		--dire = imp.detectPart.CFrame.LookVector * 50 + Vector3.new(0, 10, 0)
		--dire = ()
	end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "ImpactV"
	table.insert(imp.CoreObjects.Velocities, bv)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity = dire or cf.CFrame:ToObjectSpace(imp.Range).Position * imp.Range
	bv.Parent = pt
	--print(bv.Velocity)
	game:GetService("Debris"):AddItem(bv, 0.1)
	imp.CoreEvent:Fire()
end

-- Public Functions
function Impact.new(Damage, Range, Strength, CF, Type, Whitelist) -- constructor function.
	local MT = setmetatable({
		Type = Type or "Knockbck"; -- Knockback, Linear, and Rotational
		Damage = Damage or 0;
		Range = Range or 10;
		Strength = Strength or 5; 
		Whitelist = Whitelist or nil;
		CoreEvent = Instance.new("BindableEvent");
		CoreObjects = {};
		detectPart = nil;
		Finished = Instance.new("BindableEvent").Event;
		Speed = 1;
		Duration = 1;
	}, Impact)
	-- setup velocity objects holder
	MT.CoreObjects.Velocities = {}
	
	-- create an inivisible part
	MT.detectPart = Invisipart.new(Range, Range, Range, workspace)
	MT.detectPart.CFrame = CF
	MT.detectPart.Parent = workspace
	MT.CoreObjects.DetectPart = MT.detectPart
	
	local at = Instance.new("Attachment", MT.detectPart)
	at.Name = "ImpactAt0"
	
	MT.CoreObjects.Attachment = at
	return MT
end

function Impact:Explode(Speed, Duration, Direction, CF, Override) -- explode method
	self.detectPart.CFrame = CF
	local con = self.detectPart.Touched:Connect(function() end)

	self.Wait = nil
	self.Playing = nil

	local humtab = {}
	for i, v in pairs(self.detectPart:GetTouchingParts()) do
		coroutine.wrap(function()
			local hum = v.Parent:FindFirstChildOfClass("Humanoid")
			if self.Whitelist == "Players" then
				if not PLRS:GetPlayerFromCharacter(v.Parent) then return end
			elseif self.Whitelist == "Living" then
				if not hum then return end
			elseif self.Whitelist ~= nil then
				if not table.find(self.Whitelist, v) then return end
			end
			if hum then
				if table.find(humtab, hum) then return end
			end
			con:Disconnect()
			if hum then
				table.insert(humtab, hum)
				v = v:FindFirstChild("ImpactPart") or v.Parent.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v
			end
			self.Speed = Speed or self.Speed
			self.Duration = Duration or self.Duration
			if Override then
				for i, v in pairs(v:GetChildren()) do
					if v.Name == "ImpactV" then
						v:Destroy()
					end
				end
			end
			if self.Type == "Linear" or self.Type == "Rotational" then
				generateFloat(self, v, CF, Direction, hum)
			elseif self.Type == "LinearLock" then
				generateLock(self, v, CF, Direction, hum)
			elseif self.Type == "Knockback" then
				generateHit(self, v, CF, Direction, hum)
			end
		end)()
	end

	--if self.Wait and self.PlaybackState == Enum.PlaybackState.Playing then
	--	self.Wait:Wait()
	--end
end

function Impact:Destroy() -- cleanup method
	if self.CoreEvent then
		self.CoreEvent:Destroy()
	end
	if self.CoreObjects then
		for i, v in pairs(self.CoreObjects) do
			if typeof(v) == "Instance" then
				v:Destroy()
			else
				for i2, v2 in pairs(v) do
					if typeof(v) == "Instance" then
						v2:Destroy()
					end
				end
			end
		end
	end
	self = nil
end

return Impact