-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependancies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local Storage = RPS:WaitForChild("ClientStorage")

-- Dependancies
local itemInfo = require(Storage:WaitForChild("Info"):WaitForChild("ItemInfo"))

-- Initialization
local Inventory = {}
Inventory.__index = Inventory 

-- Private 
local function removeGapsAndResetOrder(data)
	--local newTable = {}
	local newData = {}
	local newIndex = 1

	-- Create a table to store slotObjects sorted by their Order
	local sortedSlotObjects = {}
	for i, v in pairs(data) do
		if v.List then
			for i2, slotObject in pairs(v.List) do
				if slotObject.Order then
					table.insert(sortedSlotObjects, {slotObject, i, i2})
				end
			end
		end
	end
	--print(data)
	
	-- Sort the slotObjects by their Order
	table.sort(sortedSlotObjects, function(a, b) return a[1].Order < b[1].Order end)

	newData = data
	-- Reset the Order and remove gaps
	for _, slotObject in ipairs(sortedSlotObjects) do
		newData[slotObject[2]].List[slotObject[3]].Order = newIndex
		--slotObject[1].Order = newIndex
		--newTable[newIndex] = slotObject
		newIndex += 1
	end
	print(sortedSlotObjects)

	--return newTable
	--print(newData)
	return newData or data
end

local function findSlotWithOrder(List, Order)
	for i, v in pairs(List) do
		if v.Order == Order then
			return i
		end
	end
end

local function runDataCheck(Data, BaseData)
	return Data
	--if not Data then return end
	--if (not Data[4] or not Data[4][3]) then
	--	print("(DATA STATUS) -- Resetting data")

	--	print(Data)
	--	print(BaseData)

	--	if BaseData and false then
	--		local modTable = Data
	--		modTable[4] = BaseData[4]
	--		print(modTable)
	--		return Data
	--	end
	--end
end

