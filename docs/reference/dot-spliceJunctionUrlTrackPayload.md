# Build the payload of a splice junction track read by url

The browser-free half of `loadSpliceJunctionTrackFromURL` (and, with an
app-relative url, of `loadSpliceJunctionTrackFromLocalData`): returns
the message body the `loadSpliceJunctionTrackFromURL` handler in
igvShiny.js reads. Nothing is written, so `files` is empty.

## Usage

``` r
.spliceJunctionUrlTrackPayload(
  trackName,
  url,
  indexURL = "",
  trackHeight = 100,
  displayMode = "COLLAPSED",
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- url:

  character string, url of the junction bed file

- indexURL:

  character string, url of a tabix index, or "" for none; anything but a
  single non-NA string is turned into "" with a warning

- trackHeight:

  an integer, 100 (pixels) by default

- displayMode:

  character, "COLLAPSED", "EXPANDED" or "SQUISHED"

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
