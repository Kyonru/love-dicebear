---
icon: lucide/sliders-horizontal
---
# Build an avatar editor

Use the library’s option descriptors to build controls, then keep one resolved
settings table as the editable avatar state. The [core API](api/core.md) documents
every descriptor field and return value.

## Discover controls and edit an avatar

`describe` returns independent copies of the option descriptors: available
variants, tags, palettes, types, bounds, and defaults. Use these to populate
pickers, color controls, and sliders.

```lua
local description = dicebear.describe('bottts')
local eyeChoices = description.options.eyesVariant.values
local palette = description.options.baseColor.palette

-- Resolve every random choice once, then edit that concrete state.
local settings = dicebear.resolve('bottts', {seed = 'player-42'})
settings.eyesVariant = eyeChoices[1]
settings.baseColor = '#d95c9a'
settings.topProbability = 0
local svg = dicebear.generate('bottts', settings)
```

## Save and restore state

`generate(style, options)` returns **SVG, resolved settings**. `resolve` returns
the settings without building SVG. The resolved table can be passed back to
`generate` unchanged to reproduce the output, or serialized with your game's
JSON/save library. It contains no functions or native resources.

## Visibility and rerolling

Visibility resolves to `0` or `100`; hidden features retain their selected
variant so an editor can reveal them later. Empty variant selections and
transparent colors use empty arrays. Resolved settings pin every choice:
changing their seed alone does **not** randomize them. To create a new avatar,
start with `{seed = newSeed}` and whichever restrictions you want to keep.

## Repeated components and aliases

Some styles repeat a component through aliases. A source component's options
constrain its aliases, but each alias makes an independent seeded choice.
`describe` marks aliases with `extends`; this Lua API also accepts explicit
alias choices so editors can change an individual repeated shape. Resolved
settings include these choices and visibility values for reliable round trips.
Per-component transforms from the definition remain deterministic from the seed.

## Try the descriptor-driven example

Run `npm run dev` and use the **Avatar settings** panel. Every descriptor becomes
a selectable row: variants and enums cycle through choices, colors cycle through
palettes or accept a typed hex value, and numeric options use bounded steps or
exact input. The panel also supports seed, title, and font text fields.

Use Up/Down to select a setting, Left/Right to change it, and E to type. Enter applies
typed input; Escape cancels it. Backspace outside text input removes that option's
explicit override. See [all example controls](getting-started.md#example-controls).

The example's `example/editor.lua` contains the control logic and validation;
it is separate from the runtime library and excluded from release ZIPs.
