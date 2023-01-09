return {
    start = nil, -- function(version, config, products)
    prePurchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency) returns continueTransaction, error, errorMessage
    purchase = nil, -- function(product, amount, refundAmount, transaction, transactionCurrency)
    failedPurchase = nil, -- function(transaction, transactionCurrency, product, errorMessage)
    programError = nil, -- function(err)
    blink = nil, -- function(blinkState) called every 3 seconds while shop is running
    configSaved = nil, -- function(config) called when config is edited (replaced)
    productsSaved = nil, -- function(products) called when products object is edited (replaced)
}