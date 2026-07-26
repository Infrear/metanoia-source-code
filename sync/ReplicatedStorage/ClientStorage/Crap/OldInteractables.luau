-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")


-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local NPCs = workspace:WaitForChild("NPCS")
local images = require(Storage:WaitForChild("Info"):WaitForChild("Images"))
local keySettings = require(Storage.Info.KeybindsMaster)
local gameSettings = require(Storage.Info.GameSettings)
local harvestSettings = gameSettings.HarvestSettings
local buildInfo = require(Storage:WaitForChild("Info"):WaitForChild("BuildInfo"))
local barChange = Storage:WaitForChild("Events").Standard.HotbarChange
local buildFunctions = require(Storage:WaitForChild("Info"):WaitForChild("BuildFunctions"))
local NPCM = require(script:WaitForChild("NPCs"))

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local AM = char.States:WaitForChild("AnimationManager2")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui = playerGUI:WaitForChild("Interactables")
local pickup = ui:WaitForChild("Pickup")
--local pickup2 = ui:WaitForChild("Pickup2")
local interact = ui:WaitForChild("Interact")

local event = Instance.new("BindableEvent")
local harvestEv = Storage.Events.Remotes.HarvestEvent

local TIS = {
	TweenInfo.new(
		0.5, -- Duration of each pulse (in seconds)
		Enum.EasingStyle.Sine, -- Easing style (smooth pulse)
		Enum.EasingDirection.Out, -- Easing direction (starting from low to high)
		-1, -- Loop count (-1 means infinite loop)
		true, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),

	TweenInfo.new(
		0.75, -- Duration of the ring tween (in seconds)
		Enum.EasingStyle.Linear, -- Easing style (linear transition)
		Enum.EasingDirection.InOut, -- Easing direction (both in and out)
		-1, -- Loop count (-1 means infinite loop)
		true, -- Reverses the animation after each cycle
		0 -- Delay before starting the animation
	),
}

-- Constants
local PICKUP_DISTANCE_THRESHOLD = harvestSettings.PICKUP_DISTANCE_THRESHOLD -- Adjust the distance threshold for showing the pickup button
--local PICKUP_DISTANCE_THRESHOLD_SQ = PICKUP_DISTANCE_THRESHOLD * PICKUP_DISTANCE_THRESHOLD -- Squared distance threshold for performance
local INTERACT_DISTANCE_THRESHOLD = keySettings.Interactions.INTERACT_DISTANCE_THRESHOLD
local INTERACT_DISTANCE_THRESHOLD_DEFAULT = keySettings.Interactions.INTERACT_DISTANCE_THRESHOLD_DEFAULT
local INTERACT_TIMES = keySettings.Interactions.INTERACT_TIMES
local PICKUP_DIMS = {
	["Mobile"] = {
		Size = UDim2.new(0.096, 0, 0.136, 0),
		Position = UDim2.new(0.062, 0, 0.694, 0)
	},
	["Screen"] = {
		Size = UDim2.new(0.045, 0, 0.095, 0),
		Position = UDim2.new(0.5, 0, 0.8, 0)
	}
}
local buttons = {
	["Pickup"] = {
		Frame = pickup,
		KeyIndex = "Pick up"
	},
	["Interact"] = {
		Frame = interact,
		KeyIndex = "Interact"
	},
}

-- Variables
local TES = {}
local cons = {}

local buttonsDown = {}
local harvestAnim = AM:WaitForChild("Anims"):WaitForChild("Harvest")
local harvestTrac = hum:LoadAnimation(harvestAnim)
local tool = nil--char:WaitForChild("CurrentTool"):GetChildren()[1]

local curBush = nil
local curInteractObj = nil
local pickCons = {}
cons[pickup] = {}
local lastPosition = char.HumanoidRootPart.Position

-- Initialization
local interactables = {}

-- Local Functions
function checkPlatform()
	local thetype = "Keyboard"
	if UIS.TouchEnabled then
		thetype = "Mobile"
	elseif UIS.GamepadEnabled then
		thetype = "Console"
	elseif UIS.KeyboardEnabled then
		thetype = "Keyboard"
	elseif UIS.MouseEnabled then
		thetype = "Keyboard"		
	end
	return thetype
end

