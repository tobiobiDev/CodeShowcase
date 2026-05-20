--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterInfoType = require(ReplicatedStorage.Source.Types.CharacterInfoType)

local Characters: CharacterInfoType.CharacterInfo = {
	["Noobini Appleini"] = {
		Rarity = "Common",
		SpawnChance = 30,
		CashPerSecond = 5,
		BaseUpgradePrice = 7,
	},
	["Burbaloni Luliloli"] = {
		Rarity = "Common",
		SpawnChance = 25,
		CashPerSecond = 10,
		BaseUpgradePrice = 15,
	},
	["Tung Tung Sahur"] = {
		Rarity = "Common",
		SpawnChance = 20,
		CashPerSecond = 18,
		BaseUpgradePrice = 27,
	},
	["Trippi Troppi Troppa Trippa"] = {
		Rarity = "Common",
		SpawnChance = 15,
		CashPerSecond = 28,
		BaseUpgradePrice = 42,
	},
	["Trulimero Trulichina"] = {
		Rarity = "Common",
		SpawnChance = 10,
		CashPerSecond = 40,
		BaseUpgradePrice = 60,
	},

	["Boneca Ambalabu"] = {
		Rarity = "Uncommon",
		SpawnChance = 45,
		CashPerSecond = 85,
		BaseUpgradePrice = 127,
	},
	["Frigo Camelo"] = {
		Rarity = "Uncommon",
		SpawnChance = 30,
		CashPerSecond = 120,
		BaseUpgradePrice = 180,
	},
	["Lirili Larila"] = {
		Rarity = "Uncommon",
		SpawnChance = 15,
		CashPerSecond = 180,
		BaseUpgradePrice = 270,
	},
	["Unta Tobi Tob Tob"] = {
		Rarity = "Uncommon",
		SpawnChance = 10,
		CashPerSecond = 260,
		BaseUpgradePrice = 390,
	},

	["Spiuniro Golubiro"] = {
		Rarity = "Epic",
		SpawnChance = 25,
		CashPerSecond = 700,
		BaseUpgradePrice = 1_050,
	},
	["Ballerina Capuccina"] = {
		Rarity = "Epic",
		SpawnChance = 20,
		CashPerSecond = 1_100,
		BaseUpgradePrice = 1_650,
	},
	["Ta Ta Ta Sahur"] = {
		Rarity = "Epic",
		SpawnChance = 20,
		CashPerSecond = 1_700,
		BaseUpgradePrice = 2_550,
	},
	["Glorbo Fruttodrillo"] = {
		Rarity = "Epic",
		SpawnChance = 15,
		CashPerSecond = 2_600,
		BaseUpgradePrice = 3_900,
	},
	["Melanini Pandanini"] = {
		Rarity = "Epic",
		SpawnChance = 12,
		CashPerSecond = 3_800,
		BaseUpgradePrice = 5_700,
	},
	["Bluberini Octopussini"] = {
		Rarity = "Epic",
		SpawnChance = 8,
		CashPerSecond = 6_000,
		BaseUpgradePrice = 9_000,
	},

	["Chimpanzini Cocosini"] = {
		Rarity = "Legendary",
		SpawnChance = 35,
		CashPerSecond = 12_000,
		BaseUpgradePrice = 18_000,
	},
	["Bulliccinni Bananini"] = {
		Rarity = "Legendary",
		SpawnChance = 25,
		CashPerSecond = 12_000,
		BaseUpgradePrice = 18_000,
	},
	["Cocosino Rhino"] = {
		Rarity = "Legendary",
		SpawnChance = 20,
		CashPerSecond = 18_000,
		BaseUpgradePrice = 27_000,
	},
	["Cappuccino Assassino"] = {
		Rarity = "Legendary",
		SpawnChance = 12,
		CashPerSecond = 28_000,
		BaseUpgradePrice = 42_000,
	},
	["Cabrospaghetti Mistico"] = {
		Rarity = "Legendary",
		SpawnChance = 8,
		CashPerSecond = 42_000,
		BaseUpgradePrice = 63_000,
	},

	["Elefantucci Bananucci"] = {
		Rarity = "Mythical",
		SpawnChance = 50,
		CashPerSecond = 120_000,
		BaseUpgradePrice = 180_000,
	},
	["Chimpanzini Bananini"] = {
		Rarity = "Mythical",
		SpawnChance = 20,
		CashPerSecond = 180_000,
		BaseUpgradePrice = 270_000,
	},
	["Bombardino Crocodilo"] = {
		Rarity = "Mythical",
		SpawnChance = 15,
		CashPerSecond = 260_000,
		BaseUpgradePrice = 390_000,
	},
	["Coccodrillo Formagioso"] = {
		Rarity = "Mythical",
		SpawnChance = 7,
		CashPerSecond = 380_000,
		BaseUpgradePrice = 570_000,
	},
	["Bobritto Bandito"] = {
		Rarity = "Mythical",
		SpawnChance = 5,
		CashPerSecond = 550_000,
		BaseUpgradePrice = 825_000,
	},
	["Giraffa Celestre"] = {
		Rarity = "Mythical",
		SpawnChance = 3,
		CashPerSecond = 850_000,
		BaseUpgradePrice = 1_275_000,
	},

	["Brr Brr Patapim"] = {
		Rarity = "Divine",
		SpawnChance = 32,
		CashPerSecond = 1_200_000,
		BaseUpgradePrice = 1_800_000,
	},
	["garamaran"] = {
		Rarity = "Divine",
		SpawnChance = 24,
		CashPerSecond = 1_800_000,
		BaseUpgradePrice = 2_700_000,
	},
	["Tric Trac Baraboom"] = {
		Rarity = "Divine",
		SpawnChance = 18,
		CashPerSecond = 3_000_000,
		BaseUpgradePrice = 4_500_000,
	},
	["Madu dung dung"] = {
		Rarity = "Divine",
		SpawnChance = 13,
		CashPerSecond = 4_500_000,
		BaseUpgradePrice = 6_750_000,
	},
	["Udin Din Din Dun"] = {
		Rarity = "Divine",
		SpawnChance = 8,
		CashPerSecond = 7_000_000,
		BaseUpgradePrice = 10_500_000,
	},
	["Perochello Lemonchello"] = {
		Rarity = "Divine",
		SpawnChance = 5,
		CashPerSecond = 12_000_000,
		BaseUpgradePrice = 18_000_000,
	},

	["Centralucci Nuclearucci"] = {
		Rarity = "Secret",
		SpawnChance = 40,
		CashPerSecond = 18_000_000,
		BaseUpgradePrice = 27_000_000,
	},
	["Tralalero Tralala"] = {
		Rarity = "Secret",
		SpawnChance = 30,
		CashPerSecond = 30_000_000,
		BaseUpgradePrice = 45_000_000,
	},
	["Pakrahmatmamat"] = {
		Rarity = "Secret",
		SpawnChance = 18,
		CashPerSecond = 55_000_000,
		BaseUpgradePrice = 82_500_000,
	},
	["La Esok Sekola"] = {
		Rarity = "Secret",
		SpawnChance = 8,
		CashPerSecond = 90_000_000,
		BaseUpgradePrice = 135_000_000,
	},
	["Karkerkar Kurkur"] = {
		Rarity = "Secret",
		SpawnChance = 4,
		CashPerSecond = 140_000_000,
		BaseUpgradePrice = 210_000_000,
	},

	["Truliluru Tralaluno"] = {
		Rarity = "Celestial",
		SpawnChance = 35,
		CashPerSecond = 180_000_000,
		BaseUpgradePrice = 270_000_000,
	},
	["La Grande Combination"] = {
		Rarity = "Celestial",
		SpawnChance = 25,
		CashPerSecond = 350_000_000,
		BaseUpgradePrice = 525_000_000,
	},
	["Los Tralaleritos"] = {
		Rarity = "Celestial",
		SpawnChance = 18,
		CashPerSecond = 800_000_000,
		BaseUpgradePrice = 1_200_000_000,
	},
	["Torrtuginni Dragonfrutinni"] = {
		Rarity = "Celestial",
		SpawnChance = 12,
		CashPerSecond = 1_300_000_000,
		BaseUpgradePrice = 1_950_000_000,
	},
	["Ketupat Kuprat"] = {
		Rarity = "Celestial",
		SpawnChance = 7,
		CashPerSecond = 1_800_000_000,
		BaseUpgradePrice = 2_700_000_000,
	},
	["Pot Hotspot"] = {
		Rarity = "Celestial",
		SpawnChance = 3,
		CashPerSecond = 3_000_000_000,
		BaseUpgradePrice = 4_500_000_000,

	},
}

return table.freeze(Characters)
