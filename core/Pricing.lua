local function getProductPrice(product, currency)
    local price = product.price / currency.value
    if product.priceOverrides then
        for i = 1, #product.priceOverrides do
            local override = product.priceOverrides[i]
            if override.currency == currency.id then
                price = override.price
                break
            end
        end
    end
    return price
end

return {
    getProductPrice = getProductPrice
}