--- Imports
local _ = require("util.score")
local sound = require("util.sound")
local eventHook = require("util.eventHook")
local renderHelpers = require("util.renderHelpers")

local Display = require("modules.display")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local Button = require("components.Button")
local BasicButton = require("components.BasicButton")
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

local function render(canvas, display, props, theme, version)
    local elements = {}
    local selectedProduct, setSelectedProduct = Solyd.useState("")
    local categories = renderHelpers.getCategories(props.shopState.products)
    local selectedCategory = props.shopState.selectedCategory

    local currencyEndX = 3
    if #props.configState.config.currencies > 1 then
        for i = 1, #props.configState.config.currencies do
            local symbol = renderHelpers.getCurrencySymbol(props.configState.config.currencies[i], "large")
            local symbolSize = bigFont:getWidth(symbol)+6
            currencyEndX = currencyEndX + symbolSize + 2
        end
    end

    local categoryX = display.bgCanvas.width - 2
    if #categories > 1 then
        for i = #categories, 1, -1 do
            local category = categories[i]
            local categoryName = category.name
            if i == selectedCategory then
                categoryName = "[" .. categoryName .. "]"
            end
            local categoryWidth = smolFont:getWidth(categoryName)+6
            categoryX = categoryX - categoryWidth - 2
        end
    end

    local headerCx = math.floor((display.bgCanvas.width - bigFont:getWidth(props.configState.config.branding.title)) / 2)
    local header
    -- TODO: Change header font size based on width
    local headerHeight = 15
    if theme.formatting.headerAlign == "center" and headerCx < currencyEndX and #categories == 1 then
        table.insert(elements, Rect { display=display, x=1, y=1, width=currencyEndX, height=bigFont.height+6, color=theme.colors.headerBgColor })
        header = BigText { display=display, text=props.configState.config.branding.title, x=currencyEndX, y=1, align="left", bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=display.bgCanvas.width }
    elseif theme.formatting.headerAlign == "center" and headerCx+bigFont:getWidth(props.configState.config.branding.title) > categoryX and #categories > 1 then
        table.insert(elements, Rect { display=display, x=categoryX, y=1, width=display.bgCanvas.width-categoryX+1, height=bigFont.height+6, color=theme.colors.headerBgColor })
        header = BigText { display=display, text=props.configState.config.branding.title, x=1, y=1, align="right", bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=categoryX-1 }
    else
        header = BigText { display=display, text=props.configState.config.branding.title, x=1, y=1, align=theme.formatting.headerAlign, bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=display.bgCanvas.width }
    end
    if props.configState.config.branding.subtitle then
        table.insert(elements, BasicText {
            display = display,
            text = props.configState.config.branding.subtitle,
            x = 1,
            y = 6,
            align = theme.formatting.subtitleAlign,
            bg = theme.colors.subtitleBgColor,
            color = theme.colors.subtitleColor,
            width = math.floor(display.bgCanvas.width / 2)
        })
        headerHeight = headerHeight + 3
    end

    table.insert(elements, header)

    local footerHeight = 0
    if props.configState.config.settings.showFooter then
        local footerMessage
        if props.shopState.selectedCurrency.name or not props.configState.config.lang.footerNoName then
            footerMessage = props.configState.config.lang.footer
        else
            footerMessage = props.configState.config.lang.footerNoName
        end
        if props.shopState.selectedCurrency.name and footerMessage:find("%%name%%") then
            footerMessage = footerMessage:gsub("%%name%%", props.shopState.selectedCurrency.name)
        end
        if footerMessage:find("%%addr%%") and props.shopState.selectedCurrency.host then
            footerMessage = footerMessage:gsub("%%addr%%", props.shopState.selectedCurrency.host)
        end
        if footerMessage:find("%%version%%") then
            footerMessage = footerMessage:gsub("%%version%%", version)
        end
        if selectedProduct and #selectedProduct > 0 and footerMessage:find("<item>") then
            footerMessage = footerMessage:gsub("<item>", selectedProduct)
        end

        if props.shopState.selectedCurrency then
            local footer
            local footerSize = theme.formatting.footerSize
            if footerSize == "auto" and bigFont:getWidth(footerMessage) < display.bgCanvas.width then
                footerSize = "large"
            elseif footerSize == "auto" and smolFont:getWidth(footerMessage) < display.bgCanvas.width then
                footerSize = "medium"
            elseif footerSize == "auto" then
                footerSize = "small"
            end
            if footerSize == "large" then
                footer = BigText { display=display, text=footerMessage, x=1, y=display.bgCanvas.height-bigFont.height-5, align=theme.formatting.footerAlign, bg=theme.colors.footerBgColor, color = theme.colors.footerColor, width=display.bgCanvas.width }
                footerHeight = smolFont.height + 6
            elseif footerSize == "medium" then
                footer = SmolText { display=display, text=footerMessage, x=1, y=display.bgCanvas.height-smolFont.height-2, align=theme.formatting.footerAlign, bg=theme.colors.footerBgColor, color = theme.colors.footerColor, width=display.bgCanvas.width }
                footerHeight = smolFont.height + 4
            else
                footer = BasicText { display=display, text=footerMessage, x=1, y=math.floor(display.bgCanvas.height/3), align=theme.formatting.footerAlign, bg=theme.colors.footerBgColor, color = theme.colors.footerColor, width=math.ceil(display.bgCanvas.width/2) }
                footerHeight = smolFont.height + 4
            end
            table.insert(elements, footer)
        end
    end

    local maxAddrWidth = 0
    local maxQtyWidth = 0
    local maxPriceWidth = 0
    local maxNameWidth = 0
    props.shopState.numCategories = #categories
    local catName = categories[selectedCategory].name
    local shopProducts = renderHelpers.getDisplayedProducts(categories[selectedCategory].products, props.configState.config.settings)
    local productsHeight = display.bgCanvas.height - headerHeight - footerHeight - 2
    local heightPerProduct = math.floor(productsHeight / #shopProducts)
    local layout
    if theme.formatting.layout == "auto" then
        if heightPerProduct >= 15 then
            layout = "large"
        elseif heightPerProduct >= 9 then
            layout = "medium"
        else
            layout = "small"
       end
    else
        layout = theme.formatting.layout
    end

    local currency = props.shopState.selectedCurrency
    local currencySymbol = renderHelpers.getCurrencySymbol(currency, layout)
    while maxAddrWidth == 0 or maxAddrWidth + maxQtyWidth + maxPriceWidth + maxNameWidth > display.bgCanvas.width - 3 do
        if props.configState.config.theme.formatting.layout == "auto" and (maxAddrWidth + maxQtyWidth + maxPriceWidth + maxNameWidth > display.bgCanvas.width - 3) then
            if layout == "large" then
                layout = "medium"
                maxAddrWidth = 0
                maxQtyWidth = 0
                maxPriceWidth = 0
                maxNameWidth = 0
            elseif layout == "medium" then
                layout = "small"
                maxAddrWidth = 0
                maxQtyWidth = 0
                maxPriceWidth = 0
                maxNameWidth = 0
            end
        end
        currencySymbol = renderHelpers.getCurrencySymbol(currency, layout)
        for i = 1, #shopProducts do
            local product = shopProducts[i]
            local productAddr = product.address .. "@"
            if props.shopState.selectedCurrency.name then
                if layout == "small" then
                    if props.configState.config.settings.smallTextKristPayCompatability then
                        productAddr = product.address .. "@" .. props.shopState.selectedCurrency.name
                    else
                        productAddr = product.address .. "@ "
                    end
                end
            else
                productAddr = product.address
            end
            product.quantity = product.quantity or 0
            local productPrice = Pricing.getProductPrice(product, props.shopState.selectedCurrency)
            if layout == "large" then
                maxAddrWidth = math.max(maxAddrWidth, renderHelpers.getWidth(productAddr, layout)+2)
                maxQtyWidth = math.max(maxQtyWidth, renderHelpers.getWidth(tostring(product.quantity), layout)+4+2)
                maxPriceWidth = math.max(maxPriceWidth, renderHelpers.getWidth(tostring(productPrice) .. currencySymbol, layout)+2)
                maxNameWidth = math.max(maxNameWidth, renderHelpers.getWidth(product.name, layout)+2)
            elseif layout == "medium" then
                maxAddrWidth = math.max(maxAddrWidth, renderHelpers.getWidth(productAddr, layout)+2)
                maxQtyWidth = math.max(maxQtyWidth, renderHelpers.getWidth(tostring(product.quantity), layout)+4+2)
                maxPriceWidth = math.max(maxPriceWidth, renderHelpers.getWidth(tostring(productPrice) .. currencySymbol, layout)+2)
                maxNameWidth = math.max(maxNameWidth, renderHelpers.getWidth(product.name, layout)+2)
            else
                maxAddrWidth = math.max(maxAddrWidth, renderHelpers.getWidth(productAddr, layout)+1)
                maxQtyWidth = math.max(maxQtyWidth, renderHelpers.getWidth(tostring(product.quantity), layout)+2)
                maxPriceWidth = math.max(maxPriceWidth, renderHelpers.getWidth(tostring(productPrice) .. currencySymbol, layout)+1)
                maxNameWidth = math.max(maxNameWidth, renderHelpers.getWidth(product.name, layout)+1)
            end
        end
        if props.configState.config.theme.formatting.layout ~= "auto" or layout == "small" then
            break
        end
    end
    local startY = headerHeight + 1
    local startTextY = math.ceil(headerHeight / 3) + 1
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
        if props.shopState.selectedCurrency.name then
            if layout == "small" then
                if props.configState.config.settings.smallTextKristPayCompatability then
                    productAddr = product.address .. "@" .. props.shopState.selectedCurrency.name
                else
                    productAddr = product.address .. "@ "
                end
            end
        else
            productAddr = product.address
        end
        local kristpayHelperText = props.shopState.selectedCurrency.host or ""
        if props.shopState.selectedCurrency.name then
            kristpayHelperText = product.address .. "@" .. props.shopState.selectedCurrency.name
        end
        local productBgColor = theme.colors.productBgColors[((i-1) % #theme.colors.productBgColors) + 1]
        local productClickFunction = function()
            setSelectedProduct(product.address)
            if props.configState.eventHooks and props.configState.eventHooks.onProductSelected then
                eventHook.execute(props.configState.eventHooks.onProductSelected, product, currency)
            end
            if props.configState.config.settings.playSounds then
                sound.playSound(props.peripherals.speaker, props.configState.config.sounds.button)
            end
        end
        if layout == "large" then
            table.insert(elements, Button {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=startY+((i-1)*15),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, Button {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=startY+((i-1)*15),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, Button {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth,
                y=startY+((i-1)*15),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth,
                onClick=productClickFunction
            })
            table.insert(elements, Button {
                key="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=display.bgCanvas.width-3-maxAddrWidth,
                y=startY+((i-1)*15),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+4,
                onClick=productClickFunction
            })
            table.insert(elements, BasicText {
                key="invis-" .. catName .. tostring(product.id),
                display=display,
                text=kristpayHelperText,
                x=1,
                y=startTextY+((i-1)*5),
                align="center",
                bg=productBgColor,
                color=productBgColor,
                width=#(kristpayHelperText)
            })
        elseif layout == "medium" then
            table.insert(elements, SmolButton {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=startY+((i-1)*9),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, SmolButton {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=startY+((i-1)*9),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, SmolButton {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth,
                y=startY+((i-1)*9),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth,
                onClick=productClickFunction
            })
            table.insert(elements, SmolButton { 
                ey="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=display.bgCanvas.width-3-maxAddrWidth,
                y=startY+((i-1)*9),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+4,
                onClick=productClickFunction
            })
            table.insert(elements, BasicText {
                key="invis-" .. catName .. tostring(product.id),
                display=display,
                text=kristpayHelperText,
                x=1,
                y=startTextY+((i-1)*3),
                align="center",
                bg=productBgColor,
                color=productBgColor,
                width=#(kristpayHelperText)
            })
        else
            table.insert(elements, BasicButton {
                key="qty-"..catName..tostring(product.id),
                display=display,
                text=tostring(product.quantity),
                x=1,
                y=startTextY+((i-1)*1),
                align="center",
                bg=productBgColor,
                color=qtyColor,
                width=maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, BasicButton {
                key="name-"..catName..tostring(product.id),
                display=display,
                text=product.name,
                x=maxQtyWidth+1,
                y=startTextY+((i-1)*1),
                align=theme.formatting.productNameAlign,
                bg=productBgColor,
                color=productNameColor,
                width=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth-maxQtyWidth,
                onClick=productClickFunction
            })
            table.insert(elements, BasicButton {
                key="price-"..catName..tostring(product.id),
                display=display,
                text=tostring(productPrice) .. currencySymbol,
                x=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth,
                y=startTextY+((i-1)*1),
                align="right",
                bg=productBgColor,
                color=theme.colors.priceColor,
                width=maxPriceWidth,
                onClick=productClickFunction
            })
            table.insert(elements, BasicButton {
                key="addr-"..catName..tostring(product.id),
                display=display,
                text=productAddr,
                x=(display.bgCanvas.width/2)-1-maxAddrWidth,
                y=startTextY+((i-1)*1),
                align="right",
                bg=productBgColor,
                color=theme.colors.addressColor,
                width=maxAddrWidth+2,
                onClick=productClickFunction
            })
        end
    end

    local currencyX = 3
    if #props.configState.config.currencies > 1 then
        for i = 1, #props.configState.config.currencies do
            local symbol = renderHelpers.getCurrencySymbol(props.configState.config.currencies[i], "large")
            local symbolSize = bigFont:getWidth(symbol)+6+1
            local bgColor = theme.colors.currencyBgColors[((i-1) % #theme.colors.currencyBgColors) + 1]
            table.insert(elements, Button {
                display = display,
                align = "center",
                text = symbol,
                x = currencyX,
                y = 1,
                bg = bgColor,
                color = theme.colors.currencyTextColor,
                width = symbolSize,
                onClick = function()
                    props.shopState.selectedCurrency = props.configState.config.currencies[i]
                    props.shopState.lastTouched = os.epoch("utc")
                    if props.configState.config.settings.playSounds then
                        sound.playSound(props.peripherals.speaker, props.configState.config.sounds.button)
                    end
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

            table.insert(elements, SmolButton {
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
                    setSelectedProduct("")
                    props.shopState.lastTouched = os.epoch("utc")
                    if props.configState.config.settings.playSounds then
                        sound.playSound(props.peripherals.speaker, props.configState.config.sounds.button)
                    end
                    -- canvas:markRect(1, 16, canvas.width, canvas.height-16)
                end
            })
        end
    end
    return elements
end

return render