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

local floor, ceil, min, max, abs, concat = math.floor, math.ceil, math.min, math.max, math.abs, table.concat
local function round(x) return floor(x + 0.5) end

local _ = require("util.score")

---@alias Color
---| 1
---| 2
---| 4
---| 8
---| 16
---| 32
---| 64
---| 128
---| 256
---| 512
---| 1024
---| 2048
---| 4096
---| 8192
---| 16384
---| 32768

local _ttxChars = setmetatable({}, {__index = error})
for i = 0, 31 do
    _ttxChars[i+1] = string.char(128 + i)
end

local _hex = setmetatable({}, {__index = error})
for i = 0, 15 do
    _hex[2^i] = string.format("%x", i)
end

---@alias Terminal table A computercraft terminal object

---@class PixelCanvas
---@field width integer
---@field height integer
---@field canvas { [integer]: { [integer]: integer } }
---@field dirty { [integer]: { [integer]: boolean } }
---@field allDirty boolean?
---@operator call:PixelCanvas
local PixelCanvas = {}
local PixelCanvas_mt = { __index = PixelCanvas }
setmetatable(PixelCanvas, { __call = function(_, ...) return PixelCanvas.new(...) end })

function PixelCanvas.new(width, height)
    local self = setmetatable({__opaque = true}, PixelCanvas_mt)
    self.width = width
    self.height = height
    self.canvas = {}
    for y = 1, height do
        self.canvas[y] = {}
        for x = 1, width do
            self.canvas[y][x] = nil
        end
    end

    self.dirty = {} -- { [y] = { [x] = true } }

    return self
end

---Set the pixel at {x}, {y} to {c}.
---@param x integer
---@param y integer
---@param c Color
function PixelCanvas:setPixel(x, y, c)
    x, y = floor(x), floor(y)
    -- TODO: remove bounds checking?
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end

    if self.canvas[y][x] ~= c then
        self.canvas[y][x] = c
        self.dirty[y] = self.dirty[y] or {}
        self.dirty[y][x] = true
    end
end

function PixelCanvas:clone()
    local clone = PixelCanvas.new(self.width, self.height)
    for y = 1, self.height do
        clone.dirty[y] = {}
        for x = 1, self.width do
            clone.canvas[y][x] = self.canvas[y][x]
            clone.dirty[y][x] = true
        end
    end

    return clone
end

function PixelCanvas:mapColors(map)
    for y = 1, self.height do
        for x = 1, self.width do
            self.canvas[y][x] = map[self.canvas[y][x]] or self.canvas[y][x]
        end
    end

    return self
end

---Copies the contents of {canvas} into this canvas at {x, y}.
---@param canvas PixelCanvas
---@param x integer
---@param y integer
function PixelCanvas:drawCanvas(canvas, x, y, remapFrom, remapTo)
    for cy = 1, canvas.height do
        for cx = 1, canvas.width do
            local c = canvas.canvas[cy][cx]
            if c == remapFrom then
                if type(remapTo) == "table" then error() end
                c = remapTo
            end

            if c then -- TODO: document this
                self:setPixel(x + cx - 1, y + cy - 1, c)
            end
        end
    end
end

function PixelCanvas:drawCanvas180(canvas, x, y)
    for cy = 1, canvas.height do
        for cx = 1, canvas.width do
            self:setPixel(x + cx - 1, y + canvas.height - cy - 1, canvas.canvas[cy][cx])
        end
    end
end

function PixelCanvas:drawCanvasRotated(canvas, cx, cy, angle)
    local sin, cos = math.sin(angle), math.cos(angle)
    local absSin, absCos = math.abs(sin), math.abs(cos)
    local newWidth, newHeight = ceil(canvas.width * absCos + canvas.height * absSin), ceil(canvas.width * absSin + canvas.height * absCos)

    for y = 1, newHeight do
        for x = 1, newWidth do
            local px, py = x - newWidth / 2, y - newHeight / 2
            local rx, ry = px * cos - py * sin, px * sin + py * cos
            rx, ry = rx + canvas.width / 2, ry + canvas.height / 2
            rx, ry = round(rx), round(ry)
            if rx >= 1 and rx <= canvas.width and ry >= 1 and ry <= canvas.height then
                self:setPixel(x + cx - newWidth / 2, y + cy - newHeight / 2, canvas.canvas[ry][rx])
            end
        end
    end
