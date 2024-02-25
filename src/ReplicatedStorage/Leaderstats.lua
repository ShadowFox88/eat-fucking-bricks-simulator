--!strict
local ServerStorage = game:GetService("ServerStorage")

local Types = require(script.Parent.Types)

local LEADERSTATS_TEMPLATE = ServerStorage.leaderstats
local Leaderstats = {}

export type Type = Types.Leaderstats

function Leaderstats.find(rawPlayer: Player): Types.Leaderstats?
    local player = rawPlayer :: Types.CustomPlayer

    return player:FindFirstChild("leaderstats") :: Types.Leaderstats?
end

function Leaderstats.init(rawPlayer: Player)
    local player = rawPlayer :: Types.CustomPlayer
    local leaderstats = LEADERSTATS_TEMPLATE:Clone() :: Types.Leaderstats
    leaderstats.Parent = player

    leaderstats.BricksEaten.Changed:Connect(function()
        player.Character.Torso.Size += Vector3.one
    end)

    return leaderstats
end

return Leaderstats
