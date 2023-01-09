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

local function useBoundingBox(x, y, w, h, onClick, onScroll)
    local box = Solyd.useRef(function()
        return { x = x, y = y, w = w, h = h, onClick = onClick, onScroll = onScroll }
    end).value

    box.x = x
    box.y = y
    box.w = w
    box.h = h
    box.onClick = onClick
    box.onScroll = onScroll

    return box
end

local function findNodeAt(boxes, x, y)
    -- x, y = x*2, y*3
    for i = #boxes, 1, -1 do
        local box = boxes[i]
        if box.__type == "list" then
            local node = findNodeAt(box, x, y)
            if node then
                return node
            end
        else
            if  x*2 >= box.x and x*2-1 < box.x + box.w
            and y*3 >= box.y and y*3-2 < box.y + box.h then
                return box
            end
        end
    end
end

return {
    useBoundingBox = useBoundingBox,
    findNodeAt = findNodeAt,
}
