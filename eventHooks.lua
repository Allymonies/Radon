return {
    start = nil, -- function(version, config, products)
    preProduct = nil, -- function(transaction, transactionCurrency, meta, productAddress, products) returns product
    -- If product is nil, product will be selected by the shop,
    -- If product is false, customer will be refunded for no product found.
    prePurchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency) returns continueTransaction, error, errorMessage
    purchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency)
    failedPurchase = nil, -- function(transaction, transactionCurrency, product, errorMessage)
    programError = nil, -- function(err)
    blink = nil, -- function(blinkState) called every 3 seconds while shop is running
    configSaved = nil, -- function(config) called when config is edited (replaced)
    productsSaved = nil, -- function(products) called when products object is edited (replaced)
    onInventoryRefresh = nil, -- function(products, items) called when inventory is refreshed, product quantity can be set through products table
}