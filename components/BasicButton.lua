local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox

local BasicText = require("components.BasicText")

return Solyd.wrapComponent("BasicButton", function(props)
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    return BasicText {
        display = props.display,
        align = props.align,
        text = props.text,
        x = props.x,
        y = props.y,
        bg = props.bg,
        color = props.color,
        width = props.width,
    }, {
        -- canvas = canvas,
        aabb = useBoundingBox((props.x*2)-1, (props.y*3)-2, (props.width or #props.text)*2, 3, props.onClick, props.onScroll),
    }
end)
