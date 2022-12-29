local base64 = require("modules.base64")
local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local smolFontEncoded = require("res.smolfont")
local smolFontData = base64.decode(smolFontEncoded)

local smolFontSheet = loadRIF(smolFontData)
local smolFont = createFont(smolFontSheet, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:;<=>?[\\]^_{|}~\128` !\"#$%&'()*+,-./@\164")

return smolFont
