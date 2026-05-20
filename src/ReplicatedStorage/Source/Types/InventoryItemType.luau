local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)

export type ITEM_TYPE = {
	ItemName: string,
	ItemType: "Pickaxe" | "Weapon" | "Character",
	Model: Instance?,
	Rarity: number?,
	CashPerSecond: number?,
	Mutation: MutationEnum.EnumType?,
	IsMutated: boolean?,
	IsEquipped: boolean?,
	SortPriority: number?,
	CharacterId: string?,
}


return nil
