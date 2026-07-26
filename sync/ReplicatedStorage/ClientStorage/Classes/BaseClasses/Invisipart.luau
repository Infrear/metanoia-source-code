-- Initialization
local Invisipart = {}

function Invisipart.new(xSize, ySize, zSize, par)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(xSize, ySize, zSize)
	if par then
		part.Parent = par
	end
	return part
end


return Invisipart