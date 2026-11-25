"""Verify archive contents, reproducibility, version checks and standalone use."""
import hashlib
import importlib.util
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("package_release", ROOT / "scripts/package_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "source"
        self.root.mkdir()
        for name in ["love_dicebear", "packaging"]:
            shutil.copytree(ROOT / name, self.root / name)
        for name in ["love_dicebear.lua", *release.NOTICES]:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        # Use a fixture version so the tests still work after a library bump.
        init = self.root / "love_dicebear/init.lua"
        source = init.read_text()
        init.write_text(re.sub(r"local M = \{version = '[^']+'\}", "local M = {version = '1.2.3'}", source))

    def test_archive_is_complete_portable_and_reproducible(self):
        for name in ["love_thorvg/native.dylib", "node_modules/package/index.js", "tests/test.lua", "love_dicebear/junk.tmp"]:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("must not ship")
        archive = release.package(self.root, self.base / "first", "v1.2.3")
        second = release.package(self.root, self.base / "second", "v1.2.3")
        self.assertEqual(archive.read_bytes(), second.read_bytes())
        self.assertEqual((archive.parent / "SHA256SUMS").read_text(), hashlib.sha256(archive.read_bytes()).hexdigest() + "  " + archive.name + "\n")
        expected = {"love_dicebear.lua", "README.md", "VERSION", *release.NOTICES}
        expected.update(path.relative_to(self.root).as_posix() for path in (self.root / "love_dicebear").rglob("*.lua"))
        with zipfile.ZipFile(archive) as bundle:
            self.assertEqual(set(bundle.namelist()), {"love-dicebear-1.2.3/" + name for name in expected})
            self.assertIsNone(bundle.testzip())
            self.assertIn(b"love-dicebear 1.2.3", bundle.read("love-dicebear-1.2.3/README.md"))
            bundle.extractall(self.base / "extracted")
        lua = shutil.which("lua") or shutil.which("lua5.4") or shutil.which("luajit")
        self.assertIsNotNone(lua, "install Lua to smoke-test the extracted archive")
        subprocess.run([lua, "-e", """
package.path = './?.lua;./?/init.lua'
local dicebear = require('love_dicebear')
assert(dicebear.version == '1.2.3')
assert(#dicebear.styles() == 63)
for _, style in ipairs(dicebear.styles()) do
  local svg, state = dicebear.generate(style, {seed = 'release-smoke'})
  assert(svg:find('<svg', 1, true), style)
  assert(svg == dicebear.generate(style, state), style)
end
assert(require('love_dicebear.http').url('initials', {seed = 'test'}))
assert(require('love_dicebear.thorvg'))
"""], cwd=self.base / "extracted/love-dicebear-1.2.3", check=True)

    def test_rejects_invalid_tags_and_version_mismatch(self):
        for tag in ["1.2.3", "v01.2.3", "v2.0.0", "v1.2.3/../../escape", "v1.2.3-01", "v1.2.3;echo bad"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                release.package(self.root, self.base / "invalid", tag)
        self.assertFalse((self.base / "invalid").exists())

    def test_accepts_matching_prerelease(self):
        init = self.root / "love_dicebear/init.lua"
        init.write_text(init.read_text().replace("'1.2.3'", "'1.2.3-rc.1'"))
        self.assertEqual(release.release_version(self.root, "v1.2.3-rc.1"), "1.2.3-rc.1")

    def test_rejects_symlinks_and_missing_notices(self):
        path = self.root / "love_dicebear/link.lua"
        path.symlink_to(self.root / "love_dicebear.lua")
        with self.assertRaises(ValueError):
            release.package(self.root, self.base / "linked", "v1.2.3")
        path.unlink()
        (self.root / "LICENSE").unlink()
        with self.assertRaises(FileNotFoundError):
            release.package(self.root, self.base / "missing", "v1.2.3")


if __name__ == "__main__":
    unittest.main()
