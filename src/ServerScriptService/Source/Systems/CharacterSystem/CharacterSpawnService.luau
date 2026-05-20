--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BrainrotCharacterConfigs = require(ReplicatedStorage.Source.Configs.BrainrotCharacterConfigs)
local CharacterInfoType = require(ReplicatedStorage.Source.Types.CharacterInfoType)
local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local Characters = require(ReplicatedStorage.Source.Data.Characters)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local LootTable = require(ReplicatedStorage.Source.Utility.LootTable)
local RarityEnum = require(ReplicatedStorage.Source.Enums.RarityEnum)

local MIN_DISTANCE = BrainrotCharacterConfigs.MIN_DISTANCE
local RARE_THRESHOLD = BrainrotCharacterConfigs.RARE_THRESHOLD

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

type Rarity = RarityEnum.EnumType
type CharacterName = CharacterNameEnum.EnumType

type CharacterId = string
type SpawnedCharacters = {
	[RarityEnum.EnumType]: {
		[CharacterId]: CharacterInfoType.SpawnedCharacter,
	},
}

type CharacterData = CharacterInfoType.CharacterData

local CharacterSpawnService = {}

local assetsFolder = assert(ReplicatedStorage:FindFirstChild("Assets"), "ReplicatedStorage is missing 'Assets' folder")
local charactersFolder =
	assert(assetsFolder:FindFirstChild("Characters"), "Assets folder is missing 'Characters' folder")
local raritySpawnAreas =
	assert(ServerStorage:FindFirstChild("CaveCollisionZones"), "Missing 'CaveCollisionZones' folder in ServerStorage")

local spawnedCharactersFolder = workspace:FindFirstChild("SpawnedCharacters")
if not spawnedCharactersFolder then
	local newFolder = Instance.new("Folder")
	newFolder.Name = "SpawnedCharacters"
	newFolder.Parent = workspace
	spawnedCharactersFolder = newFolder
end

-- Cache for characters grouped by rarity (as LootTable objects)
local _charactersByRarity: { [Rarity]: { [CharacterName]: number } } = {}
local _numberofCharactersByRarity: { [Rarity]: number } = {}

-- Cache of grid points used for spawning characters.
local _pointsByRarity: { [Rarity]: { Vector3 } } = {}
local _pointIndexByRarity: { [Rarity]: number } = {}

local function _initializeCharacterCache()
	for characterName, data in Characters do
		local rarity = data.Rarity :: Rarity
		if not _charactersByRarity[rarity] then
			_charactersByRarity[rarity] = {}
			_numberofCharactersByRarity[rarity] = 0
		end

		_charactersByRarity[rarity][characterName] = data.SpawnChance
		_numberofCharactersByRarity[rarity] += 1
	end
end

