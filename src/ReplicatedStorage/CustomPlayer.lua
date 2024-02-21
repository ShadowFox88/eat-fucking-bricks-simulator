--!strict
local Players = game:GetService("Players")

local Types = require(script.Parent.Types)

local CustomPlayer = {}

export type Type = Types.CustomPlayer
export type Character = Types.Character

function CustomPlayer.get(rawPlayer: Player?): Types.CustomPlayer
	if rawPlayer == nil then
		return rawPlayer :: Types.CustomPlayer
	end

	return Players.LocalPlayer :: Types.CustomPlayer
end

return CustomPlayer
