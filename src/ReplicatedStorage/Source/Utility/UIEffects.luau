--!strict

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundEffects = require(script.Parent.SoundEffects)

export type Button = TextButton | ImageButton

local UIEffects = {}

local soundFolder = SoundService:WaitForChild("GUISounds")
local hoverSound = soundFolder:FindFirstChild("Hover") :: Sound
local clickSound = soundFolder:FindFirstChild("Click") :: Sound
local activeTweens = {}

local function scaleObject(guiObject: GuiObject, originalSize: UDim2, scale: number, tweenInfo: TweenInfo): Tween
	local newSize: UDim2 = UDim2.new(
		originalSize.X.Scale * scale,
		originalSize.X.Offset * scale,
		originalSize.Y.Scale * scale,
		originalSize.Y.Offset * scale
	)

	local tween: Tween = TweenService:Create(guiObject, tweenInfo, {
		Size = newSize,
	})

	tween:Play()
	return tween
end

function UIEffects.ToggleBounceUI(frame: Frame, open: boolean, size: UDim2?)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	if activeTweens[frame] then
		activeTweens[frame]:Cancel()
		activeTweens[frame] = nil
	end

	if open then
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Visible = true

		local openTween = TweenService:Create(frame, tweenInfo, {
			Size = size or UDim2.fromScale(0.5, 0.5),
		})

		activeTweens[frame] = openTween

		openTween:Play()
		openTween.Completed:Connect(function()
			if activeTweens[frame] == openTween then
				activeTweens[frame] = nil
			end
		end)
	else
		local closeTween = TweenService:Create(frame, tweenInfo, {
			Size = UDim2.fromScale(0, 0),
		})

		activeTweens[frame] = closeTween

		closeTween:Play()
		closeTween.Completed:Connect(function()
			if activeTweens[frame] == closeTween then
				frame.Visible = false
				activeTweens[frame] = nil
			end
		end)
	end
end

-- Hover Effect
function UIEffects.ApplyHoverEffect(button: Button, hoverScale: number?, duration: number?): ()
	local scale: number = hoverScale or 1.08
	local tweenDuration: number = duration or 0.15

	local originalSize: UDim2 = button.Size
	local tweenInfo: TweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local activeTween: Tween? = nil

	local hover = button:FindFirstChild("Hover")

	button.MouseEnter:Connect(function()
		if activeTween then
			activeTween:Cancel()
		end

		if hover and hover:IsA("Frame") then
			hover.Visible = true
		end

		SoundEffects.PlaySound(hoverSound)
		activeTween = scaleObject(button, originalSize, scale, tweenInfo)
	end)

	button.MouseLeave:Connect(function()
		if activeTween then
			activeTween:Cancel()
		end

		if hover and hover:IsA("Frame") then
			hover.Visible = false
		end

		activeTween = scaleObject(button, originalSize, 1, tweenInfo)
	end)
end

-- Bounce Click Effect
function UIEffects.ApplyBounceClick(button: Button, shrinkScale: number?, duration: number?): ()
	local scale: number = shrinkScale or 0.92
	local tweenDuration: number = duration or 0.08

	local originalSize: UDim2 = button.Size

	local shrinkTweenInfo: TweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local growTweenInfo: TweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local activeTween: Tween? = nil

	button.MouseButton1Down:Connect(function()
		if activeTween then
			activeTween:Cancel()
		end

		local shrinkTween: Tween = scaleObject(button, originalSize, scale, shrinkTweenInfo)
		activeTween = shrinkTween

		shrinkTween.Completed:Connect(function()
			activeTween = scaleObject(button, originalSize, 1, growTweenInfo)
		end)
	end)
end
function UIEffects.ApplyClickSound(button: Button): ()
	button.Activated:Connect(function()
		if clickSound.IsPlaying then
			SoundEffects.StopSound(clickSound)
		end

		SoundEffects.PlaySound(clickSound)
	end)
end

function UIEffects.FadeText(textLabel: TextLabel, transparency: number)
	textLabel.Visible = true
	local uiStroke = textLabel:FindFirstChildOfClass("UIStroke")
	if uiStroke then
		local tween = TweenService:Create(uiStroke, TweenInfo.new(1), { Transparency = transparency })
		tween:Play()
	end

	local tween = TweenService:Create(textLabel, TweenInfo.new(1), { TextTransparency = transparency })
	tween:Play()

	tween.Completed:Connect(function()
		textLabel.Visible = transparency == 0
	end)
end

return UIEffects
