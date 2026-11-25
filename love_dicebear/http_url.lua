local dicebear = require('love_dicebear')
local util = require('love_dicebear.util')
local M = {}

local function encode(value)
  return (tostring(value):gsub('[^A-Za-z0-9%-%._~]', function(char)
    return string.format('%%%02X', char:byte())
  end))
end

function M.build(style, input, settings)
  if input == nil then input = {} end
  if settings == nil then settings = {} end
  assert(type(settings) == 'table', 'HTTP settings must be a table')
  dicebear.resolve(style, input) -- validate without changing caller options
  local schema = dicebear.describe(style).options
  local base = settings.baseUrl or 'https://api.dicebear.com/11.x'
  assert(type(base) == 'string' and base:match('^https?://[^/%s]+')
    and not base:find('[%z\1-\32\127?#]'), 'baseUrl must be an HTTP(S) version root without query or fragment')
  base = base:gsub('/+$', '')
  local size = input.size or 256
  assert(size >= 1 and size <= 256 and size % 1 == 0, 'HTTP PNG size must be an integer from 1 to 256')
  local values = {seed = input.seed or '', size = tostring(size)}
  for key, value in pairs(input) do
    local spec = schema[key]
    if key:match('^animation') or key:find('Animation', 1, true) then
      error('Animation options require local SVG rendering; HTTP PNG output is static', 2)
    elseif key == 'fontFamily' or key == 'fontWeight' then
      assert(value == spec.default, key .. ' is not supported by the public HTTP API')
    elseif key == 'title' then
      error('title is not supported by the public HTTP API', 2)
    else
      local component = key:match('^(.*)Probability$')
      local alias = spec.extends or (component and schema[component .. 'Variant'].extends)
      assert(not alias, key .. ' is a local alias override; use original options or the source component for HTTP')
      if type(value) == 'table' then
        local parts = {}
        if spec.type == 'variant' and #value == 0 and next(value) ~= nil then
          for _, name in ipairs(util.keys(value)) do parts[#parts + 1] = name .. ':' .. tostring(value[name]) end
        else
          for _, item in ipairs(value) do parts[#parts + 1] = tostring(item) end
        end
        value = table.concat(parts, ',')
      end
      values[key] = tostring(value)
    end
  end
  local query = {}
  for _, key in ipairs(util.keys(values)) do query[#query + 1] = encode(key) .. '=' .. encode(values[key]) end
  return base .. '/' .. style .. '/png?' .. table.concat(query, '&')
end

return M
