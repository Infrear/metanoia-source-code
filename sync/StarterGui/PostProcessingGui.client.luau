--[[
	This script creates a part that is scaled to the player's viewport and adds a SurfaceGui
	that updates its PixelsPerStuds to match the scaling of a ScreenGui instance.

	SurfaceGuis are affected by the PostProcessing effects added under game.Lighting so more
	effects can be achieved!

	In this demo's case it tiles a paraboloid gradient to make the screen look lower resolution!
	I use it a few times, once to split up the screen, and other times to amplify some of the reds,
	greens, and blues.
--]]
local svcWorkspace = game:GetService("Workspace")
local svcPlayers = game:GetService("Players")
local svcRun = game:GetService("RunService")
-- Get the players user interface.
local plLocal = svcPlayers.LocalPlayer
local insPlayerGui = plLocal:WaitForChild("PlayerGui")
-- Create part.
local insPart = Instance.new("Part") -- This part will be scaled and placed in front of the player's camera.
insPart.Parent = workspace
insPart.Transparency = 1 -- Hide entirely.
insPart.Anchored = true
insPart.CanCollide = false
-- Find or create a gui.
local uiSurfaceGui = script:FindFirstChildWhichIsA("SurfaceGui") or Instance.new("SurfaceGui") -- This is added to the part so that post processing effects are applied to it.
uiSurfaceGui.Name = "WorldScreenGui"
uiSurfaceGui.Face = "Back"
uiSurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- Set this so that the pixels per stud can be calculated so that it matches ScreenGui.
uiSurfaceGui.Adornee = insPart
uiSurfaceGui.Parent = insPlayerGui
-- Distance part is moved away from the camera.
local OFFSET_DISTANCE = 0.101
-- Every rendered frame after the camera position is calculated, move the part infront of the camera.
svcRun:BindToRenderStep("CoverScreen", Enum.RenderPriority.Camera.Value + 1, function(paramDelta)
	local camCurrent = svcWorkspace.CurrentCamera
	-- Calculate the x, and y in studs at set distance:
	local viewportSize = camCurrent.ViewportSize
	local height = math.tan(math.rad(camCurrent.FieldOfView / 2)) * 2 * OFFSET_DISTANCE
	local width = (viewportSize.X / viewportSize.Y)	* height
	-- Part position.
	insPart.Size = Vector3.new(width, height, OFFSET_DISTANCE)
	insPart.CFrame = camCurrent.CFrame * CFrame.new(0,0, -(OFFSET_DISTANCE + (insPart.Size.Z/2)))
	-- Update the pixels per stud to match a ScreenGui.
	uiSurfaceGui.PixelsPerStud = viewportSize.X / width	 
end)
