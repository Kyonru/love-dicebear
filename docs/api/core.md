---
icon: lucide/braces
---
# Core API

```lua
local dicebear = require('love_dicebear')
```

The core runs in Lua 5.1+ and LÖVE without a renderer or network connection.
Pass the generated SVG to [your own renderer](../renderers.md) without importing
either optional adapter.
Functions do not mutate your input tables or change `math.random` state.

| Member | Returns | Purpose |
| --- | --- | --- |
| [`version`](#version) | string | Identify the installed library |
| [`styles()`](#styles) | string array | List bundled styles |
| [`describe(style)`](#describestyle) | description table | Discover customization controls |
| [`resolve(style, options)`](#resolvestyle-options) | settings table | Pin all seeded choices |
| [`generate(style, options)`](#generatestyle-options) | SVG string, settings table | Generate a static avatar |

## `version`

The installed library's version string, currently `1.0.0`. Save it alongside
avatars when reproducibility across future upgrades matters.

```lua
local saved = {version = dicebear.version, style = 'bottts', settings = settings}
```

## `styles()`

Returns a fresh array of all supported names. Each call returns an independent
copy; changing this array does not change the library. Styles load lazily.

```lua
for _, name in ipairs(dicebear.styles()) do print(name) end
```

See the [style catalog](../styles.md) for every style's options and license.

## `describe(style)`

`style` is an exact name from `styles()`. Returns independent copies of:

| Field | Contents |
| --- | --- |
| `name` | The requested style name |
| `meta` | Upstream style metadata, including creator and license information |
| `options` | A map from option name to its descriptor |

Descriptors contain these fields when applicable:

| Field | Meaning |
| --- | --- |
| `type` | `string`, `number`, `enum`, `range`, `variant`, or `color` |
| `default` | Default scalar value, if defined; not a fully resolved random choice |
| `min`, `max` | Inclusive numeric bounds |
| `values` | Allowed enum or variant names |
| `palette` | Bundled colors for a color option |
| `tags` | Variant name → array of metadata tags |
| `extends` | Source component name for an alias variant option |

```lua
local info = dicebear.describe('bottts')
local choices = info.options.eyesVariant.values
local palette = info.options.baseColor.palette
local visibility = info.options.eyesProbability -- min, max, default
```

Use `resolve` for concrete defaults, rather than assuming every descriptor has a
`default` field. Tags describe artwork; tag filtering is not implemented.

## `resolve(style, options)`

Accepts a supported style and an optional table (defaults to `{}`). Returns a
plain Lua table with every random choice resolved. It has no native resources
and can be serialized with your game's preferred save format.

```lua
local settings = dicebear.resolve('bottts', {seed = 'player-42'})
settings.eyesVariant = 'happy'
settings.topProbability = 0
```

Visibility becomes `0` or `100`. Hidden components keep their selected variants.
Empty selections remain empty tables. Colors become normalized hex strings or
empty tables. Aliases have independent resolved selections.

Changing only `settings.seed` does not reroll pinned choices. Start a new input
table with a new seed to randomize again. See [editor state](../customization.md).

## `generate(style, options)`

Accepts the same arguments as `resolve`. Returns **two values**: the SVG string
and the resolved settings. Resolved settings can be passed back unchanged to
reproduce the same output.

```lua
local svg, settings = dicebear.generate('bottts', {seed = 'player-42'})
local same = dicebear.generate('bottts', settings)
assert(svg == same)
love.filesystem.write('avatar.svg', svg)
```

Assign the SVG before passing it to `love.filesystem.write`: a function call in
the last argument position forwards both Lua return values, and the second value
would be interpreted as the optional byte count.

Generation is synchronous and produces static SVG, not a LÖVE Image. See
[ThorVG](thorvg.md) for local rendering or [HTTP](http.md) for server-rendered PNGs.

## Validation and errors

An unknown style, unsupported option, invalid UTF-8, invalid color, out-of-range
number, unknown variant, or malformed array raises a Lua error. Catch it at the
boundary of an editor that accepts user input:

```lua
local ok, svg, resolved = pcall(dicebear.generate, 'bottts', userOptions)
if not ok then
  print(svg) -- error message
else
  -- display or save svg; retain resolved for editing
end
```

See [all common options](../options.md) and each style's generated option page.
Internal modules such as `prng`, `renderer`, and `http_cache` are implementation
details; use the public modules documented in this reference.
