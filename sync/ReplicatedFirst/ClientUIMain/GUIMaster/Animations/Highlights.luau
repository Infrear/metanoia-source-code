-- Services
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")
local DBS = game:GetService("Debris")

-- Dependencies
local plr = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local plrGUI = plr.PlayerGui
local mouse = plr:GetMouse()

local Storage = RPS:WaitForChild("ClientStorage")
local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings
--local BillboardUIS = Storage:WaitForChild("BillboardUIs")
--local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))

-- Initialization
local hlM = {}

-- Local Variables
local modelVals = {}
local hls = {}

-- Constants
local MAX_DIST_FOR_HIGHLIGHT = 125
local MAX_HIGHLIGHTS = 20

-- Local Functions
local function coundDict(dict)
	local c = 0
	for i, v in pairs(dict) do
		c += 1
	end
	return c
end

-- Global Functions
function hlM.CheckHighlights(hlPos)
	local canMake = true
	local dist = (char:GetPivot().Position - hlPos).Magnitude

	if dist <= MAX_DIST_FOR_HIGHLIGHT then
		if coundDict(hls) >= MAX_HIGHLIGHTS then
			local bads = {}

			for i, v in pairs(hls) do
				local dist2 = (char:GetPivot().Position - hlPos).Magnitude
				if dist2 >= dist then
					table.insert(bads, i)
				end
			end

			if #bads > 0 then
				for i, v in pairs(bads) do
					v:Destroy()
					hls[v] = nil
				end
				if coundDict(hls) >= MAX_HIGHLIGHTS then
					canMake = false
				end
			else
				canMake = false
			end
		end
	else
		canMake = false
	end

	return canMake
end

function hlM.SpawnHighlight(obj, otherValues, temp)
	if not obj then return end

	local pos = nil

	if obj:IsA("Model") then
		pos = obj:GetPivot().Position
	elseif obj:IsA("BasePart") then
		pos = obj.CFrame.Position
	else
		return
	end

	if not hlM.CheckHighlights(pos) then return end

	local highlight = Instance.new("Highlight")
	hls[highlight] = pos

	highlight.Destroying:Connect(function()
		hls[highlight] = nil
	end)

	for i, v in pairs(otherValues) do
		local success = pcall(function() 
			local t = highlight[i] 
		end) 

		if success then
			highlight[i] = v
		end
	end

	if obj then
		--highlight.Parent = obj
		highlight.Adornee = obj
	end

	highlight.Parent = workspace.PARTICLES

	if temp then
		DBS:AddItem(highlight, 10)
	end

	return highlight
end

return hlM
