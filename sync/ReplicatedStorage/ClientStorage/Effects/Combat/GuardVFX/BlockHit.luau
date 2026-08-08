-- Plays when a guarding fighter gets hit and the guard HOLDS (Fighter:TakeImpact returned "BLOCKED").
-- One-shot -- the persistent Shield-01 effect (GuardVFX.Default) keeps running underneath this the
-- whole time, this just layers a quick "impact absorbed" burst on top.
--
-- Params:
--   fighterInstance : Model -- the fighter who blocked the hit
return function(fighterInstance)
	local Utils = require(script.Parent.Utils)
	local template = game:GetService("ReplicatedStorage").ClientStorage.Effects.Combat.GuardParticles["Generic-Block-Hit"]

	local clone = Utils.AttachToFighter(template, fighterInstance)
	if not clone then return end

	Utils.EmitAndDestroy(clone, 20)
end
