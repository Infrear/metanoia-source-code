-- Services
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- Dependancies
local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local playerGUI = plr:WaitForChild("PlayerGui")
local mouse = plr:GetMouse()

local ui = playerGUI:WaitForChild("Interactables")
local frame = ui:WaitForChild("Building")

-- Local Variables
local TN = nil
local TN2 = nil
local TN3 = nil
local TI = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out,
	0,
	false
)
local TI2 = TweenInfo.new(
	1,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false
)
local TI3 = TweenInfo.new(
	3.5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In,
	0,
	false
)

-- Initialization
local sliding = {}

-- Global Functions
function sliding.setup()
	UIS.InputBegan:Connect(function(input, gP)
		if input.KeyCode == Enum.KeyCode.U and gP == false and frame.Visible == true then
			if frame:GetAttribute("Mode") == "Snap" then
				frame:SetAttribute("Mode", "Edge")
				local v = frame.BackG.Edge
				if TN ~= nil then TN:Cancel() end
				TN = TS:Create(frame.BackG.Slider, TI, {Position = v.Position})
				TN:Play()


				frame.BackG.Texter.Text = v.Name
				frame.BackG.Texter.Position = UDim2.new(frame.BackG.Texter.Position.X.Scale, frame.BackG.Texter.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)

				if TN2 ~= nil then TN2:Cancel() end	
				if TN3 ~= nil then TN3:Cancel() end	
				frame.BackG.Texter.TextTransparency = 1
				TN2 = TS:Create(frame.BackG.Texter, TI2, {TextTransparency = 0})
				TN2:Play()
				TN2.Completed:Wait()

				TN3 = TS:Create(frame.BackG.Texter, TI3, {TextTransparency = 1})			
				TN3:Play()
			elseif frame:GetAttribute("Mode") == "Edge" then
				frame:SetAttribute("Mode", "Free")
				local v = frame.BackG.Free
				if TN ~= nil then TN:Cancel() end
				TN = TS:Create(frame.BackG.Slider, TI, {Position = v.Position})
				TN:Play()

				frame.BackG.Texter.Text = v.Name
				frame.BackG.Texter.Position = UDim2.new(frame.BackG.Texter.Position.X.Scale, frame.BackG.Texter.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)

				if TN2 ~= nil then TN2:Cancel() end	
				if TN3 ~= nil then TN3:Cancel() end	
				frame.BackG.Texter.TextTransparency = 1
				TN2 = TS:Create(frame.BackG.Texter, TI2, {TextTransparency = 0})
				TN2:Play()
				TN2.Completed:Wait()

				TN3 = TS:Create(frame.BackG.Texter, TI3, {TextTransparency = 1})			
				TN3:Play()

			elseif frame:GetAttribute("Mode") == "Free" then
				frame:SetAttribute("Mode", "Snap")
				local v = frame.BackG.Snap
				if TN ~= nil then TN:Cancel() end
				TN = TS:Create(frame.BackG.Slider, TI, {Position = v.Position})
				TN:Play()

				frame.BackG.Texter.Text = v.Name
				frame.BackG.Texter.Position = UDim2.new(frame.BackG.Texter.Position.X.Scale, frame.BackG.Texter.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)

				if TN2 ~= nil then TN2:Cancel() end	
				if TN3 ~= nil then TN3:Cancel() end	
				frame.BackG.Texter.TextTransparency = 1
				TN2 = TS:Create(frame.BackG.Texter, TI2, {TextTransparency = 0})
				TN2:Play()
				TN2.Completed:Wait()

				TN3 = TS:Create(frame.BackG.Texter, TI3, {TextTransparency = 1})			
				TN3:Play()
			end
		end
	end)

	for i, v in pairs(frame.BackG:GetChildren()) do
		if v:IsA("ImageButton")then
			v.MouseButton1Click:Connect(function()
				frame:SetAttribute("Mode", v.Name)
				if TN ~= nil then TN:Cancel() end
				TN = TS:Create(frame.BackG.Slider, TI, {Position = v.Position})
				TN:Play()

				frame.BackG.Texter.Text = v.Name
				frame.BackG.Texter.Position = UDim2.new(frame.BackG.Texter.Position.X.Scale, frame.BackG.Texter.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)

				if TN2 ~= nil then TN2:Cancel() end	
				if TN3 ~= nil then TN3:Cancel() end	
				frame.BackG.Texter.TextTransparency = 1
				TN2 = TS:Create(frame.BackG.Texter, TI2, {TextTransparency = 0})
				TN2:Play()
				TN2.Completed:Wait()

				TN3 = TS:Create(frame.BackG.Texter, TI3, {TextTransparency = 1})			
				TN3:Play()
			end)
		end
	end
end

return sliding
