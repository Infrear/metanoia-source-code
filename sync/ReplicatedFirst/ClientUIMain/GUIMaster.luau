-- Services
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local TS = game:GetService("TweenService")
local DBS = game:GetService("Debris")

-- Dependencies
local plr = PLRS.LocalPlayer
local personaChar = nil

local Storage = RPS:WaitForChild("ClientStorage")
local SkillLibrary = require(Storage.Info.SkillLibrary)
local BillboardUIS = Storage:WaitForChild("BillboardUIs")
local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))

local gameSettings = require(Storage.Info.GameSettings)
local combatSettings = gameSettings.CombatSettings

-- Local Variables
local GUIMaster = {}
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local currentHighlight = nil
local CombatReplicator = Storage.Events.Remotes.ReplicateCombat

local function dictfind(tab, instKey)
	for i, v in ipairs(tab) do
		if v.Instance == instKey then
			return i
		end
	end
	return nil
end

-- Constants
local ADD_TIME = {
	MIN = 0.15/combatSettings.CombatSpeedMultiplier,
	BASE = 0.75/combatSettings.CombatSpeedMultiplier,
	CAP = 0.20/combatSettings.CombatSpeedMultiplier,
}

-- Global Variables
GUIMaster.Animations = require(script:WaitForChild("Animations"))
GUIMaster.TargEv = Instance.new("BindableEvent", script)
GUIMaster.Connections = {}
GUIMaster.UIs = {
	LeftMainBattleUI = {
		Open = false,
		Object = nil, -- will be updated as the character is selected
		OpenAnimationInfo = GUIMaster.Animations.UITransitions.BattleUIL -- for specialized opening/closing animation types for certain uis
	},
	RightMainBattleUI = {
		Open = false,
		Object = nil,
		OpenAnimationInfo = GUIMaster.Animations.UITransitions.BattleUIR
	},
	-- Add this to your GUIMaster.UIs table initialization
	Target = {
		Open = false,
		Index = 1,
		Options = {},
		Indicators = {}, -- CHANGED: Now a table to hold multiple indicators
		OpenAnimationInfo = GUIMaster.Animations.UITransitions.Target
	},
	Heart = {
		Open = false,
		Object = nil,
		OpenAnimationInfo = GUIMaster.Animations.UITransitions.Heart
	},
	SkillsMenu = {
		Open = false,
		Object = PlayerGui:WaitForChild("SkillsMenu"),
		OpenAnimationInfo = GUIMaster.Animations.UITransitions.SkillMenu
	}
}
GUIMaster.CurrentFightTab = {}

-- Local Functions


-- Public Functions
function GUIMaster.InitializeUI(pChar, currentFightTab, currentPersonaData) -- handling the MainBattleUI there
	if personaChar then return warn("Already working with a persona!") end
	if not pChar then return warn("No persona character provided!") end
	--print(pChar)
	local LsGUI, RsGUI = ((pChar:FindFirstChild("HumanoidRootPart") and pChar:FindFirstChild("HumanoidRootPart"):FindFirstChild("LeftBattleHeader")) or (pChar:FindFirstChild("LeftBattleHeader"))), ((pChar:FindFirstChild("HumanoidRootPart") and pChar:FindFirstChild("HumanoidRootPart"):FindFirstChild("RightBattleHeader")) or pChar:FindFirstChild("RightBattleHeader"))
	if not LsGUI or not RsGUI then
		warn("One or more battle headers not found! Creating them now!") 
		if not LsGUI then
			LsGUI = BillboardUIS.Combat.LeftBattleHeader:Clone()
			LsGUI.Parent = pChar
		end
		if GUIMaster.UIs.LeftMainBattleUI.OpenAnimationInfo then
			if GUIMaster.UIs.LeftMainBattleUI.OpenAnimationInfo.Reset then
				GUIMaster.UIs.LeftMainBattleUI.OpenAnimationInfo.Reset(LsGUI)
			elseif GUIMaster.UIs.LeftMainBattleUI.OpenAnimationInfo.OutFunction then
				GUIMaster.UIs.LeftMainBattleUI.OpenAnimationInfo.OutFunction(LsGUI)
			end
		end
		if not RsGUI then
			RsGUI = BillboardUIS.Combat.RightBattleHeader:Clone()
			RsGUI.Parent = pChar
		end
		if GUIMaster.UIs.RightMainBattleUI.OpenAnimationInfo then
			if GUIMaster.UIs.RightMainBattleUI.OpenAnimationInfo.Reset then
				GUIMaster.UIs.RightMainBattleUI.OpenAnimationInfo.Reset(RsGUI)
			elseif GUIMaster.UIs.RightMainBattleUI.OpenAnimationInfo.OutFunction then
				GUIMaster.UIs.RightMainBattleUI.OpenAnimationInfo.OutFunction(RsGUI)
			end
		end
	end

	personaChar = pChar

	if currentHighlight then
		currentHighlight:Destroy()
	end

	GUIMaster.CurrentFighterData = currentPersonaData

	currentHighlight = Instance.new("Highlight")
	currentHighlight.FillColor = Color3.fromRGB(60, 15, 157)
	currentHighlight.FillTransparency = 0.5
	currentHighlight.OutlineColor = Color3.new(1, 1, 1)
	currentHighlight.Parent = personaChar

	GUIMaster.UIs.Target.Index = 1
	--GUIMaster.UIs.Target.Object.Enabled = false
	--GUIMaster.UIs.Target.Object.Parent = pChar
	GUIMaster.UIs.LeftMainBattleUI.Object = LsGUI
	GUIMaster.UIs.RightMainBattleUI.Object = RsGUI

	GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, true)
	GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, true)

	GUIMaster.ClearFrame(GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.Tris)

	GUIMaster.CurrentFightTab = currentFightTab or {}

	return true
