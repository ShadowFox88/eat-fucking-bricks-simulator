--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Context = require(ReplicatedStorage.Utils.Context)

export type CameraContext = {
    InFirstPerson: boolean,
    PanDelta: Vector2,
    ZoomFactor: number,
}

local cameraContext: CameraContext = Context.create({
    InFirstPerson = false,
    PanDelta = Vector2.zero,
    ZoomFactor = 5,
})

return {
    CameraContext = cameraContext,
}
