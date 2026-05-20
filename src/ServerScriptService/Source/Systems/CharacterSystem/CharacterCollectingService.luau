--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local Network = require(ReplicatedStorage.Source.Libs.Network)
local RemoteEventName = require(ReplicatedStorage.Source.Libs.Network.RemoteName.RemoteEventName)
local Signal = require(ReplicatedStorage.Source.Libs.Signal)

type CharacterName = CharacterNameEnum.EnumType

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local caveWallsFolder = assert(workspace:FindFirstChild("CaveWalls"), "Failed to find ˙CaveWalls˙ in workspace")
local spawnedCharactersFolder =
	assert(workspace:FindFirstChild("SpawnedCharacters"), "Failed to find 'SpawnedCharacters' folder in Workspace.")
local caveCollisionZones = assert(ServerStorage:FindFirstChild("CaveCollisionZones"))
local caveWallReset = assert(ServerStorage:FindFirstChild("CaveWallReset"))
local playerCharacterFolder =
	assert(workspace:FindFirstChild("PlayerCharacters"), "Player characters folder not found in workspace") :: Folder

local zonesFolder = workspace:FindFirstChild("Zones")
local mineZonePart = assert(
	if zonesFolder then zonesFolder:WaitForChild("MineZone") :: BasePart else nil,
	"Failed to Find 'MineZone' in 'Zones' folder."
)

local CharacterCollectingService = {}

CharacterCollectingService.CharacterDropped = Signal.new() :: Signal.Signal<Player, Model, string?, boolean?>

--[[
	Calculates the CFrame offset for a character model being carried.
	Offsets are layered horizontally to allow carrying multiple characters.
]]
local function getCarryOffset(index: number, modelToCarry: Model): (Vector3, number)
	local size = modelToCarry:GetExtentsSize()
	local charWidth = size.X
	local charHeight = size.Y

	local baseHeightAboveHead = 2.0
	local horizontalPadding = 0.5

	local dynamicYOffset = (charHeight / 2) + baseHeightAboveHead

	if index == 1 then
		return Vector3.new(0, dynamicYOffset, 0), charWidth
	end

	local sideMultiplier = if index % 2 == 0 then 1 else -1
	local distanceFromCenter = math.floor(index / 2)

	local xOffset = (charWidth + horizontalPadding) * distanceFromCenter * sideMultiplier

	return Vector3.new(xOffset, dynamicYOffset, 0), charWidth
end

local function isPositionInZone(position: Vector3)
	local relative = mineZonePart.CFrame:PointToObjectSpace(position)
	local halfSize = mineZonePart.Size / 2

	return math.abs(relative.X) <= halfSize.X
		and math.abs(relative.Y) <= halfSize.Y
		and math.abs(relative.Z) <= halfSize.Z
end

--[[
	Welds a character model above the player's head and disables its physics.
	Used when a player "collects" or "carries" a Brainrot Character.
]]
function CharacterCollectingService.WeldModelAboveHead(
	player: Player,
	model: Model,
	currentlyCarrying: number,
	characterId: string
)
	logger.log(`Welding '{model.Name}' character above {player.Name}'s head...`)
	local character = player.Character
	if not character then
		logger.log(`Failed to find character for player '{player.Name}'`, true)
		return
	end

	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		logger.log(`Player character '{character.Name}' is missing 'Head'`, true)
		return
	end

	local primaryPart = model.PrimaryPart
	if not primaryPart then
		logger.log(`'{model.Name}' character model is missing PrimaryPart`, true)
		return
	end

	local offset = getCarryOffset(currentlyCarrying + 1, model)
	logger.log(`Received offset: {tostring(offset)}`)

	model:PivotTo(head.CFrame * CFrame.new(offset))
	logger.log(`Placing {model.Name} model at Position: {model:GetPivot().Position}`)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "HeadConstraint"
	weld.Part0 = primaryPart
	weld.Part1 = head
	weld.Parent = primaryPart

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	model.Parent = character
	model:AddTag("Carried")

	local proximityPrompt = model:FindFirstChild("CollectProximity")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.Enabled = false
	end
	Network.fireClient(Network.RemoteEvents.CharacterCollected, player, characterId, true)

	logger.log(`'{model.Name}' welded successfully.`)
