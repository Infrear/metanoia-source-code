--[=[

WindShake- High performance wind effect for leaves and foliage
by: boatbomber, CloneTrooper1019

Docs: https://devforum.roblox.com/t/wind-shake-high-performance-wind-effect-for-leaves-and-foliage/1039806/1

--]=]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Settings = require(script.Settings)
local Octree = require(script.Octree)

local SHAKE_AMOUNT = 0.35
local COLLECTION_TAG = "WindShake" -- The CollectionService tag to be watched and mounted automatically

-- Use the script's attributes as the default settings.
-- The table provided is a fallback if the attributes
-- are undefined or using the wrong value types.

local DEFAULT_SETTINGS = Settings.new(script, {
	WindDirection = Vector3.new(0.5, 0, 0.5),
	WindSpeed = 20,
	WindPower = 0.5,
})

-----------------------------------------------------------------------------------------------------------------

local curamp = {}
local ObjectShakeAddedEvent = Instance.new("BindableEvent")
local ObjectShakeRemovedEvent = Instance.new("BindableEvent")
local ObjectShakeUpdatedEvent = Instance.new("BindableEvent")
local PausedEvent = Instance.new("BindableEvent")
local ResumedEvent = Instance.new("BindableEvent")

local WindShake = {
	UpdateHz = 1 / 45,
	ComputeHz = 1 / 30,
	Radius = 120,

	ObjectMetadata = {},
	Octree = Octree.new(),

	Handled = 0,
	Active = 0,
	LastUpdate = os.clock(),

	ObjectShakeAdded = ObjectShakeAddedEvent.Event,
	ObjectShakeRemoved = ObjectShakeRemovedEvent.Event,
	ObjectShakeUpdated = ObjectShakeUpdatedEvent.Event,
	Paused = PausedEvent.Event,
	Resumed = ResumedEvent.Event,
}

export type WindShakeSettings = {
	WindDirection: Vector3?,
	WindSpeed: number?,
	WindPower: number?,
}

function WindShake:Connect(funcName: string, event: RBXScriptSignal): RBXScriptConnection
	local callback = self[funcName]
	assert(typeof(callback) == "function", "Unknown function: " .. funcName)

	return event:Connect(function(...)
		return callback(self, ...)
	end)
end

function WindShake:AddObjectShake(object: BasePart, settingsTable: WindShakeSettings?)
	if typeof(object) ~= "Instance" then
		return
	end

	if not object:IsA("BasePart") then
		return
	end

	local metadata = self.ObjectMetadata

	if metadata[object] then
		return
	else
		self.Handled += 1
	end

	metadata[object] = {
		Node = self.Octree:CreateNode(object.Position, object),
		Settings = Settings.new(object, DEFAULT_SETTINGS),

		Seed = math.random(1000) * 0.1,
		Origin = object.CFrame,
	}

	if settingsTable then
		self:UpdateObjectSettings(object, settingsTable)
	end

	ObjectShakeAddedEvent:Fire(object)
end

function WindShake:RemoveObjectShake(object: BasePart)
	if typeof(object) ~= "Instance" then
		return
	end

	local metadata = self.ObjectMetadata
	local objMeta = metadata[object]

	if objMeta then
		self.Handled -= 1
		metadata[object] = nil
		objMeta.Settings:Destroy()
		objMeta.Node:Destroy()

		if object:IsA("BasePart") then
			object.CFrame = objMeta.Origin
		end
	end

	ObjectShakeRemovedEvent:Fire(object)
end

