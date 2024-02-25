--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)
local CustomRaycastParams = require(ReplicatedStorage.CustomRaycastParams)

local player = CustomPlayer.get()
local Movement = {}

type UnitVector = Vector3
type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult?
type OffsetGeneratorProperties = {
    Negate: boolean,
}
type OffsetGenerator = (OffsetGeneratorProperties?) -> UnitVector
export type DirectionCallbacks = {
    [string]: OffsetGenerator,
}
type Context = {
    ActivatedKeys: { string },
    Callback: ActionHandler,
    DirectionCallbacks: DirectionCallbacks,
    FallingVelocity: Vector3,
    MovementVelocity: Vector3,
    OffsetCallbacks: { OffsetGenerator },
}

-- TODO: Combine into 1 stepped event handler
local function applyGravity(context: Context, delta: number)
    local playerTorsoUnderside = player.Character.Torso.Position - Vector3.new(0, player.Character.Torso.Size.Y / 2)
    local directlyBelow = Vector3.new(0, -1 / 10, 0)
    local parameters = CustomRaycastParams.new({
        FilterDescendantsInstances = { workspace.Baseplate, workspace.SpawnLocation },
        FilterType = Enum.RaycastFilterType.Include,
        IgnoreWater = true,
    })
    local collision = workspace:Raycast(playerTorsoUnderside, directlyBelow, parameters)

    if collision then
        context.FallingVelocity = Vector3.zero

        return
    end

    context.FallingVelocity += Vector3.new(0, workspace.Gravity * delta, 0)
end

local function extractKeyCodesFrom(directions: DirectionCallbacks): { Enum.KeyCode }
    local keyCodes = {}

    for name, _ in directions do
        local success, keyCodeFound: Enum.KeyCode | string = pcall(function()
            -- even with the pcall present, dynamically accessing this enum
            -- causes a type error, so we have to cast to any - blame my lsp
            return (Enum.KeyCode :: any)[name]
        end)

        if not success and typeof(keyCodeFound) == "string" then
            local errorMessage = keyCodeFound

            error(errorMessage)
        end

        table.insert(keyCodes, keyCodeFound)
    end

    return keyCodes
end

local function processMovement(context: Context, delta: number)
    local movementVelocity = Vector3.zero

    for _, key in context.ActivatedKeys do
        local calculateOffsetCallback = context.DirectionCallbacks[key]

        if calculateOffsetCallback == nil then
            error(`Invalid direction callback for input {key}`)
        end

        local offset = calculateOffsetCallback()
        movementVelocity += offset
    end

    local activatedKeysCount = #context.ActivatedKeys
    local atStandstill = movementVelocity == Vector3.zero

    if activatedKeysCount == 0 or atStandstill then
        movementVelocity = Vector3.zero

        if not atStandstill then
            movementVelocity = Vector3.zero
        end
    else
        movementVelocity = movementVelocity.Unit * player.Character.Humanoid.WalkSpeed
    end

    if context.FallingVelocity ~= Vector3.zero then
        player.Character.Movement.VectorVelocity = movementVelocity - context.FallingVelocity

        return
    end

    player.Character.Movement.VectorVelocity = movementVelocity
end

local function bindMovementToPlayerCharacter(context: Context)
    local keys = extractKeyCodesFrom(context.DirectionCallbacks)

    ContextActionService:BindAction("Movement", context.Callback, false, table.unpack(keys))
    RunService.RenderStepped:Connect(function(delta: number)
        applyGravity(context, delta)
    end)
    RunService.Stepped:Connect(function(_, delta: number)
        processMovement(context, delta)
    end)
end

function Movement.init(directions: DirectionCallbacks, callback: ActionHandler?)
    local activatedKeys: { string } = {}
    local movementVelocity = Vector3.zero

    if callback == nil then
        local function handleMovementDefault(action: string, state: Enum.UserInputState, input: InputObject)
            local keyName = input.KeyCode.Name

            if state == Enum.UserInputState.Begin then
                table.insert(activatedKeys, keyName)
            else
                local keyAtIndex = table.find(activatedKeys, keyName)

                table.remove(activatedKeys, keyAtIndex)
            end

            return Enum.ContextActionResult.Pass
        end

        callback = handleMovementDefault
    end

    local context: Context = {
        ActivatedKeys = activatedKeys,
        Callback = callback :: ActionHandler,
        DirectionCallbacks = directions,
        FallingVelocity = Vector3.zero,
        MovementVelocity = movementVelocity,
        OffsetCallbacks = {},
    }

    if player.Character then
        bindMovementToPlayerCharacter(context)
    end

    player.CharacterAdded:Connect(function()
        bindMovementToPlayerCharacter(context)
    end)
end

return Movement
