--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local BaseConfigs = require(ReplicatedStorage.Source.Configs.BaseConfigs)
local BaseProvider = require(ReplicatedStorage.Source.Utility.BaseProvider)
local ClientDataService = require(ReplicatedStorage.Source.PlayerData.ClientDataService)
local ConfirmUIController = require(StarterPlayer.StarterPlayerScripts.Source.Gui.ConfirmUIController)
local Connections = require(ReplicatedStorage.Source.Utility.Connections)
local Logger = require(ReplicatedStorage.Source.Utility.Logger)
local Network = require(ReplicatedStorage.Source.Libs.Network)
local TutorialConfig = require(ReplicatedStorage.Source.Configs.TutorialConfig)
local UIEffects = require(ReplicatedStorage.Source.Utility.UIEffects)
local VisualEffects = require(ReplicatedStorage.Source.Utility.VisualEffects)
local formatNumber = require(ReplicatedStorage.Source.Utility.formatNumber)
local waitForChildInstanceAsync = require(ReplicatedStorage.Source.Utility.waitForChildInstanceAsync)

local logger = Logger.new({
	Debug = false,
	Prefix = script.Name,
})

local DEBOUNCE = 0.4
local UPGRADE_DEBOUNCE = 0.1
local CASH_TICKER_UPDATE_INTERVAL = BaseConfigs.CashTickerUpdateInterval
local DEFAULT_HOLD_DURATION = 0.3 -- The default proximity prompt hold duration
local DETECTION_RADIUS = 10

type PromptConfig = {
	UIOffset: Vector2,
	KeyboardKeyCode: Enum.KeyCode,
}
local PROMPT_CONFIG: { [string]: PromptConfig } = {
	PlaceProximity = {
		UIOffset = Vector2.new(0, 70),
		KeyboardKeyCode = Enum.KeyCode.E,
	},
	SellProximity = {
		UIOffset = Vector2.new(0, 150),
		KeyboardKeyCode = Enum.KeyCode.Q,
	},
	GiftProximity = {
		UIOffset = Vector2.new(0, 0),
		KeyboardKeyCode = Enum.KeyCode.E,
	},
}

type DisplayTicker = {
	CashPerSecond: number,
	StartTime: number,
	BaseValue: number,
	isRunning: boolean,
}

local player = assert(Players.LocalPlayer, "Failed to find LocalPlayer")
local currentCharacter: Model? = nil
local humanoid: Humanoid? = nil

local assignedBase: Model? = nil

-- Connections for this character's lifecycle.
local characterConnections = Connections.new()
-- Connections bound to the current assigned base (persists across character respawns).
local baseConnections = Connections.new()
-- Cached list of display slots for the current base.
local cachedDisplayModels: { Model } = {}

local playerGui = player:WaitForChild("PlayerGui")
local basesFolder = workspace:WaitForChild("Bases") :: Folder
local TutorialBasesFolder = workspace:WaitForChild("TutorialBases") :: Folder
local modelsFolder = workspace:WaitForChild("SpawnedCharacters")
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")

local effectsFolder = assetsFolder:WaitForChild("Effects")
local upgradeEffect = effectsFolder:WaitForChild("UpgradeEffect") :: Attachment

local toolUnequipConnection: RBXScriptConnection?
local promptConnections: { [ProximityPrompt]: RBXScriptConnection } = {}

local debounceTable = {} :: { [Player]: number }
local upgradeDebounceTable = {} :: { [Player]: number }
-- List of active cash tickers for all bases on the map to update.
local displayTickers: { [Model]: DisplayTicker } = {} -- DisplayModel: DisplayTicker

local confirmUi = playerGui:WaitForChild("ConfirmUI")
local sellConfirmFrame = confirmUi:WaitForChild("ConfirmSale") :: Frame

local inTutorialArea = false
local tickerLoopStarted = false

local detectorConnection: RBXScriptConnection?

--[[
	Handles everything about characters from client side; Placement, sell, upgrade etc
]]
local BrainrotCharacterController = {}