-- Function to check if the player is close to any bushes
local function isPlayerNearBushes()
	if --[[pickup2.Visible or]] interact.Visible then return end
	if char:FindFirstChild("CurrentTool") then
		if char:FindFirstChild("CurrentTool"):GetChildren()[1] then
			--barChange:Fire("Unequip")
			return false
		end
	end

	local closest = math.huge
	local closestBush = nil
	local bushes = workspace["RESOURCES"].bushes
	if not bushes then
		return false
	end

	local playerPosition = char.HumanoidRootPart.Position
	for _, bush in pairs(bushes:GetChildren()) do
		if not bush:IsA("MeshPart") or bush.Name ~= "bush" or bush:GetAttribute("Harvested") then continue end
		if (bush.Position - playerPosition).Magnitude <= closest and (bush.Position - playerPosition).Magnitude <= PICKUP_DISTANCE_THRESHOLD[bush.Name] then
			--return true
			closest = (bush.Position - playerPosition).Magnitude
			closestBush = bush
		end
	end
	curBush = closestBush
	if closestBush then
		return true
	end

	return false
end

local function isPlayerNearInteractObject()
	--if pickup2.Visible then return end
	--if char:FindFirstChild("CurrentTool") then
	--	if char:FindFirstChild("CurrentTool"):GetChildren()[1] then
	--		--barChange:Fire("Unequip")
	--		return false
	--	end
	--end

	local closest = math.huge
	local closestObj = nil
	local interactLocation = workspace.BUILDS
	local iTable2 = {}

	if not interactLocation or not NPCs or not iTable2 then
		return false
	end

	local playerPosition = char.HumanoidRootPart.Position
	for _, obj in pairs(interactLocation:GetChildren()) do -- watch for memory
		--print(bush)
		if not obj:IsA("Model") or (not (buildFunctions[obj.Name] and buildFunctions[obj.Name]["OnInteractClient"])) or obj:GetAttribute("Fakebuild") then continue end
		--print("1")
		if (obj:GetPivot().Position - playerPosition).Magnitude <= closest and (obj:GetPivot().Position - playerPosition).Magnitude <= ((buildInfo[obj.Name] and buildInfo[obj.Name].MaxDist) or INTERACT_DISTANCE_THRESHOLD[obj.Name] or INTERACT_DISTANCE_THRESHOLD_DEFAULT) then
			--print("2")
			--return true
			closest = (obj:GetPivot().Position - playerPosition).Magnitude
			closestObj = obj
		end
	end

	for _, obj in pairs(NPCs:GetChildren()) do
		--print(bush)
		if not (obj:GetAttribute("NPCType") and keySettings.Interactions.TALKABLE_NPC_TYPES[obj:GetAttribute("NPCType")]) or not obj:IsA("Model") or obj:GetAttribute("Fakebuild") then continue end
		--print("1")
		if (obj:GetPivot().Position - playerPosition).Magnitude <= closest and (obj:GetPivot().Position - playerPosition).Magnitude <= (INTERACT_DISTANCE_THRESHOLD["NPC_"..obj:GetAttribute("NPCType")] or INTERACT_DISTANCE_THRESHOLD.NPC_Default) then
			--print("2")
			--return true
			closest = (obj:GetPivot().Position - playerPosition).Magnitude
			closestObj = obj
		end
	end

	curInteractObj = closestObj

	if closestObj then
		--if (closestObj.Parent == interactLocation) then
		--	interactables.InteractVisible = buildFunctions[closestObj.Name].UIType or "none"
		--elseif closestObj.Parent == NPCs then
		--	interactables.InteractVisible = "NPC_"..closestObj:GetAttribute("NPCType")
		--end
		--print(closestBush)
		return true
		--else
		--interactables.InteractVisible = "none"
	end

	return false
end

local function renderStepped()
	if char:FindFirstChild("HumanoidRootPart") then
		local currentPosition = char.HumanoidRootPart.Position
		local distance = (currentPosition - lastPosition).Magnitude
		if distance > 0 then
			pickup.Visible = isPlayerNearBushes()
			interact.Visible = (not NPCM.currentNPC) and isPlayerNearInteractObject()
			if interact.Visible and curInteractObj then
				if (curInteractObj.Parent == workspace.BUILDS) then
					interactables.InteractVisible = buildFunctions[curInteractObj.Name].UIType or "No UI Needed"
				elseif curInteractObj.Parent == NPCs then
					interactables.InteractVisible = "NPC_"..curInteractObj:GetAttribute("NPCType")
				end
			else
				interactables.InteractVisible = "none"
			end
		end
		lastPosition = currentPosition
		--else
		--	if cons["game"][1] then
		--		cons["game"][1]:Disconnect()
		--	end
		--	if cons[pickup][2] then
		--		cons[pickup][2]:Disconnect()
		--	end
	end
end

