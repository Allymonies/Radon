local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

return Solyd.wrapComponent("Rect", function(props)
    local canvas = useCanvas(props.display, props.width, props.height)--Solyd.useContext("canvas")

    Solyd.useEffect(function()
        if props.color then
            for x = 1, props.width do
                for y = 1, props.height do
                    canvas:setPixel(x, y, props.color)
                end
            end
        end
        return function()
            canvas:markRect(1, 1, props.width, props.height)
        end
    end, { canvas, props.display, props.x, props.y, props.width, props.height, props.color })

    return nil, { canvas = { canvas, props.x, props.y } }
end)
