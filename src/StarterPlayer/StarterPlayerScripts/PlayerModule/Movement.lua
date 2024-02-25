--!strict
-- TODO: Adjust orientation based on movement direction
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local Movement = {}

type UnitVector = Vector3
type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult?
export type Directions = {
	[string]: () -> UnitVector,
}
type State = {
	ActivatedKeys: { string },
	FallingVelocity: Vector3,
	RawMovementVelocity: Vector3,
}
type Context = {
	Callback: ActionHandler,
	DirectionCallbacks: Directions,
	State: State,
}

local function applyGravity(context: Context, delta: number)
	local playerTorsoUnderside = player.Character.Torso.Position - Vector3.new(0, player.Character.Torso.Size.Y / 2)
	local directlyBelow = Vector3.new(0, -1 / 10, 0)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Baseplate, workspace.SpawnLocation }
	parameters.IgnoreWater = true
	local collision = workspace:Raycast(playerTorsoUnderside, directlyBelow, parameters)

	if collision then
		player.Character.Movement.VectorVelocity += context.State.FallingVelocity
		context.State.FallingVelocity = Vector3.zero

		return
	end

	local newFallingOffsetVelocity = Vector3.new(0, delta * workspace.Gravity, 0)
	context.State.FallingVelocity -= newFallingOffsetVelocity
	player.Character.Movement.VectorVelocity -= newFallingOffsetVelocity
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

local function bindMovementToPlayerCharacter(context: Context)
	local keys = extractKeyCodesFrom(context.DirectionCallbacks)

	ContextActionService:BindAction("Movement", context.Callback, false, table.unpack(keys))
	RunService.RenderStepped:Connect(function(delta: number)
		applyGravity(context, delta)
	end)
end

function Movement.init(directions: Directions, callback: ActionHandler?)
	local state: State = {
		ActivatedKeys = {},
		FallingVelocity = Vector3.zero,
		RawMovementVelocity = Vector3.zero,
	}

	if callback == nil then
		local function processInputKeys(keyName: string, inputState: Enum.UserInputState): number
			if inputState == Enum.UserInputState.Begin then
				table.insert(state.ActivatedKeys, keyName)
			else
				local keyAtIndex = table.find(state.ActivatedKeys, keyName)

				table.remove(state.ActivatedKeys, keyAtIndex)
			end

			return #state.ActivatedKeys
		end

		local function handleMovementDefault(action: string, inputState: Enum.UserInputState, input: InputObject)
			if inputState ~= Enum.UserInputState.Begin and inputState ~= Enum.UserInputState.End then
				return
			end

			local keyName = input.KeyCode.Name
			local calculateOffsetCallback = directions[keyName]

			if calculateOffsetCallback == nil then
				error(`Invalid callback {calculateOffsetCallback} from calculating direction for input {keyName}`)
			end

			local offset = calculateOffsetCallback()

			if inputState == Enum.UserInputState.End then
				offset = -offset
			end

			state.RawMovementVelocity += offset
			local activatedKeysCount = processInputKeys(keyName, inputState)

			if activatedKeysCount == 0 then
				player.Character.Movement.VectorVelocity = Vector3.zero
				state.RawMovementVelocity = Vector3.zero
			else
				player.Character.Movement.VectorVelocity = state.RawMovementVelocity.Unit
					* player.Character.Humanoid.WalkSpeed
			end

			return Enum.ContextActionResult.Pass
		end

		callback = handleMovementDefault
	end

	local context: Context = {
		Callback = callback :: ActionHandler,
		DirectionCallbacks = directions,
		State = state,
	}

	if player.Character then
		bindMovementToPlayerCharacter(context)
	end

	player.CharacterAdded:Connect(function()
		bindMovementToPlayerCharacter(context)
	end)
end

return Movement
