--!strict
-- TODO: Adjust orientation based on movement direction
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local rawMovementVelocity = Vector3.zero
local fallingVelocity = Vector3.zero
local activatedKeys: { string } = {}
local Movement = {}

type UnitVector = Vector3
type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult?
export type Directions = {
	W: () -> UnitVector,
	A: () -> UnitVector,
	S: () -> UnitVector,
	D: () -> UnitVector,
}

local function applyGravity(delta: number)
	local playerTorsoUnderside = player.Character.Torso.Position - Vector3.new(0, player.Character.Torso.Size.Y / 2)
	local directlyBelow = Vector3.new(0, -1 / 10, 0)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Baseplate, workspace.SpawnLocation }
	parameters.IgnoreWater = true
	local collision = workspace:Raycast(playerTorsoUnderside, directlyBelow, parameters)

	if collision then
		player.Character.Movement.VectorVelocity += fallingVelocity
		fallingVelocity = Vector3.zero

		return
	end

	local newFallingOffsetVelocity = Vector3.new(0, delta * workspace.Gravity, 0)
	fallingVelocity -= newFallingOffsetVelocity
	player.Character.Movement.VectorVelocity -= newFallingOffsetVelocity
end

local function bindMovementToPlayerCharacter(directions: Directions, callback: ActionHandler?)
	if callback == nil then
		local function handleMovementDefault(
			action: string,
			state: Enum.UserInputState,
			input: InputObject
		): Enum.ContextActionResult?
			if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
				return
			end

			local keyName = input.KeyCode.Name
			local calculateOffsetCallbackFound = directions[keyName]

			if not calculateOffsetCallbackFound then
				error(`Invalid direction {calculateOffsetCallbackFound} during input {keyName}`)
			end

			local offset = calculateOffsetCallbackFound()

			if state == Enum.UserInputState.End then
				offset = -offset
			end

			rawMovementVelocity += offset

			if state == Enum.UserInputState.Begin then
				table.insert(activatedKeys, keyName)
			else
				table.remove(activatedKeys, table.find(activatedKeys, keyName))
			end

			if #activatedKeys == 0 then
				player.Character.Movement.VectorVelocity = Vector3.zero
				rawMovementVelocity = Vector3.zero
			else
				player.Character.Movement.VectorVelocity = rawMovementVelocity.Unit
					* player.Character.Humanoid.WalkSpeed
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
	RunService.RenderStepped:Connect(applyGravity)
end

function Movement.init(directions: Directions, callback: ActionHandler?)
	if player.Character then
		bindMovementToPlayerCharacter(directions, callback)
	end

	player.CharacterAdded:Connect(function()
		bindMovementToPlayerCharacter(directions, callback)
	end)
end

return Movement
