"""Prepare canonical notices and per-style option references for Zensical."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
docs = root / "docs"
styles = docs / "styles"
styles.mkdir(exist_ok=True)


def code(value):
    return "`" + str(value).replace("|", "&#124;").replace("`", "&#96;") + "`"


catalog = (root / "STYLES.md").read_text(encoding="utf-8")
for source in sorted((root / "vendor").glob("*.json")):
    name = source.stem
    definition = json.loads(source.read_text(encoding="utf-8"))
    components = definition.get("components", {})
    lines = ["---", "icon: lucide/smile", "---", "# " + name, "",
             "Exact style-specific options from the bundled definition. Use these alongside",
             "the [shared avatar options](../options.md) and [core API](../api/core.md).",
             "[Back to the style catalog and licenses](../styles.md).", "", "```lua",
             "local dicebear = require('love_dicebear')",
             "local svg, settings = dicebear.generate('" + name + "', {seed = 'player-42'})",
             "local options = dicebear.describe('" + name + "').options", "```", "",
             "## Components", ""]
    if not components:
        lines += ["This style has no selectable components.", ""]
    for component_name, entry in sorted(components.items()):
        component = components[entry["extends"]] if entry.get("extends") else entry
        variants = component.get("variants", {})
        lines += ["### " + component_name, "",
                  "- Variant option: " + code(component_name + "Variant") + ". Accepts a name, allowed-name array, or weight map; `{}` hides it.",
                  "- Visibility option: " + code(component_name + "Probability") + ". Range 0–100; default **" + str(component.get("probability", 100)) + "**."]
        if entry.get("extends"):
            lines += ["- Alias of " + code(entry["extends"]) + ". Local overrides are supported; HTTP alias overrides are rejected."]
        lines += ["", "| Variant | Tags |", "| --- | --- |"]
        for variant, data in sorted(variants.items()):
            tags = ", ".join(code(tag) for tag in data.get("tags", [])) or "—"
            lines += ["| " + code(variant) + " | " + tags + " |"]
        lines += [""]
    colors = definition.get("colors", {})
    lines += ["## Color palettes", "", "Each option accepts a hex color or palette array. An empty table is transparent.",
              "Bundled contrast and exclusion rules can affect the seeded choice.", ""]
    for group in sorted({"background", *colors}):
        palette = colors.get(group, {}).get("values", [])
        lines += ["### " + group + "Color", "",
                  ", ".join(code(value) for value in palette) if palette else "No bundled palette; omitted values resolve to transparency.", ""]
    animation_names = set()
    def collect_animations(value):
        if isinstance(value, dict):
            animation_names.update(block["name"] for block in value.get("animations", []))
            for child in value.values():
                collect_animations(child)
        elif isinstance(value, list):
            for child in value:
                collect_animations(child)
    collect_animations(definition)
    if animation_names:
        lines += ["## Animation", "", "Enable all selected artwork timelines with `animation = true`, or control a named timeline:", "",
                  "| Timeline | Switch | Speed | Delay |", "| --- | --- | --- | --- |"]
        for animation_name in sorted(animation_names):
            lines += ["| " + code(animation_name) + " | " + code(animation_name + "Animation") + " | "
                      + code(animation_name + "AnimationSpeed") + " | " + code(animation_name + "AnimationDelay") + " |"]
        lines += ["", "Some artwork variants may be static. See [animation options](../options.md#animation-options) and [native playback](../thorvg.md#animation).", ""]
    (styles / (name + ".md")).write_text("\n".join(lines), encoding="utf-8")
    catalog = catalog.replace("| `" + name + "` |", "| [`" + name + "`](styles/" + name + ".md) |")
(docs / "styles.md").write_text("---\nicon: lucide/layout-grid\n---\n" + catalog, encoding="utf-8")
notices = (root / "THIRD_PARTY.md").read_text(encoding="utf-8").replace("(STYLES.md)", "(styles.md)")
(docs / "third-party.md").write_text("---\nicon: lucide/scale\n---\n" + notices, encoding="utf-8")
