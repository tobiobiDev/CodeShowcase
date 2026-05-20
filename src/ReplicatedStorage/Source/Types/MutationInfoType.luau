--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local applyTypeIndexer = require(ReplicatedStorage.Source.Utility.applyTypeIndexer)

export type BaseColor = "Normal" | "Silver" | "Diamond" | "Gold" | "Ruby" | "Blaze"
export type ColorIndex = "Primary" | "Secondary" | "Tertiary"

type ChanceType = applyTypeIndexer.apply<MutationEnum.EnumType, number>

type MultiplierType = applyTypeIndexer.apply<MutationEnum.EnumType, number>
type SkinMultiplierType = applyTypeIndexer.apply<BaseColor, number>

type ColorType = applyTypeIndexer.apply<MutationEnum.EnumType, Color3>

type BaseColorTable = applyTypeIndexer.apply<ColorIndex, Color3>
type BaseColorsType = applyTypeIndexer.apply<BaseColor, BaseColorTable>

export type MutationType = {
	read Chance: ChanceType,
	read Multiplier: MultiplierType,
	read Color: ColorType,
	read SkinCashBoost: SkinMultiplierType,
	read BaseColors: BaseColorsType,
	read MutationImage: { [MutationEnum.EnumType]: string }
}

return nil