local function reconstructDisplayModel(floorNumber: number, displayModelNumber: number, baseId: string?): Model?
	local profile = ClientDataService.GetProfile()
	if not profile then
		return nil
	end

	local currentTutorialStage = profile.TutorialStage
	local tutorialAreaCompletionStage = TutorialConfig.TutorialAreaCompletionStage
	inTutorialArea = not profile.CompletedTutorial and currentTutorialStage < tutorialAreaCompletionStage

	local currentBaseFolder = if inTutorialArea then TutorialBasesFolder else basesFolder
	local baseToFindDIsplay = if baseId then currentBaseFolder:FindFirstChild(baseId) :: Model? else assignedBase
	if not baseToFindDIsplay then
		return nil
	end

	local floorFolder = baseToFindDIsplay:FindFirstChild(`Floor{floorNumber}`)
	if not floorFolder then
		return nil
	end

	local displayModel = floorFolder:FindFirstChild(`Display{displayModelNumber}`)
	if displayModel and displayModel:IsA("Model") then
		return displayModel
	end

	return nil
end

local function updateCashDisplay(displayModel: Model, cashAmountText: string)
	local cashAmountButton = displayModel:FindFirstChild("CashAmount", true)
	if not cashAmountButton then
		return
	end

	local cashAmountLabel = cashAmountButton:FindFirstChild("Amount")
	if cashAmountLabel and cashAmountLabel:IsA("TextLabel") then
		cashAmountLabel.Text = cashAmountText
	end
end

local function stopCashTicker(displayModel: Model, resetToZero: boolean?)
	local ticker = displayTickers[displayModel]
	if ticker then
		ticker.isRunning = false
		displayTickers[displayModel] = nil
	end

	if resetToZero then
		updateCashDisplay(displayModel, "$0")
	end
end

local function startCashTicker(displayModel: Model, cashPerSecond: number, initialCash: number)
	stopCashTicker(displayModel)

	local ticker: DisplayTicker = {
		CashPerSecond = cashPerSecond,
		StartTime = workspace:GetServerTimeNow(),
		BaseValue = initialCash,
		isRunning = true,
	}

	displayTickers[displayModel] = ticker
end

local function updateAllCashTickers()
	if tickerLoopStarted then
		return
	end

	tickerLoopStarted = true
	local accumulatedTime = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		accumulatedTime += deltaTime

		if accumulatedTime < CASH_TICKER_UPDATE_INTERVAL then
			return
		end

		accumulatedTime -= CASH_TICKER_UPDATE_INTERVAL

		for displayModel, ticker in displayTickers do
			if not ticker.isRunning then
				continue
			end

			local now = workspace:GetServerTimeNow()
			local currentCash = ticker.BaseValue + ticker.CashPerSecond * (now - ticker.StartTime)

			local precision = if currentCash < 1000 then 0 else 2
			local text = `${formatNumber(currentCash, precision)}`
			updateCashDisplay(displayModel, text)
		end
	end)
end

local function getEquippedCharacterTool(): Tool?
	if not currentCharacter then
		return nil
	end

	for _, child in currentCharacter:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("CharacterTool") then
			return child
		end
	end

	return nil
end

local function applyPromptConfig(prompt: ProximityPrompt, promptName: string)
	local config = PROMPT_CONFIG[promptName]
	if not config then
		return
	end

	prompt.UIOffset = config.UIOffset
	prompt.KeyboardKeyCode = config.KeyboardKeyCode
	prompt.HoldDuration = DEFAULT_HOLD_DURATION
end

--[[
	Either gets or creates proximity for multiple functions
]]
local function getOrCreateProximityPrompt(parentInstance: Instance, promptName: string): ProximityPrompt
	logger.log(`Getting or creating '{promptName}' prompt in {parentInstance:GetFullName()}...`)

	local existing = parentInstance:FindFirstChild(promptName)
	if existing and existing:IsA("ProximityPrompt") then
		logger.log(`'{promptName}' found, returning existing instance.`)
		return existing
	end

	logger.log(`Existing prompt not found. Creating a new one.`)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.Parent = parentInstance

	applyPromptConfig(prompt, promptName)

	logger.log(`'{promptName}' successfully created.`)

	return prompt
end

