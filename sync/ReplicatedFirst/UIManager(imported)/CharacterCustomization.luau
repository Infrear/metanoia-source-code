-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local characterCustomizationArea = nil
local characterDummy = nil
local cameras = nil
local pedestal = nil
local offset = nil
local currentData = nil

local CCAssets = Storage:WaitForChild("CharacterCustomizationAssets")
local pedestalAnim = Storage:WaitForChild("Animations"):WaitForChild("StableObjectAnims"):WaitForChild("CharacterCustomization"):WaitForChild("PedestalAnim")
local idleAnim = Storage:WaitForChild("Animations"):WaitForChild("StableObjectAnims"):WaitForChild("CharacterCustomization"):WaitForChild("IdleAnim")
local equipAnim = Storage:WaitForChild("Animations"):WaitForChild("StableObjectAnims"):WaitForChild("CharacterCustomization"):WaitForChild("EquipAnim")
local CCUInfo = require(script:WaitForChild("CCUIInfo"))
local colorPicker = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("ColorPicker"))
local getOnGradientSlider = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("GetOnGradientSlider"))

local ui = playerGUI:WaitForChild("CharacterCustomization")
local frame = ui:WaitForChild("MainFrame"):WaitForChild("Frame")
local box = frame:WaitForChild("SelectionItems"):WaitForChild("ScrollingFrame")
local exUI = script:WaitForChild("ScrollingFrame")
local exSub = script:WaitForChild("FakeSub")
local ctnBtn = frame:WaitForChild("SelectionItems"):WaitForChild("ContinueBtn")

local event = Instance.new("BindableEvent")
local equipEvent = Instance.new("BindableEvent")
local subEvent = Instance.new("BindableEvent")

local getData = Storage:WaitForChild("Functions").Remotes.GetData
local CCReplicator = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("CharacterCustomizationReplicator")

