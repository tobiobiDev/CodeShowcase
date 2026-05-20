--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)

export type CharacterRarity = {
	[RarityEnum.EnumType]: {
		priorityIndex: number,
		MinimumLevel: number, -- Minimum level this rarity of character can spawn at
		MaximumLevel: number, -- Maximum level this rarity of character can spawn at
		BaseSpawnNumber: number, -- How many characters of this rarity are spawned at start
		-- ^ Also serves as maximum characters per rarity

		MinimumTime: number, -- Minimum despawn time
		MaximumTime: number, -- Maximum despawn time

		AutomaticRespawn: boolean,
		rarityColor: Color3, -- color of the rarity
	},
}

return nil
