local Movement = require(script.Movement)

local DIRECTIONS: Movement.Directions = {
	W = Vector3.new(0, 0, 1),
	A = Vector3.new(-1, 0, 0),
	S = Vector3.new(0, 0, -1),
	D = Vector3.new(1, 0, 0),
}

Movement.init(DIRECTIONS)

return nil