end

---Copies the contents of {canvas} into this canvas at {x, y} with color {c}.
---@param canvas PixelCanvas
---@param x integer
---@param y integer
---@param c integer
function PixelCanvas:drawTint(canvas, x, y, c)
    for cy = 1, canvas.height do
        for cx = 1, canvas.width do
            if canvas.canvas[cy][cx] then
                self:setPixel(x + cx - 1, y + cy - 1, c)
            end
        end
    end
end

---Copies the contents of {canvas} into this canvas at {x, y} with the specified bounds.
---@param canvas PixelCanvas
---@param x integer
---@param y integer
---@param startX integer
---@param startY integer
---@param endX integer
---@param endY integer
function PixelCanvas:drawCanvasClip(canvas, x, y, startX, startY, endX, endY)
    for cy = startY, endY do
        for cx = startX, endX do
            self:setPixel(x + cx - startX, y + cy - startY, canvas.canvas[cy][cx])
        end
    end
end

function PixelCanvas:drawRect(c, x, y, w, h)
    for cy = 1, h do
        for cx = 1, w do
            self:setPixel(x + cx - 1, y + cy - 1, c)
        end
    end
end

---Mark the pixel at {x, y} as dirty, indicating that it should be updated during frame composition.
---@param x integer
---@param y integer
function PixelCanvas:mark(x, y)
    x, y = floor(x), floor(y)
    -- TODO: remove bounds checking?
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end

    self.dirty[y] = self.dirty[y] or {}
    self.dirty[y][x] = true
end

---@param x integer
---@param y integer
---@param width integer
---@param height integer
function PixelCanvas:markRect(x, y, width, height)
    x, y = floor(x), floor(y)
    -- TODO: remove bounds checking?

    for cy = y, y + height - 1 do
        if cy < 1 or cy > self.height then
            -- out of bounds
        else
            self.dirty[cy] = self.dirty[cy] or {}
            for cx = x, x + width - 1 do
                if cx < 1 or cx > self.width then
                    -- out of bounds
                else
                    self.canvas[cy][cx] = nil
                    self.dirty[cy][cx] = true
                end
            end
        end
    end
end

---@param x integer
---@param y integer
---@param width integer
---@param height integer
function PixelCanvas:dirtyRect(x, y, width, height)
    x, y = floor(x), floor(y)
    -- TODO: remove bounds checking?

    for cy = y, y + height - 1 do
        if cy < 1 or cy > self.height then
            -- out of bounds
        else
            self.dirty[cy] = self.dirty[cy] or {}
            for cx = x, x + width - 1 do
                if cx < 1 or cx > self.width then
                    -- out of bounds
                else
                    self.dirty[cy][cx] = true
                end
            end
        end
    end
end

---Mark the rectangle formed by the given canvas at {x, y} as dirty.
---@param canvas PixelCanvas
---@param x integer
---@param y integer
function PixelCanvas:markCanvas(canvas, x, y)
    for cy = 1, canvas.height do
        for cx = 1, canvas.width do
            self:setPixel(x + cx - 1, y + cy - 1, nil)
        end
    end
end

function PixelCanvas:markCanvasRotated(canvas, cx, cy, angle)
    local sin, cos = math.sin(angle), math.cos(angle)
    local absSin, absCos = math.abs(sin), math.abs(cos)
    local newWidth, newHeight = ceil(canvas.width * absCos + canvas.height * absSin), ceil(canvas.width * absSin + canvas.height * absCos)

    for y = 1, newHeight do
        for x = 1, newWidth do
            local px, py = x - newWidth / 2, y - newHeight / 2
            local rx, ry = px * cos - py * sin, px * sin + py * cos
            rx, ry = rx + canvas.width / 2, ry + canvas.height / 2
            rx, ry = round(rx), round(ry)
            if rx >= 1 and rx <= canvas.width and ry >= 1 and ry <= canvas.height then
                self:setPixel(x + cx - newWidth / 2, y + cy - newHeight / 2, nil)
            end
        end
    end
end

---Creates a new PixelCanvas with the same width and height as this canvas.
---@return PixelCanvas
function PixelCanvas:newFromSize()
    return PixelCanvas.new(self.width, self.height)
