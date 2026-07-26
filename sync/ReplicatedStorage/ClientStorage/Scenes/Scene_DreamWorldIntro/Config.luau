-- Scene_TheFall.Config
local TS = game:GetService("TweenService")

local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
local head = char:WaitForChild("Head")
local startheight = 100



return {
	Settings = { AllowSkip = false, CloseBarsOnCompletion = true, NoExitTransition = true, TweenCamBack = true},

	Animations = { -- for preloading
		{
			Subject = "CamRig",
			AnimationNames = {
				"Camera Sleep Dream Intro",
			}
		},
		{
			Subject = "MovingRoomSceneRig",
			AnimationNames = {
				"Intro Sleep Pillow Updown (RoomRig)"
			}
		},
		{
			Subject = char,
			AnimationNames = {
				"Intro Sleep Dream (MC)"
			}
		},
	},

	SceneOffset = CFrame.new(0, startheight, 0),
	
	Timeline = {

		-- ///////////////////////////////////////////////////////////
		-- 1. SETUP
		-- ///////////////////////////////////////////////////////////
		[1] = {
			Action = "Setup",
			StarterProps = {
				--Room = { Name = "RoomScene", StartingCF = CFrame.new(-280, 5947.001, -222) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(-180), math.rad(-0)) },
				CamRig = { Name = "CamRig", StartingCF = CFrame.new(-280, 5947.001, -222) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)) },
				RoomRig = { Name = "MovingRoomSceneRig", StartingCF = CFrame.new(-280, 5944.001, -222) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)) },
			},
			MC_ANCHORED = true,
		},
		
		[2] = {
			Action = "Camera",
			Properties = {
				FieldOfView = 76.0941,
			}
		},

		--[3] = {
		--	--Action   = "Spin",
		--	--PropName = "Heli",
		--	--PartName = "Propella1",
		--	--UsePivot = true,
		--	--Axis     = "Y",
		--	--Speed    = 900,
		--	--Async    = true,
		--	Action = "Placeholder",
		--},
		--[4] = {
		--	--Action   = "Spin",
		--	--PropName = "Heli",
		--	--PartName = "Propella2",
		--	--UsePivot = true,
		--	--Axis     = "Y",
		--	--Speed    = 1200,
		--	--Async    = true,
		--	Action = "Placeholder",
		--},

		[3] = {
			Action = "UI_Trigger",
			Name = "CienematicBars",
			--Delay = 2,
			Open = true,
			Async = true,
		},
		
		[4] = {
			Action = "Animation",
			Targets = {
				{
					Subject = char,
					AnimationName = "Intro Sleep Dream (MC)",
					FreezeOnCompletion = true,
				},
				{
					Subject = "MovingRoomSceneRig",
					AnimationName = "Intro Sleep Pillow Updown (RoomRig)",
				},
				{
					Subject = "CamRig",
					AnimationName = "Camera Sleep Dream Intro",
					EventSteps = {
						{ 
							SignalName = "FadeIn",
							Steps = {
								[1] = {
									Action = "UI_Trigger",
									Name = "SimpleFade",
									In = true,
									Async = false,
								},
								[2] = {
									Action    = "Hide Props",
									PropsToHide  = {"RoomScene", "MovingRoomSceneRig"},
								},
								[3] = {
									Action    = "Move",
									PropName  = char,
									isOffset  = true,
									TargetCF  = CFrame.new(0, -100, 0),
									Instant   = true,
								},
								[4] = {
									Action    = "Move",
									PropName  = "CamRig",
									isOffset  = true,
									TargetCF  = CFrame.new(0, -100, 0),
									Instant   = true,
								},
								[5] = {
									Action = "Function",
									Function = function(props)
										--props:FindFirstChild("CamRig"):SetAttribute("OnCloud", true)
										char:SetAttribute("OnCloud", true)
									end,
								},
							}
						},	
						{ 
							SignalName = "FadeOut",
							Steps = {
								[1] = {
									Action = "UI_Trigger",
									Name = "SimpleFade",
									Async = false,
								},
							}
						},	
						{ 
							SignalName = "BeamStrike",
							Steps = {
								[1] = {
									Action      = "VFX",
									VFXFunction = "BeamStrike",
									EffectPath  = "Combat.Chargu",
									WorldCF     = CFrame.new(312.448, 5951.037, -114.662) * CFrame.fromEulerAnglesXYZ(math.rad(-4.207), 0, math.rad(-1.222)),
									Lifetime    = 2,
									SlamDelay   = 0.8,
									Async       = true,
									IgnoreSceneOffset = true,
								},
							}
						},	
						{ 
							SignalName = "ShiftToNorm",
							Steps = {
								[1] = {
									Action    = "Move",
									PropName  = char,
									isOffset  = true,
									TargetCF  = CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0) * CFrame.new(1.6488, -2.642546, -0.725),
									Instant   = true,
								},
							}
						},	
					},
					FreezeOnCompletion = true,
					WaitForCompletion = true,
				},
			},
		},


		-- ///////////////////////////////////////////////////////////
		---- 25. FADE OUT — hand off to next cutscene / gameplay
		---- ///////////////////////////////////////////////////////////
		--[25] = {
		--	Action   = "Effect",
		--	Name     = "FadeToBlack",
		--	Duration = 1.5,
		--},]]
	},
	CleanupFunction = function(super)
		super.CameraHandler.Stop()
		workspace.RESOURCES.dreamworld.floatables.platforms.clouds.FrozeFoilage1:SetAttribute("Froze", true)
		char:SetAttribute("OnCloud", false)
		plr:SetAttribute("InCutscene", false)
	end,
	
	PostTweenCamBackFunction = function(super)
		workspace.RESOURCES.dreamworld.floatables.platforms.clouds.FrozeFoilage1:SetAttribute("Froze", false)
		local TE = TS:Create(cam, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {FieldOfView = 65})
		TE:Play()
	end,
}