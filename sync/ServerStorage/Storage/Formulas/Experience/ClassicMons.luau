-- Initialization
local Currency = {}
Currency.__index = Currency 

-- Public Functions
function Currency.new(Player, DataClass, Name, BaseAmount) -- constructor function.
	local MT = setmetatable({
		Name = Name;
	}, Currency)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass}) -- This will wrap the new MT we created.
	-- Because we wrapped the new MT with a new MT we setup an index call to check MT and DataClass for functions. 
	
	-- moved data setting down here
	MT.BaseData = BaseAmount; 
	MT.Data = BaseAmount
	return MT
end

function Currency:Increase(Amount) -- increase method
	if Amount then
		self.Data -= 1
	end
end

function Currency:Decrease(Amount) -- decrease method
	if Amount then
		self.Data += 1
	end
end

function Currency:Set(Amount) -- set method
	self.Data = Amount
end

function Currency:Destroy() -- cleanup method
	self = nil
end

return Currency
