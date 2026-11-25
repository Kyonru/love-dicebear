-- Optional desktop HTTP renderer. PNG decoding/upload happen on the main thread;
-- the network request runs in a worker and never blocks love.update/draw.
local url = require('love_dicebear.http_url')
local cache = require('love_dicebear.http_cache')
local M = {url = url.build, clearCache = cache.clear}
local Request = {}
Request.__index = Request
local counter = 0
local active = {}

local function start(self)
  for i = #active, 1, -1 do if not active[i]:isRunning() then table.remove(active, i) end end
  if #active >= 2 then return end
  local directory
  repeat
    counter = counter + 1
    directory = 'love-dicebear-http/request-' .. counter
  until not love.filesystem.getInfo(directory)
  local ok, message = pcall(function()
    assert(love.filesystem.createDirectory(directory), 'could not create HTTP staging directory')
    self.thread = love.thread.newThread('love_dicebear/http_worker.lua')
    self.thread:start(self.url, directory, self.timeout, love.system.getOS() == 'Windows', self.channel, self.cancelled)
  end)
  if not ok then
    love.filesystem.remove(directory)
    self.status, self.error = 'error', tostring(message)
    return
  end
  active[#active + 1] = self.thread
  self.status = 'loading'
end

local function dimension(bytes, offset)
  local a, b, c, d = bytes:byte(offset, offset + 3)
  return ((a * 256 + b) * 256 + c) * 256 + d
end

function Request:update()
  if self.status == 'queued' then start(self) end
  if self.status ~= 'loading' then return self.status end
  local message = self.channel:pop()
  local threadError = self.thread and self.thread:getError()
  if threadError then self.status, self.error = 'error', threadError
  elseif message then
    if message.error then self.status, self.error = 'error', message.error
    else
      local ok, image = pcall(function()
        local bytes = message.bytes
        assert(type(bytes) == 'string' and #bytes >= 24 and bytes:sub(1, 8) == '\137PNG\r\n\26\n'
          and bytes:sub(13, 16) == 'IHDR', 'HTTP response is not a PNG image')
        local width, height = dimension(bytes, 17), dimension(bytes, 21)
        assert(width >= 1 and height >= 1 and width <= 256 and height <= 256, 'HTTP PNG dimensions exceed 256×256')
        local file = love.filesystem.newFileData(bytes, 'avatar.png')
        local decoded, pixels = pcall(love.image.newImageData, file)
        file:release()
        if not decoded then error(pixels, 0) end
        local uploaded, texture = pcall(love.graphics.newImage, pixels)
        pixels:release()
        if not uploaded then error(texture, 0) end
        return texture
      end)
      if ok then
        self.image, self.bytes, self.status = image, message.bytes, 'ready'
        self.source = message.source or 'network'
        if self.cache and self.source == 'network' then
          local saved, err = cache.write(self.cache, message.bytes)
          if not saved then self.cacheError = err or 'could not cache PNG' end
        end
      elseif message.source == 'cache' then
        cache.clear(self.url)
        self.cacheError = 'Ignored invalid cached PNG: ' .. tostring(image)
        self.status = 'queued'
        start(self)
      else self.status, self.error = 'error', tostring(image) end
    end
  end
  return self.status
end

function Request:getStatus() return self.status end
function Request:getError() return self.error end
function Request:getImage() return self.image end
function Request:getSource() return self.source end
function Request:getCacheError() return self.cacheError end
function Request:draw(...)
  if self.image then love.graphics.draw(self.image, ...) end
end
function Request:save(path)
  if self.status ~= 'ready' then return nil, 'PNG is not ready to save (' .. self.status .. ')' end
  return love.filesystem.write(path, self.bytes)
end
function Request:release()
  if self.status == 'cancelled' then return end
  if self.image then self.image:release(); self.image = nil end
  self.bytes = nil
  self.cancelled:push(true)
  self.channel:clear()
  self.status = 'cancelled'
end

function M.new(style, options, settings)
  assert(love and love.thread and love.graphics and love.image, 'love_dicebear.http requires LÖVE')
  if settings == nil then settings = {} end
  assert(type(settings) == 'table', 'HTTP settings must be a table')
  local address = M.url(style, options, settings)
  local cacheConfig = cache.configure(address, settings)
  local timeout = settings.timeout
  if timeout == nil then timeout = 20 end
  assert(type(timeout) == 'number' and timeout == timeout and timeout >= 1 and timeout <= 60,
    'HTTP timeout must be from 1 to 60 seconds')
  local self = setmetatable({
    url = address, timeout = timeout, status = 'queued', cache = cacheConfig,
    channel = love.thread.newChannel(), cancelled = love.thread.newChannel(),
  }, Request)
  local bytes, cacheError = cache.read(cacheConfig)
  if bytes then
    self.status = 'loading'
    self.channel:push({bytes = bytes, source = 'cache'})
  else
    self.cacheError = cacheError
    start(self)
  end
  return self
end

return M
