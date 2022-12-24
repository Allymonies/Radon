local itemCache = {}

local function getInventories()
    peripherals = peripheral.getNames()
    inventories = {}
    for i = 1, #peripherals do
        name = peripherals[i]
        local methods = peripheral.getMethods(name)
        local hasListItems = false
        local hasPushItems = false
        if methods then
            for i = 1, #methods do
                if methods[i] == "list" then
                    hasListItems = true
                end
                if methods[i] == "pushItems" then
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

local function getInventoryItems(inventory)
    local inventoryName = peripheral.getName(inventory)
    local items = {}
    local slots = inventory.list()
    for slot, item in pairs(slots) do
        if item then
            item.inventory = inventoryName
            item.slot = slot
            table.insert(items, item)
        end
    end
    return items
end

local function getAllInventoryItems(inventories)
    local items = {}
    for i = 1, #inventories do
        local inventory = inventories[i]
        local inventoryItems = getInventoryItems(inventory)
        for i = 1, #inventoryItems do
            table.insert(items, inventoryItems[i])
        end
    end
    return items
end

local partialObjectMatches
local function partialArrayMatches(partialArray, array)
    for i = 1, #partialArray do
        local found = false
        for i = 1, #array do
            if type(array[i]) == "table" then
                if partialObjectMatches(partialArray[i], array[i]) then
                    found = true
                    break
                end
            elseif partialArray[i] == array[i] then
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
    local meta = peripheral.call(item.inventory, "getItemMeta", item.slot)
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

local function updateProductInventory(products)
    for i = 1, #products do
        products[i].newQty = 0
    end
    local inventories = getInventories()
    local items = getAllInventoryItems(inventories)
    itemCache = items
    for i = 1, #items do
        local item = items[i]
        local matchingProducts = findMatchingProducts(products, item)
        for i = 1, #matchingProducts do
            local product = matchingProducts[i]
            product.newQty = product.newQty + item.count
        end
    end
    for i = 1, #products do
        local product = products[i]
        product.quantity = product.newQty
        product.newQty = nil
    end
end

local function getItemCache()
    return itemCache
end

return {
    updateProductInventory = updateProductInventory,
    getItemCache = getItemCache
}