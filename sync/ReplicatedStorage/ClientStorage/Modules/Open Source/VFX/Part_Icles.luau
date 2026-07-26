--[[
    Particle Tools Plugin - OPTIMIZED CORE (V2 - Baked Support)
    Copyright (C) 2025 QwinkleTee
]]

local RunService = game:GetService('RunService')
local GraphMod = require(script.Graph)
local RangeMod = require(script.Range)
local ParticlesMod = require(script.Particles)
local MeshFlipMod = require(script.Flipbook)
local pluginscript = script.Parent.Parent

local Particle = {}
Particle.Beam = {}

Particle.ActiveEmits = {}
Particle.ActiveLoops = {} -- Prevents double-emissions on Toggle
Particle.Connection = nil

local DirectionVectors = {
	[Enum.NormalId.Top] = {vector = "UpVector", multiplier = 1},
	[Enum.NormalId.Bottom] = {vector = "UpVector", multiplier = -1},
	[Enum.NormalId.Front] = {vector = "LookVector", multiplier = 1},
	[Enum.NormalId.Back] = {vector = "LookVector", multiplier = -1},
	[Enum.NormalId.Left] = {vector = "RightVector", multiplier = -1},
	[Enum.NormalId.Right] = {vector = "RightVector", multiplier = 1},
}

local shapeFunctions = {
	[Enum.ParticleEmitterShape.Box] = function(p, emitter)
		local Px = (math.random() * 2 - 1) * p.Size.X / 2
		local Py = (math.random() * 2 - 1) * p.Size.Y / 2
		local Pz = (math.random() * 2 - 1) * p.Size.Z / 2
		return Vector3.new(Px, Py, Pz), CFrame.new()
	end,
	[Enum.ParticleEmitterShape.Sphere] = function(p, emitter)
		local outerRadius = p.Size.X / 2
		local innerRadius = outerRadius * emitter.ShapePartial
		local randomRadius = (math.random() * (outerRadius^3 - innerRadius^3) + innerRadius^3)^(1/3)
		local theta = math.random() * 2 * math.pi
		local phi = math.acos((math.random() * 2) - 1)
		local direction = Vector3.new(
			math.sin(phi) * math.cos(theta),
			math.sin(phi) * math.sin(theta),
			math.cos(phi)
		)
		local localOffset = direction * randomRadius
		local localRotation = CFrame.lookAt(Vector3.new(), -direction)
		return localOffset, localRotation
	end,
	[Enum.ParticleEmitterShape.Cylinder] = function(p, emitter)
		local radius = p.Size.X / 2
		local height = p.Size.Y
		local innerRadiusRatio = emitter.ShapePartial
		local randomRadius = math.sqrt(math.random()) * (1 - innerRadiusRatio) + innerRadiusRatio
		local angle = math.random() * 2 * math.pi
		local x = randomRadius * radius * math.cos(angle)
		local y = (math.random() * 2 - 1) * (height / 2)
		local z = randomRadius * radius * math.sin(angle)
		local localOffset = Vector3.new(x, y, z)
		local direction
		if math.abs(y) > (height / 2) - 0.01 then
			direction = Vector3.new(0, math.sign(y), 0)
		else
			direction = Vector3.new(x, 0, z).Unit
		end
		local localRotation = CFrame.lookAt(Vector3.new(), -direction)
		return localOffset, localRotation
	end,
	[Enum.ParticleEmitterShape.Disc] = function(p, emitter)
		local radius = p.Size.X / 2
		local innerRadiusRatio = emitter.ShapePartial
		local randomRadiusRatio = math.sqrt(math.random()) * (1 - innerRadiusRatio) + innerRadiusRatio
		local angle = math.random() * 2 * math.pi
		local x = randomRadiusRatio * radius * math.cos(angle)
		local z = randomRadiusRatio * radius * math.sin(angle)
		local localOffset = Vector3.new(x, 0, z)
		local direction = localOffset.Unit
		local localRotation = CFrame.lookAt(Vector3.new(), -direction)
		return localOffset, localRotation
	end,
}

local function isStatic(sequence)
	return not sequence or #sequence.Keypoints <= 1
end

local function getStaticValue(sequence, defaultValue)
	if not sequence or #sequence.Keypoints == 0 then
		return defaultValue
	else
		return sequence.Keypoints[1].Value
	end
end

-- =========================================================
-- SYSTEM ACTIVATION & DEACTIVATION
-- =========================================================

function Particle:Activate()
	if self.Connection then return end

	self.Connection = RunService.Heartbeat:Connect(function(dt)
		local currentTime = os.clock()

		for i = #self.ActiveEmits, 1, -1 do
			local pData = self.ActiveEmits[i]

			local isDead = false
			if pData.Type == "Part" then
				isDead = self:UpdatePart(pData, dt, currentTime)
			elseif pData.Type == "Beam" then
				isDead = self:UpdateBeam(pData, dt, currentTime)
			end

			if isDead then
				local visualPart = pData.VisualPart
				if pData.PartLife and pData.PartLife > 0 then
					task.delay(pData.PartLife, function()
						if visualPart then visualPart:Destroy() end
					end)
				else
					if visualPart then visualPart:Destroy() end
				end
				table.remove(self.ActiveEmits, i)
			end
		end
	end)
end

function Particle:Deactivate()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function Particle:GetFolder()
	local folder = workspace.Terrain:FindFirstChild('EmittedPartsUsingPart_icle')
	if not folder then
		folder = Instance.new('Folder')
		folder.Name = "EmittedPartsUsingPart_icle"
		folder.Parent = workspace.Terrain
	end
	return folder
end

-- =========================================================
-- ABSTRACTION LAYER: BAKE / UNBAKE / GET DATA
-- =========================================================

