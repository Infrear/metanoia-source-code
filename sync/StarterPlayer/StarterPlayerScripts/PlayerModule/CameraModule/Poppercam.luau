--!nonstrict
--[[
	Poppercam - Occlusion module that brings the camera closer to the subject when objects are blocking the view.
	modified by your's truly, obinna
--]]

local TweenService = game:GetService("TweenService")

local CommonUtils = script.Parent.Parent:WaitForChild("CommonUtils")
local FlagUtil = require(CommonUtils:WaitForChild("FlagUtil"))

local ZoomController =  require(script.Parent:WaitForChild("ZoomController"))
local FFlagUserFixCameraFPError = FlagUtil.getUserFlag("UserFixCameraFPError")

local TransformExtrapolator = {} do
	TransformExtrapolator.__index = TransformExtrapolator

	local CF_IDENTITY = CFrame.new()

	local function cframeToAxis(cframe: CFrame): Vector3
		local axis: Vector3, angle: number = cframe:ToAxisAngle()
		return axis*angle
	end

	local function axisToCFrame(axis: Vector3): CFrame
		local angle: number = axis.Magnitude
		if angle > 1e-5 then
			return CFrame.fromAxisAngle(axis, angle)
		end
		return CF_IDENTITY
	end

	local function extractRotation(cf: CFrame): CFrame
		local _, _, _, xx, yx, zx, xy, yy, zy, xz, yz, zz = cf:GetComponents()
		return CFrame.new(0, 0, 0, xx, yx, zx, xy, yy, zy, xz, yz, zz)
	end

	function TransformExtrapolator.new()
		return setmetatable({
			lastCFrame = nil,
		}, TransformExtrapolator)
	end

	function TransformExtrapolator:Step(dt: number, currentCFrame: CFrame)
		local lastCFrame = self.lastCFrame or currentCFrame
		self.lastCFrame = currentCFrame

		local currentPos = currentCFrame.Position
		local currentRot = extractRotation(currentCFrame)

		local lastPos = lastCFrame.p
		local lastRot = extractRotation(lastCFrame)

		-- Estimate velocities from the delta between now and the last frame
		-- This estimation can be a little noisy.
		local dp = (currentPos - lastPos)/dt
		local dr = cframeToAxis(currentRot*lastRot:inverse())/dt

		local function extrapolate(t)
			local p = dp*t + currentPos
			local r = axisToCFrame(dr*t)*currentRot
			return r + p
		end

		return {
			extrapolate = extrapolate,
			posVelocity = dp,
			rotVelocity = dr,
		}
	end

	function TransformExtrapolator:Reset()
		self.lastCFrame = nil
	end
end

--[[ The Module ]]--
local BaseOcclusion = require(script.Parent:WaitForChild("BaseOcclusion"))
local Poppercam = setmetatable({}, BaseOcclusion)
Poppercam.__index = Poppercam

function Poppercam.new()
	local self = setmetatable(BaseOcclusion.new(), Poppercam)
	self.focusExtrapolator = TransformExtrapolator.new()

	-- Resume-blend state, see bottom of Update()
	self.resumeBlendActive = false
	self.resumeBlendStartTime = 0
	self.resumeBlendStartCFrame = nil

	return self
end

function Poppercam:GetOcclusionMode()
	return Enum.DevCameraOcclusionMode.Zoom
end

function Poppercam:Enable(enable)
	self.focusExtrapolator:Reset()
end

function Poppercam:Update(renderDt, desiredCameraCFrame, desiredCameraFocus, cameraController)
	local rotatedFocus = nil
	if FFlagUserFixCameraFPError then
		rotatedFocus = CFrame.lookAlong(desiredCameraFocus.p, -desiredCameraCFrame.LookVector)*CFrame.new(
			0, 0, 0,
			-1, 0, 0,
			0, 1, 0,
			0, 0, -1
		)
	else
		rotatedFocus = CFrame.new(desiredCameraFocus.p, desiredCameraCFrame.p)*CFrame.new(
			0, 0, 0,
			-1, 0, 0,
			0, 1, 0,
			0, 0, -1
		)
	end

	local extrapolation = self.focusExtrapolator:Step(renderDt, rotatedFocus)
	local zoom = ZoomController.Update(renderDt, rotatedFocus, extrapolation)
	local finalCFrame = rotatedFocus*CFrame.new(0, 0, zoom)

	-- Resume-blend: when a script hands control back to Custom after driving
	-- cam.CFrame directly (cutscenes, persona cam, etc.), this is the actual
	-- last write before CameraModule sets currentCamera.CFrame, so this is
	-- where any leftover mismatch needs to be eased out, not upstream in
	-- ClassicCamera, since Poppercam recomputes position from scratch anyway.
	local camera = workspace.CurrentCamera
	local wantsResumeBlend = camera:GetAttribute("CameraResumeBlend")
	if wantsResumeBlend and not self.resumeBlendActive then
		self.resumeBlendActive = true
		self.resumeBlendStartTime = tick()
		self.resumeBlendStartCFrame = camera.CFrame -- the actual, currently-visible CFrame
	end

	if self.resumeBlendActive then
		local duration = camera:GetAttribute("CameraResumeBlendDuration") or 0.4
		local alpha = math.clamp((tick() - self.resumeBlendStartTime) / duration, 0, 1)

		-- Resolve EaseStyle attribute (String or EnumItem)
		local styleAttr = camera:GetAttribute("CameraResumeBlendEaseStyle")
		local easeStyle = Enum.EasingStyle.Quad
		if typeof(styleAttr) == "EnumItem" then
			easeStyle = styleAttr
		elseif type(styleAttr) == "string" and Enum.EasingStyle[styleAttr] then
			easeStyle = Enum.EasingStyle[styleAttr]
		end

		-- Resolve EaseDirection attribute (String or EnumItem)
		local dirAttr = camera:GetAttribute("CameraResumeBlendEaseDirection")
		local easeDir = Enum.EasingDirection.Out
		if typeof(dirAttr) == "EnumItem" then
			easeDir = dirAttr
		elseif type(dirAttr) == "string" and Enum.EasingDirection[dirAttr] then
			easeDir = Enum.EasingDirection[dirAttr]
		end

		-- Apply easing curve to the alpha value
		local easedAlpha = TweenService:GetValue(alpha, easeStyle, easeDir)
		finalCFrame = self.resumeBlendStartCFrame:Lerp(finalCFrame, easedAlpha)

		if alpha >= 1 then
			self.resumeBlendActive = false
			camera:SetAttribute("CameraResumeBlend", nil)
			camera:SetAttribute("CameraResumeBlendEaseStyle", nil)
			camera:SetAttribute("CameraResumeBlendEaseDirection", nil)
		end
	end

	return finalCFrame, desiredCameraFocus
end

-- Called when character is added
function Poppercam:CharacterAdded(character, player)
end

-- Called when character is about to be removed
function Poppercam:CharacterRemoving(character, player)
end

function Poppercam:OnCameraSubjectChanged(newSubject)
end

return Poppercam
