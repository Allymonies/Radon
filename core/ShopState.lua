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

function ShopState.new(config, products, peripherals, version, logs, eventHooks)
    local self = setmetatable({}, ShopState_mt)

    self.running = false
    self.config = config
    self.peripherals = peripherals
    self.products = products
    self.version = version
    if config.currencies and config.currencies[1] then
        self.selectedCurrency = config.currencies[1]
    else
        self.selectedCurrency = nil
    end
    self.selectedCategory = 1
    self.numCategories = 1
    self.productsChanged = false
    self.logs = logs
    self.eventHooks = eventHooks
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

function ShopState:handlePurchase(transaction, meta, sentMetaname, transactionCurrency)
    local purchasedProduct = nil
    if self.eventHooks and self.eventHooks.preProduct then
        purchasedProduct, err, errorMessage = eventHook.execute(self.eventHooks.preProduct, transaction, transactionCurrency, meta, sentMetaname, self.products)
        if err then
            refund(transactionCurrency, transaction.from, meta, transaction.value, errorMessage or self.config.lang.refundDenied, true)
            if self.eventHooks and self.eventHooks.failedPurchase then
                eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, errorMessage or self.config.lang.refundDenied)
            end
            return
        end
    end
    if purchasedProduct == nil then
        for _, product in ipairs(self.products) do
            if product.address:lower() == sentMetaname:lower() or product.name:gsub(" ", ""):lower() == sentMetaname:lower() then
                purchasedProduct = product
                break
            end
        end
    end
    if not purchasedProduct then
        if self.config.settings.refundInvalidMetaname then
            refund(transactionCurrency, transaction.from, meta, transaction.value, self.config.lang.refundInvalidProduct, true)
        end
        if self.eventHooks and self.eventHooks.failedPurchase then
            eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, nil, self.config.lang.refundInvalidProduct)
        end
        return
    end

    local productPrice = Pricing.getProductPrice(purchasedProduct, transactionCurrency)
    local amountPurchased = math.floor(transaction.value / productPrice)
    if productPrice == 0 then
        amountPurchased = math.max(transaction.value, 1)
    end
    if purchasedProduct.maxQuantity then
        amountPurchased = math.min(amountPurchased, purchasedProduct.maxQuantity)
    end
    if amountPurchased <= 0 then
        if self.config.settings.refundInsufficentFunds then
            refund(transactionCurrency, transaction.from, meta, transaction.value, self.config.lang.refundAtLeastOne, true)
        end
        if self.eventHooks and self.eventHooks.failedPurchase then
            eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, self.config.lang.refundAtLeastOne)
        end
        return
    end

    local productsPurchased = {}
    if purchasedProduct.modid then
        table.insert(productsPurchased, { product = purchasedProduct, quantity = 1 })
    end
    if purchasedProduct.bundle and #purchasedProduct.bundle > 0 then
        for _, bundleProduct in ipairs(purchasedProduct.bundle) do
            for _, product in ipairs(self.products) do
                if product.address:lower() == bundleProduct.product:lower() or product.name:lower() == bundleProduct.product:lower() or (product.productId and product.productId:lower() == bundleProduct.product:lower()) then
                    local productFound = false
                    for _, productPurchased in ipairs(productsPurchased) do
                        if productPurchased.product == product then
                            productPurchased.quantity = productPurchased.quantity + bundleProduct.quantity
                            productFound = true
                            break
                        end
                    end
                    if not productFound then
                        table.insert(productsPurchased, { product = product, quantity = bundleProduct.quantity })
                    end
                    break
                end
            end
        end
    end
    if self.eventHooks and self.eventHooks.preStockCheck then
        local allowPurchase, err, errMessage, invisible = eventHook.execute(self.eventHooks.preStockCheck, transaction, productsPurchased, self.products, amountPurchased)
        if allowPurchase == false then
            if not invisible then
                refund(transactionCurrency, transaction.from, meta, transaction.value, errMessage or self.config.lang.refundDenied, err)
                if self.eventHooks and self.eventHooks.failedPurchase then
                    eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, errMessage or self.config.lang.refundDenied, err)
                end
            end
            return
        end
    end
    local available = amountPurchased
    for _, productPurchased in ipairs(productsPurchased) do
        local onInventoryRefresh
        if self.eventHooks and self.eventHooks.onInventoryRefresh then
            onInventoryRefresh = self.eventHooks.onInventoryRefresh
        end
        local productSources, productAvailable = ScanInventory.findProductItems(self.products, productPurchased.product, productPurchased.quantity * amountPurchased, onInventoryRefresh)
        available = math.min(available, math.floor(productAvailable / productPurchased.quantity))
        productPurchased.sources = productSources
        if available == 0 then
            break
        end
    end
    if available <= 0 then
        refund(transactionCurrency, transaction.from, meta, transaction.value, self.config.lang.refundOutOfStock)
        if self.eventHooks and self.eventHooks.failedPurchase then
            eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, self.config.lang.refundOutOfStock)
        end
        return
    end

    local refundAmount = math.floor(transaction.value - (available * productPrice))
    local allowPurchase = true
    local err
    local errMessage
    if self.eventHooks and self.eventHooks.prePurchase then
        allowPurchase, err, errMessage, invisible = eventHook.execute(self.eventHooks.prePurchase, purchasedProduct, available, refundAmount, transaction, transactionCurrency)
    end
    if allowPurchase == false then
        if not invisible then
            refund(transactionCurrency, transaction.from, meta, transaction.value, errMessage or self.config.lang.refundDenied, err)
            if self.eventHooks and self.eventHooks.failedPurchase then
                eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, purchasedProduct, errMessage or self.config.lang.refundDenied, err)
            end
        end
        return
    end

    print("Purchased " .. available .. " of " .. purchasedProduct.name .. " for " .. transaction.from .. " for " .. transaction.value .. " " .. transactionCurrency.id .. " (refund " .. refundAmount .. ")")
    for _, productPurchased in ipairs(productsPurchased) do
        for _, productSource in ipairs(productPurchased.sources) do
            if self.config.peripherals.outputChest == "self" then
                if not turtle then
                    error("Self output but not a turtle!")
                end
                if not self.peripherals.modem.getNameLocal() then
                    error("Modem is not connected! Try right clicking it")
                end
                if turtle.getSelectedSlot() ~= 1 then
                    turtle.select(1)
                end
                peripheral.call(productSource.inventory, "pushItems", self.peripherals.modem.getNameLocal(), productSource.slot, productSource.amount, 1)
                if self.config.settings.dropDirection == "forward" then
                    turtle.drop(productSource.amount)
                elseif self.config.settings.dropDirection == "up" then
                    turtle.dropUp(productSource.amount)
                elseif self.config.settings.dropDirection == "down" then
                    turtle.dropDown(productSource.amount)
                else
                    error("Invalid drop direction: " .. self.config.settings.dropDirection)
                end
            else
                peripheral.call(productSource.inventory, "pushItems", self.config.peripherals.outputChest, productSource.slot, productSource.amount, 1)
                --peripheral.call(state.config.peripherals.outputChest, "drop", 1, productSource.amount, state.config.settings.dropDirection)
            end
        end
        productPurchased.product.quantity = productPurchased.product.quantity - (productPurchased.quantity * available)
    end
    if not purchasedProduct.modid then
        purchasedProduct.quantity = math.max(0, purchasedProduct.quantity - available)
    end
    if refundAmount > 0 then
        refund(transactionCurrency, transaction.from, meta, refundAmount, self.config.lang.refundRemaining)
    end
    if self.config.settings.playSounds then
        sound.playSound(self.peripherals.speaker, self.config.sounds.purchase)
    end
    if self.eventHooks and self.eventHooks.purchase then
        eventHook.execute(self.eventHooks.purchase, purchasedProduct, available, refundAmount, transaction, transactionCurrency)
    end
