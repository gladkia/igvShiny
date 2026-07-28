# load a bam track which, with index, is served up by http

load a remote bam track

## Usage

``` r
loadBamTrackFromURL(
  session,
  id,
  trackName,
  bamURL,
  indexURL,
  deleteTracksOfSameName = TRUE,
  displayMode = "EXPANDED",
  showAllBases = FALSE,
  trackConfig = list()
)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

- trackName:

  character string

- bamURL:

  character string http url for the bam file, typically very large

- indexURL:

  character string http url for the bam file index, typically small

- deleteTracksOfSameName:

  logical, default TRUE

- displayMode:

  character string, possible values are "EXPANDED"(default), "SQUISHED"
  or "COLLAPSED"

- showAllBases:

  logical, show all bases in the alignment, default FALSE

- trackConfig:

  a named list of additional igv.js track configuration options.
  Alignment tracks read `sort`:
  `list(sort = list(chr = "chr1", position = 155160540, option = "TAG", tag = "HP"))`
  sorts the reads at that 1-based position by the HP tag. Any igv.js
  sort option works (BASE, STRAND, INSERT_SIZE, ...); reads sort
  descending unless `direction = "ASC"`.

## Value

nothing

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
