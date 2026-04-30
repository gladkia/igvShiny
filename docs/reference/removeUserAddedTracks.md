# remove only those tracks explicitly added by your app

remove only those tracks explicitly added by your app. stock tracks
(i.e., \#' Refseq Genes) remain

## Usage

``` r
removeUserAddedTracks(session, id)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

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
