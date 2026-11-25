---
icon: lucide/plug
---
# Bring your own renderer

love-dicebear generates SVG strings. **You choose how to display them.**
The core does not import love-thorvg, require native binaries, or contact a server.
You do not need to register a renderer or implement the ThorVG adapter's interface.

## Generate once, render your way

```lua
local dicebear = require('love_dicebear')

local svg, settings = dicebear.generate('bottts', {
  seed = 'player-42',
  baseColor = '#448ef4',
  size = 256,
})

-- Saving SVG needs no renderer at all.
love.filesystem.write('avatar.svg', svg)
```

Pass `svg` to your renderer's SVG-string loader. If it only accepts files, load
the saved SVG using that renderer's filesystem conventions. LÖVE writes the file
to its save directory; a native renderer may need an absolute path.

The result might be a drawable vector object, pixels, or a PNG. Use your
renderer’s drawing API for vector objects. For pixels or PNGs, convert the result
into a LÖVE Image and draw it with `love.graphics.draw`.
`love.graphics.newImage` does not parse raw SVG strings.

## Connect a rasterizer

Here is a small application-side helper for renderers that can return LÖVE
`ImageData`. The `rasterize` callback is **your own integration code**, not a
love-dicebear API; adapt your renderer's output to that contract.

```lua
local dicebear = require('love_dicebear')

local function createAvatarImage(style, options, rasterize)
  local svg, settings = dicebear.generate(style, options)
  local pixels = rasterize(svg) -- Your callback returns love.image ImageData.
  local image = love.graphics.newImage(pixels)
  pixels:release()
  return image, settings, svg
end
```

This helper assumes the callback returns newly owned ImageData. Adjust cleanup
if your renderer retains ownership. Keep the returned Image for drawing, and
release it when you replace or discard it.

Generate and render during loading or when avatar settings change, then reuse
the drawable each frame. Keep `settings` for editing and reproduction, and keep
`svg` if you want to export the original vector image.

## Check your renderer's SVG support

Accepting SVG does not guarantee that every style will render correctly. Test
the styles and options you intend to use, including paths, transforms, clipping,
masks, gradients, and transparency where present. Text styles such as `initials`
and `initial-face` also need text support and suitable fonts configured through
your renderer. The generator does not embed font files.

The core options and editor descriptors stay the same whichever local renderer
you choose. Renderer-specific configuration, resource cleanup, and packaging
belong to your integration.

## Ready-made integrations

| Integration | What it provides |
| --- | --- |
| [love-thorvg adapter](thorvg.md) | Local SVG loading, drawing, and resource management through ThorVG |
| [HTTP adapter](http.md) | Server-rendered PNGs, LÖVE Images, saving, and optional URL caching |

Both are optional modules. The HTTP adapter requests an avatar from the API
using its style and options; it does not rasterize your locally generated SVG.
The bundled catalog example includes these two integrations. Using another
renderer in your game does not automatically add it to the example's selector.

See the [core API](api/core.md) for generation and the
[editor guide](customization.md) for changing and saving avatar settings.
