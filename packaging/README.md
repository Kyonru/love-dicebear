# love-dicebear @VERSION@

Generate customizable DiceBear avatars locally in Lua and LÖVE.
Includes all 63 bundled styles and optional ThorVG and HTTP adapters.

[Documentation](https://kyonru.github.io/love-dicebear/) ·
[Source](https://github.com/Kyonru/love-dicebear)

## Install

Copy `love_dicebear.lua` and `love_dicebear/` from this folder into your game's
root. Keep `LICENSE`, `STYLES.md`, `THIRD_PARTY.md`, and the two license files in
`vendor/` with distributed copies. The generator supports Lua 5.1+ and LÖVE 11.x.

```lua
local dicebear = require('love_dicebear')
local svg, settings = dicebear.generate('bottts', {seed = 'player-42'})
love.filesystem.write('avatar.svg', svg)
```

The same style, seed and options produce the same SVG. Use `dicebear.styles()`
to list styles and `dicebear.describe(style)` to discover customization options.
See the [editor guide](https://kyonru.github.io/love-dicebear/customization/).

## Optional rendering

The core generator needs no network access or additional dependencies.
This archive includes adapter code, but does not bundle their dependencies:

- **Bring your own renderer:** pass the generated SVG string to your chosen SVG
  library. No registration or ThorVG-compatible interface is required. See the
  [BYOR guide](https://kyonru.github.io/love-dicebear/renderers/).
- **Local SVG rendering with ThorVG:** install [love-thorvg](https://github.com/Kyonru/love-thorvg)
  separately, beside `love_dicebear/`. See the
  [ThorVG guide](https://kyonru.github.io/love-dicebear/thorvg/) for setup and SVG text limitations.
- **HTTP PNG rendering:** the HTTP adapter requires desktop LÖVE, system `curl`,
  and access to your configured API (or a fresh cached PNG). See the
  [HTTP and caching guide](https://kyonru.github.io/love-dicebear/http/).

No renderer is downloaded or enabled automatically by the library.
Development scripts and the interactive example are available in the source repository.

## Animation

Use love-thorvg **0.3.0** or newer for local playback:

```lua
local avatar = require('love_dicebear.thorvg').new('cats', {seed = 'Milo', animation = true})
function love.update(dt) avatar:update(dt) end
function love.draw() avatar:draw(32, 32) end
function love.quit() avatar:release() end
```

`dicebear.generate('cats', {animation = true})` exports SVG with CSS keyframes
for browser playback. Animation stays off by default. Native applications
control reduced motion themselves; exported SVG respects the browser's preference.
HTTP PNG output is static. See the [animation guide](https://kyonru.github.io/love-dicebear/thorvg/#animation).

## License

Library code is MIT licensed. Artwork licenses vary; see `STYLES.md` and
`THIRD_PARTY.md`. This is an independent Lua port of DiceBear.
