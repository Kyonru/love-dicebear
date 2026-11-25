-- Run with: love . --render-test (requires love_thorvg in the game directory).
local dicebear = require('love_dicebear')
local adapter = require('love_dicebear.thorvg')
return function()
  local count = 0
  for _, name in ipairs({'eyes', 'head', 'mouth', 'sides', 'texture', 'top'}) do
    for _, variant in ipairs(dicebear.describe('bottts').options[name .. 'Variant'].values) do
      local options = {seed = 'render-test', textureProbability = 100}
      options[name .. 'Variant'] = variant
      local document = adapter.new('bottts', options, {width = 128, height = 128})
      local pixels = document:getImageData()
      assert(pixels:getWidth() == 128 and pixels:getHeight() == 128)
      local visible = 0
      for y = 0, 127, 4 do
        for x = 0, 127, 4 do
          local _, _, _, alpha = pixels:getPixel(x, y)
          if alpha > 0 then visible = visible + 1 end
        end
      end
      assert(visible > 20, 'blank render: ' .. name .. '/' .. variant)
      if count == 0 then
        pixels:encode('png', 'bottts-smoke.png')
        print('Preview: ' .. love.filesystem.getSaveDirectory() .. '/bottts-smoke.png')
      end
      document:resize(64, 64)
      assert(document:getImageData():getWidth() == 64)
      document:release()
      count = count + 1
    end
  end
  local files = love.filesystem.getDirectoryItems('love-dicebear-temp')
  assert(#files == 0, 'temporary SVGs leaked')
  print('PASS: ' .. count .. ' native ThorVG renders, resizes and releases')
end
