--[[
MIT License

Copyright (c) 2022 emmachase

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local Solyd = require("modules.solyd")

local function useInput(x, y, width, height, inputState, onChar, onKey, onBlur, onPaste)
    local input = Solyd.useRef(function()
        return { x = x, y = y, width = width, height = height, inputState = inputState, onChar = onChar, onKey = onKey, onBlur = onBlur, onPaste = onPaste}
    end).value

    input.x = x
    input.y = y
    input.width = width
    input.height = height
    input.inputState = inputState
    input.onChar = onChar
    input.onKey = onKey
    input.onBlur = onBlur
    input.onPaste = onPaste

    return input
end

local function findActiveInput(inputs)
    -- x, y = x*2, y*3
    for i = #inputs, 1, -1 do
        local input = inputs[i]
        if input.__type == "list" then
            local node = findActiveInput(input)
            if node then
                return node
            end
        else
            if input.inputState.active then
                return input
            end
        end
    end
end

local function clearActiveInput(inputs, x, y)
    for i = #inputs, 1, -1 do
        local input = inputs[i]
        if input.__type == "list" then
            clearActiveInput(input)
        else
            if input.inputState.active and (x*2 < input.x or x*2-1 >= input.x + input.width
            or y*3 < input.y or y*3-2 >= input.y + input.height) then
                input.inputState.active = false
                return input
            end
        end
    end
end

return {
    useInput = useInput,
    findActiveInput = findActiveInput,
    clearActiveInput = clearActiveInput,
}
