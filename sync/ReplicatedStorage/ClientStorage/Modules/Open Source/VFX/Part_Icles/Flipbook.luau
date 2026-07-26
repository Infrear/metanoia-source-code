
local RangeMod = require(script.Parent.Range)
local MeshFlipbook = {}

function MeshFlipbook.Loop(particle, flipbookFolder, decal, lifetime)
	local decalObjects = {}
	for _, child in pairs(flipbookFolder:GetChildren()) do
		if child.Texture then
			table.insert(decalObjects, child)
		end
	end

	if #decalObjects == 0 then return end

	-- Sort by numerical name
	table.sort(decalObjects, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	-- Extract textures in sorted order
	local decals = {}
	for _, obj in ipairs(decalObjects) do
		table.insert(decals, obj.Texture)
	end
	
	local framerate = RangeMod.RandomValueFromRange(particle.FlipbookFramerate) 
	local frameDelay = 1 / framerate
	local currentFrame = particle.FlipbookStartRandom and math.random(1, #decals) or 1

	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < lifetime do
			decal.Texture = decals[currentFrame]

			currentFrame = currentFrame + 1
			if currentFrame > #decals then
				currentFrame = 1  -- Loop back to first frame
			end

			task.wait(frameDelay)
		end
	end)
end

function MeshFlipbook.OneShot(particle, flipbookFolder, decal, lifetime)
	
	local decalObjects = {}
	for _, child in pairs(flipbookFolder:GetChildren()) do
		if child.Texture then
			table.insert(decalObjects, child)
		end
	end

	if #decalObjects == 0 then return end

	-- Sort by numerical name
	table.sort(decalObjects, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	-- Extract textures in sorted order
	local decals = {}
	for _, obj in ipairs(decalObjects) do
		table.insert(decals, obj.Texture)
	end

	if #decals == 0 then return end
	

	-- For OneShot, distribute frames evenly over the particle's lifetime
	local frameDelay = lifetime / #decals
	local currentFrame = particle.FlipbookStartRandom and math.random(1, #decals) or 1

	task.spawn(function()
		for i = 1, #decals do
			if currentFrame > #decals then break end

			decal.Texture = decals[currentFrame]
			currentFrame = currentFrame + 1

			task.wait(frameDelay)
		end
	end)
end

function MeshFlipbook.Flip(particle, flipbookFolder, decal, lifetime)
	local flipbookMode = particle.FlipbookMode

	if flipbookMode == Enum.ParticleFlipbookMode.Loop then
		MeshFlipbook.Loop(particle, flipbookFolder, decal, lifetime)
	elseif flipbookMode == Enum.ParticleFlipbookMode.OneShot then
		MeshFlipbook.OneShot(particle, flipbookFolder, decal, lifetime)
	else
		return
	end
end

return MeshFlipbook