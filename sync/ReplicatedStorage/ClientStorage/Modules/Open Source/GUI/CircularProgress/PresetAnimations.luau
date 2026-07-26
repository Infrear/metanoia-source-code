local TweenService = game:GetService("TweenService")

local Animations = {}

--Infinite loading animations
function Animations.InfSpin1(self)
	local Circle = self.Instance.Circle
	self.Rotation = 320
	local TweenInf = TweenInfo.new(0.9, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local Speed = 100
	local Rotation = 0

	local BGRotation = 90
	local BackgroundTween = nil
	local Loop = game:GetService("RunService").RenderStepped:Connect(function(Delta)
		Rotation += Speed * Delta
		Circle.Rotation = Rotation
		if BackgroundTween == nil or BackgroundTween.PlaybackState == Enum.PlaybackState.Completed then
			BackgroundTween = TweenService:Create(self.Instance, TweenInf, {Rotation = BGRotation})
			BackgroundTween:Play()
			BGRotation += 90
		end
	end)
	return Loop
end

function Animations.InfSpin2(self)
	local Speed = 80
	local Loop = game:GetService("RunService").RenderStepped:Connect(function(Delta)
		self.Rotation += Speed * Delta
	end)
	return Loop
end

function Animations.InfSpin3(self)
	local Circle = self.Instance.Circle
	local TweenInf = TweenInfo.new(0.9, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local RTweenInf = TweenInfo.new(0.9*2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local Speed = 150
	local Rotation = 0
	local Reversing = false
	local RMultiplier = 2.25
	
	local min = 20
	local minthresh = 150
	local max = 360
	
	local BGRotation = 90
	local BackgroundTween = nil
	local Loop = game:GetService("RunService").RenderStepped:Connect(function(Delta)
		if Rotation + (Speed * Delta) >= max then
			Reversing = true
			if BackgroundTween then
				BackgroundTween:Cancel()
				BackgroundTween = nil
			end
		elseif Rotation - (Speed * Delta) <= min then
			Reversing = false
			if BackgroundTween then
				BackgroundTween:Cancel()
				BackgroundTween = nil
			end
		end
		
		if Reversing then
			if Rotation > minthresh then
				Rotation -= (Speed*RMultiplier) * Delta
			elseif Rotation <= minthresh and Rotation > min then
				-- Gradually slow down using lerp
				--print((Rotation-min)/minthresh)
				local slowDownSpeed = (Speed * RMultiplier) * ((Rotation-min)/minthresh)
				Rotation -= slowDownSpeed * Delta
			--elseif Rotation <= min then
			--	-- Gradually come to a stop using lerp
			--	local slowDownSpeed = (Speed * RMultiplier) * ((Rotation-0)/min)
			--	Rotation -= slowDownSpeed * Delta
			end
		else
			Rotation += Speed * Delta
		end
		--print(Rotation)
		Circle.Rotation = Rotation
		self.Rotation = Rotation
		if BackgroundTween == nil or BackgroundTween.PlaybackState == Enum.PlaybackState.Completed then
			--print(Reversing)
			if Reversing then
				--print("going back")
				BackgroundTween = TweenService:Create(self.Instance, RTweenInf, {Rotation = BGRotation})
				BackgroundTween:Play()
				BGRotation += 180
			else
				BackgroundTween = TweenService:Create(self.Instance, TweenInf, {Rotation = BGRotation})
				BackgroundTween:Play()
				BGRotation += 90
			end
		end
	end)
	return Loop
end

return Animations
