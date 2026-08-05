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
local CombatReplicator = Storage.Events.Remotes.ReplicateCombat
local CombatAnims = Storage.Animations.Combat
local CameraHandler = require(script.Parent.CameraHandler)
local ScreenHandler = require(script.Parent.ScreenChangeHandler)
local AnimsManager = require(script.Parent.GUIMaster.Animations)
local Highlights = require(script.Parent.GUIMaster.Animations.Highlights)
local AnimationManager2 = char:WaitForChild("States"):WaitForChild("AnimationManager2")


local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)
local CameraShaker = require(Storage.Classes.BaseClasses.CameraShaker)
local FightHudIndicators = require(script.Parent:WaitForChild("FightHudIndicators"))

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(CF)
	cam.CFrame = cam.CFrame * CF
end)

-- Initialization
local Maestro = {}
Maestro.BattleReady = false -- flips true once InitiateBattle has fighters cloned/positioned; other
-- actions' generic fighter-resolution code (in ClientUIMain) waits on this so it can't race ahead

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
	["Shrink"] = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
	["Fade"] = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

-- ===== Summon/Retrieve Mesh FX (Bases + Crests) =====
-- Grow a Base (e.g. a spinning diamond) and a Crest (e.g. a spinning wing, unique per persona) up to
-- full size to "materialize" a persona instead of tweening the persona rig's own Size every frame --
-- that per-frame Model:ScaleTo() was the actual cause of the freeze/lag when personas spawned in.
local SummonMeshes = Storage.Effects.Combat.SummonMeshes
local SummonBases = SummonMeshes.Bases
local SummonCrests = SummonMeshes.Crests

-- TODO: once persona info carries its own base/crest/offset values, read from there instead of these
-- maps. Personas not listed just fall back to the Diamond base / a plain circle crest / no offset.
local PersonaCrestMap = {
	["Angel"] = "Wing",
}
local PersonaBaseMap = {}
-- Raises (or otherwise offsets) the whole mesh FX assembly per persona -- some persona models (e.g.
-- flying-type ones) have their pivot sitting low relative to where they actually visually read as
-- "centered", which was spawning the base low into their legs.
local PersonaSpawnVFXOffset = {
	["Angel"] = Vector3.new(0, 4, 0),
}

local function getBaseTemplate(personaName)
	local mapped = PersonaBaseMap[personaName]
	return (mapped and SummonBases:FindFirstChild(mapped)) or SummonBases:FindFirstChild("Diamond")
end

local function getCrestTemplate(personaName)
	local mapped = PersonaCrestMap[personaName]
	return mapped and SummonCrests:FindFirstChild(mapped)
end

local function getSpawnVFXOffset(personaName)
	return PersonaSpawnVFXOffset[personaName] or Vector3.new(0, 0, 0)
end

-- Summon VFX modules -- same pattern as SkillLibrary.PreloadedVFXFunctions for attack VFX: every
-- ModuleScript under SummonVFX gets preloaded and keyed by name, then a persona map (again a stand-in
-- for real persona info later) picks which one to run, always falling back to "Default" if a persona
-- doesn't specify one.
local SummonVFXFolder = Storage.Effects.Combat.SummonVFX
local PreloadedSummonVFX = {}
for _, mod in pairs(SummonVFXFolder:GetChildren()) do
	if mod:IsA("ModuleScript") then
		PreloadedSummonVFX[mod.Name] = require(mod)
	end
end

-- TODO: once persona info carries its own summon VFX name, read from there instead of this map.
local PersonaSummonVFXMap = {
	["Angel"] = "VFXTwo", -- example: Angel uses a specific summon VFX instead of the default
}

local function getSummonVFXFunction(personaName)
	local mapped = PersonaSummonVFXMap[personaName]
	return (mapped and PreloadedSummonVFX[mapped]) or PreloadedSummonVFX["Default"]
end

local function makeFallbackCrest()
	-- No dedicated crest for this persona yet -- a plain flat disc reads as "circle part" without
	-- needing a custom mesh asset. Cylinders are authored lengthwise along X, so the caller rotates
	-- this 90 degrees to lay it flat.
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 1, 1)
	part.Size = Vector3.new(0.2, 2, 2)
	return part
end

