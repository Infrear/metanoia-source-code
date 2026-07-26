-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")

-- Dependancies
local plr = PLRS.LocalPlayer

local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)
local NPCs = workspace:WaitForChild("NPCS")
local QuestIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))
--local NPCActionIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCActionIndex"))

local plrName = plr and plr.DisplayName or "[player]"

local tab = {
	["TooManyQuestsDefaultDialouge"] = -- if you make a dialouge called "2manyquests" for an npc, it can have its own custom too many quests dialouge
		{
			[1] = {
				Text = "I'm sorry, but you seem to be a bit occupied right now. Come back later!",
			}
		},
}

for i, v in pairs(script:GetChildren()) do
	if v:IsA("ModuleScript") then
		tab[v.Name] = require(v)
	end
end

return tab