--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local UserInputService = game:GetService("UserInputService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)
local CustomRaycastParams = require(ReplicatedStorage.CustomRaycastParams)
local SharedState = require(script.Parent.SharedState)

local ZOOM_IN_FACTOR = 1
local ZOOM_OUT_FACTOR = -1
local player = CustomPlayer.get()
local playerCamera = workspace.CurrentCamera
local Camera = {}

local function getInstanceAheadOf(cameraCFrame: CFrame): Instance?
    local parameters = CustomRaycastParams.new({
        FilterDescendantsInstances = { player.Character.Torso },
        FilterType = Enum.RaycastFilterType.Include,
        IgnoreWater = true,
    })
    local collision = workspace:Raycast(cameraCFrame.Position, cameraCFrame.LookVector, parameters)

    return if collision then collision.Instance else nil
end

local function trackPlayerCharacter(context: SharedState.CameraContext)
    local orientation = CFrame.fromOrientation(
        -math.rad(context.PanDelta.Y * UserGameSettings.MouseSensitivity),
        -math.rad(context.PanDelta.X * UserGameSettings.MouseSensitivity),
        0
    )
    local positionalOffset = CFrame.new(0, player.Character.Torso.Size.Y + 2, 5)
    local zoomOffset = CFrame.new(0, 0, context.ZoomFactor)
    local origin = CFrame.new(player.Character.HumanoidRootPart.Position) * orientation * positionalOffset
    local newCameraCFrame = CFrame.new(origin.Position, player.Character.HumanoidRootPart.Position) * zoomOffset
    local instanceAhead = getInstanceAheadOf(newCameraCFrame)
    local cameraToCharacterDirection = playerCamera.CFrame.Position - player.Character.HumanoidRootPart.Position
    local studsFromCharacter = math.round(cameraToCharacterDirection.Magnitude)
    local inFirstPerson = studsFromCharacter == 0

    if instanceAhead and instanceAhead:IsDescendantOf(player.Character) then
        local insideCharacterCFrame = CFrame.new(
            player.Character.HumanoidRootPart.Position,
            player.Character.HumanoidRootPart.Position + player.Character.HumanoidRootPart.CFrame.LookVector
        )
        newCameraCFrame = insideCharacterCFrame
    end

    playerCamera.CFrame = newCameraCFrame

    if inFirstPerson ~= context.InFirstPerson then
        context.InFirstPerson = inFirstPerson
    end
end

local function togglePanning(state: Enum.UserInputState)
    if state == Enum.UserInputState.Begin then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    elseif state == Enum.UserInputState.End then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

local function pan(action: string, state: Enum.UserInputState, input: InputObject)
    if
        state ~= Enum.UserInputState.Begin
        and state ~= Enum.UserInputState.Change
        and state ~= Enum.UserInputState.End
    then
        return Enum.ContextActionResult.Pass
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        togglePanning(state)
    elseif
        input.UserInputType == Enum.UserInputType.MouseMovement
        and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition
    then
        local mouseDelta = UserInputService:GetMouseDelta()
        SharedState.CameraContext.PanDelta = Vector2.new(
            SharedState.CameraContext.PanDelta.X + mouseDelta.X,
            math.clamp(SharedState.CameraContext.PanDelta.Y + mouseDelta.Y, -110, 45)
        )
        print(SharedState.CameraContext.PanDelta)
    end

    return Enum.ContextActionResult.Pass
end

local function zoom(action: string, state: Enum.UserInputState, input: InputObject)
    if state ~= Enum.UserInputState.Change then
        return Enum.ContextActionResult.Pass
    end

    local scrollingUp = input.Position.Z == 1

    if scrollingUp and not SharedState.CameraContext.InFirstPerson then
        SharedState.CameraContext.ZoomFactor -= ZOOM_IN_FACTOR
    elseif not scrollingUp then
        SharedState.CameraContext.ZoomFactor -= ZOOM_OUT_FACTOR
    end

    return Enum.ContextActionResult.Pass
end

local function bindCameraToPlayerCharacter(context: SharedState.CameraContext)
    RunService.RenderStepped:Connect(function()
        trackPlayerCharacter(context)
    end)
    ContextActionService:BindAction(
        "pan",
        pan,
        false,
        Enum.UserInputType.MouseButton2,
        Enum.UserInputType.MouseMovement
    )
    ContextActionService:BindAction("zoom", zoom, false, Enum.UserInputType.MouseWheel)
end

function Camera.init()
    if player.Character then
        bindCameraToPlayerCharacter(SharedState.CameraContext)
    end

    player.CharacterAdded:Connect(function()
        bindCameraToPlayerCharacter(SharedState.CameraContext)
    end)
end

return Camera
