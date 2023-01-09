local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local Rect = require("components.Rect")
local useCanvas = hooks.useCanvas

return Solyd.wrapComponent("Scrollbar", function(props)
    local canvas = useCanvas(props.display, props.width, props.height)--Solyd.useContext("canvas")

    local elements = {}
    local scrollBarSize = math.max(
        0,
        math.floor(props.height * (props.areaHeight / (props.maxScroll + props.areaHeight)))
    )
    local scrollProgress = props.scroll / props.maxScroll
    local scrollSpace = props.height - scrollBarSize
    local scrollBarPos = math.max(0,
        math.min(
            math.floor(props.height - scrollBarSize),
            math.floor(scrollSpace * scrollProgress)
        )
    )
    table.insert(elements, Rect {
        key = "scrollbar-bg-" .. props.key,
        display = props.display,
        x = props.x,
        y = props.y,
        width = props.width,
        height = props.height,
        color = props.bg,
    })
    table.insert(elements, Rect {
        key = "scrollbar-" .. props.key,
        display = props.display,
        x = props.x,
        y = props.y + scrollBarPos,
        width = props.width,
        height = scrollBarSize,
        color = props.color,
    })

    return elements, { canvas = { canvas, props.x, props.y } }
end)