local function setupCharacterProximity(floorNumber: number, displayModel: Model)
	local upgradeFolder = displayModel:FindFirstChild("Upgrade")
	if not upgradeFolder then
		logger.log(
			`Failed to setup Proximity: Missing 'Upgrade' part in Floor{floorNumber}'s {displayModel.Name}`,
			true
		)
		return
	end

	local proximityPrompt = getOrCreateProximityPrompt(upgradeFolder, "PlaceProximity")

	if not promptConnections[proximityPrompt] then
		promptConnections[proximityPrompt] = proximityPrompt.Triggered:Connect(function()
			local equippedTool = getEquippedCharacterTool()
			local characterId = if equippedTool then equippedTool:GetAttribute("CharacterId") :: string else nil

			local displayModelNumber = tonumber(string.match(displayModel.Name, "%d+"))
			if displayModelNumber then
				Network.fireServer(Network.RemoteEvents.PlaceCharacter, characterId, floorNumber, displayModelNumber)
			end
		end)
	end

	local equippedTool = getEquippedCharacterTool()
	proximityPrompt.ActionText = if equippedTool
		then (if displayModel:GetAttribute("Occupied") then "Swap" else "Place")
		else "Pick up"
end

local function findCharacterModel(displayModel: Model): Model?
	for _, child in displayModel:GetChildren() do
		if child:GetAttribute("CharacterId") and child:IsA("Model") then
			return child
		end
	end
	return nil
end

local function setupSellProximity(floorNumber: number, displayModel: Model)
	if inTutorialArea then
		logger.log(`Skipping 'Sell' Proximity setup: Currently still in tutorial area.`)
		return
	end

	local parentInstance = displayModel:FindFirstChild("Upgrade")
	if not parentInstance then
		return
	end

	local proximityPrompt = getOrCreateProximityPrompt(parentInstance, "SellProximity")
	proximityPrompt.ActionText = "Sell"

	proximityPrompt.Triggered:Connect(function()
		local characterModel = findCharacterModel(displayModel)
		if not characterModel then
			return
		end
		local characterId = characterModel:GetAttribute("CharacterId")
		local _, characterPrice =
			Network.invokeServerAsync(Network.RemoteFunctions.SellCharacter, "Appraise", characterId)
		if not characterPrice then
			return
		end

		local _, aboveRarity = Network.invokeServerAsync(Network.RemoteFunctions.AboveRarityThreshold, characterId)
		local result = true

		if aboveRarity then
			local message = `Are you sure you want to sell this brainrot for ${formatNumber(characterPrice)} `
			result = ConfirmUIController.ConfirmOption(sellConfirmFrame, message)
		end

		local displayModelNumber = tonumber(string.match(displayModel.Name, "%d+"))
		if result and displayModelNumber then
			Network.fireServer(Network.RemoteEvents.SellCharacter, floorNumber, displayModelNumber)
		end
	end)
end

local function removePlaceProximities()
	if not assignedBase then
		return
	end

	for _, displayModel in cachedDisplayModels do
		local upgradeFolder = displayModel:FindFirstChild("Upgrade")
		if not upgradeFolder then
			continue
		end

		local proximityPrompt = upgradeFolder:FindFirstChild("PlaceProximity")
		if not (proximityPrompt and proximityPrompt:IsA("ProximityPrompt")) then
			continue
		end

		if displayModel:GetAttribute("Occupied") then
			proximityPrompt.ActionText = "Pick up"
		elseif proximityPrompt then
			proximityPrompt:Destroy()
		end
	end
end

local function setupGiftProximity(giftedPlayer: Player, characterTool: Tool)
	local giftedCharacter = giftedPlayer.Character
	if not giftedCharacter then
		return
	end
	local proximityPrompt = getOrCreateProximityPrompt(giftedCharacter, "GiftProximity")
	proximityPrompt.ActionText = "Gift"

	proximityPrompt.Triggered:Connect(function()
		Network.fireServer(Network.RemoteEvents.GiftCharacter, giftedPlayer, characterTool)
	end)
end

local function removeGiftProximity()
	for _, giftedPlayer in Players:GetPlayers() do
		local giftedCharacter = giftedPlayer.Character
		if not giftedCharacter then
			return
		end

		local proximityPrompt = giftedCharacter:FindFirstChildOfClass("ProximityPrompt")
		if proximityPrompt then
			proximityPrompt:Destroy()
		end
	end
end

