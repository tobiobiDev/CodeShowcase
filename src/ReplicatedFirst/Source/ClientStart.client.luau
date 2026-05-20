--!nonstrict
--[[
    The client-sided entry point for all code in the experience.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadingScreen = require(script.Parent.LoadingScreen)
local waitForGameLoadedAsync = require(script.Parent.Utility.waitForGameLoadedAsync)

local player = assert(Players.LocalPlayer, "LocalPlayer not found")

local function preGameLoadTasksAsync()
    -- Add loading screen pre-game tasks here
    LoadingScreen.enableAsync()
    LoadingScreen.updateDetailText("Creating world...")
end

--[[
    Place inside this function any dependency requires for modules that need to
    be started right away for the client, such as the ClientDataService.
    Added `task.wait()` to ensure full loading is completed.
]]
local function postGameLoadTasksAsync()
    local ReplicatedSourceFolder = ReplicatedStorage:WaitForChild("Source")
    local LeanPromise = require(ReplicatedSourceFolder:WaitForChild("Libs"):WaitForChild("LeanPromise"))
    
    local tasksCompleted = 0
    local totalTasks = 3

    local function updateProgress()
        tasksCompleted += 1
        LoadingScreen.updateDetailText(`Loading experience assets... ({tasksCompleted}/{totalTasks})`)
    end

    local function loadGameSystemsAsync()
        return LeanPromise.new(function(resolve)
            local Network = require(ReplicatedSourceFolder:WaitForChild("Libs"):WaitForChild("Network"))
            Network.startClientAsync()
            
            local ModuleLoader = require(ReplicatedSourceFolder:WaitForChild("ModuleLoader"))
            ModuleLoader()
            
            local ClientDataService = require(ReplicatedSourceFolder:WaitForChild("PlayerData"):WaitForChild("ClientDataService"))
            ClientDataService.init()
            if not ClientDataService.hasLoaded() then
                ClientDataService.loaded:Wait()
            end
            
            -- get dev product list
            
            updateProgress()
            resolve()
        end)
    end

    local function loadCharacterAndAnimationsAsync()
        return LeanPromise.new(function(resolve)
            local CharacterLoadedWrapper = require(ReplicatedSourceFolder:WaitForChild("Utility"):WaitForChild("CharacterLoadedWrapper"))
            local characterloadedWrapper = CharacterLoadedWrapper.new(player)
            if not characterloadedWrapper:isLoaded() then
                characterloadedWrapper.loaded:Wait()
            end

            -- Disable player controls until the loading screen has finished.
            local playerScripts = player:WaitForChild("PlayerScripts")
            local controls = require(playerScripts:WaitForChild("PlayerModule")):GetControls()
            controls:Disable()
            
            local PreloadAnimations = require(script.Parent.PreloadAnimations)
            PreloadAnimations.PreloadPickaxeAnimations(player.Character :: Model)
            
            task.wait(0.5) 
            
            updateProgress()
            resolve()
        end)
    end

    local function loadUIAsync()
        return LeanPromise.new(function(resolve)
            local preloadUI = require(script.Parent.preloadUI)
            preloadUI(player)
            
            updateProgress()
            resolve()
        end)
    end

    LoadingScreen.updateDetailText(`Loading experience assets... (0/{totalTasks})`)

    local currentThread = coroutine.running()

    LeanPromise.all({
        loadGameSystemsAsync(),
        loadCharacterAndAnimationsAsync(),
        loadUIAsync()
    }):catch(function(err)
        warn(`Experienced an error while loading assets:`, err)
    end):finally(function()
        task.spawn(currentThread)
    end)

    coroutine.yield()

    -- any additional functionality goes here

    LoadingScreen.updateDetailText("Finishing up...")
    task.wait(1)
	LoadingScreen.DisableAsync()

    local playerScripts = player:WaitForChild("PlayerScripts")
    local controls = require(playerScripts:WaitForChild("PlayerModule")):GetControls()
    controls:Enable()
end

preGameLoadTasksAsync()
task.wait(2) -- Additional wait in case there isn't enough time to work the magic
waitForGameLoadedAsync()
postGameLoadTasksAsync()
