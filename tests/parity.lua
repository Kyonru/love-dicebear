local dicebear = require('love_dicebear')
local prng = require('love_dicebear.prng')
local directory = assert(arg[1], 'fixture directory required')
local fixtures = assert(loadfile(directory .. '/cases.lua'))()
for index, case in ipairs(fixtures) do
  local svg, resolved = dicebear.generate('bottts', case)
  assert(svg == dicebear.generate('bottts', resolved), 'round-trip failed for case ' .. index)
  local file = assert(io.open(directory .. '/' .. index .. '.svg', 'wb'))
  file:write(svg); file:close()
end
local vectors = assert(loadfile(directory .. '/prng.lua'))()
for _, vector in ipairs(vectors) do
  assert(prng.hash(vector.seed) == vector.hash, 'UTF-16 hash mismatch')
  assert(prng.value(vector.seed, vector.key) == vector.value, 'PRNG mismatch')
end
