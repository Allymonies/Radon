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

local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas

---@class Font
---@field private chars { [string]: FontChar }
---@field height number
---@field kerning number
local Font = {}
local Font_mt = { __index = Font }

---@alias FontChar PixelCanvas

---@param char PixelCanvas
local function fixChar(char)
    for y = 1, char.height do
        for x = 1, char.width do
            if char.canvas[y][x] == colors.black then
                char.canvas[y][x] = nil
            end
        end
    end

    return char
end

---@param canvas PixelCanvas
---@param text string
---@param x integer
---@param y integer
---@param c integer
function Font:write(canvas, text, x, y, c)
    local cx = x
    for i = 1, #text do
        local char = self.chars[text:sub(i, i)]
        if char then
            canvas:drawTint(char, cx, y, c)
            cx = cx + char.width + self.kerning
        end
    end
end

---@param text string
function Font:getWidth(text)
    local width = 0
    for i = 1, #text do
        local char = self.chars[text:sub(i, i)]
        if char then
            width = width + char.width + 1
        end
    end

    if width == 0 then
        return 0
    end

    return width - 1
end

---Write right aligned
---@param canvas PixelCanvas
---@param text string
---@param x integer
---@param y integer
---@param c integer
function Font:writeRight(canvas, text, x, y, c)
    local width = self:getWidth(text)
    self:write(canvas, text, x - width + 1, y, c)
end

---@param fontSheet PixelCanvas
---@param mapping string
---@return Font
return function(fontSheet, mapping)
    local self = setmetatable({}, Font_mt)

    self.height = fontSheet.height-1
    self.chars = {}
    self.kerning = 1

    local charStartX = 1
    local x = 1
    for i = 1, #mapping do
        local name = mapping:sub(i, i)

        repeat
            x = x + 1
            local nc = fontSheet.canvas[self.height+1][x]
        until x > fontSheet.width or (nc and nc ~= colors.black)

        local char = PixelCanvas(x - charStartX, self.height)
        char:drawCanvasClip(fontSheet, 1, 1, charStartX, 1, x - 1, self.height)
        self.chars[name] = fixChar(char)

        charStartX = x + 1
    end

    return self
end
