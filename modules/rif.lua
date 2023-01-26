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
local base64 = require("util.base64")
local PixelCanvas = canvases.PixelCanvas

-- local palMap = {
--     colors.black,
--     colors.blue,
--     colors.purple,
--     colors.green,
--     colors.brown,
--     colors.gray,
--     colors.lightGray,
--     colors.red,
--     colors.orange,
--     colors.yellow,
--     colors.lime,
--     colors.cyan,
--     colors.magenta,
--     colors.pink,
--     colors.darkGreen,
--     colors.white
-- }

local revPalMap = {
    "black",
    "blue",
    "purple",
    "green",
    "brown",
    "gray",
    "lightGray",
    "red",
    "orange",
    "yellow",
    "lime",
    "cyan",
    "magenta",
    "pink",
    "darkGreen",
    "white"
}

local palMap = {}
for i = 1, 16 do
    palMap[i] = 2^(i - 1)
    --colors[revPalMap[i]] = 2^(i - 1)
end

local fileCache = {}

return function(filename)
    -- Riko 4 image format
    local data = fileCache[filename]
    if not data then
        data = base64.decode(require(filename))
    end
    local width, height = data:byte(5) * 256 + data:byte(6), data:byte(7) * 256 + data:byte(8)
    local canv = PixelCanvas(width, height)
    local buffer = canv.canvas

    for i = 1, math.ceil(width * height / 2) do
        local byte = data:byte(19 + i)
        local fp = bit.brshift(bit.band(byte, 240), 4)
        local sp = bit.band(byte, 15)

        -- 1, 3, 5
        local pix = i * 2 - 1
        local x = (pix - 1) % width + 1
        local y = math.ceil(pix / width)
        buffer[y][x] = palMap[fp + 1]
        local x2 = pix % width + 1
        local y2 = math.ceil((pix + 1) / width)
        if buffer[y2] then
            buffer[y2][x2] = palMap[sp + 1]
        end
    end

    if data:byte(9) == 1 then
        -- Transparency map
        local max = 19 + math.ceil(width * height / 2)
        for i = 1, math.ceil(width * height / 8) do
            local byte = data:byte(max + i)
            for j = 1, 8 do
                local pix = (i - 1) * 8 + j
                local x = (pix - 1) % width + 1
                local y = math.ceil(pix / width)
                if bit.band(byte, 2 ^ (j - 1)) ~= 0 then
                    if buffer[y] then
                        buffer[y][x] = nil
                    end
                end
            end
        end
    end

    return canv
end
