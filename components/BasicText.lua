local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useTextCanvas = hooks.useTextCanvas

return Solyd.wrapComponent("BasicText", function(props)
    local fw = props.width or #props.text
    local canvas = useTextCanvas(props.display, fw*2, 1)

    Solyd.useEffect(function()
        local text = props.text
        if props.width then
            if props.align == "center" then
                local leftPad = math.floor((props.width - #text) / 2)
                local rightPad = props.width - #text - leftPad
                text = string.rep(" ", leftPad) .. text .. string.rep(" ", rightPad)
            elseif props.align == "right" then
                text = string.rep(" ", props.width - #text) .. text
            else
                text = text .. string.rep(" ", props.width - #text)
            end
        end
        if props.width and #text > props.width then
            text = text:sub(1, props.width)
        end
        canvas:write(text, 1, 1, props.color or colors.white, props.bg or colors.black)

        return function()
            canvas:markText(text, 1, 1)
        end
    end, { canvas, props.display, props.align, props.text, props.color, props.bg, fw })

    local x = props.right and props.x-canvas.width+1 or props.x
    return nil, { canvas = { canvas, x*2-1, props.y*3-2 } }
end)
