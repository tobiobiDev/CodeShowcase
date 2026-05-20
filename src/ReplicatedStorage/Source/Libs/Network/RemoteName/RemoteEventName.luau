--[[
	Specifies the names of all RemoteEvents. One RemoteEvent object gets
    generated for each name	in this list, and these names are used as enums when
    interacting with the Network module to tell it which remote event to fire
    without typing out typo-prone string literals.
]]

export type EnumType =
	"CharacterLoaded"
	-- Teleport Events
	| "InitiateTeleport"
	| "Teleporting"
	| "TeleportFailed"
	-- Player Data Changes
	| "CurrencyChanged"
	| "PickaxeLevelChanged"
	| "WalkSpeedChanged"
	| "RebirthsChanged"
	-- Player Data Sync
	| "CharacterPlaced"
	| "CharacterUnplaced"
	| "CollectedCharacterRemoved"
	| "CharacterUpgraded"
	| "DiscoveredCharacterSaved"
	| "CarryCapacityUpgradeIncreased"
	| "CarryCapacityChanged"
	| "WalkspeedUpgradeIncreased"
	| "CashMultiplierChanged"
	| "SkinBoostChanged"
	| "FriendBoostChanged"
	| "BaseSkinSaved"
	| "PlayTimeUpdated"
	| "ThievesToolAdded"
	-- Unorganized
	| "CharacterCollected"
	| "DropCharacter"
	| "PlaceCharacter"
	| "PickupCharacter"
	| "SellCharacter"
	| "CollectCash"
	| "UpdateDisplayCash"
	| "UpgradeCharacter"
	| "UpdateIndex"
	| "EquipedCharacter"
	| "BuyCarryCapacity"
	| "BuyWalkingspeed"
	| "BuyPickaxeUpgrade"
	| "Rebirth"
	| "CharacterShop"
	| "UpdateCashBoost"
	| "SuccesfulPlayerUpgrade"
	| "ShopPurchase"
	| "LuckBoosted"
	| "PlayNotification"
	| "GiftCharacter"
	| "PickaxeModelChanged"
	| "ShopProductTimer"
	| "UnlockedNewFloor"
	| "PlaySound"
	| "ChangeSettings"
	| "MusicSettingChanged"
	| "SFXSettingChanged"
	| "VFXSettingChanged"
	| "ImportantSettingChanged"
	| "UnimportantSettingChanged"
	| "CollectedCharactersChanged"
	| "OnScreenOffersChanged"
	| "ApplyCode"
	| "UnlockedBrainrotDetector"
	| "TeleportButton"
	| "PlayRollAnimation"
	| "PlayRebirthSFX"
	-- Tutorial
	| "StartTutorialStage"
	| "TutorialStageChanged"
	| "TutorialCharacterSpawned"
	| "PickedUpCharacter"
	| "TutorialCharacterPlaced"
	| "FinishedTutorialArea"
	| "TutorialCompleted"
	-- Mining Minigame Events
	| "MiningStart"
	| "MiningSubmit"
	| "MiningStrengthTooWeak"
	-- Cave Events
	| "CaveResetFinalCountdown"
	| "CaveReset"
	| "CaveStartTimer"
	-- Dev Console
	| "AdjustCurrency"
	| "SetPickaxeLevel"
	-- Leaderboard Events
	| "RefreshLeaderboardTimer"
	-- PVP Events
	| "AttackHit"
	| "RequestAttack"
	-- Inventory
	| "SortInventory"

