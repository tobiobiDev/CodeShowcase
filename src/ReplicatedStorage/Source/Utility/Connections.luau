--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Libs.Signal)

--[[
	Takes a table of connections and then disconnects them all when prompted.
--]]
local Connections = {}
Connections.__index = Connections

type ConnectionOrSignal = RBXScriptConnection | Signal.Connection

type ClassType = {
    _connections: { RBXScriptConnection | Signal.Connection },
    add: (self: Connections, ...ConnectionOrSignal) -> (),
    remove: (self: Connections, ...ConnectionOrSignal) -> (),
    disconnect: (self: Connections) -> (),
}

export type Connections = setmetatable<ClassType, typeof(Connections)>

function Connections.new(): Connections
	local self = setmetatable({}, Connections) :: Connections
    self._connections = {}

	return self
end

function Connections.add(self: Connections, ...: ConnectionOrSignal)
	for _, connection in { ... } do
		assert(not table.find(self._connections, connection), "This connection has already been added")
		table.insert(self._connections, connection)
	end
end

function Connections.remove(self: Connections, connection: ConnectionOrSignal)
	local index = table.find(self._connections, connection)
	if index then
		table.remove(self._connections, index)
	end
end

function Connections.disconnect(self: Connections)
	for _, connection in self._connections do
        (connection :: RBXScriptConnection):Disconnect()
	end

	self._connections = {}
end

return Connections
