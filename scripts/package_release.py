"""Build the dependency-free release ZIP using only Python's standard library."""
import argparse
import hashlib
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SEMVER = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
NOTICES = ("LICENSE", "STYLES.md", "THIRD_PARTY.md", "vendor/DICEBEAR-LICENSE", "vendor/UNICODE-LICENSE")


def release_version(root, tag):
    if not re.fullmatch("v" + SEMVER, tag):
        raise ValueError("release tag must be vMAJOR.MINOR.PATCH, optionally with a prerelease suffix")
    version = tag[1:]
    if "-" in version:
        for identifier in version.split("-", 1)[1].split("."):
            if identifier.isdigit() and len(identifier) > 1 and identifier.startswith("0"):
                raise ValueError("numeric prerelease identifiers cannot have leading zeros")
    source = (root / "love_dicebear/init.lua").read_text(encoding="utf-8")
    match = re.search(r"local M = \{version = '([^']+)'\}", source)
    if not match or match[1] != version:
        raise ValueError("tag must match love_dicebear/init.lua's version")
    return version


def package(root, output, tag):
    version = release_version(root, tag)
    paths = [root / "love_dicebear.lua", *(root / name for name in NOTICES)]
    paths.extend(sorted((root / "love_dicebear").rglob("*.lua")))
    files = {}
    for path in paths:
        relative = path.relative_to(root)
        if any(part.is_symlink() for part in [path, *path.parents] if part != root and root in part.parents):
            raise ValueError("release files must not be symlinks: " + str(relative))
        files[relative.as_posix()] = path.read_bytes()
    files["README.md"] = (root / "packaging/README.md").read_text(encoding="utf-8").replace("@VERSION@", version).encode("utf-8")
    files["VERSION"] = (version + "\n").encode("ascii")
    output.mkdir(parents=True, exist_ok=True)
    name = "love-dicebear-" + version
    archive = output / (name + ".zip")
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for relative, data in sorted(files.items()):
            # Stable timestamps, paths and permissions make repeated builds identical.
            info = zipfile.ZipInfo(name + "/" + relative, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            bundle.writestr(info, data, compresslevel=9)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / "SHA256SUMS").write_text(digest + "  " + archive.name + "\n", encoding="ascii")
    return archive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="release tag matching the Lua library version, e.g. v0.2.0")
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    try:
        print(package(ROOT, args.output, args.version))
    except (ValueError, OSError) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
