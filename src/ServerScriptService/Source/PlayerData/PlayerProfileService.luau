--!strict
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local DefaultPlayerData = require(script.Parent.DefaultPlayerData)
local DeveloperIds = require(ServerScriptService.Source.Data.DeveloperIds)
local LeanPromise = require(ServerScriptService.Source.Libs.ProfileStore2.LeanPromise)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local PlaceId = require(ReplicatedStorage.Source.Data.PlaceId)
local PlayerDataType = require(ReplicatedStorage.Source.Types.PlayerDataType)
local Profile = require(ServerScriptService.Source.Libs.ProfileStore2.Profile)
local ProfileStore2 = require(ServerScriptService.Source.Libs.ProfileStore2)
local SafeTeleportHandler = require(ServerScriptService.Source.Libs.SafeTeleportHandler)

local DATA_STORE_NAME = if RunService:IsStudio() then "TestProfiles_V27" else "PlayerProfiles_V1"

type PlayerData = PlayerDataType.PlayerData
type Profile = Profile.Profile<PlayerData>
type ProfileStore<T> = ProfileStore2.ProfileStore<T>
type Promise<T> = LeanPromise.Promise<T>

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local developerConsole = ServerStorage:FindFirstChild("DeveloperConsole")

--[[
    This service is the central manager for all player data persistence.
    It uses `ProfileStore2` to safely load, manage, and save player profiles, and
    acts as the bridge between the raw data and other game systems.
]]
local PlayerProfileService = {}

-- A cache for active, loaded profiles for quick access.
local _profileCache: { [Player]: Profile } = {}
-- The single ProfileStore instance for all player data.
local _playerStore: ProfileStore<PlayerData>? = nil

--[[
    A utlity function to safely retrieve a player's loaded profile from the cache.
]]
function PlayerProfileService.GetProfile(player: Player): Profile?
	return _profileCache[player]
end

--[[
    The main handler for when a player's profile has been successfully loaded.
    This function is responsible for initializing the player's state in the game.
]]
local function onProfileLoaded(player: Player, profile: Profile)
	if player.Parent ~= Players then
		-- Player left while their data was loading. Safely release the session.
		profile:EndSession()
		return
	end

	profile:AddUserId(player.UserId) -- Required for GDPR compliance.w
	profile:Reconcile() -- Fills in any new fields from the template.

	_profileCache[player] = profile
	logger.logTable(profile.Data, `Profile loaded for {player.Name}:`)

	if developerConsole and table.find(DeveloperIds, player.UserId) then
		local devConsoleClone = developerConsole:Clone()
		devConsoleClone.Parent = player.PlayerGui
	end

	-- Grant starting items to new players.
	if profile.Data.IsNew then
		logger.log(`{player.Name} is a new player. Granting starter items.`)
		-- Insert logic here for new characters, as needed
	end

	-- Connecting a listener for when the session is forcibly ended (e.g., another server logs in).
	profile.OnSessionEnd:Connect(function()
		_profileCache[player] = nil
		SafeTeleportHandler.Teleport(player, PlaceId.Main) -- Retry loading to main place
	end)
end

--[[
    Handles loading a profile when a player joins the game.
]]
local function onPlayerAdded(player: Player)
	if not _playerStore then
		logger.log(`Player '{player.Name}' joined, but PlayerStore is not ready. They will be reloaded.`, true)
		SafeTeleportHandler.Teleport(player, PlaceId.Main)
		return
	end

	logger.log(`Attempting to load Profile for {player.Name}...`)
	_playerStore
		:LoadProfileAsync(`Player_{player.UserId}`)
		:andThen(function(profile: Profile)
			logger.log(`Successfully loaded profile for {player.Name}.`)
			return onProfileLoaded(player, profile)
		end :: (...Profile) -> any)
		:catch(function(err)
			logger.log(`Critical: Failed to load profile for {player.Name}: {tostring(err)}`, true)
			SafeTeleportHandler.Teleport(player, PlaceId.Main) -- Retry loading to main place
		end)
end

--[[
    Handles saving and releasing a player's profile when they leave.
]]
local function onPlayerRemoving(player: Player)
	local profile = _profileCache[player]
	if profile then
		profile.Data.lastOnline = os.time()
		profile:EndSession()
	end
end

function PlayerProfileService.Setup()
	ProfileStore2.create(DATA_STORE_NAME, DefaultPlayerData)
		:andThen(function(store)
			_playerStore = store
			logger.log(`ProfileStore is ready. Connecting player listeners.`)

			Players.PlayerAdded:Connect(function(player: Player)
				onPlayerAdded(player)
				logger.log(`{player.Name} added.`)
			end)
			Players.PlayerRemoving:Connect(onPlayerRemoving)

			-- Handle the rare case when players are already in the game when this script starts.
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(onPlayerAdded, player)
			end

			return
		end :: (...any) -> any)
		:catch(function(err)
			logger.log(
				`Critical: ProfileStore could not be created. Data will not save or load. Error: {tostring(err)}`,
				true
			)

			-- Prevent new players from joining this broken server.
			Players.PlayerAdded:Connect(function(player)
				player:Kick(
					`This server is experiencing critical data issues and is shutting down. Please try rejoining.`
				)
			end)

			-- Gently remove any players who are already connected.
			for _, player in ipairs(Players:GetPlayers()) do
				-- We're giving a more informative message to players who were already here.
				player:Kick(
					`A critical data error occurred. The server is restarting to protect your data. Please rejoin.`
				)
			end

			-- Using Messaging service to signal an issue. Could hook into this using an external service.
			MessagingService:PublishAsync("ServerHealthAlerts", "A server failed to intialize its ProfileStore.")
		end)
end

return table.freeze(PlayerProfileService)