end

function ShopState:setupKrypton()
    self.selectedCurrency = self.config.currencies[1]
    self.currencies = {}
    self.kryptonListeners = {}
    for _, currency in ipairs(self.config.currencies) do
        if currency.name == "" then
            currency.name = nil
        end
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
        local pkey = currency.pkey
        if currency.pkeyFormat == "kristwallet" then
            pkey = currency.krypton:toKristWalletFormat(currency.pkey)
        end
        currency.host = currency.krypton:makev2address(pkey)
        currency.krypton.privateKey = pkey
        table.insert(self.currencies, currency)
        local kryptonWs = currency.krypton:connect()
        kryptonWs:subscribe("ownTransactions")
        kryptonWs:getSelf()
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
        table.insert(self.kryptonListeners, function() kryptonWs:listen() end)
        self.kryptonReady = true
    end
end

-- Anytime the shop state is resumed, animation should be finished instantly. (call animation finish hooks)
---@param self ShopState
function ShopState:runShop()
    -- Shop is starting
    -- Wait for config ready
    while not self.config.ready do sleep(0.5) end
    self.running = true
    self.currencies = {}
    self.kryptonListeners = {}
    self:setupKrypton()
    ScanInventory.clearNbtCache()
    local transactions = {}
    parallel.waitForAny(function()
        while true do
            local event, transactionEvent = os.pullEvent("transaction")
            if event == "transaction" then
                local transactionCurrency = nil
                for _, currency in ipairs(self.currencies) do
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
                            local purchaseData = {
                                transaction = transaction,
                                meta = meta,
                                sentMetaname = sentMetaname,
                                transactionCurrency = transactionCurrency
                            }
                            transactions[#transactions + 1] = purchaseData
                            os.queueEvent("radon_purchase", purchaseData) -- for hooks that might be able to catch it (parallel).
                        elseif self.config.settings.refundMissingMetaname then
                            if self.config.settings.refundInvalidMetaname then
                                refund(transactionCurrency, transaction.from, meta, transaction.value, self.config.lang.refundNoProduct, true)
                            end
                            if self.eventHooks and self.eventHooks.failedPurchase then
                                eventHook.execute(self.eventHooks.failedPurchase, transaction, transactionCurrency, nil, self.config.lang.refundNoProduct)
                            end
                        end
                    end
                end
            end
        end
    end, function()
        while self.running do
            -- Run event hook for the parallel constant running task
            -- This can do things like listen to events or host applications
            if self.eventHooks and self.eventHooks.parallel then
                eventHook.execute(self.eventHooks.parallel)
            end
            sleep(blinkFrequency)
        end
    end, function()
        while self.running do
            os.pullEvent("radon_purchase")
            while #transactions > 0 do
                local purchaseData = table.remove(transactions, 1)
                local success, err = pcall(ShopState.handlePurchase, self, purchaseData.transaction, purchaseData.meta, purchaseData.sentMetaname, purchaseData.transactionCurrency)
                if success then
                    -- Success :D
                else
                    refund(purchaseData.transactionCurrency, purchaseData.transaction.from, purchaseData.meta, purchaseData.transaction.value, self.config.lang.refundError, true)
                    if self.eventHooks and self.eventHooks.failedPurchase then
                        eventHook.execute(self.eventHooks.failedPurchase, purchaseData.transaction, purchaseData.transactionCurrency, nil, self.config.lang.refundError)
                    end
                    error(err)
                end
            end
        end
    end, function()
        while self.running do
            local onInventoryRefresh = nil
            if self.eventHooks and self.eventHooks.onInventoryRefresh then
                onInventoryRefresh = self.eventHooks.onInventoryRefresh
            end
            ScanInventory.updateProductInventory(self.products, onInventoryRefresh)
            if self.config.settings.hideUnavailableProducts then
                self.productsChanged = true
            end
            sleep(self.config.settings.pollFrequency)
        end
    end, function()
        while self.running do
            if self.config.settings.categoryCycleFrequency > 0 and os.epoch("utc") > self.lastTouched + (self.config.settings.activityTimeout * 1000) then
                self.selectedCategory = self.selectedCategory + 1
                if self.selectedCategory > self.numCategories then
                    self.selectedCategory = 1
                end
                self.productsChanged = true
            end
            sleep(math.min(1, self.config.settings.categoryCycleFrequency))
        end
    end, function()
        local blinkState = false
        while self.running do
            blinkState = not blinkState
            if self.config.peripherals.blinker then
                redstone.setOutput(self.config.peripherals.blinker, blinkState) 
            end
            if self.eventHooks and self.eventHooks.blink then
                eventHook.execute(self.eventHooks.blink, blinkState)
            end
            sleep(blinkFrequency)
        end
    end, function()
        local x, y, z
        while self.running do
            sleep(shopSyncFrequency)
            if self.config.shopSync and self.config.shopSync.enabled and self.peripherals.shopSyncModem then
                if not x or not y or not z then
                    x, y, z = gps.locate(5)
                end
                local items = {}
                for i = 1, #self.products do
                    local product = self.products[i]
                    local prices = {}
                    local nbt = nil
                    local predicates = nil
                    if not product.bundle and not product.hidden and product.modid then
                        if product.predicates then
                            nbt = nil -- TODO: Can we get an nbt hash?
                            predicates = product.predicates
                        end
                        for j = 1, #self.config.currencies do
                            local currency = self.config.currencies[j]
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

                            local price = product.price / currency.value

                            if product.priceOverrides then
                                for _, override in pairs(product.priceOverrides) do
                                    if override.currency == currency.id then
                                        price = override.price
                                    end
                                end
                            end

                            if price >= 0 then
                                table.insert(prices, {
                                    value = price,
                                    currency = currencyName,
                                    address = address,
                                    requiredMeta = requiredMeta
                                })
                            end
                        end
                        table.insert(items, {
                            prices = prices,
                            item = {
                                name = product.modid,
                                displayName = product.name,
                                nbt = nbt,
                                --predicates = predicates
                            },
                            dynamicPrice = false,
                            stock = product.quantity,
                            madeOnDemand = false,
                        })
                    end
                end
                self.peripherals.shopSyncModem.transmit(shopSyncChannel, os.getComputerID(), {
                    type = "ShopSync",
                    info = {
                        name = self.config.shopSync.name,
                        description = self.config.shopSync.description,
                        owner = self.config.shopSync.owner,
                        computerID = os.getComputerID(),
                        software = {
                            name = "Radon",
                            version = self.version
                        },
                        location = {
                            coordinates = {x, y, z},
                            description = self.config.shopSync.location.description,
                            dimension = self.config.shopSync.location.dimension
                        },
                    },
                    items = items
                })
            end
        end
    end, function()
        while self.running do
            if self.changedCurrencies and self.oldConfig then
                self.changedCurrencies = false
                self.kryptonReady = false
                for i = 1, #self.oldConfig.currencies do
                    local currency = self.oldConfig.currencies[i]
                    if (currency.krypton and currency.krypton.ws) then
                        currency.krypton.ws:disconnect()
                        currency.krypton = nil
                    end
                end
                for i = 1, #self.currencies do
                    local currency = self.currencies[i]
                    if (currency.krypton and currency.krypton.ws) then
                        currency.krypton.ws:disconnect()
                        currency.krypton = nil
                    end
                end
                self:setupKrypton()
                self.kryptonReady = true
                self.oldConfig = nil
            end
            sleep(0.5)
        end
    end, function()
        while self.running do
            if self.kryptonReady then
                parallel.waitForAny(function()
                    while self.kryptonReady do
                        sleep(0.5)
                    end
                end, unpack(self.kryptonListeners))
            end
            sleep(0.5)
        end
    end)
end

return {
    ShopState = ShopState
}