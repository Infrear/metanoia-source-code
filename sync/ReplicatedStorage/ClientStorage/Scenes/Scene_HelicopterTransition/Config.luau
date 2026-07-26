-- Scene_TheFall.Config
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local startheight = 1000

return {
	Settings = { AllowSkip = false, CloseBarsOnCompletion = true},

	Animations = { -- for preloading
		{
			Subject = "CamRig",
			AnimationNames = {
				"Camera Intro Fight",
				"Camera Intro Idle1",
				"Camera Intro Fall", --> signal 2 is called "By Who Pause", signal 3 is "Title Pause"
				"Camera Intro Idle2",
				"Camera Intro Idle3",
			}
		},
		{
			Subject = "Villan",
			AnimationNames = {
				"Intro Fight (Villan)"
			}
		},
		{
			Subject = char,
			AnimationNames = {
				"Intro Fight (MC)",
				"Intro Fall (MC)",
				"MC By Who Idle",
				"MC Title Idle",
			}
		},
		{
			Subject = "Kiwi Bird",
			AnimationNames = {
				"Bird Intro Fall",
				"Bird By Who Idle",
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
				Villan = { Name = "Villan", StartingCF = CFrame.new(0.372, 98.46, 0.446) * CFrame.fromEulerAnglesXYZ(math.rad(-0.001), math.rad(-90), math.rad(0)) },
				CamRig = { Name = "CamRig", StartingCF = CFrame.new(0.372, 98.46 - 2.69029, 0.446) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(180), math.rad(0)) },
				Heli   = { Name = "Heli",   StartingCF = CFrame.new(0.372, 95.77, 0.446) },
			},
			MC_ANCHORED = true,
		},
		
		[2] = {
			Action = "Camera",
			Properties = {
				FieldOfView = 39.6,
			}
		},

		-- ///////////////////////////////////////////////////////////
		-- 3-4. ROTORS — spin the whole scene
		-- ///////////////////////////////////////////////////////////
		[3] = {
			Action   = "Spin",
			PropName = "Heli",
			PartName = "Propella1",
			UsePivot = true,
			Axis     = "Y",
			Speed    = 900,
			Async    = true,
		},
		[4] = {
			Action   = "Spin",
			PropName = "Heli",
			PartName = "Propella2",
			UsePivot = true,
			Axis     = "Y",
			Speed    = 1200,
			Async    = true,
		},

		-- ///////////////////////////////////////////////////////////
		-- 5. HATCH opens after 2 s (async so fight anims start immediately)
		-- ///////////////////////////////////////////////////////////
		[5] = {
			Action          = "Move",
			PropName        = "Heli",
			PartName        = "Hatch",
			UsePivot        = true,
			Axis            = "X",
			AngleDeg        = 60,
			Duration        = 0.75,
			Delay           = 2,
			EasingStyle     = Enum.EasingStyle.Elastic,
			EasingDirection = Enum.EasingDirection.Out,
			Async           = true,
		},

		[6] = {
			Action = "UI_Trigger",
			Name = "CienematicBars",
			--Delay = 2,
			Open = true,
			Async = true,
		},

		-- ///////////////////////////////////////////////////////////
		-- 7. FIGHT — runs until animation event "Pause 1" fires
		--    (put the event marker at frame ~2230 in the fight anim)
		-- ///////////////////////////////////////////////////////////
		[7] = {
			Action = "Animation",
			Targets = {
				{
					Subject = "Villan",
					AnimationName = "Intro Fight (Villan)",
				},
				{
					Subject = char,
					AnimationName = "Intro Fight (MC)",
				},
				{
					Subject = "CamRig",
					AnimationName = "Camera Intro Fight",
					Pause = { SignalName = "Pause 1", PauseAll = true },
					WaitForPause = true,
				},
			},
		},

		-- /// 8. IDLE CAM (dialogue camera) ///////////////////
		[8] = {
			Action = "Animation",
			Targets = {
				{
					Subject = "CamRig",
					AnimationName = "Camera Intro Idle1",
				},
			},
		},

		-- /// 8. FIRST DIALOGUE //////////////////////////////
		[9] = {
			Action = "Dialogue",
			Dialogue = "Pause1Dialogue",
			Speaker  = "Villan",
		},


		-- /// 10. RESUME FIGHT + WAIT FOR END //////////////////////////
		[10] = {
			Action = "Animation",
			Targets = {
				{
					Subject = "CamRig",
					AnimationName = "Camera Intro Fight",
					Unpause = true,
					FreezeOnCompletion = true,
				},
				{
					Subject = "Villan",
					AnimationName = "Intro Fight (Villan)",
					Unpause = true,
				},
				{
					Subject = "CamRig",
					AnimationName = "Camera Intro Idle1",
					Stop = true,
				},
				{
					Subject = char,
					AnimationName = "Intro Fight (MC)",
					Unpause = true,
					FreezeOnCompletion = true,
					WaitForCompletion = true,
				},
			},
		},

		[11] = {
			Action     = "Add Props",
			PropsToAdd = {
				-- spawns heli high above / off-screen so the Move below brings it in
				KB = { Name = "Kiwi Bird", StartingCF = CFrame.new(0.372, (98.46), 0.446) * CFrame.fromEulerAnglesXYZ(math.rad(-0.001), math.rad(180), math.rad(0)) },
			},
		},
		
		[12] = {
			Action    = "Hide Props",
			PropsToHide  = {"Heli", "Villan"},
		},
		
		-- ///////////////////////////////////////////////////////////
		-- 13. SCROLLING 3D CREDITS — plays during the fall before heli appears
		--     Text rises one line at a time; use funny/credits text for now
		-- ///////////////////////////////////////////////////////////
		[13] = {
			Action = "UI_Trigger",
			Name   = "ScrollingCredits",
			Data   = {
				Speed = 1,
				Color = "White",
				Lines = {
					"A Sky Imagination Studios Production",
					"Executive Producer: Nobody",
					"Craft Services: Also Nobody",
					"The bird was not harmed",
					"(the bird was harmed)",
				},
				--WaitForInput = true,   -- player clicks to continue
			},
		},
		
		-- ///////////////////////////////////////////////////////////
		-- 14. FALLING SEQUENCE — MC + Bird + cam all falling together
		--    Camera plays "Camera Intro Fall" here
		-- ///////////////////////////////////////////////////////////
		[14] = {
			Action  = "Animation",
			Targets = {
				{
					Subject       = "Kiwi Bird",
					AnimationName = "Bird Intro Fall",
				},
				{
					Subject           = char,
					AnimationName     = "Intro Fall (MC)",
					PlayInfo = {0}
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Fall",
					PlayInfo = {0},
					Pause        = { SignalName = "By Who Pause", PauseAll = true },
					WaitForPause = true,
				},
			},
		},

		-- ///////////////////////////////////////////////////////////
		-- 15. MC BROUGHT TO U IDLE — slow down everything & idle for brought to u screen
		-- ///////////////////////////////////////////////////////////
		[15] = {
			Action  = "Animation",
			Targets = {
				{
					Subject       = "Kiwi Bird",
					AnimationName = "Bird By Who Idle",
				},
				{
					Subject           = char,
					AnimationName     = "MC By Who Idle",
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Idle2",
				},
			},
		},
		
		-- ///////////////////////////////////////////////////////////
		-- 16. "BROUGHT TO YOU BY" card — waits for player click to dismiss
		-- ///////////////////////////////////////////////////////////
		[16] = {
			Action = "UI_Trigger",
			Name   = "BroughtToYouBy",
			Data   = {
				Producer  = "Sky Imagination Studios",
				WaitForInput = true,   -- your UI module should signal done when clicked
			},
		},

		-- ///////////////////////////////////////////////////////////
		-- 17. RESUME FALLING — unslow everything and continue falling animation until title screen 
		-- ///////////////////////////////////////////////////////////
		[17] = {
			Action  = "Animation",
			Targets = {
				{
					Subject       = "Kiwi Bird",
					AnimationName = "Bird Intro Fall",
					Unpause = true,
				},
				{
					Subject           = char,
					AnimationName     = "Intro Fall (MC)",
					Unpause = true,
				},
				{
					Subject       = "Kiwi Bird",
					AnimationName = "Bird By Who Idle",
					Stop = true,
				},
				{
					Subject           = char,
					AnimationName     = "MC By Who Idle",
					Stop = true,
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Idle2",
					Stop = true,
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Fall",
					Pause        = { SignalName = "Title Pause", PauseAll = true },
					WaitForPause = true,
					Unpause = true,
				},
			},
		},

		-- ///////////////////////////////////////////////////////////
		-- 18. MC TITLE IDLE — after mc turns to look at heli, hold while title, scene & heli explodes
		-- ///////////////////////////////////////////////////////////
		[18] = {
			Action  = "Animation",
			Targets = {
				{
					Subject           = char,
					AnimationName     = "MC Title Idle",
					PlayInfo = {1}
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Idle3",
				},
			},
		},

		-- ///////////////////////////////////////////////////////////
		-- 19-22. HELI FALLS AND SPINS INTO FRAME (Add Prop at off-screen position,
		--     then Move it down into frame)
		--     Triggered by animation event at ~frame 2252
		-- ///////////////////////////////////////////////////////////
		[19] = {
			Action     = "Add Props",
			PropsToAdd = {
				-- spawns heli high above / off-screen so the Move below brings it in
				H = { Name = "Heli" },
			},
		},

		[20] = {
			Action   = "Spin",
			PropName = "Heli",
			UsePivot = true,
			Axis     = "Y",
			Speed    = 1200,
			Duration = 10,
			--TargetAngle = 5400,
			Async    = true,
		},
		
		[21] = {
			Action    = "Move",
			PropName  = "Heli",
			TargetCF  = CFrame.new(-94.021, 61.247, -6.444),  -- falls into frame position
			--TargetCF = CFrame.new(-308.341, 61.247, 123.013),
			PositionOnly = true,
			Duration  = 1,
			EasingStyle     = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.In,   -- accelerates like gravity
			Async     = false,
		},
		
		[22] = {
			Action    = "Move",
			PropName  = "Heli",
			Moves = {
				[1] = {
					TargetCF = CFrame.new(-308.341, 1.247, 123.013),
					PositionOnly = true,
					Duration  = 0.5,
					EasingStyle     = Enum.EasingStyle.Quad,
					EasingDirection = Enum.EasingDirection.In,   -- accelerates like gravity
					Async     = false,
				},
				[2] = {
					Delay = 2,
					Instant = true,
					TargetCF = CFrame.new(-308.341, -200, 123.013),
					IgnoreSceneOffset = true,
					HideOnFinish = true,
					Async     = true,
				},
			},
			Async = true
		},

		-- ///////////////////////////////////////////////////////////
		-- 23. HELI EXPLOSION — async so slowdown fires simultaneously
		-- ///////////////////////////////////////////////////////////
		[23] = {
			Action     = "VFX",
			EffectPath = "Environment.Fire.MeteorSmash",
			PropName   = "Heli",
			EmitCount  = 100,
			Lifetime   = 4,
			Async      = true,
			UsePart = true
		},

		-- ///////////////////////////////////////////////////////////
		---- 24. SLOW MOTION + TITLE CARD out of the explosion
		----     Animation slows here — your UI module fades/scales the
		----     title in over the explosion bloom
		---- ///////////////////////////////////////////////////////////
		[24] = {
			Action = "UI_Trigger",
			Name   = "TitleCard",
			Data   = {
				Title    = "Metanoia 5",
				Subtitle = "Sky Imagination Studios",
				Duration = 3.5,         -- auto-dismiss after this many seconds
				FadeIn   = 0.8,
				FadeOut  = 0.6,
				WaitForDismiss = true,  -- blocks until UI signals done
				WaitForInput = true,   -- allow player to close early by clicking
			},
		},
		
		-- ///////////////////////////////////////////////////////////
		-- 25. RESUME fall anim — MC turns away from looking at heli
		-- ///////////////////////////////////////////////////////////
		[25] = {
			Action  = "Animation",
			Targets = {
				{
					Subject           = char,
					AnimationName     = "Intro Fall (MC)",
					Unpause           = true,
					FreezeOnCompletion = true,
				},
				{
					Subject           = char,
					AnimationName     = "MC Title Idle",
					Stop = true,
					StopInfo = {1},
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Idle3",
					Stop = true,
				},
				{
					Subject       = "CamRig",
					AnimationName = "Camera Intro Fall",
					Unpause           = true,
					EventSteps = {
						{ 
							SignalName = "SpawnFloor",
							Steps = {
								[1] = {
									Action     = "Add Props",
									PropsToAdd = {
										-- spawns heli high above / off-screen so the Move below brings it in
										KB = { Name = "Baser", StartingCF = CFrame.new(0, 22.271, 0) },
									},
								},
							}
						}	
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
		--},
	},
	CleanupFunction =  function(super)
		super.CameraHandler.Stop()
		char:PivotTo(workspace.SPAWNS.SpawnLocationA:GetPivot() * CFrame.new(0, 0, 5))
		hrp.Anchored = false
		workspace.CurrentCamera.FieldOfView = 65
	end,
}