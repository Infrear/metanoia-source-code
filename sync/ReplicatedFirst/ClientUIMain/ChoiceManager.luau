-- Services
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local RPS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local plr = Players.LocalPlayer

local Storage = RPS:WaitForChild("ClientStorage")
local WaitForInput = script.Parent:WaitForChild("WaitForInput")
local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)
local GUIMaster = require(script.Parent:WaitForChild("GUIMaster"))
local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))

-- Local Variables
local TIS = {
	["Grow"] = {
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
	}
}
local ChoiceManager = {}

-- Global Variables
ChoiceManager.CurrentSkillFrame = 1
ChoiceManager.CurrentMax = 1
ChoiceManager.CurrentSelectionTriangle = nil
ChoiceManager.CurrentAction = nil

local function animateInSelectionTriangle(tri)
	--tri.Visible = true
	coroutine.wrap(function()
		GUIMaster.Animations.FocusOnTri(tri)
	end)()
end

local function animateOutSelectionTriangle(tri)
	--tri.Visible = false
	coroutine.wrap(function()
		GUIMaster.Animations.CleanUpTri(tri)
	end)()
end

local function sendTriangleInput(inp, close)
	--tri.Visible = false
	coroutine.wrap(function()
		GUIMaster.Animations.UpdateTri(inp, close)
	end)()
end

local function dictfind(tab, instKey)
	for i, v in ipairs(tab) do
		if v.Instance == instKey then
			return i
		end
	end
	return nil
end

-- Global Functions
function ChoiceManager.ToggleSkillMenu(category, personaName, skills, force, selectedSkill) -- Populates the SkillsFrame or itemFrame, (imma keep the param as skills for both js for simplicity for now)
	if category == "Skills" then
		-- Load from SkillLibrary
		-- Use the Red/Blue/Green UI styles
		if (not GUIMaster.UIs.SkillsMenu.Open) and (force ~= false) then
			ChoiceManager.CurrentAction = "Skills"
			local holder = GUIMaster.UIs.SkillsMenu.Object.Holder
			local skillFrame = holder.Overlay.SkillsFrame

			ChoiceManager.CurrentMax = #skills
			if ChoiceManager.CurrentSkillFrame > ChoiceManager.CurrentMax then
				ChoiceManager.CurrentSkillFrame = ChoiceManager.CurrentMax --[[
			reset if out of bounds for now, but maybe later if the player switches personas, then 
			thats when we reset the selection triangle to 1
			]]
			end

			-- update the persona name (e.g., "Zorro")
			holder.Overlay.TitleFrame.Nameplate.Nametext.Text = personaName

			GUIMaster.ClearFrame(skillFrame)
			local foundTri = GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.Tris:FindFirstChild("Tri"..tostring(ChoiceManager.CurrentSkillFrame))
			if foundTri then
				GUIMaster.ClearFrame(GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.Tris)
				ChoiceManager.CurrentSelectionTriangle = foundTri

				if GUIMaster.Connections.TriangleButton then
					for i, v in pairs(GUIMaster.Connections.TriangleButton) do
						v:Disconnect()
					end
				end

				animateInSelectionTriangle(foundTri)
				
				GUIMaster.Connections.TriangleButton = {
					foundTri.InTri.MouseButton1Click:Connect(function()
						sendTriangleInput("MouseClick", true)
						ChoiceManager.ConfirmSelection()
					end),

					foundTri.InTri.MouseEnter:Connect(function()
						sendTriangleInput("MouseEnter")
					end),

					foundTri.InTri.MouseLeave:Connect(function()
						sendTriangleInput("MouseLeave")
					end)
				}
			end

			-- populate skill buttons using SkillLibrary
			for i, skillName in ipairs(skills) do
				local frame = skillFrame:FindFirstChild("SkillFrame" .. i)
				if frame then
					local data = SkillLibrary.GetSkill(skillName)
					frame.Visible = true
					frame.Overtext.Text = data.Name
					frame.SPFrame.Overnumber.Text = data.Cost
					frame.SPFrame.Overtype.Text = data.CostType
					frame.SPFrame.Overnumber.TextXAlignment = Enum.TextXAlignment.Right

					if data.CostType == "HP" then
						frame.SPFrame.Overtype.TextXAlignment = Enum.TextXAlignment.Center
						frame.SPFrame.Overnumber:SetAttribute("TargetColor", Color3.fromRGB(8, 255, 164))
						frame.SPFrame.Overtype:SetAttribute("TargetColor", Color3.fromRGB(0, 0, 0))
						frame.SPFrame.Slider:SetAttribute("TargetColor", Color3.fromRGB(8, 255, 164))
						frame.SPFrame.Slider:SetAttribute("InUse", true)
					else
						frame.SPFrame.Slider:SetAttribute("InUse", false)
						frame.SPFrame.Overtype.TextXAlignment = Enum.TextXAlignment.Left
						frame.SPFrame.Overnumber:SetAttribute("TargetColor", Color3.new(1, 1, 1))
						frame.SPFrame.Overtype:SetAttribute("TargetColor", Color3.new(1, 1, 1))
					end
					frame.IconFrame.Img.Image = data.Icon
					-- PLAN: UPDATE UI GRADIENTS BASED ON ELEMENT TYPE
				end
			end

			GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, false)
			GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, false)
			GUIMaster.ToggleMenu(GUIMaster.UIs.SkillsMenu, true)
		else
			if GUIMaster.Connections.TriangleButton then
				for i, v in pairs(GUIMaster.Connections.TriangleButton) do
					v:Disconnect()
				end
			end
			if not selectedSkill then
				ChoiceManager.CurrentSelectionTriangle = nil
				ChoiceManager.CurrentAction = nil

				GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, true)
				GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, true)
			end
			GUIMaster.ToggleMenu(GUIMaster.UIs.SkillsMenu, false)
		end	
	elseif category == "Items" then
		-- Load from ItemLibrary
		-- Use a simpler UI style (maybe just white/yellow)
	end