end


--function GUIMaster.MoveTarget(new) -- for later a animation style for moving between targets, prolly want a folder to hold anything in active combat to look for
--	-- done :)
--	if GUIMaster.UIs.Target.Object then
--		GUIMaster.ToggleMenu(GUIMaster.UIs.Target, false)
--	end

--	GUIMaster.UIs.Target.Object = BillboardUIS.Combat.Target:Clone()
--	GUIMaster.Animations.UITransitions["Target"].Reset(GUIMaster.UIs.Target.Object)
--	GUIMaster.UIs.Target.Object.Parent = new:FindFirstChild("HumanoidRootPart") or new
--	--GUIMaster.UIs.Target.Object.Adornee = new:FindFirstChild("HumanoidRootPart") or new
--	GUIMaster.ToggleMenu(GUIMaster.UIs.Target, true)
--end

-- Update MoveTarget to handle a TABLE of instances
function GUIMaster.MoveTarget(targetInstances) 
	-- 1. Clear old indicators
	for _, obj in ipairs(GUIMaster.UIs.Target.Indicators) do
		obj:Destroy()
	end
	GUIMaster.UIs.Target.Indicators = {}
	
	local mult = #targetInstances > 1 
	-- 2. Create new indicators for every target in the list
	for _, ins in ipairs(targetInstances) do
		local indicator = BillboardUIS.Combat.Target:Clone()
		GUIMaster.Animations.UITransitions["Target"].Reset(indicator, mult or nil)
		indicator.Parent = ins:FindFirstChild("HumanoidRootPart") or ins

		table.insert(GUIMaster.UIs.Target.Indicators, indicator)

		-- Use the existing ToggleMenu logic but for each specific object
		if mult then
			coroutine.wrap(function()
				GUIMaster.Animations.UITransitions["Target"].InFunction(indicator, true, Color3.new(1, 0, 1), Color3.new(0.74902, 0, 1))
			end)()
		else
			coroutine.wrap(function()
				GUIMaster.Animations.UITransitions["Target"].InFunction(indicator)
			end)()
		end
	end

	GUIMaster.UIs.Target.Open = #targetInstances > 0
end


function GUIMaster.MoveHeart(newTab, oldRat, timer)
	coroutine.wrap(function()
		if GUIMaster.UIs.Heart.Object then
			GUIMaster.ToggleMenu(GUIMaster.UIs.Heart, false)
		end

		local oldobj = BillboardUIS.Combat.Heart:Clone()
		GUIMaster.UIs.Heart.Object = oldobj
		GUIMaster.Animations.UITransitions["Heart"].Reset(GUIMaster.UIs.Heart.Object)
		GUIMaster.UIs.Heart.Object.Parent = newTab.Instance:FindFirstChild("HumanoidRootPart") or newTab.Instance
		--GUIMaster.UIs.Heart.Object.Adornee = newTab.Instance:FindFirstChild("HumanoidRootPart") or newTab.Instance
		GUIMaster.ToggleMenu(GUIMaster.UIs.Heart, true, newTab.HP/newTab.MaxHP, oldRat)
		if timer then
			task.wait(timer)
			if GUIMaster.UIs.Heart.Object == oldobj then
				GUIMaster.ToggleMenu(GUIMaster.UIs.Heart, false)
			end
		end
	end)()
