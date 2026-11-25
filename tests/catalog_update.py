"""Exercise catalog updates offline, including additions, removals and no-ops."""
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('update_catalog', ROOT / 'scripts/update_catalog.py')
catalog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog)


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'project'
        self.upstream = Path(self.temp.name) / 'upstream'
        for name in ['vendor', 'love_dicebear', 'scripts']:
            shutil.copytree(ROOT / name, self.root / name)
        shutil.copyfile(ROOT / 'THIRD_PARTY.md', self.root / 'THIRD_PARTY.md')
        self.src = self.upstream / 'src'
        self.src.mkdir(parents=True)
        for path in (ROOT / 'vendor').glob('*.json'):
            shutil.copyfile(path, self.src / path.name)
        self.pin = 'a' * 40

    def test_noop_does_not_bump_version_or_pin(self):
        before = (self.root / 'love_dicebear/init.lua').read_bytes()
        self.assertFalse(catalog.update(self.root, self.upstream, self.pin))
        self.assertEqual(before, (self.root / 'love_dicebear/init.lua').read_bytes())
        self.assertNotEqual(self.pin, (self.root / 'vendor/dicebear-styles.commit').read_text().strip())

    def test_add_modify_remove_and_repeat(self):
        init = self.root / 'love_dicebear/init.lua'
        init.write_text("local M = {version = '2.3.7'}\n")
        (self.src / 'cats.json').unlink()
        data = (self.src / 'bottts.json').read_bytes() + b'\n'
        (self.src / 'bottts.json').write_bytes(data)
        (self.src / 'new-style.json').write_bytes(data)
        self.assertTrue(catalog.update(self.root, self.upstream, self.pin))
        self.assertIn("'2.4.0'", init.read_text())
        self.assertEqual(data, (self.root / 'vendor/new-style.json').read_bytes())
        self.assertFalse((self.root / 'love_dicebear/styles/cats.lua').exists())
        self.assertFalse((self.root / 'vendor/cats.json').exists())
        self.assertTrue((self.root / 'love_dicebear/styles/new-style.lua').exists())
        registry = (self.root / 'love_dicebear/styles/registry.lua').read_text()
        self.assertIn('new-style', registry)
        self.assertNotIn('"cats"', registry)
        self.assertIn(self.pin, (self.root / 'STYLES.md').read_text())
        self.assertIn(self.pin, (self.root / 'THIRD_PARTY.md').read_text())
        self.assertFalse(catalog.update(self.root, self.upstream, self.pin))
        self.assertIn("'2.4.0'", init.read_text())

    def test_rejects_empty_or_invalid_catalog_before_writing(self):
        before = (self.root / 'love_dicebear/init.lua').read_bytes()
        for path in self.src.glob('*.json'):
            path.unlink()
        with self.assertRaises(ValueError):
            catalog.update(self.root, self.upstream, self.pin)
        (self.src / 'broken.json').write_text('{}')
        with self.assertRaises(ValueError):
            catalog.update(self.root, self.upstream, self.pin)
        self.assertEqual(before, (self.root / 'love_dicebear/init.lua').read_bytes())


if __name__ == '__main__':
    unittest.main()
