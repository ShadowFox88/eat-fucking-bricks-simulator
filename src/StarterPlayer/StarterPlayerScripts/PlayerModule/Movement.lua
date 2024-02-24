--!strict
-- TODO: Adjust orientation based on movement direction
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local rawMovementVelocity = Vector3.zero
local fallingVelocity = Vector3.zero
local dynamicMovementConnection: RBXScriptConnection
local Movement = {}

type UnitVector = Vector3
type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult?
export type Directions = {
	[string]: () -> UnitVector,
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

local function processInputKeys(keyName: string, state: Enum.UserInputState, cache: { string }): number
	if state == Enum.UserInputState.Begin then
		table.insert(cache, keyName)
	else
		table.remove(cache, table.find(cache, keyName))
	end

	return #cache
end

local function extractKeyCodesFrom(directions: Directions): { Enum.KeyCode }
	local keyCodes = {}

	for name, _ in directions do
		local success, keyCodeFound = pcall(function()
			-- no better way to bypass the type error of this causing an error,
			-- even with the pcall present
			return (Enum.KeyCode :: any)[name]
		end)

		if not success then
			local errorMessage = keyCodeFound

			error(errorMessage)
		end

		table.insert(keyCodes, keyCodeFound)
	end

	return keyCodes
end

local function bindMovementToPlayerCharacter(directions: Directions, callback: ActionHandler?)
	if callback == nil then
		local activatedKeys: { string } = {}

		local function handleMovementDefault(action: string, state: Enum.UserInputState, input: InputObject)
			if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
				return
			end

			local keyName = input.KeyCode.Name
			local calculateOffsetCallback = directions[keyName]

			if calculateOffsetCallback == nil then
				error(`Invalid callback {calculateOffsetCallback} from calculating direction for input {keyName}`)
			end

			local offset = calculateOffsetCallback()

			if state == Enum.UserInputState.End then
				offset = -offset
			end

			rawMovementVelocity += offset
			local activatedKeysCount = processInputKeys(keyName, state, activatedKeys)

			if activatedKeysCount == 0 then
				player.Character.Movement.VectorVelocity = Vector3.zero
				rawMovementVelocity = Vector3.zero
			else
				player.Character.Movement.VectorVelocity = rawMovementVelocity.Unit
					* player.Character.Humanoid.WalkSpeed
			end

			return Enum.ContextActionResult.Pass
		end

		callback = handleMovementDefault
	end

	local keys = extractKeyCodesFrom(directions)

	ContextActionService:BindAction("Movement", callback :: ActionHandler, false, table.unpack(keys))
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
