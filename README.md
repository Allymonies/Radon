# Radon

A next-generation highly-configurable Krist shop with categories, nameless shops, and multi-currency support.

For any support needs or feature requests, contact Allymonies. Radon is in active development!

# Installation

While you can install Radon with the Howlfile, or just copying all the files to the computer, it is recommended to use the installer, `pastebin run TPG238zDDP` (SCPaste https://p.sc3.io/TPG238zDDP). This will download the required files, `radon.lua`, `config.lua`, and `products.lua`.

# Setup

Attach a wired modem to your turtle. Then add a chest on that wired network (it must be connected to a wired modem on that network). Make sure a monitor is next to the turtle.

Either use the ingame GUI editor on an advanced computer/turtle, or edit `config.lua` and change `branding.title` to the name of your shop you want shown in the header.

Next change `currencies.name`, and `currencies.pkey` for the krist currency to your krist address, the krist name you will be using (or nil), and your krist address' private key, respectively. If you are using a kristwallet format password, change `currencies.pkeyFormat` to `"kristwallet"`. You can then either remove/comment out the tenebra currency, or fill in your respective details for that.

**WARNING**: If you do not use a name for your shop, any transaction that doesn't purchase an item to your address will be refunded. Do not run the shop on your personal address you will be receiving krist to if you are not using a name.

Finally, set up some products in `products.lua`. Some example products are given. Required fields are:
- `modid`: The item id of the item, with the namespace or mod. Example: `"plethora:neural_interface"`
- `name`: The description of the item shown to the user. Example: `"Neural Interface"`
- `address`: The metaname or required meta to identify the item being purchased. Example: `"ni"`
- `price`: The price of the item. The price in a given currency will be calculated by dividing this price by the value of the currency used. Example: `50`

Optionally, you can supply `category`, `priceOverrides`, and `predicates`. For more information on these, see the example `products.lua` file.

If your shop has multiple categories or currencies and you're playing on SwitchCraft, you'll want to `/monitortrust .public` on your plot so that players can right click on your monitor to change categories and currencies.

# Advanced Settings

Radon is designed to be highly configurable. Look through `config.lua` for what you may want to change to suit your needs. There are a few tables or categories within `config.lua`:
- `settings` controls general settings for behavior of the shop.
- `lang` controls strings used throughout the program, such as the footer or refund messages.
- `theme.formatting` controls the formatting of elements, mostly alignment
- `theme.colors` controls the colors of every element. Alternating row background colors can be accomplished by adding more entries to the `theme.colors.productBgColors` table
- `theme.palette` controls the color palette used for the shop. Use this to fine tune the colors you want
- `sounds` controls the sounds that get played in various situations
- `currencies` lists the currencies accepted by the shop. If you don't have a name on a given currency, you can leave it out or set it to nil to use nameless mode.
- `peripherals` defines peripherals to be used for the shop. Most of these can be left at nil to be automatically set. `peripherals.outputChest` should generally be left on `"self"` as setting it to a chest will cause items to be inserted into the chest without dropping them, as chest dropping is not yet implemented in plethora 1.19

For custom logic, you can define functions in `eventHooks.lua`, hooks define event hook functions to be executed when their respective event happens. Use this when you need additional functional (such as posting to webhooks) when the shop starts, a purchase happens or fails, an error occurs, and other events.

# Layouts

Radon has support for custom layouts in lua. While shops like Xenon are easier to configure, Radon offers a lot of flexibility, you get to write the code that renders the layout.


An example layout is shipped with radon, `CardLayout.lua`. You can enable it by setting `config.theme.formatting.layout` to `"custom"` and `config.theme.formatting.layoutFile` to `"CardLayout.lua"`. If you'd like to know more about defining custom layouts, look at `CardLayout.lua`. Many useful components you may want to use are in the `components` folder of the source code.