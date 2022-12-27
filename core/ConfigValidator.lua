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
        dropDirection = "enum<'forward' | 'up' | 'down' | 'north' | 'south' | 'east' | 'west'>: direction"
    },
    theme = {
        formatting = {
            headerAlign = "enum<'left' | 'center' | 'right'>: alignment",
            productNameAlign = "enum<'left' | 'center' | 'right'>: alignment",
            productTextSize = "enum<'small' | 'medium' | 'large' | 'auto'>: text size",
        },
        colors = {
            bgColor = "color",
            headerBgColor = "color",
            headerColor = "color",
            productBgColor = "color",
            outOfStockQtyColor = "color",
            lowQtyColor = "color",
            warningQtyColor = "color",
            normalQtyColor = "color",
            productNameColor = "color",
            outOfStockNameColor = "color",
            priceColor = "color",
            addressColor = "color",
            currencyTextColor = "color",
            currency1Color = "color",
            currency2Color = "color",
            currency3Color = "color",
            currency4Color = "color",
            catagoryTextColor = "color",
            category1Color = "color",
            category2Color = "color",
            category3Color = "color",
            category4Color = "color",
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
        self = "string?",
        selfRelativeOutput = "string?",
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
                    validate(config[i], schema.__entry, path .. "[" .. i .. "]")
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
                if config[k] then
                    if v == "table" and type(config[k]) ~= "table" then
                        error("Config value " .. subpath .. " must be a table")
                    end
                    if v == "string" and type(config[k]) ~= "string" then
                        error("Config value " .. subpath .. " must be a string")
                    end
                    if v == "number" and type(config[k]) ~= "number" then
                        error("Config value " .. subpath .. " must be a number")
                    end
                    if v == "color" then
                        if type(config[k]) ~= "number" then
                            error("Config value " .. subpath .. " must be a color")
                        end
                        m,n = math.frexp(config[k])
                        if m ~= 0.5 or n < 1 or n > 16 then
                            error("Config value " .. subpath .. " must be a color")
                        end
                    end
                    if v == "chest" then
                        if type(config[k]) ~= "string" then
                            error("Config value " .. subpath .. " must be a networked chest")
                        end
                        if not turtle and (config[k] == "left" or config[k] == "right" or config[k] == "front" or config[k] == "back" or config[k] == "top" or config[k] == "bottom") then
                            error("Config value " .. subpath .. " must not be a relative position")
                        end
                        if not turtle and config[k] == "self" then
                            error("Config value " .. subpath .. " can only be self for turtles")
                        end
                        if config[k] ~= "self" then
                            local chestMethods = peripheral.getMethods(config[k])
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
                    if v == "boolean" and type(config[k]) ~= "boolean" then
                        error("Config value " .. subpath .. " must be a boolean")
                    end
                    if v:sub(1, 5) == "enum<" and v:sub(-1) == ">" then
                        local enum = v:sub(6, -2)
                        local found = false
                        for enumValue in enum:gmatch("[^|]+") do
                            enumValue = enumValue:sub(enumValue:find("'(.*)'")):sub(2, -2)
                            if config[k] == enumValue then
                                found = true
                                break
                            end
                        end
                        if not found then
                            if typeName then
                                error("Config value " .. subpath .. " must be type " .. typeName .. " matching " .. enum)
                            else
                                error("Config value " .. subpath .. " must be one of " .. enum)
                            end
                        end
                    end
                    if v:sub(1, 6) == "regex<" and v:sub(-1) == ">" then
                        local regexString = v:sub(7, -2)
                        local regex = r2l.new(regexString)
                        if not regex(config[k]) then
                            if typeName then
                                error("Config value " .. subpath .. " must be type " .. typeName .. " matching " .. regexString)
                            else
                                error("Config value " .. subpath .. " must match " .. regexString)
                            end
                        end
                    end
                end
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