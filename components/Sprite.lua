local Solyd = require("modules.solyd")

return Solyd.wrapComponent("Sprite", function(props)
    local canvas = Solyd.useContext("canvas")[1]

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
