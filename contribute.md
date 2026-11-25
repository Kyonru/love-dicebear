# Contributing to love-dicebear

Use this guide to run the example, change the library, verify compatibility,
and maintain the documentation. For installation and use in a game, see the
[README](README.md) and [documentation](https://kyonru.github.io/love-dicebear/).

## Set up a checkout

```sh
git clone https://github.com/Kyonru/love-dicebear.git
cd love-dicebear
```

Use Lua 5.1, Lua 5.4, or LuaJIT for standalone tests. Install LÖVE 11.x for
rendering checks and Node.js 22 or newer for the launcher and parity tests.
Python 3.11 or newer is needed to build the documentation.

## Run the example

Install [LÖVE 11.x](https://love2d.org/) and Node.js 22 or newer, then run:

```sh
npm run dev
```

This downloads the **love-thorvg v0.3.0** release for your machine, verifies its
pinned SHA256 checksum, installs the renderer and license notices in the ignored
`love_thorvg/` directory, and launches the example. Subsequent runs reuse the
installed renderer and work offline. An existing local renderer is preserved;
an incomplete installation reports an error instead of being overwritten.

Prebuilt packages cover macOS ARM64/x64, Linux x64, and Windows x64. Extraction
uses `unzip` on macOS/Linux or PowerShell on Windows. LÖVE itself must be
installed separately; the launcher checks `PATH`, `/Applications/love.app` on
macOS, and the standard Program Files location on Windows. Use `LOVE` to select
another executable. The example uses love-thorvg by default.

```sh
npm run setup                  # download the renderer without launching
npm run dev -- --render-test    # run native rendering checks
npm run dev -- --style lorelei  # start with a specific style
LOVE=/path/to/love npm run dev  # select a LÖVE executable (macOS/Linux)
```

To use API-rendered PNGs, including the text-based styles, run:

```sh
npm run dev -- --renderer http --style initials
npm run dev -- --renderer http --style initials --cache
```

HTTP mode needs desktop `curl` on `PATH` and skips ThorVG setup. **H** switches
renderers, **S** saves PNG in HTTP mode or SVG in local mode, and **Enter** retries
or forces an HTTP refresh. `--cache` opts into a one-day disk cache; it is off by
default. Switching back to the local renderer requires love-thorvg to be installed.

The example also shows clickable rendering controls. **C** toggles disk caching,
**T** cycles its lifetime (5 minutes, 1 hour, or 24 hours), **Enter** refreshes
from the server, and **Delete** clears the current URL from the cache while
keeping the preview. The panel reports whether the image came from the network
or disk cache. Cache controls become available in HTTP mode.

No `npm install` is needed to launch: the dev script uses Node's built-in APIs.
Run `npm ci --ignore-scripts` when you want the JavaScript reference used by
`npm test`. For a previously downloaded release ZIP, set `LOVE_THORVG_ARCHIVE`
to its path; the same pinned checksum is checked. The launcher does not watch
files or hot-reload; restart it after editing Lua.

## Run tests and update styles

```sh
lua tests/run.lua
lua tests/adapter.lua
lua tests/animation.lua
lua tests/save.lua
lua tests/editor.lua
lua tests/http_url.lua
lua tests/http.lua
lua tests/http_worker.lua
npm ci --ignore-scripts
npm test
npm run test:dev
love . --test
love . --editor-test  # editor UI/input/save smoke test; no renderer needed
love . --render-test  # requires love_thorvg/
love . --catalog-render-test  # all 63 with SVG font support; otherwise 61
love . --animation-test  # all 21 animated styles through love-thorvg 0.3.0
love . --font-test  # text pixels, shared ownership, and missing-font errors
love . --http-test  # opt-in live API download, draw, save, and disk-cache test
```

Node is used for the development launcher and JavaScript reference comparison;
it is not needed by either runtime renderer.
Set `LUA=luajit` to run the parity suite with another Lua executable, or
`LOVE=/path/to/love npm test` to compare SVGs generated inside LÖVE.

The parity suite covers all bundled styles and their variant selections, Unicode seeds, weights, visibility,
palette filtering, XML escaping, and transforms. The native smoke suite checks
all 53 Bottts variants; the catalog smoke suite checks all 63 styles with an
SVG-font-capable renderer (61 otherwise), then resizes and releases each document. It also generates a
`catalog-smoke.png` contact sheet in the LÖVE save directory. These are not
pixel-by-pixel comparisons with another SVG renderer. The 1.x baseline of 7,096 parity cases
also passed inside LÖVE/LuaJIT; `npm test` reports the current catalog total. To test one style, run `npm test -- lorelei`.
Native checks passed against love-thorvg commit
`02bc96e9c63f50a99beba371534fd06a14aae407` on macOS ARM64.

Run `python3 scripts/import_style.py` to regenerate the Lua artwork from the
vendored JSON. Do not edit the generated style directly. Review licensing and
parity before changing the upstream pin.

Code is MIT licensed. Artwork licenses vary by style; see
[STYLES.md](STYLES.md) and [THIRD_PARTY.md](THIRD_PARTY.md).
This is an independent Lua port.

## Build the documentation

```sh
python3 -m venv .venv-docs
source .venv-docs/bin/activate
python -m pip install -r requirements-docs.txt
python scripts/prepare_docs.py
zensical serve
```

On Windows, use `python` and activate with `.venv-docs\Scripts\activate`
in Command Prompt. Preview the site at the URL printed by Zensical.

Before submitting documentation changes, run:

```sh
python scripts/prepare_docs.py
zensical build --clean --strict
```

Edit guides in `docs/` and navigation in `zensical.toml`. The preparation script
copies the canonical style catalog and third-party notices into the site;
do not edit their generated copies. Pull requests build the docs, and pushes
to `main` deploy GitHub Pages. See [documentation maintenance](docs/documentation.md)
for the full publishing setup.

## Package and publish a release

Releases follow the same tag-driven approach as love-thorvg. There is one
portable archive, because the Lua library does not bundle native dependencies.

1. Set `version` in `love_dicebear/init.lua` to the intended release version.
2. Update the guides for any API changes and run the relevant tests above.
3. Validate and inspect a local package (replace `v2.0.0` with your version):

   ```sh
   python3 tests/release.py
   python3 scripts/package_release.py --version v2.0.0
   ```

4. Commit the changes, then push the release commit and matching tag:

   ```sh
   git push origin main
   git -c tag.gpgSign=false tag -a v2.0.0 -m "love-dicebear v2.0.0"
   git push origin v2.0.0
   ```

The tag must match the Lua version exactly (with a leading `v`). Prerelease tags
such as `v1.1.0-rc.1` produce GitHub prereleases. Creating the tag publishes a
release automatically after the full Lua/parity suite and packaging tests pass.
No release is created by an ordinary branch push. Merged catalog update PRs
also publish releases as described below.

The packager writes `dist/love-dicebear-<version>.zip` and `dist/SHA256SUMS`.
The ZIP includes the Lua entry point, all runtime Lua modules and styles,
required license notices, an installation README, and `VERSION`. Adapter code
is included, but love-thorvg binaries, curl, tests, examples, source JSON,
Node dependencies, and development tooling are excluded. Builds use stable
paths, timestamps, permissions, and ordering for repeatable archives.

The release workflow reuses the test workflow, then verifies the archive
checksum before uploading it to GitHub Releases with generated release notes.
Only the publishing job has repository write permissions. Existing releases
are not overwritten; investigate a failed publication before retrying it.
Do not move a published tag to different code.

## Automated catalog updates

The **Update DiceBear catalog** workflow checks `dicebear/styles` main monthly on the first day at
09:23 UTC and can also be run from the Actions tab. It compares the upstream
`src/*.json` files with `vendor/`. Unchanged artwork does not create a PR or bump
the version, even if unrelated upstream commits have landed.

When definitions change, the bot opens or refreshes one PR on
`automation/dicebear-catalog`, labeled `update` and `minor`. It copies the original
JSON bytes, records the upstream SHA in `vendor/dicebear-styles.commit`, regenerates
Lua modules and `STYLES.md`, updates attribution links, removes deleted styles,
and bumps the library version to the next minor (for example, `1.2.3` → `1.3.0`).
DiceBear Core remains pinned separately; this automation updates artwork only.

Enable **Settings → Actions → General → Workflow permissions → Allow GitHub
Actions to create and approve pull requests**. The workflow uses `GITHUB_TOKEN`;
no personal token or additional secret is needed. The workflow must be merged
into `main` before its schedule and manual dispatch are available.

Bot-created PR events do not trigger other workflows with `GITHUB_TOKEN`, so the
bot explicitly dispatches **Test** and **Documentation** on its branch. Check those
runs before merging; the bot never merges automatically. Review license changes,
removed styles, and parity failures. A new upstream feature may require manual
Lua support before the update can pass. Require the test checks in branch
protection if merges must be prevented when validation fails.

Merging this branch into `main` with both labels runs the complete release test
suite on the merge commit, packages the library, creates its matching `vX.Y.0`
tag, and publishes the GitHub release and checksum. Tag creation and publishing
happen in the same workflow because bot-created tags do not trigger another
workflow. Existing releases and tags are never overwritten. If a release fails,
inspect the run and rerun failed jobs; if a tag already exists it must point to
the same merge commit. Manual tag releases continue to work as before.

To reproduce an update locally, check out `dicebear/styles` separately and run:

```sh
python3 scripts/update_catalog.py --upstream /path/to/dicebear-styles
python3 tests/catalog_update.py
npm test
```

## Submit changes

Keep changes focused and describe the behavior they change. Include the checks
you ran and any limitations. Update the relevant guides when changing the
public API, example controls, or supported options. Preserve upstream notices
and verify parity when modifying generated output or updating style definitions.
