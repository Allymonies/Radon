local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local version = "1.2.0"

--- Imports
local _ = require("util.score")
local sound = require("util.sound")
local eventHook = require("util.eventHook")

local Display = require("modules.display")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local Button = require("components.Button")
local SmolButton = require("components.SmolButton")
local BigText = require("components.BigText")
local bigFont = require("fonts.bigfont")
local SmolText = require("components.SmolText")
local smolFont = require("fonts.smolfont")
local BasicText = require("components.BasicText")
local Rect = require("components.Rect")
local RenderCanvas = require("components.RenderCanvas")
local Core = require("core.ShopState")
local Pricing = require("core.Pricing")
local ShopRunner = require("core.ShopRunner")
local ConfigValidator = require("core.ConfigValidator")

local defaultLayout = require("DefaultLayout")

local loadRIF = require("modules.rif")

local config = require("config")
local products = require("products")
--- End Imports

ConfigValidator.validateConfig(config)
ConfigValidator.validateProducts(products)

local modem
if config.peripherals.modem then
    modem = peripheral.wrap(config.peripherals.modem)
else
    modem = peripheral.find("modem", function(pName)
        return not peripheral.wrap(pName).isWireless()
    end)
    if not modem then
        error("No modem found")
    end
    if not modem.getNameLocal() then
        error("Modem is not connected! Turn it on by right clicking it!")
    end
end

local shopSyncModem
if config.peripherals.shopSyncModem then
    shopSyncModem = peripheral.wrap(config.peripherals.shopSyncModem)
else
    shopSyncModem = peripheral.find("modem", function(pName)
        return peripheral.wrap(pName).isWireless()
    end)
    if not shopSyncModem and config.shopSync and config.shopSync.enabled then
        error("No wireless modem found but ShopSync is enabled!")
    end
end

local speaker
if config.peripherals.speaker then
    speaker = peripheral.wrap(config.peripherals.speaker)
else
    speaker = peripheral.find("speaker")
end

if config.shopSync and config.shopSync.enabled and not config.shopSync.force then
    error("ShopSync is not yet finalized, please update Radon to use this feature, or set config.shopSync.force to true to use current ShopSync spec")
end

local display = Display.new({theme=config.theme, monitor=config.peripherals.monitor})

local layoutFile = nil
local layoutRenderer = nil

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas(display)
    local theme = props.config.theme

    local flatCanvas = {}
    if theme.formatting.layout ~= "custom" or not theme.formatting.layoutFile then
        flatCanvas = defaultLayout(canvas, display, props, theme, version)
    else
        if theme.formatting.layoutFile ~= layoutFile then
            layoutFile = theme.formatting.layoutFile
            local f = fs.open(layoutFile, "r")
            if not f then
                error("Could not open layout file: " .. layoutFile)
            end
            layoutRendererString = f.readAll()
            f.close()
            local loadedString, err = load(layoutRendererString, layoutFile, "t", setmetatable({ require = require }, {__index = _ENV}))
            if not loadedString then
                error("Could not load layout file: " .. err)
            end
            layoutRenderer = loadedString()
            if theme.layouts[layoutFile] and theme.layouts[layoutFile].palette then
                require("util.setPalette")(display.mon, theme.layouts[layoutFile].palette)
            end
            if theme.layouts[layoutFile] and theme.layouts[layoutFile].colors and theme.layouts[layoutFile].colors.bgColor then
                display.ccCanvas.clear = theme.layouts[layoutFile].colors.bgColor
            end
            display.ccCanvas:outputFlush(display.mon)
        end
        flatCanvas = layoutRenderer(canvas, display, props, theme, version)
    end

    return _.flat({ _.flat(flatCanvas) }), {
        canvas = {canvas, 1, 1},
        config = props.config or {},
        shopState = props.shopState or {},
        products = props.shopState.products,
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
        if canvas[1].brand == "TextCanvas" then
            display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width*2, canvas[1].height*3)
        else
            display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
        end
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local newCanvas = kept[i]
        local oldCanvas = lastCanvasHash[newCanvas[1]]
        if oldCanvas then
            if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
                -- TODO: Optimize this?
                if oldCanvas[1].brand == "TextCanvas" then
                    display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width*2, oldCanvas[1].height*3)
                    display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width*2, newCanvas[1].height*3)
                else
                    display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
                    display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
                end
            end
        end
    end

    lastCanvasStack = newStack
    lastCanvasHash = newCanvasHash
end

local shopState = Core.ShopState.new(config, products, modem, shopSyncModem, speaker, version)

local Profiler = require("profile")


local deltaTimer = os.startTimer(0)
local success, err = pcall(function() ShopRunner.launchShop(shopState, function()
    -- Profiler:activate()
    print("Radon " .. version .. " has started")
    if config.hooks and config.hooks.start then
        eventHook.execute(config.hooks.start, version, config, products)
    end
    while true do
        tree = Solyd.render(tree, Main {t = t, config = config, shopState = shopState, speaker = speaker})

        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })

        diffCanvasStack(context.canvas)

        local t1 = os.epoch("utc")
        local cstack = { {display.bgCanvas, 1, 1}, unpack(context.canvas) }
        -- cstack[#cstack+1] = {display.textCanvas, 1, 1}
        display.ccCanvas:composite(unpack(cstack))
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
        elseif name == "monitor_touch" and e[2] == peripheral.getName(display.mon) then
            local x, y = e[3], e[4]
            local node = hooks.findNodeAt(context.aabb, x, y)
            if node then
                node.onClick()
            end
        elseif name == "key" then
            if e[2] == keys.q then
                break
            end
        elseif name == "terminate" then
            break
        end
    end
    -- Profiler:deactivate()
end) end)

display.mon.clear()
for i = 1, #shopState.config.currencies do
    local currency = shopState.config.currencies[i]
    if (currency.krypton and currency.krypton.ws) then
        currency.krypton.ws:disconnect()
    end
end

os.pullEvent = oldPullEvent
if not success then
    if config.hooks and config.hooks.programError then
        eventHook.execute(config.hooks.programError, err)
    end
    error(err)
end
print("Radon terminated, goodbye!")
-- Profiler:write_results(nil, "profile.txt")
