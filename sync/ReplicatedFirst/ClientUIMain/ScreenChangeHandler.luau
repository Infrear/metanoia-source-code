-- Services
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local plr = PLRS.LocalPlayer
local PlayerGui = plr:WaitForChild("PlayerGui")

local TransportGui = PlayerGui:WaitForChild("Transport")
local Holder = TransportGui:WaitForChild("Holder")
local ScrubTransport = Holder:WaitForChild("ScrubTransport")
local FaceTransport = Holder:WaitForChild("FaceTransport")

local TransportRemote = Storage.Events.Remotes:FindFirstChild("TransportRemote")
local TransportBindable = Storage.Events.Standard:WaitForChild("TransportBindable")

-- Initialization
local TransportModule = {}
local ActiveStyle = "Scrub" -- Tracks what is currently on screen
local ActiveSpin = false

-- Local Functions
local function setScrubTransparency(scrub, transparency)
	for _, child in pairs(scrub:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.BackgroundTransparency = transparency
			if transparency < 1 then child.Visible = true end
		end
	end
end

-- Global Functions

function TransportModule.LoadIn(style, spin)
	ActiveStyle = style or "Scrub"
	ActiveSpin = spin or false

	if ActiveStyle == "Scrub" then
		-- // SCRUB STYLE
		ScrubTransport.Visible = true
		for i = 1, 6 do
			local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
			local scrubahead = (i < 6) and ScrubTransport:FindFirstChild("Scrub" .. i + 1) or nil

			if scrub then
				setScrubTransparency(scrub, 0.5)
				scrub.Visible = true
				task.wait(0.02)
				setScrubTransparency(scrub, 0)

				if scrubahead then
					setScrubTransparency(scrubahead, 0.5)
					scrubahead.Visible = true
				end
				task.wait(0.01)
			end
		end

		local scrub7 = ScrubTransport:FindFirstChild("Scrub7")
		if scrub7 then
			scrub7.Component.BackgroundTransparency = 0
			scrub7.Visible = true
			for i = 1, 6 do
				local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
				if scrub then scrub.Visible = false setScrubTransparency(scrub, 0.5) end
			end
		end

	elseif ActiveStyle == "Face" then
		-- // FACE STYLE
		FaceTransport.Visible = true
		local uiScale = FaceTransport:FindFirstChild("UIScale")

		local TE1, TE2 = nil
		if uiScale then
			uiScale.Scale = 150
			TE1 = TS:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 8})
		end

		if spin then
			FaceTransport.ImageLabel.Rotation = -180
			TE2 = TS:Create(FaceTransport.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Rotation = 0})
		end
		if TE1 then
			TE1:Play()
			if TE2 then
				TE2:Play()
				TE2.Completed:Wait()
				FaceTransport.ImageLabel.Rotation = 0 -- Reset rotation
			else
				TE1.Completed:Wait()
			end
			FaceTransport.ImageLabel.BackgroundTransparency = 0
		end	
	end
end

function TransportModule.LoadOut()
	if ActiveStyle == "Scrub" then
		-- // SCRUB EXIT
		local scrub7 = ScrubTransport:FindFirstChild("Scrub7")
		if scrub7 then
			local tween = TS:Create(scrub7.Component, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
			tween:Play()
			tween.Completed:Connect(function()
				scrub7.Visible = false
				ScrubTransport.Visible = false
			end)
		end

	elseif ActiveStyle == "Face" then
		-- // FACE EXIT
		local uiScale = FaceTransport:FindFirstChild("UIScale")
		if uiScale then
			FaceTransport.ImageLabel.BackgroundTransparency = 1
			local TE1 = TS:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = 200})
			local TE2 = nil
			if ActiveSpin then
				FaceTransport.ImageLabel.Rotation = 0
				TE2 = TS:Create(FaceTransport.ImageLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Rotation = -180})
				TE2:Play()
			end
			if TE1 then
				TE1:Play()
				if TE2 then
					TE2:Play()
					TE2.Completed:Wait()
					FaceTransport.ImageLabel.Rotation = 0 -- Reset rotation
				else
					TE1.Completed:Wait()
				end
				FaceTransport.ImageLabel.BackgroundTransparency = 1
				FaceTransport.Visible = false 
			end
		end
	end
end

function TransportModule.Load(style, seconds, spin)
	TransportModule.LoadIn(style, spin)
	if seconds and seconds > 0 then
		task.wait(seconds)
	end
	TransportModule.LoadOut()
end

function TransportModule.Initialize()
	-- Clean up state
	for i = 1, 6 do
		local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
		if scrub then scrub.Visible = false setScrubTransparency(scrub, 0.5) end
	end
	FaceTransport.Visible = false
	FaceTransport:FindFirstChild("UIScale").Scale = 150
	FaceTransport.ImageLabel.BackgroundColor3 = Color3.fromRGB(191, 0, 255)
	FaceTransport.ImageLabel.BackgroundTransparency = 1
	FaceTransport.ImageLabel.Rotation = 0

	-- Connect Events
	local function handleInput(mode, style, duration, spin)
		if mode == "In" then TransportModule.LoadIn(style, spin)
		elseif mode == "Out" then TransportModule.LoadOut()
		elseif mode == "Full" then TransportModule.Load(style, duration or 3, spin) end
	end

	TransportRemote.OnClientEvent:Connect(handleInput)
	TransportBindable.Event:Connect(handleInput)
