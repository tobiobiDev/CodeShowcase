--!strict
--[[
	Returns the instance corresponding with the given path of object names by yielding until they exist.

	Useful for accessing nested Instance trees that stream in on the client. For example:
	```lua
	local remoteEventsFolder = waitForChildInstanceAsync(ReplicatedStorage, "Source", "Network", "RemoteEvents") :: Folder
	```
]]
local function waitForChildInstanceAsync<T>(instance: Instance, ...: string): T
	for _, childName in { ... } do
		local child = instance:WaitForChild(childName)
		instance = child
	end

	-- We want this function to be callable with generic types
	return (instance :: any) :: T
end

return waitForChildInstanceAsync
