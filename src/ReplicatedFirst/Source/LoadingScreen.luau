--!strict
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local ViewportModelLibrary =
	require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Libs"):WaitForChild("ViewportModelLibrary"))

local MIN_RUNTIME = 2 -- The minimum time (s) that the laoding screen will show
local INTERVAL = 2 -- The delay between shines
local PICKAXE_SHINE_SPEED = 0.6 -- The time (s) for the picakxe shine to tween from left to right
local SCREEN_SHAKE_INTENSITY = 10 -- Intensity level to chake the screen on pickaxe hit

local player = assert(Players.LocalPlayer, "Failed to get LocalPlayer")

local loadingScreenPrefab = assert(ReplicatedFirst:FindFirstChild("LoadingScreenPrefab"))
local pickaxeFolder: Folder? = nil

local shineTweenInfo = TweenInfo.new(PICKAXE_SHINE_SPEED, Enum.EasingStyle.Linear)
local shineGoal = { Offset = Vector2.new(1, 0) }

local backSwingInfo = TweenInfo.new(0.75)
local backSwingGoal = { Rotation = -30 }

local frontSwingInfo = TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local frontSwingGoal = { Rotation = 90 }

local backgroundTiles: { ImageLabel } = {}

local elapsed = 0

--[[
    A base setup for the loading screen which can be filled out more as the
    loading screen prefab is updated.
]]
local LoadingScreen = {}
LoadingScreen._instance = loadingScreenPrefab:Clone() :: ScreenGui
LoadingScreen._contentFrame = nil :: CanvasGroup?
LoadingScreen._background = nil :: Frame?
LoadingScreen._viewport = nil :: ViewportFrame?
LoadingScreen._startTime = 0
LoadingScreen._shineConnection = nil :: RBXScriptConnection?
LoadingScreen._fadeTweenBackground = nil :: Tween?


