-- DataTypes.MetaverseProgress
local MetaverseProgress = {}
MetaverseProgress.__index = MetaverseProgress

function MetaverseProgress.new(Player, DataClass, BaseProgress)
	local MT = setmetatable({}, MetaverseProgress)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass})

	MT.BaseData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).GlobalFunctions.deepCopy(BaseProgress)
	MT.Data = MT.Data or MT.BaseData
	MT.Changed = Instance.new("BindableEvent")

	function MT:UpdateFloor(NewFloor)
		self.Data.CurrentFloor = NewFloor
		self.Changed:Fire("FloorReached", NewFloor)
	end

	function MT:SetDeadline(DateNumber)
		self.Data.CurrentDeadline = DateNumber
		self.Changed:Fire("DeadlineSet", DateNumber)
	end

	return MT
end

return MetaverseProgress