local oldLove, oldExecute = love, os.execute
local oldFilesystem, oldThread = package.loaded['love.filesystem'], package.loaded['love.thread']
local files, command, result, cancelled, failing = {}, nil, nil, false, false
local directory = 'love-dicebear-http/request-1'
local ok, message = pcall(function()
  love = {filesystem = {
    getSaveDirectory = function() return "/tmp/a user's game" end,
    write = function(path, value) files[path] = value; return true end,
    read = function(path) return files[path] end,
    remove = function(path) files[path] = nil; return true end,
  }}
  package.loaded['love.filesystem'], package.loaded['love.thread'] = true, true
  local replies = {push = function(_, value) result = value end}
  local cancel = {peek = function() return cancelled end}
  os.execute = function(value)
    command = value
    local config = assert(files[directory .. '/curl.conf'])
    assert(config:find('max-time = 4', 1, true) and config:find('proto-redir = "=https"', 1, true))
    assert(not command:find('api.dicebear.com', 1, true), 'URL reached the shell')
    assert(command:find("a user'\\''s game", 1, true), 'shell path was not escaped')
    if failing then files[directory .. '/error.txt'] = 'HTTP 429'; return 1 end
    files[directory .. '/response.png'] = 'PNG fixture'; return 0
  end
  local run = assert(loadfile('love_dicebear/http_worker.lua'))
  run('https://api.dicebear.com/11.x/initials/png?seed=%22%26%24', directory, 4, false, replies, cancel)
  assert(result.bytes == 'PNG fixture' and next(files) == nil)
  failing = true
  run('https://api.dicebear.com/11.x/initials/png', directory, 4, false, replies, cancel)
  assert(result.error:find('HTTP 429', 1, true) and next(files) == nil)
  cancelled, result, command = true, nil, nil
  run('https://api.dicebear.com/11.x/initials/png', directory, 4, false, replies, cancel)
  assert(result == nil and command == nil and next(files) == nil)
end)
love, os.execute = oldLove, oldExecute
package.loaded['love.filesystem'], package.loaded['love.thread'] = oldFilesystem, oldThread
assert(ok, message)
print('PASS: HTTP worker configuration, shell isolation, failures, cancellation, and file cleanup')
