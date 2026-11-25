-- DiceBear's FNV-1a / Mulberry32 contract. See THIRD_PARTY.md.
-- Arithmetic fallback keeps the module usable in Lua 5.1–5.4 without bit libs.
local util = require('love_dicebear.util')
local M = {}
local UINT32 = 4294967296
local ok, bit = pcall(require, 'bit')
local function xor(a, b)
  if ok then return bit.bxor(a, b) % UINT32 end
  local result, place = 0, 1
  for _ = 1, 32 do
    if a % 2 ~= b % 2 then result = result + place end
    a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
  end
  return result
end
local function bor(a, b) return a + b - (a + b - xor(a, b)) / 2 end
local function shift(a, n) return math.floor(a / 2 ^ n) end
local function mul(a, b)
  local lo, hi = a % 65536, math.floor(a / 65536)
  return (lo * b + (hi * (b % 65536) % 65536) * 65536) % UINT32
end

-- Decode UTF-8 explicitly: hashing uses UTF-16 code units, including surrogates.
function M.hash(text)
  local hash, i = 2166136261, 1
  local function unit(n) hash = mul(xor(hash, n), 16777619) end
  while i <= #text do
    local b = text:byte(i)
    local n, count, minimum
    if b < 128 then n, count, minimum = b, 1, 0
    elseif b >= 194 and b <= 223 then n, count, minimum = b - 192, 2, 128
    elseif b >= 224 and b <= 239 then n, count, minimum = b - 224, 3, 2048
    elseif b >= 240 and b <= 244 then n, count, minimum = b - 240, 4, 65536
    else error('seed must be valid UTF-8', 2) end
    for j = 1, count - 1 do
      local c = text:byte(i + j)
      assert(c and c >= 128 and c <= 191, 'seed must be valid UTF-8')
      n = n * 64 + c - 128
    end
    assert(n >= minimum and n <= 1114111 and not (n >= 55296 and n <= 57343),
      'seed must be valid UTF-8')
    if n > 65535 then
      n = n - 65536
      unit(55296 + math.floor(n / 1024)); unit(56320 + n % 1024)
    else unit(n) end
    i = i + count
  end
  return hash
end

local function generator(state)
  return function()
    state = (state + 1831565813) % UINT32
    local t = mul(xor(state, shift(state, 15)), bor(state, 1))
    t = xor(t, (t + mul(xor(t, shift(t, 7)), bor(t, 61))) % UINT32)
    return xor(t, shift(t, 14)) / UINT32
  end
end

function M.value(seed, key) return generator(M.hash(seed .. ':' .. key))() end

local function normalized(items)
  local seen, result = {}, {}
  for _, item in ipairs(items) do
    if not seen[item] then result[#result + 1], seen[item] = item, true end
  end
  table.sort(result) -- only ASCII variant names and hex colors reach this path
  return result
end

function M.pick(seed, key, items)
  local values = normalized(items)
  return values[math.floor(M.value(seed, key) * #values) + 1]
end

function M.weighted(seed, key, weights)
  local keys, total = util.keys(weights), 0
  for _, name in ipairs(keys) do total = total + weights[name] end
  if total == 0 then return M.pick(seed, key, keys) end
  local threshold, sum = M.value(seed, key) * total, 0
  for _, name in ipairs(keys) do
    sum = sum + weights[name]
    if threshold < sum then return name end
  end
  return keys[#keys]
end

function M.shuffle(seed, key, items)
  local values, nextValue = normalized(items), generator(M.hash(seed .. ':' .. key))
  for i = #values, 2, -1 do
    local j = math.floor(nextValue() * i) + 1
    values[i], values[j] = values[j], values[i]
  end
  return values
end

return M
