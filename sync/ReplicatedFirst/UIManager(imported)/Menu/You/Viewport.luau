--[=[
	Character Viewport
	Realtime viewing oneself in a GUI window, including tools

	boatbomber, dafferrelic842 2/17/19 (Updated: 7/16/2024)
--]=]

local vPort = {}

-- Settings
local OFFSET = CFrame.new(0,2.5,-7)

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Objects
local Player = game.Players.LocalPlayer
repeat wait() until Player.Character ~= nil
local Character = Player.Character
local ViewPort = nil
local Camera = nil

local ValidClasses = {
	["MeshPart"] = true; ["Part"] = true; ["Accoutrement"] = true;
	["Pants"] = true; ["Shirt"] = true;
	["Humanoid"] = true;
}

local RenderObjects = table.create(25)

function vPort.RemoveObject(Object)
	local Clone = RenderObjects[Object]
	if not Clone then return nil end

	RenderObjects[Object] = nil
	if Clone.Parent:IsA("Accoutrement") then
		Clone.Parent:Destroy()
	else
		Clone:Destroy()
	end

	--print("Removed",Object)
end

function vPort.AddObject(Object)
	if not ValidClasses[Object.ClassName] then
		return nil
	end

	-- Create clone, regardless of Archivable
	local a = Object.Archivable
	Object.Archivable = true
	local RenderClone = Object:Clone()
	Object.Archivable = a

	if Object.ClassName == "MeshPart" or Object.ClassName == "Part" then
		RenderObjects[Object] = RenderClone

	elseif Object:IsA("Accoutrement") then
		RenderObjects[Object.Handle] = RenderClone.Handle

	elseif Object.ClassName == "Humanoid" then
		--Disable all states. We only want it for clothing wrapping.
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.FallingDown,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Running,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Climbing,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.GettingUp,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Jumping,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Landed,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Flying,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Freefall,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Seated,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Dead,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Swimming,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Physics,				false)
		RenderClone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	--print("Added",Object)

	return RenderClone
end

vPort.runCon = nil 

--Let the world load before starting
wait(1)

function vPort.HandleChar()
	--warn("Handle char")

	table.clear(RenderObjects)
	ViewPort:ClearAllChildren()

	local Viewmodel = Instance.new("Model")
	Viewmodel.Name = "PlayerViewmodel"
	Viewmodel.Parent = ViewPort

	local CharObjects = Character:GetDescendants()
	for i, Object in pairs(CharObjects) do
		local RenderClone = vPort.AddObject(Object)
		if RenderClone then
			RenderClone.Parent = Viewmodel
		end
	end

	Character.DescendantAdded:Connect(function(NewObject)
		local RenderClone = vPort.AddObject(NewObject)
		if RenderClone then
			RenderClone.Parent = Viewmodel
		end
	end)
	Character.DescendantRemoving:Connect(function(OldObject)
		vPort.RemoveObject(OldObject)
	end)
end

--Render the character
function vPort.start(char, vp)
	if vp then
		ViewPort = vp
	else
		return
	end

	if char then
		Character = char
	end
	
	Camera = Instance.new("Camera")

	ViewPort.CurrentCamera	= Camera
	
	vPort.runCon = RunService.RenderStepped:Connect(function()
		if (not Character:FindFirstChild("HumanoidRootPart")) or (not ViewPort.Visible) then
			return nil
		end

		-- Update camera
		Camera.CFrame = CFrame.new(Character.HumanoidRootPart.CFrame:ToWorldSpace(OFFSET).Position, Character.HumanoidRootPart.Position)

		-- Update objects
		for Original, Clone in pairs(RenderObjects) do
			if Original and Original.Parent then
				Clone.CFrame = Original.CFrame
			else
				vPort.RemoveObject(Original)
			end
		end
	end)
	
	vPort.HandleChar()
end

return vPort