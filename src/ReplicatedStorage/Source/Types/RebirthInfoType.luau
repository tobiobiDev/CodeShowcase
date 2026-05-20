--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)

export type RebirthInfo = {
	Config: {
		read BonusIncrease: number,
		read MaxRebirth: number,
		read UpgradesPerRebirth: number,
		read FloorIncreaseRebirth: number,
		read RebirthIncrease: { { Rebirth: number, value: number } },
	},

	Requirements: {
		{
			read RebirthAmount: number,
			read Character: CharacterNameEnum.EnumType?,
			read PickaxeUpgrade: number?,
			read OwnedCharacters: {
				read Rarity: RarityEnum.EnumType,
				read Amount: number,
			}?,
		}
	},
}

return nil
