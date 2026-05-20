--!strict
local CharacterInfoService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local EasyVisuals = require(ReplicatedStorage.Source.Libs.EasyVisuals)
local GetThresholdValue = require(ReplicatedStorage.Source.Utility.GetThresholdValue)
local LevelColorConfig = require(ServerScriptService.Source.Configs.LevelColorConfig)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local MutationsConfig = require(ReplicatedStorage.Source.Configs.MutationsConfig)
local RarityConfig = require(ServerScriptService.Source.Configs.RarityConfig)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local TraitsConfig = require(ReplicatedStorage.Source.Configs.TraitsConfig)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)
local formatNumber = require(ReplicatedStorage.Source.Utility.formatNumber)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

type CharacterName = CharacterNameEnum.EnumType
type Rarity = RarityEnum.EnumType

local assetFolder = assert(ReplicatedStorage:FindFirstChild("Assets"), "Assets folder not found in ReplicatedStorage")
local rarityGradients = assert(
	assetFolder:FindFirstChild("RarityGradients"),
	"RarityGradients folder not found in ReplicatedStorage.Assets"
)

function CharacterInfoService.GetRarityByName(characterName: CharacterName): Rarity?
	local info = Characters[characterName]
	return if info then info.Rarity else nil
end

--[[
	Updates Surface GUI inside characters model
]]
function CharacterInfoService.UpdateUiInfo(
	characterClone: Model,
	characterName: CharacterName,
	characterLevel: number,
	cashPerSecond: number,
	characterMutation: MutationEnum.EnumType,
	characterTrait: TraitsEnum.EnumType
): boolean?
	local characterTorso = characterClone:FindFirstChild("Torso")
	if not (characterTorso and characterTorso:IsA("BasePart")) then
		logger.log(`Torso not found for {characterClone.Name}`)
		return nil
	end

	local billboardUi = characterTorso:FindFirstChild("BillboardGui")
	if not (billboardUi and billboardUi:IsA("BillboardGui")) then
		logger.log(`BillboardGui not found for {characterClone.Name}`)
		return nil
	end

	billboardUi.Enabled = true

	local cashPerSecondLabel = billboardUi:FindFirstChild("CashPerSecond") :: TextLabel?
	local levelLabel = billboardUi:FindFirstChild("Level") :: TextLabel?
	local nameLabel = billboardUi:FindFirstChild("Name") :: TextLabel?
	local rarityLabel = billboardUi:FindFirstChild("Rarity") :: TextLabel?
	local mutationLabel = billboardUi:FindFirstChild("Mutation") :: TextLabel?
	local traitLabel = billboardUi:FindFirstChild("Trait") :: TextLabel?

	local characterInfo = Characters[characterName]
	if not characterInfo then
		logger.log(`Character data not found for {characterName}`, true)
		return nil
	end

	local characterRarity = CharacterInfoService.GetRarityByName(characterName)

	if cashPerSecondLabel and cashPerSecond then
		cashPerSecondLabel.Text = `${formatNumber(cashPerSecond)}/s`
	end

	if levelLabel and characterLevel then
		local levelColor = GetThresholdValue.GetThresholdValue(LevelColorConfig, characterLevel) :: Color3
		levelLabel.Text = `Lvl.{characterLevel}`
		levelLabel.TextColor3 = levelColor
	end

	if nameLabel then
		nameLabel.Text = characterName
	end

	if mutationLabel and characterMutation and characterMutation ~= "Normal" then
		local mutationColor = MutationsConfig.Color[characterMutation]

		mutationLabel.Text = characterMutation
		mutationLabel.TextColor3 = mutationColor
		mutationLabel.Visible = true
	end

	if traitLabel and characterTrait and characterTrait ~= "Traitless" then
		local traitColor = TraitsConfig.Color[characterTrait].Color
		local effect = TraitsConfig.Color[characterTrait].Effect

		traitLabel.Text = `Trait: {characterTrait}`
		traitLabel.TextColor3 = traitColor

		if effect then
			EasyVisuals.new(traitLabel, effect, 0.5, 3)
		end

		traitLabel.Visible = true
	end

	if rarityLabel and characterRarity then
		local rarityGradient = rarityGradients:FindFirstChild(`{characterRarity}Gradient`) :: UIGradient
		local rarityColor = RarityConfig[characterRarity].rarityColor

		if rarityGradient then
			rarityGradient:Clone().Parent = rarityLabel
		end

		rarityLabel.Text = characterRarity
		rarityLabel.TextColor3 = rarityColor or Color3.new(1, 1, 1)
	end

	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	local despawnTimerGui = if assetsFolder then assetsFolder:FindFirstChild("DespawnTimer") else nil
	if not (despawnTimerGui and despawnTimerGui:IsA("BillboardGui")) then
		return nil
	end

	local despawnTimerGuiClone = despawnTimerGui:Clone()
	despawnTimerGuiClone.Adornee = characterTorso
	despawnTimerGuiClone.Enabled = false
	despawnTimerGuiClone.Parent = characterTorso
	return true
end

function CharacterInfoService.GetRandomLevel(rarity: Rarity): number?
	local rarityData = RarityConfig[rarity]
	if not rarityData then
		logger.log(`Rarity data for {rarity} not found`, true)
		return nil
	end

	local minimumLevel = rarityData.MinimumLevel
	local maximumLevel = rarityData.MaximumLevel

	return math.random(minimumLevel, maximumLevel)
end

function CharacterInfoService.Setup()
	local assetsFolder =
		assert(ReplicatedStorage:FindFirstChild("Assets"), "ReplicatedStorage is missing 'Assets' folder")
	local charactersFolder =
		assert(assetsFolder:FindFirstChild("Characters"), "Assets folder is missing 'Characters' folder")
	local charactersTools =
		assert(ServerStorage:FindFirstChild("CharacterTools"), "ServerStorage is missing 'CharacterTools' folder")

	for _, descendant in charactersFolder:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end

	for _, descendant in charactersTools:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end
end

return CharacterInfoService
