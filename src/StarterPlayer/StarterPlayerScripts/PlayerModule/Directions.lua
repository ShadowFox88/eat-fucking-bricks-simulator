--!strict
-- TODO: Simplify
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage.Utils)

local playerCamera = workspace.CurrentCamera

type CreateCameraOffsetCallbackProperties = {
    Negate: boolean,
}
type CameraOffsetCallbackProperties = {
    Negate: boolean?,
}

local function createCameraOffsetCallback(
    vectorName: "LookVector" | "RightVector",
    properties: CreateCameraOffsetCallbackProperties?
)
    local castedProperties: CreateCameraOffsetCallbackProperties = Utils.Table.defaults(properties or {}, {
        Negate = false,
    })

    return function(predicateProperties: CameraOffsetCallbackProperties?)
        local castedPredicateProperties: CameraOffsetCallbackProperties =
            Utils.Table.defaults(predicateProperties or {}, {
                Negate = false,
            })

        local success, vector: Vector3 | string = pcall(function()
            return (playerCamera.CFrame :: any)[vectorName]
        end)

        if not success and typeof(vector) == "string" then
            local errorMessage = vector

            error(errorMessage)
        end

        if castedPredicateProperties.Negate then
            vector = -vector
        end

        local flattened = Vector3.new(vector.X, 0, vector.Z)

        return if castedProperties.Negate then -flattened else flattened
    end
end

return {
    W = createCameraOffsetCallback("LookVector"),
    A = createCameraOffsetCallback("RightVector", {
        Negate = true,
    }),
    S = createCameraOffsetCallback("LookVector", {
        Negate = true,
    }),
    D = createCameraOffsetCallback("RightVector"),
}
