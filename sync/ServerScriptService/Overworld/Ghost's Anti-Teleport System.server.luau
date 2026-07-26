local playerList = {} --Ignore this, its just a holder for player data.
local maxDistance = 40 --The max distance a player can move in a given interval
local interval = 1 --Time in seconds between position checks (I would not make this much lower than 1)
local kickMessage = "Unstable Connection Detected." --The message a player will see when they are kicked.
local correctedViolations = 3 --The game will try to teleport a player back to their last valid location this many times before kicking them.
local maxTableEntries = 100 --The max number of entries in the table before the game tries to clean it.
local scaleWithWalkSpeed = true --Controls if the anti-exploit will factor in walkspeed into its equations
local testing = true --If you want to adjust the values to fit your game, you can turn this on to get extra info from this script
local antiFling = true --Turn this off if you do not want the code to attempt to prevent flinging

--[[                             I WOULD NOT RECOMMEND MESSING WITH ANYTHING BELOW THIS MESSAGE                             ]]--


--Check that security is good.
if script:IsDescendantOf(game:GetService("ServerScriptService")) == false then warn("This script should not be placed outside of ServerScriptService, it can be put in a folder or something as long as that folder is in ServerScriptService.") script.Parent = game:GetService("ServerScriptService") end

--this is a deep copy function that also removes nil entries.
local function removeNilEntries(tab)
	local newTab = {}
	--go through table entries
	for i,v in pairs(tab) do
		--check if we need to copy or deep copy
		if typeof(v) == "table" then
			--deep copy
			newTab[i] = removeNilEntries(v)
		else
			if v ~= nil then
				--copy
				newTab[i] = v
			end
		end
	end
	--return the new cleaner table
	return newTab
end

--add player to tracking list on join
game.Players.PlayerAdded:Connect(function(plr)
	--wait for character to exist
	repeat task.wait(1) until plr.Character ~= nil and plr.Character.Parent == game.Workspace
	--create entry at players userid
	playerList[plr.UserId] = {
		--contain a player reference, their spawned position, the time this position was taken, there exempt from tping status,
		--the number of correction attempts, and the time of the last correction
		player = plr,
		LastPosition = plr.Character:WaitForChild("HumanoidRootPart").Position,
		LastTime = os.time(),
		exempt = false,
		corrections = 0,
		timeOfLastCorrection = os.time(),
		lastStablePosition = plr.Character:WaitForChild("HumanoidRootPart").Position,
		localTolerance = 1,
		lastLocalTolerance = 1,
		oldWalkSpeed = plr.Character.Humanoid.WalkSpeed,
		connections = {
			--create a connection that prevents dying from being detected as teleporting (respawn)
			plr.Character.Humanoid.Died:Connect(function()
				playerList[plr.UserId].exempt = true
			end),
			
			--connection to refresh the other connection on respawn and unexempt a player from detection.
			plr.CharacterAdded:Connect(function(char)
				--yeet the old connection
				playerList[plr.UserId].ConnectionA:Disconnect()
				--create a new connection that exempts a player from tp detection on death
				playerList[plr.UserId].ConnectionA = char:WaitForChild("Humanoid").Died:Connect(function() 
					playerList[plr.UserId].exempt = true
				end)
				--wait for player to be in workspace
				repeat wait(.1) until plr.Character.Parent == workspace.CHARACTERS
				--Update respawned position
				playerList[plr.UserId].LastPosition = plr.Character:WaitForChild("HumanoidRootPart").Position
				--unexempt player
				playerList[plr.UserId].exempt = false
			end)
		}
	}
end)

--stop tracking a player that leaves
game.Players.PlayerRemoving:Connect(function(plr)
	--Clean up out connections and clean up our table
	if playerList[plr.UserId] then
		for i, v in pairs(playerList[plr.UserId].connections) do
			v:Disconnect()
		end
		playerList[plr.UserId] = nil
	end
end)

--Toggle function
function doToggle(player)	
	--Check that player is valid
	assert(player, "Player argument was nil.")
	assert(player.ClassName == "Player", "Player argument was "..player.ClassName.." expected Player.")
	print("Toggled")
	--Do toggle
	playerList[player.UserId].exempt = not playerList[player.UserId].exempt
	--Check if we toggled it off
	if playerList[player.UserId].exempt == false then
		--Incase we are yielding, better not error the calling code.
		local s,f = pcall(function()
			--Check if they are alive
			if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character.Humanoid.Health > 0 then
				--Update to their current location
				playerList[player.UserId].LastPosition = player.Character.HumanoidRootPart.Position
				playerList[player.UserId].LastTime = os.time()
			end
		end)
	end

	return playerList[player.UserId].exempt
end

--update individual players max limits with this bad boi
function updateLocalTolerance(player, newTolerance)
	--We will store the old one to return later, in case someone needs to remember the old tolerance for some reason.
	local oldTolerance = playerList[player.UserId].localTolerance
	playerList[player.UserId].localTolerance = newTolerance
	return oldTolerance
end