function Particle:GetData(item)
	local data = {}
	local isBaked = item:GetAttribute("IsBaked")
	local isBeam = item:IsA("Beam")

	if isBaked then
		local baked = item:FindFirstChild("BakedFactors")
		if not baked then return nil end

		data.RenderTemplate = item:FindFirstChild("RenderTemplate")
		local tkf = baked:GetAttribute("TotalKeyFrames") or 0
		data.TotalKeyFrames = tkf > 0 and tkf or 100
		data.PartLife = baked:GetAttribute("PartLife") or 0

		data.EnabledObj = baked
		data.CheckEnabled = function() return baked.Parent ~= nil and baked:GetAttribute("Enabled") == true end
		if isBeam then
			data.GraphBlender = item:FindFirstChild("GraphBlender")
			data.Lifetime = baked:GetAttribute("BeamLifetime")
			data.Rate = baked:GetAttribute("Rate") or 10

			data.BeamProps = {
				Brightness = baked:GetAttribute("BeamBrightness"),
				CurveSize0 = baked:GetAttribute("CurveSize0"),
				CurveSize1 = baked:GetAttribute("CurveSize1"),
				Width0 = baked:GetAttribute("Width0"),
				Width1 = baked:GetAttribute("Width1"),
				LightEmission = baked:GetAttribute("LightEmission"),
				Segments = baked:GetAttribute("Segments"),
				TextureLength = baked:GetAttribute("TextureLength"),
				TextureSpeed = baked:GetAttribute("TextureSpeed")
			}
		else
			data.MeshFlipbooks = item:FindFirstChild("MeshFlipbooks")
			data.VelocityVectored = baked:GetAttribute("VelocityVectored") or false
			data.Lifetime = baked:GetAttribute("Lifetime")
			data.Rate = baked:GetAttribute("Rate") or 10

			data.Shape = Enum.ParticleEmitterShape[baked:GetAttribute("Shape")]
			data.ShapeInOut = Enum.ParticleEmitterShapeInOut[baked:GetAttribute("ShapeInOut")]
			data.ShapeStyle = Enum.ParticleEmitterShapeStyle[baked:GetAttribute("ShapeStyle")]
			data.EmissionDirection = Enum.NormalId[baked:GetAttribute("EmissionDirection")]

			-- Emulate Native Object For Math
			data.ParticleData = {
				Shape = data.Shape,
				ShapeInOut = data.ShapeInOut,
				ShapeStyle = data.ShapeStyle,
				ShapePartial = baked:GetAttribute("ShapePartial") or 0,
				EmissionDirection = data.EmissionDirection,
				SpreadAngle = baked:GetAttribute("SpreadAngle"),
				Acceleration = baked:GetAttribute("Acceleration"),
				Drag = baked:GetAttribute("Drag"),
			}

			data.Transparency = baked:GetAttribute("Transparency")
			data.Color = baked:GetAttribute("Color")
			data.Speed = baked:GetAttribute("Speed")
			data.Brightness = baked:GetAttribute("Brightness")

			data.SizeX = baked:GetAttribute("SizeX")
			data.SizeY = baked:GetAttribute("SizeY")
			data.SizeZ = baked:GetAttribute("SizeZ")

			data.RotX = baked:GetAttribute("RotX")
			data.RotY = baked:GetAttribute("RotY")
			data.RotZ = baked:GetAttribute("RotZ")

			data.RotSpeedX = baked:GetAttribute("RotSpeedX")
			data.RotSpeedY = baked:GetAttribute("RotSpeedY")
			data.RotSpeedZ = baked:GetAttribute("RotSpeedZ")
		end
	else
		local factors = item:FindFirstChild("Factors")
		if not factors then return nil end

		data.RenderTemplate = factors:FindFirstChild("RenderTemplate")
		local tkf = factors:FindFirstChild("TotalKeyFrames")
		data.TotalKeyFrames = (tkf and tkf.Value > 0) and tkf.Value or 100
		local pl = factors:FindFirstChild("PartLife")
		data.PartLife = pl and pl.Value or 0

		local en = factors:FindFirstChild("Enabled")
		data.EnabledObj = en
		data.CheckEnabled = function() return en and en.Parent ~= nil and en.Value == true end
		if isBeam then
			data.GraphBlender = factors:FindFirstChild("GraphBlender")
			local lt = factors:FindFirstChild("LifeTime")
			data.Lifetime = lt and lt.Lifetime or NumberRange.new(1)
			data.Rate = lt and lt.Rate or 10

			local props = factors:FindFirstChild("Properties")
			if props then
				data.BeamProps = {
					Brightness = props:FindFirstChild("Brightness") and props.Brightness.Size,
					CurveSize0 = props:FindFirstChild("CurveSize0") and props.CurveSize0.Size,
					CurveSize1 = props:FindFirstChild("CurveSize1") and props.CurveSize1.Size,
					Width0 = props:FindFirstChild("Width0") and props.Width0.Size,
					Width1 = props:FindFirstChild("Width1") and props.Width1.Size,
					LightEmission = props:FindFirstChild("LightEmission") and props.LightEmission.Size,
					Segments = props:FindFirstChild("Segments") and props.Segments.Size,
					TextureLength = props:FindFirstChild("TextureLength") and props.TextureLength.Size,
					TextureSpeed = props:FindFirstChild("TextureSpeed") and props.TextureSpeed.Size
				}
			end
		else
			data.MeshFlipbooks = factors:FindFirstChild("MeshFlipbooks")
			local main = factors:FindFirstChild("Main")
			local vv = factors:FindFirstChild("VelocityVectored")
			data.VelocityVectored = vv and vv.Value or false

			data.Lifetime = main.Lifetime
			data.Rate = main.Rate
			data.EmissionDirection = main.EmissionDirection

			data.ParticleData = main -- Direct reference to native properties

			data.Transparency = main.Transparency
			data.Color = main.Color
			data.Speed = main.Squash
			data.Brightness = main.Size

			local sz = factors:FindFirstChild("Size")
			data.SizeX = sz.X.Size; data.SizeY = sz.Y.Size; data.SizeZ = sz.Z.Size;

			local rot = factors:FindFirstChild("Rotation")
			data.RotX = rot.X.Rotation; data.RotY = rot.Y.Rotation; data.RotZ = rot.Z.Rotation;

			local rs = factors:FindFirstChild("RotationSpeed")
			data.RotSpeedX = rs.X.Squash; data.RotSpeedY = rs.Y.Squash; data.RotSpeedZ = rs.Z.Squash;
		end
	end
	return data
