-- ============================================================
-- CloudDropOnStep (LocalScript — separate child of StarterCharacterScripts)
-- When the player steps onto a Dream World cloud platform, the
-- platform gently dips downward. When they leave, it seamlessly
-- blends back into its passive floating routine without an explicit upward tween.
-- Automatically carries any objects linked inside FloatDescendants folders.
-- ============================================================

-- Services
local RS   = game:GetService("RunService")
local TS   = game:GetService("TweenService")
local PLRS = game:GetService("Players")
local RPS  = game:GetService("ReplicatedStorage")

-- Dependencies
local plr  = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
local hrp  = char:WaitForChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

plr.CharacterAdded:Connect(function(newChar)
	char = newChar
	hum  = newChar:WaitForChild("Humanoid")
	hrp  = newChar:WaitForChild("HumanoidRootPart")
end)

local DreamWorld = require(plr.PlayerGui:WaitForChild("ClientUIMain"):WaitForChild("Regions"):WaitForChild("DreamWorld"))

-- -- Effects reference -----------------------------------------
local Storage   = RPS:WaitForChild("ClientStorage")
local stepFxSrc = Storage:FindFirstChild("Effects")
	and Storage.Effects:FindFirstChild("Environment"):FindFirstChild("Environment")
	and Storage.Effects:FindFirstChild("Environment"):FindFirstChild("DreamWorld")
	and Storage.Effects:FindFirstChild("Environment").DreamWorld:FindFirstChild("CloudEmit")
local CameraShaker = require(Storage.Classes.BaseClasses.CameraShaker)
local floatables = workspace:WaitForChild("RESOURCES"):WaitForChild("dreamworld"):WaitForChild("floatables")

-- -- Tuning ---------------------------------------------------
local DIP_AMOUNT    = 3     -- studs
local DIP_TIME      = 3.5   -- fast dip
local CHECK_RATE    = 0.05  -- poll every 50ms
local DEBOUNCE_TIME = 0.5   -- Minimum seconds a cloud stays down/waits before springback
local CLOUD_MARKER = false

-- Drift Tuning (Continuous floating)
local DRIFT_HEIGHT  = 5     -- How many studs up/down it floats passively
local DRIFT_SPEED   = 1     -- How fast it moves up and down

local TI_DIP    = TweenInfo.new(DIP_TIME,    Enum.EasingStyle.Elastic,        Enum.EasingDirection.Out)

-- -- State ----------------------------------------------------
local activePlatform = nil   -- the platform currently being stood on
local lastPlatform   = nil
local activeTES = {}         -- [Instance] = Tween
local leaveTimestamps = {}   -- [Instance] = os.clock() time when left
local cons = {}

-- Track unique phase offsets for each cloud so they don't move perfectly in sync
local cloudSeeds = {} 

-- -- Cutscene cloud-binding tuning ------------------------------
local RETURN_TIME = 1 -- seconds to ease the cloud back to its resting Y before binding
local TI_RETURN = TweenInfo.new(RETURN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local inCutscene = false
local boundProps = {} -- [prop] = {cloud = <part/model>, follow = <RBXScriptConnection>, returnTween = <Tween>}

-- Track unique structural blocks or elements to float with each step/cloud
local floatDescendantOffsets = {} -- [cloud/step] = { {instance = object, offset = offsetY}, ... }

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(CF)
	cam.CFrame = cam.CFrame * CF
end)
CamShake:Start()

-- -- Particle puff helper -------------------------------------
local function emitStepPuff(position)
	if not stepFxSrc then return end
	local clone = stepFxSrc:Clone()
	clone.Parent = workspace

	if clone:IsA("ParticleEmitter") then
		local att = Instance.new("Attachment")
		att.WorldPosition = position
		att.Parent = workspace.Terrain
		clone.Parent = att
		clone:Emit(12)
		task.delay(2, function() att:Destroy() end)
	else
		local anchor = Instance.new("Part")
		anchor.Anchored     = true
		anchor.CanCollide   = false
		anchor.Transparency = 1
		anchor.Size          = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position     = position
		anchor.Parent       = workspace
		clone.Parent        = anchor
		for _, fx in ipairs(clone:GetDescendants()) do
			if fx:IsA("ParticleEmitter") then fx:Emit(12) end
		end
		task.delay(2, function() anchor:Destroy() end)
	end
end

