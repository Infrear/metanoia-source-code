-- ClientSideNPCActions.luau
-- Dispatch table for purely-cosmetic, client-only NPC actions triggered by dialogue (v.Action).

local RPS = game:GetService("ReplicatedStorage")
local Storage = RPS:WaitForChild("ClientStorage")
local questRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("QuestRem")
local questVerifyRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("QuestVerifyRem")
local FollowerNPC = require(script.Parent:WaitForChild("FollowerNPC"))

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()

local ClientSideNPCActions = {}
local Actions = {}

-- State tracking
local activeFollowers = {} -- [npcObject] = { follower = FollowerNPC }
local sequenceTokens = {}  -- [npcObject] = integer (Workflow 3: Incrementing Sequence Token)

local ARRIVAL_DISTANCE = 6
local ARRIVAL_CHECK_INTERVAL = 0.5

local function hideNPC(npcObject)
	npcObject:SetAttribute("Fakebuild", true) 
	local npcRoot = npcObject.PrimaryPart
	local prompt = npcRoot and npcRoot:FindFirstChildOfClass("ProximityPrompt") or npcObject:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = false end

	-- stop default track animations on animator if playing
	local animator = npcObject:FindFirstChildOfClass("Animator", true)
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.2)
		end
	end

	-- store original transparencies for durational restore
	for _, part in ipairs(npcObject:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
			if not part:GetAttribute("OgTransparency") then
				part:SetAttribute("OgTransparency", part.Transparency)
			end
		end
	end
end

local function showNPC(npcObject)
	npcObject:SetAttribute("Fakebuild", false)
	local npcRoot = npcObject.PrimaryPart
	local prompt = npcRoot and npcRoot:FindFirstChildOfClass("ProximityPrompt") or npcObject:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = true end

	-- restore original transparencies
	for _, part in ipairs(npcObject:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
			if part:GetAttribute("OgTransparency") then
				part.Transparency = part:GetAttribute("OgTransparency")
			else
				if part:IsA("BasePart") then part.Transparency = 0 end
			end
		end
	end
end

Actions["StopFollowing"] = function(npcObject)
	local entry = activeFollowers[npcObject]
	if not entry then return end

	-- Workflow 3: Bump the sequence token to actively invalidate any yielding distance threads
	sequenceTokens[npcObject] = (sequenceTokens[npcObject] or 0) + 1

	entry.follower:Stop()
	task.wait(0.5)
	entry.follower:Destroy()
	activeFollowers[npcObject] = nil

	showNPC(npcObject)
end

Actions["StartFollowing"] = function(npcObject, destinationName)
	if activeFollowers[npcObject] then return end

	if not destinationName then
		warn("StartFollowing requires a destination, e.g. 'StartFollowing:PartName'")
		return
	end

	local destinationPart = workspace:WaitForChild("SCRIPTING", 5):WaitForChild("LOCATIONS", 5):FindFirstChild(destinationName)
	if not destinationPart then
		warn("StartFollowing destination not found: " .. destinationName)
		return
	end

	local follower = FollowerNPC.new(npcObject, {
		Animations = {
			Idle = npcObject:GetAttribute("IdleAnimId"),
			Walk = npcObject:GetAttribute("WalkAnimId"),
			Run  = npcObject:GetAttribute("RunAnimId"),
		}
	})

	hideNPC(npcObject)

	follower:StartFollowing(function()
		local myChar = plr.Character or char
		return myChar:GetPivot().Position
	end)

	-- 1. Populate the table FIRST so the thread doesn't instantly die
	activeFollowers[npcObject] = { 
		follower = follower
	}

	-- 2. Set up Workflow 3 Sequence Token
	sequenceTokens[npcObject] = (sequenceTokens[npcObject] or 0) + 1
	local localToken = sequenceTokens[npcObject]

	-- 3. Spawn the tracker
	task.spawn(function()
		while activeFollowers[npcObject] do
			task.wait(ARRIVAL_CHECK_INTERVAL)

			-- Check if this thread has been superseded by a newer call or stopped
			if localToken ~= sequenceTokens[npcObject] then
				break -- Thread becomes a throwaway and quietly dies
			end

			-- Sanity check: Does the destination still exist?
			if not destinationPart or not destinationPart.Parent then
				break
			end

			local myChar = plr.Character or char
			if myChar and myChar.PrimaryPart then
				local distance = (myChar:GetPivot().Position - destinationPart.Position).Magnitude

				 if distance <= ARRIVAL_DISTANCE then
				 	-- Final token verification before acting destructively
				 	if localToken == sequenceTokens[npcObject] then
				 		print("Destination reached, firing server.")
				 		questVerifyRem:FireServer("locationReached", npcObject.Name, destinationName)
				 		Actions["StopFollowing"](npcObject)
				 	end
				 	break
				 end
			end
		end
	end)
end

function ClientSideNPCActions.Run(actionString, npcObject)
	if not actionString or not npcObject then return end
	local name, arg = actionString:match("^([^:]+):?(.*)$")
	local fn = Actions[name]
	if fn then
		fn(npcObject, arg ~= "" and arg or nil)
	end
end

return ClientSideNPCActions