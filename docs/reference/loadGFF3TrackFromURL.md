# load a GFF3 track which, with index, is served up by http

load a remote GFF3 track

## Usage

``` r
loadGFF3TrackFromURL(
  session,
  id,
  trackName,
  gff3URL,
  indexURL,
  color = "gray",
  colorTable,
  colorByAttribute,
  displayMode,
  trackHeight = 50,
  visibilityWindow,
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

- gff3URL:

  character string http url for the bam file, typically very large

- indexURL:

  character string http url for the bam file index, typically small

- color:

  character \#RGB or a recognized color name. ignored if colorTable and
  colorByAttribute provided

- colorTable:

  list, mapping a gff3 attribute, typically biotype, to a color

- colorByAttribute:

  character, name of a gff3 attribute in column 9, typically "biotype"

- displayMode:

  character, "EXPANDED", "SQUISHED" or "COLLAPSED"

- trackHeight:

  numeric defaults to 50

- visibilityWindow:

  numeric, Maximum window size in base pairs for which indexed
  annotations or variants are displayed

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
  system.file(package = "igvShiny", "demos", "igvShinyDemo-GFF3.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