--[[
KEY

- Data[1] is the straight number, serverside, protected data for the inventory
- Data[2] is the local based gui data for the inventory
- Data[3] is toolbar gui info
- Data[4] is armor gui info

]]--
-- Public Functions
function Inventory.new(Player, DataClass, BaseInventory, Gridlocked) -- constructor function.
	--local BaseInventory = shallowCopy(OGBaseInventory)
	
	local MT = setmetatable({
		--Data = BaseInventory;
		--BaseData = BaseInventory;
		Gridlocked = Gridlocked or false
	}, Inventory)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass}) -- This will wrap the new MT we created.
	-- Because we wrapped the new MT with a new MT we setup an index call to check MT and DataClass for functions. 

	-- moved data setting down here
	--MT.ToolData = {}; 
	MT.BaseData = odm.GlobalFunctions.deepCopy(BaseInventory);
	
	if not Player then
		--print(BaseInventory)
		local checkedData = runDataCheck(MT.Data, MT.BaseData)
		MT.Data = MT.Data or MT.BaseData
	else
		local checkedData = runDataCheck(MT.Data, MT.BaseData)
		MT.Data = checkedData or MT.BaseData
	end
	--MT.Data[1] = BaseInventory; 
	--MT.Data[2] = {}; 
	--MT.SlotData = {}; 
	
	-- changed
	MT.Changed = Instance.new("BindableEvent")
	MT.UIUpdated = Instance.new("BindableEvent")
	
	function MT:AddItem(Item, Amount, Durability) -- add item method
		if not Item then return end

		local stackable = true

		if itemInfo[Item] then
			--print("exists")
			stackable = itemInfo[Item].Stackable
		end

		--print("added")
		--print((self.Data[1][Item] + Amount) - self.Data[1][Item])

		--print(self.Data[2])
		if not self.Data[2] then
			repeat task.wait() until self.Data[2]
		end
		if itemInfo[Item] then -- setup ui stuff ahead of time if it actually exists
			--print(Item)
			--print(stackable)

			local slotOrder = 1
			for i, v in pairs(self.Data[2]) do
				for i2, slotObject in pairs(v.List) do
					if slotObject.Order then
						slotOrder += 1
					end
				end
			end

			if self.Data[2][Item] and stackable then 
				--print("add", Amount)
				--print("before", self.Data[2][Item])
				if #self.Data[2][Item].List <= 0 then
					self.Data[2][Item].List[1] = {}
					self.Data[2][Item].List[1].Name = Item
					self.Data[2][Item].List[1].Amount = Amount or 1
					self.Data[2][Item].List[1].Order = slotOrder
				else
					self.Data[2][Item].List[1].Amount += Amount or 1
				end
				--print("after", self.Data[2][Item])
			elseif stackable then
				--print(Item)
				if not self.Data[2][Item] then
					--print("did")
					self.Data[2][Item] = {}
					self.Data[2][Item].List = {}
					self.Data[2][Item].Order = #self.Data[2]
				end
				self.Data[2][Item].List[1] = {}
				self.Data[2][Item].List[1].Name = Item
				self.Data[2][Item].List[1].Amount = Amount or 1
				self.Data[2][Item].List[1].Order = slotOrder
				--print(self.Data)
			else
				if not self.Data[2][Item] then
					self.Data[2][Item] = {}
					self.Data[2][Item].List = {}
					self.Data[2][Item].Order = #self.Data[2]
				end

				local start = #self.Data[2][Item].List + 1
				local finish = (start - 1) + Amount


				for count = start, finish do
					--print(count)
					self.Data[2][Item].List[count] = {}
					self.Data[2][Item].List[count].Name = Item
					self.Data[2][Item].List[count].Amount = 1
					self.Data[2][Item].List[count].Order = slotOrder + (count - 1)
				end
			end	

			--self.Data[2] = not self.Gridlocked and removeGapsAndResetOrder(self.Data[2]) or self.Data[2]
		end
		
		if self.Data[1][Item] then 
			--print("add", Amount)
			--print("before", self.Data[1][Item].Amount)
			if itemInfo[Item] and itemInfo[Item].Durability then
				table.insert(self.Data[1][Item].Durability, (Durability or itemInfo[Item].Durability))
			end
			if Amount > 0 or not Amount then
				local change = (self.Data[1][Item].Amount + Amount) - self.Data[1][Item].Amount
				--print("chain1")
				--print(self.Data)
				self.Data[1][Item].Amount += Amount or 1
				self.Changed:Fire(Item, change)
			end
			--print("after", self.Data[1][Item].Amount)
		else
			self.Data[1][Item] = {
				Amount = Amount or 1
			}
			if itemInfo[Item] and itemInfo[Item].Durability then
				self.Data[1][Item].Durability = {
					Durability or itemInfo[Item].Durability
				}
			end
			if Amount > 0 or not Amount then
				self.Changed:Fire(Item, Amount or 1)
			end
		end	
		--print(self.Data[2])
	end
	
	function MT:AddItemAtSlot(Item, Amount, Durability, SlotIndex, Merge)
		if not Item or not SlotIndex then
			return
		end

		local stackable = true

		if itemInfo[Item] then
			stackable = itemInfo[Item].Stackable
		else
			return
		end

		
		if not self.Data[2] then
			repeat task.wait() until self.Data[2]
			--self.Data[2] = {}
		end

		if not self.Data[2][Item] then
			self.Data[2][Item] = {}
			self.Data[2][Item].List = {}
			self.Data[2][Item].Order = #self.Data[2]
		end
		
		local targetSlotLoc = findSlotWithOrder(self.Data[2][Item].List, SlotIndex)
		
		if targetSlotLoc and self.Data[2][Item].List[targetSlotLoc] and Merge and stackable then
			--print("merge")
			self.Data[2][Item].List[targetSlotLoc].Amount += (Amount or 1)
		else
			--print("newAdd")
			local myData2 = self.Data[2]
			
			--> shift everything else if not gridlocked
			if not self.Gridlocked then
				for i, v in pairs(myData2) do
					for i2, slotObject in pairs(v.List) do
						if slotObject.Order and slotObject.Order >= SlotIndex then -- BUG WATCH
							myData2[i].List[i2].Order = myData2[i].List[i2].Order + 1
						end
					end
				end
			end
			--
			
			if not myData2[Item] then
				myData2[Item] = {
					List = {}
				}
			end
			local newItem = {}
			newItem.Name = Item
			newItem.Amount = Amount
			
			--> put it as new
			newItem.Order = SlotIndex
			table.insert(myData2[Item].List, newItem)
			--print(myData)
			self.Data[2] = myData2
			--print(Item)
			--print(self.Data)
		end
		--self.Data[2] = not self.Gridlocked and removeGapsAndResetOrder(self.Data[2]) or self.Data[2]
		if self.Data[1][Item] then
			if itemInfo[Item] and itemInfo[Item].Durability then
				if targetSlotLoc then
					table.insert(self.Data[1][Item].Durability, targetSlotLoc, (Durability or itemInfo[Item].Durability))
				else
					table.insert(self.Data[1][Item].Durability, (Durability or itemInfo[Item].Durability))
				end
			end
			if Amount > 0 or not Amount then
				local change = self.Data[1][Item].Amount + (Amount or 1)
				self.Data[1][Item].Amount = self.Data[1][Item].Amount + (Amount or 1)
				--print("chain0")
				--print(self.Data)
				self.Changed:Fire(Item, change)
			end
		else
			self.Data[1][Item] = {
				Amount = Amount or 1
			}
			if itemInfo[Item] and itemInfo[Item].Durability then
				self.Data[1][Item].Durability = {
					Durability or itemInfo[Item].Durability
				}
			end
			if Amount > 0 or not Amount then
				--print("chain1")
				--print(self.Data)
				self.Changed:Fire(Item, Amount or 1)
			end
		end
		--print(self.Data)
	end

	function MT:RemoveItem(Item, Amount) -- remove item method
		if not Item then return end
		
		local change = (self.Data[1][Item].Amount - Amount or 1) - self.Data[1][Item].Amount

		if self.Data[1][Item].Amount then 
			self.Data[1][Item].Amount -= Amount or 1
		end	

		--if self.Data[2][Item] then
		--	local list = self.Data[2][Item].List
		--	if list[1] then
		--		list[1].Amount = list[1].Amount - (Amount or 1)
		--		if list[1].Amount <= 0 then
		--			table.remove(list, 1)
		--		end
		--	end
		--end
		if self.Data[2][Item] then
			local list = self.Data[2][Item].List
			local remainingAmount = Amount or 1

			for i = 1, #list do
				local currentObject = list[i]
				local currentAmount = currentObject.Amount

				if currentAmount > 0 then
					if remainingAmount >= currentAmount then
						remainingAmount = remainingAmount - currentAmount
						currentObject.Amount = 0
					else
						currentObject.Amount = currentAmount - remainingAmount
						remainingAmount = 0
						break
					end
				end
			end

			-- Remove any objects with zero amount from the list
			for i = #list, 1, -1 do
				if list[i].Amount == 0 then
					if self.Data[3] then
						for i2, v2 in pairs(self.Data[3]) do
							--print(v)
							--print(slotObject)
							if v2.Path and self.Data[2][v2.Path[1]][v2.Path[2]][v2.Path[3]] == list[i] then
								self.Data[3][i2].Path = nil
								--print(self.Data[3][i])
							end
						end
					end
					if self.Data[1][Item].Durability then
						table.remove(self.Data[1][Item].Durability, i)
					end
					table.remove(list, i)
				end
			end
			self.Data[2] = not self.Gridlocked and removeGapsAndResetOrder(self.Data[2]) or self.Data[2]
		end
		if Amount and Amount > 0 then
			self.Changed:Fire(Item, change)
		end
	end

	function MT:RemoveItemSlot(Item, Amount, SlotIndex)
		if not Item then
			return
		end

		if not SlotIndex then
			SlotIndex = 1
		end

		local amtLeft = Amount

		if self.Data[2][Item] then
			if SlotIndex <= #self.Data[2][Item].List then
				if self.Data[2][Item].List[SlotIndex].Amount > 0 then
					if amtLeft and amtLeft >= self.Data[2][Item].List[SlotIndex].Amount then
						self.Data[2][Item].List[SlotIndex].Amount = 0
						amtLeft = amtLeft - self.Data[2][Item].List[SlotIndex].Amount
					else
						self.Data[2][Item].List[SlotIndex].Amount -= (amtLeft or 1)
						amtLeft = 0
						--print(slotObject)
					end
				end

				-- Remove the slot if the amount reaches zero
				if self.Data[2][Item].List[SlotIndex].Amount == 0 then 
					if self.Data[3] then
						for i, v in pairs(self.Data[3]) do
							--print(v)
							--print(slotObject)
							if v.Path and self.Data[2][v.Path[1]][v.Path[2]][v.Path[3]] == self.Data[2][Item].List[SlotIndex] then
								self.Data[3][i].Path = nil
								--print(self.Data[3][i])
							end
						end
					end
					if self.Data[1][Item].Durability then
						table.remove(self.Data[1][Item].Durability, SlotIndex)
					end
					table.remove(self.Data[2][Item].List, SlotIndex)
				end
			end
			--print(slotList)
		end

		self.Data[2] = not self.Gridlocked and removeGapsAndResetOrder(self.Data[2]) or self.Data[2]
		if Amount and Amount > 0 and self.Data[1][Item].Amount then
			local change = (self.Data[1][Item].Amount - Amount) - self.Data[1][Item].Amount
			self.Data[1][Item].Amount -= Amount or 1
			self.Changed:Fire(Item, change)
		else
			return
		end	
	end
	
	function MT:TransferItemBetweenInventories(Item, FromSlotIndex, ToSlotIndex, FromInventory, ToInventory, Merge)
		if not Item or not FromInventory or not ToInventory then
			return
		end
		
		--print("pre")
		--print(FromInventory.Data)
		--print(ToInventory.Data)
		FromSlotIndex = FromSlotIndex or 1

		--local targetSlotLoc = findSlotWithOrder(FromInventory.Data[2][Item].List, FromSlotIndex)
		-- Check if the item exists in the "from" inventory
		if FromInventory.Data[1][Item] and FromInventory.Data[1][Item].Amount > 0 --[[and [targetSlotLoc]] then
			-- Check if the "to" inventory has the item list, if not, create it
			if not ToInventory.Data[2][Item] then
				ToInventory.Data[2][Item] = {}
				ToInventory.Data[2][Item].List = {}
				ToInventory.Data[2][Item].Order = #ToInventory.Data[2] + 1
			end

			--print(FromSlotIndex)
			--print(FromInventory.Data[2][Item].List)

			--print(ToSlotIndex)
			--print(ToInventory.Data[2][Item].List)
			local ogSlot = FromInventory.Data[2][Item].List[FromSlotIndex]
			local ogAmount = ogSlot.Amount
			local ogDurability = (FromInventory.Data[1][Item].Durability and FromInventory.Data[1][Item].Durability[FromSlotIndex] or nil)

			--ToSlotIndex = ToSlotIndex or (#ToInventory.Data[2][Item].List + 1)

			--wait(2)
			--print("raft")
			--print(FromInventory.Data[2])
			FromInventory:RemoveItemSlot(Item, ogAmount, FromSlotIndex)
			if not ToSlotIndex then
				--print("autoing")
				ToInventory:AddItem(Item, ogAmount, ogDurability)
			else
				ToInventory:AddItemAtSlot(Item, ogAmount, ogDurability, ToSlotIndex, Merge)
			end
			--print("raft2")
			--print(FromInventory.Data[2])
		end	
		--print("aft")
		--print(FromInventory.Data)
		--print(ToInventory.Data)
	end
	
	function MT:RepositionItem(Item, FromSlotIndex, ToSlotIndex, Merge)
		--print(self.Data[2])
		--print(Item)
		--print(FromSlotIndex)
		--print(ToSlotIndex)
		--print(Merge)
		if not Item or not FromSlotIndex or not ToSlotIndex then
			return
		end

		if not self.Data[2][Item] or not self.Data[2][Item].List or not self.Data[2][Item].List[FromSlotIndex] then
			return
		end
	
		local stackable = true

		if itemInfo[Item] then
			stackable = itemInfo[Item].Stackable
		else
			return
		end
		
		local ogSlotObject = self.Data[2][Item].List[FromSlotIndex]

		local myData = self.Data

		local ogSlotLoc = ogSlotObject.Order

		-- dropped back onto its own slot, nothing to do (comparing Order to Order,
		-- NOT FromSlotIndex to ToSlotIndex -- FromSlotIndex is a raw List index while
		-- ToSlotIndex/ogSlotLoc are Order values, so those two are not directly comparable)
		if ogSlotLoc == ToSlotIndex then
			return
		end

		local targetSlotLoc = findSlotWithOrder(self.Data[2][Item].List, ToSlotIndex) -- for merging
		--print(ogSlotLoc)
		--print(self.Data[2][Item].List)
		--print(ToSlotIndex)
		--print(targetSlotLoc)
		
		if targetSlotLoc and targetSlotLoc >= FromSlotIndex then
			targetSlotLoc -= 1
		end
		
		-- remove it
		--myData[2][Item].List[FromSlotIndex] = ni
		
		if not self.Gridlocked then
			--print("shiftin")
			-- shift stuff above back
			for i, v in pairs(myData[2]) do
				for i2, slotObject in pairs(v.List) do
					print(ogSlotObject.Name)
					print(slotObject.Name)
					if slotObject ~= ogSlotObject and slotObject.Order and slotObject.Order >= ogSlotLoc then
						print("not equal")
						myData[2][i].List[i2].Order = myData[2][i].List[i2].Order - 1
					end
				end
			end
		end
		
		--print("step1")
		--print(myData[2])
		
		if Merge and stackable and targetSlotLoc then
			--print("merge")
			table.remove(myData[2][Item].List, FromSlotIndex)
			myData[2][Item].List[targetSlotLoc].Amount += (ogSlotObject.Amount or 1)
			--print("newAdd")
		else
			--local newItem = {}
			--newItem.Name = Item
			--newItem.Amount = slotObject.Amount
			--> shift everything else
			if not self.Gridlocked then
				--print("shiftin")
				for i, v in pairs(myData[2]) do
					for i2, slotObject in pairs(v.List) do
						if slotObject ~= myData[2][Item].List[FromSlotIndex] and slotObject.Order and slotObject.Order >= ToSlotIndex then
							myData[2][i].List[i2].Order = myData[2][i].List[i2].Order + 1
						end
					end
				end
			end
			--print("step2")
			--print(myData[2])
			--> put it as new
			--print(ToSlotIndex)
			myData[2][Item].List[FromSlotIndex].Order = ToSlotIndex
			--print(myData[2])
			self.Data[2] = not self.Gridlocked and removeGapsAndResetOrder(self.Data[2]) or self.Data[2]
			--table.insert(myData[2][Item].List, newItem)
			--print("step3")
			--print(myData[2])
		end
		--print(myData)
		self.Data = myData
		self.UIUpdated:Fire()
	end

	function MT:Swap(Item1, Item2, SlotIndex1, SlotIndex2)
		--print(Item1)
		--print(Item2)
		--print(SlotIndex1)
		--print(SlotIndex2)
		if not Item1 or not Item2 or not SlotIndex1 or not SlotIndex2 then
			return
		end

		if not self.Data[2][Item1] or not self.Data[2][Item2] or not self.Data[2][Item1].List or not self.Data[2][Item2].List or not self.Data[2][Item1].List[SlotIndex1] or not self.Data[2][Item2].List[SlotIndex2] then
			return
		end

		if not itemInfo[Item1] or not itemInfo[Item2] then
			return
		end

		local slotObject1 = self.Data[2][Item1].List[SlotIndex1]
		local slotObject2 = self.Data[2][Item2].List[SlotIndex2]
		
		local slotLoc1 = tonumber(slotObject2.Order)
		local slotLoc2 = tonumber(slotObject1.Order)

		local myData = self.Data

		myData[2][Item1].List[SlotIndex1].Order = slotLoc1
		myData[2][Item2].List[SlotIndex2].Order = slotLoc2

		self.Data = myData
		self.UIUpdated:Fire()
	end
	
	function MT:LowerDurability(Item, Amount, SlotIndex) -- lower item durability method
		if not Item or not itemInfo[Item] then
			return
		end

		if not SlotIndex then
			SlotIndex = 1
		end

		if not itemInfo[Item].Durability or not self.Data[1][Item].Durability or not self.Data[1][Item].Durability[SlotIndex] then
			return
		end
		local dchange = (self.Data[1][Item].Durability[SlotIndex] - Amount) - self.Data[1][Item].Durability[SlotIndex]
		

		if self.Data[1][Item].Durability[SlotIndex] then 
			self.Data[1][Item].Durability[SlotIndex] -= Amount or 1
		end
		
		if Amount and Amount > 0 then
			self.Changed:Fire(Item, dchange)
		end
		
		if self.Data[1][Item].Durability[SlotIndex] <= 0 then
			self:RemoveItemSlot(Item, 1, SlotIndex)
		end
	end
	
	function MT:FixDurability(Item, SlotIndex) -- fix item durability method
		if not Item or not itemInfo[Item] then
			return
		end

		if not SlotIndex then
			SlotIndex = 1
		end

		if not itemInfo[Item].Durability or not self.Data[1][Item].Durability or not self.Data[1][Item].Durability[SlotIndex] then
			return
		end

		local dchange = itemInfo[Item].Durability - (self.Data[1][Item].Durability[SlotIndex])
		

		if self.Data[1][Item].Durability[SlotIndex] then 
			self.Data[1][Item].Durability[SlotIndex] = itemInfo[Item].Durability
		end	
		
		self.Changed:Fire(Item, dchange)
	end
	
	function MT:Clear() -- clear inventory method
		for i, v in pairs(self.Data[1]) do
			if v > 0 then
				self.Changed:Fire(i, -(v))
			end
		end
		self.Data[1] = {}
		self.Data[2] = nil
	end

	function MT:Destroy() -- cleanup method
		if self.Changed then
			self.Changed:Destroy()
		end
		if self.UIUpdated then
			self.UIUpdated:Destroy()
		end
		self = nil
	end
	
	return MT
end


return Inventory