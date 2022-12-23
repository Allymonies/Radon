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

local Iter = require("util.iter")
local list = Iter.list

local Ease = require("modules.animation.Ease")

local function copy(t)
    local new = {}
    for k, v in pairs(t) do
        new[k] = v
    end
    return new
end

---@alias Step { duration: number, to: table?, easing: function | table<string, function> | nil }

---@class AnimationDescriptor
---@field sprite PixelCanvas
---@field initial table
---@field steps Step[]?

---@alias AnimationSets AnimationDescriptor[][]

---Evaluate one animation descriptor and return current animation state.
---@param animation AnimationDescriptor
---@param t number
---@return table animationState, number consumedTime, boolean isFinished
local function evaluateSingleAnimation(animation, t)
    local state = copy(animation.initial)
    state.sprite = animation.sprite

    local steps = animation.steps
    if not steps then
        return state, 0, true
    end

    local stepIndex = 1
    local consumedTime = 0
    while t > 0 do
        local step = steps[stepIndex]
        if not step then break end

        if t > step.duration then -- If this step is already completed, just skip it and set the to values
            if step.to then
                for k, v in pairs(step.to) do
                    state[k] = v
                end
            end

            t = t - step.duration
            consumedTime = consumedTime + step.duration
            stepIndex = stepIndex + 1
        else
            -- If this step is not completed, interpolate the values
            if step.to then
                local easingFunction = step.easing or Ease.linear
                for k, v in pairs(step.to) do
                    if type(easingFunction) == "function" then
                        state[k] = easingFunction(t, state[k], v - state[k], step.duration)
                    else ---@cast easingFunction table
                        state[k] = (easingFunction[k] or Ease.linear)(t, state[k], v - state[k], step.duration)
                    end
                end
            end

            consumedTime = consumedTime + t
            break
        end
    end

    return state, consumedTime, stepIndex > #steps
end

---Evaluate all animation descriptors for iterative sets and return current animation state.
---@param animationSets AnimationSets
---@param t number
---@return { sprite: PixelCanvas, [string]: number }[] visibleSprites, boolean isFinished
local function evaluateAnimationSets(animationSets, t)
    local remainingTime = t
    local setContents = {}
    for animationSet in list(animationSets) do
        local setDuration = 0
        local allFinished = true
        setContents = {}
        for i = 1, #animationSet do
            local animationState, consumedTime, finished = evaluateSingleAnimation(animationSet[i], remainingTime)
            setContents[i] = animationState

            print("c", consumedTime, finished)
            setDuration = math.max(setDuration, consumedTime)
            if not finished then
                allFinished = false
            end
        end

        if allFinished then
            remainingTime = remainingTime - setDuration
        else
            return setContents, false -- If we have no time left, return the current set
        end
    end

    return setContents, true -- All sets are finished
end

---@param animationSets AnimationSets
---@return { sprite: PixelCanvas, [string]: number }[] visibleSprites
local function skipAnimation(animationSets)
    local setContents = {}
    local animationSet = animationSets[#animationSets]
    for i = 1, #animationSet do
        setContents[i] = evaluateSingleAnimation(animationSet[i], math.huge)
    end

    return setContents
end

return {
    evaluateSingleAnimation = evaluateSingleAnimation,
    evaluateAnimationSets = evaluateAnimationSets,
    skipAnimation = skipAnimation,
}
