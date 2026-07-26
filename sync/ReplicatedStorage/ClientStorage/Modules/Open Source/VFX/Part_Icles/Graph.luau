

local function clamp(x, a, b) if x < a then return a end if x > b then return b end return x end
local function lerp(a, b, t) return a + (b - a) * t end

-- Align GraphA so it has all the keypoint times from graphb



local Graph = {}

Graph.GenerateSeed = function(graph: NumberSequence) -- for graphs with envelope in it
	local seed = {}
	local kp = graph.Keypoints
	local intensity = math.random()
	local isPositive = math.random() >= 0.5
	for i = 1,#kp do
		if kp[i].Envelope >0 then
			if isPositive == true then
				seed[i] = intensity * kp[i].Envelope -- returns an offset, from that envelope, uses 0-100% random value to multiply and get one in between the envelope's positive side
			else
				seed[i] = -intensity * kp[i].Envelope -- same but returns one for the negative side.
			end
		end
	end
	return seed
end

Graph.GenerateSeeds = function(graph: NumberSequence,NoOfSeeds : number)
	local seeds = {}
	for i = 1,NoOfSeeds do
		seeds[i] = Graph.GenerateSeed(graph)
	end
	return seeds
end


Graph.QueryPointsWithTime = function (t :number,graph: NumberSequence,seed: {number})
	t = math.clamp(t,0,1)
	local keypoints = graph.Keypoints

	-- This handles graphs with only one keypoint.
	if #keypoints == 1 then
		return keypoints[1].Value + (seed[1] or 0)
	end

	for i = 1,#keypoints - 1 do
		local k1 = keypoints[i]
		local k2 = keypoints[i + 1]
		if t >= k1.Time and t<= k2.Time then
			local point = (t - k1.Time)/(k2.Time - k1.Time)
			local k1value = k1.Value + (seed[i] or 0)
			local k2value = k2.Value + (seed[i+1] or 0)
			local value = k1value + ((k2value - k1value) * point)
			return value
		end
	end

	-- THE FIX: If the loop finishes, return the value of the very last keypoint.
	local lastKp = keypoints[#keypoints]
	return lastKp.Value + (seed[#keypoints] or 0)
end

Graph.QueryColorPointWithTime = function(t:number, graph : ColorSequence)
	local kp = graph.Keypoints
	if #kp == 0 then return Color3.new(1, 1, 1) end -- Return white if no keypoints exist
	if #kp == 1 then return kp[1].Value end -- Return the single value if only one keypoint

	-- Return the first keypoint's color if time is before the start
	if t <= kp[1].Time then return kp[1].Value end

	for i = 1, #kp - 1 do
		local k1 = kp[i]
		local k2 = kp[i + 1]
		if t >= k1.Time and t <= k2.Time then
			local point = (t - k1.Time) / (k2.Time - k1.Time)
			return k1.Value:Lerp(k2.Value, point)
		end
	end

	-- Return the last keypoint's color if time is after the end
	return kp[#kp].Value
end


--[[
Blend Function()
slowly lerp all keypoints in a graph to that of the keypoints in another graph.

but to make sure graph A blends perfectly to graph B, we have to make sure, the keypoints in Graph B, is present in Graph A.
we add it if there arent any.

Logic: of function (graphA,graphB,speedGraph,alpha)
1) create keypoints in graph A , if there wasnt one at that point in time, and graph B had one.
2) lerp every keypoint in graph A to graph B, the alpha is the speedgraph
3) this would i) create points in graph A, ii) lerp them.
]]

--[[ how do i create keypoints in an already existing number sequence?
answer: you cant.
the only way you could is by setting a new number sequence,
then what do you do to get the same number sequence with added number sequence stuff?

1) Loop through Numbersequence.Keypoints, store them in a table.
2) add the kp u want in there
]]

Graph.BlendGraphWithTime = function(GraphA: NumberSequence, GraphB: NumberSequence, SpeedGraph: NumberSequence, alpha: number)
	alpha = clamp(alpha or 1, 0, 1)

	local times = {} -- a table with all the time, values of graph
	local seen = {} -- seen table
	for _, seq in ipairs({GraphA, GraphB}) do -- for both graphs
		for _, kp in ipairs(seq.Keypoints) do -- in each of their keypoints
			if not seen[kp.Time] then -- if their time has not been seen yet
				seen[kp.Time] = true -- it has seen now
				table.insert(times, kp.Time) -- and it has inserted the time into the times table
			end
		end
	end
	-- now you have an array of times, that has totalkeypoints in both a and b, only their time is stored within them
	table.sort(times) -- sort everything

	local alignedA, alignedB = {}, {} -- two tables. A and B
	-- get the values in both graphs according to time.
	for _, t in ipairs(times) do -- in Times table, with all the times ordered
		local valA = Graph.QueryPointsWithTime(t, GraphA, {}) or GraphA.Keypoints[#GraphA.Keypoints].Value -- get the value in GraphA, at the time, of t in times table
		local valB = Graph.QueryPointsWithTime(t, GraphB, {}) or GraphB.Keypoints[#GraphB.Keypoints].Value -- same for B
		table.insert(alignedA, NumberSequenceKeypoint.new(t, valA)) -- insert a new keypoint with value and t
		table.insert(alignedB, NumberSequenceKeypoint.new(t, valB))
	end
	local blendFactor = Graph.QueryPointsWithTime(alpha, SpeedGraph, {}) or 1 -- get the time value to control the speed at which the blend occurs 

	-- 3) Blend each aligned keypoint
	local newKps = {} -- a table
	for i, kpA in ipairs(alignedA) do -- in graph A
		local t = kpA.Time -- for every keypoint, this variable has the time
		local valA = kpA.Value -- same, but this has the value
		local valB = alignedB[i].Value -- this has the value of graph B (the one u want to blend to)
		local blended = lerp(valA, valB, blendFactor) -- lerp to get da blended value!! YOO twin..
		table.insert(newKps, NumberSequenceKeypoint.new(t, blended)) -- the new blended keypoint is added to the newkp table
	end
	return NumberSequence.new(newKps)
	
end

Graph.BlendColorGraphWithTime = function(GraphA: ColorSequence, GraphB: ColorSequence, SpeedGraph: NumberSequence, alpha: number)
	alpha = clamp(alpha or 1, 0, 1)

	-- 1) Collect and sort all unique keypoint times
	local times = {}
	local seen = {}
	for _, seq in ipairs({GraphA, GraphB}) do
		for _, kp in ipairs(seq.Keypoints) do
			if not seen[kp.Time] then
				seen[kp.Time] = true
				table.insert(times, kp.Time)
			end
		end
	end
	table.sort(times)

	local blendFactor = Graph.QueryPointsWithTime(alpha, SpeedGraph, {}) or 1

	-- 2) Create the final array of keypoints directly
	local newKeypoints = {}
	for _, t in ipairs(times) do
		local colorA = Graph.QueryColorPointWithTime(t, GraphA)
		local colorB = Graph.QueryColorPointWithTime(t, GraphB)
		local blendedColor = colorA:Lerp(colorB, blendFactor)

		-- Directly create and insert the new keypoint into the array
		table.insert(newKeypoints, ColorSequenceKeypoint.new(t, blendedColor))
	end

	-- 3) Construct the new ColorSequence with the array of keypoints
	return ColorSequence.new(newKeypoints)
end


return Graph
