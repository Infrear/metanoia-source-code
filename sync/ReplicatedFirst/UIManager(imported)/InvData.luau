-- Dependancies 
local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character

local playerGUI = plr:WaitForChild("PlayerGui")
local ev = playerGUI:WaitForChild("UIManager"):WaitForChild("Events"):WaitForChild("UpdInv")

-- Local Variables
local currentData

-- Initialization
local invData = {}

-- Global Functions
function invData.getData()
	return currentData
end

-- Connections
ev.Event:Connect(function(Data)
	--print(Data)
	currentData = Data
end)

return invData