end

function GUIMaster.ClearFrame(pFrame, closeAnim) -- in the future, add a tween animation for closing
	for i, frame in ipairs(pFrame:GetChildren()) do
		if frame.Visible and closeAnim then
			closeAnim(frame)
		elseif frame.Visible then
			frame.Visible = false
		end
	end
end

function GUIMaster.FocusCamOnTarget(instance, pos, shouldDelay)
	if not pos and not instance then return end
	GUIMaster.TargEv:Fire()
	local con = nil
	if shouldDelay then
		local interupted = false
		con = GUIMaster.TargEv.Event:Once(function()
			interupted = true
		end)
		task.wait(0.05)
		if interupted then return end
	end
	-- early bug here ig?
	--  ReplicatedFirst.ClientUIMain.GUIMaster:226: attempt to index nil with 'Instance', probably fix this in case the instance isn't there anymore or something idk
	local relativeCF = CFrame.new(pos or instance:GetPivot().Position):ToObjectSpace(CFrame.new(GUIMaster.CurrentFighterData.Instance:GetPivot().Position))
	--print(relativeCF.Position)
	local lerped = CFrame.new(0, 0, 0):Lerp(relativeCF, 0.5)

	-- Removed 'lerped' from extraOffset because it was applying a world-space difference as a local-space offset,
	-- causing the camera to veer wildly to the side when selecting teammates.
	CameraHandler.FocusOn(instance, 20, nil, nil, "Mid Zoom")
	if con then con:Disconnect() end
end

function GUIMaster.ToggleTargets(uiObj, force, ...) -- Handles UI visibility with style, force is optional
	local target = not GUIMaster.UIs.Target.Open
	if force ~= nil then
		target = force
	end
	if 	GUIMaster.UIs.Target.OpenAnimationInfo then
		GUIMaster.UIs.Target.Open = target
		if target then
			coroutine.wrap(function(...)
				GUIMaster.UIs.Target.OpenAnimationInfo.InFunction(uiObj, ...)
			end)(...)
		else
			coroutine.wrap(function(...)
				GUIMaster.UIs.Target.OpenAnimationInfo.OutFunction(uiObj, ...)
			end)(...)
		end
	else
		GUIMaster.UIs.Target.Open = target
		if target then
			uiObj.Enabled = target
		else
			uiObj.Enabled = target
		end
	end
	-- PLAN: IMPLEMENT TILTED ANIMATIONS USING TWEENSERVICE
	-- implemented :)
end

function GUIMaster.ToggleMenu(ui, force, ...) -- Handles UI visibility with style, force is optional
	local packed = nil
	local target = not ui.Open
	if force ~= nil then
		target = force
	end
	if ui.OpenAnimationInfo then
		ui.Open = target
		if target then
			coroutine.wrap(function(...)
				ui.OpenAnimationInfo.InFunction(ui.Object, ...)
			end)(...)
		else
			coroutine.wrap(function(...)
				ui.OpenAnimationInfo.OutFunction(ui.Object, ...)
			end)(...)
		end
	else
		ui.Open = target
		if target then
			ui.Object.Enabled = target
		else
			ui.Object.Enabled = target
		end
	end
	
	-- auto-show/hide tray when skills menu toggles
	if ui == GUIMaster.UIs.SkillsMenu then
		if target and GUIMaster.CurrentFighterData then
			GUIMaster.ShowPersonaTray(true)
		else
			GUIMaster.ShowPersonaTray(false)
		end
	end
	-- PLAN: IMPLEMENT TILTED ANIMATIONS USING TWEENSERVICE
	-- implemented :)
end

-- ========================
-- persona tray ui system
-- ========================
local trayFrame = nil
local trayArrowLeft = nil
local trayArrowRight = nil

GUIMaster.ActiveTrayIndex = 1