local function onToolEquipped(characterTool: Tool)
	logger.log(`Player has equiped {characterTool}, connecting unequip event and firing event to server`)

	if not assignedBase then
		logger.log(`Missing assigned base.`, true)
		return
	end

	for _, displayModel in cachedDisplayModels do
		local floorFolder = displayModel.Parent
		if not (floorFolder and floorFolder:IsA("Model")) then
			logger.log(`Floor folder parent not found for {displayModel:GetFullName()}`, true)
			continue
		end

		local floorNumber = tonumber(string.match(floorFolder.Name, "%d+"))
		if floorNumber then
			setupCharacterProximity(floorNumber, displayModel)
		end
	end

	for _, giftedPlayer in Players:GetPlayers() do
		if giftedPlayer == player then
			continue
		end
		setupGiftProximity(giftedPlayer, characterTool)
	end

	Network.fireServer(Network.RemoteEvents.EquipedCharacter)
	toolUnequipConnection = characterTool.Unequipped:Connect(function()
		removePlaceProximities()
		removeGiftProximity()
	end)
end

local function pickedUpCharacter(displayModel: Model, resetToZero: boolean?)
	logger.log(`Player has picked up character, deleting proximites`)

	stopCashTicker(displayModel, resetToZero)

	local upgradeFolder = displayModel:FindFirstChild("Upgrade")
	if upgradeFolder then
		local placeProximity = upgradeFolder:FindFirstChild("PlaceProximity")
		local sellProximity = upgradeFolder:FindFirstChild("SellProximity")

		if placeProximity and placeProximity:IsA("ProximityPrompt") then
			placeProximity:Destroy()
		end

		if sellProximity and sellProximity:IsA("ProximityPrompt") then
			sellProximity:Destroy()
		end
	end
end

local function connectDisplay(baseModel: Model, floorFolder: Model, displayModel: Model)
	table.insert(cachedDisplayModels, displayModel)

	local upgradeButton = waitForChildInstanceAsync(displayModel, "Upgrade", "Frame", "UpgradeButton") :: TextButton
	local cashCollectPart = displayModel:WaitForChild("CashCollect")

	if upgradeButton:IsA("TextButton") then
		UIEffects.ApplyBounceClick(upgradeButton)
		UIEffects.ApplyHoverEffect(upgradeButton)
		UIEffects.ApplyClickSound(upgradeButton)

		baseConnections:add(upgradeButton.Activated:Connect(function()
			local now = os.clock()
			if upgradeDebounceTable[player] and (now - upgradeDebounceTable[player] < UPGRADE_DEBOUNCE) then
				return
			end

			upgradeDebounceTable[player] = now
			local floorNumber = tonumber(string.match(floorFolder.Name, "%d+"))
			local displayModelNumber = tonumber(string.match(displayModel.Name, "%d+"))
			if floorNumber and displayModelNumber then
				Network.fireServer(Network.RemoteEvents.UpgradeCharacter, floorNumber, displayModelNumber)
			end
		end))
	end

	if cashCollectPart and cashCollectPart:IsA("BasePart") then
		baseConnections:add(cashCollectPart.Touched:Connect(function(touchedPart: BasePart)
			if touchedPart:FindFirstAncestorOfClass("Model") ~= currentCharacter then
				logger.log(
					`'CashCollect' in '{displayModel:GetFullName()}' touched but not by currentCharacter. Touched by {touchedPart:GetFullName()}`
				)
				return
			end

			if not humanoid then
				logger.log(
					`'CashCollect' in '{displayModel:GetFullName()}' touched but '{player.Name}' is missing Humanoid.`
				)
				return
			end

			local now = os.clock()
			if debounceTable[player] and (now - debounceTable[player] < DEBOUNCE) then
				logger.log(
					`'CashCollect' in '{displayModel:GetFullName()}' touched but '{player.Name}' is on cooldown.`
				)
				return
			end

			debounceTable[player] = now
			local floorNumber = tonumber(string.match(floorFolder.Name, "%d+"))
			local displayModelNumber = tonumber(string.match(displayModel.Name, "%d+"))
			if floorNumber and displayModelNumber then
				logger.log(`{player.Name} is requesting to collect cash from '{displayModel:GetFullName()}'`)
				Network.fireServer(Network.RemoteEvents.CollectCash, floorNumber, displayModelNumber)
			end
		end))
	end
