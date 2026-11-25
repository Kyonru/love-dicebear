-- Native integration: love . --font-test (requires SVG font preloading).
return function()
  local dicebear = require('love_dicebear')
  local adapter = require('love_dicebear.thorvg')
  local thorvg = require('love_thorvg')
  assert(thorvg.capabilities and thorvg.capabilities.svgFonts, 'install the SVG-font-capable renderer first')
  local fonts = {Abel = 'examples/fonts/Abel-Regular.ttf'}
  local settings = {width = 256, height = 256, fonts = fonts}
  local documents = {}
  for _, style in ipairs({'initials', 'initial-face'}) do
    local input = {seed = 'Ada Lovelace', fontFamily = 'Abel', backgroundColor = {}}
    local doc = adapter.new(style, input, settings)
    local pixels = doc:getImageData()
    local svg = dicebear.generate(style, input)
    local stripped, count = svg:gsub('<text[%s>].-</text>', '')
    assert(count > 0)
    local path = 'font-test-without-text.svg'
    assert(love.filesystem.write(path, stripped))
    local baseline = thorvg.new(path, {width = 256, height = 256})
    love.filesystem.remove(path)
    local without = baseline:getImageData()
    local visible, changed = 0, 0
    for y = 0, 255 do for x = 0, 255 do
      local r, g, b, a = pixels:getPixel(x, y)
      local r0, g0, b0, a0 = without:getPixel(x, y)
      if a > 0 then visible = visible + 1 end
      if r ~= r0 or g ~= g0 or b ~= b0 or a ~= a0 then changed = changed + 1 end
    end end
    baseline:release()
    assert(visible > 100 and changed > 100, style .. ': font did not affect rendered pixels')
    pixels:encode('png', style .. '-font-smoke.png')
    print(style .. ': ' .. changed .. ' pixels differ from SVG without text')
    documents[#documents + 1] = doc
  end
  local canvas = love.graphics.newCanvas(544, 300)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0.94, 0.95, 0.96, 1)
  love.graphics.setColor(1, 1, 1)
  documents[1]:draw(8, 8)
  documents[2]:draw(280, 8)
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.print('initials', 16, 276)
  love.graphics.print('initial-face', 288, 276)
  love.graphics.setCanvas()
  local preview = canvas:newImageData()
  preview:encode('png', 'svg-fonts-smoke.png')
  preview:release()
  canvas:release()
  love.graphics.setColor(1, 1, 1)
  documents[1]:release()
  collectgarbage('collect')
  documents[2]:resize(128, 128)
  assert(documents[2]:getImageData():getWidth() == 128, 'shared font lifetime failed')
  documents[2]:release()
  local ok, err = pcall(adapter.new, 'initials', {fontFamily = 'Abel'}, {
    fonts = {Abel = 'missing-font.ttf'},
  })
  assert(not ok and tostring(err):find('font not found', 1, true), tostring(err))
  assert(#love.filesystem.getDirectoryItems('love-dicebear-temp') == 0, 'font load failure leaked a staged SVG')
  -- Font maps must also support virtual/custom assets without real filesystem paths.
  local fontBytes = assert(love.filesystem.read(fonts.Abel))
  local doc = adapter.new('initials', {seed = 'Custom', fontFamily = 'Virtual'}, {
    fonts = {Virtual = 'virtual.ttf'},
    assetResolver = function(source, kind)
      assert(source == 'name:Virtual' and kind == 'font')
      return fontBytes
    end,
  })
  doc:getImageData()
  doc:release()
  -- A failed LÖVE texture allocation must release native font ownership too.
  local badSettings = {width = 0, fonts = {AllocationFailure = 'virtual.ttf'},
    assetResolver = function() return fontBytes end}
  ok, err = pcall(adapter.new, 'initials', {seed = 'Allocation', fontFamily = 'AllocationFailure'}, badSettings)
  assert(not ok and tostring(err):find('render dimensions', 1, true))
  badSettings.width = 128
  badSettings.assetResolver = function() return fontBytes .. '\0' end
  doc = adapter.new('initials', {seed = 'Allocation', fontFamily = 'AllocationFailure'}, badSettings)
  doc:getImageData()
  doc:release()
  print('Font previews: ' .. love.filesystem.getSaveDirectory())
  print('PASS: both text styles, shared font ownership, custom resolver and missing-font cleanup')
end
