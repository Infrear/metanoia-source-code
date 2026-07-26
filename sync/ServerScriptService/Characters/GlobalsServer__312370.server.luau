-- Services
local UIS = game:GetService("UserInputService")
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")

-- Constants 
local STAMINA_REGEN_COOLOFF = 2.5

-- Dependancies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local Storage = RPS:WaitForChild("ClientStorage")
local NPCs = workspace:WaitForChild("NPCS")
local questRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("QuestRem")
local npcRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("NPCRem")
local questIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))
local npcActionIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCActionIndex"))
local npcIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCIndex"))

-- Connections
questRem.OnServerEvent:Connect(function(plr, action, npcName, actionText --[[this is for actions or direct quest text]])
	if not odm.PlayerData then
		repeat wait() until odm.PlayerData -- wait for data 
	end
	if not odm.PlayerData[plr] then
		repeat wait() until odm.PlayerData[plr] ~= nil -- wait for data
	end
	
	local npcInfo = npcIndex[npcName]
	local questInfo = nil --directQuestInfo
	if (not questInfo) and (npcInfo and npcInfo.QuestSequence) then -- when you have time, SECURITY MEASURE: CHECK IF ALL PREQUESTS WERE ACTUALLY DONE, also check for proximity to said npc
		questInfo = not odm.PlayerData[plr].Data.Global.Data.NPCData[npcName] and npcInfo.QuestSequence[1] or npcInfo.QuestSequence[odm.PlayerData[plr].Data.Global.Data.NPCData[npcName].QuestSequenceIndex]
	end
	
	if questInfo and action == "questRequest" then
		odm.PlayerData[plr].Data.Global:AddQuest(questInfo, npcName)
		--questRem:FireClient(plr, odm.PlayerData[plr].Data) -- doesn't my class's code do this alr?
	elseif action == "questRemove" then
		if odm.PlayerData[plr].Data.Global.Data.Quests.Current[questInfo and questInfo.Text or actionText] then -- warning?
			--odm.PlayerData[plr].Data.Global.Data.Quests.Current[questInfo and questInfo.Text or actionText].TalkToComplete = false
			local completed = nil
			if actionText then
				completed = false
			end
			odm.PlayerData[plr].Data.Global:RemoveQuest(questInfo and questInfo.Text or actionText, completed, true)
		end
	elseif action == "actionRequest" then -- prolly some sorta check here too
		npcActionIndex.Actions[actionText](plr)
	end
end)

npcRem.OnServerEvent:Connect(function(plr, action, npcName, nextDialogue)
	if not odm.PlayerData then
		repeat wait() until odm.PlayerData -- wait for data 
	end
	if not odm.PlayerData[plr] then
		repeat wait() until odm.PlayerData[plr] ~= nil -- wait for data
	end
	
	if action == "start" then
		plr.Character:SetAttribute("Chatting", npcName)
	else
		odm.PlayerData[plr].Data.Global:UpdateNPC(npcName, nextDialogue)
		plr.Character:SetAttribute("Chatting", nil)
	end
end)

--
for i, v in pairs(NPCs:GetChildren()) do
	if v:FindFirstChild("NPCBasicTrack") and v:WaitForChild("Humanoid", 10) then
		local trac = v:FindFirstChild("NPCBasicTrack")
		local animtrac = v:FindFirstChild("Humanoid"):FindFirstChild("Animator"):LoadAnimation(trac)
		animtrac:Play()
	end
end
