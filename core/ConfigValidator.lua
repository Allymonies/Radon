local r2l = require("modules.regex")

local configSchema = {
    branding = {
        title = "string"
    },
    settings = {
        hideUnavailableProducts = "boolean",
        pollFrequency = "number",
        categoryCycleFrequency = "number",
        activityTimeout = "number",
        dropDirection = "enum<'forward' | 'up' | 'down' | 'north' | 'south' | 'east' | 'west'>: direction",
        smallTextKristPayCompatability = "boolean",
    },
    lang = {
        footer = "string",
        refundRemaining = "string",
        refundOutofStock = "string",
        refundAtLeastOne = "string",
        refundInvalidProduct = "string",
        refundNoProduct = "string",
        refundError = "string"
    },
    theme = {
        formatting = {
            headerAlign = "enum<'left' | 'center' | 'right'>: alignment",
            footerAlign = "enum<'left' | 'center' | 'right'>: alignment",
            productNameAlign = "enum<'left' | 'center' | 'right'>: alignment",
            productTextSize = "enum<'small' | 'medium' | 'large' | 'auto'>: text size",
        },
        colors = {
            bgColor = "color",
            headerBgColor = "color",
            headerColor = "color",
            footerBgColor = "color",
            footerColor = "color",
            productBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            outOfStockQtyColor = "color",
            lowQtyColor = "color",
            warningQtyColor = "color",
            normalQtyColor = "color",
            productNameColor = "color",
            outOfStockNameColor = "color",
            priceColor = "color",
            addressColor = "color",
            currencyTextColor = "color",
            currencyBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            catagoryTextColor = "color",
            categoryBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            activeCategoryColor = "color",
        },
        palette = {
            [colors.black] = "number",
            [colors.blue] = "number",
            [colors.purple] = "number",
            [colors.green] = "number",
            [colors.brown] = "number",
            [colors.gray] = "number",
            [colors.lightGray] = "number",
            [colors.red] = "number",
            [colors.orange] = "number",
            [colors.yellow] = "number",
            [colors.lime] = "number",
            [colors.cyan] = "number",
            [colors.magenta] = "number",
            [colors.pink] = "number",
            [colors.lightBlue] = "number",
            [colors.white] = "number"
        }
    },
    currencies = {
        __type = "array",
        __min = 1,
        __entry = {
            id = "string",
            node = "string?",
            host = [[regex<^\w{10}$>: address]],
            name = "string",
            pkey = "string",
            pkeyFormat = "enum<'raw' | 'kristwallet'>: pkey format",
            value = "number?"
        }
    },
    peripherals = {
        monitor = "string?",
        modem = "modem?",
        exchangeChest = "chest?",
        outputChest = "chest",
    },
    exchange = {
        enabled = "boolean",
        node = "string"
    }
}

local productsSchema = {
    __type = "array",
    __entry = {
        modid = "string",
        name = "string?",
        address = "string",
        order = "number?",
        quantity = "number?",
        category = "string?",
        price = "number",
        priceOverrides = {
            __type = "array?",
            __entry = {
                currency = "string",
                price = "number"
            }
        },
        predicate = "table?"
    }
}


