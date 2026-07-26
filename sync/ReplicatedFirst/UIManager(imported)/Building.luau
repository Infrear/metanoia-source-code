-- Services
local RS = game:GetService("RunService")
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Builds = Storage:WaitForChild("Builds")
local Vehicles = Storage:WaitForChild("Vehicles")
local keySettings = require(Storage.Info.KeybindsMaster)
local gameSettings = require(Storage.Info.GameSettings)
local buildingSettings = gameSettings.BuildingSettings
local buildInfo = require(Storage.Info.BuildInfo)
local craftingIndex = require(Storage.Info.CraftingIndex)
local StartBuild = Storage.Events.Remotes:WaitForChild("StartBuild")
local StartBuildCli = Storage.Events.Standard:WaitForChild("StartBuild")
local PlaceBuild = Storage.Events.Remotes:WaitForChild("PlaceBuild")
local getData = Storage:WaitForChild("Functions").Remotes.GetData

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")
local mouse = plr:GetMouse()

local ui = playerGUI:WaitForChild("Interactables")
local frame = ui:WaitForChild("Building")
local sliding = require(script:WaitForChild("Sliding"))
local invDataStorer = require(playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"))
local clientUpdEv = playerGUI:WaitForChild("UIManager"):WaitForChild("Events"):WaitForChild("UpdInv")

local stopEvent = Instance.new("BindableEvent", script)
local startEvent = Instance.new("BindableEvent", script)

local TIS = {
	TweenInfo.new(
		0.65,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	--TweenInfo.new(
	--	0.5,
	--	Enum.EasingStyle.Quad,
	--	Enum.EasingDirection.Out
	--),
	TweenInfo.new(
		0.45,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
}

-- Local Variables
local TES = {}
local cons = {}

local canplace = true
local closestStruct = nil
local grounded = false
local e = frame:WaitForChild("Eror")
local a1 = nil
local a2 = nil

local freeFrame = nil
local state1 = true
local rotkeydown = false
local currentHit = nil
local grounded = false
local cursnap = nil
local invObjectIndex = nil

local placedBuild = nil
local currentBuildName, currentBuildObj, currentBuildType, currentBuildInfo, currentStation, currentMaterials = nil
--local curHasLeft = false
local curTool = nil

-- Constants
local MAX_PLACE = 25
local MIN_PLACE = 5

-- Initialization
local building = {}

-- Global Variables
building.placing = false
building.totalRot = Vector3.new(0, 0, 0)
building.yPos = 0
building.buildDraft = nil
building.buildStation = nil
building.CPressed = Instance.new("BindableEvent")

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

function BindCancelKey(key)
	if key ~= keySettings.UI["Crafting"] then
		table.insert(cons, building.CPressed.Event:Connect(function()
			building.stop()
		end))
	else
		table.insert(cons, UIS.InputBegan:Connect(function(input)
			if input == key then
				building.stop()
			end
		end))
	end
end

local mpules = {
	0,
	45,
	90,
	135,
	180,
	225,
	270,
	315,
	360
}

function rInputStart()
	local did = false
	local con
	con = UIS.InputEnded:Connect(function(inp)
		if inp.KeyCode ~= keySettings.Building.Rotate then return end
		con:Disconnect()
		con = nil
		did = true
		if (not (building.totalRot.Y%45 == 0)) and (building.totalRot.Y > 0) then
			local find = 0
			local closest = math.huge
			local opt = building.totalRot.Y
			for i, v in pairs(mpules) do
				local n1, n2 = 0, 0
				n1 = math.abs(opt)
				n2 = math.abs(v)
				if math.abs(n1 - n2) < closest and building.totalRot.Y < v then
					closest = n1 - n2
					find = v
				end
			end
			if find then
				building.totalRot = Vector3.new(building.totalRot.X, find, building.totalRot.Z)
			else
				building.totalRot = Vector3.zero
			end
			rotkeydown = false		
		else
			building.totalRot += Vector3.new(0, 45, 0)
			--building.totalRot.Y += 45
			if building.totalRot.Y >= 360 then building.totalRot = Vector3.new(building.totalRot.X, 0, building.totalRot.Z) end
		end
	end)
	wait(1)
	if con then
		con:Disconnect()
	end
	if not did then
		rotkeydown = true
		local rotSpeed = 5
		while rotkeydown do
			wait(0.01)
			if building.placing then
				building.totalRot += Vector3.new(0, rotSpeed, 0)								
			end
		end
	end
end

-- do it to u
-- do it to u
-- do it to u
-- hate to do it to u
function seeknDestroyObj(obj)
	local last =  nil
	for i, v in pairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then
			local TE = TS:Create(v, TIS[1], {Transparency = 1})
			TE:Play()
			last = TE
		end
	end
	if last then
		if last.PlaybackState == Enum.PlaybackState.Playing then
			last.Completed:Wait()
		end
	end
	obj:Destroy()
end

local function findat(mod, tip)
	for i, v in pairs(mod:GetDescendants()) do
		--print(v)
		--print(tip)
		if v:IsA("Attachment") and v.Name == tip then
			return true
		end
	end
end

function findTargetMod(pos)
	local list = workspace.BUILDS:GetChildren()
	table.insert(list, currentBuildObj)
	local hrp = nil
	local dist = 50
	local var = nil
	local var2 = nil
	--- iterating through the workspace array
	for x = 1, #list do
		var2 = list[x]
		if (var2:IsA("Model")) and (var2 ~= currentBuildObj) then
			if findat(var2, currentBuildInfo.BuildType) and findat(currentBuildObj, buildInfo[var2.Name].BuildType) then
				var = var2.PrimaryPart
				if (var ~= nil) then
					if (var.Position - pos).magnitude < dist then
						hrp = var
						dist = (var.Position - pos).magnitude
					end
				end
			end
		end
	end
	return hrp
end

function cInputStart()
	building.stop()
end

--local iev = Instance.new("BindableEvent")

function InputEnded(input)
	if input.KeyCode == keySettings.Building.Rotate then
		rotkeydown = false		
	end
end

function placeBuild()
	if building.placing and canplace then
		--task.wait(10)
		local StructureCFrame = currentBuildObj:GetPivot()
		--print(StructureCFrame)
		--print(currentHit)
		
		local got = false
		local con
		con = PlaceBuild.OnClientEvent:Connect(function(placed)
			--print(placed)
			got = true
			placedBuild = placed
		end)
		
		PlaceBuild:FireServer(currentBuildName, StructureCFrame, currentStation, invObjectIndex, currentHit, currentMaterials)

		if currentBuildInfo.VehicleStats then
			building.stop()
			return
		end
		
		--print("start")
		repeat wait() until got
		--print("end")
		
		if placedBuild then
			placedBuild = false
			--currentBuildObj:Destroy()
			--building.start()
			--seeknDestroyObj(currentBuildObj)
		end
	end
end

function InputStarted(input, gameProcessedEvent)
	if input.KeyCode == keySettings.Building.Rotate then
		rInputStart()
	elseif input.KeyCode == keySettings.Building.Cancel then
		cInputStart()
	elseif input.UserInputType == keySettings.Building["Confirm Placement"] then
		if not gameProcessedEvent then
			placeBuild()
		end
	end
end

-- attatch stuff
function BindAttach(at1, at2)
	if at1 and at2 then
		local floor = at2.Parent
		local wall = nil
		if at1 ~= nil then
			if at1.Parent ~= nil then
				wall = at1.Parent 
			end
		end

		--local wallCframe = (at2.WorldPosition * at2.Position):Lerp((at2.WorldPosition * at1.Position), 0.5)

		local wallPos = nil
		if frame:GetAttribute("Mode") == "Snap" then
			wallPos = (at2.WorldPosition + -(at1.Position))
		elseif frame:GetAttribute("Mode") == "Edge" then
			wallPos = (at2.WorldPosition + at1.Position)
		end
		local wallCF = CFrame.new(wallPos)
		--wallCF *= CFrame.Angles(math.rad(at2.Orientation.X), math.rad(at2.Orientation.Y), math.rad(at2.Orientation.Z))
		----wallCF *= (at2.WorldCFrame - at2.WorldCFrame.Position)
		--if at1.Position.Y == at2.Position.Y then
		--	local old = wallCF
		--	wallCF = old * CFrame.new(0, -old.Y, 0)
		--	wallCF *= CFrame.new(0, at1.WorldCFrame.Y, 0)
		--end
		local oldp = wall.Parent.PrimaryPart
		wall.Parent.PrimaryPart = wall
		--[[
			--wall.Parent:PivotTo(wallCF * CFrame.fromOrientation(0, math.rad(yPos), 0))
			--print(at1.WorldCFrame:ToEulerAnglesXYZ()) 
			--print(at1.WorldCFrame)
			--print(Vector3.new(1, 1, at1.WorldCFrame:ToEulerAnglesXYZ()))
			--print(Vector3.new(1, 1, 1) + at1.WorldCFrame:ToEulerAnglesXYZ())
			--print(at1.WorldCFrame - at1.WorldCFrame:ToEulerAnglesXYZ())
			--wallCF = at2.WorldCFrame:Lerp((at1.WorldCFrame - Vector3.new(at1.WorldCFrame:ToEulerAnglesXYZ())), 0.5)
			--wallCF -= Vector3.new(at2.WorldCFrame:Lerp((at1.WorldCFrame - Vector3.new(at1.WorldCFrame:ToEulerAnglesXYZ())), 0.5):ToEulerAnglesXYZ())
			--wallCF *= at2.WorldCFrame - at2.WorldCFrame.Position
		]]--
		if frame:GetAttribute("Mode") == "Snap" then
			--wallPos = (at2.WorldPosition + -(at1.Position))
			--print(at1)
			--print(at2)
			wallCF = at2.WorldCFrame * CFrame.new(-at1.CFrame.Position)
		elseif frame:GetAttribute("Mode") == "Edge" then
			--wallPos = (at2.WorldPosition + at1.Position)
			wallCF = at2.WorldCFrame * CFrame.new(at1.CFrame.Position)
		end
		wall.Parent:PivotTo(wallCF)
		if at2:GetAttribute("Retter") then
			local oldr = nil
			--local find = fakeStruct:FindFirstDescendant("Rottie")
			local find = wall.Parent:FindFirstChild("Rottie")
			if find then
				oldr = wall.Parent.PrimaryPart
				wall.Parent.PrimaryPart = find
			end
			wall.Parent:PivotTo(wall.Parent:GetPivot() * CFrame.Angles(0, math.rad(building.totalRot.Y), 0))
			if find and oldr then
				wall.Parent.PrimaryPart = oldr
			end
		end
		wall.Parent.PrimaryPart = oldp
		if currentBuildName ~= "Wood Base" and not grounded then
			currentHit = floor:FindFirstAncestorOfClass("Model")
		end
		cursnap = floor:FindFirstAncestorOfClass("Model")
	end
end

function GetClosestAttachment(pt, p2)
	local closestDist = math.huge
	local closestAttach = nil
	--print(p2.Type.Value)

	for i, v in pairs(pt:GetDescendants()) do
		--print(v.Name)
		if v:IsA("Attachment") and v.Name == buildInfo[p2.Name].BuildType and v:FindFirstChild("Bal") == nil then
			local mousePos = mouse.Hit.Position
			local worldPos = v.WorldPosition
			local distance = (mousePos - worldPos).Magnitude
			if distance < closestDist then 
				closestDist = distance
				closestAttach = v
			end 
		end
	end 
	--print(closestAttach:FindFirstAncestorOfClass("Model"))
	--print(pt)
	return closestAttach
end 

function GetNearestAttachment(attachments, at)
	if at ~= nil then
		local closestDist = math.huge
		local closestAttach
		for i,v in pairs(attachments) do
			if (v.ClassName == "Attachment") and v.Name == currentBuildInfo.BuildType then
				local mousePos = at.WorldPosition
				local worldPos = v.WorldPosition
				local distance = (mousePos - worldPos).Magnitude
				if distance < closestDist then 
					closestDist = distance
					closestAttach = v
				end 
			end
		end 
		return closestAttach
	end
end 
--

local function bindToRenderStep()
	table.insert(cons, RS.RenderStepped:Connect(function()
		local mpos = Vector2.new(mouse.X, mouse.Y)
		canplace = true
		
		local cando = true
		if checkPlatform() == "Mobile" then
			if (Vector2.new(375, 154) - mpos).Magnitude < 75 then
				cando = false
			end	
		end
		--print(currentBuildObj:GetPivot())
		local tgrounded = false
		if cando == true then
			local mouseRay = mouse.UnitRay
			local rParams = RaycastParams.new()
			rParams.FilterType = Enum.RaycastFilterType.Exclude
			rParams.FilterDescendantsInstances = {currentBuildObj, workspace.CHARACTERS}

			local castRay = nil
			local noncol = false
			local inst = nil
			local igtbl = rParams.FilterDescendantsInstances
			
			repeat
				castRay = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, rParams)
				if castRay then
					if castRay.Instance then
						if castRay.Instance:IsA("BasePart") then
							if castRay.Instance.CanCollide == true then
								noncol = true
							else
								table.insert(igtbl, castRay.Instance)
								rParams.FilterDescendantsInstances = igtbl
							end
						else
							noncol = true
						end
					else
						noncol = true
					end
				else
					noncol = true
				end	
			until
			noncol == true
			if castRay then
				inst = castRay.Instance
			end

			if inst ~= nil and inst:FindFirstAncestorOfClass("Model") ~= nil and inst.Name == "Terrain"  then
				currentHit = inst
			else
				if inst ~= nil then
					currentHit = inst
				else
					currentHit = nil
				end
				if not grounded and not currentBuildInfo.VehicleStats then
					canplace = false
					e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
					e.TeeTee.Text = "This structure needs support"
					e.Visible = true
					canplace = false
				end
			end
			if castRay then
				if castRay.Instance == workspace.Terrain then
					tgrounded = true
				else
					tgrounded = false
				end
			end


			if castRay then
				local hit = castRay.Instance
				local position = castRay.Position
				if hit and (hrp.Position - currentBuildObj:GetPivot().Position).Magnitude < MAX_PLACE then
					if currentBuildInfo.VehicleStats then
						if (currentStation:GetPivot().Position - currentBuildObj:GetPivot().Position).Magnitude < currentBuildInfo.VehicleStats.MaxDistanceFromStation then
							--canplace = true
						else
							e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
							e.TeeTee.Text = "Out of construction range"
							e.Visible = true
							canplace = false
						end
					else
						canplace = true
					end
					--if currentBuildName ~= "Wood Base" and currentBuildName ~= "Wood Pillar" then
					--	canplace = false
					--end
					--if currentBuildName == "Wood Roof" then
					--	if currentHit.Name == ""
					--end
				else
					e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
					e.TeeTee.Text = "Too far away from player"
					e.Visible = true
					canplace = false
				end

				if canplace then
					e.Visible = false
					for index, item in next, currentBuildObj:GetDescendants() do
						if item:IsA("BasePart") and not item:GetAttribute("invie") or item:IsA("MeshPart") and not item:GetAttribute("invie") or item:IsA("UnionOperation") then
							item.Anchored = true
							item.BrickColor = BrickColor.new("Lime green")
							item.Material = "Neon"
							if item.Transparency < 1 then
								item.Transparency = 0.5 
							end
						end
					end
				else
					for index, item in next, currentBuildObj:GetDescendants() do
						if item:IsA("BasePart") and not item:GetAttribute("invie") or item:IsA("MeshPart") and not item:GetAttribute("invie") or item:IsA("UnionOperation") then
							item.Anchored = true
							item.BrickColor = BrickColor.new("Really red")
							item.Material = "Neon"
							if item.Transparency < 1 then
								item.Transparency = 0.5 
							end
						end
					end
				end
				
				local gotData = invDataStorer.getData()
				local invData = nil
				local slotData = nil
				local barData = nil

				--print(gotData)

				if gotData then
					invData = gotData.Data[1]
					slotData = gotData.Data[2]
					barData = gotData.Data[3]
				end
					
				--[[if not currentBuildInfo.VehicleStats then
					--print(gotData)
					frame.Amt.Visible = true
					if gotData and slotData[currentBuildName] and slotData[currentBuildName].List and slotData[currentBuildName].List[invObjectIndex] then
						frame.Amt.TextLabel.Text = "x"..slotData[currentBuildName].List[invObjectIndex].Amount
					else
						frame.Amt.TextLabel.Text = "x0"
					end
					if gotData and slotData[currentBuildName] and slotData[currentBuildName].List and slotData[currentBuildName].List[invObjectIndex] then
						if slotData[currentBuildName].List[invObjectIndex].Amount <= 0 then
							for index, item in next, currentBuildObj:GetDescendants() do
								if item:IsA("BasePart") and not item:GetAttribute("invie") or item:IsA("MeshPart") and not item:GetAttribute("invie") or item:IsA("UnionOperation") then
									item.BrickColor = BrickColor.new("Deep orange")
									item.Material = "Neon"
									item.Transparency = 0.5
								end
							end
							e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
							e.TeeTee.Text = "No units left"
							e.Visible = true 
						end
					else
						for index, item in next, currentBuildObj:GetDescendants() do
							if item:IsA("BasePart") and not item:GetAttribute("invie") or item:IsA("MeshPart") and not item:GetAttribute("invie") or item:IsA("UnionOperation") then
								item.BrickColor = BrickColor.new("Deep orange")
								item.Material = "Neon"
								item.Transparency = 0.5
							end
						end
						e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
						e.TeeTee.Text = "No units left"
						e.Visible = true 
					end
				else
					frame.Amt.Visible = false
				end
				if currentMaterials then
					local canBuild = true
					for i, v in pairs(currentMaterials) do
						if invData[v.Name].Amount < v.AmountNeeded then
							canBuild = false
							canplace = false
							break
						end
					end
					if not canBuild then
						for index, item in next, currentBuildObj:GetDescendants() do
							if item:IsA("BasePart") and not item:GetAttribute("invie") or item:IsA("MeshPart") and not item:GetAttribute("invie") or item:IsA("UnionOperation") then
								item.BrickColor = BrickColor.new("Deep orange")
								item.Material = "Neon"
								item.Transparency = 0.5
							end
						end
						e.UIStroke.Color = Color3.fromRGB(255, 164, 129)
						e.TeeTee.Text = "No units left"
						e.Visible = true 
					end
				end]]
			
				local newAnglesCFrame = CFrame.Angles(math.rad(building.totalRot.X), math.rad(building.totalRot.Y), math.rad(building.totalRot.Z))
				local newCFrame = CFrame.new(position.X, position.Y + building.yPos, position.Z)
				if not currentBuildInfo.VehicleStats then
					currentBuildObj:PivotTo(newCFrame * newAnglesCFrame)
					freeFrame = (newCFrame * newAnglesCFrame)
				else
					currentBuildObj:PivotTo(newCFrame * newAnglesCFrame * CFrame.new(0, 5, 0))
					freeFrame = (newCFrame * newAnglesCFrame * CFrame.new(0, 5, 0))
				end
			end
		end
		local closestruct = findTargetMod(currentBuildObj:GetPivot().Position)
		--print(closestruct)
		--if closestruct then
		--	print(closestruct.Parent)
		--end
		if closestruct ~= nil and currentBuildInfo.BuildType ~= "Special" and (frame:GetAttribute("Mode") == "Edge" or frame:GetAttribute("Mode") == "Snap") then
			grounded = false
			local points = {}
			local stuff = closestruct.Parent:GetDescendants()
			for i, v in pairs(stuff) do
				if v.ClassName == "Attachment" and v.Name == currentBuildInfo.BuildType then
					table.insert(points, v)
				end
			end
			if #stuff > 0 then
				--print(closestruct.Parent)
				local points = {}
				local stuff = closestruct.Parent:GetDescendants()
				for i, v in pairs(stuff) do
					if v:IsA("Attachment") and v.Name == currentBuildInfo.BuildType then
						table.insert(points, v)
					end
				end
				local insideAttch = GetClosestAttachment(currentBuildObj, closestruct.Parent)
				local nearestAttch = GetNearestAttachment(points, insideAttch)
				a1, a2 = insideAttch, nearestAttch

				--print(insideAttch:FindFirstAncestorOfClass("Model"))
				--print(nearestAttch:FindFirstAncestorOfClass("Model"))
				--print(insideAttch)
				--print("binding to "..nearestAttch:FindFirstAncestorOfClass("Model").Name.." of "..nearestAttch.Name)
				if insideAttch and nearestAttch then
					BindAttach(insideAttch, nearestAttch)
				end
			end
		else
			grounded = tgrounded
		end
	end))
end

-- Global Functions
function building.start(objName, invOrder, station)
	if char:GetAttribute("Building") == true then return end
	char:SetAttribute("Building", true)
	startEvent:Fire()
	playerGUI:WaitForChild("SurvivorUI"):SetAttribute("Active", false)
	frame.Visible = true
	state1 = playerGUI:WaitForChild("SurvivorUI").Enabled
	playerGUI:WaitForChild("SurvivorUI").Enabled = false
	cursnap = nil
	
	local plrplatform = checkPlatform()
	if checkPlatform() == "Mobile" then
		frame.Confirm.Visible = true
		frame.Rotate.Visible = true
	end
	
	local cancelKey = keySettings.Building.Cancel
	local txt = string.split(tostring(cancelKey), ".")
	txt = txt[#txt]
	--frame.Cancel.TextLabel.Text = "Cancel("..txt..")"
	BindCancelKey(cancelKey)
	
	
	local currentBuildObjFound = Builds:FindFirstChild(objName) or Vehicles:FindFirstChild(objName)
	currentBuildName = objName 
	currentBuildInfo = buildInfo[objName]

	if not currentBuildName or not currentBuildObjFound or not currentBuildInfo then
		currentBuildName, currentBuildObj, currentBuildType, currentBuildInfo = nil
		return 
	end
	
	invObjectIndex = invOrder
	
	currentBuildObj = currentBuildObjFound:Clone()
	currentBuildObj:SetAttribute("Fakebuild", true)
	for i, v in pairs(currentBuildObj:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	currentBuildObj.Parent = workspace.BUILDS
	currentBuildType = currentBuildInfo.BuildType
	currentStation = station
	
	curTool = char:WaitForChild("CurrentTool"):GetChildren()[1]
	
	if currentBuildInfo.VehicleStats then
		for i, v in pairs(craftingIndex) do
			if v[objName] then
				currentMaterials = craftingIndex[i][objName].Materials
				break
			end
		end
	end
	
	building.buildDraft = currentBuildObj
	building.buildStation = currentStation
	
	frame.Visible = true
	coroutine.wrap(function()
		local toGo = true
		local con
		con = stopEvent.Event:Connect(function()
			toGo = false
			con:Disconnect()
		end)
		task.wait(0.5)
		if toGo then
			if con then
				con:Disconnect()
			end
			building.placing = true
		end
	end)()
	bindToRenderStep()
end

function building.stop()
	stopEvent:Fire()
	canplace = false
	coroutine.wrap(function()
		local thestate = state1
		local toGo = true
		local con
		con = startEvent.Event:Connect(function()
			toGo = false
			con:Disconnect()
		end)
		task.wait(0.1)
		if toGo then
			if con then
				con:Disconnect()
			end
			playerGUI:WaitForChild("SurvivorUI"):SetAttribute("Active", state1)
		end
	end)()
	playerGUI:WaitForChild("SurvivorUI").Enabled = state1
	frame.Visible = false
	e.Visible = false
	frame.Confirm.Visible = false
	frame.Rotate.Visible = false
	
	if building.buildDraft then
		seeknDestroyObj(building.buildDraft)
		building.buildDraft = nil
		currentBuildObj = nil
	end
	building.buildDraft = nil
	building.buildStation = nil
	building.totalRot = Vector3.new(0, 0, 0)
	building.yPos = 0

	if currentBuildObj then
		seeknDestroyObj(currentBuildObj)
		currentBuildObj = nil
		building.buildDraft = nil
	end
	
	curTool = nil
	currentBuildName, currentBuildObj, currentBuildType, currentBuildInfo = nil
	currentStation = nil
	currentMaterials = nil
	invObjectIndex = nil

	for i, v in pairs(cons) do
		v:Disconnect()
	end

	building.placing = false
	char:SetAttribute("Building", false)
end

function building.setup()
	UIS.InputBegan:Connect(InputStarted)
	UIS.InputEnded:Connect(InputEnded)

	char:WaitForChild("CurrentTool").ChildAdded:Connect(function()
		local tool = char:WaitForChild("CurrentTool"):GetChildren()[1]
		if tool ~= curTool then
			building.stop()
		end
	end)

	char:WaitForChild("CurrentTool").ChildRemoved:Connect(function()
		local tool = char:WaitForChild("CurrentTool"):GetChildren()[1]
		if tool ~= curTool then
			building.stop()
		end
	end)
	
	sliding.setup()
	
	--coroutine.wrap(function()
	--	building.start("Wood Base", 1)
	--end)()
	StartBuildCli.Event:Connect(building.start)
end

return building