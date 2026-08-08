-- PlayerData.lua (Persona Edition)
-- Services
local SS = game:GetService("ServerStorage")

-- Constants
local BASE_STATS = {
	[1] = {
		Level = 1,
		Exp = 3,
		MaxExp = 10,
	},
	[2] = {
		Combat = 1,
		Agility = 10,
		Oxygen = 5,
		Harvesting = 1, 
		Charisma = 1,
		Strength = 5,
		Nutrition = 1,
	}
}

local BASE_INVENTORY = {
	[1] = {
		["Boleite Pickaxe"] = {
			Amount = 1,
			Durability = {
				[1] = 80
			}
		},
		["Boleite Axe"] = {
			Amount = 1,
			Durability = {
				[1] = 35
			}
		},
		["Wooden Box"] = {
			Amount = 1,
		},
		--Iron = {26}
	},
	[2] = nil, -- slotmaker will make this on its own

	[3] = {
		[1] = {
			["Name"] = "Boleite Pickaxe",
			["Pos"] = 1,
			["Path"] = {"Boleite Pickaxe", "List", 1},
			["Equipped"] = false
		},
		[2] = {
			["Name"] = "Boleite Axe",
			["Pos"] = 2,
			["Path"] = {"Boleite Pickaxe", "List", 1},
			["Equipped"] = false
		},
		[3] = {
			["Name"] = "Wooden Box",
			["Pos"] = 3,
			["Path"] = {"Wooden Box", "List", 1},
			["Equipped"] = false
		},
	},
	[4] = {
		[1] = nil,
		[2] = nil,
		[3] = nil
	}
}

local BASE_CHARACTER = {
	Presets = {
		[1] = {
			["Skin Tone"] = {Color3.new(0.588235, 0.372549, 0.121569).R, Color3.new(0.588235, 0.372549, 0.121569).G, Color3.new(0.588235, 0.372549, 0.121569).B},
			["Hair Color"] = {Color3.new().R, Color3.new().G, Color3.new().B},
			["Eye Color"] = {Color3.new().R, Color3.new().G, Color3.new().B},
			["Race"] = "Human",
			["Hair"] = "Tail Locs",
			["Eyes"] = "Basic Eyes",
			["Mouth"] = "Basic Mouth",
			["Top"] = "Football Shirt",
			["Bottom"] = "Basic Jeans",
			["Accessories"] = {"Diamond Necklace"},
		},
		[2] = nil,
		[3] = nil
	},
	OwnedCosmetics = {
		["Hair"] = {
			"Bald",
			"Tail Locs",
			"Afro",
			"Hair 1",
			"Hair 2",
			"Hair 3",
			"Hair 4",
			"Hair 5",
			"Hair 6",
			"Hair 7",
			"Hair 8",
		},
		["Eyes"] = {"Basic Eyes"},
		["Mouth"] = {"Basic Mouth"},
		["Top"] = {"Football Shirt", "Gold Suit Top", "White Nike T-Shirt"},
		["Bottom"] = {"Basic Jeans", "Purple Pants", "Gold Suit Bottom"},
		["Accessories"] = {"Backpack", "Gold Necklace", "Diamond Necklace", "Sung Woo Coat", "Top Hat"--[[, "Nah, I'm Freaky"]]},
	},
	CurrentPreset = 1,
	CFrame = {(workspace:WaitForChild("SPAWNS"):WaitForChild("SpawnLocationE").CFrame * CFrame.new(0, 5, 0)):GetComponents() } 
}

local BASE_CALENDAR = {
	CurrentDate = 1, -- Represented as days from April 1st
	TimeSlot = "Morning", -- Morning, AfterSchool, Evening, Night
	DayOfWeek = "Monday"
}

local BASE_SOCIAL_STATS = {
	Knowledge = {Level = 1, Progress = 0},
	Guts = {Level = 1, Progress = 0},
	Proficiency = {Level = 1, Progress = 0},
	Kindness = {Level = 1, Progress = 0},
	Charm = {Level = 1, Progress = 0}
}

local BASE_CONFIDANTS = {
	["Ryuji"] = {Rank = 0, Points = 0, Arcana = "Chariot"},
	["Sojiro"] = {Rank = 0, Points = 0, Arcana = "Hierophant"},
	-- Add all 21 Arcanas here
}

