return {
    {
        modid = "minecraft:lapis_lazuli",
        name = "Lapis Lazuli",
        address = "lapis",
        price = 1.0,
        quantity = 999, -- DEBUG ONLY
        priceOverrides = {
            {
                currency = "tenebra",
                price = 1.0
            }
        },
    },
    {
        modid = "minecraft:diamond",
        name = "Diamond",
        address = "dia",
        price = 5.0,
        quantity = 0, -- DEBUG ONLY
        priceOverrides = {
            {
                currency = "tenebra",
                price = 35.0
            }
        },
    },
    {
        modid = "minecraft:gold_ingot",
        name = "Gold Ingot",
        address = "gold",
        price = 5.0,
        quantity = 16, -- DEBUG ONLY
        priceOverrides = {
            {
                currency = "tenebra",
                price = 35.0
            }
        },
    },
    {
        modid = "minecraft:diamond_pickaxe",
        name = "Diamond Pickaxe eff5",
        address = "dpick",
        price = 50.0,
        quantity = 4,
        predicates = {
            enchantments = {
                {
                    fullName = "Efficiency",
                    level = 5
                }
            }
        }
    }
}