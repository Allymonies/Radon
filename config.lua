return {
    branding = {
        title = "Radon Shop"
    },
    theme = {
        bgColor = colors.gray,
        headerBgColor = colors.red,
        headerColor = colors.white
    },
    currencies = {
        {
            id = "krist", -- if not krist or tenebra, must supply endpoint
            -- endpoint = "https://krist.dev"
            host = "kristallie",
            name = "radon.kst",
            pkey = "",
            pkeyFormat = "raw", -- Either 'raw' or 'kristwallet', defaults to 'raw'
            -- NOTE: It is not recommended to use kwallet, the best practice is to convert your pkey (using
            -- kwallet format) to raw pkey yourself first, and then use that here. Thus improving security.
            value = 1.0 -- Default scaling on item prices, can be overridden on a per-item basis
        },
        {
            id = "tenebra", -- if not krist or tenebra, must supply endpoint
            -- endpoint = "https://krist.dev"
            host = "tttttttttt",
            name = "radon.tst",
            pkey = "",
            pkeyFormat = "raw", -- Either 'raw' or 'kristwallet', defaults to 'raw'
            -- NOTE: It is not recommended to use kwallet, the best practice is to convert your pkey (using
            -- kwallet format) to raw pkey yourself first, and then use that here. Thus improving security.
            value = 0.1 -- Default scaling on item prices, can be overridden on a per-item basis
        },
    },
    peripherals = {
        monitor = nil,
        exchangeChest = nil,
        outputChest = nil,
    }
}