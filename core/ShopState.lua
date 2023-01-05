local Krypton = require("Krypton")
local ScanInventory = require("core.inventory.ScanInventory")
local Pricing = require("core.Pricing")
local sound = require("util.sound")
local eventHook = require("util.eventHook")

local blinkFrequency = 3
local shopSyncFrequency = 30
local shopSyncChannel = 9773

---@class ShopState
---@field running boolean
local ShopState = {}
local ShopState_mt = { __index = ShopState }

function ShopState.new(config, products, modem, shopSyncModem, speaker, version)
    local self = setmetatable({}, ShopState_mt)

    self.running = false
    self.config = config
    self.products = products
    self.modem = modem
    self.shopSyncModem = shopSyncModem
    self.speaker = speaker
    self.version = version
    self.selectedCurrency = config.currencies[1]
    self.selectedCategory = 1
    self.numCategories = 1
    self.productsChanged = false
    self.lastTouched = os.epoch("utc")

    return self
end

local function waitForAnimation(uid)
    coroutine.yield("animationFinished", uid)
end

local function parseMeta(transactionMeta)
    local meta = {}
    local i = 1
    if transactionMeta and #transactionMeta > 0 then
        for metaEntry in transactionMeta:gmatch("([^;]+)") do
            if metaEntry:find("=") then
                local key, value = metaEntry:match("([^=]+)=([^=]+)")
                meta[key] = value
            else
                meta[metaEntry] = true
                meta[i] = metaEntry
                i = i + 1
            end
        end
    end
    return meta
end

local function validateReturnAddress(address)
    -- Primitive validation, will accept all valid addresses at the expense of some false positives
    if address:find("@") then
        local metaname, name = address:match("([^@]+)@([^@]+).%w+")
        if not metaname or not name then
            return false
        end
        if #name > 64 or #metaname > 32 then
            return false
        end
    else
        if #address > 64 then
            return false
        end
    end
    return true
end

local function isRelative(name)
    return name == "top" or name == "bottom" or name == "left" or name == "right" or name == "front" or name == "back"
end

local function refund(currency, address, meta, value, message, error)
    message = message or "Here is your refund!"
    local returnTo = address
    if meta and meta["return"] then
        if validateReturnAddress(meta["return"]) then
            returnTo = meta["return"]
        end
    end
    if not error then
        currency.krypton.ws:makeTransaction(returnTo, value, "message=" .. message)
    else
        currency.krypton.ws:makeTransaction(returnTo, value, "error=" .. message)
    end
end

