-- DataTypes.Confidants
local Confidants = {}
Confidants.__index = Confidants

function Confidants.new(Player, DataClass, BaseConfidants)
	local MT = setmetatable({}, Confidants)
	DataClass:LoadData()
	setmetatable(MT, {__index = DataClass})

	MT.BaseData = require(game:GetService("ServerStorage"):WaitForChild("Storage"):WaitForChild("Classes"):WaitForChild("StaticClasses"):WaitForChild("Obi's DS Manager")).GlobalFunctions.deepCopy(BaseConfidants)
	MT.Data = MT.Data or MT.BaseData
	MT.Changed = Instance.new("BindableEvent")

	function MT:AddPoints(NpcName, Amount)
		local confidant = self.Data[NpcName]
		if not confidant or confidant.Rank >= 10 then return end

		confidant.Points += Amount
		-- Logic: If Points > threshold, trigger a "Rank Up Event"
		-- In Persona, Rank Ups usually require a specific story scene.
		self.Changed:Fire(NpcName, "Points", confidant.Points)
	end

	function MT:SetRank(NpcName, Rank)
		if self.Data[NpcName] then
			self.Data[NpcName].Rank = Rank
			self.Changed:Fire(NpcName, "Rank", Rank)
		end
	end

	return MT
end

return Confidants