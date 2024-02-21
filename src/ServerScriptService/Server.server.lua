local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
print("Hello world!")

local LEADERSTATS_TEMPLATE: Model = ServerStorage.leaderstats
local BASEPLATE = workspace:WaitForChild("Baseplate") :: Part
local BRICK: Part = ServerStorage.Brick
local debounces = {}

local function onPlayerAdded(player: Player)
	local leaderstats = LEADERSTATS_TEMPLATE:Clone()
	leaderstats.Parent = player

	leaderstats.BricksEaten.Changed:Connect(function(bricksEaten: number)
		local playerChar = player.Character :: Model
		local playerTorso: Part = playerChar.Torso
		playerTorso.Size += Vector3.one
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

while true do
	-- TODO: break out into function
	local newBrick = BRICK:Clone()
	newBrick.Color = Color3.fromRGB(255, 255, 0)
	newBrick.Position = BASEPLATE.Position
		+ Vector3.new(
			math.random(-BASEPLATE.Size.X / 2, BASEPLATE.Size.X / 2),
			(BASEPLATE.Size.Y / 2) + newBrick.Size.Y,
			math.random(-BASEPLATE.Size.X / 2, BASEPLATE.Size.X / 2)
		)

	newBrick.Touched:Connect(function(hit: Part)
		local characterFound = hit:FindFirstAncestorOfClass("Model")
		local playerFound = Players:GetPlayerFromCharacter(characterFound)

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
	end)

	newBrick.Parent = workspace

	task.wait(1 / 60)
end
