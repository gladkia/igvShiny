# Changelog

## igvShiny 1.9.9

- Bump the bundled igv.js from 2.13.1 to 3.8.4 (minified) and update the
  `locuschange` handler for the 3.x event payload — it now reads the
  locus from the `referenceFrameList` and keeps the whole-genome “all”
  view working ([\#116](https://github.com/gladkia/igvShiny/issues/116))

## igvShiny 1.9.8

- Add labels to all vignette code chunks (BiocCheck)
- Add the R Consortium `fnd` (funder) role to `Authors@R` — the ISC
  grant funding this work (BiocCheck)

## igvShiny 1.9.7

- Add a public, clickable demo app deployed on Posit Connect Cloud, plus
  the repository’s first `README`
  ([\#117](https://github.com/gladkia/igvShiny/issues/117),
  [\#118](https://github.com/gladkia/igvShiny/issues/118))
- Add a modern `bslib` (Bootstrap 5) UI to the Connect demo — grouped
  controls, themed layout, IGV viewer in a full-screen-able card
  ([\#119](https://github.com/gladkia/igvShiny/issues/119))

## igvShiny 1.9.6

- docs: credit past contributors in `DESCRIPTION` — Carolina Heimann,
  Steffen Klasberg, Vincent Carey, Parv Sachdeva and Mateusz Gladki are
  now listed as `ctb`

## igvShiny 1.9.5

- fix: pass `tracks` startup option through to igv.js
  ([\#36](https://github.com/gladkia/igvShiny/issues/36), thanks
  [@M4teuszzGl4dki](https://github.com/M4teuszzGl4dki))

## igvShiny 1.9.4

- fix: pass `autoscaleGroup` through in `loadBedGraphTrackFromURL`
  ([\#105](https://github.com/gladkia/igvShiny/issues/105), thanks
  [@M4teuszzGl4dki](https://github.com/M4teuszzGl4dki))
- fix: support string-based `autoscaleGroup` values in both bedGraph
  handlers

## igvShiny 1.9.3

- ci: fix Windows/macOS CI failures (install pkgload alongside pkgdown)
- ci: add automated push to Bioconductor devel on merge to master

## igvShiny 1.9.2

- fix(ci): add testthat to Suggests field in DESCRIPTION to fix warning

## igvShiny 1.9.1

- fix(ci): remove missing test_igvShiny_package.R from Collate field to
  fix build error

## igvShiny 1.9.0

- Version bump due to Bioconductor 3.23 devel synchronization.

## igvShiny 1.5.2 - 2025-09-02

- support passing additional track options to igv.js

## igvShiny 1.5.1 - 2025-09-01

- migrate from RUnit to testthat

## igvShiny 1.1.5 - 2024-08-29

- fix issue with loading bed files when app is run with query strings

## igvShiny 1.1.4 - 2024-08-25

- switch from Rcurl::url.exists to httr::http_error (Windows
  compatibility)

## igvShiny 1.1.3 - 2024-08-25

- stop using Amazon S3 URLs by default

## igvShiny 1.1.2 - 2024-08-16

- fix issue with VCF files

## igvShiny 1.1.1 - 2024-08-10

- fix issue with custom files not working properly

## igvShiny 1.0.0 - 2024-08-10

- sync with Bioconductor (3_19 release)

## igvShiny 0.99.7 - 2024-04-23

- change file links from igv-data.systemsbiology.net to gladki.pl/igvr

## igvShiny 0.99.6 - 2024-03-16

- add shinytest2 for igvShinyDemo-GFF3.R

## igvShiny 0.99.5 - 2024-03-14

- fix issues with GFF3 data
  - make igvShiny demo app for GFF3 working
  - update trackName of GFF3 (from URL)
  - udpate path to local GFF3

## igvShiny 0.99.4 - 2024-02-28

- add pkgdown content

## igvShiny 0.99.3 - 2024-02-16

- fix bug in function loadBamTrackFromLocalData
- improvge way of loading BAM files - show mismatches

## igvShiny 0.99.2 - 2024-02-09

- fix some Bioconductor NOTEs

## igvShiny 0.99.1 - 2024-02-05

- fix some Bioconductor NOTEs

## igvShiny 0.99.0 - 2024-02-04

- make the first Bioconductor release
