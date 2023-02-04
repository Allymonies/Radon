
local configSchema = {
    branding = {
        title = "string",
        subtitle = "string?",
    },
    settings = {
        hideUnavailableProducts = "boolean",
        pollFrequency = "number",
        categoryCycleFrequency = "number",
        activityTimeout = "number",
        dropDirection = "enum<'forward' | 'up' | 'down' | 'north' | 'south' | 'east' | 'west'>: direction",
        smallTextKristPayCompatability = "boolean",
        playSounds = "boolean",
        showFooter = "boolean",
        refundInvalidMetaname = "boolean",
        refundMissingMetaname = "boolean"
    },
    lang = {
        footer = "string",
        footerNoName = "string?",
        refundRemaining = "string",
        refundOutOfStock = "string",
        refundAtLeastOne = "string",
        refundInvalidProduct = "string",
        refundNoProduct = "string",
        refundError = "string"
    },
    theme = {
        formatting = {
            headerAlign = "enum<'left' | 'center' | 'right'>: alignment",
            subtitleAlign = "enum<'left' | 'center' | 'right'>: alignment",
            footerAlign = "enum<'left' | 'center' | 'right'>: alignment",
            footerSize = "enum<'small' | 'medium' | 'large' | 'auto'>: size",
            productNameAlign = "enum<'left' | 'center' | 'right'>: alignment",
            layout = "enum<'small' | 'medium' | 'large' | 'auto' | 'custom'>: layout",
            layoutFile = "file?"
        },
        colors = {
            bgColor = "color",
            headerBgColor = "color",
            headerColor = "color",
            subtitleBgColor = "color",
            subtitleColor = "color",
            footerBgColor = "color",
            footerColor = "color",
            productBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            outOfStockQtyColor = "color",
            lowQtyColor = "color",
            warningQtyColor = "color",
            normalQtyColor = "color",
            productNameColor = "color",
            outOfStockNameColor = "color",
            priceColor = "color",
            addressColor = "color",
            currencyTextColor = "color",
            currencyBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            catagoryTextColor = "color",
            categoryBgColors = {
                __type = "array",
                __min = 1,
                __entry = "color"
            },
            activeCategoryColor = "color",
        },
        palette = {
            [colors.black] = "number",
            [colors.blue] = "number",
            [colors.purple] = "number",
            [colors.green] = "number",
            [colors.brown] = "number",
            [colors.gray] = "number",
            [colors.lightGray] = "number",
            [colors.red] = "number",
            [colors.orange] = "number",
            [colors.yellow] = "number",
            [colors.lime] = "number",
            [colors.cyan] = "number",
            [colors.magenta] = "number",
            [colors.pink] = "number",
            [colors.lightBlue] = "number",
            [colors.white] = "number"
        }
    },
    terminalTheme = {
        colors = {
            titleTextColor = "color",
            titleBgColor = "color",
            bgColor = "color",
            catagoryTextColor = "color",
            catagoryBgColor = "color",
            activeCatagoryBgColor = "color",
            logTextColor = "color",
            configEditor = {
                bgColor = "color",
                textColor = "color",
                buttonColor = "color",
                buttonTextColor = "color",
                inactiveButtonColor = "color",
                inactiveButtonTextColor = "color",
                scrollbarBgColor = "color",
                scrollbarColor = "color",
                inputBgColor = "color",
                inputTextColor = "color",
                errorBgColor = "color",
                errorTextColor = "color",
                toggleColor = "color",
                toggleBgColor = "color",
                toggleOnColor = "color",
                toggleOffColor = "color",
                unsavedChangesColor = "color",
                unsavedChangesTextColor = "color",
                modalBgColor = "color",
                modalTextColor = "color",
                modalBorderColor = "color",
            },
            productsEditor = {
                bgColor = "color",
                textColor = "color",
                buttonColor = "color",
                buttonTextColor = "color",
                inactiveButtonColor = "color",
                inactiveButtonTextColor = "color",
                scrollbarBgColor = "color",
                scrollbarColor = "color",
                inputBgColor = "color",
                inputTextColor = "color",
                errorBgColor = "color",
                errorTextColor = "color",
                toggleColor = "color",
                toggleBgColor = "color",
                toggleOnColor = "color",
                toggleOffColor = "color",
                unsavedChangesColor = "color",
                unsavedChangesTextColor = "color",
                modalBgColor = "color",
                modalTextColor = "color",
                modalBorderColor = "color",
            }
        },
        palette = {
            [colors.black] = "number",
            [colors.blue] = "number",
            [colors.purple] = "number",
            [colors.green] = "number",
            [colors.brown] = "number",
            [colors.gray] = "number",
            [colors.lightGray] = "number",
            [colors.red] = "number",
            [colors.orange] = "number",
            [colors.yellow] = "number",
            [colors.lime] = "number",
            [colors.cyan] = "number",
            [colors.magenta] = "number",
            [colors.pink] = "number",
            [colors.lightBlue] = "number",
            [colors.white] = "number"
        }
    },
    sounds = {
        button = "sound",
        purchase = "sound",
    },
    currencies = {
        __type = "array",
        __label = "id",
        __min = 1,
        __entry = {
            id = "string",
            node = "string?",
            name = "regex<^[a-z0-9]{1,64}(\\.[a-z0-9]{1,64})?$>?: name",
            pkey = "string",
            pkeyFormat = "enum<'raw' | 'kristwallet'>: pkey format",
            value = "number?"
        }
    },
    peripherals = {
        monitor = "string?",
        speaker = "speaker?",
        modem = "modem?",
        shopSyncModem = "modem?",
        blinker = "enum<'left' | 'right' | 'front' | 'back' | 'top' | 'bottom'>?: side",
        exchangeChest = "chest?",
        outputChest = "chest",
    },
    -- shopSync = {
    --     enabled = "boolean?",
    --     name = "string?",
    --     description = "string?",
    --     owner = "string?",
    --     location = {
    --         coordinates = {
    --             __type = "array?",
    --             __min = 3,
    --             __max = 3,
    --             __entry = "number"
    --         },
    --         description = "string?",
    --         dimension = "enum<'overworld' | 'nether' | 'end'>?: dimension"
    --     }
    -- },
    exchange = {
        enabled = "boolean",
        node = "string"
    }
}

local productsSchema = {
    __type = "array",
    __label = "name",
    __entry = {
        modid = "string?",
        productId = "string?",
        name = "string",
        address = "string",
        category = "string?",
        hidden = "boolean?",
        maxQuantity = "number?",
        price = "number",
        priceOverrides = {
            __type = "array?",
            __label = "currency",
            __entry = {
                currency = "string",
                price = "number"
            }
        },
        bundle = {
            __type = "array?",
            __label = "product",
            __entry = {
                product = "string",
                quantity = "number"
            }
        },
        predicate = "table?"
    }
}

local hooksSchema = {
    start = "function?",
    prePurchase = "function?",
    purchase = "function?",
    failedPurchase = "function?",
    programError = "function?",
    blink = "function?",
    configSaved = "function?",
    productsSaved = "function?",
}

local soundSchema = {
    name = "string",
    volume = "number",
    pitch = "number"
}

return {
    configSchema = configSchema,
    productsSchema = productsSchema,
    hooksSchema = hooksSchema,
    soundSchema = soundSchema
}