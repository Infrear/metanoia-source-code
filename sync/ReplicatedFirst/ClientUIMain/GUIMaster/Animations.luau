-- Services
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")
local TS = game:GetService("TweenService")
local DBS = game:GetService("Debris")
local RS = game:GetService("RunService")

-- Dependencies
local plr = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local plrGUI = plr.PlayerGui
local mouse = plr:GetMouse()

local Storage = RPS:WaitForChild("ClientStorage")
local SkillsUI = plrGUI:WaitForChild("SkillsMenu")
local skillsFrame = SkillsUI:WaitForChild("Holder").Overlay
local BillboardUIS = Storage:WaitForChild("BillboardUIs")

local Storage = RPS:WaitForChild("ClientStorage")
local gameSettings = require(Storage.Info.GameSettings)
local hlM = require(script.Highlights)
local combatSettings = gameSettings.CombatSettings
--local BillboardUIS = Storage:WaitForChild("BillboardUIs")
--local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))

-- Initialization
local AnimsManager = {}

-- Constants
AnimsManager.effectCooldown = 0.1/combatSettings.CombatSpeedMultiplier

AnimsManager.BASE_STIS = {
	[3] = TweenInfo.new(
		0.5/combatSettings.CombatSpeedMultiplier,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	["Pulse"] = TweenInfo.new(
		0.2/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out,
		0,
		true
	),
	["Pulse2"] = TweenInfo.new(
		0.2/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out,
		0,
		false
	),
	["FadeUp"] = TweenInfo.new(
		1/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quart, 
		Enum.EasingDirection.Out
	),
	["FadeUp2"] = TweenInfo.new(
		7.5/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quart, 
		Enum.EasingDirection.Out
	),
	["FadeIn"] = TweenInfo.new(
		0.3/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	),
	["FadeInMid"] = TweenInfo.new(
		0.55/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	),
	["FadeInSlow"] = TweenInfo.new(
		0.85/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	),
	["FadeOut"] = TweenInfo.new(
		1.2/combatSettings.CombatSpeedMultiplier, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	),
}

AnimsManager.FTIS = {
	["SpazIn"] = TweenInfo.new(
		0.125,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	),
	["SpazLoop"] = TweenInfo.new(
		0.105,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		-1,
		true,
		0
	),
	["SpazOut"] = TweenInfo.new(
		0.105,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	),
	["Poof"] = TweenInfo.new(
		0.125,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out,
		0,
		true
	),	
} -- flat tween infos

AnimsManager.STIS = {} -- current set of combat based tween infos

AnimsManager.buts = {}
AnimsManager.CurrentTri = nil

for i, v in pairs(skillsFrame.Tris:GetChildren()) do
	AnimsManager.buts[v] = {
		LTES = {},
		TES = {},
		Cons = {},
		Default = v.Size,
		Hover = UDim2.new(
			v.Size.X.Scale,-- * 1.1,
			v.Size.X.Offset,
			v.Size.Y.Scale * 1.4,
			v.Size.Y.Offset
		),
		Click = UDim2.new(
			v.Size.X.Scale,--  * 1.2,
			v.Size.X.Offset,
			v.Size.Y.Scale * 1.5,
			v.Size.Y.Offset
		),
		Shrink = UDim2.new(
			v.Size.X.Scale,-- * 0.125, 
			v.Size.X.Offset,
			v.Size.Y.Scale * 0.005, 
			v.Size.Y.Offset
		),
		defaultColor = v.InTri.ImageColor3,
		hoverColor = Color3.new(1, 1, 1),
		clickColor = Color3.new(0.584314, 0.584314, 0.584314),
		inClick = false,
		open = false,
		stopEv = Instance.new("BindableEvent", script)
	}
end

AnimsManager.LastCCSM = plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1

-- Local Variables
local modelVals = {}

-- Local Functions

-- Global Functions
function AnimsManager.FocusOnTri(tri)
	if not AnimsManager.buts[tri] then return end
	local sme = AnimsManager.buts[tri]
	
	if not sme.open then
		tri.Size = sme.Shrink
	else
		sme.stopEv:Fire()
	end
	AnimsManager.CurrentTri = tri
	--coroutine.wrap(function()
	--	print(AnimsManager.CurrentTri)
	--	task.wait(2)
	--	print(AnimsManager.CurrentTri)
	--end)() <-- benchmark

	sme.TES[tri.InTri] = TS:Create(tri.InTri, AnimsManager.FTIS.SpazIn, {ImageColor3 = sme.defaultColor})
	sme.TES[tri.InTri.SubTri] = TS:Create(tri.InTri.SubTri, AnimsManager.FTIS.SpazIn, {ImageColor3 = sme.defaultColor})
	sme.TES[tri.InTri]:Play()
	sme.TES[tri.InTri.SubTri]:Play()
	
	sme.open = true
	tri.Visible = true

	if sme.TES[tri] then
		if sme.TES[tri].PlaybackState == Enum.PlaybackState.Playing then
			sme.TES[tri]:Cancel()
		end
	end
	
	sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazIn, {Size = sme.Default})	
	local con
	local interrupted = false
	con = sme.stopEv.Event:Connect(function()
		con:Disconnect()
		interrupted = true
		sme.TES[tri]:Cancel()
	end)
	sme.TES[tri]:Play()
	sme.TES[tri].Completed:Wait()
	if con then con:Disconnect() end
	
	if interrupted then
		return
	end
	
	if sme.LTES[tri] then
		if sme.LTES[tri].PlaybackState == Enum.PlaybackState.Playing then
			sme.LTES[tri]:Cancel()
		end
	end
	sme.LTES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazLoop, {Size = sme.Hover})
	sme.LTES[tri]:Play()

	if con then con:Disconnect() end
end

