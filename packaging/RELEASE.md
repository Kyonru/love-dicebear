## First stable release

love-dicebear 1.0.0 provides local, deterministic SVG avatar generation in pure
Lua, with all 63 styles from the bundled DiceBear catalog.

- Customize components, visibility, colors, transforms, and text options.
- Discover editor controls through style descriptors and reproduce avatars from
  resolved settings.
- Bring your own SVG renderer; love-thorvg is optional.
- Use the optional ThorVG adapter for local previews, or the desktop HTTP adapter
  for PNG Images, saving, and URL caching.
- Explore the full settings editor in the source checkout and browse the complete
  API reference and per-style option documentation.

## Scope and known limitations

Generation produces static SVGs; upstream animation annotations are not played.
SVG parity tests compare against DiceBear Core 10.7.0. Keep the library version
alongside saved settings when reproducibility across upgrades matters.

Renderer compatibility depends on the SVG features it supports. ThorVG text
styles require a supplied font and an SVG-font-capable build; the launcher's
pinned love-thorvg v0.2.0 binary does not support font preloading. See the
[font setup guide](https://kyonru.github.io/love-dicebear/thorvg/#svg-text-and-fonts).
The HTTP adapter requires desktop LÖVE and curl, follows the API's option limits,
and needs network access unless a fresh cached PNG is available.

## Download and install

Download the **love-dicebear ZIP** below for the ready-to-use library. It works
across platforms; no native binaries are included. `SHA256SUMS` contains the
archive's SHA-256 checksum.

Extract the ZIP and copy `love_dicebear.lua` and `love_dicebear/` into your game.
Keep the bundled license notices when distributing it. The archive includes
all 63 styles, a version marker, and an installation guide.

The ThorVG and HTTP adapters are included as optional Lua modules. Install
love-thorvg separately if you want local SVG rendering, or provide system curl
for the desktop HTTP adapter. Neither dependency is bundled or automatically
installed.

[Documentation](https://kyonru.github.io/love-dicebear/) ·
[Getting started](https://kyonru.github.io/love-dicebear/getting-started/)
