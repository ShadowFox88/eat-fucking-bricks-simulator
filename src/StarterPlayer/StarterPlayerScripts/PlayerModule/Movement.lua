local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerCharacter = player.Character or player.CharacterAdded:Wait()
local playerHumanoid: Humanoid = playerCharacter:WaitForChild("Humanoid")
local playerMovement: LinearVelocity = playerCharacter:WaitForChild("Movement")
local rawMovementVelocity = Vector3.zero
local Movement = {}

type UnitVector = Vector3
export type Directions = {
	W: UnitVector,
	A: UnitVector,
	S: UnitVector,
	D: UnitVector,
}

function Movement.default(directions: Directions)
	return function(action: string, state: Enum.UserInputState, input: InputObject)
		if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
			return
		end

		local direction = directions[input.KeyCode.Name]

		if not direction then
			error(`Invalid direction {direction} during input {input.KeyCode.Name}`)
		end

		if state == Enum.UserInputState.End then
			direction = -direction
		end

		rawMovementVelocity += direction

		if rawMovementVelocity == Vector3.zero then
			playerMovement.VectorVelocity = Vector3.zero
		else
			playerMovement.VectorVelocity = rawMovementVelocity.Unit * playerHumanoid.WalkSpeed
		end
	end
end

function Movement.init(directions: Directions, callback: ((string, Enum.UserInputState, InputObject) -> ())?)
	callback = callback or Movement.default(directions)

	ContextActionService:BindAction(
		"movement",
		callback,
		false,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D
	)
end

return Movement
