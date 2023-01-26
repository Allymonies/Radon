return {
    {
        modid = "minecraft:stick",
        name = "Stick",
        address = "stick",
        price = 0.1
    },
    {
        modid = "minecraft:lapis_block",
        productId = "lapis_block",
        name = "Lapis Block",
        address = "lapis",
        category = "ore",
        price = 9.0,
        priceOverrides = {
            {
                currency = "krist",
                price = 18.0
            }
        },
    },
    {
        name = "Lapis on a stick",
        address = "ls",
        price = 9.0,
        maxQuantity = 1,
        bundle = {
            {
                product = "stick",
                quantity = 1
            },
            {
                product = "lapis_block",
                quantity = 1
            }
        }
    },
    {
        modid = "minecraft:diamond_pickaxe",
        name = "Diamond Pickaxe eff5",
        address = "dpick",
        category = "tool",
        price = 50.0,
        predicates = {
            enchantments = {
                {
                    fullName = "Efficiency V"
                }
            }
        }
    },
    {
        modid = "minecraft:barrier",
        name = "Secret item",
        address = "secret",
        hidden = true,
        price = 1.0
    }
}