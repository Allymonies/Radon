local Solyd = require("modules.solyd")

local Util = require("util.misc")

---@param props { canvas: PixelCanvas, x: integer, y: integer, remap: table }
return Solyd.wrapComponent("RenderCanvas", function(props)
    local remapped = Solyd.useMemo(function()
        if props.remap then
            return props.canvas:clone():mapColors(props.remap)
        else
            return props.canvas
        end
    end, {props.canvas, props.remap})

    return {}, { canvas = { remapped, props.x, props.y } }
end)
