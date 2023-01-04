local function executeHook(func, ...)
    local args = {...}
    local ret = {pcall(func, unpack(args))}
    if not ret[1] then
        print("Error in hook: " .. ret[2])
        return
    end
    table.remove(ret, 1)
    return unpack(ret)
end

return {
    execute = executeHook
}