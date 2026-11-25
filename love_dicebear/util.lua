local M = {}

function M.copy(value)
  if type(value) ~= 'table' then return value end
  local result = {}
  for k, v in pairs(value) do result[k] = M.copy(v) end
  return result
end

function M.keys(value)
  local result = {}
  for key in pairs(value) do result[#result + 1] = key end
  table.sort(result)
  return result
end

function M.escape(value)
  return (tostring(value):gsub('&', '&amp;'):gsub('<', '&lt;')
    :gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&apos;'))
end

function M.round(value)
  local integer = math.floor(value)
  return value - integer < 0.5 and integer or integer + 1
end

function M.number(value)
  local scaled = M.round(value * 100000)
  local sign = scaled < 0 and '-' or ''
  scaled = math.abs(scaled)
  local fraction = string.format('%05d', scaled % 100000):gsub('0+$', '')
  return sign .. string.format('%.0f', math.floor(scaled / 100000))
    .. (fraction ~= '' and '.' .. fraction or '')
end

return M