local function handlePurchase(transaction, meta, sentMetaname, transactionCurrency, transactionCurrency, state)
    local purchasedProduct = nil
    for _, product in ipairs(state.products) do
        if product.address:lower() == sentMetaname:lower() or product.name:gsub(" ", ""):lower() == sentMetaname:lower() then
            purchasedProduct = product
            break
        end
    end
    if purchasedProduct then
        local productPrice = Pricing.getProductPrice(purchasedProduct, transactionCurrency)
        local amountPurchased = math.floor(transaction.value / productPrice)
        if amountPurchased > 0 then
            if purchasedProduct.quantity and purchasedProduct.quantity > 0 then
                local productSources, available = ScanInventory.findProductItems(state.products, purchasedProduct, amountPurchased)
                local refundAmount = math.floor(transaction.value - (available * productPrice))
                if available > 0 then
                    local allowPurchase = true
                    local err
                    local errMessage
                    if state.config.hooks and state.config.hooks.prePurchase then
                        allowPurchase, err, errMessage = eventHook.execute(state.config.hooks.prePurchase, purchasedProduct, available, refundAmount, transaction, transactionCurrency)
                    end
                    if allowPurchase ~= false then
                        print("Purchased " .. available .. " of " .. purchasedProduct.name .. " for " .. transaction.from .. " for " .. transaction.value .. " " .. transactionCurrency.id .. " (refund " .. refundAmount .. ")")
                        for _, productSource in ipairs(productSources) do
                            if state.config.peripherals.outputChest == "self" then
                                if not turtle then
                                    error("Self output but not a turtle!")
                                end
                                if not state.modem.getNameLocal() then
                                    error("Modem is not connected! Try right clicking it")
                                end
                                peripheral.call(productSource.inventory, "pushItems", state.modem.getNameLocal(), productSource.slot, productSource.amount, 1)
                                if state.config.settings.dropDirection == "forward" then
                                    turtle.drop(productSource.amount)
                                elseif state.config.settings.dropDirection == "up" then
                                    turtle.dropUp(productSource.amount)
                                elseif state.config.settings.dropDirection == "down" then
                                    turtle.dropDown(productSource.amount)
                                else
                                    error("Invalid drop direction: " .. state.config.settings.dropDirection)
                                end
                            else
                                peripheral.call(productSource.inventory, "pushItems", state.config.peripherals.outputChest, productSource.slot, productSource.amount, 1)
                                --peripheral.call(state.config.peripherals.outputChest, "drop", 1, productSource.amount, state.config.settings.dropDirection)
                            end
                        end
                        purchasedProduct.quantity = purchasedProduct.quantity - available
                        if refundAmount > 0 then
                            refund(transactionCurrency, transaction.from, meta, refundAmount, state.config.lang.refundRemaining)
                        end
                        if state.config.settings.playSounds then
                            sound.playSound(state.speaker, state.config.sounds.purchase)
                        end
                        if state.config.hooks and state.config.hooks.purchase then
                            eventHook.execute(state.config.hooks.purchase, purchasedProduct, available, refundAmount, transaction, transactionCurrency)
                        end
                    else
                        refund(transactionCurrency, transaction.from, meta, transaction.value, errMessage or state.config.lang.refundDenied, err)
                        if state.config.hooks and state.config.hooks.failedPurchase then
                            eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, errMessage or state.config.lang.refundDenied, err)
                        end
                    end
                else
                    refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundOutOfStock)
                    if state.config.hooks and state.config.hooks.failedPurchase then
                        eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, state.config.lang.refundOutOfStock)
                    end
                end
            else
                refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundOutOfStock)
                if state.config.hooks and state.config.hooks.failedPurchase then
                    eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, state.config.lang.refundOutOfStock)
                end
            end
        else
            refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundAtLeastOne, true)
            if state.config.hooks and state.config.hooks.failedPurchase then
                eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, state.config.lang.refundAtLeastOne)
            end
        end
    else
        refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundInvalidProduct, true)
        if state.config.hooks and state.config.hooks.failedPurchase then
            eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, nil, state.config.lang.refundInvalidProduct)
        end
    end
end

