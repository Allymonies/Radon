local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local bigFontSheet = loadRIF("res.cfont")
local bigFont = createFont(bigFontSheet, " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-,.\164!:\6@'<>")

return bigFont
