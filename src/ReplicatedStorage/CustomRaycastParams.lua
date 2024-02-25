--!strict
local CustomRaycastParams = {}

type Properties = {
    BruteForceAllSlow: boolean?,
    CollisionGroup: string?,
    FilterDescendantsInstances: { BasePart },
    FilterType: Enum.RaycastFilterType?,
    IgnoreWater: boolean?,
    RespectCanCollide: boolean?,
}
type AnyTable = { [any]: any }

local function fillDefaults<From, T>(properties: From & AnyTable, defaults: T & AnyTable): T | AnyTable
    local filled = {}

    for key, value in defaults :: AnyTable do
        local propertyFound = (properties :: AnyTable)[key]
        filled[key] = if propertyFound ~= nil then propertyFound else value
    end

    return filled
end

function CustomRaycastParams.new(properties: Properties?)
    local castedProperties: Properties = fillDefaults(properties or {}, {
        BruteForceAllSlow = false,
        CollisionGroup = "Default",
        FilterDescendantsInstances = {},
        FilterType = Enum.RaycastFilterType.Exclude,
        IgnoreWater = false,
        RespectCanCollide = true,
    })
    local raycastParams = RaycastParams.new()

    -- need to typecast in order to iterate over, sacrificing typesafety for one
    -- less type error
    for property, value in castedProperties :: AnyTable do
        (raycastParams :: any)[property] = value
    end

    return raycastParams
end

return CustomRaycastParams
