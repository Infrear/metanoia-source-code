-- Services
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")
local CPV = game:GetService("ContentProvider")

-- Dependencies
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local cam = workspace.CurrentCamera
local hum = char:WaitForChild("Humanoid")
local playerGUI = plr:WaitForChild("PlayerGui")
local hrp = char:WaitForChild("HumanoidRootPart")

local Storage = RPS:WaitForChild("ClientStorage")
local CombatAnims = Storage.Animations.Combat
local CameraHandler = require(script.Parent.CameraHandler)
local ScreenHandler = require(script.Parent.ScreenChangeHandler)
local AnimsManager = require(script.Parent.GUIMaster.Animations)
local Highlights = require(script.Parent.GUIMaster.Animations.Highlights)
local AnimationManager2 = char:WaitForChild("States"):WaitForChild("AnimationManager2")


local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)
local CameraShaker = require(Storage.Classes.BaseClasses.CameraShaker)

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(CF)
	cam.CFrame = cam.CFrame * CF
end)

-- Initialization
local Maestro = {}

local currentCharacter = "Joker"
local currentPosTween = nil
local currentSizeTween = nil
local currentAnims = {}

local ev = Instance.new("BindableEvent", script)

local Warper = playerGUI:WaitForChild("CombatEffectsHUD").Holder.Warper -- the clipping frame
Warper.ClipsDescendants = true

local InnerFrame = Instance.new("Frame")
InnerFrame.Visible = false
InnerFrame.Name = "GridContainer"
InnerFrame.BackgroundTransparency = 1
InnerFrame.Parent = Warper

CamShake:Start()

-- Constants
local imageIds = {
	"rbxassetid://106920503229207", -- Sheet/Frame 1
	"rbxassetid://99779199106272", -- Sheet/Frame 2
	"rbxassetid://74718173978425",
	"rbxassetid://103637365318177",
	"rbxassetid://88802305052251",
	"rbxassetid://77684939800559",
	"rbxassetid://83838148062228",
	"rbxassetid://91823282598041",
	"rbxassetid://112923045336657",
	-- add as many as you need here
}

local TIS = {
	["Grow"] = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	["Shrink"] = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
}

-- PRELOADED ANIMATION STORAGE
local PreloadedAnims = {
	Characters = {},
	Camera = {},
}

-- Local Variables
local charAnimator = char:WaitForChild("Humanoid"):WaitForChild("Animator")
local rigAnimator = nil

local lastFrame = 1 -- frame the animation starts at
local frames = 9 -- amount of frames in the animation
local rows = 3 -- amount of vertical frames in the animation
local columns = 3  -- amount of horizontal frames in the animation
local warperFramerate = (frames/49)*24  -- do i even need to explain this? (caps at 60)
local continuous = false -- set to true for a continuous loop, false for one-time play

local frameSize = Warper.Size --UDim2.fromScale(0.499, 0.281) -- default frame size

local currentFrame = 1
local lastTick = tick()
local hudCons = {}

-- Local Functions
local function ClearGridFunction()
	for _, child in pairs(InnerFrame:GetChildren()) do
		if child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
end

local function GenerateGridFunction()
	-- size the inner frame to fit the entire grid
	InnerFrame.Size = UDim2.new(columns, 0, rows, 0)

	for i, id in ipairs(imageIds) do
		local row = math.ceil(i / columns)
		local col = i - ((row - 1) * columns)

		local img = Instance.new("ImageLabel")
		img.Name = "Frame_" .. i
		img.Image = id
		img.BackgroundTransparency = 1
		-- scale the image to be exactly 1 slot in the grid
		img.Size = UDim2.new(1/columns, 0, 1/rows, 0)
		-- position it based on its row and column
		img.Position = UDim2.new((col - 1)/columns, 0, (row - 1)/rows, 0)
		img.Parent = InnerFrame
	end
end

