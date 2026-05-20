--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CharacterNameEnum = require(ReplicatedStorage.Source.Enums.CharacterNameEnum)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local tryGetPlayerProfile = require(ServerScriptService.Source.PlayerData.tryGetPlayerProfile)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local toolsFolder = assert(ServerStorage:FindFirstChild("CharacterTools"), "No tools folder found in ServerStorage")

local CharacterToolService = {}

function CharacterToolService.RemoveTool(player: Player, characterId: string)
	local character = player.Character
	if not character then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local starterGear = player:FindFirstChildOfClass("StarterGear")

	if backpack then
		for _, child in backpack:GetChildren() do
			if child:GetAttribute("CharacterId") == characterId then
				child:Destroy()
			end
		end
	end

	if starterGear then
		for _, child in starterGear:GetChildren() do
			if child:GetAttribute("CharacterId") == characterId then
				child:Destroy()
			end
		end
	end

	for _, child in character:GetChildren() do
		if child:GetAttribute("CharacterId") == characterId then
			child:Destroy()
		end
	end
end

--[[
	Gives character tool to player
]]
function CharacterToolService.GiveCharactersTools(
	player: Player,
	characterName: CharacterNameEnum.EnumType,
	characterId: string
)
	logger.log(`Trying to give {characterName} tool to {player}`)
	if not player or not player:IsA("Player") then
		return
	end

	local profile = tryGetPlayerProfile(player)
	if not profile then
		return
	end

	-- Checks if player already has the character
	for _, floorTable in profile.BaseInfo do
		if type(floorTable) ~= "table" then
			continue
		end

		for _, displayInfo in floorTable do
			if displayInfo.CharacterId == characterId then
				logger.log(`Player {player.Name} already has character {characterId} placed, skipping tool grant.`)
				return
			end
		end
	end

	local toolTemplate = toolsFolder:FindFirstChild(characterName:gsub(" ", ""))
	if not (toolTemplate and toolTemplate:IsA("Tool")) then
		logger.log(`No tool found for {characterName}`, true)
		return
	end

	local backpack = player:WaitForChild("Backpack")
	local starterGear = player:WaitForChild("StarterGear")

	local backpackTool = toolTemplate:Clone()
	backpackTool.Name = characterId
	backpackTool:SetAttribute("CharacterTool", true)
	backpackTool:SetAttribute("CharacterId", characterId)
	backpackTool.Parent = backpack

	local starterTool = toolTemplate:Clone()
	starterTool.Name = characterId
	starterTool:SetAttribute("CharacterTool", true)
	starterTool:SetAttribute("CharacterId", characterId)
	starterTool.Parent = starterGear

	logger.log(`Given {characterName} tool to {player}`)
end

return CharacterToolService
