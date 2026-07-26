local PlayerService = game:GetService("Players")
local PlayerList = {}

local function AddPlayerToTable(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local PlayerVariables = {
		["Character"] = Character,
		["PreviousPosition"] = Vector3.new(),
		["CurrentPosition"] = Vector3.new(),
		["ReturnCFrame"] = CFrame.new(),
		["NetworkOwner"] = "Client",
		["Tickets"] = 0,
		["Flags"] = 0
	}

	table.insert(PlayerList, PlayerVariables)
end

local function RemovePlayerFromTable(Player)
	for index, plrval in pairs(PlayerList) do
		if plrval.Character == Player.Character then
			table.remove(PlayerList, index)
		end
	end
end

PlayerService.PlayerAdded:Connect(AddPlayerToTable)
PlayerService.PlayerRemoving:Connect(RemovePlayerFromTable)

while task.wait(1) do
	for index, plrval in pairs(PlayerList) do
		local HumanoidRootPart = plrval.Character.HumanoidRootPart
		local Humanoid = plrval.Character.Humanoid
		PlayerList[index]["CurrentPosition"] = HumanoidRootPart.Position

		if plrval.Flags < 5 then
			if plrval.NetworkOwner == "Server" then
				PlayerList[index]["NetworkOwner"] = "Client"
				plrval.Character.PrimaryPart:SetNetworkOwner(PlayerService:GetPlayerFromCharacter(plrval.Character))
			end

			if plrval.Tickets == 0 then
				PlayerList[index]["ReturnCFrame"] = HumanoidRootPart.CFrame

			elseif plrval.Tickets >= 3 then
				print("Too many Tickets, Return normal")
				PlayerList[index]["Tickets"] = 0
				PlayerList[index]["Flags"] += 1
				PlayerList[index]["NetworkOwner"] = "Server"

				plrval.Character.PrimaryPart:SetNetworkOwner(nil)
				HumanoidRootPart.CFrame = plrval.ReturnCFrame
			end

			if (plrval.PreviousPosition - PlayerList[index["CurrentPosition"]]).Magnitude > (Humanoid:GetAttribute("WalkSpeed")) and plrval.NetworkOwner == "Client" then
				print(plrval.Character, "is Overspeeding")
				PlayerList[index]["Tickets"] += 1

			else
				if plrval.Tickets > 0  then
					PlayerList[index]["Tickets"] -= 0.25
				end
			end

			PlayerList[index]["PreviousPosition"] = plrval.CurrentPosition

		else
			PlayerService:GetPlayerFromCharacter(plrval.Character):Kick("SpeedHacking")
			table.remove(PlayerList, index)
		end

	end
end