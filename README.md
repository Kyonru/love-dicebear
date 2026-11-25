# love-dicebear

Customizable [DiceBear](https://www.dicebear.com/) avatars for Lua and
[LÖVE](https://love2d.org/). Generate deterministic SVGs locally, render them
with [love-thorvg](https://github.com/Kyonru/love-thorvg), or download PNGs
through the optional HTTP adapter.

**[Documentation](https://kyonru.github.io/love-dicebear/)** ·
[Style catalog](STYLES.md) · [Contributing](contribute.md)

- **63 bundled styles**, including Adventurer, Avataaars, Bottts, Lorelei,
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
| [love-thorvg](https://kyonru.github.io/love-dicebear/thorvg/) | Local SVG previews in LÖVE using the native renderer |
| [HTTP adapter](https://kyonru.github.io/love-dicebear/http/) | API-rendered PNGs, ordinary LÖVE Images, saving, and optional disk caching |

SVG generation is independent of rendering. Local previews of `initials` and
`initial-face` require an explicitly supplied font and a love-thorvg build with
SVG font preloading (not the published v0.2.0 binary). See the ThorVG guide above.
HTTP rendering requires desktop LÖVE, `curl`, and access to the configured API,
unless a fresh cached image is available.

## Try the example

From a checkout, with LÖVE 11.x and Node.js 22+ installed:

```sh
npm run dev
```

The launcher installs love-thorvg and opens the avatar browser. Browse styles,
change variants, and save SVGs, or switch to HTTP rendering for PNGs and cache
controls. See [getting started](https://kyonru.github.io/love-dicebear/getting-started/)
for setup and controls.

## License

The library code is MIT licensed. Artwork licenses vary by style; see
[STYLES.md](STYLES.md) and [THIRD_PARTY.md](THIRD_PARTY.md).
This is an independent Lua port of DiceBear.
