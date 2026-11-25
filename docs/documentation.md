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
