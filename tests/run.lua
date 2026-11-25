local dicebear = require('love_dicebear')
local prng = require('love_dicebear.prng')
local util = require('love_dicebear.util')
local count = 0
local function check(condition, message)
  count = count + 1
  assert(condition, message)
end
local function rejects(options)
  local ok = pcall(dicebear.generate, 'bottts', options)
  check(not ok, 'invalid input was accepted')
end

check(prng.hash('alice') == 2267157479, 'FNV reference mismatch')
local input = {seed = 'Ada 🤖', baseColor = {'abc', 'de1234'}, eyesVariant = {'happy', 'dizzy'}}
local svg, resolved = dicebear.generate('bottts', input)
check(svg == dicebear.generate('bottts', input), 'generation is not deterministic')
check(svg == dicebear.generate('bottts', resolved), 'resolved options cannot round-trip')
check(input.baseColor[1] == 'abc' and #input.eyesVariant == 2, 'caller options mutated')
local edited = util.copy(resolved)
edited.mouthVariant = 'grill01'
local changed, after = dicebear.generate('bottts', edited)
check(changed ~= svg, 'editor change had no effect')
check(after.eyesVariant == resolved.eyesVariant and after.baseColor == resolved.baseColor,
  'editing one part changed another')
local description = dicebear.describe('bottts')
check(#description.options.eyesVariant.values == 14, 'missing eye variants')
description.options.eyesVariant.values[1] = 'corrupted'
description.meta.source.name = 'corrupted'
check(dicebear.describe('bottts').meta.source.name == 'Bottts', 'description is not isolated')
check(dicebear.describe('bottts').options.eyesVariant.values[1] == 'bulging', 'schema mutated')
local hidden, state = dicebear.generate('bottts', {seed = 'x', eyesProbability = 0, textureProbability = 0})
check(not hidden:find('<g id="eyes%-'), 'hidden eyes rendered')
check(hidden == dicebear.generate('bottts', state), 'hidden features did not round-trip')
local escaped = dicebear.generate('bottts', {title = '<hello & "world">'})
check(escaped:find('&lt;hello &amp; &quot;world&quot;&gt;', 1, true), 'title not escaped')
local noParts = {seed = 'empty', backgroundColor = {}}
for _, component in ipairs({'eyes', 'mouth', 'head', 'sides', 'texture', 'top'}) do
  noParts[component .. 'Variant'] = {}
end
local empty, emptyState = dicebear.generate('bottts', noParts)
check(not empty:find('<use', 1, true), 'empty selection rendered a component')
check(empty == dicebear.generate('bottts', emptyState), 'empty selection did not round-trip')
rejects({seed = 10}); rejects({seed = '\255'}); rejects({seed = '\192\128'})
rejects({seed = '\237\160\128'}); rejects({seed = '\244\144\128\128'})
rejects({size = 0}); rejects({size = math.huge}); rejects({scale = 0/0})
rejects({eyesVariant = 'missing'}); rejects({eyesVariant = {happy = -1}})
rejects({eyesVariant = {happy = math.huge}}); rejects({eyesProbability = 101})
rejects({baseColor = 'red'}); rejects({backgroundColor = '<svg>'})
rejects({baseColor = {[2] = 'ffffff'}}); rejects({rotate = {1, 2, 3}})
rejects({rotate = {min = 0, max = 1}}); rejects({title = '\0'})
rejects({backgroundColorFill = 'linear'}); rejects({typo = true})
rejects({flip = true})
for _, name in ipairs({'eyes', 'mouth', 'head', 'sides', 'texture', 'top'}) do
  for _, variant in ipairs(dicebear.describe('bottts').options[name .. 'Variant'].values) do
    local options = {seed = 'every-variant', textureProbability = 100}
    options[name .. 'Variant'] = variant
    local rendered, snapshot = dicebear.generate('bottts', options)
    check(rendered == dicebear.generate('bottts', snapshot), name .. '/' .. variant .. ' round-trip failed')
  end
end
print('PASS: ' .. count .. ' Lua assertions')
return count
