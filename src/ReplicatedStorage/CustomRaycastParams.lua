--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utils.Types)
local Utils = require(ReplicatedStorage.Utils)

local CustomRaycastParams = {}

type Properties = {
    BruteForceAllSlow: boolean?,
    CollisionGroup: string?,
    FilterDescendantsInstances: Types.Array<BasePart>,
    FilterType: Enum.RaycastFilterType?,
    IgnoreWater: boolean?,
    RespectCanCollide: boolean?,
}

function CustomRaycastParams.new(properties: Properties?)
    local castedProperties: Properties = Utils.Table.defaults(properties or {}, {
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
    for property, value in castedProperties :: Types.Table do
        (raycastParams :: any)[property] = value
    end

    return raycastParams
end

return CustomRaycastParams
