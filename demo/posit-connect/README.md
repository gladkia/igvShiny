# igvShiny public demo — Posit Connect Cloud

Deploy wrapper for hosting the flagship demo (`inst/demos/igvShinyDemo.R`) as a
clickable public app on [Posit Connect Cloud](https://connect.posit.cloud/).

## What `app.R` contains

Two lines: it runs `inst/demos/igvShinyDemo.R` out of the installed package.
There is no second copy of the app to keep in sync — this used to be a
hand-maintained fork, and it drifted from the original on every new loader.

The flagship demo loads no file server-side: no `*FromLocalData` loader, hence
no `GenomicAlignments` / `Rsamtools` / `VariantAnnotation` — the heavy
C-compiled Bioconductor packages — in this deploy. Those loaders are demoed by
`inst/demos/local-data.R`, which is not what gets published here. Alignment
tracks are still on show: **BAM (URL)** and **CRAM (URL)** stream in the
browser, with zero server-side dependency.

Server-side runtime footprint is tiny: a 74 KB `gwas.RData` loaded at startup
(from the installed package via `system.file()`) plus small in-memory
`data.frame`s built on click. All heavy rendering happens client-side in igv.js.

## Deploy

Connect Cloud publishes from a public GitHub repo and needs `manifest.json` in
the content directory to know which packages to install.

The manifest pins `igvShiny` to a **development build from GitHub**
(`gladkia/igvShiny`), not the Bioconductor release — so the demo can show work
that has not been released yet.

> **The pin is a commit, not a branch.** `writeManifest` records
> `GithubSHA1`/`RemoteSha` of the build installed at the time, and Connect Cloud
> installs *that commit* — `GithubRef: master` is decoration. A republish
> therefore serves a possibly much older package.
>
> Since `app.R` now runs the demo *out of the package*, the pin decides which
> demo is live: a new button merged to master does not appear on the public
> demo until the SHA is bumped. Bump the two SHA fields (or regenerate) in the
> same commit that the demo needs. Serving an old package can also kill the app
> on the first click — an error inside `observeEvent` ends the Shiny session and
> the page just greys out, with nothing in the UI to explain it. The sidebar
> footer prints the installed `igvShiny` version — check it there first.

### Routine: publish what is on master

After a demo change lands on master, move the pin — six fields have to stay in
step (two SHAs, the recorded version, the file checksums), so use the script:

```bash
./demo/posit-connect/bump-pin.sh --check   # is the live demo behind master?
./demo/posit-connect/bump-pin.sh           # re-pin to origin/master
./demo/posit-connect/bump-pin.sh <sha>     # or to one specific commit
```

Then commit the manifest, push to master, and hit republish in Connect Cloud.
Confirm it took: the sidebar footer must read the version the script printed.

`--check` exits non-zero on drift, so it also works as a post-merge reminder.

### When dependencies change

The script only moves the pin. If the demo starts using a *new package*, the
`packages` block has to be rebuilt — install the GitHub build first, so the
manifest records the GitHub source rather than Bioconductor:

```r
remotes::install_github("gladkia/igvShiny", ref = "master")
rsconnect::writeManifest("demo/posit-connect")   # from repo root
```

Note that `writeManifest` reformats the whole file; check the diff is only what
you meant to change.

### First-time setup (already done)

1. **New content → from GitHub**, pick `gladkia/igvShiny`.
2. Primary file: `demo/posit-connect/app.R`.
3. Publish. Connect Cloud installs from `manifest.json` — CRAN via PPM for most
   packages, and `igvShiny` straight from GitHub — then serves the app.

The source branch must be **master**: a feature branch disappears when the PR
merges, and the next republish fails with nothing to point at.

## Caveat — external URL buttons

**BAM from URL**, **CRAM from URL**, and **BedGraph from URL** stream from
`1000genomes.s3.amazonaws.com` / `encodeproject.org`. When those hosts are slow
or return 5xx the tracks look broken even though the app is fine. The inline /
local-data buttons (BED, BedGraph, bed9, GWAS) always work offline.
