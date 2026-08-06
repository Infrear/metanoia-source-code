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
	-- PLAN: IMPLEMENT TILTED ANIMATIONS USING TWEENSERVICE
	-- implemented :)
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

function GUIMaster.ShowOneMore()
	--local splash = PlayerGui.BattleUI:FindFirstChild("OneMoreSplash")
	--if not splash then return end -- Ensure you have this in your UI

	--splash.Visible = true
	--splash.GroupTransparency = 1
	--splash.Position = UDim2.new(0.6, 0, 0.5, 0) -- Slide in from right

	--TS:Create(splash, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
	--	GroupTransparency = 0,
	--	Position = UDim2.new(0.5, 0, 0.5, 0)
	--}):Play()

	--task.delay(1.5, function()
	--	TS:Create(splash, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
	--end)
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

return GUIMaster