# Getting started
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
another executable. The example uses love-thorvg by default.

```sh
npm run setup                  # download the renderer without launching
npm run dev -- --render-test    # run native rendering checks
npm run dev -- --style lorelei  # start with a specific style
LOVE=/path/to/love npm run dev  # select a LÖVE executable (macOS/Linux)
```

To use API-rendered PNGs, including the text-based styles, run:

```sh
npm run dev -- --renderer http --style initials
npm run dev -- --renderer http --style initials --cache
```

HTTP mode needs desktop `curl` on `PATH` and skips ThorVG setup. **H** switches
renderers, **S** saves PNG in HTTP mode or SVG in local mode, and **Enter** retries
or forces an HTTP refresh. `--cache` opts into a one-day disk cache; it is off by
default. Switching back to the local renderer requires love-thorvg to be installed.

The example also shows clickable rendering controls. **C** toggles disk caching,
**T** cycles its lifetime (5 minutes, 1 hour, or 24 hours), **Enter** refreshes
from the server, and **Delete** clears the current URL from the cache while
keeping the preview. The panel reports whether the image came from the network
or disk cache. Cache controls become available in HTTP mode.

No `npm install` is needed to launch: the dev script uses Node's built-in APIs.
Run `npm ci --ignore-scripts` when you want the JavaScript reference used by
`npm test`. For a previously downloaded release ZIP, set `LOVE_THORVG_ARCHIVE`
to its path; the same pinned checksum is checked. The launcher does not watch
files or hot-reload; restart it after editing Lua.


## Install in your game

Download the versioned library ZIP from [GitHub Releases](https://github.com/Kyonru/love-dicebear/releases)
and extract it, or use a source checkout. Copy `love_dicebear.lua` and
`love_dicebear/` into your game's root. Keep `THIRD_PARTY.md`,
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

## Release downloads

Choose `love-dicebear-<version>.zip` for the packaged library. The automatically
provided GitHub source archives contain the full development repository instead.
The library ZIP is platform-independent and includes all styles, optional adapter
code, and required license notices. love-thorvg and other optional dependencies
are not bundled; install them only if your chosen renderer needs them.

Verify the ZIP against the release's `SHA256SUMS` file before extracting it:

```sh
sha256sum --check SHA256SUMS       # Linux
shasum -a 256 --check SHA256SUMS   # macOS
```

On Windows, run `Get-FileHash .\love-dicebear-<version>.zip -Algorithm SHA256`
in PowerShell and compare the result with `SHA256SUMS`.
