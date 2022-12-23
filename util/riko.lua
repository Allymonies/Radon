require("modules.rif") -- Initialize colors

return function(t)
    local rikoPalette = {
        {24,   24,   24}, -- black
        {29,   43,   82}, -- blue
        {126,  37,   83}, -- purple
        {0,    134,  81}, -- green
        {171,  81,   54}, -- brown
        {86,   86,   86}, -- gray
        {157,  157,  157}, -- lightGray
        {255,  0,    76}, -- red
        {255,  163,  0}, -- orange
        {255,  240,  35}, -- yellow
        {0,    231*0.7,  85*0.7}, -- lime
        {41,   173,  255}, -- cyan
        {130,  118,  156}, -- magenta
        {255,  119,  169}, -- pink
        {0,    231*0.5,  85*0.5}, -- darkGreen
        {236,  236,  236}, -- white
    }

    for i = 1, #rikoPalette do
        for j = 1, 3 do
            rikoPalette[i][j] = rikoPalette[i][j] / 255
        end

        t.setPaletteColor(2^(i - 1), unpack(rikoPalette[i]))
    end
end
