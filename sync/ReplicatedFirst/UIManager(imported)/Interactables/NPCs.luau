-- Constants
local defaultBarLength = 0.05

local BAR_SETTINGS = {
	OGSize = UDim2.new(0.713, 0, 0.231, 0),
	OGTransparency = 0.4,

	OGArrowPos = UDim2.new(0.225, 0, 0.738, 0),

	OGMidButPos = UDim2.new(0.841, 0, 1.398, 0),
	YNButDist = 0.121/2,

	OGYNButColor = Color3.new(1, 1, 1),
	HoverYNButColor = Color3.new(0.694118, 0.694118, 0.694118),

	OGButSize = UDim2.new(0.068, 0, 0.723, 0),
	HoverYNButScale = 0.1,

	ArrowChange = 0.05,
	
	OGLineTransparency = 0.1,
}

--local HOVER_SETTINGSb = {
--	RotateForwardSpeed = 0.55,
--	RotateBackSpeed = 1.5,
--	OGPosition = UDim.new(0, 1),
--	PositionAddition = UDim2.new(0, 0, 0.085, 0),
--}

-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- Dependencies
local Storage = RPS:WaitForChild("ClientStorage")
local richText = require(Storage:WaitForChild("Modules"):WaitForChild("Open Source"):WaitForChild("GUI"):WaitForChild("RichText"))
local keySettings = require(Storage.Info.KeybindsMaster)
local itemInfo = require(Storage.Info.ItemInfo)
local npcIndex = require(Storage.Info.NPCIndex)
local npcRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("NPCRem")
local questRem = Storage:WaitForChild("Events"):WaitForChild("Remotes"):WaitForChild("QuestRem")
local getData = Storage:WaitForChild("Functions").Remotes.GetData

local plr = game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer.Character ~= nil
local char = game.Players.LocalPlayer.Character
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")

local ui = playerGUI:WaitForChild("GlobalUI")
local mainFrame = ui:WaitForChild("Chatbar")
local bar = mainFrame:WaitForChild("Main")
local frame = bar:WaitForChild("Frame")
local tframe = bar:WaitForChild("Title")
local label = frame:WaitForChild("TextLabel") 
local arrow = frame:WaitForChild("Arrow")
local accept = frame:WaitForChild("Accept")
local decline = frame:WaitForChild("Decline")


local TIS = {
	[1] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In
	),
	frameFadeIn = TweenInfo.new(
		0.4
	),
	frameFadeOut = TweenInfo.new(
		1.25,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	arrowUpNDown = TweenInfo.new(
		1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		-1,
		true
	),
	quickFadeIn = TweenInfo.new(
		0.2
	),
	quickFadeOut = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	whiteOut = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		0,
		true
	)
}
local bt1, bt2 = nil, nil
local generalTES = {}
local generalCons = {}
local latestTextObject = nil

-- Initialization
local NPCM = {}
NPCM.currentNPC = nil

-- Local Functions
local function countDict(dict)
	local count = 0
	for i, v in pairs(dict) do
		count += 1
	end
	return count
end 

local function fadeInFrame()
	if bt1 then
		if bt1.PlaybackState == Enum.PlaybackState.Playing then
			bt1:Cancel()
		end
	end
	if bt2 then
		if bt2.PlaybackState == Enum.PlaybackState.Playing then
			bt2:Cancel()
		end
	end
	bt1 = TS:Create(bar, TIS.frameFadeIn, {Size = BAR_SETTINGS.OGSize, BackgroundTransparency = BAR_SETTINGS.OGTransparency})
	bt2 = TS:Create(bar.Chatbar2, TIS.frameFadeIn, {ImageTransparency = BAR_SETTINGS.OGTransparency})
	local bt3s = {}
	for i = 1, 5 do
		local line = mainFrame:FindFirstChild("Line"..tostring(i))
		if line and line.Visible then
			generalTES[line] = TS:Create(line, TIS.frameFadeIn, {BackgroundTransparency = BAR_SETTINGS.OGLineTransparency})
			table.insert(bt3s, generalTES[line])
		end
	end
	
	return bt1, bt2, bt3s
end

