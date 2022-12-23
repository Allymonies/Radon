--local ShopState = require("core.ShopState")

local Animations = require("modules.hooks.animation")

local function areAnimationsFinished(uid)
    local finished = Animations.animationFinished[uid]
    if finished then
        Animations.animationFinished[uid] = nil
        return true
    end

    return false
end

local function launchShop(shopState, mainFunction)
    --local shopCoroutine = coroutine.create(function() ShopState.runGame(shopState) end)
    local mainCoroutine = coroutine.create(mainFunction)

    local stateFilter ---@type "animationFinished" | "waitForPlayerInput"
    local uidFilter

    local eventFilter
    local eventBacklog = {}

    while true do
        local e = (eventFilter == nil and #eventBacklog > 0) and table.remove(eventBacklog, 1) or { os.pullEvent() }

        if eventFilter and e[1] ~= eventFilter then
            eventBacklog[#eventBacklog+1] = e
        else
            local status, result = coroutine.resume(mainCoroutine, unpack(e))
            eventFilter = result
            if not status then
                error(result)
            end
        end

        if coroutine.status(mainCoroutine) == "dead" then
            break
        end

        local canResume = true -- coroutine.status(gameCoroutine) ~= "dead"
        if stateFilter == "animationFinished" then
            canResume = areAnimationsFinished(uidFilter)
        elseif stateFilter == "waitForPlayerInput" then
            --canResume = isPlayerInputReady()
        elseif stateFilter == "timer" then
            canResume = e[1] == "timer" and e[2] == uidFilter
        end

        if canResume then
            -- print("resuming...")
            --status, stateFilter, uidFilter = coroutine.resume(shopCoroutine)
            status = "alive"
            if stateFilter then
                print("new filter:", stateFilter)
            end

            if not status then
                error(stateFilter)
            end

            --[[if coroutine.status(shopCoroutine) == "dead" then
                -- TODO: Reset game state
                -- gameCoroutine = coroutine.create(GameState.runGame)
                -- error("oops")
            end]]
        end
    end
end

return {
    launchShop = launchShop,
}