function AnimsManager.CleanUpTri(tri)
	if not tri and AnimsManager.CurrentTri then tri = AnimsManager.CurrentTri end
	if not tri or not AnimsManager.buts[tri] then return end
	local sme = AnimsManager.buts[tri]
	for i, v in pairs(sme.Cons) do
		v:Disconnect()
	end
	
	for i, v in pairs(sme.LTES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end

	for i, v in pairs (sme.TES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end

	AnimsManager.CurrentTri = nil
	sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazOut, {Size = sme.Shrink})
	local con1, con2
	local interrupted = false
	local oldTri = AnimsManager.CurrentTri
	con1 = sme.stopEv.Event:Connect(function()
		con1:Disconnect()
		if con2 then con2:Disconnect() end
		interrupted = true
	end)
	con2 = sme.TES[tri].Completed:Connect(function()
		con2:Disconnect()
		if con1 then con1:Disconnect() end
		if not interrupted then
			sme.open = false
			tri.Visible = false
		end
	end)
	sme.TES[tri]:Play()
end

function AnimsManager.UpdateTri(input, close)
	local tri = AnimsManager.CurrentTri
	if not tri or not AnimsManager.buts[tri] then return end
	local sme = AnimsManager.buts[tri]

	if input == "MouseClick" then
		if not sme.inClick then
			sme.InClick = true
			if sme.TES[tri] then
				if sme.TES[tri].PlaybackState == Enum.PlaybackState.Playing then
					sme.TES[tri]:Cancel()
				end
			end
			sme.TES[tri.InTri] = TS:Create(tri.InTri, AnimsManager.FTIS.Poof, {ImageColor3 = sme.clickColor})
			sme.TES[tri.InTri.SubTri] = TS:Create(tri.InTri.SubTri, AnimsManager.FTIS.Poof, {ImageColor3 = sme.clickColor})
			sme.TES[tri.InTri]:Play()
			sme.TES[tri.InTri.SubTri]:Play()
			sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazIn, {Size = sme.Click})
			sme.TES[tri]:Play()
			sme.TES[tri].Completed:Wait()
			sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazOut, {Size = sme.defaultSize})
			sme.TES[tri]:Play()
			sme.InClick = false
		end
	elseif input == "MouseEnter" then
		if sme.TES[tri.InTri] then
			if sme.TES[tri.InTri].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[tri.InTri]:Cancel()
			end
		end

		if not sme.InClick then
			if sme.LTES[tri] and sme.LTES[tri].PlaybackState == Enum.PlaybackState.Playing then
				sme.LTES[tri]:Pause()
			end
			--sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazIn, {Size = sme.Hover})
			--sme.TES[tri]:Play()
		end

		sme.TES[tri.InTri] = TS:Create(tri.InTri, AnimsManager.FTIS.SpazIn, {ImageColor3 = sme.hoverColor})
		sme.TES[tri.InTri.SubTri] = TS:Create(tri.InTri.SubTri, AnimsManager.FTIS.SpazIn, {ImageColor3 = sme.hoverColor})
		sme.TES[tri.InTri]:Play()
		sme.TES[tri.InTri.SubTri]:Play()
	elseif input == "MouseLeave" then
		if sme.TES[tri.InTri] then
			if sme.TES[tri.InTri].PlaybackState == Enum.PlaybackState.Playing then
				sme.TES[tri.InTri]:Cancel()
			end
		end

		if not sme.InClick then
			--sme.TES[tri] = TS:Create(tri, AnimsManager.FTIS.SpazOut, {Size = sme.Default})
			--sme.TES[tri]:Play()
			if sme.LTES[tri] and sme.LTES[tri].PlaybackState == Enum.PlaybackState.Paused then
				sme.LTES[tri]:Play()
			end
		end

		sme.TES[tri.InTri] = TS:Create(tri.InTri, AnimsManager.FTIS.SpazOut, {ImageColor3 = sme.defaultColor})
		sme.TES[tri.InTri.SubTri] = TS:Create(tri.InTri.SubTri, AnimsManager.FTIS.SpazOut, {ImageColor3 = sme.defaultColor})
		sme.TES[tri.InTri]:Play()
		sme.TES[tri.InTri.SubTri]:Play()
	end
	
	if close then
		AnimsManager.CleanUpTri(tri)
	end	
end

function AnimsManager.HighlightTE(model, Colors, killshot)
	--local model = script.Parent
	--local DealDamage = model:WaitForChild("DealDamage", 20)
	--local AddHealth = model:WaitForChild("AddHealth", 20)

	--if (not DealDamage or not AddHealth) and not PLRS:GetPlayerFromCharacter(model) then return end
	--if PLRS:GetPlayerFromCharacter(model) then
	--	repeat
	--		DealDamage = model:WaitForChild("DealDamage", 20)
	--	until
	--	not PLRS:GetPlayerFromCharacter(model) or (DealDamage and AddHealth)
	--	if not PLRS:GetPlayerFromCharacter(model) then return end
	--else
	--	return
	--end

	local mVals = modelVals[model]

	if not mVals then
		modelVals[model] = {
			TE1 = nil, 
			TE2 = nil,
			hl = nil,
			canEffect = true,
			addUp = 0
		}
		mVals = modelVals[model]
	end

	-- cleanup
	if mVals.TE1 then
		if mVals.TE1.PlaybackState == Enum.PlaybackState.Playing then
			mVals.TE1:Cancel()
		end
	end
	--if mVals.TE2 then
	--	if mVals.TE2.PlaybackState == Enum.PlaybackState.Playing then
	--		mVals.TE2:Cancel()
	--	end
	--end
	if mVals.hl then
		mVals.hl:Destroy()
	end
	--if ind then
	--	ind:Destroy()
	--end

	mVals.hl = hlM.SpawnHighlight(model, {
		Enabled = false,
		FillColor = Color3.new(1, 0.333333, 1),
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 0.25,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	})


	local chosenColor = math.random(-100, 100)/100

	if chosenColor >= 0 then
		chosenColor = Colors.Base:Lerp(Colors.High, chosenColor)
	else
		chosenColor = Colors.Base:Lerp(Colors.Low, -chosenColor)
	end

	if killshot and mVals.hl then
		--print("set")
		mVals.hl.FillColor = Colors.Killshot
	end

	if mVals.hl then
		mVals.hl.Adornee = model
		mVals.hl.Enabled = true
	end


	if mVals.hl then
		mVals.TE1 = TS:Create(mVals.hl, AnimsManager.STIS[3], {FillTransparency = 1, OutlineTransparency = 1})
		mVals.TE1:Play()
	end

	local con1, con2
	if mVals.hl then
		con1 = mVals.TE1.Completed:Connect(function()
			con1:Disconnect()
			mVals.hl:Destroy()
		end)
	end
	task.wait(AnimsManager.effectCooldown/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1))
	mVals.canEffect = true
end

-- Loose Threads
for i, v in pairs(AnimsManager.BASE_STIS) do
	AnimsManager.STIS[i] = TweenInfo.new(
		v.Time/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1),
		v.EasingStyle,
		v.EasingDirection,
		v.RepeatCount,
		v.Reverses,
		v.DelayTime
	)
end


-- Untouchables
AnimsManager.UITransitions = {}

AnimsManager.UITransitions["BattleUIL"] = {
	TES = {},
	stopEv = Instance.new("BindableEvent", script)
}

local slideInTI = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local slideOutTI = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local settleTI = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local battleUISpread = 8

