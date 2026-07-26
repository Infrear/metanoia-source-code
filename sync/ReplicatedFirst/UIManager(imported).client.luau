game.ReplicatedFirst:RemoveDefaultLoadingScreen()
game:GetService("UserInputService").MouseIconEnabled = false

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage:WaitForChild("Info"):WaitForChild("KeybindsMaster"))
local combatReplicator = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("ReplicateCombat")
local loadedEv = Storage.Events:WaitForChild("Standard"):WaitForChild("LoadingDone")

local plr = game.Players.LocalPlayer
repeat wait() until plr.Character
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local hrp = char:WaitForChild("HumanoidRootPart")

local mouse = plr:GetMouse()
local cam = workspace:WaitForChild("Camera")

local otherUI = playerGUI:WaitForChild("SurvivorUI"):WaitForChild("OtherworldlyUIs")
local craftFrame = playerGUI:WaitForChild("SurvivorUI"):WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Crafting")
local othInvFrame = otherUI:WaitForChild("StoreInventory"):WaitForChild("Frame"):WaitForChild("Inventory")
local othMixFrame = otherUI:WaitForChild("Mixing"):WaitForChild("Frame"):WaitForChild("Inventory")
local cursorImg = playerGUI:WaitForChild("Cursor"):WaitForChild("Cursor"):WaitForChild("ImageLabel")

local loading = require(script:WaitForChild("Loading"))

-- we'll load these in after
local essentials = nil
local toolbar = nil
local interactables = nil
local menu = nil
local regions = nil
local building = nil
local intro = nil
local charactercustomization = nil
local quests = nil
	
local forceOpenUI = Storage:WaitForChild("Events"):WaitForChild("Standard"):WaitForChild("ForceOpenUI")

-- Variables
local cons = {}
local ready = false
local doneLoading = false
local skipping = false

-- Constants
local MouseSettings = {
	["Button Growth"] = 0.5,
	["Button Shrink"] = 0.2,
	["Button Growth/Shrink Speed"] = 0.05
}
local TIS = {
	["Grow"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	),
	["Shrink"] = TweenInfo.new(
		MouseSettings["Button Growth/Shrink Speed"], 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out, 
		0, 
		false
	)
}

--local Loop = true

--plr:WaitForChild("PlayerGui"):WaitForChild("SurvivorUI").Enabled = true

-- Local functions
local function checkPlatform()
	local lastInput = UIS:GetLastInputType()

	if lastInput == Enum.UserInputType.Touch then
		return "Mobile"
	elseif lastInput == Enum.UserInputType.Gamepad1 or
		lastInput == Enum.UserInputType.Gamepad2 or
		lastInput == Enum.UserInputType.Gamepad3 or
		lastInput == Enum.UserInputType.Gamepad4 then
		return "Console"
	elseif lastInput == Enum.UserInputType.Keyboard or
		lastInput == Enum.UserInputType.MouseButton1 or
		lastInput == Enum.UserInputType.MouseMovement then
		return "Keyboard"
	else
		return "Keyboard" -- Handle edge cases or unsupported inputs
	end
end

local function setupMouseStuff()
	local defaultSize = cursorImg.Size
	local currentTween = nil
	local clickTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale + MouseSettings["Button Growth"], 0, defaultSize.Y.Scale + MouseSettings["Button Growth"], 0)})
	local shrinkTween = TS:Create(cursorImg, TIS["Grow"], {Size = UDim2.new(defaultSize.X.Scale - MouseSettings["Button Shrink"], 0, defaultSize.Y.Scale - MouseSettings["Button Shrink"], 0)})
	local defaultTween = TS:Create(cursorImg, TIS["Shrink"], {Size = defaultSize})
	
	mouse.Move:Connect(function()
		cursorImg.Parent.Position = UDim2.new(0, mouse.X, 0, mouse.Y)


		
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			cursorImg.BackgroundColor3 = Color3.new(0.141176, 0.00784314, 0.905882)
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			cursorImg.BackgroundColor3 = Color3.new(1, 0, 0)
		else
			local pos = UDim2.new(0, mouse.X, 0, mouse.Y)
			local guisAtPosition = playerGUI:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

			for _, gui in ipairs(guisAtPosition) do
				if gui:IsA("TextButton") or gui:IsA("ImageButton") then
					cursorImg.BackgroundColor3 = Color3.new(0, 0.6, 1)
					return
				end
			end
			
			cursorImg.BackgroundColor3 = Color3.new(1, 1, 1)
		end
	end)

	UIS.InputBegan:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 then
			--print("down")
			cursorImg.BackgroundColor3 = Color3.new(0.141176, 0.00784314, 0.905882)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = clickTween
			currentTween:Play()
		elseif inputType == mouse2 then
			cursorImg.BackgroundColor3 = Color3.new(1, 0, 0)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = shrinkTween
			currentTween:Play()
		end
	end)

	UIS.InputEnded:Connect(function(input, gP)
		local inputType = input.UserInputType
		local touch = Enum.UserInputType.Touch
		local mouse1 = Enum.UserInputType.MouseButton1
		local mouse2 = Enum.UserInputType.MouseButton2
		if inputType == touch or inputType == mouse1 or inputType == mouse2 then
			--print("up")
			cursorImg.BackgroundColor3 = Color3.new(1, 1, 1)
			if currentTween then
				if currentTween.PlaybackState == Enum.PlaybackState.Playing then
					currentTween:Cancel()
				end
			end
			currentTween = defaultTween
			currentTween:Play()
		end
	end)
	
	--UIS.InputBegan:Connect(function(input, gP)
	--	local inputType = input.UserInputType
	--	local touch = Enum.UserInputType.Touch
	--	local mouse1 = Enum.UserInputType.MouseButton1
	--	if inputType == touch or inputType == mouse1 and (not clickTween or clickTween.PlaybackState ~= Enum.PlaybackState.Playing) then
	--		-- tween the cursor's size
	--		clickTween:Play()
	--		local con 
	--		con = clickTween.Completed:Connect(function()
	--			con:Disconnect()
	--			cursorImg.Size = defaultSize
	--		end)
	--	end
	--end)
