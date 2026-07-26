-- Services
local RS = game:GetService("RunService")

-- Dependancies
local Warper = script.Parent.Warper -- the clipping frame
Warper.ClipsDescendants = true

local InnerFrame = Instance.new("Frame")
InnerFrame.Name = "GridContainer"
InnerFrame.BackgroundTransparency = 1
InnerFrame.Parent = Warper

-- Constants
local imageIds = {
	"rbxassetid://95645833247962", -- Sheet/Frame 1
	"rbxassetid://132413768602725", -- Sheet/Frame 2
	"rbxassetid://96214538827210",
	"rbxassetid://137847817863432",
	"rbxassetid://82491341845492",
	"rbxassetid://98235193039995",
	"rbxassetid://87395684250307",
	"rbxassetid://101090946122914",
	"rbxassetid://106540478936988",
	"rbxassetid://112741271980316",
	"rbxassetid://95600268271055",
	"rbxassetid://131003691460106",
	"rbxassetid://139929139690210",
	"rbxassetid://134926241525764",
	-- add as many as you need here
}


local lastFrame = 1 -- frame the animation starts at
local frames = 13 -- amount of frames in the animation
local rows = 5 -- amount of vertical frames in the animation
local columns = 3  -- amount of horizontal frames in the animation
local warperFramerate = (frames/49)*24  -- do i even need to explain this? (caps at 60)

local frameSize = Warper.Size --UDim2.fromScale(0.499, 0.281) -- default frame size

-- Local Variables

local currentFrame = 1
local lastTick = tick()

-- Local Methods
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
		
		script.Parent.Parent.ImageData:Fire(img)
	end
end

local function UpdateAnimation()
	if tick() - lastTick >= 1/warperFramerate then
		currentFrame = currentFrame + 1
		if currentFrame > #imageIds then currentFrame = 1 end

		local row = math.ceil(currentFrame / columns)
		local col = currentFrame - ((row - 1) * columns)

		-- move the InnerFrame in the opposite direction to "scroll" to the frame
		-- we still use scale here because InnerFrame's size is based on the number of cols/rows
		InnerFrame.Position = UDim2.new(-(col - 1), 0, -(row - 1), 0)

		lastTick = tick()
	end
end

-- Loose Threads
Warper.Size = frameSize

GenerateGridFunction()

RS.RenderStepped:Connect(UpdateAnimation)