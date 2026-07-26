--local run = game:GetService'RunService'
--local uis = game:GetService'UserInputService'
--local cam = workspace.CurrentCamera
--local mult = 180/math.pi
--local clamp = math.clamp
--local current = Vector2.zero
--local targetX, targetY = 0, 0
--local speed = 4.5
--local sensitivity = 0.7

--local BIND_NAME = "SmoothCam"

--local function step(dt)
--	uis.MouseDeltaSensitivity = 0.01
--	local delta = uis:GetMouseDelta()*sensitivity*50
--	targetX += delta.X
--	targetY = clamp(targetY+delta.Y,-90,90)
--	current = current:Lerp(Vector2.new(-targetX,-targetY), dt*(speed*5))
--	cam.CFrame = CFrame.fromOrientation(current.Y/mult,current.X/mult,0)
--end

--local function bind()
--	run:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value-1, step)
--	--step(0.0001)
--end

--local function unbind()
--	run:UnbindFromRenderStep(BIND_NAME)
--end

--if script:GetAttribute("EnabledScript") then bind() end

--script:GetAttributeChangedSignal("EnabledScript"):Connect(function()
--	if script:GetAttribute("EnabledScript") then
--		uis:GetMouseDelta() -- discard any stale backlog delta from while unbound
--		local rx, ry = cam.CFrame:ToOrientation()
--		targetX, targetY = -ry*mult, -rx*mult
--		current = Vector2.new(-targetX, -targetY)
--		bind()
--	else
--		unbind()
--	end
--end)