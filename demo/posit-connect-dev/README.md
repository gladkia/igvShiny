# igvShiny Dev demo — Posit Connect Cloud

Deploy wrapper for hosting the development demo with Custom Genome and Local BAM Streaming
(`inst/demos/custom-genome-bam.R`) as a public app on
[Posit Connect Cloud](https://connect.posit.cloud/) at `gladkia-igvshiny-dev.share.connect.posit.cloud`.

## What `app.R` contains

It runs `inst/demos/custom-genome-bam.R` out of the installed package.
This demo showcases:
1. Loading a non-stock reference genome (HLA-A*24:02:01:01) with fasta, fasta index, and GFF3 annotation.
2. Streaming local BAM and BAI alignment files directly from disk via HTTP 206 Partial Content range requests (`serveLocalFile()` and `loadBamTrackFromLocalFile()`), requiring zero copying and zero R RAM overhead.

## Deploy to Posit Connect Cloud

Connect Cloud publishes from a public GitHub repository and needs `manifest.json` in
the content directory to know which packages to install.

### Initial Setup on Posit Connect Cloud
1. In Posit Connect Cloud, click **Publish** -> **Git**.
2. Select repository `gladkia/igvShiny`, branch `master`.
3. Specify Primary File: `demo/posit-connect-dev/app.R`.
4. Set custom URL slug / name: `gladkia-igvshiny-dev`.

### Re-pinning to a new commit
Connect installs `igvShiny` from the commit recorded in `manifest.json`.
To update the pin to the latest commit:

```bash
./demo/posit-connect-dev/bump-pin.sh --check   # check for drift
./demo/posit-connect-dev/bump-pin.sh           # re-pin to origin/master
./demo/posit-connect-dev/bump-pin.sh <sha>     # re-pin to specific commit
```