local function fadeOutFrame()
	if bt1 then
		if bt1.PlaybackState == Enum.PlaybackState.Playing then
			bt1:Cancel()
		end
	end
	if bt2 then
		if bt2.PlaybackState == Enum.PlaybackState.Playing then
			bt2:Cancel()
		end
	end

	bt1 = TS:Create(bar, TIS.frameFadeOut, {Size = UDim2.new(BAR_SETTINGS.OGSize.X.Scale * 0.85, 0, BAR_SETTINGS.OGSize.Y.Scale * 0.85, 0), BackgroundTransparency = 1})
	bt2 = TS:Create(bar.Chatbar2, TIS.frameFadeOut, {ImageTransparency = 1})
	local bt3s = {}
	for i = 1, 5 do
		local line = mainFrame:FindFirstChild("Line"..tostring(i))
		if line and line.Visible then
			generalTES[line] = TS:Create(line, TIS.frameFadeIn, {BackgroundTransparency = 1})
			table.insert(bt3s, generalTES[line])
		end
	end
	
	return bt1, bt2, bt3s
end

function lineMessage(text, duration, newLabel--[[, continued]])
	-- Rich text Wind Waker example: -- https://youtu.be/CY3ghdwL9W4?t=4m34s	https://twitter.com/Defaultio/status/903138250054709248

	--print("texting")

	--local textObject = richText:New(label, text, {Font = "Cartoon"})--, AnimateStyle = "Wiggle", AnimateStepFrequency = 1, AnimateStyleTime = 7, AnimateStyleNumPeriods = 10})
	latestTextObject = richText:New(newLabel or label, text, {Font = (newLabel and newLabel.Font.Name) or (label and label.Font.Name), ContainerHorizontalAlignment = "Left", ContainerVerticalAlignment = "Top", AnimateStyleTime = 7})--, AnimateStyle = "Wiggle", AnimateStepFrequency = 1, AnimateStyleTime = 7, AnimateStyleNumPeriods = 10})

	local ccon 

	ccon = UIS.InputBegan:Connect(function(inp, gP)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
			ccon:Disconnect()
			ccon = nil
			if latestTextObject then
				latestTextObject:Show()
			end
		end
	end)

	latestTextObject:Animate(true)

	if ccon then
		ccon:Disconnect()
	end

	--task.wait(1)

	-- too lazy to script 🥱
	--print(text)
	--task.wait(duration + 0.5)

	--This is the animation example:
	--local textSequence = {{Text = "This text is about to be <Color=Green><AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=2>wiggly<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1.5>\nIt can also be <Color=Red><AnimateStyle=Fade><AnimateStepFrequency=1><AnimateStyleTime=0.5>fadey <Img=Eggplant>fadey<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1>\n<AnimateStyle=Rainbow><AnimateStyleTime=2>Or rainbow!!! :O<Img=Thinking><AnimateStyle=/><AnimateStyleTime=/><AnimateYield=1>\n<AnimateStyle=Swing><AnimateStyleTime=3>Make custom animations! <Img=Eggplant>", Delay = 10}}

	--This is a text justification example:
	--local textSequence = {{Text = "Have you ever <Color=Red>thought<Color=/><AnimateStepFrequency=1><AnimateStepTime=0.4> . . .<AnimateStepFrequency=/><AnimateStepTime=/><AnimateYield=1><ContainerHorizontalAlignment=Center>\n<TextScale=0.5><AnimateStyle=Rainbow><AnimateStyleTime=2.5><Img=Thinking><AnimateStyle=/><TextScale=/><AnimateYield=3><ContainerHorizontalAlignment=Right>\n<Color=Green><AnimateStyle=Spin><AnimateStyleTime=1.5>Wow<AnimateStyle=/><Color=/>!", Delay = 10}}
	--task.wait(duration)
	--task.wait()
end

