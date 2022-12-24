local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox

local SmolText = require("components.SmolText")
local smolFont = require("fonts.smolfont")

return Solyd.wrapComponent("SmolButton", function(props)
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    return SmolText {
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
        aabb = useBoundingBox(props.x, props.y, props.width or smolFont:getWidth(props.text), smolFont.height+3, props.onClick),
    }
end)
