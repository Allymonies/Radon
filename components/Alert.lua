local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox

local BasicText = require("components.BasicText")
local BasicButton = require("components.BasicButton")

return Solyd.wrapComponent("Alert", function(props)
    local text = props.text
    local lines = {}
    local textWidth = props.width - 2
    for line in text:gmatch("[^\n]+") do
        for j = 1, math.ceil(#line / textWidth) do
            table.insert(lines, line:sub((j-1)*textWidth, (j)*textWidth - 1))
        end
    end
    local elements = {}
    table.insert(elements, BasicText {
        key = props.key .. "-header",
        display = props.display,
        align = "left",
        text = "",
        x = props.x,
        y = props.y,
        bg = props.borderColor,
        color = props.color,
        width = props.width,
    })
    local lineY = 0
    for i = 1, #lines do
        if (i+1) >= props.height then
            break
        end
        lineY = lineY + 1
        table.insert(elements, BasicText {
            key = props.key .. "-line-" .. i,
            display = props.display,
            align = props.align,
            text = lines[i],
            x = props.x + 1,
            y = props.y + i,
            bg = props.bg,
            color = props.color,
            width = props.width - 2,
        })
        table.insert(elements, BasicText {
            key = props.key .. "-filler-bl-" .. i,
            display = props.display,
            align = "left",
            text = " ",
            x = props.x,
            y = props.y + i,
            bg = props.borderColor,
            color = props.color,
            width = 1,
        })
        table.insert(elements, BasicText {
            key = props.key .. "-filler-br-" .. i,
            display = props.display,
            align = "left",
            text = " ",
            x = props.x + props.width - 1,
            y = props.y + i,
            bg = props.borderColor,
            color = props.color,
            width = 1,
        })
    end
    for i = lineY + 1, props.height - 2 do
        table.insert(elements, BasicText {
            key = props.key .. "-filler-" .. i,
            display = props.display,
            align = "left",
            text = "",
            x = props.x + 1,
            y = props.y + i,
            bg = props.bg,
            color = props.color,
            width = props.width - 2,
        })
        table.insert(elements, BasicText {
            key = props.key .. "-filler-bl-" .. i,
            display = props.display,
            align = "left",
            text = " ",
            x = props.x,
            y = props.y + i,
            bg = props.borderColor,
            color = props.color,
            width = 1,
        })
        table.insert(elements, BasicText {
            key = props.key .. "-filler-br-" .. i,
            display = props.display,
            align = "left",
            text = " ",
            x = props.x + props.width - 1,
            y = props.y + i,
            bg = props.borderColor,
            color = props.color,
            width = 1,
        })
    end
    table.insert(elements, BasicText {
        key = props.key .. "-footer",
        display = props.display,
        align = "left",
        text = "",
        x = props.x,
        y = props.y + props.height - 1,
        bg = props.borderColor,
        color = props.color,
        width = props.width,
    })
    local cancelText = props.cancelText or "Cancel"
    local confirmText = props.confirmText or "Confirm"
    local buttonsWidth = #cancelText + #confirmText + 2
    local buttonsX = math.floor(props.x + (props.width - buttonsWidth) / 2)
    table.insert(elements, BasicButton {
        key = props.key .. "-cancel",
        display = props.display,
        align = "left",
        text = cancelText,
        x = buttonsX,
        y = props.y + props.height - 2,
        bg = props.buttonColor,
        color = props.buttonTextColor,
        width = props.buttonsWidth,
        onClick = props.onCancel,
    })
    table.insert(elements, BasicButton {
        key = props.key .. "-confirm",
        display = props.display,
        align = "left",
        text = confirmText,
        x = buttonsX + #cancelText + 2,
        y = props.y + props.height - 2,
        bg = props.buttonColor,
        color = props.buttonTextColor,
        width = props.buttonsWidth,
        onClick = props.onConfirm,
    })

    return elements
end)
