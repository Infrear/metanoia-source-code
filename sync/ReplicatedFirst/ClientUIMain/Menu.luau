-- Constants
local ADD_TIME = {
	MIN = 0.85,
	BASE = 1,
	CAP = 2,
}

local HOVER_SETTINGS = {
	RotateForwardSpeed = 0.35,
	RotateBackSpeed = 0.35,
	RotationAddition = 45,
	OGSize = UDim2.new(0.885, 0, 0.885, 0),
	OGPosition = UDim2.new(0.5, 0, 0.5, 0),
	SizeAddition = UDim2.new(0.015, 0, 0.015, 0),
	PositionAddition = UDim2.new(0, 0, 0.085, 0),
	--OGColor = Color3.new(0.45098, 0.45098, 0.45098),
	OGColor = Color3.fromRGB(255, 255, 255),
	HoverColor = Color3.new(0.756863, 0.756863, 0.862745)
}

--local HOVER_SETTINGSb = {
--	RotateForwardSpeed = 0.55,
--	RotateBackSpeed = 1.5,
--	OGPosition = UDim.new(0, 1),
--	PositionAddition = UDim2.new(0, 0, 0.085, 0),
--}

local HOVER_SETTINGS2 = {
	RotateForwardSpeed = 0.35,
	RotateBackSpeed = 0.35,
	RotationAddition = 45,
	OGSize = UDim2.new(1, 0, 1, 0),
	OGPosition = UDim2.new(0.5, 0, 0.5, 0),
	SizeAddition = UDim2.new(0.015, 0, 0.015, 0),
	PositionAddition = UDim2.new(0, 0, 0.085, 0),
	OGColor = Color3.fromRGB(47, 46, 59),
	--OGColor = Color3.fromRGB(255, 255, 255),
	HoverColor = Color3.fromRGB(70, 69, 88)
}

local HOVER_SETTINGSb = {
	RotateForwardSpeed = 0.25,
	RotateBackSpeed = 0.65,
	OGPosition = UDim2.new(0, 0, 0.126, 0),
	PositionAddition = UDim2.new(0, 0, 0.085, 0),
} 

local HOVER_SETTINGS2b = {
	RotateForwardSpeed = 0.25,
	RotateBackSpeed = 0.65,
	OGPosition = UDim2.new(0.173, 0, 0, 0),
	PositionAddition = UDim2.new(-0.085, 0, 0, 0),
}

local KeysIndex = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five
}

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)

local plr = game.Players.LocalPlayer
local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local mouse = plr:GetMouse()

local ui = playerGUI:WaitForChild("SurvivorUI")
local rPop = ui:WaitForChild("RClickPop")
local frame = ui:WaitForChild("Inventory"):WaitForChild("Frame")
local mainbar = ui:WaitForChild("MainBar")
local box1 = frame:WaitForChild("Inventory"):WaitForChild("Inv")
local desc = frame:WaitForChild("Inventory"):WaitForChild("Info")
local fakeBar = frame:WaitForChild("Inventory"):WaitForChild("Fakebar")

-- otherworldly dependacies
local otherUI = ui:WaitForChild("OtherworldlyUIs")
local storeframe = otherUI:WaitForChild("StoreInventory"):WaitForChild("Frame")
local storebox = storeframe:WaitForChild("Inventory"):WaitForChild("Inv")
--

