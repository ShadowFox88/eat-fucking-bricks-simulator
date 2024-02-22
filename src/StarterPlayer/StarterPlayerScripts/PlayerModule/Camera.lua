--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CustomPlayer = require(ReplicatedStorage.CustomPlayer)

local player = CustomPlayer.get()
local playerCamera = workspace.CurrentCamera
local Camera = {}

local function trackPlayerCharacter()
	local origin = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, player.Character.Torso.Size.Y + 2, 5)
	playerCamera.CFrame = CFrame.new(origin.Position, player.Character.HumanoidRootPart.Position)
end

local function bindCameraToPlayerCharacter()
	RunService.RenderStepped:Connect(trackPlayerCharacter)
end

function Camera.init()
	if player.Character then
		bindCameraToPlayerCharacter()
	end

	player.CharacterAdded:Connect(bindCameraToPlayerCharacter)
end

return Camera
