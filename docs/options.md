---
icon: lucide/list-filter
---
# Avatar options

Pass these values as the second argument to `generate`, `resolve`, or an adapter
constructor. Omitted options use the defaults below or the style's own defaults.
For exact component names and palettes, choose a style in the [catalog](styles.md).

## Identity and output

| Option | Accepted values | Default |
| --- | --- | --- |
| `seed` | Valid UTF-8 string | `''` |
| `title` | Optional accessible SVG title, valid XML text | Omitted |
| `size` | Number from 1 to 8192; output width and height | Omitted; SVG keeps its viewBox |

The local generator accepts numeric `size` values within the range. The HTTP
adapter requires an **integer from 1 to 256**, defaults to 256, and rejects
`title`. See [HTTP differences](api/http.md#avatar-option-differences).

## Variants and visibility

Each style exposes `<component>Variant` and `<component>Probability` options.
Use `dicebear.describe(style).options` to discover valid names and defaults.

| Option | Accepted values | Default |
| --- | --- | --- |
| `<component>Variant` | One variant name, an allowed-name array, or a `{name = weight}` map | Seeded selection from the style |
| `<component>Probability` | Number from 0 to 100 | Defined by the style; 100 when unspecified |

```lua
local options = {
  seed = 'player-42',
  eyesVariant = {'happy', 'dizzy'}, -- choose from these variants
  mouthVariant = {smile01 = 3, smile02 = 1}, -- weighted choice
  topProbability = 0, -- hide the component
}
```

Variant weights must be finite numbers from 0 to 1,000,000. All-zero weights
select uniformly. An empty variant table `{}` hides the component. Arrays must
be dense and use 1-based indices. Unknown variants and option names raise errors.

Aliased components expose `extends` in their variant descriptor. Local editors
can override an individual alias; the HTTP adapter accepts only source-component
options. Tags are descriptive metadata, not selection filters.

## Colors

| Option | Accepted values | Default |
| --- | --- | --- |
| `<group>Color` | Hex string or an array of hex strings | Seeded choice from the style palette |
| `backgroundColor` | Same forms; `{}` gives transparency | Style palette, or transparent when absent |

Accepted hex lengths are RGB, RGBA, RRGGBB, and RRGGBBAA, with an optional `#`.
The resolved state uses normalized lowercase hex strings with `#`.

```lua
local options = {
  baseColor = '#448ef4',
  backgroundColor = {}, -- transparent
}
```

Palettes select a solid color; they do not generate a configurable gradient.
Bundled contrast rules and exclusions apply to seeded palette selection.
An empty color array represents transparency.

## Transforms

| Option | Accepted values | Default |
| --- | --- | --- |
| `flip` | `none`, `horizontal`, `vertical`, `both` | `none` |
| `rotate` | −360 to 360 degrees | `0` |
| `scale` | 0 to 10; 1 is original size | `1` |
| `translateX` | −100 to 100 percent of canvas width | `0` |
| `translateY` | −100 to 100 percent of canvas height | `0` |
| `borderRadius` | 0 to 50 percent of canvas | `0` |

All numeric transforms also accept `{min, max}` arrays for a seeded value within
the bounds. Reversed bounds are sorted. A one-value array is fixed; an empty
array uses the default. Resolution rounds sampled values to four decimal places.

```lua
local options = {rotate = {-15, 15}, scale = 0.9, borderRadius = 12}
```

## Text

| Option | Accepted values | Default |
| --- | --- | --- |
| `fontFamily` | Valid UTF-8/XML text string | `system-ui` |
| `fontWeight` | Number from 1 to 1000 | `400` |

These describe SVG text. A family name does not load a font file. Local ThorVG
text needs an explicit matching font map and a capable native build; see
[supplied fonts](thorvg.md#svg-text-and-fonts). The HTTP adapter only accepts the
default family/weight values and omits them from the URL.

## Compatibility and limits

This release generates **static SVGs for all bundled styles**. Animation
annotations are preserved in the source but are not played or emitted. Built-in
artwork gradients and filters are retained; configurable color gradients,
user-supplied definitions, tag filtering, and ID randomization are not
implemented. Unsupported or misspelled options
raise an error. Tags are exposed as editor metadata only. Multiple generated
SVGs should be loaded as separate documents; inlining them into one DOM can
collide on artwork IDs.

The supported output is tested byte-for-byte against **DiceBear Core 10.7.0**
with the pinned style definitions in `vendor/`. For schema 2 definitions with
animation annotations, the reference test uses their static projection because
Core 10.7.0's validator predates those annotations. DiceBear version 9
seeds and option names are not interchangeable with this API. Store the library
version with saved avatars when you need stability across future upgrades.
