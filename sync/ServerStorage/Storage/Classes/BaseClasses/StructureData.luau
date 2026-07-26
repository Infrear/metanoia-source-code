-- Services
local SS = game:GetService("ServerStorage")
local RPS = game:GetService("ReplicatedStorage")

-- Constants
local BASE_INVENTORY = {
	[1] = {
	},
	[2] = {
	},
}
	
-- Dependencies
local Storage = SS:WaitForChild("Storage")
local CStorage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)
local DataTypes = Importer:ImportFolder(Storage.Classes.DataTypes)
local Currency = require(Storage.Classes.DataTypes.Currency)
local DataClass = Importer:ImportScript(Storage.Classes.BaseClasses.DataClass)
local Builds = CStorage:WaitForChild("Builds")
local buildInfo = require(CStorage:WaitForChild("Info"):WaitForChild("BuildInfo"))
--local itemInfo = require(CStorage:WaitForChild("Info"):WaitForChild("ItemInfo"))

-- Initialization
local StructureData = {}
StructureData.__index = StructureData

-- Public Functions
function StructureData.new(ID, Keys, newRealWorldObjectData) -- constructor function.
	local uniqueStructureID = ID
	local MT = setmetatable({
		-- Set up properties for StructureClass here
		Inventory = nil,
		RealWorldObjectData = nil, -- has health, buildType and location
		RealWorldObject = nil
	}, StructureData)

	-- Initialize the inventory for the structure
	MT.RealWorldObjectData = DataTypes.RealWorldObjectData.new(DataClass.new(uniqueStructureID, Keys.REALWORLDBUILD_KEY), newRealWorldObjectData)
	
	--print(MT.RealWorldObjectData)
	local myRWData = ((MT.RealWorldObjectData and MT.RealWorldObjectData.Data) or newRealWorldObjectData)
	local needsInventory = myRWData and buildInfo[(myRWData).BuildType] and buildInfo[(myRWData).BuildType].NeedsInventory
	
	if needsInventory then
		MT.Inventory = DataTypes.Inventory.new(nil, DataClass.new(uniqueStructureID, Keys.INVENTORY_KEY), BASE_INVENTORY, buildInfo[(myRWData).BuildType].GridlockedInventory)
		--print(BASE_INVENTORY)
		--print(uniqueStructureID)
		--print(MT.Inventory)	
	end
	--MT.RealWorldObject = Builds:WaitForChild(MT.RealWorldObjectData.BuildType):Clone()
	--MT.RealWorldObject.Parent = workspace.BUILDS
	
	return MT
end

-- ...

function StructureData:SaveData() -- save data 
	if self.Inventory then
		self.Inventory:SaveData() -- Call the SaveData method of the Inventory instance to save the structure's inventory data
	end
	self.RealWorldObjectData:SaveData()
	-- You may add more saving logic here for BuildType and Health if needed
end

function StructureData:BindBuild(realBuild)
	self.RealWorldObject = realBuild
end

function StructureData:Destroy()
	self = nil
end

-- ...

return StructureData