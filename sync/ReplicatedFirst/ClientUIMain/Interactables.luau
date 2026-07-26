-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

-- Dependancies
local plr = PLRS.LocalPlayer

local char = plr.Character or plr.CharacterAdded:Wait()
local Storage = RPS:WaitForChild("ClientStorage")
local NPCs = workspace:WaitForChild("NPCS")
local BUILDs = workspace:WaitForChild("BUILDS")
local BOUNDs = workspace:WaitForChild("BOUNDS")
local images = require(Storage:WaitForChild("Info"):WaitForChild("Images"))
local keySettings = require(Storage.Info.KeybindsMaster)
local gameSettings = require(Storage.Info.GameSettings)

local Collections = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Transport = require(script:WaitForChild("TransportService"))
local NPCM = require(script:WaitForChild("NPCs"))
local itemInfo = require(Storage.Info.ItemInfo)
local npcIndex = require(Storage.Info.NPCIndex)

-- Constants
local MAX_RADIUS = 15
local EXIT_DEBOUNCE_TIME = 2      -- must be continuously "out" for this long before a leave actually registers
local REENTRY_COOLDOWN_TIME = 1.5 -- after a confirmed leave, entry attempts are ignored for this long
local TIS = {
	Look = TweenInfo.new(
		.75, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	),
	Away = TweenInfo.new(
		1.35, 
		Enum.EasingStyle.Quint, 
		Enum.EasingDirection.Out
	)
}

-- Shared across ALL bounds zones — CameraService only supports one active
-- persona cam at a time, so the debounce/cooldown state has to live here,
-- not per-model, or a stale exit from a zone you've already left can still
-- fire later and kill whatever zone is now active.
local activeDestination = nil
local exitToken = 0
local cooldowns = {} -- [destination] = cooldownUntil timestamp

-- Initialization
local InteractionService = {}

-- Local Functions
local function createPrompt(parent, action, object, duration)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = action
	prompt.ObjectText = object or ""
	prompt.HoldDuration = duration or 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end


local function findClosestsPlayerHrp(dist, npc)
	local closest = nil
	for i, plr in pairs(game.Players:GetChildren()) do
		local char = plr.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local tmpDist = (npc:GetPivot().Position - char:GetPivot().Position).Magnitude
			if tmpDist < dist then
				closest = char
				dist = tmpDist
			end
		end
	end
	return closest, dist
