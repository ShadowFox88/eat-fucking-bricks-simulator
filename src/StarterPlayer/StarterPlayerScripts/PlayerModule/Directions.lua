--!strict
-- TODO: Simplify
local playerCamera = workspace.CurrentCamera

type AnyTable = { [any]: any }
type CreateCameraOffsetCallbackProperties = {
    Negate: boolean,
}
type CameraOffsetCallbackProperties = {
    Negate: boolean?,
}

-- TODO: Incorporate into utils
local function fillDefaults<From, T>(properties: From & AnyTable, defaults: T & AnyTable): T | AnyTable
    local filled = {}

    for key, value in defaults :: AnyTable do
        local propertyFound = (properties :: AnyTable)[key]
        filled[key] = if propertyFound ~= nil then propertyFound else value
    end

    return filled
end

local function createCameraOffsetCallback(
    vectorName: "LookVector" | "RightVector",
    properties: CreateCameraOffsetCallbackProperties?
)
    local castedProperties: CreateCameraOffsetCallbackProperties = fillDefaults(properties or {}, {
        Negate = false,
    })

    return function(predicateProperties: CameraOffsetCallbackProperties?)
        local castedPredicateProperties: CameraOffsetCallbackProperties = fillDefaults(predicateProperties or {}, {
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
