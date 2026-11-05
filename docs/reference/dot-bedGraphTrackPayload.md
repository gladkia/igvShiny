# Build the payload of a bedGraph track from a data.frame

The browser-free half of `loadBedGraphTrack`: checks and sorts the table
and returns the message body the `loadBedGraphTrack` handler in
igvShiny.js reads. The features travel inline as JSON, so `files` is
empty.

## Usage

``` r
.bedGraphTrackPayload(
  trackName,
  tbl,
  color = "gray",
  trackHeight = 30,
  autoscale,
  autoscaleGroup = -1,
  min = NA_real_,
  max = NA_real_,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- tbl:

  data.frame, with at least "chrom" "start" "end" "score" columns

- color:

  character string, a legal CSS color, or "random"

- trackHeight:

  an integer, 30 (pixels) by default

- autoscale:

  logical

- autoscaleGroup:

  numeric(1), -1 (no group) by default

- min:

  numeric, consulted when autoscale is FALSE

- max:

  numeric, consulted when autoscale is FALSE

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
