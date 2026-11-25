local util = require('love_dicebear.util')
local prng = require('love_dicebear.prng')
local colors = require('love_dicebear.colors')
local M = {}

local core = {
  seed = {type = 'string', default = ''},
  title = {type = 'string'},
  fontFamily = {type = 'string', default = 'system-ui'},
  fontWeight = {type = 'number', min = 1, max = 1000, default = 400},
  size = {type = 'number', min = 1, max = 8192},
  flip = {type = 'enum', values = {'none', 'horizontal', 'vertical', 'both'}, default = 'none'},
  rotate = {type = 'range', min = -360, max = 360, default = 0},
  scale = {type = 'range', min = 0, max = 10, default = 1},
  translateX = {type = 'range', min = -100, max = 100, default = 0},
  translateY = {type = 'range', min = -100, max = 100, default = 0},
  borderRadius = {type = 'range', min = 0, max = 50, default = 0},
}

function M.describe(style)
  local result = util.copy(core)
  for name, entry in pairs(style.components or {}) do
    local component = entry.extends and style.components[entry.extends] or entry
    local tags = {}
    for variant, data in pairs(component.variants) do tags[variant] = util.copy(data.tags or {}) end
    result[name .. 'Variant'] = {type = 'variant', values = util.keys(component.variants), tags = tags, extends = entry.extends}
    result[name .. 'Probability'] = {type = 'number', min = 0, max = 100,
      default = component.probability or 100}
  end
  local groups = {background = true}
  for name in pairs(style.colors or {}) do groups[name] = true end
  for name in pairs(groups) do
    result[name .. 'Color'] = {type = 'color', palette = util.copy(
      (style.colors or {})[name] and style.colors[name].values or {})}
  end
  return result
end

local function fail(key, message) error('invalid option ' .. tostring(key) .. ': ' .. message, 3) end
local function number(key, value, spec)
  if type(value) ~= 'number' or value ~= value or value < spec.min or value > spec.max then
    fail(key, 'expected a finite number in [' .. spec.min .. ', ' .. spec.max .. ']')
  end
  return value
end

local function list(key, value)
  if type(value) ~= 'table' then fail(key, 'expected an array') end
  local count = 0
  for k in pairs(value) do
    if type(k) ~= 'number' or k % 1 ~= 0 or k < 1 or k > #value then
      fail(key, 'expected a dense array')
    end
    count = count + 1
  end
  if count ~= #value then fail(key, 'expected a dense array') end
  return value
end

local function hex(key, value)
  if type(value) ~= 'string' then fail(key, 'expected a hex color') end
  local digits = value:gsub('^#', ''):lower()
  if not digits:match('^[0-9a-f]+$') or
    (#digits ~= 3 and #digits ~= 4 and #digits ~= 6 and #digits ~= 8) then
    fail(key, 'expected RGB, RGBA, RRGGBB or RRGGBBAA hex')
  end
  if #digits < 5 then digits = digits:gsub('.', '%0%0') end
  return '#' .. digits
end

local function variants(key, value, component)
  if type(value) == 'string' then value = {value} end
  if type(value) ~= 'table' then fail(key, 'expected a variant, array or weight map') end
  local weights = {}
  local array = #value > 0
  if array then list(key, value) end
  for k, v in pairs(value) do
    local name, weight = k, v
    if array then name, weight = v, 1 end
    if type(name) ~= 'string' or not component.variants[name] then
      fail(key, 'unknown variant ' .. tostring(name))
    end
    weights[name] = number(key, weight, {min = 0, max = 1000000})
  end
  return weights
end

function M.resolve(style, input)
  if type(input) ~= 'table' then error('options must be a table', 2) end
  local schema, result = M.describe(style), {}
  local seed = input.seed or ''
  if type(seed) ~= 'string' then fail('seed', 'expected a string') end
  prng.hash(seed) -- validate UTF-8 even if all choices are explicit
  result.seed = seed
  for key in pairs(input) do
    if not schema[key] then fail(key, 'unknown or unsupported option') end
  end
  for key, spec in pairs(core) do
    local value = input[key]
    if value == nil then value = spec.default end
    if value ~= nil then
      if spec.type == 'string' then
        if type(value) ~= 'string' then fail(key, 'expected a string') end
        -- XML 1.0 excludes these control characters, even in escaped text.
        if key ~= 'seed' and value:find('[%z\1-\8\11\12\14-\31]') then fail(key, 'invalid XML text') end
        prng.hash(value)
      elseif spec.type == 'number' then number(key, value, spec)
      elseif spec.type == 'enum' then
        local valid = false
        for _, choice in ipairs(spec.values) do if value == choice then valid = true end end
        if not valid then fail(key, 'unknown value') end
      elseif spec.type == 'range' then
        local lo, hi
        if type(value) == 'table' then
          list(key, value)
          if #value > 2 then fail(key, 'expected at most two bounds') end
          lo = value[1] or spec.default; hi = value[2] or lo
        else lo, hi = value, value end
        number(key, lo, spec); number(key, hi, spec)
        lo, hi = math.min(lo, hi), math.max(lo, hi)
        value = util.round((lo + prng.value(seed, key) * (hi - lo)) * 10000) / 10000
      end
      result[key] = value
    end
  end
  local palettes = {}
  for key, spec in pairs(schema) do
    if spec.type == 'color' then
      local name = key:sub(1, -6)
      local values = input[key]
      if values == nil then values = schema[key].palette end
      if type(values) == 'string' then values = {values} end
      list(key, values)
      local candidates = {}
      for _, value in ipairs(values) do candidates[#candidates + 1] = hex(key, value) end
      palettes[name] = candidates
    end
  end
  for name, value in pairs(colors.resolve(style, palettes, seed)) do
    result[name .. 'Color'] = value or {}
  end
  for name, entry in pairs(style.components or {}) do
    local component = entry.extends and style.components[entry.extends] or entry
    local pk, vk = name .. 'Probability', name .. 'Variant'
    local probability = input[pk]
    if probability == nil and entry.extends then probability = input[entry.extends .. 'Probability'] end
    if probability == nil then probability = schema[pk].default end
    number(pk, probability, schema[pk])
    local weights = {}
    local selection = input[vk]
    if selection == nil and entry.extends then selection = input[entry.extends .. 'Variant'] end
    if selection ~= nil then weights = variants(vk, selection, component)
    else
      for variant, data in pairs(component.variants) do weights[variant] = data.weight or 1 end
    end
    local variant = prng.weighted(seed, vk, weights)
    local visible = variant ~= nil and prng.value(seed, pk) * 100 < probability
    result[pk] = visible and 100 or 0
    -- Keep a hidden part's selection so the editor can enable it later.
    result[vk] = variant or {}
  end
  return result
end

return M