local function bindBut(btn)
	if generalCons[btn] then
		for i, v in pairs(generalCons[accept]) do
			v:Disconnect()
		end
		generalCons[btn] = nil
	end

	if generalTES[btn] then
		if generalTES[btn].PlaybackState == Enum.PlaybackState.Playing then
			generalTES[btn]:Cancel()
		end
	end

	generalCons[btn] = {
		btn.MouseEnter:Connect(function()
			if generalTES[btn] then
				if generalTES[btn].PlaybackState == Enum.PlaybackState.Playing then
					generalTES[btn]:Cancel()
				end
			end
			generalTES[btn] = TS:Create(btn, TIS.quickFadeIn, {BackgroundColor3 = BAR_SETTINGS.HoverYNButColor, Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)})
			generalTES[btn]:Play()
		end),

		btn.MouseLeave:Connect(function()
			if generalTES[btn] then
				if generalTES[btn].PlaybackState == Enum.PlaybackState.Playing then
					generalTES[btn]:Cancel()
				end
			end
			generalTES[btn] = TS:Create(btn, TIS.quickFadeOut, {BackgroundColor3 = BAR_SETTINGS.OGYNButColor, Size = BAR_SETTINGS.OGButSize})
			generalTES[btn]:Play()
		end)
	}

	return generalCons[btn]	
end

