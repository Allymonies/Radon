local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

return Solyd.wrapComponent("Sprite", function(props)
    local canvas = useCanvas(props.display, props.sprite.width, props.sprite.height)

    Solyd.useEffect(function()
        -- local s, x, y = props.sprite, props.x, props.y
        canvas:drawCanvas(props.sprite, props.x, props.y, props.remapFrom, props.remapTo)
        -- canvas:drawCanvasRotated(props.sprite, props.x, props.y, props.angle or 0)
        return function()
            canvas:markCanvas(props.sprite, props.x, props.y)
            -- canvas:markCanvasRotated(props.sprite, props.x, props.y, props.angle or 0)
        end
    end, { props.sprite, props.x, props.y, props.remapFrom, props.remapTo })
end)
