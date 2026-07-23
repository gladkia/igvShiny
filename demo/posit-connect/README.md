# igvShiny public demo — Posit Connect Cloud

A trimmed, deploy-ready copy of the flagship demo (`inst/demos/igvShinyDemo.R`)
for hosting a clickable public demo on [Posit Connect Cloud](https://connect.posit.cloud/).

## What's different from the in-package demo

The "BAM local data" button and its `readGAlignments()` call were removed. That
call is the *only* reason the full demo needs `GenomicAlignments` + `Rsamtools`
— two heavy Bioconductor C-compiled packages. Dropping it keeps the deploy light
without losing the alignment-track demo: the **BAM from URL** and **CRAM from
URL** buttons still show alignments, because igv.js streams those files directly
in the browser (zero server-side dependency).

Server-side runtime footprint is tiny: a 74 KB `gwas.RData` loaded at startup
(from the installed package via `system.file()`) plus small in-memory
`data.frame`s built on click. All heavy rendering happens client-side in igv.js.

## Deploy

Connect Cloud publishes from a public GitHub repo and needs `manifest.json` in
the content directory to know which packages to install.

The manifest pins `igvShiny` to the **development version from GitHub**
(`gladkia/igvShiny@master`), not the Bioconductor release — so the demo tracks
the newest code. Regenerate it whenever `app.R` or its dependencies change, and
make sure the locally installed `igvShiny` is the GitHub build first, so the
manifest records the GitHub source rather than Bioconductor:

```r
# install the dev version so writeManifest records source = github:
remotes::install_github("gladkia/igvShiny", ref = "master")

# then, from repo root, with rsconnect installed:
rsconnect::writeManifest("demo/posit-connect")
```

Then in the Connect Cloud UI:

1. **New content → from GitHub**, pick `gladkia/igvShiny`.
2. Primary file: `demo/posit-connect/app.R`.
3. Publish. Connect Cloud installs from `manifest.json` — CRAN via PPM for most
   packages, and `igvShiny` straight from GitHub master — then serves the app.

## Caveat — external URL buttons

**BAM from URL**, **CRAM from URL**, and **BedGraph from URL** stream from
`1000genomes.s3.amazonaws.com` / `encodeproject.org`. When those hosts are slow
or return 5xx the tracks look broken even though the app is fine. The inline /
local-data buttons (BED, BedGraph, bed9, GWAS) always work offline.