local BASE_PERSONA_STOCK = {
	ActiveIndex = 1,
	TraySize = 1,
	Tray = {1, 2}, -- For testing, we are pre-filling 2 slots
	Stock = {
		[1] = {Name = "Angel", Level = 1, Exp = 0, Skills = {"Light Strike", "Spirit Heal"}, Stats = {ST=5, MA=5, EN=5, AG=5, LU=5}},
		[2] = {Name = "Golem", Level = 1, Exp = 0, Skills = {"Rock Smash"}, Stats = {ST=8, MA=2, EN=9, AG=2, LU=4}}
	}
}

local BASE_GLOBAL = {
	Quests = {
		Current = {
			--["Be a sigma"] = {
			--	Task = "Sigma",
			--	Goal = true,
			--	Progress = false,
			--	Object = "Sigma Obtained",

			--	Text = "Be a sigma",

			--	RewardType = "Currency",
			--	Reward = {1000, "Gems"}
			--}	
		},
		Completed = {}
	},
	NPCData = {
		--["PeridotPerfection"] = {
		--	["Behavior"] = "Done"
		--}
		--["Xander"] = {
		--	["Behavior"] = "Quest Return 6"
		--}
	},
	Clan = nil,
	Elo = {
		Rank = "Bronze",
		Rating = 1000
	}
}

local BASE_EUROS = 5000
local BASE_BP = 0

-- Dependencies
local Storage = SS:WaitForChild("Storage")
local Importer = require(Storage.Importer)
local DataTypes = Importer:ImportFolder(Storage.Classes.DataTypes)
local Currency = require(Storage.Classes.DataTypes.Currency)
local DataClass = Importer:ImportScript(Storage.Classes.BaseClasses.DataClass)

-- Initialization
local PlayerData = {}
PlayerData.__index = PlayerData 

function PlayerData.new(Player, Keys, slotId)
	local MT = setmetatable({
		Player = Player;
		SlotId = slotId or "1";

		-- 1. CURRENCY (yen or euros?? idk)
		Euros = Currency.new(Player, DataClass.new(Player, Keys.MONEY_KEY, slotId), "Euros", BASE_EUROS);
		BattlePoints = Currency.new(Player, DataClass.new(Player, Keys.BP_KEY, slotId), "BattlePoints", BASE_BP);

		-- 2. PERSONA CORE SYSTEMS
		Calendar = DataTypes.Calendar.new(Player, DataClass.new(Player, Keys.CALENDAR_KEY, slotId), BASE_CALENDAR);
		SocialStats = DataTypes.SocialStats.new(Player, DataClass.new(Player, Keys.SOCIAL_STATS_KEY, slotId), BASE_SOCIAL_STATS);
		Confidants = DataTypes.Confidants.new(Player, DataClass.new(Player, Keys.CONFIDANTS_KEY, slotId), BASE_CONFIDANTS);
		PersonaStock = DataTypes.PersonaStock.new(Player, DataClass.new(Player, Keys.PERSONA_STOCK_KEY, slotId), BASE_PERSONA_STOCK);

		-- 4. CUSTOMIZATION & GEAR (imma keep these for now), as well as potions and rare stuff probably
		Character = DataTypes.Character.new(Player, DataClass.new(Player, Keys.CHARACTER_KEY, slotId), BASE_CHARACTER);
		Inventory = DataTypes.Inventory.new(Player, DataClass.new(Player, Keys.INVENTORY_KEY, slotId), BASE_INVENTORY);

		-- 5. STORY & QUEST PERSISTENCE
		Global = DataTypes.Global.new(Player, DataClass.new(Player, Keys.GLOBAL_KEY, slotId), BASE_GLOBAL);
	}, PlayerData)

	return MT
end

function PlayerData:SaveData() -- save data 
	for i, saveClass in pairs(self) do
		if typeof(saveClass) == "table" and typeof(saveClass.SaveData) == "function" then
			saveClass:SaveData()
		end
	end

	self = nil
end

function PlayerData:Destroy() -- cleanup method
	self = nil
end

return PlayerData