# load a scored genome annotation track provided as a data.frame

load a genome annotation track provided as a data.frame

## Usage

``` r
loadBedGraphTrack(
  session,
  id,
  trackName,
  tbl,
  color = "gray",
  trackHeight = 30,
  autoscale,
  autoscaleGroup = -1,
  min = NA_real_,
  max = NA_real_,
  deleteTracksOfSameName = TRUE,
  quiet = TRUE,
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

- tbl:

  data.frame, with at least "chrom" "start" "end" "score" columns

- color:

  character string, a legal CSS color, or "random", "gray" by default

- trackHeight:

  an integer, 30 (pixels) by default

- autoscale:

  logical

- autoscaleGroup:

  numeric(1) defaults to -1

- min:

  numeric, consulted when autoscale is FALSE

- max:

  numeric, consulted when autoscale is FALSE

- deleteTracksOfSameName:

  logical, default TRUE

- quiet:

  logical, default TRUE, controls verbosity

- trackConfig:

  a named list of additional igv.js track configuration options.

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
