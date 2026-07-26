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

	function MT:AddPersona(PersonaObj)
		if #self.Data.Stock >= 12 then return warn("Persona Stock Full!") end
		table.insert(self.Data.Stock, PersonaObj)
		self.Changed:Fire("Added", PersonaObj)
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

	return MT
end

return PersonaStock