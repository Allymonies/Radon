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

local animationRequests = {}
local animationFinished = {}

---@return number?
local function useAnimation(playing)
    -- local anim = Solyd.useRef(function()
    --     return { playing = playing, frame = 0, time = 0 }
    -- end).value
    local t, setT = Solyd.useState(0)

    if playing then
        -- Request animation frame
        animationRequests[#animationRequests + 1] = {t, setT}

        return t
    elseif t ~= 0 then
        print("reset")
        setT(0)
        return
    else
        -- print("ff", t)
    end
end

local function tickAnimations(dt)
    -- Clone the queue to avoid mutating it while iterating
    local animationQueue = {unpack(animationRequests)}
    animationRequests = {}
    for _, v in ipairs(animationQueue) do
        local aT, setT = v[1], v[2]
        setT(aT + dt)
    end
end

return {
    useAnimation = useAnimation,
    tickAnimations = tickAnimations,
    animationFinished = animationFinished,
}
