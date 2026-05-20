--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterEarningService = require(ServerScriptService.Source.Systems.CharacterSystem.CharacterEarningService)
local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local CurrencyEnum = require(ReplicatedStorage.Source.Enums.CurrencyEnum)
local DeveloperIds = require(ServerScriptService.Source.Data.DeveloperIds)
local LeaderstatsEnum = require(ReplicatedStorage.Source.Enums.LeaderstatsEnum)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local Network = require(ReplicatedStorage.Source.Libs.Network)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local Signal = require(ReplicatedStorage.Source.Libs.Signal)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)
local WeaponNameEnum = require(ReplicatedStorage.Source.Enums.WeaponNameEnum)
local tryGetPlayerProfile = require(script.Parent.tryGetPlayerProfile)

type PlayerData = tryGetPlayerProfile.PlayerData
type CharacterName = CharacterNameEnum.EnumType
type Leaderstat = LeaderstatsEnum.EnumType

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local PlayerDataService = {}

PlayerDataService.Signals = {
	UpdateLeaderstats = Signal.new() :: Signal.Signal<Player, Leaderstat, number>,
	PickaxeLevelUpdated = Signal.new() :: Signal.Signal<Player, number>,
	UpdateTutorialStage = Signal.new() :: Signal.Signal<Player, number>,
	TutorialCompleted = Signal.new() :: Signal.Signal<Player, boolean>,
	NewThievesToolAdded = Signal.new() :: Signal.Signal<Player, string>,
	CollectedNewCharacter = Signal.new() :: Signal.Signal<Player>,
	WalkspeedUpdated = Signal.new() :: Signal.Signal<Player, number>,
}