-- Spins a part in place around its own Y axis forever, until it's destroyed/unparented. speed can be
-- a plain number (constant degrees/sec) or a function(elapsedSeconds) -> degrees/sec for a dynamic
-- rate (negative values spin the opposite direction).
local function spinIndefinitely(part, speed, pivotCFrame)
	local angle = 0
	local elapsed = 0
	local conn
	conn = RS.Heartbeat:Connect(function(dt)
		if not part or not part.Parent then
			if conn then conn:Disconnect() end
			return
		end
		elapsed += dt
		local degPerSec = type(speed) == "function" and speed(elapsed) or speed
		angle += math.rad(degPerSec * dt)
		part.CFrame = pivotCFrame * CFrame.Angles(0, angle, 0)
	end)
	return conn
end

-- Base spin rate curve: starts nearly still, then ramps up on a true exponential curve (barely
-- moving at first, then a fast blow-up right near the end) up to max speed, then just holds there --
-- no slow-down, it stays at max speed straight through the disappear. The crest spins at a fast
-- constant rate in the opposite direction (negative).
local BASE_SPIN_START = 12 -- super slow starting speed
local BASE_SPIN_MAX = 1000 -- super fast max speed
local BASE_SPIN_RAMP_DURATION = 0.9 -- time to reach max; holds at max forever after this
local BASE_SPIN_EXP_STEEPNESS = 7 -- higher = stays slower for longer before the blow-up
local function baseSpinCurve(elapsed)
	if elapsed >= BASE_SPIN_RAMP_DURATION then
		return BASE_SPIN_MAX
	end
	local t = elapsed / BASE_SPIN_RAMP_DURATION
	-- normalized exponential: 0 at t=0, 1 at t=1, curving up increasingly steeply
	local expT = (math.exp(BASE_SPIN_EXP_STEEPNESS * t) - 1) / (math.exp(BASE_SPIN_EXP_STEEPNESS) - 1)
	return BASE_SPIN_START + (BASE_SPIN_MAX - BASE_SPIN_START) * expT
end
local CREST_SPIN_RATE = -240

-- Spawns the base+crest pair at spawnCFrame, sized relative to targetSize (usually the persona's own
-- full-scale extents), already spinning. startFull decides whether they start at full size (for
-- retrieve, which fades in) or tiny (for summon, which grows in). Returns a handle table used by the
-- grow/fade/shrink helpers below.
local function spawnSummonMeshFX(personaName, spawnCFrame, targetSize, startFull)
	spawnCFrame = spawnCFrame + getSpawnVFXOffset(personaName)

	local baseTemplate = getBaseTemplate(personaName)
	local crestTemplate = getCrestTemplate(personaName)
	local isFallbackCrest = not crestTemplate

	local handle = {}

	if baseTemplate then
		local base = baseTemplate:Clone()
		local diameter = math.max(targetSize.X, targetSize.Z) * 1.15
		local scaleFactor = diameter / math.max(baseTemplate.Size.X, baseTemplate.Size.Z)
		local finalSize = baseTemplate.Size * scaleFactor

		base.Anchored = true
		base.CanCollide = false
		base.CanQuery = false
		base.CanTouch = false
		base.Transparency = 0
		base.Size = startFull and finalSize or (finalSize * 0.01)
		base.Parent = workspace.PERSONAS

		handle.Base = base
		handle.BaseFinalSize = finalSize
		handle.BaseSpin = spinIndefinitely(base, baseSpinCurve, spawnCFrame)
	end

	local crest = crestTemplate and crestTemplate:Clone() or makeFallbackCrest()
	if crest then
		local diameter = math.max(targetSize.X, targetSize.Z) * 0.65
		local scaleFactor = diameter / math.max(crest.Size.X, crest.Size.Z)
		local finalSize = crest.Size * scaleFactor
		local crestCFrame = spawnCFrame * CFrame.new(0, targetSize.Y * 0.55, 0)
		if isFallbackCrest then
			crestCFrame = crestCFrame * CFrame.Angles(0, 0, math.rad(90))
		end

		crest.Anchored = true
		crest.CanCollide = false
		crest.CanQuery = false
		crest.CanTouch = false
		crest.Transparency = 0
		crest.Size = startFull and finalSize or (finalSize * 0.01)
		crest.Parent = workspace.PERSONAS

		handle.Crest = crest
		handle.CrestFinalSize = finalSize
		-- fast constant rate, opposite direction from the base's curve
		handle.CrestSpin = spinIndefinitely(crest, CREST_SPIN_RATE, crestCFrame)
	end

	return handle
end