end

return TransportModule

---- Services
--local TS = game:GetService("TweenService")
--local RPS = game:GetService("ReplicatedStorage")
--local PLRS = game:GetService("Players")

---- Dependancies
--local Storage = RPS:WaitForChild("ClientStorage")
--local plr = PLRS.LocalPlayer
--local PlayerGui = plr:WaitForChild("PlayerGui")

--local TransportGui = PlayerGui:WaitForChild("Transport")
--local Holder = TransportGui:WaitForChild("Holder")
--local ScrubTransport = Holder:WaitForChild("ScrubTransport")
--local FaceTransport = Holder:WaitForChild("FaceTransport")

--local TransportRemote = Storage.Events.Remotes:FindFirstChild("TransportRemote")
--local TransportBindable = Storage.Events.Standard:WaitForChild("TransportBindable")

---- Initialization
--local TransportModule = {}

---- Local Functions
--local function setScrubTransparency(scrub, transparency) -- Helper to set transparency on a Scrub's children
--	for _, child in pairs(scrub:GetDescendants()) do
--		if child:IsA("GuiObject") then
--			child.BackgroundTransparency = transparency
--			-- If it's the initial pass, make it visible
--			if transparency == 0.5 then
--				child.Visible = true
--			end
--		end
--	end
--end

---- Global Functions
--function TransportModule.LoadIn()
--	-- 1. Scrub Sequence (Scrub1 to Scrub6)
--	ScrubTransport.Visible = true
--	for i = 1, 6 do
--		local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
--		local scrubahead = nil
--		if i < 6 then
--			scrubahead = ScrubTransport:FindFirstChild("Scrub" .. i + 1)
--		end
--		if scrub then
--			-- Appear at 0.5 transparency
--			setScrubTransparency(scrub, 0.5)
--			scrub.Visible = true
--			task.wait(0.02)

--			-- Switch to solid 0 transparency
--			setScrubTransparency(scrub, 0)
			
--			if scrubahead then
--				setScrubTransparency(scrubahead, 0.5)
--				scrubahead.Visible = true
--			end

--			-- Wait before next scrub
--			task.wait(0.01)
--		end
--	end

--	-- 2. Handle Scrub7 (The Full Screen Blackout)
--	local scrub7 = ScrubTransport:FindFirstChild("Scrub7")
--	if scrub7 then
--		scrub7.Component.BackgroundTransparency = 0
--		scrub7.Visible = true

--		-- Hide previous scrubs for performance/cleanup
--		for i = 1, 6 do
--			local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
--			if scrub then scrub.Visible = false setScrubTransparency(scrub, 0.5) end
--		end
--	end

--	---- 3. Face Transport Animation --> okay so this is actually a separate style lol
--	--FaceTransport.Visible = true
--	--local uiScale = FaceTransport:FindFirstChild("UIScale")
--	--if uiScale then
--	--	uiScale.Scale = 0
--	--	TS:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Scale = 1}):Play()
--	--end
--end

--function TransportModule.LoadOut()
--	local scrub7 = ScrubTransport:FindFirstChild("Scrub7")
--	--local uiScale = FaceTransport:FindFirstChild("UIScale")

--	---- Fade out the Face silhouette first -- > supposed to be in a separate style
--	--if uiScale then
--	--	local fadeOut = TS:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Scale = 1.5})
--	--	fadeOut:Play()
--	--	fadeOut.Completed:Connect(function() FaceTransport.Visible = false end)
--	--end

--	-- Slowly tween out Scrub7 transparency
--	if scrub7 then
--		local tween = TS:Create(scrub7.Component, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
--		tween:Play()
--		tween.Completed:Connect(function()
--			scrub7.Visible = false
--			-- Reset all scrubs for next time
--			for i = 1, 6 do
--				local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
--				if scrub then scrub.Visible = false setScrubTransparency(scrub, 0.5) end
--			end
--			ScrubTransport.Visible = false
--		end)
--	end
--end

--function TransportModule.Load(seconds)
--	TransportModule.LoadIn()
--	if seconds > 0 then
--		task.wait(seconds)
--	end
--	TransportModule.LoadOut()
--end

--function TransportModule.Initialize()
--	for i = 1, 6 do
--		local scrub = ScrubTransport:FindFirstChild("Scrub" .. i)
--		if scrub then scrub.Visible = false setScrubTransparency(scrub, 0.5) end
--	end
	
--	-- Connect Events
--	TransportRemote.OnClientEvent:Connect(function(mode, style, duration)
--		if mode == "In" then TransportModule.LoadIn()
--		elseif mode == "Out" then TransportModule.LoadOut() --> maybe keep track of which style im using so specifying the style doesn't matter for this
--		elseif mode == "Full" then TransportModule.Load(duration or 3) end
--	end)

--	TransportBindable.Event:Connect(function(mode, style, duration)
--		if mode == "In" then TransportModule.LoadIn()
--		elseif mode == "Out" then TransportModule.LoadOut()
--		elseif mode == "Full" then TransportModule.Load(duration or 3) end
--	end)
--end

--return TransportModule