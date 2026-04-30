# Create an igvShiny instance

This function is called in the server function of your shiny app

## Usage

``` r
igvShiny(
  genomeOptions,
  width = NULL,
  height = NULL,
  elementId = NULL,
  displayMode = "squished",
  tracks = list()
)
```

## Arguments

- genomeOptions:

  a list with these fields: genomeName, initialLocus, annotation,
  dataMode, fasta, fastaIndex, stockGenome, validated

- width:

  a character string, standard css notations, either e.g., "1000px" or
  "95%"

- height:

  a character string, needs to be an explicit pixel measure, e.g.,
  "800px"

- elementId:

  a character string, the html element id within which igv is created

- displayMode:

  a character string, default "SQUISHED".

- tracks:

  a list of track specifications to be created and displayed at startup

## Value

the created widget

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "demos", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