-- Helper to find the base part or model primary part to extract height data from
local function getTargetPart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then
		return instance
	elseif instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildOfClass("BasePart")
	end
	return nil
end

-- ── Sync Float Descendants ──────────────────────────────────
local function updateFloatDescendants(platform, currentY)
	-- Automatically map the descendants folder if it exists and hasn't been scanned yet
	if not floatDescendantOffsets[platform] then
		local folder = platform:FindFirstChild("FloatDescendants") or platform:FindFirstChild("FloadDescendants")
		if folder then
			floatDescendantOffsets[platform] = {}
			local platformY = platform:IsA("BasePart") and platform.Position.Y or platform:GetPivot().Position.Y
			
			for _, objValue in ipairs(folder:GetChildren()) do
				if objValue:IsA("ObjectValue") and objValue.Value then
					local target = objValue.Value
					local targetPart = getTargetPart(target)
					if targetPart then
						local offset = targetPart.Position.Y - platformY
						table.insert(floatDescendantOffsets[platform], {instance = target, offset = offset})
						
						cons[objValue] = objValue.Changed:Connect(function(newVal)
							if newVal == nil then
								local idx
								for i, item in ipairs(floatDescendantOffsets[platform]) do
									if item.instance == target then
										idx = i
										break
									end
								end
								if idx then
									table.remove(floatDescendantOffsets[platform], idx)
								end
							elseif newVal == target then
								local targetPart = getTargetPart(target)
								if targetPart then
									local offset = targetPart.Position.Y - platformY
									table.insert(floatDescendantOffsets[platform], {instance = target, offset = offset})
								end
							end
						end)
					end
				end
			end
		else
			return -- No folder found, skip
		end
	end

	-- Move all registered child blocks vertically based on the platform's current height position
	for _, data in ipairs(floatDescendantOffsets[platform]) do
		local inst = data.instance
		if inst:IsA("BasePart") then
			inst.Position = Vector3.new(inst.Position.X, currentY + data.offset, inst.Position.Z)
		elseif inst:IsA("Model") then
			local currentPivot = inst:GetPivot()
			inst:PivotTo(CFrame.new(currentPivot.X, currentY + data.offset, currentPivot.Z) * currentPivot.Rotation)
		end
	end
end

local function tweenModelPos(model, info, CF)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPivot()

	local con1
	con1 = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(CFrameValue.Value)
		updateFloatDescendants(model, CFrameValue.Value.Position.Y)
	end)

	local TE = TS:Create(CFrameValue, info, {Value = CF})
	TE:Play()

	local con2
	con2 = TE.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		CFrameValue:Destroy()
	end)
	return TE
end

-- -- Dip a platform -------------------------------------------
local function dipPlatform(platform)
	local part = platform
	if (not part) or part:GetAttribute("Froze") then return end
	CamShake:Shake(CameraShaker.Presets.SlightShudder)

	-- If this platform was scheduled to return, cancel the timer
	leaveTimestamps[part] = nil

	if activeTES[part] then
		activeTES[part]:Cancel()
	end 

	-- Flag it so the passive drift system completely ignores it while occupied
	part:SetAttribute("IsOccupied", true)
	if part:IsA("BasePart") then
		if not part:GetAttribute("ogY") then
			part:SetAttribute("ogY", part.Position.Y)
		end
		if CLOUD_MARKER and (not part:GetAttribute("ogCol")) then
			part:SetAttribute("ogCol", part.Color)
		end
		if CLOUD_MARKER  then
			part.Color = Color3.new(1, 0, 0) -- Turn Red
		end

		-- Run down animation
		activeTES[part] = TS:Create(part, TI_DIP, {
			Position = Vector3.new(part.Position.X, part:GetAttribute("ogY") - DIP_AMOUNT, part.Position.Z)
		})
		activeTES[part]:Play()
	elseif part:IsA("Model") then
		if not part:GetAttribute("ogY") then
			part:SetAttribute("ogY", part:GetPivot().Position.Y)
		end
		tweenModelPos(part, TI_DIP, CFrame.new(part:GetPivot().X, part:GetAttribute("ogY") - DIP_AMOUNT, part:GetPivot().Z) * part:GetPivot().Rotation)
	end

	if part.Parent == floatables.platforms.clouds then
		emitStepPuff(hrp.Position - Vector3.new(0, 3, 0))
	end
end

