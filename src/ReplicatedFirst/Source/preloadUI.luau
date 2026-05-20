--!strict
local ContentProvider = game:GetService("ContentProvider")

local function preloadUI(player: Player)
    local playerGui = player.PlayerGui
    local images = {}

    for _, screenGui in playerGui:GetChildren() do
        if not screenGui:IsA("ScreenGui") then
            continue
        end

        for _, instance in screenGui:GetDescendants() do
            if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
                table.insert(images, instance)
            end
        end
    end

    ContentProvider:PreloadAsync(images)
end

return preloadUI
