-- Services
local Camera = workspace.CurrentCamera
local Replicated = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

-- Assets
local CameraShaker = require(Replicated.ClientStorage.Classes.BaseClasses.CameraShaker)

-- Functions
local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(CF)
	Camera.CFrame = Camera.CFrame * CF
end)

local function PlaySound(Id, Volume, Parent, Duration)
	local s = Instance.new('Sound')
	s.SoundId = Id
	s.Volume = Volume
	s.Parent = Parent
	s:Play()
	Debris:AddItem(s, Duration or 1)
	return s
end

CamShake:Start()

return 
	function(...)

	local Parameters = {...}
end
