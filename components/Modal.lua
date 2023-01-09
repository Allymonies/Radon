local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox
local useInput = hooks.useInput

local Rect = require("components.Rect")
local BasicText = require("components.BasicText")
local BasicButton = require("components.BasicButton")
local Scrollbar = require("components.Scrollbar")

return Solyd.wrapComponent("Modal", function(props)
    --print("Test")
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()
    local modal = Solyd.useContext("modal")
    if not modal[0] then
        modal[0], modal[1] = Solyd.useState({})
    end
    local modalElements = modal[0]
    local setModalElements = modal[1]

    local elements = {}

    for i = 1, #modalElements do
        table.insert(elements, modalElements[i])
    end

    return elements, {}
end)
