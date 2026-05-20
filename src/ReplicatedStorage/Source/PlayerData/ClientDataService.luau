--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local CurrencyEnum = require(ReplicatedStorage.Source.Enums.CurrencyEnum)
local InventoryItemType = require(ReplicatedStorage.Source.Types.InventoryItemType)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local Network = require(ReplicatedStorage.Source.Libs.Network)
local PlayerDataType = require(ReplicatedStorage.Source.Types.PlayerDataType)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local Signal = require(ReplicatedStorage.Source.Libs.Signal)
local SoundEffects = require(ReplicatedStorage.Source.Utility.SoundEffects)
local WeaponNameEnum = require(ReplicatedStorage.Source.Enums.WeaponNameEnum)

type PlayerData = PlayerDataType.PlayerData

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

--[[
	Handles all client-side data manipulation including getting the player's
	profile from the server and connecting to various events that fire when a
	player's data changes on the server. This then updates the client-side
	version of their profile data to stay in sync.
]]
local ClientDataService = {}

--[[
	Currently playing sound and VFX here until Signal gets fixed
]]

local miscSounds = assert(SoundService:FindFirstChild("Misc"), "No Misc folder found in SoundService")

local isDataLoaded = false
local playerProfile: PlayerData? = nil

local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
local weaponsFolder = if assetsFolder then assetsFolder:FindFirstChild("Weapons") else nil
local pickaxeFolder = if assetsFolder then assetsFolder:FindFirstChild("Pickaxes") else nil

-- Public API for Signals
ClientDataService.Signals = {
	LoadingScreenFinished = Signal.new() :: Signal.Signal<>,
	-- Player Data Signals
	CurrencyChanged = Signal.new() :: Signal.Signal<CurrencyEnum.EnumType, number, boolean>,
	UpdatePickaxeLevel = Signal.new() :: Signal.Signal<number>,
	UpdateCurrentlyCarried = Signal.new() :: Signal.Signal<string, boolean>,
	UpdateWalkSpeed = Signal.new() :: Signal.Signal<number>,
	UpdateRebirths = Signal.new() :: Signal.Signal<number>,
	UpdateTutorialStage = Signal.new() :: Signal.Signal<number>,
	UpdateTutorialCompleted = Signal.new() :: Signal.Signal<boolean>,
	MusicSettingChanged = Signal.new() :: Signal.Signal<number>,
	OnScreenSettingChanged = Signal.new() :: Signal.Signal<boolean>,
	SFXSettingChanged = Signal.new() :: Signal.Signal<number>,
	VFXSettingChanged = Signal.new() :: Signal.Signal<boolean>,
	ImportantSettingChanged = Signal.new() :: Signal.Signal<boolean>,
	UnimportantSettingChanged = Signal.new() :: Signal.Signal<boolean>,
	CollectedCharactersChanged = Signal.new() :: Signal.Signal<string>,
	CharacterPlaced = Signal.new() :: Signal.Signal<string>,
	CharacterPickedUp = Signal.new() :: Signal.Signal<string>,
	RemoveCollectedCharacter = Signal.new() :: Signal.Signal<string>,
	TheivesToolAdded = Signal.new() :: Signal.Signal<InventoryItemType.ITEM_TYPE>,
	PickaxeModelChanged = Signal.new() :: Signal.Signal<InventoryItemType.ITEM_TYPE>,
}

-- Separate Signal for when data is loaded to ensure nothing happens before this.
ClientDataService.loaded = Signal.new()

--[[
    Get the player's full data profile from the server-side tryGetPlayerProfile.
]]
local function loadClientProfile()
	if isDataLoaded then
		return
	end

	local success, profile = Network.invokeServerAsync(Network.RemoteFunctions.GetProfileData)

	if not success then
		logger.log(`Failed to initially retrieve player profile data: {tostring(profile)}`, true)
		return
	end

	playerProfile = profile
	isDataLoaded = true
	ClientDataService.loaded:Fire()
end

