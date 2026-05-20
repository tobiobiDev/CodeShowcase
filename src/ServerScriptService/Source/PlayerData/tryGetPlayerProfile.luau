--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Libs.Network)
local PlayerProfileService = require(script.Parent.PlayerProfileService)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local PlayerDataType = require(ReplicatedStorage.Source.Types.PlayerDataType)

local ATTEMPT_LIMIT = 5 -- Number of retry attempts on failure
local RETRY_DELAY = 1 -- Seconds to wait between retry attempts

-- Used to access player data schema in other scripts.
export type PlayerData = PlayerDataType.PlayerData

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

--[[
    Returns the given player's data profile if found.
    This is the primary, safe way for other systems to access player data.
    Utilizes a retry method in case data fails to be found upon initial attempts.
    Removes additional need for `.Data` layer when retrieving values.

    Example usage:
    ```lua
    local profile = tryGetPlayerProfile(player)
    if profile then
        print(profile.Cash)
    end
    ```
]]
local function tryGetPlayerProfile(player: Player): PlayerData?
	local success, data
	local attemptIndex = 0

	repeat
		success, data = pcall(function()
			local profile = PlayerProfileService.GetProfile(player)
			if profile then
				return profile.Data
			end
			return profile :: any
		end)

		if success and data then
			logger.log(`Successfully retrieved {player.Name}'s profile data.`)
			return data
		end

		attemptIndex += 1
		task.wait(RETRY_DELAY)
	until (success and data) or attemptIndex == ATTEMPT_LIMIT

	if not success then
		logger.log(`{player.Name}'s profile data was not found: {tostring(data)}`, true)
		return nil
	end

	return data
end

-- Remote function for client to get a copy of the player's profile.
Network.bindFunction(Network.RemoteFunctions.GetProfileData, tryGetPlayerProfile)

return tryGetPlayerProfile
