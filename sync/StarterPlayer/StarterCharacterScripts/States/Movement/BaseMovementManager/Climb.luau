--defs
-- I also just want to say thanks to the devforum cause some of this was pretty complicated for me to understand
-- Services
local RS = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")

-- Constants
local TURN_INFO = TweenInfo.new(
	0.25, 
	Enum.EasingStyle.Linear
)
local S = 10
local AS = 1.3
local MAXIMUM_ANGLE_FROM_WALL = math.pi / 4

-- Dependancies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local mouse = plr:GetMouse()
--local ShiftLock = require(script.Parent:WaitForChild("ShiftLock"))

local rParams = RaycastParams.new()
local constraint = Instance.new("PrismaticConstraint")
local rootAttachment = hrp:FindFirstChildOfClass("Attachment")
local bodyVelocity = Instance.new("BodyVelocity")

--local Event = RS.Events:WaitForChild("ClimbStamina")
--local Event2 = RS.Events:WaitForChild("ClimbOff")
--local Event3 = RS.Events:WaitForChild("Drained")
--local Event4 = RS.Events:WaitForChild("DisableClimb")

local AM = char.States:WaitForChild("AnimationManager2")
local climbAnim = AM:WaitForChild("Anims").Climb

local vectors = {
	"LookVector",
	"UpVector",
	"RightVector"
}

-- Initialization
local Climb = {}

-- Local Variable
local turning = false
--local firstJump = false

local currentClimbTrack = nil

local climbStates = {
	["cf"] = 0, --Forwards
	["cb"] = 0, --Backwards
	["cr"] = 0, --Right
	["cl"] = 0 --Left
}

-- Global Variables
Climb.climbing = false
Climb.list = {}

-- Local Functions
local function setup()
	--adding stuff to characters
	rParams.FilterType = Enum.RaycastFilterType.Blacklist
	rParams.IgnoreWater = true
	
	for _, player in ipairs(PLRS:GetChildren()) do
		if player.Character then
			table.insert(Climb.list, player.Character or plr.CharacterAdded:Wait())
		end
		rParams.FilterDescendantsInstances = Climb.list
	end

	PLRS.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function()
			table.insert(Climb.list, plr.Character or plr.CharacterAdded:Wait())
		end)
		rParams.FilterDescendantsInstances = Climb.list
	end)
	
	--rootAttachment = hrp:FindFirstChildOfClass("Attachment")
	--print(rParams.FilterDescendantsInstances)
	
	constraint.Parent = char
	constraint.Name = "ClimbingConstraint"
	constraint.Attachment1 = rootAttachment
	constraint.LimitsEnabled = false

	bodyVelocity.MaxForce = Vector3.new()
	bodyVelocity.Parent = script
end

local function adjustConstraints()

	local f = climbStates["cf"]
	local b = climbStates["cb"]
	local r = climbStates["cr"]
	local l = climbStates["cl"]

	constraint.Attachment0.WorldCFrame = hrp.CFrame * CFrame.Angles(0, 0, (r - l) * (f - b) * math.pi/4 + (-(r - l)^2 + 1) * math.pi/2) --complicated math stuff i needed help with. thx devform and youtube
	currentClimbTrack:AdjustSpeed((r - l) * (f - b) * AS + (-(r - l)^2 + 1) * (f - b) * AS + (-(f - b)^2 + 1) * (r - l) * AS) --edit this when you have an animation
	rootAttachment.WorldCFrame = constraint.Attachment0.WorldCFrame
	bodyVelocity.Parent = hrp
	bodyVelocity.Velocity = (hrp.CFrame.RightVector * S * (r - l)) + (hrp.CFrame.UpVector * S * (f - b))
end

local function checkSides(direction, rotation) --Check if you need to climb around the wall sideways

	local vector, position

	local innerPos = (hrp.CFrame.RightVector * 3 * direction + hrp.CFrame.LookVector) * rotation
	local innerDir = (hrp.CFrame.RightVector * -7 * direction + hrp.CFrame.LookVector * 2) * rotation


	local targetSide = workspace:Raycast(hrp.Position + innerPos, hrp.CFrame.RightVector * 4 * direction + innerDir, rParams)

	if targetSide and math.acos(((-targetSide.Normal):Dot(hrp.CFrame.LookVector))) > .05 then
		turning = true
		hrp.Anchored = true
		bodyVelocity.MaxForce = Vector3.new()
		constraint.Enabled = false

		vector = -targetSide.Normal
		position = targetSide.Position - vector * 1.2 

		local animation = TS:Create(hrp, TURN_INFO, {CFrame = CFrame.new(position, position + vector)})
		animation:Play()
		animation.Completed:Wait()

		adjustConstraints()

		bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
		constraint.Enabled = true
		hrp.Anchored = false
		turning = false
	end
end

local function checkEdges() --Check if you need to climb upwards
	if not turning then
		local f = climbStates["cf"]
		local b = climbStates["cb"]
		local r = climbStates["cr"]
		local l = climbStates["cl"]


		local targetUp = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 1.5 + hrp.CFrame.UpVector, rParams)
		local targetOuter = workspace:Raycast(hrp.Position, hrp.CFrame.RightVector * 3 * (r - l), rParams)
		local targetDown = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2 - hrp.CFrame.UpVector, rParams)
		
		if targetUp ~= nil then
			if (targetUp.Position - char:WaitForChild("Head").Position).Magnitude > 2.5 then targetUp = nil end
		end
		if (not targetUp and (b - f) == -1) then
			Climb.stop()

			--turning = true
			hrp.Anchored = true
			local newpos = hrp.Position+hrp.CFrame.UpVector * 2 + hrp.CFrame.LookVector * 2
			
			-- Turn stuff
			--local locked = false
			--if ShiftLock.Locked then
			--	ShiftLock.Inactive = true
			--	ShiftLock.Unlock()
			--	locked = true
			--	--coroutine.wrap(function()
			--	--	task.wait(0.525)
			--	--	ShiftLock.Inactive = false
			--	--end)()
			--end
			--ShiftLock.Locked = true
			
			local animation = TS:Create(hrp, TURN_INFO, {CFrame = CFrame.new(newpos, newpos + hrp.CFrame.LookVector)})
			animation:Play()
			animation.Completed:Wait()

			--if locked then
			--	ShiftLock.Lock()
			--	ShiftLock.Inactive = false
			--end
			--
			
			hrp.Anchored = false
			turning = false
			return
		end


		if targetOuter then
			checkSides(r - l, 0)
		elseif not targetOuter then
			checkSides(r - l, 1)
		end

		if not targetDown then
			Climb.stop()
		end
	end
