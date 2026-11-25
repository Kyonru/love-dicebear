local oldLove = love
local threads, files, released = {}, {}, 0
local modified, hashes, hashCount, failCacheWrite = {}, {}, 0, false
local function channel()
  return {
    push = function(self, value) self.value = value end,
    pop = function(self) local value = self.value; self.value = nil; return value end,
    peek = function(self) return self.value end,
    clear = function(self) self.value = nil end,
  }
end
local bytes = '\137PNG\r\n\26\n' .. '\0\0\0\13IHDR' .. '\0\0\0\2\0\0\0\2' .. 'fixture'
local ok, message = pcall(function()
  love = {
    system = {getOS = function() return 'OS X' end},
    filesystem = {
      getInfo = function(path)
        if files[path] then return {type = 'file', size = #files[path], modtime = modified[path] or os.time()} end
      end,
      createDirectory = function() return true end,
      remove = function(path) files[path] = nil; return true end,
      read = function(path) return files[path] end,
      newFileData = function(value) assert(value == bytes); return {release = function() end} end,
      write = function(path, value)
        if failCacheWrite and path:find('love-dicebear-cache/', 1, true) then return nil, 'disk full' end
        files[path], modified[path] = value, os.time(); return true
      end,
    },
    data = {
      hash = function(algorithm, url)
        assert(algorithm == 'sha256')
        if not hashes[url] then hashCount = hashCount + 1; hashes[url] = tostring(hashCount) end
        return hashes[url]
      end,
      encode = function(container, encoding, digest)
        assert(container == 'string' and encoding == 'hex'); return digest
      end,
    },
    image = {newImageData = function() return {release = function() end} end},
    graphics = {newImage = function() return {release = function() released = released + 1 end} end},
    thread = {newChannel = channel, newThread = function(path)
      assert(path == 'love_dicebear/http_worker.lua')
      local thread = {running = true}
      function thread:start(url, dir, timeout, windows, result, cancelled)
        self.result, self.cancelled = result, cancelled
      end
      function thread:isRunning() return self.running end
      function thread:getError() return self.error end
      threads[#threads + 1] = thread
      return thread
    end},
  }
  local http = require('love_dicebear.http')
  local a, b, c = http.new('initials', {seed = 'Ada'}), http.new('bottts'), http.new('lorelei')
  assert(c:getStatus() == 'queued' and #threads == 2, 'unbounded download concurrency')
  assert(not a:save('early.png'))
  threads[1].result:push({bytes = bytes}); threads[1].running = false
  assert(a:update() == 'ready' and a:getImage())
  assert(a:save('avatar.png') and files['avatar.png'] == bytes, 'saved bytes changed')
  assert(c:update() == 'loading' and #threads == 3)
  b:release(); b:release()
  threads[2].result:push({bytes = bytes}); threads[2].running = false
  assert(b:update() == 'cancelled' and not b:getImage(), 'cancelled result became visible')
  threads[3].result:push({bytes = '<html>not an image</html>'}); threads[3].running = false
  assert(c:update() == 'error' and c:getError():find('not a PNG', 1, true))
  local d = http.new('bottts')
  threads[4].result:push({error = 'HTTP 429'}); threads[4].running = false
  assert(d:update() == 'error' and d:getError() == 'HTTP 429')
  assert(not d:save('error.png'))
  a:release(); c:release(); d:release()
  assert(released == 1, 'texture leaked or was released twice')
  local first = http.new('initials', {seed = 'cache'}, {cache = true})
  threads[5].result:push({bytes = bytes}); threads[5].running = false
  assert(first:update() == 'ready' and first:getSource() == 'network')
  local cachePath = first.cache.path
  assert(files[cachePath] == bytes)
  first:release()
  local hit = http.new('initials', {seed = 'cache'}, {cache = {ttl = 3600}})
  assert(#threads == 5 and hit:update() == 'ready' and hit:getSource() == 'cache')
  assert(hit:save('cached.png') and files['cached.png'] == bytes)
  hit:release()
  modified[cachePath] = os.time() - 3601
  local expired = http.new('initials', {seed = 'cache'}, {cache = {ttl = 3600}})
  assert(expired:getStatus() == 'loading' and #threads == 6)
  expired:release(); threads[6].running = false
  modified[cachePath] = os.time()
  local refresh = http.new('initials', {seed = 'cache'}, {cache = true, refresh = true})
  assert(refresh:getStatus() == 'loading' and #threads == 7)
  refresh:release(); threads[7].running = false
  files[cachePath] = 'corrupt cache'
  local corrupt = http.new('initials', {seed = 'cache'}, {cache = true})
  assert(corrupt:update() == 'loading' and #threads == 8)
  assert(corrupt:getCacheError():find('invalid cached PNG', 1, true))
  assert(files[cachePath] == nil)
  failCacheWrite = true
  threads[8].result:push({bytes = bytes}); threads[8].running = false
  assert(corrupt:update() == 'ready' and corrupt:getCacheError() == 'disk full')
  assert(corrupt:save('uncached.png'), 'cache failure prevented saving the downloaded image')
  corrupt:release(); failCacheWrite = false
  files[cachePath] = bytes
  local disabled = http.new('initials', {seed = 'cache'})
  assert(disabled:getStatus() == 'loading' and #threads == 9, 'cache is not opt-in')
  disabled:release(); threads[9].running = false
  assert(http.clearCache(first.url) and files[cachePath] == nil)
  assert(not pcall(http.new, 'initials', {}, {cache = {ttl = 0}}))
  assert(not pcall(http.new, 'initials', {}, {cache = {ttl = false}}))
end)
love = oldLove
package.loaded['love_dicebear.http'] = nil
assert(ok, message)
print('PASS: HTTP lifecycle, saving, concurrency, cache hits, expiry, refresh, corruption and cache write failures')
