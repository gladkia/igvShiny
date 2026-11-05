# Build the payload of a bed track from a data.frame

The browser-free half of `loadBedTrack`: checks and sorts the table,
writes it to `path` as headerless bed, and returns the message body the
`loadBedTrackFromFile` handler in igvShiny.js reads. It touches no
session; the caller picks the path (in a sender, with
[`.trackFile()`](https://gladkia.github.io/igvShiny/reference/dot-trackFile.md))
and adds the element id.

## Usage

``` r
.bedTrackPayload(
  trackName,
  tbl,
  path,
  color = "",
  trackHeight = 50,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- tbl:

  data.frame, with at least "chrom" (or "chr") "start" "end" columns

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

- color:

  character string, a legal CSS color, or "random"

- trackHeight:

  an integer, 50 (pixels) by default

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written (here: `path`)
