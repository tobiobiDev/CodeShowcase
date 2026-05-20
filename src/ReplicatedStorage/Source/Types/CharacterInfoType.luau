local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)

export type CharacterData = {
	Rarity: RarityEnum.EnumType,
	SpawnChance: number,
	CashPerSecond: number,
	BaseUpgradePrice: number,
}

export type CharacterInfo = {
	[CharacterNameEnum.EnumType]: CharacterData,
}

export type SpawnedCharacter = {
	Name: CharacterNameEnum.EnumType,
	Rarity: RarityEnum.EnumType,
	Level: number,
	Position: Vector3,
	Mutation: MutationEnum.EnumType,
	Trait: TraitsEnum.EnumType,
	Model: Model?,
	TimerGui: BillboardGui?,
	TimerLabel: TextLabel?,
	TimeToDespawn: number,
	IsCarried: boolean,
}

export type CollectedCharacterInfo = {
	Name: CharacterNameEnum.EnumType,
	Level: number,
	Mutation: MutationEnum.EnumType,
	Trait: TraitsEnum.EnumType,
	Placed: boolean,
	Rarity: RarityEnum.EnumType,
	CashPerSecond: number,
}

return nil