-- -- Release a specific part back to drift --------------------
local function releasePlatform(part)
	if not part then return end
	leaveTimestamps[part] = nil

	if activeTES[part] then
		activeTES[part]:Cancel()
		activeTES[part] = nil
	end

	if CLOUD_MARKER and part:IsA("BasePart") then
		part.Color = part:GetAttribute("ogCol")
	end

	-- Hand control straight back over to the passive drift loop
	part:SetAttribute("IsOccupied", false)
end

-- -- Cutscene cloud-binding helpers ----------------------------
local function getCF(inst)
	return inst:IsA("BasePart") and inst.CFrame or inst:GetPivot()
end

local function setCF(inst, cf)
	if inst:IsA("BasePart") then
		inst.CFrame = cf
	else
		inst:PivotTo(cf)
	end
end

-- Raycasts straight down from the prop to find which cloud it's resting on
local function findCloudBelow(prop)
	local originPos = getCF(prop).Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {floatables.platforms.clouds}

	local result = workspace:Raycast(originPos, Vector3.new(0, -200, 0), params)
	if not result or not result.Instance then return nil end

	-- climb up until we hit the direct child of the clouds folder
	local hit = result.Instance
	while hit.Parent and hit.Parent ~= floatables.platforms.clouds do
		hit = hit.Parent
	end

	return hit.Parent == floatables.platforms.clouds and hit or nil
end

-- Stops following/holds and hands the cloud back to the passive drift loop
local function unbindProp(prop)
	local data = boundProps[prop]
	if not data then return end

	if data.follow then data.follow:Disconnect() end
	if data.returnTween then data.returnTween:Cancel() end

	releasePlatform(data.cloud)
	boundProps[prop] = nil
end

-- Eases the cloud back to its resting height, then welds the prop to it via
-- a per-frame CFrame offset so they move together for as long as the bind lasts
local function bindPropToCloud(prop, cloud)
	if boundProps[prop] then return end -- already bound

	-- Take the cloud away from the passive drift loop and cancel any dip in progress
	if activeTES[cloud] then
		activeTES[cloud]:Cancel()
		activeTES[cloud] = nil
	end
	leaveTimestamps[cloud] = nil
	cloud:SetAttribute("IsOccupied", true)

	local currentCF = getCF(cloud)
	local ogY = cloud:GetAttribute("ogY")
	local restCF = ogY
		and (CFrame.new(currentCF.Position.X, ogY, currentCF.Position.Z) * (currentCF - currentCF.Position))
		or currentCF

	local returnTween
	if cloud:IsA("BasePart") then
		returnTween = TS:Create(cloud, TI_RETURN, {Position = restCF.Position})
		returnTween:Play()
	else
		returnTween = tweenModelPos(cloud, TI_RETURN, restCF)
	end

	local data = {cloud = cloud, returnTween = returnTween}
	boundProps[prop] = data
	coroutine.wrap(function()
		returnTween.Completed:Wait()

		local offset = getCF(cloud):ToObjectSpace(getCF(prop))
		local lastAppliedCF = nil

		data.follow = RS.Heartbeat:Connect(function()
			if cloud:GetAttribute("Froze") then return end
			local cloudCF = getCF(cloud)
			local propCF  = getCF(prop)

			if lastAppliedCF and not propCF:FuzzyEq(lastAppliedCF, 1e-3) then
				-- Prop moved since our last write
				offset = cloudCF:ToObjectSpace(propCF)
			end

			local newCF = cloudCF * offset
			setCF(prop, newCF)
			lastAppliedCF = newCF
			
			-- Keep attached elements fully locked to it during cutscene movements
			updateFloatDescendants(cloud, cloudCF.Position.Y)
		end)
	end)()
end

-- Scans the cutscene props folder for anything flagged OnCloud that isn't bound yet
local function scanCutsceneProps()
	local folder = workspace:FindFirstChild("SCENES")
	if char:GetAttribute("OnCloud") then
		local cloud = findCloudBelow(char)

		if cloud then
			bindPropToCloud(char, cloud)
		end
	end
	if not folder then return end

	for _, propFolder in ipairs(folder:GetChildren()) do
		for i, prop in pairs(propFolder:GetChildren()) do
			if (prop:IsA("BasePart") or prop:IsA("Model")) and prop:GetAttribute("OnCloud") and not boundProps[prop] then
				local cloud = findCloudBelow(prop)
				if cloud then
					bindPropToCloud(prop, cloud)
				end
			end 
		end
	end
