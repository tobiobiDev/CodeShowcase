--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local BrainrotCharacterConfigs = require(ReplicatedStorage.Source.Configs.BrainrotCharacterConfigs)
local CharacterCollectingService = require(script.Parent.CharacterCollectingService)
local CharacterEarningService = require(script.Parent.CharacterEarningService)
local CharacterInfoService = require(ServerScriptService.Source.Systems.CharacterSystem.CharacterInfoService)
local CharacterInfoType = require(ReplicatedStorage.Source.Types.CharacterInfoType)
local CharacterMutationService = require(script.Parent.CharacterMutationService)
local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local CharacterSpawnService = require(ServerScriptService.Source.Systems.CharacterSystem.CharacterSpawnService)
local CharacterToolService = require(script.Parent.CharacterToolService)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local Network = require(ReplicatedStorage.Source.Libs.Network)
local PickaxeUtilities = require(ReplicatedStorage.Source.Utility.PickaxeUtilities)
local PlayerCharacterService = require(ServerScriptService.Source.Systems.PlayerCharacterSystem.PlayerCharacterService)
local PlayerDataService = require(ServerScriptService.Source.PlayerData.PlayerDataService)
local RarityConfig = require(ServerScriptService.Source.Configs.RarityConfig)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)
local RebirthSystem = require(ServerScriptService.Source.Systems.RebirthSystem)
local Signal = require(ReplicatedStorage.Source.Libs.Signal)
local WallStrengthConfig = require(ReplicatedStorage.Source.Configs.WallStrengthConfig)
local ZoneService = require(ReplicatedStorage.Source.Libs.ZoneService)
local formatTime = require(ReplicatedStorage.Source.Utility.formatTime)
local generateCharacterId = require(script.Parent.generateCharacterId)
local tryGetPlayerProfile = require(ServerScriptService.Source.PlayerData.tryGetPlayerProfile)

local CHECK_INTERVAL = BrainrotCharacterConfigs.CHECK_INTERVAL
local CHECK_RADIUS = BrainrotCharacterConfigs.CHECK_RADIUS
local DEFAULT_DESPAWN_TIME_MIN = BrainrotCharacterConfigs.DEFAULT_DESPAWN_TIME_MIN
local DEFAULT_DESPAWN_TIME_MAX = BrainrotCharacterConfigs.DEFAULT_DESPAWN_TIME_MAX
local CELESTIAL_SPAWN_TIME = BrainrotCharacterConfigs.CELESTIAL_SPAWN_TIME
local TRY_SPAWN_DELAY = BrainrotCharacterConfigs.TRY_SPAWN_DELAY
local MAX_LUCK_LEVEL = BrainrotCharacterConfigs.MAX_LUCK_LEVEL
local INCREMENT_TIME = BrainrotCharacterConfigs.INCREMENT_TIME
local LUCK_MULTIPLIER = BrainrotCharacterConfigs.LUCK_MULTIPLIER
local COOLDOWN = 0.5

-- ProximityPrompt Settings
local MAX_ACTIVATION_DISTANCE = BrainrotCharacterConfigs.MAX_ACTIVATION_DISTANCE
local HOLD_DURATION = BrainrotCharacterConfigs.HOLD_DURATION

local ZONE_ID = "MineZone"
local TUTORIAL_ZONE_ID = "TutorialZone"

local CHARACTER_ID_ATTRIBUTE = "CharacterId"
local RARITY_ATTRIBUTE = "CharacterRarity"

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

type Rarity = RarityEnum.EnumType

type CharacterId = string
type SpawnedCharacters = {
	[RarityEnum.EnumType]: {
		[CharacterId]: CharacterInfoType.SpawnedCharacter,
	},
}
type CarriedBrainrots = {
	[Player]: { [CharacterId]: Model },
}

local carriedCharacters: CarriedBrainrots = {}
local carryCapacities: { [Player]: number } = {}
local spawnedCharacters: SpawnedCharacters = {}
local activeTutorialZones: { ZoneService.ZoneId } = {}

local lobbyFolder = assert(workspace:FindFirstChild("Lobby"), "Workspace missing 'Lobby' folder")
local celestialSpawnTimer = lobbyFolder:FindFirstChild("CelestialSpawn", true)

local tutorialBasesFolder =
	assert(workspace:FindFirstChild("TutorialBases"), "Workspace is missing 'TutorialBases' folder")
