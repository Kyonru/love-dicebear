# love-dicebear
Generate customizable [DiceBear](https://www.dicebear.com/) avatars locally in
Lua and LÖVE. Includes **all 63 styles** from the pinned DiceBear catalog,
including Adventurer, Avataaars, Bottts, Lorelei, Micah, Notionists, Open Peeps,
Pixel Art, and Initials. See [STYLES.md](styles.md) for the full list and licenses.
The local generator needs no HTTP requests, Node runtime, native generator,
or JSON parser in your game.

SVG generation and rendering are separate. Use any SVG renderer, or the optional
adapter for [love-thorvg](https://github.com/Kyonru/love-thorvg). An optional
HTTP backend downloads PNGs from DiceBear and displays ordinary LÖVE Images.


## Start here

- [Run the example or install the library](getting-started.md).
- [Build an avatar editor](customization.md) using introspected options and saved state.
- [Look up supported options](options.md) and [all 63 styles](styles.md).

## Choose a rendering path

| Path | Output | Requirements | Works offline |
| --- | --- | --- | --- |
| Core generator | SVG string | Lua 5.1+ or LÖVE | Yes |
| [love-thorvg](thorvg.md) | Drawable SVG document | LÖVE and native love-thorvg | Yes |
| [HTTP adapter](http.md) | LÖVE Image and PNG | Desktop LÖVE, curl, API access | With a fresh cached PNG |

The generator is independent of either renderer. Use local generation for fully
local avatars, or the HTTP adapter when you want server-rendered PNGs.

See [development](development.md) for tests and [documentation maintenance](documentation.md)
for local previews and GitHub Pages deployment.
