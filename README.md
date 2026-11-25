# love-dicebear

Generate customizable [DiceBear](https://www.dicebear.com/) avatars locally in
Lua and LÖVE. The first release includes **Bottts**, with all 53 variants across
eyes, heads, mouths, sides, textures, and tops. No HTTP requests, Node runtime,
native generator, or JSON parser is needed in your game.

SVG generation and rendering are separate. Use any SVG renderer, or the optional
adapter for [love-thorvg](https://github.com/Kyonru/love-thorvg).

## Install

Copy `love_dicebear.lua` and `love_dicebear/` into your game's root. Keep `THIRD_PARTY.md`,
`vendor/DICEBEAR-LICENSE`, and `LICENSE` with distributed copies. The raw JSON,
scripts, tests, and Node development dependencies are not needed at runtime.

```lua
local dicebear = require('love_dicebear')

local svg, settings = dicebear.generate('bottts', {
  seed = 'player-42',
  eyesVariant = 'happy',
  mouthVariant = 'smile01',
  baseColor = '#448ef4',
  backgroundColor = '#e8edf2',
  textureProbability = 0,
  size = 256,
})

love.filesystem.write('avatar.svg', svg)
```

The same style, seed, and options produce the same SVG. The module supports Lua
5.1 syntax and runs in LÖVE 11.x / LuaJIT and standalone Lua. Tests have been run
with Lua 5.4 and LÖVE 11.5 on macOS ARM64. It does not change `math.random` state.

## Build an editor

`describe` returns independent copies of the option descriptors: available
variants, tags, palettes, types, bounds, and defaults. Use these to populate
pickers, color controls, and sliders.

```lua
local description = dicebear.describe('bottts')
local eyeChoices = description.options.eyesVariant.values
local palette = description.options.baseColor.palette

-- Resolve every random choice once, then edit that concrete state.
local settings = dicebear.resolve('bottts', {seed = 'player-42'})
settings.eyesVariant = eyeChoices[1]
settings.baseColor = '#d95c9a'
settings.topProbability = 0
local svg = dicebear.generate('bottts', settings)
```

`generate(style, options)` returns **SVG, resolved settings**. `resolve` returns
the settings without building SVG. The resolved table can be passed back to
`generate` unchanged to reproduce the output, or serialized with your game's
JSON/save library. It contains no functions or native resources.

Visibility resolves to `0` or `100`; hidden features retain their selected
variant so an editor can reveal them later. Empty variant selections and
transparent colors use empty arrays. Resolved settings pin every choice:
changing their seed alone does **not** randomize them. To create a new avatar,
start with `{seed = newSeed}` and whichever restrictions you want to keep.

## Supported options

| Option | Accepted values |
| --- | --- |
| `seed` | UTF-8 string; default `''` |
| `title` | Optional accessible SVG title |
| `size` | Output width/height, 1–8192; omitted by default |
| `eyesVariant`, `headVariant`, `mouthVariant`, `sidesVariant`, `textureVariant`, `topVariant` | One variant name, an array of allowed names, or a `{name = weight}` map |
| Corresponding `*Probability` | 0–100; default 100 except texture, which defaults to 50 |
| `baseColor`, `backgroundColor` | Hex string or palette array; optional `#`; RGB, RGBA, RRGGBB, or RRGGBBAA |
| `flip` | `none`, `horizontal`, `vertical`, `both` |
| `rotate` | −360–360 degrees |
| `scale` | 0–10; `1` is original size |
| `translateX`, `translateY` | −100–100 percent of the canvas |
| `borderRadius` | 0–50 percent of the canvas |

Rotate, scale, translations, and border radius also accept `{min, max}` arrays
(or a one-value array). Empty ranges use the default. Variant weights must be
finite numbers between 0 and 1,000,000; all-zero weights select uniformly.
Empty variant arrays hide the component. Color arrays select a seeded solid
color; an empty background palette is transparent. The default base palette is
bundled in the style. Inputs and returned descriptors are never mutated.

This release supports **Bottts and solid colors**, not the whole DiceBear core.
Other styles, user-supplied definitions, gradients, tag filtering, font options,
and ID randomization are not implemented. Unsupported or misspelled options
raise an error. Tags are exposed as editor metadata only. Multiple generated
SVGs should be loaded as separate documents; inlining them into one DOM can
collide on artwork IDs.

The supported output is tested byte-for-byte against **DiceBear Core 10.7.0**
with the pinned style definition in `vendor/bottts.json`. DiceBear version 9
seeds and option names are not interchangeable with this API. Store the library
version with saved avatars when you need stability across future upgrades.

## Render with love-thorvg

Install its complete `love_thorvg/` directory beside `love_dicebear/`, including
the native binary for your platform. See its README for distribution details.

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

Keep the returned document between frames. When an editor changes settings,
create the replacement document, then release the old one. Do not generate or
rasterize the avatar every `love.draw` call.

Run `love .` from this repository for a small example: Left/Right changes eyes
without changing other features, R generates a new avatar, and S saves SVG.

## Development

```sh
lua tests/run.lua
lua tests/adapter.lua
npm ci --ignore-scripts
npm test
love . --test
love . --render-test  # requires love_thorvg/
```

Node is used only for comparison against the pinned JavaScript reference.
Set `LUA=luajit` to run the parity suite with another Lua executable, or
`LOVE=/path/to/love npm test` to compare SVGs generated inside LÖVE.

The parity suite covers every variant, Unicode seeds, weights, visibility,
palette filtering, XML escaping, and transforms. The native smoke suite checks
all 53 variants produce nonblank images, then resizes and releases each
document. It is not a pixel-by-pixel comparison with another SVG renderer.
Native checks passed against love-thorvg commit
`02bc96e9c63f50a99beba371534fd06a14aae407` on macOS ARM64.

Run `python3 scripts/import_style.py` to regenerate the Lua artwork from the
vendored JSON. Do not edit the generated style directly. Review licensing and
parity before changing the upstream pin.

Code is MIT licensed. Bottts artwork is by **Pablo Stanley** and has its own
terms; see [THIRD_PARTY.md](THIRD_PARTY.md). This is an independent Lua port.
