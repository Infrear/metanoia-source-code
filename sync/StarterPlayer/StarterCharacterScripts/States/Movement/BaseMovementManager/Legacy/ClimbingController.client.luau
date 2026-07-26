--defs
-- I also just want to say thanks to the devforum cause some of this was pretty complicated for me to understand
local CAS = game:GetService("ContextActionService")

local RS = game:GetService("ReplicatedStorage")
--local Event = RS.Events:WaitForChild("ClimbStamina")
--local Event2 = RS.Events:WaitForChild("ClimbOff")
--local Event3 = RS.Events:WaitForChild("Drained")
--local Event4 = RS.Events:WaitForChild("DisableClimb")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local TweenS = game:GetService("TweenService")

local AT = TweenInfo.new(0.25, Enum.EasingStyle.Linear)
local S = 10
local AS = 1.3
local MAXIMUM_ANGLE_FROM_WALL = math.pi / 4

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local climbing = false
local turning = false
local firstJump = false

local currentClimbTrack

local vectors = {
	"LookVector",
	"UpVector",
	"RightVector"
}
--definitions
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true
local filterTable = {}

--adding stuff to characters
for _, player in ipairs(game:GetService("Players"):GetChildren()) do
	if player.Character then
		table.insert(filterTable, player.Character or plr.CharacterAdded:Wait())
	end
end

game:GetService("Players").PlayerAdded:Connect(function(plr)
	table.insert(filterTable, plr.Character or plr.CharacterAdded:Wait())
	raycastParams.FilterDescendantsInstances = filterTable
end)

raycastParams.FilterDescendantsInstances = filterTable

local rootAttachment = hrp:FindFirstChildOfClass("Attachment")

local constraint = Instance.new("PrismaticConstraint")
constraint.Parent = char
constraint.Name = "ClimbingConstraint"
constraint.Attachment1 = rootAttachment
constraint.LimitsEnabled = false

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new()
bodyVelocity.Parent = script

local AM = char.States:WaitForChild("AnimationManager2")
local climbAnim = AM:WaitForChild("Anims").Climb

local climbStates = {
	["cf"] = 0, --Forwards
	["cb"] = 0, --Backwards
	["cr"] = 0, --Right
	["cl"] = 0 --Left
}



--functions
function adjustConstraints()

	local f = climbStates["cf"]
	local b = climbStates["cb"]
	local r = climbStates["cr"]
	local l = climbStates["cl"]

	constraint.Attachment0.WorldCFrame = hrp.CFrame * CFrame.Angles(0, 0, (r - l) * (f - b) * math.pi/4 + (-(r - l)^2 + 1) * math.pi/2) --complicated math stuff i needed help with. thx devform and youtube
	--[[currentClimbTrack:AdjustSpeed((r - l) * (f - b) * AS + (-(r - l)^2 + 1) * (f - b) * AS + (-(f - b)^2 + 1) * (r - l) * AS)]] --edit this when you have an animation
	rootAttachment.WorldCFrame = constraint.Attachment0.WorldCFrame
	bodyVelocity.Parent = hrp
	bodyVelocity.Velocity = (hrp.CFrame.RightVector * S * (r - l)) + (hrp.CFrame.UpVector * S * (f - b))
end

function checkSides(direction, rotation) --Check if you need to climb around the wall sideways

	local vector, position

	local innerPos = (hrp.CFrame.RightVector * 3 * direction + hrp.CFrame.LookVector) * rotation
	local innerDir = (hrp.CFrame.RightVector * -7 * direction + hrp.CFrame.LookVector * 2) * rotation


	local targetSide = workspace:Raycast(hrp.Position + innerPos, hrp.CFrame.RightVector * 4 * direction + innerDir, raycastParams)

	if targetSide and math.acos(((-targetSide.Normal):Dot(hrp.CFrame.LookVector))) > .05 then
		turning = true
		hrp.Anchored = true
		bodyVelocity.MaxForce = Vector3.new()
		constraint.Enabled = false

		vector = -targetSide.Normal
		position = targetSide.Position - vector * 1.2 

		local animation = TweenS:Create(hrp, AT, {["CFrame"] = CFrame.new(position, position + vector)})
		animation:Play()
		animation.Completed:Wait()

		adjustConstraints()

		bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
		constraint.Enabled = true
		hrp.Anchored = false
		turning = false
	end
end

function checkEdges() --Check if you need to climb upwards
	if not turning then
		local f = climbStates["cf"]
		local b = climbStates["cb"]
		local r = climbStates["cr"]
		local l = climbStates["cl"]


		local targetUp = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2 + hrp.CFrame.UpVector, raycastParams)
		local targetOuter = workspace:Raycast(hrp.Position, hrp.CFrame.RightVector * 3 * (r - l), raycastParams)
		local targetDown = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2 - hrp.CFrame.UpVector, raycastParams)

		if not targetUp and (b - f) == -1 then
			Cancel()

			turning = true
			hrp.Anchored = true
			local newpos = hrp.Position+hrp.CFrame.UpVector * 2 + hrp.CFrame.LookVector * 2

			local animation = TweenS:Create(hrp, AT, {["CFrame"] = CFrame.new(newpos, newpos + hrp.CFrame.LookVector)})
			animation:Play()
			animation.Completed:Wait()

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
			Cancel()
		end
	end
