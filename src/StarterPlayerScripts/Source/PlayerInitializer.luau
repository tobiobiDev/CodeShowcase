--!strict
--[[
    This is the main client-side orchestrator. It uses the CharacterLoadedWrapper
	to reliably detect when a new character is ready, and then initializes all
	client-side gameplay systems for that character.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ActionBinder = require(script.Parent.ActionBinder)
local BrainrotCharacterController = require(script.Parent.BrainrotCharacterController)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.Utility.CharacterLoadedWrapper)
local ClientMiningSystem = require(StarterPlayer.StarterPlayerScripts.Source.ActionSystems.ClientMiningSystem)
local ClientWeaponSystem = require(StarterPlayer.StarterPlayerScripts.Source.ActionSystems.ClientWeaponSystem)
local InventoryController = require(StarterPlayer.StarterPlayerScripts.Source.Gui.InventoryController)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local player = assert(Players.LocalPlayer, "LocalPlayer not found")

--[[
    This function runs for a SINGLE character lifecyle. It sets up all systems
    for the newly loaded character.
]]
local function onCharacterReady(character: Model)
	logger.log("New character is ready. Initializing client systems.")

	-- Initialize each client-side system here. Each system should manage its own
	-- state, animations, and VFX for this character's lifecycle.
	BrainrotCharacterController.Initialize(character)
	ClientMiningSystem.Initialize(character)
	ClientWeaponSystem.Initialize(character)
	InventoryController.Initialize(character)

	-- The ActionBinder is initialized last, as it will connect the inputs to
	-- the now-initialized systems.
	ActionBinder.BindActions()
end

--[[
    This function cleans up systems when a character's lifecycle ends.
]]
local function onCharacterDied(_character: Model)
	logger.log("Character has died or been removed. Cleaning up client systems.")

	-- Unbind all actions to prevent inputs from firing on a dead/gone character.
	ActionBinder.UnbindActions()

	-- Allow each system to perform its own cleanup if necessary. Define this for
	-- each system.
	BrainrotCharacterController.Cleanup()
	ClientMiningSystem.Cleanup()
	ClientWeaponSystem.Cleanup()
end

return {
	Start = function()
		local masterWrapper = CharacterLoadedWrapper.new(player)

		-- Connect to the relizable signals from the wrapper.
		masterWrapper.loaded:Connect(onCharacterReady)
		masterWrapper.died:Connect(onCharacterDied)

		-- Handle the case where the character is already loaded when this script runs.
		if masterWrapper:isLoaded() then
			onCharacterReady(player.Character :: Model)
		end

		logger.log("PlayerInitializer is active and waiting for character.")
	end,
}
