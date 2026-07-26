-- services
local DSS = game:GetService("DataStoreService")

-- init
local odm = {
	--["BuildTable"] =   {
	--	["BuildAmt"] = 4,
	--	["BuildingsFinishedLoaded"] = Event,
	--	["Builds"] =  ▶ {...},
	--	["BuildsData"] =  ▶ {...},
	--	["Players"] = {}
	--},
	--["Movement"] =  ▶ {...},
	--["PlayerCombos"] =  ▶ {...},
	--["PlayerData"] =  ▶ {...},
	--["PlayerSwitchAnims"] = {},
	--["Tools"] = {...},
	--["countDict"] = "function"
--------------------------------------------------------------------------
	BuildTable = {
		Players = {},
		Builds = {},
		BuildsData = {},
		BuildAmt = 0,
		BuildingsFinishedLoaded = Instance.new("BindableEvent")
	},
	Movement = {},
	PlayerCombos = {},
	PlayerData = {},
	PlayerSwitchAnims = {},
	Tools = {},
	GlobalFunctions = require(script:WaitForChild("GlobalFunctions"))
}
return odm