--- Imports
local _ = require("util.score")

local Display = require("modules.display")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local BigText = require("components.BigText")
local bigFont = require("fonts.bigfont")
local SmolText = require("components.SmolText")
local smolFont = require("fonts.smolfont")
local BasicText = require("components.BasicText")
local RenderCanvas = require("components.RenderCanvas")
local Core = require("core.ShopState")
local ShopRunner = require("core.ShopRunner")
local ConfigValidator = require("core.ConfigValidator")

local loadRIF = require("modules.rif")

local config = require("config")
local products = require("products")
--- End Imports

ConfigValidator.validateConfig(config)
ConfigValidator.validateProducts(products)

local display = Display.new({theme=config.theme})

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas(display)
    local theme = props.config.theme

    header = BigText { display=display, text="Radon Shop", x=1, y=1, align=theme.formatting.headerAlign, bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=display.bgCanvas.width }

    local flatCanvas = {
        header
    }

    local maxAddrWidth = 0
    local maxQtyWidth = 0
    local maxPriceWidth = 0
    local shopProducts = props.shopState.products
    local productsHeight = display.bgCanvas.height - 17
    local heightPerProduct = math.floor(productsHeight / #shopProducts)
    local productTextSize
    if theme.formatting.productTextSize == "auto" then
        if heightPerProduct >= 15 then
            productTextSize = "large"
        elseif heightPerProduct >= 9 then
            productTextSize = "medium"
        else
            productTextSize = "small"
       end
    else
        productTextSize = theme.formatting.productTextSize
    end

    for i = 1, #shopProducts do
        local product = shopProducts[i]
        if productTextSize == "large" then
            maxAddrWidth = math.max(maxAddrWidth, bigFont:getWidth(product.address .. "@")+2)
            maxQtyWidth = math.max(maxQtyWidth, bigFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, bigFont:getWidth(tostring(product.price) .. "kst")+2)
        elseif productTextSize == "medium" then
            maxAddrWidth = math.max(maxAddrWidth, smolFont:getWidth(product.address .. "@")+2)
            maxQtyWidth = math.max(maxQtyWidth, smolFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, smolFont:getWidth(tostring(product.price) .. "kst")+2)
        else
            maxAddrWidth = math.max(maxAddrWidth, #(product.address .. "@")+1)
            maxQtyWidth = math.max(maxQtyWidth, #tostring(product.quantity)+2)
            maxPriceWidth = math.max(maxPriceWidth, #(tostring(product.price) .. "kst")+1)
        end
    end
    for i = 1, #shopProducts do
        local product = shopProducts[i]
        -- Display products in format:
        -- <quantity> <name> <price> <address>
        local qtyColor = theme.colors.normalQtyColor
        if product.quantity == 0 then
            qtyColor = theme.colors.outOfStockQtyColor
        elseif product.quantity < 10 then
            qtyColor = theme.colors.lowQtyColor
        elseif product.quantity < 64 then
            qtyColor = theme.colors.warningQtyColor
        end
        local productNameColor = theme.colors.productNameColor
        if product.quantity == 0 then
            productNameColor = theme.colors.outOfStockNameColor
        end
        if productTextSize == "large" then
            table.insert(flatCanvas, BigText { display=display, text=tostring(product.quantity), x=1, y=17+((i-1)*15), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, BigText { display=display, text=product.name, x=maxQtyWidth+1, y=17+((i-1)*15), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, BigText { display=display, text=tostring(product.price) .. "kst", x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth, y=17+((i-1)*15), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, BigText { display=display, text=product.address .. "@", x=display.bgCanvas.width-3-maxAddrWidth, y=17+((i-1)*15), align="center", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+6 })
        elseif productTextSize == "medium" then
            table.insert(flatCanvas, SmolText { display=display, text=tostring(product.quantity), x=1, y=17+((i-1)*9), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, SmolText { display=display, text=product.name, x=maxQtyWidth+1, y=17+((i-1)*9), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, SmolText { display=display, text=tostring(product.price) .. "kst", x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth, y=17+((i-1)*9), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, SmolText { display=display, text=product.address .. "@", x=display.bgCanvas.width-3-maxAddrWidth, y=17+((i-1)*9), align="center", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+6 })
        else
            table.insert(flatCanvas, BasicText { display=display, text=tostring(product.quantity), x=1, y=6+((i-1)*1), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, BasicText { display=display, text=product.name, x=maxQtyWidth+1, y=6+((i-1)*1), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, BasicText { display=display, text=tostring(product.price) .. "kst", x=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth, y=6+((i-1)*1), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, BasicText { display=display, text=product.address .. "@", x=(display.bgCanvas.width/2)-1-maxAddrWidth, y=6+((i-1)*1), align="center", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+6 })
        end
    end

    return _.flat({ _.flat(flatCanvas) }), {
        canvas = {canvas, 1, 1},
        config = props.config or {},
        shopState = props.shopState or {}
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

local shopState = Core.ShopState.new(config, products)

local deltaTimer = os.startTimer(0)
ShopRunner.launchShop(shopState, function()
    while true do
        tree = Solyd.render(tree, Main {t = t, config = config, shopState = shopState})

        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })

        diffCanvasStack(context.canvas)

        local t1 = os.epoch("utc")
        display.ccCanvas:composite(unpack(context.canvas))
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