end

local function setupBaseConnections(baseModel: Model)
	if not currentCharacter then
		logger.log(`Connection setup failed: 'currentCharacter' not set.`, true)
		return
	end

	logger.log(`Setting up new base connections for base: {baseModel.Name}`)
	baseConnections:disconnect()
	assignedBase = baseModel
	table.clear(cachedDisplayModels)

	for _, floorFolder in baseModel:GetChildren() do
		if not string.match(floorFolder.Name, "Floor") or not floorFolder:IsA("Model") then
			continue
		end

		logger.log(`Getting display models for {floorFolder.Name}`)

		floorFolder.ChildAdded:Connect(function(displayModel: Instance)
			if not (displayModel:IsA("Model") and string.match(displayModel.Name, "Display")) then
				return
			end

			connectDisplay(baseModel, floorFolder, displayModel)
		end)

		for _, displayModel in floorFolder:GetChildren() do
			if not (displayModel:IsA("Model") and string.match(displayModel.Name, "Display")) then
				continue
			end

			connectDisplay(baseModel, floorFolder, displayModel)
		end

		updateAllCashTickers()
	end
end

local function setBillboardVisibility(brainrotCharacter: Model)
	local billboard = brainrotCharacter:FindFirstChild("BillboardGui", true)
	if not (billboard and billboard:IsA("BillboardGui")) then
		logger.log(
			`Failed to update BillboardGui visibility for {brainrotCharacter.Name}: No BillboardGui instance found`,
			true
		)
		return
	end

	billboard.AlwaysOnTop = true
end

function BrainrotCharacterController.Initialize(character: Model)
	currentCharacter = character
	humanoid = character:FindFirstChildOfClass("Humanoid")

	BaseProvider.GetBase():andThen(function(baseModel: Model)
		if not baseModel then
			return
		end
		setupBaseConnections(baseModel)
	end)

	characterConnections:add(currentCharacter.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Tool") and child:GetAttribute("CharacterTool") then
			if toolUnequipConnection then
				toolUnequipConnection:Disconnect()
				toolUnequipConnection = nil
			end

			onToolEquipped(child)
		elseif child:IsA("Model") and not (child:HasTag("Pickaxe") or child:HasTag("Weapon")) then
			setBillboardVisibility(child)
		end
	end))

	characterConnections:add(Network.connectEvent(Network.RemoteEvents.UnlockedNewFloor, function()
		BaseProvider.InvalidateCache()
		BaseProvider.GetBase():andThen(function(baseModel: Model)
			if baseModel then
				setupBaseConnections(baseModel)
			end
		end)
	end))

	characterConnections:add(Network.connectEvent(Network.RemoteEvents.FinishedTutorialArea, function()
		BaseProvider.InvalidateCache()
		BaseProvider.GetBase():andThen(function(baseModel: Model)
			if baseModel then
				setupBaseConnections(baseModel)
			end
		end)
	end))

	characterConnections:add(
		Network.connectEvent(
			Network.RemoteEvents.PlaceCharacter,
			function(
				baseId: string,
				floorNumber: number,
				displayModelNumber: number,
				cashPerSecond: number?,
				initialCash: number?
			)
				local displayModel = reconstructDisplayModel(floorNumber, displayModelNumber, baseId)
				if not displayModel then
					return
				end

				logger.log(`Player has placed down character, setting up proximities`)
				if assignedBase and assignedBase.Name == baseId then
					setupCharacterProximity(floorNumber, displayModel)
					setupSellProximity(floorNumber, displayModel)
				end

				if cashPerSecond and initialCash then
					startCashTicker(displayModel, cashPerSecond, initialCash)
				end
			end
		)
	)

	characterConnections:add(
		Network.connectEvent(
			Network.RemoteEvents.UpdateDisplayCash,
			function(floorNumber: number, displayModelNumber: number, cashAmount: number)
				local displayModel = reconstructDisplayModel(floorNumber, displayModelNumber)
				if not displayModel then
					return
				end

				local precision = if cashAmount < 1000 then 0 else 2
				local text = `${formatNumber(cashAmount, precision)}`
				updateCashDisplay(displayModel, text)
			end
		)
	)

	characterConnections:add(
		Network.connectEvent(
			Network.RemoteEvents.PickupCharacter,
			function(baseId: string, floorNumber: number, displayModelNumber: number, resetToZero: boolean?)
				local displayModel = reconstructDisplayModel(floorNumber, displayModelNumber, baseId)
				if not displayModel then
					return
				end

				pickedUpCharacter(displayModel, resetToZero)
			end
		)
	)

	characterConnections:add(
		Network.connectEvent(
			Network.RemoteEvents.CollectCash,
			function(baseId: string, floorNumber: number, displayModelNumber: number, _collectedCash: number)
				local displayModel = reconstructDisplayModel(floorNumber, displayModelNumber, baseId)
				if not displayModel then
					return
				end

				local ticker = displayTickers[displayModel]

				stopCashTicker(displayModel, true)
				if ticker then
					startCashTicker(displayModel, ticker.CashPerSecond, 0)
				end
			end
		)
	)

	characterConnections:add(
		Network.connectEvent(
			Network.RemoteEvents.UpgradeCharacter,
			function(baseId: string, floorNumber: number, displayModelNumber: number, newCashPerSecond: number)
				local displayModel = reconstructDisplayModel(floorNumber, displayModelNumber, baseId)
				if not displayModel then
					return
				end
				local characterModel = displayModel:FindFirstChildOfClass("Model")
				local torso = characterModel and characterModel:FindFirstChild("Torso") :: BasePart
				if characterModel and torso and characterModel:GetAttribute("CharacterId") then
					VisualEffects.EmitVFX(upgradeEffect, torso)
				end

				local ticker = displayTickers[displayModel]
				if ticker then
					local currentCash = ticker.BaseValue
						+ ticker.CashPerSecond * (workspace:GetServerTimeNow() - ticker.StartTime)
					stopCashTicker(displayModel)
					startCashTicker(displayModel, newCashPerSecond, currentCash)
				end
			end
		)
	)

	characterConnections:add(Players.PlayerAdded:Connect(function(giftedPlayer: Player)
		if giftedPlayer == player then
			return
		end

		local characterTool = getEquippedCharacterTool()
		if characterTool then
			setupGiftProximity(giftedPlayer, characterTool)
		end
	end))

	logger.log("Initialized and listening for Brainrot character changes.")