end

function Particle:Bake(item)
	-- 1. KILL GHOST LOOPS BEFORE BAKING
	if Particle.ActiveLoops[item] then 
		task.cancel(Particle.ActiveLoops[item]) 
		Particle.ActiveLoops[item] = nil 
	end

	local factors = item:FindFirstChild("Factors")
	if not factors or item:GetAttribute("IsBaked") then return end

	local baked = Instance.new("Configuration")
	baked.Name = "BakedFactors"

	-- Extract Core Base Values
	local tkf = factors:FindFirstChild("TotalKeyFrames")
	if tkf then baked:SetAttribute("TotalKeyFrames", tkf.Value) end

	local pl = factors:FindFirstChild("PartLife")
	if pl then baked:SetAttribute("PartLife", pl.Value) end

	local en = factors:FindFirstChild("Enabled")
	if en then baked:SetAttribute("Enabled", en.Value) end

	-- Safely preserve the RenderTemplate directly inside the item
	local rt = factors:FindFirstChild("RenderTemplate")
	if rt then rt.Parent = item end

	if item:IsA("Beam") then
		-- Safely preserve GraphBlender for Beams
		local gb = factors:FindFirstChild("GraphBlender")
		if gb then gb.Parent = item end

		local lt = factors:FindFirstChild("LifeTime")
		if lt then
			baked:SetAttribute("BeamLifetime", lt.Lifetime)
			baked:SetAttribute("Rate", lt.Rate)
		end

		local props = factors:FindFirstChild("Properties")
		if props then
			if props:FindFirstChild("Brightness") then baked:SetAttribute("BeamBrightness", props.Brightness.Size) end
			if props:FindFirstChild("CurveSize0") then baked:SetAttribute("CurveSize0", props.CurveSize0.Size) end
			if props:FindFirstChild("CurveSize1") then baked:SetAttribute("CurveSize1", props.CurveSize1.Size) end
			if props:FindFirstChild("Width0") then baked:SetAttribute("Width0", props.Width0.Size) end
			if props:FindFirstChild("Width1") then baked:SetAttribute("Width1", props.Width1.Size) end
			if props:FindFirstChild("LightEmission") then baked:SetAttribute("LightEmission", props.LightEmission.Size) end
			if props:FindFirstChild("Segments") then baked:SetAttribute("Segments", props.Segments.Size) end
			if props:FindFirstChild("TextureLength") then baked:SetAttribute("TextureLength", props.TextureLength.Size) end
			if props:FindFirstChild("TextureSpeed") then baked:SetAttribute("TextureSpeed", props.TextureSpeed.Size) end
		end
	else
		-- Safely preserve MeshFlipbooks for standard Parts
		local mb = factors:FindFirstChild("MeshFlipbooks")
		if mb then mb.Parent = item end

		local main = factors:FindFirstChild("Main")
		if main then
			baked:SetAttribute("Lifetime", main.Lifetime)
			baked:SetAttribute("Rate", main.Rate)
			baked:SetAttribute("SpreadAngle", main.SpreadAngle)
			baked:SetAttribute("Acceleration", main.Acceleration)
			baked:SetAttribute("Drag", main.Drag)
			baked:SetAttribute("Transparency", main.Transparency)
			baked:SetAttribute("Color", main.Color)
			baked:SetAttribute("Speed", main.Squash)
			baked:SetAttribute("Brightness", main.Size)

			-- Enums need to be saved as strings
			if main.Shape then baked:SetAttribute("Shape", main.Shape.Name) end
			if main.ShapeInOut then baked:SetAttribute("ShapeInOut", main.ShapeInOut.Name) end
			if main.ShapeStyle then baked:SetAttribute("ShapeStyle", main.ShapeStyle.Name) end
			if main.ShapePartial then baked:SetAttribute("ShapePartial", main.ShapePartial)end
			if main.EmissionDirection then baked:SetAttribute("EmissionDirection", main.EmissionDirection.Name) end
		end

		local vv = factors:FindFirstChild("VelocityVectored")
		if vv then baked:SetAttribute("VelocityVectored", vv.Value) end

		local sz = factors:FindFirstChild("Size")
		if sz then
			if sz:FindFirstChild("X") then baked:SetAttribute("SizeX", sz.X.Size) end
			if sz:FindFirstChild("Y") then baked:SetAttribute("SizeY", sz.Y.Size) end
			if sz:FindFirstChild("Z") then baked:SetAttribute("SizeZ", sz.Z.Size) end
		end

		local rot = factors:FindFirstChild("Rotation")
		if rot then
			if rot:FindFirstChild("X") then baked:SetAttribute("RotX", rot.X.Rotation) end
			if rot:FindFirstChild("Y") then baked:SetAttribute("RotY", rot.Y.Rotation) end
			if rot:FindFirstChild("Z") then baked:SetAttribute("RotZ", rot.Z.Rotation) end
		end

		local rs = factors:FindFirstChild("RotationSpeed")
		if rs then
			if rs:FindFirstChild("X") then baked:SetAttribute("RotSpeedX", rs.X.Squash) end
			if rs:FindFirstChild("Y") then baked:SetAttribute("RotSpeedY", rs.Y.Squash) end
			if rs:FindFirstChild("Z") then baked:SetAttribute("RotSpeedZ", rs.Z.Squash) end
		end
	end

	-- Finalize Transformation
	baked.Parent = item
	factors:Destroy()
	item:SetAttribute("IsBaked", true)
end

