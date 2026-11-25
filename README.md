# love-dicebear

Customizable [DiceBear](https://www.dicebear.com/) avatars for Lua and
[LÖVE](https://love2d.org/). Generate deterministic SVGs locally, render them
with your choice of SVG renderer, or download PNGs through the optional HTTP
adapter. [love-thorvg](https://github.com/Kyonru/love-thorvg) is an optional
integration, never a requirement for generation.

**[Documentation](https://kyonru.github.io/love-dicebear/)** ·
[Style catalog](STYLES.md) · [Contributing](contribute.md)

- **Bundled DiceBear styles**, including Adventurer, Avataaars, Bottts, Lorelei,
  Micah, Notionists, Open Peeps, Pixel Art, and Initials.
- **Local generation** in pure Lua, with no network or Node.js runtime required.
- **Customizable avatars** with variants, colors, visibility, and transforms.
- **Editor support** through option descriptors and reproducible saved settings.
- **Optional HTTP PNGs** with native LÖVE Images, saving, and URL caching.

## Install

Download `love-dicebear-<version>.zip` from [GitHub Releases](https://github.com/Kyonru/love-dicebear/releases),
extract it, and copy `love_dicebear.lua` and `love_dicebear/` into your game's root.
You can also copy those files directly from a source checkout.
The generator works with Lua 5.1+ and LÖVE 11.x / LuaJIT.
Release ZIPs contain the library and notices; optional renderer dependencies
are installed separately. Each release includes `SHA256SUMS` for verification.

Keep `LICENSE`, `THIRD_PARTY.md`, `STYLES.md`, `vendor/DICEBEAR-LICENSE`, and
`vendor/UNICODE-LICENSE` with distributed copies. Tests, scripts, raw style JSON,
and Node dependencies are not needed in your game.

## Generate an avatar

```lua
local dicebear = require('love_dicebear')

local svg, settings = dicebear.generate('bottts', {
  seed = 'player-42',
  eyesVariant = 'happy',
  mouthVariant = 'smile01',
  baseColor = '#448ef4',
  backgroundColor = '#e8edf2',
  size = 256,
})

love.filesystem.write('avatar.svg', svg)
```

The same style, seed, and options produce the same SVG. Save the returned
`settings` to reproduce an avatar, or edit them to customize it. Use
`dicebear.styles()` to list styles and `dicebear.describe(style)` to discover
available options for an editor.

See [customization](https://kyonru.github.io/love-dicebear/customization/) and the
[options reference](https://kyonru.github.io/love-dicebear/options/) for details.

## Display and save

| Renderer | Use it for |
| --- | --- |
| [Bring your own renderer](https://kyonru.github.io/love-dicebear/renderers/) | Pass generated SVG to your preferred renderer; no adapter registration needed |
| [love-thorvg](https://kyonru.github.io/love-dicebear/thorvg/) | Local SVG previews in LÖVE using the native renderer |
| [HTTP adapter](https://kyonru.github.io/love-dicebear/http/) | API-rendered PNGs, ordinary LÖVE Images, saving, and optional disk caching |

SVG generation is independent of rendering. Local previews of `initials` and
`initial-face` require an explicitly supplied font and a love-thorvg build with
SVG font preloading (included in love-thorvg v0.3.0). See the ThorVG guide above.
HTTP rendering requires desktop LÖVE, `curl`, and access to the configured API,
unless a fresh cached image is available.

## Animated avatars

Version **2.0.0** adds opt-in animation for the 21 animated styles in DiceBear 11.
For desktop LÖVE, use **love-thorvg 0.3.0**, powered by **ThorVG 1.2.0-dev**
(pinned to `7793957774e5b494c07ac77cf555789ce3ae059c`).

```lua
local avatars = require('love_dicebear.thorvg')
local avatar = avatars.new('cats', {seed = 'Milo', animation = true})
function love.update(dt) avatar:update(dt) end
function love.draw() avatar:draw(32, 32) end
function love.quit() avatar:release() end
```

Use `animationSpeed`, `animationDelay`, and named controls such as `wagAnimation`
to tune playback. SVG export embeds CSS keyframes for browser playback and respects
reduced-motion preferences by default. In native LÖVE, the application controls
reduced motion by disabling animation. HTTP PNG previews remain static.
See the [animation guide](https://kyonru.github.io/love-dicebear/thorvg/#animation).

Run `npm run dev` (or `love .` after setup) to start with an animated cat.
Press **A** or click **Animation** to toggle motion; the setting stays selected
when switching styles with Tab / Shift+Tab or generating a new avatar with R.
Use `love . --no-animate` to start with motion off. Only styles and variants with
timelines animate; HTTP PNG previews remain static. Text styles automatically
use the bundled Abel font; pass `--font path/to/font.ttf` to use another font.

## Try the example

From a checkout, with LÖVE 11.x and Node.js 22+ installed:

```sh
npm run dev
```

The launcher installs love-thorvg and opens the avatar browser. Browse styles,
edit avatar settings, and save SVGs, or switch to HTTP rendering for PNGs and cache
controls. See [getting started](https://kyonru.github.io/love-dicebear/getting-started/)
for setup and controls.

## License

The library code is MIT licensed. Artwork licenses vary by style; see
[STYLES.md](STYLES.md) and [THIRD_PARTY.md](THIRD_PARTY.md).
This is an independent Lua port of DiceBear.
