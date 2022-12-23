return {
    {
        modid = "minecraft:lapis_lazuli",
        name = "Lapis Lazuli",
        address = "lapis",
        price = 1.0,
        priceOverrides = {
            {
                currency = "tenebra",
                price = 1.0
            }
        },
    },
    {
        modid = "minecraft:diamond_pickaxe",
        name = "Diamond Pickaxe eff5",
        address = "dpick",
        price = 50.0,
        predicates = {
            enchantments = {
                {
                    fullName = "Efficiency",
                    level = 4
                }
            }
        }
    }
}