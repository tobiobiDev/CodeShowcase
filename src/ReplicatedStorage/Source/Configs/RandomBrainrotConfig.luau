--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)

type RandomBrainrot = {
	CYCLE_DURATION: number,
	TOTAL_ROLLING_LENGTH: number,
	LAST_ROLL_DURATION: number,
	TOTAL_ROLL_AMOUNT: number,
	LAST_ROLL_RARITY: RarityEnum.EnumType,
	REVEAL_DURATION: number,
	SHINE_ROTATE_DURATION: number,
}

local RandomBrainrotConfig: RandomBrainrot = {
	CYCLE_DURATION = 5, -- Duration of a cycle in viewport frame
	TOTAL_ROLLING_LENGTH = 8, -- Total duration of rolling animation
	LAST_ROLL_DURATION = 3.2, -- Duration of last roll
	TOTAL_ROLL_AMOUNT = 15, -- Total amount of rolls
	LAST_ROLL_RARITY = "Secret", -- rarity of last roll before reveal
	REVEAL_DURATION = 3, -- Duration of reveal
	SHINE_ROTATE_DURATION = 3, -- How long it takes to rotate 360 degrees, defines speed of rotation
}

return RandomBrainrotConfig
