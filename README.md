# love-dicebear

Generate customizable [DiceBear](https://www.dicebear.com/) avatars locally in
Lua and LÖVE. Includes **all 63 styles** from the pinned DiceBear catalog,
including Adventurer, Avataaars, Bottts, Lorelei, Micah, Notionists, Open Peeps,
Pixel Art, and Initials. See [STYLES.md](STYLES.md) for the full list and licenses.
No HTTP requests, Node runtime,
native generator, or JSON parser is needed in your game.

SVG generation and rendering are separate. Use any SVG renderer, or the optional
adapter for [love-thorvg](https://github.com/Kyonru/love-thorvg).

## Quick start the example

Install [LÖVE 11.x](https://love2d.org/) and Node.js 22 or newer, then run:

```sh
npm run dev
```

This downloads the **love-thorvg v0.2.0** release for your machine, verifies its
pinned SHA256 checksum, installs the renderer and license notices in the ignored
`love_thorvg/` directory, and launches the example. Subsequent runs reuse the
installed renderer and work offline. An existing local renderer is preserved;
an incomplete installation reports an error instead of being overwritten.

Prebuilt packages cover macOS ARM64/x64, Linux x64, and Windows x64. Extraction
uses `unzip` on macOS/Linux or PowerShell on Windows. LÖVE itself must be
installed separately; the launcher checks `PATH`, `/Applications/love.app` on
macOS, and the standard Program Files location on Windows. Use `LOVE` to select
another executable. The example uses love-thorvg for all avatar rendering.

```sh
npm run setup                  # download the renderer without launching
npm run dev -- --render-test    # run native rendering checks
npm run dev -- --style lorelei  # start with a specific style
LOVE=/path/to/love npm run dev  # select a LÖVE executable (macOS/Linux)
```

No `npm install` is needed to launch: the dev script uses Node's built-in APIs.
Run `npm ci --ignore-scripts` when you want the JavaScript reference used by
`npm test`. For a previously downloaded release ZIP, set `LOVE_THORVG_ARCHIVE`
to its path; the same pinned checksum is checked. The launcher does not watch
files or hot-reload; restart it after editing Lua.

## Install

Copy `love_dicebear.lua` and `love_dicebear/` into your game's root. Keep `THIRD_PARTY.md`,
`STYLES.md`, `vendor/DICEBEAR-LICENSE`, `vendor/UNICODE-LICENSE`, and `LICENSE`
with distributed copies. The raw JSON,
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

Use `dicebear.styles()` to list the available names. Each module loads lazily:
generating one style does not load the other artwork. Changing styles is simply
`dicebear.generate('lorelei', {seed = 'player-42'})`.

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

Some styles repeat a component through aliases. A source component's options
constrain its aliases, but each alias makes an independent seeded choice.
`describe` marks aliases with `extends`; this Lua API also accepts explicit
alias choices so editors can change an individual repeated shape. Resolved
settings include these choices and visibility values for reliable round trips.
Per-component transforms from the definition remain deterministic from the seed.

## Supported options

| Option | Accepted values |
| --- | --- |
| `seed` | UTF-8 string; default `''` |
| `title` | Optional accessible SVG title |
| `size` | Output width/height, 1–8192; omitted by default |
| `<component>Variant` | One variant name, an array of allowed names, or a `{name = weight}` map; component names come from `describe(style)` |
| Corresponding `*Probability` | 0–100; defaults come from the style |
| `<group>Color`, `backgroundColor` | Hex string or palette array; optional `#`; RGB, RGBA, RRGGBB, or RRGGBBAA; groups come from `describe(style)` |
| `fontFamily`, `fontWeight` | SVG text font family string (default `system-ui`) and weight 1–1000 (default 400) |
| `flip` | `none`, `horizontal`, `vertical`, `both` |
| `rotate` | −360–360 degrees |
| `scale` | 0–10; `1` is original size |
| `translateX`, `translateY` | −100–100 percent of the canvas |
| `borderRadius` | 0–50 percent of the canvas |

Rotate, scale, translations, and border radius also accept `{min, max}` arrays
(or a one-value array). Empty ranges use the default. Variant weights must be
finite numbers between 0 and 1,000,000; all-zero weights select uniformly.
Empty variant arrays hide the component. Color arrays select a seeded solid
color; an empty background palette is transparent. Palettes, contrast rules,
and color exclusions are bundled in each style. Inputs and returned descriptors
are never mutated.

This release generates **static SVGs for all bundled styles**. Animation
annotations are preserved in the source but are not played or emitted. Built-in
artwork gradients and filters are retained; configurable color gradients,
user-supplied definitions, tag filtering, and ID randomization are not
implemented. Unsupported or misspelled options
raise an error. Tags are exposed as editor metadata only. Multiple generated
SVGs should be loaded as separate documents; inlining them into one DOM can
collide on artwork IDs.

The supported output is tested byte-for-byte against **DiceBear Core 10.7.0**
with the pinned style definitions in `vendor/`. For schema 2 definitions with
animation annotations, the reference test uses their static projection because
Core 10.7.0's validator predates those annotations. DiceBear version 9
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

**SVG text is a known limitation of the tested love-thorvg v0.2.0 build.**
`initials` and `initial-face` generate correct SVGs but cannot be fully previewed
with that backend. The adapter rejects SVG text instead of returning a blank or
incomplete avatar. The example displays a notice for those two styles and still
lets you save their SVGs for another renderer. Embedding a font did not resolve
the limitation in the tested build. Other renderer differences in filters,
blending, or masking are not covered by byte-level generator parity.

Keep the returned document between frames. When an editor changes settings,
create the replacement document, then release the old one. Do not generate or
rasterize the avatar every `love.draw` call.

Run `npm run dev` (or `love .` after setup) for the catalog example: Up/Down changes
style, Left/Right changes eyes or the first component, R generates a new avatar,
and S saves
`avatar.svg` in LÖVE's save directory (the full path is printed to the console).

## Development

```sh
lua tests/run.lua
lua tests/adapter.lua
lua tests/save.lua
npm ci --ignore-scripts
npm test
npm run test:dev
love . --test
love . --render-test  # requires love_thorvg/
love . --catalog-render-test  # 61 native previews + 2 documented text limitations
```

Node is used only for comparison against the pinned JavaScript reference.
Set `LUA=luajit` to run the parity suite with another Lua executable, or
`LOVE=/path/to/love npm test` to compare SVGs generated inside LÖVE.

The parity suite covers all 63 styles and 2,985 variant selections, Unicode seeds, weights, visibility,
palette filtering, XML escaping, and transforms. The native smoke suite checks
all 53 Bottts variants; the catalog smoke suite checks 61 styles without
backgrounds, then resizes and releases each document. It also generates a
`catalog-smoke.png` contact sheet in the LÖVE save directory. These are not
pixel-by-pixel comparisons with another SVG renderer. All 7,096 parity cases
have also passed inside LÖVE/LuaJIT. To test one style, run `npm test -- lorelei`.
Native checks passed against love-thorvg commit
`02bc96e9c63f50a99beba371534fd06a14aae407` on macOS ARM64.

Run `python3 scripts/import_style.py` to regenerate the Lua artwork from the
vendored JSON. Do not edit the generated style directly. Review licensing and
parity before changing the upstream pin.

Code is MIT licensed. Artwork licenses vary by style; see
[STYLES.md](STYLES.md) and [THIRD_PARTY.md](THIRD_PARTY.md).
This is an independent Lua port.
