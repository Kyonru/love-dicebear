---
icon: lucide/book-open
---
# Documentation maintenance

The site is built with [Zensical](https://zensical.org/) and published at
<https://kyonru.github.io/love-dicebear/>. Python 3.11 or newer is required;
CI uses Python 3.14. The version of Zensical is pinned in `requirements-docs.txt`.

## Preview locally

From the repository root:

```sh
python3 -m venv .venv-docs
source .venv-docs/bin/activate
python -m pip install -r requirements-docs.txt
python scripts/prepare_docs.py
zensical serve
```

On Windows, use `python` instead of `python3` and activate with
`.venv-docs\Scripts\activate` in Command Prompt.
Open the local URL printed by Zensical. Markdown edits reload automatically.

## Build

With the virtual environment activated:

```sh
python scripts/prepare_docs.py
zensical build --clean --strict
```

The generated site is written to `site/`, which is ignored by Git. Edit guides
in `docs/` and navigation in `zensical.toml`. `scripts/prepare_docs.py` copies
`STYLES.md` and `THIRD_PARTY.md` into the site so the catalog and attribution
notices have a single source of truth. Rerun it after those files change;
do not edit the ignored copies in `docs/`.

## GitHub Pages

The `Documentation` workflow builds pull requests without deploying them.
Pushes to `main` build and deploy to GitHub Pages. You can also run it manually
from the repository's Actions tab with `main` selected.

The repository's **Settings → Pages → Build and deployment → Source** must be
**GitHub Actions**. A private repository needs a GitHub plan that supports Pages
for private repositories; the workflow does not change repository visibility.

Deployment uses the built Pages artifact and GitHub's short-lived token. No
personal access token or generated `gh-pages` branch is needed. Only the deploy
job has Pages and OIDC write permissions, and deployments run one at a time.

See [Zensical's publishing guide](https://zensical.org/docs/publish-your-site/)
for the underlying GitHub Pages integration.

## Navigation and reference checks

The header's sun/moon toggle switches between light and dark mode. On the first
visit, the site follows the system color preference; a manual selection is saved
for subsequent visits. Both palettes are configured in `zensical.toml` using
Zensical's built-in theme colors.

The theme uses `navigation.instant` to fetch internal pages without reloading
the browser document. Keep `site_url` set to the GitHub Pages project URL.
Each source page has a Lucide `icon` in its front matter; the preparation script
adds icons to generated pages. A small `sidebar.js` hook preserves desktop menu
scroll position after the theme mounts each page; Zensical still owns routing.

The preparation script also generates `docs/styles/` from the pinned style
JSON definitions. Edit the canonical definitions through the normal import
workflow, not generated documentation. The core API describes shared options;
these pages enumerate the style-specific choices.

The docs workflow runs browser checks before deploying: navigation icons,
instant page changes, retained sidebar scrolling, history, style links, and
mobile layout, system color preferences, and theme selection persistence.
Screenshots are attached as `documentation-previews` artifacts.
To run those checks locally after building:

```sh
npm ci --prefix tests/docs --ignore-scripts
tests/docs/node_modules/.bin/playwright install chromium
npm test --prefix tests/docs
```

The browser test serves the built files through request interception at the real
Pages URL, so it does not need a local server or change the published site.
