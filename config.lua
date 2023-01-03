return {
    branding = {
        title = "Radon Shop"
    },
    settings = {
        hideUnavailableProducts = false,
        pollFrequency = 30,
        categoryCycleFrequency = -1,
        activityTimeout = 60,
        dropDirection = "forward",
        smallTextKristPayCompatability = true,
        playSounds = true,
    },
    lang = {
        footer = "/pay <item>@%name% <amt>",
        footerNoName = "/pay %addr% <amt> <item>",
        refundRemaining = "Here is the funds remaining after your purchase!",
        refundOutofStock = "Sorry, that item is out of stock!",
        refundAtLeastOne = "You must purchase at least one of this product!",
        refundInvalidProduct = "You must supply a valid product to purchase!",
        refundNoProduct = "You must supply a product to purchase!",
        refundError = "An error occurred while processing your purchase!"
    },
    theme = {
        formatting = {
            headerAlign = "center",
            footerAlign = "center",
            productNameAlign = "center",
            productTextSize = "auto"
        },
        colors = {
            bgColor = colors.lightGray,
            headerBgColor = colors.red,
            headerColor = colors.white,
            footerBgColor = colors.red,
            footerColor = colors.white,
            productBgColors = {
                colors.blue,
            },
            outOfStockQtyColor = colors.red,
            lowQtyColor = colors.orange,
            warningQtyColor = colors.yellow,
            normalQtyColor = colors.white,
            productNameColor = colors.white,
            outOfStockNameColor = colors.lightGray,
            priceColor = colors.lime,
            addressColor = colors.white,
            currencyTextColor = colors.white,
            currencyBgColors = {
                colors.green,
                colors.pink,
                colors.lightBlue,
                colors.yellow,
            },
            catagoryTextColor = colors.white,
            categoryBgColors = {
                colors.pink,
                colors.orange,
                colors.lime,
                colors.lightBlue,
            },
            activeCategoryColor = colors.black,
        },
        palette = {
            [colors.black] = 0x181818,
            [colors.blue] = 0x182B52,
            [colors.purple] = 0x7E2553,
            [colors.green] = 0x008751,
            [colors.brown] = 0xAB5136,
            [colors.gray] = 0x565656,
            [colors.lightGray] = 0x9D9D9D,
            [colors.red] = 0xFF004C,
            [colors.orange] = 0xFFA300,
            [colors.yellow] = 0xFFEC23,
            [colors.lime] = 0x00A23C,
            [colors.cyan] = 0x29ADFF,
            [colors.magenta] = 0x82769C,
            [colors.pink] = 0xFF77A9,
            [colors.lightBlue] = 0x3D7EDB,
            [colors.white] = 0xECECEC
        }
    },
    sounds = {
        button = {
            name = "minecraft:block.note_block.hat",
            volume = 0.5,
            pitch = 1.1
        },
        purchase = {
            name = "minecraft:block.note_block.pling",
            volume = 0.5,
            pitch = 2
        },
    },
    currencies = {
        {
            id = "krist", -- if not krist or tenebra, must supply endpoint
            -- node = "https://krist.dev"
            host = "ksbangelco",
            name = "radon.kst",
            pkey = "",
            pkeyFormat = "raw", -- Currently must be 'raw', kwallet support is planned
            -- You can get your raw pkey from kristweb or using https://pkey.its-em.ma/
            value = 1.0 -- Default scaling on item prices, can be overridden on a per-item basis
        },
        {
            id = "tenebra", -- if not krist or tenebra, must supply endpoint
            -- node = "https://krist.dev"
            host = "tttttttttt",
            name = "radon.tst",
            pkey = "",
            pkeyFormat = "raw", -- Currently must be 'raw', kwallet support is planned
            -- You can get your raw pkey from kristweb or using https://pkey.its-em.ma/
            value = 0.1 -- Default scaling on item prices, can be overridden on a per-item basis
        },
    },
    peripherals = {
        monitor = nil, -- Monitor to display on, if not specified, will use the first monitor found
        modem = nil, -- Modem for inventories, if not specified, will use the first wired modem found
        speaker = nil, -- Speaker to play sounds on, if not specified, will use the first speaker found
        shopSyncModem = nil, -- Modem for ShopSync, if not specified, will use the first wireless modem found
        exchangeChest = nil,
        outputChest = "self", -- Chest peripheral or self
        -- NOTE: Chest dropping is NYI in plethora 1.19, so do not use unless
        -- the output chest can be accessed
    },
    shopSync = {
        enabled = false,
        name = "Radon Shop",
        description = "Shop for selling valuable items",
        owner = "Allymonies",
        location = {
            coordinates = { 227, 70, -175 },
            description = "East of spawn, just passed the ISA",
            dimension = "overworld"
        }
    },
    exchange = {
        -- Not yet implemented
        enabled = true,
        node = "https://localhost:8000/"
    }
}
