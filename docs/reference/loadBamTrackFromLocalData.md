# load GenomicAlignments data as an igv.js alignment track

load GenomicAlignments data as an igv.js alignment track

## Usage

``` r
loadBamTrackFromLocalData(
  session,
  id,
  trackName,
  data,
  deleteTracksOfSameName = TRUE,
  displayMode = "EXPANDED",
  trackConfig = list(),
  validateReference = TRUE
)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

- trackName:

  character string

- data:

  GenomicAlignments object

- deleteTracksOfSameName:

  logical, default TRUE

- displayMode:

  character string, possible values are "EXPANDED"(default), "SQUISHED"
  or "COLLAPSED"

- trackConfig:

  a named list of additional igv.js track configuration options, `sort`
  among them; see
  [`loadBamTrackFromURL`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromURL.md).

- validateReference:

  logical flag, default TRUE: checks track contigs against the active
  reference genome and emits warnings/toasts on mismatch.

## Value

nothing

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
