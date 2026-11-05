# Build the payload of a GWAS track from a data.frame

The browser-free half of `loadGwasTrack`: writes the table with its
header to `path` and returns the message body the `loadGwasTrack`
handler in igvShiny.js reads.

## Usage

``` r
.gwasTrackPayload(
  trackName,
  tbl.gwas,
  path,
  ymin = 0,
  ymax = 35,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- tbl.gwas:

  data.frame, the GWAS table

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

- ymin:

  numeric defaults to 0

- ymax:

  numeric defaults to 35

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written (here: `path`)