local function buildTrayFrame()
	if trayFrame then return end
	
	trayFrame = Instance.new("Frame")
	trayFrame.Name = "PersonaTray"
	trayFrame.AnchorPoint = Vector2.new(0, 1)
	trayFrame.Position = UDim2.new(0.015, 0, 0.96, 0)
	trayFrame.Size = UDim2.new(0, 200, 0, 55)
	trayFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	trayFrame.BackgroundTransparency = 0.3
	trayFrame.BorderSizePixel = 0
	trayFrame.Visible = false
	trayFrame.Parent = PlayerGui:WaitForChild("SkillsMenu")
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = trayFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 40, 40)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = trayFrame
	
	-- left arrow
	trayArrowLeft = Instance.new("TextButton")
	trayArrowLeft.Name = "ArrowLeft"
	trayArrowLeft.Size = UDim2.new(0, 22, 1, 0)
	trayArrowLeft.Position = UDim2.new(0, 0, 0, 0)
	trayArrowLeft.BackgroundTransparency = 1
	trayArrowLeft.Text = "◀"
	trayArrowLeft.TextColor3 = Color3.fromRGB(220, 220, 220)
	trayArrowLeft.TextSize = 16
	trayArrowLeft.Font = Enum.Font.GothamBold
	trayArrowLeft.Parent = trayFrame
	trayArrowLeft.MouseButton1Click:Connect(function()
		GUIMaster.CyclePersonaTray("left")
	end)
	
	-- right arrow
	trayArrowRight = Instance.new("TextButton")
	trayArrowRight.Name = "ArrowRight"
	trayArrowRight.Size = UDim2.new(0, 22, 1, 0)
	trayArrowRight.Position = UDim2.new(1, -22, 0, 0)
	trayArrowRight.BackgroundTransparency = 1
	trayArrowRight.Text = "▶"
	trayArrowRight.TextColor3 = Color3.fromRGB(220, 220, 220)
	trayArrowRight.TextSize = 16
	trayArrowRight.Font = Enum.Font.GothamBold
	trayArrowRight.Parent = trayFrame
	trayArrowRight.MouseButton1Click:Connect(function()
		GUIMaster.CyclePersonaTray("right")
	end)
end

local function refreshTrayIcons()
	if not trayFrame then return end
	-- clear old icons
	for _, child in ipairs(trayFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local fighterData = GUIMaster.CurrentFighterData
	if not fighterData or not fighterData.StoredPersonas then return end
	
	local personas = fighterData.StoredPersonas
	local count = #personas
	if count == 0 then return end
	
	-- figure out which tray slot is active
	for i, p in ipairs(personas) do
		if p.Name == fighterData.ActivePersona.Name then
			GUIMaster.ActiveTrayIndex = i
			break
		end
	end
	
	-- resize tray frame to fit
	local iconSize = 40
	local padding = 6
	local arrowWidth = 22
	local totalWidth = (arrowWidth * 2) + (count * iconSize) + ((count - 1) * padding) + 12
	trayFrame.Size = UDim2.new(0, totalWidth, 0, iconSize + 14)
	
	-- create icon frames
	for i, persona in ipairs(personas) do
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "PersonaIcon_" .. i
		iconFrame.Size = UDim2.new(0, iconSize, 0, iconSize)
		iconFrame.Position = UDim2.new(0, arrowWidth + 6 + (i - 1) * (iconSize + padding), 0.5, 0)
		iconFrame.AnchorPoint = Vector2.new(0, 0.5)
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = trayFrame
		
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 6)
		iconCorner.Parent = iconFrame
		
		if i == GUIMaster.ActiveTrayIndex then
			iconFrame.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
			local activeStroke = Instance.new("UIStroke")
			activeStroke.Color = Color3.fromRGB(255, 255, 255)
			activeStroke.Thickness = 2
			activeStroke.Parent = iconFrame
		else
			iconFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		end
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = string.sub(persona.Name, 1, 5)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = iconFrame
	end
end

function GUIMaster.ShowPersonaTray(show)
	buildTrayFrame()
	if show then
		refreshTrayIcons()
	end
	trayFrame.Visible = show
end

function GUIMaster.CyclePersonaTray(dir)
	local fighterData = GUIMaster.CurrentFighterData
	if not fighterData or not fighterData.StoredPersonas or #fighterData.StoredPersonas <= 1 then return end
	
	local count = #fighterData.StoredPersonas
	if dir == "left" then
		GUIMaster.ActiveTrayIndex = GUIMaster.ActiveTrayIndex - 1
		if GUIMaster.ActiveTrayIndex < 1 then GUIMaster.ActiveTrayIndex = count end
	else
		GUIMaster.ActiveTrayIndex = GUIMaster.ActiveTrayIndex + 1
		if GUIMaster.ActiveTrayIndex > count then GUIMaster.ActiveTrayIndex = 1 end
	end
	
	-- fire to server — server validates and broadcasts swapUpdate back to all clients
	CombatReplicator:FireServer("SwapPersona", tostring(GUIMaster.ActiveTrayIndex))
	
	-- optimistic local highlight update
	refreshTrayIcons()
