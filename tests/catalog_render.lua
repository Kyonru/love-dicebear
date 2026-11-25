local dicebear = require('love_dicebear')
local adapter = require('love_dicebear.thorvg')
return function()
  local styles, failures = dicebear.styles(), {}
  local unsupported = require('love_dicebear.thorvg_support')
  local thorvg = require('love_thorvg')
  local fontReady = thorvg.capabilities and thorvg.capabilities.svgFonts
  local rendered = 0
  local width, height, columns = 128, 156, 9
  local canvas = love.graphics.newCanvas(columns * width, math.ceil(#styles / columns) * height)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0.94, 0.95, 0.96, 1)
  love.graphics.setCanvas()
  for i, name in ipairs(styles) do
    if unsupported[name] and not fontReady then
      local x, y = ((i - 1) % columns) * width, math.floor((i - 1) / columns) * height
      love.graphics.setCanvas(canvas)
      love.graphics.setColor(0.1, 0.1, 0.1)
      love.graphics.printf('SVG text\nExport supported\nPreview unavailable', x, y + 24, width, 'center')
      love.graphics.printf(name, x, y + 120, width, 'center')
      love.graphics.setCanvas()
      print('PREVIEW LIMITATION: ' .. name .. ' (SVG text; generation verified separately)')
    else
    local ok, message = pcall(function()
      local renderOptions = {width = 112, height = 112}
      if unsupported[name] then renderOptions.fonts = {['system-ui'] = 'examples/fonts/Abel-Regular.ttf'} end
      local document = adapter.new(name, {seed = 'Ada Lovelace', backgroundColor = {}}, renderOptions)
      local pixels = document:getImageData()
      local visible = 0
      for y = 0, 111, 2 do
        for x = 0, 111, 2 do
          local _, _, _, alpha = pixels:getPixel(x, y)
          if alpha > 0 then visible = visible + 1 end
        end
      end
      local x, y = ((i - 1) % columns) * width, math.floor((i - 1) / columns) * height
      love.graphics.setCanvas(canvas)
      love.graphics.setColor(1, 1, 1)
      document:draw(x + 8, y + 4)
      love.graphics.setColor(0.1, 0.1, 0.1)
      love.graphics.printf(name, x, y + 120, width, 'center')
      love.graphics.setCanvas()
      document:resize(64, 64)
      assert(document:getImageData():getWidth() == 64)
      document:release()
      assert(visible > 0, 'transparent result without background')
      rendered = rendered + 1
    end)
    if not ok then failures[#failures + 1] = name .. ': ' .. tostring(message) end
    end
  end
  canvas:newImageData():encode('png', 'catalog-smoke.png')
  canvas:release()
  print('Catalog preview: ' .. love.filesystem.getSaveDirectory() .. '/catalog-smoke.png')
  assert(#failures == 0, table.concat(failures, '\n'))
  assert(#love.filesystem.getDirectoryItems('love-dicebear-temp') == 0, 'temporary SVGs leaked')
  print('PASS: ' .. rendered .. ' catalog styles render, resize, and release without a background')
end