-- Anytime the shop state is resumed, animation should be finished instantly. (call animation finish hooks)
---@param state ShopState
local function runShop(state)
    -- Shop is starting
    state.running = true
    state.currencies = {}
    local kryptonListeners = {}
    for _, currency in ipairs(state.config.currencies) do
        local node = currency.node
        if not node and currency.id == "krist" then
            node = "https://krist.dev/"
        elseif not node and currency.id == "tenebra" then
            node = "https://tenebra.lil.gay/"
        end
        currency.krypton = Krypton.new({
            privateKey = currency.pkey,
            node = node,
            id = currency.id,
        })
        table.insert(state.currencies, currency)
        local kryptonWs = currency.krypton:connect()
        kryptonWs:subscribe("ownTransactions")
        kryptonWs:getSelf()
        local pkey = currency.pkey
        if currency.pkeyFormat == "kristwallet" then
            pkey = currency.krypton:toKristWalletFormat(currency.pkey)
        end
        currency.host = currency.krypton:makev2address(pkey)
        if currency.name then
            local name = currency.name
            if name:find("%.") then
                name = name:sub(1, name:find("%.") - 1)
            end
            local nameInfo = currency.krypton:getName(name)
            if not nameInfo then
                error("Name " .. currency.name .. " does not exist!")
            end
            if nameInfo.name.owner:lower() ~= currency.host:lower() then
                error("Name " .. currency.name .. " is not owned by " .. currency.host .. "!")
            end
        end
        table.insert(kryptonListeners, function() kryptonWs:listen() end)
    end
    parallel.waitForAny(function()
        while true do
            local event, transactionEvent = os.pullEvent("transaction")
            if event == "transaction" then
                local transactionCurrency = nil
                for _, currency in ipairs(state.currencies) do
                    if currency.krypton.id == transactionEvent.source then
                        transactionCurrency = currency
                        break
                    end
                end
                if transactionCurrency then
                    local transaction = transactionEvent.transaction
                    local sentName = transaction.sent_name
                    local sentMetaname = transaction.sent_metaname
                    local nameSuffix = transactionCurrency.krypton.currency.name_suffix
                    if sentName and transactionCurrency.name and transactionCurrency.name:find(".") then
                        sentName = sentName .. "." .. nameSuffix
                    end
                    if transaction.from ~= transactionCurrency.host and (not transactionCurrency.name and not sentName) or (transactionCurrency.name and sentName and sentName:lower() == transactionCurrency.name:lower()) then
                        local meta = parseMeta(transaction.metadata)
                        if transaction.to == transactionCurrency.host and not transactionCurrency.name and not sentMetaname then
                            sentMetaname = meta[1]
                        end
                        if sentMetaname then
                            local success, err = pcall(handlePurchase, transaction, meta, sentMetaname, transactionCurrency, transactionCurrency, state)
                            if success then
                                -- Success :D
                            else
                                refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundError, true)
                                if state.config.hooks and state.config.hooks.failedPurchase then
                                    eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, nil, state.config.lang.refundError)
                                end
                                error(err)
                            end
                        else
                            refund(transactionCurrency, transaction.from, meta, transaction.value, state.config.lang.refundNoProduct, true)
                            if state.config.hooks and state.config.hooks.failedPurchase then
                                eventHook.execute(state.config.hooks.failedPurchase, transaction, transactionCurrency, nil, state.config.lang.refundNoProduct)
                            end
                        end
                    end
                end
            end
        end
    end, function()
        while state.running do
            ScanInventory.updateProductInventory(state.products)
            if state.config.settings.hideUnavailableProducts then
                state.productsChanged = true
            end
            sleep(state.config.settings.pollFrequency)
        end
    end, function()
        while state.running do
            if state.config.settings.categoryCycleFrequency > 0 and os.epoch("utc") > state.lastTouched + (state.config.settings.activityTimeout * 1000) then
                state.selectedCategory = state.selectedCategory + 1
                if state.selectedCategory > state.numCategories then
                    state.selectedCategory = 1
                end
                state.productsChanged = true
            end
            sleep(math.min(1, state.config.settings.categoryCycleFrequency))
        end
    end, function()
        local blinkState = false
        while state.running do
            blinkState = not blinkState
            if state.config.peripherals.blinker then
                redstone.setOutput(state.config.peripherals.blinker, blinkState) 
            end
            if state.config.hooks and state.config.hooks.blink then
                eventHook.execute(state.config.hooks.blink, blinkState)
            end
            sleep(blinkFrequency)
        end
    end, function()
        while state.running do
            sleep(shopSyncFrequency)
            if state.config.shopSync and state.config.shopSync.enabled and state.shopSyncModem then
                local items = {}
                for i = 1, #state.products do
                    local product = state.products[i]
                    local prices = {}
                    local nbt = nil
                    local predicates = nil
                    if product.predicates then
                        nbt = ""
                        predicates = product.predicates
                    end
                    for j = 1, #state.config.currencies do
                        local currency = state.config.currencies[j]
                        local currencyName = "KST"
                        if currency.krypton and currency.krypton.currency and currency.krypton.currency.currency_symbol then
                            currencyName = currency.krypton.currency.currency_symbol
                        end
                        local address = currency.host
                        local requiredMeta = nil
                        if currency.name then
                            address = product.address .. "@" .. currency.name
                        else
                            requiredMeta = product.address
                        end
                        table.insert(prices, {
                            value = product.price / currency.value,
                            currency = currencyName,
                            address = address,
                            --requiredMeta = requiredMeta
                        })
                    end
                    table.insert(items, {
                        price = prices,
                        item = {
                            name = product.modid,
                            displayName = product.name,
                            nbt = nbt,
                            --predicates = predicates
                        }
                    })
                end
                state.shopSyncModem.transmit(shopSyncChannel, os.getComputerID(), {
                    type = "ShopSync",
                    info = {
                        name = state.config.shopSync.name,
                        description = state.config.shopSync.description,
                        owner = state.config.shopSync.owner,
                        software = {
                            name = "Radon",
                            version = state.version
                        },
                        location = state.config.shopSync.location,
                    },
                    items = {

                    }
                })
            end
        end
    end, unpack(kryptonListeners))
end

return {
    ShopState = ShopState,
    runShop = runShop,
}