AnimsManager.UITransitions["BattleUIL"].InFunction = function(ui, right)
	local info = right and AnimsManager.UITransitions["BattleUIR"] or AnimsManager.UITransitions["BattleUIL"]
	info.stopEv:Fire()
	local interrupted = false
	local con
	con = info.stopEv.Event:Connect(function()
		interrupted = true
		con:Disconnect()
	end)

	ui.Enabled = true
	local holder = ui:FindFirstChild("Holder")
	if not holder then return end

	-- Slide the whole billboard in from the right via StudsOffset
	ui.StudsOffset = Vector3.new(battleUISpread * (right and 1 or -1), 0, 0) -- start far right
	info.TES["slideR"] = TS:Create(ui, slideInTI, { StudsOffset = Vector3.new(4 * (right and 1 or -1), 0, 0) })
	info.TES["slideR"]:Play()

	-- Stagger each child frame glitching in
	local children = holder:GetChildren()
	for i, frame in ipairs(children) do
		if not frame:IsA("Frame") and not frame:IsA("ImageLabel") then continue end
		task.spawn(function()
			task.wait((i - 1) * 0.045)
			if interrupted then return end
			local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")

			-- Store real values
			local realAspect = 1.479
			local realPos = right and Storage.BillboardUIs.Combat.RightBattleHeader.Holder:FindFirstChild(frame.Name).Position or Storage.BillboardUIs.Combat.LeftBattleHeader.Holder:FindFirstChild(frame.Name).Position

			-- Start flat and offset
			aspect.AspectRatio = 12
			frame.Position = UDim2.new(realPos.X.Scale + 0.3, realPos.X.Offset, realPos.Y.Scale, realPos.Y.Offset)

			-- Glitch step 1: partial snap
			task.wait(0.04)
			if interrupted then return end
			aspect.AspectRatio = 8
			frame.Position = UDim2.new(realPos.X.Scale + 0.08, realPos.X.Offset, realPos.Y.Scale, realPos.Y.Offset)

			-- Glitch step 2: full settle
			task.wait(0.035)
			if interrupted then return end
			info.TES[frame] = TS:Create(frame, settleTI, { Position = realPos })
			info.TES[aspect] = TS:Create(aspect, settleTI, { AspectRatio = realAspect })
			info.TES[aspect]:Play()
			info.TES[frame]:Play()
			
			info.TES[aspect].Completed:Once(function()
				if interrupted then return end
				if frame.Underlay.UIGradient:FindFirstChildOfClass("UIAspectRatioConstraint") then
					frame.Underlay.UIGradient:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Overlay
				end
				if frame.Key.UIAspectRatioConstraint:FindFirstChildOfClass("UIAspectRatioConstraint") then
					frame.Key.UIAspectRatioConstraint:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Underlay
				end
			end)
		end)
	end

	if con then con:Disconnect() end
end

AnimsManager.UITransitions["BattleUIL"].OutFunction = function(ui, right)
	if not ui or not ui.Parent then return end
	local info = right and AnimsManager.UITransitions["BattleUIR"] or AnimsManager.UITransitions["BattleUIL"]
	info.stopEv:Fire()
	local interrupted = false
	local con
	con = info.stopEv.Event:Connect(function()
		interrupted = true
		con:Disconnect()
	end)

	local holder = ui:FindFirstChild("Holder")

	for i, frame in ipairs(holder:GetChildren()) do
		if not frame:IsA("Frame") and not frame:IsA("ImageLabel") then continue end
		local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")
		if frame.Overlay:FindFirstChildOfClass("UIAspectRatioConstraint") then
			frame.Overlay:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Underlay.UIGradient
		end
		if frame.Underlay:FindFirstChildOfClass("UIAspectRatioConstraint") then
			frame.Underlay:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Key.UIAspectRatioConstraint
		end

		info.TES[aspect] = TS:Create(aspect, settleTI, { AspectRatio = 8 })
		info.TES[aspect]:Play()
	end

	info.TES["slideOutR"] = TS:Create(ui, slideOutTI, { StudsOffset = Vector3.new(battleUISpread * (right and 1 or -1), 0, 0) })
	info.TES["slideOutR"]:Play()
	info.TES["slideOutR"].Completed:Once(function()
		if not interrupted then
			ui.Enabled = false
		end
	end)
end

AnimsManager.UITransitions["BattleUIL"].Reset = function(ui, right)
	if not ui or not ui.Parent then return end
	ui.StudsOffset = Vector3.new(battleUISpread * (right and 1 or -1), 0, 0)
	

	for i, frame in ipairs(ui.Holder:GetChildren()) do
		if not frame:IsA("Frame") and not frame:IsA("ImageLabel") then continue end
		local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")

		-- Store real values
		local realAspect = 1.479
		local realPos = right and Storage.BillboardUIs.Combat.RightBattleHeader.Holder:FindFirstChild(frame.Name).Position or Storage.BillboardUIs.Combat.LeftBattleHeader.Holder:FindFirstChild(frame.Name).Position

		-- Start flat and offset
		aspect.AspectRatio = 8
		frame.Position = UDim2.new(realPos.X.Scale + 0.3, realPos.X.Offset, realPos.Y.Scale, realPos.Y.Offset)
		if frame.Overlay:FindFirstChildOfClass("UIAspectRatioConstraint") then
			frame.Overlay:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Underlay.UIGradient
		end
		if frame.Underlay:FindFirstChildOfClass("UIAspectRatioConstraint") then
			frame.Underlay:FindFirstChildOfClass("UIAspectRatioConstraint").Parent = frame.Key.UIAspectRatioConstraint
		end
	end
end


AnimsManager.UITransitions["BattleUIR"] = {
	TES = {},
	stopEv = Instance.new("BindableEvent", script)
}

AnimsManager.UITransitions["BattleUIR"].InFunction = function(ui)
	--ui.Enabled = true
	AnimsManager.UITransitions["BattleUIL"].InFunction(ui, true)
end
AnimsManager.UITransitions["BattleUIR"].OutFunction = function(ui)
	--ui.Enabled = false
	AnimsManager.UITransitions["BattleUIL"].OutFunction(ui, true)
end

AnimsManager.UITransitions["BattleUIR"].Reset = function(ui, right)
	if not ui or not ui.Parent then return end
	AnimsManager.UITransitions["BattleUIL"].Reset(ui, true)
end

-- Constants for Heart UI
local HEART_TARGET_SIZE = UDim2.fromScale(1, 1) -- Adjust this to your preferred "Full" size
local HEART_BLOOP_TI = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HEALTH_FILL_TI = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

AnimsManager.UITransitions["Heart"] = {
	Poses = {
		["Holder"] = {
			TargetSize = HEART_TARGET_SIZE,
		}
	},
	OGSeq = RPS.ClientStorage.BillboardUIs.Combat.Heart.Holder.In.UIGradient.Color,
	TES = {},
	stopEv = Instance.new("BindableEvent", script)
}