-- Global Functions
function NPCM.runNPC(npcObject, dialogueName, displayName) -- dialogueName and displayName is optional if you have an npc model
	if NPCM.currentNPC or (not ((npcObject and npcObject:GetAttribute("NPCType") and npcIndex[npcObject.Name]) or (dialogueName and npcIndex[dialogueName]))) then return end

	if not displayName then
		if npcObject then
			displayName = npcObject.Name
			tframe.Visible = true
			mainFrame.Line5.Visible = false
		else
			mainFrame.Line5.Visible = true
			tframe.Visible = false
		end
	else
		tframe.Visible = true
		mainFrame.Line5.Visible = false
	end
	
	local npcInfo = (displayName and npcIndex[displayName]) or (dialogueName and npcIndex[dialogueName])

	if latestTextObject then
		latestTextObject:Hide()
	end
	tframe.TextLabel.Text = ""
	label.Text = ""
	bar.Visible = true
	frame.Visible = true
	NPCM.currentNPC = npcObject
	local options = {}

	for i, v in pairs(generalTES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	generalTES = {}

	for i, v in pairs(generalCons) do
		if typeof(v) == 'RBXScriptConnection' then
			v:Disconnect()
		elseif typeof(v) == 'table' then
			for i2, v2 in pairs(v) do
				if typeof(v2) == 'RBXScriptConnection' then
					v2:Disconnect()
				end
			end
		end
	end
	generalCons = {}

	tframe.TextLabel.Text = npcInfo.DisplayName and npcInfo.DisplayName.Text or displayName or ""
	tframe.TextLabel.TextColor3 = npcInfo.DisplayName and npcInfo.DisplayName.Color or Color3.new(1, 1, 1)
	
	
	npcRem:FireServer("start", displayName)
	
	local te1, te2, te3s = fadeInFrame()
	te1:Play()
	te2:Play()
	for i, te3 in pairs(te3s) do
		te3:Play()
	end

	local Data = getData:InvokeServer("Global")

	local npcData = Data.Data.NPCData
	local npcType = npcObject and npcObject:GetAttribute("NPCType") or nil

	local questData = Data.Data.Quests
	local dilogs = npcInfo.Dialogues
	local dilog = dilogs.First

	if displayName then
		if npcType == "Quest" and countDict(questData.Current) >= 2 and (not (npcData[displayName] and (npcData[displayName] ~= "First") and npcData[displayName].QuestSequenceIndex and npcData[displayName].QuestSequenceIndex >= 1)) then
			dilog = dilogs["2manyquests"] or npcIndex.TooManyQuestsDefaultDialouge
		elseif npcData[displayName] then
			dilog = dilogs[npcData[displayName].Behavior]
		end
	end

	local latestV = nil
	local latestAlt = false
	local nextDialogue = nil

	for i, v in ipairs(dilog) do
		latestAlt = false
		latestV = v
		--
		local lastOption = options[i - 1]

		local canAlt = false
		if v.AltText and v.AltText.Condition then
			local past = tonumber(v.AltText.Condition.Past) or lastOption
			local ans = v.AltText.Condition.Answer

			canAlt = options[past] == ans
			latestAlt = options[past] == ans
		end
		lineMessage(canAlt and v.AltText.Text or v.Text)


		if v.NameChange and v.NameChange.Text then
			tframe.TextLabel.Text = v.NameChange.Text
			tframe.TextLabel.TextColor3 = v.NameChange.Color or Color3.new(1, 1, 1)
		end

		local canContinue = false
		local myCon, myCon2
		if v.QuestFinished and displayName then
			questRem:FireServer("questRemove", displayName)
		end
		if not v.Specialty then
			arrow.Position = UDim2.new(BAR_SETTINGS.OGArrowPos.X, UDim.new(BAR_SETTINGS.OGArrowPos.Y.Scale + BAR_SETTINGS.ArrowChange, 0))
			arrow.Visible = true
			generalTES[arrow] = TS:Create(arrow, TIS.arrowUpNDown, {Position = UDim2.new(BAR_SETTINGS.OGArrowPos.X, UDim.new(BAR_SETTINGS.OGArrowPos.Y.Scale - (BAR_SETTINGS.ArrowChange*2), 0))})
			generalTES[arrow]:Play()

			myCon = UIS.InputBegan:Connect(function(inp, gP)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
					canContinue = true
				end
			end)
			table.insert(generalCons, myCon)
		else
			if string.sub(v.Specialty, 1, 3) == "Y/N" then
				accept.Position = BAR_SETTINGS.OGMidButPos
				decline.Position = BAR_SETTINGS.OGMidButPos
				accept.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
				decline.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)

				accept.Whiteout.BackgroundTransparency = 1
				decline.Whiteout.BackgroundTransparency = 1
				accept.Visible = true
				decline.Visible = true

				generalTES[accept.Whiteout] = TS:Create(accept.Whiteout, TIS.whiteOut, {BackgroundTransparency = 0.15})
				generalTES[decline.Whiteout] = TS:Create(decline.Whiteout, TIS.whiteOut, {BackgroundTransparency = 0.15})
				generalTES[accept] = TS:Create(accept, TIS.frameFadeIn, {Position = UDim2.new(UDim.new(BAR_SETTINGS.OGMidButPos.X.Scale - BAR_SETTINGS.YNButDist, 0), BAR_SETTINGS.OGMidButPos.Y), Size = BAR_SETTINGS.OGButSize})
				generalTES[decline] = TS:Create(decline, TIS.frameFadeIn, {Position = UDim2.new(UDim.new(BAR_SETTINGS.OGMidButPos.X.Scale + BAR_SETTINGS.YNButDist, 0), BAR_SETTINGS.OGMidButPos.Y), Size = BAR_SETTINGS.OGButSize})

				generalTES[accept.Whiteout]:Play()
				generalTES[decline.Whiteout]:Play()
				generalTES[accept]:Play()
				generalTES[decline]:Play()

				generalTES[decline].Completed:Wait()

				local afold = bindBut(accept)
				local dfold = bindBut(decline)

				table.insert(afold, accept.MouseButton1Click:Connect(function()
					local specialtySub2 = string.sub(v.Specialty, 5)
					if specialtySub2 == "Quest" and displayName then
						questRem:FireServer("questRequest", displayName)
					elseif specialtySub2 == "Action" then
						questRem:FireServer("actionRequest", displayName or dialogueName, v.Action)
					end

					if generalTES[accept.Whiteout] then
						if generalTES[accept.Whiteout].PlaybackState == Enum.PlaybackState.Playing then
							generalTES[accept.Whiteout]:Cancel()
						end
					end
					accept.Whiteout.BackgroundTransparency = 1

					generalTES[accept.Whiteout] = TS:Create(accept.Whiteout, TIS.whiteOut, {BackgroundTransparency = 0.08})

					generalTES[accept.Whiteout]:Play()
					options[i] = 'accepted' 
					task.wait(0.5)
					canContinue = true
				end))

				table.insert(dfold, decline.MouseButton1Click:Connect(function()
					if generalTES[decline.Whiteout] then
						if generalTES[decline.Whiteout].PlaybackState == Enum.PlaybackState.Playing then
							generalTES[decline.Whiteout]:Cancel()
						end
					end
					decline.Whiteout.BackgroundTransparency = 1

					generalTES[decline.Whiteout] = TS:Create(decline.Whiteout, TIS.whiteOut, {BackgroundTransparency = 0.08})

					generalTES[decline.Whiteout]:Play()
					options[i] = 'declined' 
					task.wait(0.5)
					canContinue = true
				end))
			end
		end

		repeat wait() until canContinue

		if myCon then
			myCon:Disconnect()
			myCon = nil
		end

		if generalCons[accept] then
			for i, v in pairs(generalCons[accept]) do
				v:Disconnect()
			end
			generalCons[accept] = nil
		end
		if generalCons[decline] then
			for i, v in pairs(generalCons[decline]) do
				v:Disconnect()
			end
			generalCons[decline] = nil
		end
		if generalTES[arrow] then
			if generalTES[arrow].PlaybackState == Enum.PlaybackState.Playing then
				generalTES[arrow]:Cancel()
			end
		end
		if generalTES[accept] then
			if generalTES[accept].PlaybackState == Enum.PlaybackState.Playing then
				generalTES[accept]:Cancel()
			end
		end
		if generalTES[decline] then
			if generalTES[decline].PlaybackState == Enum.PlaybackState.Playing then
				generalTES[decline]:Cancel()
			end
		end

		arrow.Visible = false

		accept.Visible = false
		accept.Whiteout.BackgroundTransparency = 1
		decline.Visible = false
		decline.Whiteout.BackgroundTransparency = 1
	end 
	
	if dilog.NextDialogue then
		if dilog.NextDialogue.Condition then
			local past = tonumber(dilog.NextDialogue.Condition.Past)
			local ans = dilog.NextDialogue.Condition.Answer
			--print(past)
			--print(ans)

			nextDialogue = (options[past] == ans and dilog.NextDialogue.Dialogue)
		else
			nextDialogue = dilog.NextDialogue.Dialogue
		end
	end

	if displayName then
		npcRem:FireServer("end", displayName, (((latestAlt) and latestV.AltText.NextDialogue)) or nextDialogue or nil)
	end

	for i, v in pairs(generalTES) do
		if v.PlaybackState == Enum.PlaybackState.Playing then
			v:Cancel()
		end
	end
	generalTES = {}

	for i, v in pairs(generalCons) do
		if typeof(v) == 'RBXScriptConnection' then
			v:Disconnect()
		elseif typeof(v) == 'table' then
			for i2, v2 in pairs(v) do
				if typeof(v2) == 'RBXScriptConnection' then
					v2:Disconnect()
				end
			end
		end
	end
	generalCons = {}


	frame.Visible = false
	arrow.Visible = false

	accept.Visible = false
	accept.Whiteout.BackgroundTransparency = 1
	accept.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	accept.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	decline.Visible = false
	decline.Whiteout.BackgroundTransparency = 1
	decline.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	decline.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	label.Text = ""
	tframe.Visible = false
	tframe.TextLabel.Text = ""


	te1, te2, te3s = fadeOutFrame()
	te1:Play()
	te2:Play()
	for i, te3 in pairs(te3s) do
		te3:Play()
	end

	NPCM.currentNPC = nil
