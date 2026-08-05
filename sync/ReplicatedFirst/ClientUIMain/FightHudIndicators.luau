--[[
	FightHudIndicators
	--------------------
	Umbrella module for all the "extra" in-combat HUD pieces that sit on top of the core
	skills/action UI (which lives in CombatOverlays / GUIMaster, and is unaffected by this):

	.CombatStoryline     -- config-driven mid-fight dialogue (tutorial-fight banter, click to proceed)
	.BattleMessage       -- the passive "Nice! The enemy's down!" style top-right banner + portrait
	.AbilityAnnouncement -- big shake-effect RichText panel for ability/event callouts (skeleton for now)
	.HealthTray          -- party health bar tray (player + allies)

	Nothing in here touches DataManager or any server-side system -- purely client-side visuals,
	driven by data the combat code already has (fightTable / fighter tables) and fired by whatever
	client code wants to trigger a beat (InitiateBattle, turn-end, custom events, etc).
]]

local FightHudIndicators = {}

FightHudIndicators.CombatStoryline = require(script:WaitForChild("CombatStoryline"))
FightHudIndicators.BattleMessage = require(script:WaitForChild("BattleMessage"))
FightHudIndicators.AbilityAnnouncement = require(script:WaitForChild("AbilityAnnouncement"))
FightHudIndicators.HealthTray = require(script:WaitForChild("HealthTray"))

return FightHudIndicators
