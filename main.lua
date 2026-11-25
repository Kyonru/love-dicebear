-- Small integration example. Copy love_thorvg/ beside this file to run it.
local dicebear = require('love_dicebear')
local document, state, variantIndex
local styleName, styleIndex = 'bottts', 1
local styles = dicebear.styles()
local part = 'eyes'
local previewNotice
local description = dicebear.describe(styleName)
local variants = dicebear.describe('bottts').options.eyesVariant.values

local function selectStyle(name)
  description = dicebear.describe(name)
  styleName = name
  for i, value in ipairs(styles) do if value == name then styleIndex = i end end
  part = description.options.eyesVariant and 'eyes' or nil
  if not part then
    local parts = {}
    for key, spec in pairs(description.options) do
      if spec.type == 'variant' and not spec.extends then parts[#parts + 1] = key:sub(1, -8) end
    end
    table.sort(parts)
    part = parts[1]
  end
  variants = part and description.options[part .. 'Variant'].values or {}
end

local function rebuild(options)
  local nextDocument, nextState
  previewNotice = require('love_dicebear.thorvg_support')[styleName]
  if previewNotice then
    nextState = dicebear.resolve(styleName, options)
  else
    nextDocument, nextState = require('love_dicebear.thorvg').new(
      styleName, options, {width = 256, height = 256})
  end
  if document then document:release() end
  document, state = nextDocument, nextState
  variantIndex = 1
  for i, variant in ipairs(variants) do if variant == state[part .. 'Variant'] then variantIndex = i end end
end

function love.load(args)
  if args[1] == '--test' or args[1] == '--render-test' or args[1] == '--catalog-render-test' or args[1] == '--parity' then
    local ok, err = pcall(function()
      require('tests.run')
      require('tests.adapter')
      if args[1] == '--render-test' then require('tests.render')() end
      if args[1] == '--catalog-render-test' then require('tests.catalog_render')() end
      if args[1] == '--parity' then
        arg = {args[2]}
        require('tests.parity')
      end
    end)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
    return
  end
  for i, arg in ipairs(args) do
    if arg == '--style' then styleName = assert(args[i + 1], '--style requires a name') end
  end
  selectStyle(styleName)
  love.window.setTitle('love-dicebear / Style catalog')
  rebuild({seed = 'hello-love', backgroundColor = 'e8edf2', borderRadius = 12})
end

function love.keypressed(key)
  if not state then return end
  if key == 'right' or key == 'left' then
    if #variants == 0 then return end
    variantIndex = (variantIndex - 1 + (key == 'right' and 1 or -1)) % #variants + 1
    state[part .. 'Variant'] = variants[variantIndex]
    state[part .. 'Probability'] = 100
    rebuild(state)
  elseif key == 'up' or key == 'down' then
    local seed = state.seed
    styleIndex = (styleIndex - 1 + (key == 'down' and 1 or -1)) % #styles + 1
    selectStyle(styles[styleIndex])
    rebuild({seed = seed, borderRadius = 12})
  elseif key == 'r' then
    rebuild({seed = tostring(love.timer.getTime()), backgroundColor = 'e8edf2', borderRadius = 12})
  elseif key == 's' then
    local svg = dicebear.generate(styleName, state)
    assert(love.filesystem.write('avatar.svg', svg))
    print('Saved ' .. love.filesystem.getSaveDirectory() .. '/avatar.svg')
  elseif key == 'escape' then love.event.quit() end
end

function love.draw()
  if not state then return end
  love.graphics.clear(0.08, 0.09, 0.11)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', 32, 32, 256, 256)
  if document then document:draw(32, 32)
  else
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.printf(previewNotice, 48, 110, 224, 'center')
    love.graphics.setColor(1, 1, 1)
  end
  love.graphics.print(styleName .. ' / ' .. ((description.meta.creator or {}).name or 'Unknown'), 32, 310)
  love.graphics.print('Up / Down: style    Left / Right: variant    R: new    S: save', 32, 338)
  love.graphics.print(part and (part .. ': ' .. tostring(state[part .. 'Variant'])) or '', 32, 366)
end

function love.quit() if document then document:release() end end