--[[
    Used to adjust a player's given currency type by the given amount.
    Supports both positive and negative numbers. Updates leaderstats.
]]
function PlayerDataService.AdjustCurrency(player: Player, currencyType: CurrencyEnum.EnumType, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Currency[currencyType] += amount
	local newBalance = profile.Currency[currencyType]
	Network.fireClient(Network.RemoteEvents.CurrencyChanged, player, currencyType, newBalance)
	PlayerDataService.Signals.UpdateLeaderstats:Fire(player, "Cash", newBalance)

	-- For dev console
	if table.find(DeveloperIds, player.UserId) then
		Network.fireClient(Network.RemoteEvents.AdjustCurrency, player, newBalance)
	end

	logger.log(`Successfully adjusted {player.Name}'s {currencyType} by {amount}. New value: {newBalance}`)
end

--[[
    Used to update a player's cash per second value by the given amount.
    Supports both positive and negative values. Updates leaderstats.
]]
function PlayerDataService.AdjustCashPerSecond(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CashPerSecond = amount
	local newAmount = profile.CashPerSecond
	Network.fireClient(Network.RemoteEvents.CurrencyChanged, player, newAmount)
	PlayerDataService.Signals.UpdateLeaderstats:Fire(player, "CashPerSecond", newAmount)

	logger.log(`Successfully adjusted {player.Name}'s CashPerSecond by ${amount}. New value: ${newAmount}/s`)
end

function PlayerDataService.SaveCollectedCharacter(
	player: Player,
	characterId: string,
	characterName: CharacterName,
	characterLevel: number,
	characterMutation: MutationEnum.EnumType,
	characterTrait: TraitsEnum.EnumType,
	characterRarity: RarityEnum.EnumType
)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local baseCharacterEarning = Characters[characterName].CashPerSecond
	local totalCashPerSecond = CharacterEarningService.ApplyEarningFormula(
		baseCharacterEarning,
		characterLevel,
		characterMutation,
		characterTrait
	)

	profile.CollectedCharacters[characterId] = {
		Name = characterName,
		Level = characterLevel,
		Mutation = characterMutation,
		Placed = false,
		Rarity = characterRarity,
		Trait = characterTrait,
		CashPerSecond = totalCashPerSecond,
	}

	Network.fireClient(
		Network.RemoteEvents.CollectedCharactersChanged,
		player,
		characterId,
		characterName,
		characterLevel,
		characterMutation,
		characterRarity,
		totalCashPerSecond
	)

	PlayerDataService.Signals.CollectedNewCharacter:Fire(player)
	logger.log(
		`Successfully added level {characterLevel} '{characterName}' character to {player.Name}'s profile with ID: {characterId}`
	)
end

function PlayerDataService.SavePlacedCharacter(
	player: Player,
	floorName: "Floor1" | "Floor2" | "Floor3",
	characterId: string,
	displayModelName: string
)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end
	profile.BaseInfo[floorName][displayModelName] = profile.BaseInfo[floorName][displayModelName]
		or { CharacterId = nil, CollectedCash = 0 }
	profile.BaseInfo[floorName][displayModelName].CharacterId = characterId
	profile.BaseInfo[floorName][displayModelName].CollectedCash = profile.BaseInfo[floorName][displayModelName].CollectedCash
		or 0
	profile.CollectedCharacters[characterId].Placed = true

	Network.fireClient(Network.RemoteEvents.CharacterPlaced, player, floorName, characterId, displayModelName)
	logger.log(
		`Successfully saved character with ID '{characterId}' in {player.Name}'s base on {floorName} at display '{displayModelName}'`
	)
end

function PlayerDataService.RemovePlacedCharacter(
	player: Player,
	floorName: "Floor1" | "Floor2" | "Floor3",
	displayModelName: string
)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	if profile.BaseInfo[floorName][displayModelName] then
		local characterId = profile.BaseInfo[floorName][displayModelName].CharacterId
		if characterId then
			profile.CollectedCharacters[characterId].Placed = false
		end

		profile.BaseInfo[floorName][displayModelName].CharacterId = nil
		if (profile.BaseInfo[floorName][displayModelName].CollectedCash or 0) <= 0 then
			profile.BaseInfo[floorName][displayModelName] = nil
		end
	end

	Network.fireClient(Network.RemoteEvents.CharacterUnplaced, player, floorName, displayModelName)
	logger.log(`Successfully removed placed character at {displayModelName} on {floorName} for {player.Name}`)
end

function PlayerDataService.RemoveCollectedCharacter(player: Player, characterId: string)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CollectedCharacters[characterId] = nil
	Network.fireClient(Network.RemoteEvents.CollectedCharacterRemoved, player, characterId)
	PlayerDataService.Signals.CollectedNewCharacter:Fire(player)
	logger.log(`Successfully removed collected character with id: {characterId} for {player.Name}`)
end

function PlayerDataService.UpgradeCharacter(player: Player, characterId: string, amount: number?)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local characterInfo = profile.CollectedCharacters[characterId]
	local baseCharacterEarning = Characters[characterInfo.Name].CashPerSecond
	characterInfo.Level += amount or 1
	characterInfo.CashPerSecond = CharacterEarningService.ApplyEarningFormula(
		baseCharacterEarning,
		characterInfo.Level,
		characterInfo.Mutation,
		characterInfo.Trait
	)

	Network.fireClient(
		Network.RemoteEvents.CharacterUpgraded,
		player,
		characterId,
		characterInfo.Level,
		characterInfo.CashPerSecond
	)
	logger.log(`Successfully upgraded character with id: {characterId} by {amount} levels for {player.Name}`)
end

function PlayerDataService.SaveDiscoveredCharacter(player: Player, characterName: string, mutation: string)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.DiscoveredCharacters[mutation] = profile.DiscoveredCharacters[mutation] or {}
	table.insert(profile.DiscoveredCharacters[mutation], characterName)

	Network.fireClient(Network.RemoteEvents.DiscoveredCharacterSaved, player, characterName, mutation)
	logger.log(`Successfully saved discovered character for {characterName} with {mutation} Mutation for {player.Name}`)
end

function PlayerDataService.IncreaseCarryCapacityUpgrade(player: Player)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Upgrades.CarryCapacity += 1
	Network.fireClient(Network.RemoteEvents.CarryCapacityUpgradeIncreased, player, profile.Upgrades.CarryCapacity)
	logger.log(`Successfully saved increase in carry capacity upgrade by 1 for {player.Name}`)
end

function PlayerDataService.SetCarryCapacity(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CarryingCapacity = amount
	Network.fireClient(Network.RemoteEvents.CarryCapacityChanged, player, amount)
	logger.log(`Successfully set players carry capacity to {amount} for {player.Name}`)
end

function PlayerDataService.IncreaseWalkspeedUpgrade(player: Player)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Upgrades.Walkspeed += 1
	Network.fireClient(Network.RemoteEvents.WalkspeedUpgradeIncreased, player, profile.Upgrades.Walkspeed)
	PlayerDataService.Signals.WalkspeedUpdated:Fire(player, profile.MovementSpeed)
	logger.log(`Successfully saved increase in walkspeed upgrade by 1 for {player.Name}`)
end

function PlayerDataService.SetWalkspeed(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.MovementSpeed = amount

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not humanoid then
		logger.log(`Failed to update {player.Name}'s WalkSpeed value: No Humanoid found in their character`, true)
		return
	end

	humanoid.WalkSpeed = amount

	Network.fireClient(Network.RemoteEvents.WalkSpeedChanged, player, amount)
	PlayerDataService.Signals.WalkspeedUpdated:Fire(player, profile.MovementSpeed)
	logger.log(`Successfully set players walkspeed to {amount} for {player.Name}`)
end

function PlayerDataService.SetPickaxeLevel(player: Player, newLevel: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Upgrades.Pickaxe = newLevel

	PlayerDataService.Signals.PickaxeLevelUpdated:Fire(player, newLevel)
	Network.fireClient(Network.RemoteEvents.PickaxeLevelChanged, player, newLevel)
	-- For Dev Console
	Network.fireClient(Network.RemoteEvents.SetPickaxeLevel, player, newLevel)
	logger.log(`Successfully set pickaxe to level {newLevel} for {player.Name}`)
end

function PlayerDataService.AdjustRebirth(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Rebirths += amount

	Network.fireClient(Network.RemoteEvents.RebirthsChanged, player, profile.Rebirths)
	logger.log(`Successfully adjusted rebirths for {player} by {amount} to {profile.Rebirths}`)
end

function PlayerDataService.SetCashMultiplier(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CashBoosts.RebirthMultiplier = amount
	Network.fireClient(Network.RemoteEvents.CashMultiplierChanged, player, amount)
	logger.log(`Successfully set cash multiplier for {player.Name} to {amount}`)
end

function PlayerDataService.SetSkinBoost(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CashBoosts.SkinBoost = amount
	Network.fireClient(Network.RemoteEvents.SkinBoostChanged, player, amount)
	logger.log(`Successfully set base skin cash boost for {player.Name} to {amount}`)
end

function PlayerDataService.SetFriendBoost(player: Player, amount: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CashBoosts.FriendsBoost = amount
	Network.fireClient(Network.RemoteEvents.FriendBoostChanged, player, amount)
	logger.log(`Successfully set friend cash boost for {player.Name} to {amount}`)
end

function PlayerDataService.AdjustUnlockedFloor(player: Player)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.BaseInfo.UnlockedFloors += 1
	Network.fireClient(Network.RemoteEvents.UnlockedNewFloor, player, profile.BaseInfo.UnlockedFloors)
	logger.log(
		`Successfully unlocked floor for {player.Name}, current unlocked floors: {profile.BaseInfo.UnlockedFloors}`
	)
end

function PlayerDataService.SaveBaseSkin(player: Player, mutationName: string)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	table.insert(profile.BaseSkins, mutationName)
	Network.fireClient(Network.RemoteEvents.BaseSkinSaved, player, mutationName)
	logger.log(`Successfully saved {mutationName} base skin for {player.Name}`)
end

function PlayerDataService.AddPlayTime(player: Player, addTime: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.PlayTime += addTime
	Network.fireClient(Network.RemoteEvents.PlayTimeUpdated, player, profile.PlayTime)
	logger.log(`Successfully added {addTime} play time to {player}.`)
end

function PlayerDataService.SetTutorialStage(player: Player, newTutorialStage: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.TutorialStage = newTutorialStage
	Network.fireClient(Network.RemoteEvents.TutorialStageChanged, player, newTutorialStage)
	PlayerDataService.Signals.UpdateTutorialStage:Fire(player, newTutorialStage)
	logger.log(`Successfully set Tutorial Stage for {player.Name} to {newTutorialStage}.`)
end

function PlayerDataService.SetTutorialCompleted(player: Player, isCompleted: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.CompletedTutorial = isCompleted
	Network.fireClient(Network.RemoteEvents.TutorialCompleted, player, isCompleted)
	PlayerDataService.Signals.TutorialCompleted:Fire(player, isCompleted)
	logger.log(`Successfully set Tutorial completion for {player.Name} to {isCompleted}.`)
end

function PlayerDataService.AddThievesTool(player: Player, thievesToolName: WeaponNameEnum.EnumType)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	if not WeaponNameEnum[thievesToolName] then
		logger.log(
			`Failed to add '{thievesToolName}' thieves tool to {player.Name} profile: Invalid weapon name passed`,
			true
		)
		return
	end

	table.insert(profile.ThievesTools, thievesToolName)
	Network.fireClient(Network.RemoteEvents.ThievesToolAdded, player, thievesToolName)
	PlayerDataService.Signals.NewThievesToolAdded:Fire(player, thievesToolName)
	logger.log(`Successfully added '{thievesToolName}' to {player.Name}'s owned Thieves Tools.`)
end

function PlayerDataService.ChangeMusicSetting(player: Player, value: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.Music = value
	Network.fireClient(Network.RemoteEvents.MusicSettingChanged, player, value)
	logger.log(`Successfully set music setting to {value}.`)
end

function PlayerDataService.ChangeSFXSetting(player: Player, value: number)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.SFX = value
	Network.fireClient(Network.RemoteEvents.SFXSettingChanged, player, value)
	logger.log(`Successfully set SFX setting to {value}.`)
end

function PlayerDataService.ChangeVFXSetting(player: Player, value: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.VFX = value
	Network.fireClient(Network.RemoteEvents.VFXSettingChanged, player, value)
	logger.log(`Successfully set sfx setting to {value}.`)
end

function PlayerDataService.ChangeImportantSetting(player: Player, value: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.Important = value
	Network.fireClient(Network.RemoteEvents.ImportantSettingChanged, player, value)
	logger.log(`Successfully set important notification setting to {value}.`)
end

function PlayerDataService.ChangeUnimportantSetting(player: Player, value: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.Unimportant = value
	Network.fireClient(Network.RemoteEvents.UnimportantSettingChanged, player, value)
	logger.log(`Successfully set unimportant notification setting to {value}.`)
end

function PlayerDataService.ChangeDetectorSetting(player: Player, value: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.BrainrotDetector = value
	Network.fireClient(Network.RemoteEvents.UnlockedBrainrotDetector, player, value)
	logger.log(`Successfully set brainrot detector setting to {value}.`)
end

function PlayerDataService.ChangeOnScreenSetting(player: Player, value: boolean)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.Settings.OnScreenOffers = value
	Network.fireClient(Network.RemoteEvents.OnScreenOffersChanged, player, value)
	logger.log(`Successfully set On-screen offers setting to {value}.`)
end

function PlayerDataService.UnlockBrainrotDetector(player: Player)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	profile.BrainrotDetector = true
	Network.fireClient(Network.RemoteEvents.UnlockedBrainrotDetector, player, true)
	logger.log(`Successfully unlocked brainrot detector for {player}.`)
end

Network.connectEvent(Network.RemoteEvents.AdjustCurrency, PlayerDataService.AdjustCurrency)
Network.connectEvent(Network.RemoteEvents.SetPickaxeLevel, PlayerDataService.SetPickaxeLevel)
Network.connectEvent(Network.RemoteEvents.WalkSpeedChanged, PlayerDataService.SetWalkspeed)

return PlayerDataService
