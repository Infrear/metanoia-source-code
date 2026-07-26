-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)
local StatusIndicator = require(script:WaitForChild("StatusIndicator"))

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("Essentials"):WaitForChild("MainFrame")

local stamina = frame.Parent:WaitForChild("Stamina")

local event = Instance.new("BindableEvent")
local event2 = Instance.new("BindableEvent")

local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[2] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[3] = TweenInfo.new(
		3.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[4] = TweenInfo.new(
		1.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[5] = TweenInfo.new(
		1.5,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	[6] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	[7] = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	[8] = TweenInfo.new(
		0.25,  -- Total duration of the animation (in seconds)
		Enum.EasingStyle.Quad,  -- Easing style (you can choose a different style if desired)
		Enum.EasingDirection.Out,  -- Easing direction (you can choose a different direction if desired)
		0,  -- Number of times to repeat the animation (0 means no repeat)
		false,  -- Whether to reverse the animation on each repeat
		0  -- Delay before starting the animation (in seconds)
	)
}

-- Variables
local TES = {}
local TES2 = {}
local TES3 = {}
local TE = nil
local TE2 = nil
local TE3 = nil
local TE4 = nil
local cons = {}
local oldTemp = 0

-- Constants
local SIGNAL = hum:GetAttributeChangedSignal("Stamina")
local MAXIMUM_EXTRA_PLACES = 1
local VAL1 = {hum, "Stamina"}
local MAX1 = {hum, "MaxStamina"}
local FADE_OBJECTS = {
	--frame.LeftBG,
	--frame.RightBG,
	--frame.ImageLabel,
	--frame.LeftBG.LeftFrame.LeftBG,
	--frame.RightBG.RightFrame.RightBG
	stamina.Bar,
}
local FADE_TYPE = "BackgroundTransparency"
local ADD_TIME = {
	MIN = 0.95,
	BASE = 1.5,
	CAP = 2.5,
}

-- Initialization
local essentials = {}

repeat wait() until MAX1[1]:GetAttribute(MAX1[2]) and VAL1[1]:GetAttribute(VAL1[2]) -- wait for stat(s)

-- Global Variables
essentials.Ready = Instance.new("BindableEvent")

-- Local Functions
local function returnValidChildren(obj)
	local tab = {}
	for i, v in pairs(obj:GetChildren()) do
		if not v:IsA("Frame") and not v:IsA("ImageLabel") and not v:IsA("TextLabel") then continue end
		table.insert(tab, v)
	end
	return tab
end

local function fadeOut()
	for i, v in pairs(FADE_OBJECTS) do
		if TES[v] then
			if TES[v][1].PlaybackState == Enum.PlaybackState.Playing then
				if TES[v][2] == false then
					return
				else
					TES[v][1]:Cancel()
				end
			end
		end
		TES[v] = {}
		TES[v][2] = false
		TES[v][1] = TS:Create(v, TIS[3], {[FADE_TYPE] = 1})
		TES[v][1]:Play()
	end
end

local function fadeIn()
	for i, v in pairs(FADE_OBJECTS) do
		if TES[v] then
			if TES[v][1].PlaybackState == Enum.PlaybackState.Playing then
				if TES[v][2] == true then
					return
				else
					TES[v][1]:Cancel()
				end
			end
		end
		TES[v] = {}
		TES[v][2] = true
		TES[v][1] = TS:Create(v, TIS[2], {[FADE_TYPE] = 0})
		TES[v][1]:Play()
		coroutine.wrap(function()
			TES[v][1].Completed:Wait()
			repeat wait() until VAL1[1]:GetAttribute(VAL1[2]) >= MAX1[1]:GetAttribute(MAX1[2])
			--task.wait(2.5)
			fadeOut()
		end)()
	end
end

local function calculateColor(temperature)
	-- Define the color range
	local lightblue = Color3.new(0.243137, 0.835294, 1)
	local blue = Color3.new(0, 0.482353, 1)
	local red = Color3.new(1, 0, 0)
	local orange = Color3.new(1, 0.25098, 0)
	local white = Color3.new(1, 1, 1)
	local black = Color3.new(0, 0, 0)

	-- Define the temperature range
	local minTemp = -250
	local maxTemp = 150

	-- Check if the temperature is within the white range
	if temperature >= 0 and temperature <= 20 then
		return white
	elseif temperature > 20 and temperature <= 55 then
		-- Calculate the interpolation factor based on the temperature value
		local t = (temperature - 20) / (55 - 20)
		-- Interpolate between white and orange
		return white:Lerp(orange, t)
	elseif temperature > 55 and temperature <= 100 then
		-- Calculate the interpolation factor based on the temperature value
		local t = (temperature - 55) / (100 - 55)
		-- Interpolate between orange and red
		return orange:Lerp(red, t)
	elseif temperature > 100 and temperature <= 150 then
		return black
	elseif temperature >= -250 and temperature < -200 then
		return white
	elseif temperature >= -200 and temperature < -100 then
		-- Calculate the interpolation factor based on the temperature value
		
		local t = (temperature - (-200)) / (-100 - (-200))
		--print(tostring(t).."from lb to blue")
		-- Interpolate between blue and white
		return blue:Lerp(lightblue, t)
	elseif temperature >= -100 and temperature < 0 then
		-- Calculate the interpolation factor based on the temperature value
		local t = (temperature - (-100)) / (0 - (-100))
		--print(tostring(t).."from white to lb")
		-- Interpolate between blue and white
		return lightblue:Lerp(white, t)
	end
end



local function todo1()
	--if not hum then hum = char:WaitForChild("Humanoid") end --??
	--script.Parent.Value = MAX1[1]:GetAttribute(MAX1[2])
	fadeIn()
	--print("ran")
	local val = math.clamp((VAL1[1]:GetAttribute(VAL1[2])/(MAX1[1]:GetAttribute(MAX1[2]))) * 2.272, 0, 2.272)
	
	--if TE then
	--	if TE.PlaybackState == Enum.PlaybackState.Playing then
	--		TE:Cancel()
	--	end
	--end 
	local TE = TS:Create(stamina.Bar, TIS[1], {Size = UDim2.new(val, stamina.Bar.Size.X.Offset, stamina.Bar.Size.Y.Scale, stamina.Bar.Size.Y.Offset)})
	TE:Play()	
end

local function todo2(frame, VAL, MAX)
	--if not hum then hum = char:WaitForChild("Humanoid") end --??
	--script.Parent.Value = MAX1[1]:GetAttribute(MAX1[2])
	fadeIn()
	--print("ran")
	local val = math.clamp((VAL[1]:GetAttribute(VAL[2]) or VAL[1][VAL[2]])/(MAX[1]:GetAttribute(MAX[2]) or MAX[1][MAX[2]]) * 0.772, 0, 0.772)

	--if TE then
	--	if TE.PlaybackState == Enum.PlaybackState.Playing then
	--		TE:Cancel()
	--	end
	--end 
	local oldie = TES3[frame][2]
	TES3[frame] = {}
	local amt = tostring(math.ceil((VAL[1]:GetAttribute(VAL[2]) or VAL[1][VAL[2]]) * (10^(MAXIMUM_EXTRA_PLACES)))/(10^(MAXIMUM_EXTRA_PLACES)))
	
	TES3[frame][1] = TS:Create(frame.Bar, TIS[1], {Size = UDim2.new(val, frame.Bar.Size.X.Offset, frame.Bar.Size.Y.Scale, frame.Bar.Size.Y.Offset)})
	TES3[frame][1]:Play()	
	TES3[frame][2] = (VAL[1]:GetAttribute(VAL[2]) or VAL[1][VAL[2]])
	
	if frame.Name == "Health" then
		frame.Text.Text = amt
		if (VAL[1]:GetAttribute(VAL[2]) or VAL[1][VAL[2]]) >= oldie then return end
		event2:Fire()
		local toContinue = true
		local con
		con = event2.Event:Connect(function()
			con:Disconnect()
			toContinue = false
		end)
		
		if TE4 then
			if TE4.PlaybackState == Enum.PlaybackState.Playing then
				TE4:Cancel()
			end
		end
		
		TE4 = TS:Create(frame.Bar, TIS[2], {BackgroundColor3 = Color3.new(1, 1, 1)})
		TE4:Play()
		TE4.Completed:Wait()
		if not toContinue then return end
		con:Disconnect()
		
		TE4 = TS:Create(frame.Bar, TIS[2], {BackgroundColor3 = Color3.fromRGB(225, 91, 104)})
		TE4:Play()
	else
		--if tonumber(frame.Text.Text) > 15 then
		--	frame.Text.Visible = false
		--else
		--	frame.Text.Visible = true
		--end
		frame.Text.Text = math.round(amt)
	end
end

local function todo3(frame, VAL)
	local temp = VAL[1]:GetAttribute(VAL[2])
	if not temp then return end
	local textLabel = frame.Text
	local imageLabel = frame.Icon
	
	local og = math.round(oldTemp*10)/10
	local new = math.round(temp*10)/10
	
	--print(og, new)
	if og ~= new then
		coroutine.wrap(function()
			local dif = math.floor(math.abs(new - og))
			local tim = math.clamp(((dif * 0.04) * ADD_TIME.BASE), ADD_TIME.MIN , ADD_TIME.CAP) --ADD_TIME.CAP
			local div = tim/dif
			if TES3[frame] then
				if TES3[frame][1] then
					TES3[frame][1]:Fire()
				else
					TES3[frame][1] = Instance.new("BindableEvent")
				end
				if TES3[frame][3] then
					TES3[frame][3]:Cancel()
				end
				if TES3[frame][4] then
					TES3[frame][4]:Cancel()
				end
			else
				TES3[frame] = {}
				TES3[frame][3] = Instance.new("BindableEvent")
			end
			
			-- tween the color to a lerped color between deep blue and deep red here based on the temperature
			local determinedColor = calculateColor(temp)
			TES3[frame][3] = TS:Create(textLabel, TIS[8], {TextColor3 = determinedColor})
			TES3[frame][3]:Play()
			
			TES3[frame][4] = TS:Create(imageLabel, TIS[8], {ImageColor3 = determinedColor})
			TES3[frame][4]:Play()
			
			--50 
			--100
			--1/50
			local stopped = false
			local con
			con = TES3[frame][1].Event:Connect(function()
				stopped = true
				con:Disconnect()
				--if TES3[frame][1] then
				--	TES3[frame][1]:Destroy()
				--end
			end)

			--print(dif)
			for i = 1, dif do
				--print(i)
				if stopped then break end

				if new > og then
					local wo, w = math.modf(og + i)
					if w ~= 0 then
						textLabel.Text = og + i
					else
						textLabel.Text = tostring(og + i)..".0"
					end
				else
					local wo, w = math.modf(og - i)
					if w ~= 0 then
						textLabel.Text = og - i
					else
						textLabel.Text = tostring(og - i)..".0"
					end
				end

				task.wait(div)
			end
			if not stopped then
				local wo, w = math.modf(new)
				if w ~= 0 then
					textLabel.Text = new
				else
					textLabel.Text = tostring(new)..".0"
				end
			end
			if con then
				con:Disconnect()
				--if TES3[frame][1] then
				--	TES3[frame][1]:Destroy()
				--end
			end
		end)()
	end
	oldTemp = temp
end


-- Constants
local OTHER_FADE_OBJECTS = {
	{
		--frame.Parent:WaitForChild("Temperature"),
		table.unpack(returnValidChildren(frame.Parent:WaitForChild("Temperature"))),
	},
	{
		frame:WaitForChild("Health"),
		table.unpack(returnValidChildren(frame:WaitForChild("Health"))),
	},
	{
		frame:WaitForChild("Hunger"),
		table.unpack(returnValidChildren(frame:WaitForChild("Hunger"))),
	},
	{
		frame:WaitForChild("Thirst"),
		table.unpack(returnValidChildren(frame:WaitForChild("Thirst"))),
	},
}

-- Global Functions
function essentials.fadeOutOthers()
	event:Fire()
	coroutine.wrap(function() -- frame movement
		if TE2 then
			if TE2.PlaybackState == Enum.PlaybackState.Playing then
				TE2:Cancel()
				--print("cancelled")
			end
		end
		TE2 = TS:Create(frame, TIS[5], {Position = UDim2.new(0.007, 0 , 0.936, 0), Size = UDim2.new(0.14, 0, 0.12, 0)})
		TE2:Play()
		--TE4 = TS:Create(stamina.Bar, TIS[5], {BackgroundTransparency = 1})
		--TE4:Play()
	end)()
	coroutine.wrap(function() -- stamina bar movement
		if TE3 then
			if TE3.PlaybackState == Enum.PlaybackState.Playing then
				TE3:Cancel()
			end
		end
		TE3 = TS:Create(stamina, TIS[5], {Position = UDim2.new(0.5, 0 , 1.25, 0), Size = UDim2.new(0.05, 0, 0.0075, 0)})
		TE3:Play()
	end)()
	for oldi, oldv in pairs(OTHER_FADE_OBJECTS) do
		coroutine.wrap(function() -- main indicators movement
			local toContinue = true
			local con
			con = event.Event:Connect(function()
				con:Disconnect()
				toContinue = false
			end)
			for i, v in pairs(oldv) do
				if not v:IsA("Frame") and not v:IsA("ImageLabel") and not v:IsA("TextLabel") then continue end
				if TES2[v] then
					if TES2[v][1].PlaybackState == Enum.PlaybackState.Playing then
						--if TES2[v][2] == true then
						--	return
						--else
							TES2[v][1]:Cancel()
						--end
					end
				end
				--if TE4 then
				--	if TE4.PlaybackState == Enum.PlaybackState.Playing then
				--		TE4:Cancel()
				--	end
				--end
				TES2[v] = {}
				TES2[v][2] = true
				if v:IsA("Frame") then
					if v.Name == "Bar" then
						TES2[v][1] = TS:Create(v, TIS[6], {BackgroundTransparency = 1})
					else
						TES2[v][1] = TS:Create(v, TIS[4], {BackgroundTransparency = 1})
					end
				elseif v:IsA("ImageLabel") then
					TES2[v][1] = TS:Create(v, TIS[4], {ImageTransparency = 1})
				elseif v:IsA("TextLabel") then
					TES2[v][1] = TS:Create(v, TIS[4], {TextTransparency = 1})
				end
				coroutine.wrap(function()
					for _, Object in pairs(frame:GetDescendants()) do
						if Object:IsA("UIStroke") then
							game:GetService("TweenService"):Create(Object, TIS[4], {Thickness = 0}):Play()
						end
					end
				end)()
				TES2[v][1]:Play()
				--print(#oldv)
				--TES2[v][1].Completed:Wait()
				--if #oldv == i then
				--	if essentials.Ready then
				--		--print("fired")
				--		essentials.Ready:Fire()
				--	end
				--end
				if not toContinue then
					con:Disconnect()
					break
				end
			end	
		end)()
		task.wait(0.35)
	end
end

function essentials.fadeInOthers()
	event:Fire()
	coroutine.wrap(function() -- frame movement
		if TE2 then
			if TE2.PlaybackState == Enum.PlaybackState.Playing then
				TE2:Cancel()
				--print("cancelled")
			end
		end
		TE2 = TS:Create(frame, TIS[5], {Position = UDim2.new(0.007, 0 , 0.889, 0), Size = UDim2.new(0.13, 0,0.093, 0)})
		TE2:Play()
	end)()
	coroutine.wrap(function() -- stamina bar movement
		if TE3 then
			if TE3.PlaybackState == Enum.PlaybackState.Playing then
				TE3:Cancel()
			end
		end
		TE3 = TS:Create(stamina, TIS[5], {Position = UDim2.new(0.5, 0 , 0.88, 0), Size = UDim2.new(0.072, 0, 0.014, 0)})
		TE3:Play()
	end)()
	for oldi, oldv in pairs(OTHER_FADE_OBJECTS) do
		coroutine.wrap(function() -- main indicators movement
			local toContinue = true
			local con
			con = event.Event:Connect(function()
				con:Disconnect()
				toContinue = false
			end)
			for i, v in pairs(oldv) do
				if not v:IsA("Frame") and not v:IsA("ImageLabel") and not v:IsA("TextLabel") then continue end
				if TES2[v] then
					if TES2[v][1].PlaybackState == Enum.PlaybackState.Playing then
						--if TES2[v][2] == true then
						--	return
						--else
							TES2[v][1]:Cancel()
						--end
					end
				end
				--if TE4 then
				--	if TE4.PlaybackState == Enum.PlaybackState.Playing then
				--		TE4:Cancel()
				--	end
				--end
				TES2[v] = {}
				TES2[v][2] = true
				if v:IsA("Frame") then
					if v.Name == "Bar" then
						TES2[v][1] = TS:Create(v, TIS[6], {BackgroundTransparency = 0})
					--elseif v.Name == "Temperature" then
					--	TES2[v][1] = TS:Create(v, TIS[4], {BackgroundTransparency = 1})
					else
						TES2[v][1] = TS:Create(v, TIS[4], {BackgroundTransparency = 0})
					end
				elseif v:IsA("ImageLabel") then
					TES2[v][1] = TS:Create(v, TIS[4], {ImageTransparency = 0})
				elseif v:IsA("TextLabel") then
					TES2[v][1] = TS:Create(v, TIS[4], {TextTransparency = 0})
				end
				coroutine.wrap(function()
					for _, Object in pairs(frame:GetDescendants()) do
						if Object:IsA("UIStroke") then
							game:GetService("TweenService"):Create(Object, TIS[4], {Thickness = 2}):Play()
						end
					end
				end)()
				--print("start"..v.Name)
				TES2[v][1]:Play()
				--print(#oldv)
				if v.Name ~= "Background2" then
					TES2[v][1].Completed:Wait()
				end
				--print("end"..v.Name)
				if #oldv == i then
					--print("readied"..v.Name)
					if essentials.Ready then
						--print("fired")
						essentials.Ready:Fire()
					end
				end
				if not toContinue then
					con:Disconnect()
					break
				end
			end	
		end)()
		task.wait(0.35)
	end
end

function essentials.setup()
	StatusIndicator.setup()
	
	for i, v in pairs(cons) do
		v:Disconnect()
	end
	table.clear(cons)
	
	todo1() -- Stamina
	table.insert(cons, SIGNAL:Connect(function()
		--print("ran")
		todo1()
	end))

	TES3[frame:WaitForChild("Health")] = {nil, hum.Health}
	todo2( -- Health
		frame:WaitForChild("Health"),
		{hum, "Health"},
		{hum, "MaxHealth"}
	)
	table.insert(cons, hum.HealthChanged:Connect(function()
		todo2(
			frame:WaitForChild("Health"),
			{hum, "Health"},
			{hum, "MaxHealth"}
		)
	end))
	

	TES3[frame:WaitForChild("Hunger")] = {nil, hum:GetAttribute("Hunger")}
	todo2( -- Hunger
		frame:WaitForChild("Hunger"),
		{hum, "Hunger"},
		{hum, "MaxHunger"}
	)
	table.insert(cons, hum:GetAttributeChangedSignal("Hunger"):Connect(function()
		todo2( -- Hunger
			frame:WaitForChild("Hunger"),
			{hum, "Hunger"},
			{hum, "MaxHunger"}
		)
	end))
	
	TES3[frame:WaitForChild("Thirst")] = {nil, hum:GetAttribute("Thirst")}
	todo2( -- Thirst
		frame:WaitForChild("Thirst"),
		{hum, "Thirst"},
		{hum, "MaxThirst"}
	)
	table.insert(cons, hum:GetAttributeChangedSignal("Thirst"):Connect(function()
		todo2( -- Thirst
			frame:WaitForChild("Thirst"),
			{hum, "Thirst"},
			{hum, "MaxThirst"}
		)
	end))
	
	TES3[frame.Parent:WaitForChild("Temperature")] = {nil, hum:GetAttribute("Temperature")}
	todo3( -- Temperature
		frame.Parent:WaitForChild("Temperature"),
		{hum, "Temperature"}
	)
	table.insert(cons, hum:GetAttributeChangedSignal("Temperature"):Connect(function()
		todo3( -- Temperature
			frame.Parent:WaitForChild("Temperature"),
			{hum, "Temperature"}
		)
	end))
	
	--fadeOut()
	essentials.fadeInOthers() -- visuals
end

-- Connections
plr.CharacterAdded:Connect(function(char)
	essentials.setup()
end)

return essentials