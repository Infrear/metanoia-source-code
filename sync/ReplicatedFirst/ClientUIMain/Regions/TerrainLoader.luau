-- ============================================================
-- TerrainLoader (ModuleScript — child of Regions)
-- Loads and unloads terrain model assets when the player enters
-- or leaves a region.
--
-- "Terrain" here means pre-built Model objects (trees, props,
-- set dressing) stored in ReplicatedStorage, NOT Roblox Terrain
-- voxels. Those are always present; only decorative models are
-- streamed in/out.
--
-- REGION DATA FORMAT:
--   TerrainAssets = { "ForestTrees", "VillageProps" }
--     → names of Models inside ClientStorage.TerrainAssets
--   TerrainParent = "TERRAIN" (default)
--     → workspace folder to parent loaded assets into
--
-- Models are cloned on load and destroyed on unload.
-- We track by regionName so unloading the correct set is easy.
-- ============================================================

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS  = game:GetService("TweenService")

-- Dependencies
local Storage      = RPS:WaitForChild("ClientStorage")
local assetStorage = Storage:WaitForChild("TerrainAssets", 5) -- optional; nil if not present

local TI = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ── Internal state ───────────────────────────────────────────
-- loadedAssets[regionName] = { cloneA, cloneB, ... }
local loadedAssets = {}

-- ── Helpers ──────────────────────────────────────────────────

-- Fade all BaseParts in a model from transparency 1 → 0 after parenting
local function fadeIn(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			TS:Create(part, TI, { Transparency = 0 }):Play()
		end
	end
end

-- Fade all BaseParts to 1 then destroy
local function fadeOutAndDestroy(model)
	local parts = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(parts, part) end
	end
	if #parts == 0 then model:Destroy() return end

	local done = false
	local conn
	local tw = TS:Create(parts[1], TI, { Transparency = 1 })
	conn = tw.Completed:Connect(function()
		conn:Disconnect()
		if not done then
			done = true
			model:Destroy()
		end
	end)
	for _, part in ipairs(parts) do
		TS:Create(part, TI, { Transparency = 1 }):Play()
	end
	tw:Play()
end

-- ============================================================
-- MODULE
-- ============================================================
local TerrainLoader = {}

function TerrainLoader.load(regionName, terrainData)
	if not terrainData then return end
	if not assetStorage then
		warn("TerrainLoader: ClientStorage.TerrainAssets not found — skipping terrain load")
		return
	end

	local assetNames  = terrainData.TerrainAssets
	local parentName  = terrainData.TerrainParent or "TERRAIN"
	local parentFolder = workspace:FindFirstChild(parentName)
		or (function()
			local f = Instance.new("Folder")
			f.Name   = parentName
			f.Parent = workspace
			return f
		end)()

	if type(assetNames) == "string" then assetNames = { assetNames } end
	if not assetNames then return end

	loadedAssets[regionName] = loadedAssets[regionName] or {}

	for _, assetName in ipairs(assetNames) do
		local src = assetStorage:FindFirstChild(assetName)
		if src then
			local clone = src:Clone()
			clone.Parent = parentFolder
			table.insert(loadedAssets[regionName], clone)
			fadeIn(clone)
		else
			warn("TerrainLoader: asset '" .. assetName .. "' not found in TerrainAssets")
		end
	end
end

function TerrainLoader.unload(regionName)
	local assets = loadedAssets[regionName]
	if not assets then return end

	for _, model in ipairs(assets) do
		if model and model.Parent then
			fadeOutAndDestroy(model)
		end
	end
	loadedAssets[regionName] = nil
end

function TerrainLoader.unloadAll()
	for regionName in pairs(loadedAssets) do
		TerrainLoader.unload(regionName)
	end
end

return TerrainLoader