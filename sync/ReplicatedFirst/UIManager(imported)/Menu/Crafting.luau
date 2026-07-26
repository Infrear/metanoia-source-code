-- Constants
local defaultBarLength = 0.05

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

local POP_SIZES = {
	UDim2.new(1, 0, 0.486, 0),
	UDim2.new(1, 0, 0.734, 0),
	UDim2.new(1, 0, 1.02, 0)
}

--local HOVER_SETTINGSb = {
--	RotateForwardSpeed = 0.55,
--	RotateBackSpeed = 1.5,
--	OGPosition = UDim.new(0, 1),
--	PositionAddition = UDim2.new(0, 0, 0.085, 0),
--}

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)
local itemInfo = require(Storage.Info.ItemInfo)
local craftingIndex = require(Storage.Info.CraftingIndex)

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")

local invDataStorer = require(playerGUI:WaitForChild("UIManager"):WaitForChild("InvData"))
local clientUpdEv = playerGUI:WaitForChild("UIManager"):WaitForChild("Events"):WaitForChild("UpdInv")
local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("Inventory"):WaitForChild("Frame")
local box1 = frame:WaitForChild("Inventory"):WaitForChild("Inv")
local box2 = frame:WaitForChild("Crafting"):WaitForChild("Inv")
local bar = frame:WaitForChild("Crafting"):WaitForChild("Craftline"):WaitForChild("Craftbar")
local canCraftref = box2:WaitForChild("CanCraft"):Clone()
local cantCraftref = box2:WaitForChild("CantCraft"):Clone()
local startCraftEv = Storage.Events.Remotes:WaitForChild("StartCraft")
local otherUI = playerGUI:WaitForChild("SurvivorUI"):WaitForChild("OtherworldlyUIs")
local cPop = ui:WaitForChild("CraftPop")
local cPopev = Instance.new("BindableEvent", script)
local craftRunning = false

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	),
	["Hover"] = TweenInfo.new(
		HOVER_SETTINGS.RotateForwardSpeed,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
}
local BarTween = nil
local Crafts = {}
local HOVER_TES = {}
local HOVER_cons = {}
local cPopCon = nil
local currentItem = nil

-- Initialization
local crafting = {}
crafting.loadedCraft = nil

-- Local Functions
local function canCraft(item, materials, gotData)
	if not gotData then
		gotData = invDataStorer.getData()
	end

	local invData = nil
	local slotData = nil
	local barData = nil

	--print(gotData)

	if gotData then
		invData = gotData.Data[1]
		slotData = gotData.Data[2]
		barData = gotData.Data[3]
	end

	for i, v in pairs(materials) do
		--print(v)
		if not gotData or not invData[v.Name] or invData[v.Name].Amount < v.AmountNeeded then
			return false
		end
	end

	return true
end

local function closeUp(button)
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
end

local function bindHover(button)
	HOVER_cons[button] = {}

	HOVER_cons[button][1] = button.MouseEnter:Connect(function()
		--print(Crafts)
		--print(canCraft(button, Crafts[button].Materials))
		local gotData = invDataStorer.getData()

		if canCraft(button, Crafts[button].Materials, gotData) then
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
		end


		local amt = #Crafts[button].Materials
		for i = (amt + 1), 3 do
			cPop.Box:FindFirstChild(tostring(i)).Visible = false
		end 

		local invData = nil
		local slotData = nil
		local barData = nil

		--print(gotData)

		if gotData then
			invData = gotData.Data[1]
			slotData = gotData.Data[2]
			barData = gotData.Data[3]
		end

		if gotData then
			local mouseLocation = UIS:GetMouseLocation()
			cPop.Bg.Size = POP_SIZES[#Crafts[button].Materials]
			cPop.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y - cPop.Bg.AbsoluteSize.Y)

			local count = 1

			cPop.Title.Text = button.Name

			--print(Crafts[button].Materials)
			for i, v in pairs(Crafts[button].Materials) do
				local slot = cPop.Box:FindFirstChild(tostring(count))
				if slot then
					slot.Img.Image = itemInfo[v.Name].Image
					slot.Amt.Text = tostring((invData[v.Name] and invData[v.Name].Amount) or 0).."/"..tostring(v.AmountNeeded)	

					if not gotData or not invData[v.Name] or invData[v.Name].Amount < v.AmountNeeded then
						slot.Amt.TextColor3 = Color3.new(1)
					else
						slot.Amt.TextColor3 = Color3.new(1, 1, 1)
					end
					slot.Visible = true
				end
				count += 1
			end

			cPopev:Fire()
			cPop.Visible = true
		end
	end)


	HOVER_cons[button][3] = button.MouseMoved:Connect(function()
		local mouseLocation = UIS:GetMouseLocation()
		cPop.Position = UDim2.new(0, mouseLocation.X, 0, mouseLocation.Y - cPop.Bg.AbsoluteSize.Y)
	end)

	HOVER_cons[button][2] = button.MouseLeave:Connect(function()
		closeUp(button)

		local mousePos = UIS:GetMouseLocation() - GS:GetGuiInset()
		local getGUI = playerGUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
		local found = false

		for i, v in pairs(getGUI) do
			if v:IsDescendantOf(box2) then
				found = true
				break
			end
		end

		if not found then
			cPop.Visible = false
		end
	end)
