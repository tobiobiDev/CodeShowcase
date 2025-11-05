--!strict

local StockItems = require(script.StockItems)

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remote = ReplicatedStorage.Events:WaitForChild("RestockShop")

local CYCLE_STORE = DataStoreService:GetDataStore("GlobalShopRestock")
local STOCK_STORE = DataStoreService:GetDataStore("GlobalShopStock")

local CHANNEL = "GlobalRestockSync"
local RESTOCK_INTERVAL = 60
local CHECK_INTERVAL = 10
local MAX_ITEMS = 3

local SERVER_ID = HttpService:GenerateGUID(false)
local NextRestockTime = 0
local lastKnownRestockTime = 0
local lastPeriodicCheck = 0
local shopStock = {}

local DEFAULT_STOCK = StockItems.StockItems

local function getTime(): number
	return DateTime.now().UnixTimestamp
end

local function broadcastRestock()
	remote:FireAllClients({
		Time = NextRestockTime,
		Stock = shopStock
	})
end

local function generateStock()
	local newStock = {}
	local availableItems = {}

	for item in pairs(DEFAULT_STOCK) do
		table.insert(availableItems, item)
	end

	for i = #availableItems, 2, -1 do
		local j = math.random(i)
		availableItems[i], availableItems[j] = availableItems[j], availableItems[i]
	end

	for i = 1, math.min(MAX_ITEMS, #availableItems) do
		local item = availableItems[i]
		newStock[item] = DEFAULT_STOCK[item]
	end

	return newStock
end

local function attemptRestock()
	local now = getTime()

	local success, newData = pcall(function()
		return CYCLE_STORE:UpdateAsync("RestockData", function(oldData)
			local current = getTime()
			if oldData and oldData.Time and oldData.Time > current then
				return oldData
			end
			if oldData and oldData.Timestamp and (current - oldData.Timestamp) < 3 then
				return oldData
			end

			local newStock = generateStock()
			return {
				Time = current + RESTOCK_INTERVAL,
				Stock = newStock,
				ServerID = SERVER_ID,
				Timestamp = current
			}
		end)
	end)

	if not success or not newData then return end

	local dataChanged = (NextRestockTime ~= newData.Time) or (lastKnownRestockTime ~= (newData.Timestamp or 0))
	NextRestockTime = newData.Time
	shopStock = newData.Stock
	lastKnownRestockTime = newData.Timestamp or 0

	if newData.ServerID == SERVER_ID then
		task.spawn(function()
			pcall(function()
				STOCK_STORE:SetAsync("CurrentShopStock", shopStock)
			end)
		end)

		task.spawn(function()
			local encoded = HttpService:JSONEncode({
				Time = NextRestockTime,
				Stock = shopStock,
				ServerID = SERVER_ID,
				Timestamp = newData.Timestamp
			})
			pcall(function()
				MessagingService:PublishAsync(CHANNEL, encoded)
			end)
		end)

		broadcastRestock()
		print("[SHOP] New stock generated, broadcasting to clients.")
	elseif dataChanged then
		broadcastRestock()
		print("[SHOP] Synced with new stock from another server.")
	end
end

local function checkForUpdates()
	local success, data = pcall(function()
		return CYCLE_STORE:GetAsync("RestockData")
	end)
	if success and data and data.Timestamp and data.Timestamp > lastKnownRestockTime then
		NextRestockTime = data.Time
		shopStock = data.Stock
		lastKnownRestockTime = data.Timestamp
		broadcastRestock()
		print("[SHOP] Synced with DataStore update.")
	end
end

local function loadFromDataStore()
	local success, data = pcall(function()
		return CYCLE_STORE:GetAsync("RestockData")
	end)

	if success and data then
		NextRestockTime = data.Time or getTime() + RESTOCK_INTERVAL
		shopStock = data.Stock or generateStock()
		lastKnownRestockTime = data.Timestamp or 0
	else
		NextRestockTime = 0
		shopStock = generateStock()
	end

	print("[SHOP] Loaded existing or initialized stock.")
end

MessagingService:SubscribeAsync(CHANNEL, function(message)
	local decoded = HttpService:JSONDecode(message.Data)
	if decoded.ServerID == SERVER_ID then return end
	if decoded.Timestamp and decoded.Timestamp > lastKnownRestockTime then
		NextRestockTime = decoded.Time
		shopStock = decoded.Stock
		lastKnownRestockTime = decoded.Timestamp
		broadcastRestock()
		print("[SHOP] Real-time sync from another server.")
	end
end)

local function startCycle()
	while true do
		local now = getTime()
		if NextRestockTime == 0 or now >= NextRestockTime then
			attemptRestock()
		end

		if (now - lastPeriodicCheck) >= 30 then
			checkForUpdates()
			lastPeriodicCheck = now
		end

		task.wait(CHECK_INTERVAL)
	end
end

loadFromDataStore()

task.delay(2, function()
	broadcastRestock()
end)

task.spawn(startCycle)

game.Players.PlayerAdded:Connect(function(player)
	remote:FireClient(player, {
		Time = NextRestockTime,
		Stock = shopStock
	})
end)