local function getRandomPickaxe(): Model?
	pickaxeFolder = ReplicatedFirst:WaitForChild("Pickaxes") :: Folder

	local eligibleModels: { Model } = {}
	for _, child in pickaxeFolder:GetChildren() do
		local model = child:FindFirstChildOfClass("Model")
		if model then
			table.insert(eligibleModels, model)
		end
	end

	if #eligibleModels == 0 then
		return nil
	end

	return eligibleModels[math.random(#eligibleModels)]
end

local function fadeLoadingScreen()
	if LoadingScreen._background then
		TweenService:Create(LoadingScreen._background, TweenInfo.new(1), { Transparency = 1 }):Play()
	end

	if LoadingScreen._fadeTweenBackground then
		LoadingScreen._fadeTweenBackground:Play()
		LoadingScreen._fadeTweenBackground.Completed:Wait()
	end
end

local function applyScreenShake()
	if not LoadingScreen._contentFrame then
		return
	end

	local fadeTime = 1

	local basePosition = LoadingScreen._contentFrame.Position
	local baseRotation = LoadingScreen._contentFrame.Rotation

	local posMagnitude = SCREEN_SHAKE_INTENSITY
	local rotMagnitude = 1
	local time = 0

	RunService:BindToRenderStep("shake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		if not LoadingScreen._contentFrame then
			RunService:UnbindFromRenderStep("shake")
			return
		end
		time += dt * 6 -- shake speed

		local x = math.noise(time, 0) * posMagnitude
		local y = math.noise(0, time) * posMagnitude
		local r = math.noise(time, time) * rotMagnitude

		LoadingScreen._contentFrame.Position = basePosition + UDim2.fromOffset(x, y)
		LoadingScreen._contentFrame.Rotation = baseRotation + r
	end)

	task.delay(fadeTime, function()
		RunService:UnbindFromRenderStep("shake")
	end)
end

local function crumbleBackground()
	for _, tile in backgroundTiles do
		local fallDistance = 1
		local rotationAmount = math.random(-90, 90)
		local duration = math.random(40, 80) / 100 -- 0.4 to 0.8 seconds

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local tween = TweenService:Create(tile, tweenInfo, {
			Position = tile.Position + UDim2.fromScale(0, fallDistance),
			Rotation = rotationAmount,
		})

		tween:Play()
	end
end

local function wrapUp(delay: number?)
	fadeLoadingScreen()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	-- Disable backpack Gui to use Custom inventory
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	if delay then
		task.wait(delay)
	end

	LoadingScreen._instance:Destroy()
	if pickaxeFolder then
		pickaxeFolder:Destroy()
	end
end

local function swingPickaxe()
	local hitSound = LoadingScreen._instance:FindFirstChild("PickaxeHit") :: Sound
	local rockCrumbleSound = LoadingScreen._instance:FindFirstChild("RockCrumbling") :: Sound

	local backSwingTween = TweenService:Create(LoadingScreen._viewport :: ViewportFrame, backSwingInfo, backSwingGoal)
	local forwardSwingTween =
		TweenService:Create(LoadingScreen._viewport :: ViewportFrame, frontSwingInfo, frontSwingGoal)

	local hitEffect = (LoadingScreen._contentFrame :: CanvasGroup):WaitForChild("HitEffect") :: CanvasGroup

	backSwingTween:Play()
	backSwingTween.Completed:Once(function()
		forwardSwingTween:Play()
		task.delay(0.2, function()
			hitSound:Play()
			rockCrumbleSound:Play()
			TweenService:Create(hitEffect, TweenInfo.new(0.1), { Size = UDim2.fromScale(0.5, 0.5) }):Play()

			applyScreenShake()
			crumbleBackground()

			task.wait(0.05)

			local hitFadeTween = TweenService:Create(hitEffect, TweenInfo.new(0.2), { GroupTransparency = 1 })
			hitFadeTween:Play()
			hitFadeTween.Completed:Wait()

			task.delay(0.5, wrapUp, 1.61)
		end)
	end)
end

function LoadingScreen.enableAsync()
	local playerGui = player:WaitForChild("PlayerGui")
	LoadingScreen._instance.Parent = playerGui

	-- Remove default loading screen now that ours in in place
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	-- Disable core Gui display
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	-- Get the Viewport and shine to randomly select a pickaxe and start the tween
	LoadingScreen._background = LoadingScreen._instance:FindFirstChild("BackestOfGrounds") :: Frame
	LoadingScreen._contentFrame = LoadingScreen._instance:FindFirstChild("ContentFrame") :: CanvasGroup
	LoadingScreen._viewport = if LoadingScreen._contentFrame
		then LoadingScreen._contentFrame:FindFirstChildOfClass("ViewportFrame")
		else nil
	local shine = if LoadingScreen._contentFrame
		then LoadingScreen._contentFrame:FindFirstChild("PickaxeShine") :: ImageLabel
		else nil
	local shineGradient = if shine then shine:FindFirstChildOfClass("UIGradient") else nil
	if not (LoadingScreen._viewport and shineGradient) then
		error(`'PickaxeShine' and/or ViewportFrame not found in 'ContentFrame' of laoding screen GUI `)
	end

	local shineTween = TweenService:Create(shineGradient, shineTweenInfo, shineGoal)

	LoadingScreen._fadeTweenBackground =
		TweenService:Create(LoadingScreen._contentFrame :: CanvasGroup, TweenInfo.new(1), { GroupTransparency = 1 })

	local randomPickaxeModel: Model? = getRandomPickaxe()
	if not randomPickaxeModel then
		warn("Failed to find a random pickaxe")
		LoadingScreen._startTime = os.clock()
		return
	end

	ViewportModelLibrary.CleanViewport(LoadingScreen._viewport) -- Clean just in case
	ViewportModelLibrary.GenerateViewport(LoadingScreen._viewport, randomPickaxeModel:Clone())

	LoadingScreen._shineConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime

		if elapsed >= INTERVAL then
			elapsed -= INTERVAL

			shineTween:Play()
			shineTween.Completed:Connect(function()
				shineGradient.Offset = Vector2.new(-1, 0)
			end)
		end
	end)

	local background = if LoadingScreen._contentFrame
		then LoadingScreen._contentFrame:FindFirstChild("Background") :: Frame
		else nil
	if not background then
		return
	end

	for _, tile in background:GetChildren() do
		if tile:IsA("ImageLabel") then
			table.insert(backgroundTiles, tile)
		end
	end

	LoadingScreen._startTime = os.clock()
end

function LoadingScreen.updateDetailText(text: string)
	local detailTextLabel = if LoadingScreen._contentFrame
		then LoadingScreen._contentFrame:FindFirstChildOfClass("TextLabel")
		else nil
	if not detailTextLabel then
		warn(`'DetailTextLabel' not found in 'ContentFrame' of loading screen GUI.`)
		return
	end
	detailTextLabel.Text = text
end

function LoadingScreen.DisableAsync()
	-- Implementing a minimum time in case the game loads super fast to prevent
	-- a quick flashing loading screen from occurring.
	local runTime = os.clock() - LoadingScreen._startTime
	task.wait(math.max(0, MIN_RUNTIME - runTime))

	if not LoadingScreen._contentFrame then
		LoadingScreen._instance:Destroy()
		return
	end

	if LoadingScreen._shineConnection then
		LoadingScreen._shineConnection:Disconnect()
	end

	if not LoadingScreen._viewport then
		warn(`Missing ViewportFrame from LaodingScreen GUI`)

		task.spawn(wrapUp, nil)
		return
	end

	swingPickaxe()
end

return LoadingScreen