end

function crafting.fillCorrectUI(station)
	local location = craftingIndex.Self
	if station == nil then
		station = plr
		location = craftingIndex.Self
	elseif station ~= plr then
		location = craftingIndex[station.Name]
	end
	--print(location)
	for i, v in pairs(location) do
		--print(i)
		if not itemInfo[i] then continue end
		--print(i)
		local clo = nil
		if canCraft(i, v.Materials) then
			clo = canCraftref:Clone()
		else
			clo = cantCraftref:Clone()
		end
		clo.Name = i
		clo.Img.Image = itemInfo[i].Image
		clo.LayoutOrder = v.Order
		Crafts[clo] = {}
		Crafts[clo].Materials = v.Materials
		clo.Parent = box2

		bindHover(clo)

		clo.MouseButton1Click:Connect(function()
			if canCraft(i, v.Materials) and not craftRunning then
				craftRunning = true

				local craftWentThrough = false
				local didCraft = nil
				local con
				con = startCraftEv.OnClientEvent:Connect(function(didItCraft)
					con:Disconnect()
					didCraft = didItCraft
					craftWentThrough = true
				end)

				coroutine.wrap(function()
					if BarTween then
						if BarTween.PlaybackState == Enum.PlaybackState.Playing then
							BarTween:Cancel()
						end
					end

					local newTI = TweenInfo.new(
						v.CraftingTime,
						TIS[1].EasingStyle,
						TIS[1].EasingDirection
					)

					bar.Size = UDim2.new(defaultBarLength, 0, bar.Size.Y.Scale, 0)

					BarTween = TS:Create(bar, newTI, {Size = UDim2.new(1, 0, bar.Size.Y.Scale, 0)})
					BarTween:Play()
					BarTween.Completed:Wait()

					bar.Size = UDim2.new(defaultBarLength, 0, bar.Size.Y.Scale, 0)
				end)()

				startCraftEv:FireServer(station, i)

				repeat wait() until didCraft
				craftRunning = false
			end
		end)
	end
end

function crafting.updCorrectUI(gotData)
	for i, v in pairs(box2:GetChildren()) do
		if v:IsA("TextButton") and Crafts[v] then
			if canCraft(v.Name, Crafts[v].Materials, gotData) then
				v.UIGradient.Color = canCraftref.UIGradient.Color
				v.Img.ImageTransparency = canCraftref.Img.ImageTransparency
			else
				closeUp(v)
				v.UIGradient.Color = cantCraftref.UIGradient.Color
				v.Img.ImageTransparency = cantCraftref.Img.ImageTransparency
			end
		end
	end
end

-- Global Functions
function crafting.setup(station)
	-- set station
	cPop.Visible = false
	if (crafting.loadedCraft) and (crafting.loadedCraft == station) then return end
	crafting.loadedCraft = station or plr
	otherUI:WaitForChild("Station").Value = station

	-- unbind past binds
	for i, v in pairs(HOVER_TES) do
		for i2, v2 in pairs(v) do
			if v2.PlaybackState == Enum.PlaybackState.Playing then
				v2:Cancel()
			end
		end
	end

	-- get refs
	canCraftref.Parent = script
	cantCraftref.Parent = script

	-- set bar size
	bar.Size = UDim2.new(defaultBarLength, 0, bar.Size.Y.Scale, 0)

	-- clearup
	for i, v in pairs(box2:GetChildren()) do
		if v:IsA("TextButton") then
			Crafts[v] = nil
			v:Destroy()
		end
	end

	crafting.fillCorrectUI(station)
end

return crafting
