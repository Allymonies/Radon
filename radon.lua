--- Imports
local _ = require("util.score")

local display = require("modules.display")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local BigText = require("components.BigText")
local RenderCanvas = require("components.RenderCanvas")
--local Core = require("core.GameState")
local ShopRunner = require("core.ShopRunner")
local ConfigValidator = require("core.ConfigValidator")

local loadRIF = require("modules.rif")

local config = require("config")
local products = require("products")
--- End Imports

ConfigValidator.validateConfig(config)
ConfigValidator.validateProducts(products)

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas()

    return _.flat {
        BigText { text="Radon Shop", x=1, y=1, bg=colors.red, width=display.bgCanvas.width },
    }, {
        canvas = {canvas, 1, 1},
        gameState = props.gameState or {}
    }
end)



local t = 0
local tree = nil
local lastClock = os.epoch("utc")

local lastCanvasStack = {}
local lastCanvasHash = {}
local function diffCanvasStack(newStack)
    -- Find any canvases that were removed
    local removed = {}
    local kept, newCanvasHash = {}, {}
    for i = 1, #lastCanvasStack do
        removed[lastCanvasStack[i][1]] = lastCanvasStack[i]
    end
    for i = 1, #newStack do
        if removed[newStack[i][1]] then
            kept[#kept+1] = newStack[i]
            removed[newStack[i][1]] = nil
            newStack[i][1].allDirty = false
        else -- New
            newStack[i][1].allDirty = true
        end

        newCanvasHash[newStack[i][1]] = newStack[i]
    end

    -- Mark rectangle of removed canvases on bgCanvas (TODO: using bgCanvas is a hack)
    for _, canvas in pairs(removed) do
        display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local newCanvas = kept[i]
        local oldCanvas = lastCanvasHash[newCanvas[1]]
        if oldCanvas then
            if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
                -- TODO: Optimize this?
                display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
                display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
            end
        end
    end

    lastCanvasStack = newStack
    lastCanvasHash = newCanvasHash
end

--local shopState = Core.ShopState.new()
local shopState = nil

local deltaTimer = os.startTimer(0)
ShopRunner.launchShop(shopState, function()
    while true do
        tree = Solyd.render(tree, Main {t = t, gameState = shopState})

        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })

        diffCanvasStack(context.canvas)

        local t1 = os.epoch("utc")
        display.ccCanvas:composite({display.bgCanvas, 1, 1}, unpack(context.canvas))
        display.ccCanvas:outputDirty(display.mon)
        local t2 = os.epoch("utc")
        -- print("Render time: " .. (t2-t1) .. "ms")

        local e = { os.pullEvent() }
        local name = e[1]
        if name == "timer" and e[2] == deltaTimer then
            local clock = os.epoch("utc")
            local dt = (clock - lastClock)/1000
            t = t + dt
            lastClock = clock
            deltaTimer = os.startTimer(0)

            hooks.tickAnimations(dt)
        --[[elseif name == "monitor_touch" then
            local x, y = e[3], e[4]
            local player = auth.reconcileTouch(x, y)
            if player then
                local node = hooks.findNodeAt(context.aabb, x, y)
                if node then
                    node.onClick(player)
                end
            else
                -- TODO: Yell at the players
            end]]
        end
    end
end)
