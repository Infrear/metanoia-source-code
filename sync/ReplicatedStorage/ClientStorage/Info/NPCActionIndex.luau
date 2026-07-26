-- Services
local RPS = game:GetService("ReplicatedStorage")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")
local SSS = game:GetService("ServerScriptService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local plr = game.Players.LocalPlayer
if not plr then
	odm = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager"))
end
local GhostsAnti = SSS:WaitForChild("Overworld"):WaitForChild("Ghost's Anti-Teleport System")
local tolerance = GhostsAnti:WaitForChild("Tolerance")
local setRelative = GhostsAnti:WaitForChild("SetRelative")
local toggle = GhostsAnti:WaitForChild("Toggle")
local toggleWYield = GhostsAnti:WaitForChild("ToggleWithYield")


-- Constants
local TIS = {
	TWEEN_INFO_FAST = TweenInfo.new(
		3, 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.Out
	),
	TWEEN_INFO_SLOW = TweenInfo.new(
		10, 
		Enum.EasingStyle.Sine, 
		Enum.EasingDirection.InOut
	),
	TWEEN_INFO_OPEN = TweenInfo.new(
		5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	)
}

local function tweenModel(model, info, CF, relativeModels, currentTween)
	if currentTween then
		if currentTween.PlaybackState == Enum.PlaybackState.Playing then
			currentTween:Cancel()
		end
	end

	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPivot()

	local con1
	con1 = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(CFrameValue.Value)
		if relativeModels then
			for i, rModel in pairs(relativeModels) do
				rModel[1]:PivotTo(CFrameValue.Value:ToWorldSpace(rModel[2]))
			end
		end
	end)

	currentTween = TS:Create(CFrameValue, info, {Value = CF})
	currentTween:Play()

	local con2
	con2 = currentTween.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		CFrameValue:Destroy()
	end)
	return currentTween
end


return {
["Actions"] = {},
}
	
---


























































---
--local function toggleHatch(open)
--	local TE = nil
--	local TEs = {}
--	if open then
--		TE = TS:Create(slider, TIS.TWEEN_INFO_OPEN, {Size = Vector3.new(28.935, 0.556, 64.882), Position = Vector3.new(-114.581, 38.737, -274.169)})
--		for i, v in pairs(slider.Parent.Rafters:GetChildren()) do
--			table.insert(TEs, TS:Create(v, TIS.TWEEN_INFO_OPEN, {Transparency = 1}))
--		end	
--	else
--		TE = TS:Create(slider, TIS.TWEEN_INFO_OPEN, {Size = Vector3.new(94.035, 0.556, 64.882), Position = Vector3.new(-146.022, 38.737, -265.744)})
--		for i, v in pairs(slider.Parent.Rafters:GetChildren()) do
--			table.insert(TEs, TS:Create(v, TIS.TWEEN_INFO_OPEN, {Transparency = 0}))
--		end		
--	end
--	for i, v in pairs(TEs) do
--		v:Play()
--	end
--	TE:Play()
--	return TE, TEs
--end


-- space waypoints
--local waypoints = {
--	Start = ship:GetPivot(),
--	--EarthTakeoff = Vector3.new(374.564, -19.007, -208), -- Ship moves up and forward
--	SpaceExit = Vector3.new(-10501.3087158203125, 10976.72216796875, -1301.4544677734375),  -- High altitude above Earth
--	MarsApproach = Vector3.new(-45418.31640625, 26467.177734375, 1954.712158203125), -- Near Mars, but above its surface
--	MarsSurface = Vector3.new(-43150.27, 9791.003, 7101.405) -- Mars surface landing
--}

