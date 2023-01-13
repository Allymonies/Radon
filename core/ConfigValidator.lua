local r2l = require("modules.regex")
local schemas = require("core.schemas")

local regexCache = {}

local function typeCheck(entryType, typeName, value, path)
    if value then
        if entryType == "table" and type(value) ~= "table" then
            return { path = subpath, error = "Must be a table" }
        end
        if entryType == "string" and type(value) ~= "string" then
            return { path = subpath, error = "Must be a string" }
        end
        if entryType == "number" and type(value) ~= "number" then
            return { path = subpath, error = "Must be a number" }
        end
        if entryType == "function" and type(value) ~= "function" then
            return { path = subpath, error = "Must be a function" }
        end
        if entryType == "file" then
            if type(value) ~= "string" then
                return { path = subpath, error = "Must be a file path" }
            end
            if not fs.exists(value) or fs.isDir(value) then
                return { path = subpath, error = "File must exist" }
            end
        end
        if entryType == "color" then
            if type(value) ~= "number" then
                return { path = subpath, error = "Must be a color" }
            end
            m,n = math.frexp(value)
            if m ~= 0.5 or n < 1 or n > 16 then
                return { path = subpath, error = "Must be a color" }
            end
        end
        if entryType == "modem" then
            if type(value) ~= "string" then
                return { path = subpath, error = "Must be a modem name" }
            end
            if peripheral.getType(value) ~= "modem" then
                return { path = subpath, error = "Must refer to a modem" }
            end
        end
        if entryType == "speaker" then
            if type(value) ~= "string" then
                return { path = subpath, error = "Must be a speaker name" }
            end
            if peripheral.getType(value) ~= "speaker" then
                return { path = subpath, error = "Must refer to a speaker" }
            end
        end
        if entryType == "chest" then
            if type(value) ~= "string" then
                return { path = subpath, error = "Must be a chest name" }
            end
            -- If relative paths are fixed, add not turtle and
            if value == "left" or value == "right" or value == "front" or value == "back" or value == "top" or value == "bottom" then
                return { path = subpath, error = "Must be a network name" }
            end
            if not turtle and value == "self" then
                return { path = subpath, error = "Can only be self for turtles" }
            end
            if value ~= "self" then
                local chestMethods = peripheral.getMethods(value)
                if not chestMethods then
                    return { path = subpath, error = "Must refer to a valid peripheral" }
                end
                local hasDropMethod = false
                for i = 1, #chestMethods do
                    if chestMethods[i] == "drop" then
                        hasDropMethod = true
                        break
                    end
                end
                if not hasDropMethod then
                    return { path = subpath, error = "Must refer to an inventory" }
                end
            end
        end
        if entryType == "sound" then
            if type(value) ~= "table" then
                return { path = subpath, error = "Must be a sound" }
            end
            if not value.name or type(value.name) ~= "string" then
                return { path = subpath, error = "Sound must have a name" }
            end
            if not value.volume or type(value.volume) ~= "number" then
                return { path = subpath, error = "Sound must have a volume" }
            end
            if not value.pitch or type(value.pitch) ~= "number" then
                return { path = subpath, error = "Sound must have a pitch" }
            end
        end
        if entryType == "boolean" and type(value) ~= "boolean" then
            return { path = subpath, error = "Must be a boolean" }
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
                    return { path = subpath, error = "Must be entryType " .. typeName .. " matching " .. enum }
                else
                    return { path = subpath, error = "Must match " .. enum }
                end
            end
        end
        if entryType:sub(1, 6) == "regex<" and entryType:sub(-1) == ">" then
            local regexString = entryType:sub(7, -2)
            if not regexCache[regexString] then
                regexCache[regexString] = r2l.new(regexString)
            end
            local regex = regexCache[regexString]
            if not regex(value) then
                if typeName then
                    return { path = subpath, error = "Must be entryType " .. typeName .. " matching " .. regexString }
                else
                    return { path = subpath, error = "Must match " .. regexString }
                end
            end
        end
    end
    return nil
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
                return { path = path, error = "Must be an array" }
            end
            if schema.__min and #config < schema.__min then
                return { path = path, error = "Must have at least " .. schema.__min .. " entries" }
            end
            if schema.__max and #config > schema.__max then
                return { path = path, error = "Must have at most " .. schema.__max .. " entries" }
            end
            if schema.__entry then
                local validationErrors = {}
                for i = 1, #config do
                    if type(config[i]) ~= "table" then
                        local err = typeCheck(schema.__entry, schema.__entry, config[i], path .. "[" .. i .. "]")
                        if err then
                            table.insert(validationErrors, err)
                        end
                    else
                        local errs = validate(config[i], schema.__entry, path .. "[" .. i .. "]")
                        if errs and type(errs) == "table" and errs[1] then
                            for _, err in ipairs(errs) do
                                table.insert(validationErrors, err)
                            end
                        else
                            table.insert(validationErrors, errs)
                        end
                    end
                end
                if #validationErrors > 0 then
                    return validationErrors
                end
            end
        end
    else
        if not config then
            config = {}
        end
        local validationErrors = {}
        for k,v in pairs(schema) do
            subpath = path .. "." .. k
            if type(v) == "table" then
                local errs = validate(config[k], v, subpath)
                if errs and type(errs) == "table" and errs[1] then
                    for _, err in ipairs(errs) do
                        table.insert(validationErrors, err)
                    end
                else
                    table.insert(validationErrors, errs)
                end
            else
                -- If regex or enum, get type name
                -- E.g. regex<\w{10}>: address -> address
                local typeDef, typeName
                _, _, typeDef, typeName = v:find("^(%w+<.+>%??): (.+)$")
                if typeDef then
                    v = typeDef
                end
                if v:sub(-1) ~= "?" and config[k] == nil then
                    table.insert(validationErrors, {
                        path = subpath,
                        error = "Missing required config value"
                    })
                end
                if v:sub(-1) == "?" then
                    v = v:sub(1, -2)
                end
                local err = typeCheck(v, typeName, config[k], subpath)
                if err then
                    table.insert(validationErrors, err)
                end
            end
        end
        if #validationErrors > 0 then
            return validationErrors
        end
    end
end

function validationArrayToMap(validationErrors)
    local map = {}
    if not validationErrors then
        return map
    end
    for _, err in ipairs(validationErrors) do
        if err.path then
            map[err.path:gsub("%[(%d+)%]", "%.%1")] = err.error
        end
    end
    return map
end

local function validateConfig(config)
    return validate(config, schemas.configSchema, "config")
end

local function validateProducts(products)
    return validate(products, schemas.productsSchema, "products")
end

local function validateHooks(hooks)
    return validate(hooks, schemas.hooksSchema, "hooks")
end

return {
    typeCheck = typeCheck,
    validate = validate,
    validationArrayToMap = validationArrayToMap,
    validateConfig = validateConfig,
    validateProducts = validateProducts,
    validateHooks = validateHooks,
}