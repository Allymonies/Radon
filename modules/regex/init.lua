-- Main utilty file, exposes entire library
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

local r2l = {}

r2l.parser = require("modules.regex.parser")

r2l.nfactory = require("modules.regex.nfactory")

r2l.reducer = require("modules.regex.reducer")

r2l.emitter = require("modules.regex.emitter")

r2l.new = function(regex)
    local tokens = r2l.parser.lexRegex(regex)
    local parseSuccess, parsedRegex = pcall(r2l.parser.parse, tokens)
    if not parseSuccess then
        error("Failed to parse regex: " .. parsedRegex)
    end
    local origNFA = r2l.nfactory.generateNFA(parsedRegex)
    local origDFA = r2l.reducer.reduceNFA(origNFA)
    return loadstring(r2l.emitter.generateLua(origDFA))()
end

return r2l
