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

local Ease = {}

function Ease.linear(t, b, c, d)
    return c * t / d + b
end

function Ease.inQuad(t, b, c, d)
    t = t / d
    return c * t * t + b
end

function Ease.outQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

function Ease.inOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t + b
    else
        t = t - 1
        return -c / 2 * (t * (t - 2) - 1) + b
    end
end

function Ease.outInQuad(t, b, c, d)
    if t < d / 2 then
        return Ease.outQuad(t * 2, b, c / 2, d)
    else
        return Ease.inQuad((t * 2) - d, b + c / 2, c / 2, d)
    end
end

function Ease.inCubic(t, b, c, d)
    t = t / d
    return c * t * t * t + b
end

function Ease.outCubic(t, b, c, d)
    t = t / d - 1
    return c * (t * t * t + 1) + b
end

function Ease.inOutCubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t + b
    else
        t = t - 2
        return c / 2 * (t * t * t + 2) + b
    end
end

function Ease.outInCubic(t, b, c, d)
    if t < d / 2 then
        return Ease.outCubic(t * 2, b, c / 2, d)
    else
        return Ease.inCubic((t * 2) - d, b + c / 2, c / 2, d)
    end
end

function Ease.inQuart(t, b, c, d)
    t = t / d
    return c * t * t * t * t + b
end

function Ease.outQuart(t, b, c, d)
    t = t / d - 1
    return -c * (t * t * t * t - 1) + b
end

function Ease.inOutQuart(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t * t + b
    else
        t = t - 2
        return -c / 2 * (t * t * t * t - 2) + b
    end
end

function Ease.outInQuart(t, b, c, d)
    if t < d / 2 then
        return Ease.outQuart(t * 2, b, c / 2, d)
    else
        return Ease.inQuart((t * 2) - d, b + c / 2, c / 2, d)
    end
end

return Ease
