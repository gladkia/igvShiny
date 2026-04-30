# load a seg track provided as a data.frame

load a SEG track provided as a data.frame. igv "displays segmented data
as a blue-to-red heatmap where the data range is -1.5 to 1.5... The
segmented data file format is the output of the Circular Binary
Segmentation algorithm (Olshen et al., 2004)".

## Usage

``` r
loadSegTrack(
  session,
  id,
  trackName,
  tbl,
  deleteTracksOfSameName = TRUE,
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

- deleteTracksOfSameName:

  logical, default TRUE

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