end

function GUIMaster.ChangeSelection(dir) -- Moves target from left to right
	if #GUIMaster.UIs.Target.Indicators > 1 then return end
	if dir == "left" then
		if GUIMaster.UIs.Target.Index > 1 then -- if at beginning, go to end 
			GUIMaster.UIs.Target.Index  -= 1 
		else
			GUIMaster.UIs.Target.Index = #GUIMaster.UIs.Target.Options
		end
	elseif dir == "right" then	
		if GUIMaster.UIs.Target.Index  < #GUIMaster.UIs.Target.Options then -- if at end, go to beginning 
			GUIMaster.UIs.Target.Index  += 1
		else
			GUIMaster.UIs.Target.Index  = 1
		end
	end
	GUIMaster.MoveTarget({GUIMaster.UIs.Target.Options[GUIMaster.UIs.Target.Index].Instance})
	GUIMaster.MoveHeart(GUIMaster.UIs.Target.Options[GUIMaster.UIs.Target.Index])
	GUIMaster.FocusCamOnTarget(GUIMaster.UIs.Target.Options[GUIMaster.UIs.Target.Index].Instance)
end

function GUIMaster.CreateDamagePopup(targetInstance, info)
	if GUIMaster.Animations.LastCCSM ~= plr:GetAttribute("CurrentCombatSpeedMultiplier") then
		for i, v in pairs(GUIMaster.Animations.BASE_STIS) do
			GUIMaster.Animations.STIS[i] = TweenInfo.new(
				v.Time/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1),
				v.EasingStyle,
				v.EasingDirection,
				v.RepeatCount,
				v.Reverses,
				v.DelayTime
			)
		end
	end
	
	local popups = {}
	if info.damage then
		table.insert(popups, {
			Obj = BillboardUIS.Combat.Num:Clone(),
			TES = {},
			PopType = "Number"
		})
	end

	if info.result and BillboardUIS.Combat:FindFirstChild(info.result) then
		table.insert(popups, {
			Obj = BillboardUIS.Combat:FindFirstChild(info.result):Clone(),
			TES = {},
			PopType = "Result"
		})
	end


	-- Style based on info
	for i, v in ipairs(popups) do
		local popup = v.Obj
		popup.Enabled = false
		popup.Parent = targetInstance.PrimaryPart or targetInstance:FindFirstChild("HumanoidRootPart")
		popup.Adornee = targetInstance
		popup.Enabled = true

		if v.PopType == "Number" then
			local namt = (math.floor(info.damage * 10))/10

			local og = 0
			local new = namt
			--print(og, new)
			if og == new then
				popup.Holder.SampleText.Text = new
				popup.Holder.BackgText.Text = new
			else
				coroutine.wrap(function()
					local dif = math.floor(math.abs(new - og))
					local tim = math.clamp(((dif * 0.04) * ADD_TIME.BASE/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)), ADD_TIME.MIN/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1), ADD_TIME.CAP/(plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1)) --ADD_TIME.CAP
					--print(tim)
					local div = tim/dif

					--print(dif)
					for i2 = 1, dif do
						--print(i)
						if not popup then break end

						if new > og then
							popup.Holder.SampleText.Text = og + i2
							popup.Holder.BackgText.Text = og + i2
						else
							popup.Holder.SampleText.Text = og - i2
							popup.Holder.BackgText.Text = og - i2
						end

						task.wait(div)
					end
				end)()
			end
			repeat wait() until popup.Holder.SampleText.Text  == tostring(math.floor(namt))
			popup.Holder.SampleText.Text = namt
			popup.Holder.BackgText.Text = namt
			
			coroutine.wrap(function()
				GUIMaster.Animations.HighlightTE(
					targetInstance, 
					{
						High = Color3.new(1, 0.745098, 0.627451),
						Base = Color3.new(1, 0.666667, 0),
						Low = Color3.new(0.560784, 0.372549, 0),
						Killshot = Color3.new(1, 1, 0)
						--	High = Color3.new(1, 0.360784, 0.603922),
						--	Base = Color3.new(1, 0, 0.235294),
						--	Low = Color3.new(0.392157, 0, 0.105882)
					},
					info.killshot
				)
			end)()
			
			if not info.killshot then
				v.TES["Grow"] = TS:Create(popup, GUIMaster.Animations.STIS.Pulse, {
					Size = UDim2.new(12, 0, 12, 0)
				})
				v.TES["Glow"] = TS:Create(popup.Holder.SampleText, GUIMaster.Animations.STIS.Pulse, {
					TextColor3 = popup.Holder.BackgText.TextColor3
				})
			else
				v.TES["Grow"] = TS:Create(popup, GUIMaster.Animations.STIS.Pulse2, {
					Size = UDim2.new(20, 0, 20, 0)
				})
				v.TES["Glow2"] = TS:Create(popup.Holder.BackgText, GUIMaster.Animations.STIS.Pulse2, {
					TextColor3 = Color3.new(1, 0.329412, 0.329412)
				})
				v.TES["Glow"] = TS:Create(popup.Holder.SampleText, GUIMaster.Animations.STIS.Pulse2, {
					TextColor3 = Color3.new(1)
				})
			end
			for i2, v2 in pairs(v.TES) do
				v2:Play()
			end
			if v.TES["Glow"].PlaybackState ~= Enum.PlaybackState.Completed then --> might be dangerous later idk
				v.TES["Glow"].Completed:Wait()
			end
			v.TES["Glow"] = nil
			v.TES["Grow"] = nil
			if v.TES["Glow2"] then
				v.TES["Glow2"] = nil
			end
		end


		for i2, v2 in pairs(v.TES) do
			v2:Play()
		end

		local t2use = not info.killshot and GUIMaster.Animations.STIS.FadeUp or GUIMaster.Animations.STIS.FadeUp2
		v.TES["FadeUp"] = TS:Create(popup, t2use, {
			StudsOffset = popup.StudsOffset + Vector3.new(0, 3, 0)
		})
		v.TES["FadeOut1"] = TS:Create(popup.Holder.BackgText, t2use, {
			TextTransparency = 1
		})
		v.TES["FadeOut2"] = TS:Create(popup.Holder.SampleText, t2use, {
			TextTransparency = 1
		})

		coroutine.wrap(function()
			for i2, v2 in pairs(v.TES) do
				v2:Play()
			end
			if v.TES["FadeOut2"].PlaybackState ~= Enum.PlaybackState.Completed then --> might be dangerous later idk
				v.TES["FadeOut2"].Completed:Wait()
			end
			popup:Destroy()
		end)() --> possible data leak for later on??? idk
	end
