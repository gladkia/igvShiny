# GFF3Track: gene models from a GFF3 data.frame or url

A `GFF3Track` holds either a 9-column GFF3 table (`tbl`), served as a
file, or the url of a GFF3 file and optionally its index. Features are
colored by `trackColor`, or by the `colorByAttribute` attribute through
`colorTable`. Display it with
[`loadTrack`](https://gladkia.github.io/igvShiny/reference/loadTrack.md).

## Usage

``` r
GFF3Track(
  trackName,
  tbl.track = data.frame(),
  url = NA_character_,
  indexURL = NA_character_,
  trackColor = "black",
  colorByAttribute = NA_character_,
  colorTable = list(),
  displayMode = "EXPANDED",
  trackHeight = 50,
  visibilityWindow = 1e+05
)
```

## Arguments

- trackName:

  A character string, used as track label by igv

- tbl.track:

  a data.frame in standard 9-column GFF3 format

- url:

  url of a GFF3 file, used when `tbl.track` is empty

- indexURL:

  url of its index

- trackColor:

  A CSS color, used unless colorTable is given

- colorByAttribute:

  name of a GFF3 attribute in column 9, e.g. "biotype"

- colorTable:

  a named list mapping attribute values to colors

- displayMode:

  "COLLAPSED", "SQUISHED" or "EXPANDED"

- trackHeight:

  track height in pixels

- visibilityWindow:

  Maximum window size in base pairs for which features are displayed

## Value

An object of class GFF3Track

## Slots

- `tbl`:

  data.frame, the GFF3 table, or an empty data.frame

- `url`:

  character, the GFF3 url, or NA

- `indexURL`:

  character, the index url, or NA

- `colorByAttribute`:

  character, a column 9 attribute, or NA

- `colorTable`:

  list, attribute value to color; a "default" entry is renamed "\*",
  igv.js's fallback key

## Examples

``` r
f <- system.file(package = "igvShiny", "extdata", "GRCh38.94.NDUFS2.gff3")
tbl <- utils::read.table(f, sep = "\t", header = FALSE, quote = "",
                         stringsAsFactors = FALSE)
track <- GFF3Track("NDUFS2", tbl, colorByAttribute = "biotype",
                   colorTable = list(protein_coding = "blue",
                                     default = "gray"))
trackSize(track)
#> [1] 1056
```
