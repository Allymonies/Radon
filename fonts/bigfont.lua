local base64 = require("modules.base64")
local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local cFont = require("res.cfont")
local bigFontData = base64.decode(cFont)

local bigFontSheet = loadRIF(bigFontData)
local bigFont = createFont(bigFontSheet, " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-,.\164!:\6@'<>")

return bigFont