local function setDefaults(button, image)
	local mob = checkPlatform() ~= "Mobile"
	button.Position = mob and PICKUP_DIMS.Screen.Position or PICKUP_DIMS.Mobile.Position
	button.Size = mob and PICKUP_DIMS.Screen.Size or PICKUP_DIMS.Mobile.Size

	if image then
		button.Button.ImageLabel.Image = image
	end
	button.Button.BackgroundTransparency = 0
	button.Button.ImageLabel.ImageTransparency = 0
	button.Button.Ring.Transparency = 0
	button.Button.Ring.Thickness = 6.25
end

local function pauseAnimations(button)
	for _, tween in pairs(TES[button] or {}) do
		if tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Pause()
		end
	end
	setDefaults(button)
	if button.Name == "Pickup" then
		hrp.Anchored = true
		harvestTrac:Play()
	end
end

local function resumeAnimations(button)
	for _, tween in pairs(TES[button] or {}) do
		if tween.PlaybackState == Enum.PlaybackState.Paused then
			tween:Play()
		end
	end
	if button.Name == "Pickup" then
		hrp.Anchored = false
		if harvestTrac then
			harvestTrac:Stop()
		end
	end
end

local function runShi(buttonName)
	if buttonName == "Pickup" then
		hrp.Anchored = false
		local theBush = curBush
		curBush = nil
		--print("run")
		harvestEv:FireServer(theBush)

		pickup.Visible = isPlayerNearBushes()

		---- Perform the transparency animation 
		--theBush.Transparency = 0.3
		--task.wait(0.1)
		--theBush.Transparency = 0.4
		--task.wait(0.1)
		--theBush.Transparency = 0.5
		--task.wait(0.1)
		--theBush.Transparency = 0.6
		--task.wait(0.1)
		--theBush.Transparency = 0.7
		--task.wait(0.1)
		--theBush.Transparency = 0.8
		--task.wait(0.1)
		--theBush.Transparency = 0.9
		--task.wait(0.1)
		--theBush.Transparency = 1
	elseif buttonName == "Interact" then
		local theObj = curInteractObj
		curInteractObj = nil

		if theObj.Parent == workspace.BUILDS then
			hrp.Anchored = false
			buildFunctions[theObj.Name].OnInteractClient(plr, theObj)

			--interact.Visible = isPlayerNearInteractObject()
			--if interact.Visible and curInteractObj then
			--	interactables.InteractVisible = buildFunctions[curInteractObj.Name].UIType or "none"
			--else
			--	interactables.InteractVisible = "none"
			--end
		elseif theObj.Parent == NPCs and not NPCM.currentNPC then
			if theObj:GetAttribute("NPCType") --[[== "Quest"]] then
				--print(theObj)
				--print(plr)
				NPCM.runNPC(theObj)
			end
		end
	end
end

