---
icon: lucide/cloud-download
---
# HTTP API

```lua
local http = require('love_dicebear.http')
```

Use [the HTTP guide](../http.md) for a complete LÖVE example. `http.url` works in
standalone Lua. Downloading, decoding, saving, and disk caching require desktop
LÖVE; network downloads also require system `curl`.

## `http.url(style, options, settings)`

Returns the encoded PNG URL without starting a request. `options` and `settings`
are optional tables. Only `settings.baseUrl` affects the URL. Validation errors
raise immediately. Query parameters are sorted consistently, making this URL
suitable as a cache key for your own downloader.

```lua
local url = http.url('initials', {seed = 'Ada Lovelace', size = 128})
```

## `http.new(style, options, settings)`

Returns a request object and starts a worker if a slot is available. At most two
workers download concurrently; additional requests stay `queued` until polled
with `update()`. A fresh cache entry skips the network but still needs `update()`
to decode and upload the image on the main thread.

```lua
local request = http.new('initials', {seed = 'Ada', size = 128}, {
  cache = {ttl = 3600},
  timeout = 20,
})
```

### Settings

| Setting | Type and default | Behavior |
| --- | --- | --- |
| `baseUrl` | string; `https://api.dicebear.com/11.x` | HTTP(S) version root; no query, fragment, whitespace, or control characters |
| `timeout` | number; `20` | Total request timeout in seconds, inclusive range 1–60 |
| `cache` | `false` / omitted | Disable disk-cache reads and writes |
| `cache = true` | boolean | Cache for 86,400 seconds (24 hours) |
| `cache = {ttl = seconds}` | table | Finite lifetime of at least 1 second; omitted `ttl` defaults to 86,400 |
| `refresh` | boolean; `false` | With caching enabled, bypass reading and replace the entry after a successful download |

The cache key includes the full URL, so different endpoints, sizes, seeds, and
options use different entries. There is no size-budget eviction or automatic
fallback to expired entries when offline. Cache write failures do not prevent
using the downloaded image.

### Avatar option differences

Use original avatar options, not a locally resolved snapshot with alias choices.

| Option | HTTP behavior |
| --- | --- |
| `size` | Integer 1–256; defaults to 256 |
| Alias `*Variant` / `*Probability` | Rejected; use the source component |
| `title` | Rejected |
| `fontFamily`, `fontWeight` | Only the core defaults are accepted, and omitted from the URL |
| Arrays, palettes, ranges | Encoded as comma-separated values |
| Variant weight maps | Encoded in sorted `name:weight` order |

These restrictions also apply to custom `baseUrl` values. The hosted service
may change independently of the pinned local catalog; identical local and
remote pixels are not guaranteed.

## Request lifecycle

| Status | Meaning | What to do |
| --- | --- | --- |
| `queued` | Waiting for a worker slot | Keep calling `update()` |
| `loading` | Download or cached-image decoding pending | Keep calling `update()` |
| `ready` | Image and original PNG bytes are available | Draw or save; release when finished |
| `error` | Network, staging, or decoding failed | Inspect `getError()`; create a new request to retry |
| `cancelled` | `release()` was called | Do not reuse the image; create a new request |

There are no automatic retries. Releasing an in-flight request discards its
result; it does not kill curl, which finishes or times out in the background.

## Request methods

### `request:update()`

Polls the request, decodes completed PNG data, and returns the current status
string. Call from `love.update` while queued or loading. Calling it after a
terminal state simply returns that state. Network work never blocks this call.

### `request:getStatus()`

Returns the current status without polling or advancing the request.

### `request:getError()`

Returns the stored request error message, or `nil` if none has been recorded.
Argument validation errors in `http.new` or `http.url` raise directly instead.

### `request:getImage()`

Returns the ordinary `love.graphics.Image` after decoding, otherwise `nil`.
The request owns it. Do not release it separately or retain it after releasing
the request.

### `request:draw(...)`

Passes all arguments after `self` to `love.graphics.draw(image, ...)` when an
image exists; otherwise does nothing. For example, `request:draw(40, 40)`.
It does not poll the request and has no return value.

### `request:save(path)`

Writes the original PNG bytes to a path in LÖVE's save directory without
re-encoding. Returns the result of `love.filesystem.write` (`true` on success),
or `nil, message` if not ready. Filesystem failures may return `false, message`;
check `if not ok` in both cases. It does not create parent directories.

### `request:getSource()`

Returns `network` or `cache` after a successful load, otherwise `nil`.
This records where the last image came from; releasing does not reset it.

### `request:getCacheError()`

Returns a nonfatal cache error message, or `nil`. It may describe a read/write
failure or an invalid cached PNG that was discarded before a network retry.
A `ready` request can still have a cache error.

### `request:release()`

Releases the owned Image, discards PNG bytes and pending results, and changes
status to `cancelled`. Calling it repeatedly is safe. No return value.

### `request.url`

The canonical request URL. Treat this field as read-only; use it to identify or
clear the cache entry. Other request fields are implementation details.

## `http.clearCache(url)`

Deletes the disk entry for exactly this URL, regardless of its age. Requires
LÖVE's filesystem and data modules. Returns `true` if removed or already absent,
otherwise `false, message`. It does not cancel a download or release a preview.
A still-running cached request can write its result back later.

```lua
local ok, err = http.clearCache(request.url)
if not ok then print(err) end
```

For service terms, privacy, platform requirements, and a working lifecycle
example, see [HTTP rendering and caching](../http.md).
