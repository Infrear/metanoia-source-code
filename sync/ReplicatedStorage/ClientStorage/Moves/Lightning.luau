local l = require(game:GetService("ReplicatedStorage").ClientStorage.Modules["Open Source"].VFX.Templates.Abilities.Lightning) 

return function(attackParams)
	local cf = attackParams.TargetCFrame
	local physicalModel = attackParams.TargetModel
	l(cf)
end