function WindShake:Update()
	local now = os.clock()
	local dt = now - self.LastUpdate

	if dt < self.UpdateHz then
		return
	end

	self.LastUpdate = now

	debug.profilebegin("WindShake")

	local camera = workspace.CurrentCamera
	local cameraCF = camera and camera.CFrame

	debug.profilebegin("Octree Search")
	local updateObjects =
		self.Octree:RadiusSearch(cameraCF.Position + (cameraCF.LookVector * (self.Radius * 0.95)), self.Radius)
	debug.profileend()

	local activeCount = #updateObjects

	self.Active = activeCount

	if activeCount < 1 then
		return
	end

	local step = math.min(1, dt * 8)
	local cfTable = table.create(activeCount)
	local objectMetadata = self.ObjectMetadata

	debug.profilebegin("Calc")
	--print(updateObjects)
	for i, object in ipairs(updateObjects) do
		--print(object:GetAttribute("Harvested"))
		if object:GetAttribute("Harvested") or object.Parent:GetAttribute("Harvested") then 
			--table.remove(updateObjects, table.find(updateObjects, object))
			updateObjects[i] = nil
			continue 
		end
		local objMeta = objectMetadata[object]
		local lastComp = objMeta.LastCompute or 0

		local origin = objMeta.Origin
		local current = objMeta.CFrame or origin

		if (now - lastComp) > self.ComputeHz then
			local objSettings = objMeta.Settings

			local seed = objMeta.Seed
			
			coroutine.wrap(function()
				if not object:GetAttribute("isFoilage") then
					if not object:GetAttribute("InEffect") then
						if curamp[object] then
							curamp[object] = math.clamp(curamp[object] - 0.1, objSettings.WindPower * SHAKE_AMOUNT, math.huge)
						else
							curamp[object] = objSettings.WindPower * SHAKE_AMOUNT
						end
					else
						--print(amp)
						curamp[object] = objSettings.WindPower * 1.25
					end
				else
					if not object:GetAttribute("InEffect") then
						if curamp[object] then
							curamp[object] = math.clamp(curamp[object] - 0.1, objSettings.WindPower * (SHAKE_AMOUNT*2), math.huge)
						else
							curamp[object] = objSettings.WindPower * (SHAKE_AMOUNT*2)
						end
					else
						--print(amp)
						curamp[object] = objSettings.WindPower * (1.25 * 1.4)
						--print(object)
					end
				end
			end)()
			
			local amp = curamp[object]
				

			local freq = now * (objSettings.WindSpeed * 0.08)
			local rotX = math.noise(freq, 0, seed) * amp
			local rotY = math.noise(freq, 0, -seed) * amp
			local rotZ = math.noise(freq, 0, seed + seed) * amp
			local offset = object.PivotOffset
			local worldpivot = origin * offset

			objMeta.Target = (
				worldpivot * CFrame.Angles(rotX, rotY, rotZ)
				+ objSettings.WindDirection * ((0.5 + math.noise(freq, seed, seed)) * amp)
			) * offset:Inverse()

			objMeta.LastCompute = now
		end

		current = current:Lerp(objMeta.Target, step)
		objMeta.CFrame = current
		cfTable[i] = current
	end
	debug.profileend()

	workspace:BulkMoveTo(updateObjects, cfTable, Enum.BulkMoveMode.FireCFrameChanged)
	debug.profileend()
end

function WindShake:Pause()
	if self.UpdateConnection then
		self.UpdateConnection:Disconnect()
		self.UpdateConnection = nil
	end

	self.Active = 0
	self.Running = false

	PausedEvent:Fire()
end

function WindShake:Resume()
	if self.Running then
		return
	else
		self.Running = true
	end

	-- Connect updater
	self.UpdateConnection = self:Connect("Update", RunService.Heartbeat)

	ResumedEvent:Fire()
end

function WindShake:Init()
	if self.Initialized then
		return
	else
		self.Initialized = true
	end

	-- Define attributes if they're undefined.
	local power = script:GetAttribute("WindPower")
	local speed = script:GetAttribute("WindSpeed")
	local direction = script:GetAttribute("WindDirection")

	if typeof(power) ~= "number" then
		script:SetAttribute("WindPower", DEFAULT_SETTINGS.WindPower)
	end

	if typeof(speed) ~= "number" then
		script:SetAttribute("WindSpeed", DEFAULT_SETTINGS.WindSpeed)
	end

	if typeof(direction) ~= "Vector3" then
		script:SetAttribute("WindDirection", DEFAULT_SETTINGS.WindDirection)
	end

	-- Clear any old stuff.
	self:Cleanup()

	-- Wire up tag listeners.
	local windShakeAdded = CollectionService:GetInstanceAddedSignal(COLLECTION_TAG)
	self.AddedConnection = self:Connect("AddObjectShake", windShakeAdded)

	local windShakeRemoved = CollectionService:GetInstanceRemovedSignal(COLLECTION_TAG)
	self.RemovedConnection = self:Connect("RemoveObjectShake", windShakeRemoved)

	for _, object in pairs(CollectionService:GetTagged(COLLECTION_TAG)) do
		self:AddObjectShake(object)
	end

	-- Automatically start.
	self:Resume()
