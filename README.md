# jekyll-deploy

Builds and deploys a jekyll page to GitHub pages.

Features:
* build and test modes
* record the site's source commit using a merge commit
* build from any subdirectory in your repository
* specify a target branch

## Usage

To deploy every update to the `main` branch and regenerate the site once a day:

```yaml
name: Jekyll Deploy

on:
  push:
    branches:
      # deploy on updates on main
      - main
  schedule:
    # redeploy every morning to update unpublished pages
    - cron: "0 2 * * *"

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Cache gems
        uses: actions/cache@v1
        with:
          path: vendor/gems
          key: ${{ runner.os }}-build-${{ hashFiles('**/Gemfile.lock') }}
          restore-keys: |
            ${{ runner.os }}-build-
            ${{ runner.os }}-

      - name: Build & Deploy to GitHub Pages
        uses: DavidS/jekyll-deploy@main
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```

To check PRs, set `build-only: true`:

```yaml
name: Jekyll Test

on: [ pull_request ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Cache gems
        uses: actions/cache@v1
        with:
          path: vendor/gems
          key: ${{ runner.os }}-build-${{ hashFiles('**/Gemfile.lock') }}
          restore-keys: |
            ${{ runner.os }}-build-
            ${{ runner.os }}-

      - name: Test
        uses: DavidS/jekyll-deploy@
        with:
          build-only: true
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```

The `GH_PAGES_TOKEN` needs the `public_repo` scope to be able to trigger deployments on a public repo or the full `repo` scope to deploy a private repository. Please note that this is circumventing GitHub's protection for infinitely recursive Actions invocations, so proceed with caution!

## Specifying a source directory

If your site's source is not at the root of the repository, you can use the `source-dir` input to tell this action where the source can be found. For example, if your site is in a `docs/jekyll` subdirectory:

```yaml
      - name: Build & Deploy to custom branch
        uses: DavidS/jekyll-deploy@
        with:
          source-dir: docs/jekyll
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```


## Specifying a target branch

By default, this action deploys the compiled output to `gh-pages`, GitHub's default. If you want to use a different branch, you can use the `target-branch` input to do so. For example, to deploy to `docs`:

```yaml
      - name: Build & Deploy to custom branch
        uses: DavidS/jekyll-deploy@main
        with:
          target-branch: docs
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```
