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

local util = require("modules.regex.util")

local emitter = {}

-- local counter = 0
-- local function makeName()
--   counter = counter + 1
--   return "n" .. counter
-- end

--[[

local states = {
  s1 = function(nextChar) ... end,
  ...
}

local acceptStates = {s1 = true, ...}

return function match(str)
  local strlen = #str
  local state = s1
  local allMatches, ai = {}, 1

  for startChar = 1, strlen do -- Conditional upon properties.clampStart
    local ci = 0
    while state and ci <= strlen do
      if acceptStates[state] then
        if ci == strlen then -- Conditional upon properties.clampEnd
          allMatches[ai] = {str:sub(1, ci), startChar, ci + startChar - 1}
        end
      end

      state = states[state](str:sub(ci + 1, ci + 1))

      ci = ci + 1
    end
  end

  return unpack(allMatches)
end

]]

local function generateFunction(state)
  if #state.edges == 0 then
    return "function() end"
  end

  local output = "function(char)"

  local dests = {}
  for i = 1, #state.edges do
    local edge = state.edges[i]
    local dest = edge.dest
    dests[dest] = dests[dest] or {}
    dests[dest][#dests[dest] + 1] = edge.condition
  end

  local prefix = "if"
  for dest, conds in pairs(dests) do
    output = output .. "\n    " .. prefix

    table.sort(conds)
    local ranges = {}
    local singles = {}

    while #conds > 0 do
      if #conds == 1 then
        singles[#singles + 1] = conds[1]
        break
      elseif #conds == 2 then
        singles[#singles + 1] = conds[1]
        singles[#singles + 1] = conds[2]
        break
      end

      local val, index = conds[1]:byte(), 2
      while conds[index]:byte() - index + 1 == val do
        index = index + 1
        if index > #conds then
          break
        end
      end

      index = index - 1

      if index == 1 then
        singles[#singles + 1] = table.remove(conds, 1)
      elseif index == 2 then
        singles[#singles + 1] = table.remove(conds, 1)
        singles[#singles + 1] = table.remove(conds, 1)
      else
        ranges[#ranges + 1] = {string.char(val), string.char(val + index - 1)}
        for i = 1, index do
          table.remove(conds, 1)
        end
      end
    end

    local first = true

    for i = 1, #ranges do
      local range = ranges[i]

      if first then
        first = false
      else
        output = output .. " or"
      end

      output = output .. " (char >= " .. range[1]:byte() .. " and char <= " .. range[2]:byte() .. ")"

      -- if range[1] == "]" then
      --   output = output .. "%]"
      -- elseif range[1]:match("[a-zA-Z]") then
      --   output = output .. range[1]
      -- else
      --   output = output .. "\\" .. range[1]:byte()
      -- end

      -- output = output .. "-"

      -- if range[2] == "]" then
      --   output = output .. "%]"
      -- elseif range[2]:match("[a-zA-Z]") then
      --   output = output .. range[2]
      -- else
      --   output = output .. "\\" .. range[2]:byte()
      -- end
    end

    for i = 1, #singles do
      if first then
        first = false
      else
        output = output .. " or"
      end

      output = output .. " char == " .. singles[i]:byte()
      -- if singles[i]:match("[a-zA-Z]") then
      --   output = output .. singles[i]
      -- else
      --   output = output .. "%\\" .. singles[i]:byte()
      -- end
    end

    output = output .. " then return " .. dest

    prefix = "elseif"
  end

  output = output .. " end\n  end"

  return output
end

--[[
  machine = {
    states = {
      [sName] = {edges = {}}
    },
    startState = sName,
    acceptStates = {[sName] = true}
  }
]]

local function numericize(dfa)
  local newMachine = util.deepClone(dfa)

  local oldNames = {}
  local newNames = {}
  local counter = 0
  for k, v in pairs(dfa.states) do
    counter = counter + 1

    newMachine.states[k] = nil
    newMachine.states[counter] = v
    newNames[k] = counter
    oldNames[counter] = k
  end

  for i = 1, counter do
    local oldEdges = dfa.states[oldNames[i]].edges
    local newEdges = newMachine.states[i].edges
    local n = #oldEdges

    for j = 1, n do
      newEdges[j].dest = newNames[oldEdges[j].dest]
    end
  end

  newMachine.startState = newNames[dfa.startState]
  for k, v in pairs(dfa.acceptStates) do
    newMachine.acceptStates[k] = nil
    newMachine.acceptStates[newNames[k]] = v
  end

  return newMachine
end

function emitter.generateLua(dfa)
  dfa = numericize(dfa)

  local output = [[
local unpack = unpack or table.unpack

local states = {
]]

  for i = 1, #dfa.states do
    local state = dfa.states[i]
    output = output .. "  " .. generateFunction(state) .. ",\n"
  end

  output = output .. [[}

local stateEntries = {
]]

for i = 1, #dfa.states do
  output = output .. "  {"

  local state = dfa.states[i]
  local entries = util.nub(state.enter)
  for j = 1, #entries do
    output = output .. "'" .. entries[j] .. "',"
  end

  output = output .. "},\n"
end

  output = output .. [[}

local acceptStates = {]]

  for state in pairs(dfa.acceptStates) do
    output = output .. "[" .. state .."] = true,"
  end

  output = output .. [[}
return function(str)
  local strlen = #str
  local allMatches, ai = {}, 1

  ]]

  if dfa.properties.clampStart then
    output = output .. "local startChar = 1 do\n"
  else
    output = output .. "for startChar = 1, strlen do\n"
  end

  output = output .. [[
    local state = ]]

  output = output .. dfa.startState

  output = output .. [[

    local ci = startChar - 1
    while state and ci <= strlen do
      if acceptStates[state] then
]]

  if dfa.properties.clampEnd then
    output = output .. [[
        if ci == strlen then
          ]]
  else
    output = output .. [[
        do
          ]]
  end

  output = output .. [[allMatches[ai] = {str:sub(startChar, ci), startChar, ci}
          ai = ai + 1
        end
      end

      local char = str:sub(ci + 1, ci + 1):byte()
      if char then
        state = states[state](char)
      end

      ci = ci + 1
    end
  end

  local result
  for i = 1, #allMatches do
    if (not result) or #allMatches[i][1] > #result[1] then
      result = allMatches[i]
    end
  end

  if result then
    return unpack(result)
  end
end
]]

  return output
end

return emitter
