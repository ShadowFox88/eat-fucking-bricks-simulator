--!strict
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local UserInputService = game:GetService("UserInputService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local playerCamera = workspace.CurrentCamera
local panDelta = Vector2.zero
local Camera = {}

local function trackPlayerCharacter()
    local orientation = CFrame.fromOrientation(
        -math.rad(panDelta.Y * UserGameSettings.MouseSensitivity),
        -math.rad(panDelta.X * UserGameSettings.MouseSensitivity),
        0
    )
    local positionalOffset = CFrame.new(0, player.Character.Torso.Size.Y + 2, 5)
    local origin = CFrame.new(player.Character.HumanoidRootPart.Position) * orientation * positionalOffset
    playerCamera.CFrame = CFrame.new(origin.Position, player.Character.HumanoidRootPart.Position)
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
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        togglePanning(state)
    elseif
        input.UserInputType == Enum.UserInputType.MouseMovement
        and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition
    then
        panDelta += UserInputService:GetMouseDelta()
    end

    return Enum.ContextActionResult.Pass
end

local function bindCameraToPlayerCharacter()
    RunService.RenderStepped:Connect(trackPlayerCharacter)
    ContextActionService:BindAction(
        "pan",
        pan,
        false,
        Enum.UserInputType.MouseButton2,
        Enum.UserInputType.MouseMovement
    )
end

function Camera.init()
    if player.Character then
        bindCameraToPlayerCharacter()
    end

    player.CharacterAdded:Connect(bindCameraToPlayerCharacter)
end

return Camera
