--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)
local applyTypeIndexer = require(ReplicatedStorage.Source.Utility.applyTypeIndexer)

type boostOptionsType = {
	CashBoost: number?,
	UpgradeDecrease: number?,
	SellValueIncrease: number?,
	MaxUpgradeIncrease: number?,
	BoostNearby: number?,
}?

type ColorOptionsType = {
	Color: Color3,
	Effect: string?,
}

type ChanceType = applyTypeIndexer.apply<TraitsEnum.EnumType, number>
type BoostType = applyTypeIndexer.apply<TraitsEnum.EnumType, boostOptionsType>
type ColorType = applyTypeIndexer.apply<TraitsEnum.EnumType, ColorOptionsType>

export type TraitType = {
	read Chance: ChanceType,
	read Boost: BoostType,
	read Color: ColorType,
}

return nil
