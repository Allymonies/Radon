local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local smolFontSheet = loadRIF("res.smolfont")
local smolFont = createFont(smolFontSheet, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:;<=>?[\\]^_{|}~\128` !\"#$%&'()*+,-./@\164")

return smolFont
