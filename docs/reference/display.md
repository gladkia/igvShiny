# display the already constructed and configured track

display the already constructed and configured track

## Usage

``` r
# S4 method for class 'GWASTrack'
display(obj, session, id, deleteTracksOfSameName = TRUE)
```

## Arguments

- obj:

  An object of class GWASTrack

- session:

  a Shiny session object

- id:

  character the identifier of the target igv object in the browser

- deleteTracksOfSameName:

  logical to avoid duplications in track names

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