AnimsManager.UITransitions["Heart"].InFunction = function(ui, healthRatio, oldRat, indColor)
	-- healthRatio: a number from 0 to 1 (current health / max health)
	local info = AnimsManager.UITransitions["Heart"]
	info.stopEv:Fire()

	local interrupted = false
	local con
	con = info.stopEv.Event:Connect(function()
		--interrupted = true
		con:Disconnect()
	end)

	local holder = ui:FindFirstChild("Holder")
	if not holder then return end

	-- Target the Gradient inside the "In" heart frame
	local inFrame = holder:FindFirstChild("In", true)
	local gradient = inFrame and inFrame:FindFirstChild("UIGradient")

	-- 1. Pre-setup: Full reset while invisible
	holder.Size = UDim2.fromScale(0, 0)
	ui.Enabled = true

	local correction = 0.15

	local targetOffsetX = (0 - (1 - healthRatio)) + correction
	
	-- We calculate the Offset based on health before showing it
	-- Adjust the math here if your gradient alignment differs
	local startOffset = oldRat and ((0 - (1 - oldRat)) + correction) or correction
	gradient.Offset = Vector2.new(startOffset, 0)

	-- 2. Bounce In
	if info.TES[holder] then info.TES[holder]:Cancel() end
	info.TES[holder] = TS:Create(holder, HEART_BLOOP_TI, {Size = info.Poses.Holder.TargetSize})
	info.TES[holder]:Play()
	
	if oldRat and gradient then
		-- Wait for the bounce to nearly finish before "filling" the bar if you want a delay
		task.wait(0.2)

		-- 3. Tween the Gradient (The "Health Fill" effect)
		if not interrupted then
			if info.TES[gradient] then info.TES[gradient]:Cancel() end

			info.TES[gradient] = TS:Create(gradient, HEALTH_FILL_TI, {Offset = Vector2.new(targetOffsetX, 0)})
			info.TES[gradient]:Play()
		else
			if con then con:Disconnect() end
			return
		end

		if not indColor then
			if oldRat > healthRatio then
				indColor = Color3.new(1, 1, 1)
			else
				indColor = Color3.new(0.333333, 1, 0.498039)
			end
		end
		local frames = 8
		local speed = 0.01

		local originalColour = info.OGSeq.Keypoints[1].Value
		for i = frames, 0, -1 do
			task.wait((speed/3) )
			if interrupted then
				if con then con:Disconnect() end
				return
			end
			local currentShade = indColor:lerp(originalColour, i / frames)
			local newSequence = ColorSequence.new{
				ColorSequenceKeypoint.new(info.OGSeq.Keypoints[1].Time, currentShade),
				ColorSequenceKeypoint.new(info.OGSeq.Keypoints[2].Time, currentShade),
				info.OGSeq.Keypoints[3],
				info.OGSeq.Keypoints[4],
			}
			gradient.Color =  newSequence
		end

		for i = 0, frames, 1 do
			task.wait(speed*1.5)
			if interrupted then
				if con then con:Disconnect() end
				return
			end
			local currentShade = indColor:lerp(originalColour, i / frames)
			local newSequence = ColorSequence.new{
				ColorSequenceKeypoint.new(info.OGSeq.Keypoints[1].Time, currentShade),
				ColorSequenceKeypoint.new(info.OGSeq.Keypoints[2].Time, currentShade),
				info.OGSeq.Keypoints[3],
				info.OGSeq.Keypoints[4],
			}
			gradient.Color =  newSequence
		end
		
	elseif gradient then
		gradient.Offset = Vector2.new(targetOffsetX, 0)
	end
	
	if con then con:Disconnect() end
end

AnimsManager.UITransitions["Heart"].OutFunction = function(ui)
	if not ui or not ui.Parent then return end
	local info = AnimsManager.UITransitions["Heart"]
	info.stopEv:Fire()

	local holder = ui:FindFirstChild("Holder")
	if holder then
		if info.TES[holder] then info.TES[holder]:Cancel() end

		info.TES[holder] = TS:Create(holder, AnimsManager.STIS.FadeIn, {Size = UDim2.fromScale(0, 0)})
		info.TES[holder].Completed:Connect(function()
			ui.Enabled = false
		end)
		info.TES[holder]:Play()
		info.TES[holder].Completed:Wait()
	end

	ui:Destroy()
end

AnimsManager.UITransitions["Heart"].Reset = function(ui)
	local info = AnimsManager.UITransitions["Heart"]
	info.stopEv:Fire()

	local holder = ui:FindFirstChild("Holder")
	if holder then
		holder.Size = UDim2.fromScale(0, 0)

		-- Reset Gradient to "Full" (fully filled)
		local inFrame = holder:FindFirstChild("In", true)
		local gradient = inFrame and inFrame:FindFirstChild("UIGradient")
		if gradient then
			gradient.Offset = Vector2.new(-0.5, 0) -- Adjust to your "Full" offset
		end
	end

	ui.Enabled = false
end

-- Constants for the Target UI
local TARGET_RING_SIZES = {
	OutRing = UDim2.fromScale(0.567, 0.499),
	MidRing = UDim2.fromScale(0.5, 0.43),
	InRing = UDim2.fromScale(0.485, 0.385)
}

-- TweenInfo for the "Bloop" effect
local BloopTI = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TriTI = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local LineTI = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) 

AnimsManager.UITransitions["Target"] = {
	Poses = {
		["InRing"] = { ObjName = "InRing", TargetSize = TARGET_RING_SIZES.InRing },
		["MidRing"] = { ObjName = "MidRing", TargetSize = TARGET_RING_SIZES.MidRing },
		["OutRing"] = { ObjName = "OutRing", TargetSize = TARGET_RING_SIZES.OutRing },
		["InTris"] = { ObjName = "InTris", TargetSize = UDim2.fromScale(1.136, 1)},
		["OutTris"] = { ObjName = "OutTris", TargetSize = UDim2.fromScale(1.136, 1)},
	},
	TES = {},
	stopEv = Instance.new("BindableEvent", script),
	cons = {}
	--[[
	
	Poses = {
		["InRing"] = {
			InTE = {
				Size = UDim2.fromScale(0.401, 0.353),
			},
			OutTE = {
				Size = UDim2.fromScale(0.01, 0.01),
			},
			TI = AnimsManager.STIS.FadeIn,
		},
		["MidRing"] = {
			InTE = {
				Size = UDim2.fromScale(0.454, 0.4),
			},
			OutTE = {
				Size = UDim2.fromScale(0.01, 0.01),
			},
			TI = AnimsManager.STIS.FadeIn,
		},
		["OutRing"] = {
			InTE = {
				Size = UDim2.fromScale(0.567, 0.499),
			},
			OutTE = {
				Size = UDim2.fromScale(0.01, 0.01),
			},
			TI = AnimsManager.STIS.FadeIn,
		},
	},
	TES = {},
	stopEv = Instance.new("BindableEvent", script)
	]]
}

