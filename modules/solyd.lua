--[[
MIT License

Copyright (c) 2022 emmachase

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local _ = require("util.score")

local Solyd = {} -- like lyqyd but not

local __hook
local function getKey()
    local key = __hook.__volatile.key
    if key == nil then
        key = 1
        __hook.__volatile.key = 2
    else
        __hook.__volatile.key = key + 1
    end

    return key
end

---Helper definition for the lazy variant of useState, the type system isn't stronk enough otherwise
---@alias UseStateFn<T> fun(initial: fun(): T): T, fun(newValue: T): T
---@alias UseState<T> fun(initial: T): T, fun(newValue: T): T

local setChange = false

---Use State as a hook, sets the initial value if it is not set.
---@generic T
---@param initial T
---@return T, fun(value: T): T
function Solyd.useState(initial)
    local key = getKey()

    local state = __hook[key]
    if state == nil then
        state = { value = type(initial) == "function" and initial() or initial }
        __hook[key] = state
    end

    state.dirty = false

    local function setState(newState)
        state.value = newState
        state.dirty = true
        setChange = true
        return newState
    end

    return state.value, setState
end

---Returns returns a mutable ref object whose .value property is initialized to the passed argument {initial}.
---The returned object will persist for the full lifetime of the component.
---@generic T
---@param initial fun(): T
---@return { value: T }
function Solyd.useRef(initial)
    local key = getKey()

    local ref = __hook[key]
    if ref == nil then
        ref = { value = initial() }
        __hook[key] = ref
    end

    return ref
end

---Pass a “create” function and an array of dependencies. useMemo will only recompute the memoized 
---value when one of the dependencies has changed. This optimization helps to avoid expensive 
---calculations on every render.
---@generic T
---@param fun fun(): T
---@param deps any[]?
---@return T
function Solyd.useMemo(fun, deps)
    local key = getKey()

    local memo = __hook[key]
    if memo == nil then
        memo = { value = fun() }
        __hook[key] = memo
    end

    if memo.deps == nil then
        memo.deps = deps
    else
        for i, v in ipairs(deps) do
            if v ~= memo.deps[i] then
                memo.value = fun()
                memo.deps = deps
                break
            end
        end
    end

    return memo.value
end

function Solyd.useCallback(fun, deps)
    return Solyd.useMemo(function() return fun end, deps)
end

---Accepts a function that contains imperative, possibly effectful code.
---The function passed to useEffect may return a clean-up function
---@param fun fun(): fun()?
---@param deps any[]?
function Solyd.useEffect(fun, deps)
    local key = getKey()

    local memo = __hook[key]
    if memo == nil then
        memo = { unmount = fun() }
        __hook[key] = memo
    end

    if memo.deps == nil then
        memo.deps = deps
    else
        for i, v in ipairs(deps) do
            if v ~= memo.deps[i] then
                memo.unmount()
                memo.deps = deps
                memo.unmount = fun()

                break
            end
        end
    end
end

---Get a value from the component context using the given key, returns nil if the key is not found.
---@generic T
---@param key any
---@return T?
function Solyd.useContext(key)
    local parentHookCtx = __hook.__volatile.parentContext
    while parentHookCtx do
        if parentHookCtx.context and parentHookCtx.context[key] then
            parentHookCtx.contextConsumers[key] = parentHookCtx.contextConsumers[key] or {}
            for i = 1, #parentHookCtx.contextConsumers[key] do
                if parentHookCtx.contextConsumers[key][i] == __hook then
                    return parentHookCtx.context[key]
                end
            end

            table.insert(parentHookCtx.contextConsumers[key], __hook)
            __hook.contextSubscriptions = __hook.contextSubscriptions or {}
            __hook.contextSubscriptions[key] = parentHookCtx.contextConsumers
            return parentHookCtx.context[key]
        end

        parentHookCtx = parentHookCtx.__volatile and parentHookCtx.__volatile.parentContext
    end

    return nil
end

---Gets the topologically ordered list of context values that were assigned with the given keys.
---@param tree table?
---@param keys string[]
---@return table
function Solyd.getTopologicalContext(tree, keys)
    local values = {}
    for i, key in ipairs(keys) do
        values[key] = {}
    end

    if not tree then
        return values
    end

    local queue = {tree}
    while #queue > 0 do
        local node = table.remove(queue, 1)

        if node.context then
            for i, key in ipairs(keys) do
                if node.context[key] then
                    table.insert(values[key], node.context[key])
                end
            end
        end

        if node.dom then
            if node.dom.src and node.dom.src.__tag == "element" then
                table.insert(queue, 1, node.dom)
            else
                for i = #node.dom, 1, -1 do
                    if type(node.dom[i]) == "table" and node.dom[i].src then
                        assert(node.dom[i].src.__tag == "element", "Invalid tree")
                        table.insert(queue, 1, node.dom[i])
                    end
                end
            end
        end
    end

    return values
end

---@alias ElementType "element"
---@alias SolydElement { __tag: ElementType, props: table, propsDiff: table, key: any?, component: fun(props: table): SolydElement | SolydElement[] }

---Create a Solyd element from a comonent and props.
---@generic P: table
---@param component fun(P): table The component function
---@param props P
---@param key any?
---@return SolydElement
function Solyd.createElement(name, component, props, key)
    return { __tag="element", name = name, component = component, props = props, propsDiff = _.copyDeep(props), key = key }
end

local function propsChanged(oldProps, newProps)
    if type(newProps) ~= "table" or newProps.__opaque ~= nil then
        return oldProps ~= newProps
    end

    if type(oldProps) ~= type(newProps) then
        return true
    end

    local keySet = {}
    for k, v in pairs(newProps) do
        keySet[k] = true
        if type(v) == "table" and v.__opaque == nil then
            if propsChanged(oldProps[k], v) then
                return true
            end
        elseif oldProps[k] ~= v then
            return true
        end
    end

    for k, v in pairs(oldProps) do
        if not keySet[k] then
            return true
        end
    end

    return false
end

-- local function tableSize(t)
--     if type(t) ~= "table" then
--         return nil
--     end
    
--     local count = 0
--     for k, v in pairs(t) do
--         count = count + 1
--     end
--     return count
-- end

---Call any unmount functions bottom-up to ensure everything is cleaned up.
local function _unmount(node)
    if node.dom then
        if node.dom.src and node.dom.src.__tag == "element" then
            _unmount(node.dom)
        else
            for i = 1, #node.dom do
                _unmount(node.dom[i])
            end
        end
    end

    if node.src and node.src.component then
        for k, v in pairs(node.hook) do
            if type(v) == "table" and v.unmount then
                v.unmount()
            end
        end

        if node.hook.contextSubscriptions then
            for key, consumers in pairs(node.hook.contextSubscriptions) do
                for i = 1, #consumers do
                    if consumers[i] == node.hook then
                        table.remove(consumers, i)
                        break
                    end
                end
            end
        end
    end
end

---Renders a Solyd element via tree expansion, pass the return value to the next invocation.
---@param previousTree table?
---@param rootComponent SolydElement?
---@return table?
local function _render(previousTree, rootComponent, parentContext, forceRender)
    local nextTree = previousTree

    if type(rootComponent) ~= "table" then
        return { src = nil }
    end

    if forceRender
    or not previousTree
    or propsChanged(previousTree.src.propsDiff, rootComponent.propsDiff)
    -- or propsChanged(previousTree.hook.__volatile.parentContext, parentContext) 
    then
        -- upkeep
        local hook = previousTree and previousTree.hook or { contextConsumers = {} }
        hook.__volatile = {
            __opaque = true,
            previousTree = previousTree,
            rootComponent = rootComponent,
            parentContext = parentContext or {}
        }

        __hook = hook

        -- update
        local newTree, context = rootComponent.component(rootComponent.props)

        if context and context.gameState then
            -- print(hook.contextDiff, context.gameState, propsChanged(hook.contextDiff, context))
        end

        -- TODO: Optimize only call context consumers for the context that changed
        if propsChanged(hook.contextDiff, context) then
            for k, v in pairs(hook.contextConsumers or {}) do
                for i = 1, #v do
                    v[i].contextDirty = { dirty = true }
                end
            end

            hook.contextDiff = _.copyDeep(context)
        end

        hook.context = context
        -- hook.contextConsumers = {}

        if not newTree then
            -- Check if we need to unmount children
            if previousTree and previousTree.dom and previousTree.dom.src then
                if previousTree.dom.src.__tag == "element" then
                    _unmount(previousTree.dom)
                else
                    for i = 1, #previousTree.dom do
                        _unmount(previousTree.dom[i])
                    end
                end
            end

            nextTree = { src = rootComponent, context = context, hook = hook }
        else
            -- TODO: verif ythat support swapping between singel and multiple children returned
            if newTree.__tag == "element" and ((not previousTree) or previousTree.dom.src ~= nil) then
                local oldChild = previousTree and previousTree.dom
                if oldChild and oldChild.src.component == newTree.component then
                    nextTree = { src = rootComponent, hook = hook, context = context, dom = _render(oldChild, newTree, hook) }
                else
                    if oldChild then
                        _unmount(previousTree) -- component changed, unmount old tree
                    end
                    nextTree = { src = rootComponent, hook = hook, context = context, dom = _render(nil, newTree, hook) }
                end
            else
                local oldChildren = previousTree and previousTree.dom ---@type table?
                -- this supports the swapping behavior
                if oldChildren and oldChildren.src ~= nil then
                    oldChildren = { oldChildren }
                end
                if newTree.__tag == "element" then
                    newTree = { newTree }
                end

                local children = {}

                local previousUniqueComponents = previousTree and previousTree.keyed or {}

                local nextUniqueComponents, nIndex = {}, 0
                for i, child in ipairs(newTree) do
                    if type(child) == "table" and child.key then
                        local prevMatch = previousUniqueComponents[child.key]
                        if prevMatch and prevMatch.src and prevMatch.src.component ~= child.component then
                            prevMatch = nil
                        end

                        local newChild = _render(prevMatch, child, hook)
                        nextUniqueComponents[child.key] = newChild
                        children[i] = newChild
                    elseif type(child) == "table" then
                        nIndex = nIndex + 1
                        local prevMatch = previousUniqueComponents[nIndex]
                        if prevMatch and prevMatch.src and prevMatch.src.component ~= child.component then
                            prevMatch = nil
                        end

                        local newChild = _render(prevMatch, child, hook)
                        nextUniqueComponents[nIndex] = newChild
                        children[i] = newChild
                    else
                        -- should not mount
                        nIndex = nIndex + 1
                        children[i] = { src = nil }
                    end
                end

                -- Find any children that no longer exist in the new tree
                for key, child in pairs(previousUniqueComponents) do
                    if child and not nextUniqueComponents[key] or nextUniqueComponents[key].src.component ~= child.src.component then
                        _unmount(child)
                    end
                end

                nextTree = { src = rootComponent, hook = hook, context = context, dom = children, keyed = nextUniqueComponents }
            end
        end

        hook.__volatile.nextTree = nextTree
    end

    return nextTree
end

---Traverses the tree to find dirty nodes and re-renders them, updating them in-place.
---@param tree table?
---@return table?
local function _cleanDirty(tree)
    local queue = {{nil, tree, nil}}
    local queuedMounts = {}
    while #queue > 0 do
        local didUpdate = false
        local pair = table.remove(queue, 1)
        local parent, node = pair[1], pair[2]
        local originalNode = node
        if node.hook then
            local dirty = false
            for k, v in pairs(node.hook) do
                if type(v) == "table" and v.dirty then
                    dirty = true
                    v.dirty = false
                end
            end

            if dirty then
                local volatile = node.hook.__volatile
                node = _render(volatile.nextTree, volatile.rootComponent, volatile.parentContext, true)
                didUpdate = true
            end
        end

        if didUpdate then
            table.insert(queuedMounts, {parent, node, originalNode})
        end

        if node and node.dom then
            if node.dom.src and node.dom.src.__tag == "element" then
                table.insert(queue, {node, node.dom, parent})
            else
                for i = 1, #node.dom do
                    table.insert(queue, {node, node.dom[i], parent})
                end
            end
        end
    end

    for i = 1, #queuedMounts do
        local triple = queuedMounts[i]
        local parent, node, originalNode = triple[1], triple[2], triple[3]

        if parent and parent.dom then
            if parent.dom and parent.dom.src and parent.dom.src.__tag == "element" then
                assert(parent.dom == originalNode, "parent dom is not original node")
                parent.dom = node
            else
                local found = false
                for j = 1, #parent.dom do
                    if parent.dom[j] == originalNode then
                        parent.dom[j] = node
                        found = true
                        break
                    end
                end

                local found2 = false
                for k, v in pairs(parent.keyed) do
                    if v == originalNode then
                        parent.keyed[k] = node
                        found2 = true
                        break
                    end
                end

                assert(found, "not found" .. parent.src.name)
                assert(found2, "not found2" .. parent.src.name)
            end
        elseif not parent then
            tree = node -- root
        else
            error("SHIT")
        end

    end

    return tree
end

---Renders a Solyd element via tree expansion and sweeping, pass the return value to the next invocation.
---@param previousTree table?
---@param rootComponent SolydElement
---@return table?
function Solyd.render(previousTree, rootComponent)
    local wasHook = __hook

    local tree = _render(previousTree, rootComponent)
    repeat
        setChange = false
        tree = _cleanDirty(tree)
    until not setChange

    __hook = wasHook -- Support nested render calls

    return tree
end

---Wrap a component function to allow calling it directly without invoking createElement.
---@generic P: table
---@param component fun(props: P): table
---@return fun(props: P): table
function Solyd.wrapComponent(name, component)
    return function(props)
        return Solyd.createElement(name, component, props, props.key)
    end
end

return Solyd
