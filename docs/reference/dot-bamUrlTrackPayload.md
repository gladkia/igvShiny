# Build the payload of a bam track read by url

The browser-free half of `loadBamTrackFromURL` and
`loadBamTrackFromLocalFile`: returns the message body the
`loadBamTrackFromURL` handler in igvShiny.js reads. The urls are used as
given (remote, or app-relative from
[`serveLocalFile()`](https://gladkia.github.io/igvShiny/reference/serveLocalFile.md));
nothing is written, so `files` is empty.

## Usage

``` r
.bamUrlTrackPayload(
  trackName,
  bamURL,
  indexURL,
  displayMode = "EXPANDED",
  showAllBases = FALSE,
  trackHeight = NULL,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- bamURL:

  character string, url of the bam file

- indexURL:

  character string, url of the bam index

- displayMode:

  character string, "EXPANDED" (default), "SQUISHED" or "COLLAPSED"

- showAllBases:

  logical, or NULL to leave the key out of the message (what
  `loadBamTrackFromLocalFile` has always sent)

- trackHeight:

  numeric track height in pixels, or NULL for the igv.js default

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
`character(0)`