end

function ChoiceManager.ChangeSelection(dir) -- Populates the SkillsFrame
	if dir == "up" then
		if ChoiceManager.CurrentSkillFrame > 1 then -- if at top, go to bottom 
			ChoiceManager.CurrentSkillFrame -= 1 
		else
			ChoiceManager.CurrentSkillFrame = ChoiceManager.CurrentMax
		end
	elseif dir == "down" then	
		if ChoiceManager.CurrentSkillFrame < ChoiceManager.CurrentMax then -- if at bottom, go to top 
			ChoiceManager.CurrentSkillFrame += 1
		else
			ChoiceManager.CurrentSkillFrame = 1
		end
	end
	CameraHandler.FocusOn(GUIMaster.CurrentFighterData.Instance, nil, CameraHandler.OffsetPresets.SkillMenu, CFrame.new(0, -1.5 * (ChoiceManager.CurrentSkillFrame - 1), 0), "Mid Zoom")
	
	local foundTri = GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.Tris:FindFirstChild("Tri"..tostring(ChoiceManager.CurrentSkillFrame))
	if foundTri then
		GUIMaster.ClearFrame(GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.Tris, animateOutSelectionTriangle)
		if GUIMaster.Connections.TriangleButton then
			for i, v in pairs(GUIMaster.Connections.TriangleButton) do
				v:Disconnect()
			end
		end
		
		animateInSelectionTriangle(foundTri)

		GUIMaster.Connections.TriangleButton = {
			foundTri.InTri.MouseButton1Click:Connect(function()
				sendTriangleInput("MouseClick", true)
				ChoiceManager.ConfirmSelection()
			end),

			foundTri.InTri.MouseEnter:Connect(function()
				sendTriangleInput("MouseEnter")
			end),

			foundTri.InTri.MouseLeave:Connect(function()
				sendTriangleInput("MouseLeave")
			end)
		}
	end
