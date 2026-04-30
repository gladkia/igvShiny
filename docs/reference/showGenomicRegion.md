# focus igv on a region

zoom in or out to show the nominated region, by chromosome locus or gene
symbol

return the current region displayed by your igv instance

## Usage

``` r
showGenomicRegion(session, id, region)

getGenomicRegion(session, id)
```

## Arguments

- session:

  an environment or list, provided and managed by shiny

- id:

  character string, the html element id of this widget instance

- region:

  a character string, either e.g. "chr5:92,221,640-92,236,523" or
  "MEF2C"

## Value

a character string of format "chrom:start-end"

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}

library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