--local Actions = {
--	["Travel Ship"] = function(plr)
--		print(odm.PlayerData[plr].Data.Money.Data)

--		local char = plr.Character
--		if not char then return end

--		if odm.PlayerData[plr].Data.Money.Data > 500 or true then
--			--odm.PlayerData[plr].Data.Money:Decrease(500)
--			--print("flying out "..plr.Name)
--			if not ship then
--				return
--			end
--			if not ship.PrimaryPart then
--				warn("Ship must have a PrimaryPart set for tweening.")
--				return
--			end

--			local currentTween = nil

--			print(3)
--			task.wait(1)
--			print(2)
			
--			toggleHatch(true)
			
--			task.wait(1)
--			print(1)
--			task.wait(1)

--			--char.Parent = ship
--			--char.Parent = ship
--			char:FindFirstChild("HumanoidRootPart").Anchored = true
--			local objectCFrames = {
--				{char, ship:GetPivot():ToObjectSpace(char:GetPivot())},
--				{workspace.NPCS.Captain, ship:GetPivot():ToObjectSpace(workspace.NPCS.Captain:GetPivot())}	
--			}
--			for i, v in pairs(workspace.CHARACTERS:GetChildren()) do
--				v:FindFirstChild("HumanoidRootPart").Anchored = true
--				table.insert(objectCFrames, {v, ship:GetPivot():ToObjectSpace(v:GetPivot())})
--			end
		
--			--ship = game.Players.LocalPlayer.Character
--			-- Sequence of ship animations
--			-- Ensure the ship has a PrimaryPart for movement

--			setRelative:Fire(true, plr, ship)

--			---- Move forward/upward
--			--tweenModel(ship, TIS.TWEEN_INFO_SLOW, CFrame.new(waypoints.EarthTakeoff), objectCFrames).Completed:Connect(function()
--			-- Rotate to face upward
--			tweenModel(ship, TIS.TWEEN_INFO_FAST, (CFrame.lookAt(ship:GetPivot().Position, waypoints.SpaceExit)), objectCFrames).Completed:Connect(function()
--				-- Ascend to space
--				tweenModel(ship, TIS.TWEEN_INFO_SLOW, (CFrame.new(waypoints.SpaceExit) * ship:GetPivot().Rotation), objectCFrames).Completed:Connect(function()
--					toggleHatch(false)
--					-- Rotate to face place above mars
--					tweenModel(ship, TIS.TWEEN_INFO_FAST, CFrame.lookAt(ship:GetPivot().Position, waypoints.MarsApproach), objectCFrames).Completed:Connect(function()
--						-- Fly toward Mars
--						tweenModel(ship, TIS.TWEEN_INFO_SLOW, (CFrame.new(waypoints.MarsApproach) * ship:GetPivot().Rotation), objectCFrames).Completed:Connect(function()
--							-- Rotate to face downward toward Mars surface
--							tweenModel(ship, TIS.TWEEN_INFO_FAST, CFrame.lookAt(ship:GetPivot().Position, waypoints.MarsSurface), objectCFrames).Completed:Connect(function()
--								-- Descend to Mars surface
--								tweenModel(ship, TIS.TWEEN_INFO_SLOW, CFrame.new(ship:GetPivot().Position):Lerp(CFrame.new(waypoints.MarsSurface) * ship:GetPivot().Rotation, 0.85), objectCFrames).Completed:Connect(function()
--									-- Rotate to face forward upon landing
--									--tweenModel(ship, TIS.TWEEN_INFO_FAST, CFrame.new(waypoints.MarsSurface), objectCFrames).Completed:Connect(function()
--									--	game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Anchored = false
--									--end)
--									-- Rotate to face forward upon landing
--									tweenModel(ship, TIS.TWEEN_INFO_FAST, CFrame.new(waypoints.MarsSurface), objectCFrames).Completed:Connect(function()
--										setRelative:Fire(false, plr, ship)
--										task.wait(1.5)
--										print("undoing")
--										for i, v in pairs(workspace.CHARACTERS:GetChildren()) do
--											v:FindFirstChild("HumanoidRootPart").Anchored = false
--										end
--										char:FindFirstChild("HumanoidRootPart").Anchored = false
--									end)
--								end)
--							end)
--						end)
--					end)
--				end)
--			end)
--			--end)
--		end
--	end,

--	["Travel Ship Back"] = function(plr)
--		local char = plr.Character
--		if not char then return end
--		--print("flying back out "..plr.Name)
--		if not ship then
--			return
--		end
--		if not ship.PrimaryPart then
--			warn("Ship must have a PrimaryPart set for tweening.")
--			return
--		end

--		local currentTween = nil

--		print(3)
--		task.wait(1)
--		print(2)
--		task.wait(1)
--		print(1)
--		task.wait(1)

--		--char.Parent = ship
--		--char.Parent = ship
--		char:FindFirstChild("HumanoidRootPart").Anchored = true
--		local objectCFrames = {
--			{char, ship:GetPivot():ToObjectSpace(char:GetPivot())},
--			{workspace.NPCS.Captain, ship:GetPivot():ToObjectSpace(workspace.NPCS.Captain:GetPivot())}	
--		}
--		for i, v in pairs(workspace.CHARACTERS:GetChildren()) do
--			v:FindFirstChild("HumanoidRootPart").Anchored = true
--			table.insert(objectCFrames, {v, ship:GetPivot():ToObjectSpace(v:GetPivot())})
--		end
--		--ship = game.Players.LocalPlayer.Character
--		-- Sequence of ship animations
--		-- Ensure the ship has a PrimaryPart for movement

--		setRelative:Fire(true, plr, ship)

--		-- Rotate to face upward toward Mars surface
--		tweenModel(ship, TIS.TWEEN_INFO_FAST, (CFrame.lookAt((ship:GetPivot().Position)+Vector3.new(0, 10, 0), waypoints.MarsApproach)), objectCFrames).Completed:Connect(function()
--			-- Fly out mars's exit
--			tweenModel(ship, TIS.TWEEN_INFO_SLOW, (CFrame.new(waypoints.MarsApproach) * ship:GetPivot().Rotation), objectCFrames).Completed:Connect(function()
--				-- Look at to earth space entrance
--				tweenModel(ship, TIS.TWEEN_INFO_FAST, (CFrame.lookAt(ship:GetPivot().Position, waypoints.SpaceExit)), objectCFrames).Completed:Connect(function()
--					-- Go to earth's entrance
--					tweenModel(ship, TIS.TWEEN_INFO_SLOW, (CFrame.new(waypoints.SpaceExit) * ship:GetPivot().Rotation), objectCFrames).Completed:Connect(function()
--						-- Look at Earth's surface landing
--						tweenModel(ship, TIS.TWEEN_INFO_FAST, (CFrame.lookAt(ship:GetPivot().Position, waypoints.Start.Position)), objectCFrames).Completed:Connect(function()
--							toggleHatch(true)
--							-- Descend to the surface & landing
--							tweenModel(ship, TIS.TWEEN_INFO_SLOW, (waypoints.Start) * CFrame.Angles(0, math.rad(180), 0), objectCFrames).Completed:Connect(function()
--								toggleHatch(false)
--								setRelative:Fire(false, plr, ship)
--								task.wait(1.5)
--								for i, v in pairs(workspace.CHARACTERS:GetChildren()) do
--									v:FindFirstChild("HumanoidRootPart").Anchored = false
--								end
--								char:FindFirstChild("HumanoidRootPart").Anchored = false
--							end)
--						end)
--					end)
--				end)
--			end)
--		end)
--	end,
--	}

--	return {
--	["Actions"] = Actions,
--}