AnimsManager.UITransitions["Target"].InFunction = function(ui, multi, color1, color2)
	local info = AnimsManager.UITransitions["Target"]
	info.stopEv:Fire(multi)

	local myClone = nil
	local interrupted = false
	local con = info.stopEv.Event:Once(function(mult)
		interrupted = ((not multi) and  mult) or false
		if interrupted and myClone then myClone:Destroy() end
	end)

	local altui = plrGUI:FindFirstChild("TargetOuter")
	local last = nil
	if altui then -- do the linestuff first
		local objPos, isInView =  workspace.CurrentCamera:WorldToScreenPoint(ui.Parent:GetPivot().Position) 
		if isInView then
			altui.Enabled = true
			local aholder = altui:FindFirstChild("Holder")
			myClone = aholder:FindFirstChild('LineTris'):Clone()
			myClone.Name = "Linny"
			myClone.Parent = aholder
			--aholder.Position = UDim2.fromOffset(objPos.X, objPos.Y)

			-- 2. Procedural Triangle Scaling Loop
			coroutine.wrap(function()
				if info.cons[myClone] then info.cons[myClone]:Disconnect() end
				myClone.Visible = true
				info.cons[myClone] = RS.RenderStepped:Connect(function()
					if not interrupted and ui and ui.Parent then
						local objPos, isInView =  workspace.CurrentCamera:WorldToScreenPoint(ui.Parent:GetPivot().Position) 
						if isInView then
							myClone.Position = UDim2.fromOffset(objPos.X, objPos.Y)
						end
					else
						info.cons[myClone]:Disconnect()
					end
				end)
				for i, triFrame in pairs(myClone:GetChildren()) do
					if triFrame:IsA("Frame") then
						local top = triFrame:FindFirstChild("TopTri")
						local bottom = triFrame:FindFirstChild("BottomTri")

						if top and bottom then
							if info.TES[top] and info.TES[top].PlaybackState == Enum.PlaybackState.Playing then info.TES[top]:Cancel() end
							if info.TES[bottom] and info.TES[bottom].PlaybackState == Enum.PlaybackState.Playing then info.TES[bottom]:Cancel() end

							local randColor = math.random(1, 3) == 3 and (color1 or Color3.fromRGB(191, 0, 255)) or (color2 or Color3.fromRGB(106, 0, 255))
							
							local scale = 0
							top.Size = UDim2.fromScale(3, 0.5)
							top.Position = UDim2.fromScale(0, 0.25)
							top.ImageTransparency = 0
							top.ImageColor3 = randColor 
							
							bottom.Size =  UDim2.fromScale(3, 0.5)
							bottom.Position = UDim2.fromScale(0, 0.75)
							bottom.ImageTransparency = 0
							bottom.ImageColor3 = randColor 
							
							-- Simultaneous X scale
							info.TES[top] = TS:Create(top, LineTI, {Size = UDim2.fromScale(scale, top.Size.Y.Scale), ImageTransparency = 0, Position = UDim2.fromScale(-0.05, top.Position.Y.Scale)})
							info.TES[bottom] = TS:Create(bottom, LineTI, {Size = UDim2.fromScale(scale, bottom.Size.Y.Scale), ImageTransparency = 0, Position = UDim2.fromScale(-0.05, bottom.Position.Y.Scale)})
							info.TES[top]:Play() 
							last = info.TES[bottom] 
							last:Play()
						end
						--task.wait(0.1)
					end
				end
			end)()
		end
	end
	
	if last then
		task.wait(last.TweenInfo.Time - 0.275)
		if interrupted then return end
		coroutine.wrap(function()
			if last and last.PlaybackState == Enum.PlaybackState.Playing then
				repeat wait() if interrupted then return end until last.PlaybackState ~= Enum.PlaybackState.Playing
			end
			--print("closed")
			altui.Enabled = false
			if con then con:Disconnect() end
			if info.con3 then info.con3:Disconnect() end
		end)()
	end
	--ui.Enabled = true
	local holder = ui.Holder
	local lastTween = nil

	-- 1. Sequential Ring Animation (Out -> Mid -> In)
	local ringOrder = {"OutRing", "MidRing", "InRing", "InTris", "OutTris"}

	coroutine.wrap(function()
		for i, name in ipairs(ringOrder) do
			if interrupted then break end

			local ring = holder:FindFirstChild(name)

			if ring then
				if i <= 3 then
					if info.TES[ring] then info.TES[ring]:Cancel() end

					ring.ImageColor3 = color1 or ring.ImageColor3
					info.TES[ring] = TS:Create(ring, BloopTI, {Size = info.Poses[name].TargetSize})
					lastTween = info.TES[ring]
					info.TES[ring]:Play()
					task.wait(0.125) -- The "Bloop" stagger
				else
					ring.Size = info.Poses[name].TargetSize
				end
			end
		end
	end)()


	if lastTween then
		--lastTween.Completed:Wait()
		task.wait(lastTween.TweenInfo.Time - 0.5)
	end

	
	-- 2. Procedural Triangle Scaling Loop
	coroutine.wrap(function()
		local allTris = {}
		-- Collect all InTris and OutTris
		for _, container in pairs({holder:FindFirstChild("InTris"), holder:FindFirstChild("OutTris")}) do
			if container then
				for _, triFrame in pairs(container:GetChildren()) do
					if triFrame:IsA("Frame") then table.insert(allTris, triFrame) end
				end
			end
		end

		while ui and ui.Parent and not interrupted do
			-- Pick 2-3 random tris to animate per "tick"
			for i = 1, math.random(4, 8) do
				local triFrame = allTris[math.random(1, #allTris)]
				local top = triFrame:FindFirstChild("TopTri")
				local bottom = triFrame:FindFirstChild("BottomTri")

				if top and bottom then
					local randColor = math.random(1, 3) == 3 and (color1 or Color3.fromRGB(191, 0, 255)) or (color2 or Color3.fromRGB(106, 0, 255))
					local randScale = math.random(3, 10) / 6.5 -- Random scale between 0.3 and 1.0

					-- Simultaneous X scale
					TS:Create(top, TriTI, {Size = UDim2.new(randScale, 0, top.Size.Y.Scale, 0), ImageColor3 = randColor}):Play()
					local bt = TS:Create(bottom, TriTI, {Size = UDim2.new(randScale, 0, bottom.Size.Y.Scale, 0), ImageColor3 = randColor})
					bt:Play()

					-- Reset them back after a short delay
					coroutine.wrap(function()
						task.wait(TriTI.Time + (math.random(5, 15)/100))
						if not interrupted then
							TS:Create(top, TriTI, {Size = UDim2.new(0, 0, top.Size.Y.Scale, 0), ImageColor3 = Color3.fromRGB(106, 0, 255)}):Play()
							TS:Create(bottom, TriTI, {Size = UDim2.new(0, 0, bottom.Size.Y.Scale, 0), ImageColor3 = Color3.fromRGB(106, 0, 255)}):Play()
						end
					end)()
				end
			end
			task.wait(math.random(1, 3) / 10)
		end
	end)()
end

AnimsManager.UITransitions["Target"].OutFunction = function(ui, multi) --> maybe make a select function later
	if not ui or not ui.Parent then return end
	local info = AnimsManager.UITransitions["Target"]
	info.stopEv:Fire(multi)

	local interrupted = false
	local con = info.stopEv.Event:Once(function(mult)
		interrupted = ((not multi) and  mult) or false
	end)
	
	local holder = ui.Holder
	local lastTween = nil

	-- Shrink rings and triangles
	for i, v in pairs(holder.InTris:GetChildren()) do
		if v:IsA("Frame") and v.Name == "InTri" then
			local top = v:FindFirstChild("TopTri")
			local bottom = v:FindFirstChild("BottomTri")
			if top then
				if info.TES[top] and info.TES[top].PlaybackState == Enum.PlaybackState.Playing then 
					info.TES[top]:Cancel() 
				end
				info.TES[top] = TS:Create(top, AnimsManager.STIS.FadeOut, {Size = UDim2.fromScale(0, top.Size.Y.Scale)})
				lastTween = info.TES[top]
				info.TES[top]:Play()
			end
			if bottom then
				if info.TES[bottom] and info.TES[bottom].PlaybackState == Enum.PlaybackState.Playing then 
					info.TES[bottom]:Cancel() 
				end
				info.TES[bottom] = TS:Create(bottom, AnimsManager.STIS.FadeOut, {Size = UDim2.fromScale(0, bottom.Size.Y.Scale)})
				lastTween = info.TES[bottom]
				info.TES[bottom]:Play()
			end
		end
	end
	
	for i, v in pairs(holder.OutTris:GetChildren()) do
		if v:IsA("Frame") and v.Name == "OutTri" then
			local top = v:FindFirstChild("TopTri")
			local bottom = v:FindFirstChild("BottomTri")
			if top then
				if info.TES[top] and info.TES[top].PlaybackState == Enum.PlaybackState.Playing then 
					info.TES[top]:Cancel() 
				end
				info.TES[top] = TS:Create(top, AnimsManager.STIS.FadeOut, {Size = UDim2.fromScale(0, top.Size.Y.Scale)})
				lastTween = info.TES[top]
				info.TES[top]:Play()
			end
			if bottom then
				if info.TES[bottom] and info.TES[bottom].PlaybackState == Enum.PlaybackState.Playing then 
					info.TES[bottom]:Cancel() 
				end
				info.TES[bottom] = TS:Create(bottom, AnimsManager.STIS.FadeOut, {Size = UDim2.fromScale(0, bottom.Size.Y.Scale)})
				lastTween = info.TES[bottom]
				info.TES[bottom]:Play()
			end
		end
	end

	--if lastTween then
	--	lastTween.Completed:Wait()
	--end

	-- 1. Sequential Ring Animation (Out -> Mid -> In)
	local ringOrder = {"InRing", "MidRing", "OutRing", "InTris", "OutTris"}

	for i, name in ipairs(ringOrder) do
		local ring = holder:FindFirstChild(name)
		if ring then
			if info.TES[ring] then info.TES[ring]:Cancel() end

			info.TES[ring] = TS:Create(ring, AnimsManager.STIS.FadeIn, {Size = UDim2.fromScale(0, 0)})
			lastTween = info.TES[ring]
			info.TES[ring]:Play()
			if i <= 2 then
				task.wait(0.1)
			end
		end
	end

	if lastTween and lastTween.PlaybackState == Enum.PlaybackState.Playing then
		lastTween.Completed:Wait()
	end
	if con then con:Disconnect() end
	ui:Destroy()
	--ui.Enabled = false
end

AnimsManager.UITransitions["Target"].Reset = function(ui, multi)
	local info = AnimsManager.UITransitions["Target"]
	if not multi then
		info.stopEv:Fire()
	end

	local altui = plrGUI:FindFirstChild("TargetOuter")
	if altui then -- do the linestuff first
		altui.Enabled = false
	end
	
	local holder = ui.Holder
	-- Reset Rings
	for name, data in pairs(info.Poses) do
		local obj = holder:FindFirstChild(name)
		if obj then
			if info.TES[obj] then info.TES[obj]:Cancel() end
			obj.Size = UDim2.fromScale(0, 0)
		end
	end

	-- Reset Triangles
	local function resetTris(containerName)
		local container = holder:FindFirstChild(containerName)
		if container then
			for _, triFrame in pairs(container:GetChildren()) do
				local top = triFrame:FindFirstChild("TopTri")
				local bottom = triFrame:FindFirstChild("BottomTri")
				if top then top.Size = UDim2.new(0, 0, top.Size.Y.Scale, 0) end
				if bottom then bottom.Size = UDim2.new(0, 0, bottom.Size.Y.Scale, 0) end
			end
		end
	end

	resetTris("InTris")
	resetTris("OutTris")

	--ui.Enabled = false
end

AnimsManager.UITransitions["SkillMenu"] = {
	Poses = {
		["Backg1"] = {
			InTE = {
				Position = plrGUI.SkillsMenu.Holder.Overlay.Backg1.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.Backg1.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg1.Rotation,
			},
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.Backg1.Position.X.Scale, 0, -0.8, 0),
				Size = UDim2.new(0.01, 0, 0.01, 0),
				Rotation = 30,
			},
			TI = AnimsManager.STIS.FadeIn,
			Obj = plrGUI.SkillsMenu.Holder.Overlay.Backg1,
		},
		["Backg2"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.Backg2.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.Backg2.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg2.Rotation,
			},
			OutTE = {
				Position = UDim2.new(-1.5, 0, plrGUI.SkillsMenu.Holder.Overlay.Backg2.Position.Y.Scale, 0),
				Size = UDim2.new(0.01, 0, 0.01, 0),
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg2.Rotation,
			},
			TI = AnimsManager.STIS.FadeIn,
			Obj = plrGUI.SkillsMenu.Holder.Overlay.Backg2,
		},
		["Backg3"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.Backg3.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.Backg3.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg3.Rotation,
			},
			OutTE = {
				Position = UDim2.new(-1.5, 0, plrGUI.SkillsMenu.Holder.Overlay.Backg2.Position.Y.Scale, 0),
				Size = UDim2.new(0.01, 0, 0.01, 0),
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg3.Rotation,
			},
			TI = AnimsManager.STIS.FadeIn,
			Obj = plrGUI.SkillsMenu.Holder.Overlay.Backg3,
		},
		["Backg4"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.Backg4.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.Backg4.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg4.Rotation,
			},
			OutTE = {
				Position = UDim2.new(1.4, 0, 4.5, 0),
				Size = UDim2.new(0.01, 0, 0.01, 0),
				Rotation = 30,
			},
			TI = AnimsManager.STIS.FadeIn,
			Obj = plrGUI.SkillsMenu.Holder.Overlay.Backg4,
		},
		["Backg5"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.Backg5.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.Backg5.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.Backg5.Rotation,
			},
			OutTE = {
				Position = UDim2.new(-1.5, 0, plrGUI.SkillsMenu.Holder.Overlay.Backg2.Position.Y.Scale, 0),
				Size = UDim2.new(0.01, 0, 0.01, 0),
				Rotation = 30,
			},
			TI = AnimsManager.STIS.FadeIn,
			Obj = plrGUI.SkillsMenu.Holder.Overlay.Backg5,
		},
		["DescBackg"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Rotation,
			},
			TI = AnimsManager.STIS.FadeInSlow,
			OutTE = {
				Position = UDim2.new(-0.5, 0, 3.35, 0),
				Size = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Size.X.Scale + 0.5, 0, plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Size.Y.Scale + 0.5, 0),
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.DescBackg.Rotation,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.DescBackg,
		},
		["F1"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Rotation,
			},
			TI = AnimsManager.STIS.FadeIn,
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.X.Scale - 0.8, 0, plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.Y.Scale, 0),
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Rotation,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1,
		},
		["F2"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2.Rotation,
			},
			TI = AnimsManager.STIS.FadeInMid,
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.X.Scale - 0.8, 0, plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.Y.Scale, 0),
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2.Rotation,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F2,
		},
		["F3"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3.Rotation,
			},
			TI = AnimsManager.STIS.FadeInSlow,
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.X.Scale - 0.8, 0, plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.Y.Scale, 0),
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3.Rotation,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F3,
		},
		["F4"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4.Rotation,
			},
			TI = AnimsManager.STIS.FadeOut,
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.X.Scale - 0.8, 0, plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F1.Position.Y.Scale, 0),
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4.Rotation,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.F4,
		},
		["Nameplate"] = {
			InTE = {
				Position =  plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate.Position,
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate.Size,
				Rotation = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate.Rotation,
			},
			TI = AnimsManager.STIS.FadeIn,
			OutTE = {
				Position = UDim2.new(plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate.Position.X.Scale, 0, -1.5, 0),
				Size = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate.Size,
				Rotation = -185,
			},
			Obj = plrGUI.SkillsMenu.Holder.Overlay.TitleFrame.Nameplate,
		},
	},
	TES = {},
	stopEv = Instance.new("BindableEvent", script)
}

