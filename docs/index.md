---
icon: lucide/house
---
# love-dicebear
Generate customizable [DiceBear](https://www.dicebear.com/) avatars locally in
Lua and LÖVE. Includes **the complete pinned DiceBear catalog**,
including Adventurer, Avataaars, Bottts, Lorelei, Micah, Notionists, Open Peeps,
Pixel Art, and Initials. See [STYLES.md](styles.md) for the full list and licenses.
The local generator needs no HTTP requests, Node runtime, native generator,
or JSON parser in your game.

SVG generation and rendering are separate. Use [your own SVG renderer](renderers.md), or the optional
adapter for [love-thorvg](https://github.com/Kyonru/love-thorvg). An optional
HTTP backend downloads PNGs from DiceBear and displays ordinary LÖVE Images.


Version **2.0.0** adds [animated avatars](thorvg.md#animation): browser SVG
keyframes and local playback through love-thorvg **0.3.0**. Animation stays off
until enabled.

## Start here

- [Run the example or install the library](getting-started.md).
- [Build an avatar editor](customization.md) using introspected options and saved state.
- [Look up supported options](options.md) and [all bundled styles](styles.md).

## Choose a rendering path

| Path | Output | Requirements | Works offline |
| --- | --- | --- | --- |
| Core generator | SVG string | Lua 5.1+ or LÖVE | Yes |
| [Bring your own renderer](renderers.md) | Your renderer’s output | Your chosen SVG library | Depends on your renderer |
| [love-thorvg](thorvg.md) | Drawable SVG document | LÖVE and native love-thorvg | Yes |
| [HTTP adapter](http.md) | LÖVE Image and PNG | Desktop LÖVE, curl, API access | With a fresh cached PNG |

The generator is independent of all rendering integrations. Use local generation for fully
local avatars, or the HTTP adapter when you want server-rendered PNGs.

See [development](development.md) for tests and [documentation maintenance](documentation.md)
for local previews and GitHub Pages deployment.

## API reference

- [Core API](api/core.md): generate, resolve, inspect styles, and save deterministic settings.
- [Avatar options](options.md): all shared settings, bounds, defaults, and accepted forms.
- [ThorVG adapter](api/thorvg.md): construction, supplied fonts, and Document methods.
- [HTTP API](api/http.md): URLs, request lifecycle, saving, caching, and errors.

Each entry in the [style catalog](styles.md) links to the style’s exact component
names, variants, probability defaults, aliases, tags, and color palettes.
