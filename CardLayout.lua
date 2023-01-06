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
local SmolButton = require("components.SmolButton")
local BasicButton = require("components.BasicButton")
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
    local layoutName = theme.formatting.layoutFile
    local elements = {}

    local categories = renderHelpers.getCategories(props.shopState.products)
    local selectedCategory = props.shopState.selectedCategory
    local shopProducts = renderHelpers.getDisplayedProducts(categories[selectedCategory].products, props.config.settings)
    local currency = props.shopState.selectedCurrency

    local headerSuffix = ""
    if currency.name and currency.krypton and currency.krypton.currency then
        headerSuffix = "." .. currency.krypton.currency.name_suffix
    end
    local headerPadding = 2*6
    local headerWidth
    local headerText = currency.host
    if currency.name then
        headerText = currency.name
        headerWidth = bigFont:getWidth(currency.name)
    else
        headerWidth = bigFont:getWidth(currency.host)
    end
    local headerStartX = 1
    local headerAlign = renderHelpers.getThemeSetting(theme, "formatting.headerAlign", layoutName)
    if  headerAlign == "center" then
        headerStartX = math.floor((display.bgCanvas.width - headerWidth) / 2)
    elseif headerAlign == "right" then
        headerStartX = display.bgCanvas.width - headerWidth - headerPadding - (#headerSuffix * 2)
    end
    local header = BigText {
        display = display,
        text = headerText,
        x = headerStartX,
        y = 3*2,
        align = "left",
        bg = renderHelpers.getThemeSetting(theme, "colors.bgColor", layoutName),
        color = renderHelpers.getThemeSetting(theme, "colors.headerColor", layoutName)
    }
    table.insert(elements, header)

    if headerSuffix and #headerSuffix > 0 then
        local suffix = BasicText {
            display = display,
            text = headerSuffix,
            x = (headerStartX + headerWidth + headerPadding)/2,
            y = 6,
            align = "left",
            bg = renderHelpers.getThemeSetting(theme, "colors.bgColor", layoutName),
            color = renderHelpers.getThemeSetting(theme, "colors.headerSuffixColor", layoutName)
        }
        table.insert(elements, suffix)
    end

    local subHeaderWidth = math.max( (display.bgCanvas.width / 2) / 2, #props.config.branding.title)
    local subheaderStartX = 1
    if  headerAlign == "center" then
        subheaderStartX = math.floor(((display.bgCanvas.width / 2) - subHeaderWidth) / 2)
    elseif headerAlign == "right" then
        subheaderStartX = (display.bgCanvas.width/2) - subHeaderWidth
    end
    local subHeader = BasicText {
        display = display,
        text = props.config.branding.title,
        x = subheaderStartX,
        y = 6 + 2,
        align = headerAlign,
        bg = renderHelpers.getThemeSetting(theme, "colors.subheaderBgColor", layoutName),
        color = renderHelpers.getThemeSetting(theme, "colors.subheaderColor", layoutName),
        width = subHeaderWidth
    }
    table.insert(elements, Rect {
        display = display,
        x = (subheaderStartX*2) - 1,
        y = ((6+2)*3) - 3,
        width = (subHeaderWidth*2) + 1,
        height = 4,
        color = renderHelpers.getThemeSetting(theme, "colors.subheaderBgColor", layoutName)
    })
    table.insert(elements, Rect {
        display = display,
        x = (subheaderStartX*2) - 2,
        y = ((6+2)*3) - 2,
        width = 1,
        height = 2,
        color = renderHelpers.getThemeSetting(theme, "colors.subheaderBgColor", layoutName)
    })
    table.insert(elements, Rect {
        display = display,
        x = ((subheaderStartX+subHeaderWidth)*2),
        y = ((6+2)*3) - 2,
        width = 1,
        height = 2,
        color = renderHelpers.getThemeSetting(theme, "colors.subheaderBgColor", layoutName)
    })
    table.insert(elements, subHeader)
    table.insert(elements, Rect {
        display = display,
        x = 5,
        y = 9*3,
        width = display.bgCanvas.width-10,
        height = 1,
        color = renderHelpers.getThemeSetting(theme, "colors.dividerColor", layoutName)
    })

    if renderHelpers.getThemeSetting(theme, "settings.showCredits", layoutName) then
        local credits = BasicText {
            display = display,
            text = "Radon",
            x = 1,
            y = 1,
            align = "left",
            bg = renderHelpers.getThemeSetting(theme, "colors.bgColor", layoutName),
            color = renderHelpers.getThemeSetting(theme, "colors.creditsColor", layoutName)
        }
        table.insert(elements, credits)
    end

    local cardX = (2*2) + 1
    local cardY = (10*3)+1
    local helperX = 1
    local currencySymbol = renderHelpers.getCurrencySymbol(currency, "small")
    local productBgColors = renderHelpers.getThemeSetting(theme, "colors.productBgColors", layoutName)
    local productBgShadowColors = renderHelpers.getThemeSetting(theme, "colors.productBgShadowColors", layoutName)

    for i = 1, #shopProducts do
        local product = shopProducts[i]
        local productAddr = product.address .. "@"
        if not props.shopState.selectedCurrency.name then
            productAddr = product.address
        end
        product.quantity = product.quantity or 0
        local qtyColor = renderHelpers.getThemeSetting(theme, "colors.normalQtyColor", layoutName)
        if product.quantity == 0 then
            qtyColor = renderHelpers.getThemeSetting(theme, "colors.outOfStockQtyColor", layoutName)
        elseif product.quantity < 10 then
            qtyColor = renderHelpers.getThemeSetting(theme, "colors.lowQtyColor", layoutName)
        elseif product.quantity < 64 then
            qtyColor = renderHelpers.getThemeSetting(theme, "colors.warningQtyColor", layoutName)
        end
        local productPrice = Pricing.getProductPrice(product, props.shopState.selectedCurrency)
        local priceString = tostring(productPrice) .. currencySymbol
        local productBgColor = productBgColors[((i-1) % #productBgColors) + 1]
        local productBgShadowColor = productBgShadowColors[((i-1) % #productBgShadowColors) + 1]
        local cardWidth = 2 + 2 + (math.max(
            #product.name,
            #(" Left: " .. tostring(product.quantity)),
            #(" Name: " .. productAddr),
            2+#priceString
        )*2)
        if cardWidth % 2 ~= 0 then
            cardWidth = cardWidth + 1
        end
        if cardX + cardWidth > display.bgCanvas.width then
            cardX = (2*2) + 1
            cardY = cardY + 8*3
        end

        -- Inner card
        table.insert(elements, Rect {
            display = display,
            x = cardX + 1,
            y = cardY + 4,
            width = cardWidth - 2,
            height = (6*3) - 2,
            color = productBgColor
        })
        -- Left border
        table.insert(elements, Rect {
            display = display,
            x = cardX,
            y = cardY + 5,
            width = 1,
            height = (5*3) - 1,
            color = productBgColor
        })
        -- Right Border
        table.insert(elements, Rect {
            display = display,
            x = cardX + cardWidth - 1,
            y = cardY + 5,
            width = 1,
            height = (5*3) - 1,
            color = productBgColor
        })
        -- Right shadow
        table.insert(elements, Rect {
            display = display,
            x = cardX + cardWidth,
            y = cardY + 6,
            width = 1,
            height = (5*3),
            color = productBgShadowColor
        })
        -- Bottom shadow
        table.insert(elements, Rect {
            display = display,
            x = cardX + 2,
            y = cardY + (6*3) + 2,
            width = cardWidth - 2,
            height = 1,
            color = productBgShadowColor
        })
        -- Bottom right shadow
        table.insert(elements, Rect {
            display = display,
            x = cardX + cardWidth - 1,
            y = cardY + (6*3) + 1,
            width = 1,
            height = 1,
            color = productBgShadowColor
        })
        -- Product name
        table.insert(elements, BasicText {
            display = display,
            text = product.name,
            x = math.floor((cardX/2) + 2),
            y = math.floor((cardY/3) + 3),
            align = "left",
            bg = productBgColor,
            color = renderHelpers.getThemeSetting(theme, "colors.productNameColor", layoutName)
        })
        -- Product quantity
        table.insert(elements, BasicText {
            display = display,
            text = " Left: ",
            x = math.floor((cardX/2) + 2),
            y = math.floor((cardY/3) + 4),
            align = "left",
            bg = productBgColor,
            color = renderHelpers.getThemeSetting(theme, "colors.fieldLabelColor", layoutName)
        })
        table.insert(elements, BasicText {
            display = display,
            text = tostring(product.quantity),
            x = math.floor((cardX/2) + 2) + #(" Left: "),
            y = math.floor((cardY/3) + 4),
            align = "left",
            bg = productBgColor,
            color = qtyColor
        })
        -- Product address (metaname)
        table.insert(elements, BasicText {
            display = display,
            text = " Name: ",
            x = math.floor((cardX/2) + 2),
            y = math.floor((cardY/3) + 5),
            align = "left",
            bg = productBgColor,
            color = renderHelpers.getThemeSetting(theme, "colors.fieldLabelColor", layoutName)
        })
        table.insert(elements, BasicText {
            display = display,
            text = productAddr,
            x = math.floor((cardX/2) + 2) + #(" Name: "),
            y = math.floor((cardY/3) + 5),
            align = "left",
            bg = productBgColor,
            color = renderHelpers.getThemeSetting(theme, "colors.addressColor", layoutName)
        })
        -- Product price
        table.insert(elements, BasicText {
            display = display,
            text = " " .. priceString .. " ",
            x = math.floor(((cardX + cardWidth)/2) - (#priceString + 2)),
            y = math.floor((cardY/3) + 6),
            align = "center",
            bg = renderHelpers.getThemeSetting(theme, "colors.priceBgColor", layoutName),
            color = renderHelpers.getThemeSetting(theme, "colors.priceColor", layoutName),
        })
        -- Product kristpay helper
        if props.shopState.selectedCurrency.name then
            local helperString = productAddr .. props.shopState.selectedCurrency.name
            table.insert(elements, BasicText {
                display = display,
                text = helperString,
                x = helperX,
                y = math.floor(cardY/3),
                align = "left",
                bg = renderHelpers.getThemeSetting(theme, "colors.bgColor", layoutName),
                color = renderHelpers.getThemeSetting(theme, "colors.bgColor", layoutName),
            })
            helperX = helperX + #helperString + 1
        end
        
        cardX = cardX + cardWidth + 4
    end

    -- Currencies
    if #props.config.currencies > 1 then
        local currencyBgColors = renderHelpers.getThemeSetting(theme, "colors.currencyBgColors", layoutName)
        local maxCurrencyLeftX = math.floor( ((subheaderStartX*2) - 3) / 2)
        local minCurrencyRightX = math.ceil( (((subheaderStartX+subHeaderWidth)*2) + 3) / 2)
        local currencyX = 2
        for i = 1, #props.config.currencies do
            local displayCurrency = props.config.currencies[i]
            local displaySymbol = " " .. renderHelpers.getCurrencySymbol(displayCurrency, "small") .. " "
            local currencyBgColor = currencyBgColors[((i-1) % #currencyBgColors) + 1]
            if currencyX + #displaySymbol > maxCurrencyLeftX then
                currencyX = minCurrencyRightX
            end
            table.insert(elements, BasicButton {
                display = display,
                text = displaySymbol,
                x = currencyX,
                y = 6 + 2,
                align = "left",
                bg = currencyBgColor,
                color = renderHelpers.getThemeSetting(theme, "colors.currencyTextColor", layoutName),
                onClick = function()
                    props.shopState.selectedCurrency = props.config.currencies[i]
                    props.shopState.lastTouched = os.epoch("utc")
                    if props.config.settings.playSounds then
                        sound.playSound(props.speaker, props.config.sounds.button)
                    end
                end
            })
            currencyX = currencyX + #displaySymbol + 2
        end
    end

    -- Categories
    if #categories > 1 then
        local categoryBgColors = renderHelpers.getThemeSetting(theme, "colors.categoryBgColors", layoutName)
        local categoriesWidth = 0
        for i = 1, #categories do
            local category = categories[i]
            local categoryName = category.name
            if i == selectedCategory then
                categoryName = "[" .. categoryName .. "]"
            end
            categoriesWidth = categoriesWidth + #categoryName + 4
        end
        local categoryX = math.floor((display.bgCanvas.width / 4) - (categoriesWidth / 2))
        for i = 1, #categories do
            local category = categories[i]
            local categoryName = category.name
            local categoryBgColor = categoryBgColors[((i-1) % #categoryBgColors) + 1]
            if i == selectedCategory then
                categoryName = "[" .. categoryName .. "]"
                categoryBgColor = renderHelpers.getThemeSetting(theme, "colors.activeCategoryColor", layoutName)
            end
            table.insert(elements, BasicButton {
                display = display,
                text = " " .. categoryName .. " ",
                x = categoryX,
                y = math.floor(display.bgCanvas.height / 3) - 1,
                align = "left",
                bg = categoryBgColor,
                color = renderHelpers.getThemeSetting(theme, "colors.categoryTextColor", layoutName),
                onClick = function()
                    props.shopState.selectedCategory = i
                    props.shopState.lastTouched = os.epoch("utc")
                    if props.config.settings.playSounds then
                        sound.playSound(props.speaker, props.config.sounds.button)
                    end
                end
            })
            categoryX = categoryX + #categoryName + 4
        end
    end

    if props.config.settings.showFooter then
        local footerMessage
        if props.shopState.selectedCurrency.name or not props.config.lang.footerNoName then
            footerMessage = props.config.lang.footer
        else
            footerMessage = props.config.lang.footerNoName
        end
        if props.shopState.selectedCurrency.name and footerMessage:find("%%name%%") then
            footerMessage = footerMessage:gsub("%%name%%", props.shopState.selectedCurrency.name)
        end
        if footerMessage:find("%%addr%%") then
            footerMessage = footerMessage:gsub("%%addr%%", props.shopState.selectedCurrency.host)
        end
        if footerMessage:find("%%version%%") then
            footerMessage = footerMessage:gsub("%%version%%", version)
        end

        if props.shopState.selectedCurrency then
            local footer = BasicText {
                display = display,
                text = footerMessage,
                x = 1,
                y = math.floor(display.bgCanvas.height / 3) ,
                align = renderHelpers.getThemeSetting(theme, "formatting.footerAlign", layoutName),
                bg = renderHelpers.getThemeSetting(theme, "colors.footerBgColor", layoutName),
                color = renderHelpers.getThemeSetting(theme, "colors.footerColor", layoutName),
                width = math.floor(display.bgCanvas.width / 2)
            }
            table.insert(elements, footer)
        end
    end

    return elements
end

return render