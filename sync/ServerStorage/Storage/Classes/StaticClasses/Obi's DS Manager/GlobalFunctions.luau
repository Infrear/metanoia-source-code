local gfs = {}

gfs.countDict = function(dict)
	local count = 0
	for i, v in pairs(dict) do
		count += 1
	end
	return count
end

gfs.deepCopy = function(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = gfs.deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

return gfs