# Development
```sh
lua tests/run.lua
lua tests/adapter.lua
lua tests/save.lua
lua tests/http_url.lua
lua tests/http.lua
lua tests/http_worker.lua
npm ci --ignore-scripts
npm test
npm run test:dev
love . --test
love . --render-test  # requires love_thorvg/
love . --catalog-render-test  # all 63 with SVG font support; otherwise 61
love . --font-test  # text pixels, shared ownership, and missing-font errors
love . --http-test  # opt-in live API download, draw, save, and disk-cache test
```

Node is used for the development launcher and JavaScript reference comparison;
it is not needed by either runtime renderer.
Set `LUA=luajit` to run the parity suite with another Lua executable, or
`LOVE=/path/to/love npm test` to compare SVGs generated inside LÖVE.

The parity suite covers all 63 styles and 2,985 variant selections, Unicode seeds, weights, visibility,
palette filtering, XML escaping, and transforms. The native smoke suite checks
all 53 Bottts variants; the catalog smoke suite checks all 63 styles with an
SVG-font-capable renderer (61 otherwise), then resizes and releases each document. It also generates a
`catalog-smoke.png` contact sheet in the LÖVE save directory. These are not
pixel-by-pixel comparisons with another SVG renderer. All 7,096 parity cases
have also passed inside LÖVE/LuaJIT. To test one style, run `npm test -- lorelei`.
Native checks passed against love-thorvg commit
`02bc96e9c63f50a99beba371534fd06a14aae407` on macOS ARM64.

Run `python3 scripts/import_style.py` to regenerate the Lua artwork from the
vendored JSON. Do not edit the generated style directly. Review licensing and
parity before changing the upstream pin.

Code is MIT licensed. Artwork licenses vary by style; see
[STYLES.md](styles.md) and [THIRD_PARTY.md](third-party.md).
This is an independent Lua port.
