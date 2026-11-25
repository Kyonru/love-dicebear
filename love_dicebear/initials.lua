local data = require('love_dicebear.data.unicode')
local M = {}

-- Input has already passed the generator's UTF-8 validation.
local function points(text)
  local result, i = {}, 1
  while i <= #text do
    local byte, size = text:byte(i), 1
    if byte >= 240 then size = 4 elseif byte >= 224 then size = 3 elseif byte >= 192 then size = 2 end
    local cp = byte % (size == 1 and 128 or 2 ^ (7 - size))
    for j = 1, size - 1 do cp = cp * 64 + text:byte(i + j) - 128 end
    result[#result + 1] = {cp = cp, text = text:sub(i, i + size - 1)}
    i = i + size
  end
  return result
end

local function contains(ranges, cp)
  local lo, hi = 1, #ranges / 2
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if cp < ranges[mid * 2 - 1] then hi = mid - 1
    elseif cp > ranges[mid * 2] then lo = mid + 1
    else return true end
  end
  return false
end

function M.fromSeed(seed, keepAt)
  local text = keepAt and seed or seed:gsub('@.*', '')
  local words, word, cluster = {}, nil, nil
  for _, point in ipairs(points(text)) do
    local cp = point.cp
    if cp ~= 96 and cp ~= 180 and cp ~= 39 and cp ~= 700 then
      if contains(data.letters, cp) then
        if not word then word = {}; words[#words + 1] = word end
        cluster = {point}; word[#word + 1] = cluster
      elseif contains(data.marks, cp) and word then
        cluster[#cluster + 1] = point
      else word, cluster = nil, nil end
    end
  end
  if #words == 0 then return not keepAt and M.fromSeed(seed, true) or '' end
  local chosen = {words[1][1]}
  if #words == 1 then chosen[2] = words[1][2] else chosen[2] = words[#words][1] end
  local result = {}
  for _, part in ipairs(chosen) do
    for _, point in ipairs(part) do result[#result + 1] = data.upper[point.cp] or point.text end
  end
  return table.concat(result)
end

function M.first(text)
  local point = points(text)[1]
  return point and point.text or ''
end

return M
