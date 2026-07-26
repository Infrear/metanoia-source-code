-- Offset slowly.
local ui = script.Parent
game:GetService("RunService").RenderStepped:Connect(function()
	local offset = (tick() * 80) % 250
	ui.Position = UDim2.new(ui.Position.X.Scale, 0, ui.Position.Y.Scale, offset)
end)