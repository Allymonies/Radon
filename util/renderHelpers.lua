local bigFont = require("fonts.bigfont")
local smolFont = require("fonts.smolfont")
local Pricing = require("core.Pricing")

local function getDisplayedProducts(allProducts, settings, currency)
    local displayedProducts = {}
    for i = 1, #allProducts do
        local product = allProducts[i]
        product.id = i
        local productPrice = Pricing.getProductPrice(product, currency)
        if
            (not settings.hideUnavailableProducts or (product.quantity and product.quantity > 0))
            and (not settings.hideNegativePrices or (productPrice and productPrice >= 0))
            then
            table.insert(displayedProducts, product)
        end
    end
    return displayedProducts
end

local function getCurrencySymbol(currency, layout)
    if currency.krypton and currency.krypton.currency then
        currencySymbol = currency.krypton.currency.currency_symbol  
    elseif not currencySymbol and currency.name and currency.name:find("%.") then
        currencySymbol = currency.name:sub(currency.name:find("%.")+1, #currency.name)
    elseif currency.id == "tenebra" then
        currencySymbol = "tst"
    else
        currencySymbol = "KST"
    end
    if currencySymbol == "TST" then
        currencySymbol = "tst"
    end
    if currencySymbol:lower() == "kst" and (layout == "medium" or layout == "small") then
        currencySymbol = "kst"
    elseif currencySymbol:lower() == "kst" then
        currencySymbol = "\164"
    end
    return currencySymbol
end

local function getCategories(products)
    local categories = {}
    for _, product in ipairs(products) do
        if not product.hidden then
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
    end
    return categories
end

local function getWidth(text, fontSize)
    if fontSize == "large" then
        return bigFont:getWidth(text)
    elseif fontSize == "medium" then
        return smolFont:getWidth(text)
    else
        return #text
    end
end

local function getThemeSetting(theme, path, layout)
    -- Split on "."
    layoutTheme = {}
    if theme.layouts and theme.layouts[layout] then
        layoutTheme = theme.layouts[layout]
    end
    local paths = path:gmatch("[^%.]+")
    for subpath in paths do
        if layoutTheme and layoutTheme[subpath] then
            layoutTheme = layoutTheme[subpath]
        else
            layoutTheme = nil
        end
        if theme and theme[subpath] then
            theme = theme[subpath]
        else
            theme = nil 
        end
        if not theme and not layoutTheme then
            return nil
        end
    end
    if layoutTheme then
        return layoutTheme
    else
        return theme
    end
end

return {
    getDisplayedProducts = getDisplayedProducts,
    getCurrencySymbol = getCurrencySymbol,
    getCategories = getCategories,
    getWidth = getWidth,
    getThemeSetting = getThemeSetting,
}