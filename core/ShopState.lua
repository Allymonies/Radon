local Krypton = require("Krypton")
local ScanInventory = require("core.inventory.ScanInventory")
local Pricing = require("core.Pricing")

---@class ShopState
---@field running boolean
local ShopState = {}
local ShopState_mt = { __index = ShopState }

function ShopState.new(config, products)
    local self = setmetatable({}, ShopState_mt)

    self.running = false
    self.config = config
    self.products = products
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
    for metaEntry in transactionMeta:gmatch("([^;]+)") do
        if metaEntry:find("=") then
            local key, value = metaEntry:match("([^=]+)=([^=]+)")
            meta[key] = value
        else
            meta[metaEntry] = true
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
        if product.address:lower() == sentMetaname:lower() then
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
                print("Purchased " .. available .. " of " .. purchasedProduct.name .. " for " .. transaction.from .. " for " .. transaction.value .. " " .. transactionCurrency.name .. " (refund " .. refundAmount .. ")")
                if available > 0 then
                    for _, productSource in ipairs(productSources) do
                        if isRelative(state.config.peripherals.outputChest) then
                            -- Move to self first
                            if not turtle then
                                error("Relative output but not a turtle!")
                            end
                            peripheral.call(productSource.inventory, "pushItems", state.config.peripherals.self, productSource.slot, productSource.amount, 1)
                            peripheral.call(state.config.peripherals.outputChest, "pullItems", state.config.peripherals.selfRelativeOutput, productSource.slot, productSource.amount, 1)
                            peripheral.call(state.config.peripherals.outputChest, "drop", 1, productSource.amount, state.config.settings.dropDirection)
                        elseif state.config.peripherals.outputChest == "self" then
                            if not turtle then
                                error("Self output but not a turtle!")
                            end
                            peripheral.call(productSource.inventory, "pushItems", state.config.peripherals.self, productSource.slot, productSource.amount, 1)
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
                            peripheral.call(state.config.peripherals.outputChest, "drop", 1, productSource.amount, state.config.settings.dropDirection)
                        end
                    end
                    purchasedProduct.quantity = purchasedProduct.quantity - available
                    if refundAmount > 0 then
                        refund(transactionCurrency, transaction.from, meta, refundAmount, "Here is the funds remaining after your purchase!")
                    end
                else
                    refund(transactionCurrency, transaction.from, meta, transaction.value, "Sorry, that item is out of stock!")
                end
            else
                refund(transactionCurrency, transaction.from, meta, transaction.value, "Sorry, that item is out of stock!")
            end
        else
            refund(transactionCurrency, transaction.from, meta, transaction.value, "You must purchase at least one of this product!", true)
        end
    else
        refund(transactionCurrency, transaction.from, meta, transaction.value, "Must supply a valid product to purchase!", true)
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
        table.insert(kryptonListeners, function() kryptonWs:listen() end)
    end
    parallel.waitForAny(function()
        while true do
            local event, transactionEvent = os.pullEvent("transaction")
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
                if sentName and transactionCurrency.name:find(".") then
                    sentName = sentName .. "." .. nameSuffix
                end
                if sentName and sentName:lower() == transactionCurrency.name:lower() then
                    local meta = parseMeta(transaction.metadata)
                    if sentMetaname then
                        success, err = pcall(handlePurchase, transaction, meta, sentMetaname, transactionCurrency, transactionCurrency, state)
                        if success then
                            -- Success :D
                        else
                            refund(transactionCurrency, transaction.from, meta, transaction.value, "An error occurred while processing your purchase!", true)
                            error(err)
                        end
                    else
                        refund(transactionCurrency, transaction.from, meta, transaction.value, "Must supply a product to purchase!", true)
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
    end, unpack(kryptonListeners))
end

return {
    ShopState = ShopState,
    runShop = runShop,
}