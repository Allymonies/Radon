return {
    branding = {
        title = nil,
        subtitle = nil,
    },
    settings = {
        hideUnavailableProducts = false,
        pollFrequency = 30,
        categoryCycleFrequency = -1,
        activityTimeout = 60,
        dropDirection = "forward",
        smallTextKristPayCompatability = true,
        playSounds = true,
        showFooter = true,
        refundInvalidMetaname = true,
    },
    lang = {
        footer = "/pay <item>@%name% <amt>",
        footerNoName = "/pay %addr% <amt> <item>",
        refundRemaining = "Here is the funds remaining after your purchase!",
        refundOutOfStock = "Sorry, that item is out of stock!",
        refundAtLeastOne = "You must purchase at least one of this product!",
        refundInvalidProduct = "You must supply a valid product to purchase!",
        refundNoProduct = "You must supply a product to purchase!",
        refundError = "An error occurred while processing your purchase!",
        refundDenied = "This purchase has been denied"
    },
    theme = {
        formatting = {
            headerAlign = "center",
            subtitleAlign = "center",
            footerAlign = "center",
            footerSize = "auto",
            productNameAlign = "center",
            layout = "auto", -- "auto" automatically picks from "small", "medium", or "large"
            -- based on the size of the screen
            -- "custom" allows you to specify a custom layout file
            --layoutFile = "CardLayout.lua"
        },
        colors = {
            bgColor = colors.lightGray,
            headerBgColor = colors.red,
            headerColor = colors.white,
            subtitleBgColor = colors.red,
            subtitleColor = colors.white,
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
        },
        layouts = {
            ["CardLayout.lua"] = {
                -- Special theming for the card layout
                -- Takes precedence over the above settings
                settings = {
                    showCredits = true
                },
                colors = {
                    creditsColor = colors.lightGray,
                    bgColor = colors.gray,
                    headerColor = colors.lime,
                    headerSuffixColor = colors.lightGray,
                    subheaderBgColor = colors.white,
                    subheaderColor = colors.black,
                    footerBgColor = colors.black,
                    footerColor = colors.white,
                    dividerColor = colors.black,
                    productNameColor = colors.lime,
                    fieldLabelColor = colors.gray,
                    normalQtyColor = colors.black,
                    addressColor = colors.black,
                    priceBgColor = colors.lime,
                    priceColor = colors.white,
                    productBgColors = {
                        colors.lightGray
                    },
                    productBgShadowColors = {
                        colors.black
                    },
                },
                palette = {
                    [colors.black] = 0x111111,
                    [colors.blue] = 0x3366cc,
                    [colors.purple] = 0xb266e5,
                    [colors.green] = 0x57a64e,
                    [colors.brown] = 0x7f664c,
                    [colors.gray] = 0x4c4c4c,
                    [colors.lightGray] = 0x999999,
                    [colors.red] = 0xcc4c4c,
                    [colors.orange] = 0xf2b233,
                    [colors.yellow] = 0xdede6c,
                    [colors.lime] = 0x7fcc19,
                    [colors.cyan] = 0x4c99b2,
                    [colors.magenta] = 0xe57fd8,
                    [colors.pink] = 0xf2b2cc,
                    [colors.lightBlue] = 0x99b2f2,
                    [colors.white] = 0xf0f0f0
                }
            }
        }
    },
    terminalTheme = {
        colors = {
            titleTextColor = colors.white,
            titleBgColor = colors.blue,
            bgColor = colors.black,
            catagoryTextColor = colors.black,
            catagoryBgColor = colors.white,
            activeCatagoryBgColor = colors.lightGray,
            logTextColor = colors.white,
            configEditor = {
                bgColor = colors.lime,
                textColor = colors.black,
                buttonColor = colors.green,
                buttonTextColor = colors.white,
                inactiveButtonColor = colors.gray,
                inactiveButtonTextColor = colors.white,
                scrollbarBgColor = colors.white,
                scrollbarColor = colors.lightGray,
                inputBgColor = colors.white,
                inputTextColor = colors.black,
                errorBgColor = colors.red,
                errorTextColor = colors.white,
                toggleColor = colors.lightGray,
                toggleBgColor = colors.gray,
                toggleOnColor = colors.lime,
                toggleOffColor = colors.red,
                unsavedChangesColor = colors.blue,
                unsavedChangesTextColor = colors.white,
                modalBgColor = colors.white,
                modalTextColor = colors.black,
                modalBorderColor = colors.lightGray,
            },
            productsEditor = {
                bgColor = colors.lightBlue,
                textColor = colors.black,
                buttonColor = colors.blue,
                buttonTextColor = colors.white,
                inactiveButtonColor = colors.gray,
                inactiveButtonTextColor = colors.white,
                scrollbarBgColor = colors.white,
                scrollbarColor = colors.lightGray,
                inputBgColor = colors.white,
                inputTextColor = colors.black,
                errorBgColor = colors.red,
                errorTextColor = colors.white,
                toggleColor = colors.lightGray,
                toggleBgColor = colors.gray,
                toggleOnColor = colors.lime,
                toggleOffColor = colors.red,
                unsavedChangesColor = colors.green,
                unsavedChangesTextColor = colors.white,
                modalBgColor = colors.white,
                modalTextColor = colors.black,
                modalBorderColor = colors.lightGray,
            }
        },
        palette = {
            [colors.black] = 0x111111,
            [colors.blue] = 0x3366cc,
            [colors.purple] = 0xb266e5,
            [colors.green] = 0x57a64e,
            [colors.brown] = 0x7f664c,
            [colors.gray] = 0x4c4c4c,
            [colors.lightGray] = 0x999999,
            [colors.red] = 0xcc4c4c,
            [colors.orange] = 0xf2b233,
            [colors.yellow] = 0xdede6c,
            [colors.lime] = 0x7fcc19,
            [colors.cyan] = 0x4c99b2,
            [colors.magenta] = 0xe57fd8,
            [colors.pink] = 0xf2b2cc,
            [colors.lightBlue] = 0x99b2f2,
            [colors.white] = 0xf0f0f0
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
            -- node = "https://krist.dev/"
            name = nil, -- Your krist name, usually ending in .kst
            pkey = nil, -- Your private key, or password for kristwallet
            pkeyFormat = "raw", -- Currently must be 'raw' or 'kristwallet'
            -- You can get your raw pkey from kristweb or using https://pkey.its-em.ma/
            value = 1.0 -- Default scaling on item prices, can be overridden on a per-item basis
        },
        --[[{
            id = "tenebra", -- if not krist or tenebra, must supply endpoint
            -- node = "https://krist.dev/"
            host = "tttttttttt",
            name = "radon.tst", -- Your krist name, usually ending in .kst
            pkey = nil, -- Your private key, or password for kristwallet
            pkeyFormat = "raw", -- Currently must be 'raw', kwallet support is planned
            -- You can get your raw pkey from kristweb or using https://pkey.its-em.ma/
            value = 0.1 -- Default scaling on item prices, can be overridden on a per-item basis
        },--]]
    },
    peripherals = {
        monitor = nil, -- Monitor to display on, if not specified, will use the first monitor found
        modem = nil, -- Modem for inventories, if not specified, will use the first wired modem found
        speaker = nil, -- Speaker to play sounds on, if not specified, will use the first speaker found
        shopSyncModem = nil, -- Modem for ShopSync, if not specified, will use the first wireless modem found
        blinker = nil, -- Side that a redstone lamp or other redstone device is on
        -- Will be toggled on and off every 3 seconds to indicate that the shop is online
        exchangeChest = nil,
        outputChest = "self", -- Chest peripheral or self
        -- NOTE: Chest dropping is NYI in plethora 1.19, so do not use unless
        -- the output chest can be accessed
    },
    exchange = {
        -- Not yet implemented
        enabled = true,
        node = "https://localhost:8000/"
    }
}
