# load a GWAS (genome-wide association study) track provided as a data.frame

load a GWAS (genome-wide association study) track provided as a
data.frame

## Usage

``` r
loadGwasTrack(
  session,
  id,
  trackName,
  tbl.gwas,
  ymin = 0,
  ymax = 35,
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

- tbl.gwas:

  data.frame, with at least "chrom" "start" "end" columns

- ymin:

  numeric defaults to 0

- ymax:

  numeric defaults to 35

- deleteTracksOfSameName:

  logical, default TRUE

- trackConfig:

  a named list of additional igv.js track configuration options. A table
  whose headers igv.js does not recognize needs its layout spelled out,
  1-based, as
  `columns = list(chromosome = 3, position = 4, value = 10)`;
  `colorTable` takes a chromosome-to-color map, see
  [`GWASTrack`](https://gladkia.github.io/igvShiny/reference/GWASTrack-class.md)

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
