# jekyll-deploy

Builds and deploys a jekyll page to GitHub pages.

Features:
* build and test modes
* record the site's source commit using a merge commit
* specify a target branch

## Usage

To deploy from master and update once a day:

```yaml
name: Jekyll Deploy

on:
  push:
    branches:
      # only deploy from master
      - master
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
        uses: DavidS/jekyll-deploy@master
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
        uses: DavidS/jekyll-deploy@master
        with:
          build-only: true
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```

The `GH_PAGES_TOKEN` needs the `public_repo` scope to be able to trigger deployments on a public repo or the full `repo` scope to deploy a private repository. Please note that this is circumventing GitHub's protection for infinitely recursive Actions invocations, so proceed with caution!

## Specifying a target branch

By default, this action deploys the compiled output to `gh-pages`, GitHub's default. If you want to use a different branch, you can use the `target-branch` input to do so. For example, to deploy to `master`:

```yaml
      - name: Build & Deploy to custom branch
        uses: DavidS/jekyll-deploy@master
        with:
          target-branch: master
        env:
          JEKYLL_ENV: production
          GH_PAGES_TOKEN: ${{ secrets.GH_PAGES_TOKEN }}
```