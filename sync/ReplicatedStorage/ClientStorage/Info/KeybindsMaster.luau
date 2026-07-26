-- Services
local UIS = game:GetService("UserInputService")

-- Local Functions
-- Function to detect platform based on the last input type
local function checkPlatform()
	local lastInput = UIS:GetLastInputType()

	if lastInput == Enum.UserInputType.Touch then
		return "Mobile"
	elseif lastInput == Enum.UserInputType.Gamepad1 or
		lastInput == Enum.UserInputType.Gamepad2 or
		lastInput == Enum.UserInputType.Gamepad3 or
		lastInput == Enum.UserInputType.Gamepad4 then
		return "Console"
	elseif lastInput == Enum.UserInputType.Keyboard or
		lastInput == Enum.UserInputType.MouseButton1 or
		lastInput == Enum.UserInputType.MouseMovement then
		return "Keyboard"
	else
		return "Keyboard" -- Handle edge cases or unsupported inputs
	end
end
--[[function checkPlatform()
	local thetype = "Keyboard"
	if UIS.TouchEnabled then
		thetype = "Mobile"
	elseif UIS.GamepadEnabled then
		thetype = "Console"
	elseif UIS.KeyboardEnabled then
		thetype = "Keyboard"
	elseif UIS.MouseEnabled then
		thetype = "Keyboard"		
	end
	UIS.InputBegan:Connect(function)
	return thetype
end]]--

-- Send initial platform data to the server
local plrPlatform = checkPlatform()
print(plrPlatform)

-- Update platform when the user's input type changes
UIS.LastInputTypeChanged:Connect(function()
	local newPlatform = checkPlatform()
	--print(plrPlatform)
	if newPlatform ~= plrPlatform then
		--print(plrPlatform)
		plrPlatform = newPlatform
	end
end)


-- Local Variables
local plrplatform = checkPlatform()
--print(plrplatform)

-- Loose Threads
if checkPlatform() == "Mobile" then

end

-- Initialization
return {
	Platform = plrplatform,
	-- Combat
	Combat = {
		["Main Action"] = plrplatform == "Console" and Enum.KeyCode.ButtonR2 or Enum.UserInputType.MouseButton1,
		["Alternate Action"] = plrplatform == "Console" and Enum.KeyCode.ButtonL2 or Enum.UserInputType.MouseButton2,
		["Block"] = plrplatform == "Console" and Enum.KeyCode.ButtonR1 or Enum.KeyCode.F,
		["Sword"] = Enum.KeyCode.One,
		["Uptilt"] = Enum.KeyCode.Space,
	},
	UI = {
		["Inventory"] = plrplatform == "Console" and Enum.KeyCode.ButtonB or Enum.KeyCode.E,
		["Crafting"] = plrplatform == "Console" and "empty keybind" or Enum.KeyCode.C,
		["Self"] = plrplatform == "Console" and "empty keybind" or Enum.KeyCode.F,
	},
	Interactions = {
		["Pick up"] = plrplatform == "Console" and Enum.KeyCode.ButtonY or Enum.KeyCode.T,
		["Interact"] = plrplatform == "Console" and Enum.KeyCode.ButtonX or Enum.KeyCode.E,
		["Drop"] = plrplatform == "Console" and Enum.KeyCode.ButtonL1 or Enum.KeyCode.Q,
		INTERACT_DISTANCE_THRESHOLD_DEFAULT = 8.5,
		INTERACT_TIMES = {
		},
		INTERACT_DISTANCE_THRESHOLD = {
			["NPC_Default"] = 5.5,
			["NPC_Quest"] = 5.5,
		},
		TALKABLE_NPC_TYPES = {
			["Quest"] = true,
			["Action"] = true,
			["Talk"] = true,
		}
	},
	Building = {
		["Cancel"] = plrplatform == "Console" and Enum.KeyCode.ButtonB or Enum.KeyCode.C,
		["Rotate"] = plrplatform == "Console" and Enum.KeyCode.ButtonR3 or Enum.KeyCode.R,
		["Turn"] = plrplatform == "Console" and Enum.KeyCode.ButtonL3 or Enum.KeyCode.T,
		["Confirm Placement"] = plrplatform == "Console" and Enum.KeyCode.ButtonR2 or Enum.UserInputType.MouseButton1,
	},
	Movement = {
		["Climb"] = plrplatform == "Console" and Enum.KeyCode.ButtonA or Enum.KeyCode.Space,	
		["Run"] = plrplatform == "Console" and Enum.KeyCode.ButtonL3 or Enum.KeyCode.LeftShift,
		["Shift Lock"] = plrplatform == "Console" and Enum.KeyCode.ButtonSelect or Enum.KeyCode.LeftAlt,
		["Crouch"] = plrplatform == "Console" and Enum.KeyCode.DPadDown or Enum.KeyCode.LeftControl,
	},
}

