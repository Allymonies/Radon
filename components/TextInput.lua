local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useBoundingBox = hooks.useBoundingBox
local useInput = hooks.useInput

local BasicText = require("components.BasicText")

local function numToHex(num)
    return "#" .. string.format("%06x", num)
end

return Solyd.wrapComponent("TextInput", function(props)
    --print("Test")
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    if props.inputState.value and type(props.inputState.value) == "number" then
        if props.type == "number" then
            props.inputState.value = tostring(props.inputState.value)
        elseif props.type == "colorpicker" then
            props.inputState.value = numToHex(props.inputState.value)
        end
    end
    if not props.inputState.value then
        props.inputState.value = ""
    end
    local inputState, setInputState = Solyd.useState(props.inputState)
    if not inputState.prevValue then
        inputState.prevValue = inputState.value
        --setInputState(inputState)
    end
    if not inputState.active then
        inputState.active = false
        --setInputState(inputState)
    end
    inputState.cursorY = props.y
    if not inputState.cursorPos then
        inputState.cursorPos = #inputState.value + 1
        inputState.viewPort = 1
        inputState.cursorX = props.x + inputState.cursorPos - 1
        --setInputState(inputState)
    end

    function addChar(char)
        if props.type == "number" then
            if char == "." then
                if inputState.value:find("%.") then
                    return
                end
            elseif char:match("%D") then
                return
            elseif char == "-" then
                if inputState.cursorPos ~= 1 or inputState.value:find("%-") then
                    return
                end
            end
        elseif props.type == "colorpicker" then
            if char == "x" then
                if inputState.cursorPos == 1 and inputState.value:find("x") then
                    return
                elseif inputState.cursorPos == 2 and (inputState.value:sub(1, 1) ~= "0" or inputState.value:find("x")) then
                    return
                elseif inputState.cursorPos >= 3 then
                    return
                end
            elseif char == "#" then
                if inputState.cursorPos == 1 and inputState.value:find("#") then
                    return
                elseif inputState.cursorPos >= 2 then
                    return
                end
            elseif char:match("%X") then
                return
            else
                if inputState.cursorPos == 1 and (inputState.value:find("x") or inputState.value:find("#")) then
                    return
                elseif inputState.cursorPos == 2 and (inputState.value:sub(2, 2) == "x") then
                    return
                end
            end
        end
        inputState.value = inputState.value:sub(1, inputState.cursorPos-1) .. char .. inputState.value:sub(inputState.cursorPos)
        inputState.cursorPos = inputState.cursorPos + 1
        inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
        if inputState.cursorPos > inputState.viewPort + props.width - 1 then
            inputState.viewPort = inputState.viewPort + 1
        end
        setInputState(inputState)
    end

    return BasicText {
        display = props.display,
        align = props.align,
        text = inputState.value:sub(inputState.viewPort, inputState.viewPort + props.width - 1),
        x = props.x,
        y = props.y,
        bg = props.bg,
        color = props.color,
        width = props.width,
    },
    {
        -- canvas = canvas,
        aabb = useBoundingBox((props.x*2)-1, (props.y*3)-2, (props.width)*2, (props.height)*3,
            function() -- onClick
                inputState.active = true
                inputState.viewPort = math.max(1, inputState.cursorPos - props.width + 1)
                inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                setInputState(inputState)
            end,
            function(dir) -- onScroll
                if props.type == "number" and inputState.value and inputState.value ~= "" then
                    inputState.value = tostring(tonumber(inputState.value) - dir)
                    setInputState(inputState)
                    if props.onChange then
                        if props.type == "number" and inputState.value ~= nil then
                            props.onChange(tonumber(inputState.value))
                        else
                            props.onChange(inputState.value)
                        end
                    end
                    return true
                end
            end),
        input = useInput(props.x, props.y, props.width, props.height, inputState, addChar,
            function(key, held)
                if key == keys.backspace then
                    if inputState.cursorPos > 1 then
                        inputState.value = inputState.value:sub(1, inputState.cursorPos-2) .. inputState.value:sub(inputState.cursorPos)
                        inputState.cursorPos = inputState.cursorPos - 1
                        inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                        if inputState.cursorPos < inputState.viewPort then
                            inputState.viewPort = inputState.viewPort - 1
                        end
                        setInputState(inputState)
                    end
                elseif key == keys.delete then
                    if inputState.cursorPos < #inputState.value + 1 then
                        inputState.value = inputState.value:sub(1, inputState.cursorPos-1) .. inputState.value:sub(inputState.cursorPos+1)
                        setInputState(inputState)
                    end
                elseif key == keys.enter then
                    inputState.active = false
                    inputState.viewPort = 1
                    if inputState.value ~= inputState.prevValue then
                        if props.onChange then
                            if props.type == "number" and inputState.value ~= nil then
                                props.onChange(tonumber(inputState.value))
                            elseif props.type == "colorpicker" and inputState.value ~= nil then
                                -- Convert hex to number
                                local hex = inputState.value
                                hex = hex:gsub("#", "")
                                hex = hex:gsub("x", "")
                                props.onChange(tonumber(hex, 16))
                            else
                                props.onChange(inputState.value)
                            end
                        end
                        inputState.prevValue = inputState.value
                    end
                    setInputState(inputState)
                elseif key == keys.left then
                    if inputState.cursorPos > 1 then
                        inputState.cursorPos = inputState.cursorPos - 1
                        if inputState.cursorPos < inputState.viewPort then
                            inputState.viewPort = inputState.viewPort - 1
                        end
                        inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                        setInputState(inputState)
                    end
                elseif key == keys.right then
                    if inputState.cursorPos < #inputState.value + 1 then
                        inputState.cursorPos = inputState.cursorPos + 1
                        if inputState.cursorPos > inputState.viewPort + props.width - 1 then
                            inputState.viewPort = inputState.viewPort + 1
                        end
                        inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                        setInputState(inputState)
                    end
                elseif key == keys.home then
                    inputState.cursorPos = 1
                    inputState.viewPort = 1
                    inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                    setInputState(inputState)
                elseif key == keys["end"] then
                    inputState.cursorPos = #inputState.value + 1
                    inputState.viewPort = math.max(1, inputState.cursorPos - props.width + 1)
                    inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                    setInputState(inputState)
                end
            end,
            function()
                -- On blur
                if inputState.value ~= inputState.prevValue then
                    if props.onChange then
                        if props.type == "number" and inputState.value ~= nil then
                            props.onChange(tonumber(inputState.value))
                        else
                            props.onChange(inputState.value)
                        end
                    end
                    inputState.prevValue = inputState.value
                end
                setInputState(inputState)
            end,
            function(contents)
                -- On paste
                if props.type == "number" then
                    contents = contents:gsub("[^%d]", "")
                elseif props.type == "colorpicker" then
                    if contents:sub(1, 1) ~= "#" or contents:sub(1,2):find("x") then
                        contents = "#" .. contents:gsub("[^%x]", "")
                    else
                        contents:gsub("[^%x]", "")
                    end
                end
                inputState.value = inputState.value:sub(1, inputState.cursorPos-1) .. contents .. inputState.value:sub(inputState.cursorPos)
                inputState.cursorPos = inputState.cursorPos + #contents
                if inputState.cursorPos > inputState.viewPort + props.width - 1 then
                    inputState.viewPort = inputState.cursorPos - props.width + 2
                end
                inputState.cursorX = props.x + inputState.cursorPos - inputState.viewPort
                setInputState(inputState)
            end
        ),
    }
end)
