# Build the payload of a bedpe interaction track from a data.frame

The browser-free builder of `BedpeInteractionsTrack`: sorts the table by
chrom1 and start1, writes it to `path` as headerless bedpe, and returns
the message body the `loadBedpeTrackFromFile` handler in igvShiny.js
reads. It has no exported data.frame loader;
[`loadTrack()`](https://gladkia.github.io/igvShiny/reference/loadTrack.md)
is its sender.

## Usage

``` r
.bedpeTrackPayload(
  trackName,
  tbl,
  path,
  color = "darkBlue",
  trackHeight = 50,
  trackConfig = list()
)
```

## Arguments

- trackName:

  character string

- tbl:

  data.frame, bedpe: chrom1, start1, end1, chrom2, start2, end2, then
  optional columns

- path:

  character string, the file to write; its basename is what the browser
  fetches from the `tracks/` resource path

- color:

  character string, a legal CSS color, or "random"

- trackHeight:

  numeric, pixels

- trackConfig:

  a named list of additional igv.js track configuration options, merged
  onto the defaults

## Value

a list with `config`, the message body without `elementID`, and `files`,
the paths written (here: `path`)
