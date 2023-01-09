local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox
local useInput = hooks.useInput

local Rect = require("components.Rect")

return Solyd.wrapComponent("Toggle", function(props)
    --print("Test")
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    if not props.inputState.value then
        props.inputState.value = false
    end
    local inputState, setInputState = Solyd.useState(props.inputState)

    local offColor = props.offColor
    local onColor = props.bg
    if inputState.value then
        offColor = props.bg
        onColor = props.onColor
    end
    local stateWidth = math.floor(props.width / 3)
    local stateMiddle = props.width - (stateWidth * 2)

    return {
        Rect {
            key = "toggle-off-" .. props.key,
            display = props.display,
            x = props.x,
            y = props.y,
            width = stateWidth,
            height = props.height,
            color = offColor
        },
        Rect {
            key = "toggle-middle-" .. props.key,
            display = props.display,
            x = props.x + stateWidth,
            y = props.y,
            width = stateMiddle,
            height = props.height,
            color = props.color
        },
        Rect {
            key = "toggle-on-" .. props.key,
            display = props.display,
            x = props.x + stateWidth + stateMiddle,
            y = props.y,
            width = stateWidth,
            height = props.height,
            color = onColor
        },
    },
    {
        -- canvas = canvas,
        aabb = useBoundingBox(props.x, props.y, props.width, props.height, function() inputState.value = not inputState.value setInputState(inputState) if props.onChange then props.onChange(inputState.value) end end),
    }
end)
