# Build the payload of a seg track from a data.frame

The browser-free half of `loadSegTrack`: returns the message body the
`loadSegTrack` handler in igvShiny.js reads. The segments travel inline
as JSON, so `files` is empty.

## Usage

``` r
.segTrackPayload(trackName, tbl, trackConfig = list())
```

## Arguments

- trackName:

  character string

- tbl:

  data.frame of segments, written through as is

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
