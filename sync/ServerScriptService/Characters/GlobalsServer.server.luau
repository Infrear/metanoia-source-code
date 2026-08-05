	-- Services
local UIS = game:GetService("UserInputService")
local RPS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")

-- Constants 
local STAMINA_REGEN_COOLOFF = 2.5

-- Dependancies
local odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
local Storage = RPS:WaitForChild("ClientStorage")
local Events = Storage:WaitForChild("Events")
local NPCs = workspace:WaitForChild("NPCS")
local questRem = Events:WaitForChild("Remotes"):WaitForChild("QuestRem")
local questverifyRem = Events:WaitForChild("Remotes"):WaitForChild("QuestVerifyRem")
local npcRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("NPCRem")
local questIndex = require(Storage:WaitForChild("Info"):WaitForChild("QuestIndex"))
local npcActionIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCActionIndex"))
local npcIndex = require(Storage:WaitForChild("Info"):WaitForChild("NPCIndex"))

local ListenerEvents = Events:WaitForChild("QuestListeners")

-- Local Functions
local function startBridgeCombat(plr)
	local CombatManager = require(SS.Storage.Classes.CombatSystem.CombatManager)
	local Fighter = require(SS.Storage.Classes.CombatSystem.Fighter)
	local PersonaData = require(Storage.Classes.PersonaClientSide.PersonaData)
	
	-- prepare player fighter
	local plrPersona = PersonaData.new("Angel")
	local plrFighter = Fighter.new(plr.Character, {ActivePersona = plrPersona}, plr)
	
	-- prepare timmy fighter (Server passes string, Client renders)
	local timmyPersona = PersonaData.new("Balloon")
	local timmyFighter = Fighter.new("Timmy", {ActivePersona = timmyPersona}, nil) 
	timmyFighter.IsNPC = true 
	
	-- prepare golem fighters
	local enemyCount = 3 
	local golems = {}

	for i = 1, enemyCount do
		local golemPersona = PersonaData.new("Golem")
		local golemFighter = Fighter.new("Golem", {ActivePersona = golemPersona}, nil)
		golemFighter.IsNPC = true
		table.insert(golems, golemFighter)
	end
	
	local splitParticipants = {
		PlayersInvolved = {{PlayerObject = plr, FighterObject = plrFighter}},
		PlayerFighters = {plrFighter, timmyFighter},
		EnemyFighters = golems
	}
	
	-- The Formations will be calculated inside InitializeBattle
	CombatManager.InitializeBattle(splitParticipants, plr.Character:GetPivot())
end

-- (Removed getFormationOffsets as FormationCalculator handles this now)

-- Connections
questRem.OnServerEvent:Connect(function(plr, action, npcName, actionText --[[this is for actions or direct quest text]], extraParams)
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

	--------------- MAIN REMOTES
	if action == "questRequest" then
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
			
			if questInfo and questInfo.Text == "Follow the strange boy" then
				startBridgeCombat(plr)
			end
		end
	elseif action == "actionRequest" and npcActionIndex.Actions[actionText] then -- prolly some sorta check here too
		npcActionIndex.Actions[actionText](plr, table.unpack(extraParams))
	end
end)

questverifyRem.OnServerEvent:Connect(function(plr, action, ...)
	if action == "locationReached" then
		local char = plr.Character
		local npcName, destinationName = ...
		local destinationPart = workspace.SCRIPTING.LOCATIONS:FindFirstChild(destinationName)
		if destinationPart and plr.Character then
			local dist = (char:GetPivot().Position - destinationPart.Position).Magnitude
			if dist <= 10 then -- server-side sanity check, don't just trust the client's claim
				ListenerEvents.LocationReached:Fire(plr, destinationName)
				
				local qCurrent = odm.PlayerData[plr].Data.Global.Data.Quests.Current
				if qCurrent["Follow the strange boy"] and destinationName == "StrangeBoyMeetPoint" then
					odm.PlayerData[plr].Data.Global:RemoveQuest("Follow the strange boy", nil, true)
					startBridgeCombat(plr)
				end
			end
		end
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


for i, npc in pairs(NPCs:GetChildren()) do 
	local hum = npc:WaitForChild("Humanoid", 10)
	if hum then
		for i, v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
			if v ~= Enum.HumanoidStateType.None then
				hum:SetStateEnabled(v, false)
			end
		end
		hum.EvaluateStateMachine = false
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end
