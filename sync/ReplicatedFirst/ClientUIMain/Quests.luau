-- Constants

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local keySettings = require(Storage.Info.KeybindsMaster)

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local mouse = plr:GetMouse()

local ui = playerGUI:WaitForChild("GlobalUI")
local frame = ui:WaitForChild("Questbar")
local box1 = frame:WaitForChild("Questbox")
local slot1, slot2 = box1:WaitForChild("Questslot1"), box1:WaitForChild("Questslot2")

--
local dataUpdEv = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("DataUpdated")
local questRem = Storage:WaitForChild("Events").Remotes.QuestRem
local getData = Storage:WaitForChild("Functions").Remotes.GetData

local TIS = {
	["Open"] = TweenInfo.new(
		0.85,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
	["Close"] = TweenInfo.new(
		1.25,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	),
}

-- Variables
local TES = {}
local cons = {}

-- Initialization
local quests = {}

-- Global Variables

-- Local Functions
local function countDict(dict)
	local count = 0
	for i, v in pairs(dict) do
		count += 1
	end
	return count
end 

local function findInDict(dict, obj, dir)
	if dir then
		if dict[dir] == obj then return dir end
	end
	for i, v in pairs(dict) do
		--print(v)
		--print(obj)
		--print(obj.ClassName)

		--print(dict[i])
		--print(v == obj)
		if dict[i] == obj then
			--print(i)
			return i
		end
	end
end

local function findBoxwText(txt, container)
	for i, v in pairs(container:GetChildren()) do
		if v.Visible and v:IsA("Frame") and v:FindFirstChild("TextLabel") then
			if v:FindFirstChild("TextLabel").Text == txt then
				return v
			end
		end
	end
end

local function getReadySlot()
	return ((not slot1:GetAttribute("Using")) and slot1) or ((not slot2:GetAttribute("Using")) and slot2) or nil
end

local function tableContainsAmt(progressTable, goalTable)
	local amt = 0
	for i, v in pairs(goalTable) do
		if table.find(progressTable, v) then
			amt += 1
		end
	end
	return amt
end

local function getVisibleChildren(parent)
	local count = 0
	for i, v in pairs(parent:GetChildren()) do
		if v:IsA("Frame") then
			if v.Visible then
				count +=1
			end
		end
	end
	return count
end

function updateQuestUI(action, questData)
	if action == "Start" then
		for i, v in pairs(questData.Current) do -- setup loaded quests
			if not findBoxwText(i, box1) then
				local newSlot = getReadySlot()
				if not newSlot then return end
				newSlot:SetAttribute("Using", true)
				--newSlot.Name = i
				newSlot.TextLabel.Text = i
				if not cons[newSlot] then
					cons[newSlot] = {}
				end
				if typeof(v.Goal) == 'number' then
					newSlot.Progress.Text = v.Progress.."/"..v.Goal
					newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 2
					newSlot.Progress.UIStroke.Enabled = false
					newSlot.Progress.Check.Visible = false
				elseif typeof(v.Goal) == 'boolean' then
					newSlot.Progress.Text = ""
					newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 1
					newSlot.Progress.UIStroke.Enabled = true
					newSlot.Progress.Check.Visible = v.Progress
				elseif typeof(v.Goal) == 'table' then
					newSlot.Progress.Text = ""
					newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 1
					newSlot.Progress.UIStroke.Enabled = true
					newSlot.Progress.Check.Visible = false
				else
					newSlot.Progress.Visible = false
				end
				cons[newSlot].Close = newSlot.Cancel.MouseButton1Click:Connect(function()
					questRem:FireServer("questRemove", nil, i)
				end)
				newSlot.Parent = box1
				newSlot.Visible = true
			end
		end
	elseif action == "Add" then -- add new quests to the questbar
		local i, v = questData.Text, questData
		if not findBoxwText(i, box1) then
			local newSlot = getReadySlot()
			if not newSlot then return end
			newSlot:SetAttribute("Using", true)
			--newSlot.Name = i
			newSlot.TextLabel.Text = i
			if not cons[newSlot] then
				cons[newSlot] = {}
			end
			if typeof(v.Goal) == 'number' then
				newSlot.Progress.Text = v.Progress.."/"..v.Goal
				newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 2
				newSlot.Progress.UIStroke.Enabled = false
				newSlot.Progress.Check.Visible = false
			elseif typeof(v.Goal) == 'boolean' then
				newSlot.Progress.Text = ""
				newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 1
				newSlot.Progress.UIStroke.Enabled = true
				newSlot.Progress.Check.Visible = v.Progress
			elseif typeof(v.Goal) == 'table' then
				newSlot.Progress.UIAspectRatioConstraint.AspectRatio = 2
				newSlot.Progress.UIStroke.Enabled = false
				newSlot.Progress.Check.Visible = false
				newSlot.TableLabel.Visible = false
				
				cons[newSlot].Enter = newSlot.Progress.MouseEnter:Connect(function()
					newSlot.TableLabel.Visible = true
				end)
				cons[newSlot].Leave = newSlot.Progress.MouseLeave:Connect(function()
					newSlot.TableLabel.Visible = false
				end)
				newSlot.Progress.Text = tableContainsAmt(v.Progress, v.Goal).."/"..#v.Goal
				for i, v in pairs(newSlot.TableLabel:GetChildren()) do
					if v:IsA("TextLabel") then
						v:Destroy()
					end
				end
				
				local count = 0
				for i2, v2 in pairs(v.Goal) do
					local tslot = script.TableSlot:Clone()
					tslot.Text = v2
					tslot.Parent = newSlot.TableLabel
					tslot.LayoutOrder = count
					tslot.Name = count
					
					if table.find(v.Progress, v2) then
						tslot.TextColor3 = Color3.fromRGB(85, 255, 0)
					else
						tslot.TextColor3 = Color3.fromRGB(144, 144, 144)
					end
					tslot.Visible = true
					count += 1
				end
			else
				newSlot.Progress.Visible = false
			end
			cons[newSlot].Close = newSlot.Cancel.MouseButton1Click:Connect(function()
				questRem:FireServer("questRemove", nil, i)
			end)
			newSlot.Parent = box1
			-- add a slide in animation here
			newSlot.Visible = true
		end
	elseif action == "Update" then 
		local foundslot = findBoxwText(questData.Text, box1)
		if foundslot then -- update the data here
			if typeof(questData.Goal) == 'number' then
				foundslot.Progress.Text = questData.Progress.."/"..questData.Goal
				--foundslot.Progress.UIAspectRatioConstraint.AspectRatio = 2
				--foundslot.Progress.UIStroke.Enabled = false
				if questData.Progress >= questData.Goal then 
					-- TODO: add a text label color to green animation here
				end
			elseif typeof(questData.Goal) == 'boolean' then
				--foundslot.Progress.Text = ""
				--foundslot.Progress.UIAspectRatioConstraint.AspectRatio = 1
				--foundslot.Progress.UIStroke.Enabled = false
				foundslot.Progress.Check.Visible = questData.Progress
				if questData.Progress then 
					-- TODO: add a check imagecolor to green animation here
				end
			elseif typeof(questData.Goal) == 'table' then
				foundslot.Progress.Text = tableContainsAmt(questData.Progress, questData.Goal).."/"..#questData.Goal
				
				for i, v in pairs(foundslot.TableLabel:GetChildren()) do
					if v:IsA("TextLabel") then
						if table.find(questData.Progress, v.Text) then
							v.TextColor3 = Color3.fromRGB(85, 255, 0)
						else
							v.TextColor3 = Color3.fromRGB(144, 144, 144)
						end
					end
				end
			end
		end
	elseif action == "Remove" then
		local foundslot = findBoxwText(questData.Text, box1)
		if foundslot then
			if cons[foundslot] then
				for i, v in pairs(cons[foundslot]) do
					v:Disconnect()
				end
			end
			local completed = false
			if typeof(questData.Goal) == 'number' then
				completed = questData.Progress >= questData.Goal
			elseif typeof(questData.Goal) == 'boolean' then
				completed = questData.Progress
			elseif typeof(questData.Goal) == 'table' then
				completed = tableContainsAmt(questData.Progress, questData.Goal) >= #questData.Goal
			else
				completed = false
			end

			if completed then
				-- TODO: add a slide out quest vanish animation here if completed is true
			end
			foundslot.Visible = false
			foundslot:SetAttribute("Using", false)
		end
	end

	if (frame.BackgroundTransparency < 1) and (getVisibleChildren(box1) <= 0) then
		if TES[frame] then
			for i, TE in pairs(TES[frame]) do
				if TE.PlaybackState == Enum.PlaybackState.Playing then
					TE:Cancel()
				end
			end
		else
			TES[frame] = {}
		end
		TES[frame].Fade = TS:Create(frame, TIS.Close, {BackgroundTransparency = 1})
		TES[frame].Stroke = TS:Create(frame.Lines.UIStroke, TIS.Close, {Transparency = 0.9, Thickness = 1.5})
		TES[frame].Fade:Play()	
		TES[frame].Stroke:Play()	
	elseif (frame.BackgroundTransparency > frame:GetAttribute("BaseBackgroundTransparency")) and (getVisibleChildren(box1) > 0) then
		if TES[frame] then
			for i, TE in pairs(TES[frame]) do
				if TE.PlaybackState == Enum.PlaybackState.Playing then
					TE:Cancel()
				end
			end
		else
			TES[frame] = {}
		end
		TES[frame].Fade = TS:Create(frame, TIS.Open, {BackgroundTransparency = frame:GetAttribute("BaseBackgroundTransparency")})
		TES[frame].Stroke = TS:Create(frame.Lines.UIStroke, TIS.Open, {Transparency = frame.Lines.UIStroke:GetAttribute("BaseTransparency"), Thickness = frame.Lines.UIStroke:GetAttribute("BaseThickness")})
		TES[frame].Fade:Play()	
		TES[frame].Stroke:Play()	
	end
end

function quests.setup()

	task.spawn(function()
		local globalData = nil
		while not globalData do
			pcall(function()
				globalData = getData:InvokeServer("Global")
			end)
			if not globalData then task.wait(1) end
		end

		for i, v in pairs(box1:GetChildren()) do
			if v:IsA("Frame") then
				v.Visible = false
				v:SetAttribute("Using", false)
			end
		end
		
		updateQuestUI("Start", globalData.Data.Quests)
		
		dataUpdEv.OnClientEvent:Connect(function(which, changed1, changed2)
			if which == "Global -Quests" then
				updateQuestUI(changed1, changed2)
			end
		end)
	end)
end

return quests