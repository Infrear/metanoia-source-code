local svcLighting = game.Lighting
local updateLighting = function()
	if (script.Parent.Visible) then
		script.Parent.Parent.Brightness = 1
		-- Clear post processing.
		svcLighting:ClearAllChildren()
		-- Defaults.
		svcLighting.Ambient = Color3.new(1,1,1)
		svcLighting.Brightness = 0.25
		svcLighting.ColorShift_Bottom = Color3.new(1,1,1)
		svcLighting.ColorShift_Top = Color3.new(1,1,1)
		svcLighting.EnvironmentDiffuseScale = 0
		svcLighting.EnvironmentSpecularScale = 1
		svcLighting.OutdoorAmbient = Color3.new(0,0,0)
		svcLighting.FogEnd = 128
		svcLighting.FogStart = 0
		-- Color correction
		local correction = Instance.new("ColorCorrectionEffect")
		correction.Brightness = 0
		correction.Contrast = 100000
		correction.Saturation = -1
		correction.TintColor = Color3.new(1,1,1)
		correction.Parent = svcLighting
	end	
end
script.Parent:GetPropertyChangedSignal("Visible"):Connect(updateLighting)
wait()
updateLighting()