local miscFolder = assert(SoundService:FindFirstChild("Misc"), "Failed to find misc folder in SoundService")
local celestialSpawnSound =
	assert(miscFolder:FindFirstChild("CelestialSpawn"), "Failed to find CelestialSpawn Sound") :: Sound

local zonesFolder = workspace:FindFirstChild("Zones")
local mineZonePart = assert(
	if zonesFolder then zonesFolder:WaitForChild("MineZone") :: BasePart else nil,
	"Failed to Find 'MineZone' in 'Zones' folder."
)

local caveWallsFolder = workspace:FindFirstChild("CaveWalls")
local caveCollisionZonesFolder = if caveWallsFolder then caveWallsFolder:FindFirstChild("CaveCollisionZones") else nil

local timePassedSinceLastCelestial = 0
local debounce = 1
local debounceTable = {} :: { [Player]: number }
local lastZoneExit = {} :: { [Player]: number }
local alreadyRan: { [Player]: boolean } = {}

local luckEndTime = 0
local resetTask: thread? = nil

local CharacterSystem = {}

CharacterSystem.UnlockedBaseSkin = Signal.new()
CharacterSystem.currentLuckLevel = 0

--[[
    Find random location, character and level of a given rarity and spawns it,
    model is not spawned until player is close.
]]
local function spawnCharacter(rarity: Rarity)
	local characterToSpawn = CharacterSpawnService.GetRandomCharacter(rarity, CharacterSystem.currentLuckLevel)
	local randomLocation = CharacterSpawnService.GetRandomLocation(rarity, spawnedCharacters, characterToSpawn)
	local characterLevel = CharacterInfoService.GetRandomLevel(rarity)

	if not randomLocation or not characterToSpawn or not characterLevel then
		logger.log(
			`Failed to get location: {randomLocation} or character: {characterToSpawn} or level: {characterLevel}, retrying in {TRY_SPAWN_DELAY}`
		)
		task.delay(TRY_SPAWN_DELAY, function()
			spawnCharacter(rarity)
		end)
	end

	if characterToSpawn and randomLocation and characterLevel then
		logger.log(`Information for {characterToSpawn} saved. Ready to spawn model when someone gets close`)

		spawnedCharacters[rarity] = spawnedCharacters[rarity] or {}

		local spawnId = generateCharacterId()

		local randomDespawnTime = math.random(DEFAULT_DESPAWN_TIME_MIN, DEFAULT_DESPAWN_TIME_MAX)

		local rarityData = RarityConfig[rarity]
		if rarityData then
			randomDespawnTime = math.random(rarityData.MinimumTime, rarityData.MaximumTime)
		end

		local rolledMutation = CharacterMutationService.GetMutation()
		local rolledTrait = CharacterMutationService.GetTrait()

		spawnedCharacters[rarity][spawnId] = {
			Rarity = rarity,
			Name = characterToSpawn,
			Position = randomLocation,
			Level = characterLevel,
			Model = nil,
			TimerGui = nil,
			TimerLabel = nil,
			Mutation = rolledMutation,
			Trait = rolledTrait,
			TimeToDespawn = randomDespawnTime,
			IsCarried = false,
		}
	end
end

local function despawnCharacter(characterId: string, spawnedCharacterInfo: CharacterInfoType.SpawnedCharacter)
	if not spawnedCharacterInfo then
		return
	end
	local rarity = spawnedCharacterInfo.Rarity
	local spawnedCharactersInRarity = spawnedCharacters[rarity]

	if spawnedCharacterInfo.Model then
		CharacterSpawnService.DespawnCharacter(spawnedCharacterInfo.Model)
	end

	local rarityData = RarityConfig[rarity]
	if rarityData and rarityData.AutomaticRespawn then
		spawnCharacter(rarity)
	end

	if spawnedCharactersInRarity then
		spawnedCharactersInRarity[characterId] = nil
	end
end

local function dropCharacter(player: Player, characterId: string)
	logger.log(`{player} is trying to drop character with Id: {characterId}`)

	local carried = carriedCharacters[player]
	if not carriedCharacters[player] then
		logger.log(`'dropCharacter' called when {player.Name} has no carried characters.`, true)
		return
	end

	local foundCharacter = carried[characterId]
	if not foundCharacter then
		logger.log(
			`Drop character failed: {player.Name} tried to drop character with invalid or missing Id '{characterId}'`
		)
		return
	end

	CharacterCollectingService.DropCharacter(player, foundCharacter, false)
end