local barChange = Storage:WaitForChild("Events").Standard.HotbarChange
local buildInvSend = Storage:WaitForChild("Events").Remotes.SendBuildInventoryEvents
local event = Instance.new("BindableEvent")
local getData = Storage:WaitForChild("Functions").Remotes.GetData
local setSlots = Storage:WaitForChild("Functions").Remotes.SetSlots
local craftingIndex = require(Storage.Info.CraftingIndex)
local invDataStorer = require(playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"))
local clientUpdEv = playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"):WaitForChild("UpdInv")
local dataUpdEv = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("DataUpdated")
local itemInfo = require(Storage:WaitForChild("Info"):WaitForChild("ItemInfo"))
local colorSettings = require(Storage:WaitForChild("Info"):WaitForChild("ColorSettings"))
local crafting = require(script:WaitForChild("Crafting"))

local DraggableObject = require(Storage:WaitForChild("Modules")["DraggableObject"])
local ItemIndicator = require(script:WaitForChild("ItemIndicator"))

local TIS = {
	["Open"] = TweenInfo.new(
		0.85,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	["Close"] = TweenInfo.new(
		1.25,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	--["FadeIn"] = TweenInfo.new(
	--	0.65,
	--	Enum.EasingStyle.Quad,
	--	Enum.EasingDirection.Out
	--),
	--["FadeOut"] = TweenInfo.new(
	--	0.65,
	--	Enum.EasingStyle.Quad,
	--	Enum.EasingDirection.Out
	--),
	["Hover"] = TweenInfo.new(
		HOVER_SETTINGS.RotateForwardSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	["Hover2"] = TweenInfo.new(
		HOVER_SETTINGS2b.RotateForwardSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	["Unhover"] = TweenInfo.new(
		HOVER_SETTINGS.RotateBackSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	["Unhover2"] = TweenInfo.new(
		HOVER_SETTINGS2b.RotateBackSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
}

-- Variables
local slots = {}
local oslots = {}
local fullOrder = {} 
local fullOrder2 = {}
local runs = {}
local bars = {}
local equipped = nil

local HOVER_TES = {}
local HOVER_cons = {}
local BAR_HOVER_cons = {}
local BAR_cons = {}
local currentRpop = nil
local currentCon = nil
local currentBump = false
local rPopev = Instance.new("BindableEvent")

--local TES = {}
local TES = {}

-- Constants
local SECTIONS = {
	["Inventory"] = {
		Key = "Inventory",
		Frames = {
			F1 = {
				Frame = frame:WaitForChild("Inventory"),
				Size = UDim2.new(0.6, 0, 0.65, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}
		},
		Alt = {
			Frame = frame:WaitForChild("Inventory"):WaitForChild("Fakebar"),
			Size = UDim2.new(0.141, 0, 1.161, 0),
			Position = UDim2.new(1.071, 0, -0.029, 0),
			Size2 = UDim2.new(0.088, 0, 0.869, 0),
			Position2 = UDim2.new(0.914, 0, 0.173, 0)
		}
	},
	["Inventory2"] = {
		Key = "Inventory2",
		Frames = {
			F1 = {
				Frame = frame:WaitForChild("Inventory"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.294, 0, 0.5, 0)
			},
			F2 = {
				Frame = frame:WaitForChild("Avatar"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.706, 0, 0.499, 0)
			}
		}
	},
	["Crafting"] = {
		Key = "Crafting",
		Frames = {
			F1 = {
				Frame = frame:WaitForChild("Inventory"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.294, 0, 0.5, 0)
			},
			F2 = {
				Frame = frame:WaitForChild("Crafting"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.706, 0, 0.499, 0)
			}
		}
	},

	--------- otherworldy inventories and stuff
	["StoreInventory"] = {
		Key = "StoreInventory",
		Frames = {
			F1 = {
				Frame = frame:WaitForChild("Inventory"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.294, 0, 0.5, 0)
			},
			F2 = {
				Frame = storeframe:WaitForChild("Inventory"),
				Size = UDim2.new(0.392, 0,0.597, 0),
				Position = UDim2.new(0.706, 0, 0.499, 0)
			}
		}
	},
}

local ClosedPos = UDim2.new(0.5, 0, 2.15, 0)

-- Initialization
local menu = {}

-- Global Variables
menu.In = false
menu.currentSection = nil

-- Local Functions
local function removeGapsFromTable(tbl)
	local newTable = {}
	local index = 1

	for _, value in ipairs(tbl) do
		newTable[index] = value
		index = index + 1
	end

	return newTable
end

local function findInDict(dict, obj, dir)
	if dir then
		if dict[dir] == obj then return dir end
	end
	for i, v in pairs(dict) do
		--print(v)
		--print(obj)
		--print(obj.ClassName)

		--print(dict[i])
		--print(v == obj)
		if dict[i] == obj then
			--print(i)
			return i
		end
	end
end

function tablesAreEqual(table1, table2)
	if #table1 ~= #table2 then
		return false
	end

	for k, v in pairs(table1) do
		if table2[k] ~= v then
			return false
		end
	end

	return true
end

local function findInList(list, obj)
	for i, v in pairs(list) do
		--print(v)
		--print(obj)
		--print(obj.ClassName)

		--print(dict[i])
		--print(v == obj)
		if list[i].Object == obj then
			--print(i)
			return i
		end
	end
end

local function findSlot(obj, boxes, max, taype, tofind)
	local closest = max or math.huge
	local var = nil
	for alpha, box in pairs(boxes) do
		for i, v in pairs(box:GetChildren()) do
			if (not v:IsA(taype or "TextButton")) or (v == obj) or (not v.Visible) then continue end
			--print(obj)
			--print(v)
			local mag = math.huge
			if not tofind then
				mag = (v.AbsolutePosition - obj.AbsolutePosition).Magnitude
			else
				mag = (v:FindFirstChild(tofind).AbsolutePosition - obj.AbsolutePosition).Magnitude
			end
			--print(mag)
			if mag < closest then
				closest = mag
				if not tofind then
					var = v
				else
					var = v:FindFirstChild(tofind)
				end
			end
		end
	end
	return var
end

local function sortButtonsByLayoutOrder(scrollingFrame, taype)
	-- Retrieve all text buttons from the scrolling frame
	local buttons = {}
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA(taype or "TextButton") and child.Visible then
			table.insert(buttons, child)
		end
	end

	-- Sort the buttons by layout order
	table.sort(buttons, function(a, b)
		if a.LayoutOrder == b.LayoutOrder then
			-- If layout order is the same, sort alphabetically by button name
			return a.Name < b.Name
		else
			return a.LayoutOrder < b.LayoutOrder
		end
	end)

	return buttons
end

local function findTab(obj)
	for i, v in pairs(slots) do
		--print(v)
		for i2, v2 in ipairs(v.List) do
			if v2.Object == obj then
				return v2
			end
		end
	end
end

local function slideIn(v, obj2)
	--print(mainbar:GetAttribute("CanMove"))
	if not BAR_HOVER_cons[v] then
		BAR_HOVER_cons[v] = {}
	end
	if BAR_HOVER_cons[v][1] then
		if BAR_HOVER_cons[v][1].PlaybackState == Enum.PlaybackState.Playing then
			BAR_HOVER_cons[v][1]:Cancel()
		end
	end
	if BAR_HOVER_cons[v][2] then
		if BAR_HOVER_cons[v][2].PlaybackState == Enum.PlaybackState.Playing then
			BAR_HOVER_cons[v][2]:Cancel()
		end
	end
	if mainbar:GetAttribute("CanMove") then  
		BAR_HOVER_cons[v][1] = TS:Create(v, TIS.Hover2, {Position = UDim2.new(v.Position.X, HOVER_SETTINGSb.OGPosition.Y + HOVER_SETTINGSb.PositionAddition.Y)})
		BAR_HOVER_cons[v][1]:Play()
	end

	--print(obj2)
	BAR_HOVER_cons[v][2] = TS:Create(obj2, TIS.Hover2, {Position = UDim2.new(HOVER_SETTINGS2b.OGPosition.X + HOVER_SETTINGS2b.PositionAddition.X,  obj2.Position.Y)})
	BAR_HOVER_cons[v][2]:Play()
end

local function slideOut(v, obj2)
	if not BAR_HOVER_cons[v] then
		BAR_HOVER_cons[v] = {}
	end
	if BAR_HOVER_cons[v][1] then
		if BAR_HOVER_cons[v][1].PlaybackState == Enum.PlaybackState.Playing then
			BAR_HOVER_cons[v][1]:Cancel()
		end
	end
	if BAR_HOVER_cons[v][2] then
		if BAR_HOVER_cons[v][2].PlaybackState == Enum.PlaybackState.Playing then
			BAR_HOVER_cons[v][2]:Cancel()
		end
	end
	--print(v)
	--print(v.Position)
	--print(HOVER_SETTINGSb.OGPosition.Y)
	--coroutine.wrap(function()
	--	while true do
	--		print(v.Position)
	--		wait()
	--	end
	--end)()
	if mainbar:GetAttribute("CanMove") then  
		BAR_HOVER_cons[v][1] = TS:Create(v, TIS.Unhover2, {Position = UDim2.new(v.Position.X, HOVER_SETTINGSb.OGPosition.Y)})
		BAR_HOVER_cons[v][1]:Play()
	end

	--print(obj2)
	BAR_HOVER_cons[v][2] = TS:Create(obj2, TIS.Unhover2, {Position = UDim2.new(HOVER_SETTINGS2b.OGPosition.X,  obj2.Position.Y)})
	BAR_HOVER_cons[v][2]:Play()
end

local function reOrderBox(preferedRef, prefOrder, boxly)
	--print("old-")
	--print(slots)
	
	if not fullOrder then
		fullOrder = {}
	end
	
	if #fullOrder <= 0 then
		print("resetting inv order")
		
		local maxCount = 0
		for i, v in pairs(slots) do
			for i2, slotObject in pairs(v.List) do
				if slotObject.Object then
					maxCount += 1
					
					slotObject.Order = maxCount
					slotObject.Object.LayoutOrder = maxCount
					table.insert(fullOrder, maxCount, slotObject.Object)
				end
			end
		end
		return
	end
	
	if boxly then
		if not fullOrder2 then
			fullOrder2 = {}
		end
		if #fullOrder2 <= 0 then
			print("resetting box order")

			local maxCount = 0
			for i, v in pairs(oslots) do
				for i2, slotObject in pairs(v.List) do
					if slotObject.Object then
						maxCount += 1

						slotObject.Order = maxCount
						slotObject.Object.LayoutOrder = maxCount
						table.insert(fullOrder2, maxCount, slotObject.Object)
					end
				end
			end
			return
		end
	end
	
	local changed = false
	--local pairedTab = {}
	--for i, v in pairs(slots) do
	--	for i, v in pairs(v.List) do

	--	end
	--	--print(v)
	--	pairedTab[v.Order] = v
	--end
	--print(slots)
	--local pairedTab = {
	--	[1] = "a",
	--	[2] = "b",
	--	[3] = "c"
	--}
	--for i, v in ipairs(pairedTab) do
	--	print(v)
	--end
	--print(pairedTab)
	--local cur = 0
	--for i, v in ipairs(pairedTab) do
	--	--print(v.List)
	--	for i2, v2 in ipairs(v.List) do
	--		if not v2.Object then continue end
	--		--print(v.List)
	--		--print(v2)
	--		v2.Object.LayoutOrder = cur
	--		--print(slots[v2.Name].List[i2])
	--		slots[v2.Name].List[i2].Order = cur
	--		cur += 1
	--	end
	--end

	--print(bars)
	--print(fullOrder)
	--for i3, v3 in pairs(bars) do
	--	--print(v3)
	--	--print(v3.Path)
	--	local dir = slots[v3.Path[1]][v3.Path[2]][v3.Path[3]]
	--	print(dir)

	--	if dir and findInDict(fullOrder, dir.Object) ~= dir.Path[3] then
	--		--print("newie")
	--		bars[i3].Path = {v3.Path[1], v3.Path[2], findInDict(fullOrder, dir.Object)}
	--	end
	--end

	--print(fullOrder)
	local mySlots = preferedRef or slots
	local myOrder = prefOrder or fullOrder
	
	for i, v in pairs(mySlots) do
		--print(v)
		for i2, v2 in ipairs(v.List) do
			--print(v2)
			if not v2.Object then continue end
			--v2.Object.LayoutOrder = v2.Order

			--print(v2)
			--print(" -iTers")
			--print(table.find(fullOrder, v2.Object))
			--v2.Order = table.find(fullOrder, v2.Object) or 0 --#fullOrder + 1
			mySlots[i].List[i2].Order = findInDict(myOrder, v2.Object) or 0 --#fullOrder + 1
			--print(findInDict(fullOrder, v2.Object))
			mySlots[i].List[i2].Object.LayoutOrder = mySlots[i].List[i2].Order
		end
	end
	
	--print("mid-")
	--print(slots)
	
	if not boxly then
		slots = mySlots
	else
		oslots = mySlots
	end
	--for i = 1, #fullOrder do
	--	if not fullOrder[i] then
	--		fullOrder[i] = fullOrder[i + 1].Object
	--		fullOrder[i + 1] = nil

	--	end
	--end
	
	--local myOrder = {
	--	[1] = "hi",
	--	[2] = "wow",
	--	[3] = nil,
	--	[4] = "eh",
	--	[5] = nil,
	--	[6] = "lasy",
	--}

	--local cleanedOrder = {}
	--for i = 1, #myOrder do
	--	if myOrder[i] then
	--		table.insert(cleanedOrder, myOrder[i])
	--	end
	--end

	--print(cleanedOrder)
	
	local cleanedOrder = {}
	for i = 1, #myOrder do
		if myOrder[i] then
			table.insert(cleanedOrder, myOrder[i])
			--table.remove(boxly and fullOrder2 or fullOrder, i)
		else
			changed = true
		end
	end
	
	if boxly then
		fullOrder2 = cleanedOrder
	else
		fullOrder = cleanedOrder
	end
	--print(fullOrder)
	if changed then reOrderBox() end
	--print("new-")
	--print(slots)
end

local function bindBar(bar)
	for i, f in pairs(bar:GetChildren()) do
		if not f:IsA("Frame") then continue end
		local button = f:WaitForChild("Button")

		HOVER_cons[button] = {}
		HOVER_cons[button][1] = button.MouseEnter:Connect(function()
			if HOVER_TES[button] then
				if HOVER_TES[button][1] then
					if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
						HOVER_TES[button][1]:Cancel()
					end
				end
				if HOVER_TES[button][2] then
					if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
						HOVER_TES[button][2]:Cancel()
					end
				end
			end
			HOVER_TES[button] = {}


			HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS2.HoverColor})
			HOVER_TES[button][1]:Play()

			HOVER_TES[button][2] = TS:Create(f.Img, TIS.Hover, {Size = HOVER_SETTINGS2.OGSize + HOVER_SETTINGS2.SizeAddition,  Position = HOVER_SETTINGS2.OGPosition + HOVER_SETTINGS2.PositionAddition})
			HOVER_TES[button][2]:Play()
		end)

		HOVER_cons[button][2] = button.MouseLeave:Connect(function()
			if HOVER_TES[button] then
				if HOVER_TES[button][1] then
					if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
						HOVER_TES[button][1]:Cancel()
					end
				end
				if HOVER_TES[button][2] then
					if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
						HOVER_TES[button][2]:Cancel()
					end
				end
			end
			HOVER_TES[button] = {}

			HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS2.OGColor})
			HOVER_TES[button][1]:Play()

			HOVER_TES[button][2] = TS:Create(f.Img, TIS.Hover, {Size = HOVER_SETTINGS2.OGSize,  Position = HOVER_SETTINGS2.OGPosition})
			HOVER_TES[button][2]:Play()
		end)
	end
	--HOVER_cons[button][5] = button.MouseButton1Up:Connect(function()
	--end)
end

local function bindSlot(button, oldSlotTab, key)
	--print(oldSlotTab.Object)
	--print(button, oldSlotTab, key)
	--if not button:IsA("ImageButton") then return end
	local clo = nil
	if oldSlotTab.Order then
		button.LayoutOrder = oldSlotTab.Order
	end

	HOVER_cons[button] = {}
	HOVER_cons[button][1] = button.MouseEnter:Connect(function()
		desc.ImageLabel.Image = itemInfo[oldSlotTab.Name].Image
		desc.Title.Text = itemInfo[oldSlotTab.Name].Description
		if HOVER_TES[button] then
			if HOVER_TES[button][1] then
				if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][1]:Cancel()
				end
			end
			if HOVER_TES[button][2] then
				if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][2]:Cancel()
				end
			end
		end
		HOVER_TES[button] = {}


		HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.HoverColor})
		HOVER_TES[button][1]:Play()

		HOVER_TES[button][2] = TS:Create(button.Img, TIS.Hover, {Size = HOVER_SETTINGS.OGSize + HOVER_SETTINGS.SizeAddition,  Position = HOVER_SETTINGS.OGPosition + HOVER_SETTINGS.PositionAddition})
		HOVER_TES[button][2]:Play()
	end)

	HOVER_cons[button][2] = button.MouseLeave:Connect(function()
		if HOVER_TES[button] then
			if HOVER_TES[button][1] then
				if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][1]:Cancel()
				end
			end
			if HOVER_TES[button][2] then
				if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
					HOVER_TES[button][2]:Cancel()
				end
			end
		end
		HOVER_TES[button] = {}

		HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.OGColor})
		HOVER_TES[button][1]:Play()

		HOVER_TES[button][2] = TS:Create(button.Img, TIS.Hover, {Size = HOVER_SETTINGS.OGSize,  Position = HOVER_SETTINGS.OGPosition})
		HOVER_TES[button][2]:Play()
	end)
	HOVER_cons[button][3] = rPop.Op1.MouseButton1Click:Connect(function() -- split
		--local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
		--local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
		local found = (currentRpop == button)--table.find(getGUI, button)

		if found then
			if oldSlotTab.Amount <= 1 then return end
			--print("split")
			local split0 = oldSlotTab.Amount/2
			local split1 = math.ceil(split0)
			local split2 = math.floor(split0)
			local slotTab = {}
			slotTab.Name = oldSlotTab.Name
			slotTab.Amount = split1
			--print(oldSlotTab)
			slotTab.Object = oldSlotTab.Object:Clone()
			slotTab.Object.Name = oldSlotTab.Name..(key + 1)
			slotTab.Object.Parent = box1
			slotTab.Object.Ind.Text = split1

			oldSlotTab.Amount = split2
			oldSlotTab.Object.Ind.Text = split2

			table.insert(slots[oldSlotTab.Name].List, slotTab)
			--local pos = (table.find(fullOrder, oldSlotTab.Object))
			local pos = (findInDict(fullOrder, oldSlotTab.Object))
			if not pos then
				pos = #fullOrder + 1 
			else
				pos += 1
			end
			table.insert(fullOrder, pos, slotTab.Object)	
			
			bindSlot(slotTab.Object, slotTab, key + 1)
			reOrderBox()
			setSlots:InvokeServer(slots, bars, equipped)
			--print(Data)
			clientUpdEv:Fire(Data)
		end
	end)
	HOVER_cons[button][4] = button.MouseButton2Click:Connect(function()
		rPopev:Fire()
		local mouseLocation = UIS:GetMouseLocation()
		rPop.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y - rPop.AbsoluteSize.Y)

		rPop.Op1.Text = "Split"
		rPop.Op2.Text = "Drop"

		rPop.Op1.Visible = true and button.Parent == box1
		rPop.Op2.Visible = true
		rPop.Op3.Visible = false

		rPop.Visible = true
		currentRpop = button

		coroutine.wrap(function()
			local cons = {}
			local function runEnd()
				rPop.Visible = false
				for i, v in pairs(cons) do
					if v then
						v:Disconnect()
					end
				end
			end

			table.insert(cons, UIS.InputBegan:Connect(function(inp, gP)
				--print(inp.UserInputType)
				local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
				local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
				local found = table.find(getGUI, rPop)
				if found then return end
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
					runEnd()
				end
			end))

			table.insert(cons, frame:WaitForChild("Inventory"):GetPropertyChangedSignal("Position"):Connect(function()
				runEnd()
			end))

			table.insert(cons, rPopev.Event:Connect(function()
				runEnd()
			end))

			table.insert(cons, box1:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				runEnd()
			end))

			table.insert(cons, button.MouseLeave:Connect(function()
				runEnd()
			end))
			--table.insert(cons, function()

			--end))
		end)()
	end)
	
	local but = nil
	HOVER_cons[button][5] = button.MouseButton1Down:Connect(function()
		local dragCons = {}
		local curslot = nil
		local tcurslot = nil
		local clo = button:Clone()
		button.Visible = false
		but = DraggableObject.new(clo, button)
		clo:WaitForChild("Ind").Visible = false
		clo.UIStroke.Transparency = 1
		clo.BackgroundTransparency = 1
		--print("down")
		local ogAp = button.AbsolutePosition
		local ogSz = button.AbsoluteSize
		--print(ogAp)
		clo.AnchorPoint = Vector2.new(0, 0)
		clo.ZIndex = 10
		clo.Parent = ui
		--clo.Size = UDim2.new(0.25, 0, 0.25, 0)
		--print(ogAp.Y)
		clo.Size = UDim2.new(0, ogSz.X, 0, ogSz.Y)
		--clo.Position = UDim2.new(0, ogAp.X + clo.Size.X.Offset/2, 0, ogAp.Y + clo.Size.Y.Offset*0.8)
		clo.Position = UDim2.new(0, ogAp.X, 0, ogAp.Y)
		local newAp = clo.AbsolutePosition.Y
		local calcY = math.abs(math.abs(clo.Position.Y.Offset) - math.abs(newAp))
		calcY += clo.Position.Y.Offset
		--print(clo.Position.Y)
		--print(clo.AbsolutePosition.Y)
		clo.Position = UDim2.new(0, clo.Position.X.Offset, 0, calcY)

		--HOVER_cons[clo][4.1] = RS.RenderStepped:Connect(function()
		--	local mpos = UIS:GetMouseLocation()
		--	clo.Position = UDim2.new(mpos.X - 0.016, 0, mpos.Y - 0.05, 0)

		--end)

		but:Enable()


		but.DragStarted = function()
			--local mouse = game.Players.LocalPlayer:GetMouse()

			local function updateSlotPosition()
				local slotSize = clo.Size
				local mouseLocation = Vector2.new(mouse.X - slotSize.X.Offset / 2, mouse.Y - slotSize.Y.Offset / 2)
				clo.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
			end

			table.insert(dragCons, mouse.Move:Connect(updateSlotPosition))

			for i, v in pairs(fakeBar:GetChildren()) do
				if v:IsA("Frame") then
					table.insert(dragCons, v:WaitForChild("Button").MouseEnter:Connect(function()
						v.UIStroke.Thickness = 3.5
						v.UIStroke.Transparency = 0
						v.UIStroke.Color = Color3.new(255, 255)
						tcurslot = v
					end))
					table.insert(dragCons, v:WaitForChild("Button").MouseLeave:Connect(function()
						if bars[tonumber(v.Name)] and (bars[tonumber(v.Name)].Equipped) then
							v.UIStroke.Thickness = 3.25
							v.UIStroke.Transparency = 0
							v.UIStroke.Color = Color3.new(255, 255, 255)
						else
							v.UIStroke.Thickness = 2
							v.UIStroke.Transparency = 0.3
							v.UIStroke.Color = Color3.new(255, 255, 255)
						end
						--tcurslot = nil
					end))
				end
			end
			--print("User has started dragging the frame")
			bindBar(fakeBar)
		end

		local ordered, pos, realslot
		but.Dragged = function(ObjPosition)
			local mouseLocation = UIS:GetMouseLocation()
			local slotSize = clo.Size
			local slotPosition = UDim2.new(0, mouseLocation.X - slotSize.X.Offset / 2, 0, mouseLocation.Y - slotSize.Y.Offset / 2)
			clo.Position = slotPosition

			local newslot
			if not storeframe:WaitForChild("Inventory"):WaitForChild("Station").Value then
				newslot = findSlot(clo, {box1}, nil, nil, "Slide")
			else
				newslot = findSlot(clo, {box1, storebox}, nil, nil, "Slide")
			end
			--local tnewslot = findSlot(clo, fakeBar, 30, "Frame")
			--print(button.AbsolutePosition)
			--print(newslot)
			--print(pos)
			if curslot ~= newslot and newslot ~= button then
				realslot = newslot.Parent
				if curslot then
					curslot.Parent.Slide.Visible = false
					curslot.Parent.Slide2.Visible = false
				end
				--print(fullOrder)
				ordered = sortButtonsByLayoutOrder(realslot.Parent)
				--print(ordered)
				pos = table.find(ordered, realslot)
				--print("reposition")
				--print(pos)
				--print(#fullOrder)
				if pos == #ordered then
					--print("ok")
					--print((clo.AbsolutePosition - newslot:FindFirstChild("Slide2").AbsolutePosition).Magnitude)
					--print((clo.AbsolutePosition - newslot:FindFirstChild("Slide").AbsolutePosition).Magnitude)
					if (clo.AbsolutePosition - realslot:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - realslot:FindFirstChild("Slide").AbsolutePosition).Magnitude then
						realslot.Slide.Visible = false
						realslot.Slide2.Visible = true
					else
						realslot.Slide2.Visible = false
						realslot.Slide.Visible = true
					end
				else
					realslot.Slide2.Visible = false
					realslot.Slide.Visible = true
				end
				curslot = newslot
			elseif pos then
				--print(ordered)
				--print(pos)
				if pos == #ordered then
					--print("ok")
					--print((clo.AbsolutePosition - newslot:FindFirstChild("Slide2").AbsolutePosition).Magnitude)
					--print((clo.AbsolutePosition - newslot:FindFirstChild("Slide").AbsolutePosition).Magnitude)
					if (clo.AbsolutePosition - realslot:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - realslot:FindFirstChild("Slide").AbsolutePosition).Magnitude then
						realslot.Slide.Visible = false
						realslot.Slide2.Visible = true
					else
						realslot.Slide2.Visible = false
						realslot.Slide.Visible = true
					end
				else
					realslot.Slide2.Visible = false
					realslot.Slide.Visible = true
				end
			end
			--if (tcurslot ~= tnewslot and tnewslot ~= button) then
			--	if tcurslot then
			--		tcurslot.UIStroke.Thickness = 2
			--		tcurslot.UIStroke.Transparency = 0.3
			--		tcurslot.UIStroke.Color = Color3.new(255, 255, 255)
			--	end
			--	if tnewslot then
			--		tnewslot.UIStroke.Thickness = 3.5
			--		tnewslot.UIStroke.Transparency = 0
			--		tnewslot.UIStroke.Color = Color3.new(255, 255)
			--		--tnewslot.Slide.Visible = true
			--		tcurslot = tnewslot
			--	else
			--		tcurslot.UIStroke.Thickness = 2
			--		tcurslot.UIStroke.Transparency = 0.3
			--		tcurslot.UIStroke.Color = Color3.new(255, 255, 255)
			--		tnewslot = nil
			--		tcurslot = nil
			--	end
			--end
			--print("Frame is currently at", ObjPosition)
		end

		local function undid()
			--print("User has stopped dragging the frame")
			--if HOVER_cons[button][4.1] then
			--	HOVER_cons[button][4.1]:Disconnect()
			--end

			but:Disable()
			if clo then
				clo:Destroy()
			end
			if but then

			end

			for i, v in pairs(dragCons) do
				v:Disconnect()
			end

			for i, v in pairs(fakeBar:GetChildren()) do
				if v:IsA("Frame") then
					local button = v.Button
					if HOVER_cons[button] then
						if HOVER_cons[button][1] then
							HOVER_cons[button][1]:Disconnect()
						end
						if HOVER_cons[button][2] then
							HOVER_cons[button][2]:Disconnect()
						end
						HOVER_cons[button] = nil
					end
					if HOVER_TES[button] then
						if HOVER_TES[button][1] then
							if HOVER_TES[button][1].PlaybackState == Enum.PlaybackState.Playing then
								HOVER_TES[button][1]:Cancel()
							end
						end
						if HOVER_TES[button][2] then
							if HOVER_TES[button][2].PlaybackState == Enum.PlaybackState.Playing then
								HOVER_TES[button][2]:Cancel()
							end
						end
					end
					HOVER_TES[button] = {}

					HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS2.OGColor})
					HOVER_TES[button][1]:Play()

					HOVER_TES[button][2] = TS:Create(v.Img, TIS.Hover, {Size = HOVER_SETTINGS2.OGSize,  Position = HOVER_SETTINGS2.OGPosition})
					HOVER_TES[button][2]:Play()
				end
			end

			local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
			local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
			local checkFound2 = table.find(getGUI, storebox.Parent)
			local inStation = storeframe:WaitForChild("Inventory"):WaitForChild("Station").Value
			local inEmptyStore = inStation and checkFound2 and #storebox:GetChildren() <= 2
			local ies = false
			if inEmptyStore then	
				--print("done it")

				local key2 = (findInDict(fullOrder, button))
				
				--print(key2)
				
				local actionData = {
					build = inStation,
					item = oldSlotTab.Name,
					--count = findInDict(fullOrder, oldSlotTab.Object),
					count = key,
				}
				ies = true
				buildInvSend:FireServer("Transfer", actionData)
			elseif curslot then
				curslot.Parent.Slide.Visible = false
				curslot.Parent.Slide2.Visible = false
				local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
				local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
				local found = table.find(getGUI, curslot.Parent)
				local tfound = table.find(getGUI, tcurslot)
				local checkFound = table.find(getGUI, box1.Parent)
				--for _, GuiObject in pairs(getGUI) do
				--	print(GuiObject)
				--end
				--local tfound2 = findTab(tcurslot)
				local found2 = findTab(curslot.Parent)
				
				--print(oldSlotTab.Object.Parent)
				if (curslot.Parent.Parent == storebox and inStation) or button.Parent == storebox then
					if curslot.Parent.Parent == box1 then -- move back
						local pos = (findInDict(fullOrder, curslot.Parent))
						local key2 = (findInDict(fullOrder2, button))

						table.remove(fullOrder2, table.find(fullOrder2, button))
						
						if not pos then
							pos = #fullOrder2 + 1 
						else
							if (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide").AbsolutePosition).Magnitude then
								pos += 1
							else
								pos += 0
							end
						end

						table.insert(fullOrder, pos, button)

						local actionData = {
							build = inStation,
							item = oldSlotTab.Name,
							--count = findInDict(fullOrder, oldSlotTab.Object),
							count = key,
							target = pos
						}
						local moveOrStack = "Stackback" 
						if ((not found2 or found2.Name ~= oldSlotTab.Name) or not itemInfo[oldSlotTab.Name].Stackable) then
							moveOrStack = "Transferback"
						end
						--print("1")
						ies = true
						buildInvSend:FireServer(moveOrStack, actionData)
					elseif (inStation and checkFound2) and button.Parent == box1 then -- move in
						local pos = (findInDict(fullOrder2, curslot.Parent))
						local key2 = (findInDict(fullOrder, button))

						table.remove(fullOrder, table.find(fullOrder, button))
						
						if not pos then
							pos = #fullOrder2 + 1 
						else
							if (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide").AbsolutePosition).Magnitude then
								pos += 1
							else
								pos += 0
							end
						end

						table.insert(fullOrder2, pos, button)
						
						local actionData = {
							build = inStation,
							item = oldSlotTab.Name,
							--count = findInDict(fullOrder, oldSlotTab.Object),
							count = key,
							target = pos
						}
						local moveOrStack = "Transfer" 
						if ((not found2 or found2.Name ~= oldSlotTab.Name) or not itemInfo[oldSlotTab.Name].Stackable) then
							moveOrStack = "Stack"
						end
						ies = true
						buildInvSend:FireServer(moveOrStack, actionData)
					elseif (inStation and checkFound2) and button.Parent == storebox then -- reposition
						--print(fullOrder)
						--print(fullOrder2)
						local pos = (findInDict(fullOrder2, curslot.Parent))
						local key2 = (findInDict(fullOrder2, button))

						if not pos then
							pos = #fullOrder2 + 1 
						else
							if (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide").AbsolutePosition).Magnitude then
								pos += 1
							else
								pos += 0
							end
						end

						local actionData = {
							build = inStation,
							item = oldSlotTab.Name,
							--count = findInDict(fullOrder, oldSlotTab.Object),
							count = key,
							target = pos
						}
						
						local moveOrStack = "Stackpos" 
						if ((not found2 or found2.Name ~= oldSlotTab.Name) or not itemInfo[oldSlotTab.Name].Stackable) then
							moveOrStack = "Standardpos"
						end
						--print("1")
						ies = true
						buildInvSend:FireServer(moveOrStack, actionData)
					end
				elseif curslot.Parent.Parent == box1 then
					if checkFound and ((not found2 or found2.Name ~= oldSlotTab.Name) or (not itemInfo[oldSlotTab.Name].Stackable)) then -- reposition
						--print(fullOrder)
						--print(findInDict(fullOrder, oldSlotTab.Object))
						--print(fullOrder)
						table.remove(fullOrder, findInDict(fullOrder, oldSlotTab.Object))
						local pos = (findInDict(fullOrder, curslot.Parent))
						--print("reposition")
						if not pos then
							pos = #fullOrder + 1 
						else
							if (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide2").AbsolutePosition).Magnitude < (clo.AbsolutePosition - curslot.Parent:FindFirstChild("Slide").AbsolutePosition).Magnitude then
								pos += 1
							else
								pos += 0
							end
						end
						--print(fullOrder)
						--print(oldSlotTab.Object)
						table.insert(fullOrder, pos, oldSlotTab.Object)
						--print(fullOrder)

						--bindSlot(oldSlotTab.Object, oldSlotTab, pos)
						--print(fullOrder)
					elseif checkFound and itemInfo[oldSlotTab.Name].Stackable then -- restack
						--print("hovering")
						local item = slots[found2.Name]
						local me = findInList(item.List, oldSlotTab.Object)
						--print(me)
						local og = found2.Amount
						found2.Amount += item.List[me].Amount
						local new = found2.Amount
						item.List[me] = nil

						--print(item)
						--print(found2.Amount)

						-- delete button
						local path = {oldSlotTab.Name, "List", me}
						local name = oldSlotTab.Name
						local oldequipped = false

						for i, v in pairs(bars) do
							--print(v.Name)
							--print(name)
							--print(v.Name == name)
							--print(v.Path)
							--print(path)
							--print(v.Path == path)
							--if v.Path == path and v.Name == name then
							--print(v.Path)
							--print(path)
							--print(v.Name)
							--print(name)
							if tablesAreEqual(v.Path, path) and v.Name == name then
								--print("passed")
								local bar1, bar2 = fakeBar:FindFirstChild(tostring(i)), mainbar:FindFirstChild(tostring(i))
								bar1.Img.Image = ""
								bar2.Img.Image = ""
								if v.Equipped then	
									bar1.UIStroke.Thickness = 2
									bar1.UIStroke.Transparency = 0.3
									bar1.UIStroke.Color = Color3.new(255, 255, 255)

									bar2.UIStroke.Thickness = 2
									bar2.UIStroke.Transparency = 0.3
									bar2.UIStroke.Color = Color3.fromRGB(86, 86, 98)
									equipped = nil
									barChange:Fire("Unequip")
								end
								bars[i] = nil
								break
							end
						end

						table.remove(fullOrder, findInDict(fullOrder, oldSlotTab.Object))
						--

						for i, v in pairs(HOVER_cons[button]) do
							v:Disconnect()
						end
						button:Destroy()
						coroutine.wrap(function()
							local dif = math.floor(math.abs(new - og))
							local tim = math.clamp(((dif * 0.04) * ADD_TIME.BASE), ADD_TIME.MIN , ADD_TIME.CAP) --ADD_TIME.CAP
							local div = tim/dif
							if runs[found2.Object] then
								runs[found2.Object]:Fire()
							else
								runs[found2.Object] = Instance.new("BindableEvent")
							end
							--50 
							--100
							--1/50
							local stopped = false
							local con
							con = runs[found2.Object].Event:Connect(function()
								stopped = true
								con:Disconnect()
								--if runs[found2.Object] then
								--	runs[found2.Object]:Destroy()
								--end
							end)

							--print(dif)
							for i = 1, dif do
								--print(i)
								if stopped then break end

								if new > og then
									found2.Object.Ind.Text = og + i
								else
									found2.Object.Ind.Text = og - i
								end

								task.wait(div)
							end
							if not stopped then
								found2.Object.Ind.Text = new
							end
							if con then
								con:Disconnect()
								--if runs[found2.Object] then
								--	runs[found2.Object]:Destroy()
								--end
							end
						end)()
					elseif tfound then -- equip
						local item = slots[oldSlotTab.Name]
						local me = findInList(item.List, oldSlotTab.Object)
						local path = {oldSlotTab.Name, "List", me}
						local name = oldSlotTab.Name
						local pos = tonumber(tcurslot.Name)
						local oldequipped = false
						for i, v in pairs(bars) do
							--print(v.Name)
							--print(name)
							--print(v.Name == name)
							--print(v.Path)
							--print(path)
							--print(v.Path == path)
							--if v.Path == path and v.Name == name then
							if tablesAreEqual(v.Path, path) and v.Name == name then
								print("passed")
								oldequipped = v.Equipped or false
								fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
								mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
								bars[i] = nil
							end
						end
						bars[tonumber(tcurslot.Name)] = {
							["Name"] = name,
							["Pos"] = pos,
							["Path"] = path,
							["Equipped"] = oldequipped or mainbar:FindFirstChild(tonumber(tcurslot.Name)).UIStroke.Thickness > 2
						}
						equipped = bars[tonumber(tcurslot.Name)].Equipped or nil
						tcurslot.Img.Image = button.Img.Image
						mainbar:FindFirstChild(tostring(pos)).Img.Image = button.Img.Image
						--print(bars)
					end
					--print(fullOrder)
					reOrderBox()
					--print(fullOrder)
					setSlots:InvokeServer(slots, bars, equipped)
					local Data = getData:InvokeServer("Inventory")
					print(Data)
					clientUpdEv:Fire(Data)
				end
				if curslot.Parent then
					curslot.Parent.Slide.Visible = false
					curslot.Parent.Slide2.Visible = false
					curslot = nil
				end
			end
			if tcurslot then
				--print(tonumber(tcurslot.Name))
				if (bars[tonumber(tcurslot.Name)] and bars[tonumber(tcurslot.Name)].Equipped) or mainbar:FindFirstChild(tonumber(tcurslot.Name)).UIStroke.Thickness > 2 then
					tcurslot.UIStroke.Thickness = 3.25
					tcurslot.UIStroke.Transparency = 0
					tcurslot.UIStroke.Color = Color3.new(255, 255, 255)
				else
					tcurslot.UIStroke.Thickness = 2
					tcurslot.UIStroke.Transparency = 0.3
					tcurslot.UIStroke.Color = Color3.new(255, 255, 255)
				end
				tcurslot = nil
			end
			button.Visible = true and not ies
		end

		but.DragEnded = function()
			undid()
		end
		clo.MouseButton1Up:Connect(function()
			undid()
		end)
		--clo.MouseLeave:Connect(function()
		--	undid()
		--end)
	end)
	--HOVER_cons[button][5] = button.MouseButton1Up:Connect(function()
	--end)
end

local function bindToolbar()
	for i, v in pairs(mainbar:GetChildren()) do
		if v:IsA("Frame") then
			local button = v:WaitForChild("Button")
			local function bindbartool()
				--if not bars[tonumber(v.Name)] then return end
				--print(v)
				local oldT = v.UIStroke.Transparency
				for i, v2 in pairs(mainbar:GetChildren()) do
					if not v2:IsA("Frame") then continue end
					if bars[tonumber(v2.Name)] and v2 ~= v --[[or (bars[tonumber(v2.Name)].Name ~= v2.Name and not tablesAreEqual(bars[tonumber(v2.Name)].Path, v.Path))]] then
						bars[tonumber(v2.Name)].Equipped = false
					end
					--print(v2)
					local obj = v2
					obj.UIStroke.Thickness = 2
					obj.UIStroke.Transparency = 0.3
					obj.UIStroke.Color = Color3.fromRGB(86, 86, 98)

					local obj2 = fakeBar:WaitForChild(tostring(v2.Name))
					obj2.UIStroke.Thickness = 2
					obj2.UIStroke.Transparency = 0.3
					obj2.UIStroke.Color = Color3.new(255, 255, 255)

					--print("out")
					slideOut(obj, obj2)
				end

				--print(tonumber(v.Name))
				--print(bars)
				--print(bars[tonumber(v.Name)].Equipped)
				if bars[tonumber(v.Name)] then
					if not bars[tonumber(v.Name)].Equipped then
						-- equip
						bars[tonumber(v.Name)].Equipped = true
						equipped = bars[tonumber(v.Name)]
						barChange:Fire("Equip", bars[tonumber(v.Name)].Name)
						v.UIStroke.Thickness = 3.25
						v.UIStroke.Transparency = 0
						v.UIStroke.Color = Color3.new(255, 255, 255)

						local obj2 = fakeBar:WaitForChild(v.Name)
						obj2.UIStroke.Thickness = 3.25
						obj2.UIStroke.Transparency = 0
						obj2.UIStroke.Color = Color3.new(255, 255, 255)

						slideIn(v, obj2)
					else
						-- unequip
						bars[tonumber(v.Name)].Equipped = false
						local obj2 = fakeBar:WaitForChild(v.Name)
						slideOut(v, obj2)
						equipped = nil
						barChange:Fire("Unequip")
					end
				else
					--print(v.UIStroke)
					--print(v.UIStroke.Transparency)
					--print(v.UIStroke.Transparency ~= 0)
					if oldT ~= 0 then
						-- "equip"
						v.UIStroke.Thickness = 3.25
						v.UIStroke.Transparency = 0
						v.UIStroke.Color = Color3.new(255, 255, 255)

						local obj2 = fakeBar:WaitForChild(v.Name)
						obj2.UIStroke.Thickness = 3.25
						obj2.UIStroke.Transparency = 0
						obj2.UIStroke.Color = Color3.new(255, 255, 255)

						equipped = nil
						barChange:Fire("Unequip")
						slideIn(v, obj2)
					else
						-- "unequip"
						v.UIStroke.Thickness = 2
						v.UIStroke.Transparency = 0.3
						v.UIStroke.Color = Color3.fromRGB(86, 86, 98)

						local obj2 = fakeBar:WaitForChild(v.Name)
						obj2.UIStroke.Thickness = 2
						obj2.UIStroke.Transparency = 0.3
						obj2.UIStroke.Color = Color3.new(255, 255, 255)

						equipped = nil
						barChange:Fire("Unequip")
						slideOut(v, obj2)
					end
				end
				setSlots:InvokeServer(slots, bars, equipped)
				local Data = getData:InvokeServer("Inventory")
				--print(Data)
				clientUpdEv:Fire(Data)
			end
			BAR_cons[button] = {}
			BAR_cons[button][1] = button.MouseButton1Click:Connect(function()
				bindbartool()
			end)
			BAR_cons[button][2] = UIS.InputBegan:Connect(function(inp, gP) 
				if gP then return end
				if inp.KeyCode == KeysIndex[tonumber(v.Name)] then
					bindbartool()
				end
			end)
			--BAR_cons[button].MouseButton1Click:Connect(function()

			--end)
		end
	end
end

local function bindBuildsAddition()
	--for i, v in pairs(workspace.BUILDS:GetChildren()) do
	--	local updUiEv = v:WaitForChild("UpdateUI")
	--	updUiEv.OnClientEvent:Connect(function()

	--	end)
	--end
	storeframe:WaitForChild("Inventory"):WaitForChild("Station").Changed:Connect(function(newVal)
		if newVal ~= nil then
			currentBump = false
			if currentCon then
				currentCon:Disconnect()
			end
			local updUiEv = newVal:WaitForChild("UpdateUI", 5)
			if updUiEv then
				currentCon = updUiEv.OnClientEvent:Connect(function(ogPlr, way, Data)
					--print(Data)
					if ogPlr ~= plr or not currentBump then
						currentBump = true
						menu.updateStoreInventory(storebox, way, Data)
					end
				end)
			end
		end
	end)
end

-- Global Functions
function menu.updateInventory(already)
	--print(slots)
	local Data = getData:InvokeServer("Inventory")
	--print(Data)
	clientUpdEv:Fire(Data)

	crafting.updCorrectUI(Data)

	local invData = Data.Data[1]
	local slotData = Data.Data[2]
	local barData = Data.Data[3]

	--print(invData.BaseData)

	-- do stuff
	--print(invData.SlotData)
	--print(slotData)
	if already and not slotData then
		--print("1")
		for i, v in pairs(invData) do
			--print(v)
			if not itemInfo[i] then continue end
			local stackable, rarity = itemInfo[i].Stackable, itemInfo[i].Rarity
			local ringInfo = colorSettings[rarity.." Color"]

			if not slots[i] or not stackable then
				if not slots[i] then
					slots[i] = {}
					--slots[i].Order = #slots + 1
					slots[i].List = {}
				end

				local function newslot(amt)
					local slotTab = {}
					table.insert(slots[i].List, slotTab)
					slotTab.Name = i
					slotTab.Amount = amt

					slotTab.Object = script:WaitForChild("Slot"):Clone()
					--print(slotTab.Object)
					bindSlot(slotTab.Object, slotTab, 1)

					--slotTab.Order = ((#box1:GetChildren() - 3) + 1)
					--slotTab.Object.LayoutOrder = slotTab.Order
					if not stackable then
						slotTab.Object.Ind.Visible = false
					end

					slotTab.Object.Name = i.."1"
					slotTab.Object.Parent = box1
					slotTab.Object.Ind.Text = amt
					slotTab.Object.Img.Image = itemInfo[i].Image

					slotTab.Object.UIStroke.Color = ringInfo.Color
					for i3, v3 in pairs(ringInfo.Objs) do
						local ob = Instance.new(i3, slotTab.Object.UIStroke)
						for i4, v4 in pairs(v3) do
							ob[i4] = v4
						end
					end

					table.insert(fullOrder, slotTab.Object)	
				end

				if stackable then
					newslot(v)
				else
					for i = 1, v do
						newslot(1)
					end
				end

				--slots[i].Object.
			else
				local slotTab = slots[i].List[1]
				slotTab.Object.Ind.Text = v
			end

			bars = barData
			for i, v in pairs(barData) do
				fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				if v.Equipped then
					equipped = bars[tonumber(v.Name)]
					barChange:Fire("Equip", bars[tonumber(v.Name)].Name)
					local obj = mainbar:WaitForChild(tostring(v.Pos))
					obj.UIStroke.Thickness = 3.25
					obj.UIStroke.Transparency = 0
					obj.UIStroke.Color = Color3.new(255, 255, 255)

					local obj2 = fakeBar:WaitForChild(tostring(v.Pos))
					obj2.UIStroke.Thickness = 3.25
					obj2.UIStroke.Transparency = 0
					obj2.UIStroke.Color = Color3.new(255, 255, 255)

					coroutine.wrap(function()
						local con
						con = mainbar:GetAttributeChangedSignal("CanMove"):Connect(function()
							if mainbar:GetAttribute("CanMove") then
								con:Disconnect()
								slideIn(obj, obj2)
							end
						end)
					end)()
				end
			end
		end
	else
		--print("2")
		--print(slotData)
		if already then
			slots = slotData
		end
		--print(slotData)
		--print(slots)

		for i, v in pairs(slotData) do
			if not itemInfo[i] then continue end
			--print(i)
			local stackable, rarity = itemInfo[i].Stackable, itemInfo[i].Rarity
			local ringInfo = colorSettings[rarity.." Color"]

			if not slots[i] or #slotData[i].List <= 0 then
				slots[i] = {}
				slots[i].List = {}
			end


			if #v.List > 0 then
				for i2, object in pairs(v.List) do
					local foundSlot = box1:FindFirstChild(tostring(i)..tostring(i2))
					--print(foundSlot)
					--print(tostring(i)..tostring(i2))
					if foundSlot and foundSlot:IsA("TextButton") then
						--print("1of")
						local og = tonumber(foundSlot.Ind.Text)
						local new = tonumber(slotData[i].List[i2].Amount)
						--print(og, new)
						if og == new then
							foundSlot.Ind.Text = new
						else
							coroutine.wrap(function()
								local dif = math.floor(math.abs(new - og))
								local tim = math.clamp(((dif * 0.04) * ADD_TIME.BASE), ADD_TIME.MIN , ADD_TIME.CAP) --ADD_TIME.CAP
								local div = tim/dif
								if runs[foundSlot] then
									runs[foundSlot]:Fire()
								else
									runs[foundSlot] = Instance.new("BindableEvent")
								end
								--50 
								--100
								--1/50
								local stopped = false
								local con
								con = runs[foundSlot].Event:Connect(function()
									stopped = true
									con:Disconnect()
								end)

								--print(dif)
								for i = 1, dif do
									--print(i)
									if stopped then break end

									if new > og then
										foundSlot.Ind.Text = og + i
									else
										foundSlot.Ind.Text = og - i
									end

									task.wait(div)
								end
								if not stopped then
									foundSlot.Ind.Text = new
								end
								if con then
									con:Disconnect()
								end
							end)()
						end
					else
						--print("2of")
						if not slots[i].List[i2] then
							slots[i].List[i2] = {}
						end
						slots[i].List[i2].Object = script:WaitForChild("Slot"):Clone()
						--print("binding")
						--print(slots[i].List[i2].Object)
						if not stackable then
							slots[i].List[i2].Object.Ind.Visible = false
						end

						bindSlot(slots[i].List[i2].Object, slots[i].List[i2], i2)
						slots[i].List[i2].Object.Name = (tostring(i)..tostring(i2))
						slots[i].List[i2].Object.Parent = box1
						slots[i].List[i2].Object.Ind.Text = slotData[i].List[i2].Amount

						--slots[i].List[i2].Order = slotData[i].List[i2].Order or ((#box1:GetChildren() - 3) + 1)
						--slots[i].List[i2].Object.LayoutOrder = slots[i].List[i2].Order

						slots[i].List[i2].Object.Img.Image = itemInfo[i].Image

						slots[i].List[i2].Object.UIStroke.Color = ringInfo.Color
						for i3, v3 in pairs(ringInfo.Objs) do
							local ob = Instance.new(i3, slots[i].List[i2].Object.UIStroke)
							for i4, v4 in pairs(v3) do
								ob[i4] = v4
							end
						end
						--print(i)
						--print(slotData[i].List[i2].Order)
						local order = slotData[i].List[i2].Order
						if not order then
							table.insert(fullOrder, slots[i].List[i2].Object)
						else
							table.insert(fullOrder, order, slots[i].List[i2].Object)
							--print(fullOrder)
						end		
					end
					if slots[i].List[i2] then
						slots[i].List[i2].Name = i
						slots[i].List[i2].Amount = slotData[i].List[i2].Amount
					end
					--print(slots)
				end
			else
				-- local i = "Basic Sword" local buttonName = "Basic Sword5786" print(string.sub(buttonName, 1, string.len(i))) --> Basic Sword
				for i2, v in pairs(box1:GetChildren()) do
					if string.sub(v.Name, 1, string.len(i)) == i then
						v:Destroy()
					end
				end
			end
			--print(slots)
		end
		--print("final")
		--print(slots)

		-- clear nonexistants
		--print(slots)
		--print(slotData)
		for i, v in pairs(slots) do
			for i2, object in pairs(v.List) do
				if not slotData[i].List[i2] then
					local foundSlot = box1:FindFirstChild(tostring(i)..tostring(i2))
					--print(foundSlot)
					--print(tostring(i)..tostring(i2))
					if foundSlot and foundSlot:IsA("TextButton") then
						foundSlot:Destroy()
					end
					slots[i].List[i2] = nil
				end
				--print(slots)
			end
		end

		-- equiptoolbarshi
		bars = barData
		--print(barData)
		for i, v in pairs(barData) do
			if v.Path then
				fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				if v.Equipped then
					--print(v)
					--print(bars[tonumber(v.Name)])
					--print(bars[tonumber(v.Pos)])
					equipped = bars[tonumber(v.Pos)]
					if bars[tonumber(v.Pos)] then
						barChange:Fire("Equip", bars[tonumber(v.Pos)].Name)
					end

					local obj = mainbar:WaitForChild(tostring(v.Pos))
					obj.UIStroke.Thickness = 3.25
					obj.UIStroke.Transparency = 0
					obj.UIStroke.Color = Color3.new(255, 255, 255)

					local obj2 = fakeBar:WaitForChild(tostring(v.Pos))
					obj2.UIStroke.Thickness = 3.25
					obj2.UIStroke.Transparency = 0
					obj2.UIStroke.Color = Color3.new(255, 255, 255)

					coroutine.wrap(function()
						local con
						con = mainbar:GetAttributeChangedSignal("CanMove"):Connect(function()
							if mainbar:GetAttribute("CanMove") then
								con:Disconnect()
								slideIn(obj, obj2)
							end
						end)
					end)()
				end
			else
				--print(v)
				--print(bars[tonumber(v.Name)])
				--print(bars[tonumber(v.Pos)])
				if v.Equipped then
					equipped = nil
					if bars[tonumber(v.Pos)] then
						barChange:Fire("Unequip")
					end
				end

				local obj = mainbar:WaitForChild(tostring(v.Pos))
				obj.UIStroke.Thickness = 2
				obj.UIStroke.Transparency = 0.3
				obj.UIStroke.Color = Color3.fromRGB(86, 86, 98)

				local obj2 = fakeBar:WaitForChild(tostring(v.Pos))
				obj2.UIStroke.Thickness = 2
				obj2.UIStroke.Transparency = 0.3
				obj2.UIStroke.Color = Color3.fromRGB(255, 255, 255)

				obj.Img.Image = ""
				obj2.Img.Image = ""

				slideOut(obj, obj2)
				bars[i] = nil
			end
		end
		reOrderBox()
		--print(slots)
		--slots[i].Object.
	end
	--print("last")
	--print(slots)
	setSlots:InvokeServer(slots, bars, equipped)
	local Data = getData:InvokeServer("Inventory")
	--print(Data)
	clientUpdEv:Fire(Data)
end

function menu.fadeOut()
	menu.In = false

	-- stop other tweens
	for i, v in pairs(TES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end

	local F1 = SECTIONS.Inventory.Frames.F1

	-- unique tweens

	TES[F1.Frame] = TS:Create(F1.Frame, TIS.Close, {Position = ClosedPos, Size = F1.Size - UDim2.new(0.3, 0, 0.3, 0)})

	for i, v in pairs(SECTIONS) do
		if not v.Frames.F2 then continue end
		local invalid = false

		if menu.currentSection then
			if menu.currentSection.Frames then
				if menu.currentSection.Frames.F2 then
					if menu.currentSection.Frames.F2.Frame == v.Frames.F2.Frame then
						invalid = true
						TES[v.Frames.F2.Frame] = TS:Create(v.Frames.F2.Frame, TIS.Close, {Position = ClosedPos, Size = v.Frames.F2.Size - UDim2.new(0.3, 0, 0.3, 0)})
					end	
				end
			end
		end
		if not invalid then
			v.Frames.F2.Frame.Visible = false
			v.Frames.F2.Frame.Position = ClosedPos
			v.Frames.F2.Frame.Size = v.Frames.F2.Size - UDim2.new(0.3, 0, 0.3, 0)
		end
	end

	local ALT = SECTIONS.Inventory.Alt
	TES[ALT.Frame] = TS:Create(ALT.Frame, TIS.Open, {Position = ALT.Position2, Size = ALT.Size2})

	--print(TES)
	for i, v in pairs(TES) do
		--print(TES.PlaybackState) 
		if v.PlaybackState ~= Enum.PlaybackState.Playing then
			v:Play()
		end
	end
end

function menu.fadeIn(section)
	--print(section)
	-- check and set, and record last section
	if not SECTIONS[section] then return end
	local oldSection = menu.currentSection
	menu.currentSection = SECTIONS[section]

	-- keep record of in & ou
	local opening = not menu.In
	menu.In = true

	-- stop other tweens
	for i, v in pairs(TES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	--print(menu.currentSection)
	local F1, F2 = menu.currentSection.Frames.F1, menu.currentSection.Frames.F2
	local ALT = SECTIONS.Inventory.Alt
	--print(F1, F2)

	-- unique tweens
	if menu.currentSection == SECTIONS.Inventory then -- INVENTORY TWEEN IN
		--elseif menu.currentSection == SECTIONS.Crafting then  -- CRAFT OPENING
	end

	-- remove that pesky toolbar and other potential alts
	--if oldSection and oldSection.Alt then
	--	print(oldSection)
	--	local ALT = oldSection.Alt
	--	TES[ALT.Frame] = TS:Create(ALT.Frame, TIS.Open, {Position = ALT.Position2, Size = ALT.Size2})
	--end

	TES[F1.Frame] = TS:Create(F1.Frame, TIS.Open, {Position = F1.Position, Size = F1.Size})
	F1.Frame.Visible = true

	-- put back other frames
	if not opening then
		for i, v in pairs(SECTIONS) do
			if not v.Frames.F2 then continue end
			if v ~= oldSection then
				v.Frames.F2.Frame.Visible = true
			end
			TES[v.Frames.F2.Frame] = TS:Create(v.Frames.F2.Frame, TIS.Close, {Position = F1.Position, Size = v.Frames.F2.Size - UDim2.new(0.5, 0, 0.5, 0)})
		end
	else
		for i, v in pairs(SECTIONS) do
			if not v.Frames.F2 then continue end
			if v ~= oldSection then
				v.Frames.F2.Frame.Visible = false
				v.Position = F1.Position
				v.Size = v.Frames.F2.Size - UDim2.new(0.5, 0, 0.5, 0)
			end
		end
	end

	if F2 then
		F2.Frame.Size =  F2.Size - UDim2.new(0.5, 0, 0.5, 0)
		F2.Frame.Position = F1.Frame.Position
		F2.Frame.Visible = true
		TES[F2.Frame] = TS:Create(F2.Frame, TIS.Open, {Position = F2.Position, Size = F2.Size})
		--print(F2.Position)
	end

	local there = menu.currentSection == SECTIONS.Inventory --[[false
	for i, v in pairs(menu.currentSection.Frames) do
		if v.Frame == SECTIONS.Inventory.Frames.F1.Frame then
			there = true break
		end
	end]]

	if there then
		TES[ALT.Frame] = TS:Create(ALT.Frame, TIS.Open, {Position = ALT.Position, Size = ALT.Size})
	else
		TES[ALT.Frame] = TS:Create(ALT.Frame, TIS.Open, {Position = ALT.Position2, Size = ALT.Size2})
	end

	for i, v in pairs(TES) do
		--print(v)
		if v.PlaybackState ~= Enum.PlaybackState.Playing then
			v:Play()
		end
	end
end

function menu.setup()
	for i, v in pairs(mainbar:GetChildren()) do
		if v:IsA("Frame") then
			v.UIStroke.Transparency = 0.3
		end
	end
	mainbar:GetAttributeChangedSignal("CanMove"):Connect(function()
		if not mainbar:GetAttribute("CanMove") then
			for i, v in pairs(BAR_HOVER_cons) do
				if v[1] then
					if v[1].PlaybackState == Enum.PlaybackState.Playing then
						v[1]:Cancel()
					end
				end
			end
		else
			for i, v2 in pairs(bars) do
				local obj = mainbar:WaitForChild(tostring(v2.Pos))
				local obj2 = fakeBar:WaitForChild(tostring(v2.Pos))
				if v2.Equipped then
					slideIn(obj, obj2)
				end
			end
			for pos = 1, #bars do
				local obj = mainbar:WaitForChild(tostring(pos))
				local obj2 = fakeBar:WaitForChild(tostring(pos))
				if obj.UIStroke.Transparency == 0 then
					slideIn(obj, obj2)
				end
			end
		end
	end)

	--if not menu.currentSection then menu.currentSection = SECTIONS.Inventory end
	SECTIONS.Inventory.Frames.F1.Frame.Size = UDim2.new(UDim.new(SECTIONS.Inventory.Frames.F1.Size.X.Scale - 0.3), UDim.new(SECTIONS.Inventory.Frames.F1.Size.Y.Scale - 0.3))
	SECTIONS.Inventory.Frames.F1.Frame.Position = UDim2.new(0.5, 0, 2.15, 0)
	SECTIONS.Inventory.Frames.F1.Frame.Visible = false

	for i, v in pairs(SECTIONS) do
		if not v.Frames.F2 then continue end
		v.Frames.F2.Frame.Position = ClosedPos
		v.Frames.F2.Frame.Size = v.Frames.F2.Size - UDim2.new(0.3, 0, 0.3, 0)
		SECTIONS.Inventory.Frames.F1.Frame.Visible = false
	end

	-- clear box
	for i, v in pairs(box1:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	crafting.setup()

	menu.updateInventory(true)
	bindBar(mainbar)
	bindToolbar()
	bindBuildsAddition()
	ItemIndicator.setup()

	--
	dataUpdEv.OnClientEvent:Connect(function(which, item, changed)
		if which == "Inventory" then
			menu.updateInventory()
		end
	end)
end

function menu.loadCrafting(station)
	crafting.setup(station)
end

function menu.updateStoreInventory(invbox, way, data)
	if way == "Basic" then
		for i, v in pairs(invbox:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end

		local invData = data[1]
		local slotData = data[2]
		local barData = data[3]
		--print(slotData)
		fullOrder2 = {}
		oslots = slotData
		if slotData then
			for i, v in pairs(slotData) do
				if not itemInfo[i] then continue end
				--print(i)
				local stackable, rarity = itemInfo[i].Stackable, itemInfo[i].Rarity
				local ringInfo = colorSettings[rarity.." Color"]

				if not oslots[i] or #slotData[i].List <= 0 then
					oslots[i] = {}
					oslots[i].List = {}
				end


				if #v.List > 0 then
					for i2, object in pairs(v.List) do
						local foundSlot = invbox:FindFirstChild(tostring(i)..tostring(i2))
						--print(foundSlot)
						--print(tostring(i)..tostring(i2))
						if foundSlot and foundSlot:IsA("TextButton") then
							--print("1of")
							local og = tonumber(foundSlot.Ind.Text)
							local new = tonumber(slotData[i].List[i2].Amount)
							--print(og, new)
							if og == new then
								foundSlot.Ind.Text = new
							else
								coroutine.wrap(function()
									local dif = math.floor(math.abs(new - og))
									local tim = math.clamp(((dif * 0.04) * ADD_TIME.BASE), ADD_TIME.MIN , ADD_TIME.CAP) --ADD_TIME.CAP
									local div = tim/dif
									if runs[foundSlot] then
										runs[foundSlot]:Fire()
									else
										runs[foundSlot] = Instance.new("BindableEvent")
									end
									--50 
									--100
									--1/50
									local stopped = false
									local con
									con = runs[foundSlot].Event:Connect(function()
										stopped = true
										con:Disconnect()
									end)

									--print(dif)
									for i = 1, dif do
										--print(i)
										if stopped then break end

										if new > og then
											foundSlot.Ind.Text = og + i
										else
											foundSlot.Ind.Text = og - i
										end

										task.wait(div)
									end
									if not stopped then
										foundSlot.Ind.Text = new
									end
									if con then
										con:Disconnect()
									end
								end)()
							end
						else
							--print("2of")
							if not oslots[i].List[i2] then
								oslots[i].List[i2] = {}
							end
							oslots[i].List[i2].Object = script:WaitForChild("Slot"):Clone()
							--print("binding")
							--print(oslots[i].List[i2].Object)
							if not stackable then
								oslots[i].List[i2].Object.Ind.Visible = false
							end
							
							--oslots[i].List[i2].Object:SetAttribute("Foreign", true)
							oslots[i].List[i2].Order = slotData[i].List[i2].Order --or ((#invbox:GetChildren() - 3) + 1)
							bindSlot(oslots[i].List[i2].Object, oslots[i].List[i2], i2)
							oslots[i].List[i2].Object.Name = (tostring(i)..tostring(i2))
							oslots[i].List[i2].Object.Parent = invbox
							oslots[i].List[i2].Object.Ind.Text = slotData[i].List[i2].Amount

							--oslots[i].List[i2].Order = slotData[i].List[i2].Order or ((#invbox:GetChildren() - 3) + 1)
							--oslots[i].List[i2].Object.LayoutOrder = oslots[i].List[i2].Order

							oslots[i].List[i2].Object.Img.Image = itemInfo[i].Image

							oslots[i].List[i2].Object.UIStroke.Color = ringInfo.Color
							for i3, v3 in pairs(ringInfo.Objs) do
								local ob = Instance.new(i3, oslots[i].List[i2].Object.UIStroke)
								for i4, v4 in pairs(v3) do
									ob[i4] = v4
								end
							end
							--print(i)
							--print(slotData[i].List[i2].Order)
							local order = slotData[i].List[i2].Order
							if not order then
								table.insert(fullOrder2, oslots[i].List[i2].Object)
							else
								table.insert(fullOrder2, order, oslots[i].List[i2].Object)
								--print(fullOrder2)
							end		
						end
						oslots[i].List[i2].Name = i
						oslots[i].List[i2].Amount = slotData[i].List[i2].Amount
						--print(oslots)
					end
				else
					-- local i = "Basic Sword" local buttonName = "Basic Sword5786" print(string.sub(buttonName, 1, string.len(i))) --> Basic Sword
					for i2, v in pairs(invbox:GetChildren()) do
						if string.sub(v.Name, 1, string.len(i)) == i then
							v:Destroy()
						end
					end
				end
				--print(oslots)
			end
			--print("final")
			--print(oslots)

			-- clear nonexistants
			for i, v in pairs(oslots) do
				for i2, object in pairs(v.List) do
					if not slotData[i].List[i2] then
						local foundSlot = invbox:FindFirstChild(tostring(i)..tostring(i2))
						--print(foundSlot)
						--print(tostring(i)..tostring(i2))
						if foundSlot and foundSlot:IsA("TextButton") then
							foundSlot:Destroy()
						end
						oslots[i].List[i2] = nil
					end
					--print(oslots)
				end
			end
			reOrderBox(oslots, fullOrder2, true)
		end
	end
end

return menu