end

-- -- Centralized Frame Loop ---------------------------------------
-- This loop manages BOTH passive drifting AND updates objects 
-- undergoing player-activated dipping/tweens sequentially.
task.spawn(function()
	local cloudsFolder = floatables.platforms.clouds
	if not cloudsFolder then return end

	local totals = cloudsFolder:GetChildren()
	for i, v in pairs(floatables.platforms.steps:GetChildren()) do
		table.insert(totals, v)
	end

	while true do
		local dt = RS.Heartbeat:Wait()
		local now = os.clock()

		for _, part in ipairs(totals) do
			if not part or part:GetAttribute("Froze") then continue end

			-- CASE 1: Platform is occupied (player is stepping on it / it's dipping via TweenService)
			if part:GetAttribute("IsOccupied") then
				-- Skip the drift math, but capture Tween's frame position to update descendants
				if part:IsA("BasePart") then
					updateFloatDescendants(part, part.Position.Y)
				end
				continue 
			end

			-- CASE 2: Platform is completely unoccupied (Passive Drifting)
			if not part:GetAttribute("ogY") then
				part:SetAttribute("ogY", part:IsA("BasePart") and part.Position.Y or part:GetPivot().Position.Y)
			end

			-- Assign a unique offset seed per cloud so they drift at separate intervals
			if not cloudSeeds[part] then
				cloudSeeds[part] = math.random() * 100
			end

			-- Calculate the passive float position using trigonometry
			local wave = math.sin((now * DRIFT_SPEED) + cloudSeeds[part]) * DRIFT_HEIGHT
			local targetY = part:GetAttribute("ogY") + wave

			if part:IsA("BasePart") then
				-- Lerp position slightly for smooth frame updates to transition back into place
				part.Position = Vector3.new(
					part.Position.X, 
					part.Position.Y + (targetY - part.Position.Y) * 0.05,
					part.Position.Z
				)
				updateFloatDescendants(part, part.Position.Y)
			else
				local nextY = part:GetPivot().Position.Y + (targetY - part:GetPivot().Position.Y) * 0.05
				part:PivotTo(part:GetPivot() + Vector3.new(0, (targetY - part:GetPivot().Position.Y) * 0.05, 0))
				updateFloatDescendants(part, nextY)
			end
		end
	end
end)

-- -- Poll loop -------------------------------------------------
local elapsed = 0
RS.Heartbeat:Connect(function(dt)
	-- 1. Continuously process independent platform release timers
	local now = os.clock()
	for part, leaveTime in pairs(leaveTimestamps) do
		if now - leaveTime >= DEBOUNCE_TIME then
			releasePlatform(part)
		end
	end

	elapsed += dt
	if elapsed < CHECK_RATE then return end
	elapsed = 0

	-- 2. Cutscene cloud-binding: pick up newly-flagged props, drop released ones
	if plr:GetAttribute("InCutscene") then
		inCutscene = true

		for prop in pairs(boundProps) do
			if not prop.Parent or not prop:GetAttribute("OnCloud") then
				unbindProp(prop)
			end
		end

		scanCutsceneProps()
	elseif inCutscene then
		-- Cutscene just ended: release everything still bound
		inCutscene = false
		for prop in pairs(boundProps) do
			unbindProp(prop)
		end
	end

	if not DreamWorld.isActive() then
		if activePlatform then
			local part = activePlatform
			if part then leaveTimestamps[part] = os.clock() end
			activePlatform = nil
			lastPlatform = nil
		end
		return
	end

	local currentPlatform = DreamWorld.getPlatformUnder()

	if currentPlatform ~= lastPlatform then
		-- We left the old platform: Tag it with a timestamp
		if lastPlatform then
			local oldPart = lastPlatform
			if oldPart then
				leaveTimestamps[oldPart] = os.clock()
			end
		end

		lastPlatform = currentPlatform
		activePlatform = currentPlatform

		-- We entered a new platform: Dip it immediately
		if currentPlatform then
			local oldPlatform = currentPlatform
			if plr:GetAttribute("InCutscene") then
				repeat wait() until not plr:GetAttribute("InCutscene")
				if currentPlatform ~= oldPlatform then return end
			end
			dipPlatform(currentPlatform)
		end
	end
end)