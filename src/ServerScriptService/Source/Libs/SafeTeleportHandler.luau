--!strict
--[[
    This script handles teleporting a player to another place within the
    experience via TeleportService.

    The teleport function itself is handled using a protected call with a set
    number of retry attempts. The script also fires a remote event which will
    handle the UI when the player initiates the teleport, informing them they
    are being teleported.

    The specific code here is a module script to handle calling the SafeTeleport
    function, replacing the need to call TeleportService:TeleportAsync funciton.
    You can call SafeTeleport to perform teleports from anywhere in your
    experience to reduce failed teleports.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local Network = require(ReplicatedStorage.Source.Libs.Network)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local totalAttempts = {} :: { [Player]: number }

-- SafeTeleport Constants
local SHORT_ATTEMPT_LIMIT = 3 -- how many time to try teleporting within pcall
local ATTEMPT_LIMIT = 5 -- how many total failed teleport attempts to make before no longer trying
local RETRY_DELAY = 1 -- the time (in seconds) between reattempting to teleport after a failed result
local FLOOD_DELAY = 15 -- if too many attempts have been made to the server recently, how long to wait (in seconds)

local function SafeTeleport(
	player: Player,
	placeId: number,
	options: TeleportOptions?
): (boolean?, TeleportAsyncResult?)
	local attemptIndex = 0
	local success, errorMessage -- define pcall results outside of loop so results can be reported later on

	repeat
		success, errorMessage = pcall(TeleportService.TeleportAsync, TeleportService, placeId, { player :: any }, options)

		attemptIndex += 1
		if not success then
			task.wait(RETRY_DELAY)
		end
	until success or attemptIndex == SHORT_ATTEMPT_LIMIT

	if not success then
		logger.log(tostring(errorMessage), true)
		if totalAttempts[player] then
			totalAttempts[player] += 1
		else
			totalAttempts[player] = 1
		end
	end

	return success, errorMessage :: TeleportAsyncResult?
end

local function handleFailedTeleport(
	player: Instance,
	teleportResult: Enum.TeleportResult,
	errorMessage: string,
	targetPlaceId: number,
	teleportOptions: Instance
)
	if teleportResult == Enum.TeleportResult.Flooded then
		task.wait(FLOOD_DELAY) -- too many attempts made recently, wait to make another
	elseif teleportResult == Enum.TeleportResult.Failure then
		task.wait(RETRY_DELAY) -- teleport attempt just failed, wait to retry
	end

	if not player:IsA("Player") then
		return
	end

	Network.fireClient(
		Network.RemoteEvents.TeleportFailed,
		player,
		`Invalid teleport {teleportResult.Name}: {errorMessage}`
	)

	if totalAttempts[player] and totalAttempts[player] < ATTEMPT_LIMIT then
		logger.log(`Teleport attempts: {totalAttempts[player]}/{ATTEMPT_LIMIT}`)
		-- Retry teleport again
		SafeTeleport(player, targetPlaceId, teleportOptions :: TeleportOptions)
	else
		-- fire event to show the player the teleport failed
		Network.fireClient(
			Network.RemoteEvents.TeleportFailed,
			player,
			`Invalid teleport {teleportResult.Name}: {errorMessage}`
		)
		-- if the teleport is invalid, report the error instead of retrying inifinitely
		logger.log(`Invalid teleport {teleportResult.Name}: {errorMessage}`, true)
		totalAttempts[player] = nil
	end
end

TeleportService.TeleportInitFailed:Connect(handleFailedTeleport)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SafeTeleportHandler = {}

-- Call this function in any script instead of using `TeleportService:TeleportAsync`
function SafeTeleportHandler.Teleport(player: Player, placeID: number, options: TeleportOptions?)
	-- fire event to show Teleport UI, informing the player they are being teleported
	Network.fireClient(Network.RemoteEvents.Teleporting, player, placeID)
	logger.log(`Teleporting {player.Name} to placeId: {placeID}`)
	-- safely teleport
	SafeTeleport(player, placeID, options)
end

-- This is the event that will be fired if a client initiates the teleport
Network.connectEvent(
	Network.RemoteEvents.InitiateTeleport,
	function(player: Player, placeID: number, options: TeleportOptions?)
		-- ReplicatedStorage.Remotes.RemoteEvents.Teleporting:FireClient(player, placeID)
		SafeTeleportHandler.Teleport(player, placeID, options)
	end
)

return SafeTeleportHandler
