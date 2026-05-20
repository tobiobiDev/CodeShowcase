--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultConfigs = require(ReplicatedStorage.Source.Configs.DefaultConfigs)
local InventoryConfigs = require(ReplicatedStorage.Source.Configs.InventoryConfigs)
local PlayerDataType = require(ReplicatedStorage.Source.Types.PlayerDataType)

local DefaultPlayerData: PlayerDataType.PlayerData = {
	IsNew = true,
	lastOnline = os.time(),
	PlayTime = 0,

	Currency = {
		Cash = 0,
	},

	BaseInfo = {
		UnlockedFloors = 1,
		Floor1 = {},
		Floor2 = {},
		Floor3 = {},
	},

	CashBoosts = {
		FriendsBoost = 0,
		RebirthMultiplier = 1,
		SkinBoost = 0,
	},
	CashPerSecond = 0,

	TutorialStage = 1,
	CompletedTutorial = false,

	DiscoveredCharacters = {},

	-- Tracks how many times and when was each of shop purchases made
	PurchaseHistory = {},
	Codes = {},

	BaseSkins = {},

	Upgrades = {
		CarryCapacity = 0,
		Pickaxe = 0,
		Walkspeed = 0,
	},

	CollectedCharacters = {},

	Settings = {
		Music = 100,
		SFX = 100,
		VFX = true,
		Important = true,
		Unimportant = true,
		BrainrotDetector = false,
		OnScreenOffers = false,
	},

	BrainrotDetector = false,
	Rebirths = 0,
	CarryingCapacity = DefaultConfigs.CarryingCapacity,
	InventoryCapacity = InventoryConfigs.MAX_INVENTORY_CAPACITY,
	MovementSpeed = DefaultConfigs.WalkSpeed,
	ThievesTools = { "Bat" },

	HasSecret = false,
}

return DefaultPlayerData
