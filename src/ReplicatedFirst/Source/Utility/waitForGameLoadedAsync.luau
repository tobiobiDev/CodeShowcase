--!strict
--[[
    Returns when the initial snapshopt of the game has finished replicating to the client.

    Used by the client-side entry point script to determine when it's OK to hide the loading screen.
]]
return function()
    if game:IsLoaded() then
        return
    end

    game.Loaded:Wait()
end
