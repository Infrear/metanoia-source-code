local RPS = game:GetService("ReplicatedStorage")
local Storage = RPS:WaitForChild("ClientStorage")
local FormationCalculator = {}


local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {workspace.NPCS, workspace.PERSONAS, workspace.SCRIPTING, workspace.BOUNDS, workspace.CAMERAS, workspace.NPCWALKERS, workspace.CHARACTERS, workspace.PARTICLES}

local function getModel(fighter)
	if fighter.Instance then
		return fighter.Instance
	elseif fighter.ModelName then
		return Storage.Personas:FindFirstChild(fighter.ModelName) or workspace.NPCS:FindFirstChild(fighter.ModelName)
	end
	return nil
end

-- Use a Raycast to find the exact floor position below the target X, Z coordinate
local function getFloorY(x, y, z)
	local rayOrigin = Vector3.new(x, y + 10, z)
	local rayDirection = Vector3.new(0, -50, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result then
		return result.Position.Y
	end
	
	-- Fallback to default if nothing was hit
	return y - 2.5 
end

function FormationCalculator.CalculateFormations(fightTable, centerPosition)
	-- Normalize centerPosition so it's upright (only Y-axis rotation)
	local lookVec = centerPosition.LookVector
	local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z).Unit
	local baseCFrame = CFrame.new(centerPosition.Position, centerPosition.Position + flatLook)
	
	local allySpacing = 6
	local enemySpacing = 12.5
	
	-- Enemy Center
	local enemyOffset = 30
	local enemyCenter = baseCFrame * CFrame.new(0, 0, -enemyOffset)
	
	for i, fighter in ipairs(fightTable.PlayerFighters) do
		-- Position them in a slight V-formation
		local x = (i - (#fightTable.PlayerFighters/2 + 0.5)) * allySpacing
		local z = math.abs(x) * 0.3 -- curve backwards slightly
		
		-- Start relative to baseCFrame
		local pos = (baseCFrame * CFrame.new(x, 0, z)).Position
		
		-- Use raycast to determine exact floor Y
		local floorY = getFloorY(pos.X, centerPosition.Position.Y, pos.Z)
		
		local model = getModel(fighter)
		local pivotOffset = 2.5
		if model then
			local cframe, size = model:GetBoundingBox()
			local pivot = model:GetPivot()
			pivotOffset = pivot.Y - (cframe.Y - size.Y / 2)
		end
		
		local finalPos = Vector3.new(pos.X, floorY + pivotOffset, pos.Z)
		
		-- Explicitly face the enemy center
		local lookAt = Vector3.new(enemyCenter.Position.X, finalPos.Y, enemyCenter.Position.Z)
		fighter.SpawnCFrame = CFrame.new(finalPos, lookAt)
	end
	
	for i, fighter in ipairs(fightTable.EnemyFighters) do
		local x = (i - (#fightTable.EnemyFighters/2 + 0.5)) * enemySpacing
		local z = (-enemyOffset) - (math.abs(x) * 0.3) -- curve away slightly
		
		-- Randomize slightly for dynamic feel
		local randomOffset = CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
		
		local pos = (baseCFrame * CFrame.new(x, 0, z) * randomOffset).Position
		
		-- Use raycast to determine exact floor Y
		local floorY = getFloorY(pos.X, centerPosition.Position.Y, pos.Z)
		
		local model = getModel(fighter)
		local pivotOffset = 2.5
		if model then
			local cframe, size = model:GetBoundingBox()
			local pivot = model:GetPivot()
			pivotOffset = pivot.Y - (cframe.Y - size.Y / 2)
		end
		
		local finalPos = Vector3.new(pos.X, floorY + pivotOffset, pos.Z)
		
		-- Enemies explicitly face the player center
		local lookAt = Vector3.new(baseCFrame.Position.X, finalPos.Y, baseCFrame.Position.Z)
		fighter.SpawnCFrame = CFrame.new(finalPos, lookAt)
	end
end

return FormationCalculator
