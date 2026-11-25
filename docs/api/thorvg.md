---
icon: lucide/scan-line
---
# ThorVG adapter API

```lua
local avatars = require('love_dicebear.thorvg')
```

This module renders locally through the separately installed `love_thorvg`
library. See [the rendering guide](../thorvg.md) for installation and supplied fonts.

## `avatars.new(style, options, renderOptions)`

Returns **a love-thorvg Document and resolved avatar settings**. `options` uses
the [core options](../options.md); both option tables may be omitted.

```lua
local document, settings = avatars.new('bottts', {seed = 'player-42'}, {
  width = 256,
  height = 256,
})
```

The adapter synchronously generates and stages an SVG in LÖVE's save directory,
loads it, and removes the temporary file. It requires LÖVE, a writable save
directory, and the complete love-thorvg wrapper/native installation. Construction
errors raise; staged files are removed after successful or failed renderer loads.

### Render settings

The table is copied and forwarded to love-thorvg, with these adapter rules:

| Setting | Adapter behavior |
| --- | --- |
| `width`, `height` | Requested raster dimensions; absent values use love-thorvg's intrinsic dimensions |
| `autoplay` | Always forced to `false` for static avatars |
| `assetRoot` | Defaults to `''` so supplied font paths resolve from the game root; explicit values are preserved |
| `fonts` | Family → font path map; SVG text needs an entry matching the resolved `fontFamily` |
| Other settings | Forwarded unchanged to the installed love-thorvg version |

Text also requires `love_thorvg.capabilities.svgFonts`. Missing mappings or an
unsupported build raise before a temporary file is written. The published
v0.2.0 native binary does not support font preloading. See [SVG fonts](../thorvg.md#svg-text-and-fonts).

Additional settings supported by the tested desktop wrapper are `filter`
(default `linear`), `frameCache` (default `0`), `threads` (default `0`),
`progress` (default `0`), `speed` (default `1`), `loop` (default `true`),
`resourcePath` (default `''`), `mimeType` (normally inferred from `.svg`), and
`assetResolver(source, kind)`. `assetResolver` returns font/picture bytes as a
string or LÖVE Data, or `nil` when unavailable. Preserve SVG MIME selection for
these generated files. See [love-thorvg's API](https://kyonru.github.io/love-thorvg/API/)
for dependency-specific behavior.

## Returned Document

This is the original love-thorvg object, not a DiceBear-specific wrapper.
Keep it between frames and release it when replaced or no longer needed.

| Method | Behavior / return value |
| --- | --- |
| `draw(x, y, rotation, scaleX, scaleY, originX, originY)` | Render if dirty, then draw; no return value |
| `render()` | Rasterize/upload only if dirty; returns whether a new raster was produced |
| `getImage()` | Render if needed and return the owned LÖVE Image |
| `getImageData()` | Render if needed and return owned pixels; unavailable when frame caching is enabled |
| `resize(width, height)` | Change raster size and invalidate caches; returns the Document |
| `release()` | Free native and LÖVE resources; safe to repeat |
| `clearCache()` | Clear cached frames and mark dirty; returns the Document |
| `getCacheStats()` | Table: `enabled`, `size`, `limit`, `hits`, `misses`, `evictions` |
| `getRenderStats()` | Table: `frames`, `lastRasterSeconds`, `lastUploadSeconds`, `totalRasterSeconds`, `totalUploadSeconds`, `averageRasterSeconds`, `averageUploadSeconds`, `lastCacheHit` |
| `resetRenderStats()` | Reset accumulated rendering counters; returns the Document |
| `setProgress(progress)` | Clamp animation progress to 0–1; returns the Document |
| `seek(seconds)` | Set animation time; returns the Document |
| `update(dt)` | Advance playback when active; returns whether playback advanced |
| `play()` / `pause()` | Change playback state; return the Document |

The playback methods belong to love-thorvg; DiceBear output is static, and the
adapter disables autoplay. Images and pixel buffers are owned by the Document:
do not free them separately or use them after release/resize. Methods and
settings outside this table depend on your installed love-thorvg version.

## Replacing an avatar safely

```lua
local ok, replacement, resolved = pcall(avatars.new, 'bottts', edited, {
  width = 256, height = 256,
})
if ok then
  if document then document:release() end
  document, settings = replacement, resolved
else
  print(replacement) -- keep the existing preview
end
```
