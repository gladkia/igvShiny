# Quantitative tracks: scored intervals from a data.frame, GRanges or UCSCData

`QuantitativeTrack` adds y-axis scaling to
[`Track`](https://gladkia.github.io/igvShiny/reference/Track-class.md);
it carries no data, so build tracks with its subclasses:
`DataFrameQuantitativeTrack` (a data.frame of chrom, start, end, value
in bedGraph coordinates), `GRangesQuantitativeTrack` (a `GRanges` with
exactly one numeric metadata column) and `UCSCBedGraphQuantitativeTrack`
(an `rtracklayer` `UCSCData` imported from bedGraph, needs the suggested
package rtracklayer). Display one with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md),
which also sends `visibilityWindow` to igv.js.

## Usage

``` r
QuantitativeTrack(
  trackName,
  quantitativeData,
  fileFormat = c("wig", "bigWig", "bedGraph", "gwas"),
  color = "gray",
  sourceType = c("file", "url"),
  trackHeight = 50,
  autoscale = TRUE,
  min = NA_real_,
  max = NA_real_,
  visibilityWindow = 1e+05
)

DataFrameQuantitativeTrack(
  trackName,
  quantitativeData,
  color = "blue",
  trackHeight = 50,
  autoscale,
  min = NA_real_,
  max = NA_real_,
  visibilityWindow = 1e+05
)

GRangesQuantitativeTrack(
  trackName,
  quantitativeData,
  color = "blue",
  trackHeight = 50,
  autoscale = TRUE,
  min = NA_real_,
  max = NA_real_,
  visibilityWindow = 1e+05
)

UCSCBedGraphQuantitativeTrack(
  trackName,
  quantitativeData,
  color = "blue",
  trackHeight = 50,
  autoscale = TRUE,
  min = NA_real_,
  max = NA_real_,
  visibilityWindow = 1e+05
)
```

## Arguments

- trackName:

  A character string, used as track label by igv; we recommend unique
  names per track

- quantitativeData:

  the scored intervals; ignored by `QuantitativeTrack`, which only
  builds the shared part

- fileFormat:

  One of "wig", "bigWig", "bedGraph", "gwas"

- color:

  A CSS color name (e.g., "red" or "#FF0000"), or "random"

- sourceType:

  "file" or "url"

- trackHeight:

  track height in pixels

- autoscale:

  Autoscale track to maximum value in view

- min:

  Sets the minimum value for the data (y-axis) scale

- max:

  Sets the maximum value for the data (y-axis) scale; ignored if
  autoscale is TRUE

- visibilityWindow:

  Maximum window size in base pairs for which data is displayed

## Value

An object of the named class

## Slots

- `autoscale`:

  logical, scale the track to the maximum value in view

- `min`:

  numeric, y-axis minimum, used when autoscale is FALSE

- `max`:

  numeric, y-axis maximum, used when autoscale is FALSE

- `coreObject`:

  the scores: data.frame, GRanges or UCSCData

## Examples

``` r
tbl <- data.frame(chrom = "chr1", start = c(100, 200), end = c(200, 300),
                  value = c(0.5, 2), stringsAsFactors = FALSE)
track <- DataFrameQuantitativeTrack("bedGraph demo", tbl, autoscale = TRUE)
gr <- GenomicRanges::GRanges(c("chr1:101-200", "chr1:201-300"),
                             score = c(0.5, 2))
track2 <- GRangesQuantitativeTrack("GRanges demo", gr)
trackSize(track2)
#> [1] 2
```