local function onCharacterDropped(player: Player, characterModel: Model, characterId: string?, shouldDespawn: boolean?)
	local carried = carriedCharacters[player]
	if not carriedCharacters[player] then
		logger.log(`{player.Name} has no carried characters table entry.`)
		return
	end

	if not characterId then
		logger.log(`Failed to finish dropping character for {player.Name}: Missing character ID`, true)
		return
	end

	carried[characterId] = nil
	carryCapacities[player] = math.max(0, carryCapacities[player] - 1)

	local rarity = characterModel:GetAttribute(RARITY_ATTRIBUTE) :: RarityEnum.EnumType?
	if not (rarity and typeof(rarity) == "string") then
		logger.log(
			`Failed to set 'IsCarried' for character with ID '{characterId}': Missing 'CharacterRarity' atribute`,
			true
		)
		return
	end

	if not spawnedCharacters[rarity] then
		logger.log(
			`Failed to set 'IsCarried' for character with ID '{characterId}': Missing '{rarity}' folder in SpawnedCharacters folder`,
			true
		)
		return
	end

	local spawnedCharacter = spawnedCharacters[rarity][characterId]

	if shouldDespawn then
		despawnCharacter(characterId, spawnedCharacter)
		return
	end

	if spawnedCharacter then
		spawnedCharacter.IsCarried = false
	end

	logger.log(`{player} succesfully dropped '{characterModel.Name}' with ID '{characterId}'`)
end

--[[
    Handles despawns of all characters and immediately spawns new ones of same
    rarity unless excluded.
]]
local function despawnTimer()
	for _, spawnedCharactersInRarity in spawnedCharacters do
		for characterId, spawnedCharacterInfo in spawnedCharactersInRarity do
			if spawnedCharacterInfo.IsCarried then
				continue
			end

			spawnedCharacterInfo.TimeToDespawn -= 1

			if spawnedCharacterInfo.TimerGui and spawnedCharacterInfo.TimerLabel then
				spawnedCharacterInfo.TimerGui.Enabled = true
				spawnedCharacterInfo.TimerLabel.Text = `{spawnedCharacterInfo.TimeToDespawn}s`
			end

			if spawnedCharacterInfo.TimeToDespawn <= 0 then
				logger.log(`Despawn timer for {spawnedCharacterInfo.Name} has hit 0, despawning the character`)
				despawnCharacter(characterId, spawnedCharacterInfo)
			end
		end
	end
end

--[[
    Handles timer and spawning of celestial character.
]]
local function celestialSpawn()
	if not (celestialSpawnTimer and celestialSpawnTimer:IsA("TextLabel")) then
		logger.log(`Failed to update Celestial Spawn Timer: Missing 'CelestialSpawn' TextLabel`, true)
		return
	end

	while true do
		local timeUntilSpawn = CELESTIAL_SPAWN_TIME - timePassedSinceLastCelestial
		local formattedTimeUntilSpawn = formatTime(timeUntilSpawn)
		timePassedSinceLastCelestial += 1

		celestialSpawnTimer.Text = `Celestial spawns in {formattedTimeUntilSpawn}`

		if timeUntilSpawn <= 0 then
			Network.fireAllClients(Network.RemoteEvents.PlayNotification, "Celestial character has spawned!")
			Network.fireAllClients(Network.RemoteEvents.PlaySound, celestialSpawnSound)
			spawnCharacter("Celestial")
			timePassedSinceLastCelestial = 0
		end

		task.wait(1)
	end
end

local function isPlayerInPromptRange(player: Player, prompt: ProximityPrompt): boolean
	local character = player.Character
	local humanoidRootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (humanoidRootPart and humanoidRootPart:IsA("BasePart")) then
		return false
	end

	local characterModel = prompt.Parent
	local primaryPart = if characterModel and characterModel:IsA("Model") then characterModel.PrimaryPart else nil
	if not (primaryPart and primaryPart:IsA("BasePart")) then
		return false
	end

	local distance = (humanoidRootPart.Position - primaryPart.Position).Magnitude
	return distance <= MAX_ACTIVATION_DISTANCE
end

