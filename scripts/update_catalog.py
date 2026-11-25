"""Sync a checked-out DiceBear catalog and prepare a minor library release."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = r"local M = \{version = '(\d+)\.(\d+)\.(\d+)'\}"


def update(root, upstream, pin):
    if not re.fullmatch(r'[0-9a-f]{40}', pin):
        raise ValueError('Expected an immutable upstream commit SHA')
    incoming = {}
    for path in sorted((upstream / 'src').glob('*.json')):
        if path.is_symlink() or not re.fullmatch(r'[a-z][a-z0-9-]*', path.stem) or path.stem == 'registry':
            raise ValueError(f'Invalid style path: {path.name}')
        data = path.read_bytes()
        definition = json.loads(data)
        if not isinstance(definition, dict) or not definition.get('meta', {}).get('license'):
            raise ValueError(f'Missing definition or license: {path.name}')
        incoming[path.name] = data
    if not incoming:
        raise ValueError('Upstream catalog is empty; refusing to remove every style')
    current = {p.name: p.read_bytes() for p in (root / 'vendor').glob('*.json')}
    if incoming == current:
        return False
    init = root / 'love_dicebear/init.lua'
    source = init.read_text()
    match = re.search(VERSION, source)
    if not match:
        raise ValueError('Expected a stable MAJOR.MINOR.PATCH library version')
    version = f'{int(match[1])}.{int(match[2]) + 1}.0'
    # Validate all inputs before writing. Keep upstream JSON bytes unchanged.
    old_pin = (root / 'vendor/dicebear-styles.commit').read_text().strip()
    for name, data in incoming.items():
        (root / 'vendor' / name).write_bytes(data)
    for name in current.keys() - incoming.keys():
        (root / 'vendor' / name).unlink()
        (root / 'love_dicebear/styles' / (Path(name).stem + '.lua')).unlink(missing_ok=True)
    (root / 'vendor/dicebear-styles.commit').write_text(pin + '\n')
    notices = root / 'THIRD_PARTY.md'
    notices.write_text(notices.read_text().replace(old_pin, pin))
    init.write_text(re.sub(VERSION, "local M = {version = '" + version + "'}", source))
    subprocess.run([sys.executable, str(root / 'scripts/import_style.py')], cwd=root, check=True)
    print(f'Prepared v{version}: {len(incoming)} styles at {pin}')
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upstream', required=True, type=Path)
    args = parser.parse_args()
    upstream = args.upstream.resolve()
    pin = subprocess.check_output(['git', '-C', str(upstream), 'rev-parse', 'HEAD'], text=True).strip()
    update(ROOT, upstream, pin)


if __name__ == '__main__':
    main()
