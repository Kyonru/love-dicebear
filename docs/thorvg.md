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
love-thorvg **0.3.0** or newer with its matching native library. The adapter
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

The launcher pins v0.3.0. Existing manual installations are preserved; replace
an older `love_thorvg/` directory with the complete v0.3.0 package to upgrade. Without a
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

## Animation

love-dicebear 2.0.0 plays the catalog's declarative timelines through
love-thorvg 0.3.0's SVG element API. The bundled engine is ThorVG 1.2.0-dev,
pinned to `7793957774e5b494c07ac77cf555789ce3ae059c`.

```lua
local avatar = avatars.new('dogs', {
  seed = 'Milo', animation = true, animationSpeed = 1.2,
  wagAnimationSpeed = 0.8,
}, {width = 256, height = 256})

function love.update(dt) avatar:update(dt) end
function love.draw() avatar:draw(32, 32) end
function love.quit() avatar:release() end
```

Animation is off by default. `animation = true` enables all timelines selected
by the avatar's artwork. `wagAnimation = false` disables only the named timeline;
`wagAnimation = true` enables it even when global animation is off. The named
controls available to a style appear in `dicebear.describe(style).options`.
Some variants in an animated style may still be static.

The player evaluates translation, rotation, scale, opacity, easing, delay,
direction, and fill behavior in Lua and edits the loaded SVG scene in place.
It reuses the native document and the uncached LÖVE texture. Each track loops on
its own duration, and transforms pivot around the resting SVG fill-box geometry.
This does not rely on ThorVG interpreting browser CSS animations.

Call `pause()`, `play()`, or `seek(seconds)` to control playback. `seek(0)` restores
the first animation frame. `setProgress(0..1)` maps to the longest single timeline
cycle including positive delay; independent cycles need not align at its end.
`autoplay = false` starts paused, `speed` scales the player's clock, and
`loop = false` stops at the end of that longest cycle. Native applications must
implement reduced-motion preferences by passing `animation = false` (and disabling
any named overrides). `animationRespectReducedMotion` controls exported CSS only.

Animated element edits invalidate the renderer's frame cache, so leave
`frameCache = 0` for continuous animation. The experimental web backend does not
expose SVG element editing. An older or unsupported renderer raises a capability
error before staging the avatar; static SVG generation remains dependency-free.
