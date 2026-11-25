-- Explicit opt-in network test: love . --http-test
local M = {}
function M.new()
  local http = require('love_dicebear.http')
  local options = {seed = 'Ada Lovelace', size = 128, backgroundColor = {}}
  local self = {elapsed = 0, frames = 0, request = http.new('initials', options, {
    timeout = 15, cache = true, refresh = true,
  })}
  function self:update(dt)
    if self.done then return end
    self.elapsed, self.frames = self.elapsed + dt, self.frames + 1
    local ok, err = pcall(function()
      assert(self.elapsed < 25, 'HTTP smoke test timed out')
      local status = self.request:update()
      assert(status ~= 'error', self.request:getError())
      if status ~= 'ready' then return end
      local image = self.request:getImage()
      assert(image:typeOf('Image') and image:getWidth() == 128 and image:getHeight() == 128)
      if self.phase == 'cache' then
        assert(self.request:getSource() == 'cache', 'repeat request missed disk cache')
        assert(self.request.bytes == love.filesystem.read('http-smoke-initials.png'))
        assert(http.clearCache(self.request.url))
        self.request:release()
        print('PASS: API PNG, native LÖVE draw, byte-identical save, URL cache hit and cleanup')
        print('HTTP preview: ' .. love.filesystem.getSaveDirectory() .. '/http-smoke-initials.png')
        self.done = true
        love.event.quit(0)
        return
      end
      assert(self.request:save('http-smoke-initials.png'))
      assert(love.filesystem.read('http-smoke-initials.png') == self.request.bytes, 'saved PNG bytes changed')
      local pixels = love.image.newImageData('http-smoke-initials.png')
      assert(pixels:getWidth() == 128)
      pixels:release()
      local canvas = love.graphics.newCanvas(128, 128)
      love.graphics.push('all')
      love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1)
      self.request:draw(0, 0)
      love.graphics.pop()
      pixels = canvas:newImageData()
      local visible = 0
      for y = 0, 127 do for x = 0, 127 do
        local _, _, _, alpha = pixels:getPixel(x, y)
        if alpha > 0 then visible = visible + 1 end
      end end
      pixels:release()
      canvas:release()
      assert(visible > 0, 'HTTP initials image is blank')
      assert(self.frames > 1, 'network work blocked the event loop')
      self.request:release()
      assert(#love.filesystem.getDirectoryItems('love-dicebear-http') == 0, 'HTTP staging files leaked')
      self.request, self.phase = http.new('initials', options, {cache = true}), 'cache'
    end)
    if not ok then
      self.request:release(); self.done = true; print(err); love.event.quit(1)
    end
  end
  return self
end
return M