end

function NPCM.setup()
	bar.Visible = false
	
	frame:WaitForChild("SampleText"):Destroy()
	frame:WaitForChild("TextLabel").Visible = true
	
	bar.Size = UDim2.new(BAR_SETTINGS.OGSize.X.Scale * 0.85, 0, BAR_SETTINGS.OGSize.Y.Scale * 0.85, 0)
	bar.BackgroundTransparency = 1
	bar.Chatbar2.ImageTransparency = 1
	for i = 1, 5 do
		local line = mainFrame:FindFirstChild("Line"..tostring(i))
		if line then
			line.BackgroundTransparency = 1
		end
	end
	frame.Visible = false
	arrow.Visible = false

	accept.Visible = false
	accept.Whiteout.BackgroundTransparency = 1
	accept.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	accept.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	decline.Visible = false
	decline.Whiteout.BackgroundTransparency = 1
	decline.Size = UDim2.new(BAR_SETTINGS.OGButSize.X.Scale - BAR_SETTINGS.HoverYNButScale/10, 0, BAR_SETTINGS.OGButSize.Y.Scale - BAR_SETTINGS.HoverYNButScale, 0)
	decline.BackgroundColor3 = BAR_SETTINGS.OGYNButColor

	arrow.Position = BAR_SETTINGS.OGArrowPos
	label.Text = ""
	tframe.Visible = false
	tframe.TextLabel.Text = ""
	
	npcRem.OnClientEvent:Connect(function(dialogueObj, dialogueName, displayName)
		if (dialogueName and npcIndex[dialogueName]) or npcIndex[dialogueObj.Name] then
			NPCM.runNPC(dialogueObj, dialogueName, displayName)
		end
	end)
end

return NPCM
