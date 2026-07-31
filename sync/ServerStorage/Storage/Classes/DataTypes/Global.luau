-- Services
local RPS = game:GetService("ReplicatedStorage")

-- Dependancies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local Storage = RPS:WaitForChild("ClientStorage")

-- Dependancies
local itemInfo = require(Storage:WaitForChild("Info"):WaitForChild("ItemInfo"))
local questIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))
local npcIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCIndex"))

-- Initialization
local Global = {}
Global.__index = Global 

-- Private 
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

local function checkForNPCQuest(book, npcInfo)
	if not npcInfo.QuestSequence then return end
	for i, page in pairs(npcInfo.QuestSequence) do
		for i2, v2 in pairs(book) do
			if v2.Text == page.Text then
				return page.Text
			end
		end
	end
end

local function tableSatisfies(progressTable, goalTable)
	for i, v in pairs(goalTable) do
		if not table.find(progressTable, v) then
			return false
		end
	end
	return true
end

-- Public Functions
function Global.new(Player, DataClass, BaseGlobal) -- constructor function.
	
	local MT = setmetatable({
	
	}, Global)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass}) -- This will wrap the new MT we created.
	-- Because we wrapped the new MT with a new MT we setup an index call to check MT and DataClass for functions. 

	-- moved data setting down here
	MT.BaseData = odm.GlobalFunctions.deepCopy(BaseGlobal);
	MT.Data = MT.Data or MT.BaseData
	--MT.Player = Player -- this might be problematic later
	
	-- changed
	MT.Changed = Instance.new("BindableEvent")
	MT.Connections = {}
	--MT.UIUpdated = Instance.new("BindableEvent")

	function MT:UpdateNPC(NpcName, NewBehavior, NewQuestInfo, Completed) -- update npc next talk data method
		if not NpcName then return end

		if not self.Data.NPCData[NpcName] then
			self.Data.NPCData[NpcName] = {
				Behavior = NewBehavior or "First", -- cant tell if this is gonna be problematic later or nah
				QuestSequenceIndex = 1
			}
		elseif NewBehavior then
			self.Data.NPCData[NpcName].Behavior = NewBehavior
			--self.Data.NPCData[NpcName].QuestSequenceIndex += 1
		end
		--print(NewBehavior)
		--print(self.Data.NPCData)
		if NewQuestInfo then
			self:AddQuest(NewQuestInfo, NpcName)
		end
		
		local hasNPCQuest = checkForNPCQuest(self.Data.Quests.Current, npcIndex[NpcName])
		if hasNPCQuest then
			if (typeof(self.Data.Quests.Current[hasNPCQuest].Progress) == 'number') and (self.Data.Quests.Current[hasNPCQuest].Progress >= self.Data.Quests.Current[hasNPCQuest].Goal) then
				MT:RemoveQuest(hasNPCQuest, true)
			elseif (typeof(self.Data.Quests.Current[hasNPCQuest].Progress) == 'boolean') and (self.Data.Quests.Current[hasNPCQuest].Progress == self.Data.Quests.Current[hasNPCQuest].Goal) then
				MT:RemoveQuest(hasNPCQuest, true)
			end
		end
		
		self.Changed:Fire("NPCs", NpcName, {NewBehavior, NewQuestInfo, Completed})
	end
	
	function MT:AddQuest(QuestInfo, NPCSource) -- add quest method
		--print(QuestInfo)
		--print(self.Data)
		if not QuestInfo or self.Data.Quests.Current[QuestInfo.Text] or odm.GlobalFunctions.countDict(self.Data.Quests.Current) >= 2 then return end
		print(QuestInfo)
		self.Data.Quests.Current[QuestInfo.Text] = odm.GlobalFunctions.deepCopy(QuestInfo)
		print(self.Data.Quests.Current[QuestInfo.Text])
		self.Data.Quests.Current[QuestInfo.Text].NPCSource = NPCSource
		
		-- setup the listener
		self:UpdateQuest(QuestInfo.Text, questIndex.Listeners[QuestInfo.QuestListener].InitialCheck(Player, self.Data.Quests.Current[QuestInfo.Text], QuestInfo))
		
		self.Connections[QuestInfo.Text] = questIndex.Listeners[QuestInfo.QuestListener].Event.Event:Connect(function(...)
			--print(Player)
			--print(QuestInfo)
			--print(...)
			self:UpdateQuest(QuestInfo.Text, questIndex.Listeners[QuestInfo.QuestListener].Checker(Player, self.Data.Quests.Current[QuestInfo.Text], QuestInfo, {...}))
		end)
		
		self.Changed:Fire("Quests", "Add", QuestInfo)
		--print(self.Data)
		--self.UIUpdated:Fire()
	end

	function MT:UpdateQuest(QuestText, Progress) -- update quest progress method
		if not QuestText or not Progress or not self.Data.Quests.Current[QuestText] then return end

		self.Data.Quests.Current[QuestText].Progress = Progress

		self.Changed:Fire("Quests", "Update", self.Data.Quests.Current[QuestText])

		if (typeof(self.Data.Quests.Current[QuestText].Progress) == 'number') and (self.Data.Quests.Current[QuestText].Progress >= self.Data.Quests.Current[QuestText].Goal) then
			MT:RemoveQuest(QuestText, true, false)
		elseif (typeof(self.Data.Quests.Current[QuestText].Progress) == 'boolean') and (self.Data.Quests.Current[QuestText].Progress == self.Data.Quests.Current[QuestText].Goal) then
			MT:RemoveQuest(QuestText, true, false)
		elseif (typeof(self.Data.Quests.Current[QuestText].Progress) == 'table') and (tableSatisfies(self.Data.Quests.Current[QuestText].Progress, self.Data.Quests.Current[QuestText].Goal)) then
			MT:RemoveQuest(QuestText, true, false)
		end
	end
	
	function MT:RemoveQuest(QuestText, Completed, talking) -- remove quest method, (false means a quit)
		if not QuestText or not self.Data.Quests.Current[QuestText] then return end

		local NPCSource = self.Data.Quests.Current[QuestText].NPCSource

		if self.Connections[QuestText] then
			self.Connections[QuestText]:Disconnect()
			self.Connections[QuestText] = nil
		end
		
		if Completed ~= false then
			if (typeof(self.Data.Quests.Current[QuestText].Progress) == 'number') and (self.Data.Quests.Current[QuestText].Progress >= self.Data.Quests.Current[QuestText].Goal) then
				Completed = true
			elseif (typeof(self.Data.Quests.Current[QuestText].Progress) == 'boolean') and (self.Data.Quests.Current[QuestText].Progress == self.Data.Quests.Current[QuestText].Goal) then
				Completed = true
			elseif (typeof(self.Data.Quests.Current[QuestText].Progress) == 'table') and (tableSatisfies(self.Data.Quests.Current[QuestText].Progress,  self.Data.Quests.Current[QuestText].Goal)) then
				Completed = true
			end
		else
			if NPCSource then
				self.Data.NPCData[NPCSource] = nil
			end
		end

		
		if Completed then
			if self.Data.NPCData[NPCSource] and self.Data.Quests.Current[QuestText].NextConvo then
				self.Data.NPCData[NPCSource].Behavior = self.Data.Quests.Current[QuestText].NextConvo
			end
			if self.Data.Quests.Current[QuestText].TalkToComplete and not talking then
				return
			end
		end

		self.Changed:Fire("Quests", "Remove", self.Data.Quests.Current[QuestText])--, Completed)
		self.Data.Quests.Current[QuestText] = nil

		if Completed then
			local rewardfn = npcIndex[NPCSource].QuestSequence[self.Data.NPCData[NPCSource].QuestSequenceIndex].RewardFcn
			
			if not self.Data.Quests.Completed[QuestText] then
				self.Data.Quests.Completed[QuestText] = {
					CompletedTimes = 1
				}
			else
				self.Data.Quests.Completed[QuestText].CompletedTimes += 1
			end
			if NPCSource then
				self.Data.NPCData[NPCSource].QuestSequenceIndex += 1
			end
			if rewardfn then
				rewardfn(Player, NPCSource)
			end
			--print(self.Data.Quests.Completed)
		end

		--self.UIUpdated:Fire()
	end


	function MT:Destroy() -- cleanup method
		if self.Changed then
			self.Changed:Destroy()
		end
		if self.UIUpdated then
			self.UIUpdated:Destroy()
		end
		for i, v in pairs(self.Connections) do
			if v then
				v:Disconnect()
			end
		end
		self.Connections = {}
		self = nil
	end
	
	return MT
end


return Global
