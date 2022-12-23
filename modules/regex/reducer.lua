--[[
MIT License

Copyright (c) 2019 emmachase

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

local dr = {}

local pprint = require("modules.regex.pprint")
local util = require("modules.regex.util")

local function isEpsilon(condition)
  return type(condition) == "table" and condition.type == "epsilon"
end

local function traverseEpsilon(machine, state, seen)
  seen = seen or {}

  local func = {state}

  local edges = machine.states[state].edges
  for i = 1, #edges do
    local edge = edges[i]
    if isEpsilon(edge.condition) then
      if not seen[edge.dest] then
        seen[edge.dest] = true

        -- Epsilon transition, add to E function
        func[#func + 1] = edge.dest

        -- Traverse through its destination and fully evaluate the epsilon path
        local extraFn = traverseEpsilon(machine, edge.dest, seen)

        -- Append those new states to this E function
        local pos = #func
        for j = 1, #extraFn do
          func[pos + 1] = extraFn[j]
          pos = pos + 1
        end
      end
    end
  end

  return util.nub(func)
end

local function nameFromST(st)
  table.sort(st)
  return table.concat(st)
end

function dr.reduceNFA(nfa)
  -- Construct E function
  local eFunc = {}
  for k in pairs(nfa.states) do
    local eI = 1
    eFunc[k] = traverseEpsilon(nfa, k)
  end

  local newMachine = {
    states = {},
    startState = nameFromST(eFunc[nfa.startState]),
    acceptStates = {},
    properties = nfa.properties
  }

  local todoStates = {eFunc[nfa.startState]}
  local completeStates = {}

  while todoStates[1] do -- while todoStates is not empty
    local workingState = table.remove(todoStates, 1)
    local newState = {
      edges = {},
      enter = {}
    }

    local lang = {}

    local isAccepted = false

    -- Get all possible inputs by traversing states
    for i = 1, #workingState do
      local stateName = workingState[i]
      if nfa.acceptStates[stateName] then
        isAccepted = true
      end

      local state = nfa.states[stateName]
      for j = 1, #state.edges do
        local cond = state.edges[j].condition
        if type(cond) == "string" then
          lang[cond] = lang[cond] or {}
          lang[cond][#lang[cond] + 1] = state.edges[j].dest
        end
      end
    end

    -- For each possible input, compute the resultant state, and create an edge
    for k, v in pairs(lang) do
      local st, si = {}, 1

      for i = 1, #v do
        local throughput = eFunc[v[i]]
        for j = 1, #throughput do
          st[si] = throughput[j]
          si = si + 1
        end
      end

      st = util.nub(st)
      table.sort(st)

      local destState = nameFromST(st)
      newState.edges[#newState.edges + 1] = {
        condition = k,
        dest = destState
      }

      if not completeStates[destState] then
        todoStates[#todoStates + 1] = st
        completeStates[destState] = true
      end
    end

    -- Append each enter condition
    local ei = 1
    for i = 1, #workingState do
      local stateName = workingState[i]
      local state = nfa.states[stateName]

      if state.enter then
        for j = 1, #state.enter do
          newState.enter[ei] = state.enter[j]
          ei = ei + 1
        end
      end
    end

    local stateName = nameFromST(workingState)
    newMachine.states[stateName] = newState
    if isAccepted then
      newMachine.acceptStates[stateName] = true
    end

    completeStates[stateName] = true
  end

  return newMachine
end

return dr