end

local function setupUIs()
	playerGUI:WaitForChild("SurvivorUI").Enabled = false
	playerGUI:WaitForChild("Interactables").Enabled = false
	playerGUI:WaitForChild("GlobalUI").Enabled = false
	playerGUI:WaitForChild("LoadingScreen").Enabled = true
	playerGUI:WaitForChild("CharacterCustomization").Enabled = true
	if checkPlatform() ~= "Mobile" then
		playerGUI:WaitForChild("Cursor").Enabled = true
	end
	
	--coroutine.wrap(function()
	--	while Loop do
	-- 		task.wait(.1)
	--		plr:WaitForChild("PlayerGui"):WaitForChild("SurvivorUI"):WaitForChild("Essentials"):WaitForChild("MainFrame"):WaitForChild("Health").BackgroundTransparency = 1
	--		plr:WaitForChild("PlayerGui"):WaitForChild("SurvivorUI"):WaitForChild("Essentials"):WaitForChild("MainFrame"):WaitForChild("Hunger").BackgroundTransparency = 1
	--		plr:WaitForChild("PlayerGui"):WaitForChild("SurvivorUI"):WaitForChild("Essentials"):WaitForChild("MainFrame"):WaitForChild("Thirst").BackgroundTransparency = 1
	--	end
	--end)()

	coroutine.wrap(function()
		loading.setup(skipping) -- skip argument
	end)()
	
	coroutine.wrap(function()
		local con = nil
		con = loading.Ready.Event:Connect(function()
			con:Disconnect()
			doneLoading = true
		end)
	end)()
	--print("ok")

	script.Parent = playerGUI
	essentials = require(script:WaitForChild("Essentials"))
	toolbar = require(script:WaitForChild("Toolbar"))
	interactables = require(script:WaitForChild("Interactables"))
	menu = require(script:WaitForChild("Menu"))
	regions = require(script:WaitForChild("Regions"))
	building = require(script:WaitForChild("Building"))
	intro = require(script:WaitForChild("Building"))
	charactercustomization = require(script:WaitForChild("CharacterCustomization"))
	quests = require(script:WaitForChild("Quests"))
	
	menu.setup()
	toolbar.setup()
	regions.setup()
	--toolbar.Ready.Event:Wait()
	toolbar.Ready:Destroy()
	toolbar.Ready = nil
	interactables.setup()
	interactables.Ready:Destroy()
	interactables.Ready = nil
	task.wait(0.25)
	essentials.setup()
	essentials.Ready.Event:Wait()
	essentials.Ready:Destroy()
	essentials.Ready = nil
	building.setup()
	quests.setup()

	task.wait(1.25) -- buffer
	repeat wait() until doneLoading

	--task.desynchronize()
	setupMouseStuff()
	--task.synchronize()
	
	coroutine.wrap(function()
		charactercustomization.setup(skipping)
	end)()
	
	task.wait(0.75)
	
	
	loading.stop()
	loadedEv:Fire()
	
	if not skipping then
		charactercustomization.FinishedCustomization.Event:Wait()
	end
	loading.tweenInCover()
	task.wait(2)
	charactercustomization.undoStuff = true
	charactercustomization.FinishedCustomization:Destroy()
	charactercustomization.FinishedCustomization = nil
	
	playerGUI:WaitForChild("CharacterCustomization").Enabled = false
	playerGUI:WaitForChild("GlobalUI").Enabled = true
	playerGUI:WaitForChild("SurvivorUI"):SetAttribute("Active", true)
	playerGUI:WaitForChild("SurvivorUI").Enabled = true
	playerGUI:WaitForChild("Interactables").Enabled = true
	--if checkPlatform() ~= "Mobile" then
	--	plr.PlayerScripts.Camera["TSC v1"].Enabled = true
	--end
	if not skipping then
		task.wait(2)
	end
	loading.tweenOutCover()
	--task.wait(7)
	--Loop = false