-- Grows the base+crest from tiny up to full size (blocking -- waits for it to finish)
local function growSummonMeshFX(handle, tweenInfo)
	local tweens = {}
	if handle.Base then table.insert(tweens, TS:Create(handle.Base, tweenInfo, {Size = handle.BaseFinalSize})) end
	if handle.Crest then table.insert(tweens, TS:Create(handle.Crest, tweenInfo, {Size = handle.CrestFinalSize})) end
	for _, t in ipairs(tweens) do t:Play() end
	if tweens[1] then tweens[1].Completed:Wait() end
end

-- Fades the base+crest transparency in from invisible to visible (blocking)
local function fadeInSummonMeshFX(handle, tweenInfo)
	local tweens = {}
	if handle.Base then
		handle.Base.Transparency = 1
		table.insert(tweens, TS:Create(handle.Base, tweenInfo, {Transparency = 0}))
	end
	if handle.Crest then
		handle.Crest.Transparency = 1
		table.insert(tweens, TS:Create(handle.Crest, tweenInfo, {Transparency = 0}))
	end
	for _, t in ipairs(tweens) do t:Play() end
	if tweens[1] then tweens[1].Completed:Wait() end
end

-- The crest's disappearing beat: a fast, snappy shrink down to almost nothing, then an explosive burst
-- out past its normal size while fading to invisible. Used identically every time the crest
-- disappears -- whether summon just finished or retrieve just finished -- unlike the base, this never
-- reverses direction.
local function burstDisappearCrestFX(crest, crestFinalSize, spinConn)
	if not crest then return end
	-- Fast, hard snap down to almost nothing, then a burst back out to its normal explosion size --
	-- but the transparency fade runs slower/separately so it lingers a beat after the size settles
	local snapDownInfo = TweenInfo.new(0.09, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
	local burstSizeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local burstFadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local snapTween = TS:Create(crest, snapDownInfo, {Size = crestFinalSize * 0.02})
	snapTween:Play()
	snapTween.Completed:Wait()

	local burstSizeTween = TS:Create(crest, burstSizeInfo, {Size = crestFinalSize * 1.8})
	local burstFadeTween = TS:Create(crest, burstFadeInfo, {Transparency = 1})
	burstSizeTween:Play()
	burstFadeTween:Play()
	burstFadeTween.Completed:Wait()

	if spinConn then spinConn:Disconnect() end
	crest:Destroy()
end

-- Fades the base's transparency out at its current size (used once the persona's already revealed),
-- and runs the crest's burst-disappear at the same time, then cleans both up
local function fadeOutSummonMeshFX(handle, tweenInfo)
	local baseDone = not handle.Base
	if handle.Base then
		local baseTween = TS:Create(handle.Base, tweenInfo, {Transparency = 1})
		baseTween:Play()
		coroutine.wrap(function()
			baseTween.Completed:Wait()
			if handle.BaseSpin then handle.BaseSpin:Disconnect() end
			handle.Base:Destroy()
			baseDone = true
		end)()
	end

	local crestDone = not handle.Crest
	if handle.Crest then
		coroutine.wrap(function()
			burstDisappearCrestFX(handle.Crest, handle.CrestFinalSize, handle.CrestSpin)
			crestDone = true
		end)()
	end

	repeat task.wait() until baseDone and crestDone
end

