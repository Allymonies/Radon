local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local smolFont = require("fonts.smolfont")

return Solyd.wrapComponent("SmolText", function(props)
    local fw = props.width or smolFont:getWidth(props.text)+2
    local bgHeight = 3
    local canvas = useCanvas(props.display, fw, smolFont.height+bgHeight)--Solyd.useContext("canvas")

    Solyd.useEffect(function()
        if props.bg then
            for x = 1, fw do
                for y = 1, smolFont.height+bgHeight do
                    canvas:setPixel(x, y, props.bg)
                end
            end
        end

        local cx = 0
        if props.width then
            if props.align == "center" then
                cx = math.floor((props.width - smolFont:getWidth(props.text)) / 2)
            elseif props.align == "right" then
                cx = props.width - smolFont:getWidth(props.text) - 2
            end
        end
        smolFont:write(canvas, props.text, 2 + cx, bgHeight+1, props.color or colors.white)

        return function()
            canvas:markRect(1, 1, fw, smolFont.height+bgHeight)
        end
    end, { canvas, props.display, props.align, props.text, props.color, props.bg, fw })

    local x = props.right and props.x-canvas.width+1 or props.x
    return nil, { canvas = { canvas, x, props.y } }
end)
