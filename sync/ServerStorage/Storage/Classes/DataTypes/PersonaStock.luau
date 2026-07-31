-- DataTypes.PersonaStock
local PersonaStock = {}
PersonaStock.__index = PersonaStock

function PersonaStock.new(Player, DataClass, BaseStock)
	local MT = setmetatable({}, PersonaStock)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass})

	MT.BaseData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).GlobalFunctions.deepCopy(BaseStock)
	MT.Data = MT.Data or MT.BaseData
	MT.Changed = Instance.new("BindableEvent")
	
	local PersonaData = require(game:GetService("ReplicatedStorage"):WaitForChild("ClientStorage"):WaitForChild("Classes"):WaitForChild("PersonaClientSide"):WaitForChild("PersonaData"))

	function MT:AddPersona(PersonaObj)
		if #self.Data.Stock >= 12 then return warn("Persona Stock Full!") end
		
		-- Ensure we only store raw data, not the metatable itself
		local rawData = typeof(PersonaObj) == "table" and PersonaObj.Serialize and PersonaObj:Serialize() or PersonaObj
		table.insert(self.Data.Stock, rawData)
		self.Changed:Fire("Added", rawData)
	end

	function MT:RemovePersona(Index)
		local removed = table.remove(self.Data.Stock, Index)
		if self.Data.ActiveIndex > #self.Data.Stock then
			self.Data.ActiveIndex = 1
		end
		self.Changed:Fire("Removed", removed)
	end

	function MT:Equip(Index)
		if self.Data.Stock[Index] then
			self.Data.ActiveIndex = Index
			self.Changed:Fire("Equipped", self.Data.Stock[Index])
		end
	end
	
	function MT:GetActivePersona()
		local data = self.Data.Stock[self.Data.ActiveIndex]
		if data then
			return PersonaData.fromData(data)
		end
		return nil
	end
	
	function MT:UpdateActivePersona(personaObj)
		if self.Data.Stock[self.Data.ActiveIndex] then
			self.Data.Stock[self.Data.ActiveIndex] = personaObj:Serialize()
			self.Changed:Fire("Updated", self.Data.Stock[self.Data.ActiveIndex])
		end
	end

	return MT
end

return PersonaStock