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
local TeletextCanvas = canvases.TeletextCanvas
local TextCanvas = canvases.TextCanvas


local mon = peripheral.find("monitor")
if not mon then
    mon = term
else
    mon.setTextScale(0.5)
end

-- Set Riko Palette
require("util.riko")(mon)

local ccCanvas = TeletextCanvas(colors.green, mon.getSize())
ccCanvas:outputFlush(mon)

local bgCanvas = ccCanvas.pixelCanvas:newFromSize()
for y = 1, bgCanvas.height do
    for x = 1, bgCanvas.width do
        -- T-Piece
        bgCanvas:setPixel(x, y, colors.lightGray)
    end
end

return {
    ccCanvas = ccCanvas,
    bgCanvas = bgCanvas,
    mon = mon,
}