-- have a vehicle, (a model that you can get the cframe with model:GetPivot) and add a check for the track distance from the vehicle 
function setRelative(player, model)
	-- Ensure the model and player are valid
	assert(player, "Player argument was nil.")
	assert(model and typeof(model.GetPivot) == "function", "Model argument was invalid or missing GetPivot function.")

	local playerData = playerList[player.UserId]
	if not playerData then
		warn("Player is not being tracked.")
		return
	end

	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("Player does not have a HumanoidRootPart.")
		return
	end

	-- Get the model's pivot position
	local modelPivot = model:GetPivot().Position

	-- Calculate the relative position
	local relativePosition = player.Character:GetPivot().Position - modelPivot

	-- Update player data with the relative position
	playerData.lastRelativePosition = relativePosition
	playerData.lastRelativeTime = os.time()

	-- Adjust the tracking logic for relative motion
	playerData.lastStableRelativePosition = relativePosition
	playerData.relativeModel = model
end

function unlinkVehicle(player)
	local playerInfo = playerList[player.UserId] -- Assuming playerList is indexed by UserId
	if playerInfo then
		-- Unlink the relative model
		playerInfo.relativeModel = nil

		-- Update the last position to the current world position
		if playerInfo.player.Character and playerInfo.player.Character:FindFirstChild("HumanoidRootPart") then
			playerInfo.LastPosition = playerInfo.player.Character.HumanoidRootPart.Position
		end

		if testing then
			print("Unlinked vehicle model for player: " .. player.Name)
		end
	else
		warn("Player info not found for: " .. player.Name)
	end
end

--Handle toggle requests without yield
script:WaitForChild("Toggle").Event:Connect(function(player)
	doToggle(player)
end)

--Handle relativeobj requests
script:WaitForChild("SetRelative").Event:Connect(function(action, plr, model)
	if action then
		setRelative(plr, model)
	else
		unlinkVehicle(plr)
	end
end)

--Handle toggle requests with yield
script:WaitForChild("ToggleWithYield").OnInvoke = doToggle

--Handle tolerance requests
script:WaitForChild("Tolerance").OnInvoke = updateLocalTolerance