--[[
	This function is used for potential exploit protection, preventing players
	from collecting a character if that player has deleted a cave wall, or used
	some other means of attempting to collect the character while the character
	is still inside of a wall.
]]
local function isInLineOfSight(player: Player, character: Model, humanoid: Humanoid, spawnedCharacter: Model): boolean
	local playerRootPart = character:FindFirstChild("HumanoidRootPart") or humanoid.RootPart
	if not (playerRootPart and playerRootPart:IsA("BasePart")) then
		logger.log(`Failed to get {player.Name}'s root part for raycast check`, true)
		return false
	end

	local characterRootPart = spawnedCharacter.PrimaryPart
	if not characterRootPart then
		logger.log(`Failed to get {spawnedCharacter.Name}'s root part for raycast check`, true)
		return false
	end

	local playerPos = playerRootPart.Position
	local characterPos = characterRootPart.Position

	-- Used for spatial query to detect if a player is inside a cave wall.
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { caveWallsFolder :: Folder }

	-- Spatial Query: Is the player INSIDE a wall?
	local wallsInsidePlayer = workspace:GetPartBoundsInRadius(playerPos, 0.5, overlapParams)
	if #wallsInsidePlayer > 0 then
		for _, wall in wallsInsidePlayer do
			if wall:HasTag("Cave") then
				logger.log(`{player.Name} is standing inside an unmined wall ({wall.Name})`, true)
				return false
			end
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character, spawnedCharacter, caveCollisionZonesFolder :: Folder }

	local direction = characterPos - playerPos
	local raycastResult = workspace:Raycast(playerPos, direction, raycastParams)

	-- If the ray hits a CaveWall, it likely means the player walked through a deleted wall.
	if
		raycastResult
		and raycastResult.Instance:IsDescendantOf(caveWallsFolder :: Folder)
		and raycastResult.Instance:HasTag("Cave")
	then
		logger.log(
			`{player.Name} attempted to collect a character through a wall ({raycastResult.Instance.Name})`,
			true
		)
		return false
	end

	return true
end

local function setupCollecting(
	spawnedCharacter: Model,
	characterId: string,
	characterInfo: CharacterInfoType.SpawnedCharacter
)
	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.MaxActivationDistance = MAX_ACTIVATION_DISTANCE
	proximityPrompt.Name = "CollectProximity"
	proximityPrompt.ActionText = "Pick up"
	proximityPrompt.HoldDuration = HOLD_DURATION
	proximityPrompt.Parent = spawnedCharacter

	proximityPrompt.Triggered:Connect(function(player: Player)
		if characterInfo.IsCarried then
			return
		end

		if not isPlayerInPromptRange(player, proximityPrompt) then
			logger.log(`{player} tried activating prompt from too far, potentially cheating`, true)
			return
		end

		local isInCaveArea = if ZoneService.IsPlayerInZone(player, ZONE_ID) then true else false
		for _, zoneId in activeTutorialZones do
			if ZoneService.IsPlayerInZone(player, zoneId) then
				isInCaveArea = true
			end
		end

		if not isInCaveArea then
			logger.log(`{player.Name} tried collecting character while outside of mining zone`)
			return
		end

		local character = player.Character
		if not character then
			logger.log(`{player.Name} is missing a character`, true)
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			logger.log(`{player.Name}'s character is missing humanoid`, true)
			return
		end

		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Dead or humanoid.Health <= 5 then
			return
		end

		if state == Enum.HumanoidStateType.Ragdoll then
			return
		end

		local profile = tryGetPlayerProfile(player)
		if not profile then
			logger.log(`Profile not found for {player}`, true)
			return
		end

		local carryCapacity = profile.CarryingCapacity

		carriedCharacters[player] = carriedCharacters[player] or {}
		if carriedCharacters[player][characterId] then
			return
		end

		local currentlyCarrying = 0
		for _, _ in carriedCharacters[player] do
			currentlyCarrying += 1
		end

		if currentlyCarrying >= carryCapacity then
			logger.log(`{player} can't carry more characters`)
			return
		end

		local wallName = `{characterInfo.Rarity}Wall`
		local wallStrength = WallStrengthConfig[wallName] or 25
		local pickaxeStrength = PickaxeUtilities.GetPickaxeStrength(profile.Upgrades.Pickaxe)

		if pickaxeStrength < wallStrength then
			logger.log(
				`{player} tried picking up character that requires {wallStrength} Pickaxe Strength but only has {pickaxeStrength}`
			)

			local message = `You need {wallStrength} Pickaxe Strength to pick up this`
			Network.fireClient(Network.RemoteEvents.PlayNotification, player, message, false, `StrengthRequirement`)
			return
		end

		if not isInLineOfSight(player, character, humanoid, spawnedCharacter) then
			return
		end

		CharacterCollectingService.WeldModelAboveHead(player, spawnedCharacter, currentlyCarrying, characterId)

		characterInfo.IsCarried = true

		if not carryCapacities[player] then
			carryCapacities[player] = 0
		end
		carryCapacities[player] += 1

		carriedCharacters[player][characterId] = spawnedCharacter

		if not profile.CompletedTutorial then
			Network.fireClient(Network.RemoteEvents.PickedUpCharacter, player)
		end
	end)