end

local TS = game:GetService("TweenService")
local oneMoreSetupDone = false
local burst, speedLines, numberFrame, moreFrame, burstFinal, numberFinal, letterFrames, oneMoreScreenGui
local spinConn

function GUIMaster.ShowOneMore()
	if not oneMoreSetupDone then
		oneMoreScreenGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("OneMoreGui")
		if not oneMoreScreenGui then return end
		
		local holder = oneMoreScreenGui:WaitForChild("Holder")
		burst = holder.Burst
		speedLines = holder.SpeedLines
		numberFrame = holder.NumberFrame
		moreFrame = holder.MoreFrame
		
		local function captureFinalPose(inst)
			return {Size = inst.Size, Position = inst.Position, Rotation = inst.Rotation}
		end
		burstFinal = captureFinalPose(burst)
		numberFinal = captureFinalPose(numberFrame)
		
		letterFrames = {}
		for _, child in ipairs(moreFrame:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(letterFrames, {frame = child, final = captureFinalPose(child)})
			end
		end
		table.sort(letterFrames, function(a, b) return a.frame.Name < b.frame.Name end)
		oneMoreSetupDone = true
	end

	if not oneMoreScreenGui then return end

	local function setHidden()
		burst.BackgroundTransparency = 1
		burst.Size = UDim2.new(burstFinal.Size.X.Scale * 0.3, 0, burstFinal.Size.Y.Scale * 0.3, 0)
		speedLines.Rotation = 0
		numberFrame.Size = UDim2.new(0, 0, 0, 0)
		for _, data in ipairs(letterFrames) do
			data.frame.Size = UDim2.new(0, 0, 0, 0)
		end
	end

	local function tweenGroupTransparency(inst, transparency, info)
		for _, desc in ipairs(inst:GetDescendants()) do
			if desc:IsA("TextLabel") then
				TS:Create(desc, info, {TextTransparency = transparency}):Play()
			elseif desc:IsA("UIStroke") then
				TS:Create(desc, info, {Transparency = transparency}):Play()
			elseif desc:IsA("Frame") and desc.BackgroundTransparency < 1 then
				TS:Create(desc, info, {BackgroundTransparency = transparency}):Play()
			end
		end
	end

	setHidden()
	oneMoreScreenGui.Enabled = true

	TS:Create(burst, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = burstFinal.Size,
		BackgroundTransparency = 0.15,
	}):Play()
	
	CameraHandler.Shake(0.3, 0.4)

	if spinConn then spinConn:Disconnect() end
	spinConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		speedLines.Rotation += dt * 260
	end)

	task.delay(0.05, function()
		TS:Create(numberFrame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = numberFinal.Size,
		}):Play()
	end)

	for i, data in ipairs(letterFrames) do
		task.delay(0.12 + (i - 1) * 0.06, function()
			TS:Create(data.frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = data.final.Size,
			}):Play()
		end)
	end

	task.delay(1.1, function()
		local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		TS:Create(burst, fadeInfo, {BackgroundTransparency = 1}):Play()
		tweenGroupTransparency(numberFrame, 1, fadeInfo)
		tweenGroupTransparency(moreFrame, 1, fadeInfo)

		task.delay(0.35, function()
			if spinConn then spinConn:Disconnect() end
			oneMoreScreenGui.Enabled = false
			setHidden()
			for _, desc in ipairs(numberFrame:GetDescendants()) do
				if desc:IsA("TextLabel") then desc.TextTransparency = 0
				elseif desc:IsA("UIStroke") then desc.Transparency = 0 end
			end
			for _, desc in ipairs(moreFrame:GetDescendants()) do
				if desc:IsA("TextLabel") then desc.TextTransparency = 0
				elseif desc:IsA("UIStroke") then desc.Transparency = 0 end
			end
		end)
	end)
