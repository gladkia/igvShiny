# BedpeInteractionsTrack: paired-end interactions from a bedpe data.frame

A `DataFrameAnnotationTrack` whose table is bedpe: chrom1, start1, end1,
chrom2, start2, end2 (0-based starts), optionally followed by name and
score. igv.js draws it as an "interact" track of arcs between the two
anchors. Display it with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md);
color and height are sent to igv.js.

## Usage

``` r
BedpeInteractionsTrack(
  trackName,
  table,
  color = "darkBlue",
  trackHeight = 50,
  displayMode = "EXPANDED",
  visibilityWindow = 1e+05
)
```

## Arguments

- trackName:

  A character string, used as track label by igv

- table:

  a bedpe data.frame, at least 6 columns

- color:

  A CSS color name (e.g., "red" or "#FF0000"), or "random"

- trackHeight:

  track height in pixels

- displayMode:

  "COLLAPSED", "SQUISHED" or "EXPANDED"; stored, not sent

- visibilityWindow:

  Maximum window size in base pairs; stored, not sent

## Value

An object of class BedpeInteractionsTrack

## Examples

``` r
f <- system.file(package = "igvShiny", "extdata", "sixColumn-demo1.bedpe")
tbl <- utils::read.table(f, sep = "\t", header = TRUE,
                         stringsAsFactors = FALSE)
track <- BedpeInteractionsTrack("interactions", tbl)
trackSize(track)
#> [1] 32
```
