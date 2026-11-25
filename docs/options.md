# Options reference
| Option | Accepted values |
| --- | --- |
| `seed` | UTF-8 string; default `''` |
| `title` | Optional accessible SVG title |
| `size` | Output width/height, 1–8192; omitted by default |
| `<component>Variant` | One variant name, an array of allowed names, or a `{name = weight}` map; component names come from `describe(style)` |
| Corresponding `*Probability` | 0–100; defaults come from the style |
| `<group>Color`, `backgroundColor` | Hex string or palette array; optional `#`; RGB, RGBA, RRGGBB, or RRGGBBAA; groups come from `describe(style)` |
| `fontFamily`, `fontWeight` | SVG text font family string (default `system-ui`) and weight 1–1000 (default 400) |
| `flip` | `none`, `horizontal`, `vertical`, `both` |
| `rotate` | −360–360 degrees |
| `scale` | 0–10; `1` is original size |
| `translateX`, `translateY` | −100–100 percent of the canvas |
| `borderRadius` | 0–50 percent of the canvas |

Rotate, scale, translations, and border radius also accept `{min, max}` arrays
(or a one-value array). Empty ranges use the default. Variant weights must be
finite numbers between 0 and 1,000,000; all-zero weights select uniformly.
Empty variant arrays hide the component. Color arrays select a seeded solid
color; an empty background palette is transparent. Palettes, contrast rules,
and color exclusions are bundled in each style. Inputs and returned descriptors
are never mutated.

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