function Particle:Unbake(item)
	if Particle.ActiveLoops[item] then task.cancel(Particle.ActiveLoops[item]); Particle.ActiveLoops[item] = nil end
	local baked = item:FindFirstChild("BakedFactors")
	if not baked then return end

	local layoutSource = item:IsA("Beam") and pluginscript.Layouts.Beam.Factors or pluginscript.Layouts.Part.Factors
	local newFactors = layoutSource:Clone()

	-- Extract Common Values
	local tkf = newFactors:FindFirstChild("TotalKeyFrames")
	if tkf then tkf.Value = baked:GetAttribute("TotalKeyFrames") or 100 end

	local pl = newFactors:FindFirstChild("PartLife")
	if pl then pl.Value = baked:GetAttribute("PartLife") or 0 end

	local en = newFactors:FindFirstChild("Enabled")
	if en then en.Value = baked:GetAttribute("Enabled") or false end

	local rt = item:FindFirstChild("RenderTemplate")
	if rt then rt.Parent = newFactors end

	if item:IsA("Beam") then
		-- THE FIX: Destroy the cloned default GraphBlender before moving the saved one!
		local gb = item:FindFirstChild("GraphBlender")
		if gb then 
			local defaultGb = newFactors:FindFirstChild("GraphBlender")
			if defaultGb then defaultGb:Destroy() end
			gb.Parent = newFactors 
		end

		local lt = newFactors:FindFirstChild("LifeTime")
		if lt then
			lt.Lifetime = baked:GetAttribute("BeamLifetime") or lt.Lifetime
			lt.Rate = baked:GetAttribute("Rate") or lt.Rate
		end

		local props = newFactors:FindFirstChild("Properties")
		if props then
			if props:FindFirstChild("Brightness") and baked:GetAttribute("BeamBrightness") then props.Brightness.Size = baked:GetAttribute("BeamBrightness") end
			if props:FindFirstChild("CurveSize0") and baked:GetAttribute("CurveSize0") then props.CurveSize0.Size = baked:GetAttribute("CurveSize0") end
			if props:FindFirstChild("CurveSize1") and baked:GetAttribute("CurveSize1") then props.CurveSize1.Size = baked:GetAttribute("CurveSize1") end
			if props:FindFirstChild("Width0") and baked:GetAttribute("Width0") then props.Width0.Size = baked:GetAttribute("Width0") end
			if props:FindFirstChild("Width1") and baked:GetAttribute("Width1") then props.Width1.Size = baked:GetAttribute("Width1") end
			if props:FindFirstChild("LightEmission") and baked:GetAttribute("LightEmission") then props.LightEmission.Size = baked:GetAttribute("LightEmission") end
			if props:FindFirstChild("Segments") and baked:GetAttribute("Segments") then props.Segments.Size = baked:GetAttribute("Segments") end
			if props:FindFirstChild("TextureLength") and baked:GetAttribute("TextureLength") then props.TextureLength.Size = baked:GetAttribute("TextureLength") end
			if props:FindFirstChild("TextureSpeed") and baked:GetAttribute("TextureSpeed") then props.TextureSpeed.Size = baked:GetAttribute("TextureSpeed") end
		end
	else
		-- THE FIX: Do the same for MeshFlipbooks on normal parts!
		local mb = item:FindFirstChild("MeshFlipbooks")
		if mb then 
			local defaultMb = newFactors:FindFirstChild("MeshFlipbooks")
			if defaultMb then defaultMb:Destroy() end
			mb.Parent = newFactors 
		end

		local main = newFactors:FindFirstChild("Main")
		if main then
			main.Lifetime = baked:GetAttribute("Lifetime") or main.Lifetime
			main.Rate = baked:GetAttribute("Rate") or main.Rate
			main.SpreadAngle = baked:GetAttribute("SpreadAngle") or main.SpreadAngle
			main.Acceleration = baked:GetAttribute("Acceleration") or main.Acceleration
			main.Drag = baked:GetAttribute("Drag") or main.Drag
			main.Transparency = baked:GetAttribute("Transparency") or main.Transparency
			main.Color = baked:GetAttribute("Color") or main.Color
			main.Squash = baked:GetAttribute("Speed") or main.Squash
			main.Size = baked:GetAttribute("Brightness") or main.Size

			if baked:GetAttribute("Shape") then main.Shape = Enum.ParticleEmitterShape[baked:GetAttribute("Shape")] end
			if baked:GetAttribute("ShapeInOut") then main.ShapeInOut = Enum.ParticleEmitterShapeInOut[baked:GetAttribute("ShapeInOut")] end
			if baked:GetAttribute("ShapeStyle") then main.ShapeStyle = Enum.ParticleEmitterShapeStyle[baked:GetAttribute("ShapeStyle")] end
			if baked:GetAttribute("ShapePartial") then main.ShapePartial = baked:GetAttribute("ShapePartial") end
			if baked:GetAttribute("EmissionDirection") then main.EmissionDirection = Enum.NormalId[baked:GetAttribute("EmissionDirection")] end
		end

		local vv = newFactors:FindFirstChild("VelocityVectored")
		if vv then vv.Value = baked:GetAttribute("VelocityVectored") or false end

		local sz = newFactors:FindFirstChild("Size")
		if sz then
			if sz:FindFirstChild("X") and baked:GetAttribute("SizeX") then sz.X.Size = baked:GetAttribute("SizeX") end
			if sz:FindFirstChild("Y") and baked:GetAttribute("SizeY") then sz.Y.Size = baked:GetAttribute("SizeY") end
			if sz:FindFirstChild("Z") and baked:GetAttribute("SizeZ") then sz.Z.Size = baked:GetAttribute("SizeZ") end
		end

		local rot = newFactors:FindFirstChild("Rotation")
		if rot then
			if rot:FindFirstChild("X") and baked:GetAttribute("RotX") then rot.X.Rotation = baked:GetAttribute("RotX") end
			if rot:FindFirstChild("Y") and baked:GetAttribute("RotY") then rot.Y.Rotation = baked:GetAttribute("RotY") end
			if rot:FindFirstChild("Z") and baked:GetAttribute("RotZ") then rot.Z.Rotation = baked:GetAttribute("RotZ") end
		end

		local rs = newFactors:FindFirstChild("RotationSpeed")
		if rs then
			if rs:FindFirstChild("X") and baked:GetAttribute("RotSpeedX") then rs.X.Squash = baked:GetAttribute("RotSpeedX") end
			if rs:FindFirstChild("Y") and baked:GetAttribute("RotSpeedY") then rs.Y.Squash = baked:GetAttribute("RotSpeedY") end
			if rs:FindFirstChild("Z") and baked:GetAttribute("RotSpeedZ") then rs.Z.Squash = baked:GetAttribute("RotSpeedZ") end
		end
	end

	newFactors.Parent = item
	baked:Destroy()
	item:SetAttribute("IsBaked", nil)
