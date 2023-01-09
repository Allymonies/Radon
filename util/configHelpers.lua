local score = require("util.score")

function getPeripherals(config, peripherals)
    
    local modem
    local failed = 0
    repeat
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
        if not modem then
            failed = failed + 1
            sleep(2)
        end
    until modem or failed > 2
    if not modem then
        error("No modem found")
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

    if modem then peripherals.modem = modem end
    if shopSyncModem then peripherals.shopSyncModem = shopSyncModem end
    if speaker then peripherals.speaker = speaker end

    return peripherals
end

local colorNames = {
    [colors.black] = "colors.black",
    [colors.blue] = "colors.blue",
    [colors.purple] = "colors.purple",
    [colors.green] = "colors.green",
    [colors.brown] = "colors.brown",
    [colors.gray] = "colors.gray",
    [colors.lightGray] = "colors.lightGray",
    [colors.red] = "colors.red",
    [colors.orange] = "colors.orange",
    [colors.yellow] = "colors.yellow",
    [colors.lime] = "colors.lime",
    [colors.cyan] = "colors.cyan",
    [colors.magenta] = "colors.magenta",
    [colors.pink] = "colors.pink",
    [colors.lightBlue] = "colors.lightBlue",
    [colors.white] = "colors.white",
}

function getColorName(num)
    return colorNames[num]
end

function getNewConfig(config, configDiffs, arrayAdds, arrayRemoves)
    local newConfig = score.copyDeep(config)
    for k, _ in pairs(arrayAdds) do
        local subConfig = newConfig
        for path in k:gmatch("([^%[?%]?%.?]+)") do
            if path:match("%d+") then
                path = tonumber(path) or path
            end
            if subConfig[path] then
                subConfig = subConfig[path]
            else
                subConfig[path] = {}
                subConfig = subConfig[path]
            end
        end
    end
    for k, v in pairs(configDiffs) do
        local subConfig = newConfig
        for path in k:gmatch("([^%[?%]?%.?]+)%.+") do
            if path:match("%d+") then
                path = tonumber(path) or path
            end
            if subConfig[path] then
                subConfig = subConfig[path]
            else
                subConfig[path] = {}
                subConfig = subConfig[path]
            end
        end
        local lastPath = k:match("^.+%.([^%.]+)$")
        if lastPath:match("%d+") then
            lastPath = tonumber(lastPath) or lastPath
        end
        if v == "%nil%" then
            v = nil
        end
        subConfig[lastPath] = v
    end
    local removalArrays = {}
    for k, _ in pairs(arrayRemoves) do
        local subConfig = newConfig
        for path in k:gmatch("([^%[?%]?%.?]+)%.+") do
            if path:match("%d+") then
                path = tonumber(path) or path
            end
            if subConfig[path] then
                subConfig = subConfig[path]
            else
                subConfig[path] = {}
                subConfig = subConfig[path]
            end
        end

        local lastPath, index = ("." .. k):match("^.*%.([^%.]+)%.([^%.]+)$")
        if not lastPath then
            lastPath = ""
        end
        if not index then
            index = k:match("^.*%.([^%.]+)$")
        end
        if lastPath:match("%d+") then
            lastPath = tonumber(lastPath) or lastPath
        end
        if index:match("%d+") then
            index = tonumber(index) or index
        end
        local array = subConfig
        -- if lastPath ~= "" then
        --     array = subConfig[lastPath]
        -- else
        --     array = subConfig
        -- end
        if not removalArrays[lastPath] then
            removalArrays[lastPath] = { array = array, indices = {} }
        end
        table.insert(removalArrays[lastPath].indices, index)
    end
    for k, v in pairs(removalArrays) do
        table.sort(v.indices, function(a, b) return a > b end)
        for _, index in ipairs(v.indices) do
            table.remove(v.array, index)
        end
    end
    if newConfig.currencies then
        for k,v in pairs(newConfig.currencies) do
            newConfig.currencies[k].krypton = nil
        end
    end
    newConfig.hooks = nil
    return newConfig
end

function loadDefaults(config, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if v[1] then -- Is a table, only replace if not exists
                if not config[k] then
                    config[k] = {}
                    loadDefaults(config[k], v)
                end
            else
                if not config[k] then
                    config[k] = {}
                end
                loadDefaults(config[k], v)
            end
        else
            if config[k] == nil then
                config[k] = v
            end
        end
    end
end

return {
    getPeripherals = getPeripherals,
    getColorName = getColorName,
    getNewConfig = getNewConfig,
    loadDefaults = loadDefaults,
}