local function UpdateAnimation(conVar)
	if tick() - lastTick >= 1/warperFramerate then
		currentFrame = currentFrame + 1
		if currentFrame > #imageIds and continuous then currentFrame = 1 
		elseif currentFrame > #imageIds then
			currentFrame = 1
			if conVar then
				conVar:Disconnect()
			end
			--ClearGridFunction()
			InnerFrame.Visible = false
			return
		end

		local row = math.ceil(currentFrame / columns)
		local col = currentFrame - ((row - 1) * columns)

		-- move the InnerFrame in the opposite direction to "scroll" to the frame
		-- we still use scale here because InnerFrame's size is based on the number of cols/rows
		InnerFrame.Position = UDim2.new(-(col - 1), 0, -(row - 1), 0)

		lastTick = tick()
	end
end

-- // CHANGED: Now accepts a preloaded 'track' instead of an 'animation' instance
local function playAnim(animator, track, fadeTime, smoothTransition) 
	if (not track) or (not animator) then warn("no track or animator") return end
	local old = currentAnims[animator]
	currentAnims[animator] = track
	local played = false
	
	if currentAnims[animator] then
		if old ~= track then
			if old and old.IsPlaying then 
				if not smoothTransition  then
					old:Stop()
				else
					currentAnims[animator]:Play(fadeTime or 0.1)
					played = true
					task.wait(0.35)
					old:Stop(0.1)
				end
			end
			if not played then
				currentAnims[animator]:Play(fadeTime)
			end
		end
	end
	return currentAnims[animator]
end

local function tweenModelPos(model, info, CF)
	if currentPosTween then
		if currentPosTween.PlaybackState == Enum.PlaybackState.Playing then
			currentPosTween:Cancel()
		end
	end

	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPivot()

	local con1
	con1 = CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(CFrameValue.Value)
	end)

	currentPosTween = TS:Create(CFrameValue, info, {Value = CF})
	currentPosTween:Play()

	local con2
	con2 = currentPosTween.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		CFrameValue:Destroy()
	end)
	return currentPosTween
end

local function tweenModelSize(model, info, Size)
	if currentSizeTween then
		if currentSizeTween.PlaybackState == Enum.PlaybackState.Playing then
			currentSizeTween:Cancel()
		end
	end

	local NumberValue = Instance.new("NumberValue")
	NumberValue.Value = model:GetScale()

	local con1
	con1 = NumberValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:ScaleTo(NumberValue.Value)
	end)

	currentSizeTween = TS:Create(NumberValue, info, {Value = Size})
	currentSizeTween:Play()

	local con2
	con2 = currentSizeTween.Completed:Connect(function()
		con1:Disconnect()
		con2:Disconnect()
		NumberValue:Destroy()
	end)
	return currentSizeTween
end

-- Global Functions

