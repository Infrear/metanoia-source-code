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
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
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
local vFrame = ui:WaitForChild("Inventory"):WaitForChild("Frame"):WaitForChild("Avatar"):WaitForChild("Background"):WaitForChild("VBackground")

-- otherworldly dependacies
local otherUI = ui:WaitForChild("OtherworldlyUIs")
local storeframe = otherUI:WaitForChild("StoreInventory"):WaitForChild("Frame")
local mixingframe = otherUI:WaitForChild("Mixing"):WaitForChild("Frame")
local storebox = storeframe:WaitForChild("Inventory"):WaitForChild("Inv")
local mFrame = mixingframe:WaitForChild("Inventory")
--

local barChange = Storage:WaitForChild("Events").Standard.HotbarChange
local event = Instance.new("BindableEvent")
local buildInvSend = Storage:WaitForChild("Functions").Remotes.SendBuildInventoryEvents
local getData = Storage:WaitForChild("Functions").Remotes.GetData
local setSlots = Storage:WaitForChild("Functions").Remotes.SetSlots
local craftingIndex = require(Storage.Info.CraftingIndex)
local invDataStorer = require(playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"))
local clientUpdEv = playerGUI:WaitForChild("UIManager"):WaitForChild("Events"):WaitForChild("UpdInv")
local dataUpdEv = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("DataUpdated")
local itemInfo = require(Storage:WaitForChild("Info"):WaitForChild("ItemInfo"))
local buildInfo = require(Storage:WaitForChild("Info"):WaitForChild("BuildInfo"))
local colorSettings = require(Storage:WaitForChild("Info"):WaitForChild("ColorSettings"))
local crafting = require(script:WaitForChild("Crafting"))
local you = require(script:WaitForChild("You"))
local decorLines = {
	mFrame:WaitForChild("Decorline1"), 
	mFrame:WaitForChild("Decorline2"), 
	mFrame:WaitForChild("Decorline3")
}

local DraggableObject = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI")["DraggableObject"])
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
	),
	["Update"] = TweenInfo.new(
		0.05,
		Enum.EasingStyle.Linear,
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
local armors = {}
local durData = {}
local odurData = {}
local equipped = nil

local HOVER_TES = {}
local HOVER_cons = {}
local BAR_HOVER_cons = {}
local BAR_cons = {}
local FAKEBAR_cons = {}
local currentRpop = nil
local currentStationCons = {}
local currentStationTweens = {}
local currentBump = false
local rPopev = Instance.new("BindableEvent", script)
local descChangedEv = Instance.new("BindableEvent", script)

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
	
	["Mixing"] = {
		Key = "Mixing",
		Frames = {
			F1 = {
				Frame = frame:WaitForChild("Inventory"),
				Size = UDim2.new(0.465, 0,0.563, 0),
				Position = UDim2.new(0.34, 0, 0.5, 0)
			},
			F2 = {
				Frame = mixingframe:WaitForChild("Inventory"),
				Size = UDim2.new(0.266, 0,0.547, 0),
				Position = UDim2.new(0.709, 0, 0.502, 0)
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
				return v2, i, i2
			end
		end
	end
end

local function inStoreBox(v)
	if v.Parent == storebox then
		return true
	elseif v.Parent.Parent == mFrame then
		return true
	end
	return false
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

local function reOrderBox(preferedRef, prefOrder, boxly, gridlocked)
	--print("old-")
	--print(slots)
	--print(fullOrder2)
	if not boxly then
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

	else
		if not fullOrder2 then
			fullOrder2 = {}
		end
		if #fullOrder2 <= 0 then
			--print("resetting box order")

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
		for i2, v2 in pairs(v.List) do
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
	--print(fullOrder)
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
	--print(fullOrder2)
	if changed then reOrderBox() end
	--print("new-")
	--print(slots)
end

local function findGridTab(item, order)
	--print(oslots)
	--print(item)
	--print(order)
	for i, v in pairs(oslots[item].List) do
		--print(order)
		--print(v.Order)
		if v.Order == order then
			return i	
		end
	end
end

local function bindBar(bar)
	for i, f in pairs(bar:GetChildren()) do
		if not f:IsA("Frame") or not tonumber(f.Name) then continue end
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

	--if durData[oldSlotTab.Name] and itemInfo[oldSlotTab.Name].Durability then
	--	local durRat = (durData[oldSlotTab.Name].Durability[key]/itemInfo[oldSlotTab.Name].Durability)
	--	button.Dur.Visible = true
	--	button.Dur.Durbar.Size = UDim2.new(button.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
	--	button.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
	--end
end

local function bindSlot(button, oldSlotTab, key, isGridbutton)
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
		desc.Title.Text = oldSlotTab.Name
		desc.Desc.Text = itemInfo[oldSlotTab.Name].Description
		descChangedEv:Fire()
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


		if not isGridbutton then
			HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.HoverColor})
			HOVER_TES[button][2] = TS:Create(button:FindFirstChildOfClass("ImageLabel"), TIS.Hover, {Size = HOVER_SETTINGS.OGSize + HOVER_SETTINGS.SizeAddition,  Position = HOVER_SETTINGS.OGPosition + HOVER_SETTINGS.PositionAddition})
		else
			HOVER_TES[button][1] = TS:Create(button.Parent, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.HoverColor})
			HOVER_TES[button][2] = TS:Create(button.Parent:FindFirstChildOfClass("ImageLabel"), TIS.Hover, {Size = HOVER_SETTINGS.OGSize + HOVER_SETTINGS.SizeAddition,  Position = HOVER_SETTINGS.OGPosition + HOVER_SETTINGS.PositionAddition})
		end
		
		HOVER_TES[button][1]:Play()
		HOVER_TES[button][2]:Play()
	end)

	HOVER_cons[button][2] = button.MouseLeave:Connect(function()
		coroutine.wrap(function()
			local con, stopit = nil, false
			con = descChangedEv.Event:Connect(function()
				stopit = true
				con:Disconnect()
			end)
			task.wait(0.5)
			if not stopit then
				desc.ImageLabel.Image = ""
				desc.Title.Text = ""
				desc.Desc.Text = ""
			end
		end)()
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

		if not isGridbutton then
			HOVER_TES[button][1] = TS:Create(button, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.OGColor})
			HOVER_TES[button][2] = TS:Create(button:FindFirstChildOfClass("ImageLabel"), TIS.Hover, {Size = HOVER_SETTINGS.OGSize,  Position = HOVER_SETTINGS.OGPosition})
		else
			HOVER_TES[button][1] = TS:Create(button.Parent, TIS.Hover, {BackgroundColor3 = HOVER_SETTINGS.OGColor})
			HOVER_TES[button][2] = TS:Create(button.Parent:FindFirstChildOfClass("ImageLabel"), TIS.Hover, {Size = HOVER_SETTINGS.OGSize,  Position = HOVER_SETTINGS.OGPosition})
		end
		
		HOVER_TES[button][1]:Play()
		HOVER_TES[button][2]:Play()
	end)
	
	if not isGridbutton then
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
				setSlots:InvokeServer(slots, bars, armors, equipped)
				--print(Data)
				clientUpdEv:Fire(Data)
			end
		end)
		
		--print("1")
		HOVER_cons[button][4] = button.MouseButton2Click:Connect(function()
			--print("2")
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
	end
	
	
	local but = nil
	local oldImg = (button:FindFirstChildOfClass("ImageLabel") and button:FindFirstChildOfClass("ImageLabel").Visible) or (button.Parent:FindFirstChildOfClass("ImageLabel") and button.Parent:FindFirstChildOfClass("ImageLabel").Visible) 
	local oldText = (button:FindFirstChildOfClass("TextLabel") and button:FindFirstChildOfClass("TextLabel").Visible) or (button.Parent:FindFirstChildOfClass("TextLabel") and button.Parent:FindFirstChildOfClass("TextLabel").Visible) 
	local oldDur = (button:FindFirstChild("Dur") and button:FindFirstChild("Dur").Visible) or (button.Parent:FindFirstChild("Dur") and button.Parent:FindFirstChild("Dur").Visible) 
		
	HOVER_cons[button][5] = button.MouseButton1Down:Connect(function()
		local dragCons = {}
		local curslot = nil
		local tcurslot = nil
		local clo = nil
		if not isGridbutton then
			clo = button:Clone()
		else
			clo = button.Parent:Clone()
		end
		--button.Visible = false
		oldImg = (button:FindFirstChildOfClass("ImageLabel") and button:FindFirstChildOfClass("ImageLabel").Visible) or (button.Parent:FindFirstChildOfClass("ImageLabel") and button.Parent:FindFirstChildOfClass("ImageLabel").Visible) 
		oldText = (button:FindFirstChildOfClass("TextLabel") and button:FindFirstChildOfClass("TextLabel").Visible) or (button.Parent:FindFirstChildOfClass("TextLabel") and button.Parent:FindFirstChildOfClass("TextLabel").Visible) 
		oldDur = (button:FindFirstChild("Dur") and button:FindFirstChild("Dur").Visible) or (button.Parent:FindFirstChild("Dur") and button.Parent:FindFirstChild("Dur").Visible) 

		if button and button.Parent then
			if button:FindFirstChildOfClass("ImageLabel") then
				button:FindFirstChildOfClass("ImageLabel").Visible = false
			elseif button.Parent:FindFirstChildOfClass("ImageLabel") then
				button.Parent:FindFirstChildOfClass("ImageLabel").Visible = false
			end
			if button:FindFirstChildOfClass("TextLabel") then
				button:FindFirstChildOfClass("TextLabel").Visible = false
			elseif button.Parent:FindFirstChildOfClass("TextLabel") then
				button.Parent:FindFirstChildOfClass("TextLabel").Visible = false
			end
			if button:FindFirstChild("Dur") then
				button:FindFirstChild("Dur").Visible = false
			elseif button.Parent:FindFirstChild("Dur") then
				button.Parent:FindFirstChild("Dur").Visible = false
			end
		end
		
		but = DraggableObject.new(clo, button)
		if clo:FindFirstChild("Ind") then
			clo:FindFirstChild("Ind").Visible = false
		end
		clo.UIStroke.Transparency = 1
		clo.BackgroundTransparency = 1
		--print("down")
		local ogAp = button.AbsolutePosition
		local ogSz = button.AbsoluteSize
		--print(ogAp)
		clo.AnchorPoint = Vector2.new(0, 0)
		clo.ZIndex = 16
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

		local putables = fakeBar:GetChildren()
		for i, v in pairs(vFrame:GetChildren()) do
			if v:IsA("Frame") and tonumber(v.Name) then
				if not v:GetAttribute("OldColor") then
					v:SetAttribute("OldColor", v.UIStroke.Color)
				end
				table.insert(putables, v)
			end
		end
		for i, v in pairs(mFrame:GetChildren()) do
			if v:IsA("Frame") and tonumber(v.Name) and tonumber(v.Name) ~= 4 and v:FindFirstChildOfClass("TextButton") and v:FindFirstChildOfClass("ImageLabel") then
				if not v:GetAttribute("OldColor") then
					v:SetAttribute("OldColor", v.UIStroke.Color)
				end
				table.insert(putables, v)
			end
		end
		but:Enable()


		but.DragStarted = function()
			--local mouse = game.Players.LocalPlayer:GetMouse()

			local function updateSlotPosition()
				local slotSize = clo.Size
				local mouseLocation = Vector2.new(mouse.X - slotSize.X.Offset / 2, mouse.Y - slotSize.Y.Offset / 2)
				clo.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y)
			end

			table.insert(dragCons, mouse.Move:Connect(updateSlotPosition))

			--mFrame["1"]:FindFirstChildOfClass("TextButton").MouseEnter:Connect(function()
			--	print("entered0")
			--end)
			
			for i, v in pairs(putables) do
				if v:IsA("Frame") then
					table.insert(dragCons, v:FindFirstChildOfClass("TextButton").MouseEnter:Connect(function()
						--print("entered")
						v.UIStroke.Thickness = 3.5
						v.UIStroke.Transparency = 0
						v.UIStroke.Color = Color3.new(255, 255)
						tcurslot = v
					end))
					table.insert(dragCons, v:FindFirstChildOfClass("TextButton").MouseLeave:Connect(function()
						if v.Parent == fakeBar then
							if bars[tonumber(v.Name)] and (bars[tonumber(v.Name)].Equipped) then
								v.UIStroke.Thickness = 3.25
								v.UIStroke.Transparency = 0
								v.UIStroke.Color = Color3.new(255, 255, 255)
							else
								v.UIStroke.Thickness = 2
								v.UIStroke.Transparency = 0.3
								v.UIStroke.Color = Color3.new(255, 255, 255)
							end
						else 
							v.UIStroke.Thickness = 2.3
							v.UIStroke.Transparency = 0
							v.UIStroke.Color = v:GetAttribute("OldColor")
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
			if not otherUI:WaitForChild("Station").Value then
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
				if curslot and curslot.Parent then
					curslot.Parent.Slide.Visible = false --- BUG WATCH
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

			for i, v in pairs(putables) do
				if v:IsA("Frame") and v.Parent ~= mFrame then
					local button = v:FindFirstChildOfClass("TextButton")
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
			local inStation = otherUI:WaitForChild("Station").Value
			local inEmptyStore = inStation and checkFound2 and #storebox:GetChildren() <= 2
			local ies = false -- moved to the next store
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
				buildInvSend:InvokeServer("Transfer", actionData)
			elseif curslot then
				if curslot.Parent then
					curslot.Parent.Slide.Visible = false 
					curslot.Parent.Slide2.Visible = false
				end
				local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
				local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
				local found = table.find(getGUI, curslot.Parent)
				local tfound = table.find(getGUI, tcurslot)
				local checkFound = table.find(getGUI, box1.Parent)
				--for _, GuiObject in pairs(getGUI) do
				--	print(GuiObject)
				--end
				--local tfound2 = findTab(tcurslot)
				local found2, found2Name, found2Index = findTab(curslot.Parent)
				
				--print(oldSlotTab.Object.Parent)
				if (inStoreBox(curslot.Parent) and inStation) or inStoreBox(button) and not tfound then
					if curslot.Parent.Parent == box1 then -- move back
						--print("backing")
						local pos = (findInDict(fullOrder, curslot.Parent))
						--local key2 = (findInDict(fullOrder2, button))

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
							target = pos,
						}
						local moveOrStack = "Stackback" 
						if ((not found2 or found2.Name ~= oldSlotTab.Name) or not itemInfo[oldSlotTab.Name].Stackable) then
							moveOrStack = "Transferback"
						else
							actionData.count2 = found2Index
						end
						--print("1")
						ies = true
						buildInvSend:InvokeServer(moveOrStack, actionData)
					elseif (inStation and checkFound2) and button.Parent == box1 then -- move in
						local pos = (findInDict(fullOrder2, curslot.Parent))
						--local key2 = (findInDict(fullOrder, button))

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
						local moveOrStack = "Stack" 
						if ((not found2 or found2.Name ~= oldSlotTab.Name) or not itemInfo[oldSlotTab.Name].Stackable) then
							moveOrStack = "Transfer"
						else
							actionData.count2 = found2Index
						end
						ies = true
						buildInvSend:InvokeServer(moveOrStack, actionData)
					elseif (inStation and checkFound2) and inStoreBox(button) then -- reposition
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
						else
							actionData.count2 = found2Index or findGridTab(oldSlotTab.Name, pos)
						end
						--print("1")
						--ies = true
						buildInvSend:InvokeServer(moveOrStack, actionData)
					end
				elseif curslot.Parent.Parent == box1 or (tfound) then
					if curslot.Parent.Parent == box1 and checkFound and ((not found2 or found2.Name ~= oldSlotTab.Name) or (not itemInfo[oldSlotTab.Name].Stackable)) then -- reposition
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
					elseif curslot.Parent.Parent == box1 and checkFound and itemInfo[oldSlotTab.Name].Stackable then -- restack
						if found2.Object ~= oldSlotTab.Object then
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
						else
							-- do nth
						end
					elseif tfound then -- bar stuff
						local wenthrough = false
						if getGUI[tfound].Parent == fakeBar then -- equip in fake toolbar
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
									--print("passed")
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
							if bars[tonumber(tcurslot.Name)].Equipped then
								equipped = bars[tonumber(tcurslot.Name)] or nil
								barChange:Fire("Equip", name)
							end
							tcurslot.Img.Image = button.Img.Image
							mainbar:FindFirstChild(tostring(pos)).Img.Image = button.Img.Image
							wenthrough = tonumber(tcurslot.Name)
						elseif getGUI[tfound].Parent == vFrame then -- equip in armor
							local name = oldSlotTab.Name
							if Storage.Tools.Armor:FindFirstChild(name) and itemInfo[name].WearPosition == tonumber(tcurslot.Name) then
								local item = slots[oldSlotTab.Name]
								local me = findInList(item.List, oldSlotTab.Object)
								local path = {oldSlotTab.Name, "List", me}
								local pos = tonumber(tcurslot.Name)
								armors[tonumber(tcurslot.Name)] = {
									["Name"] = name,
									["Pos"] = pos,
									["Path"] = path,
								}
								--print(armors)
								--equipped = armors[tonumber(tcurslot.Name)].Equipped or nil
								tcurslot.Img.Image = button.Img.Image
								wenthrough = tonumber(tcurslot.Name)
							end
						elseif getGUI[tfound].Parent == mFrame and tonumber(tcurslot.Name) ~= 4 then -- move into mixing pot
							--print(inStation)
							--print("into mixing pot")
							local name = oldSlotTab.Name
							--print(itemInfo[name])
							if itemInfo[name] and itemInfo[name].MixColor and itemInfo[name].MixMaterial and itemInfo[name].MixTransparency then
								local pos = tonumber(tcurslot.Name)
								local myPos = oldSlotTab.Order
								--print(button.Parent.Parent)
								if button.Parent.Parent == mFrame then -- reposition in mixing pot
									--print("reposing m")
									--print(oslots)

									local actionData = {
										build = inStation,
										item = oldSlotTab.Name,
										--count = findInDict(fullOrder, oldSlotTab.Object),
										count = key,
										target = pos
									}
									--print((tcurslot:FindFirstChildOfClass("TextButton")))
									local moveOrStack = "Nothing" 
									if (tcurslot:FindFirstChildOfClass("TextButton").Name == "SlotButton") then
										moveOrStack = "Standardpos" 
									elseif (tcurslot:FindFirstChildOfClass("TextButton").Name == name) then
										if not itemInfo[oldSlotTab.Name].Stackable then
											moveOrStack = "Stackpos"
											actionData.count2 = findGridTab(tcurslot:FindFirstChildOfClass("TextButton").Name, pos)
										end
									else
										--print("elsing")
										moveOrStack = "Switchpos"
										actionData.item2 = tcurslot:FindFirstChildOfClass("TextButton").Name
										actionData.count2 = findGridTab(tcurslot:FindFirstChildOfClass("TextButton").Name, pos)
										--print(actionData.count)
										--print(actionData.count2)
									end

									if moveOrStack ~= "Nothing" then 
										ies = true and moveOrStack ~= "Switchpos"
										button.Visible = false
										buildInvSend:InvokeServer(moveOrStack, actionData)
									end
								else -- move into mixing pot
									--print("cre")
									--print(oslots)
									table.remove(fullOrder, table.find(fullOrder, button))

									table.insert(fullOrder2, pos, button)

									local actionData = {
										build = inStation,
										item = oldSlotTab.Name,
										--count = findInDict(fullOrder, oldSlotTab.Object),
										count = key,
										target = pos
									}
									local moveOrStack = "Transfer" 
									if (tcurslot:FindFirstChildOfClass("TextButton").Name == "SlotButton") then
										moveOrStack = "Transfer" 
									elseif (tcurslot:FindFirstChildOfClass("TextButton").Name == name) then
										if not itemInfo[oldSlotTab.Name].Stackable then
											moveOrStack = "Stack"
											actionData.count2 = findGridTab(tcurslot:FindFirstChildOfClass("TextButton").Name, pos)
										end
									else
										moveOrStack = "Switch"
										actionData.item2 = tcurslot:FindFirstChildOfClass("TextButton").Name
										actionData.count2 = findGridTab(tcurslot:FindFirstChildOfClass("TextButton").Name, pos)
										actionData.target2 = myPos
									end
									--tcurslot.Img.Image = button.Img.Image
									--bindSlot(tcurslot:FindFirstChildOfClass("TextButton"))
									ies = true
									button.Visible = false
									--print(slots)
									buildInvSend:InvokeServer(moveOrStack, actionData)
									--print("caft")
									--print(oslots)
								end
							end
						end
						if wenthrough then
							if FAKEBAR_cons[getGUI[tfound]] then
								FAKEBAR_cons[getGUI[tfound]]:Disconnect()
							end
							FAKEBAR_cons[getGUI[tfound]] = getGUI[tfound]:FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
								FAKEBAR_cons[getGUI[tfound]]:Disconnect()
								if getGUI[tfound].Parent == fakeBar then
									mainbar:FindFirstChild(wenthrough).Img.Image = ""
									if bars[wenthrough].Equipped then
										bars[wenthrough].Equipped = false
										equipped = nil
									end
									bars[wenthrough] = nil
								elseif getGUI[tfound].Parent == vFrame then
									armors[wenthrough] = nil
								end
								getGUI[tfound].Img.Image = ""
								setSlots:InvokeServer(slots, bars, armors, equipped)
							end)
						end
						--print(bars)
					end
					--print(fullOrder)
					reOrderBox()
					--print(fullOrder)
					setSlots:InvokeServer(slots, bars, armors, equipped)
					local Data = getData:InvokeServer("Inventory")
					--print(Data)
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
			
			-- remove pesky slides
			for i, v in pairs(box1:GetChildren()) do
				if v:IsA("TextButton") then
					if v:FindFirstChild("Slide")  then
						v:FindFirstChild("Slide").Visible = false
					end
					if v:FindFirstChild("Slide2")  then
						v:FindFirstChild("Slide2").Visible = false
					end
				end
			end
			for i, v in pairs(storebox:GetChildren()) do
				if v:IsA("TextButton") then
					if v:FindFirstChild("Slide2")  then
						v:FindFirstChild("Slide2").Visible = false
					end
					if v:FindFirstChild("Slide2")  then
						v:FindFirstChild("Slide2").Visible = false
					end
				end
			end
			
			--print(button)
			--print(ies)
			if button and button.Parent then
				if button:FindFirstChildOfClass("ImageLabel") then
					button:FindFirstChildOfClass("ImageLabel").Visible = oldImg
				elseif button.Parent:FindFirstChildOfClass("ImageLabel") then
					button.Parent:FindFirstChildOfClass("ImageLabel").Visible = oldImg
				end
				if button:FindFirstChildOfClass("TextLabel") then
					button:FindFirstChildOfClass("TextLabel").Visible = oldText
				elseif button.Parent:FindFirstChildOfClass("TextLabel") then
					button.Parent:FindFirstChildOfClass("TextLabel").Visible = oldImg
				end
				if button:FindFirstChild("Dur") then
					button:FindFirstChild("Dur").Visible = oldDur
				elseif button.Parent:FindFirstChild("Dur") then
					button.Parent:FindFirstChild("Dur").Visible = oldDur
				end
			end
			if not isGridbutton then
				button.Visible = true and not ies
			else
				button.Visible = true
			end
			if ies then
				if HOVER_cons[button] then
					for i, v in pairs(HOVER_cons[button]) do
						v:Disconnect()
					end
				end
				if button then
					if isGridbutton then
						button.Name = "SlotButton"
						button.Parent.Ind.Visible = false
						button.Parent:FindFirstChildOfClass("ImageLabel").Image = ""
						button.Parent.UIStroke.UIGradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromHex("#dedeff")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("#454455"))
						}
					else
						button:Destroy()
					end
				end
			end
		end

		but.DragEnded = function()
			undid()
		end
		--clo.MouseButton1Up:Connect(function()
		--	undid()
		--end)
		--clo.MouseLeave:Connect(function()
		--	undid()
		--end)
	end)
	--HOVER_cons[button][5] = button.MouseButton1Up:Connect(function()
	--end)
	--print(button)
	--print(oldSlotTab)
	--print(oldSlotTab.Name)
	--print("durdatas-")
	--print(durData)
	--print(odurData)
	--print(durData[oldSlotTab.Name])
	--print(itemInfo[oldSlotTab.Name])
	--print(button.Parent)
	--print(box1)
	--print(storebox)
	if button.Parent == box1 then
		--print("box")
		if durData[oldSlotTab.Name] and durData[oldSlotTab.Name].Durability and itemInfo[oldSlotTab.Name].Durability then
			local durRat = (durData[oldSlotTab.Name].Durability[key]/itemInfo[oldSlotTab.Name].Durability)
			button.Dur.Visible = true
			button.Dur.Durbar.Size = UDim2.new(button.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
			button.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
		end
	elseif inStoreBox(button) then
		--print("storebox")
		if odurData[oldSlotTab.Name] and odurData[oldSlotTab.Name].Durability and itemInfo[oldSlotTab.Name].Durability then
			local durRat = (odurData[oldSlotTab.Name].Durability[key]/itemInfo[oldSlotTab.Name].Durability)
			button.Dur.Visible = true
			button.Dur.Durbar.Size = UDim2.new(button.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
			button.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
		end
	end
	button.Visible = true
end

local function bindToolbar()
	for i, v in pairs(mainbar:GetChildren()) do
		if v:IsA("Frame") and tonumber(v.Name) then
			local button = v:WaitForChild("Button")
			local function bindbartool()
				--if not bars[tonumber(v.Name)] then return end
				--print(v)
				local oldT = v.UIStroke.Transparency
				for i, v2 in pairs(mainbar:GetChildren()) do
					if not v2:IsA("Frame") or not tonumber(v2.Name) then continue end
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
				setSlots:InvokeServer(slots, bars, armors, equipped)
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
	otherUI:WaitForChild("Station").Changed:Connect(function(newVal)
		if newVal ~= nil and buildInfo[newVal.Name] and buildInfo[newVal.Name].NeedsInventory then
			local gottenData = getData:InvokeServer("Inventory", newVal)
			--print(newVal.Name)
			--print(gottenData)
			menu.updateStoreInventory(storebox, buildInfo[newVal.Name].InventoryType, gottenData and gottenData.Data)
			
			currentBump = false
			if currentStationCons[1] then
				currentStationCons[1]:Disconnect()
			end
			
			if buildInfo[newVal.Name] and buildInfo[newVal.Name].ProgressEffect then
				currentStationCons[2] = newVal:GetAttributeChangedSignal("Progress"):Connect(function()
					local prog = newVal:GetAttribute("Progress")
					
					for i, v in pairs(currentStationTweens) do
						v:Cancel()
					end
					if prog ~= 0 then
						for i, v in pairs(decorLines) do
							local correFrame = mFrame:FindFirstChild(tostring(string.sub(v.Name, #v.Name, #v.Name)))
							local correButton = correFrame and correFrame:FindFirstChildOfClass("TextButton")
							if correFrame and correButton and correButton.Name ~= "SlotButton" then
								local TE = TS:Create(v.Decorbar, TIS.Update, {Size = UDim2.new(v.Decorbar.Size.X.Scale, 0, (prog/100), 0), BackgroundColor3 = (itemInfo[correButton.Name] and itemInfo[correButton.Name].MixColor) or Color3.fromRGB(81, 26, 176)})
								TE:Play()
								table.insert(currentStationTweens, TE)
							else
								--v.Decorbar.BackgroundColor3 = Color3.fromRGB(81, 26, 176)
								v.Decorbar.Size = UDim2.new(v.Decorbar.Size.X.Scale, 0, 0.05, 0)
							end
						end
					else
						for i, v in pairs(decorLines) do
							--local TE = TS:Create(v.Decorbar, TIS.Update, {Size = UDim2.new(v.Decorbar.Size.X.Scale, 0, 0.05, 0)})
							--TE:Play()
							--table.insert(currentStationTweens, TE)
							--v.Decorbar.BackgroundColor3 = Color3.fromRGB(81, 26, 176)
							v.Decorbar.Size = UDim2.new(v.Decorbar.Size.X.Scale, 0, 0.05, 0)
						end
					end
				end)
			end
				
			local updUiEv = newVal:WaitForChild("UpdateUI", 5)
			if updUiEv then
				currentStationCons[1] = updUiEv.OnClientEvent:Connect(function(ogPlr, way, Data)
					--print(Data)
					if ogPlr ~= plr or not currentBump then
						--currentBump = true
						--print("updating")
						menu.updateStoreInventory(storebox, way or buildInfo[newVal.Name].InventoryType or "Basic", Data)
					end
				end)
			end
		else
			if currentStationCons then
				for i, currentCon in pairs(currentStationCons) do
					currentCon:Disconnect()
				end
			end
		end
	end)
end

-- Global Functions
function menu.updateInventory(already)
	--print(slots)
	local Data = getData:InvokeServer("Inventory")
	--print("inventory data -")
	--print(Data)
	clientUpdEv:Fire(Data)

	crafting.updCorrectUI(Data)

	local invData = Data.Data[1]
	local slotData = Data.Data[2]
	local barData = Data.Data[3]
	local armorData = Data.Data[4]

	durData = invData
	--print(Data.Data)
	--print(armorData)

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

					slotTab.Order = ((#box1:GetChildren() - 3) + 1)
					slotTab.Object.LayoutOrder = slotTab.Order
					if not stackable then
						slotTab.Object.Ind.Visible = false
					end

					slotTab.Object.Name = i.."1"
					slotTab.Object.Visible = false
					slotTab.Object.Parent = box1
					bindSlot(slotTab.Object, slotTab, 1)
					slotTab.Object.Ind.Text = amt
					slotTab.Object.Img.Image = itemInfo[i].Image

					slotTab.Object.UIStroke.Color = ringInfo.BaseColor
					for i3, v3 in pairs(ringInfo.Objs) do
						local ob = Instance.new(i3, slotTab.Object.UIStroke)
						for i4, v4 in pairs(v3) do
							ob[i4] = v4
						end
					end

					table.insert(fullOrder, slotTab.Object)	
				end

				if stackable then
					newslot(v.Amount)
				else
					for i = 1, v.Amount do
						newslot(1)
					end
				end

				--slots[i].Object.
			else
				local slotTab = slots[i].List[1]
				slotTab.Object.Ind.Text = v.Amount
			end

			bars = barData
			for i, v in pairs(barData) do
				fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				
				FAKEBAR_cons[fakeBar:FindFirstChild(tostring(v.Pos))] = fakeBar:FindFirstChild(tostring(v.Pos)):FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
					FAKEBAR_cons[fakeBar:FindFirstChild(tostring(v.Pos))]:Disconnect()
					
					bars[v.Pos] = nil
					fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
					mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
					if v.Equipped then
						v.Equipped = false
						equipped = nil
					end
					setSlots:InvokeServer(slots, bars, armors, equipped)
				end)
				
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
			
			armors = armorData 
			for i, v in pairs(armorData) do
				vFrame:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				
				FAKEBAR_cons[vFrame:FindFirstChild(tostring(v.Pos))] = fakeBar:FindFirstChild(tostring(v.Pos)):FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
					FAKEBAR_cons[vFrame:FindFirstChild(tostring(v.Pos))]:Disconnect()

					armorData[v.Pos] = nil
					vFrame:FindFirstChild(tostring(v.Pos)).Img.Image = ""
					setSlots:InvokeServer(slots, bars, armors, equipped)
				end)
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
						
						-- updating durability
						if durData[i] and durData[i].Durability and itemInfo[i].Durability then
							local durRat = (durData[i].Durability[i2]/itemInfo[i].Durability)
							foundSlot.Dur.Visible = true
							foundSlot.Dur.Durbar.Size = UDim2.new(foundSlot.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
							foundSlot.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
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
						slots[i].List[i2].Object.Name = (tostring(i)..tostring(i2))
						slots[i].List[i2].Name = i
						slots[i].List[i2].Object.Visible = false
						slots[i].List[i2].Object.Parent = box1
						bindSlot(slots[i].List[i2].Object, slots[i].List[i2], i2)
						slots[i].List[i2].Object.Ind.Text = slotData[i].List[i2].Amount

						--slots[i].List[i2].Order = slotData[i].List[i2].Order or ((#box1:GetChildren() - 3) + 1)
						--slots[i].List[i2].Object.LayoutOrder = slots[i].List[i2].Order

						slots[i].List[i2].Object.Img.Image = itemInfo[i].Image

						slots[i].List[i2].Object.UIStroke.Color = ringInfo.BaseColor
						if ringInfo.Objs then
							for i3, v3 in pairs(ringInfo.Objs) do
								local ob = Instance.new(i3, slots[i].List[i2].Object.UIStroke)
								for i4, v4 in pairs(v3) do
									ob[i4] = v4
								end
							end
						end
						local order = slotData[i].List[i2].Order
						if not order then
							table.insert(fullOrder, slots[i].List[i2].Object)
						else
							table.insert(fullOrder, order, slots[i].List[i2].Object)
							--print(fullOrder)
						end	
						--print(i)
						--print(slotData[i].List[i2].Order)
					end	
					if slots[i].List[i2] then
						slots[i].List[i2].Name = i
						slots[i].List[i2].Amount = slotData[i].List[i2].Amount
						slots[i].List[i2].Object = slots[i].List[i2].Object or foundSlot
					end
					--print(slots)
				end
			else
				-- local i = "Basic Sword" local buttonName = "Basic Sword5786" print(string.sub(buttonName, 1, string.len(i))) --> Basic Sword
				for i2, v in pairs(box1:GetChildren()) do
					if string.sub(v.Name, 1, string.len(i)) == i then
						if HOVER_cons[v] then
							for i, v in pairs(HOVER_cons[v]) do
								v:Disconnect()
							end
						end
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
		local validSlots = {}

		-- Precompute valid slot names and their corresponding indices
		--print(slots)
		for i, v in pairs(slots) do
			for i2, object in pairs(v.List) do
				if slotData[i] and not slotData[i].List[i2] then
					local foundSlot = box1:FindFirstChild(tostring(i)..tostring(i2))
					--print(foundSlot)
					--print(tostring(i)..tostring(i2))
					if HOVER_cons[foundSlot] then
						for i, v in pairs(HOVER_cons[foundSlot]) do
							v:Disconnect()
						end
					end

					-- Destroy the slot and remove it from `slots`
					foundSlot:Destroy()
					if foundSlot and foundSlot:IsA("TextButton") then
						foundSlot:Destroy()
					end
					slots[i].List[i2] = nil
				end
				table.insert(validSlots, tostring(i) .. tostring(i2))
			end
		end

		-- Iterate over the children of box1
		for _, foundSlot in pairs(box1:GetChildren()) do
			if foundSlot:IsA("TextButton") then
				local validIndex = table.find(validSlots, foundSlot.Name)
				if not validIndex then
					-- Disconnect hover connections
					if HOVER_cons[foundSlot] then
						for _, connection in pairs(HOVER_cons[foundSlot]) do
							connection:Disconnect()
						end
					end

					-- Destroy the slot and remove it from `slots`
					foundSlot:Destroy()
				end
			end
		end


		-- equiptoolbarshi
		bars = barData
		--print(barData)
		for i, v in pairs(barData) do
			if v.Path then
				fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
				
				FAKEBAR_cons[fakeBar:FindFirstChild(tostring(v.Pos))] = fakeBar:FindFirstChild(tostring(v.Pos)):FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
					FAKEBAR_cons[fakeBar:FindFirstChild(tostring(v.Pos))]:Disconnect()

					bars[v.Pos] = nil
					fakeBar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
					mainbar:FindFirstChild(tostring(v.Pos)).Img.Image = ""
					if v.Equipped then
						v.Equipped = false
						equipped = nil
					end
					setSlots:InvokeServer(slots, bars, armors, equipped)
				end)
				
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
		

		armors = armorData 
		for i, v in pairs(armorData) do
			vFrame:FindFirstChild(tostring(v.Pos)).Img.Image = itemInfo[v.Name].Image
			
			FAKEBAR_cons[vFrame:FindFirstChild(tostring(v.Pos))] = fakeBar:FindFirstChild(tostring(v.Pos)):FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
				FAKEBAR_cons[vFrame:FindFirstChild(tostring(v.Pos))]:Disconnect()

				armors[v.Pos] = nil
				vFrame:FindFirstChild(tostring(v.Pos)).Img.Image = ""
				setSlots:InvokeServer(slots, bars, armors, equipped)
			end)
		end
		
		reOrderBox()
		--print(slots)
		--slots[i].Object.
	end
	--print("last")
	--print(slots)
	
	--you.updArmor(armorData)
	setSlots:InvokeServer(slots, bars, armors, equipped)
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
	--TES = {}
	
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
	--print(oldSection)
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
	--TES = {}
	
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
		--print("ok")
		for i, v in pairs(SECTIONS) do
			if not v.Frames.F2 then continue end
			if v ~= oldSection then
				--print(oldSection.Key)
				v.Frames.F2.Frame.Visible = --[[(oldSection and (oldSection.Key ~= "Inventory")) and]] false 
			end
			TES[v.Frames.F2.Frame] = TS:Create(v.Frames.F2.Frame, TIS.Close, {Position = F1.Position, Size = v.Frames.F2.Size - UDim2.new(0.35, 0, 0.35, 0)})
		end
	else
		for i, v in pairs(SECTIONS) do
			--print(v)
			if not v.Frames.F2 then continue end
			if v ~= oldSection then
				--print(v)
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
		--print(v.Instance)
		if v.PlaybackState ~= Enum.PlaybackState.Playing then
			v:Play()
		end
	end
end

function menu.setup()
	for i, v in pairs(mainbar:GetChildren()) do
		if v:IsA("Frame") and tonumber(v.Name) and v:FindFirstChildOfClass("UIStroke") then
			v:FindFirstChildOfClass("UIStroke").Transparency = 0.3
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

	-- clear boxes
	for i, v in pairs(box1:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	for i, v in pairs(storebox:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	crafting.setup()

	menu.updateInventory(true)
	you.setup()
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
	if not data then return end
	--for i, v in pairs(invbox:GetChildren()) do
	--	if v:IsA("TextButton") then
	--		v:Destroy()
	--	end
	--end

	--print("store data -")
	--print(data)
	local invData = data[1]
	local slotData = data[2]
	--local barData = data[3]
	--local armorData = data[4]
	--print(slotData)

	fullOrder2 = {}
	oslots = slotData
	odurData = invData
	--print(data)
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

			if way == "Basic" then
				if #v.List > 0 or v.List[1].Amount > 1 then
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

							-- updating durability
							if odurData[i] and odurData[i].Durability and itemInfo[i].Durability then
								local durRat = (odurData[i].Durability[i2]/itemInfo[i].Durability)
								foundSlot.Dur.Visible = true
								foundSlot.Dur.Durbar.Size = UDim2.new(foundSlot.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
								foundSlot.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
							end	
						else
							--print(tostring(i)..tostring(i2))
							--print(invbox:GetChildren())
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
							oslots[i].List[i2].Order = slotData[i].List[i2].Order or ((#storebox:GetChildren() - 3) + 1)
							oslots[i].List[i2].Object.Name = (tostring(i)..tostring(i2))
							oslots[i].List[i2].Name = i
							oslots[i].List[i2].Object.Visible = false
							oslots[i].List[i2].Object.Parent = storebox
							bindSlot(oslots[i].List[i2].Object, oslots[i].List[i2], i2)
							oslots[i].List[i2].Object.Ind.Text = slotData[i].List[i2].Amount

							--oslots[i].List[i2].Order = slotData[i].List[i2].Order or ((#invbox:GetChildren() - 3) + 1)
							--oslots[i].List[i2].Object.LayoutOrder = oslots[i].List[i2].Order

							oslots[i].List[i2].Object.Img.Image = itemInfo[i].Image

							oslots[i].List[i2].Object.UIStroke.Color = ringInfo.BaseColor
							for i3, v3 in pairs(ringInfo.Objs) do
								local ob = Instance.new(i3, oslots[i].List[i2].Object.UIStroke)
								for i4, v4 in pairs(v3) do
									ob[i4] = v4
								end
							end
							--print(i)
							--print(slotData[i].List[i2].Order)
						end
						oslots[i].List[i2].Name = i
						oslots[i].List[i2].Amount = slotData[i].List[i2].Amount
						oslots[i].List[i2].Object = oslots[i].List[i2].Object or foundSlot
						local order = slotData[i].List[i2].Order
						if not order then
							table.insert(fullOrder2, oslots[i].List[i2].Object)
						else
							table.insert(fullOrder2, order, oslots[i].List[i2].Object)
						end	
						--print(fullOrder2)	
						--print(oslots)
					end
				else
					-- local i = "Basic Sword" local buttonName = "Basic Sword5786" print(string.sub(buttonName, 1, string.len(i))) --> Basic Sword
					for i2, v in pairs(storebox:GetChildren()) do
						if string.sub(v.Name, 1, string.len(i)) == i then
							if HOVER_cons[v] then
								for i, v in pairs(HOVER_cons[v]) do
									v:Disconnect()
								end
							end
							v:Destroy()
						end
					end
				end
			elseif way == "Gridded" then
				--print(slotData)
				if #v.List > 0 or v.List[1].Amount > 1 then
					for i2, object in pairs(v.List) do
						--print(object)
						local foundSlot = mFrame[tostring(object.Order)]:FindFirstChild(tostring(i))
						--print(foundSlot)
						--print(slotData[i].List[i2].Order)
						--print(tostring(i)..tostring(i2))
						if foundSlot and foundSlot:IsA("TextButton") then
							--print("1of")
							local og = tonumber(foundSlot.Parent.Ind.Text)
							local new = tonumber(slotData[i].List[i2].Amount)
							--print(og, new)
							if og == new then
								foundSlot.Parent.Ind.Text = new
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
											foundSlot.Parent.Ind.Text = og + i
										else
											foundSlot.Parent.Ind.Text = og - i
										end

										task.wait(div)
									end
									if not stopped then
										foundSlot.Parent.Ind.Text = new
									end
									if con then
										con:Disconnect()
									end
								end)()
							end

							-- updating durability
							if odurData[i] and odurData[i].Durability and itemInfo[i].Durability then
								local durRat = (odurData[i].Durability[i2]/itemInfo[i].Durability)
								foundSlot.Dur.Visible = true
								foundSlot.Dur.Durbar.Size = UDim2.new(foundSlot.Dur.Durbar.Size.X.Scale, 0, (1 * durRat), 0)
								foundSlot.Dur.Durbar.BackgroundColor3 = Color3.new(0.85):Lerp(Color3.new(0, 1, 0.3), durRat) 
							end	
						else
							--print(tostring(i)..tostring(i2))
							--print(invbox:GetChildren())
							--print("2of")
							if not oslots[i].List[i2] then
								oslots[i].List[i2] = {}
							end
							--print(oslots)
							if mFrame[tostring(slotData[i].List[i2].Order)]:FindFirstChildOfClass("TextButton") then
								--print("exists")
								if HOVER_cons[mFrame[tostring(slotData[i].List[i2].Order)]:FindFirstChildOfClass("TextButton")] then
									--print("there are cons")
									for i, v in pairs(HOVER_cons[mFrame[tostring(slotData[i].List[i2].Order)]:FindFirstChildOfClass("TextButton")]) do
										v:Disconnect()
									end
								end
							end
							oslots[i].List[i2].Object = mFrame[tostring(slotData[i].List[i2].Order)]:FindFirstChildOfClass("TextButton")
							--print(oslots)
							--print("binding")
							--print(oslots[i].List[i2].Object)
							if not stackable then
								oslots[i].List[i2].Object.Ind.Visible = false
							else
								oslots[i].List[i2].Object.Parent.Ind.Visible = true
							end

							--oslots[i].List[i2].Object:SetAttribute("Foreign", true)
							--print(slotData[i].List[i2].Order)
							oslots[i].List[i2].Order = slotData[i].List[i2].Order
							--print(oslots[i].List[i2].Order)
							--print(oslots)
							oslots[i].List[i2].Object.Name = tostring(i)
							oslots[i].List[i2].Name = i
							bindSlot(oslots[i].List[i2].Object, oslots[i].List[i2], i2, true)
							oslots[i].List[i2].Object.Parent.Ind.Text = slotData[i].List[i2].Amount
							--print(oslots[i].List[i2].Object)

							--oslots[i].List[i2].Order = slotData[i].List[i2].Order or ((#invbox:GetChildren() - 3) + 1)
							--oslots[i].List[i2].Object.LayoutOrder = oslots[i].List[i2].Order

							oslots[i].List[i2].Object.Parent.Img.Image = itemInfo[i].Image

							oslots[i].List[i2].Object.Parent.UIStroke.Color = ringInfo.BaseColor

							--if ringInfo.Objs["UIStroke"]
							--v:SetAttribute("OldColor", ringInfo.BaseColor)

							oslots[i].List[i2].Object.Parent.UIStroke.UIGradient.Color = ColorSequence.new{
								ColorSequenceKeypoint.new(0, Color3.fromHex("#dedeff")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("#454455"))
							}
							for i3, v3 in pairs(ringInfo.Objs) do
								local ob = oslots[i].List[i2].Object.Parent.UIStroke:FindFirstChildOfClass(i3) or Instance.new(i3, oslots[i].List[i2].Object.Parent.UIStroke)
								for i4, v4 in pairs(v3) do
									ob[i4] = v4
								end
							end
						end
						oslots[i].List[i2].Name = i
						oslots[i].List[i2].Amount = slotData[i].List[i2].Amount
						oslots[i].List[i2].Object = oslots[i].List[i2].Object or foundSlot
						local order = slotData[i].List[i2].Order
						if not order then
							table.insert(fullOrder2, oslots[i].List[i2].Object)
						else
							table.insert(fullOrder2, order, oslots[i].List[i2].Object)
						end	
						--print(oslots)
					end
				else
					--local i = "Basic Sword" local buttonName = "Basic Sword5786" print(string.sub(buttonName, 1, string.len(i))) --> Basic Sword

					local bs = {
						mFrame["1"]:FindFirstChildOfClass("TextButton"), 
						mFrame["2"]:FindFirstChildOfClass("TextButton"), 
						mFrame["3"]:FindFirstChildOfClass("TextButton"),
						mFrame["4"]:FindFirstChildOfClass("TextButton")
					}
					for i2, v in pairs(bs) do
						if string.sub(v.Name, 1, string.len(i)) == i then
							if HOVER_cons[v] then
								for i, v in pairs(HOVER_cons[v]) do
									v:Disconnect()
								end
							end
							v.Name = "SlotButton"
							v.Parent.Ind.Visible = false
							v.Parent:FindFirstChildOfClass("ImageLabel").Image = ""
							v.Parent.UIStroke.UIGradient.Color = ColorSequence.new{
								ColorSequenceKeypoint.new(0, Color3.fromHex("#dedeff")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("#454455"))
							}
						end
					end
				end
			end
			--print("final")
			--print(oslots)

		end

		-- clear nonexistants
		local validSlots = {}
		
		if way ~= "Gridded" then
			-- Precompute valid slot names and their corresponding indices
			for i, v in pairs(oslots) do
				for i2, object in pairs(v.List) do
					table.insert(validSlots, tostring(i) .. tostring(i2))
					if not slotData[i].List[i2] then
						local foundSlot = storebox:FindFirstChild(tostring(i)..tostring(i2))
						--print(foundSlot)
						--print(tostring(i)..tostring(i2))
						if HOVER_cons[v] then
							for i, v in pairs(HOVER_cons[v]) do
								v:Disconnect()
							end
						end


						if foundSlot and foundSlot:IsA("TextButton") then
							foundSlot:Destroy()
						end
						oslots[i].List[i2] = nil
					end
					--print(oslots)
				end
			end
			
			-- Iterate over the children of storebox
			for _, foundSlot in pairs(storebox:GetChildren()) do
				if foundSlot:IsA("TextButton") then
					local validIndex = table.find(validSlots, foundSlot.Name)
					if not validIndex then
						-- Disconnect hover connections
						if HOVER_cons[foundSlot] then
							for _, connection in pairs(HOVER_cons[foundSlot]) do
								connection:Disconnect()
							end
						end

						-- Destroy the slot and remove it from `slots`
						foundSlot:Destroy()
					end
				end
			end
		else
			for i, v in pairs(oslots) do
				for i2, object in pairs(v.List) do
					if not slotData[i].List[i2] then
						local foundSlot = mFrame[object.Order]:FindFirstChild(tostring(i))
						--print(foundSlot)
						--print(tostring(i)..tostring(i2))
						if foundSlot and foundSlot:IsA("TextButton") then
							if HOVER_cons[mFrame[object.Order]] then
								for i, v in pairs(HOVER_cons[mFrame[object.Order]]) do
									v:Disconnect()
								end
							end
							v.Name = "SlotButton"
							v.Parent.Ind.Visible = false
							v.Parent:FindFirstChildOfClass("ImageLabel").Image = ""
							v.Parent.UIStroke.UIGradient.Color = ColorSequence.new{
								ColorSequenceKeypoint.new(0, Color3.fromHex("#dedeff")),
								ColorSequenceKeypoint.new(1, Color3.fromHex("#454455"))
							}
						end
						oslots[i].List[i2] = nil
					end
					--print(oslots)
				end
			end
			
			for i, v in pairs(oslots) do
				for i2, object in pairs(v.List) do
					table.insert(validSlots, tostring(i)) -- Note: Only `i` is used as the key here based on your original code
				end
			end

			-- Iterate through mFrame to find matching slots
			for _, frame in pairs(mFrame:GetChildren()) do
				for _, foundSlot in pairs(frame:GetChildren()) do
					local validIndex = table.find(validSlots, foundSlot.Name)
					if foundSlot:IsA("TextButton") and  not validIndex then
						-- Disconnect hover connections if present
						if HOVER_cons[frame] then
							for _, connection in pairs(frame) do
								connection:Disconnect()
							end
						end

						-- Update found slot properties
						foundSlot.Name = "SlotButton"
						foundSlot.Parent.Ind.Visible = false
						foundSlot.Parent:FindFirstChildOfClass("ImageLabel").Image = ""
						foundSlot.Parent.UIStroke.UIGradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromHex("#dedeff")),
							ColorSequenceKeypoint.new(1, Color3.fromHex("#454455"))
						}
					end
				end
			end
		end
		if way ~= "Gridded" then
			reOrderBox(oslots, fullOrder2, true, way == "Gridded")
		end
	end
end

return menu