end

function Particle:Transform(part)
	local layoutSource = part:IsA('Beam') and pluginscript.Layouts.Beam.Factors or pluginscript.Layouts.Part.Factors
	local PartLayout = layoutSource:Clone()
	PartLayout.Parent = part

	local renderTemplate = part:Clone()
	renderTemplate.Name = "RenderTemplate"

	for _, child in renderTemplate:GetChildren() do
		-- THE FIX: Spare nested Part-Icles and Attachments (which Beams rely on)
		if child:GetAttribute("Transformed") or child:IsA("Attachment") then
			continue
		end

		if not child:IsA("SpecialMesh") and not child:IsA("Decal") and not child:IsA("Texture") then
			child:Destroy()
		end
	end

	for attrName, _ in pairs(renderTemplate:GetAttributes()) do
		renderTemplate:SetAttribute(attrName, nil)
	end

	if renderTemplate:IsA("BasePart") then
		renderTemplate.Anchored = true; renderTemplate.CanCollide = false; renderTemplate.CanQuery = false;
		renderTemplate.CanTouch = false; renderTemplate.CastShadow = false; renderTemplate.Massless = true
	end

	-- FEATURE FIX: Disable Beams instantly so they don't visually clutter the screen
	if part:IsA("Beam") then
		part.Enabled = false
		if renderTemplate:IsA("Beam") then renderTemplate.Enabled = false end
	end

	renderTemplate.Parent = PartLayout

	if part:IsA("Beam") then
		local props = PartLayout:FindFirstChild("Properties")
		if props then
			local function mapProp(name, val)
				local obj = props:FindFirstChild(name)
				if obj and typeof(val) == "number" then obj.Size = NumberSequence.new(val) end
			end
			mapProp("Brightness", part.Brightness)
			mapProp("CurveSize0", part.CurveSize0)
			mapProp("CurveSize1", part.CurveSize1)
			mapProp("Width0", part.Width0)
			mapProp("Width1", part.Width1)
			mapProp("LightEmission", part.LightEmission)
			mapProp("Segments", part.Segments)
			mapProp("TextureLength", part.TextureLength)
			mapProp("TextureSpeed", part.TextureSpeed)
		end

		local gb = PartLayout:FindFirstChild("GraphBlender")
		if gb then
			local cg = gb:FindFirstChild("ColorGraphs")
			if cg then
				local first = cg:FindFirstChild("1") or cg:FindFirstChildWhichIsA("Folder")
				if first and first:FindFirstChild("Color") then first.Color.Color = part.Color end
			end

			local tg = gb:FindFirstChild("TransparencyGraphs")
			if tg then
				local first = tg:FindFirstChild("1") or tg:FindFirstChildWhichIsA("Folder")
				if first and first:FindFirstChild("Transparency") then first.Transparency.Transparency = part.Transparency end
			end
		end
	end

	part:SetAttribute('Transformed', true)
	part:SetAttribute('EmitCount', part:IsA('Beam') and 1 or 0)
	part:SetAttribute('EmitDuration', 0)
	part:SetAttribute('EmitDelay', 0)
	part:SetAttribute('IsEmitter', true)
end

-- =========================================================
-- UPDATE LOGIC (ECS LOOP)
-- =========================================================

function Particle:UpdatePart(pData, dt, currentTime)
	local elapsedTime = currentTime - pData.StartTime
	local i = elapsedTime / pData.LifeTime

	if i >= 1 then return true end 

	pData.AccumulatedDT += dt
	local targetStep = math.floor(i * pData.TotalKeyFrames)

	if targetStep > pData.CurrentStep then
		pData.CurrentStep = targetStep
		local steppedI = pData.CurrentStep / pData.TotalKeyFrames

		local stepDT = pData.AccumulatedDT
		pData.AccumulatedDT = 0

		local sizex = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.SizeX, pData.Seeds.SizeX)
		local sizey = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.SizeY, pData.Seeds.SizeY)
		local sizez = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.SizeZ, pData.Seeds.SizeZ)
		local rotSpeedX = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.RotSpeedX, pData.Seeds.RotSpeedX)
		local rotSpeedY = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.RotSpeedY, pData.Seeds.RotSpeedY)
		local rotSpeedZ = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.RotSpeedZ, pData.Seeds.RotSpeedZ)
		local speed = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.Speed, pData.Seeds.Speed)
		local brightness = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.Brightness, pData.Seeds.Brightness)
		local transparency = GraphMod.QueryPointsWithTime(steppedI, pData.Graphs.Transparency, pData.Seeds.Transparency)
		local color = GraphMod.QueryColorPointWithTime(steppedI, pData.Graphs.Color)

		local accelerationOffset = pData.Acceleration * steppedI
		local draggedSpeed = speed * math.exp(-pData.Drag * steppedI)

		local newPosition = pData.CurrentPosition 
			+ (pData.BaseDirection * draggedSpeed * (stepDT * 10)) 
			+ (accelerationOffset * (stepDT * 10))

		local worldDelta = newPosition - pData.CurrentPosition
		local parentCF_now = pData.Link and pData.Link.CFrame or CFrame.new()
		local parentLocalDelta = parentCF_now:VectorToObjectSpace(worldDelta)

		pData.LocalCF = CFrame.new(parentLocalDelta) * pData.LocalCF
		local rotationCFrame = CFrame.Angles(math.rad(rotSpeedX), math.rad(rotSpeedY), math.rad(rotSpeedZ))

		pData.VisualPart.CFrame = (parentCF_now * pData.LocalCF) * rotationCFrame
		pData.CurrentPosition = pData.VisualPart.Position

		local sizeVec = Vector3.new(sizex, sizey, sizez)
		if pData.SpecialMesh then
			pData.SpecialMesh.Scale = sizeVec
		else
			pData.VisualPart.Size = sizeVec
		end

		if pData.Decal then
			pData.Decal.Transparency = transparency
			pData.Decal.Color3 = Color3.fromRGB(color.R * 255 * brightness, color.G * 255 * brightness, color.B * 255 * brightness)
		else
			pData.VisualPart.Transparency = transparency
			pData.VisualPart.Color = color
		end

		if pData.VelocityVectored then
			local rotatedCF = pData.VisualPart.CFrame * pData.SpreadRotation
			local dirInfo = DirectionVectors[pData.EmissionDirection] or DirectionVectors[Enum.NormalId.Top]
			pData.BaseDirection = rotatedCF[dirInfo.vector] * dirInfo.multiplier
		end
	end

	return false 
