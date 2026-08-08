--[[
		Module made by: Maplestorm (@Maplestorm_0) | Discord: maplestorm
		Modified for osp4/Metanoia portability:
		  - fixed ObjectCache require path (sibling module, not root)
		  - configurable raycast filter (defaults to Terrain if workspace.Map doesn't exist)
		  - custom rock template support via SetRockTemplate()
		  - nil-safety for Smoke emitter on custom rocks
]]

local RockModule = {}

--Services
local TS = game:GetService("TweenService")
local RPS = game:GetService("ReplicatedStorage")

local ObjectCache = require(script.Parent.ObjectCache)

-- defaults
local defaultTemplate = script.RockDebris
local cacheFolder = workspace:FindFirstChild("PARTICLES")
	and workspace.PARTICLES:FindFirstChild("Cache")
	or workspace:FindFirstChild("PARTICLES")
	or workspace

local cache = ObjectCache.new(defaultTemplate, 100, cacheFolder)

-- configurable raycast filter (workspace.Map for production, Terrain for osp4)
local filterInstances = {workspace.RESOURCES.GROUND, workspace.Terrain, workspace.RESOURCES.dreamworld.floatables.platforms.clouds}

-- Swap out the raycast filter targets at runtime.
-- instances - array of BasePart/Model to include in the raycast
function RockModule.SetFilterInstances(instances)
	filterInstances = instances
end

-- Swap the rock template used by the object cache.
-- template   - the Part/MeshPart to pool
-- cacheSize  - optional pool size (default 100)
function RockModule.SetRockTemplate(template, cacheSize)
	cache = ObjectCache.new(template, cacheSize or 100, cacheFolder)
end

function RockModule.Punch(origin:Vector3, direction:Vector3, raycastDirection:Vector3, angle:number, lines:number, distance:number, startsize:number, endsize:number, numrocks:number, lifetime:number, startdist:number, popuptime:number, retracttime:number, forceFilterInstances:{Instances}, blacklist:boolean)
	local rayparams = RaycastParams.new()
	rayparams.FilterType = blacklist and Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Include
	rayparams.FilterDescendantsInstances = forceFilterInstances or filterInstances
	
	local result = workspace:Raycast(origin, raycastDirection, rayparams)
	
	if result then
		local normal = result.Normal
		local startCF = CFrame.new(result.Position, result.Position + direction)
		startCF = startCF:ToWorldSpace(CFrame.Angles(0,math.rad(-angle/2),0))
		local rocksPerLine = numrocks/lines

		for i = 1, lines do
			local dir = startCF:ToWorldSpace(CFrame.Angles(0,math.rad(angle/(lines-1)*(i-1)),0))
			if lines == 1 then
				dir = startCF
			end
			local amount = rocksPerLine + math.round(math.random(rocksPerLine*3,rocksPerLine*5)/(rocksPerLine))
			task.spawn(function()
				for j = 1, amount do
					local size = startsize+(endsize-startsize)*(j/amount)
					local torigin = startCF+dir.LookVector*(1+(distance-1)*(j/amount))+dir.LookVector*startdist
					local tResult = workspace:Raycast(torigin.Position+Vector3.new(0,raycastDirection.Y/-2,0), raycastDirection, rayparams)
					if tResult then
						local rock = cache:GetPart()
						rock.Massless = true
						rock.Anchored = true
						rock.AssemblyLinearVelocity = Vector3.zero
						rock.Position = tResult.Position - Vector3.new(0,size/2,0)
						rock.Size = Vector3.new(size,size,size)
						-- nil-safe smoke handling (custom rocks may not have Smoke)
						local smoke = rock:FindFirstChild("Smoke")
						if smoke then
							smoke.Size = NumberSequence.new(size*math.random(3,6))
						end
						rock.Parent = workspace.PARTICLES
						rock.Material = tResult.Material
						rock.Color = tResult.Instance.Color
						rock.Rotation = Vector3.new(math.random(0,360),math.random(0,360),math.random(0,360))
						TS:Create(rock, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = tResult.Position}):Play()
						if smoke and (math.random(j, amount)/amount) >= 0.75 then
							smoke:Emit(1)
						end
						task.delay(0.21, function()
							rock.Position = tResult.Position
						end)
						task.delay(lifetime, function()
							retracttime = retracttime or 1
							local t = TS:Create(rock, TweenInfo.new(retracttime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = tResult.Position-Vector3.new(0,size,0)})
							t.Completed:Connect(function()
								cache:ReturnPart(rock)
							end)
							t:Play()
						end)
					end
					popuptime = popuptime or 0.1
					if popuptime ~= 0 then
						task.wait(popuptime/amount)
					end
				end
			end)
		end

	end
end

return RockModule