end

function GUIMaster.CloseAllBattleUIs()
	GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, false)
	GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, false)
	GUIMaster.ToggleMenu(GUIMaster.UIs.SkillsMenu, false)
	GUIMaster.ToggleMenu(GUIMaster.UIs.Target, false)
	GUIMaster.ToggleMenu(GUIMaster.UIs.Heart, false)
	GUIMaster.UIs.Target.Index = 1
	GUIMaster.UIs.Target.Options = {}
	GUIMaster.CurrentFighterData = nil

	if currentHighlight then
		currentHighlight:Destroy()
	end


	if personaChar then
		local LsGUI, RsGUI = ((personaChar:FindFirstChild("HumanoidRootPart") and personaChar:FindFirstChild("HumanoidRootPart"):FindFirstChild("LeftBattleHeader")) or (personaChar:FindFirstChild("LeftBattleHeader"))), ((personaChar:FindFirstChild("HumanoidRootPart") and personaChar:FindFirstChild("HumanoidRootPart"):FindFirstChild("RightBattleHeader")) or personaChar:FindFirstChild("RightBattleHeader"))

		if LsGUI then
			LsGUI:Destroy()
		end
		if RsGUI then 
			RsGUI:Destroy()
		end
	end

	for i, connection in pairs(GUIMaster.Connections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		else if typeof(connection) == "table" then
				for i2, v2 in pairs(connection) do
					if typeof(v2) == "RBXScriptConnection" then
						v2:Disconnect()
					end
				end
			end
		end
	end
	personaChar = nil
end

-- Called from ClientUIMain when the server prompts a baton pass ("1 MORE") after a weakness hit /
-- critical. Shows the OneMoreGui popup, lets the player cycle through eligible party members using
-- the same Target-indicator system skill-targeting already uses (so it feels consistent), and either
-- fires "batonPass" with a chosen target index, or lets it time out -- the server already defaults
-- back to the attacker if it doesn't hear back in time.
function GUIMaster.PromptBatonPass(fightTable)

	-- Eligible pass-targets: your own party, excluding yourself and anyone already knocked out
	local eligible = {}
	for _, fighterData in ipairs(fightTable.PlayerFighters or {}) do
		local isSelf = GUIMaster.CurrentFighterData and fighterData.Instance == GUIMaster.CurrentFighterData.Instance
		local isDown = fighterData.HP and fighterData.HP <= 0
		if not isSelf and not isDown then
			table.insert(eligible, fighterData)
		end
	end

	if #eligible == 0 then
		return -- nobody to pass to -- server will default back to the attacker after its own timeout
	end

	local index = 1
	GUIMaster.IsPromptingBatonPass = true
	local function showSelection()
		local sel = eligible[index]
		GUIMaster.MoveTarget({sel.Instance})
		GUIMaster.FocusCamOnTarget(sel.Instance, nil, true)
		GUIMaster.MoveHeart(sel)
	end
	showSelection()

	local confirmed = false
	local chosenIndex = nil

	local conn
	conn = UIS.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			index -= 1
			if index < 1 then index = #eligible end
			showSelection()
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			index += 1
			if index > #eligible then index = 1 end
			showSelection()
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			chosenIndex = index
			confirmed = true
		elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then
			confirmed = true -- decline -- chosenIndex stays nil, falls through to the timeout default
		end
	end)

	local waited = 0
	while not confirmed do
		task.wait(0.05)
	end
	conn:Disconnect()
	GUIMaster.IsPromptingBatonPass = false

	-- Close out the indicator(s) the same way ChoiceManager does after a normal target confirm
	local multi = (#GUIMaster.UIs.Target.Indicators > 1) or nil
	for _, indicator in ipairs(GUIMaster.UIs.Target.Indicators) do
		GUIMaster.ToggleTargets(indicator, false, multi)
	end
	GUIMaster.UIs.Target.Indicators = {}
	GUIMaster.UIs.Target.Open = false

	if chosenIndex then
		local chosenFighter = eligible[chosenIndex]
		local realIndex = dictfind(fightTable.AllFighters, chosenFighter.Instance)
		if realIndex then
			CombatReplicator:FireServer("batonPass", nil, {realIndex})
			return true
		end
	end
	return false
end

function GUIMaster.PulseMainOption(optionName)
	local optionUI = nil
	if GUIMaster.UIs.RightMainBattleUI.Object then
		local holder = GUIMaster.UIs.RightMainBattleUI.Object:FindFirstChild("Holder")
		if holder then optionUI = holder:FindFirstChild(optionName) end
	end
	if not optionUI and GUIMaster.UIs.LeftMainBattleUI.Object then
		local holder = GUIMaster.UIs.LeftMainBattleUI.Object:FindFirstChild("Holder")
		if holder then optionUI = holder:FindFirstChild(optionName) end
	end
	
	if optionUI then
		local originalSize = optionUI.Size
		local isText = optionUI:IsA("TextLabel") or optionUI:IsA("TextButton")
		local originalColor = isText and optionUI.TextColor3 or (optionUI:IsA("ImageLabel") and optionUI.ImageColor3 or nil)
		local origBgColor = optionUI.Overlay.Chatbar2.ImageColor3
		local origBgTrans = optionUI.Overlay.Chatbar2.ImageTransparency
		
		local propsOut = {
			Size = UDim2.fromScale(originalSize.X.Scale * 1.4, originalSize.Y.Scale * 1.1),
		}
		local ovOut = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
		}
		local imgOut = {
			ImageColor3 = Color3.new(1, 1, 1),
			ImageTransparency = 0,
		}
		
		local propsIn = {
			Size = originalSize,
		}
		local ovIn = {
			BackgroundColor3 = origBgColor,
			BackgroundTransparency = origBgTrans,
		}
		local imgIn = {
			ImageColor3 = origBgColor,
			BackgroundTransparency = origBgTrans,
		}
		
		if originalColor then
			if isText then
				propsOut.TextColor3 = Color3.new(1, 1, 1)
				propsIn.TextColor3 = originalColor
			else
				propsOut.ImageColor3 = Color3.new(1, 1, 1)
				propsIn.ImageColor3 = originalColor
			end
		end
		
		TS:Create(optionUI, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), propsOut):Play()
		TS:Create(optionUI.Overlay, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), ovOut):Play()
		TS:Create(optionUI.Overlay.Chatbar2, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), imgOut):Play()
		
		task.delay(0.06, function()
			if optionUI and optionUI.Parent then
				TS:Create(optionUI, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), propsIn):Play()
				TS:Create(optionUI.Overlay, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), ovIn):Play()
				TS:Create(optionUI.Overlay.Chatbar2, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), imgIn):Play()
			end
		end)
	end
end

return GUIMaster