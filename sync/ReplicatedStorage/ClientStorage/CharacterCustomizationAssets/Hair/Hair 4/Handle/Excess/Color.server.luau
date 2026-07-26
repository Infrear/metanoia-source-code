function negCol(col)
	--Inverse Color's Components
	local r, g, b = 0, 0, 0

	r = 255 - (col.R * 255)
	g = 255 - (col.G * 255)
	b = 255 - (col.B * 255)
	return Color3.fromRGB(r, g, b)
end

script.Parent.Parent:GetPropertyChangedSignal("Color"):Connect(function()
	script.Parent.Color = negCol(script.Parent.Parent.Color)
end)