end

function Particle:UpdateBeam(pData, dt, currentTime)
	local elapsedTime = currentTime - pData.StartTime
	local i = elapsedTime / pData.LifeTime

	if i >= 1 or not pData.VisualPart.Parent then return true end

	local targetStep = math.floor(i * pData.TotalKeyFrames)

	if targetStep > pData.CurrentStep then
		pData.CurrentStep = targetStep
		local steppedI = pData.CurrentStep / pData.TotalKeyFrames

		if pData.CurrentTransGraph and pData.CurrentTransGraph:FindFirstChild("DurationOfBlend") then
			local dur = pData.CurrentTransGraph.DurationOfBlend.Value
			if elapsedTime > pData.TransBlendStartTime + dur then
				if pData.TransparencyKgs[pData.TransIndex + 1] then
					pData.TransBlendStartTime += dur
					pData.TransIndex += 1
					pData.CurrentTransGraph = pData.TransparencyKgs[pData.TransIndex]
				end
			end
		end

		if pData.CurrentColorGraph and pData.CurrentColorGraph:FindFirstChild("DurationOfBlend") then
			local dur = pData.CurrentColorGraph.DurationOfBlend.Value
			if elapsedTime > pData.ColorBlendStartTime + dur then
				if pData.ColorKgs[pData.ColorIndex + 1] then
					pData.ColorBlendStartTime += dur
					pData.ColorIndex += 1
					pData.CurrentColorGraph = pData.ColorKgs[pData.ColorIndex]
				end
			end
		end

		if pData.CurrentTransGraph then
			local transNode = pData.CurrentTransGraph:FindFirstChild("Transparency")
			local speedNode = pData.CurrentTransGraph:FindFirstChild("BlendSpeed")

			if transNode and speedNode then
				pData.VisualPart.Transparency = GraphMod.BlendGraphWithTime(pData.VisualPart.Transparency, transNode.Transparency, speedNode.Transparency, steppedI)
			end
		end

		if pData.CurrentColorGraph then
			local colorNode = pData.CurrentColorGraph:FindFirstChild("Color")
			local speedNode = pData.CurrentColorGraph:FindFirstChild("BlendSpeed")

			if colorNode and speedNode then
				pData.VisualPart.Color = GraphMod.BlendColorGraphWithTime(pData.VisualPart.Color, colorNode.Color, speedNode.Transparency, steppedI)
			end
		end

		for name, animData in pairs(pData.AnimatedProps) do
			pData.VisualPart[name] = GraphMod.QueryPointsWithTime(steppedI, animData.Sequence, animData.Seed)
		end
	end

	return false
end

-- =========================================================
-- EMISSION LOGIC
-- =========================================================

function Particle:Emit(item, link)
	if item:IsA("Beam") then
		self:EmitBeam(item, link)
	else
		self:EmitPart(item, link)
	end
end

