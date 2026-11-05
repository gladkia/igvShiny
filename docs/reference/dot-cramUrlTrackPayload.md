# Build the payload of a cram track read by url

The browser-free half of `loadCramTrackFromURL` and
`loadCramTrackFromLocalData`: returns the message body the
`loadCramTrackFromURL` handler in igvShiny.js reads. The urls are used
as given (remote, or app-relative from
[`serveLocalFile()`](https://gladkia.github.io/igvShiny/reference/serveLocalFile.md));
nothing is written, so `files` is empty.

## Usage

``` r
.cramUrlTrackPayload(
  trackName,
  cramURL,
  indexURL,
  trackHeight = NULL,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- cramURL:

  character string, url of the cram file

- indexURL:

  character string, url of the crai index

- trackHeight:

  numeric track height in pixels, or NULL for the igv.js default

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
