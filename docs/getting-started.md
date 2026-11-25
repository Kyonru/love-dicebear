---
icon: lucide/rocket
---
# Getting started

Install the pure-Lua generator first, then choose how to display its SVG output.
You can also run the catalog example to explore styles before integrating it.

## Install in your game

Download `love-dicebear-<version>.zip` from
[GitHub Releases](https://github.com/Kyonru/love-dicebear/releases), extract it,
and copy these files into your game's root:

```text
my-game/
├── main.lua
├── love_dicebear.lua
└── love_dicebear/
```

A source checkout contains the same library files. The generator supports Lua
5.1+ and LÖVE 11.x / LuaJIT. No Node.js runtime or network connection is required.

Keep `LICENSE`, `THIRD_PARTY.md`, `STYLES.md`, `vendor/DICEBEAR-LICENSE`, and
`vendor/UNICODE-LICENSE` with distributed copies. The library ZIP includes those
notices and excludes optional renderer dependencies and development tooling.

## Generate your first avatar

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

The same style, seed, and options produce the same SVG. Keep `settings` to edit
or reproduce this exact avatar. Use `dicebear.styles()` to list names and
`dicebear.describe(style)` to discover controls. Each style loads lazily.

Continue with [building an editor](customization.md) or the [core API](api/core.md).

## Choose a renderer

| Renderer | Setup | Output |
| --- | --- | --- |
| [Bring your own renderer](renderers.md) | Use your preferred SVG library | Whatever your renderer produces |
| [Local ThorVG](thorvg.md) | Install love-thorvg separately | Drawable document, entirely local |
| [HTTP adapter](http.md) | Desktop LÖVE and system `curl` | Downloaded PNG and ordinary LÖVE Image |

The core generator works independently of all renderers. No renderer registration
or ThorVG-compatible interface is required. When using ThorVG, local text styles
require a supplied font and SVG-font-capable build; see [font setup](thorvg.md#svg-text-and-fonts).

## Try the catalog example

From a source checkout, install LÖVE 11.x and Node.js 22 or newer, then run:

```sh
npm run dev
```

The launcher downloads the pinned love-thorvg v0.2.0 package, verifies its
checksum, and starts the example. Existing complete renderer installations are
preserved. No `npm install` is needed just to launch the example.

Choose a style or use the HTTP renderer:

```sh
npm run dev -- --style lorelei
npm run dev -- --renderer http --style initials --cache
```

HTTP mode skips ThorVG installation and requires `curl`. With an updated
SVG-font-capable renderer already installed, try a supplied local font:

```sh
npm run dev -- --style initials --font examples/fonts/Abel-Regular.ttf
```

The launcher's pinned v0.2.0 download does not support font preloading. See the
[ThorVG guide](thorvg.md) for the updated build requirement.

### Example controls

Rendering and cache actions are also clickable in the example's side panel.

| Key | Action |
| --- | --- |
| Up / Down | Change style |
| Tab / Shift+Tab | Select the next / previous avatar setting |
| Left / Right | Cycle choices or increase / decrease the selected value |
| E | Type an exact value (hex color, seed, number, or variant name) |
| Enter / Escape while typing | Apply / cancel the edit |
| Backspace outside text input | Reset the selected setting to its default |
| Page Up / Page Down | Move through settings by a page |
| Mouse wheel over settings | Move through the settings list |
| R | Generate a new seeded avatar |
| H | Switch between local SVG and HTTP PNG rendering |
| S | Save `avatar.svg` or `avatar.png` to LÖVE's save directory |
| C | Toggle HTTP disk caching |
| T | Cycle cache lifetime: 5 minutes, 1 hour, 24 hours |
| Enter | Retry or refresh from the HTTP server |
| Delete | Clear the current URL's cache entry while keeping the preview |
| Escape | Quit |

The settings panel is generated from each style's descriptors. It exposes
component variants and visibility, colors (including `transparent`), rotation,
scale, translation, corner radius, flip, output size, seed, and text settings.
Click a row to select it, use its **− / +** buttons to adjust it, or click the
value to type directly. Cycle a component to **None** (or type `None`) to hide it.
Selecting a variant makes it visible again. Backspace on a component resets both
its variant and visibility to the seeded defaults.
Invalid values keep the current avatar and show an error beside the editor.

HTTP mode marks alias overrides, title, and font settings as local-only and
limits size to 256. If existing local options cannot be represented by the API,
switching to HTTP reports the incompatible setting; reset it first. Font-family
changes use the font supplied with `--font`; they do not select a different file.

Caching is off by default; `--cache` enables a 24-hour lifetime. The panel shows
whether the image came from the network or disk. Switching to local rendering
requires love-thorvg to be installed. The save path is printed to the console.

For launcher overrides, offline setup, tests, and development workflows, see
[contribute.md](https://github.com/Kyonru/love-dicebear/blob/main/contribute.md).

## Verify a release download

Choose the versioned library ZIP rather than GitHub's automatic source archive.
Download its `SHA256SUMS` file into the same directory and check it before extraction:

```sh
sha256sum --check SHA256SUMS       # Linux
shasum -a 256 --check SHA256SUMS   # macOS
```

On Windows, use `Get-FileHash .\love-dicebear-<version>.zip -Algorithm SHA256`
in PowerShell and compare the result with `SHA256SUMS`.