AnimsManager.UITransitions["SkillMenu"].InFunction = function(ui)
	local info = AnimsManager.UITransitions["SkillMenu"]
	info.stopEv:Fire()
	
	local last = nil
	
	local con
	local interrupted = false

	con = info.stopEv.Event:Connect(function()
		con:Disconnect()
		interrupted = true
	end)
	
	for i, v in pairs(info.Poses) do
		if info.TES[v.Obj] and info.TES[v.Obj].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Obj]:Cancel()
		end
		
		info.TES[v.Obj] = TS:Create(v.Obj, v.TI, v.InTE)
		if i == "Backg1" then
			last = info.TES[v.Obj]
		else
			info.TES[v.Obj]:Play()
		end
	end
	
	if last then 
		if last.PlaybackState ~= Enum.PlaybackState.Playing then
			last:Play()
		end
		last.Completed:Wait()
		if interrupted then 
			if con then con:Disconnect() end
			return
		end
		last = nil
	end
	
	coroutine.wrap(function()
		for i = ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.MaxVisibleGraphemes, #ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.Text do
			ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.MaxVisibleGraphemes = i
			task.wait(0.01)
			if interrupted then 
				if con then con:Disconnect() end
				break
			end
		end 
	end)()
	
	for i, v in pairs(ui.Holder.Overlay.SkillsFrame:GetChildren()) do
		if not v.Visible then continue end
		if info.TES[v.Overtext] and info.TES[v.Overtext].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Overtext]:Cancel()
		end
		if info.TES[v.IconFrame] and info.TES[v.IconFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame]:Cancel()
		end
		if info.TES[v.IconFrame.Img] and info.TES[v.IconFrame.Img].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame.Img]:Cancel()
		end
		if info.TES[v.SPFrame] and info.TES[v.SPFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame]:Cancel()
		end
		if v.SPFrame.Slider:GetAttribute("InUse") and info.TES[v.SPFrame.Slider] and info.TES[v.SPFrame.Slider].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Slider]:Cancel()
		end
		if info.TES[v.SPFrame.Overnumber] and info.TES[v.SPFrame.Overnumber].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overnumber]:Cancel()
		end
		if info.TES[v.SPFrame.Overtype] and info.TES[v.SPFrame.Overtype].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overtype]:Cancel()
		end
		
		info.TES[v.Overtext] = TS:Create(v.Overtext, AnimsManager.STIS.FadeUp, {TextTransparency = 0})
		info.TES[v.IconFrame] = TS:Create(v.IconFrame, AnimsManager.STIS.FadeUp, {BackgroundTransparency = 0})
		info.TES[v.IconFrame.Img] = TS:Create(v.IconFrame.Img, AnimsManager.STIS.FadeUp, {ImageTransparency = 0})
		info.TES[v.SPFrame] = TS:Create(v.SPFrame, AnimsManager.STIS.FadeUp, {BackgroundTransparency = 0})
		if v.SPFrame.Slider:GetAttribute("InUse") then
			info.TES[v.SPFrame.Slider] = TS:Create(v.SPFrame.Slider, AnimsManager.STIS.FadeUp, {ImageTransparency = 0, ImageColor3 = v.SPFrame.Slider:GetAttribute("TargetColor") or v.SPFrame.Slider.ImageColor3})
			info.TES[v.SPFrame.Slider]:Play()
		end
		info.TES[v.SPFrame.Overnumber] = TS:Create(v.SPFrame.Overnumber, AnimsManager.STIS.FadeUp, {TextTransparency = 0, TextColor3 = v.SPFrame.Overnumber:GetAttribute("TargetColor") or v.SPFrame.Overnumber.TextColor3})
		info.TES[v.SPFrame.Overtype] = TS:Create(v.SPFrame.Overtype, AnimsManager.STIS.FadeUp, {TextTransparency = 0, TextColor3 = v.SPFrame.Overtype:GetAttribute("TargetColor") or v.SPFrame.Overtype.TextColor3})
		info.TES[v.Overtext]:Play()
		info.TES[v.IconFrame]:Play()
		info.TES[v.IconFrame.Img]:Play()
		info.TES[v.SPFrame]:Play()
		info.TES[v.SPFrame.Overnumber]:Play()
		info.TES[v.SPFrame.Overtype]:Play()
		
		task.wait(AnimsManager.STIS.FadeUp.Time/5)
		
		if interrupted then 
			if con then con:Disconnect() end
			return
		end
	end
	if con then con:Disconnect() end
