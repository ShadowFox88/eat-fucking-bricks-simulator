--!strict
local Camera = require(script.Camera)
local Directions = require(script.Directions)
local Movement = require(script.Movement)

Movement.init(Directions)
Camera.init()

return nil
