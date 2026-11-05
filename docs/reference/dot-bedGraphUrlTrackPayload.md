# Build the payload of a quantitative track read from a URL

The browser-free half of `loadBedGraphTrackFromURL`: returns the message
body the `loadBedGraphTrackFromURL` handler in igvShiny.js reads.
Nothing is written, so `files` is empty.

## Usage

``` r
.bedGraphUrlTrackPayload(
  trackName,
  url,
  color = "gray",
  trackHeight = 30,
  autoscale = TRUE,
  min = 0,
  max = 1,
  autoscaleGroup = -1,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- url:

  character string, a bedGraph, wig or bigwig URL

- color:

  character string, a legal CSS color, or "random"

- trackHeight:

  an integer, 30 (pixels) by default

- autoscale:

  logical

- min:

  numeric, consulted when autoscale is FALSE

- max:

  numeric, consulted when autoscale is FALSE

- autoscaleGroup:

  numeric(1), -1 (no group) by default

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