end

function WindShake:Cleanup()
	if not self.Initialized then
		return
	end

	self:Pause()

	if self.AddedConnection then
		self.AddedConnection:Disconnect()
		self.AddedConnection = nil
	end

	if self.RemovedConnection then
		self.RemovedConnection:Disconnect()
		self.RemovedConnection = nil
	end

	table.clear(self.ObjectMetadata)
	self.Octree:ClearNodes()

	self.Handled = 0
	self.Active = 0
	self.Initialized = false
end

function WindShake:UpdateObjectSettings(object: Instance, settingsTable: WindShakeSettings)
	if typeof(object) ~= "Instance" then
		return
	end

	if typeof(settingsTable) ~= "table" then
		return
	end

	if not self.ObjectMetadata[object] and (object ~= script) then
		return
	end

	for key, value in pairs(settingsTable) do
		object:SetAttribute(key, value)
	end

	ObjectShakeUpdatedEvent:Fire(object)
end

function WindShake:UpdateAllObjectSettings(settingsTable: WindShakeSettings)
	if typeof(settingsTable) ~= "table" then
		return
	end

	for obj, objMeta in pairs(self.ObjectMetadata) do
		for key, value in pairs(settingsTable) do
			obj:SetAttribute(key, value)
		end
		ObjectShakeUpdatedEvent:Fire(obj)
	end
end

function WindShake:SetDefaultSettings(settingsTable: WindShakeSettings)
	self:UpdateObjectSettings(script, settingsTable)
end

--if workspace:FindFirstChild("RESOURCES") then
--	local t1, t2 = workspace["RESOURCES"].trees:GetChildren(), workspace["RESOURCES"].bushes:GetChildren()

