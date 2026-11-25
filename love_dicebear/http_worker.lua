-- Runs in a LÖVE worker thread. No graphics calls or shell-interpolated URLs.
require('love.filesystem')
require('love.thread')
local url, directory, timeout, windows, result, cancelled = ...
local files = {'curl.conf', 'response.png', 'error.txt'}
local function cleanup()
  for _, name in ipairs(files) do love.filesystem.remove(directory .. '/' .. name) end
  love.filesystem.remove(directory)
end
local function configString(value)
  return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
end
local function shellPath(path)
  if windows then
    assert(not path:find('[%%!"\r\n]'), 'curl configuration path contains unsupported Windows shell characters')
    return '"' .. path .. '"'
  end
  return "'" .. path:gsub("'", "'\\''") .. "'"
end
local ok, payload = pcall(function()
  if cancelled:peek() then return end
  local absolute = love.filesystem.getSaveDirectory() .. '/' .. directory
  local config = table.concat({
    'url = ' .. configString(url),
    'output = ' .. configString(absolute .. '/response.png'),
    'stderr = ' .. configString(absolute .. '/error.txt'),
    'silent', 'show-error', 'fail', 'location', 'max-redirs = 3',
    'proto = "=http,https"',
    'proto-redir = "=' .. (url:match('^https:') and 'https' or 'http,https') .. '"',
    'max-time = ' .. timeout, 'connect-timeout = ' .. math.min(timeout, 10),
    'max-filesize = 5242880',
  }, '\n')
  assert(love.filesystem.write(directory .. '/curl.conf', config))
  local command = (windows and 'curl.exe' or 'curl') .. ' -q --config ' .. shellPath(absolute .. '/curl.conf')
  local success, _, code = os.execute(command)
  if success ~= true and success ~= 0 then
    local detail = love.filesystem.read(directory .. '/error.txt') or ''
    error('HTTP download failed: ' .. (detail ~= '' and detail:sub(1, 1024)
      or ('curl could not run (exit ' .. tostring(code or success) .. '); install curl and check PATH')), 0)
  end
  local bytes, err = love.filesystem.read(directory .. '/response.png')
  assert(bytes, err)
  assert(#bytes <= 5242880, 'HTTP image exceeds the 5 MiB limit')
  return bytes
end)
cleanup()
if not cancelled:peek() then result:push(ok and {bytes = payload} or {error = tostring(payload)}) end
