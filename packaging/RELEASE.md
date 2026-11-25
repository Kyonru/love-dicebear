## Animated avatars and updated renderer

love-dicebear 2.0.0 includes the released DiceBear 11 catalog and opt-in animation
for its 21 animated styles. Export browser-compatible SVG keyframes or play them
locally with love-thorvg 0.3.0 (ThorVG 1.2.0-dev, pinned November 25 revision).

- Global and named animation switches, speed, and delay controls.
- Native pause, play, seek, resize, and reusable textures.
- SVG font support in the pinned renderer; applications supply licensed fonts.
- Monthly catalog update PRs and minor releases on merge.

## Upgrade from 1.x

Install the complete love-thorvg 0.3.0 wrapper and matching native library for
animation and local text. Existing manual renderer installations are preserved
by the launcher and must be upgraded manually. Animation stays off by default. The HTTP adapter now defaults to `/11.x/`
to match the bundled catalog; use `baseUrl` to retain a different API version.
The updated upstream catalog can change artwork and variant selection for a
saved seed. Preserve the library version with saved avatar settings.

## Scope and known limitations

Static output remains covered by byte-for-byte reference tests; animated output
is covered by timeline and native pixel tests, not full browser pixel parity.
SVG parity tests compare against DiceBear Core 10.7.0. Keep the library version
alongside saved settings when reproducibility across upgrades matters.

Renderer compatibility depends on the SVG features it supports. ThorVG text
styles require a supplied font and an SVG-font-capable build; the launcher's
pinned love-thorvg v0.3.0 includes font preloading. See the
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
