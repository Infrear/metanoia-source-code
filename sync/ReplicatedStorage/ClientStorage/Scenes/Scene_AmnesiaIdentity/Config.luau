-- Scene_TheFall.Config
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local startheight = 0

return {
	Settings = { AllowSkip = false, CloseBarsOnCompletion = true},

	Animations = { -- for preloading
		{
			Subject = "CamRig",
			AnimationNames = {
				"Camera Sleep Dream Intro",
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
				Villan = { Name = "RoomScene", StartingCF = CFrame.new(-280, 5947.001, -222) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(-180), math.rad(-0)) },
				CamRig = { Name = "CamRig", StartingCF = CFrame.new(-280, 5947.001, -222) * CFrame.fromEulerAnglesXYZ(math.rad(0), math.rad(0), math.rad(0)) },
			},
			MC_ANCHORED = true,
		},
		
		[2] = {
			Action = "Camera",
			Properties = {
				FieldOfView = 76.0941,
			}
		},

		[3] = {
			--Action   = "Spin",
			--PropName = "Heli",
			--PartName = "Propella1",
			--UsePivot = true,
			--Axis     = "Y",
			--Speed    = 900,
			--Async    = true,
			Action = "Placeholder",
		},
		[4] = {
			--Action   = "Spin",
			--PropName = "Heli",
			--PartName = "Propella2",
			--UsePivot = true,
			--Axis     = "Y",
			--Speed    = 1200,
			--Async    = true,
			Action = "Placeholder",
		},

		[5] = {
			Action = "Animation",
			Targets = {
				{
					Subject = char,
					AnimationName = "Intro Sleep Dream (MC)",
				},
				{
					Subject = "CamRig",
					AnimationName = "Camera Sleep Dream Into",
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
									PropsToHide  = {"RoomScene"},
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
	CleanupFunction = function()
		char:PivotTo(workspace.SPAWNS.SpawnLocationA:GetPivot() * CFrame.new(0, 0, 5))
		hrp.Anchored = false
		workspace.CurrentCamera.FieldOfView = 65
	end,
}