end


-- Connections
UIS.InputBegan:Connect(function(input, gP)
	--print(interactables.InteractVisible)
	if not ready then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		--print(playerGUI:WaitForChild("SurvivorUI").Enabled)
		local entering = not menu.In
		if input.KeyCode == keySettings.UI["Inventory"] and interactables.InteractVisible == "none" and not gP then
			--print("in")
			--print(menu.In)
			if menu.In and (menu.currentSection.Key == "Inventory" or menu.currentSection.Key == "StoreInventory" or menu.currentSection.Key == "Mixing")  and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") then
				menu.fadeOut()
				toolbar.fadeIn()
				essentials.fadeInOthers()
			else
				--print("out")
				menu.fadeIn("Inventory")
				if entering then
					toolbar.fadeOut()
					essentials.fadeOutOthers()
				end
			end
		--elseif input.KeyCode == Enum.KeyCode.M then
		--	toolbar.fadeOut()
		elseif input.KeyCode == keySettings.UI["Self"] --[[and interactables.InteractVisible ~= "Self"]] and not gP then
			if menu.In and menu.currentSection.Key == "Inventory2" and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") and (otherUI:WaitForChild("Station").Value == nil or otherUI:WaitForChild("Station").Value == plr) then
				menu.fadeOut()
				toolbar.fadeIn()
				essentials.fadeInOthers()
			else
				menu.fadeIn("Inventory2")
				if entering then
					toolbar.fadeOut()
					essentials.fadeOutOthers()
				end
			end
		elseif input.KeyCode == keySettings.UI["Crafting"] --[[and interactables.InteractVisible ~= "Crafting"]] and not gP then 
			if (keySettings.UI["Crafting"] == keySettings.Building.Cancel and building.placing) then
				building.CPressed:Fire()
			else
				if menu.In and menu.currentSection.Key == "Crafting" and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") then
					menu.fadeOut()
					toolbar.fadeIn()
					essentials.fadeInOthers()
				else
					if (otherUI:WaitForChild("Station").Value == nil or otherUI:WaitForChild("Station").Value == plr) then
						menu.loadCrafting() --> empty loads the self crafting
					end
					menu.fadeIn("Crafting")
					if entering then
						toolbar.fadeOut()
						essentials.fadeOutOthers()
					end
				end
			end
		end
	end
end)

UIS.InputEnded:Connect(function(input, gP)
	if not ready then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and not gP then
		---
	end
end)

forceOpenUI.Event:Connect(function(widge, station)
	local entering = not menu.In
	if widge == "Crafting" then
		if menu.In and menu.currentSection.Key == "Crafting" and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") and (otherUI:WaitForChild("Station").Value == station) then
			otherUI:WaitForChild("Station").Value = nil
			menu.fadeOut()
			toolbar.fadeIn()
			essentials.fadeInOthers()
		else
			if not (otherUI:WaitForChild("Station").Value == station) then
				menu.loadCrafting(station)
			end
			menu.fadeIn("Crafting")
			if entering then
				toolbar.fadeOut()
				essentials.fadeOutOthers()
			end
		end
	elseif widge == "StoreInventory" then
		if menu.In and menu.currentSection.Key == "StoreInventory" and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") and (otherUI:WaitForChild("Station").Value == station) then
			otherUI:WaitForChild("Station").Value = nil
			menu.fadeOut()
			toolbar.fadeIn()
			essentials.fadeInOthers()
		else
			otherUI:WaitForChild("Station").Value = station
			othInvFrame.Title.Text = station.Name
			--if not (craftFrame:WaitForChild("Station").Value == station) then
			--	menu.loadCrafting(station)
			--end
			menu.fadeIn("StoreInventory")
			if entering then
				toolbar.fadeOut()
				essentials.fadeOutOthers()
			end
		end
	elseif widge == "Mixing" then
		if menu.In and menu.currentSection.Key == "Mixing" and playerGUI:WaitForChild("SurvivorUI"):GetAttribute("Active") and (otherUI:WaitForChild("Station").Value == station) then
			otherUI:WaitForChild("Station").Value = nil
			menu.fadeOut()
			toolbar.fadeIn()
			essentials.fadeInOthers()
		else
			otherUI:WaitForChild("Station").Value = station
			othMixFrame.Title.Text = station.Name
			--if not (craftFrame:WaitForChild("Station").Value == station) then
			--	menu.loadCrafting(station)
			--end
			menu.fadeIn("Mixing")
			if entering then
				toolbar.fadeOut()
				essentials.fadeOutOthers()
			end
		end
	end
end)

-- Loose Threads
UIS.MouseIconEnabled = false
task.wait(1.5)
setupUIs()
--print("confirmed")
ready = true
