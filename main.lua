-- Small integration example. Copy love_thorvg/ beside this file to run it.
local dicebear = require('love_dicebear')
local document, state, eyeIndex
local eyes = dicebear.describe('bottts').options.eyesVariant.values

local function rebuild(options)
  local nextDocument, nextState = require('love_dicebear.thorvg').new(
    'bottts', options, {width = 256, height = 256})
  if document then document:release() end
  document, state = nextDocument, nextState
  for i, variant in ipairs(eyes) do if variant == state.eyesVariant then eyeIndex = i end end
end

function love.load(args)
  if args[1] == '--test' or args[1] == '--render-test' or args[1] == '--parity' then
    local ok, err = pcall(function()
      require('tests.run')
      require('tests.adapter')
      if args[1] == '--render-test' then require('tests.render')() end
      if args[1] == '--parity' then
        arg = {args[2]}
        require('tests.parity')
      end
    end)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
    return
  end
  love.window.setTitle('love-dicebear / Bottts')
  rebuild({seed = 'hello-love', backgroundColor = 'e8edf2', borderRadius = 12})
end

function love.keypressed(key)
  if not state then return end
  if key == 'right' or key == 'left' then
    eyeIndex = (eyeIndex - 1 + (key == 'right' and 1 or -1)) % #eyes + 1
    state.eyesVariant = eyes[eyeIndex]
    rebuild(state)
  elseif key == 'r' then
    rebuild({seed = tostring(love.timer.getTime()), backgroundColor = 'e8edf2', borderRadius = 12})
  elseif key == 's' then
    assert(love.filesystem.write('avatar.svg', dicebear.generate('bottts', state)))
    print('Saved ' .. love.filesystem.getSaveDirectory() .. '/avatar.svg')
  elseif key == 'escape' then love.event.quit() end
end

function love.draw()
  if not document then return end
  love.graphics.clear(0.08, 0.09, 0.11)
  love.graphics.setColor(1, 1, 1)
  document:draw(32, 32)
  love.graphics.print('Bottts by Pablo Stanley / bottts.com', 32, 310)
  love.graphics.print('Left / Right: eyes    R: new avatar    S: save SVG', 32, 338)
  love.graphics.print('Eyes: ' .. state.eyesVariant, 32, 366)
end

function love.quit() if document then document:release() end end
