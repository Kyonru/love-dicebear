# HTTP rendering and caching
```lua
local http = require('love_dicebear.http')
local avatar

function love.load()
  avatar = http.new('initials', {seed = 'Ada Lovelace', size = 256}, {
    cache = {ttl = 3600}, -- optional: one hour; omit to disable
    timeout = 20,
  })
end

function love.update(dt)
  avatar:update()
end

function love.draw()
  avatar:draw(40, 40) -- draws once ready; otherwise a no-op
end

function love.keypressed(key)
  if key == 's' then
    local ok, err = avatar:save('avatar.png')
    if not ok then print(err) end
  end
end

function love.quit()
  if avatar then avatar:release() end
end
```

`getImage()` returns an ordinary `love.graphics.Image` once ready, so you can
also pass it to your own draw/UI code. The request owns that image: `release()`
releases it. `save(path)` writes the original PNG bytes without re-encoding;
it returns `nil, message` while the image is unavailable or if writing fails.

Call `update()` until `getStatus()` is `ready` or `error`. Other states are
`queued`, `loading`, and `cancelled`. `getError()` exposes download or decode
failures. At most two workers download concurrently. Releasing an in-flight
request discards its result; its curl process finishes or times out in the
background. No automatic retries are made. The example debounces edits before
requesting a new PNG.

This backend uses system `curl` in `love.thread`; HTTPS certificate verification
stays enabled. It requires desktop process execution and a writable save
directory. It is not a web/mobile transport. The live download, image draw,
save, and cache tests have been verified on macOS. Temporary request files are
cleaned on completion or handled failure.

### Optional URL cache

- `cache = true`: enable a disk cache with a 24-hour lifetime.
- `cache = {ttl = 3600}`: set a lifetime in seconds, at least 1.
- `refresh = true`: bypass reading the cache and replace it after a successful download.
- `getSource()`: returns `network` or `cache` after the image is ready.
- `http.clearCache(avatar.url)`: remove the entry for that exact URL.
- `getCacheError()`: reports nonfatal cache-read/write issues or a rejected corrupt entry.

The cache key is a SHA256 of the full, consistently ordered request URL,
including the endpoint, style, seed, and options. PNGs live under
`love-dicebear-cache/` in the game's save directory. Fresh entries work offline.
Expired entries are refreshed; corrupt entries are discarded and fetched again.
Cache-write errors do not prevent displaying or explicitly saving a downloaded
image. There is no automatic cache size budget or global eviction policy;
games can manage that policy or leave caching disabled and own their cache.

### API options and hosting

The default endpoint is `https://api.dicebear.com/10.x`. To use a self-hosted
instance, pass `{baseUrl = 'https://avatars.example.com/10.x'}` as the third
argument. `http.url(style, options, settings)` returns the encoded PNG URL
without starting a request and can be used with your own downloader/cache.

Use the original options for HTTP requests. Scalar choices, variant arrays,
weight maps, numeric ranges, and color palettes are encoded as API query
parameters. Local per-alias overrides cannot be represented by this API and
are rejected. Default `fontFamily`/`fontWeight` values are omitted; custom fonts,
weights, and `title` are rejected because the public service disables them.
PNG sizes are limited to integer values from 1 to 256 (default 256).

HTTP rendering sends the seed and selected options to the configured server.
The hosted service may update styles independently of this library's pinned
definitions, so local and remote output are not guaranteed to match exactly.
The [DiceBear HTTP API documentation](https://www.dicebear.com/integrations/http-api/)
describes its PNG limits and non-commercial public-service terms; use a
self-hosted instance for commercial use. Artwork licenses still apply.