-- Shrinks the base back down to tiny (the reverse of its grow-in), and runs the crest's
-- burst-disappear at the same time (not reversed -- the crest's disappear is always the same), then
-- cleans both up
local function shrinkOutSummonMeshFX(handle, tweenInfo)
	local baseDone = not handle.Base
	if handle.Base then
		local baseTween = TS:Create(handle.Base, tweenInfo, {Size = handle.BaseFinalSize * 0.01})
		baseTween:Play()
		coroutine.wrap(function()
			baseTween.Completed:Wait()
			if handle.BaseSpin then handle.BaseSpin:Disconnect() end
			handle.Base:Destroy()
			baseDone = true
		end)()
	end

	local crestDone = not handle.Crest
	if handle.Crest then
		coroutine.wrap(function()
			burstDisappearCrestFX(handle.Crest, handle.CrestFinalSize, handle.CrestSpin)
			crestDone = true
		end)()
	end

	repeat task.wait() until baseDone and crestDone
end

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
				
				local animFolder
				if v.IsWildPersona then
					-- Wild Personas are their own trainer -- they never had a "Character" to begin with,
					-- so their anims live under CombatAnims.Personas, not .Characters. Looking in
					-- .Characters (the old behavior) is exactly why Golem's anims never loaded.
					animFolder = (v.ModelName and CombatAnims.Personas:FindFirstChild(v.ModelName)) or CombatAnims.Personas:FindFirstChild(v.Instance.Name)
					if not animFolder then
						warn("[Maestro] no CombatAnims.Personas folder found for wild persona '" .. tostring(v.ModelName or v.Instance.Name) .. "'")
					end
				else
					animFolder = (v.ModelName and CombatAnims.Characters:FindFirstChild(v.ModelName)) or CombatAnims.Characters:FindFirstChild(v.Instance.Name)
					if not animFolder then
						-- only fall back to Joker's animations if this fighter actually has a compatible
						-- humanoid rig -- forcing Joker's anims onto a differently-shaped custom rig (like Golem)
						-- just fails/glitches since the keyframe bone names won't match
						if v.Instance:FindFirstChildOfClass("Humanoid") then
							animFolder = CombatAnims.Characters.Joker
						else
							warn("[Maestro] no combat animation folder found for '" .. tostring(v.ModelName or v.Instance.Name) .. "' and it isn't a humanoid rig -- add a CombatAnims.Characters folder for it instead of relying on fallback")
						end
					end
				end

				if animFolder then
					for _, anim in pairs(animFolder:GetChildren()) do
						if anim:IsA("Animation") then
							PreloadedAnims.Characters[v.Instance].CharacterAnims[anim.Name] = tAnimator:LoadAnimation(anim)
						end
					end
				end

				-- Wild Personas name their idle anim "Idle" (persona-naming convention); Characters use "Fight Idle"
				local idleKey = v.IsWildPersona and "Idle" or "Fight Idle"
				playAnim(tAnimator, PreloadedAnims.Characters[v.Instance].CharacterAnims[idleKey], 0.2, false)
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
				
				playAnim(charAnimator, PreloadedAnims.Characters[v.Instance].CharacterAnims["Fight Idle"], 0.2, false)

				-- Pre-stage the player's bonded persona hidden inside them while the screen's still
				-- covered, same trick as the enemy/NPC fighters above -- so the FIRST time they open
				-- the persona menu (SummonPersona) there's no Clone()/LoadAnimation cost left to pay,
				-- just a pivot + scale-up.
				local personaName = (v.ActivePersona and v.ActivePersona.Name) or "Angel"
				if Storage.Personas:FindFirstChild(personaName) and CombatAnims.Personas:FindFirstChild(personaName) then
					local personaModel = Storage.Personas:FindFirstChild(personaName):Clone()
					local pum = personaModel:FindFirstChildOfClass("Humanoid") or personaModel:FindFirstChildOfClass("AnimationController")
					local pAnimator = pum and pum:FindFirstChildOfClass("Animator")

					if pAnimator then
						personaModel.Parent = workspace.PERSONAS
						personaModel:PivotTo(v.Instance:GetPivot())
						personaModel:ScaleTo(0.01)

						PreloadedAnims.Characters[v.Instance].Personas = PreloadedAnims.Characters[v.Instance].Personas or {}
						PreloadedAnims.Characters[v.Instance].Personas[personaModel] = {}
						for _, anim in pairs(CombatAnims.Personas[personaName]:GetChildren()) do
							if anim:IsA("Animation") then
								PreloadedAnims.Characters[v.Instance].Personas[personaModel][anim.Name] = pAnimator:LoadAnimation(anim)
							end
						end

						PreloadedAnims.Characters[v.Instance].StashedPersonas = PreloadedAnims.Characters[v.Instance].StashedPersonas or {}
						PreloadedAnims.Characters[v.Instance].StashedPersonas[personaName] = personaModel
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
	FightHudIndicators.BattleMessage.Show("BATTLE START!")
	
	local rigAnimator = camRig:WaitForChild("AnimationController"):WaitForChild("Animator")
	local rigTrack = playAnim(rigAnimator, PreloadedAnims.Camera["Walk In Fight"])
	local stopped = false

	-- NPC allies (Timmy etc.) and enemy persona users summon their persona ONCE here, right after
	-- their walk-in, and then leave it out for the rest of the fight -- no per-attack summon/retrieve
	-- cinematic like the player gets. Wild Personas (Golem etc.) and the player are excluded: wild
	-- personas ARE the persona (nothing to summon), and the player controls their own summon/retrieve.
	local function isAutoSummonFighter(fighter)
		return fighter.ActivePersona and not fighter.IsWildPersona and fighter.Instance ~= char and not PLRS:GetPlayerFromCharacter(fighter.Instance)
	end

	-- Tracks in-flight auto-summons (Timmy etc.) so this function can't return -- and let anything
	-- downstream (like CombatStoryline's OnBattleStart dialogue, which plays its own animation
	-- directly via hum:LoadAnimation) touch these fighters -- until they've actually finished
	-- materializing. Before this, PlayEntranceAnimations only waited on the CAMERA's walk-in, so
	-- dialogue could fire and stomp an NPC's animator mid-summon, which is why Timmy's animation
	-- looked like it "didn't play" -- it was playing, then got immediately overridden.
	local pendingAutoSummons = 0

	for _, fighter in pairs(allFighters) do
		local fighterChar = fighter.Instance
		local animator = (fighterChar:FindFirstChildOfClass("Humanoid") and fighterChar:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")) or fighterChar:FindFirstChildOfClass("AnimationController") and fighterChar:FindFirstChildOfClass("AnimationController"):FindFirstChildOfClass("Animator")
		local anims = PreloadedAnims.Characters[fighterChar] and PreloadedAnims.Characters[fighterChar].CharacterAnims

		if animator and anims and anims["Walk In Fight"] then
			local charTrack = anims["Walk In Fight"]
			charTrack:Play(0.1)
			if charTrack then
				local isAutoSummon = isAutoSummonFighter(fighter)
				if isAutoSummon then
					pendingAutoSummons += 1
				end
				charTrack.Stopped:Once(function()
					if isAutoSummon then
						Maestro.SummonPersona(fighterChar, fighter.ActivePersona.Name)
						pendingAutoSummons -= 1
					end
				end)
			end
		elseif animator and anims and fighter.IsWildPersona and anims["Summoned"] then
			-- Wild Personas have no dedicated walk-in clip -- reuse their "Summoned" animation (the
			-- same clip used later if this persona gets bonded to a user) as an entrance fallback
			local summonTrack = playAnim(animator, anims["Summoned"])
			if summonTrack then
				summonTrack.Stopped:Once(function()
					if anims["Idle"] then
						playAnim(animator, anims["Idle"], 0.15, true)
					end
				end)
			end
		elseif animator and anims and (anims["Fight Idle"] or anims["Idle"]) then
			-- Straight to idle if nothing else is available
			playAnim(animator, anims["Fight Idle"] or anims["Idle"], 0.1, true)
		end
	end
	
	if rigTrack then
		rigTrack.Stopped:Once(function()
			local idleAnim = PreloadedAnims.Camera["Fight Idle"] or PreloadedAnims.Camera["Idle"]
			if idleAnim then
				playAnim(rigAnimator, idleAnim, 0.15, true)
			else
				CameraHandler.Circle()
			end
			stopped = true
		end)
	else
		task.wait(3.15)
		local idleAnim = PreloadedAnims.Camera["Fight Idle"] or PreloadedAnims.Camera["Idle"]
		if idleAnim then
			playAnim(rigAnimator, idleAnim, 0.15, true)
		else
			CameraHandler.Circle()
		end
		stopped = true
	end
	repeat task.wait() until stopped and pendingAutoSummons <= 0
end

function Maestro.InitiateBattle(char, camRig, fightTable, spawnPos, LocalFightersMap, LocalClonedFighters)
	Maestro.BattleReady = false

	-- 0. Pokemon-style intro punch, THEN cover the screen with the scrub transition, THEN give it a
	-- couple seconds to fully settle -- everything from here down (cloning fighters in, loading their
	-- animations) happens behind the covered screen, same as how the cutscenes hide their setup.
	coroutine.wrap(function()
		CameraHandler.BattleIntroPunch()
	end)()
	ScreenHandler.LoadIn("Scrub", true)
	task.wait(0.5)

	-- 1. Clone every fighter in behind the covered screen (moved here from ClientUIMain so this whole
	-- sequence -- punch, cover, clone, load anims, reveal -- is owned in one place with one clear order)
	for _, f in ipairs(fightTable.AllFighters) do
		if not f.Instance then
			if not LocalFightersMap[f.ID] then
				local existing = workspace.NPCS:FindFirstChild(f.ModelName)
				if existing then
					LocalFightersMap[f.ID] = existing
				else
					local template = Storage.Personas:FindFirstChild(f.ModelName) or Storage.NPCs:FindFirstChild(f.ModelName)
					local newInst = template and template:Clone() or Instance.new("Model")
					newInst.Name = "Enemy_" .. (f.ModelName or "Unknown")
					newInst.Parent = workspace.PERSONAS
					LocalFightersMap[f.ID] = newInst
					table.insert(LocalClonedFighters, newInst)
				end

				if f.SpawnCFrame then
					LocalFightersMap[f.ID]:PivotTo(f.SpawnCFrame)
				end
			end
			f.Instance = LocalFightersMap[f.ID]
		end
	end
	if fightTable.PlayerFighters then
		for _, f in ipairs(fightTable.PlayerFighters) do
			if not f.Instance then f.Instance = LocalFightersMap[f.ID] end
		end
	end
	if fightTable.EnemyFighters then
		for _, f in ipairs(fightTable.EnemyFighters) do
			if not f.Instance then f.Instance = LocalFightersMap[f.ID] end
		end
	end

	local allFighters = fightTable.AllFighters

	-- FightHudIndicators wiring -- right after fighters are cloned in/positioned, since HealthTray
	-- needs real fighter.Instance refs and CombatStoryline needs a Speaker-name -> Instance map to
	-- resolve against for NPCM.runNPC
	local fightersByName = {}
	for _, f in ipairs(allFighters) do
		if f.ModelName then
			fightersByName[f.ModelName] = f.Instance
		end
	end
	fightersByName["Player"] = char

	FightHudIndicators.HealthTray.Init(fightTable)
	FightHudIndicators.CombatStoryline.Init(fightTable.StorylineConfig, fightersByName)

	AnimationManager2.ToggleAllOverworldAnims:Invoke(false)

	-- 2. Make sure animations are loaded
	Maestro.Init(char, camRig, allFighters)

	-- Camera centering needs real fighter positions, which only exist now that they're cloned in
	CameraHandler.Initialize(allFighters)

	-- Start following the rig camera
	CameraHandler.CurrentMode = "Cutscene"
	CameraHandler.SetToRig(camRig)

	-- 3. Setup positions while screen is still obscured
	char:PivotTo(spawnPos)
	camRig:PivotTo(spawnPos)

	charAnimator = char:WaitForChild("Humanoid"):WaitForChild("Animator")

	-- Fighters are cloned in and positioned as of here -- safe for other actions' generic
	-- fighter-resolution block (in ClientUIMain) to stop waiting and proceed. That block was racing
	-- ahead of this function before (since it runs in its own coroutine per RemoteEvent firing), which
	-- is what left fighters like Timmy claimed-but-not-positioned in LocalFightersMap.
	Maestro.BattleReady = true

	task.wait(0.5)
	ScreenHandler.LoadOut()

	coroutine.wrap(function()
		Maestro.PlayEntranceAnimations(camRig, allFighters)
		-- Tutorial-fight banter (if this battle was given a StorylineConfig) plays after the walk-in
		-- is fully done, and WaitForClear() holds the "entranceComplete" ack (and therefore the first
		-- turn) until the player's actually clicked all the way through it
		FightHudIndicators.CombatStoryline.OnBattleStart()
		--print("3")
		--FightHudIndicators.CombatStoryline.WaitForClear()
		-- Tell the server the entrance sequence (cloning, animation loading, camera walk-in) is
		-- actually done, instead of it guessing a fixed wait time -- that guess was too short
		-- whenever this fight had more/heavier stuff to load, so turnStartUpdate would fire and
		-- CameraHandler.FocusOn would cut the walk-in camera off mid-play.
		CombatReplicator:FireServer("entranceComplete")
	end)()
end

function Maestro.SummonPersona(chara, personaName)
	if not Storage.Personas:FindFirstChild(personaName) or not CombatAnims.Personas:FindFirstChild(personaName) then return end

	-- Already summoned and visible (player reopened the persona menu without ever retrieving it) --
	-- there's nothing to animate, just make sure it's still near the character in case they moved,
	-- and skip the shrink/regrow + summon animation replay entirely.
	if PreloadedAnims.Characters[chara].CurrentPersona and PreloadedAnims.Characters[chara].CurrentPersona.Name == personaName and PreloadedAnims.Characters[chara].CurrentPersona.Parent == workspace.PERSONAS then
		PreloadedAnims.Characters[chara].CurrentPersona:PivotTo(chara:GetPivot() * CFrame.new(-3, 2, 2))
		return
	end

	ev:Fire()
	local interuppted = false
	local con = ev.Event:Once(function()
		interuppted = true
	end)

	-- Reuse a stashed (previously retrieved, kept alive) model if we have one -- avoids re-cloning a
	-- full rig and re-loading all its animations from scratch every time the persona menu is reopened,
	-- which was a big chunk of the reopen-menu lag on top of the ScaleTo cost.
	local personaModel = PreloadedAnims.Characters[chara].StashedPersonas and PreloadedAnims.Characters[chara].StashedPersonas[personaName]
	if personaModel then
		PreloadedAnims.Characters[chara].StashedPersonas[personaName] = nil
	else
		personaModel = Storage.Personas:FindFirstChild(personaName):Clone()
	end
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
	local spawnCFrame = chara:GetPivot() * CFrame.new(-3, 2, 2)
	personaModel:PivotTo(spawnCFrame)

	-- Measure the persona's real, full-scale size (regardless of whatever scale it happened to be at
	-- from a previous stash) so the mesh FX can be sized to match, then keep the rig itself hidden and
	-- tiny -- the base+crest mesh FX does the "materializing" visual instead of tweening the rig
	personaModel:ScaleTo(1)
	local targetSize = personaModel:GetExtentsSize()
	personaModel:ScaleTo(0.01)

	local meshFX = spawnSummonMeshFX(personaName, spawnCFrame, targetSize, false)

	coroutine.wrap(function()
		-- Run this persona's summon VFX module (or the fallback) alongside the mesh FX. Wrapped in pcall
		-- since these are effect modules that could error without needing to break the whole summon.
		local summonVFXFn = getSummonVFXFunction(personaName)
		if summonVFXFn then
			local vfxOk, vfxErr = pcall(summonVFXFn, spawnCFrame, personaModel, targetSize, TIS.Grow.Time)
			if not vfxOk then
				warn("[Maestro] summon VFX error for '" .. personaName .. "': " .. tostring(vfxErr))
			end
		end
	end)()
	local hl = Highlights.SpawnHighlight(PreloadedAnims.Characters[chara].CurrentPersona, {
		Enabled = false,
		FillColor = Color3.new(1, 0.333333, 1),
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 0,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	})

	hl.Enabled = true

	local TE1 = nil
	if hl then
		TE1 = TS:Create(hl, AnimsManager.STIS[3], {FillTransparency = 1, OutlineTransparency = 1})
		TE1:Play()
	end

	if hl then
		TE1.Completed:Once(function()
			hl:Destroy()
		end)
	end

	-- 2. Play Synced Summoning
	local charSummon = playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Summon Persona"])

	charSummon.Stopped:Once(function()
		if interuppted then return end
		local idleAnim = PreloadedAnims.Characters[chara].CharacterAnims["Summoned Persona Idle"] or PreloadedAnims.Characters[chara].CharacterAnims["Fight Idle"]
		playAnim(charAnimator, idleAnim, 0.2, false)
	end)

	playAnim(pAnimator, PreloadedAnims.Characters[chara].Personas[personaModel]["Idle"])

	coroutine.wrap(function()
		-- Grow the mesh FX to full size, then reveal the real persona at full scale (a single instant
		-- ScaleTo, not tweened), then fade the mesh FX away to unveil it
		growSummonMeshFX(meshFX, TIS.Grow)

		if interuppted then
			fadeOutSummonMeshFX(meshFX, TIS.Fade)
			if con then con:Disconnect() end
			return
		end

		personaModel:ScaleTo(1)
		fadeOutSummonMeshFX(meshFX, TIS.Fade)

		if con then con:Disconnect() end
	end)()
end

function Maestro.RetrievePersona(chara)
	if not PreloadedAnims.Characters[chara].CurrentPersona then return end
	ev:Fire()
	local interuppted = false
	local con = ev.Event:Once(function()
		interuppted = true
	end)

	local charAnimator = chara.Humanoid.Animator

	local retrievingPersona = PreloadedAnims.Characters[chara].CurrentPersona

	coroutine.wrap(function()
		local hl = Highlights.SpawnHighlight(retrievingPersona, {
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
			TE = TS:Create(hl, AnimsManager.STIS[3], {FillTransparency = 1, OutlineTransparency = 1})
			TE:Play()
		end

		local con1
		if hl then
			con1 = TE.Completed:Once(function()
				hl:Destroy()
			end)
		end

		-- Mirror of the summon FX: fade the mesh pair IN (at full size) to cover the persona, hide
		-- the persona instantly while it's covered (a single instant ScaleTo, not a tweened one), then
		-- shrink the mesh pair back down and clean it up -- the persona rig itself never needs an
		-- animated scale-down at all.
		local retrieveCFrame = retrievingPersona:GetPivot()
		local targetSize = retrievingPersona:GetExtentsSize()
		local meshFX = spawnSummonMeshFX(retrievingPersona.Name, retrieveCFrame, targetSize, true)

		fadeInSummonMeshFX(meshFX, TIS.Fade)

		if interuppted then
			shrinkOutSummonMeshFX(meshFX, TIS.Shrink)
			return
		end

		retrievingPersona:ScaleTo(0.01)

		shrinkOutSummonMeshFX(meshFX, TIS.Shrink)

		if interuppted then return end

		-- Stash instead of destroying -- keeps the model and its already-loaded animations alive so
		-- the next SummonPersona for this same persona just pivots it back out instead of re-cloning
		-- a full rig and re-loading every animation from scratch (that repeated clone/load cycle was
		-- the biggest chunk of the lag whenever the persona menu got toggled mid-fight).
		if not PreloadedAnims.Characters[chara].StashedPersonas then
			PreloadedAnims.Characters[chara].StashedPersonas = {}
		end
		PreloadedAnims.Characters[chara].StashedPersonas[retrievingPersona.Name] = retrievingPersona

		-- Tuck it inside the persona user rather than below the floor -- "below ground" isn't a safe
		-- hiding spot for flying scenes, but "wherever the character currently is" always is
		retrievingPersona:PivotTo(chara:GetPivot())

		PreloadedAnims.Characters[chara].CurrentPersona = nil
	end)()

	local charRet = playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Retrieve Persona"])

	charRet.Stopped:Wait()

	if interuppted then return end
	-- Return to base Fight Idle
	playAnim(charAnimator, PreloadedAnims.Characters[chara].CharacterAnims["Fight Idle"], 0)

	if con then con:Disconnect() end
end

function Maestro.CienemateWindUp(char, atktype, fighterData, targets, isEnemy, speedMult)
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
		if fighterData.IsWildPersona then
			-- Wild Personas attack as themselves -- there's no separate "user" to wind up and no
			-- summoned persona instance to sync with (that whole flow requires SummonPersona to have
			-- been called first, which never happens for these). Just play its own Attack1 directly.
			task.wait(0.6 / (speedMult or 1))
			local thum = fighterData.Instance:FindFirstChildOfClass("Humanoid") or fighterData.Instance:FindFirstChildOfClass("AnimationController")
			local tAnimator = thum and thum:FindFirstChildOfClass("Animator")
			if tAnimator and PreloadedAnims.Characters[fighterData.Instance] then
				local atk = playAnim(tAnimator, PreloadedAnims.Characters[fighterData.Instance].CharacterAnims["Attack1"])
				if atk then
					atk.Stopped:Once(function()
						playAnim(tAnimator, PreloadedAnims.Characters[fighterData.Instance].CharacterAnims["Idle"], 0.2, false)
					end)
				end
			end
		elseif fighterData.ActivePersona and --[[PreloadedAnims.Characters[fighterData.Instance].CurrentPersona and]] ((fighterData.Instance == char) or (not PLRS:GetPlayerFromCharacter(fighterData.Instance))) then
			-- this used to be a flat task.wait(0.6) that never scaled with combat speed, unlike the
			-- caller's windup wait -- at 2x combat speed the caller would already be moving on to the
			-- next step before this had even started playing "Use Persona"/"Attack1", which is why
			-- the attack animation could look like it doesn't play or gets cut off
			task.wait(0.6 / (speedMult or 1))
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
			-- track the persona's OWN attack track separately so its idle-transition is driven by
			-- ITS OWN Stopped event, not the character's "Use Persona" gesture finishing. Attack1 is
			-- usually longer than the caster's gesture, so tying them together was cutting Attack1
			-- off mid-play every time -- that's the "interrupted mid animation" bug.
			local personaAttackTrack = nil
			if currentPersona then
				local pum = currentPersona:FindFirstChildOfClass("Humanoid") or currentPersona:FindFirstChildOfClass("AnimationController")
				local pAnimator = pum:FindFirstChildOfClass("Animator")
				local pAnims = PreloadedAnims.Characters[fighterData.Instance].Personas[currentPersona]
				if pAnims and pAnims["Attack1"] then
					personaAttackTrack = playAnim(pAnimator, pAnims["Attack1"], 0.1)
				end
			end
			
			charAttack.Stopped:Once(function()
				playAnim(charAnimator, PreloadedAnims.Characters[fighterData.Instance].CharacterAnims["Fight Idle"], 0.2, false)
			end)

			if personaAttackTrack then
				personaAttackTrack.Stopped:Once(function()
					if currentPersona and currentPersona.Parent then
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
	Maestro.BattleReady = false
end

return Maestro