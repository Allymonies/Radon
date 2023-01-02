local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local version = "1.1.0"

--- Imports
local _ = require("util.score")

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

local loadRIF = require("modules.rif")

local config = require("config")
local products = require("products")
--- End Imports

ConfigValidator.validateConfig(config)
ConfigValidator.validateProducts(products)

local modem
if config.peripherals.modem then
    modem = peripheral.wrap(config.peripherals.modem)
elseif peripheral.find("modem") then
    modem = peripheral.find("modem")
else
    error("No modem found")
end

local display = Display.new({theme=config.theme, monitor=config.peripherals.monitor})

local function getDisplayedProducts(allProducts, settings)
    local displayedProducts = {}
    for i = 1, #allProducts do
        local product = allProducts[i]
        product.id = i
        if not settings.hideUnavailableProducts or product.quantity > 0 then
            table.insert(displayedProducts, product)
        end
    end
    return displayedProducts
end

local function getCurrencySymbol(currency, productTextSize)
    local currencySymbol
    if currency.krypton and currency.krypton.currency then
        currencySymbol = currency.krypton.currency.currency_symbol  
    elseif not currencySymbol and currency.name:find("%.") then
        currencySymbol = currency.name:sub(currency.name:find("%.")+1, #currency.name)
    elseif currency.id == "tenebra" then
        currencySymbol = "tst"
    else
        currencySymbol = "KST"
    end
    if currencySymbol == "TST" then
        currencySymbol = "tst"
    end
    if currencySymbol:lower() == "kst" and productTextSize == "medium" then
        currencySymbol = "kst"
    elseif currencySymbol:lower() == "kst" then
        currencySymbol = "\164"
    end
    return currencySymbol
end

local function getCategories(products)
    local categories = {}
    for _, product in ipairs(products) do
        local category = product.category
        if not category then
            category = "*"
        end
        local found = nil
        for i = 1, #categories do
            if categories[i].name == category then
                found = i
                break
            end
        end
        if not found then
            if category == "*" then
                table.insert(categories, 1, {name=category, products={}})
                found = 1
            else
                table.insert(categories, {name=category, products={}})
                found = #categories
            end
        end
        table.insert(categories[found].products, product)
    end
    return categories
end

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas(display)
    local theme = props.config.theme

    local header = BigText { display=display, text=props.config.branding.title, x=1, y=1, align=theme.formatting.headerAlign, bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=display.bgCanvas.width }

    local flatCanvas = {
        header
    }

    local footerMessage = props.config.lang.footer
    if footerMessage:find("%%name%%") then
        footerMessage = footerMessage:gsub("%%name%%", props.shopState.selectedCurrency.name)
    end

    if props.shopState.selectedCurrency then
        local footer = SmolText { display=display, text=footerMessage, x=1, y=display.bgCanvas.height-smolFont.height-4, align=theme.formatting.footerAlign, bg=theme.colors.footerBgColor, color = theme.colors.footerColor, width=display.bgCanvas.width }
        table.insert(flatCanvas, footer)
    end

    local maxAddrWidth = 0
    local maxQtyWidth = 0
    local maxPriceWidth = 0
    local categories = getCategories(props.shopState.products)
    props.shopState.numCategories = #categories
    local selectedCategory = props.shopState.selectedCategory
    local catName = categories[selectedCategory].name
    local shopProducts = getDisplayedProducts(categories[selectedCategory].products, config.settings)
    local productsHeight = display.bgCanvas.height - 17 - smolFont.height - 4
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

    local currency = props.shopState.selectedCurrency
    local currencySymbol = getCurrencySymbol(currency, productTextSize)
    for i = 1, #shopProducts do
        local product = shopProducts[i]
        local productAddr = product.address .. "@"
        if productTextSize == "small" then
            if props.config.settings.smallTextKristPayCompatability then
                productAddr = product.address .. "@" .. props.shopState.selectedCurrency.name
            else
                productAddr = product.address .. "@ "
            end
        end
        product.quantity = product.quantity or 0
        local productPrice = Pricing.getProductPrice(product, props.shopState.selectedCurrency)
        if productTextSize == "large" then
            maxAddrWidth = math.max(maxAddrWidth, bigFont:getWidth(productAddr)+2)
            maxQtyWidth = math.max(maxQtyWidth, bigFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, bigFont:getWidth(tostring(productPrice) .. currencySymbol)+2)
        elseif productTextSize == "medium" then
            maxAddrWidth = math.max(maxAddrWidth, smolFont:getWidth(productAddr)+2)
            maxQtyWidth = math.max(maxQtyWidth, smolFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, smolFont:getWidth(tostring(productPrice) .. currencySymbol)+2)
        else
            maxAddrWidth = math.max(maxAddrWidth, #(productAddr)+1)
            maxQtyWidth = math.max(maxQtyWidth, #tostring(product.quantity)+2)
            maxPriceWidth = math.max(maxPriceWidth, #(tostring(productPrice) .. currencySymbol)+1)
        end
    end
    for i = 1, #shopProducts do
        local product = shopProducts[i]
        -- Display products in format:
        -- <quantity> <name> <price> <address>
        product.quantity = product.quantity or 0
        local productPrice = Pricing.getProductPrice(product, props.shopState.selectedCurrency)
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
        local productAddr = product.address .. "@"
        if productTextSize == "small" then
            if props.config.settings.smallTextKristPayCompatability then
                productAddr = product.address .. "@" .. props.shopState.selectedCurrency.name
            else
                productAddr = product.address .. "@ "
            end
        end
        local productBgColor = theme.colors.productBgColors[((i-1) % #theme.colors.productBgColors) + 1]
        if productTextSize == "large" then
            table.insert(flatCanvas, BigText {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=16+((i-1)*15),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth
            })
            table.insert(flatCanvas, BigText {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=16+((i-1)*15),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth
            })
            table.insert(flatCanvas, BigText {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth,
                y=16+((i-1)*15),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth
            })
            table.insert(flatCanvas, BigText {
                key="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=display.bgCanvas.width-3-maxAddrWidth,
                y=16+((i-1)*15),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+4
            })
            table.insert(flatCanvas, BasicText {
                key="invis-" .. catName .. tostring(product.id),
                display=display,
                text=product.address .. "@" .. props.shopState.selectedCurrency.name,
                x=1,
                y=1+(i*5),
                align="center",
                bg=productBgColor,
                color=productBgColor,
                width=#(product.address .. "@" .. props.shopState.selectedCurrency.name)
            })
        elseif productTextSize == "medium" then
            table.insert(flatCanvas, SmolText {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=16+((i-1)*9),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth
            })
            table.insert(flatCanvas, SmolText {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=16+((i-1)*9),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth
            })
            table.insert(flatCanvas, SmolText {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth,
                y=16+((i-1)*9),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth
            })
            table.insert(flatCanvas, SmolText { 
                ey="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=display.bgCanvas.width-3-maxAddrWidth,
                y=16+((i-1)*9),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+4
            })
            table.insert(flatCanvas, BasicText {
                key="invis-" .. catName .. tostring(product.id),
                display=display,
                text=product.address .. "@" .. props.shopState.selectedCurrency.name,
                x=1,
                y=3+(i*3),
                align="center",
                bg=productBgColor,
                color=productBgColor,
                width=#(product.address .. "@" .. props.shopState.selectedCurrency.name)
            })
        else
            table.insert(flatCanvas, BasicText {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=6+((i-1)*1),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth
            })
            table.insert(flatCanvas, BasicText {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=6+((i-1)*1),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth-maxQtyWidth
            })
            table.insert(flatCanvas, BasicText {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth,
                y=6+((i-1)*1),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth
            })
            table.insert(flatCanvas, BasicText {
                key="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=(display.bgCanvas.width/2)-1-maxAddrWidth,
                y=6+((i-1)*1),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+2
            })
        end
    end

    local currencyX = 3
    if #props.config.currencies > 1 then
        for i = 1, #props.config.currencies do
            local symbol = getCurrencySymbol(props.config.currencies[i], productTextSize)
            local symbolSize = bigFont:getWidth(symbol)+6
            local bgColor = theme.colors.currencyBgColors[((i-1) % #theme.colors.currencyBgColors) + 1]
            table.insert(flatCanvas, Button {
                display = display,
                align = "center",
                text = symbol,
                x = currencyX,
                y = 1,
                bg = bgColor,
                color = theme.colors.currencyTextColor,
                width = symbolSize,
                onClick = function()
                    props.shopState.selectedCurrency = props.config.currencies[i]
                    props.shopState.lastTouched = os.epoch("utc")
                end
            })
            currencyX = currencyX + symbolSize + 2
        end
    end

    local categoryX = display.bgCanvas.width - 2
    if #categories > 1 then
        for i = #categories, 1, -1 do
            local category = categories[i]
            local categoryName = category.name
            local categoryColor
            if i == selectedCategory then
                categoryColor = theme.colors.activeCategoryColor
                categoryName = "[" .. categoryName .. "]"
            else
                categoryColor = theme.colors.categoryBgColors[((i-1) % #theme.colors.categoryBgColors) + 1]
            end
            local categoryWidth = smolFont:getWidth(categoryName)+6
            categoryX = categoryX - categoryWidth - 2

            table.insert(flatCanvas, SmolButton {
                display = display,
                align = "center",
                text = categoryName,
                x = categoryX,
                y = 4,
                bg = categoryColor,
                color = theme.colors.categoryTextColor,
                width = categoryWidth,
                onClick = function()
                    props.shopState.selectedCategory = i
                    props.shopState.lastTouched = os.epoch("utc")
                    -- canvas:markRect(1, 16, canvas.width, canvas.height-16)
                end
            })
        end
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

local shopState = Core.ShopState.new(config, products, modem)

local Profiler = require("profile")


local deltaTimer = os.startTimer(0)
local success, err = pcall(function() ShopRunner.launchShop(shopState, function()
    -- Profiler:activate()
    print("Radon " .. version .. " has started")
    while true do
        tree = Solyd.render(tree, Main {t = t, config = config, shopState = shopState})

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
        elseif name == "monitor_touch" then
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
    error(err)
end
print("Radon terminated, goodbye!")
-- Profiler:write_results(nil, "profile.txt")
