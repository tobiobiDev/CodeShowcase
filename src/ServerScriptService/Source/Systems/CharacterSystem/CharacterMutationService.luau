--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCharacterConfigs = require(ReplicatedStorage.Source.Configs.BrainrotCharacterConfigs)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local LootTable = require(ReplicatedStorage.Source.Utility.LootTable)
local MutationEnum = require(ReplicatedStorage.Source.Enums.MutationEnum)
local MutationsConfig = require(ReplicatedStorage.Source.Configs.MutationsConfig)
local TraitsConfig = require(ReplicatedStorage.Source.Configs.TraitsConfig)
local TraitsEnum = require(ReplicatedStorage.Source.Enums.TraitsEnum)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local MUTATION_CHANCE = BrainrotCharacterConfigs.MUTATION_CHANCE
local TRAIT_CHANCE = BrainrotCharacterConfigs.TRAIT_CHANCE

local assetsFolder = assert(ReplicatedStorage:FindFirstChild("Assets"), "Missing 'Assets' folder in ReplicatedStorage")
local mutationsFolder =
	assert(assetsFolder:FindFirstChild("Mutations"), "Missing 'Mutations' folder in ReplicatedStorage.Assets")

local MutationService = {}

function MutationService.GetMutation(): MutationEnum.EnumType
	local roll: number = math.random() * 100
	if roll > MUTATION_CHANCE then
		return "Normal"
	end

	local selector = LootTable.new(MutationsConfig.Chance :: { [string]: number })
	local randomMutation = selector:getRandomItem()

	return if randomMutation then randomMutation :: MutationEnum.EnumType else "Normal"
end

function MutationService.GetTrait(): TraitsEnum.EnumType
	local roll: number = math.random() * 100
	if roll > TRAIT_CHANCE then
		return "Traitless"
	end

	local selector = LootTable.new(TraitsConfig.Chance :: { [string]: number })
	local randomTrait = selector:getRandomItem()

	return if randomTrait then randomTrait :: TraitsEnum.EnumType else "Traitless"
end

function MutationService.ApplyMutation(characterClone: Model | Tool, mutationName: string)
	local mutationFolder = mutationsFolder:FindFirstChild(mutationName)
	if not mutationFolder or characterClone:GetAttribute("ActiveMutation") then
		return
	end
	local visualTemplate = mutationFolder:FindFirstChildWhichIsA("BasePart")
	local torso = characterClone:FindFirstChild("Torso") or characterClone:FindFirstChild("UpperTorso")
	if not torso then
		return
	end

	logger.log(`Applying {mutationName} Mutation to {characterClone.Name}`)
	characterClone:SetAttribute("ActiveMutation", mutationName)

	if visualTemplate then
		for _, part in characterClone:GetChildren() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "Handle" then
				part.BrickColor = visualTemplate.BrickColor
				part.Color = visualTemplate.Color
				part.Material = visualTemplate.Material
				part.Reflectance = visualTemplate.Reflectance
				part.Transparency = visualTemplate.Transparency

				if part:IsA("MeshPart") then
					part.TextureID = ""
				end
			end
		end
	end

	for _, child in mutationFolder:GetChildren() do
		if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("PointLight") then
			local effectCopy = child:Clone()
			effectCopy.Parent = torso

			task.delay(1, function()
				if effectCopy and effectCopy.Parent then
					effectCopy.Enabled = true
				end
			end)
		end
	end
end

return MutationService