end

--[[
	Detaches a carried character model and places it on the ground.
	Uses raycasting to ensure the character is placed correctly on the floor.
]]
function CharacterCollectingService.DropCharacter(
	player: Player,
	characterModel: Model,
	batHit: boolean,
	characterIndex: number?
)
	logger.log(`Dropping '{characterModel.Name}' model from {player.Name}'s character...`)

	local character = player.Character
	if not character then
		logger.log(`Failed to find character for player '{player.Name}'`, true)
		return
	end

	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		logger.log(`Player character '{character.Name}' is missing 'Head'`, true)
		return
	end

	local primaryPart = characterModel.PrimaryPart
	if not primaryPart then
		logger.log(`'{characterModel.Name}' character model is missing PrimaryPart`, true)
		return
	end

	local dropDistance = 4
	local origin = head.Position + (head.CFrame.LookVector * dropDistance)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { playerCharacterFolder, caveWallsFolder, caveCollisionZones, caveWallReset }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)

	local extents = characterModel:GetExtentsSize()
	local halfHeight = extents.Y / 2

	local dropPosition
	if result then
		local hitInstance = result.Instance
		local hitModel = hitInstance:FindFirstAncestorOfClass("Model")

		if hitModel and (hitModel.Parent == spawnedCharactersFolder) and not batHit then
			Network.fireClient(RemoteEventName.PlayNotification, player, "You can't drop character here, please move")
			return
		end

		if batHit and characterIndex then
			local totalCharacters = 6

			local circleRadius = 5

			local angle = (characterIndex / totalCharacters) * (2 * math.pi)

			local offsetX = math.cos(angle) * circleRadius
			local offsetZ = math.sin(angle) * circleRadius

			dropPosition =
				Vector3.new(head.Position.X + offsetX, result.Position.Y + halfHeight, head.Position.Z + offsetZ)
		else
			dropPosition = result.Position + Vector3.new(0, halfHeight, 0)
		end
	else
		dropPosition = origin - Vector3.new(0, 5 - halfHeight, 0)
	end

	local weldConstraint = primaryPart:FindFirstChild("HeadConstraint", true)
	if weldConstraint then
		weldConstraint:Destroy()
	else
		logger.log(`Failed to find WeldConstraint in '{characterModel.Name}' model.`, true)
	end

	primaryPart:SetNetworkOwner(nil)
	characterModel.Parent = spawnedCharactersFolder
	characterModel:RemoveTag("Carried")

	for _, part in characterModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = true
			part.CanQuery = true
			part.Massless = false

			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local characterId = characterModel:GetAttribute("CharacterId") :: string?

	if not isPositionInZone(dropPosition) then
		logger.log(`{player.Name} dropped {characterModel.Name} outside of mining zone, despawning it`, true)
		CharacterCollectingService.CharacterDropped:Fire(player, characterModel, characterId, true)
		Network.fireClient(Network.RemoteEvents.CharacterCollected, player, characterId, false)
		return
	end

	local yaw = math.rad(head.Orientation.Y)

	characterModel:PivotTo(CFrame.new(dropPosition) * CFrame.Angles(0, -yaw, 0))

	local proximityPrompt = characterModel:FindFirstChild("CollectProximity")
	if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
		proximityPrompt.Enabled = true
	end

	Network.fireClient(Network.RemoteEvents.CharacterCollected, player, characterId, false)

	CharacterCollectingService.CharacterDropped:Fire(player, characterModel, characterId)

	logger.log(`'{characterModel.Name}' successfully dropped at position: {characterModel:GetPivot().Position}`)
end

return CharacterCollectingService
