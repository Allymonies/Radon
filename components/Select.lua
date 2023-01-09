local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox
local useInput = hooks.useInput

local Rect = require("components.Rect")
local BasicText = require("components.BasicText")
local BasicButton = require("components.BasicButton")
local Scrollbar = require("components.Scrollbar")

return Solyd.wrapComponent("Select", function(props)
    --print("Test")
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()
    local modal = Solyd.useContext("modal")
    local modalElements = modal[0]
    local setModalElements = modal[1]

    -- if not props.inputState.value then
    --     props.inputState.value = props.options[1].value
    -- end
    if not props.inputState.active then
        props.inputState.active = false
    end
    if not props.inputState.scroll then
        props.inputState.scroll = 0
    end
    if not props.inputState.maxScroll then
        props.inputState.maxScroll = math.max(#props.options - props.height, 0)
    end
    local inputState, setInputState = Solyd.useState(props.inputState)
    local newMaxScroll = math.max(#props.options - props.height, 0)
    if newMaxScroll ~= inputState.maxScroll then
        inputState.maxScroll = newMaxScroll
        setInputState(inputState)
    end
    local elements = {}
    local elementHeight = 3
    local xOffset = -1
    if inputState.active and modalElements then
        xOffset = 3
        for i = inputState.scroll+1, inputState.scroll + math.min(#props.options - inputState.scroll, props.height) do
            table.insert(modalElements, BasicButton {
                key = "select-option-" .. props.key .. "-" .. i,
                display = props.display,
                text = props.options[i].text,
                x = props.x + 2,
                y = props.y + (i - 1 - inputState.scroll),
                width = props.width - 3,
                height = props.height,
                bg = props.bg,
                color = props.color,
                onClick = function()
                    inputState.value = props.options[i].value
                    inputState.active = false
                    setInputState(inputState)
                    for j = 1, #modalElements do
                        table.remove(modalElements, 1)
                    end
                    setModalElements(modalElements)
                    if props.onChange then
                        props.onChange(inputState.value)
                    end
                end,
                onScroll = function(dir)
                    if dir <= -1 then
                        inputState.scroll = math.max(inputState.scroll + dir, 0)
                        setInputState(inputState)
                    elseif dir >= 1 then
                        inputState.scroll = math.min(inputState.scroll + dir, inputState.maxScroll)
                        setInputState(inputState)
                    end
                    return true
                end
            })
        end
        elementHeight = math.min(#props.options - inputState.scroll, props.height) * 3
        if #props.options > props.height then
            table.insert(modalElements, Scrollbar {
                key = "select-scrollbar-" .. props.key,
                display = props.display,
                x = (props.x + props.width - 1)*2 - 1,
                y = (props.y*3)-2,
                width = 2,
                height = props.height * 3,
                areaHeight = props.height * 3,
                scroll = inputState.scroll * 3,
                maxScroll = inputState.maxScroll * 3,
                color = props.scrollbarColor,
                bg = props.bg,
            })
        end
        setModalElements(modalElements)
    else
        local valueText = inputState.value
        for i = 1, #props.options do
            if props.options[i].value == inputState.value then
                valueText = props.options[i].text
            end
        end
        table.insert(elements, BasicText {
            key = "select-value-" .. props.key,
            display = props.display,
            text = valueText or "",
            x = props.x+2,
            y = props.y,
            width = props.width-2,
            height = 1,
            color = props.color,
            bg = props.bg,
        })
        if setModalElements then
            setModalElements({})
        end
    end

    local arrow = "> "
    if inputState.active then
        arrow = "v "
    end
    table.insert(elements, BasicText {
        key = "select-arrow-" .. arrow .. "-" .. props.key,
        display = props.display,
        text = arrow,
        x = props.x,
        y = props.y,
        width = 2,
        height = 1,
        color = props.toggleColor,
        bg = props.bg,
    })

    return elements,
    {
        -- canvas = canvas,
        aabb = useBoundingBox((props.x*2)+xOffset, (props.y*3)-1, props.width*2, elementHeight, function()
            inputState.active = true
            setInputState(inputState)
        end,
        function(dir) -- onScroll
            if inputState.active then
                if dir <= -1 then
                    inputState.scroll = math.max(inputState.scroll + dir, 0)
                    setInputState(inputState)
                elseif dir >= 1 then
                    inputState.scroll = math.min(inputState.scroll + dir, inputState.maxScroll)
                    setInputState(inputState)
                end
                return true
            end
        end),
        input = useInput((props.x*2)+xOffset, (props.y*3)-1, props.width*2, elementHeight, inputState, function(char)
            -- Select based on first letter
            setInputState(inputState)
        end,
        function(key, held)
            if key == keys.backspace then
                inputState.value = nil
                setInputState(inputState)
            elseif key == keys.delete then
                inputState.value = nil
                setInputState(inputState)
            elseif key == keys.enter then
                inputState.active = false
                if props.onChange then
                    props.onChange(inputState.value)
                end
                setInputState(inputState)
                for i = 1, #modalElements do
                    table.remove(modalElements, 1)
                end
                setModalElements(modalElements)
            elseif key == keys.up then
                inputState.scroll = math.max(inputState.scroll - 1, 0)
                setInputState(inputState)
            elseif key == keys.down then
                inputState.scroll = math.min(inputState.scroll + 1, inputState.maxScroll)
                setInputState(inputState)
            end
        end,
        function()
            -- On blur
            inputState.active = false
            setInputState(inputState)
            for i = 1, #modalElements do
                table.remove(modalElements, 1)
            end
            setModalElements(modalElements)
        end
        ),
    }
end)