end

local function setVisuals(model: Model, enabled: boolean)
	local torso = model:FindFirstChild("Torso")
	if not torso then
		return
	end

	local highlight = model:FindFirstChild("DetectorHighlight") :: Highlight
	if highlight then
		highlight.Enabled = enabled
	end

	for _, child in torso:GetChildren() do
		if not child:IsA("BillboardGui") then
			continue
		end

		child.AlwaysOnTop = enabled
	end
end

local function clearAll()
	for _, model in ipairs(modelsFolder:GetChildren()) do
		if model:IsA("Model") then
			setVisuals(model, false)
		end
	end
end

local function BrainrotDetector(enable: boolean)
	if not enable then
		if detectorConnection then
			detectorConnection:Disconnect()
			detectorConnection = nil
		end

		clearAll()
		return
	end

	detectorConnection = RunService.Heartbeat:Connect(function()
		local character = player.Character or player.CharacterAdded:Wait()
		if not character or not character.PrimaryPart then
			return
		end

		local playerPos = character.PrimaryPart.Position

		for _, model in ipairs(modelsFolder:GetChildren()) do
			if not model:IsA("Model") then
				continue
			end

			local torso = model:FindFirstChild("Torso") :: BasePart
			if not torso then
				continue
			end

			local distance = (torso.Position - playerPos).Magnitude

			local highlight = model:FindFirstChild("DetectorHighlight")
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "DetectorHighlight"
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Enabled = false
				highlight.Parent = model
			end

			local inRange = distance <= DETECTION_RADIUS

			setVisuals(model, inRange)
		end
	end)
end

function BrainrotCharacterController.Start()
	Network.connectEvent(Network.RemoteEvents.UnlockedBrainrotDetector, BrainrotDetector)
end

function BrainrotCharacterController.Cleanup()
	characterConnections:disconnect()

	currentCharacter = nil
	humanoid = nil

	logger.log("Cleaned up.")
end

return BrainrotCharacterController
