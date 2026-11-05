# Build the payload of a splice junction track from a data.frame

The browser-free half of `loadSpliceJunctionTrackFromLocalData`: writes
the six-column junction bed to `path` and returns the message body of
`.spliceJunctionUrlTrackPayload` pointed at it, which is what the
`loadSpliceJunctionTrackFromURL` handler in igvShiny.js reads.

## Usage

``` r
.spliceJunctionTrackPayload(
  trackName,
  tbl,
  path,
  trackHeight = 100,
  displayMode = "COLLAPSED",
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- tbl:

  data.frame, with at least "chrom" (or "chr") "start" "end" columns, in
  bed coordinates; see `loadSpliceJunctionTrackFromLocalData` for the
  optional columns

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

- trackHeight:

  an integer, 100 (pixels) by default

- displayMode:

  character, "COLLAPSED", "EXPANDED" or "SQUISHED"

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written (here: `path`)
