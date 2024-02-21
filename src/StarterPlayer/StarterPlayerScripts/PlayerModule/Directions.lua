--!strict
local playerCamera = workspace.CurrentCamera
local Directions = {}

local function flattenVector(vector: Vector3)
	return Vector3.new(vector.X, 0, vector.Z)
end

function Directions.W()
	return flattenVector(playerCamera.CFrame.LookVector)
end

function Directions.A()
	return flattenVector(-playerCamera.CFrame.RightVector)
end

function Directions.S()
	return flattenVector(-playerCamera.CFrame.LookVector)
end

function Directions.D()
	return flattenVector(playerCamera.CFrame.RightVector)
end

return Directions
