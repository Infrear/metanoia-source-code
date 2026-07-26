-- Move the image randomly so it appears fuzzy.
local ui = script.Parent
-- Move randomly.
game:GetService("RunService").RenderStepped:Connect(function()
	ui.Position = UDim2.new(0.5,math.random(-250,250),0.5,math.random(-250,250))
end)