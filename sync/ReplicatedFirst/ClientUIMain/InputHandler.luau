-- Services
local RPS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local PLRS = game:GetService("Players")
local CAS = game:GetService("ContextActionService")

-- Dependencies
local plr = PLRS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()

local Storage = RPS:WaitForChild("ClientStorage")
local WaitForInput = script.Parent:WaitForChild("WaitForInput")
local KeySettings = require(Storage.Info.KeybindsMaster)
local SkillLibrary = require(Storage.Info.SkillLibrary)
local ChoiceManager = require(script.Parent:WaitForChild("ChoiceManager"))
local GUIMaster = require(script.Parent:WaitForChild("GUIMaster"))
local CameraHandler = require(script.Parent:WaitForChild("CameraHandler"))
local Maestro = require(script.Parent:WaitForChild("CombatCienematics"))

-- Local Variables
local InputHandler = {}
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Global Variables
InputHandler.Active = false
InputHandler.Connections = {}

-- Local Functions

-- Public Functions
function InputHandler.InitializeInput() -- Starts input manager to listen for input & recives the surfaceGUI for handling the MainBattleUI there
	if not InputHandler.Active then
		InputHandler.Active = true
		CAS:UnbindAction("RbxCameraKeypress") -- Stops camera from using I and O as well as disables arrow key cam movement
		
		if InputHandler.Connections.InputBegan then
			InputHandler.Connections.InputBegan:Disconnect()
		end

		InputHandler.Connections.InputBegan = UIS.InputBegan:Connect(function(input, gP)
			if not gP then
				InputHandler.HandleActionInput(input)
			end
		end)
		return true
	else
		warn("InputManager is already active!")
	end
end

function InputHandler.Stop() -- Cleans up the InputManager
	if InputHandler.Active then
		InputHandler.Active = false
		for i, connection in pairs(InputHandler.Connections) do
			connection:Disconnect()
		end
	else
		warn("InputManager is already inactive!")
	end
end

function InputHandler.HandleActionInput(input) -- Detects keypresses for the Ring
	if input.KeyCode == Enum.KeyCode.E then -- Item
		if not GUIMaster.UIs.Target.Open then
			print("Opening Items...")
			ChoiceManager.ToggleSkillMenu("Items", GUIMaster.CurrentFighterData.ActivePersona.Name, {"Apple", "Berry", "Position"}) -- for later implementation
		end
	elseif input.KeyCode == Enum.KeyCode.F then -- Guard
			if GUIMaster.UIs.LeftMainBattleUI.Open then
				WaitForInput:FireServer("Guard")
			end
	elseif input.KeyCode == Enum.KeyCode.P then -- Persona/Skills
		if not GUIMaster.UIs.Target.Open and GUIMaster.CurrentFighterData and GUIMaster.CurrentFighterData.Skills then
			if GUIMaster.UIs.SkillsMenu.Open then
				coroutine.wrap(function()
					Maestro.RetrievePersona(char)
				end)()
				CameraHandler.Circle()
				coroutine.wrap(function()
					ChoiceManager.ToggleSkillMenu(ChoiceManager.CurrentAction, nil, nil, false)
					GUIMaster.Animations.CleanUpTri()
				end)()
			else
				--coroutine.wrap(function()
				Maestro.SummonPersona(char, GUIMaster.CurrentFighterData.ActivePersona.Name)
				--end)()
				ChoiceManager.ToggleSkillMenu("Skills", GUIMaster.CurrentFighterData.ActivePersona.Name, GUIMaster.CurrentFighterData.Skills)
				CameraHandler.FocusOn(GUIMaster.CurrentFighterData.Instance, nil, CameraHandler.OffsetPresets.SkillMenu, CFrame.new(0, -1.5 * (ChoiceManager.CurrentSkillFrame - 1), 0))
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp or input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.DPadDown then
		if GUIMaster.UIs.SkillsMenu.Open then
			ChoiceManager.ChangeSelection((input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.DPadUp) and "up" or "down")
		end	
	elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1 then
		local isLeft = (input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.ButtonL1)
		local isBumper = (input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.ButtonR1)
		
		if GUIMaster.UIs.Target.Open and not isBumper then
			-- arrow keys cycle target selection
			GUIMaster.ChangeSelection(isLeft and "left" or "right", ChoiceManager.CurrentSkillFrame)
		elseif GUIMaster.UIs.SkillsMenu.Open then
			-- cycle persona tray (arrows + bumpers both work here)
			GUIMaster.CyclePersonaTray(isLeft and "left" or "right")
		end	
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
		if GUIMaster.UIs.SkillsMenu.Open or GUIMaster.UIs.Target.Open then
			GUIMaster.Animations.UpdateTri("MouseClick", true)
			ChoiceManager.ConfirmSelection()
		end
	elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.ButtonX then
		if not GUIMaster.UIs.Target.Open then
			coroutine.wrap(function()
				ChoiceManager.ToggleSkillMenu(ChoiceManager.CurrentAction, nil, nil, false)
				GUIMaster.Animations.CleanUpTri()
				GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, false)
				GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, false)
				
				local success = GUIMaster.PromptBatonPass(GUIMaster.CurrentFightTab)
				
				if not success then
					ChoiceManager.ToggleSkillMenu("Skills", nil, nil, true)
					GUIMaster.ToggleMenu(GUIMaster.UIs.LeftMainBattleUI, true)
					GUIMaster.ToggleMenu(GUIMaster.UIs.RightMainBattleUI, true)
				end
			end)()
		end
	elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then -- "Back" button When player hits Backspace / Cancels
		if GUIMaster.UIs.Target.Open then
			-- Back out of Target selection to Skills or Items
			local m = (#GUIMaster.UIs.Target.Indicators > 1) or nil
			for i, v in pairs(GUIMaster.UIs.Target.Indicators) do
				GUIMaster.ToggleTargets(v, false, m)
			end
			GUIMaster.ToggleMenu(GUIMaster.UIs.Heart, false)
			ChoiceManager.ToggleSkillMenu(ChoiceManager.CurrentAction, GUIMaster.CurrentFighterData.ActivePersona.Name, {"Zio", "Agi", "Garu", "Cleave"}, true) -- re-open menu
			CameraHandler.FocusOn(GUIMaster.CurrentFighterData.Instance, nil, CameraHandler.OffsetPresets.SkillMenu, CFrame.new(0, -1.5 * (ChoiceManager.CurrentSkillFrame - 1), 0))
		elseif GUIMaster.UIs.SkillsMenu.Open then
			-- Back out of Skills to Main Ring
			CameraHandler.Circle()
			coroutine.wrap(function()
				Maestro.RetrievePersona(char)
			end)()
			coroutine.wrap(function()
				ChoiceManager.ToggleSkillMenu(ChoiceManager.CurrentAction, nil, nil, false)
				GUIMaster.Animations.CleanUpTri()
			end)()
		end
	end
end

-- INPUT SYSTEM INTEGRATION PLANNED
--[[
	1. DYNAMIC CONTROLS:
	   USE KeySettings TO REMAP BUTTONS FOR CONTROLLER SUPPORT (PHASE 8)[cite: 54].
	
	2. SELECTION UI:
	   WHEN A SKILL IS CLICKED, TRIGGER THE "TARGET SELECTION" PHASE.
	   THE MOUSE OR KEYBOARD SHOULD HIGHLIGHT THE TARGETED NPC.
]]

return InputHandler