end

function CStates(actionName, inputState, inputObject)
	local state = climbStates[actionName]

	if inputState == Enum.UserInputState.Begin and state == 0 then
		climbStates[actionName] = 1
	elseif inputState == Enum.UserInputState.End and state == 1 then
		climbStates[actionName] = 0
	end

	if not turning then
		adjustConstraints()
	end
end

function startClimb(vector, position, part) --Check if you need to climb upwards
	char.Humanoid.AutoRotate = false
	hrp.CFrame = CFrame.new(position, position + vector)
	bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)

	local currentAttach = Instance.new("Attachment")
	currentAttach.Parent = part
	currentAttach.WorldCFrame = hrp.CFrame
	constraint.Attachment0 = currentAttach
	constraint.Enabled = true

	--[[local anim = char.Humanoid:LoadAnimation(climbAnim)
	anim.Priority = 1
	anim:Play(.5, 1, 0)

	currentClimbTrack = anim]] --edit this later to be the animation zellion makes

	local wHeld = UIS:IsKeyDown(Enum.KeyCode.W)
	if wHeld then
		climbStates["cf"] = 1
		adjustConstraints()
	end

	CAS:BindAction("cf", CStates, false, Enum.PlayerActions.CharacterForward)
	CAS:BindAction("cb", CStates, false, Enum.PlayerActions.CharacterBackward)
	CAS:BindAction("cr", CStates, false, Enum.PlayerActions.CharacterRight)
	CAS:BindAction("cl", CStates, false, Enum.PlayerActions.CharacterLeft)
	Run:BindToRenderStep("checkClimb", 50, checkEdges)

	char.Humanoid:SetStateEnabled(5, false)
	char.Humanoid:SetStateEnabled(8, false)
	char.Humanoid:ChangeState(12)

	climbing = true

end

function Cancel()
	--Event4:Fire()
	climbStates["cf"] = 0
	climbStates["cb"] = 0
	climbStates["cr"] = 0
	climbStates["cl"] = 0

	char.Humanoid:SetStateEnabled(5, true)
	char.Humanoid:SetStateEnabled(8, true)
	for _, track in ipairs(char.Humanoid.Animator:GetPlayingAnimationTracks()) do
		if track.Animation == climbAnim then
			track:Stop()
			track:Destroy()
		end
	end --Edit this when you have an animation but dont make it a comment or stuff will get weird

	constraint.Enabled = false
	char.Humanoid.AutoRotate = true
	constraint.Attachment0:Destroy()
	rootAttachment.WorldCFrame = hrp.CFrame
	bodyVelocity.Parent = script
	bodyVelocity.MaxForce = Vector3.new()
	bodyVelocity.Velocity = Vector3.new()

	CAS:UnbindAction("cf")
	CAS:UnbindAction("cb")
	CAS:UnbindAction("cr")
	CAS:UnbindAction("cl")
	Run:UnbindFromRenderStep("checkClimb")

	climbing = false
end

function checkForWall()
	local raycastResult = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2 + Vector3.new(0, .5, 0), raycastParams)

	if raycastResult then
		local characterStraightness = (hrp.CFrame.UpVector.Unit - Vector3.new(0, 1, 0)).Magnitude
		local vector = -raycastResult.Normal
		local position = raycastResult.Position - vector * 1.2
		if raycastResult.Instance.Anchored and position and characterStraightness < .05 and math.acos((vector:Dot(hrp.CFrame.LookVector))) < MAXIMUM_ANGLE_FROM_WALL then
			startClimb(vector, position, raycastResult.Instance)

		end
	end
end

function jump(actionName, inputState, inputObject) --bye bye infinite jump bug :)
	if inputState == Enum.UserInputState.Begin then
		if firstJump and char.Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not climbing then
			checkForWall()
			--Event2:Fire()
		elseif firstJump and climbing and not turning then
			Cancel()
			--Event:Fire()

			return Enum.ContextActionResult.Sink
		elseif not firstJump then
			firstJump = true
		end
	end
end

function stateChanged(_, state)
	if state == 7 then
		firstJump = false
	end
end

function characterAdded(instance)
	if instance:FindFirstChild("Humanoid") then
		table.insert(filterTable, instance)
		raycastParams.FilterDescendantsInstances = filterTable
	end

end



char.Humanoid.StateChanged:Connect(stateChanged)
CAS:BindAction("onJump", jump, false, Enum.PlayerActions.CharacterJump)
workspace.ChildAdded:Connect(characterAdded)
--Event3.Event:Connect(Cancel)

while true do	
	if climbing == true then
		--Event2:Fire()
		wait(.1)
	else
		--Event:Fire()
		wait(.1)
	end

end