local function _generateGridPoints(part: BasePart, stepSize: number): { Vector3 }
	local points: { Vector3 } = {}
	-- Inset by stepSize to avoid wall clipping (assuming characters generally fit within this stepSize radius)
	local extentX = math.max(0, part.Size.X - stepSize)
	local extentY = math.max(0, part.Size.Y - stepSize)
	local extentZ = math.max(0, part.Size.Z - stepSize)

	local startX = -extentX / 2
	local startY = -extentY / 1.5
	local startZ = -extentZ / 2

	-- Increase grid density by reducing step size.
	-- This helps immensely in smaller areas (like Uncommon) to provide enough valid check points.
	local safeStep = math.max(1, stepSize / 1.5)

	for x = 0, extentX, safeStep do
		for y = 0, extentY, safeStep do
			for z = 0, extentZ, safeStep do
				local offset = Vector3.new(startX + x, startY + y, startZ + z)
				local worldPos: Vector3 = part.CFrame:PointToWorldSpace(offset)
				table.insert(points, worldPos)
			end
		end
	end

	-- Fallback to center if part is too small for grid (edge case I don't foresee happening but good to have)
	if #points == 0 then
		table.insert(points, part.CFrame.Position)
	end

	-- Shuffling the points array...
	local rng = Random.new()
	for i = #points, 2, -1 do
		local j = rng:NextInteger(1, i)
		points[i], points[j] = points[j], points[i]
	end

	return points
end

local function _initializeGridPools()
	for rarity, _ in _charactersByRarity do
		local rarityArea = raritySpawnAreas:FindFirstChild(`{rarity}CollisionPlayer`)
		if rarityArea and rarityArea:IsA("BasePart") then
			_pointsByRarity[rarity] = _generateGridPoints(rarityArea, MIN_DISTANCE)
			_pointIndexByRarity[rarity] = 1
		else
			logger.log(`Could not initialize grid pool for {rarity}: Missing CollisionPlayer part`, true)
		end
	end
end

--[[
    Checks if random location is far enough from other spawned characters.
]]
local function isFarEnough(position: Vector3, minDistance: number, spawnedCharacters: SpawnedCharacters): boolean
	for _, rarityTable in spawnedCharacters do
		for _, spawnedCharacterInfo in rarityTable do
			if (spawnedCharacterInfo.Position - position).Magnitude < minDistance then
				return false
			end
		end
	end
	return true
end

--[[
    Gets a random character of a given rarity.
]]
function CharacterSpawnService.GetRandomCharacter(rarity: Rarity, luckLevel: number): CharacterName?
	local characters = _charactersByRarity[rarity]
	local numberOfCharacters = _numberofCharactersByRarity[rarity] or 0

	if not characters or numberOfCharacters == 0 then
		logger.log(`No characters found for rarity: {rarity}`, true)
		return nil
	end

	local adjustedTable = table.clone(characters)
	local multiplier = 2 ^ luckLevel

	local totalAddedChance = 0
	local commonCharacters = {}
	local totalCommonWeight = 0

	-- 2. First pass: Apply luck to Rare ones (< 10) and identify Commons (>= 10)
	for name, chance in pairs(adjustedTable) do
		if chance < RARE_THRESHOLD then
			local newChance = chance * multiplier
			totalAddedChance += (newChance - chance)
			adjustedTable[name] = newChance
		else
			table.insert(commonCharacters, name)
			totalCommonWeight += chance
		end
	end

	-- Subtract the "added chance" from the common characters
	if totalAddedChance > 0 and totalCommonWeight > 0 then
		for _, name in commonCharacters do
			local originalChance = adjustedTable[name]
			-- Calculate how much of the "burden" this specific common character takes
			local weightContribution = originalChance / totalCommonWeight
			local subtraction = totalAddedChance * weightContribution

			-- Clamp to 0.01 to ensure common characters aren't removed entirely
			adjustedTable[name] = math.max(0.01, originalChance - subtraction)
		end
	end

	local randomTable = LootTable.new(adjustedTable :: { [string]: number })
	return randomTable:getRandomItem() :: CharacterName
end

--[[
    Gets a random location inside a wall of given rarity.
]]
function CharacterSpawnService.GetRandomLocation(
	rarity: Rarity,
	spawnedCharacters: SpawnedCharacters,
	characterName: string?
): Vector3?
	if not characterName then
		return nil
	end

	local pointsList = _pointsByRarity[rarity]
	if not pointsList or #pointsList == 0 then
		logger.log(`No points available in grid pool for rarity {rarity}`, true)
		return nil
	end

	local totalPoints = #pointsList

	for _ = 1, totalPoints do
		local index = _pointIndexByRarity[rarity]

		if index > totalPoints then
			local rng = Random.new()
			for j = totalPoints, 2, -1 do
				local k = rng:NextInteger(1, j)
				pointsList[j], pointsList[k] = pointsList[k], pointsList[j]
			end
			index = 1
		end

		local position = pointsList[index]
		_pointIndexByRarity[rarity] = index + 1

		-- Apply a minor random organic offset so it isn't a perfect rigid grid.
		-- Offset is up to +/- 25% of the minimum distance on X and Z axes.
		local offsetRange = MIN_DISTANCE * 0.25
		local randomOffset = Vector3.new(
			(math.random() - 0.5) * 2 * offsetRange,
			0, -- Keep Y flat so they stay above the floor of the zone
			(math.random() - 0.5) * 2 * offsetRange
		)

		local testPosition = position + randomOffset

		if isFarEnough(testPosition, MIN_DISTANCE, spawnedCharacters) then
			return testPosition
		end
	end

	logger.log(`Failed to find valid spawn location for {characterName} in {rarity} rarity zone.`)
	return nil
end

function CharacterSpawnService.PlayIdleAnimation(characterClone: Model | Tool)
	local idleAnimation = characterClone:FindFirstChild("Idle")

	if idleAnimation and idleAnimation:IsA("Animation") then
		local controller = characterClone:FindFirstChildOfClass("AnimationController")
			or Instance.new("AnimationController")
		controller.Parent = characterClone

		local animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = controller

		local idleTrack = animator:LoadAnimation(idleAnimation)
		idleTrack.Looped = true
		idleTrack:Play()
	end
end

function CharacterSpawnService.SpawnCharacter(characterName: CharacterName, location: Vector3): Model?
	local characterModel = charactersFolder:FindFirstChild(characterName:gsub(" ", ""))
	if not (characterModel and characterModel:IsA("Model")) then
		logger.log(`Character model not found for character: {characterName}`, true)
		return nil
	end

	local characterClone = characterModel:Clone()

	if not characterClone.PrimaryPart then
		logger.log(`Primary part not found for character model: {characterName}`, true)
		characterClone:Destroy()
		return nil
	end

	characterClone.PrimaryPart.CFrame = CFrame.new(location)
	characterClone.PrimaryPart.Anchored = true

	for _, part in characterClone:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Characters"
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	characterClone.Parent = spawnedCharactersFolder
	logger.log(`Character model {characterClone} has been spawned at location: {location}`)

	CharacterSpawnService.PlayIdleAnimation(characterClone)

	return characterClone
end

function CharacterSpawnService.DespawnCharacter(characterModel: Model)
	if characterModel then
		characterModel:Destroy()
	end
end

function CharacterSpawnService.Setup()
	_initializeCharacterCache()
	_initializeGridPools()
end

return CharacterSpawnService
