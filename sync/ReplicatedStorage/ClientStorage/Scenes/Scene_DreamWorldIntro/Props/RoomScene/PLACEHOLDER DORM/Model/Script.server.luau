local model = script.Parent
local door = model:WaitForChild("Door")

local openSound = model:WaitForChild("OpenSound")
local closeSound = model:WaitForChild("CloseSound")
local light = model:FindFirstChildOfClass("PointLight")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- SETTINGS
local OPEN_RANGE = 7     -- opens when closer than this
local CLOSE_RANGE = 9    -- closes only when farther than this (prevents flicker)

local SLIDE_DISTANCE = 6
local TWEEN_TIME = 0.4

-- base position
local closedCFrame = door.CFrame

-- safe slide direction (no forward bug)
local right = door.CFrame.RightVector
right = Vector3.new(right.X, 0, right.Z)

if right.Magnitude == 0 then
	right = Vector3.new(1, 0, 0)
else
	right = right.Unit
end

local openCFrame = closedCFrame * CFrame.new(right * SLIDE_DISTANCE)

-- tween helper
local function tweenDoor(target)
	local cf = Instance.new("CFrameValue")
	cf.Value = door.CFrame

	cf:GetPropertyChangedSignal("Value"):Connect(function()
		door.CFrame = cf.Value
	end)

	local tween = TweenService:Create(
		cf,
		TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Value = target}
	)

	tween:Play()
	tween.Completed:Connect(function()
		cf:Destroy()
	end)
end

-- player distance check (returns closest distance)
local function getClosestDistance()
	local closest = math.huge

	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = (hrp.Position - door.Position).Magnitude
			if dist < closest then
				closest = dist
			end
		end
	end

	return closest
end

-- STATE
local isOpen = false
local busy = false

while task.wait(0.1) do
	local dist = getClosestDistance()

	-- OPEN
	if not isOpen and dist <= OPEN_RANGE and not busy then
		busy = true

		openSound:Play()
		tweenDoor(openCFrame)

		if light then light.Enabled = true end

		task.delay(TWEEN_TIME, function()
			isOpen = true
			busy = false
		end)

		-- CLOSE
	elseif isOpen and dist >= CLOSE_RANGE and not busy then
		busy = true

		closeSound:Play()
		tweenDoor(closedCFrame)

		if light then light.Enabled = false end

		task.delay(TWEEN_TIME, function()
			isOpen = false
			busy = false
		end)
	end
end