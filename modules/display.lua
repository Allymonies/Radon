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

local Display = {}
local Display_mt = { __index = Display }

function Display.new(props)
    local self = setmetatable({}, Display_mt)

    local canvases = require("modules.canvas")
    local PixelCanvas = canvases.PixelCanvas
    local TeletextCanvas = canvases.TeletextCanvas
    local TextCanvas = canvases.TextCanvas

    self.mon = props.monitor
    if self.mon and self.mon ~= term then
        self.mon = peripheral.wrap(props.monitor)
    end
    if not self.mon and self.mon ~= term then
        self.mon = peripheral.find("monitor")
    end
    if not self.mon then
        self.mon = term
    elseif self.mon ~= term then
        self.mon.setTextScale(0.5)
    end

    -- Set Riko Palette
    if props.theme and props.theme.palette then
        require("util.setPalette")(self.mon, props.theme.palette)
    end

    local bgColor = colors.black
    if props.theme and props.theme.colors and props.theme.colors.bgColor then
        bgColor = props.theme.colors.bgColor
    end
    self.ccCanvas = TeletextCanvas(bgColor, self.mon.getSize())
    self.ccCanvas:outputFlush(self.mon)

    self.textCanvas = TextCanvas(bgColor, self.mon.getSize())

    self.bgCanvas = self.ccCanvas.pixelCanvas:newFromSize()
    -- for y = 1, self.bgCanvas.height do
    --     for x = 1, self.bgCanvas.width do
    --         -- T-Piece
    --         self.bgCanvas:setPixel(x, y, props.theme.colors.headerBgColor)
    --     end
    -- end

    return self
end

return Display