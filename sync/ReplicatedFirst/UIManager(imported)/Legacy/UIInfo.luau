---- Services
--local RPS = game:GetService("ReplicatedStorage")
--local TS = game:GetService("TweenService")

---- Dependancies
--local Storage = RPS:WaitForChild("ClientStorage")

--local plr = game.Players.LocalPlayer
--repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
--local hum = char:WaitForChild("Humanoid")

---- Initialization
--local info = {}

---- Global Variables
--info.uis = {}
--info.cons = {}

---- Local Functions

--local function refresh()
--	-- setup mains
--	info.playerGui = plr:WaitForChild("PlayerGui")
	
--	-- setup connections
--	table.clear(info.cons)
--	local oldcons = info.cons
--	for i, v in pairs(oldcons) do
--		table.insert(info.cons, 
--			v.Event,
--			v.Function,
--			v.
--		)
--	end
	
--	-- setup uis
--	table.clear(info.uis)
--	for i, v in pairs(info.playerGui:GetChildren()) do
--		info.uis[v.Name:gsub("^%l", string.upper)] = v
--	end
	
--	--
--end


--local function bindConnection()
	
--end

--local function unbindConnection()

--end

---- Connections
--plr.CharacterAdded:Connect(refresh)

---- Loose Threads
--refresh()

--return info