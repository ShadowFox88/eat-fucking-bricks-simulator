--!strict
local Players = game:GetService("Players")

local Types = require(script.Parent.Types)

local CustomPlayer = {}

export type Type = Types.CustomPlayer
export type Character = Types.Character

function CustomPlayer.get(rawPlayer: Player?): Types.CustomPlayer
    local player = (rawPlayer or Players.LocalPlayer) :: Types.CustomPlayer
    local playerCharacter = (player.Character or player.CharacterAdded:Wait()) :: Character

    playerCharacter:WaitForChild("HumanoidRootPart")

    return player
end

return CustomPlayer