end

local function collectCarriedCharacters(player: Player)
	local now = os.clock()
	if debounceTable[player] and (now - debounceTable[player] < debounce) then
		return
	end

	debounceTable[player] = now

	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local playerCarrying = carriedCharacters[player]
	if not playerCarrying then
		logger.log(`{player} touched part for collecting characters but is not carrying any`)
		return
	end

	for characterId, characterModel in playerCarrying do
		local rarity = characterModel:GetAttribute(RARITY_ATTRIBUTE) :: RarityEnum.EnumType?
		local characterInfo = if rarity and spawnedCharacters[rarity]
			then spawnedCharacters[rarity][characterId]
			else nil

		if characterInfo then
			local characterName = characterInfo.Name
			local characterLevel = characterInfo.Level
			local characterMutation = characterInfo.Mutation
			local characterRarity = characterInfo.Rarity
			local characterTrait = characterInfo.Trait

			PlayerDataService.SaveCollectedCharacter(
				player,
				characterId :: string,
				characterName,
				characterLevel,
				characterMutation,
				characterTrait,
				characterRarity			)

			RebirthSystem.CheckRarity(player, characterRarity)
			CharacterSystem.CheckBaseSkin(player, characterMutation, characterName)
			CharacterToolService.GiveCharactersTools(player, characterName, characterId :: string)
			Network.fireClient(Network.RemoteEvents.CharacterCollected, player, characterId, false, true)
			despawnCharacter(characterId :: string, characterInfo)

			logger.log(`{player} succesfully collected {characterName}`)
		end
	end

	carriedCharacters[player] = {}
end

local function spawnAndUpdateModel(
	spawnedCharacterInfo: CharacterInfoType.SpawnedCharacter,
	characterId: string
): Model?
	logger.log(`A player is close enough to character: {spawnedCharacterInfo.Name}, attempting to spawn it now`)

	local spawnedModel = CharacterSpawnService.SpawnCharacter(spawnedCharacterInfo.Name, spawnedCharacterInfo.Position)
	local characterMutation = spawnedCharacterInfo.Mutation
	local characterTrait = spawnedCharacterInfo.Trait
	local baseEarning = Characters[spawnedCharacterInfo.Name].CashPerSecond
	local realEarning = CharacterEarningService.ApplyEarningFormula(
		baseEarning,
		spawnedCharacterInfo.Level,
		characterMutation,
		characterTrait
	)

	if spawnedModel then
		spawnedModel:SetAttribute(CHARACTER_ID_ATTRIBUTE, characterId)
		spawnedModel:SetAttribute(RARITY_ATTRIBUTE, spawnedCharacterInfo.Rarity)

		CharacterMutationService.ApplyMutation(spawnedModel, characterMutation)

		CharacterInfoService.UpdateUiInfo(
			spawnedModel,
			spawnedCharacterInfo.Name,
			spawnedCharacterInfo.Level,
			realEarning,
			characterMutation,
			characterTrait
		)

		spawnedCharacterInfo.Model = spawnedModel

		local torso = spawnedModel:FindFirstChild("Torso")
		local timerGui = if torso then torso:FindFirstChild("DespawnTimer") else nil
		if timerGui and timerGui:IsA("BillboardGui") then
			spawnedCharacterInfo.TimerGui = timerGui
			spawnedCharacterInfo.TimerLabel = timerGui:FindFirstChild("Timer") :: TextLabel
		end

		setupCollecting(spawnedModel, characterId, spawnedCharacterInfo)
	end

	return spawnedModel
end