end

AnimsManager.UITransitions["SkillMenu"].OutFunction = function(ui)
	local info = AnimsManager.UITransitions["SkillMenu"]
	info.stopEv:Fire()

	local last = nil

	local con
	local interrupted = false

	con = info.stopEv.Event:Connect(function()
		con:Disconnect()
		interrupted = true
	end)

	coroutine.wrap(function()
		for i = ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.MaxVisibleGraphemes, 0, -1 do
			ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.MaxVisibleGraphemes = i
			task.wait(0.01)
			if interrupted then 
				if con then con:Disconnect() end
				break
			end
		end 
	end)()
	
	for i, v in pairs(ui.Holder.Overlay.SkillsFrame:GetChildren()) do
		if not v.Visible then continue end
		if info.TES[v.Overtext] and info.TES[v.Overtext].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Overtext]:Cancel()
		end
		if info.TES[v.IconFrame] and info.TES[v.IconFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame]:Cancel()
		end
		if info.TES[v.IconFrame.Img] and info.TES[v.IconFrame.Img].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame.Img]:Cancel()
		end
		if info.TES[v.SPFrame] and info.TES[v.SPFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame]:Cancel()
		end
		if v.SPFrame.Slider:GetAttribute("InUse") and info.TES[v.SPFrame.Slider] and info.TES[v.SPFrame.Slider].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Slider]:Cancel()
		end
		if info.TES[v.SPFrame.Overnumber] and info.TES[v.SPFrame.Overnumber].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overnumber]:Cancel()
		end
		if info.TES[v.SPFrame.Overtype] and info.TES[v.SPFrame.Overtype].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overtype]:Cancel()
		end

		info.TES[v.Overtext] = TS:Create(v.Overtext, AnimsManager.STIS.FadeIn, {TextTransparency = 1})
		info.TES[v.IconFrame] = TS:Create(v.IconFrame, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 1})
		info.TES[v.IconFrame.Img] = TS:Create(v.IconFrame.Img, AnimsManager.STIS.FadeIn, {ImageTransparency = 1})
		info.TES[v.SPFrame] = TS:Create(v.SPFrame, AnimsManager.STIS.FadeIn, {BackgroundTransparency = 1})
		if v.SPFrame.Slider:GetAttribute("InUse") then
			info.TES[v.SPFrame.Slider] = TS:Create(v.SPFrame.Slider, AnimsManager.STIS.FadeIn, {ImageTransparency = 1, BackgroundTransparency = 1})
			info.TES[v.SPFrame.Slider]:Play()
		end
		info.TES[v.SPFrame.Overnumber] = TS:Create(v.SPFrame.Overnumber, AnimsManager.STIS.FadeIn, {TextTransparency = 1})
		info.TES[v.SPFrame.Overtype] = TS:Create(v.SPFrame.Overtype, AnimsManager.STIS.FadeIn, {TextTransparency = 1})
		info.TES[v.Overtext]:Play()
		info.TES[v.IconFrame]:Play()
		info.TES[v.IconFrame.Img]:Play()
		info.TES[v.SPFrame]:Play()
		info.TES[v.SPFrame.Overnumber]:Play()
		last = info.TES[v.SPFrame.Overtype]
		info.TES[v.SPFrame.Overtype]:Play()
	end

	if last then 
		--last.Completed:Wait()
		task.wait(last.TweenInfo.Time/3)
		if interrupted then 
			if con then con:Disconnect() end
			return
		end
		last = nil
	end
	
	for i, v in pairs(info.Poses) do
		if info.TES[v.Obj] and info.TES[v.Obj].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Obj]:Cancel()
		end

		info.TES[v.Obj] = TS:Create(v.Obj, v.TI, v.OutTE)
		last = info.TES[v.Obj]
		info.TES[v.Obj]:Play()
	end

	if last then 
		last.Completed:Wait()
		if interrupted then 
			if con then con:Disconnect() end
			return
		end
		last = nil
	end
	
	if con then con:Disconnect() end
