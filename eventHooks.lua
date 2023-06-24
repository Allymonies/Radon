return {
    start = nil, -- function(version, config, products, shopState)
    preProduct = nil, -- function(transaction, transactionCurrency, meta, productAddress, products) returns product, errored, errorMessage
    -- If product is nil, product will be selected by the shop,
    -- If product is false, customer will be refunded for no product found.
    -- If product is false and errored is true, customer will be refunded with error message.
    preStockCheck = nil, -- function(transaction, productsPurchased, products)
    prePurchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency) returns continueTransaction, errored, errorMessage, invisible
    purchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency)
    failedPurchase = nil, -- function(transaction, transactionCurrency, product, errorMessage)
    programError = nil, -- function(err)
    blink = nil, -- function(blinkState) called every 3 seconds while shop is running
    configSaved = nil, -- function(config) called when config is edited (replaced)
    productsSaved = nil, -- function(products) called when products object is edited (replaced)
    onInventoryRefresh = nil, -- function(products, items) called when inventory is refreshed, product quantity can be set through products table
    onProductSelected = nil, -- function(product, currency) called when product is clicked on the shop screen
    parallel = nil, -- function() called in parallel constantly. Allowed to be blocking for usage in creating parallel apps.
}