local function typeCheck(entryType, typeName, value, path)
    if value then
        if entryType == "table" and type(value) ~= "table" then
            error("Config value " .. subpath .. " must be a table")
        end
        if entryType == "string" and type(value) ~= "string" then
            error("Config value " .. subpath .. " must be a string")
        end
        if entryType == "number" and type(value) ~= "number" then
            error("Config value " .. subpath .. " must be a number")
        end
        if entryType == "color" then
            if type(value) ~= "number" then
                error("Config value " .. subpath .. " must be a color")
            end
            m,n = math.frexp(value)
            if m ~= 0.5 or n < 1 or n > 16 then
                error("Config value " .. subpath .. " must be a color")
            end
        end
        if entryType == "modem" then
            if type(value) ~= "string" then
                error("Config value " .. subpath .. " must be a modem name")
            end
            if peripheral.getType(value) ~= "modem" then
                error("Config value " .. subpath .. " must refer to a modem")
            end
        end
        if entryType == "chest" then
            if type(value) ~= "string" then
                error("Config value " .. subpath .. " must be a networked chest")
            end
            if not turtle and (value == "left" or value == "right" or value == "front" or value == "back" or value == "top" or value == "bottom") then
                error("Config value " .. subpath .. " must not be a relative position")
            end
            if not turtle and value == "self" then
                error("Config value " .. subpath .. " can only be self for turtles")
            end
            if value ~= "self" then
                local chestMethods = peripheral.getMethods(value)
                if not chestMethods then
                    error("Config value " .. subpath .. " must refer to a valid peripheral")
                end
                local hasDropMethod = false
                for i = 1, #chestMethods do
                    if chestMethods[i] == "drop" then
                        hasDropMethod = true
                        break
                    end
                end
                if not hasDropMethod then
                    error("Config value " .. subpath .. " must refer to a peripheral with an inventory")
                end
            end
        end
        if entryType == "boolean" and type(value) ~= "boolean" then
            error("Config value " .. subpath .. " must be a boolean")
        end
        if entryType:sub(1, 5) == "enum<" and entryType:sub(-1) == ">" then
            local enum = entryType:sub(6, -2)
            local found = false
            for enumValue in enum:gmatch("[^|]+") do
                enumValue = enumValue:sub(enumValue:find("'(.*)'")):sub(2, -2)
                if value == enumValue then
                    found = true
                    break
                end
            end
            if not found then
                if typeName then
                    error("Config value " .. subpath .. " must be entryType " .. typeName .. " matching " .. enum)
                else
                    error("Config value " .. subpath .. " must be one of " .. enum)
                end
            end
        end
        if entryType:sub(1, 6) == "regex<" and entryType:sub(-1) == ">" then
            local regexString = entryType:sub(7, -2)
            local regex = r2l.new(regexString)
            if not regex(value) then
                if typeName then
                    error("Config value " .. subpath .. " must be entryType " .. typeName .. " matching " .. regexString)
                else
                    error("Config value " .. subpath .. " must match " .. regexString)
                end
            end
        end
    end
end

local function validate(config, schema, path)
    if not path then
        path = ""
    end
    if schema.__type then
        if schema.__type:sub(1, 5) == "array" then
            if schema.__type:sub(6, 6) == "?" and config == nil then
                return
            end
            if type(config) ~= "table" then
                error("Config value " .. path .. " must be an array")
            end
            if schema.__min and #config < schema.__min then
                error("Config value " .. path .. " must have at least " .. schema.__min .. " entries")
            end
            if schema.__max and #config > schema.__max then
                error("Config value " .. path .. " must have at most " .. schema.__max .. " entries")
            end
            if schema.__entry then
                for i = 1, #config do
                    if type(config[i]) ~= "table" then
                        typeCheck(schema.__entry, schema.__entry, config[i], path .. "[" .. i .. "]")
                    else
                        validate(config[i], schema.__entry, path .. "[" .. i .. "]")
                    end
                end
            end
        end
    else
        for k,v in pairs(schema) do
            subpath = path .. "." .. k
            if type(v) == "table" then
                validate(config[k], v, subpath)
            else
                -- If regex or enum, get type name
                -- E.g. regex<\w{10}>: address -> address
                local typeDef, typeName
                _, _, typeDef, typeName = v:find("^(%w+<.+>%??): (.+)$")
                if typeDef then
                    v = typeDef
                end
                if v:sub(-1) ~= "?" and config[k] == nil then
                    error("Missing required config value: " .. subpath)
                end
                if v:sub(-1) == "?" then
                    v = v:sub(1, -2)
                end
                typeCheck(v, typeName, config[k], subpath)
            end
        end
    end
end

local function validateConfig(config)
    validate(config, configSchema, "config")
end

local function validateProducts(products)
    validate(products, productsSchema, "products")
end

return {
    validateConfig = validateConfig,
    validateProducts = validateProducts
}