end

AnimsManager.UITransitions["SkillMenu"].Reset = function(ui)
	local info = AnimsManager.UITransitions["SkillMenu"]
	info.stopEv:Fire()
	for i, v in pairs(info.Poses) do
		if info.TES[v.Obj] and info.TES[v.Obj].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Obj]:Cancel()
		end

		for i2, v2 in pairs(v.OutTE) do
			v.Obj[i2] = v2
		end
	end

	ui.Holder.Overlay.TitleFrame.Nameplate.Nametext.MaxVisibleGraphemes = 0

	for i, v in pairs(ui.Holder.Overlay.SkillsFrame:GetChildren()) do
		if not v.Visible then continue end
		if info.TES[v.Overtext] and info.TES[v.Overtext].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.Overtext]:Cancel()
		end
		if info.TES[v.IconFrame] and info.TES[v.IconFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame]:Cancel()
		end
		if info.TES[v.IconFrame.Img] and info.TES[v.IconFrame.Img].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.IconFrame.Img]:Cancel()
		end
		if info.TES[v.SPFrame] and info.TES[v.SPFrame].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame]:Cancel()
		end
		if info.TES[v.SPFrame.Slider] and info.TES[v.SPFrame.Slider].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Slider]:Cancel()
		end
		if info.TES[v.SPFrame.Overnumber] and info.TES[v.SPFrame.Overnumber].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overnumber]:Cancel()
		end
		if info.TES[v.SPFrame.Overtype] and info.TES[v.SPFrame.Overtype].PlaybackState == Enum.PlaybackState.Playing then
			info.TES[v.SPFrame.Overtype]:Cancel()
		end

		v.Overtext.TextTransparency = 1
		v.IconFrame.BackgroundTransparency = 1
		v.IconFrame.Img.ImageTransparency = 1
		v.SPFrame.BackgroundTransparency = 1
		v.SPFrame.Slider.ImageTransparency = 1
	
		v.SPFrame.Overnumber.TextTransparency = 1
		v.SPFrame.Overtype.TextTransparency = 1
	end
end

return AnimsManager

---