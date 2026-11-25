local prng = require('love_dicebear.prng')
local linear = require('love_dicebear.data.linearized')
local M = {}

local function luminance(color)
  local r = linear[tonumber(color:sub(2, 3), 16) + 1]
  local g = linear[tonumber(color:sub(4, 5), 16) + 1]
  local b = linear[tonumber(color:sub(6, 7), 16) + 1]
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Resolve constraints recursively, independent of Lua table iteration order.
function M.resolve(style, palettes, seed)
  local result, visiting = {}, {}
  local function resolve(name)
    if result[name] ~= nil then return result[name] end
    assert(not visiting[name], 'circular color constraint: ' .. name)
    visiting[name] = true
    local definition = (style.colors or {})[name] or {}
    local candidates = palettes[name] or {}
    if definition.contrastTo then
      local reference = resolve(definition.contrastTo)
      if reference ~= false then
        local target, ranked = luminance(reference), {}
        for i, color in ipairs(candidates) do
          local lum = luminance(color)
          ranked[i] = {color = color, index = i, ratio = (math.max(lum, target) + 0.05) / (math.min(lum, target) + 0.05)}
        end
        table.sort(ranked, function(a, b)
          if a.ratio == b.ratio then return a.index < b.index end
          return a.ratio > b.ratio
        end)
        candidates = {}
        for i, entry in ipairs(ranked) do candidates[i] = entry.color end
      end
    end
    local excluded = {}
    for _, reference in ipairs(definition.notEqualTo or {}) do
      local value = resolve(reference)
      if value then excluded[value:sub(1, 7)] = true end
    end
    local filtered = {}
    for _, value in ipairs(candidates) do
      if not excluded[value:sub(1, 7)] then filtered[#filtered + 1] = value end
    end
    if #filtered > 0 then candidates = filtered end
    if not definition.contrastTo then candidates = prng.shuffle(seed, name .. 'Color', candidates) end
    result[name], visiting[name] = candidates[1] or false, nil
    return result[name]
  end
  for name in pairs(palettes) do resolve(name) end
  return result
end

return M
