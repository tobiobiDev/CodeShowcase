--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PreloadAnimations = {}

local animator: Animator? = nil
local animationsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations")

local function preloadAnimation(anim: Animation): AnimationTrack?
    if not animator then
        return nil
    end
    local track = animator:LoadAnimation(anim)
    return track
end

function PreloadAnimations.PreloadPickaxeAnimations(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    local pickaxeAnimationFolder = animationsFolder:WaitForChild("Pickaxe")
    for _, anim in pickaxeAnimationFolder:GetChildren() do
        if anim:IsA("Animation") then
            preloadAnimation(anim)
        end
    end

    local weaponAnimationFolder = animationsFolder:WaitForChild("Weapon")
    for _, anim in weaponAnimationFolder:GetChildren() do
        if anim:IsA("Animation") then
            preloadAnimation(anim)
        end
    end
end

return PreloadAnimations
