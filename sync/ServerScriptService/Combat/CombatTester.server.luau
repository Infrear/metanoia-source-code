-- Services
local RPS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local PLRS = game:GetService("Players")

-- Dependancies
local SStorage = SS:WaitForChild("Storage")
local Storage = RPS:WaitForChild("ClientStorage")
local SCRP = workspace:WaitForChild("SCRIPTING")
local combatSettings = require(Storage.Info.CombatSettings)
local testPart = SCRP:WaitForChild("Activate")

local CombatSystem = SStorage.Classes.CombatSystem
local ClientSidePersonaSystem = Storage.Classes.PersonaClientSide
local PersonaData = require(ClientSidePersonaSystem.PersonaData)
local FighterClass = require(CombatSystem.Fighter)
local CombatManager = require(CombatSystem.CombatManager)

-- Local Variables
local con = nil

-- Local Functions
local function getStuff(plr)
end


-- Connections
con = testPart.Touched:Connect(function(hit)
	local char = hit.Parent
	local hum = char:FindFirstChild("Humanoid")

	if hum and char and PLRS:GetPlayerFromCharacter(char) then
		con:Disconnect()
		local plr = PLRS:GetPlayerFromCharacter(char) 
		
		-- initialize combatants using the SCRIPTING folder models
		local playerPersona = PersonaData.new("Angel")
		local playerFighter = FighterClass.new(char, {ActivePersona = playerPersona}, plr)

		-- assuming 'Fighter' model in workspace SCRIPTING folder is the enemy
		local enemyModels = {workspace.H, workspace.S2, SCRP:WaitForChild("Fighter")}
		local enemyPersonas = {
			{ActivePersona = PersonaData.new("Shadow", {ST=15, MA=6, EN=3, AG=5, LU=2}, nil, {"Agi", "Cleave"})}, 
			{ActivePersona = PersonaData.new("Shadow1", {ST=5, MA=13, EN=3, AG=2, LU=2}, nil, {"Agi", "Cleave"})},
			{ActivePersona = PersonaData.new("Shadow2", {ST=25, MA=3, EN=3, AG=2, LU=2}, nil, {"Agi", "Cleave"})}
		}
		local enemyFighters = {
			FighterClass.new(enemyModels[1], enemyPersonas[1]), 
			FighterClass.new(enemyModels[2], enemyPersonas[2]), 
			FighterClass.new(enemyModels[3], enemyPersonas[3])
		}

		CombatManager.InitializeBattle({
			PlayersInvolved = { -- for possible 2v2, 3v3, 4v4 or pvp implementation in the future
				[1] = {
					PlayerObject = plr,
					FighterObject = playerFighter,
				}
			},
			PlayerFighters = { -- anything controlled by any players
				[1] = playerFighter,
			},
			EnemyFighters = enemyFighters -- basically npcs
		})
	end
end)