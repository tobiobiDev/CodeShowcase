--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotCharacterConfigs = require(ReplicatedStorage.Source.Configs.BrainrotCharacterConfigs)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local MutationsConfig = require(ReplicatedStorage.Source.Configs.MutationsConfig)
local TraitsConfig = require(ReplicatedStorage.Source.Configs.TraitsConfig)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)
local tryGetPlayerProfile = require(ServerScriptService.Source.PlayerData.tryGetPlayerProfile)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local UPGRADE_CASH_INCREASE = BrainrotCharacterConfigs.UPGRADE_CASH_INCREASE
local SELL_PRICE_MULTIPLIER = BrainrotCharacterConfigs.SELL_PRICE_MULTIPLIER
local OFFLINE_EARNING_MULTIPLIER = BrainrotCharacterConfigs.OFFLINE_EARNING_MULTIPLIER

type Floor = "Floor1" | "Floor2" | "Floor3"
type DisplayName = string

type ReturnTable = {
	-- Tracks how much each display per floor has collected
	[Floor]: {
		[DisplayName]: number,
	},
}
type baseInfo = {
	Owner: Player?,
	Skin: string?,
	TotalEarning: number?,

	-- Tracks how much each display per floor has collected
	[Floor]: {
		[DisplayName]: number,
	},
}

local CharacterEarningService = {}

--[[
	Applies formula for earning, called by multiple systems
]]
function CharacterEarningService.ApplyEarningFormula(
	baseCharacterEarning: number,
	characterLevel: number,
	characterMutation: MutationEnum.EnumType?,
	characterTrait: TraitsEnum.EnumType?,
	proximityMultiplier: number?
)
	local leveledEarning = math.floor(baseCharacterEarning * (UPGRADE_CASH_INCREASE ^ (characterLevel - 1)))
	local mutationMultiplier = if characterMutation then MutationsConfig.Multiplier[characterMutation] else 1
	local traitMultiplier = 1
	local realProximityMultiplier = proximityMultiplier or 1
	if characterTrait then
		local boostData = TraitsConfig.Boost[characterTrait]
		if boostData and boostData.CashBoost then
			traitMultiplier = boostData.CashBoost
		end
	end

	local finalEarning = leveledEarning * mutationMultiplier * traitMultiplier * realProximityMultiplier
	return finalEarning
end

--[[
	Returns how much character earns online per second
]]
function CharacterEarningService.GetEarningPerSecond(
	player: Player,
	characterId: string,
	proximityMultiplier: number?
): number
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return 0
	end

	local collectedCharacters = profile.CollectedCharacters
	local characterInfo = collectedCharacters[characterId]

	if not characterInfo then
		logger.log(`{player} does not own character he is trying to get earning off, character id: {characterId}`)
		return 0
	end

	local cashMultiplier = profile.CashBoosts.RebirthMultiplier
	local characterName = characterInfo.Name
	local baseCharacterEarning = Characters[characterName].CashPerSecond
	local characterLevel = characterInfo.Level
	local characterMutation = characterInfo.Mutation
	local characterTrait = characterInfo.Trait

	local characterEarning = CharacterEarningService.ApplyEarningFormula(
		baseCharacterEarning,
		characterLevel,
		characterMutation,
		characterTrait,
		proximityMultiplier
	)

	local multipliedEarning = characterEarning
		* (cashMultiplier + (profile.CashBoosts.FriendsBoost + profile.CashBoosts.SkinBoost) / 100)
	return multipliedEarning
end

--[[
	Returns how much character earns offline per second
]]
function CharacterEarningService.GetOfflineEarning(player: Player, characterId: string): number
	local onlineEarning = CharacterEarningService.GetEarningPerSecond(player, characterId)
	if onlineEarning then
		return onlineEarning * OFFLINE_EARNING_MULTIPLIER
	end

	return 0
end

function CharacterEarningService.OfflineEarning(player: Player, playerBase: baseInfo): ReturnTable?
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return nil
	end
	local lastTimeOnline = profile.lastOnline or os.time()
	local now = os.time()

	local returnTable: ReturnTable = {}

	for floorName, floorInfo in profile.BaseInfo do
		if type(floorInfo) ~= "table" then
			continue
		end

		playerBase[floorName] = playerBase[floorName] or {}

		for displayName, displayInfo in floorInfo do
			local characterId = displayInfo.CharacterId
			if not characterId then
				playerBase[floorName][displayName] = (displayInfo.CollectedCash or 0)
				logger.log(
					`{displayName} on {floorName} in {player} Base has {playerBase[floorName][displayName]} Cash`
				)
				continue
			end

			local offlineRate = CharacterEarningService.GetOfflineEarning(player, characterId)
			local amountGained = (now - lastTimeOnline) * offlineRate

			returnTable[floorName] = returnTable[floorName] or {}
			returnTable[floorName][displayName] = amountGained

			logger.log(`{player} earned {amountGained} Cash while offline at {displayName} on {floorName}`)
		end
	end

	return returnTable
end

function CharacterEarningService.GetSellPrice(player: Player, characterId: string): number | nil
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return nil
	end
	local characterTrait = profile.CollectedCharacters[characterId].Trait
	local cashPerSecond = CharacterEarningService.GetEarningPerSecond(player, characterId)
	local traitMultiplier = 1
	if characterTrait then
		local boostData = TraitsConfig.Boost[characterTrait]
		if boostData and boostData.SellValueIncrease then
			traitMultiplier = boostData.SellValueIncrease
		end
	end

	if not cashPerSecond then
		logger.log(`{player} failed to get sell price for characterId: {characterId}`)
		return nil
	end

	local sellAmount = cashPerSecond * SELL_PRICE_MULTIPLIER * traitMultiplier
	return sellAmount
end

return CharacterEarningService
