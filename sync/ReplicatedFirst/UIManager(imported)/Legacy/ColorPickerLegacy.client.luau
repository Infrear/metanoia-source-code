-- dispeller 2020
-- Color picker example

local Player = game.Players.LocalPlayer
local UserInputService = game:GetService('UserInputService')
local MainFrame = script.Parent.ColorPickerFrame
local ColorShower = MainFrame.ColorShower
local PickerArea = MainFrame.ColorPickerArea
local Picker = PickerArea.Picker
local Gradient = PickerArea:FindFirstChildOfClass('UIGradient')
local ColorKeyPoints = Gradient.Color.Keypoints
local selecting = false

-- load the getColor function
getColor = require(script.GetOnGradientSlider)

-- upon the user selecting
function beginSelection()
	selecting = true
	repeat wait()
		
		-- left cord of ColorPickerArea in pixels
		local minXPos = PickerArea.AbsolutePosition.X
		
		-- right cord of ColorPickerArea in pixels
		local maxXPos = minXPos+PickerArea.AbsoluteSize.X
		
		-- width of ColorPickerArea in pixels
		local xPixelSize = maxXPos-minXPos
		
		-- raw Mouse X pixel position
		local mouseX = UserInputService:GetMouseLocation().X
		
		-- constraints
		if mouseX<minXPos then
			mouseX = minXPos
		elseif mouseX>maxXPos then
			mouseX = maxXPos
		end
		
		-- get percentage mouse is on
		local xPos = (mouseX-minXPos)/xPixelSize
		
		-- move the visual Picker line
		Picker.Position = UDim2.new(xPos,0,0,0)
		
		-- set the ColorShower frame color
		ColorShower.BackgroundColor3 = getColor(xPos,ColorKeyPoints)
		
	until not selecting
end

-- upon the user ending selection
function endSelection()
	-- this will stop the loop
	selecting = false
end

-- check input for selection beginning
local function inputBegan(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginSelection()
	end
end
PickerArea.InputBegan:Connect(inputBegan)

-- check input for selection ending
local function inputEnded(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endSelection()
	end
end
PickerArea.InputEnded:Connect(inputEnded)