--[[
    Constantly checks if any of the players are close to any of the spawned
    characters, if so spawn model.
]]
local function checkDistance()
	local activePlayerPositions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character.PrimaryPart then
			table.insert(activePlayerPositions, character:GetPivot().Position)
		end
	end

	if #activePlayerPositions == 0 then
		return
	end

	for _, spawnedCharactersInRarity in spawnedCharacters do
		for characterId, spawnedCharacterInfo in spawnedCharactersInRarity do
			if spawnedCharacterInfo.IsCarried then
				continue
			end

			local targetPos = spawnedCharacterInfo.Position
			local hasNearbyPlayer = false

			for _, playerPos in activePlayerPositions do
				if (playerPos - targetPos).Magnitude <= CHECK_RADIUS then
					hasNearbyPlayer = true
					break
				end
			end

			if hasNearbyPlayer and not spawnedCharacterInfo.Model then
				spawnAndUpdateModel(spawnedCharacterInfo, characterId)
			elseif not hasNearbyPlayer and spawnedCharacterInfo.Model then
				-- No players are nearby, but model is spawned. Visually hide it
				logger.log(`No players are close to {spawnedCharacterInfo.Name}, visually despawning it`)
				CharacterSpawnService.DespawnCharacter(spawnedCharacterInfo.Model)

				spawnedCharacterInfo.Model = nil
				spawnedCharacterInfo.TimerGui = nil
				spawnedCharacterInfo.TimerLabel = nil
			end
		end
	end
end

local function connectPlayerDeath(player: Player)
	task.spawn(function()
		local playerCarrying = carriedCharacters[player]
		if not playerCarrying then
			logger.log(`Player is not carrying any characters`)
			return
		end

		for characterId, _characterModel in playerCarrying do
			dropCharacter(player, characterId)
		end
	end)
end

local function onToolEquip(player: Player)
	local playerCharacter = player.Character
	local equippedTool = if playerCharacter then playerCharacter:FindFirstChildOfClass("Tool") else nil
	if not equippedTool then
		return
	end

	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local characterId = equippedTool:GetAttribute(CHARACTER_ID_ATTRIBUTE) :: string?
	local characterInfo = if (characterId and typeof(characterId) == "string")
		then profile.CollectedCharacters[characterId]
		else nil
	if not characterInfo then
		logger.log(`Character info not found for {characterId} for {player}`, true)
		return
	end

	local characterName = characterInfo.Name
	local characterLevel = characterInfo.Level
	local characterMutation = characterInfo.Mutation
	local characterTrait = characterInfo.Trait

	local baseEarning = Characters[characterName].CashPerSecond
	local realEarning =
		CharacterEarningService.ApplyEarningFormula(baseEarning, characterLevel, characterMutation, characterTrait)

	CharacterInfoService.UpdateUiInfo(
		equippedTool,
		characterName,
		characterLevel,
		realEarning,
		characterMutation,
		characterTrait
	)
	CharacterMutationService.ApplyMutation(equippedTool, characterMutation)
end

local function giftCharacter(giftingPlayer: Player, giftedPlayer: Player, characterTool: Tool)
	logger.log(`{giftingPlayer.Name} is trying to gift {characterTool.Name} to {giftedPlayer.Name}`)

	local giftingProfile = tryGetPlayerProfile(giftingPlayer)
	local giftedProfile = tryGetPlayerProfile(giftedPlayer)

	if not giftingProfile or not giftedProfile then
		return
	end

	local characterId = characterTool:GetAttribute(CHARACTER_ID_ATTRIBUTE)
	if not (characterId and typeof(characterId) == "string") then
		return
	end

	local characterInfo = giftingProfile.CollectedCharacters[characterId]
	if not characterInfo then
		logger.log(`Character info not found for {characterId} for {giftingPlayer}`, true)
		return
	end

	if giftedProfile.CollectedCharacters[characterId] then
		logger.log(
			`{giftedPlayer} already has brainrot with id: {characterId} that {giftingPlayer} is trying to gift him`,
			true
		)
		return
	end

	local characterName = characterInfo.Name
	local characterLevel = characterInfo.Level
	local characterMutation = characterInfo.Mutation
	local characterTrait = characterInfo.Trait
	local characterRarity = characterInfo.Rarity

	local giftingMesasge = `Are you sure you want to gift {characterName} to {giftedPlayer.Name}`

	local giftingSuccess, wantsToGift =
		Network.invokeClientAsync(Network.RemoteFunctions.ConfirmGiftingPlayer, giftingPlayer, giftingMesasge)

	while not giftingSuccess do
		task.wait(1)
	end

	if not wantsToGift then
		logger.log(`{giftingPlayer.Name} declined to gift {characterName} to {giftedPlayer.Name}`)
		return
	end

	local giftedMessage = `{giftingPlayer.Name} wants to gift you {characterName}!`
	local giftedSuccess, wantsToTake =
		Network.invokeClientAsync(Network.RemoteFunctions.ConfirmGiftingPlayer, giftedPlayer, giftedMessage)

	while not giftedSuccess do
		task.wait(1)
	end

	if not wantsToTake then
		logger.log(`{giftedPlayer.Name} declined to take {characterName} from {giftingPlayer.Name}`)
		return
	end

	for _, floorTable in giftingProfile.BaseInfo do
		if type(floorTable) ~= "table" then
			continue
		end

		for _, displayInfo in floorTable do
			if displayInfo.CharacterId == characterId then
				logger.log(`{giftingPlayer} tried gifting character he has placed`, true)
				return
			end
		end
	end

	PlayerDataService.RemoveCollectedCharacter(giftingPlayer, characterId)
	CharacterToolService.RemoveTool(giftingPlayer, characterId)

	PlayerDataService.SaveCollectedCharacter(
		giftedPlayer,
		characterId,
		characterName,
		characterLevel,
		characterMutation,
		characterTrait,
		characterRarity
	)
	CharacterToolService.GiveCharactersTools(giftedPlayer, characterName, characterId)

	logger.log(`{giftingPlayer} successfuly gifted {characterName} with id: {characterId} to {giftedPlayer}`)
