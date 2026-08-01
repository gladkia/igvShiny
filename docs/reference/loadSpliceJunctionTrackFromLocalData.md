# load a splice junction track from a data.frame

load splice junctions held in R. The table is written as the six-column
bed igv.js draws junctions from, and served from the same directory as
the other local-data tracks.

Coordinates are taken as bed coordinates and written out unchanged, as
the other `*FromLocalData` loaders take theirs. STAR reports the first
and last intron base of a junction 1-based in `SJ.out.tab`, so a table
read straight from that file needs its start shifted by one first; a bed
already converted from it, which is what STAR wrappers and the igv.js
test fixtures ship, is passed in as is.

Columns `chrom` (or `chr`), `start` and `end` are required. `score` and
`strand` are used when present. The per-junction attributes `motif`,
`uniquely_mapped`, `multi_mapped`, `maximum_spliced_alignment_overhang`
and `annotated_junction` are packed into the bed name column, which is
where the track reads its filters and labels from; supply the ones you
want to filter or label on. A `name` column, if you have already packed
it yourself, is written through untouched.

Without `uniquely_mapped` or an explicit `score` the arcs all draw at
the same thickness: igv.js has nothing to size them by.

## Usage

``` r
loadSpliceJunctionTrackFromLocalData(
  session,
  id,
  trackName,
  tbl,
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

- tbl:

  data.frame, with at least "chrom" "start" "end" columns, in bed
  coordinates: a 0-based start and an exclusive end

- trackHeight:

  an integer, 100 (pixels) by default

- displayMode:

  character, "COLLAPSED", "EXPANDED" or "SQUISHED"

- deleteTracksOfSameName:

  logical, default TRUE

- trackConfig:

  a named list of additional igv.js track configuration options, the
  junction ones among them; see
  [`loadSpliceJunctionTrackFromURL`](https://gladkia.github.io/igvShiny/reference/loadSpliceJunctionTrackFromURL.md)

## Value

nothing

## Examples

``` r
library(igvShiny)
demo_app_file <-
  system.file(package = "igvShiny", "showcase", "igvShinyDemo.R")
if (interactive()) {
  shiny::runApp(demo_app_file)
}
```
