-- Optional URL-keyed PNG cache in the game's LÖVE save directory.
local M = {}
local directory = 'love-dicebear-cache'

function M.path(url)
  assert(type(url) == 'string', 'cache URL must be a string')
  local digest = love.data.encode('string', 'hex', love.data.hash('sha256', url))
  return directory .. '/' .. digest .. '.png'
end

function M.configure(url, settings)
  local option = settings.cache
  if option == nil or option == false then return nil end
  assert(option == true or type(option) == 'table', 'cache must be true, false, or a table with ttl')
  local ttl = 86400
  if type(option) == 'table' and option.ttl ~= nil then ttl = option.ttl end
  assert(type(ttl) == 'number' and ttl == ttl and ttl >= 1 and ttl < math.huge, 'cache ttl must be a finite number of seconds >= 1')
  assert(settings.refresh == nil or type(settings.refresh) == 'boolean', 'refresh must be a boolean')
  return {path = M.path(url), ttl = ttl, refresh = settings.refresh == true}
end

function M.read(config)
  if not config or config.refresh then return nil end
  local info = love.filesystem.getInfo(config.path)
  if not info or info.type ~= 'file' or not info.modtime or not info.size or info.size > 5242880 then return nil end
  local age = os.time() - info.modtime
  if age < 0 or age >= config.ttl then return nil end
  return love.filesystem.read(config.path)
end

function M.write(config, bytes)
  if not love.filesystem.createDirectory(directory) then return nil, 'could not create PNG cache directory' end
  return love.filesystem.write(config.path, bytes)
end

function M.clear(url)
  local path = M.path(url)
  if not love.filesystem.getInfo(path) then return true end
  local ok = love.filesystem.remove(path)
  return ok, not ok and 'could not remove cached PNG' or nil
end

return M
