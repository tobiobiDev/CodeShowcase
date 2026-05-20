local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Source.Libs.Network)
local ModuleLoader = require(ReplicatedStorage.Source.ModuleLoader)

Network.startServer()
ModuleLoader()
