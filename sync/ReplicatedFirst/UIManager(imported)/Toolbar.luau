-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)

local plr = game.Players.LocalPlayer
repeat wait() until plr.Character ~= nil
local char = plr.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui = playerGUI:WaitForChild("SurvivorUI")
local frame = ui:WaitForChild("MainBar")

local event = Instance.new("BindableEvent")

local TIS = {
	TweenInfo.new(
		0.55,
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

-- Variables
local TES = {}

-- Constants
local DEFAULTS = {
	[frame:WaitForChild("1")] = UDim2.new(0.239, 0, 0.126, 0),
	[frame:WaitForChild("2")] = UDim2.new(0.347, 0, 0.126, 0),
	[frame:WaitForChild("3")] = UDim2.new(0.455, 0, 0.126, 0),
	[frame:WaitForChild("4")] = UDim2.new(0.562, 0, 0.126, 0),
	[frame:WaitForChild("5")] = UDim2.new(0.67, 0, 0.126, 0),
}
local UDIM_INFO = {
	["FrameSize"] = UDim2.new(0.09, 0, 0.5, 0),
	["DownHeight"] = UDim.new(1, 0),
	["UpHeight"] = UDim.new(0.126, 0),
	["MiddleXPos"] = UDim.new(0.455, 0),
}

-- Initialization
local toolbar = {}

-- Global Variables
--toolbar.In = false
toolbar.Ready = Instance.new("BindableEvent")

-- Global Functions
function toolbar.fadeOut()
	frame:SetAttribute("CanMove", false)
	event:Fire()
	for i, v in pairs(DEFAULTS) do
		coroutine.wrap(function()
			local toContinue = true
			local con
			con = event.Event:Connect(function()
				con:Disconnect()
				toContinue = false
			end)

			if TES[i] then
				if TES[i].PlaybackState == Enum.PlaybackState.Playing then
					TES[i]:Cancel()
				end
			end
			TES[i] = TS:Create(i, TIS[1], {Position = UDim2.new(UDIM_INFO.MiddleXPos, UDim.new(UDIM_INFO.UpHeight.Scale - 0.25, UDIM_INFO.UpHeight.Offset)), Size = UDim2.new(
				UDIM_INFO.FrameSize.X.Scale, 
				UDIM_INFO.FrameSize.Y.Scale,
				UDIM_INFO.FrameSize.Y.Scale + 0.150, 
				UDIM_INFO.FrameSize.Y.Offset
				)})

			for i,v in pairs(frame.ButtonIndications:GetChildren()) do
				if TES[v] then
					if TES[v].PlaybackState == Enum.PlaybackState.Playing then
						TES[v]:Cancel()
					end
				end
				if v:IsA("ImageButton") then
					TES[v] = TS:Create(v, TIS[1], {ImageTransparency = 1})
					TES[v]:Play()
					local foundLabel = v:FindFirstChildOfClass("TextLabel")
					if foundLabel then
						if TES[foundLabel] then
							if TES[foundLabel].PlaybackState == Enum.PlaybackState.Playing then
								TES[foundLabel]:Cancel()
							end
						end
						TES[foundLabel] = TS:Create(foundLabel, TIS[1], {TextTransparency = 1})
						TES[foundLabel]:Play()
					end
				end
			end
			
			TES[i]:Play()
			TES[i].Completed:Wait()

			if toContinue then
				con:Disconnect()
				TES[i] = TS:Create(i, TIS[1], {Position = UDim2.new(UDIM_INFO.MiddleXPos, UDIM_INFO.DownHeight), Size = UDIM_INFO.FrameSize})
				TES[i]:Play()
			end
		end)()
	end
end

function toolbar.fadeIn()
	frame:SetAttribute("CanMove", false)
	event:Fire()
	for i, v in pairs(DEFAULTS) do
		coroutine.wrap(function()
			local toContinue = true
			local con
			con = event.Event:Connect(function()
				con:Disconnect()
				toContinue = false
			end)
			--print("here")
			--print(i)
			--print(TES)
			--print(TES[i])
			if TES[i] then
				--print("did")
				if TES[i].PlaybackState == Enum.PlaybackState.Playing then
					TES[i]:Cancel()
				end
			end
			--print("this")
			--print(UDim2.new(UDIM_INFO.MiddleXPos, UDIM_INFO.UpHeight))
			TES[i] = TS:Create(i, TIS[1], {Position = UDim2.new(UDIM_INFO.MiddleXPos, UDim.new(UDIM_INFO.UpHeight.Scale - 0.25, UDIM_INFO.UpHeight.Offset)), Size = UDim2.new(
				UDIM_INFO.FrameSize.X.Scale, 
				UDIM_INFO.FrameSize.Y.Scale,
				UDIM_INFO.FrameSize.Y.Scale + 0.150, 
				UDIM_INFO.FrameSize.Y.Offset
				)})

			for i,v in pairs(frame.ButtonIndications:GetChildren()) do
				if TES[v] then
					if TES[v].PlaybackState == Enum.PlaybackState.Playing then
						TES[v]:Cancel()
					end
				end
				if v:IsA("ImageButton") then
					TES[v] = TS:Create(v, TIS[1], {ImageTransparency = 0})
					TES[v]:Play()
					local foundLabel = v:FindFirstChildOfClass("TextLabel")
					if foundLabel then
						if TES[foundLabel] then
							if TES[foundLabel].PlaybackState == Enum.PlaybackState.Playing then
								TES[foundLabel]:Cancel()
							end
						end
						TES[foundLabel] = TS:Create(foundLabel, TIS[1], {TextTransparency = 0})
						TES[foundLabel]:Play()
					end
				end
			end
			
			TES[i]:Play()
			TES[i].Completed:Wait()
			if toolbar.Ready then
				toolbar.Ready:Fire()
			end
			coroutine.wrap(function()
				if toContinue then return end
				frame:SetAttribute("CanMove", true)
			end)()
			
			--print("here2")
			if toContinue then
				con:Disconnect()
				TES[i] = TS:Create(i, TIS[2], {Position = v, Size = UDIM_INFO.FrameSize})
				TES[i]:Play()
				--print("here3")
				coroutine.wrap(function()
					local con
					con = TES[i].Completed:Connect(function()
						con:Disconnect()
						frame:SetAttribute("CanMove", true)
					end)
				end)()
			end
		end)()
		--task.wait(5)
		--toolbar.fadeOut()
	end
end


function toolbar.setup()
	toolbar.fadeIn()
	--task.wait(5)
	--toolbar.fadeOut()
end

return toolbar