end

local function connectPlayerJoin(player: Player)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local collectedCharacters = profile.CollectedCharacters

	for characterId, collectedInfo in collectedCharacters do
		CharacterToolService.GiveCharactersTools(player, collectedInfo.Name, characterId)
	end

	for mutationName, discoveredCharacters in profile.DiscoveredCharacters do
		for _, characterName in discoveredCharacters do
			Network.fireClient(Network.RemoteEvents.UpdateIndex, player, mutationName, characterName)
		end
	end

	if CharacterSystem.currentLuckLevel > 0 then
		Network.fireClient(
			Network.RemoteEvents.LuckBoosted,
			player,
			luckEndTime,
			CharacterSystem.currentLuckLevel,
			LUCK_MULTIPLIER,
			MAX_LUCK_LEVEL
		)
	end

	if profile.BrainrotDetector then
		Network.fireClient(Network.RemoteEvents.UnlockedBrainrotDetector, player, profile.Settings.BrainrotDetector)
	end
end

local function onLeavingMiningZone(player: Player)
	local now = os.clock()
	if lastZoneExit[player] and (now - lastZoneExit[player] < COOLDOWN) then
		return
	end

	lastZoneExit[player] = now
	collectCarriedCharacters(player)
end

local function registerZones()
	if not ZoneService.IsZoneRegistered(ZONE_ID) then
		ZoneService.RegisterZone(ZONE_ID, { mineZonePart })
	end

	ZoneService.OnZoneExited(ZONE_ID, onLeavingMiningZone)

	tutorialBasesFolder.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Model") and string.find(child.Name, "Base") then
			local tutorialZonePart = child:FindFirstChild("MineZone")
			if not (tutorialZonePart and tutorialZonePart:IsA("BasePart")) then
				return
			end

			local zoneId = `{TUTORIAL_ZONE_ID}{child.Name}`
			table.insert(activeTutorialZones, zoneId)

			if not ZoneService.IsZoneRegistered(zoneId) then
				ZoneService.RegisterZone(zoneId, { tutorialZonePart })
			end
			ZoneService.OnZoneExited(zoneId, onLeavingMiningZone)
		end
	end)
end

function CharacterSystem.UpdateServerLuck(player: Player)
	-- Update the Luck Level (Capped)
	if CharacterSystem.currentLuckLevel < MAX_LUCK_LEVEL then
		CharacterSystem.currentLuckLevel += 1
	end

	-- If luck is active, add to existing time. If expired, start from now.
	local currentTime = os.time()
	luckEndTime = if luckEndTime > currentTime then luckEndTime + INCREMENT_TIME else currentTime + INCREMENT_TIME

	-- Manage the Reset Logic, cancel any existing reset thread so we don't reset early
	if resetTask then
		task.cancel(resetTask)
	end

	-- Schedule the reset
	local delayTime = luckEndTime - currentTime
	resetTask = task.delay(delayTime, function()
		CharacterSystem.currentLuckLevel = 0
		luckEndTime = 0
		resetTask = nil
		logger.log(`Server luck has expired, resetting back`)
		Network.fireAllClients(Network.RemoteEvents.PlayNotification, `Server Luck has expired!`)
	end)

	Network.fireAllClients(Network.RemoteEvents.PlayNotification, `{player} has boosted Server Luck!`)

	logger.log(
		`{player} has boosted Luck Level: {CharacterSystem.currentLuckLevel} | Time Remaining: {delayTime / 60}m`
	)

	Network.fireAllClients(
		Network.RemoteEvents.LuckBoosted,
		luckEndTime,
		CharacterSystem.currentLuckLevel,
		LUCK_MULTIPLIER,
		MAX_LUCK_LEVEL
	)
