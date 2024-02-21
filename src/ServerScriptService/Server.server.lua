--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local LEADERSTATS_TEMPLATE: Model = ServerStorage.leaderstats
local BASEPLATE = workspace:WaitForChild("Baseplate") :: Part
local BRICK: Part = ServerStorage.Brick
local debounces = {}

type Leaderstats = Model & {
	BricksEaten: IntValue,
}
type PlayerWithLeaderstats = Player & {
	leaderstats: Leaderstats,
}
type PlayerCharacter = Model & {
	Humanoid: Humanoid,
	Movement: LinearVelocity,
	Torso: Part,
}

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

	local playerFound = Players:GetPlayerFromCharacter(characterFound) :: PlayerWithLeaderstats?

	if not playerFound then
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

	newBrick.Parent = workspace
end

local function onPlayerAdded(player: Player)
	local leaderstats = LEADERSTATS_TEMPLATE:Clone() :: Leaderstats
	leaderstats.Parent = player

	leaderstats.BricksEaten.Changed:Connect(function(bricksEaten: number)
		local playerChar = player.Character :: PlayerCharacter
		playerChar.Torso.Size += Vector3.one
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

while true do
	spawnBrickOnto(BASEPLATE)

	task.wait(1 / 60)
end