--[[
return {
	Platform = plrplatform,
	-- Combat
	Combat = {
		["Main Action"] = plrplatform == "Keyboard" and Enum.UserInputType.MouseButton1 or Enum.KeyCode.ButtonR2,
		["Alternate Action"] = plrplatform == "Keyboard" and Enum.UserInputType.MouseButton2 or Enum.KeyCode.ButtonL2,
		["Block"] = plrplatform == "Keyboard" and Enum.KeyCode.F or Enum.KeyCode.ButtonR1,
		["Sword"] = Enum.KeyCode.One,
		["Uptilt"] = Enum.KeyCode.Space,
	},
	UI = {
		["Inventory"] = plrplatform == "Keyboard" and Enum.KeyCode.E or Enum.KeyCode.ButtonB,
		["Crafting"] = plrplatform == "Keyboard" and Enum.KeyCode.C or nil,
		["Self"] = plrplatform == "Keyboard" and Enum.KeyCode.F or nil,
	},
	Interactions = {
		["Pick up"] = plrplatform == "Keyboard" and Enum.KeyCode.T or Enum.KeyCode.ButtonY,
		["Interact"] = plrplatform == "Keyboard" and Enum.KeyCode.E or Enum.KeyCode.ButtonX,
		["Drop"] = plrplatform == "Keyboard" and Enum.KeyCode.Q or Enum.KeyCode.ButtonL1,
		INTERACT_DISTANCE_THRESHOLD_DEFAULT = 9.5,
		INTERACT_TIMES = {
		},
		INTERACT_DISTANCE_THRESHOLD = {
			["NPC_Default"] = 5.5,
			["NPC_Quest"] = 5.5,
		},
		TALKABLE_NPC_TYPES = {
			["Quest"] = true,
		}
	},
	Building = {
		["Cancel"] = plrplatform == "Keyboard" and Enum.KeyCode.C or Enum.KeyCode.ButtonB,
		["Rotate"] = plrplatform == "Keyboard" and Enum.KeyCode.R or Enum.KeyCode.ButtonR3,
		["Turn"] = plrplatform == "Keyboard" and Enum.KeyCode.T or Enum.KeyCode.ButtonL3,
		["Confirm Placement"] = plrplatform == "Keyboard" and Enum.UserInputType.MouseButton1 or Enum.KeyCode.ButtonR2,
	},
	Movement = {
		["Climb"] = plrplatform == "Keyboard" and Enum.KeyCode.Space or Enum.KeyCode.ButtonA,	
		["Run"] = plrplatform == "Keyboard" and Enum.KeyCode.LeftShift or Enum.KeyCode.ButtonL3,
		["Shift Lock"] = plrplatform == "Keyboard" and Enum.KeyCode.LeftAlt or Enum.KeyCode.ButtonSelect,
		["Crouch"] = plrplatform == "Keyboard" and Enum.KeyCode.LeftControl or Enum.KeyCode.DPadDown,
	},
}
]]