function Particle:EmitPart(part, link)
	local data = self:GetData(part)
	if not data or not data.RenderTemplate then return end

	local Time = RangeMod.RandomValueFromRange(data.Lifetime)

	-- =======================================================
	-- STEP 1: CALCULATE SHAPE OFFSET MATH FIRST
	-- =======================================================
	local unrotatedCF = part.CFrame
	local dirInfo = DirectionVectors[data.EmissionDirection] or DirectionVectors[Enum.NormalId.Top]
	local rawWorldDirection = unrotatedCF[dirInfo.vector] * dirInfo.multiplier

	local shapeFunc = shapeFunctions[data.ParticleData.Shape]
	local localOffset = Vector3.new()
	local localRotation = CFrame.new()

	if shapeFunc and data.ParticleData.ShapeInOut == Enum.ParticleEmitterShapeInOut.InAndOut then
		localOffset, localRotation = shapeFunc(part, data.ParticleData)
	end

	local initialCF = unrotatedCF
	if typeof(localRotation) == "CFrame" and data.ParticleData.ShapeStyle == Enum.ParticleEmitterShapeStyle.Surface then
		local rx, ry, rz = initialCF:ToEulerAnglesXYZ()
		initialCF = CFrame.new((initialCF * CFrame.new(localOffset)).Position) * localRotation * CFrame.Angles(rx, ry, rz)
	else
		initialCF = CFrame.new((initialCF * CFrame.new(localOffset)).Position) * initialCF.Rotation
	end

	-- STEP 2: Apply Random Initial Rotation
	local RX = RangeMod.RandomValueFromRange(data.RotX)
	local RY = RangeMod.RandomValueFromRange(data.RotY)
	local RZ = RangeMod.RandomValueFromRange(data.RotZ)
	initialCF = initialCF * CFrame.Angles(math.rad(RX), math.rad(RY), math.rad(RZ))

	-- STEP 3: Base Direction calculation
	local baseDirection
	if data.VelocityVectored then
		baseDirection = initialCF[dirInfo.vector] * dirInfo.multiplier
	else
		baseDirection = rawWorldDirection
	end

	-- STEP 4: Spread Math
	local randomX, randomY = 0, 0
	if data.ParticleData.SpreadAngle.X > 0 or data.ParticleData.SpreadAngle.Y > 0 then
		randomX = (math.random() * 2 - 1) * data.ParticleData.SpreadAngle.X
		randomY = (math.random() * 2 - 1) * data.ParticleData.SpreadAngle.Y
	end
	local spreadRotation = CFrame.Angles(math.rad(randomX), math.rad(randomY), 0)

	local cf = CFrame.lookAt(Vector3.new(), baseDirection)
	cf = cf * spreadRotation
	baseDirection = cf.LookVector

	-- =======================================================
	-- STEP 5: SPAWN & INITIALIZE BEFORE NATIVE EFFECTS & PARENTING
	-- =======================================================
	local visualPart = data.RenderTemplate:Clone()
	local parentCF_now = link and link.CFrame or CFrame.new()
	local localCF = link and link.CFrame:ToObjectSpace(initialCF) or initialCF
	visualPart.CFrame = parentCF_now * localCF

	local pData = {
		Type = "Part",
		VisualPart = visualPart,
		Link = link,
		SpecialMesh = visualPart:FindFirstChildOfClass('SpecialMesh'),
		Decal = visualPart:FindFirstChildOfClass('Decal'),

		StartTime = os.clock(),
		TotalKeyFrames = data.TotalKeyFrames,
		CurrentStep = 0,
		AccumulatedDT = 0,
		LifeTime = Time,
		PartLife = data.PartLife,
		CurrentPosition = initialCF.Position,
		LocalCF = localCF,

		BaseDirection = baseDirection,
		EmissionDirection = data.EmissionDirection,
		SpreadRotation = spreadRotation,
		Acceleration = data.ParticleData.Acceleration,
		Drag = data.ParticleData.Drag,
		VelocityVectored = data.VelocityVectored,

		Graphs = {
			SizeX = data.SizeX, SizeY = data.SizeY, SizeZ = data.SizeZ,
			RotSpeedX = data.RotSpeedX, RotSpeedY = data.RotSpeedY, RotSpeedZ = data.RotSpeedZ,
			Speed = data.Speed, Brightness = data.Brightness,
			Transparency = data.Transparency, Color = data.Color
		},

		Seeds = {
			SizeX = GraphMod.GenerateSeed(data.SizeX), SizeY = GraphMod.GenerateSeed(data.SizeY), SizeZ = GraphMod.GenerateSeed(data.SizeZ),
			RotSpeedX = GraphMod.GenerateSeed(data.RotSpeedX), RotSpeedY = GraphMod.GenerateSeed(data.RotSpeedY), RotSpeedZ = GraphMod.GenerateSeed(data.RotSpeedZ),
			Speed = GraphMod.GenerateSeed(data.Speed), Brightness = GraphMod.GenerateSeed(data.Brightness),
			Transparency = GraphMod.GenerateSeed(data.Transparency)
		}
	}

	-- FIX: The 1-Frame Pop Prevention
	local startSize = Vector3.new(
		GraphMod.QueryPointsWithTime(0, pData.Graphs.SizeX, pData.Seeds.SizeX),
		GraphMod.QueryPointsWithTime(0, pData.Graphs.SizeY, pData.Seeds.SizeY),
		GraphMod.QueryPointsWithTime(0, pData.Graphs.SizeZ, pData.Seeds.SizeZ)
	)
	local startTrans = GraphMod.QueryPointsWithTime(0, pData.Graphs.Transparency, pData.Seeds.Transparency)
	local startColor = GraphMod.QueryColorPointWithTime(0, pData.Graphs.Color)
	local startBright = GraphMod.QueryPointsWithTime(0, pData.Graphs.Brightness, pData.Seeds.Brightness)

	if pData.SpecialMesh then
		pData.SpecialMesh.Scale = startSize
	else
		pData.VisualPart.Size = startSize
	end

	if pData.Decal then
		pData.Decal.Transparency = startTrans
		pData.Decal.Color3 = Color3.fromRGB(startColor.R * 255 * startBright, startColor.G * 255 * startBright, startColor.B * 255 * startBright)
	else
		pData.VisualPart.Transparency = startTrans
		pData.VisualPart.Color = startColor
	end

	-- NOW PARENT AFTER ALL VISUALS ARE SET
	visualPart.Parent = self:GetFolder()

	for _, desc in visualPart:GetDescendants() do
		if desc:IsA("ParticleEmitter") then desc.Enabled = false end
	end
	for _, child in visualPart:GetChildren() do
		if child:IsA("Attachment") then ParticlesMod.EnableEmitChildrenAndRepeatForAttachments(child) end
		ParticlesMod.EnableEmitSingle(child)
	end

	table.insert(self.ActiveEmits, pData)

	if pData.Decal and data.MeshFlipbooks then
		MeshFlipMod.Flip(data.ParticleData, data.MeshFlipbooks, pData.Decal, Time)
	end

	for _, child in visualPart:GetChildren() do
		if child:GetAttribute("Transformed") then
			self:EnableEmit(child, visualPart)
		end
	end
end

