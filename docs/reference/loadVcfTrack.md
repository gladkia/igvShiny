# load a VCF (variant) track provided as a Bioconductor VariantAnnotation object

load a VCF (variant) track provided as a Bioconductor VariantAnnotation
object

## Usage

``` r
loadVcfTrack(
  session,
  id,
  trackName,
  vcfData,
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

- vcfData:

  VariantAnnotation object

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
  system.file(package = "igvShiny", "demos", "igvShinyDemo-withVCF.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
