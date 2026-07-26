-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local plr = game.Players.LocalPlayer
if not plr then
	odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
end
local ListenerEvents = Storage:WaitForChild("Events"):WaitForChild("QuestListeners")
local Importer = require(Storage.Importer)
local NPCs = workspace:WaitForChild("NPCS")


local Listeners = {
	["Item Listener"] = { -- later add support for multiple items
		["InitialCheck"] = function(myPlr, questInfo)
			return odm.PlayerData[myPlr].Data.Inventory.Data[1][questInfo.Object] and odm.PlayerData[myPlr].Data.Inventory.Data[1][questInfo.Object].Amount or 0
		end,

		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local plrToCheck, resource, finalAmt = table.unpack(wrapped)
			if plrToCheck == myPlr and questInfo.Object == resource then
				return finalAmt
			end
		end,

		["Event"] = ListenerEvents:WaitForChild("ResourceChanged")
	},

	["Resource Listener"] = {
		["InitialCheck"] = function(myPlr, oldQuest, questInfo)
			return oldQuest.Progress
		end,
		
		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local plrToCheck, resourceObj = table.unpack(wrapped)
			if plrToCheck == myPlr and oldQuest.Object == resourceObj.Name then
				return oldQuest.Progress + 1
			end
		end,
		

		["Event"] = ListenerEvents:WaitForChild("ResourceBroken")
	},

	["Build Listener"] = {
		["InitialCheck"] = function(myPlr, oldQuest, questInfo)
			return oldQuest.Progress
		end,

		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local action, plrToCheck, buildName, buildObj = table.unpack(wrapped)
			if plrToCheck == myPlr and questInfo.Object == buildName then
				if action == "built" then
					return oldQuest.Progress + 1
				elseif action == "destroyed" then
					return oldQuest.Progress - 1
				end
			end
		end,

		["Event"] = ListenerEvents:WaitForChild("ItemBuiltDestroyed")
	},

	["Item Collect Listener"] = {
		["InitialCheck"] = function(myPlr, oldQuest, questInfo)
			return oldQuest.Progress
		end,

		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local plrToCheck, item = table.unpack(wrapped)
			if plrToCheck == myPlr and table.find(questInfo.Goal, item) then
				--print("added "..item
				local prog = oldQuest.Progress
				table.insert(oldQuest.Progress, item)
				
				return prog
			end
		end,

		["Event"] = ListenerEvents:WaitForChild("ItemCollect")
	},
	
	["Action Listener"] = {
		["InitialCheck"] = function(myPlr, questInfo)
			return questInfo.Progress
		end,

		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local plrToCheck, item = table.unpack(wrapped)
			if plrToCheck == myPlr and table.find(questInfo.Goal, item) then
				--print("added "..item
				local prog = oldQuest.Progress
				table.insert(oldQuest.Progress, item)

				return prog
			end
		end,

		["Event"] = ListenerEvents:WaitForChild("Action")
	},
	["Location Listener"] = {
		["InitialCheck"] = function(myPlr, oldQuest, questInfo)
			return oldQuest.Progress
		end,

		["Checker"] = function(myPlr, oldQuest, questInfo, wrapped)
			local plrToCheck, locationName = table.unpack(wrapped)
			if plrToCheck == myPlr and questInfo.Object == locationName then
				return true
			end
		end,

		["Event"] = ListenerEvents:WaitForChild("LocationReached")
	},
}

local Quests = {
	["Strange Boy's Quest"] = {
		[1] = {
			Goal = true,
			Progress = false,
			Text = "Follow the strange boy",

			Object = "StrangeBoyMeetPoint", -- name your destination part/attribute this
			QuestListener = "Location Listener",

			TalkToComplete = true,
			NextConvo = "Quest Return 1",
		}
	},
}

table.freeze(Listeners)
table.freeze(Quests)

return {
	["Quests"] = Quests,
	["Listeners"] = Listeners
}