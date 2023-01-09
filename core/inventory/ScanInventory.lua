local itemCache = {}

local partialObjectMatches
local function partialArrayMatches(partialArray, array)
    for i = 1, #partialArray do
        local found = false
        for j = 1, #array do
            if type(array[j]) == "table" then
                if partialObjectMatches(partialArray[i], array[j]) then
                    found = true
                    break
                end
            elseif partialArray[i] == array[j] then
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    return true
end

function partialObjectMatches(partialObject, object)
    if type(object) ~= "table" then
        return false
    end
    if object[1] then
        return partialArrayMatches(partialObject, object)
    end
    for k,v in pairs(partialObject) do
        if type(v) == "table" then
            if not partialObjectMatches(v, object[k]) then
                return false
            end
        elseif object[k] == nil or object[k] ~= v then
            return false
        end
    end
    return true
end

local function predicateMatches(predicates, item)
    local meta = peripheral.call(item.inventory, "getItemDetail", item.slot)
    item.cachedMeta = meta
    return partialObjectMatches(predicates, meta)
end

local function findMatchingProducts(products, item)
    local matchingProducts = {}
    for i = 1, #products do
        local product = products[i]
        if item.name == product.modid then
            if not product.predicates or predicateMatches(product.predicates, item) then
                table.insert(matchingProducts, product)
            end
        end
    end
    return matchingProducts
end

local function getInventories()
    peripherals = peripheral.getNames()
    inventories = {}
    for i = 1, #peripherals do
        name = peripherals[i]
        local methods = peripheral.getMethods(name)
        local hasListItems = false
        local hasPushItems = false
        if methods then
            for j = 1, #methods do
                if methods[j] == "list" then
                    hasListItems = true
                end
                if methods[j] == "pushItems" then
                    hasPushItems = true
                end
                if hasListItems and hasPushItems then
                    break
                end
            end
        end
        if hasListItems and hasPushItems then
            table.insert(inventories, peripheral.wrap(name))
        end
    end
    return inventories
end

local function getInventoryItems(inventory, products)
    local inventoryName = peripheral.getName(inventory)
    local items = {}
    local slots = inventory.list()
    for slot, item in pairs(slots) do
        if item then
            item.inventory = inventoryName
            item.slot = slot
            table.insert(items, item)
            local matchingProducts = findMatchingProducts(products, item)
            for j = 1, #matchingProducts do
                local product = matchingProducts[j]
                if not product.newQty then
                    product.newQty = 0
                end
                product.newQty = product.newQty + item.count
            end
        end
    end
    return items
end

local function getAllInventoryItems(inventories, products)
    local items = {}
    local inventoryThreads = {}
    for i = 1, #inventories do
        local inventory = inventories[i]
        table.insert(inventoryThreads, function()
            local inventoryItems = getInventoryItems(inventory, products)
            for j = 1, #inventoryItems do
                table.insert(items, inventoryItems[j])
            end
        end)
    end
    parallel.waitForAll(unpack(inventoryThreads))
    return items
end

local function updateProductInventory(products)
    for i = 1, #products do
        products[i].newQty = 0
    end
    local inventories = getInventories()
    local items = getAllInventoryItems(inventories, products)
    itemCache = items
    for i = 1, #products do
        local product = products[i]
        product.quantity = product.newQty
        product.newQty = nil
    end
end

local function getItemCache()
    return itemCache
end

local function findProductItemsFrom(product, quantity, items, cached)
    local sources = {}
    local remaining = quantity
    for i = 1, #items do
        local item = items[i]
        local inventory = item.inventory
        local slot = item.slot
        if item.name == product.modid and (not cached or not product.predicates or (item.cachedMeta and partialObjectMatches(product.predicates, item.cachedMeta))) then
            if cached or product.predicates then
                item = peripheral.call(inventory, "getItemDetail", slot)
            end
            if item then
                if item.name ~= product.modid or (product.predicates and not partialObjectMatches(product.predicates, item)) then
                    item = nil
                else
                    item.inventory = inventory
                    item.slot = slot
                end
            end
            if item and item.count > 0 then
                local amount = math.min(item.count, remaining)
                table.insert(sources, {
                    inventory = item.inventory,
                    slot = item.slot,
                    amount = amount
                })
                remaining = remaining - amount
            end
        end
        if remaining <= 0 then
            break
        end
    end
    return sources, quantity - remaining
end

local function findProductItems(products, product, quantity)
    local sources = nil
    local amount = 0
    local items = getItemCache()
    sources, amount = findProductItemsFrom(product, quantity, items, true)
    if amount == 0 then
        updateProductInventory(products)
        items = getItemCache()
        sources, amount = findProductItemsFrom(product, quantity, items)
    end
    return sources, amount
end

return {
    updateProductInventory = updateProductInventory,
    getItemCache = getItemCache,
    findProductItems = findProductItems
}