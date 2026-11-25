local dicebear = require('love_dicebear')
local Editor = require('example.editor')
local editor, edits, input, state
edits = 0
editor = Editor.new(function(nextInput)
  input, state, edits = nextInput, dicebear.resolve(editor.description.name, nextInput), edits + 1
  editor:setState(input, state, editor.renderer)
end)
local function setup(style, renderer)
  editor:setDescription(dicebear.describe(style))
  input = {seed = 'editor-test'}
  state = dicebear.resolve(style, input)
  editor:setState(input, state, renderer or 'thorvg')
end
local function select(name)
  for i, row in ipairs(editor.rows) do if row.name == name then editor:select(i); return end end
  error('missing editor setting ' .. name)
end
local function typeValue(value)
  editor:beginInput(); editor:textinput(value); editor:keypressed('return')
end
setup('bottts')
assert(editor.rows[1].name == 'eyesVariant')
local eyes = state.eyesVariant
select('mouthVariant'); editor:adjust(1)
assert(input.mouthVariant and input.mouthProbability == 100 and state.eyesVariant == eyes)
local mouth = state.mouthVariant
local visibleSvg = dicebear.generate('bottts', input)
typeValue('None')
assert(input.mouthProbability == 0 and state.mouthVariant == mouth)
assert(editor:value(editor.rows[editor.selected]) == 'None')
local hiddenSvg = dicebear.generate('bottts', input)
assert(hiddenSvg ~= visibleSvg and hiddenSvg == dicebear.generate('bottts', state))
editor:adjust(1)
assert(state.mouthProbability == 100 and state.mouthVariant == editor.rows[editor.selected].spec.values[1])
editor:adjust(-1); assert(state.mouthProbability == 0, 'cycling backward should offer None')
editor:adjust(-1); assert(state.mouthProbability == 100, 'cycling backward from None should restore a variant')
typeValue('None'); editor:keypressed('backspace')
assert(input.mouthVariant == nil and input.mouthProbability == nil, 'reset should restore seeded visibility')
select('topProbability'); typeValue('0'); assert(state.topProbability == 0)
select('baseColor'); typeValue('#abc'); assert(state.baseColor == '#aabbcc')
select('backgroundColor'); typeValue('transparent'); assert(type(state.backgroundColor) == 'table')
select('rotate'); editor:adjust(1); assert(state.rotate == 5)
select('scale'); typeValue('0.8'); assert(state.scale == 0.8)
select('flip'); editor:adjust(1); assert(state.flip == 'horizontal')
select('rotate'); editor:keypressed('backspace'); assert(input.rotate == nil and state.rotate == 0)
select('scale'); local before = edits
editor:beginInput(); editor:textinput('invalid'); editor:keypressed('return')
assert(edits == before and editor.input ~= nil and editor.message)
editor:keypressed('escape'); assert(editor.input == nil)
select('seed'); editor:keypressed('e'); editor:textinput('e');
assert(editor.input == state.seed, 'opening shortcut was inserted as text')
editor:textinput('Adaé'); editor:keypressed('backspace')
assert(editor.input == 'Ada')
assert(editor:keypressed('s') and edits == before, 'editing text leaked an application shortcut')
editor:keypressed('return'); assert(state.seed == 'Ada')
setup('bottts', 'http')
select('mouthVariant'); typeValue('None')
assert(input.mouthProbability == 0)
assert(require('love_dicebear.http').url('bottts', input):find('mouthProbability=0', 1, true))
editor:adjust(1); assert(state.mouthProbability == 100)
setup('initials', 'http')
select('fontFamily'); before = edits; editor:adjust(1)
assert(edits == before and editor.message:find('local%-only'))
select('size'); typeValue('257'); assert(editor.input ~= nil and edits == before)
editor:keypressed('escape'); editor:adjust(1); assert(state.size == 256)
editor:adjust(-1); assert(state.size == 240)
-- Every descriptor is discoverable, and cycling source variants/colors is valid for every style.
for _, style in ipairs(dicebear.styles()) do
  setup(style)
  local count = 0
  for _ in pairs(editor.description.options) do count = count + 1 end
  assert(#editor.rows == count, style)
  for i, row in ipairs(editor.rows) do
    if row.spec.type == 'variant' or row.spec.type == 'color' or row.spec.type == 'enum' then
      editor:select(i); editor:adjust(1)
      assert(not editor.message, style .. '/' .. row.name .. ': ' .. tostring(editor.message))
      if row.spec.type == 'variant' then
        typeValue('None')
        assert(not editor.message and state[row.name:gsub('Variant$', 'Probability')] == 0, style .. '/' .. row.name)
        editor:adjust(1)
        assert(not editor.message and state[row.name:gsub('Variant$', 'Probability')] == 100)
      end
    end
  end
end
print('PASS: editor components, visibility, colors, transforms, text, validation, HTTP limits and all 63 style schemas')
