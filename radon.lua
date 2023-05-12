local version = "1.3.25"
local configHelpers = require "util.configHelpers"
local schemas       = require "core.schemas"
local ScanInventory = require("core.inventory.ScanInventory")
local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw
local oldPrint = print
local logs = {}
local maxLogs = 100
function print(...)
    local args = {...}
    local str = ""
    for i = 1, #args do
        str = str .. tostring(args[i])
        if i ~= #args then
            str = str .. " "
        end
    end
    table.insert(logs, 1, {time = os.time("utc"), text = str})
    if #logs > maxLogs then
        table.remove(logs, #logs)
    end
end


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
local BasicButton = require("components.BasicButton")
local BigText = require("components.BigText")
local Modal = require("components.Modal")
local Logs = require("components.Logs")
local ConfigEditor = require("components.ConfigEditor")
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

local configDefaults = require("configDefaults")
local config = require("config")
local products = require("products")
local eventHooks = {}
if fs.exists(fs.combine(fs.getDir(shell.getRunningProgram()), "eventHooks.lua")) then
    eventHooks = require("eventHooks")
end
--- End Imports

configHelpers.loadDefaults(config, configDefaults)
local configErrors = ConfigValidator.validateConfig(config)
local productsErrors = ConfigValidator.validateProducts(products)

if (configErrors and #configErrors > 0) or (productsErrors and #productsErrors > 0) then
    config.ready = false
else
    config.ready = true
end

local peripherals = {}
configHelpers.getPeripherals(config, peripherals)

if config.shopSync and config.shopSync.enabled and not config.shopSync.force then
    error("ShopSync is not yet finalized, please update Radon to use this feature, or set config.shopSync.force to true to use current ShopSync spec")
end

local display = Display.new({theme=config.theme, monitor=config.peripherals.monitor})
local terminal = Display.new({theme=config.terminalTheme, monitor=term})

local layout = nil
local layoutFile = nil
local layoutRenderer = nil

local configState = {
    config = config,
    products = products,
    eventHooks = eventHooks,
}

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas(display)
    local flatCanvas = {}
    if props.configState.config.ready and props.shopState.kryptonReady then
        local theme = props.configState.config.theme
            
        if theme.formatting.layout ~= "custom" or not theme.formatting.layoutFile then
            local addBg = false
            if theme.formatting.layout ~= layout then
                layout = theme.formatting.layout
                if theme.palette then
                    require("util.setPalette")(display.mon, theme.palette)
                end
                if theme.colors and theme.colors.bgColor then
                    display.ccCanvas.clear = theme.colors.bgColor
                    addBg = true
                end
                display.ccCanvas:outputFlush(display.mon)
            end
            flatCanvas = defaultLayout(canvas, display, props, theme, version)
            if addBg then
                table.insert(flatCanvas, Rect {
                    display = display,
                    x = 1,
                    y = 1,
                    width = display.bgCanvas.width,
                    height = display.bgCanvas.height,
                    color = theme.colors.bgColor,
                })
            end
        else
            local addBg = false
            if theme.formatting.layoutFile ~= layoutFile or theme.formatting.layout ~= layout then
                layout = "custom"
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
                    addBg = true
                end
                display.ccCanvas:outputFlush(display.mon)
            end
            flatCanvas = layoutRenderer(canvas, display, props, theme, version)
            if addBg then
                table.insert(flatCanvas, 1, Rect {
                    display = display,
                    x = 1,
                    y = 1,
                    width = display.bgCanvas.width,
                    height = display.bgCanvas.height,
                    color = theme.layouts[layoutFile].colors.bgColor,
                })
            end
        end
    elseif not props.configState.config.ready then
        flatCanvas = {
            BasicText({
                display = display,
                text = "Waiting on config...",
                x = 1,
                y = 1,
                color = colors.white,
                bgColor = colors.black,
            })
        }
    else
        flatCanvas = {
            BasicText({
                display = display,
                text = "Connecting...",
                x = 1,
                y = 1,
                color = colors.white,
                bgColor = colors.black,
            })
        }
    end

    return _.flat({ _.flat(flatCanvas) }), {
        canvas = {canvas, 1, 1},
        config = props.configState.config or {},
        shopState = props.shopState or {},
        products = props.shopState.products,
        peripherals = props.peripherals or {},
    }
end)

local terminalState = {
    prevCatagory = "logs",
    activeCatagory = "logs",
    configErrors = configErrors,
    productsErrors = productsErrors,
    scroll = 0,
    maxScroll = 0,
}

--local mbsMode = settings.get("mbs.shell.enabled")

local Terminal = Solyd.wrapComponent("Terminal", function(props)
    local canvas = useCanvas(terminal)
    local theme = props.configState.config.terminalTheme

    local flatCanvas = {}
    local versionString = "Radon " .. version
    local terminalCatagories = { "logs", "config", "products" }
    local bodyHeight = math.floor(terminal.bgCanvas.height / 3) - 1
    local bodyWidth = math.floor(terminal.bgCanvas.width / 2)

    table.insert(flatCanvas, Rect {
        key = "header",
        display = terminal,
        x = 1,
        y = 1,
        width = terminal.bgCanvas.width,
        height = 3,
        color = theme.colors.titleBgColor,
    })
    table.insert(flatCanvas, BasicText {
        key = "title",
        display = terminal,
        align = "left",
        text = versionString,
        x = 1,
        y = 1,
        color = theme.colors.titleTextColor,
        bg = theme.colors.titleBgColor,
    })

    local catagoriesX = 1 + #versionString
    for i = 1, #terminalCatagories do
        local bgColor = theme.colors.catagoryBgColor
        if props.terminalState.activeCatagory == terminalCatagories[i] then
            bgColor = theme.colors.activeCatagoryBgColor
        end
        table.insert(flatCanvas, BasicButton {
            key = "catagory-" .. terminalCatagories[i],
            display = terminal,
            align = "center",
            text = " "  .. terminalCatagories[i] .. " ",
            x = 2 + catagoriesX,
            y = 1,
            color = theme.colors.catagoryTextColor,
            bg = bgColor,
            onClick = function()
                props.terminalState.activeCatagory = terminalCatagories[i]
            end
        })

        catagoriesX = catagoriesX + 3 + #terminalCatagories[i]
    end

    if (props.terminalState.configErrors and #props.terminalState.configErrors > 0) or terminalState.activeCatagory == "config" then
        if terminalState.prevCatagory ~= "config" then
            terminalState.prevCatagory = "config"
            terminalState.configPath = ""
            terminalState.scroll = 0
        end
        table.insert(flatCanvas, ConfigEditor {
            key = "config-editor",
            display = terminal,
            x = 1,
            y = 2,
            width = bodyWidth,
            height = bodyHeight,
            config = props.configState.config,
            schema = schemas.configSchema,
            errors = props.terminalState.configErrors,
            errorPrefix = "config",
            terminalState = props.terminalState,
            theme = theme.colors.configEditor,
            onSave = function(newConfig)
                props.shopState.oldConfig = props.configState.config
                props.shopState.config = newConfig
                props.configState.config = newConfig
                props.terminalState.configErrors = ConfigValidator.validateConfig(newConfig)
                if (not props.terminalState.configErrors or #props.terminalState.configErrors == 0) and (not props.terminalState.productsErrors or #props.terminalState.productsErrors == 0) then
                    newConfig.ready = true
                end
                configHelpers.getPeripherals(newConfig, peripherals)
                -- TODO: Detect if we actually need to update currencies
                props.shopState.changedCurrencies = true
                local f = fs.open("config.lua", "w")
                f.write("return " .. textutils.serialize(newConfig))
                f.close()
                print("Configs updated!")
                if props.configState.eventHooks and props.configState.eventHooks.configSaved then
                    props.configState.eventHooks.configSaved(newConfig)
                end
            end
        })
    elseif (props.terminalState.productsErrors and #props.terminalState.productsErrors > 0) or terminalState.activeCatagory == "products" then
        if terminalState.prevCatagory ~= "products" then
            terminalState.prevCatagory = "products"
            terminalState.configPath = ""
            terminalState.scroll = 0
        end
        table.insert(flatCanvas, ConfigEditor {
            key = "products-editor",
            display = terminal,
            x = 1,
            y = 2,
            width = bodyWidth,
            height = bodyHeight,
            config = props.shopState.products,
            schema = schemas.productsSchema,
            errors = props.terminalState.productsErrors,
            errorPrefix = "products",
            terminalState = props.terminalState,
            theme = theme.colors.productsEditor,
            onSave = function(newConfig)
                props.shopState.products = newConfig
                props.configState.products = newConfig
                props.terminalState.productsErrors = ConfigValidator.validateProducts(products)
                if (not props.terminalState.configErrors or #props.terminalState.configErrors == 0) and (not props.terminalState.productsErrors or #props.terminalState.productsErrors == 0) then
                    props.configState.config.ready = true
                end
                ScanInventory.clearNbtCache()
                local f = fs.open("products.lua", "w")
                f.write("return " .. textutils.serialize(newConfig))
                f.close()
                print("Products updated!")
                if props.configState.eventHooks and props.configState.eventHooks.productsSaved then
                    props.configState.eventHooks.productsSaved(newConfig)
                end
            end
        })
    elseif terminalState.activeCatagory == "logs" then
        table.insert(flatCanvas, Logs {
            key = "logs",
            display = terminal,
            x = 1,
            y = 2,
            width = bodyWidth,
            height = bodyHeight,
            logs = props.logs,
            color = theme.colors.logTextColor,
            bg = theme.colors.bgColor,
        })
    end

    table.insert(flatCanvas, Modal { key="modal" })


    return _.flat({ _.flat(flatCanvas) }), {
        canvas = {canvas, 1, 1},
        config = props.configState.config or {},
        shopState = props.shopState or {},
        products = props.shopState.products,
        terminalState = props.terminalState,
        peripherals = props.peripherals or {},
        modal = props.modal
    }
end)



local t = 0
local tree = nil
local terminalTree = nil
local lastClock = os.epoch("utc")

local lastCanvases = {
    { stack = {}, hash = {} },
    { stack = {}, hash = {} },
}

local function diffCanvasStack(diffDisplay, newStack, lastCanvas)
    -- Find any canvases that were removed
    local removed = {}
    local kept, newCanvasHash = {}, {}
    for i = 1, #lastCanvas.stack do
        removed[lastCanvas.stack[i][1]] = lastCanvas.stack[i]
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
            diffDisplay.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width*2, canvas[1].height*3)
        else
            diffDisplay.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
        end
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local newCanvas = kept[i]
        local oldCanvas = lastCanvas.hash[newCanvas[1]]
        if oldCanvas then
            if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
                -- TODO: Optimize this?
                if oldCanvas[1].brand == "TextCanvas" then
                    diffDisplay.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width*2, oldCanvas[1].height*3)
                    diffDisplay.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width*2, newCanvas[1].height*3)
                else
                    diffDisplay.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
                    diffDisplay.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
                end
            end
        end
    end

    lastCanvas.stack = newStack
    lastCanvas.hash = newCanvasHash
end

local shopState = Core.ShopState.new(config, products, peripherals, version, logs, eventHooks)

--local Profiler = require("profile")


local deltaTimer = os.startTimer(0)
local success, err = pcall(function() ShopRunner.launchShop(shopState, function()
    --Profiler:activate()
    print("Radon " .. version .. " started")
    if eventHooks and eventHooks.start then
        eventHook.execute(eventHooks.start, version, config, products, shopState)
    end
    while true do
        -- add t = t if we need animations
        tree = Solyd.render(tree, Main { configState = configState, shopState = shopState, peripherals = peripherals})
        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })
        diffCanvasStack(display, context.canvas, lastCanvases[1])
        local t1 = os.epoch("utc")
        local cstack = { {display.bgCanvas, 1, 1}, unpack(context.canvas) }
        -- cstack[#cstack+1] = {display.textCanvas, 1, 1}
        display.ccCanvas:composite(unpack(cstack))
        display.ccCanvas:outputDirty(display.mon)
        local t2 = os.epoch("utc")
        --print("Render time: " .. (t2-t1) .. "ms")

        terminalTree = Solyd.render(terminalTree, Terminal { configState = configState, products = products, shopState = shopState, peripherals = peripherals, logs = logs, terminalState = terminalState, modal = {}})

        local terminalContext = Solyd.getTopologicalContext(terminalTree, { "canvas", "aabb", "input" })

        diffCanvasStack(terminal, terminalContext.canvas, lastCanvases[2])

        t1 = os.epoch("utc")
        local cstackT = { {terminal.bgCanvas, 1, 1}, unpack(terminalContext.canvas) }
        -- cstack[#cstack+1] = {display.textCanvas, 1, 1}
        terminal.ccCanvas:composite(unpack(cstackT))
        terminal.ccCanvas:outputDirty(terminal.mon)
        t2 = os.epoch("utc")
        -- print("Render time: " .. (t2-t1) .. "ms")

        local activeNode = hooks.findActiveInput(terminalContext.input)
        if activeNode then
            if activeNode.inputState.cursorX and activeNode.inputState.cursorY then
                terminal.mon.setCursorPos(activeNode.inputState.cursorX, activeNode.inputState.cursorY)
            else
                terminal.mon.setCursorPos(activeNode.x, activeNode.y)
            end
            terminal.mon.setTextColor(colors.black)
            terminal.mon.setCursorBlink(true)
        else
            terminal.mon.setCursorBlink(false)
        end


        local receivedEvent = false
        local terminate = false
        while not receivedEvent do
            local e = { os.pullEvent() }
            receivedEvent = true
            local name = e[1]
            if name == "timer" and e[2] == deltaTimer then
                -- local clock = os.epoch("utc")
                -- local dt = (clock - lastClock)/1000
                -- t = t + dt
                -- lastClock = clock
                -- deltaTimer = os.startTimer(0)

                -- hooks.tickAnimations(dt)
            elseif name == "timer" then
                receivedEvent = false
            elseif name == "monitor_touch" and e[2] == peripheral.getName(display.mon) then
                local x, y = e[3], e[4]
                local node = hooks.findNodeAt(context.aabb, x, y)
                if node then
                    node.onClick()
                end
            elseif name == "term_resize" then
                terminal.ccCanvas:outputFlush(terminal.mon)
            elseif name == "mouse_click" then
                local x, y = e[3], e[4]
                local clearedInput = hooks.clearActiveInput(terminalContext.input, x, y)
                if clearedInput and clearedInput.onBlur then
                    clearedInput.onBlur()
                end
                local node = hooks.findNodeAt(terminalContext.aabb, x, y)
                if node then
                    node.onClick()
                end
            elseif name == "mouse_scroll" then
                local dir = e[2]
                local x, y = e[3], e[4]
                local node = hooks.findNodeAt(terminalContext.aabb, x, y)
                local cancelScroll = false
                if node and node.onScroll then
                    if node.onScroll(dir) then
                        cancelScroll = true
                    end
                end
                if not cancelScroll then
                    if dir >= 1 and terminalState.scroll < terminalState.maxScroll then
                        terminalState.scroll = math.min(terminalState.scroll + dir, terminalState.maxScroll)
                    elseif dir <= -1 and terminalState.scroll > 0 then
                        terminalState.scroll = math.max(terminalState.scroll + dir, 0)
                    end
                end
            elseif name == "char" then
                local char = e[2]
                local node = hooks.findActiveInput(terminalContext.input)
                if node then
                    node.onChar(char)
                end
            elseif name == "key" then
                --if e[2] == keys.q then
                --    break
                --end
                local key, held = e[2] or 0, e[3] or false
                local node = hooks.findActiveInput(terminalContext.input)
                if node then
                    node.onKey(key, held)
                end
            elseif name == "paste" then
                local contents = e[2]
                local node = hooks.findActiveInput(terminalContext.input)
                if node and node.onPaste then
                    node.onPaste(contents)
                end
            elseif name == "terminate" then
                terminate = true
                break
            end
        end
        if terminate then
            break
        end
    end
    ---Profiler:deactivate()
end) end)

display.mon.clear()
terminal.mon.setBackgroundColor(colors.black)
terminal.mon.setTextColor(colors.white)
terminal.mon.clear()
terminal.mon.setCursorPos(1,1)
for i = 1, #shopState.config.currencies do
    local currency = shopState.config.currencies[i]
    if (currency.krypton and currency.krypton.ws) then
        currency.krypton.ws:disconnect()
    end
end

os.pullEvent = oldPullEvent
if not success then
    if eventHooks and eventHooks.programError then
        eventHook.execute(eventHooks.programError, err)
    end
    error(err)
end
print("Radon terminated, goodbye!")
--Profiler:write_results(nil, "profile.txt")