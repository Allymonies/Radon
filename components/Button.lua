local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox

local BigText = require("components.BigText")
local bigFont = require("fonts.bigfont")

return Solyd.wrapComponent("Button", function(props)
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    return BigText {
        text = props.text,
        x = props.x,
        y = props.y,
        bg = props.bg,
        color = props.color,
        width = props.width,
    }, {
        -- canvas = canvas,
        aabb = useBoundingBox(props.x, props.y, props.width or bigFont:getWidth(props.text), bigFont.height+3, props.onClick),
    }
end)
