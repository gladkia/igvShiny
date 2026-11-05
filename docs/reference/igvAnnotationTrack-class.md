# Annotation tracks: bed-like features from a data.frame, GRanges or UCSCData

`igvAnnotationTrack` adds the slots of igv.js annotation tracks to
[`Track`](https://gladkia.github.io/igvShiny/reference/Track-class.md).
Its subclasses carry the features in a `coreObject` slot:
`DataFrameAnnotationTrack` (a bed-like data.frame, written as is),
`GRangesAnnotationTrack` (a `GRanges`; 1-based starts become 0-based bed
starts) and `UCSCBedAnnotationTrack` (an `rtracklayer` `UCSCData`, needs
the suggested package rtracklayer). Display one with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md),
which sends `displayMode`, `expandedRowHeight`, `squishedRowHeight`,
`maxRows`, `searchable` and `visibilityWindow` to igv.js. `nameField` is
stored for igvR compatibility, not sent.

## Usage

``` r
DataFrameAnnotationTrack(
  trackName,
  annotation,
  color = "",
  displayMode = "SQUISHED",
  trackHeight = 50,
  expandedRowHeight = 30,
  squishedRowHeight = 15,
  maxRows = 500,
  searchable = FALSE,
  visibilityWindow = 1e+05
)

GRangesAnnotationTrack(
  trackName,
  annotationData,
  color = "darkGrey",
  displayMode = "SQUISHED",
  trackHeight = 50,
  expandedRowHeight = 30,
  squishedRowHeight = 15,
  maxRows = 500,
  searchable = FALSE,
  visibilityWindow = 1e+05
)

UCSCBedAnnotationTrack(
  trackName,
  annotation,
  color = "darkGrey",
  displayMode = "SQUISHED",
  trackHeight = 50,
  expandedRowHeight = 30,
  squishedRowHeight = 15,
  maxRows = 500,
  searchable = FALSE,
  visibilityWindow = 1e+05
)
```

## Arguments

- trackName:

  A character string, used as track label by igv; we recommend unique
  names per track

- annotation:

  for `DataFrameAnnotationTrack`, a data.frame with at least chrom (or
  chr), start and end columns, in bed (0-based) coordinates; for
  `UCSCBedAnnotationTrack`, a `UCSCData` object, e.g. from
  `rtracklayer::import(format = "bed")`

- color:

  A CSS color name (e.g., "red" or "#FF0000"), or "random"; for a
  data.frame, leave the default "" if supplying bed9 with itemRgb

- displayMode:

  "COLLAPSED", "SQUISHED" or "EXPANDED"

- trackHeight:

  track height in pixels

- expandedRowHeight:

  Height of each row of features in "EXPANDED" mode

- squishedRowHeight:

  Height of each row of features in "SQUISHED" mode

- maxRows:

  maximum number of feature rows to display

- searchable:

  If TRUE, labels on annotation elements may be used in search

- visibilityWindow:

  Maximum window size in base pairs for which features are displayed

- annotationData:

  a `GRanges`; mcols "name" and "score", when present, fill the bed name
  and score columns

## Value

An object of the named class

## Slots

- `classTypeOfSuppliedObject`:

  character

- `displayMode`:

  character, "COLLAPSED", "SQUISHED" or "EXPANDED"

- `expandedRowHeight`:

  numeric, row height in "EXPANDED" mode

- `squishedRowHeight`:

  numeric, row height in "SQUISHED" mode

- `nameField`:

  character; stored for igvR compatibility, not sent

- `maxRows`:

  numeric

- `searchable`:

  logical

- `coreObject`:

  the features: data.frame, GRanges or UCSCData

## Examples

``` r
tbl <- data.frame(chrom = rep("chr5", 3),
                  start = c(88883100, 88883200, 88883350),
                  end = c(88883150, 88883220, 88883390),
                  name = c("a", "b", "c"),
                  stringsAsFactors = FALSE)
track <- DataFrameAnnotationTrack("data.frame demo", tbl, color = "red")
gr <- GenomicRanges::GRanges(c("chr5:100-149", "chr5:300-349"))
track2 <- GRangesAnnotationTrack("GRanges demo", gr)
trackSize(track2)
#> [1] 2
```
