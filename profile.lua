--| Profiler module.
--b "Pedro Miller Rabinovitch" <miller@inf.puc-rio.br>
--$Id: prof.lua,v 1.4 2003/10/17 00:17:21 miller Exp $
--TODO  add function call profiling. Some of the skeleton is already in
---     place, but call profiling behaves different, so a couple of new
---     functionalities must be added.
--TODO  add methods for proper result retrieval
--TODO  use optional clock() function for millisecond precision, if it's
---     available

local E, I = {}, {}
--& Profiler module.
-- Profiler = E

--. Keeps track of the hit counts of each item
E.counts = {
  line = {}
}
--. These should be inside the _line_ table above.
E.last_line = nil
E.last_time = os.epoch("utc")
E.started, E.ended = nil, nil

local dontdie = 0

--% Activates the profiling system.
--@ [kind] (string) Optional hook kind. For now, only 'line' works,
--- so just avoid it. >: )
function E:activate( kind )
  kind = kind or 'line'

  local function hook_counter( hk_name, param,... )
    local t = self.counts[hk_name][param]
    if t == nil then
      t = { count=0, time = 0, name = debug.getinfo(2).short_src }
      self.counts[hk_name][param] = t
    end
    self.counts[hk_name][param].count =
     self.counts[hk_name][param].count + 1

     dontdie = dontdie + 1
     if dontdie > 1000000 then
       dontdie = 0
       print("yielding")
       self.ended = os.epoch("utc")
       E:write_results("line", "profile.txt")
       coroutine.yield()
     end

    if self.last_line then
      local delta = os.epoch("utc") - self.last_time
      if delta > 0 then
        self.counts[hk_name][self.last_line].time =
         self.counts[hk_name][self.last_line].time + delta
        self.last_time = os.epoch("utc")
      end
    end

    self.last_line = param
  end

  self.started = os.epoch("utc")
  debug.sethook( hook_counter, kind )
end

--% Deactivates the profiling system.
--@ [kind] (string) Optional hook kind. For now, only 'line' works,
--- so just avoid it.
function E:deactivate( kind )
  kind = kind or 'line'
  self.ended = os.epoch("utc")
  debug.sethook( nil, kind )
end

--% Prints the results.
--@ [kind] (string) Optional hook... Aah, you got it by now.
--TODO add print output formatting and sorting
function E:print_results( kind )
  kind = kind or 'line'
  print( kind, 'count', 'approx. time (s)' )
  print( '----', '-----', '----------------' )
  for i,v in pairs( self.counts[kind] ) do
    print( i, v.count, v.time )
  end
  print( self.ended - self.started,
    ' second(s) total (approximately).' )
end

function E:write_results( kind, filename )
    kind = kind or 'line'
    local f = io.open( filename, 'w' )
    f:write( 'file', kind, ' count', ' approx. time (s)', '\n' )
    f:write( '-------------', '----', ' -----', ' ----------------', '\n' )
    for i,v in pairs( self.counts[kind] ) do
        f:write( v.name, ' ', i, ' ', v.count, ' ', v.time, '\n' )
    end
    f:write( self.ended - self.started,
        ' second(s) total (approximately).', '\n' )
    f:close()
end

return E
