-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local DBS = game:GetService("Debris")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Importer = require(Storage.Importer)

local dependencies = {}

for i, v in pairs(script:GetChildren()) do
	dependencies[v.Name] = (require(v))
end

return dependencies
