--Initialization
local importer = {}

-- Public functions
function importer:ImportFolder(Folder: Folder) -- import class(es) from a folder
	local imports = newproxy(true)
	local importsMT = getmetatable(imports)
	importsMT.__index = importsMT
	
	for i, v in pairs(Folder:GetDescendants()) do
		if not v:IsA("ModuleScript") then continue end
		local name = v.Name
		--print(v.Name)
		local enumData = require(v)
		importsMT[name] = enumData
	end

	--setmetatable(importsMT, {__index = {}})
	return imports
end

function importer:ImportScript(Script: ModuleScript) -- import class(es) a script
	return require(Script)
end

return importer