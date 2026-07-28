## igvShiny 1.9.27
* Remove the mm10 and danRer11 reference workaround, unneeded with igv.js 3.x (#107)
* Drop four unused igv.js builds and the unreferenced stylesheet from the package
* Read the genome registry igv.js 3.x uses and document the UCSC dependency it carries

## igvShiny 1.9.26
* Update the Connect Cloud manifest, which pinned a commit older than the demo
* Expose the installed igvShiny version in the demo sidebar

## igvShiny 1.9.25
* Allow a gwas column mapping through trackConfig, for loadGwasTrack callers
* Extend the Connect Cloud demo with a gwas track using custom columns and colors

## igvShiny 1.9.24
* Send the gwas column mapping to igv.js, so any data frame layout works (#32)
* Support a chromosomeColorMap argument coloring gwas points per chromosome (#46)
* Prevent out-of-range gwas column numbers from yielding a silently empty track

## igvShiny 1.9.23
* Restore the full three-system matrix on every pull request
* Remove the full-ci label, redundant once macOS and Windows finish in minutes
* Correct the macOS libxml2 config path, wrong since the runners moved to arm64

## igvShiny 1.9.22
* Reduce the pull request matrix to Linux, running macOS and Windows on master and nightly
* Enable a full-ci label to force the whole matrix on a pull request

## igvShiny 1.9.21
* Bump the GitHub Actions used in CI to their current major versions
* Replace the mutable `upload-artifact@master` reference with a released version

## igvShiny 1.9.20
* Fix `getGenomicRegion()` in a shiny module whose id is not `igv`

## igvShiny 1.9.19
* Reduce bioconductor.org round trips in CI and cancel superseded pull request runs
* Disable the BiocCheck deprecation lookup, the last CI step reaching bioconductor.org
* Prevent the macOS and Windows jobs from rebuilding every package on each run

## igvShiny 1.9.17
* Enforce green CI on macOS and Windows by dropping the allow-failure matrix flags

## igvShiny 1.9.16
* Add a getting-started vignette covering the widget, track loaders, navigation and modules

## igvShiny 1.9.15
* Fix the 404 on locally written tracks when the tracks directory moves

## igvShiny 1.9.14
* Allow `igvShiny()` to build outside a shiny session, for scripts and vignettes

## igvShiny 1.9.13
* Prevent NA or empty names in `trackConfig`, warning instead of erroring
* Enforce a non-empty scalar string for the startup track `url`

## igvShiny 1.9.12
* Add unit tests for the track loaders, driven by a fake Shiny session (M3)
* Replace the gladki.pl test fixtures with a local httpuv static server
* Extend test coverage from 16% to 92% (M3)

## igvShiny 1.9.11
* Enable the covr coverage step on every Linux CI build (M3)
* Add `covr` to Suggests

## igvShiny 1.9.10
* Wrap the 25 over-long lines in `R/igvShiny.R` at 80 characters (BiocCheck)
* Move `paste()` out of `warning()` calls, keeping the message text unchanged
* Exclude local `*.BiocCheck/` output folders from git

## igvShiny 1.9.9
* Bump the bundled igv.js from 2.13.1 to 3.8.4 (minified) and update the
  `locuschange` handler for the 3.x event payload — it now reads the locus from
  the `referenceFrameList` and keeps the whole-genome "all" view working (#116)

## igvShiny 1.9.8
* Add labels to all vignette code chunks (BiocCheck)
* Add the R Consortium `fnd` (funder) role to `Authors@R` — the ISC grant
  funding this work (BiocCheck)

## igvShiny 1.9.7
* Add a public, clickable demo app deployed on Posit Connect Cloud, plus the
  repository's first `README` (#117, #118)
* Add a modern `bslib` (Bootstrap 5) UI to the Connect demo — grouped controls,
  themed layout, IGV viewer in a full-screen-able card (#119)

## igvShiny 1.9.6
* docs: credit past contributors in `DESCRIPTION` — Carolina Heimann, Steffen
  Klasberg, Vincent Carey, Parv Sachdeva and Mateusz Gladki are now listed as
  `ctb`

## igvShiny 1.9.5
* fix: pass `tracks` startup option through to igv.js (#36, thanks @M4teuszzGl4dki)

## igvShiny 1.9.4
* fix: pass `autoscaleGroup` through in `loadBedGraphTrackFromURL` (#105, thanks @M4teuszzGl4dki)
* fix: support string-based `autoscaleGroup` values in both bedGraph handlers

## igvShiny 1.9.3
* ci: fix Windows/macOS CI failures (install pkgload alongside pkgdown)
* ci: add automated push to Bioconductor devel on merge to master

## igvShiny 1.9.2
* fix(ci): add testthat to Suggests field in DESCRIPTION to fix warning

## igvShiny 1.9.1
* fix(ci): remove missing test_igvShiny_package.R from Collate field to fix build error

## igvShiny 1.9.0
* Version bump due to Bioconductor 3.23 devel synchronization.

## igvShiny 1.5.2 - 2025-09-02
* support passing additional track options to igv.js

## igvShiny 1.5.1 - 2025-09-01
* migrate from RUnit to testthat

## igvShiny 1.1.5 - 2024-08-29
* fix issue with loading bed files when app is run with query strings

## igvShiny 1.1.4 - 2024-08-25
* switch from Rcurl::url.exists to httr::http_error (Windows compatibility)

## igvShiny 1.1.3 - 2024-08-25
* stop using Amazon S3 URLs by default

## igvShiny 1.1.2 - 2024-08-16
* fix issue with VCF files

## igvShiny 1.1.1 - 2024-08-10
* fix issue with custom files not working properly

## igvShiny 1.0.0 - 2024-08-10
* sync with Bioconductor (3_19 release)

## igvShiny 0.99.7 - 2024-04-23
* change file links from igv-data.systemsbiology.net to gladki.pl/igvr

## igvShiny 0.99.6 - 2024-03-16
* add shinytest2 for igvShinyDemo-GFF3.R

## igvShiny 0.99.5 - 2024-03-14
* fix issues with GFF3 data
  * make igvShiny demo app for GFF3 working
  * update trackName of GFF3 (from URL)
  * udpate path to local GFF3

## igvShiny 0.99.4 - 2024-02-28
* add pkgdown content

## igvShiny 0.99.3 - 2024-02-16
* fix bug in function loadBamTrackFromLocalData
* improvge way of loading BAM files - show mismatches

## igvShiny 0.99.2 - 2024-02-09
* fix some Bioconductor NOTEs

## igvShiny 0.99.1 - 2024-02-05
* fix some Bioconductor NOTEs

## igvShiny 0.99.0 - 2024-02-04
* make the first Bioconductor release

