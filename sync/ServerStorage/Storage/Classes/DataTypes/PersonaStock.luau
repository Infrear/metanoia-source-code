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

	-- RemovePersona is defined below with tray-aware cleanup

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
	
	-- Returns a list of hydrated PersonaData objects for every slot in the tray
	function MT:GetTrayPersonas()
		local tray = self.Data.Tray or {self.Data.ActiveIndex}
		local out = {}
		for _, stockIdx in ipairs(tray) do
			local raw = self.Data.Stock[stockIdx]
			if raw then
				table.insert(out, PersonaData.fromData(raw))
			end
		end
		return out
	end
	
	-- Returns the raw Tray index array (e.g. {1, 2})
	function MT:GetTray()
		return self.Data.Tray or {self.Data.ActiveIndex}
	end
	
	-- Equips by tray position (1-based index WITHIN the tray, not the stock)
	function MT:SwapToTrayPersona(traySlot)
		local tray = self.Data.Tray
		if not tray or not tray[traySlot] then return end
		local stockIdx = tray[traySlot]
		if self.Data.Stock[stockIdx] then
			self.Data.ActiveIndex = stockIdx
			self.Changed:Fire("Equipped", self.Data.Stock[stockIdx])
		end
	end
	
	-- Override: removing a persona should also scrub it from the tray
	function MT:RemovePersona(Index)
		local removed = table.remove(self.Data.Stock, Index)
		-- fix up ActiveIndex
		if self.Data.ActiveIndex > #self.Data.Stock then
			self.Data.ActiveIndex = math.max(1, #self.Data.Stock)
		end
		-- scrub the removed index from the tray and shift down any that were above it
		if self.Data.Tray then
			local cleaned = {}
			for _, idx in ipairs(self.Data.Tray) do
				if idx ~= Index then
					table.insert(cleaned, idx > Index and idx - 1 or idx)
				end
			end
			self.Data.Tray = cleaned
		end
		self.Changed:Fire("Removed", removed)
	end
	
	-- admin tray size override for testing
	local AdminInfo = require(game:GetService("ReplicatedStorage"):WaitForChild("ClientStorage"):WaitForChild("Info"):WaitForChild("AdminInfo"))
	if table.find(AdminInfo.Admins, Player.Name) then
		MT.Data.TraySize = 3
	end

	return MT
end

return PersonaStock