function Particle:EmitBeam(beam, link)
	local data = self:GetData(beam)
	if not data or not data.RenderTemplate then return end

	local visualBeam = data.RenderTemplate:Clone()
	visualBeam.Enabled = true
	visualBeam.Parent = self:GetFolder()

	local animatedProps = {}
	for name, sequence in pairs(data.BeamProps) do
		if sequence then
			if isStatic(sequence) then
				visualBeam[name] = getStaticValue(sequence, visualBeam[name])
			else
				animatedProps[name] = { Sequence = sequence, Seed = GraphMod.GenerateSeed(sequence) }
			end
		end
	end

	local ColorKgs, TransparencyKgs = {}, {}
	if data.GraphBlender then
		local ColorGraphs = data.GraphBlender:FindFirstChild('ColorGraphs')
		local TransparencyGraphs = data.GraphBlender:FindFirstChild('TransparencyGraphs')

		if TransparencyGraphs then for _, v in pairs(TransparencyGraphs:GetChildren()) do table.insert(TransparencyKgs, v) end end
		if ColorGraphs then for _, v in pairs(ColorGraphs:GetChildren()) do table.insert(ColorKgs, v) end end

		-- SAFE SORT: Won't crash if folder name contains letters
		local function safeSort(a, b)
			local numA = tonumber(string.match(a.Name, "%d+")) or 0
			local numB = tonumber(string.match(b.Name, "%d+")) or 0
			if numA == numB then return a.Name < b.Name end
			return numA < numB
		end

		table.sort(TransparencyKgs, safeSort)
		table.sort(ColorKgs, safeSort)
	end

	local safeLifeTime = RangeMod.RandomValueFromRange(data.Lifetime)
	if safeLifeTime <= 0 then safeLifeTime = 0.001 end

	local pData = {
		Type = "Beam",
		VisualPart = visualBeam,
		Link = link,
		StartTime = os.clock(),
		TotalKeyFrames = data.TotalKeyFrames,
		CurrentStep = 0,
		LifeTime = safeLifeTime,
		PartLife = 0,

		AnimatedProps = animatedProps,

		ColorKgs = ColorKgs, TransparencyKgs = TransparencyKgs,
		ColorIndex = 1, TransIndex = 1,
		CurrentColorGraph = ColorKgs[1], CurrentTransGraph = TransparencyKgs[1],
		ColorBlendStartTime = 0, TransBlendStartTime = 0,
	}

	table.insert(self.ActiveEmits, pData)
end
-- =========================================================
-- SCHEDULING & RECURSION
-- =========================================================

function Particle:Enable(item, link, duration)
	local data = self:GetData(item)
	if not data then return end

	local loopDuration = duration or math.huge

	-- 1. CACHE THE RATE OBJECT OUTSIDE THE LOOP (Fixes performance drain)
	local rateObj = nil
	local isBaked = item:GetAttribute("IsBaked")

	if isBaked then
		rateObj = item:FindFirstChild("BakedFactors")
	else
		local factors = item:FindFirstChild("Factors")
		if factors then
			rateObj = item:IsA("Beam") and factors:FindFirstChild("LifeTime") or factors:FindFirstChild("Main")
		end
	end

	-- ANTI-STACKING GUARD
	if Particle.ActiveLoops[item] then task.cancel(Particle.ActiveLoops[item]) end

	Particle.ActiveLoops[item] = task.spawn(function()
		local startTime = os.clock()
		while true do
			-- 2. SAFETY KILL-SWITCH: Stops memory leaks if the part is Destroyed!
			if not item or not item.Parent then 
				Particle.ActiveLoops[item] = nil
				break
			end

			-- BREAKS IF: Time runs out OR the particle is manually toggled off!
			if (os.clock() - startTime >= loopDuration) or not data.CheckEnabled() then 
				Particle.ActiveLoops[item] = nil
				break 
			end

			self:Emit(item, link)

			-- 3. FAST DYNAMIC RATE: Reads the property of the cached object instantly
			local currentRate = 10
			if rateObj then
				currentRate = isBaked and rateObj:GetAttribute("Rate") or rateObj.Rate
			end

			if currentRate <= 0 then currentRate = 1 end
			task.wait(1 / currentRate)
		end
	end)
end

function Particle:EnableEmit(item, link)
	local emitCount = item:GetAttribute('EmitCount') or 1
	local emitDelay = item:GetAttribute('EmitDelay') or 0
	local emitDuration = item:GetAttribute('EmitDuration') or 0

	local data = self:GetData(item)

	local function doEmit()
		-- 1. Burst Emits
		for i = 1, emitCount do self:Emit(item, link) end

		-- 2. Continuous Loop
		if emitDuration > 0 then
			-- Safely set Enabled to true based on whether it's baked or unbaked
			if data and data.EnabledObj then
				if data.EnabledObj:IsA("BoolValue") then 
					data.EnabledObj.Value = true 
				elseif data.EnabledObj:IsA("Configuration") then 
					data.EnabledObj:SetAttribute("Enabled", true) -- Fixed target!
				end
			end

			self:Enable(item, link, emitDuration)

			-- Safely flip it back to false when duration ends
			task.delay(emitDuration, function()
				if data and data.EnabledObj then
					if data.EnabledObj:IsA("BoolValue") then 
						data.EnabledObj.Value = false 
					elseif data.EnabledObj:IsA("Configuration") then 
						data.EnabledObj:SetAttribute("Enabled", false) -- Fixed target!
					end
				end
			end)
		end
	end

	if emitDelay > 0 then
		task.delay(emitDelay, doEmit)
	else
		doEmit()
	end
end
function Particle:AbsoluteEmit(item)
	if item:GetAttribute("Transformed") then
		self:EnableEmit(item, nil)
		return
	end

	if item:IsA("BasePart") then ParticlesMod.EnableEmit(item) end

	for _, child in item:GetChildren() do
		if item:IsA("BasePart") and child:IsA("BasePart") and not child:GetAttribute("Transformed") then
			continue
		end
		self:AbsoluteEmit(child)
	end
end

return Particle