-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependancies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local Storage = RPS:WaitForChild("ClientStorage")
local CCAssets = Storage:WaitForChild("CharacterCustomizationAssets")

-- Initialization
local Character = {}
Character.__index = Character 

-- Private Functions

-- Public Functions
function Character.new(Player, DataClass, BaseCharacter) -- constructor function.
	local MT = setmetatable({
		--Data = BaseCharacter;
		--BaseData = BaseCharacter;
	}, Character)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass}) -- This will wrap the new MT we created.
	-- Because we wrapped the new MT with a new MT we setup an index call to check MT and DataClass for functions. 

	-- moved data setting down here
	--MT.ToolData = {}; 
	MT.BaseData = odm.GlobalFunctions.deepCopy(BaseCharacter);
	-- data loaded from data class or itself
	MT.Data = MT.Data or MT.BaseData
	--MT.Data[2] = {}; 
	--MT.SlotData = {}; 
	
	-- changed
	MT.Changed = Instance.new("BindableEvent")
	
	function MT:UpdateCharacterPreset(newData, preset) -- method for updating character data for a certain preset
		if not preset or not newData then return end
		self.Data.Presets[preset] = newData
		self.Changed:Fire(preset, newData)
	end
	
	function MT:UpdateCharacterCFrame(newCFrame) -- method for updating cframe method
		--print(self.Data)
		self.Data.CFrame = {newCFrame:GetComponents()}
		self.Changed:Fire(newCFrame)
	end
	
	function MT:Reset() -- reset character method
		self.Data = self.BaseData
		self.Changed:Fire()
	end

	function MT:Destroy() -- cleanup method
		if self.Changed then
			self.Changed:Destroy()
		end
		self = nil
	end
	
	return MT
end


return Character