end
local function collectZoneParts(instance)
	local parts = {}
	if instance:IsA("BasePart") then
		table.insert(parts, instance)
	end
	for _, desc in ipairs(instance:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end
	return parts
end

local function requestZoneEnter(destination)
	local now = os.clock()
	if cooldowns[destination] and now < cooldowns[destination] then
		return -- this destination specifically is still cooling down
	end

	exitToken += 1 -- cancels ANY pending exit — this zone's own, or a different zone's stale one

	if activeDestination ~= destination then
		activeDestination = destination
		Transport.EnterZone(destination)
	end
end

local function requestZoneExitStart(destination)
	if activeDestination ~= destination then return end -- not the active zone, ignore

	exitToken += 1
	local myToken = exitToken

	task.delay(EXIT_DEBOUNCE_TIME, function()
		if myToken ~= exitToken then return end          -- superseded by a re-entry or a new zone
		if activeDestination ~= destination then return end -- extra safety

		activeDestination = nil
		cooldowns[destination] = os.clock() + REENTRY_COOLDOWN_TIME
		Transport.ExitZone(destination)
	end)
end

local function cancelPendingZoneExit(destination)
	if activeDestination ~= destination then return end
	exitToken += 1
end

-- Tracks a touch counter across every part in the zone (handles multi-limb
-- and multi-part overlap) and only fires on the 0->1 / 1->0 transitions.
local function bindTouchZone(zoneInstance, onEnter, onExit)
	local parts = collectZoneParts(zoneInstance)
	local touchCount = 0

	local function isOwnCharacterPart(otherPart)
		return otherPart:IsDescendantOf(char)
	end

	for _, part in ipairs(parts) do
		part.Touched:Connect(function(otherPart)
			if not isOwnCharacterPart(otherPart) then return end
			touchCount += 1
			if touchCount == 1 then
				onEnter()
			end
		end)
		part.TouchEnded:Connect(function(otherPart)
			if not isOwnCharacterPart(otherPart) then return end
			touchCount = math.max(0, touchCount - 1)
			if touchCount == 0 then
				onExit()
			end
		end)
	end
end

local function findRolePart(model, role, fallbackNames)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:GetAttribute("TPRole") == role then
			return desc
		end
	end
	for _, name in ipairs(fallbackNames) do
		local found = model:FindFirstChild(name, true)
		if found then return found end
	end
	return nil
end

function InteractionService.setupOnePartTouch(model, destination)
	bindTouchZone(model,
		function() requestZoneEnter(destination) end,
		function() requestZoneExitStart(destination) end
	)
end

function InteractionService.setupTwoPartTouch(model, destination)
	local enterZone = findRolePart(model, "Enter", {"Enter", "EnterPart"})
	local exitZone = findRolePart(model, "Exit", {"Exit", "ExitPart", "Leave", "LeavePart"})

	if not enterZone or not exitZone then
		warn("TwoPartTouch model '" .. model.Name .. "' is missing an Enter or Exit part.")
		return
	end

	bindTouchZone(enterZone, function() requestZoneEnter(destination) end, function() end)
	bindTouchZone(exitZone, function() requestZoneExitStart(destination) end, function() cancelPendingZoneExit(destination) end)
end

-- Global Functions
function InteractionService.setup()
	NPCM.setup()
	
	-- 1. Setup NPCs (Talk)
	for _, npc in ipairs(NPCs:GetChildren()) do
		if npc:IsA("Model") then
			coroutine.wrap(function()
				local humorac =  npc:FindFirstChild("Humanoid") or npc:FindFirstChild("AnimationController") or npc:WaitForChild("Humanoid", 10) or npc:WaitForChild("AnimationController", 10)
				if humorac then
					if humorac:IsA("Humanoid") then
						for i, v in pairs(Enum.HumanoidStateType:GetEnumItems()) do
							if v ~= Enum.HumanoidStateType.None then
								humorac:SetStateEnabled(v, false)
							end
						end
						humorac.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
						humorac.EvaluateStateMachine = false
					end
					local closest, dist = findClosestsPlayerHrp(MAX_RADIUS, npc)
					if npc:FindFirstChild("NPCBasicTrack") then
						local trac = npc:FindFirstChild("NPCBasicTrack")
						local at = humorac:FindFirstChildOfClass("Animator") or Instance.new("Animator", humorac)
						local animtrac = at:LoadAnimation(trac)
						animtrac:Play()
					end

					local periodictrac = npc:FindFirstChild("PeriodicalTrack")
					local periodicanim = nil
					local pInt = periodictrac and periodictrac:GetAttribute("InterruptedByPlayerNear") or false

					if periodictrac then
						-- Periodical NPC Animation
						local periodRange = periodictrac:GetAttribute("Interval")
						if periodRange then
							periodicanim = humorac:FindFirstChild("Animator"):LoadAnimation(periodictrac)

							coroutine.wrap(function()
								if pInt and closest then
									repeat wait() until not closest
								end

								while true do
									local tim = math.random(periodRange.Min, periodRange.Max)

									for i = 1, tim do
										wait(1)

										if pInt and closest then
											repeat wait() until not closest
										end
									end

									periodicanim:Play(periodictrac:GetAttribute("FadeTime") or 0.35, nil, periodictrac:GetAttribute("Speed") or 1)
								end
							end)()

							if periodictrac:GetAttribute("StartOnOne") then
								if pInt and closest then
									repeat wait() until not closest
								end
								periodicanim:Play(periodictrac:GetAttribute("FadeTime") or 0.35, nil, periodictrac:GetAttribute("Speed") or 1)
							end
						end
					end

					local head = npc:WaitForChild("Head")
					local neck = npc:FindFirstChild("Neck", true)
					if not head or not neck then return end

					-- Store the ORIGINAL C0 so we know where "Normal" is
					local originalC0 = neck.C0 

					coroutine.wrap(function()
						while task.wait(0.1) do -- Throttled slightly for performance
							closest, dist = findClosestsPlayerHrp(MAX_RADIUS, npc)

							if closest then
								if pInt and periodicanim.IsPlaying then
									periodicanim:Stop()
								end
								-- Tracking Logic
								local CameraDirection = (CFrame.new(npc:GetPivot().Position, closest:GetPivot().Position):inverse() * npc:GetPivot()).LookVector * -1
								local YOffset = originalC0.Y -- Use the original Y offset

								local Goal = CFrame.new(0, YOffset, 0) 
									* CFrame.Angles(0, -math.asin(CameraDirection.x), 0) 
									* CFrame.Angles(math.asin(CameraDirection.y), 0, 0)

								TS:Create(neck, TIS.Look, {C0 = Goal}):Play()
							else
								-- RESET Logic: If no player is found, return to the original position
								TS:Create(neck, TIS.Away, {C0 = originalC0}):Play()
							end
						end
					end)()
				end
			end)()
			
			if not (npc:GetAttribute("NPCType") and keySettings.Interactions.TALKABLE_NPC_TYPES[npc:GetAttribute("NPCType")]) or not npc:IsA("Model") or npc:GetAttribute("Fakebuild") then continue end
			local prompt = createPrompt(npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart"), "Talk", npc.Name, 0.5)
			prompt.Triggered:Connect(function()
				NPCM.runNPC(npc)
			end)
		end
	end

	-- 2. Setup Builds (Examine)
	for _, obj in ipairs(BUILDs:GetChildren()) do
		if obj:GetAttribute("Examinable") then
			local prompt = createPrompt(obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"), "Examine", obj.Name, 0)
			prompt.Triggered:Connect(function()
				print("Examining: " .. obj.Name)
				-- Trigger your examine UI logic here
			end)
		end
	end

	-- 3. Setup Bounds (Travel)
	for _, model in ipairs(BOUNDs:GetChildren()) do
		local destination = model:GetAttribute("DestinationPart")
		if not (model:GetAttribute("Travelable") and destination) then continue end

		local tpType = model:GetAttribute("TPType") or "ProximityPart"

		if tpType == "ProximityPart" then
			local prompt = createPrompt(model:FindFirstChild("PromptPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"), "Go", model:GetAttribute("DestinationDisplayName"), 1)
			prompt.Triggered:Connect(function()
				Transport.Teleport(destination)
			end)

		elseif tpType == "OnePartTouch" then
			InteractionService.setupOnePartTouch(model, destination)

		elseif tpType == "TwoPartTouch" then
			InteractionService.setupTwoPartTouch(model, destination)
		end
	end
end

return InteractionService