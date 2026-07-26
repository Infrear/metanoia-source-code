local ReplicatedStorage = game.ReplicatedStorage
local PlaceStructure = ReplicatedStorage:WaitForChild("Assets")["Remote Events"]:WaitForChild("PlaceStructure")
local Structures = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Structures")
local Vehicles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Vehicles")

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local plr = game.Players.LocalPlayer
local StructureFrame = script.Parent.Build
local char = plr.Character or plr.Character:wait(0.01)
local b = script.Parent.BackG
local HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
local mouse = plr:GetMouse()
local placing = false
local yRot = 0
local yPos = 0
local maxPlace = 65
local canplace = true
local fakeStruct = nil
local placedStructure = nil
local connection = nil
local newconnec = nil
local vec = nil
local e = script.Parent.Eror
local a1 = nil
local a2 = nil
local freeFrame = nil
local state1 = true
local state2 = true
local rotkeydown = false
local currentHit = nil
local grounded = false
local cursnap = nil

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
	connection = UIS.InputBegan:Connect(function(input)
		if input == key then
			StopAll()
		end
	end)
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
function rInputStart(input)
	local did = false
	local con
	con = UIS.InputEnded:Connect(function(inp)
		if inp.KeyCode ~= Enum.KeyCode.T then return end
		con:Disconnect()
		con = nil
		did = true
		if (not (yRot%45 == 0)) and (yRot > 0) then
			local find = 0
			local closest = math.huge
			local opt = yRot
			for i, v in pairs(mpules) do
				local n1, n2 = 0, 0
				n1 = math.abs(opt)
				n2 = math.abs(v)
				if math.abs(n1 - n2) < closest and yRot < v then
					closest = n1 - n2
					find = v
				end
			end
			if find then
				yRot = find
			else
				yRot = 0
			end
			rotkeydown = false		
		else
			yRot += 45
			if yRot >= 360 then yRot = 0 end
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
			if placing == true then
				yRot = yRot + rotSpeed								
			end
		end
	end
end

function StopAll()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	if newconnec ~= nil then
		newconnec:Disconnect()
		newconnec = nil	
	end
	placing = false
	if fakeStruct ~= nil then
		fakeStruct:Destroy()
	end
	script.Parent.Parent.MobileInter.Cancel.Visible = false
	script.Parent.Parent.MobileInter.Build.Visible = false
	script.Parent.Enabled = false
	b.Visible = false
	plr.PlayerGui.Inventory.Enabled = state1
	plr.PlayerGui.Settings.Enabled = state2
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
	local list = workspace.STRUCTURES:GetChildren()
	local hrp = nil
	local dist = 50
	local var = nil
	local var2 = nil
	--- iterating through the workspace array
	for x = 1, #list do
		var2 = list[x]
		if (var2.className == "Model") and (var2 ~= script.Parent) then
			if findat(var2, fakeStruct.Type.Value) and findat(fakeStruct, var2.Type.Value) then
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
function cInputStart(input)
	StopAll()
end

local iev = Instance.new("BindableEvent")

function InputEnded(input)
	if input.KeyCode == Enum.KeyCode.T then
		rotkeydown = false		
	end
end

function InputBegan(input)
	if placing == true then
		if canplace == true then
			local StructureCFrame = fakeStruct:GetPrimaryPartCFrame()
			print(currentHit)
			placedStructure = PlaceStructure:FireServer(fakeStruct.Name, StructureCFrame, vec, nil, currentHit)

			if vec then
				StopAll()
			end

			if placedStructure == true then
				placing = false
				fakeStruct:Destroy()
				script.Parent.Enabled = false
			end
		end
	end
end

function InputStarted(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.T then
		rInputStart(input)
	elseif input.KeyCode == Enum.KeyCode.C then
		cInputStart(input)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if gameProcessedEvent == false then
			InputBegan(input)
		end
	end
end
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
		if b.Mode.Value == "Snap" then
			wallPos = (at2.WorldPosition + -(at1.Position))
		elseif b.Mode.Value == "Edge" then
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
		if b.Mode.Value == "Snap" then
			--wallPos = (at2.WorldPosition + -(at1.Position))
			wallCF = at2.WorldCFrame * CFrame.new(-at1.CFrame.Position)
		elseif b.Mode.Value == "Edge" then
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
			wall.Parent:PivotTo(wall.Parent:GetPivot() * CFrame.Angles(0, math.rad(yRot), 0))
			if find and oldr then
				wall.Parent.PrimaryPart = oldr
			end
		end
		wall.Parent.PrimaryPart = oldp
		if fakeStruct.Name ~= "Wood Floor" and not grounded then
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
		if v:IsA("Attachment") and v.Name == p2.Type.Value and v:FindFirstChild("Bal") == nil then
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
			if (v.ClassName == "Attachment") and v.Name == fakeStruct.Type.Value then
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

function RenderStepped()
	local mpos = Vector2.new(mouse.X, mouse.Y)
	canplace = true
	local cando = true
	if checkPlatform() == "Mobile" then
		if (Vector2.new(375, 154) - mpos).Magnitude < 75 then
			cando = false
		end	
	end
	local tgrounded = false
	if cando == true then
		local mouseRay = mouse.UnitRay
		local rParams = RaycastParams.new()
		rParams.FilterType = Enum.RaycastFilterType.Blacklist
		rParams.FilterDescendantsInstances = {fakeStruct, workspace.CHARACTERS}

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
			if not grounded and not vec then
				canplace = false
				e.BackgroundColor3 = Color3.fromRGB(255, 164, 129)
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
			if hit and (HumanoidRootPart.Position - fakeStruct.PrimaryPart.Position).Magnitude < maxPlace then
				if vec then
					if (vec[1]:GetPivot().Position - fakeStruct.PrimaryPart.Position).Magnitude < vec[2] then
						--canplace = true
					else
						e.BackgroundColor3 = Color3.fromRGB(255, 164, 129)
						e.TeeTee.Text = "Out of construction range"
						e.Visible = true
						canplace = false
					end
				else
					canplace = true
				end
				--if fakeStruct.Name ~= "Wood Floor" and fakeStruct.Name ~= "Wood Pillar" then
				--	canplace = false
				--end
				--if fakeStruct.Name == "Wood Roof" then
				--	if currentHit.Name == ""
				--end
			else
				e.BackgroundColor3 = Color3.fromRGB(255, 164, 129)
				e.TeeTee.Text = "Too far away from player"
				e.Visible = true
				canplace = false
			end

			if canplace then
				e.Visible = false
				for index, item in next, fakeStruct:GetDescendants() do
					if item:IsA("BasePart") and item.Name ~= "invie" or item:IsA("MeshPart") and item.Name ~= "invie" or item:IsA("UnionOperation") then
						item.Anchored = true
						item.BrickColor = BrickColor.new("Lime green")
						item.Material = "Neon"
						if item.Transparency < 1 then
							item.Transparency = 0.5 
						end
					end
				end
			else
				for index, item in next, fakeStruct:GetDescendants() do
					if item:IsA("BasePart") and item.Name ~= "invie" or item:IsA("MeshPart") and item.Name ~= "invie" or item:IsA("UnionOperation") then
						item.Anchored = true
						item.BrickColor = BrickColor.new("Really red")
						item.Material = "Neon"
						if item.Transparency < 1 then
							item.Transparency = 0.5 
						end
					end
				end
			end
			if not vec then
				if plr.Items:FindFirstChild(fakeStruct.Name) then
					if plr.Items[fakeStruct.Name].Amount.Value <= 0 then
						for index, item in next, fakeStruct:GetDescendants() do
							if item:IsA("BasePart") and item.Name ~= "invie" or item:IsA("MeshPart") and item.Name ~= "invie" or item:IsA("UnionOperation") then
								item.BrickColor = BrickColor.new("Deep orange")
								item.Material = "Neon"
								item.Transparency = 0.5
							end
						end
						e.BackgroundColor3 = Color3.fromRGB(255, 164, 129)
						e.TeeTee.Text = "No units left"
						e.Visible = true 
					end
				else
					for index, item in next, fakeStruct:GetDescendants() do
						if item:IsA("BasePart") and item.Name ~= "invie" or item:IsA("MeshPart") and item.Name ~= "invie" or item:IsA("UnionOperation") then
							item.BrickColor = BrickColor.new("Deep orange")
							item.Material = "Neon"
							item.Transparency = 0.5
						end
					end
					e.BackgroundColor3 = Color3.fromRGB(255, 164, 129)
					e.TeeTee.Text = "No units left"
					e.Visible = true 
				end
			end
			local newAnglesCFrame = CFrame.Angles(0, math.rad(yRot), 0)
			local newCFrame = CFrame.new(position.X, position.Y + yPos, position.Z)
			if not vec then
				fakeStruct:PivotTo(newCFrame * newAnglesCFrame)
				freeFrame = (newCFrame * newAnglesCFrame)
			else
				fakeStruct:PivotTo(newCFrame * newAnglesCFrame * CFrame.new(0, 5, 0))
				freeFrame = (newCFrame * newAnglesCFrame * CFrame.new(0, 5, 0))
			end
		end
	end
	local closestruct = findTargetMod(fakeStruct.PrimaryPart.Position)
	--print(closestruct.Parent)
	if closestruct ~= nil and fakeStruct.Type.Value ~= "Special" and (b.Mode.Value == "Edge" or b.Mode.Value == "Snap") then
		grounded = false
		local points = {}
		local stuff = closestruct.Parent:GetDescendants()
		for i, v in pairs(stuff) do
			if v.ClassName == "Attachment" and v.Name == fakeStruct.Type.Value then
				table.insert(points, v)
			end
		end
		if #stuff > 0 then
			--print(closestruct.Parent)
			local points = {}
			local stuff = closestruct.Parent:GetDescendants()
			for i, v in pairs(stuff) do
				if v:IsA("Attachment") and v.Name == fakeStruct.Type.Value then
					table.insert(points, v)
				end
			end
			local insideAttch = GetClosestAttachment(fakeStruct, closestruct.Parent)
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
end

function Startbuild(buildobject, vehic)
	if placing or char:FindFirstChild("CBoard") then return end
	if not vehic then
		if not (plr.Items:FindFirstChild(buildobject) ~= nil) then
			StopAll()
			return
		else
			if not (plr.Items[buildobject].Amount.Value > 0) then
				StopAll()
				return
			end
		end
	end
	state1 = plr.PlayerGui.Inventory.Enabled 
	state2 = plr.PlayerGui.Settings.Enabled 
	b.Visible = true
	plr.PlayerGui.Inventory.Enabled = false
	plr.PlayerGui.Settings.Enabled = false
	vec = vehic
	cursnap = nil
	local plrplatform = checkPlatform()
	if checkPlatform() == "Mobile" then
		script.Parent.Parent.MobileInter.Cancel.Visible = true
		script.Parent.Parent.MobileInter.Build.Visible = true
		StructureFrame.Visible = false
		StructureFrame.Cancel.Text = "Cancel"
	elseif checkPlatform() == "Console" then
		StructureFrame.Visible = true
		StructureFrame.Cancel.Text = "Cancel(B)"
		BindCancelKey(Enum.KeyCode.ButtonB)
	elseif checkPlatform() == "Keyboard" then
		StructureFrame.Visible = true
		StructureFrame.Cancel.Text = "Cancel(C)"
		BindCancelKey(Enum.KeyCode.C)
	end
	script.Parent.CurrentStructure.Value = buildobject
	local structureName = script.Parent.CurrentStructure.Value
	script.Parent.Enabled = true

	if placing == false then
		placing = true
		local found = Structures:FindFirstChild(structureName) or Vehicles:FindFirstChild(structureName)
		fakeStruct = found:Clone()
		for i, v in pairs(fakeStruct:GetDescendants()) do
			if v:IsA("ProximityPrompt") then
				v.Enabled = false
			end
		end
		for index, item in next, fakeStruct:GetChildren() do
			if item:IsA("BasePart") or item:IsA("MeshPart") or item:IsA("UnionOperation")  then
				item.BrickColor = BrickColor.new("Lime green")
				item.Material = "Neon"
				item.CanCollide = false
				if item.Transparency < 1 then
					item.Transparency = 0.5 
				end
			end
			fakeStruct.Parent = game.Workspace
		end
		yRot = 0
		local startingCFrame = CFrame.new(0, -2, -15)
		--fakeStruct:PivotTo(HumanoidRootPart.CFrame * CFrame.new(0, 0, -10))
		fakeStruct:PivotTo(CFrame.new((HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)).Position) * (workspace["Scripting Assets"].BPart.CFrame - workspace["Scripting Assets"].BPart.CFrame.Position))
		newconnec = RS.RenderStepped:Connect(RenderStepped)
	end
end

script.Parent.Parent.MobileInter.Cancel.MouseButton1Click:Connect(StopAll)
script.Parent.Parent.MobileInter.Build.MouseButton1Click:Connect(InputBegan)
game.ReplicatedStorage:WaitForChild("Assets")["Remote Events"].BuildStruc.OnClientEvent:Connect(Startbuild)
game.ReplicatedStorage:WaitForChild("Assets")["Events"].BuildStruc.Event:Connect(Startbuild)
UIS.InputBegan:Connect(InputStarted)
UIS.InputEnded:Connect(InputEnded)