--	table.move(t2, 1, #t2, #t1 + 1, t1)

--	local treesInRadius = {}
--	local maxDist = 250
--	local plr = game.Players.LocalPlayer
--	local canCheck = true

--	RunService.RenderStepped:Connect(function()
--		if not canCheck then return end
--		canCheck = false
--		for i, v in pairs(t1) do
--			if plr:DistanceFromCharacter(v:GetPivot().Position) > maxDist or table.find(treesInRadius, v) then
--				if plr:DistanceFromCharacter(v:GetPivot().Position) > maxDist and table.find(treesInRadius, v) then
--					table.remove(treesInRadius, table.find(treesInRadius, v))
--				end
--				continue 
--			end
--			if v:IsA("BasePart") then
--				CollectionService:AddTag(v, COLLECTION_TAG)
--			elseif v:IsA("Model") then
--				for i, v in pairs(v:GetChildren()) do
--					if v:IsA("BasePart") then 
--						CollectionService:AddTag(v, COLLECTION_TAG) 
--					elseif v:IsA("Model") then
--						for i, v in pairs(v:GetChildren()) do
--							if v:IsA("BasePart") then CollectionService:AddTag(v, COLLECTION_TAG) end
--						end
--					end
--				end
--			end
--			table.insert(treesInRadius, v)
--		end
--		canCheck = true
--	end)
--end
wait(5)
repeat wait() until game:IsLoaded()
if workspace:FindFirstChild("RESOURCES") then
	local TS = game:GetService("TweenService")
	
	local TES = {}
	local TI = TweenInfo.new(
		0.75,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local Storage = game:GetService("ReplicatedStorage"):WaitForChild("ClientStorage")
	
	local function bindBush(bush, foilage)
		bush:SetAttribute("StarterOrientation", bush.Orientation)
		coroutine.wrap(function()
			task.wait(2.5)
			bush.Touched:Connect(function(hit)
				if bush:GetAttribute("InEffect") or not hit.CanCollide then return end
				bush:SetAttribute("InEffect", true)
				if not foilage then
					--coroutine.wrap(function()
					--	local clone = Storage.Sounds.Environment.Leafs.Rustle1:Clone()
					--	clone.Parent = bush

					--	clone.Volume = 1
					--	--clone.TimePosition = 20
					--	clone:Play()

					--	task.wait(clone.TimeLength + 5)
					--	clone:Destroy()
					--end)()
				end
				task.wait(0.5)
				bush:SetAttribute("InEffect", false)
				--local rand = math.random(1, 2)
				--print("ran")

				--if TES[bush] then
				--	if TES[bush][1] then
				--		if TES[bush].PlaybackState == Enum.PlaybackState.Playing then
				--			TES[bush]:Cancel()
				--		end
				--	end
				--else
				--	TES[bush] = {}
				--end
				--TES[bush][2] = Instance.new("BindableEvent", bush)

				--local canContinue = true

				--local min, max = 8, 15
				--local val = math.random(min, max)
				--local or1, or2 = nil, nil
				--if rand == 1 then
				--	or1 = Vector3.new(bush:GetAttribute("StarterOrientation").X, bush:GetAttribute("StarterOrientation").Y, bush:GetAttribute("StarterOrientation").Z + val)
				--	or2 = Vector3.new(bush:GetAttribute("StarterOrientation").X, bush:GetAttribute("StarterOrientation").Y, bush:GetAttribute("StarterOrientation").Z - val)
				--else
				--	or1 = Vector3.new(bush:GetAttribute("StarterOrientation").X + val, bush:GetAttribute("StarterOrientation").Y, bush:GetAttribute("StarterOrientation").Z)		
				--	or2 = Vector3.new(bush:GetAttribute("StarterOrientation").X - val, bush:GetAttribute("StarterOrientation").Y, bush:GetAttribute("StarterOrientation").Z)					
				--end
				--print("ran1")
				--TES[bush][1] = TS:Create(bush, TI, {Orientation = or1})
				--TES[bush][1]:Play()
				--local con
				--con = TES[bush][2].Event:Connect(function()
				--	con:Disconnect()
				--	canContinue = false
				--	if TES[bush][2] then
				--		TES[bush][2]:Destroy()
				--	end
				--end)
				--TES[bush][1].Completed:Wait()
				--if not canContinue then return end
				--if TES[bush][2] then
				--	TES[bush][2]:Destroy()
				--end
				--print("ran2")
				--con:Disconnect()
				--TES[bush][1] = TS:Create(bush, TI, {Orientation = or1})
				--TES[bush][1]:Play()
				--bush:SetAttribute("InEffect", false)
			end)
		end)()
	end
	
	local t1, t2, t3 = workspace["RESOURCES"].trees:GetChildren(), workspace["RESOURCES"].bushes:GetChildren(), workspace["RESOURCES"].flowers:GetChildren()

	table.move(t2, 1, #t2, #t1 + 1, t1)
	table.move(t3, 1, #t3, #t1 + 1, t1)
	
	--print(t1)
	for i, v in ipairs(t1) do
		--print(v)
		if v:IsA("BasePart") then
			CollectionService:AddTag(v, COLLECTION_TAG)
			if v.Name == "bush" and v:IsDescendantOf(workspace["RESOURCES"].bushes) then
				bindBush(v)
			end
		elseif v:IsA("Model") then
			for i, v in pairs(v:GetDescendants()) do
				if v:IsA("BasePart") then 
					if (v.Name == "Leaves") and v:IsDescendantOf(workspace["RESOURCES"].trees) then
						bindBush(v)
						CollectionService:AddTag(v, COLLECTION_TAG) 
					elseif v.Name == "bush" and v:IsDescendantOf(workspace["RESOURCES"].bushes) then
						bindBush(v)
						CollectionService:AddTag(v, COLLECTION_TAG) 
					elseif v.Name == "foilage" and (v:IsDescendantOf(workspace["RESOURCES"].flowers)) then
						v:SetAttribute("isFoilage", true)
						bindBush(v, true)
						CollectionService:AddTag(v, COLLECTION_TAG) 
					end
				--elseif v:IsA("Model") then
				--	for i, v in pairs(v:GetChildren()) do
				--		if v:IsA("BasePart") then CollectionService:AddTag(v, COLLECTION_TAG) end
				--	end
				end
			end
		end
	end
end

return WindShake
