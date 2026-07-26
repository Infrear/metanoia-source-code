-- Services
local DSS = game:GetService("DataStoreService")
local DS = DSS:GetDataStore("DataStore1.69.93") -- player stuff
local DSA = DSS:GetDataStore("DataStoreA1.69.40") -- non-player stuff

-- Initialization
local DataClass = {}
DataClass.__index = DataClass

-- Public Functions
function DataClass.new(idSource, key) -- constructor function (with modifications)
	return setmetatable({
		key = key;
		Player = typeof(idSource) == "Instance" and idSource or nil;
		ID = (typeof(idSource) == "string" or typeof(idSource) == "number") and idSource or nil;
		Data = nil;	
		BaseData = nil;
	}, DataClass)
end


function DataClass:LoadData() -- load data method
	local Data = nil
	local success, err = pcall(function()
		if self.Player then
			Data = DS:GetAsync(self.key..(self.Player.UserId)) -- attempt to load data from store
			--print(Data)
		else
			Data = DSA:GetAsync(self.key..(tostring(self.ID))) -- attempt to load data from store
			--print(Data)
		end
	end)
	if success then
		--print(Data)
		if true or not Data then -- set data inside private method
			if self.Player then
				print("(DATA STATUS) -- No data to load")
			end
			--print(self.BaseData)
			--if self.BaseData then
			--	Data = self.BaseData
			--end
		-- For updating datastores (THIS SHI DONT WORK)
			--elseif Data and self.key == "Stats" and not Data[2] then
			--	if self.Player then
			--		print("(DATA STATUS) -- Resetting data")
			--	end
			--	if self.BaseData then
			--		self.Data = self.BaseData
			--		oldData = self.BaseData
			--	end
		--elseif Data and self.Player and self.key == "Inventory" and (not Data[4] or not Data[4][3]) then
		--	if self.Player then
		--		print("(DATA STATUS) -- Resetting data")
		--	end
			
		--	print(Data)
		--	print(self.BaseData)
			
		--	if self.BaseData then
		--		local modTable = Data
		--		modTable[4] = self.BaseData[4]
		--		print(modTable)
		--		--self.Data = modTable
		--	end
		else
			if self.Player then
				print("(DATA STATUS) -- Successfully loaded data")
			end
			self.Data = Data
			--print(self.Data)
			--if self.Player then
			--	print(Data)
			--end
		end
	elseif err then
		warn("(DATA STATUS) -- "..err)
	end
end


function DataClass:SaveData() -- save data method
	--print(self.Data)
	local success, err = pcall(function()
		if self.Player then
			DS:UpdateAsync(self.key..(self.Player.UserId), function(oldData) -- we save data
				--print(self.Data)
				return self.Data or oldData
			end)
		else
			DSA:UpdateAsync(self.key..(tostring(self.ID)), function(oldData) -- we save data
				--print(self.Data)
				return self.Data or oldData
			end)
		end
	end)
	if success and self.Player then
		print("(DATA STATUS) -- Successfully saved data")
	elseif err then
		print(self.Data)
		warn("(DATA STATUS) -- "..err)
	end
	self = nil
end

return DataClass