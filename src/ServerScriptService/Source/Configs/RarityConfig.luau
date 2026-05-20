--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterRarityType = require(ReplicatedStorage.Source.Types.CharacterRarityType)

local RarityConfig: CharacterRarityType.CharacterRarity = {
	Common = {
		priorityIndex = 1,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 30,
		MinimumTime = 70,
		MaximumTime = 90,
		AutomaticRespawn = true,
		rarityColor = Color3.new(0.52549, 0.52549, 0.52549),
	},
	Uncommon = {
		priorityIndex = 2,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 35,
		MinimumTime = 80,
		MaximumTime = 90,
		AutomaticRespawn = true,
		rarityColor = Color3.new(0.266667, 0.772549, 0.152941),
	},
	Epic = {
		priorityIndex = 3,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 35,
		MinimumTime = 90,
		MaximumTime = 110,
		AutomaticRespawn = true,
		rarityColor = Color3.new(0.501961, 0, 1),
	},
	Legendary = {
		priorityIndex = 4,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 30,
		MinimumTime = 90,
		MaximumTime = 120,
		AutomaticRespawn = true,
		rarityColor = Color3.new(0.921569, 0.690196, 0),
	},
	Mythical = {
		priorityIndex = 5,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 30,
		MinimumTime = 100,
		MaximumTime = 125,
		AutomaticRespawn = true,
		rarityColor = Color3.new(0.776471, 0.0196078, 0.196078),
	},
	Divine = {
		priorityIndex = 6,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 35,
		MinimumTime = 110,
		MaximumTime = 140,
		AutomaticRespawn = true,
		rarityColor = Color3.new(1, 1, 1),
	},
	Secret = {
		priorityIndex = 7,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 35,
		MinimumTime = 120,
		MaximumTime = 200,
		AutomaticRespawn = true,
		rarityColor = Color3.new(1, 1, 1),
	},
	Celestial = {
		priorityIndex = 8,
		MinimumLevel = 1,
		MaximumLevel = 1,
		BaseSpawnNumber = 0,
		MinimumTime = 150,
		MaximumTime = 200,
		AutomaticRespawn = false,
		rarityColor = Color3.new(1, 1, 1),
	},
}

return table.freeze(RarityConfig)