local function bindButtons()
	for buttonName, buttonInfo in pairs(buttons) do
		local button = buttonInfo.Frame
		cons[button] = {}
		cons[button][1] = button:GetPropertyChangedSignal("Visible"):Connect(function()
			if button.Visible then
				setDefaults(button, (buttonName == "Interact" and (curInteractObj and ((curInteractObj.Parent == NPCs and images.Chats.Talk) or (--[[curInteractObj.Parent == workspace.Structures and]] images.Chats.Interact)))) or (buttonName == "Pickup" and images.Chats.Pickup) or nil)

				-- Main tween
				TES[button] = {}
				TES[button][1] = TS:Create(button.Button, TIS[1], { BackgroundTransparency = 0.6 })
				TES[button][1]:Play()

				TES[button][1.1] = TS:Create(button.Button.ImageLabel, TIS[1], { ImageTransparency = 0.6 })
				TES[button][1.1]:Play()

				-- Ring tween
				local ring = button.Button:FindFirstChild("Ring")
				if ring and ring:IsA("UIStroke") then
					TES[button][2] = TS:Create(ring, TIS[2], {
						Transparency = 0.5,
						Thickness = 4, -- Adjust the initial thickness of the ring
					})
					TES[button][2]:Play()

					-- Scale the ring size during the tween
					pickCons[1] = TES[button][2].Changed:Connect(function(property)
						if property == "Progress" then
							local progress = TES[button][2].Progress
							local minScale = 0.8 -- Adjust the minimum scale factor
							local maxScale = 1.2 -- Adjust the maximum scale factor
							local scale = minScale + (maxScale - minScale) * progress
							ring.Thickness = 4 * scale -- Adjust the initial thickness of the ring multiplied by the scale
						end
					end)
				end
			else
				if TES[button] then
					for i, v in pairs(TES[button]) do
						if v.PlaybackState == Enum.PlaybackState.Playing then
							v:Cancel()
							v = nil
						end
					end
				end
				TES[button] = nil
				for i, v in pairs(pickCons) do
					v:Disconnect()
				end
			end
		end)

		cons[button][4] = button.Button.MouseButton1Down:Connect(function()
			--print(curInteractObj)
			if UIS:IsKeyDown(keySettings.Interactions[buttonInfo.KeyIndex]) then return end
			if not ((buttonName == "Pickup" and curBush) or (buttonName == "Interact" and curInteractObj)) then return end
			buttonsDown[button] = true

			-- Pause animations when the button is held down
			pauseAnimations(button)

			local startTime = tick() -- Get the current time
			local endTime = 0

			if buttonName == "Pickup" then
				-- Loop until the button is released or 3 seconds have passed
				endTime = 3
				while buttonsDown[button] and tick() - startTime < endTime and not tool do
					wait()
				end
			elseif buttonName == "Interact" and INTERACT_TIMES[curInteractObj.Name] then
				-- Loop until the button is released or 3 seconds have passed
				endTime = INTERACT_TIMES[curInteractObj.Name] or endTime
				while buttonsDown[button] and tick() - startTime < endTime and not tool do
					wait()
				end
			end

			-- Resume animations when the button is released or 3 seconds have passed
			resumeAnimations(button)

			local elapsed = tick() - startTime
			if elapsed < endTime then return end
			runShi(buttonName)
		end)

		cons[button][4.1] = UIS.InputBegan:Connect(function(inp)
			if not (inp.KeyCode == keySettings.Interactions[buttonInfo.KeyIndex]) or buttonsDown[button] then return end
			if not ((buttonName == "Pickup" and curBush) or (buttonName == "Interact" and curInteractObj)) then return end
			buttonsDown[button] = true

			-- Pause animations when the button is held down
			pauseAnimations(button)

			local startTime = tick() -- Get the current time
			local endTime = 0

			if buttonName == "Pickup" then
				-- Loop until the button is released or 3 seconds have passed
				local endTime = 3
				while UIS:IsKeyDown(keySettings.Interactions[buttonInfo.KeyIndex]) and not tool and tick() - startTime < endTime do
					wait()
				end
			elseif buttonName == "Interact" and INTERACT_TIMES[curInteractObj.Name] then
				-- Loop until the button is released or 3 seconds have passed
				local endTime = INTERACT_TIMES[curInteractObj.Name] or endTime
				while UIS:IsKeyDown(keySettings.Interactions["Interact"]) and not tool and tick() - startTime < endTime do
					wait()
				end
			end

			-- Resume animations when the button is released or 3 seconds have passed
			resumeAnimations(button)

			local elapsed = tick() - startTime
			buttonsDown[button] = false
			--print(elapsed)
			if elapsed < endTime then return end
			runShi(buttonName)
		end)

		cons[button][5] = button.Button.MouseButton1Up:Connect(function()
			buttonsDown[button] = false
		end)

		cons[button][5.1] = button.Button.MouseLeave:Connect(function()
			buttonsDown[button] = false
		end)


		cons[button][5.2] = UIS.InputEnded:Connect(function(inp)
			if not (inp.KeyCode == keySettings.Interactions[buttonInfo.KeyIndex]) then return end
			buttonsDown[button] = false
		end)
	end

	--cons[pickup][6] = char:WaitForChild("CurrentTool").ChildAdded:Connect(function()
	--	tool = char:WaitForChild("CurrentTool"):GetChildren()[1]
	--	pickup.Visible = isPlayerNearBushes()
	--end)

	--cons[pickup][7] = char:WaitForChild("CurrentTool").ChildRemoved:Connect(function()
	--	tool = char:WaitForChild("CurrentTool"):GetChildren()[1]
	--	pickup.Visible = isPlayerNearBushes()
	--end)
	cons["game"] = {}
	cons["game"][1] = RS.Heartbeat:Connect(renderStepped)
	-- Connect character movement and input changed events
	--hum.Move:Connect(onCharacterMove)
	--hum:GetPropertyChangedSignal("MoveDirection"):Connect(onCharacterMove)
end

-- Global Variables
interactables.Ready = Instance.new("BindableEvent")
interactables.InteractVisible = "none"

-- Global Functions
function interactables.setup()
	NPCM.setup()
	interactables.Ready:Fire()
	bindButtons()
end

return interactables