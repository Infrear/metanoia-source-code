-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local combatSettings = require(Storage.Info.CombatSettings)
local Importer = require(Storage.Importer)


return {
	["Longsword"] = function(char, tool)
		coroutine.wrap(function()
			--local HitEffect = Storage.Effects.Combat.HitEffect:Clone()
			--HitEffect.Parent = foundchar:FindFirstChild("UpperTorso")

			--HitEffect:Emit(1)
			--task.wait(2)
			--HitEffect:Destroy()
			local effect = Storage.Effects.Combat.LightningExplode.Attachment:Clone()
			effect.Parent = char:FindFirstChild("UpperTorso")
			for i, v in pairs(effect:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					--v.Color = ColorSequence.new(Color3.new(1, 0.5, 0))
					v:Emit(5)
				end
			end

			task.wait(2)
			effect:Destroy()
		end)()
	end,
}