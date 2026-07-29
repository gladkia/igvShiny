# load a splice junction track served up by http

load splice junctions from a BED file reachable by URL, as written by
STAR (`SJ.out.tab` converted to BED). Six columns, with the per-junction
attributes packed into the name column as `key=value` pairs separated by
semicolons: `motif`, `uniquely_mapped`, `multi_mapped`,
`maximum_spliced_alignment_overhang` and `annotated_junction`. The track
reads its filters and labels from those attributes.

igv.js draws junctions from a file of that shape only - it derives none
of them from a bam file, and it has no sashimi plot. Show this track
above a coverage track (bigWig, bedGraph) for the same sample to get the
arcs-over-coverage view sashimi plots are wanted for.

## Usage

``` r
loadSpliceJunctionTrackFromURL(
  session,
  id,
  trackName,
  url,
  indexURL = "",
  trackHeight = 100,
  displayMode = "COLLAPSED",
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

- url:

  character string http url for the bed file of junctions

- indexURL:

  character string http url for a tabix index, needed only for a
  bgzipped bed; "" by default, which loads the file whole

- trackHeight:

  an integer, 100 (pixels) by default

- displayMode:

  character, "COLLAPSED", "EXPANDED" or "SQUISHED"

- deleteTracksOfSameName:

  logical, default TRUE

- trackConfig:

  a named list of additional igv.js track configuration options. The
  junction ones are read straight off it: `minUniquelyMappedReads`,
  `minTotalReads`, `maxFractionMultiMappedReads`,
  `minSplicedAlignmentOverhang`, `thicknessBasedOn`,
  `bounceHeightBasedOn`, `colorBy`, `labelWith`,
  `hideAnnotatedJunctions`, `hideUnannotatedJunctions`, `hideMotifs`
  among them.

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
