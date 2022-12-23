local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local bigFont = require("fonts.bigfont")

return Solyd.wrapComponent("BigText", function(props)
    local fw = props.width or bigFont:getWidth(props.text)+2
    local bgHeight = 6
    local canvas = useCanvas(fw, bigFont.height+bgHeight)--Solyd.useContext("canvas")

    Solyd.useEffect(function()
        if props.bg then
            for x = 1, fw do
                for y = 1, bigFont.height+bgHeight do
                    canvas:setPixel(x, y, props.bg)
                end
            end
        end

        local cx = props.width and math.floor((props.width - bigFont:getWidth(props.text)) / 2) or 0
        bigFont:write(canvas, props.text, 2 + cx, bgHeight-3, props.color or colors.white)

        return function()
            canvas:markRect(1, 1, fw, bigFont.height+bgHeight)
        end
    end, { canvas, props.text, props.color, props.bg, fw })

    local x = props.right and props.x-canvas.width+1 or props.x
    return nil, { canvas = { canvas, x, props.y } }
end)
