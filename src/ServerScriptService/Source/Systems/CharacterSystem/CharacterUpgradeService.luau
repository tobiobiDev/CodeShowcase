--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotCharacterConfigs = require(ReplicatedStorage.Source.Configs.BrainrotCharacterConfigs)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local TraitsConfig = require(ReplicatedStorage.Source.Configs.TraitsConfig)
local tryGetPlayerProfile = require(ServerScriptService.Source.PlayerData.tryGetPlayerProfile)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local UPGRADE_PRICE_INCREASE = BrainrotCharacterConfigs.UPGRADE_PRICE_INCREASE
local MAX_LEVEL = BrainrotCharacterConfigs.MAX_LEVEL

local CharacterUpgradeService = {}

function CharacterUpgradeService.ApplyUpgradeFormula(baseUpgradePrice: number, characterLevel: number): number
	return math.floor(baseUpgradePrice * (UPGRADE_PRICE_INCREASE ^ (characterLevel - 1)))
end

function CharacterUpgradeService.GetUpgradePrice(player: Player, characterId: string): number | nil
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return nil
	end

	local characterInfo = profile.CollectedCharacters[characterId]
	if not characterInfo then
		logger.log(`Tried getting upgrade price for character id: {characterId} for {player} but they don't own it`)
		return nil
	end

	local characterName = characterInfo.Name
	local characterLevel = characterInfo.Level
	local characterMutation = characterInfo.Mutation
	local characterTrait = characterInfo.Trait

	local traitMultiplier = 1
	local maxLevelIncrease = 0

	if characterTrait then
		local boostData = TraitsConfig.Boost[characterTrait]
		if boostData and boostData.UpgradeDecrease then
			traitMultiplier = boostData.UpgradeDecrease
		end
		if boostData and boostData.MaxUpgradeIncrease then
			maxLevelIncrease = boostData.MaxUpgradeIncrease
		end
	end

	local baseUpgradePrice = Characters[characterName].BaseUpgradePrice * traitMultiplier
	local additionalLevels = BrainrotCharacterConfigs.MUTATION_INCREASE[characterMutation] or 0

	if characterLevel >= MAX_LEVEL + additionalLevels + maxLevelIncrease then
		logger.log(`{characterName} is already at max level`)
		return nil
	end

	local upgradePrice = CharacterUpgradeService.ApplyUpgradeFormula(baseUpgradePrice, characterLevel)

	return upgradePrice
end

return CharacterUpgradeService
