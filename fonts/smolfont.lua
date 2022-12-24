local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local smolFontSheet = loadRIF("res/smolfont.rif")
local smolFont = createFont(smolFontSheet, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:;<=>?[\\]^_{|}~\128` !\"#$%&'()*+,-./@")

return smolFont