end

function CharacterSystem.CheckBaseSkin(player: Player, characterMutation: string, characterName: string)
	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	local discoveredCharacters = profile.DiscoveredCharacters
	local mutationEntries = discoveredCharacters[characterMutation] or {}
	local totalCharacters: number = 0

	for _, _ in Characters do
		totalCharacters += 1
	end

	if not table.find(mutationEntries, characterName) then
		PlayerDataService.SaveDiscoveredCharacter(player, characterName, characterMutation)

		if
			#profile.DiscoveredCharacters[characterMutation] == totalCharacters
			and not table.find(profile.BaseSkins, characterMutation)
		then
			local unlockedSkin = if characterMutation == "Normal" then "Silver" else characterMutation
			logger.log(`{player} has unlocked {unlockedSkin} Base skin`)
			PlayerDataService.SaveBaseSkin(player, unlockedSkin)
			CharacterSystem.UnlockedBaseSkin:Fire(player)
		end

		Network.fireClient(Network.RemoteEvents.UpdateIndex, player, characterMutation, characterName)
	end
end

function CharacterSystem.ForceDropCharacters(player: Player)
	connectPlayerDeath(player)
end

function CharacterSystem.SpawnTutorialCharacter(
	rarity: Rarity,
	characterToSpawn: CharacterNameEnum.EnumType,
	location: Vector3,
	characterLevel: number,
	player: Player
)
	if not location or not characterToSpawn or not characterLevel then
		logger.log(
			`Failed to get location: {location} or character: {characterToSpawn} or level: {characterLevel}, retrying in {TRY_SPAWN_DELAY}`
		) -- ...but you're not retrying? 🧐
		return
	end

	logger.log(`Information for {characterToSpawn} saved. Ready to spawn model when someone gets close`)

	spawnedCharacters[rarity] = spawnedCharacters[rarity] or {}

	local spawnId = generateCharacterId()

	spawnedCharacters[rarity][spawnId] = {
		Rarity = rarity,
		Name = characterToSpawn,
		Position = location,
		Level = characterLevel,
		Model = nil,
		TimerGui = nil,
		TimerLabel = nil,
		Mutation = "Normal",
		Trait = "Traitless",
		TimeToDespawn = 9999,
		IsCarried = false,
	}

	local spawnedCharacterInfo = spawnedCharacters[rarity][spawnId]
	local spawnedModel = spawnAndUpdateModel(spawnedCharacterInfo, spawnId)
	Network.fireClient(Network.RemoteEvents.TutorialCharacterSpawned, player, spawnedModel)
end

function CharacterSystem.Setup()
	registerZones()
end

function CharacterSystem.Start()
	logger.log(`Setup of CharacterSystem started, spawning base number of rarities`)

	for rarity, info in RarityConfig do
		for _ = 1, info.BaseSpawnNumber do
			spawnCharacter(rarity)
		end
	end

	-- Starts all loops on start (TODO: See if we can convert some of these to event listeners)
	task.spawn(function()
		while task.wait(CHECK_INTERVAL) do
			checkDistance()
		end
	end)
	task.spawn(function()
		while task.wait(1) do
			despawnTimer()
		end
	end)
	task.spawn(celestialSpawn)

	Network.connectEvent(Network.RemoteEvents.DropCharacter, dropCharacter)

	Network.connectEvent(Network.RemoteEvents.EquipedCharacter, onToolEquip)
	Network.connectEvent(
		Network.RemoteEvents.GiftCharacter,
		function(giftingPlayer: Player, giftedPlayer: Player, characterTool: Tool)
			task.spawn(giftCharacter, giftingPlayer, giftedPlayer, characterTool)
		end
	)
	PlayerCharacterService.Signals.CharacterLoaded:Connect(function(player: Player)
		if alreadyRan[player] then
			return
		end

		connectPlayerJoin(player)
		alreadyRan[player] = true
	end)

	PlayerCharacterService.Signals.CharacterDied:Connect(connectPlayerDeath)
	CharacterCollectingService.CharacterDropped:Connect(onCharacterDropped)
end

CharacterSystem.spawnedCharacters = spawnedCharacters
return CharacterSystem
