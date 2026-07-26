-- Initialization
local Currency = {}
Currency.__index = Currency 

-- Private Functions

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
	MT.Data = MT.Data or BaseAmount
	
	-- changed
	MT.Changed = Instance.new("BindableEvent")
	
	function MT:Increase(Amount) -- increase method
		if Amount and Amount > 0 then
			self.Changed:Fire((self.Data + Amount) - self.Data)
		end
		self.Data += (Amount or 1)
	end

	function MT:Decrease(Amount) -- decrease method
		if Amount and Amount > 0 then
			self.Changed:Fire(self.Data - (self.Data - Amount))
		end
		self.Data -= (Amount or 1)
	end

	function MT:Set(Amount) -- set method
		self.Changed:Fire(Amount - self.Data)
		if self.Data ~= Amount then
			self.Changed:Fire()
		end
		self.Data = (Amount or self.Data)
	end

	function MT:Destroy() -- cleanup method
		if self.Changed then
			self.Changed:Destroyed()
		end
		self = nil
	end
	
	return MT
end

return Currency
