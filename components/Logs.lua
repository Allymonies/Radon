local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local BasicText = require("components.BasicText")
local useTextCanvas = hooks.useTextCanvas

return Solyd.wrapComponent("Logs", function(props)
    local canvas = useTextCanvas(props.display, props.width*2, props.height*3)
    local texts = {}
    local logMessageY = props.height
    for i = 1, math.min(#props.logs, props.height) do
        local logMessage = "[" .. textutils.formatTime(props.logs[i].time, true) .. "] " .. props.logs[i].text
        local numLines = math.ceil(#logMessage / props.width)
        if logMessageY - numLines + 1 < 0 then
            break
        end
        for j = 1, numLines do
            local line = logMessage:sub((j - 1) * props.width + 1, j * props.width)
            table.insert(texts, BasicText {
                key = "logs-"..tostring(i).."-"..tostring(j),
                display = props.display,
                align = "left",
                text = line,
                x = 1,
                y = logMessageY - numLines + j + 1,
                color = props.color,
                bg = props.bg,
            })
        end
        logMessageY = logMessageY - numLines
    end

    return texts, { canvas = { canvas, props.x*2-1, props.y*3-2 } }
end)
