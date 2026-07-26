-- DataTypes.Calendar
local Calendar = {}
Calendar.__index = Calendar

local SLOTS = {"Morning", "After School", "Evening", "Night"}

function Calendar.new(Player, DataClass, BaseCalendar)
	local MT = setmetatable({}, Calendar)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass})

	MT.BaseData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).GlobalFunctions.deepCopy(BaseCalendar)
	MT.Data = MT.Data or MT.BaseData
	MT.Changed = Instance.new("BindableEvent")

	-- Progress to the next time slot
	function MT:AdvanceTime()
		local currentIndex = table.find(SLOTS, self.Data.TimeSlot)
		if currentIndex < #SLOTS then
			self.Data.TimeSlot = SLOTS[currentIndex + 1]
		else
			-- It was Night, so move to the next day
			self.Data.TimeSlot = SLOTS[1]
			self.Data.CurrentDate += 1
			-- (Optional) Logic for DayOfWeek calculation based on CurrentDate
		end
		self.Changed:Fire("TimeAdvanced", self.Data)
	end

	return MT
end

return Calendar