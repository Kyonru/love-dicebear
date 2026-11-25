---
icon: lucide/image
---
# Local rendering with love-thorvg

Use ThorVG to preview locally generated SVGs without a server. For constructor
settings and Document methods, see the [adapter API](api/thorvg.md).
This adapter is optional: you can also [bring your own renderer](renderers.md).

## Install the renderer

Install its complete `love_thorvg/` directory beside `love_dicebear/`, including
the native binary for your platform. See its README for distribution details.

## Draw an avatar

```lua
local avatars = require('love_dicebear.thorvg')
local document

function love.load()
  document = avatars.new('bottts', {seed = 'player-42'}, {
    width = 256, height = 256,
  })
end

function love.draw()
  document:draw(40, 40)
end

function love.quit()
  if document then document:release() end
end
```

`avatars.new(style, options, renderOptions)` returns the ThorVG document and
resolved settings. It stages an SVG in the LÖVE save directory because
love-thorvg currently takes a path, loads it synchronously, then removes the
temporary file even if loading fails. It therefore needs a writable save
directory. Rendering requires LÖVE; the core generator does not.

## SVG text and fonts

`initials` and `initial-face` can render locally when you supply a font and use
an SVG-font-capable love-thorvg build. The published v0.2.0 binary does not
preload SVG fonts; update both its Lua wrapper and native library.
The upstream implementation is tracked in [love-thorvg PR #1](https://github.com/Kyonru/love-thorvg/pull/1). The adapter
checks `thorvg.capabilities.svgFonts` and reports missing support explicitly.

```lua
local document, settings = avatars.new('initials', {
  seed = 'Ada Lovelace',
  fontFamily = 'Abel',
}, {
  width = 256, height = 256,
  fonts = {Abel = 'fonts/Abel-Regular.ttf'},
})
```

The `fonts` key must match the resolved `fontFamily` exactly. To keep the default
family, map `['system-ui']` to your font file instead. A family name alone does
not load an operating-system font. Font paths are relative to the game root
unless you explicitly set `assetRoot` (include its trailing slash). Missing or
invalid supplied fonts raise an error; no font is downloaded automatically.

Use an appropriately licensed TTF or OTF font and distribute its notice.
The repository includes Abel Regular under the SIL Open Font License for the
example and tests; it is excluded from library release ZIPs.

With the updated renderer installed:

```sh
npm run dev -- --style initials --font examples/fonts/Abel-Regular.ttf
npm run dev -- --style initial-face --font examples/fonts/Abel-Regular.ttf
love . --font-test
```

The launcher still pins the published v0.2.0 release, so install the updated
renderer manually first; an existing installation is preserved. Without a
font, the example offers SVG export or an HTTP preview. The experimental web
backend does not yet support SVG font preloading.

Font data is shared across live documents using the same family. That family
must refer to identical bytes until all its documents are released. Supply the
actual font face you need; browser-like fallback and automatic weight/style
matching are not provided. These tests verify visible text and lifecycle;
other renderer differences in filters, blending, or masking remain outside
byte-level SVG generator parity.

## Update a preview

Keep the returned document between frames. When an editor changes settings,
create the replacement document, then release the old one. Do not generate or
rasterize the avatar every `love.draw` call.

Run `npm run dev` (or `love .` after setup) for the catalog example: Up/Down changes
style, Tab selects an avatar setting and Left/Right changes it, and R generates a new
avatar. Saved files are written to LÖVE's save directory; the full path is
printed to the console.
