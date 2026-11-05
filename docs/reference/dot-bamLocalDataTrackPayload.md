# Build the payload of a bam track from in-memory alignments

The browser-free half of `loadBamTrackFromLocalData`: exports `data` to
`path` as bam with `rtracklayer::export`, which also writes the index
`paste0(path, ".bai")`, and returns the message body the
`loadBamTrackFromLocalData` handler in igvShiny.js reads. Needs
rtracklayer and Rsamtools (Suggests).

## Usage

``` r
.bamLocalDataTrackPayload(
  trackName,
  data,
  path,
  displayMode = "EXPANDED",
  trackHeight = NULL,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- data:

  a `GAlignments` object (GenomicAlignments)

- path:

  character string, the bam file to write; its basename is what the
  browser fetches from the `tracks/` resource path

- displayMode:

  character string, "EXPANDED" (default), "SQUISHED" or "COLLAPSED"

- trackHeight:

  numeric track height in pixels, or NULL for the igv.js default

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the bam and its index
