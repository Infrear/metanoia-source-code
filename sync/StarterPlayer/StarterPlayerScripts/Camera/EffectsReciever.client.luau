-- Services
local RPS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local DBS = game:GetService("Debris")

-- Constants
local MAXIMUM_EXTRA_PLACES = 1

local MAX_DIST_FOR_HIGHLIGHT = 125
local MAX_HIGHLIGHTS = 20

local Colors = {
	High = Color3.new(1, 0.745098, 0.627451),
	Base = Color3.new(1, 0.666667, 0),
	Low = Color3.new(0.560784, 0.372549, 0)
	--	High = Color3.new(1, 0.360784, 0.603922),
	--	Base = Color3.new(1, 0, 0.235294),
	--	Low = Color3.new(0.392157, 0, 0.105882)
}

local effectCooldown = 0.1

-- Dependancies
local Storage = RPS:WaitForChild("ClientStorage")
local Trash = RPS:WaitForChild("ClientTrash")
local damageTypes = require(Storage.Info.DamageTypes)
local effectEv = Storage.Events.Remotes:WaitForChild("EffectRequest")
local hideObjEv = Storage.Events.Remotes:WaitForChild("HideObj")

local plr = game.Players.LocalPlayer
repeat wait() until plr.Character ~= nil
local char = plr.Character
local hum = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local TIS = {
	[1] = TweenInfo.new(
		0.375,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[2] = TweenInfo.new( --> unused rn, (nvm)
		2,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[3] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[4] = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	),
	[5] = TweenInfo.new(
		0.25,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	),
	[6] = TweenInfo.new(
		0.35,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	),
}

-- Local Variables
local modelVals = {}
local hls = {}
for i = 1, 100 do
	local highlight = Instance.new("Highlight", workspace:WaitForChild("TEMPORARY"):WaitForChild("Usables"):WaitForChild("armor"):WaitForChild("boleite armor"))
	hls[highlight] = workspace:WaitForChild("TEMPORARY"):WaitForChild("Usables"):WaitForChild("armor"):WaitForChild("boleite armor"):GetPivot().Position
end

-- Local Functions
local function coundDict(dict)
	local c = 0
	for i, v in pairs(dict) do
		c += 1
	end
	return c
end

local function checkHighlights(hlPos)
	local canMake = true
	local dist = (char:GetPivot().Position - hlPos).Magnitude
	
	if dist <= MAX_DIST_FOR_HIGHLIGHT then
		if coundDict(hls) >= MAX_HIGHLIGHTS then
			local bads = {}
			
			for i, v in pairs(hls) do
				local dist2 = (char:GetPivot().Position - hlPos).Magnitude
				if dist2 >= dist then
					table.insert(bads, i)
				end
			end
			
			if #bads > 0 then
				for i, v in pairs(bads) do
					v:Destroy()
					hls[v] = nil
				end
				if coundDict(hls) >= MAX_HIGHLIGHTS then
					canMake = false
				end
			else
				canMake = false
			end
		end
	else
		canMake = false
	end
	
	return canMake
end

local function spawnHighlight(obj, otherValues, temp)
	if not obj then return end
	
	local pos = nil
	
	if obj:IsA("Model") then
		pos = obj:GetPivot().Position
	elseif obj:IsA("BasePart") then
		pos = obj.CFrame.Position
	else
		return
	end

	if not checkHighlights(pos) then return end

	local highlight = Instance.new("Highlight")
	hls[highlight] = pos
	
	highlight.Destroying:Connect(function()
		hls[highlight] = nil
	end)
	
	for i, v in pairs(otherValues) do
		local success = pcall(function() 
			local t = highlight[i] 
		end) 

		if success then
			highlight[i] = v
		end
	end

	if obj then
		--highlight.Parent = obj
		highlight.Adornee = obj
	end

	highlight.Parent = workspace.PARTICLES

	if temp then
		DBS:AddItem(highlight, 10)
	end

	return highlight
end

local function rizzUpB(build, dmg, me, dcf)
	local model = build
	local mVals = modelVals[model]
	local blood = false
	local highlight = true

	if not mVals then
		modelVals[model] = {
			TE1 = nil, 
			TE2 = nil,
			hl = nil,
			canEffect = true,
			addUp = 0
		}
		mVals = modelVals[model]
	end
	--print(dmg)
	if mVals.canEffect then
		--print("ok")
		mVals.canEffect = false
		local amt = mVals.addUp
		mVals.addUp = 0
		if blood then
			coroutine.wrap(function()
				local clones = {}
				local effects = Storage.Effects.Combat.Gore:GetChildren()
				for i, v in pairs(effects) do
					clones[v.Name] = v:Clone()
					clones[v.Name].Parent = model.PrimaryPart or model
					if clones[v.Name]:IsA("ParticleEmitter") then
						clones[v.Name]:Emit(5)
					end
					for i, v in pairs(clones[v.Name]:GetChildren()) do
						if v:IsA("ParticleEmitter") then
							v:Emit(5)
						end
					end
				end


				task.wait(2)
				for i, v in pairs(clones) do
					v:Destroy()
				end
			end)()
		end
		if highlight then 
			-- cleanup
			if mVals.TE1 then
				if mVals.TE1.PlaybackState == Enum.PlaybackState.Playing then
					mVals.TE1:Cancel()
				end
			end
			--if mVals.TE2 then
			--	if mVals.TE2.PlaybackState == Enum.PlaybackState.Playing then
			--		mVals.TE2:Cancel()
			--	end
			--end
			if mVals.hl then
				mVals.hl:Destroy()
			end
			--if ind then
			--	ind:Destroy()
			--end

			mVals.hl = spawnHighlight(model, {
				Enabled = false,
				FillColor = Color3.new(1),
				OutlineColor = Color3.new(1, 1, 1),
				FillTransparency = 0.25,
				OutlineTransparency = 0,
				DepthMode = Enum.HighlightDepthMode.Occluded,
			})

			local ind = Storage:WaitForChild("UI"):WaitForChild("Indication").Damage:Clone()

			local chosenColor = math.random(-100, 100)/100

			if chosenColor >= 0 then
				chosenColor = Colors.Base:Lerp(Colors.High, chosenColor)
			else
				chosenColor = Colors.Base:Lerp(Colors.Low, -chosenColor)
			end

			ind.Texter.TextColor3 = chosenColor
			if me.Health <= 0 or me.Health - dmg <= 0 and mVals.hl then
				--print("set")
				mVals.hl.FillColor = Color3.new(1, 1, 0)
			end

			if mVals.hl then
				mVals.hl.Adornee = model
				mVals.hl.Enabled = true
			end

			ind.Enabled = true
			ind.Parent = model

			local pt = nil
			if dcf then
				pt = Instance.new("Part")
				pt.Name = "oider"
				pt.Anchored = true
				pt.CanCollide = false
				pt.CanTouch = false
				pt.CanQuery = false
				pt.Transparency = 1
				pt.CFrame = dcf
				pt.Parent = workspace.PARTICLES
				ind.Adornee = pt
				--DBS:AddItem(pt, 9)
			else
				ind.Adornee = model.PrimaryPart or model
			end

			if mVals.hl then
				mVals.TE1 = TS:Create(mVals.hl, TIS[4], {FillTransparency = 1, OutlineTransparency = 1})
				mVals.TE1:Play()
			end
			
			local rmount = 0
			if amt > 0 then
				rmount = amt
			else
				rmount = dmg
			end
			ind.Texter.Text = math.ceil(rmount * (10^(MAXIMUM_EXTRA_PLACES)))/(10^(MAXIMUM_EXTRA_PLACES))

			local x, y, z = (math.random(-100, 100)/100), (math.random(-100, 100)/100) + 1.5, 1
			ind.StudsOffset = Vector3.new(x, y, z)

			mVals.TE2 = TS:Create(ind, TIS[5], {StudsOffset = Vector3.new(x, y + 1.5, 1), Size = UDim2.new(ind.Size.X.Scale + 0.675, 0, ind.Size.Y.Scale + 0.675, 0)})
			mVals.TE2:Play()
			local con1, con2
			if mVals.hl then
				con1 = mVals.TE1.Completed:Connect(function()
					con1:Disconnect()
					mVals.hl:Destroy()
				end)
			end
			con2 = mVals.TE2.Completed:Connect(function()
				con2:Disconnect()
				--print(ind)
				--print(TIS[3])
				local TE3 = TS:Create(ind, TIS[6], {StudsOffset = Vector3.new(x, y - 2.5, 1), Size = UDim2.new(0, 0, 0, 0)})
				TE3:Play()

				local con
				con = TE3.Completed:Connect(function()
					con:Disconnect()
					ind:Destroy()
					if pt then
						pt:Destroy()
					end
				end)
			end)
		end
		task.wait(effectCooldown)
		mVals.canEffect = true
	else
		mVals.addUp += dmg
	end
end

local function rizzUpH(model, dmg, dmgType)
	--local model = script.Parent
	local hum = model:WaitForChild("Humanoid")
	local hrp = model:WaitForChild("HumanoidRootPart")
	--local DealDamage = model:WaitForChild("DealDamage", 20)
	--local AddHealth = model:WaitForChild("AddHealth", 20)

	--if (not DealDamage or not AddHealth) and not PLRS:GetPlayerFromCharacter(model) then return end
	--if PLRS:GetPlayerFromCharacter(model) then
	--	repeat
	--		DealDamage = model:WaitForChild("DealDamage", 20)
	--	until
	--	not PLRS:GetPlayerFromCharacter(model) or (DealDamage and AddHealth)
	--	if not PLRS:GetPlayerFromCharacter(model) then return end
	--else
	--	return
	--end

	local mVals = modelVals[model]

	if not mVals then
		modelVals[model] = {
			TE1 = nil, 
			TE2 = nil,
			hl = nil,
			canEffect = true,
			addUp = 0
		}
		mVals = modelVals[model]
	end

	local blood = damageTypes[dmgType].Blood
	local highlight = damageTypes[dmgType].Indicate

	if highlight then
		if mVals.canEffect then
			mVals.canEffect = false
			local amt = mVals.addUp
			mVals.addUp = 0
			if blood then
				coroutine.wrap(function()
					local clones = {}
					local effects = Storage.Effects.Combat.Gore:GetChildren()
					for i, v in pairs(effects) do
						clones[v.Name] = v:Clone()
						clones[v.Name].Parent = model:FindFirstChild("UpperTorso") or model:FindFirstChild("GorePart")
						if clones[v.Name]:IsA("ParticleEmitter") then
							clones[v.Name]:Emit(5)
						end
						for i, v in pairs(clones[v.Name]:GetChildren()) do
							if v:IsA("ParticleEmitter") then
								v:Emit(5)
							end
						end
					end


					task.wait(2)
					for i, v in pairs(clones) do
						v:Destroy()
					end
				end)()
			end
			if highlight then 
				-- cleanup
				if mVals.TE1 then
					if mVals.TE1.PlaybackState == Enum.PlaybackState.Playing then
						mVals.TE1:Cancel()
					end
				end
				--if mVals.TE2 then
				--	if mVals.TE2.PlaybackState == Enum.PlaybackState.Playing then
				--		mVals.TE2:Cancel()
				--	end
				--end
				if mVals.hl then
					mVals.hl:Destroy()
				end
				--if ind then
				--	ind:Destroy()
				--end

				mVals.hl = spawnHighlight(model, {
					Enabled = false,
					FillColor = Color3.new(1),
					OutlineColor = Color3.new(1, 1, 1),
					FillTransparency = 0.25,
					OutlineTransparency = 0,
					DepthMode = Enum.HighlightDepthMode.Occluded,
				})

				local ind = Storage:WaitForChild("UI"):WaitForChild("Indication").Damage:Clone()

				local chosenColor = math.random(-100, 100)/100

				if chosenColor >= 0 then
					chosenColor = Colors.Base:Lerp(Colors.High, chosenColor)
				else
					chosenColor = Colors.Base:Lerp(Colors.Low, -chosenColor)
				end

				ind.Texter.TextColor3 = chosenColor
				if hum.Health <= 0 or hum.Health - dmg <= 0 and mVals.hl then
					--print("set")
					mVals.hl.FillColor = Color3.new(1, 1, 0)
				end
				
				if mVals.hl then
					mVals.hl.Adornee = model
					mVals.hl.Enabled = true
				end
				
				ind.Enabled = true
				ind.Adornee = hrp
				ind.Parent = hrp

				if mVals.hl then
					mVals.TE1 = TS:Create(mVals.hl, TIS[3], {FillTransparency = 1, OutlineTransparency = 1})
					mVals.TE1:Play()
				end
					
				local rmount = 0
				if amt > 0 then
					rmount = amt
				else
					rmount = dmg
				end
				ind.Texter.Text = math.ceil(rmount * (10^(MAXIMUM_EXTRA_PLACES)))/(10^(MAXIMUM_EXTRA_PLACES))

				local x, y, z = (math.random(-100, 100)/100), (math.random(-100, 100)/100), 1
				ind.StudsOffset = Vector3.new(x, y, z)

				mVals.TE2 = TS:Create(ind, TIS[5], {StudsOffset = Vector3.new(x, y + 1.5, 1), Size = UDim2.new(ind.Size.X.Scale + 0.675, 0, ind.Size.Y.Scale + 0.675, 0)})
				mVals.TE2:Play()
				
				local con1, con2
				if mVals.hl then
					con1 = mVals.TE1.Completed:Connect(function()
						con1:Disconnect()
						mVals.hl:Destroy()
					end)
				end
				con2 = mVals.TE2.Completed:Connect(function()
					con2:Disconnect()
					local TE3 = TS:Create(ind, TIS[6], {StudsOffset = Vector3.new(x, y - 2.5, 1), Size = UDim2.new(0, 0, 0, 0)})
					TE3:Play()

					local con
					con = TE3.Completed:Connect(function()
						con:Disconnect()
						ind:Destroy()
					end)
				end)
			end
			task.wait(effectCooldown)
			mVals.canEffect = true
		else
			mVals.addUp += dmg
		end
	end
end

local function bizzUpB(realStructure)
	local hl = spawnHighlight(realStructure, {
		FillColor = Color3.new(1, 1),
		OutlineColor = Color3.new(1, 1),
		FillTransparency = 0,
		OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	})

	coroutine.wrap(function()
		local TE = TS:Create(hl, TIS[2], {FillTransparency = 1, OutlineTransparency = 1})
		TE:Play()
		TE.Completed:Wait()
		hl:Destroy()
	end)()
end

local function questUpB(loc)
	local pt = Instance.new("Part")
	pt.Name = "questlost"
	pt.Anchored = true
	pt.CanCollide = false
	pt.CanTouch = false
	pt.CanQuery = false
	pt.Transparency = 1
	pt.CFrame = loc
	pt.Parent = workspace.PARTICLES

	local att = Storage.Effects.Environment.Other.Disappear.centeratt:Clone()
	att.Parent = pt

	for i, clo in pairs(att:GetChildren()) do
		if clo:IsA("ParticleEmitter") then
			clo:Emit(10)
		end
		for i, v in pairs(clo:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(10)
			end
		end
	end

	DBS:AddItem(pt, 2.5)
end

-- Connections
effectEv.OnClientEvent:Connect(function(effectType, pars)
	if effectType == "HumanoidDamage" then
		rizzUpH(table.unpack(pars))
	elseif effectType == "BuildDamage" then
		rizzUpB(table.unpack(pars))
	elseif effectType == "BuildPlace" then
		bizzUpB(table.unpack(pars))
	elseif effectType == "YellowVanish" then
		questUpB(table.unpack(pars))
	end
end)

hideObjEv.OnClientEvent:Connect(function(action, thing)
	if action == "trash" and thing and thing.Parent then
		thing.Parent = Trash
	end
end)
