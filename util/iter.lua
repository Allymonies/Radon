-- Iterator for list
local function list(xs)
    local i = 0
    return function()
        i = i + 1
        return xs[i]
    end
end

return {
    list = list,
}
