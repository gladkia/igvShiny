# load a cram file sitting on the same machine as the shiny app

load a local cram track. Unlike `loadBamTrackFromLocalData` this loader
takes file paths, not an R object: no bioconductor package parses cram,
so the file and its index are handed to igv.js untouched, through the
directory shiny serves as "tracks".

## Usage

``` r
loadCramTrackFromLocalData(
  session,
  id,
  trackName,
  cramFile,
  indexFile = paste0(cramFile, ".crai"),
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

- cramFile:

  character string, path to a cram file

- indexFile:

  character string, path to its crai index, by default the cram file
  with ".crai" appended

- deleteTracksOfSameName:

  logical, default TRUE

- trackConfig:

  a named list of additional igv.js track configuration options, `sort`
  among them; see
  [`loadBamTrackFromURL`](https://gladkia.github.io/igvShiny/reference/loadBamTrackFromURL.md).

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
