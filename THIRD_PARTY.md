# Third-party notices

All bundled definitions and generated artwork retain their own license metadata.
See [STYLES.md](STYLES.md) for each style's creator, license, and immutable source
URL. The MIT code license does not replace these artwork licenses. Generated
SVGs include the corresponding attribution and license metadata.

## Bottts artwork

Bottts by **Pablo Stanley**, https://bottts.com/ — free for personal and
commercial use, as stated in the upstream definition's license metadata.
The original metadata is retained in `vendor/bottts.json`, the generated Lua
module, and every generated SVG.

Source: https://github.com/dicebear/styles/blob/b19a973b7ff86e2ac49277e371c2d0fdcac49faa/src/bottts.json

The vendored JSON is unmodified. `scripts/import_style.py` converts it to a Lua
table, preserving SVG attribute order. Its SHA256 is recorded in the generated
file. This artwork has its own license; the repository's MIT license does not
replace it.

## DiceBear algorithms

The random generator, option resolution, and SVG composition are adapted from
DiceBear Core 10.7.0, copyright (c) 2026 Florian Körner, MIT licensed.
The complete notice is in `vendor/DICEBEAR-LICENSE`.

Reference: https://github.com/dicebear/dicebear and
https://www.dicebear.com/create-styles/implement-dicebear-core/

love-thorvg is an optional, separately installed dependency. Retain its own
MIT and ThorVG notices when distributing its binaries.

## Unicode data

The initials implementation uses generated Unicode 17.0 letter/mark categories
and uppercase mappings. See `vendor/UNICODE-LICENSE`. The generation script uses
Node's Unicode implementation only at development time; the resulting tables
are bundled for consistent behavior across Lua runtimes.
