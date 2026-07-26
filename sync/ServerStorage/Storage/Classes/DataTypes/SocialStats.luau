-- DataTypes.SocialStats
local SocialStats = {}
SocialStats.__index = SocialStats

-- Points required to reach Level 2, 3, 4, 5
local THRESHOLDS = {10, 30, 70, 150}

function SocialStats.new(Player, DataClass, BaseSocialStats)
	local MT = setmetatable({}, SocialStats)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass})

	MT.BaseData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).GlobalFunctions.deepCopy(BaseSocialStats)
	MT.Data = MT.Data or MT.BaseData
	MT.Changed = Instance.new("BindableEvent")

	function MT:AddPoints(StatName, Amount)
		local stat = self.Data[StatName]
		if not stat or stat.Level >= 5 then return end

		stat.Progress += Amount

		-- Check for Level Up
		if stat.Progress >= (THRESHOLDS[stat.Level] or 999) then
			stat.Level += 1
			stat.Progress = 0
			self.Changed:Fire(StatName, "LevelUp", stat.Level)
		else
			self.Changed:Fire(StatName, "Progress", stat.Progress)
		end
	end

	return MT
end

return SocialStats