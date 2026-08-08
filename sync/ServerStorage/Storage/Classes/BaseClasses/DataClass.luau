-- Services
local DSS = game:GetService("DataStoreService")

-- Playtest & Debug Settings
local DEV_SETTINGS = {
	DISABLE_DATA_LOADING = false,
	DISABLE_DATA_SAVING  = false, 
	DATA_VERSION_SUFFIX  = "1.69.95", 
}

local DS = DSS:GetDataStore("DataStore" .. DEV_SETTINGS.DATA_VERSION_SUFFIX) -- player stuff
local DSA = DSS:GetDataStore("DataStoreA" .. DEV_SETTINGS.DATA_VERSION_SUFFIX) -- non-player stuff

-- Initialization
local DataClass = {}
DataClass.__index = DataClass
DataClass.DevSettings = DEV_SETTINGS

-- Public Functions
function DataClass.new(idSource, key, slotId) -- constructor function (with modifications)
	return setmetatable({
		key = key;
		SlotId = slotId or "1";
		Player = typeof(idSource) == "Instance" and idSource or nil;
		ID = (typeof(idSource) == "string" or typeof(idSource) == "number") and idSource or nil;
		Data = nil;	
		BaseData = nil;
	}, DataClass)
end


function DataClass:LoadData() -- load data method
	if DEV_SETTINGS.DISABLE_DATA_LOADING then
		if self.Player then
			print("(DATA STATUS) -- Data loading disabled via DevSettings")
		end
		self.Data = nil
		return
	end

	local Data = nil
	local success, err = pcall(function()
		if self.Player then
			Data = DS:GetAsync(self.key.."_Slot"..self.SlotId.."_"..(self.Player.UserId)) -- attempt to load data from store
			--print(Data)
		else
			Data = DSA:GetAsync(self.key..(tostring(self.ID))) -- attempt to load data from store
			--print(Data)
		end
	end)
	if success then
		--print(Data)
		if not Data then -- set data inside private method
			if self.Player then
				print("(DATA STATUS) -- No data to load")
			end
		else
			if self.Player then
				print("(DATA STATUS) -- Successfully loaded data")
			end
			self.Data = Data
		end
	elseif err then
		warn("(DATA STATUS) -- "..err)
	end
end


function DataClass:SaveData() -- save data method
	if DEV_SETTINGS.DISABLE_DATA_SAVING then
		if self.Player then
			print("(DATA STATUS) -- Data saving disabled via DevSettings")
		end
		self = nil
		return
	end

	local success, err = pcall(function()
		if self.Player then
			DS:UpdateAsync(self.key.."_Slot"..self.SlotId.."_"..(self.Player.UserId), function(oldData) -- we save data
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