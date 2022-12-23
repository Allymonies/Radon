local _ = require("util.score")

local Solyd = require("modules.solyd")
local Canvases = require("modules.canvas")
local PixelCanvas = Canvases.PixelCanvas

local function tableSize(t)
    if type(t) ~= "table" then
        return nil
    end
    
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

---Renders a Solyd tree and bakes the canvases into one
function bakeToCanvas(rootComponent)
    local tree = Solyd.render(nil, rootComponent)
    local context = Solyd.getTopologicalContext(tree, { "canvas" })
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, canvas in ipairs(context.canvas) do
        minX = math.min(minX, canvas[2])
        minY = math.min(minY, canvas[3])
        maxX = math.max(maxX, canvas[2] + canvas[1].width - 1)
        maxY = math.max(maxY, canvas[3] + canvas[1].height - 1)
    end

    local canvas = PixelCanvas.new(maxX - minX + 1, maxY - minY + 1)
    canvas:composite(_.map(context.canvas, function(c)
        return {c[1], c[2] - minX + 1, c[3] - minY + 1}
    end))
    return canvas
end

return {
    tableSize = tableSize,
    bakeToCanvas = bakeToCanvas,
}