end

function ChoiceManager.ConfirmSelection()
	if not ChoiceManager.CurrentAction then return end

	local skillFrame = GUIMaster.UIs.SkillsMenu.Object.Holder.Overlay.SkillsFrame:FindFirstChild("SkillFrame" .. tostring(ChoiceManager.CurrentSkillFrame))
	local skillName = skillFrame.Overtext.Text
	local skillData = SkillLibrary.GetSkill(skillName)

	if ChoiceManager.CurrentSelectionTriangle and not GUIMaster.UIs.Target.Open then 
		-- PHASE 1: CHOSE A SKILL, NOW OPEN TARGETING
		ChoiceManager.ToggleSkillMenu("Skills", nil, nil, false, true) 

		if skillData.TargetType == "Enemies" then
			GUIMaster.UIs.Target.Options = GUIMaster.CurrentFightTab.EnemyFighters
		elseif skillData.TargetType == "Allies" then
			GUIMaster.UIs.Target.Options = GUIMaster.CurrentFightTab.PlayerFighters
		elseif skillData.TargetType == "Any" then
			GUIMaster.UIs.Target.Options = GUIMaster.CurrentFightTab.AllFighters
		elseif skillData.TargetType == "Self" then
			GUIMaster.UIs.Target.Options = {GUIMaster.CurrentFighterData}
		end

		if GUIMaster.UIs.Target.Index > #GUIMaster.UIs.Target.Options then
			GUIMaster.UIs.Target.Index = 1
		end

		-- BUG FIX: If it's a multi-target skill, show icons on EVERYONE in the options list immediately
		if skillData.TargetAmt and skillData.TargetAmt == "All" then
			local instances = {}
			for _, data in ipairs(GUIMaster.UIs.Target.Options) do 
				table.insert(instances, data.Instance) 
			end
			GUIMaster.MoveTarget(instances) -- Pass the whole table
			GUIMaster.FocusCamOnTarget(GUIMaster.UIs.Target.Options[math.ceil(#GUIMaster.UIs.Target.Options/2)].Instance, nil, true)
		else
			local selected = GUIMaster.UIs.Target.Options[GUIMaster.UIs.Target.Index]
			GUIMaster.MoveTarget({selected.Instance}) -- Wrap in table for consistency
			GUIMaster.FocusCamOnTarget(selected.Instance, nil, true)
			GUIMaster.MoveHeart(selected)
		end

	elseif GUIMaster.UIs.Target.Open then 
		-- PHASE 2: CHOSE TARGETS, SEND TO SERVER
		local targetIndices = {}

		if skillData.TargetAmt and skillData.TargetAmt == "All" then
			-- Logic: Select every index that belongs to the target group
			for _, targetData in ipairs(GUIMaster.UIs.Target.Options) do
				local idx = dictfind(GUIMaster.CurrentFightTab.AllFighters, targetData.Instance)
				if idx then table.insert(targetIndices, idx) end
			end
		else
			-- Logic: Select only the one specifically highlighted
			local selectedFighter = GUIMaster.UIs.Target.Options[GUIMaster.UIs.Target.Index]
			local idx = dictfind(GUIMaster.CurrentFightTab.AllFighters, selectedFighter.Instance)
			if idx then table.insert(targetIndices, idx) end
		end

		-- We send the TABLE of indices. Even if it's 1 target, it's {index}
		local currentSpeed = plr:GetAttribute("CurrentCombatSpeedMultiplier") or 1
		local m = (#GUIMaster.UIs.Target.Indicators > 1) or nil
		for i, v in pairs(GUIMaster.UIs.Target.Indicators) do
			GUIMaster.ToggleTargets(v, false, m)
		end
		WaitForInput:Fire(ChoiceManager.CurrentAction, skillName, targetIndices, currentSpeed)
	end 
end

return ChoiceManager