local TIS = {
	[1] = TweenInfo.new(
		0.55,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	[2] = TweenInfo.new(
		0.4,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	[3] = TweenInfo.new(
		1,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[4] = TweenInfo.new(
		0.45,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[5] = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0,
		true
	),
	[6] = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[7] = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
		--0,
		--false,
		--0.25
	),
}

-- Variables
local CTE = nil
local TTE = {}
local currentCamera = nil
local oldCF = nil
local currentAnims = {}
local cons = {}
local clones = {}
local currentInfo = {}
local FTES = {}
local currentPreset = {
	["Skin Tone"] = {Color3.new(0.588235, 0.372549, 0.121569).R, Color3.new(0.588235, 0.372549, 0.121569).G, Color3.new(0.588235, 0.372549, 0.121569).B},
	["Hair Color"] = {Color3.new().R, Color3.new().G, Color3.new().B},
	["Eye Color"] = {Color3.new().R, Color3.new().G, Color3.new().B},
	["Race"] = "Human",
	["Hair"] = "Tail Locs",
	["Eyes"] = "Basic Eyes",
	["Mouth"] = "Basic Mouth",
	["Top"] = "Football Shirt",
	["Bottom"] = "Basic Jeans",
	["Accessories"] = {"Diamond Necklace", "Backpack"},
}
local tdColorUISetup = false
local selectingColor = false

-- Constants
local DEFAULTS = {
	Spin = {
		Object = frame:WaitForChild("Spin"),	
		Open = UDim2.new(0.165, 0, 0.05, 0),
		Closed = UDim2.new(-0.215, 0, 0.05, 0),
	},
	ItemBox = {
		Object = frame:WaitForChild("Invbox"),	
		Open = UDim2.new(0.165, 0, 0.189, 0),
		Closed = UDim2.new(-0.215, 0, 0.189, 0),
	},
	Color = {
		Object = frame:WaitForChild("ColorWindow"),	
		Open = UDim2.new(0.14, 0, 0.526, 0),
		Closed = UDim2.new(-0.215, 0, 0.526, 0),

		--Create new Color object using New function
		colorObject = colorPicker.New(ui, plr:GetMouse(), frame:WaitForChild("ColorWindow"))
	},
	Color2 = {
		Object = frame:WaitForChild("ColorWindow2"),
		Open = UDim2.new(0.19, 0, 0.853, 0),
		Closed = UDim2.new(-0.215, 0, 0.853, 0),
	}
}

-- Initialization
local charactercustomization = {}

-- Local Functions
function negCol(col)
	--Inverse Color's Components
	local r, g, b = 0, 0, 0

	r = 255 - (col.R * 255)
	g = 255 - (col.G * 255)
	b = 255 - (col.B * 255)
	return Color3.fromRGB(r, g, b)
end

local function readyCam()
	if not oldCF then
		oldCF = cam.CFrame
	end
	cam.CameraType = "Scriptable"
	cam.CameraSubject = nil
end

local function resetCam(tween)
	if CTE then
		if CTE.PlaybackState == Enum.PlaybackState.Playing then
			CTE:Cancel()
		end
	end
	if not tween then
		cam.CFrame = oldCF or char:WaitForChild("Head").CFrame
	else
		if CTE then
			if CTE.PlaybackState == Enum.PlaybackState.Playing then
				CTE:Cancel()
			end
		end

		CTE = TS:Create(cam, TIS[1], {CFrame = oldCF or char:WaitForChild("Head").CFrame})
		CTE:Play()
		CTE.Completed:Wait()
	end
	cam.CameraType = Enum.CameraType.Follow
	cam.CameraSubject = plr.Character:WaitForChild("Humanoid")
	oldCF = nil
end

local function setCam(cframe, tween)
	readyCam()

	if CTE then
		if CTE.PlaybackState == Enum.PlaybackState.Playing then
			CTE:Cancel()
		end
	end
	if not tween then
		cam.CFrame = cframe
	else
		CTE = TS:Create(cam, TIS[1], {CFrame = cframe})
		CTE:Play()
	end
end

local function startUpPedestal()
	if pedestal then
		if currentAnims["PedestalAnim"] then
			currentAnims["PedestalAnim"]:Stop()
		end

		currentAnims["PedestalAnim"] = pedestal:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator"):LoadAnimation(pedestalAnim)
		currentAnims["PedestalAnim"]:Play()
	end

	if characterDummy then
		if currentAnims["IdleAnim"] then
			currentAnims["IdleAnim"]:Stop()
		end

		currentAnims["IdleAnim"] = characterDummy:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator"):LoadAnimation(idleAnim)
		currentAnims["IdleAnim"]:Play()
	end

	if characterCustomizationArea then
		cons[pedestal] = RS.RenderStepped:Connect(function()
			if characterCustomizationArea and pedestal and characterDummy and offset then
				--local newPosition = pedestal:WaitForChild("Rings"):WaitForChild("InRing").Position + offset
				--local rotationComponentA = characterDummy:GetPivot() - characterDummy:GetPivot().Position
				--local cleanedCFrame = rotationComponentA * CFrame.new(newPosition)

				--characterDummy:PivotTo(cleanedCFrame)

				local newPosition = pedestal:WaitForChild("Rings"):WaitForChild("InRing").Position + offset
				local originalRotation = characterDummy:GetPivot().LookVector
				local newCFrame = CFrame.new(newPosition, newPosition + originalRotation)

				characterDummy:PivotTo(newCFrame)
			end
		end)
	end
end

local function countDict(dict)
	local count = 0
	for i, v in pairs(dict) do
		count += 1
	end
	return count
end

function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach1.Parent
	return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Name = weldName
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

function addAccoutrement(character, accoutrement)  
	accoutrement.Parent = character
	local handle = accoutrement:FindFirstChild("Handle")
	if handle then
		local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
		if accoutrementAttachment then
			local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
			if characterAttachment then
				weldAttachments(characterAttachment, accoutrementAttachment)
			end
		else
			local head = character:FindFirstChild("Head")
			if head then
				local attachmentCFrame = CFrame.new(0, 0.5, 0)
				local hatCFrame = accoutrement.AttachmentPoint
				buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
			end
		end
	end
end

local function runEquipSequence()
	if not characterDummy then return end
	equipEvent:Fire()
	--for i, v in pairs(TTE) do
	--	local TE = v[1]
	--	local ogColor = v[2]
	--	local ogMaterial = v[3]

	--	if TE then
	--		if TE.PlaybackState == Enum.PlaybackState.Playing then
	--			TE:Cancel()
	--		end
	--	end
	--end

	--for i, v in pairs(characterDummy:GetDescendants()) do
	--	if v:IsA("BasePart") then
	--		coroutine.wrap(function()
	--			v.Material = Enum.Material.Neon
	--			TTE[v][1] = TS:Create(v, TIS[5], {Color = Color3.new(1, 1, 1)})
	--			TTE[v][1]:Play()
	--			local con1, con2
	--			local ev = Instance.new("BindableEvent")
	--			local canContinue = true
	--			con1 = TTE[v][1].Completed:Connect(function()
	--				con1:Disconnect()
	--				con2:Disconnect()
	--				ev:Fire()
	--			end)
	--			con2 = equipEvent.Event:Connect(function()
	--				con1:Disconnect()
	--				con2:Disconnect()
	--				canContinue = false
	--				ev:Fire()
	--			end)
	--			ev.Event:Wait()
	--			ev:Destroy()
	--			if canContinue then
	--				if TTE[v][2] then
	--					v.Color = TTE[v][2]
	--				end
	--				if TTE[v][3] then
	--					v.Material = TTE[v][3]
	--				end
	--			end
	--		end)()
	--	end
	--end

	if pedestal then
		pedestal:FindFirstChild("Rings"):FindFirstChild("InRing"):FindFirstChild("Smoke"):Emit(50)
	end
	if characterDummy then
		if currentAnims["EquipAnim"] then
			currentAnims["EquipAnim"]:Stop()
		end

		currentAnims["EquipAnim"] = characterDummy:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator"):LoadAnimation(equipAnim)
		currentAnims["EquipAnim"]:Play(0.5, nil, 1.25) -- fade in time, weight, and speed
		--Instance.new("Animator"):LoadAnimation():Play()
	end
end

local function setupTdUi()
	DEFAULTS.Color2.Object.ColorShower.BackgroundColor3 = getOnGradientSlider(DEFAULTS.Color2.Object.ColorPickerArea.Picker.Position.X.Scale, DEFAULTS.Color2.Object.ColorPickerArea:FindFirstChildOfClass("UIGradient").Color.Keypoints)
	if tdColorUISetup then return end
	tdColorUISetup = true
	-- dispeller 2020
	-- Color picker example

	-- upon the user selecting
	local function beginSelection()
		selectingColor = true
		repeat wait()

			-- left cord of ColorPickerArea in pixels
			local minXPos = DEFAULTS.Color2.Object.ColorPickerArea.AbsolutePosition.X

			-- right cord of ColorPickerArea in pixels
			local maxXPos = minXPos+DEFAULTS.Color2.Object.ColorPickerArea.AbsoluteSize.X

			-- width of ColorPickerArea in pixels
			local xPixelSize = maxXPos-minXPos

			-- raw Mouse X pixel position
			local mouseX = UIS:GetMouseLocation().X

			-- constraints
			if mouseX<minXPos then
				mouseX = minXPos
			elseif mouseX>maxXPos then
				mouseX = maxXPos
			end

			-- get percentage mouse is on
			local xPos = (mouseX-minXPos)/xPixelSize

			-- move the visual Picker line
			DEFAULTS.Color2.Object.ColorPickerArea.Picker.Position = UDim2.new(xPos,0,0.5,0)

			-- set the ColorShower frame color
			DEFAULTS.Color2.Object.ColorShower.BackgroundColor3 = getOnGradientSlider(xPos, DEFAULTS.Color2.Object.ColorPickerArea:FindFirstChildOfClass("UIGradient").Color.Keypoints)

		until not selectingColor
	end

	-- upon the user ending selection
	local function endSelection()
		-- this will stop the loop
		selectingColor = false
	end

	-- check input for selection beginning
	local function inputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginSelection()
		end
	end
	DEFAULTS.Color2.Object.ColorPickerArea.InputBegan:Connect(inputBegan)

	-- check input for selection ending
	local function inputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endSelection()
		end
	end
	DEFAULTS.Color2.Object.ColorPickerArea.InputEnded:Connect(inputEnded)
end

local function openSubCloneUI(subClone, parentClone)
	subEvent:Fire()
	local myInfo = CCUInfo[parentClone.Name].Sub[subClone.Name]
	local sme = clones[parentClone].subClones[subClone]

	if not sme.open then
		for i, fui in pairs(myInfo.UIS) do
			local fuiName, fuiData = fui[1], fui[2]
			if FTES[DEFAULTS[fuiName].Object] then
				if FTES[DEFAULTS[fuiName].Object].PlaybackState == Enum.PlaybackState.Playing then
					FTES[DEFAULTS[fuiName].Object]:Cancel()
				end
			end
			
			for i, v in pairs(clones) do
				for i2, v2 in pairs(v.subClones) do
					if v2.open and i2.Name ~= subClone.Name then
						local theirInfo = CCUInfo[v2.theparentClone.Name].Sub[i2.Name]
						clones[i].subClones[i2].open = false
						local last = nil
						for i, fui2 in pairs(theirInfo.UIS) do
							if cons[DEFAULTS[fui2[1]].Object] then
								for i, v in pairs(cons[DEFAULTS[fui2[1]].Object]) do
									if typeof(v) == 'RBXScriptConnection' then
										v:Disconnect()
									elseif typeof(v) == 'table' then
										for i2, v2 in pairs(v) do
											if typeof(v2) == 'RBXScriptConnection' then
												v2:Disconnect()
											end
										end
									end
								end
								cons[DEFAULTS[fui2[1]].Object] = {}
							end
							local fuiName2, fuiData2 = fui2[1], fui2[2]
							if FTES[DEFAULTS[fuiName2].Object] then
								if FTES[DEFAULTS[fuiName2].Object].PlaybackState == Enum.PlaybackState.Playing then
									FTES[DEFAULTS[fuiName2].Object]:Cancel()
								end
							end
							FTES[DEFAULTS[fuiName2].Object] = TS:Create(DEFAULTS[fuiName2].Object, TIS[7], {Position = DEFAULTS[fuiName2].Closed})
							FTES[DEFAULTS[fuiName2].Object]:Play()
							last = FTES[DEFAULTS[fuiName2].Object]
						end
						if last then
							local con1, con2
							local ev = Instance.new("BindableEvent")
							local canContinue = true
							con1 = last.Completed:Connect(function()
								con1:Disconnect()
								con2:Disconnect()
								ev:Fire()
							end)
							con2 = subEvent.Event:Connect(function()
								con1:Disconnect()
								con2:Disconnect()
								canContinue = false
								ev:Fire()
							end)
							ev.Event:Wait()
							ev:Destroy()
							if not canContinue then return end
						end
					end
				end
			end

			if cons[DEFAULTS[fuiName].Object] then
				for i, v in pairs(cons[DEFAULTS[fuiName].Object]) do
					if typeof(v) == 'RBXScriptConnection' then
						v:Disconnect()
					elseif typeof(v) == 'table' then
						for i2, v2 in pairs(v) do
							if typeof(v2) == 'RBXScriptConnection' then
								v2:Disconnect()
							end
						end
					end
				end
				cons[DEFAULTS[fuiName].Object] = {}
			else
				cons[DEFAULTS[fuiName].Object] = {}
			end

			if fuiName == "Spin" then
			elseif fuiName == "ItemBox" then
				--print(fuiData) -- name of customizaition (Hairs)
				--print(DEFAULTS[fuiName].Object) -- customization frame object (Invbox)
				for i, v in pairs(DEFAULTS[fuiName].Object.Inv:GetChildren()) do
					if v:IsA("TextButton") then
						v:Destroy()
					end
				end
				--print(fuiData)
				--print(currentData.Data.OwnedCosmetics)

				if currentData.Data and currentData.Data.OwnedCosmetics and currentData.Data.OwnedCosmetics[fuiData] and characterDummy and currentPreset[fuiData] then
					for i, v in pairs(currentData.Data.OwnedCosmetics[fuiData]) do
						local clo = script:WaitForChild("Slot"):Clone()
						clo.Name = v
						clo.Ind.Text = v

						if fuiData == "Accessories" then
							if table.find(currentPreset[fuiData], v) then
								clo.UIStroke.Thickness = 3.2
								clo.UIStroke.Color = Color3.new(1, 1, 1) --Color3.new(1, 1)
							end
						else
							if currentPreset[fuiData] == v then
								clo.UIStroke.Thickness = 3.2
								clo.UIStroke.Color = Color3.new(1, 1, 1) --Color3.new(1, 1)
							end
						end

						if cons[DEFAULTS[fuiName].Object][v] then
							cons[DEFAULTS[fuiName].Object][v]:Disconnect()
						end

						cons[DEFAULTS[fuiName].Object][v] = clo.MouseButton1Click:Connect(function()
							if fuiData == "Accessories" then
								if table.find(currentPreset[fuiData], v) then
									table.remove(currentPreset[fuiData], table.find(currentPreset[fuiData], v))
									local oldFound = characterDummy:FindFirstChild(v)
									if oldFound then
										oldFound:Destroy()
									end

									clo.UIStroke.Thickness = 2.3
									clo.UIStroke.Color = Color3.fromRGB(95, 95, 121)
									coroutine.wrap(function()
										runEquipSequence()
									end)()
								else
									local CCAsset = CCAssets:FindFirstChild(fuiData) and CCAssets:FindFirstChild(fuiData):FindFirstChild(v)
									local parent = characterDummy


									if #currentPreset[fuiData] < 3 then
										table.insert(currentPreset[fuiData], v)
									else
										local oldFound = parent:FindFirstChild(currentPreset[fuiData][1])
										if oldFound then
											oldFound:Destroy()
										end
										
										local oldFound2 = DEFAULTS[fuiName].Object.Inv:FindFirstChild(currentPreset[fuiData][1])
										if oldFound2 then
											if oldFound2:IsA("TextButton") and oldFound2 ~= clo then
												oldFound2.UIStroke.Thickness = 2.3
												oldFound2.UIStroke.Color = Color3.fromRGB(95, 95, 121)
											end
										end
										table.remove(currentPreset[fuiData], 1)
										table.insert(currentPreset[fuiData], v)
									end

									clo.UIStroke.Thickness = 3.2
									clo.UIStroke.Color = Color3.new(1, 1, 1) --Color3.new(1, 1)
									if CCAsset then
										local cclone = CCAsset:Clone()
										if CCAsset:IsA("Accessory") then
											addAccoutrement(characterDummy, cclone)
										else
											cclone.Parent = parent 
										end
										coroutine.wrap(function()
											runEquipSequence()
										end)()
									end
								end
							else
								if currentPreset[fuiData] ~= v then
									local CCAsset = CCAssets:FindFirstChild(fuiData) and CCAssets:FindFirstChild(fuiData):FindFirstChild(v)
									if CCAsset then
										local parent = characterDummy
										if fuiData == "Eyes" or fuiData == "Mouth" then
											parent = characterDummy:FindFirstChild("Head")
										end
										local oldFound = parent:FindFirstChild(currentPreset[fuiData])

										if oldFound then
											oldFound:Destroy()
										end

										currentPreset[fuiData] = v
										local cclone = CCAsset:Clone()
										
										if fuiData == "Hair" and currentPreset["Hair Color"] and cclone:FindFirstChild("Handle") then
											cclone:FindFirstChild("Handle").Color = Color3.new(currentPreset["Hair Color"][1], currentPreset["Hair Color"][2], currentPreset["Hair Color"][3])
											if cclone:FindFirstChild("Handle"):FindFirstChild("Excess") then
												cclone:FindFirstChild("Handle"):FindFirstChild("Excess").Color = negCol(cclone:FindFirstChild("Handle").Color)
											end
										elseif fuiData == "Eyes" and currentPreset["Eye Color"] and cclone:IsA("Decal") then
											cclone.Color3 = Color3.new(currentPreset["Eye Color"][1], currentPreset["Eye Color"][2], currentPreset["Eye Color"][3]) 
										end
										
										if CCAsset:IsA("Accessory") then
											addAccoutrement(characterDummy, cclone)
										else
											cclone.Parent = parent 
										end

										clo.UIStroke.Thickness = 3.2
										clo.UIStroke.Color = Color3.new(1, 1, 1) --Color3.new(1, 1)

										for i, v in pairs(DEFAULTS[fuiName].Object.Inv:GetChildren()) do
											if v:IsA("TextButton") and v ~= clo then
												v.UIStroke.Thickness = 2.3
												v.UIStroke.Color = Color3.fromRGB(95, 95, 121)
											end
										end
										coroutine.wrap(function()
											runEquipSequence()
										end)()
									end
								end	
							end
						end)

						clo.Parent = DEFAULTS[fuiName].Object.Inv
					end
				end
			elseif fuiName == "Color" then
				local same = nil

				for i, v in pairs(cons[DEFAULTS[fuiName].Object]) do
					v:Disconnect()
				end
				
				cons[DEFAULTS[fuiName].Object][fuiName] = DEFAULTS[fuiName].Object.UpdateEvent.Event:Connect(function(color)
					--print(fuiData)
					--print(color)

					if subClone.Name == "Hair" then
						currentPreset["Hair Color"] = {color.R, color.G, color.B}

						local foundHair = currentPreset["Hair"] and characterDummy:FindFirstChild(currentPreset["Hair"])
						if foundHair and foundHair:IsA("Accessory") then
							foundHair:FindFirstChild("Handle").Color = color
							if foundHair:FindFirstChild("Handle"):FindFirstChild("Excess") then
								foundHair:FindFirstChild("Handle"):FindFirstChild("Excess").Color = negCol(foundHair:FindFirstChild("Handle").Color)
							end	
						end
					end
					
					same = color
					coroutine.wrap(function()
						task.wait(0.25)
						if same == color then
							runEquipSequence()
						end
					end)()
				end)
			elseif fuiName == "Color2" then
				local same = nil
				DEFAULTS.Color2.Object.ColorPickerArea.Gradient.Color = fuiData
				setupTdUi()

				for i, v in pairs(cons[DEFAULTS[fuiName].Object]) do
					v:Disconnect()
				end

				cons[DEFAULTS[fuiName].Object][fuiName] = DEFAULTS[fuiName].Object.ColorShower:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
					local color = DEFAULTS[fuiName].Object.ColorShower.BackgroundColor3

					--print(fuiData)
					--print(color)

					if subClone.Name == "Skin Tone" then
						currentPreset["Skin Tone"] = {color.R, color.G, color.B}

						characterDummy["Body Colors"].HeadColor3 = color
						characterDummy["Body Colors"].TorsoColor3 = color
						characterDummy["Body Colors"].LeftArmColor3 = color
						characterDummy["Body Colors"].LeftLegColor3 = color
						characterDummy["Body Colors"].RightArmColor3 = color
						characterDummy["Body Colors"].RightLegColor3 = color
					elseif subClone.Name == "Eyes" then
						currentPreset["Eye Color"] = {color.R, color.G, color.B}

						local foundDecal = currentPreset["Eyes"] and characterDummy:FindFirstChild("Head"):FindFirstChild(currentPreset["Eyes"])
						if foundDecal and foundDecal:IsA("Decal") then
							foundDecal.Color3 = color
						end
					end
					
					same = color
					coroutine.wrap(function()
						task.wait(0.25)
						if same == color then
							runEquipSequence()
						end
					end)()
				end)
			end
			FTES[DEFAULTS[fuiName].Object] = TS:Create(DEFAULTS[fuiName].Object, TIS[6], {Position = DEFAULTS[fuiName].Open})
		end
	else
		for i, fui in pairs(myInfo.UIS) do
			local fuiName, fuiData = fui[1], fui[2]
			--print(cons[DEFAULTS[fuiName].Object])
			if cons[DEFAULTS[fuiName].Object] then
				for i, v in pairs(cons[DEFAULTS[fuiName].Object]) do
					if typeof(v) == 'RBXScriptConnection' then
						v:Disconnect()
					elseif typeof(v) == 'table' then
						for i2, v2 in pairs(v) do
							if typeof(v2) == 'RBXScriptConnection' then
								--print(v)
								v2:Disconnect()
							end
						end
					end
				end
				cons[DEFAULTS[fuiName].Object] = {}
			end
			if FTES[DEFAULTS[fuiName].Object] then
				if FTES[DEFAULTS[fuiName].Object].PlaybackState == Enum.PlaybackState.Playing then
					FTES[DEFAULTS[fuiName].Object]:Cancel()
				end
			end
			FTES[DEFAULTS[fuiName].Object] = TS:Create(DEFAULTS[fuiName].Object, TIS[7], {Position = DEFAULTS[fuiName].Closed})
		end
	end
	for i, fui in pairs(myInfo.UIS) do
		local fuiName, fuiData = fui[1], fui[2]
		FTES[DEFAULTS[fuiName].Object]:Play()
	end
	sme.open = not sme.open
end

local function bindSubClone(subClone, parentClone)
	--local currentData = getData:InvokeServer("Character")
	--print(subClone)
	local pme = clones[parentClone]
	pme.subClones[subClone] = {
		TES = {},
		Cons = {},
		defaultColor = subClone.BackgroundColor3,
		hoverColor = Color3.fromRGB(163, 163, 185),
		defaultSize = subClone.Ind.Size,
		defaultIndPos = subClone.Ind.Position,
		indShift = Vector2.new(0.07, 0),
		sizeIncrease = Vector2.new(0.1, 0.01),
		inClick = false,
		open = false,
		theparentClone = parentClone 
	}
	local sme = pme.subClones[subClone]

	table.insert(sme.Cons, subClone.MouseButton1Click:Connect(function()
		if sme.inClick then return end
		if characterCustomizationArea and cameras then
			coroutine.wrap(function()
				setCam(cameras:FindFirstChild(CCUInfo[parentClone.Name].Sub[subClone.Name].Camera or "HalfOverview").CFrame, true)
			end)()
			--coroutine.wrap(function()
			openSubCloneUI(subClone, parentClone)
			--end)()
			--coroutine.wrap(function()
			--	runEquipSequence()
			--end)() -- OPTIONAL
		end
		sme.InClick = true
		if sme.TES[subClone] then
			if sme.TES[subClone].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[subClone]:Cancel()
			end
		end
		sme.TES[subClone] = TS:Create(subClone.Ind, TIS[2], {Size = UDim2.new(sme.defaultSize.X.Scale + sme.sizeIncrease.X, 0, sme.defaultSize.Y.Scale + sme.sizeIncrease.Y, 0)})
		sme.TES[subClone]:Play()
		sme.TES[subClone].Completed:Wait()
		sme.TES[subClone] = TS:Create(subClone.Ind, TIS[4], {Size = sme.defaultSize})
		sme.TES[subClone]:Play()
		sme.InClick = false
	end))

	table.insert(sme.Cons, subClone.MouseEnter:Connect(function()
		if sme.TES[subClone.Ind] then
			if sme.TES[subClone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[subClone.Ind]:Cancel()
			end
		end
		-- using img to store clone color tween cause im lazy
		if sme.TES[subClone.Img] then
			if sme.TES[subClone.Img].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[subClone.Img]:Cancel()
			end
		end
		sme.TES[subClone.Ind] = TS:Create(subClone.Ind, TIS[4], {Position = UDim2.new(sme.defaultIndPos.X.Scale + sme.indShift.X, 0, sme.defaultIndPos.Y.Scale + sme.indShift.Y, 0)})
		sme.TES[subClone.Img] = TS:Create(subClone, TIS[4], {BackgroundColor3 = sme.hoverColor})
		sme.TES[subClone.Ind]:Play()
		sme.TES[subClone.Img]:Play()
	end))

	table.insert(sme.Cons, subClone.MouseLeave:Connect(function()
		if sme.TES[subClone.Ind] then
			if sme.TES[subClone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[subClone.Ind]:Cancel()
			end
		end
		if sme.TES[subClone.Img] then
			if sme.TES[subClone.Img].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[subClone.Img]:Cancel()
			end
		end

		sme.TES[subClone.Ind] = TS:Create(subClone.Ind, TIS[4], {Position = sme.defaultIndPos})
		sme.TES[subClone.Img] = TS:Create(subClone, TIS[4], {BackgroundColor3 = sme.defaultColor})
		sme.TES[subClone.Ind]:Play()
		sme.TES[subClone.Img]:Play()
	end))
end

local function bindClone(clone)
	clones[clone] = {
		Cons = {},
		TES = {},
		TES2 = {},
		Open = false,
		changed = Instance.new("BindableEvent"),
		exOpen = exUI:FindFirstChild("Open"..tostring(countDict(CCUInfo[clone.Name].Sub))),
		defaultSize = exUI:FindFirstChild("Closed").Size,
		openSize = exUI:FindFirstChild("Open"..tostring(countDict(CCUInfo[clone.Name].Sub))).Size,
		defaultColor = clone.BackgroundColor3,
		hoverColor = Color3.fromRGB(183, 183, 208),
		indShift = Vector2.new(0.105, 0),
		subClones = {}
	}
	if not clones[clone].exOpen then return end

	if not clone:FindFirstChild("Sub") then
		local sClone = clones[clone].exOpen.Sub:Clone()
		sClone.Size = exSub.Size
		sClone.Position = exSub.Position
		sClone.Visible = false
		local used = {}
		local first, last = false, false
		for i, v in pairs(CCUInfo[clone.Name].Sub) do
			local count = 1
			local found = nil
			repeat
				if count <= #sClone:GetChildren() then
					found = sClone:GetChildren()[count]
				else
					found = nil
				end
				count += 1
			until
			(found and (found:IsA("TextButton") and not table.find(used, found))) or count > #sClone:GetChildren()
			if found and found:isA("TextButton") and not table.find(used, found) then
				table.insert(used, found)
				found.Name = i
				found.Ind.Text = i
				found.Img.Image = v.Icon
				found.LayoutOrder = v.SubOrder
				local ffound = found:FindFirstChildOfClass("UICorner")
				if ffound then
					ffound:Destroy()
				end
				if v.SubOrder <= 1 and not first then
					first = true
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0.05, 0)
					uiCorner.Parent = found
				elseif v.SubOrder >= countDict(CCUInfo[clone.Name].Sub) and not last then
					last = true
					local uiCorner = Instance.new("UICorner")
					uiCorner.CornerRadius = UDim.new(0.1, 0)
					uiCorner.Parent = found
				end
				bindSubClone(found, clone)
			end
		end
		sClone.Parent = clone
	end

	table.insert(clones[clone].Cons, clone.MouseButton1Click:Connect(function()
		local me = clones[clone]
		me.changed:Fire()
		if me.TES[clone] then
			if me.TES[clone].PlaybackState == Enum.PlaybackState.Playing then
				me.TES[clone]:Cancel()
			end
		end
		if me.TES[clone.Ind] then
			if me.TES[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				me.TES[clone.Ind]:Cancel()
			end
		end
		if me.TES[clone.Img] then
			if me.TES[clone.Img].PlaybackState == Enum.PlaybackState.Playing then
				me.TES[clone.Img]:Cancel()
			end
		end
		if me.TES[clone.Sub] then
			if me.TES[clone.Sub].PlaybackState == Enum.PlaybackState.Playing then
				me.TES[clone.Sub]:Cancel()
			end
		end
		if me.TES2[clone.Ind] then
			if me.TES2[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				me.TES2[clone.Ind]:Cancel()
			end
		end

		if me.Open then
			me.Open = false
			me.TES[clone] = TS:Create(clone, TIS[3], {Size = me.defaultSize})
			me.TES[clone.Ind] = TS:Create(clone.Ind, TIS[3], {Size = exUI:FindFirstChild("Closed").Ind.Size, Position = exUI:FindFirstChild("Closed").Ind.Position})
			me.TES[clone.Img] = TS:Create(clone.Img, TIS[3], {Size = exUI:FindFirstChild("Closed").Img.Size, Position = exUI:FindFirstChild("Closed").Img.Position, Rotation = exUI:FindFirstChild("Closed").Img.Rotation})
			me.TES[clone.Sub] = TS:Create(clone.Sub, TIS[3], {Size = exSub.Size, Position = exSub.Position})
			me.TES[clone]:Play()
			me.TES[clone.Ind]:Play()
			me.TES[clone.Img]:Play()
			me.TES[clone.Sub]:Play()

			-- wait for stuff to finish
			local ev = Instance.new("BindableEvent")
			local canContinue = true
			coroutine.wrap(function()
				task.wait(TIS[3].Time * 0.625)
				if canContinue then
					clone.Sub.Visible = false
				end
			end)()
			local con1, con2
			con1 = me.TES[clone].Completed:Connect(function()
				con1:Disconnect()
				con2:Disconnect()
				ev:Fire()
			end)
			con2 = me.changed.Event:Connect(function()
				con1:Disconnect()
				con2:Disconnect()
				canContinue = false
				ev:Fire()
			end)
			ev.Event:Wait()
			ev:Destroy()
			if not canContinue then return end
			--if clone:FindFirstChild("Sub") then
			--	clone:FindFirstChild("Sub"):Destroy()
			--end
		else
			me.Open = true
			clone.Sub.Visible = true
			me.TES[clone] = TS:Create(clone, TIS[2], {Size = me.openSize})
			me.TES[clone.Ind] = TS:Create(clone.Ind, TIS[2], {Size = me.exOpen.Ind.Size, Position = me.exOpen.Ind.Position})
			me.TES[clone.Img] = TS:Create(clone.Img, TIS[2], {Size = me.exOpen.Img.Size, Position = me.exOpen.Img.Position, Rotation = me.exOpen.Img.Rotation})
			me.TES[clone.Sub] = TS:Create(clone.Sub, TIS[2], {Size = me.exOpen.Sub.Size, Position = me.exOpen.Sub.Position})
			me.TES[clone]:Play()
			me.TES[clone.Ind]:Play()
			me.TES[clone.Img]:Play()
			me.TES[clone.Sub]:Play()
		end
	end))

	table.insert(clones[clone].Cons, clone.Ind.MouseEnter:Connect(function()
		local me = clones[clone]
		local canInd = true
		if me.TES[clone.Ind] then
			if me.TES[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				canInd = false
			end
		end
		if me.TES2[clone] then
			if me.TES2[clone].PlaybackState == Enum.PlaybackState.Playing then
				me.TES2[clone]:Cancel()
			end
		end
		if canInd then
			if me.TES2[clone.Ind] then
				if me.TES2[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
					me.TES2[clone.Ind]:Cancel()
				end
			end
			if me.Open then
				me.TES2[clone.Ind] = TS:Create(clone.Ind, TIS[4], {Position = UDim2.new(me.exOpen.Ind.Position.X.Scale + me.indShift.X, 0, me.exOpen.Ind.Position.Y.Scale + me.indShift.Y, 0)})
			else
				me.TES2[clone.Ind] = TS:Create(clone.Ind, TIS[4], {Position = UDim2.new(exUI:FindFirstChild("Closed").Ind.Position.X.Scale + me.indShift.X, 0, exUI:FindFirstChild("Closed").Ind.Position.Y.Scale + me.indShift.Y, 0)})
			end
			me.TES2[clone.Ind]:Play()
		end
		me.TES2[clone] = TS:Create(clone, TIS[4], {BackgroundColor3 = me.hoverColor})
		me.TES2[clone]:Play()
	end))

	table.insert(clones[clone].Cons, clone.Ind.MouseLeave:Connect(function()
		local me = clones[clone]
		local canInd = true
		if me.TES[clone.Ind] then
			if me.TES[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
				canInd = false
			end
		end
		if me.TES2[clone] then
			if me.TES2[clone].PlaybackState == Enum.PlaybackState.Playing then
				me.TES2[clone]:Cancel()
			end
		end
		if canInd then
			if me.TES2[clone.Ind] then
				if me.TES2[clone.Ind].PlaybackState == Enum.PlaybackState.Playing then
					me.TES2[clone.Ind]:Cancel()
				end
			end
			if me.Open then
				me.TES2[clone.Ind] = TS:Create(clone.Ind, TIS[4], {Position = me.exOpen.Ind.Position})
			else
				me.TES2[clone.Ind] = TS:Create(clone.Ind, TIS[4], {Position = exUI:FindFirstChild("Closed").Ind.Position})
			end
			me.TES2[clone.Ind]:Play()
		end
		me.TES2[clone] = TS:Create(clone, TIS[4], {BackgroundColor3 = me.defaultColor})
		me.TES2[clone]:Play()
	end))
end


local function setupUI()
	for i, v in pairs(box:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	for i, header in pairs(CCUInfo) do
		local closeClone = exUI.Closed:Clone()
		closeClone.Name = i
		closeClone.Ind.Text = i
		closeClone.LayoutOrder = header.Order
		bindClone(closeClone)
		closeClone.Parent = box
	end
end

-- Global Variables
charactercustomization.FinishedCustomization = Instance.new("BindableEvent") 
charactercustomization.undoStuff = false

-- Global Functions
function charactercustomization.stop()
	for oi, v in pairs(clones) do
		for i, subCloneSlot in pairs(v.subClones) do
			for i, con in pairs(subCloneSlot.Cons) do
				con:Disconnect()
			end
		end
		for i, con in pairs(v.Cons) do
			con:Disconnect()
		end
	end
	CCReplicator:FireServer(currentPreset)

	if charactercustomization.FinishedCustomization then
		charactercustomization.FinishedCustomization:Fire()
	end
	
	repeat wait() until charactercustomization.undoStuff == true
	
	resetCam()
	hrp.Anchored = false
	

	for i, v in pairs(currentAnims) do
		v:Stop()
	end

	if characterCustomizationArea then
		characterCustomizationArea:Destroy()
	end
	offset = nil

	for i, v in pairs(cons) do
		if typeof(v) == 'RBXScriptConnection' then
			v:Disconnect()
		elseif typeof(v) == 'table' then
			for i2, v2 in pairs(v) do
				if typeof(v2) == 'RBXScriptConnection' then
					v2:Disconnect()
				end
			end
		end
	end
end

function charactercustomization.testCams()
	for i, v in pairs(cameras:GetChildren()) do
		if characterCustomizationArea then
			if v.Name == "Overview" then return end
			setCam(v.CFrame, true)
			task.wait(5)
		end
	end
end

function charactercustomization.setup(skip)
	if skip then
		charactercustomization.stop()
		return
	end
	hrp.Anchored = true
	characterCustomizationArea = Storage:WaitForChild("CutsceneStuff"):WaitForChild("Areas"):WaitForChild("Character Customization Area"):Clone()
	offset = characterCustomizationArea:WaitForChild("Me"):GetPivot().Position - characterCustomizationArea:WaitForChild("Pedestal"):WaitForChild("Rings"):WaitForChild("InRing").Position
	characterCustomizationArea.Parent = workspace

	characterDummy = characterCustomizationArea:WaitForChild("Me")
	cameras = characterCustomizationArea:WaitForChild("Cameras")
	pedestal = characterCustomizationArea:WaitForChild("Pedestal")

	for i, v in pairs(characterDummy:GetDescendants()) do
		if v:IsA("BasePart") then
			TTE[v] = {nil, v.Color, v.Material}
		end
	end
	
	characterDummy:WaitForChild("Humanoid"):ApplyDescription(Storage:WaitForChild("CharacterBases").BaseCharacter)
	currentData = getData:InvokeServer("Character")
	currentPreset = currentData.Data.Presets[currentData.Data.CurrentPreset]

	for fuiData, v in pairs(currentPreset) do
		if fuiData == "Skin Tone" then
			local skinColor = Color3.new(currentPreset["Skin Tone"][1], currentPreset["Skin Tone"][2], currentPreset["Skin Tone"][3]) 
			characterDummy["Body Colors"].HeadColor3 = skinColor
			characterDummy["Body Colors"].TorsoColor3 = skinColor
			characterDummy["Body Colors"].LeftArmColor3 = skinColor
			characterDummy["Body Colors"].LeftLegColor3 = skinColor
			characterDummy["Body Colors"].RightArmColor3 = skinColor
			characterDummy["Body Colors"].RightLegColor3 = skinColor
		elseif fuiData == "Accessories" then
			for i, v2 in pairs(v) do
				local CCAsset = CCAssets:FindFirstChild(fuiData) and CCAssets:FindFirstChild(fuiData):FindFirstChild(v2)
				local parent = characterDummy
				--local oldFound = parent:FindFirstChild(currentPreset[fuiData])

				--if oldFound then
				--	oldFound:Destroy()
				--end
				if CCAsset then
					local cclone = CCAsset:Clone()
					if cclone:IsA("Accessory") then
						addAccoutrement(characterDummy, cclone)
					else
						cclone.Parent = parent 
					end 
				end
			end
		elseif fuiData ~= "Eye Color" and fuiData ~= "Hair Color" and fuiData ~= "Race" then
			local CCAsset = CCAssets:FindFirstChild(fuiData) and CCAssets:FindFirstChild(fuiData):FindFirstChild(v)
			if CCAsset then
				local parent = characterDummy
				if fuiData == "Eyes" or fuiData == "Mouth" then
					parent = characterDummy:FindFirstChild("Head")
				end
				local oldFound = parent:FindFirstChild(currentPreset[fuiData])

				if oldFound then
					oldFound:Destroy()
				end

				local cclone = CCAsset:Clone()
				
				if fuiData == "Hair" and currentPreset["Hair Color"] and cclone:FindFirstChild("Handle") then
					cclone:FindFirstChild("Handle").Color = Color3.new(currentPreset["Hair Color"][1], currentPreset["Hair Color"][2], currentPreset["Hair Color"][3]) 
					if cclone:FindFirstChild("Handle"):FindFirstChild("Excess") then
						cclone:FindFirstChild("Handle"):FindFirstChild("Excess").Color = negCol(cclone:FindFirstChild("Handle").Color)
					end	
				elseif fuiData == "Eyes" and currentPreset["Eye Color"] and cclone:IsA("Decal") then
					cclone.Color3 = Color3.new(currentPreset["Eye Color"][1], currentPreset["Eye Color"][2], currentPreset["Eye Color"][3]) 
				end
				
				if cclone:IsA("Accessory") then
					addAccoutrement(characterDummy, cclone)
				else
					cclone.Parent = parent 
				end 
			end
		end
	end

	setCam(cameras:WaitForChild("HalfOverview").CFrame, false)
	startUpPedestal()
	
	table.insert(cons, ctnBtn.MouseEnter:Connect(function()
		if FTES[ctnBtn] then
			if FTES[ctnBtn].PlaybackState == Enum.PlaybackState.Playing then
				FTES[ctnBtn]:Cancel()
			end
		end
		if FTES[ctnBtn.UIStroke] then
			if FTES[ctnBtn.UIStroke].PlaybackState == Enum.PlaybackState.Playing then
				FTES[ctnBtn.UIStroke]:Cancel()
			end
		end
		FTES[ctnBtn] = TS:Create(ctnBtn, TIS[4], {BackgroundColor3 = Color3.fromRGB(62, 62, 86)})
		FTES[ctnBtn]:Play()

		FTES[ctnBtn.UIStroke] = TS:Create(ctnBtn.UIStroke, TIS[4], {Thickness = 4.5})
		FTES[ctnBtn.UIStroke]:Play()
	end))
	table.insert(cons, ctnBtn.MouseLeave:Connect(function()
		if FTES[ctnBtn] then
			if FTES[ctnBtn].PlaybackState == Enum.PlaybackState.Playing then
				FTES[ctnBtn]:Cancel()
			end
		end
		if FTES[ctnBtn.UIStroke] then
			if FTES[ctnBtn.UIStroke].PlaybackState == Enum.PlaybackState.Playing then
				FTES[ctnBtn.UIStroke]:Cancel()
			end
		end
		FTES[ctnBtn] = TS:Create(ctnBtn, TIS[4], {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
		FTES[ctnBtn]:Play()

		FTES[ctnBtn.UIStroke] = TS:Create(ctnBtn.UIStroke, TIS[4], {Thickness = 2.5})
		FTES[ctnBtn.UIStroke]:Play()
	end))
	table.insert(cons, ctnBtn.MouseButton1Click:Connect(function()
		charactercustomization.stop()
	end))

	--task.wait(15)
	--charactercustomization.testCams()

	--task.wait(5)
	--charactercustomization.stop()

	setupUI()
end

return charactercustomization