end

function PixelCanvas.is(obj)
    return getmetatable(obj) == PixelCanvas_mt
end

---@param others { [1]: PixelCanvas, [2]: integer, [3]: integer }[]
function PixelCanvas:composite(others)
    for _, other in ipairs(others) do
        self:drawCanvas(other[1], other[2], other[3])
    end
end

---@class TextCanvas
---@field width number
---@field height number
---@field canvas { [integer]: { t: { [integer]: string }, c: { [integer]: string }, b: { [integer]: string } } }
---@field dirty { [integer]: { [integer]: boolean } }
---@operator call:PixelCanvas
local TextCanvas = {}
local TextCanvas_mt = { __index = TextCanvas }
setmetatable(TextCanvas, { __call = function(_, ...) return TextCanvas.new(...) end })

function TextCanvas.new(width, height)
    local self = setmetatable({__opaque = true}, TextCanvas_mt)
    self.width = width
    self.height = height
    self.brand = "TextCanvas"
    self.canvas = {}
    for y = 1, height do
        self.canvas[y] = {}
        self.canvas[y].t = {}
        self.canvas[y].c = {}
        self.canvas[y].b = {}
        -- for x = 1, width do
        --     [x] = nil
        -- end
    end

    self.dirty = {} -- { [y] = { [x] = true } }

    return self
end

