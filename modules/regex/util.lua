local util = {}

function util.deepClone(tab)
  local nt = {}

  for k, v in pairs(tab) do
    if type(v) == "table" then
      nt[k] = util.deepClone(v)
    else
      nt[k] = v
    end
  end

  return nt
end

function util.nub(tab)
  local entries = {}
  local nt, i = {}, 1

  for k, v in pairs(tab) do
    if not entries[v] then
      entries[v] = true
      nt[i] = v
      i = i + 1
    end
  end

  return nt
end

return util