--main loop
while task.wait(interval) do
	--Check how big our table has gotten
	if #playerList > maxTableEntries then
		--Remove all the dead table entries
		playerList = removeNilEntries(playerList)
	end
	--go through all players
	for index, playerInfo in pairs(playerList) do
		-- Use pcall to prevent errors from breaking the loop
		local success, errorMessage = pcall(function()
			if playerInfo and not playerInfo.exempt then
				local character = playerInfo.player.Character
				if not character or not character:FindFirstChild("HumanoidRootPart") then return end

				local rootPart = character.HumanoidRootPart
				local humanoid = character:FindFirstChild("Humanoid")
				local relativeModel = playerInfo.relativeModel

				-- Determine the current position (relative or absolute)
				local currentPosition
				if relativeModel and typeof(relativeModel.GetPivot) == "function" then
					local modelPivot = relativeModel:GetPivot().Position
					currentPosition = rootPart.Position - modelPivot
				else
					currentPosition = rootPart.Position
				end

				-- Calculate movement
				local movementVector = currentPosition - (playerInfo.LastPosition or currentPosition)
				local passedTime = os.time() - playerInfo.LastTime

				if movementVector.magnitude > 1 then
					-- Tolerance calculations
					playerInfo.oldWalkSpeed = math.max(playerInfo.oldWalkSpeed, humanoid.WalkSpeed)
					local tolerance = scaleWithWalkSpeed and playerInfo.oldWalkSpeed / 16 or 1
					local playerTolerance = math.max(playerInfo.lastLocalTolerance, playerInfo.localTolerance)
					playerInfo.lastLocalTolerance = playerInfo.localTolerance

					-- Check for violations
					if movementVector.magnitude > maxDistance * passedTime * tolerance * playerTolerance then
						-- Fall/rise detection
						if movementVector.magnitude * 0.66 > math.abs(movementVector.Y) then
							-- Mostly horizontal movement
							if playerInfo.corrections < correctedViolations then
								playerInfo.corrections += 1
								-- Correct player position
								if relativeModel then
									local modelPivot = relativeModel:GetPivot().Position
									character:SetPrimaryPartCFrame(CFrame.new(modelPivot + playerInfo.lastStableRelativePosition))
								else
									character:SetPrimaryPartCFrame(CFrame.new(playerInfo.lastStablePosition))
								end

								if antiFling then
									rootPart.AssemblyLinearVelocity = Vector3.zero
								end

								if testing then
									warn("Violation of "..movementVector.magnitude.." by "..playerInfo.player.Name.." Max Movement: "..(maxDistance*passedTime*tolerance*playerTolerance))
								end
							else
								-- Kick player for excessive violations
								playerInfo.player:Kick(kickMessage)
							end
						else
							-- Update last position for vertical movements
							playerInfo.LastPosition = currentPosition
							playerInfo.LastTime = os.time()
							if testing then
								warn("A fall/rise was detected for "..playerInfo.player.Name)
							end
						end
					else
						-- Valid movement, update positions and timings
						playerInfo.LastPosition = currentPosition
						playerInfo.LastTime = os.time()
						playerInfo.oldWalkSpeed = humanoid.WalkSpeed

						-- Update stable position
						if humanoid.FloorMaterial ~= Enum.Material.Air then
							if relativeModel then
								playerInfo.lastStableRelativePosition = currentPosition
							else
								playerInfo.lastStablePosition = currentPosition
							end
						end

						if testing then
							local tolerance = scaleWithWalkSpeed and playerInfo.oldWalkSpeed/16 or 1 
							print("No violation for "..playerInfo.player.Name.." movement was "..movementVector.magnitude.." max movement was "..(maxDistance*passedTime*tolerance))
						end

						-- Remove strikes over time
						if playerInfo.corrections > 0 and os.time() - playerInfo.timeOfLastCorrection > interval then
							playerInfo.corrections -= 1
						end
					end
				else
					-- Handle idle state
					if os.time() - playerInfo.LastTime > 3 * interval then
						playerInfo.LastTime += interval
					end
				end
			end
		end)

		if not success then
			warn(errorMessage)
		end
	end

	--[[for index, playerInfo in pairs(playerList) do
		--an uncaught error won't break the whole code
		local s,f = pcall(function()
			--check if player is allowed to tp
			if playerInfo ~= nil and playerInfo.exempt == false then
				local movementVector = playerInfo.player.Character.HumanoidRootPart.Position - playerInfo.LastPosition
				local passedTime = os.time()-playerInfo.LastTime
				--check if player moved at all (The beauty here is that this also allows us to compensate for high ping players)
				if movementVector.magnitude > 1 then
					--create a tolerance factor
					playerInfo.oldWalkSpeed = playerInfo.oldWalkSpeed > playerInfo.player.Character.Humanoid.WalkSpeed and playerInfo.oldWalkSpeed or playerInfo.player.Character.Humanoid.WalkSpeed
					local tolerance = scaleWithWalkSpeed and playerInfo.oldWalkSpeed/16 or 1
					local playerTolerance = playerInfo.lastLocalTolerance >= playerInfo.localTolerance and playerInfo.lastLocalTolerance or playerInfo.localTolerance
					playerInfo.lastLocalTolerance = playerInfo.localTolerance
					--check if the movement is sus
					if movementVector.magnitude > maxDistance*passedTime*tolerance*playerTolerance then
						--this movement was sus, but lets examine it a little closer
						--check if player was falling 
						--(I define falling as a movement in the Y/-Y direction where the 2/3 magnitude of the movement is less than the change in Y)
						if movementVector.magnitude * .66 > math.abs(movementVector.Y) then
							--we moved down/up, but most of our distance was covered by side to side motion
							--check if we need to issue a correction or yeetus the player
							if playerInfo.corrections < correctedViolations then
								--add a correction to their record
								playerInfo.corrections += 1
								--do the correction
								playerInfo.player.Character:SetPrimaryPartCFrame(CFrame.new(playerInfo.lastStablePosition))
								playerInfo.LastPosition = playerInfo.lastStablePosition

								if antiFling == true then
									playerInfo.player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
								end
								if testing then
									warn("Violation of "..movementVector.magnitude.." by "..playerInfo.player.Name.." Max Movement: "..(maxDistance*passedTime*tolerance*playerTolerance))
								end
							else
								--remove the player
								playerInfo.player:Kick(kickMessage)
							end
						else 
							--Update info, check if testing, if so, post notif
							playerInfo.LastPosition = playerInfo.player.Character.HumanoidRootPart.Position
							playerInfo.LastTime = os.time()
							playerInfo.oldWalkSpeed = playerInfo.player.Character.Humanoid.WalkSpeed
							if testing then
								warn("A fall/rise was detected.")
							end
						end
					else
						--it was not sus, update our infomation
						playerInfo.LastPosition = playerInfo.player.Character.HumanoidRootPart.Position
						playerInfo.LastTime = os.time()
						playerInfo.oldWalkSpeed = playerInfo.player.Character.Humanoid.WalkSpeed
						--check if player is on the ground
						if playerInfo.player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							--update last stable position
							playerInfo.lastStablePosition = playerInfo.LastPosition
						end
						--if we are in testing mode, print out the info
						if testing then
							local tolerance = scaleWithWalkSpeed and playerInfo.oldWalkSpeed/16 or 1 
							print("No violation for "..playerInfo.player.Name.." movement was "..movementVector.magnitude.." max movement was "..(maxDistance*passedTime*tolerance))
						end
						--check if we can remove a strike from the player
						if playerInfo.corrections > 0 and os.time() - playerInfo.timeOfLastCorrection > interval then
							--we can remove it from their record so we will
							playerInfo.corrections -= 1
						end
					end
				else
					--Player is still, check how long they have been still
					if os.time() - playerInfo.LastTime > 3*interval then
						--Limit Compensation
						playerInfo.LastTime += interval
					end
				end
			end
		end)
		--check for and warn in console any errors
		if not s then warn(f) end
	end]]
end