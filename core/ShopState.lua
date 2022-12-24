local Krypton = require("Krypton")

---@class ShopState
---@field running boolean
local ShopState = {}
local ShopState_mt = { __index = ShopState }

function ShopState.new(config, products)
    local self = setmetatable({}, ShopState_mt)

    self.running = false
    self.config = config
    self.products = products

    return self
end

local function waitForAnimation(uid)
    coroutine.yield("animationFinished", uid)
end

-- Anytime the shop state is resumed, animation should be finished instantly. (call animation finish hooks)
---@param state ShopState
local function runShop(state)
    -- Shop is starting
    state.running = true
    state.currencies = {}
    local kryptonListeners = {}
    for _, currency in ipairs(state.config.currencies) do
        local node = currency.node
        if not node and currency.id == "krist" then
            node = "https://krist.dev/"
        elseif not node and currency.id == "tenebra" then
            node = "https://tenebra.lil.gay/"
        end
        currency.krypton = Krypton.new({
            privateKey = currency.privateKey,
            node = node,
            id = currency.id,
        })
        table.insert(state.currencies, currency)
        local kryptonWs = currency.krypton:connect()
        kryptonWs:subscribe("transactions")
        table.insert(kryptonListeners, function() kryptonWs:listen() end)
    end
    parallel.waitForAny(unpack(kryptonListeners), function()
        while true do
            local event, transaction = os.pullEvent("transaction")
            --print("Received transaction on " .. transaction.source)
        end
    end)
end

return {
    ShopState = ShopState,
    runShop = runShop,
}