require("modules.rif") -- Initialize colors

return function(t, palette)
    for k, v in pairs(palette) do
        t.setPaletteColor(k, v)
    end
end