-- // NEW: Call this once when setting up the battle to load everything into memory
function Maestro.Init(char, camRig, allFighters)
	-- // NEW: Preload the UI Spritesheets
	local assetsToLoad = {}
	for _, id in ipairs(imageIds) do
		local tempImg = Instance.new("ImageLabel")
		tempImg.Image = id
		table.insert(assetsToLoad, tempImg)
	end

	-- This yields until the images are actually ready
	CPV:PreloadAsync(assetsToLoad)

	-- Cleanup temp objects
	for _, img in ipairs(assetsToLoad) do img:Destroy() end
	

	ClearGridFunction()
	GenerateGridFunction()
	
	rigAnimator = camRig:WaitForChild("AnimationController"):WaitForChild("Animator")

	-- Preload Character Anims
	for i, v in pairs(allFighters) do
		if not PLRS:GetPlayerFromCharacter(v.Instance) then
			PreloadedAnims.Characters[v.Instance] = {
				CharacterAnims = {}
			}

			local thum = v.Instance:FindFirstChildOfClass("Humanoid") 
			local tAnimator = (thum and thum:FindFirstChildOfClass("Animator")) or (v.Instance:FindFirstChildOfClass("AnimationController")  and v.Instance:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator"))

			if tAnimator then
				-- Stop any overworld animations (like walking/idle from quests)
				for _, track in ipairs(tAnimator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
				
				local animFolder = (v.ModelName and CombatAnims.Characters:FindFirstChild(v.ModelName)) or CombatAnims.Characters:FindFirstChild(v.Instance.Name) or CombatAnims.Characters.Joker
				
				for _, anim in pairs(animFolder:GetChildren()) do
					if anim:IsA("Animation") then
						PreloadedAnims.Characters[v.Instance].CharacterAnims[anim.Name] = tAnimator:LoadAnimation(anim)
					end
				end

				playAnim(tAnimator, PreloadedAnims.Characters[v.Instance].CharacterAnims["Fight Idle"], 0.2, false)
			end	
		else
			PreloadedAnims.Characters[v.Instance] = {}
			if v.Instance == char then
				for _, track in ipairs(charAnimator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
				PreloadedAnims.Characters[v.Instance].CharacterAnims = {}
				for _, anim in pairs(CombatAnims.Characters[currentCharacter]:GetChildren()) do
					if anim:IsA("Animation") then
						PreloadedAnims.Characters[v.Instance].CharacterAnims[anim.Name] = charAnimator:LoadAnimation(anim)
					end
				end
			end
		end
	end

	-- Preload Camera Anims
	for _, anim in pairs(Storage.Animations.Camera.Fight:GetChildren()) do
		if anim:IsA("Animation") then
			PreloadedAnims.Camera[anim.Name] = rigAnimator:LoadAnimation(anim)
		end
	end
end

function Maestro.PlayEntranceAnimations(camRig, allFighters)
	local rigAnimator = camRig:WaitForChild("AnimationController"):WaitForChild("Animator")
	local rigTrack = playAnim(rigAnimator, PreloadedAnims.Camera["Walk In Fight"])
	local stopped = false
	
	for _, fighter in pairs(allFighters) do
		local fighterChar = fighter.Instance
		local animator = (fighterChar:FindFirstChildOfClass("Humanoid") and fighterChar:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")) or fighterChar:FindFirstChildOfClass("AnimationController") and fighterChar:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
		if animator and PreloadedAnims.Characters[fighterChar] and PreloadedAnims.Characters[fighterChar].CharacterAnims["Walk In Fight"] then
			local charTrack = playAnim(animator, PreloadedAnims.Characters[fighterChar].CharacterAnims["Walk In Fight"])
			if charTrack then
				charTrack.Stopped:Once(function()
					charTrack:Play(0, 1, 0)
					charTrack.TimePosition = charTrack.Length - .000001
					if PreloadedAnims.Characters[fighterChar].CharacterAnims["Fight Idle"] then
						playAnim(animator, PreloadedAnims.Characters[fighterChar].CharacterAnims["Fight Idle"], 0.1, true)
					end
				end)
			end
		elseif animator and PreloadedAnims.Characters[fighterChar] and PreloadedAnims.Characters[fighterChar].CharacterAnims["Fight Idle"] then
			-- Fallback to idle if no walk-in animation (for golems etc.)
			playAnim(animator, PreloadedAnims.Characters[fighterChar].CharacterAnims["Fight Idle"], 0.1, true)
		end
	end
	
	if rigTrack then
		rigTrack.Stopped:Once(function()
			stopped = true
		end)
	else
		task.wait(3.15)
		stopped = true
	end
	repeat task.wait() until stopped
end

function Maestro.InitiateBattle(char, camRig, allFighters, spawnPos)
	-- 1. Load the "tuff" transition
	ScreenHandler.LoadIn("Scrub", true) 
	AnimationManager2.ToggleAllOverworldAnims:Invoke(false)
	
	-- Initialize the animations here
	Maestro.Init(char, camRig, allFighters)
	task.wait(0.2)

	-- Start following the rig camera
	CameraHandler.CurrentMode = "Cutscene"
	CameraHandler.SetToRig(camRig)

	-- 2. Setup positions while screen is obscured
	char:PivotTo(spawnPos)
	camRig:PivotTo(spawnPos)

	task.wait(0.3)


	charAnimator = char:WaitForChild("Humanoid"):WaitForChild("Animator")



	coroutine.wrap(function()
		task.wait(0.1)
		ScreenHandler.LoadOut()
		Maestro.PlayEntranceAnimations(camRig, allFighters)
	end)()
end

function Maestro.SummonPersona(chara, personaName)
	if not Storage.Personas:FindFirstChild(personaName) or not CombatAnims.Personas:FindFirstChild(personaName) then return end
	ev:Fire()
	local interuppted = false
	local con = ev.Event:Once(function()
		interuppted = true
	end)

	local personaModel = (PreloadedAnims.Characters[chara].CurrentPersona and PreloadedAnims.Characters[chara].CurrentPersona.Name == personaName) and PreloadedAnims.Characters[chara].CurrentPersona or Storage.Personas:FindFirstChild(personaName):Clone()
	local animFolder = CombatAnims.Personas:FindFirstChild(personaName)

	local chum, pum = (chara:FindFirstChildOfClass("Humanoid") or chara:FindFirstChildOfClass("AnimationController")), (personaModel:FindFirstChildOfClass("Humanoid") or personaModel:FindFirstChildOfClass("AnimationController"))
	local charAnimator = chum:FindFirstChildOfClass("Animator")
	local pAnimator = pum:FindFirstChildOfClass("Animator")

	PreloadedAnims.Characters[chara].CurrentPersona = personaModel

	-- 1. Setup Persona Initial State
	personaModel.Parent = workspace.PERSONAS
	if not PreloadedAnims.Characters[chara].Personas then
		PreloadedAnims.Characters[chara].Personas = {}
	end
	
	-- // DYNAMIC PRELOAD: Load Persona anims onto its animator the first time it spawns
	if not PreloadedAnims.Characters[chara].Personas[personaModel] then
		PreloadedAnims.Characters[chara].Personas[personaModel] = {}
		for _, anim in pairs(animFolder:GetChildren()) do
			if anim:IsA("Animation") then
				PreloadedAnims.Characters[chara].Personas[personaModel][anim.Name] = pAnimator:LoadAnimation(anim)
			end
		end
	end
	personaModel:PivotTo(chara:GetPivot() * CFrame.new(-3, 2, 2))
	personaModel:ScaleTo(0.01)

	local hl = Highlights.SpawnHighlight(PreloadedAnims.Characters[chara].CurrentPersona, {
		Enabled = false,
		FillColor = Color3.new(1, 0.333333, 1),
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 0,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	})

	hl.Enabled = true

	local TE = nil
	if hl then
		TE1 = TS:Create(hl, AnimsManager.STIS[3], {FillTransparency = 1, OutlineTransparency = 1})
		TE1:Play()
	end

	local con1
	if hl then
		con1 = TE1.Completed:Once(function()
			hl:Destroy()
		end)
	end

	-- 2. Play Synced Summoning
	local charSummon = playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Summon Persona"])
	local TE = tweenModelSize(personaModel, TIS.Grow, 1)

	charSummon.Stopped:Once(function()
		if interuppted then return end
		playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Summoned Persona Idle"], 0.2, false)
	end)

	playAnim(pAnimator, PreloadedAnims.Characters[chara].Personas[personaModel]["Idle"])

	if con then con:Disconnect() end
end

function Maestro.RetrievePersona(chara)
	if not PreloadedAnims.Characters[chara].CurrentPersona then return end
	ev:Fire()
	local interuppted = false
	local con = ev.Event:Once(function()
		interuppted = true
	end)

	local charAnimator = chara.Humanoid.Animator

	coroutine.wrap(function()
		local hl = Highlights.SpawnHighlight(PreloadedAnims.Characters[chara].CurrentPersona, {
			Enabled = false,
			FillColor = Color3.new(1, 1, 1),
			OutlineColor = Color3.new(1, 1, 1),
			FillTransparency = 0,
			OutlineTransparency = 0,
			DepthMode = Enum.HighlightDepthMode.Occluded,
		})

		hl.Enabled = true

		local TE = nil
		if hl then
			TE1 = TS:Create(hl, AnimsManager.STIS[3], {FillTransparency = 1, OutlineTransparency = 1})
			TE1:Play()
		end

		local con1
		if hl then
			con1 = TE1.Completed:Once(function()
				hl:Destroy()
			end)
		end

		local TE = tweenModelSize(PreloadedAnims.Characters[chara].CurrentPersona, TIS.Shrink, 0.01)
		TE.Completed:Wait()

		if interuppted then return end

		-- Clear persona's preloaded cache since the animator is getting destroyed
		PreloadedAnims.Characters[chara].Personas[PreloadedAnims.Characters[chara].CurrentPersona.Name] = nil 

		PreloadedAnims.Characters[chara].CurrentPersona:Destroy()
		PreloadedAnims.Characters[chara].CurrentPersona = nil
	end)()

	local charRet = playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Retrieve Persona"])

	charRet.Stopped:Wait()

	if interuppted then return end
	-- Return to base Fight Idle
	playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Fight Idle"], 0)

	if con then con:Disconnect() end
end

function Maestro.CienemateWindUp(char, atktype, fighterData, targets, isEnemy)
	if isEnemy and (atktype == "Skill" or atktype == "Attack") then --> maybe add like an effect in the lighting here
		coroutine.wrap(function()
			task.wait(0.2)
			-- Instead of generating, just ensure it's visible and reset
			InnerFrame.Visible = true 

			-- Reset position immediately so it doesn't flicker the last frame of the previous use
			InnerFrame.Position = UDim2.new(0, 0, 0, 0)


			lastFrame = 1 -- frame the animation starts at
			frames = 9 -- amount of frames in the animation
			rows = 3 -- amount of vertical frames in the animation
			columns = 3  -- amount of horizontal frames in the animation
			warperFramerate = 24  -- do i even need to explain this? (caps at 60)


			currentFrame = 1
			lastTick = tick()

			-- Loose Threads
			Warper.Position = UDim2.fromScale(0.625, 0.475)
			Warper.Size = UDim2.fromScale(1.25, 1)

			if hudCons["enematk"] then hudCons["enematk"]:Disconnect() end

			hudCons["enematk"] = RS.RenderStepped:Connect(function()
				UpdateAnimation(hudCons["enematk"])
			end)
			CamShake:Shake(CameraShaker.Presets.SlightShudder)
			task.wait((frames/warperFramerate) + 1)
			InnerFrame.Visible = false -- Hide it when done instead of destroying
			if hudCons["enematk"] then hudCons["enematk"]:Disconnect() end
		end)()
	end
	if atktype == "Skill" then
		if fighterData.ActivePersona and --[[PreloadedAnims.Characters[fighterData.Instance].CurrentPersona and]] ((fighterData.Instance == char) or (not PLRS:GetPlayerFromCharacter(fighterData.Instance))) then
			task.wait(0.6)
			if fighterData.Instance == char then
				ev:Fire()
			end
			--local interuppted = false
			--local con = ev.Event:Once(function()
			--	interuppted = true
			--end)

			local chum = fighterData.Instance:FindFirstChildOfClass("Humanoid") or fighterData.Instance:FindFirstChildOfClass("AnimationController") 
			local charAnimator = chum:FindFirstChildOfClass("Animator")
			local charAttack = playAnim(charAnimator, PreloadedAnims.Characters[fighterData.Instance].CharacterAnims["Use Persona"])
			
			local currentPersona = PreloadedAnims.Characters[fighterData.Instance].CurrentPersona
			if currentPersona then
				local pum = currentPersona:FindFirstChildOfClass("Humanoid") or currentPersona:FindFirstChildOfClass("AnimationController")
				local pAnimator = pum:FindFirstChildOfClass("Animator")
				local pAnims = PreloadedAnims.Characters[fighterData.Instance].Personas[currentPersona]
				if pAnims and pAnims["Attack1"] then
					playAnim(pAnimator, pAnims["Attack1"], 0.1)
				end
			end
			
			charAttack.Stopped:Once(function()
				playAnim(charAnimator, PreloadedAnims.Characters[fighterData.Instance].CharacterAnims["Fight Idle"], 0.2, false)
				if currentPersona then
					local pum = currentPersona:FindFirstChildOfClass("Humanoid") or currentPersona:FindFirstChildOfClass("AnimationController")
					local pAnimator = pum:FindFirstChildOfClass("Animator")
					local pAnims = PreloadedAnims.Characters[fighterData.Instance].Personas[currentPersona]
					if pAnims and pAnims["Idle"] then
						playAnim(pAnimator, pAnims["Idle"], 0.2)
					end
				end
			end)
		end
	end
end

function Maestro.CienemateMove(char, atktype, skillName, fighterData, targets)
	if atktype == "Skill" then
		for i, target in pairs(targets) do
			if SkillLibrary.List[skillName].VFXMod then
				coroutine.wrap(function()
					SkillLibrary.List[skillName].VFXMod(target.Instance:GetPivot())
				end)()
			end
		end
	end
end

function Maestro.Cleanup()

end

return Maestro