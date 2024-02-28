--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Context = require(ReplicatedStorage.Utils.Context)
local CustomPlayer = require(ReplicatedStorage.CustomPlayer)
local CustomRaycastParams = require(ReplicatedStorage.CustomRaycastParams)
local Types = require(ReplicatedStorage.Utils.Types)

local player = CustomPlayer.get()
local Movement = {}

type UnitVector = Vector3
type ActionHandler = (string, Enum.UserInputState, InputObject) -> Enum.ContextActionResult
type OffsetGeneratorProperties = {
    Negate: boolean,
}
type OffsetGenerator = (OffsetGeneratorProperties?) -> UnitVector
export type DirectionCallbacks = Types.Record<string, OffsetGenerator>
type ContextDefaults = {
    ActivatedKeys: Types.Array<string>,
    Callback: ActionHandler,
    DirectionCallbacks: DirectionCallbacks,
    FallingVelocity: Vector3,
    MovementVelocity: Vector3,
    OffsetCallbacks: Types.Array<OffsetGenerator>,
}
type MovementContext = Context.Type<ContextDefaults>

local function applyGravity(context: MovementContext, delta: number)
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

local function extractKeyCodesFrom(directions: DirectionCallbacks): Types.Array<Enum.KeyCode>
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

local function adjustOrientation(context: MovementContext)
    local isMoving = context.MovementVelocity ~= Vector3.zero

    if (isMoving and not player.Character.Turning.Enabled) or (not isMoving and player.Character.Turning.Enabled) then
        player.Character.Turning.Enabled = isMoving
    end

    player.Character.Turning.CFrame = CFrame.new(
        player.Character.HumanoidRootPart.Position,
        player.Character.HumanoidRootPart.Position + context.MovementVelocity
    )
end

local function processMovement(context: MovementContext, delta: number)
    local newMovementVelocity = Vector3.zero

    for _, key in context.ActivatedKeys do
        local calculateOffsetCallback = context.DirectionCallbacks[key]

        if calculateOffsetCallback == nil then
            error(`Invalid direction callback for input {key}`)
        end

        local offset = calculateOffsetCallback()
        newMovementVelocity += offset
    end

    local activatedKeysCount = #context.ActivatedKeys
    local atStandstill = newMovementVelocity == Vector3.zero

    if activatedKeysCount == 0 or atStandstill then
        newMovementVelocity = Vector3.zero

        if not atStandstill then
            newMovementVelocity = Vector3.zero
        end
    else
        newMovementVelocity = newMovementVelocity.Unit * player.Character.Humanoid.WalkSpeed
    end

    if context.FallingVelocity ~= Vector3.zero then
        player.Character.Movement.VectorVelocity = newMovementVelocity - context.FallingVelocity

        return
    end

    context.MovementVelocity = newMovementVelocity
    player.Character.Movement.VectorVelocity = newMovementVelocity
end

local function bindMovementToPlayerCharacter(context: MovementContext)
    local keys = extractKeyCodesFrom(context.DirectionCallbacks)

    ContextActionService:BindAction("Movement", context.Callback, false, table.unpack(keys))
    RunService.Stepped:Connect(function(_, delta: number)
        applyGravity(context, delta)
        processMovement(context, delta)
        adjustOrientation(context)
    end)
end

function Movement.init(directions: DirectionCallbacks, callback: ActionHandler?)
    local activatedKeys: Types.Array<string> = {}
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

    local context: ContextDefaults = Context.create({
        ActivatedKeys = activatedKeys,
        Callback = callback :: ActionHandler,
        DirectionCallbacks = directions,
        FallingVelocity = Vector3.zero,
        MovementVelocity = movementVelocity,
        OffsetCallbacks = {},
    })

    if player.Character then
        bindMovementToPlayerCharacter(context)
    end

    player.CharacterAdded:Connect(function()
        bindMovementToPlayerCharacter(context)
    end)
end

return Movement
