--[[
	CombatStoryline
	-----------------
	Config-driven mid-fight dialogue -- runs directly through your existing NPC module
	(NPCM.runNPC), exactly like SceneDirector does for cutscenes. Meant for tutorial fights and
	story beats, not every normal encounter.

	Pass a config table in at battle start (see GlobalsServer.startBridgeCombat / CombatManager.
	InitializeBattle -- storylineConfig flows down through tab.StorylineConfig same as everything
	else in fightTable):

		local storyline = {
			Steps = {
				{
					Trigger = "OnStart",
					Speaker = "Timmy",              -- resolved against the fighter map passed to Init()
					Dialogue = "TimmyIntro1",        -- string name (npcIndex) OR a ModuleScript instance
					DisplayName = "Timmy",           -- optional, defaults to Speaker
				},
				{
					Trigger = "AfterRound", Round = 2,
					Speaker = "Angel", Dialogue = "AngelWarning",
				},
				{
					Trigger = "OnEvent", Event = "GolemEnraged",
					Speaker = "Golem", Dialogue = "GolemEnragedLine",
				},
				{
					Trigger = "OnEnd",
					Speaker = "Timmy", Dialogue = "TimmyOutro",
				},
			}
		}

	Usage from the client combat flow:

		CombatStoryline.Init(fightTable.StorylineConfig, fightersByName)  -- fightersByName: {Timmy = fighter.Instance, ...}
		CombatStoryline.OnBattleStart()
		CombatStoryline.OnRoundEnd(2)
		CombatStoryline.FireEvent("GolemEnraged")
		CombatStoryline.OnBattleEnd()

	Each step fires exactly once per battle (Init() resets that).

	Turn-flow integration: call CombatStoryline.WaitForClear() right before you'd normally open
	the skill/action menu -- it returns immediately if nothing's playing, or yields until NPCM
	has finished running the dialogue (player's clicked all the way through).
]]

local NPCM = require(script.Parent.Parent:WaitForChild("Interactables"):WaitForChild("NPCs"))

local CombatStoryline = {}
CombatStoryline.IsActive = false

local currentConfig = nil
local fightersByName = {} -- Speaker name -> fighter Instance, set by Init()
local firedSteps = {} -- set of step tables already fired, cleared on Init()

local WAIT_FOR_START_TIMEOUT = 2 -- safety cap in case runNPC rejects the call silently
local WAIT_FOR_END_TIMEOUT = 90  -- safety cap so a stuck dialogue can't softlock the fight forever

local function runStep(step)
	local speakerInstance = step.Speaker and fightersByName[step.Speaker] or nil
	local dialogueRef = step.Dialogue

	-- Dialogue can be given as a plain string (looked up in npcIndex, same as any overworld NPC)
	-- or as a direct ModuleScript reference, e.g. from a per-fight Dialogues folder you set up
	-- the same way SceneDirector scenes have their own Dialogues folder
	if step.DialoguesFolder and typeof(dialogueRef) == "string" then
		local found = step.DialoguesFolder:FindFirstChild(dialogueRef)
		if found then
			dialogueRef = found
		end
	end

	NPCM.runNPC(speakerInstance, dialogueRef, step.DisplayName or step.Speaker)

	-- runNPC sets NPCM.currentNPC synchronously if the call was accepted -- if it's still nil
	-- right after, the call got rejected (bad dialogue ref, already-running dialogue, etc), so
	-- there's nothing to wait on
	local started = false
	local waited = 0
	while waited < WAIT_FOR_START_TIMEOUT do
		if NPCM.currentNPC ~= nil then
			started = true
			break
		end
		waited += task.wait()
	end

	if not started then
		warn("[CombatStoryline] runNPC didn't start for step (Speaker=" .. tostring(step.Speaker) .. ", Dialogue=" .. tostring(step.Dialogue) .. ") -- skipping")
		return
	end

	waited = 0
	while NPCM.currentNPC ~= nil and waited < WAIT_FOR_END_TIMEOUT do
		task.wait(0.1)
		waited += 0.1
	end
end

local function playStep(step)
	CombatStoryline.IsActive = true
	runStep(step)
	CombatStoryline.IsActive = false
end

function CombatStoryline.Init(config, fighterMap)
	currentConfig = config
	fightersByName = fighterMap or {}
	firedSteps = {}
end

-- Generic firer -- matcherFn(step) -> bool decides which steps (of the given Trigger) fire
local function fireMatching(trigger, matcherFn)
	if not currentConfig or not currentConfig.Steps then return end

	for _, step in ipairs(currentConfig.Steps) do
		if step.Trigger == trigger and not firedSteps[step] then
			if (not matcherFn) or matcherFn(step) then
				firedSteps[step] = true
				playStep(step)
			end
		end
	end
end

function CombatStoryline.OnBattleStart()
	fireMatching("OnStart", nil)
end

function CombatStoryline.OnBattleEnd()
	fireMatching("OnEnd", nil)
end

function CombatStoryline.OnRoundEnd(roundNum)
	fireMatching("AfterRound", function(step) return step.Round == roundNum end)
end

function CombatStoryline.FireEvent(eventName)
	fireMatching("OnEvent", function(step) return step.Event == eventName end)
end

-- Yields until any currently-queued dialogue has been fully clicked through. Call this right
-- before opening the action-choice menu so the player can't pick a move mid-dialogue.
function CombatStoryline.WaitForClear()
	while CombatStoryline.IsActive do
		task.wait()
	end
end

function CombatStoryline.Cleanup()
	currentConfig = nil
	fightersByName = {}
	firedSteps = {}
	CombatStoryline.IsActive = false
end

return CombatStoryline
