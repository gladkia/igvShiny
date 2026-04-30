# load a bedgraph track from a URL

load a bedgraph track provided as a data.frame

## Usage

``` r
loadBedGraphTrackFromURL(
  session,
  id,
  trackName,
  url,
  color = "gray",
  trackHeight = 30,
  autoscale = TRUE,
  min = 0,
  max = 1,
  autoscaleGroup = -1,
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

- url:

  character

- color:

  character string, a legal CSS color, or "random", "gray" by default

- trackHeight:

  an integer, 30 (pixels) by default

- autoscale:

  logical

- min:

  numeric, consulted when autoscale is FALSE

- max:

  numeric, consulted when autoscale is FALSE

- autoscaleGroup:

  numeric(1) defaults to -1

- deleteTracksOfSameName:

  logical(1) defaults to TRUE

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
