--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local rawMovementVelocity = Vector3.zero
local Movement = {}

type UnitVector = Vector3
export type Directions = {
	W: UnitVector,
	A: UnitVector,
	S: UnitVector,
	D: UnitVector,
}

type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult?

local function bindMovementToPlayerCharacter(playerCharacter: Model, directions: Directions, callback: ActionHandler?)
	if callback == nil then
		local function handleMovementDefault(
			action: string,
			state: Enum.UserInputState,
			input: InputObject
		): Enum.ContextActionResult?
			if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
				return
			end

			local playerMovement = playerCharacter:WaitForChild("Movement") :: LinearVelocity
			local playerHumanoid = playerCharacter:WaitForChild("Humanoid") :: Humanoid
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

			return nil
		end

		callback = handleMovementDefault
	end

	ContextActionService:BindAction(
		"Movement",
		callback :: ActionHandler,
		false,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D
	)
end

function Movement.init(directions: Directions, callback: ActionHandler?)
	if player.Character then
		bindMovementToPlayerCharacter(player.Character, directions, callback)
	end

	player.CharacterAdded:Connect(function(playerCharacter: Model)
		bindMovementToPlayerCharacter(playerCharacter, directions, callback)
	end)
end

return Movement