end

local function bindState(actionName, inputState, inputObject)
	local state = climbStates[actionName]

	if inputState == Enum.UserInputState.Begin and state == 0 then
		climbStates[actionName] = 1
	elseif inputState == Enum.UserInputState.End and state == 1 then
		climbStates[actionName] = 0
	end
	--print(climbStates)
	if not turning then
		adjustConstraints()
	end
end

local function checkForWall()
	local raycastResult = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2 + Vector3.new(0, .5, 0), rParams)

	if raycastResult then
		local characterStraightness = (hrp.CFrame.UpVector.Unit - Vector3.new(0, 1, 0)).Magnitude
		local vector = -raycastResult.Normal
		local position = raycastResult.Position - vector * 1.2
		if raycastResult.Instance.Anchored and position and characterStraightness < .05 and math.acos((vector:Dot(hrp.CFrame.LookVector))) < MAXIMUM_ANGLE_FROM_WALL then
			return vector, position, raycastResult.Instance
		end
	end
end

--local function stateChanged(old, new)
--	if new == 7 then
--		firstJump = false
--	end
--end

--function jump(actionName, inputState, inputObject) --bye bye infinite jump bug :)
--	if inputState == Enum.UserInputState.Begin then
--		if firstJump and hum:GetState() == Enum.HumanoidStateType.Freefall and not Climb.climbing then
--			checkForWall()
--			--Event2:Fire()
--		elseif firstJump and Climb.climbing and not turning then
--			Climb.stop()
--			--Event:Fire()

--			return Enum.ContextActionResult.Sink
--		elseif not firstJump then
--			firstJump = true
--		end
--	end
--end

-- Global Functions
function Climb.start() --Check if you need to climb upwards
	local vector, position, part = checkForWall()
	
	if not vector or not position or not part then return end
	
	hum.AutoRotate = false
	hrp.CFrame = CFrame.new(position, position + vector)
	bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)

	local currentAttach = Instance.new("Attachment")
	currentAttach.Parent = part
	currentAttach.WorldCFrame = hrp.CFrame
	constraint.Attachment0 = currentAttach
	constraint.Enabled = true

	local anim = hum:LoadAnimation(climbAnim)
	anim.Priority = 1
	anim:Play(.5, 1, 0)

	currentClimbTrack = anim --edit this later to be the animation zellion makes

	local wHeld = UIS:IsKeyDown(Enum.KeyCode.W)
	if wHeld then
		climbStates["cf"] = 1
		adjustConstraints()
	end

	CAS:BindAction("cf", bindState, false, Enum.PlayerActions.CharacterForward)
	CAS:BindAction("cb", bindState, false, Enum.PlayerActions.CharacterBackward)
	CAS:BindAction("cr", bindState, false, Enum.PlayerActions.CharacterRight)
	CAS:BindAction("cl", bindState, false, Enum.PlayerActions.CharacterLeft)
	RS:BindToRenderStep("checkClimb", 50, checkEdges)

	--hum:SetStateEnabled(0, false)
	--hum:SetStateEnabled(2, false)
	hum:SetStateEnabled(5, false)
	hum:SetStateEnabled(8, false)
	hum:ChangeState(12)

	Climb.climbing = true
end

function Climb.stop()
	--if not (Climb.climbing and not turning) then return end
	if not Climb.climbing or turning then return end
	--Event:Fire()

	--Event4:Fire()
	climbStates["cf"] = 0
	climbStates["cb"] = 0
	climbStates["cr"] = 0
	climbStates["cl"] = 0

	--hum:SetStateEnabled(0, true)
	--hum:SetStateEnabled(2, true)
	hum:SetStateEnabled(5, true)
	hum:SetStateEnabled(8, true)
	for _, track in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
		if track.Animation == climbAnim then
			track:Stop()
			track:Destroy()
		end
	end --Edit this when you have an animation but dont make it a comment or stuff will get weird

	constraint.Enabled = false
	hum.AutoRotate = true
	constraint.Attachment0:Destroy()
	rootAttachment.WorldCFrame = hrp.CFrame
	bodyVelocity.Parent = script
	bodyVelocity.MaxForce = Vector3.new()
	bodyVelocity.Velocity = Vector3.new()

	CAS:UnbindAction("cf")
	CAS:UnbindAction("cb")
	CAS:UnbindAction("cr")
	CAS:UnbindAction("cl")
	RS:UnbindFromRenderStep("checkClimb")

	Climb.climbing = false
end

-- Connections
--hum.StateChanged:Connect(stateChanged)
--CAS:BindAction("onJump", jump, false, Enum.PlayerActions.CharacterJump)
--Event3.Event:Connect(stop)

-- Loose Threads
setup()

--while true do	
--	if Climb.climbing == true then
--		--Event2:Fire()
--		wait(.1)
--	else
--		--Event:Fire()
--		wait(.1)
--	end

--end

return Climb