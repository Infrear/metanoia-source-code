-- Guard-up VFX -- plays while a fighter's Guarding flag is active. Persistent/looping (not a one-shot
-- burst), welded to the fighter so it follows them, since guard lasts until their next turn and they
-- might shift around (idle sway, etc.) in the meantime.
--
-- Returns the spawned instance so the caller can track and later clean it up (either faded out
-- normally when guard ends, or destroyed abruptly when GuardVFX.ShieldBreak plays).
--
-- Params:
--   fighterInstance : Model -- the guarding fighter's rig
return function(fighterInstance)
	local Utils = require(script.Parent.Utils)
	local template = game:GetService("ReplicatedStorage").ClientStorage.Effects.Combat.GuardParticles["Shield-01"]

	local clone = Utils.AttachToFighter(template, fighterInstance, nil, true)
	if not clone then return nil end

	Utils.SetLooping(clone, true)
	for _, e in ipairs(Utils.GetAllEmitters(clone)) do
		e:Emit(e:GetAttribute("EmitCount") or 15)
	end

	return clone
end
