-- Exercise the example's S key, including LÖVE's optional byte-count argument.
local dicebear = require('love_dicebear')
local oldLove, oldAdapter = love, package.loaded['love_dicebear.thorvg']
local saved, settings
local ok, message = pcall(function()
  love = {
    window = {setTitle = function() end},
    filesystem = {
      write = function(path, data, size)
        assert(size == nil, 'save passed resolved settings as the byte count')
        assert(path == 'avatar.svg')
        saved = data
        return true
      end,
      getSaveDirectory = function() return '/example-save-directory' end,
    },
  }
  package.loaded['love_dicebear.thorvg'] = {new = function(style, input)
    settings = dicebear.resolve(style, input)
    return {release = function() end}, settings
  end}
  assert(loadfile('main.lua'))()
  love.load({})
  love.keypressed('right')
  love.keypressed('s')
  assert(saved == dicebear.generate('bottts', settings), 'saved SVG differs from current avatar')
end)
love, package.loaded['love_dicebear.thorvg'] = oldLove, oldAdapter
assert(ok, message)
print('PASS: example saves the edited avatar with the correct write arguments')
