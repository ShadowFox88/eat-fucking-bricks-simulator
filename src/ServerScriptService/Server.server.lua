--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)
local Leaderstats = require(ReplicatedStorage.Leaderstats)

local BASEPLATE = workspace:WaitForChild("Baseplate") :: Part
local BRICK = ServerStorage.Brick
local touchCountTracker = {}

local function calculatePositionOnTopOf(part: Part, brickHeight: number)
    local offset = Vector3.new(
        math.random(-part.Size.X / 2, part.Size.X / 2),
        (part.Size.Y / 2) + brickHeight,
        math.random(-part.Size.X / 2, part.Size.X / 2)
    )

    return part.Position + offset
end

local function handleBrickTouched(hit: BasePart, newBrick: Part)
    local characterFound = hit:FindFirstAncestorOfClass("Model")

    if not characterFound then
        return
    end

    local playerFound = Players:GetPlayerFromCharacter(characterFound) :: CustomPlayer.Type?

    if not (playerFound and Leaderstats.find(playerFound)) then
        return
    end

    local touchCountFound = touchCountTracker[playerFound]

    if not touchCountFound then
        touchCountFound = 1
        touchCountTracker[playerFound] = 1
    else
        touchCountTracker[playerFound] += 1
    end

    if touchCountFound > 1 then
        return
    end

    playerFound.leaderstats.BricksEaten.Value += 1
    newBrick:Destroy()

    touchCountTracker[playerFound] = 0
end

local function spawnBrickOnto(part: Part)
    local newBrick = BRICK:Clone()
    newBrick.Color = Color3.fromRGB(255, 255, 0)
    newBrick.Position = calculatePositionOnTopOf(part, newBrick.Size.Y)

    newBrick.Touched:Connect(function(hit: BasePart)
        handleBrickTouched(hit, newBrick)
    end)

    -- without casting to any, workspace is seen as the original parent of
    -- newBrick, ServerStorage - this causes an unavoidable type error that can
    -- only be remedied by the following (as far as im aware)
    newBrick.Parent = workspace :: any
end

Players.PlayerAdded:Connect(Leaderstats.init)

while true do
    spawnBrickOnto(BASEPLATE)

    task.wait(1 / 60)
end