--[[
    A rarely used function to get the entire data profile for the player.
]]
function ClientDataService.GetProfile(): PlayerData?
	if not isDataLoaded then
		loadClientProfile()
	end
	return playerProfile
end

--[[
    Called by the `ClientStart` LocalScript in ReplicatedFirst, not the ModuleLoader.
]]
function ClientDataService.init()
	loadClientProfile()
	if playerProfile then
		ClientDataService.Signals.UpdatePickaxeLevel:Fire(playerProfile.Upgrades.Pickaxe)
	end
end

function ClientDataService.hasLoaded(): boolean
	return isDataLoaded
end

--[[
    Used to get the current walk speed in case it has been modified.
    @return The current base walk speed.
]]
function ClientDataService.getWalkSpeed(): number?
	if not playerProfile then
		return nil
	end
	return playerProfile.MovementSpeed
end

local function onCurrencyChange(currencyType: CurrencyEnum.EnumType, newBalance: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	local currency = (playerProfile :: PlayerData).Currency

	if currency[currencyType] == newBalance then
		return
	end

	local playSound = if newBalance > currency[currencyType] then true else false

	currency[currencyType] = newBalance
	ClientDataService.Signals.CurrencyChanged:Fire(currencyType, newBalance, playSound)
end

local function onCharacterCollectedUpdate(characterId: string, isCollected: boolean, trulyCollected: boolean)
	ClientDataService.Signals.UpdateCurrentlyCarried:Fire(characterId, isCollected)

	local sound = miscSounds:FindFirstChild("BrainrotCollected")
	if (sound and sound:IsA("Sound")) and trulyCollected then
		SoundEffects.PlaySound(sound)
	end
end

local function onPickaxeLevelUpdate(newLevel: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Upgrades.Pickaxe = newLevel
	ClientDataService.Signals.UpdatePickaxeLevel:Fire(newLevel)
end

local function onWalkSpeedUpdate(newWalkSpeed: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).MovementSpeed = newWalkSpeed
	ClientDataService.Signals.UpdateWalkSpeed:Fire(newWalkSpeed)
end

local function onRebirthsUpdate(newRebirthAmount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Rebirths = newRebirthAmount
	ClientDataService.Signals.UpdateRebirths:Fire(newRebirthAmount)
end

local function onTutorialStageChange(newTutorialStage: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).TutorialStage = newTutorialStage
	ClientDataService.Signals.UpdateTutorialStage:Fire(newTutorialStage)
end

local function onTutorialCompleted(isCompleted: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CompletedTutorial = isCompleted
	ClientDataService.Signals.UpdateTutorialCompleted:Fire(isCompleted)
end

local function musicSettingChanged(value: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end
	(playerProfile :: PlayerData).Settings.Music = value
	ClientDataService.Signals.MusicSettingChanged:Fire(value)
end

local function sfxSettingChanged(value: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end
	(playerProfile :: PlayerData).Settings.SFX = value
	ClientDataService.Signals.SFXSettingChanged:Fire(value)
end

local function vfxSettingChanged(value: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Settings.VFX = value
	ClientDataService.Signals.VFXSettingChanged:Fire(value)
end

local function importantSettingChanged(value: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Settings.Important = value
	ClientDataService.Signals.ImportantSettingChanged:Fire(value)
end

local function unimportantSettingChanged(value: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Settings.Unimportant = value
	ClientDataService.Signals.UnimportantSettingChanged:Fire(value)
end

local function onScreenSettingChanged(value: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Settings.OnScreenOffers = value
	ClientDataService.Signals.OnScreenSettingChanged:Fire(value)
end

local function collectedCharactersChanged(
	characterId: string,
	characterName: CharacterNameEnum.EnumType,
	characterLevel: number,
	characterMutation: MutationEnum.EnumType,
	characterRarity: RarityEnum.EnumType,
	cashPerSecond: number
)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CollectedCharacters[characterId] = {
		Name = characterName,
		Level = characterLevel,
		Mutation = characterMutation,
		Placed = false,
		Rarity = characterRarity,
		CashPerSecond = cashPerSecond,
	}

	ClientDataService.Signals.CollectedCharactersChanged:Fire(characterId)
end

local function onCharacterPlaced(
	floorName: "Floor1" | "Floor2" | "Floor3",
	characterId: string,
	displayModelName: string
)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	local profile = playerProfile :: PlayerData
	profile.BaseInfo[floorName][displayModelName] = profile.BaseInfo[floorName][displayModelName]
		or { CharacterId = nil, CollectedCash = 0 }
	profile.BaseInfo[floorName][displayModelName].CharacterId = characterId

	local characterInfo = profile.CollectedCharacters[characterId]
	characterInfo.Placed = true

	ClientDataService.Signals.CharacterPlaced:Fire(characterId)
end

local function onCharacterUnplaced(floorName: "Floor1" | "Floor2" | "Floor3", displayModelName: string)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	local profile = playerProfile :: PlayerData
	if profile.BaseInfo[floorName][displayModelName] then
		local characterId = profile.BaseInfo[floorName][displayModelName].CharacterId
		local characterInfo = if characterId then profile.CollectedCharacters[characterId] else nil
		if characterInfo then
			characterInfo.Placed = false
			ClientDataService.Signals.CharacterPickedUp:Fire(characterId :: string)
		end
		profile.BaseInfo[floorName][displayModelName].CharacterId = nil
	end
end

local function onCollectedCharacterRemoved(characterId: string)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CollectedCharacters[characterId] = nil
	ClientDataService.Signals.RemoveCollectedCharacter:Fire(characterId)
end

local function onCharacterUpgraded(characterId: string, newLevel: number, newCashPerSecond: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	local characterInfo = (playerProfile :: PlayerData).CollectedCharacters[characterId]
	if characterInfo then
		characterInfo.Level = newLevel
		characterInfo.CashPerSecond = newCashPerSecond
	end
end

local function onDiscoveredCharacterSaved(characterName: string, mutation: string)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	local profile = playerProfile :: PlayerData
	profile.DiscoveredCharacters[mutation] = profile.DiscoveredCharacters[mutation] or {}
	table.insert(profile.DiscoveredCharacters[mutation], characterName)
end

local function onCarryCapacityUpgradeIncreased(newUpgradeLevel: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Upgrades.CarryCapacity = newUpgradeLevel
end

local function onCarryCapacityChanged(amount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CarryingCapacity = amount
end

local function onWalkspeedUpgradeIncreased(newUpgradeLevel: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).Upgrades.Walkspeed = newUpgradeLevel
end

local function onCashMultiplierChanged(amount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CashBoosts.RebirthMultiplier = amount
end

local function onSkinBoostChanged(amount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CashBoosts.SkinBoost = amount
end

local function onFriendBoostChanged(amount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).CashBoosts.FriendsBoost = amount
end

local function onUnlockedNewFloor(newFloorCount: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).BaseInfo.UnlockedFloors = newFloorCount
end

local function onBaseSkinSaved(mutationName: string)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	table.insert((playerProfile :: PlayerData).BaseSkins, mutationName)
end

local function onPlayTimeUpdated(newPlayTime: number)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).PlayTime = newPlayTime
end

local function onThievesToolAdded(thievesToolName: WeaponNameEnum.EnumType)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	table.insert((playerProfile :: PlayerData).ThievesTools, thievesToolName)

	local foundModel = if weaponsFolder then weaponsFolder:FindFirstChild(thievesToolName) else nil
	local weaponModel = if foundModel then foundModel:Clone() else nil

	local itemData: InventoryItemType.ITEM_TYPE = {
		ItemName = thievesToolName,
		ItemType = "Weapon",
		Model = if weaponModel then weaponModel else warn(`Failed to find weapon model for inventory display`),
		SortPriority = 2,
	}

	ClientDataService.Signals.TheivesToolAdded:Fire(itemData)
end

local function onBrainrotDetectorUnlocked(value: boolean)
	if not playerProfile then
		ClientDataService.loaded:Wait()
	end

	(playerProfile :: PlayerData).BrainrotDetector = value
end

local function onPickaxeModelChanged(replacementPickaxeName: string)
	local foundModel = if pickaxeFolder then pickaxeFolder:FindFirstChild(replacementPickaxeName) else nil
	local pickaxeModel = if foundModel then foundModel:Clone() else nil
	local itemData: InventoryItemType.ITEM_TYPE = {
		ItemName = replacementPickaxeName,
		ItemType = "Pickaxe",
		Model = if pickaxeModel then pickaxeModel else warn(`Failed to find pickaxe model for inventory display`),
		SortPriority = 1,
	}

	ClientDataService.Signals.PickaxeModelChanged:Fire(itemData)
end

Network.connectEvent(Network.RemoteEvents.CurrencyChanged, onCurrencyChange)
Network.connectEvent(Network.RemoteEvents.CharacterCollected, onCharacterCollectedUpdate)
Network.connectEvent(Network.RemoteEvents.PickaxeLevelChanged, onPickaxeLevelUpdate)
Network.connectEvent(Network.RemoteEvents.WalkSpeedChanged, onWalkSpeedUpdate)
Network.connectEvent(Network.RemoteEvents.RebirthsChanged, onRebirthsUpdate)
Network.connectEvent(Network.RemoteEvents.TutorialStageChanged, onTutorialStageChange)
Network.connectEvent(Network.RemoteEvents.TutorialCompleted, onTutorialCompleted)
Network.connectEvent(Network.RemoteEvents.MusicSettingChanged, musicSettingChanged)
Network.connectEvent(Network.RemoteEvents.SFXSettingChanged, sfxSettingChanged)
Network.connectEvent(Network.RemoteEvents.VFXSettingChanged, vfxSettingChanged)
Network.connectEvent(Network.RemoteEvents.ImportantSettingChanged, importantSettingChanged)
Network.connectEvent(Network.RemoteEvents.UnimportantSettingChanged, unimportantSettingChanged)
Network.connectEvent(Network.RemoteEvents.OnScreenOffersChanged, onScreenSettingChanged)
Network.connectEvent(Network.RemoteEvents.CollectedCharactersChanged, collectedCharactersChanged)
Network.connectEvent(Network.RemoteEvents.CharacterPlaced, onCharacterPlaced)
Network.connectEvent(Network.RemoteEvents.CharacterUnplaced, onCharacterUnplaced)
Network.connectEvent(Network.RemoteEvents.CollectedCharacterRemoved, onCollectedCharacterRemoved)
Network.connectEvent(Network.RemoteEvents.CharacterUpgraded, onCharacterUpgraded)
Network.connectEvent(Network.RemoteEvents.DiscoveredCharacterSaved, onDiscoveredCharacterSaved)
Network.connectEvent(Network.RemoteEvents.CarryCapacityUpgradeIncreased, onCarryCapacityUpgradeIncreased)
Network.connectEvent(Network.RemoteEvents.CarryCapacityChanged, onCarryCapacityChanged)
Network.connectEvent(Network.RemoteEvents.WalkspeedUpgradeIncreased, onWalkspeedUpgradeIncreased)
Network.connectEvent(Network.RemoteEvents.CashMultiplierChanged, onCashMultiplierChanged)
Network.connectEvent(Network.RemoteEvents.SkinBoostChanged, onSkinBoostChanged)
Network.connectEvent(Network.RemoteEvents.FriendBoostChanged, onFriendBoostChanged)
Network.connectEvent(Network.RemoteEvents.UnlockedNewFloor, onUnlockedNewFloor)
Network.connectEvent(Network.RemoteEvents.BaseSkinSaved, onBaseSkinSaved)
Network.connectEvent(Network.RemoteEvents.PlayTimeUpdated, onPlayTimeUpdated)
Network.connectEvent(Network.RemoteEvents.ThievesToolAdded, onThievesToolAdded)
Network.connectEvent(Network.RemoteEvents.UnlockedBrainrotDetector, onBrainrotDetectorUnlocked)
Network.connectEvent(Network.RemoteEvents.PickaxeModelChanged, onPickaxeModelChanged)

return ClientDataService