local RemoteEventName = {
	CharacterLoaded = "CharacterLoaded" :: "CharacterLoaded",
	-- Teleport Events
	InitiateTeleport = "InitiateTeleport" :: "InitiateTeleport",
	Teleporting = "Teleporting" :: "Teleporting",
	TeleportFailed = "TeleportFailed" :: "TeleportFailed",
	-- Player Data Changes
	CurrencyChanged = "CurrencyChanged" :: "CurrencyChanged",
	PickaxeLevelChanged = "PickaxeLevelChanged" :: "PickaxeLevelChanged",
	WalkSpeedChanged = "WalkSpeedChanged" :: "WalkSpeedChanged",
	RebirthsChanged = "RebirthsChanged" :: "RebirthsChanged",
	-- Player Data Sync
	CharacterPlaced = "CharacterPlaced" :: "CharacterPlaced",
	CharacterUnplaced = "CharacterUnplaced" :: "CharacterUnplaced",
	CollectedCharacterRemoved = "CollectedCharacterRemoved" :: "CollectedCharacterRemoved",
	CharacterUpgraded = "CharacterUpgraded" :: "CharacterUpgraded",
	DiscoveredCharacterSaved = "DiscoveredCharacterSaved" :: "DiscoveredCharacterSaved",
	CarryCapacityUpgradeIncreased = "CarryCapacityUpgradeIncreased" :: "CarryCapacityUpgradeIncreased",
	CarryCapacityChanged = "CarryCapacityChanged" :: "CarryCapacityChanged",
	WalkspeedUpgradeIncreased = "WalkspeedUpgradeIncreased" :: "WalkspeedUpgradeIncreased",
	CashMultiplierChanged = "CashMultiplierChanged" :: "CashMultiplierChanged",
	SkinBoostChanged = "SkinBoostChanged" :: "SkinBoostChanged",
	FriendBoostChanged = "FriendBoostChanged" :: "FriendBoostChanged",
	BaseSkinSaved = "BaseSkinSaved" :: "BaseSkinSaved",
	PlayTimeUpdated = "PlayTimeUpdated" :: "PlayTimeUpdated",
	ThievesToolAdded = "ThievesToolAdded" :: "ThievesToolAdded",
	-- Unorganized
	CharacterCollected = "CharacterCollected" :: "CharacterCollected",
	DropCharacter = "DropCharacter" :: "DropCharacter",
	PlaceCharacter = "PlaceCharacter" :: "PlaceCharacter",
	PickupCharacter = "PickupCharacter" :: "PickupCharacter",
	SellCharacter = "SellCharacter" :: "SellCharacter",
	CollectCash = "CollectCash" :: "CollectCash",
	UpdateDisplayCash = "UpdateDisplayCash" :: "UpdateDisplayCash",
	UpgradeCharacter = "UpgradeCharacter" :: "UpgradeCharacter",
	UpdateIndex = "UpdateIndex" :: "UpdateIndex",
	EquipedCharacter = "EquipedCharacter" :: "EquipedCharacter",
	BuyCarryCapacity = "BuyCarryCapacity" :: "BuyCarryCapacity",
	BuyWalkingspeed = "BuyWalkingspeed" :: "BuyWalkingspeed",
	BuyPickaxeUpgrade = "BuyPickaxeUpgrade" :: "BuyPickaxeUpgrade",
	Rebirth = "Rebirth" :: "Rebirth",
	CharacterShop = "CharacterShop" :: "CharacterShop",
	UpdateCashBoost = "UpdateCashBoost" :: "UpdateCashBoost",
	SuccesfulPlayerUpgrade = "SuccesfulPlayerUpgrade" :: "SuccesfulPlayerUpgrade",
	ShopPurchase = "ShopPurchase" :: "ShopPurchase",
	LuckBoosted = "LuckBoosted" :: "LuckBoosted",
	PlayNotification = "PlayNotification" :: "PlayNotification",
	GiftCharacter = "GiftCharacter" :: "GiftCharacter",
	PickaxeModelChanged = "PickaxeModelChanged" :: "PickaxeModelChanged",
	ShopProductTimer = "ShopProductTimer" :: "ShopProductTimer",
	UnlockedNewFloor = "UnlockedNewFloor" :: "UnlockedNewFloor",
	PlaySound = "PlaySound" :: "PlaySound",
	ChangeSettings = "ChangeSettings" :: "ChangeSettings",
	MusicSettingChanged = "MusicSettingChanged" :: "MusicSettingChanged",
	SFXSettingChanged = "SFXSettingChanged" :: "SFXSettingChanged",
	VFXSettingChanged = "VFXSettingChanged" :: "VFXSettingChanged",
	ImportantSettingChanged = "ImportantSettingChanged" :: "ImportantSettingChanged",
	UnimportantSettingChanged = "UnimportantSettingChanged" :: "UnimportantSettingChanged",
	CollectedCharactersChanged = "CollectedCharactersChanged" :: "CollectedCharactersChanged",
	OnScreenOffersChanged = "OnScreenOffersChanged" :: "OnScreenOffersChanged",
	ApplyCode = "ApplyCode" :: "ApplyCode",
	UnlockedBrainrotDetector = "UnlockedBrainrotDetector" :: "UnlockedBrainrotDetector",
	TeleportButton = "TeleportButton" :: "TeleportButton",
	PlayRollAnimation = "PlayRollAnimation" :: "PlayRollAnimation",
	PlayRebirthSFX = "PlayRebirthSFX" :: "PlayRebirthSFX",
	-- Tutorial
	StartTutorialStage = "StartTutorialStage" :: "StartTutorialStage",
	TutorialStageChanged = "TutorialStageChanged" :: "TutorialStageChanged",
	TutorialCharacterSpawned = "TutorialCharacterSpawned" :: "TutorialCharacterSpawned",
	PickedUpCharacter = "PickedUpCharacter" :: "PickedUpCharacter",
	TutorialCharacterPlaced = "TutorialCharacterPlaced" :: "TutorialCharacterPlaced",
	FinishedTutorialArea = "FinishedTutorialArea" :: "FinishedTutorialArea",
	TutorialCompleted = "TutorialCompleted" :: "TutorialCompleted",
	-- Mining Minigame Events
	MiningStart = "MiningStart" :: "MiningStart",
	MiningSubmit = "MiningSubmit" :: "MiningSubmit",
	MiningStrengthTooWeak = "MiningStrengthTooWeak" :: "MiningStrengthTooWeak",
	-- Cave Events
	CaveResetFinalCountdown = "CaveResetFinalCountdown" :: "CaveResetFinalCountdown",
	CaveReset = "CaveReset" :: "CaveReset",
	CaveStartTimer = "CaveStartTimer" :: "CaveStartTimer",
	-- Dev Console
	AdjustCurrency = "AdjustCurrency" :: "AdjustCurrency",
	SetPickaxeStrength = "SetPickaxeStrength" :: "SetPickaxeStrength",
	SetPickaxeLevel = "SetPickaxeLevel" :: "SetPickaxeLevel",
	-- Leaderboard Events
	RefreshLeaderboardTimer = "RefreshLeaderboardTimer" :: "RefreshLeaderboardTimer",
	-- PVP Events
	AttackHit = "AttackHit" :: "AttackHit",
	RequestAttack = "RequestAttack" :: "RequestAttack",
	-- Inventory
	SortInventory = "SortInventory" :: "SortInventory",
}

return RemoteEventName
