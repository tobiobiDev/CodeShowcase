local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local CurrencyEnum = require(ReplicatedStorage.Source.Enums.CurrencyEnum)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)
local WeaponNameEnum = require(ReplicatedStorage.Source.Enums.WeaponNameEnum)

type Floor = "Floor1" | "Floor2" | "Floor3"
type CharacterId = string
type BaseDisplayPlatform = string

export type PlayerData = {
	IsNew: boolean, -- Are they a brand new player?
	lastOnline: number,
	PlayTime: number,

	Currency: {
		[CurrencyEnum.EnumType]: number,
	},

	BaseInfo: {
		UnlockedFloors: number,
		[Floor]: {
			[BaseDisplayPlatform]: {
				["CharacterId"]: string?,
				["CollectedCash"]: number,
			},
		},
	},

	CashBoosts: {
		RebirthMultiplier: number,
		SkinBoost: number,
		FriendsBoost: number,
	},
	CashPerSecond: number,

	TutorialStage: number,
	CompletedTutorial: boolean,

	DiscoveredCharacters: {
		[string]: { string },
	},

	PurchaseHistory: {
		[string]: { number },
	},

	Codes: { string },

	BaseSkins: { string },

	Upgrades: {
		["CarryCapacity"]: number,
		["Pickaxe"]: number,
		["Walkspeed"]: number,
	},

	CollectedCharacters: {
		[CharacterId]: {
			Name: CharacterNameEnum.EnumType,
			Rarity: RarityEnum.EnumType,
			CashPerSecond: number,
			Level: number,
			Mutation: MutationEnum.EnumType,
			Trait: TraitsEnum.EnumType,
			Placed: boolean,
		},
	},

	Settings: {
		Music: number,
		SFX: number,
		VFX: boolean,
		Important: boolean,
		Unimportant: boolean,
		BrainrotDetector: boolean,
		OnScreenOffers: boolean,
	},

	BrainrotDetector: boolean,
	Rebirths: number,
	CarryingCapacity: number, -- Number of Brainrot characters a player can carry at once
	InventoryCapacity: number, -- Maximum number of Brainrot characters the player can store in their inventory
	MovementSpeed: number, -- Upgradable walk speed
	ThievesTools: { WeaponNameEnum.EnumType }, -- List of owned PvP stealing tools (e.g., Bat)

	HasSecret: boolean?, -- Test value for now
}

return nil
