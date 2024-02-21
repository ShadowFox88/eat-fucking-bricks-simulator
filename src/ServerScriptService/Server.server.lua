--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)
local Leaderstats = require(ReplicatedStorage.Leaderstats)

local BASEPLATE = workspace:WaitForChild("Baseplate") :: Part
local BRICK = ServerStorage.Brick
local debounces = {}

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

	local debounceFound = debounces[playerFound]

	if not debounceFound then
		debounceFound = 1
		debounces[playerFound] = 1
	else
		debounceFound += 1
		debounces[playerFound] += 1
	end

	if debounceFound > 1 then
		return
	end

	playerFound.leaderstats.BricksEaten.Value += 1
	newBrick:Destroy()

	debounces[playerFound] = 0
end

local function spawnBrickOnto(part: Part)
	local newBrick = BRICK:Clone()
	newBrick.Color = Color3.fromRGB(255, 255, 0)
	newBrick.Position = calculatePositionOnTopOf(part, newBrick.Size.Y)

	newBrick.Touched:Connect(function(hit: BasePart)
		handleBrickTouched(hit, newBrick)
	end)

	-- TODO: Remove any type
	newBrick.Parent = workspace :: any
end

local function onPlayerAdded(rawPlayer: Player)
	local player = rawPlayer :: CustomPlayer.Type

	Leaderstats.init(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

while true do
	spawnBrickOnto(BASEPLATE)

	task.wait(1 / 60)
end
