local UIS = game:GetService("UserInputService")
local Key = Enum.KeyCode.M

UIS.InputBegan:Connect(function(Input, GP)
	if GP then return end
	if Input.KeyCode == Key then
		script.Parent.Enabled = not script.Parent.Enabled
	end
end)