---Write a string to the canvas at {x, y}.
---@param text string
---@param x integer
---@param y integer
---@param c integer
---@param b integer
function TextCanvas:write(text, x, y, c, b)
    x, y = floor(x), floor(y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end

    c = _hex[c]
    b = _hex[b]

    self.dirty[y] = self.dirty[y] or {}
    for i = 1, #text do
        if x + i - 1 > self.width then
            break
        end

        self.dirty[y][x + i - 1] = true
        self.canvas[y].t[x + i - 1] = text:sub(i, i)
        self.canvas[y].c[x + i - 1] = c
        self.canvas[y].b[x + i - 1] = b
    end
end

---Mark a string to the canvas at {x, y}.
---@param text string
---@param x integer
---@param y integer
function TextCanvas:markText(text, x, y)
    x, y = floor(x), floor(y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return
    end

    self.dirty[y] = self.dirty[y] or {}
    for i = 1, #text do
        if x + i - 1 > self.width then
            break
        end

        self.dirty[y][x + i - 1] = true
        self.canvas[y].t[x + i - 1] = nil
    end
end

function TextCanvas.is(self)
    return getmetatable(self) == TextCanvas_mt
end

---@class TeletextCanvas
---@field width integer
---@field height integer
---@field clear integer The color to use when a pixel is transparent.
---@field pixelCanvas PixelCanvas
---@field canvas { [integer]: { t: { [integer]: string }, c: { [integer]: string }, b: { [integer]: string }, direct: { [integer]: boolean } } }
---@field dirty { [integer]: { [integer]: boolean } }
---@field dirtyRows { [integer]: { [1]: integer, [2]: integer } }
---@operator call:TeletextCanvas
local TeletextCanvas = {}
local TeletextCanvas_mt = { __index = TeletextCanvas }
setmetatable(TeletextCanvas, { __call = function(_, ...) return TeletextCanvas.new(...) end })

function TeletextCanvas.new(clear, width, height)
    local self = setmetatable({__opaque = true}, TeletextCanvas_mt)
    self.width = width
    self.height = height
    self.clear = clear or colors.black

    self.pixelCanvas = PixelCanvas(width*2, height*3)

    self.canvas = {}
    for y = 1, height do
        self.canvas[y] = { t = {}, c = {}, b = {}, direct = {} }
        for x = 1, width do
            self.canvas[y].t[x] = " "
            self.canvas[y].c[x] = "0"
            self.canvas[y].b[x] = _hex[clear]
            self.canvas[y].direct[x] = false
        end
    end

    self.dirty = {} -- { [y] = { [x] = true } }
    self.dirtyRows = {}

    return self
end

function TeletextCanvas:reset(clear)
    for y = 1, self.height do
        self.canvas[y] = { t = {}, c = {}, b = {}, direct = {} }
        for x = 1, self.width do
            self.canvas[y].t[x] = " "
            self.canvas[y].c[x] = "0"
            self.canvas[y].b[x] = _hex[clear]
            self.canvas[y].direct[x] = false
        end
    end
    self.dirty = {} -- { [y] = { [x] = true } }
    self.dirtyRows = {}
end

---Composites the given pixel canvases onto the teletext's internal 
---pixel canvas and recomputes the teletext's character data.
---@param ... { [1]: PixelCanvas, [2]: integer, [3]: integer }
function TeletextCanvas:composite(...)
    local others = {...}

    -- Partition the screen based on canvas x/y/w/h
    -- local t1 = os.epoch("utc")
    local partitionSize = 20
    local partitions = {}
    for y = 1, self.height*3, partitionSize do
        partitions[ceil(y/partitionSize)] = {}
        for x = 1, self.width*2, partitionSize do
            partitions[ceil(y/partitionSize)][ceil(x/partitionSize)] = {}
        end
    end
    -- local t2 = os.epoch("utc")
    -- print("Partitioning took " .. (t2-t1) .. "ms")

    -- t1 = os.epoch("utc")
    for _, other in ipairs(others) do
        other[2] = floor(other[2])
        other[3] = floor(other[3])
        -- if PixelCanvas.is(other) then
        local otherCanvas, otherX, otherY = other[1], other[2], other[3]

        local originPartitionX = (ceil(otherX/partitionSize) - 1)*partitionSize + 1
        local originPartitionY = (ceil(otherY/partitionSize) - 1)*partitionSize + 1

        --TODO: This is a hack, should use -1 instead of +1
        for y = originPartitionY, otherY+otherCanvas.height+1, partitionSize do
            for x = originPartitionX, otherX+otherCanvas.width+1, partitionSize do
                local px = ceil(x/partitionSize)
                local py = ceil(y/partitionSize)
                local partition = (partitions[py] or {})[px]
                if partition then
                    partition[#partition + 1] = other
                end
            end
        end
        -- end
    end
    -- t2 = os.epoch("utc")
    -- print("Canvas partition assignment took " .. (t2-t1) .. "ms")

    -- t1 = os.epoch("utc")
    local queuedDirty = {}
    local c = 0
    for _, other in ipairs(others) do
        
        local ocanvas, ox, oy = other[1], other[2]-1, other[3]-1
        local isPixel = ocanvas.brand ~= "TextCanvas"
        if ocanvas.allDirty then
            for y = 1, ocanvas.height do
                for x = 1, ocanvas.width do
                    if isPixel then
                        local tx = x+ox
                        local ty = y+oy
                        if tx >= 1 and tx <= self.width*2 and ty >= 1 and ty <= self.height*3 then
                            queuedDirty[ty] = queuedDirty[ty] or {}
                            queuedDirty[ty][tx] = true
                            c = c + 1
                        end
                    else
                        local tx = x*2-1 + ox
                        local ty = y*3-2 + oy
                        -- print(ty)
                        if tx >= 1 and tx <= self.width*2 and ty >= 1 and ty <= self.height*3 then
                            queuedDirty[ty] = queuedDirty[ty] or {}
                            queuedDirty[ty][tx] = true
                            c = c + 1
                        end
                    end
                end
            end
        else
            for y, row in pairs(ocanvas.dirty) do
                for x, _ in pairs(row) do
                    if isPixel then
                        local tx = x+ox
                        local ty = y+oy
                        if tx >= 1 and tx <= self.width*2 and ty >= 1 and ty <= self.height*3 then
                            queuedDirty[ty] = queuedDirty[ty] or {}
                            queuedDirty[ty][tx] = true
                            c = c + 1
                        end
                    else
                        local tx = x*2-1 + ox
                        local ty = y*3-2 + oy
                        -- print(ty)
                        if tx >= 1 and tx <= self.width*2 and ty >= 1 and ty <= self.height*3 then
                            queuedDirty[ty] = queuedDirty[ty] or {}
                            queuedDirty[ty][tx] = true
                            c = c + 1
                        end
                        -- print(y)
                        -- for gayY = y-10,y+10 do
                        --     if gayY > 1 and gayY <= #ocanvas.dirty then
                        --         for gayX = x-10,x+10 do
                        --             if gayX > 1 and gayX <= #row then
                        --                 queuedDirty[y*3] = queuedDirty[y*3] or {}
                        --                 queuedDirty[y*3][x*2] = true
                        --                 queuedDirty[y*3][x*2-1] = true
                        --                 queuedDirty[y*3-1] = queuedDirty[y*3-1] or {}
                        --                 queuedDirty[y*3-1][x*2] = true
                        --                 queuedDirty[y*3-1][x*2-1] = true
                        --                 queuedDirty[y*3-2] = queuedDirty[y*3-2] or {}
                        --                 queuedDirty[y*3-2][x*2] = true
                        --                 queuedDirty[y*3-2][x*2-1] = true
                        --             end
                        --         end
                        --     end
                        -- end
                    end

                    -- else
                    --     -- TODO: ewwwwwwww
                        
                    -- end
                end
            end
        end

        ocanvas.dirty = {} -- TODO: is this necessary?
    end
    -- t2 = os.epoch("utc")

    -- t1 = os.epoch("utc")
    for y, row in pairs(queuedDirty) do
        local targetY = ceil(y / 3)
        self.dirty[targetY] = self.dirty[targetY] or {}
        -- print("row size: " .. #row)
        for x, _ in pairs(row) do
            local targetX = ceil(x / 2)
            local currPixel = self.pixelCanvas.canvas[y][x]
            partitionY = ceil(y/partitionSize) --math.min(floor(y/partitionSize)+1, #partitions)
            partitionX = ceil(x/partitionSize) --math.min(floor(x/partitionSize)+1, #partitions[1])
            --print("getting partition (partizion size " .. partitionSize .. ") at x: " .. x .. ", y: " .. y .. " -> ".. floor(x/partitionSize)+1 .. ", " .. floor(y/partitionSize)+1)
            --print("Partitions size: " .. #partitions[1] .. ", " .. #partitions)
            local partition = partitions[partitionY][partitionX]

            local found = false
            -- local foundText = false
            for i = #partition, 1, -1 do
                local other = partition[i]
                local otherCanvas, ox, oy = other[1], other[2], other[3]
                if PixelCanvas.is(otherCanvas) then ---@cast other PixelCanvas
                    t1 = os.epoch("utc")
                    if otherCanvas.canvas[y-oy+1] then
                        local otherPixel = (otherCanvas.canvas[y-oy+1] or {})[x-ox+1]
                        if otherPixel then
                            found = true

                            if otherPixel ~= currPixel then
                                self.pixelCanvas.canvas[y][x] = otherPixel
                                self.dirty[targetY][targetX] = true
                            end

                            if self.canvas[targetY].direct[targetX] then
                                self.canvas[targetY].direct[targetX] = false
                                self.dirty[targetY][targetX] = true
                            end
                            break
                        end
                    end
                t2 = os.epoch("utc")
                else ---@cast other TextCanvas
                    -- print( targetX .. ", " .. targetY .. ": " .. ox .. ", " .. oy .. " -> " .. x .. ", " .. y)
                    local ty = ceil((y-oy+1)/3) --ceil(targetY - oy / 3)
                    local tx = ceil((x-ox+1)/2) --ceil(targetX - ox / 2)
                    -- print(tx .. " " .. ty)
                    -- if ty == 1 then
                        -- print("fuck")
                        -- print(#otherCanvas.canvas)
                        -- print(#otherCanvas.canvas[ty].t)
                        -- sleep(1)
                    -- end
                    if otherCanvas.canvas[ty] and otherCanvas.canvas[ty].c[tx] then
                        -- print("found text")
                        local otherRow = otherCanvas.canvas[ty]
                        local otherT = otherRow.t[tx]
                        local otherC = otherRow.c[tx]
                        local otherB = otherRow.b[tx]
                        if otherT then
                            found = true
                            foundText = true

                            local currRow = self.canvas[targetY]
                            local currT = currRow.t[targetX]
                            local currC = currRow.c[targetX]
                            local currB = currRow.b[targetX]

                            if otherT ~= currT or otherC ~= currC or otherB ~= currB then
                                currRow.t[targetX] = otherT
                                currRow.c[targetX] = otherC
                                currRow.b[targetX] = otherB
                                currRow.direct[targetX] = true
                                self.dirty[targetY][targetX] = false -- Already processed

                                local dirtyRow = self.dirtyRows[targetY] or {}
                                local minX, maxX = dirtyRow[1], dirtyRow[2]
                                minX = minX and min(minX, targetX) or targetX
                                maxX = maxX and max(maxX, targetX) or targetX
                                self.dirtyRows[targetY] = { minX, maxX }
                            end

                            break
                        else
                            local currRow = self.canvas[targetY]
                            currRow.direct[targetX] = false
                        end
                    else
                        -- local currRow = self.canvas[targetY]
                        -- currRow.direct[targetX] = false
                    end
                end
            end

            if not found then
                self.pixelCanvas.canvas[y][x] = self.clear
                self.dirty[targetY][targetX] = true
                self.canvas[targetY].direct[targetX] = false
            end

            -- if not foundText then
            --     if self.canvas[targetY].direct[targetX] then
            --         self.canvas[targetY].direct[targetX] = false
            --         self.dirty[targetY][targetX] = true
            --     end
            -- end
        end
    end
    -- t2 = os.epoch("utc")
    -- print("Canvas merging took " .. (t2-t1) .. "ms")

    -- Recalculate teletext canvas
    local clear = self.clear
    for y, row in pairs(self.dirty) do
        local oy = (y - 1) * 3

        local dirtyRow = self.dirtyRows[y] or {}
        local minX, maxX = dirtyRow[1], dirtyRow[2]
        for x, _ in pairs(row) do
            minX = minX and min(minX, x) or x
            maxX = maxX and max(maxX, x) or x

            local ox = (x - 1) * 2
            local sub, char, c1, c2, c3, c4, c5, c6 = 32768, 1,
                self.pixelCanvas.canvas[oy + 1][ox + 1] or clear,
                self.pixelCanvas.canvas[oy + 1][ox + 2] or clear,
                self.pixelCanvas.canvas[oy + 2][ox + 1] or clear,
                self.pixelCanvas.canvas[oy + 2][ox + 2] or clear,
                self.pixelCanvas.canvas[oy + 3][ox + 1] or clear,
                self.pixelCanvas.canvas[oy + 3][ox + 2] or clear

            if c1 ~= c6 then
                sub = c1
                char = 2
            end
            if c2 ~= c6 then
                sub = c2
                char = char + 2
            end
            if c3 ~= c6 then
                sub = c3
                char = char + 4
            end
            if c4 ~= c6 then
                sub = c4
                char = char + 8
            end
            if c5 ~= c6 then
                sub = c5
                char = char + 16
            end

            if self.canvas[y].direct[x] == false then
                self.canvas[y].t[x] = _ttxChars[char]
                self.canvas[y].c[x] = _hex[sub]
                self.canvas[y].b[x] = _hex[c6]
            end
        end

        self.dirtyRows[y] = { minX, maxX }
    end
end

---Output any dirty rows to the given {out} terminal.
---@param out Terminal
function TeletextCanvas:outputDirty(out)
    for y, row in pairs(self.dirtyRows) do
        local minX, maxX = row[1], row[2]
        if minX then
            local t,c,b
            if maxX - minX == 0 then
                t = self.canvas[y].t[minX]
                c = self.canvas[y].c[minX]
                b = self.canvas[y].b[minX]
            else
                t = concat(self.canvas[y].t, "", minX, maxX)
                c = concat(self.canvas[y].c, "", minX, maxX)
                b = concat(self.canvas[y].b, "", minX, maxX)
            end

            out.setCursorPos(minX, y)
            out.blit(t, c, b)
        end
    end

    self.dirty = {}
    self.dirtyRows = {}
end

---Output the entire canvas to the given {out} terminal.
---@param out Terminal
function TeletextCanvas:outputFlush(out)
    for y = 1, self.height do
        local t = concat(self.canvas[y].t, "")
        local c = concat(self.canvas[y].c, "")
        local b = concat(self.canvas[y].b, "")

        out.setCursorPos(1, y)
        out.blit(t, c, b)
    end
end

return {
    PixelCanvas = PixelCanvas,
    TeletextCanvas = TeletextCanvas,
    TextCanvas = TextCanvas,
}
