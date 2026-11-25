# Local rendering with love-thorvg
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
lets you save their SVGs or switch to the HTTP PNG backend with H. Embedding a font did not resolve
the limitation in the tested build. Other renderer differences in filters,
blending, or masking are not covered by byte-level generator parity.

Keep the returned document between frames. When an editor changes settings,
create the replacement document, then release the old one. Do not generate or
rasterize the avatar every `love.draw` call.

Run `npm run dev` (or `love .` after setup) for the catalog example: Up/Down changes
style, Left/Right changes eyes or the first component, and R generates a new
avatar. Saved files are written to LÖVE's save directory; the full path is
printed to the console.
