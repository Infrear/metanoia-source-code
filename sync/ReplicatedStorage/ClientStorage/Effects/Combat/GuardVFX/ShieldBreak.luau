-- Plays when a guarding fighter's guard BREAKS (Fighter:TakeImpact returned "GUARD_BREAK" -- a
-- weakness hit, or a hit big enough to shatter it outright). One-shot burst. The caller is
-- responsible for destroying/fading whatever persistent Shield-01 instance (from GuardVFX.Default)
-- was tracked for this fighter -- this module only plays the shatter burst itself.
--
-- Params:
--   fighterInstance : Model -- the fighter whose guard just broke
return function(fighterInstance)
	local Utils = require(script.Parent.Utils)
	local template = game:GetService("ReplicatedStorage").ClientStorage.Effects.Combat.GuardParticles["Shield-Break-01"]

	local clone = Utils.AttachToFighter(template, fighterInstance)
	if not clone then return end

	Utils.EmitAndDestroy(clone, 25)
end
