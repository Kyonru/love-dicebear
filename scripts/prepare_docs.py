"""Copy canonical generated catalogs/notices into the documentation source tree."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for source, target in [("STYLES.md", "styles.md"), ("THIRD_PARTY.md", "third-party.md")]:
    text = (root / source).read_text(encoding="utf-8")
    text = text.replace("(STYLES.md)", "(styles.md)")
    (root / "docs" / target).write_text(text, encoding="utf-8")
