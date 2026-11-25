"""Catch missing public API entries and broken generated site links."""
from html.parser import HTMLParser
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

root = Path(__file__).resolve().parents[2]
for source, reference, prefix in [
    ('love_dicebear/init.lua', 'docs/api/core.md', ''),
    ('love_dicebear/http.lua', 'docs/api/http.md', 'http.'),
    ('love_dicebear/thorvg.lua', 'docs/api/thorvg.md', 'avatars.'),
]:
    code = (root / source).read_text()
    docs = (root / reference).read_text()
    for name in re.findall(r'function M\.(\w+)\(', code):
        assert prefix + name + '(' in docs, (reference, name)
    for name in re.findall(r'function Request:(\w+)\(', code):
        assert 'request:' + name + '(' in docs, (reference, name)
assert 'http.url(' in (root / 'docs/api/http.md').read_text()
assert 'http.clearCache(' in (root / 'docs/api/http.md').read_text()
assert '`version`' in (root / 'docs/api/core.md').read_text()
core = (root / 'love_dicebear/options.lua').read_text().split('function M.describe')[0]
for option in re.findall(r'^  (\w+) = \{type =', core, re.M):
    assert '`' + option + '`' in (root / 'docs/options.md').read_text(), option
registry = (root / 'love_dicebear/styles/registry.lua').read_text()
names = re.findall(r'["\']([^"\']+)["\']', registry)
assert names, 'style registry was not parsed' 
for name in names:
    assert (root / 'docs/styles' / (name + '.md')).exists(), name

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.path, self.ids, self.links = path, set(), []
        self.feed(path.read_text())
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if attrs.get(key):
                self.links.append(attrs[key])

pages = {p.resolve(): Page(p) for p in (root / 'site').rglob('*.html')}
for page in pages.values():
    for link in page.links:
        url = urlsplit(link)
        if url.scheme or url.netloc: continue
        path = unquote(url.path)
        if path.startswith('/love-dicebear/'):
            target = root / 'site' / path[len('/love-dicebear/'):]
        elif path.startswith('/'):
            raise AssertionError(('unexpected root path', page.path, link))
        else:
            target = page.path.parent / path if path else page.path
        if target.is_dir(): target /= 'index.html'
        target = target.resolve()
        assert target.exists(), (page.path, link)
        if url.fragment and target in pages:
            assert unquote(url.fragment) in pages[target].ids, (page.path, link, 'missing anchor')
print(f'PASS: public API entries, {len(names)} style pages, and links/anchors in {len(pages)} HTML pages')
